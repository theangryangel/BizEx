defmodule BizEx.Schedule do
  alias BizEx.Period

  defstruct time_zone: "Etc/UTC", periods: [], holidays: []

  @type t :: %__MODULE__{
          time_zone: Timex.Types.time_zone(),
          periods: list(Period.t()),
          holidays: list(Date.t())
        }

  def default() do
    %__MODULE__{
      time_zone: "Europe/London",
      periods: [
        %Period{start_at: ~T[09:00:00], end_at: ~T[12:30:00], weekday: 1},
        %Period{start_at: ~T[13:00:00], end_at: ~T[17:30:00], weekday: 1},
        %Period{start_at: ~T[09:00:00], end_at: ~T[17:30:00], weekday: 2},
        %Period{start_at: ~T[09:00:00], end_at: ~T[17:30:00], weekday: 3},
        %Period{start_at: ~T[09:00:00], end_at: ~T[17:30:00], weekday: 4},
        %Period{start_at: ~T[09:00:00], end_at: ~T[17:30:00], weekday: 5}
      ],
      holidays: [
        ~D[2018-12-25]
      ]
      # TODO add date specific override support
      # How do we feel about something like this?
      # overrides: %{
      #   '2017-09-01': %Period{start_at: ~T[09:00:00], end_at: ~T[17:30:00]}
      # }
    }
  end

  @doc """
  Set the timezone of the schedule.
  """
  @spec set_timezone(t, Timex.Types.time_zone()) :: t
  def set_timezone(%__MODULE__{} = schedule, time_zone) when is_binary(time_zone) do
    if Timex.Timezone.exists?(time_zone) do
      %{schedule | time_zone: time_zone}
    else
      raise "invalid time zone"
    end
  end

  @doc """
  Add a working period (comprising of `start_at` time, `end_at` time and a `weekday` number) to a `schedule`, 
  ensuring that the periods are correctly ordered and no overlapping of periods occurs.
  """
  @spec add_period(
          t,
          Time.t(),
          Time.t(),
          Timex.Types.weekday() | :mon | :tue | :wed | :thu | :fri | :sat | :sun
        ) :: t
  def add_period(%__MODULE__{} = schedule, %Time{} = start_at, %Time{} = end_at, weekday)
      when is_number(weekday) and weekday >= 1 and weekday <= 7 do
    new_period = %Period{start_at: start_at, end_at: end_at, weekday: weekday}

    if overlaps?(schedule.periods, new_period) do
      raise "overlapping period defined, this is unsupported"
    else
      %{schedule | periods: sort_periods(schedule.periods ++ [new_period])}
    end
  end

  def add_period(%__MODULE__{} = schedule, %Time{} = start_at, %Time{} = end_at, weekday)
      when is_atom(weekday) do
    weekday_number =
      case weekday do
        :mon -> 1
        :tue -> 2
        :wed -> 3
        :thu -> 4
        :fri -> 5
        :sat -> 6
        :sun -> 7
      end

    add_period(schedule, start_at, end_at, weekday_number)
  end

  @doc """
  Add a holiday `date` to a `schedule`
  """
  @spec add_holiday(t, Date.t()) :: t
  def add_holiday(%__MODULE__{} = schedule, %Date{} = date) do
    %{schedule | holidays: schedule.holidays ++ [date]}
  end

  @doc """
  Checks if a given `date` is defined as a holiday, in the provided `schedule`
  """
  @spec holiday?(t, Date.t() | DateTime.t() | NaiveDateTime.t()) :: boolean
  def holiday?(schedule, date)

  def holiday?(%__MODULE__{} = schedule, %Date{} = date) do
    Enum.member?(schedule.holidays, date)
  end

  def holiday?(%__MODULE__{} = schedule, %DateTime{} = datetime) do
    holiday?(schedule, DateTime.to_date(datetime))
  end

  def holiday?(%__MODULE__{} = schedule, %NaiveDateTime{} = datetime) do
    holiday?(schedule, NaiveDateTime.to_date(datetime))
  end

  def working?(%__MODULE__{} = schedule, %Date{} = date) do
    if holiday?(schedule, date) do
      {:error, "not in hours"}
    else
      found =
        Enum.find_value(schedule.periods, fn period ->
          if Period.today?(period, date) do
            {:ok, period}
          end
        end)

      case found do
        {:ok, period} ->
          {:ok, period}

        _ ->
          {:error, "not in hours"}
      end
    end
  end

  def working?(%__MODULE__{} = schedule, %DateTime{} = datetime) do
    if holiday?(schedule, datetime) do
      {:error, "not in hours"}
    else
      found =
        Enum.find_value(schedule.periods, fn period ->
          if Period.active?(period, datetime) do
            {:ok, period}
          end
        end)

      case found do
        {:ok, period} ->
          start_at = Period.use_time(period, datetime, :start)
          end_at = Period.use_time(period, datetime, :end)

          {:ok, period, start_at, end_at}

        e ->
          e
      end
    end
  end

  @doc """
  Get the next working time
  """
  def next_working(%__MODULE__{} = schedule, %Date{} = date) do
    next_working(schedule, Timex.to_datetime(date))
  end

  def next_working(%__MODULE__{} = schedule, %DateTime{} = datetime) do
    working_period =
      if !holiday?(schedule, datetime) do
        Enum.find(schedule.periods, fn period ->
          Period.before_start?(period, datetime) and Period.before_end?(period, datetime)
        end)
      end

    if working_period do
      start_date = Period.use_time(working_period, datetime, :start)
      end_date = Period.use_time(working_period, datetime, :end)

      {:ok, start_date, end_date, working_period}
    else
      datetime =
        datetime
        |> Timex.shift(days: 1)
        |> Timex.set(hour: 0, minute: 0, second: 0)

      next_working(schedule, datetime)
    end
  end

  def previous_working(%__MODULE__{} = schedule, %DateTime{} = datetime) do
    working_period =
      if !holiday?(schedule, datetime) do
        schedule.periods
        |> Enum.reverse()
        |> Enum.find(fn period ->
          Period.after_start?(period, datetime) and Period.after_end?(period, datetime)
        end)
      end

    if working_period do
      start_date = Period.use_time(working_period, datetime, :start)
      end_date = Period.use_time(working_period, datetime, :end)

      {:ok, start_date, end_date, working_period}
    else
      datetime =
        datetime
        |> Timex.shift(days: -1)
        |> Timex.end_of_day()

      previous_working(schedule, datetime)
    end
  end

  @doc """
  Checks if a schedule is valid.
  """
  @spec valid?(t) :: boolean
  def valid?(%__MODULE__{} = schedule) do
    # TODO This needs to be padded out a bit and check for overlapping.
    # Do we care about performance?
    # Should this be checked by the user manually, or by the public functions on every call?
    length(schedule.periods) > 0
  end

  # Sort a list of periods, into their correct order
  defp sort_periods(periods) do
    periods
    |> Enum.sort(fn x, y ->
      # TODO this seems a bit crap, there's probably a better way to do it.
      if x.weekday == y.weekday do
        x.start_at < y.start_at
      else
        x.weekday < y.weekday
      end
    end)
  end

  # Determine if the new_period overlaps with any of the existing periods
  defp overlaps?(existing_periods, %Period{} = new_period) do
    Enum.any?(existing_periods, fn x ->
      x.weekday == new_period.weekday and new_period.start_at >= x.start_at and
        new_period.start_at <= x.end_at
    end)
  end
end

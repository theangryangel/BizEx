defmodule BizEx.Schedule do
  @moduledoc """
  BizEx Schedule module.
  """

  defstruct time_zone: "Etc/UTC", periods: [], holidays: []

  alias BizEx.Period

  # TODO: Re-implement.
  #def load_config() do
  #%Schedule{
  #time_zone: load_schedule_timezone(),
  #schedule: load_schedule(),
  #holidays: load_holidays()
  #}
  #end

  #defp load_schedule() do
  #Application.get_env(:bizex, :schedule, %{})
  #end

  #defp load_schedule_timezone() do
  #Application.get_env(:bizex, :schedule_timezone, "Etc/UTC")
  #end

  # defp load_holidays() do
  #Application.get_env(:bizex, :holidays, [])
  #end

  def default() do
    %__MODULE__{
      time_zone: "Europe/London", 
      periods: [
        %Period{start_at: ~T[09:00:00], end_at: ~T[12:30:00], weekday: 1 },
        %Period{start_at: ~T[13:00:00], end_at: ~T[17:30:00], weekday: 1 },
        %Period{start_at: ~T[09:00:00], end_at: ~T[17:30:00], weekday: 2 },
        %Period{start_at: ~T[09:00:00], end_at: ~T[17:30:00], weekday: 3 },
        %Period{start_at: ~T[09:00:00], end_at: ~T[17:30:00], weekday: 4 },
        %Period{start_at: ~T[09:00:00], end_at: ~T[17:30:00], weekday: 5 }
      ],
      holidays: [
        ~D[2017-12-25]
      ]
    }
  end

  @doc """
  Set the timezone of the schedule.
  """
  def set_timezone(%__MODULE__{} = schedule, time_zone) when is_binary(time_zone) do
    if Timex.Timezone.exists?(time_zone) do
      %{ schedule | time_zone: time_zone }
    else 
      raise "invalid time zone"
    end
  end

  @doc """
  Add a working period (comprising of `start_at` time, `end_at` time and a `weekday` number) to a `schedule`, 
  ensuring that the periods are correctly ordered.
  """
  def add_period(%__MODULE__{} = schedule, %Time{} = start_at, %Time{} = end_at, weekday) when weekday >= 1 and weekday <= 7 do
    overlaps = Enum.any?(schedule.periods, fn x -> 
      x.weekday == weekday and Timex.between?(start_at, x.start_at, x.end_at, inclusive: true)
    end)

    unless overlaps do
      sorted = (schedule.periods ++ [%Period{start_at: start_at, end_at: end_at, weekday: weekday }])
               |> Enum.sort(fn x, y -> 
                 # TODO fix this so that the start times are also appropriately sorted.
                 x.weekday < y.weekday
               end)

      %{schedule | periods: sorted}
    else
      raise "overlapping period defined, this is unsupported"      
    end
  end

  @doc """
  Add a holiday `date` to a `schedule`
  """
  def add_holiday(%__MODULE__{} = schedule, %Date{} = date) do
    %{schedule | holidays: (schedule.holidays ++ [date])}
  end

  @doc """
  Checks if a given `date` is defined as a holiday, in the provided `schedule`
  """
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

  @doc """
  Checks if a given `datetime` is between any of the provided `schedule` periods.

  Assumption is currently made that the timezone of the provided `datetime` is the same
  as the `schedule` timezone.
  """
  def between?(%__MODULE__{} = schedule, %DateTime{} = datetime) do
    period = schedule.periods
             |> Enum.map(fn x ->
               if Period.between?(x, datetime) do
                 x
               end
             end)
             |> Enum.reject(&is_nil/1)
             |> List.first

    if !is_nil(period) and !holiday?(schedule, datetime) do
      {:ok, period}
    else
      {:error, "not in hours"}
    end
  end

  @doc """
  Fetch the any active period, for a given `datetime`, from the provided `schedule`.

  Assumption is currently made that the timezone of the provided `datetime` is the same
  as the `schedule` timezone.
  """
  def current(%__MODULE__{} = schedule, %DateTime{} = datetime) do
    between?(schedule, datetime)
  end

  @doc """
  Fetch the next active period, for a given `datetime`, from the provided `schedule`.

  Assumption is currently made that the timezone of the provided `datetime` is the same
  as the `schedule` timezone.
  """
  def next(%__MODULE__{} = schedule, %DateTime{} = datetime, opts \\ []) do
    force_time = Keyword.get(opts, :force, false)

    period = schedule.periods
             |> Enum.map(fn x ->

               cond do
                 holiday?(schedule, datetime) ->
                   nil
                 force_time == true and Period.today?(x, datetime) ->
                   x
                 Period.after?(x, datetime) ->
                   x
                 true ->
                   nil
               end
             end)
             |> Enum.reject(&is_nil/1)
             |> List.first

    if !is_nil(period) do
      {:ok, period, Period.use_time(period, datetime, :start)}
    else
      next(schedule, Timex.shift(datetime, days: 1), [force: true])
    end
  end

  @doc """
  Fetch the previous active period, for a given `datetime`, from the provided `schedule`.

  Assumption is currently made that the timezone of the provided `datetime` is the same
  as the `schedule` timezone.
  """
  def prev(%__MODULE__{} = schedule, %DateTime{} = datetime, opts \\ []) do
    force_time = Keyword.get(opts, :force, false)

    period = schedule.periods
             |> Enum.map(fn x ->

               cond do
                 holiday?(schedule, datetime) ->
                   nil
                 force_time == true and Period.today?(x, datetime) ->
                   x
                 Period.before?(x, datetime) ->
                   x
                 true ->
                   nil
               end
             end)
             |> Enum.reject(&is_nil/1)
             |> List.first

    if !is_nil(period) do
      {:ok, period, Period.use_time(period, datetime, :end)}
    else
      prev(schedule, Timex.shift(datetime, days: -1), [force: true])
    end
  end

end


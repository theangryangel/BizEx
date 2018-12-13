defmodule BizEx do
  @moduledoc """
  Documentation for BizEx.
  """

  alias BizEx.{
    Schedule,
    Shift,
    Diff
  }

  @doc """
  Are we working?
  """
  @spec working?(Schedule.t(), DateTime.t() | NaiveDateTime.t() | Date.t()) :: boolean()
  def working?(schedule, datetime) do
    date =
      datetime
      |> Timex.Timezone.convert(schedule.time_zone)
      |> DateTime.to_date()

    with :ok <- schedule_valid?(schedule),
      {:ok, _period} <- Schedule.working?(schedule, date) do
        true
    else
      _ -> false
    end
  end

  @doc """
  Is a given date a holiday?
  """
  @spec holiday?(Schedule.t(), DateTime.t() | NaiveDateTime.t() | Date.t()) :: boolean()
  def holiday?(schedule, datetime) do
    date =
      datetime
      |> Timex.Timezone.convert(schedule.time_zone)
      |> DateTime.to_date()

    with :ok <- schedule_valid?(schedule) do
      Schedule.holiday?(schedule, date)
    else
      _ -> true
    end
  end

  @doc """
  Return the working periods for a given date
  """
  @spec working_periods_for(Schedule.t(), DateTime.t() | NaiveDateTime.t() | Date.t()) ::
          list(BizEx.Period.t())
  def working_periods_for(%Schedule{} = schedule, datetime) do
    if holiday?(schedule, datetime) do
      []
    else
      schedule.periods
      |> Enum.filter(fn p -> p.weekday == Timex.weekday(datetime) end)
    end
  end

  @doc """
  Current working period
  """
  @spec current_working_period(Schedule.t(), DateTime.t() | NaiveDateTime.t() | Date.t()) :: {:ok, DateTime.t(), DateTime.t()} | {:error, any()}
  def current_working_period(schedule, date)

  def current_working_period(schedule, %Date{} = date) do
    current_working_period(schedule, Timex.to_datetime(date))
  end

  def current_working_period(schedule, %DateTime{} = date) do
    original_tz = date.time_zone

    date = Timex.Timezone.convert(date, schedule.time_zone)

    case Schedule.working?(schedule, date) do
      {:ok, _period, start_at, end_at} ->
        start_at =
          if Timex.after?(date, start_at) do
            date
          else
            start_at
          end

        start_at = Timex.Timezone.convert(start_at, original_tz)
        end_at = Timex.Timezone.convert(end_at, original_tz)

        {:ok, start_at, end_at}

      e ->
        e
    end
  end

  @doc """
  When is the next working period?
  """
  @spec next_working_period(Schedule.t(), DateTime.t() | NaiveDateTime.t() | Date.t()) :: {:ok, DateTime.t(), DateTime.t()} | {:error, any()}
  def next_working_period(schedule, date)

  def next_working_period(schedule, %Date{} = date) do
    next_working_period(schedule, Timex.to_datetime(date))
  end

  def next_working_period(schedule, %DateTime{} = datetime) do
    with :ok <- schedule_valid?(schedule) do
      original_tz = datetime.time_zone
      converted_dt = Timex.Timezone.convert(datetime, schedule.time_zone)

      {:ok, start_at, end_at, _period} = Schedule.next_working(schedule, converted_dt)

      {
        :ok,
        Timex.Timezone.convert(start_at, original_tz),
        Timex.Timezone.convert(end_at, original_tz)
      }
    else
      e ->
        e
    end
  end

  @doc """
  When is the previous working period
  """
  @spec previous_working_period(Schedule.t(), DateTime.t() | NaiveDateTime.t() | Date.t()) :: {:ok, DateTime.t(), DateTime.t()} | {:error, any()}
  def previous_working_period(schedule, datetime) do
    with :ok <- schedule_valid?(schedule) do
      original_tz = datetime.time_zone
      converted_dt = Timex.Timezone.convert(datetime, schedule.time_zone)

      {:ok, start_at, end_at, _period} = Schedule.previous_working(schedule, converted_dt)

      {
        :ok,
        Timex.Timezone.convert(start_at, original_tz),
        Timex.Timezone.convert(end_at, original_tz)
      }
    else
      e ->
        e
    end
  end

  @doc """
  Shift the date time by some units of time.
  """
  @spec shift(Schedule.t(), DateTime.t() | NaiveDateTime.t() | Date.t(), integer() | keyword()) :: {:ok, DateTime.t()} | {:error, any()}
  def shift(schedule, datetime, units) do
    with :ok <- schedule_valid?(schedule) do
      datetime = Timex.Timezone.convert(datetime, schedule.time_zone)
      
      {:ok, Shift.shift(schedule, datetime, units)}
    else
      e ->
        e
    end
    
  end

  @doc """
  Working time between 2 datetimes, in seconds
  """
  @spec diff(Schedule.t(), DateTime.t() | NaiveDateTime.t() | Date.t(), DateTime.t() | NaiveDateTime.t() | Date.t()) :: {:ok, integer()} | {:error, any()}
  def diff(schedule, start_at, end_at) do
    with :ok <- schedule_valid?(schedule) do
      start_at = Timex.Timezone.convert(start_at, schedule.time_zone)
      end_at = Timex.Timezone.convert(end_at, schedule.time_zone)
      
      {:ok, Diff.diff(schedule, start_at, end_at)}
    else
      e ->
        e
    end
  end

  defp schedule_valid?(schedule) do
    case Schedule.valid?(schedule) do
      true ->
        :ok
      false ->
        {:error, "invalid schedule"}
    end
  end
end

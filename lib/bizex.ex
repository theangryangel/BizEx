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
  def working?(schedule, datetime) do
    date = datetime
    |> Timex.Timezone.convert(schedule.time_zone)
    |> DateTime.to_date

    case Schedule.working?(schedule, date) do
      {:ok, _period} -> true
      _ -> false
    end
  end

  def holiday?(schedule, datetime) do
    date = datetime
    |> Timex.Timezone.convert(schedule.time_zone)
    |> DateTime.to_date

    Schedule.holiday?(schedule, date)
  end

  @doc """
  Current working period?
  """

  def current_working_period(schedule, %Date{} = date) do
    current_working_period(schedule, Timex.to_datetime(date))
  end

  def current_working_period(schedule, %DateTime{} = date) do
    original_tz = date.time_zone

    date = Timex.Timezone.convert(date, schedule.time_zone)

    case Schedule.working?(schedule, date) do
      {:ok, _period, start_at, end_at} -> 
        start_at = if Timex.after?(date, start_at) do
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
  def next_working_period(schedule, date)

  def next_working_period(schedule, %Date{} = date) do
    next_working_period(schedule, Timex.to_datetime(date))
  end

  def next_working_period(schedule, %DateTime{} = datetime) do
    original_tz = datetime.time_zone
    converted_dt = Timex.Timezone.convert(datetime, schedule.time_zone)

    {:ok, start_at, end_at, _period} = Schedule.next_working(schedule, converted_dt)

    {
      Timex.Timezone.convert(start_at, original_tz), 
      Timex.Timezone.convert(end_at, original_tz)
    }
  end

  def previous_working_period(schedule, datetime) do
    original_tz = datetime.time_zone
    converted_dt = Timex.Timezone.convert(datetime, schedule.time_zone)

    {:ok, start_at, end_at, _period} = Schedule.previous_working(schedule, converted_dt)

    {
      Timex.Timezone.convert(start_at, original_tz), 
      Timex.Timezone.convert(end_at, original_tz)
    }
  end

  def shift(schedule, datetime, units) do
    Shift.shift(schedule, datetime, units)
  end

  def diff(schedule, start_at, end_at) do
    Diff.diff(schedule, start_at, end_at)
  end
end

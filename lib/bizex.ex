defmodule BizEx do
  @moduledoc """
  Documentation for BizEx.
  """
  alias BizEx.Schedule
  alias BizEx.Math

  def shift(schedule, datetime, params) do
    converted_datetime = Timex.Timezone.convert(datetime, schedule.time_zone)
    schedule 
    |> Math.shift(converted_datetime, params)
    |> Timex.Timezone.convert(datetime.time_zone)
  end

  def prev(schedule, datetime) do
    converted_datetime = Timex.Timezone.convert(datetime, schedule.time_zone)
    {:ok, period, converted_datetime} = Schedule.prev(schedule, converted_datetime)

    {:ok, period, Timex.Timezone.convert(converted_datetime, datetime.time_zone)}
  end

  def next(schedule, datetime) do
    converted_datetime = Timex.Timezone.convert(datetime, schedule.time_zone)
    {:ok, period, converted_datetime} = Schedule.next(schedule, converted_datetime)

    {:ok, period, Timex.Timezone.convert(converted_datetime, datetime.time_zone)}
  end

  def holiday?(schedule, datetime) do
    date = datetime
    |> Timex.Timezone.convert(schedule.time_zone)
    |> DateTime.to_date

    Schedule.holiday?(schedule, date)
  end

end

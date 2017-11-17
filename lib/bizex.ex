defmodule BizEx do
  @moduledoc """
  Documentation for BizEx.
  """
  alias BizEx.Schedule
  alias BizEx.Math

  @doc """
  Shift (add/remove) time to the provided `datetime` according to the `schedule`.

  Will automatically convert the datetime to the same timezone as the schedule, 
  and then convert back to the original timezone.
  """
  def shift(%Schedule{} = schedule, datetime, params) do
    converted_datetime = Timex.Timezone.convert(datetime, schedule.time_zone)
    schedule 
    |> Math.shift(converted_datetime, params)
    |> Timex.Timezone.convert(datetime.time_zone)
  end

  @doc """
  Return the currently active period, using the provided `datetime` according to the `schedule`.

  Will automatically convert the datetime to the same timezone as the schedule, 
  and then convert back to the original timezone.
  """
  def current(%Schedule{} = schedule, datetime) do
    converted_datetime = Timex.Timezone.convert(datetime, schedule.time_zone)
    with {:ok, period, converted_datetime} <- Schedule.current(schedule, converted_datetime) do
      {:ok, period, Timex.Timezone.convert(converted_datetime, datetime.time_zone)}
    else _ ->
      {:error, "not in hours", datetime}
    end
  end

  @doc """
  Return the previous active period, using the provided `datetime` according to the `schedule`.

  Will automatically convert the datetime to the same timezone as the schedule, 
  and then convert back to the original timezone.
  """
  def prev(%Schedule{} = schedule, datetime) do
    converted_datetime = Timex.Timezone.convert(datetime, schedule.time_zone)
    {:ok, period, converted_datetime} = Schedule.prev(schedule, converted_datetime)

    {:ok, period, Timex.Timezone.convert(converted_datetime, datetime.time_zone)}
  end

  @doc """
  Return the next active period, using the provided `datetime` according to the `schedule`.

  Will automatically convert the datetime to the same timezone as the schedule, 
  and then convert back to the original timezone.
  """
  def next(%Schedule{} = schedule, datetime) do
    converted_datetime = Timex.Timezone.convert(datetime, schedule.time_zone)
    {:ok, period, converted_datetime} = Schedule.next(schedule, converted_datetime)

    {:ok, period, Timex.Timezone.convert(converted_datetime, datetime.time_zone)}
  end

  @doc """
  Returns whether or not the provided `datetime` is defined as a holiday in the `schedule`.

  Will automatically convert the datetime to the same timezone as the schedule.
  """
  def holiday?(%Schedule{} = schedule, datetime) do
    date = datetime
    |> Timex.Timezone.convert(schedule.time_zone)
    |> DateTime.to_date

    Schedule.holiday?(schedule, date)
  end

end

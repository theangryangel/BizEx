defmodule BizEx do
  @moduledoc """
  Documentation for BizEx.
  """

  @doc """
  Is a given date, or datetime, a working day?
  """
  def working?(datetime) do
    BizEx.Schedule.load()
    |> BizEx.Date.working?(datetime)
  end

  @doc """
  Is a given date, or datetime, a holiday?
  """
  def holiday?(datetime) do
    BizEx.Schedule.load()
    |> BizEx.Date.holiday?(datetime)
  end

  @doc """
  Adds hours, minutes, seconds, etc. to a date, working time only
  """
  def shift(datetime, params) do
    seconds = BizEx.Units.to_seconds(params)

    if seconds == 0 do
      # TODO: This is a bit shit, and a total workaround for the shiftup and shiftdown adding and removing +/-1 second
      schedule = BizEx.Schedule.load()    
      BizEx.Schedule.next_datetime_in_period(schedule, datetime)
    else
      if seconds > 0 do
        shiftup(datetime, %{ seconds: seconds })
      else
        shiftdown(datetime, %{ seconds: seconds })
      end
    end
  end

  defp shiftup(datetime, %{ seconds: seconds }) do
    IO.puts "shifting up #{datetime}, by seconds: #{seconds}"
    schedule = BizEx.Schedule.load()
    
    converted_datetime = Timex.Timezone.convert(datetime, schedule.time_zone)

    {starting_datetime, period} = BizEx.Schedule.next_datetime_in_period(schedule, converted_datetime)

    IO.puts "using shiftup start point of #{starting_datetime}"

    raw_shifted = Timex.shift(starting_datetime, seconds: seconds)

    period_ends_at = BizEx.Time.force_to(starting_datetime, elem(period, 1))

    if Timex.after?(raw_shifted, period_ends_at) do
      remainder = Timex.diff(raw_shifted, period_ends_at, :seconds)

      period_ends_at
      |> Timex.shift(seconds: 1)
      |> Timex.Timezone.convert(datetime.time_zone)
      |> shiftup(%{ seconds: remainder-1 })
    else
      Timex.Timezone.convert(raw_shifted, datetime.time_zone)
    end
  end

  defp shiftdown(datetime, %{ seconds: seconds }) do
    IO.puts "shifting down #{datetime}, by seconds: #{seconds}"
    schedule = BizEx.Schedule.load()
    
    converted_datetime = Timex.Timezone.convert(datetime, schedule.time_zone)

    {starting_datetime, period} = BizEx.Schedule.next_datetime_in_period(schedule, converted_datetime, direction: :down)

    raw_shifted = Timex.shift(starting_datetime, seconds: seconds)

    period_starts_at = BizEx.Time.force_to(starting_datetime, elem(period, 0))

    if Timex.before?(raw_shifted, period_starts_at) do
      remainder = Timex.diff(raw_shifted, period_starts_at, :seconds)

      period_starts_at
      |> Timex.shift(seconds: -1)
      |> Timex.Timezone.convert(datetime.time_zone)
      |> shiftdown(%{ seconds: remainder+1 })
    else
      Timex.Timezone.convert(raw_shifted, datetime.time_zone)
    end
  end

end

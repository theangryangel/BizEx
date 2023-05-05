defmodule BizEx.Shift do
  alias BizEx.Schedule
  alias BizEx.Units

  def shift(%Schedule{} = schedule, %DateTime{} = datetime, units) when is_list(units) do
    seconds = Units.to_seconds(units)

    shift(schedule, datetime, seconds)
  end

  def shift(%Schedule{} = schedule, %DateTime{} = datetime, seconds)
      when is_integer(seconds) and seconds == 0 do
    case Schedule.working?(schedule, datetime) do
      {:ok, _period, _start, _end} ->
        datetime

      _ ->
        {:ok, start_date, _, _} = Schedule.next_working(schedule, datetime)
        start_date
    end
  end

  def shift(%Schedule{} = schedule, %DateTime{} = datetime, seconds)
      when is_integer(seconds) and seconds < 0 do
    case Schedule.working?(schedule, datetime) do
      {:ok, _period, period_start_at, _period_end_at} ->
        raw_shifted =
          datetime
          |> Timex.shift(seconds: seconds)
          |> DateTime.truncate(:second)

        if Timex.before?(raw_shifted, period_start_at) do
          remainder = Timex.diff(raw_shifted, period_start_at, :seconds)

          {:ok, _next_start_time, next_end_time, _next_period} =
            Schedule.previous_working(schedule, period_start_at)

          shift(schedule, next_end_time, remainder)
        else
          raw_shifted
        end

      _ ->
        {:ok, _start_date, end_date, _} = Schedule.previous_working(schedule, datetime)
        shift(schedule, end_date, seconds)
    end
  end

  def shift(%Schedule{} = schedule, %DateTime{} = datetime, seconds)
      when is_integer(seconds) and seconds > 0 do
    case Schedule.working?(schedule, datetime) do
      {:ok, _period, _period_start_at, period_end_at} ->
        raw_shifted =
          datetime
          |> Timex.shift(seconds: seconds)
          |> DateTime.truncate(:second)

        if Timex.after?(raw_shifted, period_end_at) do
          remainder = Timex.diff(raw_shifted, period_end_at, :seconds)

          {:ok, next_start_time, _next_end_time, _next_period} =
            Schedule.next_working(schedule, period_end_at)

          shift(schedule, next_start_time, remainder)
        else
          raw_shifted
        end

      _ ->
        {:ok, start_date, _, _} = Schedule.next_working(schedule, datetime)
        shift(schedule, start_date, seconds)
    end
  end
end

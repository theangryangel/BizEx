defmodule BizEx.Math do
  @moduledoc false 

  alias BizEx.Period
  alias BizEx.Schedule

  def shift(schedule, datetime, params)

  def shift(%Schedule{} = schedule, %DateTime{} = datetime, params) when is_list(params) do
    seconds = BizEx.Units.to_seconds(params)
    shift(schedule, datetime, seconds)
  end

  def shift(%Schedule{} = schedule, datetime, seconds) when is_integer(seconds) and seconds == 0 do
    with {:ok, _period} <- Schedule.current(schedule, datetime) do
      datetime
    else _ ->
      Schedule.next(schedule, datetime, force: true)
    end
  end

  def shift(%Schedule{} = schedule, %DateTime{} = datetime, seconds) when is_integer(seconds) and seconds > 0 do
    with {:ok, period} <- Schedule.current(schedule, datetime) do
      raw_shifted = Timex.shift(datetime, seconds: seconds)
      period_ends_at = Period.use_time(period, datetime, :end)

      if Timex.after?(raw_shifted, period_ends_at) do
        remainder = Timex.diff(raw_shifted, period_ends_at, :seconds)

        {:ok, _period, next_start_time} = Schedule.next(schedule, period_ends_at)
        shift(schedule, next_start_time, remainder)
      else
        raw_shifted
      end
    else _ ->
      {:ok, _period, next_datetime} = Schedule.next(schedule, datetime)

      shift(schedule, next_datetime, seconds)
    end
  end

  def shift(%Schedule{} = schedule, datetime, seconds) when is_integer(seconds) and seconds < 0 do
    with {:ok, period} <- Schedule.current(schedule, datetime) do
      raw_shifted = Timex.shift(datetime, seconds: seconds)
      period_starts_at = Period.use_time(period, datetime, :end)

      if Timex.after?(raw_shifted, period_starts_at) do
        remainder = Timex.diff(raw_shifted, period_starts_at, :seconds)

        {:ok, _period, next_start_time} = Schedule.prev(schedule, period_starts_at)
        shift(schedule, next_start_time, remainder)
      else
        raw_shifted
      end
    else _ ->
      {:ok, _period, next_datetime} = Schedule.prev(schedule, datetime, force: true)

      shift(schedule, next_datetime, seconds)
    end
  end
end

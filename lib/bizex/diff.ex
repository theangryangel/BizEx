defmodule BizEx.Diff do
  alias BizEx.Schedule

  def diff(schedule, start_at, end_at) do
    start_at = current_or_next(schedule, start_at)
    end_at = current_or_next(schedule, end_at)

    if Timex.after?(start_at, end_at) do
      diff(schedule, start_at, end_at, 0) * -1
    else
      diff(schedule, end_at, start_at, 0)
    end
  end

  defp diff(schedule, start_at, end_at, acc, count \\ 0) do
    if count > 100 do
      raise "Inception guard"
    end

    case Schedule.working?(schedule, start_at) do
      {:ok, _period, period_start_at, period_end_at} ->
        cond do
          Timex.compare(start_at, end_at) == 0 ->
            acc

          Timex.compare(period_end_at, end_at, :days) == 0 and
              Timex.compare(period_end_at, end_at) >= 0 ->
            acc + Timex.diff(end_at, start_at, :seconds)

          true ->
            acc = acc + Timex.diff(period_start_at, start_at, :seconds)

            {:ok, _start_date, end_date, _} = Schedule.previous_working(schedule, start_at)
            diff(schedule, end_date, end_at, acc, count + 1)
        end

      _ ->
        {:ok, _start_date, end_date, _} = Schedule.previous_working(schedule, start_at)
        diff(schedule, end_date, end_at, acc, count + 1)
    end
  end

  defp current_or_next(schedule, datetime) do
    case Schedule.working?(schedule, datetime) do
      {:ok, _period, _period_start_at, _period_end_at} ->
        datetime

      _ ->
        {:ok, start_date, _, _} = Schedule.next_working(schedule, datetime)
        start_date
    end
  end
end

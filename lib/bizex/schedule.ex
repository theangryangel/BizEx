defmodule BizEx.Schedule do

  alias BizEx.Schedule

  defstruct timezone: "Etc/UTC", schedule: [], holidays: []

  def load() do
    %Schedule{
      timezone: load_schedule_timezone(),
      schedule: load_schedule(),
      holidays: load_holidays()
    }
  end

  def fetch(%Schedule{} = schedule, %Date{} = date) do
    ordinal = date
      |> Timex.weekday
      |> ordinal_week_day_to_atom

    Map.get(schedule.schedule, ordinal)
  end

  defp load_schedule() do
    Application.get_env(:bizex, :schedule, %{})
  end

  defp load_schedule_timezone() do
    Application.get_env(:bizex, :schedule_timezone, "Etc/UTC")
  end

  defp load_holidays() do
    Application.get_env(:bizex, :holidays, [])
  end

  def ordinal_week_day_to_atom(n) do
    case n do
      1 -> :mon
      2 -> :tue
      3 -> :wed
      4 -> :thu
      5 -> :fri
      6 -> :sat
      7 -> :sun
    end
  end
end

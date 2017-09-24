defmodule BizEx.Schedule do

  alias BizEx.Schedule

  defstruct time_zone: "Etc/UTC", schedule: [], holidays: []

  def load() do
    %Schedule{
      time_zone: load_schedule_timezone(),
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

  # TODO currently not correctly selecting the next datetime, if multiple periods per day
  def next_datetime_in_period(schedule, datetime, opts \\ %{}) do
    direction = opts[:direction] || :up
    force_time = opts[:force] || false

    time = DateTime.to_time(datetime)

    current_periods = BizEx.Schedule.fetch(schedule, Timex.to_date(datetime))

    datetime = if force_time and !is_nil(current_periods) and length(current_periods) > 0 do
      force_to = if direction == :up, do: 0, else: 1

      BizEx.Time.force_to(datetime, elem(List.first(current_periods), force_to))
    else
      datetime
    end

    with false <- BizEx.Date.holiday?(schedule, datetime),
      {:ok, period} <- BizEx.Time.between_any?(time, current_periods)
    do
      {datetime, period}
    else
      _err ->
        days = if direction == :up, do: 1, else: -1

        next_datetime_in_period(schedule, Timex.shift(datetime, days: days), direction: direction, force: true)
    end
  end
end

defmodule BizEx.Schedule do
  defstruct time_zone: "Etc/UTC", periods: [], holidays: []

  alias BizEx.Period

  # TODO: Re-implement.
  #def load_config() do
  #%Schedule{
  #time_zone: load_schedule_timezone(),
  #schedule: load_schedule(),
  #holidays: load_holidays()
  #}
  #end

  #defp load_schedule() do
  #Application.get_env(:bizex, :schedule, %{})
  #end

  #defp load_schedule_timezone() do
  #Application.get_env(:bizex, :schedule_timezone, "Etc/UTC")
  #end

  # defp load_holidays() do
  #Application.get_env(:bizex, :holidays, [])
  #end

  def default() do
    %__MODULE__{
      time_zone: "Europe/London", 
      periods: [
        # TODO Probably should add some kind of validation functionality. 
        # Currently assumes the order of definition is Mon-Sun, in the appropriate time order
        %Period{start_at: ~T[09:00:00], end_at: ~T[12:30:00], weekday: 1 },
        %Period{start_at: ~T[13:00:00], end_at: ~T[17:30:00], weekday: 1 },
        %Period{start_at: ~T[09:00:00], end_at: ~T[17:30:00], weekday: 2 },
        %Period{start_at: ~T[09:00:00], end_at: ~T[17:30:00], weekday: 3 },
        %Period{start_at: ~T[09:00:00], end_at: ~T[17:30:00], weekday: 4 },
        %Period{start_at: ~T[09:00:00], end_at: ~T[17:30:00], weekday: 5 }
      ],
      holidays: [
        ~D[2017-12-25]
      ]
    }
  end

  def holiday?(%__MODULE__{} = schedule, %Date{} = date) do
    Enum.member?(schedule.holidays, date)
  end

  def holiday?(%__MODULE__{} = schedule, %DateTime{} = datetime) do
    holiday?(schedule, DateTime.to_date(datetime))
  end

  def holiday?(%__MODULE__{} = schedule, %NaiveDateTime{} = datetime) do
    holiday?(schedule, NaiveDateTime.to_date(datetime))
  end

  def between?(%__MODULE__{} = schedule, %DateTime{} = datetime) do
    period = schedule.periods
             |> Enum.map(fn x ->
               if Period.between?(x, datetime) do
                 x
               end
             end)
             |> Enum.reject(&is_nil/1)
             |> List.first

    if !is_nil(period) and !holiday?(schedule, datetime) do
      {:ok, period}
    else
      {:error, "not in hours"}
    end
  end

  def current(%__MODULE__{} = schedule, %DateTime{} = datetime) do
    between?(schedule, datetime)
  end

  def next(%__MODULE__{} = schedule, %DateTime{} = datetime, opts \\ []) do
    force_time = Keyword.get(opts, :force, false)

    period = schedule.periods
             |> Enum.map(fn x ->

               cond do
                 holiday?(schedule, datetime) ->
                   nil
                 force_time == true and Period.today?(x, datetime) ->
                   x
                 Period.after?(x, datetime) ->
                   x
                 true ->
                   nil
               end
             end)
             |> Enum.reject(&is_nil/1)
             |> List.first

    if !is_nil(period) do
      {:ok, period, Period.use_time(period, datetime, :start)}
    else
      next(schedule, Timex.shift(datetime, days: 1), [force: true])
    end
  end

  def prev(%__MODULE__{} = schedule, %DateTime{} = datetime, opts \\ []) do
    force_time = Keyword.get(opts, :force, false)

    period = schedule.periods
             |> Enum.map(fn x ->

               cond do
                 holiday?(schedule, datetime) ->
                   nil
                 force_time == true and Period.today?(x, datetime) ->
                   x
                 Period.before?(x, datetime) ->
                   x
                 true ->
                   nil
               end
             end)
             |> Enum.reject(&is_nil/1)
             |> List.first

    if !is_nil(period) do
      {:ok, period, Period.use_time(period, datetime, :end)}
    else
      prev(schedule, Timex.shift(datetime, days: -1), [force: true])
    end
  end

end


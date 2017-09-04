defmodule BizEx.Date do

  alias BizEx.Schedule

  def working?(%Schedule{} = schedule, %DateTime{} = datetime) do
    datetime = Timex.Timezone.convert(datetime, schedule.timezone)

    hours = Schedule.fetch(schedule, DateTime.to_date(datetime))

    if hours != nil and !holiday?(schedule, datetime) do
      time = datetime |> DateTime.to_time()

      BizEx.Time.in_set_of_hours?(hours, time)
    else
      false
    end
  end

  def working?(%Schedule{} = schedule, %NaiveDateTime{} = datetime) do
    hours = Schedule.fetch(schedule, NaiveDateTime.to_date(datetime))

    if hours != nil and !holiday?(schedule, datetime) do
      BizEx.Time.in_set_of_hours?(hours, NaiveDateTime.to_time(datetime))
    else
      false
    end
  end

  def working?(%Schedule{} = schedule, %Date{} = date)  do
    hours = Schedule.fetch(schedule, date)

    if hours != nil do
      true
    else
      false
    end
  end

  def working?(_, _), do: false

  def holiday?(%Schedule{} = schedule, %Date{} = date) do
    Enum.member?(schedule.holidays, date)
  end

  def holiday?(%Schedule{} = schedule, %DateTime{} = datetime) do
    holiday?(schedule, DateTime.to_date(datetime))
  end

  def holiday?(%Schedule{} = schedule, %NaiveDateTime{} = datetime) do
    holiday?(schedule, NaiveDateTime.to_date(datetime))
  end


  def now_or_prev(schedule, datetime, opts \\ %{})

  def now_or_prev(%Schedule{} = schedule, %DateTime{} = datetime, opts) do
    converted_datetime = Timex.Timezone.convert(datetime, schedule.timezone)

    # Find any list of periods, for the current date
    ordinal = converted_datetime |> Timex.weekday |> Schedule.ordinal_week_day_to_atom
    hours = Map.get(schedule.schedule, ordinal) ||  []

    # if we have a period, and force is true, then set the time to the start of the first period available
    # otherwise, use the time supplied
    converted_datetime = if length(hours) > 0 and opts[:force] == true do
                 new_time = hours |> List.first |> List.last
                 BizEx.Time.force_to(converted_datetime, new_time)
               else
                 converted_datetime
               end

    time = DateTime.to_time(converted_datetime)

    current_period = hours
      |> Enum.map(fn x -> 
        if Timex.between?(time, List.first(x), List.last(x), [inclusive: true]) do
          x
        end
    end)
    |> Enum.reject(&is_nil/1)
    |> List.last

    cond do
      is_nil(hours) or holiday?(schedule, converted_datetime) -> 
        now_or_prev(schedule, Timex.shift(datetime, days: -1), force: true)

      !is_nil(current_period) and length(current_period) > 0 -> 
        new_date = Timex.Timezone.convert(converted_datetime, datetime.time_zone)
        %{
          date: new_date, 
          starts_at: BizEx.Time.force_to(new_date, List.first(current_period)), 
          ends_at: BizEx.Time.force_to(new_date, List.last(current_period))
        }

      true ->
        next_period = hours
          |> Enum.map(fn x -> 
  
            if Timex.between?(time, List.first(x), List.last(x)) do
              List.last(x)
            end
          end)
          |> Enum.reject(&is_nil/1)

        if is_nil(next_period) or length(next_period) < 1 do
          now_or_prev(schedule, Timex.shift(datetime, days: -1), force: true)
        else
          next_period_starts_at = converted_datetime |> BizEx.Time.force_to(List.first(next_period)) |> Timex.Timezone.convert(datetime.time_zone)

          %{
            date: next_period_starts_at, 
            starts_at: next_period_starts_at,
            ends_at: converted_datetime |> BizEx.Time.force_to(List.last(next_period)) |> Timex.Timezone.convert(datetime.timezone)
          }
        end
      end
  end


  @doc """
  Given a schedule, and a datetime, if it's a working period return the datetime
  otherwise calculate the next starting point
  """
  def now_or_next(schedule, datetime, opts \\ %{})

  def now_or_next(%Schedule{} = schedule, %Date{} = date, _opts) do
    if working?(schedule, date) do
      %{date: date, starts_at: date, ends_at: date}
    else
      now_or_next(schedule, Timex.shift(date, days: 1))
    end
  end

  # TODO There's a whole lof of un-necessary timezone conversions here. This needs to be refactored.
  def now_or_next(%Schedule{} = schedule, %DateTime{} = datetime, opts) do
    converted_datetime = Timex.Timezone.convert(datetime, schedule.timezone)

    # Find any list of periods, for the current date
    ordinal = converted_datetime |> Timex.weekday |> Schedule.ordinal_week_day_to_atom
    hours = Map.get(schedule.schedule, ordinal) ||  []

    # if we have a period, and force is true, then set the time to the start of the first period available
    # otherwise, use the time supplied
    converted_datetime = if length(hours) > 0 and opts[:force] == true do
                 new_time = hours |> List.first |> List.first
                 BizEx.Time.force_to(converted_datetime, new_time)
               else
                 converted_datetime
               end

    time = DateTime.to_time(converted_datetime)

    current_period = hours
      |> Enum.map(fn x -> 
        if Timex.between?(time, List.first(x), List.last(x), [inclusive: true]) do
          x
        end
    end)
    |> Enum.reject(&is_nil/1)
    |> List.first

    cond do
      is_nil(hours) or holiday?(schedule, converted_datetime) -> 
        now_or_next(schedule, Timex.shift(datetime, days: 1), force: true)

      !is_nil(current_period) and length(current_period) > 0 -> 
        new_date = Timex.Timezone.convert(converted_datetime, datetime.time_zone)
        %{
          date: new_date, 
          starts_at: BizEx.Time.force_to(new_date, List.first(current_period)), 
          ends_at: BizEx.Time.force_to(new_date, List.last(current_period))
        }

      true ->
        next_period = hours
          |> Enum.map(fn x -> 
            start_time = List.first(x)
  
            if Timex.after?(start_time, time) do
              start_time
            end
          end)
          |> Enum.reject(&is_nil/1)

        if is_nil(next_period) or length(next_period) < 1 do
          now_or_next(schedule, Timex.shift(datetime, days: 1), force: true)
        else
          next_period_starts_at = converted_datetime |> BizEx.Time.force_to(List.first(next_period)) |> Timex.Timezone.convert(datetime.time_zone)

          %{
            date: next_period_starts_at, 
            starts_at: next_period_starts_at,
            ends_at: converted_datetime |> BizEx.Time.force_to(List.last(next_period)) |> Timex.Timezone.convert(datetime.time_zone)
          }
        end

    end
  end
  
  # TODO Figure out how to get NaiveDateTime and DateTime implementations to share as much as possible.
  # Current issue, NaiveDateTime can only be converted into a DateTime as Etc/UTC by Elixir
  def now_or_next(%Schedule{} = schedule, %NaiveDateTime{} = datetime, opts) do
    IO.puts "moving forward"
    # Find any list of periods, for the current date
    ordinal = datetime |> Timex.weekday |> Schedule.ordinal_week_day_to_atom
    time = NaiveDateTime.to_time(datetime)
    hours = Map.get(schedule.schedule, ordinal)

    # if we have a period, and force is true, then set the time to the start of the first period available
    # otherwise, use the time supplied
    datetime = if !is_nil(hours) and length(hours) > 0 and opts[:force] == true do
                 new_time = hours |> List.first |> List.first
                 Timex.set(datetime, hour: new_time.hour, minute: new_time.minute, second: new_time.second, microsecond: new_time.microsecond)
               else
                 datetime
               end

    cond do
      is_nil(hours) or holiday?(schedule, datetime) -> 
        now_or_next(schedule, Timex.shift(datetime, days: 1), force: true)

      BizEx.Time.in_set_of_hours?(hours, NaiveDateTime.to_time(datetime)) -> 
        datetime

      true ->
        next_period_starts_at = hours
          |> Enum.map(fn x -> 
            start_time = List.first(x)
  
            if Timex.after?(start_time, time) do
              start_time
            end
          end)
          |> Enum.reject(&is_nil/1)
          |> List.first

        if is_nil(next_period_starts_at) do
          now_or_next(schedule, Timex.shift(datetime, days: 1), force: true)
        else
          Timex.set(datetime, hour: next_period_starts_at.hour, minute: next_period_starts_at.minute, second: next_period_starts_at.second)
        end

    end
  end

  def shift(%Schedule{} = schedule, %DateTime{} = datetime, 0) do
    now_or_next(schedule, datetime)
  end

  def shift(%Schedule{} = schedule, %DateTime{} = datetime, seconds) when seconds > 0 do
    current_period = now_or_next(schedule, datetime)
    raw_shifted = Timex.shift(datetime, seconds: seconds)

    if Timex.after?(raw_shifted, current_period[:ends_at]) do
      remainder = Timex.diff(raw_shifted, current_period[:ends_at], :seconds)

      next_period = now_or_next(schedule, Timex.shift(current_period[:ends_at], seconds: 1))

      shift(schedule, next_period[:starts_at], remainder - 1)
    else
      raw_shifted
    end
  end
  
  def shift(%Schedule{} = schedule, %DateTime{} = datetime, seconds) when seconds < 0 do
    current_period = now_or_prev(schedule, datetime)

    raw_shifted = Timex.shift(datetime, seconds: seconds)

    if Timex.before?(raw_shifted, current_period[:starts_at]) do

      remainder = Timex.diff(raw_shifted, current_period[:starts_at], :seconds)

      IO.puts "moving backwards #{current_period[:starts_at]}, remainder #{remainder}"      

      next_period = now_or_prev(schedule, Timex.shift(current_period[:starts_at], seconds: - 1))

      shift(schedule, next_period[:ends_at], remainder + 1)
   else
      raw_shifted
    end
  end


end


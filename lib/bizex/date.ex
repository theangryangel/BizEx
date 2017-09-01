defmodule BizEx.Date do

  alias BizEx.Schedule

  def working_day?(%Schedule{} = schedule, %DateTime{} = datetime) do
    datetime = Timex.Timezone.convert(datetime, schedule.timezone)

    hours = Schedule.fetch(schedule, DateTime.to_date(datetime))

    if hours != nil and !holiday?(schedule, datetime) do
      time = datetime |> DateTime.to_time()

      BizEx.Time.in_set_of_hours?(hours, time)
    else
      false
    end
  end

  def working_day?(%Schedule{} = schedule, %NaiveDateTime{} = datetime) do
    hours = Schedule.fetch(schedule, NaiveDateTime.to_date(datetime))

    if hours != nil and !holiday?(schedule, datetime) do
      BizEx.Time.in_set_of_hours?(hours, NaiveDateTime.to_time(datetime))
    else
      false
    end
  end

  def working_day?(%Schedule{} = schedule, %Date{} = date)  do
    hours = Schedule.fetch(schedule, date)

    if hours != nil do
      true
    else
      false
    end
  end

  def working_day?(_, _), do: false

  def holiday?(%Schedule{} = schedule, %Date{} = date) do
    Enum.member?(schedule.holidays, date)
  end

  def holiday?(%Schedule{} = schedule, %DateTime{} = datetime) do
    holiday?(schedule, DateTime.to_date(datetime))
  end

  def holiday?(%Schedule{} = schedule, %NaiveDateTime{} = datetime) do
    holiday?(schedule, NaiveDateTime.to_date(datetime))
  end
end


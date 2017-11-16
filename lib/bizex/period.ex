defmodule BizEx.Period do
  @enforce_keys [:start_at, :end_at, :weekday]
  defstruct [:start_at, :end_at, :weekday]

  @type t :: %__MODULE__{
    :start_at => Calendar.Time.t,
    :end_at => Calendar.Time.t
  }

  def between?(%__MODULE__{} = period, %DateTime{} = datetime) do
    (Timex.weekday(datetime) == period.weekday) and (Timex.between?(DateTime.to_time(datetime), period.start_at, period.end_at, inclusive: true))
  end

  def today?(%__MODULE__{} = period, %DateTime{} = datetime) do
    (Timex.weekday(datetime) == period.weekday)
  end

  def after?(%__MODULE__{} = period, %DateTime{} = datetime) do
    today?(period, datetime) and (period.start_at >= DateTime.to_time(datetime))
  end

  def before?(%__MODULE__{} = period, %DateTime{} = datetime) do
    today?(period, datetime) and (period.end_at <= DateTime.to_time(datetime))
  end

  def use_time(%__MODULE__{} = period, %DateTime{} = datetime, :start) do
    Timex.set(datetime, hour: period.start_at.hour, minute: period.start_at.minute, second: period.start_at.second, microsecond: period.start_at.microsecond)
  end

  def use_time(%__MODULE__{} = period, %DateTime{} = datetime, :end) do
    Timex.set(datetime, hour: period.end_at.hour, minute: period.end_at.minute, second: period.end_at.second, microsecond: period.end_at.microsecond)
  end

end



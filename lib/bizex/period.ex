defmodule BizEx.Period do
  @moduledoc """
  Module that 
  """

  @enforce_keys [:start_at, :end_at, :weekday]

  @doc """
  Represents a period of time by start and end time, along with weekday number.

  * :start_at - the starting time (i.e. ~T[09:00:00])
  * :end_at - the end time (i.e. ~T[17:30:00])
  * :weekday - the weekday number (1-7, representing Monday-Sunday. Mirrors Timex.weekday functionality)
  """
  defstruct [:start_at, :end_at, :weekday]

  @type t :: %__MODULE__{
    :start_at => Calendar.Time.t,
    :end_at => Calendar.Time.t,
    :weekday => integer
  }

  @doc """
  For the `period` and `datetime`, do the weekday match?
  """
  def today?(%__MODULE__{} = period, %DateTime{} = datetime) do
    (Timex.weekday(datetime) == period.weekday)
  end

  @doc """
  For the `period` and `datetime`, does the weekday match, and does the time component of the `datetime` sit between (inclusive) 
  the start_at and end_at values?
  """
  def between?(%__MODULE__{} = period, %DateTime{} = datetime) do
    today?(period, datetime) and (Timex.between?(DateTime.to_time(datetime), period.start_at, period.end_at, inclusive: true))
  end

  @doc """
  For the `period` and `datetime`, does the weekday match, and is the time component of the `datetime` after the `period.start_at`? 
  """
  def after?(%__MODULE__{} = period, %DateTime{} = datetime) do
    today?(period, datetime) and (period.start_at >= DateTime.to_time(datetime))
  end

  @doc """
  For the `period` and `datetime`, does the weekday match, and is the time component of the `datetime` before the `period.end_at`? 
  """
  def before?(%__MODULE__{} = period, %DateTime{} = datetime) do
    today?(period, datetime) and (period.end_at <= DateTime.to_time(datetime))
  end

  @doc """
  Overwrite the time for the provided `datetime` using either the `period.start_at` or `period.end_at`
  """
  def use_time(period, datetime, field)

  def use_time(%__MODULE__{} = period, %DateTime{} = datetime, :start) do
    Timex.set(datetime, hour: period.start_at.hour, minute: period.start_at.minute, second: period.start_at.second, microsecond: period.start_at.microsecond)
  end

  def use_time(%__MODULE__{} = period, %DateTime{} = datetime, :end) do
    Timex.set(datetime, hour: period.end_at.hour, minute: period.end_at.minute, second: period.end_at.second, microsecond: period.end_at.microsecond)
  end

end



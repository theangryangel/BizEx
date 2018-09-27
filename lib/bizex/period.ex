defmodule BizEx.Period do
  @moduledoc """
  Module that defines and works with periods of time.
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
    :start_at => Time.t,
    :end_at => Time.t,
    :weekday => 1..7
  }

  @doc """
  For the `period` and `datetime`, do the weekday match?
  """
  @spec today?(t, DateTime.t) :: boolean() 
  def today?(%__MODULE__{} = period, %DateTime{} = datetime) do
    Timex.weekday(datetime) == period.weekday
  end

  @doc """
  For the `period` and `datetime`, does the weekday match, and does the time component of the `datetime` sit between (inclusive) 
  the start_at and end_at values?
  """
  @spec between?(t, DateTime.t) :: boolean
  def between?(%__MODULE__{} = period, %DateTime{} = datetime) do
    with true <- today?(period, datetime),
         time <- DateTime.to_time(datetime),
         true <- time_gte(Time.compare(time, period.start_at)),
         true <- time_lte(Time.compare(time, period.end_at))
    do
      true
    else _ ->
      false
    end
  end

  @doc """
  For the `period` and `datetime`, does the weekday match, and is the time component of the `datetime` after the `period.start_at`? 
  """
  @spec after?(t, DateTime.t) :: boolean
  def after?(%__MODULE__{} = period, %DateTime{} = datetime) do
    today?(period, datetime) and and time_gte(Time.compare(DateTime.to_time(datetime), period.start_at))
  end

  @doc """
  For the `period` and `datetime`, does the weekday match, and is the time component of the `datetime` before the `period.end_at`? 
  """
  @spec before?(t, DateTime.t) :: boolean
  def before?(%__MODULE__{} = period, %DateTime{} = datetime) do
    today?(period, datetime) and time_lte(Time.compare(DateTime.to_time(datetime), period.end_at))
  end

  @doc """
  Overwrite the time for the provided `datetime` using either the `period.start_at` or `period.end_at`
  """
  @spec use_time(t, DateTime.t, atom()) :: Timex.Types.valid_datetime
  def use_time(period, datetime, field)

  def use_time(%__MODULE__{} = period, %DateTime{} = datetime, :start) do
    Timex.set(datetime, hour: period.start_at.hour, minute: period.start_at.minute, second: period.start_at.second, microsecond: period.start_at.microsecond)
  end

  def use_time(%__MODULE__{} = period, %DateTime{} = datetime, :end) do
    Timex.set(datetime, hour: period.end_at.hour, minute: period.end_at.minute, second: period.end_at.second, microsecond: period.end_at.microsecond)
  end
  
  defp time_gte(w) when w in [:gt, :eq], do: true
  defp time_gte(_), do: false
  
  defp time_lte(w) when w in [:lt, :eq], do: true
  defp time_lte(_), do: false
end

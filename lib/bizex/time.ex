defmodule BizEx.Time do
  @moduledoc false

  # Given a set of hours, in the format of [{~T[09:00:00], ~T[17:30:00]}, ...],
  # check if the given time is between any of them
  # If yes, return a tuple of :ok and the time period
  def between_any?(time, periods) when is_list(periods) do
    between_periods = periods
      |> Enum.map(fn x -> 
        if time >= elem(x, 0) and time <= elem(x, 1) do
          x
        end
    end)
    |> Enum.reject(&is_nil/1)
    |> List.last

    if !is_nil(between_periods) and tuple_size(between_periods) == 2 do
      {:ok, between_periods}
    else
      {:error, nil}
    end
  end

  def between_any?(_, _) do
    {:error, nil}
  end

  # Force a datetime to a specific date and time
  def force_to(datetime, time) do
    Timex.set(datetime, hour: time.hour, minute: time.minute, second: time.second, microsecond: time.microsecond)
  end
end

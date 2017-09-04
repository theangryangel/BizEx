defmodule BizEx.Time do
  @moduledoc false

  # Given a set of hours, in the format of [[~T[09:00:00], ~T[17:30:00]], ...],
  # check if the given time is between any of them
  def in_set_of_hours?(hours, %Time{} = time) when is_list(hours) do
    hours
    |> Enum.map(fn x -> 
      Timex.between?(time, List.first(x), List.last(x), [inclusive: true])
    end)
    |> Enum.member?(true)
  end

  def in_set_of_hours?(nil, _), do: false

  def force_to(datetime, time) do
    Timex.set(datetime, hour: time.hour, minute: time.minute, second: time.second, microsecond: time.microsecond)
  end
end

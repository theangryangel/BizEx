defmodule BizEx.Units do
  @defmodule false

  def to_seconds(units) when is_list(units) do
    units
    |> Enum.map(&to_seconds/1)
    |> Enum.reduce(fn(x, acc) -> x + acc end)
  end

  def to_seconds({:days, days}) do
    60 * 60 * 24 * days
  end

  def to_seconds({:hours, hours}) do
    60 * 60 * hours
  end

  def to_seconds({:minutes, minutes}) do
    60 * minutes
  end

  def to_seconds({:seconds, seconds}), do: seconds

  def to_seconds({unsupported_unit, _}), do: raise("Unsupported units (#{unsupported_unit})!")

end

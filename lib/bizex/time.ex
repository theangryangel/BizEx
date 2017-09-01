defmodule BizEx.Time do

  @doc """
  """
  def in_set_of_hours?(hours, %Time{} = time) do
    hours
    |> Enum.map(fn x -> 
      Timex.between?(time, List.first(x), List.last(x), [inclusive: true])
    end)
    |> Enum.member?(true)
  end

end

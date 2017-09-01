defmodule BizEx do
  @moduledoc """
  Documentation for BizEx.
  """

  @doc """
  Is a given date, or datetime, a working day?
  """
  def working_day?(datetime) do
    BizEx.Schedule.load()
    |> BizEx.Date.working_day?(datetime)
  end

  @doc """
  Is a given date, or datetime, a holiday?
  """
  def holiday?(datetime) do
    BizEx.Schedule.load()
    |> BizEx.Date.holiday?(datetime)
  end

  @doc """
  Adds hours, minutes, seconds, etc. to a date, working time only
  """
  def shift(_datetime, _params) do
    # TODO
    "Moving on up. Moving on out. Time to break free. Love ain't gonna stop me."
  end
end

defmodule BizEx do
  @moduledoc """
  Documentation for BizEx.
  """

  @doc """
  Is a given date, or datetime, a working day?
  """
  def working?(datetime) do
    BizEx.Schedule.load()
    |> BizEx.Date.working?(datetime)
  end

  @doc """
  Is a given date, or datetime, a holiday?
  """
  def holiday?(datetime) do
    BizEx.Schedule.load()
    |> BizEx.Date.holiday?(datetime)
  end

  @doc """
  Is a given date, or datetime, a working day?
  """
  def now_or_next(datetime) do
    BizEx.Schedule.load()
    |> BizEx.Date.now_or_next(datetime)
  end

  @doc """
  Adds hours, minutes, seconds, etc. to a date, working time only
  """
  def shift(datetime, %{ seconds: seconds }) do
    BizEx.Schedule.load()
    |> BizEx.Date.shift(datetime, seconds)

    # TODO
    #"Moving on up. Moving on out. Time to break free. Love ain't gonna stop me."
  end
end

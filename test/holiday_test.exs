defmodule BizExHoldayTest do
  use ExUnit.Case
  doctest BizEx

  test "Christmas should be a holiday" do
    assert true == BizEx.holiday?(BizEx.Schedule.default(), ~D[2017-12-25])
  end

end

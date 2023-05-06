defmodule BizExUnitsTest do
  use ExUnit.Case
  doctest BizEx

  test "1 minute = 60 seconds" do
    assert BizEx.Units.to_seconds(minutes: 1) == 60
  end

  test "1 hour = 3600 seconds" do
    assert BizEx.Units.to_seconds(hours: 1) == 3600
  end

  test "1 day = 86400 seconds" do
    assert BizEx.Units.to_seconds(days: 1) == 86_400
  end

  test "1d1h = 90000 seconds" do
    assert BizEx.Units.to_seconds(days: 1, hours: 1) == 90_000
  end
end

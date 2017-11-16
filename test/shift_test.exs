defmodule BizExShiftTest do
  use ExUnit.Case
  doctest BizEx

  test "Shift 1 hour, in hours" do
    {:ok, current_dt} = Timex.parse("2017-11-16T09:00:00+00:00", "{ISO:Extended}")
    {:ok, wanted_dt} = Timex.parse("2017-11-16T10:00:00+00:00", "{ISO:Extended}")

    assert wanted_dt == BizEx.shift(BizEx.Schedule.default(), current_dt, hours: 1)
  end

  test "Shift 1 hour, out of hours" do
    {:ok, current_dt} = Timex.parse("2017-11-16T17:30:00+00:00", "{ISO:Extended}")
    {:ok, wanted_dt} = Timex.parse("2017-11-17T10:00:00+00:00", "{ISO:Extended}")

    assert wanted_dt == BizEx.shift(BizEx.Schedule.default(), current_dt, hours: 1)
  end

  test "Shift 1 hour, out of hours, traversing multiple days" do
    {:ok, current_dt} = Timex.parse("2017-11-18T17:30:00+00:00", "{ISO:Extended}")
    {:ok, wanted_dt} = Timex.parse("2017-11-20T10:00:00+00:00", "{ISO:Extended}")

    assert wanted_dt == BizEx.shift(BizEx.Schedule.default(), current_dt, hours: 1)
  end

  test "Shift -1 hour, in hours" do
    {:ok, current_dt} = Timex.parse("2017-11-16T10:00:00+00:00", "{ISO:Extended}")
    {:ok, wanted_dt} = Timex.parse("2017-11-16T09:00:00+00:00", "{ISO:Extended}")

    assert wanted_dt == BizEx.shift(BizEx.Schedule.default(), current_dt, hours: -1)
  end

  test "Shift -1 hour, out of hours" do
    {:ok, current_dt} = Timex.parse("2017-11-16T17:30:00+00:00", "{ISO:Extended}")
    {:ok, wanted_dt} = Timex.parse("2017-11-16T16:30:00+00:00", "{ISO:Extended}")

    assert wanted_dt == BizEx.shift(BizEx.Schedule.default(), current_dt, hours: -1)
  end

  test "Shift -1 hour, out of hours, traversing multiple days" do
    {:ok, current_dt} = Timex.parse("2017-11-18T17:30:00+00:00", "{ISO:Extended}")
    {:ok, wanted_dt} = Timex.parse("2017-11-17T16:30:00+00:00", "{ISO:Extended}")

    assert wanted_dt == BizEx.shift(BizEx.Schedule.default(), current_dt, hours: -1)
  end

  test "Shift 1 hour, on a holiday" do
    {:ok, current_dt, tz} = DateTime.from_iso8601("2017-12-25T16:50:00Z")
    {:ok, wanted_dt} = Timex.parse("2017-12-26T10:00:00Z:00+00:00", "{ISO:Extended}")

    assert wanted_dt == BizEx.shift(BizEx.Schedule.default(), current_dt, hours: 1)
  end

  test "Shift -1 hour, on a holiday" do
    {:ok, current_dt, tz} = DateTime.from_iso8601("2017-12-25T16:50:00Z")
    {:ok, wanted_dt} = Timex.parse("2017-12-22T16:30:00Z:00+00:00", "{ISO:Extended}")

    assert wanted_dt == BizEx.shift(BizEx.Schedule.default(), current_dt, hours: -1)
  end


end

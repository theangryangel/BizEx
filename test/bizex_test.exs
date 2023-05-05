defmodule BizExTest do
  use ExUnit.Case
  doctest BizEx

  setup_all do
    schedule =
      %BizEx.Schedule{}
      |> BizEx.Schedule.set_timezone("Etc/UTC")
      |> BizEx.Schedule.add_period(~T[09:00:00], ~T[12:30:00], :mon)
      |> BizEx.Schedule.add_period(~T[13:00:00], ~T[17:30:00], :mon)
      |> BizEx.Schedule.add_period(~T[09:00:00], ~T[17:30:00], :tue)
      |> BizEx.Schedule.add_period(~T[09:00:00], ~T[17:30:00], :wed)
      |> BizEx.Schedule.add_period(~T[09:00:00], ~T[17:30:00], :thu)
      |> BizEx.Schedule.add_period(~T[09:00:00], ~T[17:30:00], :fri)
      |> BizEx.Schedule.add_holiday(~D[2018-12-25])
      |> BizEx.Schedule.add_holiday(~D[2017-12-25])

    [
      schedule: schedule,
      xmas: ~D[2018-12-25],
      weekend: [~D[2018-12-08], ~D[2018-12-09]]
    ]
  end

  test "Get working periods for Christmas Day 2018", ctx do
    assert [] == BizEx.working_periods_for(ctx[:schedule], ctx[:xmas])

    assert [
             %BizEx.Period{end_at: ~T[12:30:00], start_at: ~T[09:00:00], weekday: 1},
             %BizEx.Period{end_at: ~T[17:30:00], start_at: ~T[13:00:00], weekday: 1}
           ] == BizEx.working_periods_for(ctx[:schedule], ~D[2018-12-24])
  end

  test "Christmas Day 2018 is a holiday? and is not working?", ctx do
    assert true == BizEx.holiday?(ctx[:schedule], ctx[:xmas])
    assert false == BizEx.working?(ctx[:schedule], ctx[:xmas])

    assert {:error, "not in hours"} == BizEx.current_working_period(ctx[:schedule], ctx[:xmas])
  end

  test "Christmas Eve 2018 is not a holiday? and is working?", ctx do
    xmas_eve = Timex.shift(ctx[:xmas], days: -1)

    assert false == BizEx.holiday?(ctx[:schedule], xmas_eve)
    assert true == BizEx.working?(ctx[:schedule], xmas_eve)

    xmas_eve_9am =
      xmas_eve
      |> Timex.to_datetime()
      |> Timex.set(hour: 9)

    expected_start_at = Timex.parse!("2018-12-24T09:00:00Z", "{ISO:Extended}")
    expected_end_at = Timex.parse!("2018-12-24T12:30:00Z", "{ISO:Extended}")

    assert {:ok, expected_start_at, expected_end_at} ==
             BizEx.current_working_period(ctx[:schedule], xmas_eve_9am)
  end

  test "Check Saturday and Sunday are not holiday? and are not working?", ctx do
    Enum.each(ctx[:weekend], fn date ->
      assert false == BizEx.holiday?(ctx[:schedule], date)
      assert false == BizEx.working?(ctx[:schedule], date)
    end)
  end

  test "Get next working hours after Christmas Day 2018", ctx do
    expected_start_at = Timex.parse!("2018-12-26T09:00:00Z", "{ISO:Extended}")
    expected_end_at = Timex.parse!("2018-12-26T17:30:00Z", "{ISO:Extended}")

    assert {:ok, expected_start_at, expected_end_at} ==
             BizEx.next_working_period(ctx[:schedule], ctx[:xmas])
  end

  test "Get next working hours after 2018-12-24T09:00:00Z", ctx do
    expected_start_at = Timex.parse!("2018-12-24T13:00:00Z", "{ISO:Extended}")
    expected_end_at = Timex.parse!("2018-12-24T17:30:00Z", "{ISO:Extended}")

    assert {:ok, expected_start_at, expected_end_at} ==
             BizEx.next_working_period(
               ctx[:schedule],
               Timex.parse!("2018-12-24T10:30:00Z", "{ISO:Extended}")
             )
  end

  test "Get previous working hours before 2018-12-24T17:45:00Z", ctx do
    expected_start_at = Timex.parse!("2018-12-24T13:00:00Z", "{ISO:Extended}")
    expected_end_at = Timex.parse!("2018-12-24T17:30:00Z", "{ISO:Extended}")

    assert {:ok, expected_start_at, expected_end_at} ==
             BizEx.previous_working_period(
               ctx[:schedule],
               Timex.parse!("2018-12-24T17:45:00Z", "{ISO:Extended}")
             )
  end

  test "Get previous working hours before 2018-12-24T17:25:00Z", ctx do
    expected_start_at = Timex.parse!("2018-12-24T09:00:00Z", "{ISO:Extended}")
    expected_end_at = Timex.parse!("2018-12-24T12:30:00Z", "{ISO:Extended}")

    assert {:ok, expected_start_at, expected_end_at} ==
             BizEx.previous_working_period(
               ctx[:schedule],
               Timex.parse!("2018-12-24T17:25:00Z", "{ISO:Extended}")
             )
  end

  test "Get previous working hours before 2018-12-24T12:20:00Z", ctx do
    expected_start_at = Timex.parse!("2018-12-21T09:00:00Z", "{ISO:Extended}")
    expected_end_at = Timex.parse!("2018-12-21T17:30:00Z", "{ISO:Extended}")

    assert {:ok, expected_start_at, expected_end_at} ==
             BizEx.previous_working_period(
               ctx[:schedule],
               Timex.parse!("2018-12-24T12:20:00Z", "{ISO:Extended}")
             )
  end

  test "Diff in hours, on a working day", ctx do
    assert {:ok, -600} ==
             BizEx.diff(
               ctx[:schedule],
               Timex.parse!("2018-12-24T17:20Z", "{ISO:Extended}"),
               Timex.parse!("2018-12-24T17:30Z", "{ISO:Extended}")
             )
  end

  test "Diff crossing a non-working day", ctx do
    assert {:ok, -30600} ==
             BizEx.diff(
               ctx[:schedule],
               Timex.parse!("2018-12-25T17:20Z", "{ISO:Extended}"),
               Timex.parse!("2018-12-26T17:35Z", "{ISO:Extended}")
             )
  end

  test "Diff on same day, both out of hours ", ctx do
    assert {:ok, 0} ==
             BizEx.diff(
               ctx[:schedule],
               Timex.parse!("2018-12-25T17:20Z", "{ISO:Extended}"),
               Timex.parse!("2018-12-25T17:20Z", "{ISO:Extended}")
             )
  end

  test "Shift 1 hour, in hours", ctx do
    {:ok, current_dt} = Timex.parse("2017-11-16T09:00:00+00:00", "{ISO:Extended}")
    {:ok, wanted_dt} = Timex.parse("2017-11-16T10:00:00+00:00", "{ISO:Extended}")

    assert {:ok, wanted_dt} == BizEx.shift(ctx[:schedule], current_dt, hours: 1)
  end

  test "Shift 1 hour, out of hours", ctx do
    {:ok, current_dt} = Timex.parse("2017-11-16T17:30:00+00:00", "{ISO:Extended}")
    {:ok, wanted_dt} = Timex.parse("2017-11-17T10:00:00+00:00", "{ISO:Extended}")

    assert {:ok, wanted_dt} == BizEx.shift(ctx[:schedule], current_dt, hours: 1)
  end

  test "Shift 1 hour, out of hours, traversing multiple days", ctx do
    {:ok, current_dt} = Timex.parse("2017-11-18T17:30:00+00:00", "{ISO:Extended}")
    {:ok, wanted_dt} = Timex.parse("2017-11-20T10:00:00+00:00", "{ISO:Extended}")

    assert {:ok, wanted_dt} == BizEx.shift(ctx[:schedule], current_dt, hours: 1)
  end

  test "Shift -1 hour, in hours", ctx do
    {:ok, current_dt} = Timex.parse("2017-11-16T10:00:00+00:00", "{ISO:Extended}")
    {:ok, wanted_dt} = Timex.parse("2017-11-16T09:00:00+00:00", "{ISO:Extended}")

    assert {:ok, wanted_dt} == BizEx.shift(ctx[:schedule], current_dt, hours: -1)
  end

  test "Shift -1 hour, out of hours", ctx do
    {:ok, current_dt} = Timex.parse("2017-11-16T17:30:00+00:00", "{ISO:Extended}")
    {:ok, wanted_dt} = Timex.parse("2017-11-16T16:30:00+00:00", "{ISO:Extended}")

    assert {:ok, wanted_dt} == BizEx.shift(ctx[:schedule], current_dt, hours: -1)
  end

  test "Shift -1 hour, out of hours, traversing multiple days", ctx do
    {:ok, current_dt} = Timex.parse("2017-11-18T17:30:00+00:00", "{ISO:Extended}")
    {:ok, wanted_dt} = Timex.parse("2017-11-17T16:30:00+00:00", "{ISO:Extended}")

    assert {:ok, wanted_dt} == BizEx.shift(ctx[:schedule], current_dt, hours: -1)
  end

  test "Shift 1 hour, on a holiday", ctx do
    {:ok, current_dt, _tz} = DateTime.from_iso8601("2017-12-25T16:50:00Z")
    {:ok, wanted_dt} = Timex.parse("2017-12-26T10:00:00Z:00+00:00", "{ISO:Extended}")

    assert {:ok, wanted_dt} == BizEx.shift(ctx[:schedule], current_dt, hours: 1)
  end

  test "Shift -1 hour, on a holiday", ctx do
    {:ok, current_dt, _tz} = DateTime.from_iso8601("2017-12-25T16:50:00.00Z")
    {:ok, wanted_dt} = Timex.parse("2017-12-22T16:30:00Z:00+00:00", "{ISO:Extended}")

    assert {:ok, wanted_dt} == BizEx.shift(ctx[:schedule], current_dt, hours: -1)
  end
end

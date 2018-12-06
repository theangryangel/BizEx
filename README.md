# BizEx

[![Build Status](https://travis-ci.org/theangryangel/BizEx.svg?branch=master)](https://travis-ci.org/theangryangel/BizEx)

Work in Progress. Incomplete. API not stable. Minimal documentation. May contain bugs. Help wanted, etc.

**You have been warned.**

Adds business hours to a provided datetime, based on a schedule. 
i.e. if your business is open 9-5, and you add 1 hour after 5, you'll end up with a time the next working day at 10.

Inspired by [Biz](https://github.com/zendesk/biz), [business_time](https://github.com/bokmann/business_time), [working_hours](https://github.com/Intrepidd/working_hours).

## Supports;
  * Shifting time by days, hours, minutes and seconds
  * Multiple time periods per-day
  * Manually defined holidays

## Known Issues
  * There are assumptions based on the schedule order. If you do not use the `BizEx.Schedule.add_*` functions behaviour may not be defined
  * Missing tests
  * Shifting of time is not leap second aware (sorry for my purposes I just really dont need to engineer this in)
  * Minimal module docs - still being worked on
  * Shifting long periods of time may be slow

## Getting Started

### Installation

```elixir
def deps do
  [{:bizex, git: "https://github.com/theangryangel/BizEx.git"}]
end
```

Then, update your dependencies:

```sh-session
$ mix deps.get
```

### Quick introduction

```elixir
# Create a datetime for us to work with
{:ok, dt, tz} = DateTime.from_iso8601("2017-11-16T16:50:00Z")
#=> {:ok, #DateTime<2017-11-16 16:50:00Z>, 0}

# Get a copy of the bundled default schedule
schedule = BizEx.Schedule.default()

# Add 1 working hour to the date time from above, using the default schedule
BizEx.shift(schedule, dt, hours: 1)
#=> #DateTime<2017-11-17 09:20:00Z>

# Creating and using a custom defined schedule, rather than the default schedule
schedule = %BizEx.Schedule{}
  |> BizEx.Schedule.set_timezone("Europe/London")
  |> BizEx.Schedule.add_period(~T[09:00:00], ~T[17:30:00], :mon)
  |> BizEx.Schedule.add_period(~T[09:00:00], ~T[17:30:00], :tue)
  |> BizEx.Schedule.add_period(~T[09:00:00], ~T[17:30:00], :wed)
  |> BizEx.Schedule.add_period(~T[09:00:00], ~T[17:30:00], :thu)
  |> BizEx.Schedule.add_period(~T[09:00:00], ~T[17:30:00], :fri)
  |> BizEx.Schedule.add_holiday(~D[2017-12-25])

BizEx.shift(schedule, dt, hours: 1)
#=> #DateTime<2017-11-17 09:20:00Z>

# This is an out of hours time! Our schedule says we end at 17:30
{:ok, dt2, tz} = DateTime.from_iso8601("2017-11-16T17:50:00Z")

# Since the schedule ends at 17:30, we end up with 40 minutes or 2400 seconds between 16:50 and 17:30, rather than 1 hour
BizEx.diff(schedule, dt2, dt)
#=> 2400

```

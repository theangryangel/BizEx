# BizEx

:warning: Minimal documentation. Works for Me(TM). May contain bugs. PR always appreciated, etc. **You have been warned.**

A simple and small library that assists with time calculations using business/working hours.

Inspired by [Biz](https://github.com/zendesk/biz), [business_time](https://github.com/bokmann/business_time) and [working_hours](https://github.com/Intrepidd/working_hours).

## Support:
  * Multiple intervals/periods per-day
  * As many schedules as you want (the first parameter to every public function is your schedule)
  * Holidays (manually defined at present)
  * Diffing and shifting time by working days, hours, minutes and seconds
  * Timezone handling (datetimes passed to the public functions are are converted to the schedule timezone and then back for return values)
  * Second-level calculation precision

## Known Issues
  * Minimal docs - will be updated shortly
  * Performance is not guaranteed - shift'ing or diff'ing over longer distances maybe slow depending on your schedule complexity

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
#=> {:ok, #DateTime<2017-11-17 09:20:00Z>}

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
#=> {:ok, #DateTime<2017-11-17 09:20:00Z>}

# This is an out of hours time! Our schedule says we end at 17:30
{:ok, dt2, tz} = DateTime.from_iso8601("2017-11-16T17:50:00Z")

# Since the schedule ends at 17:30, we end up with 40 minutes or 2400 seconds between 16:50 and 17:30, rather than 1 hour
BizEx.diff(schedule, dt2, dt)
#=> {:ok, 2400}

```

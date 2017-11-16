# BizEx

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
  * There are assumptions based on the schedule order. This will be addressed before "1.0".
  * Shifting of time is not leap second aware (sorry for my purposes I just really dont need to engineer this in)
  * No module docs (yet)

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

# Using the bundled default schedule, add 1 working hour to that date time.

BizEx.shift(BizEx.Schedule.default(), dt, hours: 1)
#=> #DateTime<2017-11-17 09:20:00Z>

# TODO Demonstrate custom schedule creation after validation has been sorted

```

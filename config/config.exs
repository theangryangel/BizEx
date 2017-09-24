# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
config :bizex, :schedule, %{
  mon: [{~T[09:00:00], ~T[12:30:00]}, {~T[13:00:00], ~T[17:30:00]}],
  tue: [{~T[09:00:00], ~T[17:30:00]}],
  wed: [{~T[09:00:00], ~T[17:30:00]}],
  thu: [{~T[09:00:00], ~T[17:30:00]}],
  fri: [{~T[09:00:00], ~T[17:30:00]}],
}

config :bizex, :schedule_timezone, "Europe/London"

config :bizex, :holidays, [
  ~D[2017-09-01],
  ~D[2017-10-01],
  ~D[2017-09-01],
  ~D[2017-12-25]
]
#
# and access this configuration in your application as:
#
#     Application.get_env(:bizex, :key)
#
# You can also configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"

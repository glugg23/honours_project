import Config

config :logger, :console, format: "$time [$level] $levelpad$metadata$message\n"

config :os_mon, start_disksup: false, start_memsup: false

import_config "#{System.get_env("EXPERIMENT", "default")}.exs"

import_config "#{config_env()}.exs"

import Config

config :logger, :console, format: "$time [$level] $levelpad$metadata$message\n"

import_config "#{System.get_env("EXPERIMENT", "default")}.exs"

import_config "#{config_env()}.exs"

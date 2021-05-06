import Config

config :logger,
  backends: [:console],
  level: :notice,
  compile_time_purge_matching: [
    [level_lower_than: :notice]
  ]

import Config

config :logger,
  backends: [:console],
  level: :notice,
  compile_time_purge_matching: [
    [level_lower_than: :notice],
    [module: SupplyChain.Knowledge.Server, level_lower_than: :error],
    [module: SupplyChain.Behaviour.Server, level_lower_than: :error]
  ]

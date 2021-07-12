import Config

config :supply_chain, :clock,
  type: :clock,
  information_filter: [],
  agent_count: 3,
  max_rounds: 220,
  automatic?: true

config :supply_chain, :manufacturer,
  type: :manufacturer,
  information_filter: [],
  total_storage: 100,
  production_capacity: 50,
  price_per_unit: 100,
  production_cost: 50

config :supply_chain, :consumer,
  type: :consumer,
  information_filter: [:producer],
  maximum_demand: 25,
  price_per_unit: 100

config :supply_chain, :producer,
  type: :producer,
  information_filter: [:consumer, :producer],
  total_storage: 100,
  production_capacity: 50,
  price_per_unit: 100,
  production_cost: 50

config :supply_chain, :agent_types, [:clock, :manufacturer, :consumer, :producer]

config :logger, :console, format: "$time [$level] $levelpad$metadata$message\n"

import_config "#{config_env()}.exs"

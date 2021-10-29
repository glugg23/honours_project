import Config

config :supply_chain, :common,
  components: [cpu: 1000, motherboard: 250],
  computers: [computer: 1250],
  recipes: [computer: [cpu: 1, motherboard: 1]]

config :supply_chain, :clock,
  type: :clock,
  information_filter: [],
  agent_count: 6,
  max_rounds: 220,
  automatic?: true

config :supply_chain, :manufacturer,
  type: :manufacturer,
  information_filter: [],
  production_capacity: 2000,
  producer_capacity: 550

config :supply_chain, :consumer,
  type: :consumer,
  information_filter: [:producer]

config :supply_chain, :producer,
  type: :producer,
  information_filter: [:consumer, :producer],
  production_capacity: 550

config :supply_chain, :cpu, produces: :cpu

config :supply_chain, :motherboard, produces: :motherboard

config :supply_chain, :agent_types, [:clock, :manufacturer, :consumer, :producer]
config :supply_chain, :sub_types, [:cpu, :motherboard]

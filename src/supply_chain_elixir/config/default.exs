import Config

config :supply_chain, :common,
  components: [good: 1650],
  computers: [computer: 1650],
  recipes: [%{requires: [good: 1], produces: :computer}]

config :supply_chain, :clock,
  type: :clock,
  information_filter: [],
  agent_count: 3,
  max_rounds: 220,
  automatic?: true

config :supply_chain, :manufacturer,
  type: :manufacturer,
  information_filter: [],
  production_capacity: 2000

config :supply_chain, :consumer,
  type: :consumer,
  information_filter: [:producer]

config :supply_chain, :producer,
  type: :producer,
  information_filter: [:consumer, :producer],
  produces: :good,
  production_capacity: 550

config :supply_chain, :agent_types, [:clock, :manufacturer, :consumer, :producer]

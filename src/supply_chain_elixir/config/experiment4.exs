import Config

config :supply_chain, :common,
  components: [
    cpu_slow: 1000,
    cpu_fast: 1500,
    memory_small: 100,
    memory_large: 200,
    motherboard: 250,
    hard_drive: 400
  ],
  computers: [computer_cheap: 1750, computer_expensive: 2350],
  recipes: [
    computer_cheap: [cpu_slow: 1, memory_small: 1, motherboard: 1, hard_drive: 1],
    computer_expensive: [cpu_fast: 1, memory_large: 1, motherboard: 1, hard_drive: 1]
  ]

config :supply_chain, :clock,
  type: :clock,
  information_filter: [],
  agent_count: 10,
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

config :supply_chain, :cpu_slow, produces: :cpu_slow
config :supply_chain, :cpu_fast, produces: :cpu_fast

config :supply_chain, :memory_small, produces: :memory_small
config :supply_chain, :memory_large, produces: :memory_large

config :supply_chain, :motherboard, produces: :motherboard

config :supply_chain, :hard_drive, produces: :hard_drive

config :supply_chain, :agent_types, [:clock, :manufacturer, :consumer, :producer]

config :supply_chain, :sub_types, [
  :cpu_slow,
  :cpu_fast,
  :memory_small,
  :memory_large,
  :motherboard,
  :hard_drive
]

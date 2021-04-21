import Config

config :supply_chain, :manufacturer,
  type: :manufacturer,
  information_filter: []

config :supply_chain, :consumer,
  type: :consumer,
  information_filter: [:producer]

config :supply_chain, :producer,
  type: :producer,
  information_filter: [:consumer, :producer]

config :supply_chain, :agent_types, [:manufacturer, :consumer, :producer]

import_config "#{config_env()}.exs"

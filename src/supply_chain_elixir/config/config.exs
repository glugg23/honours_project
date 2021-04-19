import Config

config :supply_chain, :manufacturer, type: :manufacturer

config :supply_chain, :consumer, type: :consumer

config :supply_chain, :producer, type: :producer

config :supply_chain, :agent_types, [:manufacturer, :consumer, :producer]

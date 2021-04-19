defmodule SupplyChain.Knowledge.Server do
  @moduledoc false

  require Logger

  use GenServer

  def init(_args) do
    type = System.get_env("AGENT_TYPE") |> match_config_type()
    state = [config: Application.get_env(:supply_chain, type)]
    {:ok, state}
  end

  def handle_call(:get_config, _from, state) do
    {:reply, state[:config], state}
  end

  defp match_config_type(string) do
    case string do
      "agent" ->
        Agent

      _ ->
        Logger.critical("Invalid string #{string} for AGENT_TYPE environment variable")
        System.stop(1)
    end
  end
end

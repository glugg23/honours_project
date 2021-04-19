defmodule SupplyChain.Knowledge.Server do
  @moduledoc false

  use GenServer

  def init(_args) do
    state = [config: Application.get_env(:supply_chain, Agent)]
    {:ok, state}
  end

  def handle_call(:get_config, _from, state) do
    {:reply, state[:config], state}
  end
end

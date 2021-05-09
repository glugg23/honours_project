defmodule SupplyChain.Knowledge.Server do
  @moduledoc false

  require Logger

  use GenServer

  def init(type) do
    state = %{config: Application.get_env(:supply_chain, type)}
    {:ok, state}
  end

  def handle_call(:get_config, _from, state) do
    {:reply, state.config, state}
  end

  def handle_call(:ready?, _from, state) do
    {:reply, true, state}
  end
end

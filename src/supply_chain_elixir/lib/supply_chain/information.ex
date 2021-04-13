defmodule SupplyChain.Information do
  @moduledoc """
  The Information layer for the agent.
  It handles receiving all the data from other agents and filtering it according to the Knowledge layer.
  """

  def child_spec(arg) do
    %{
      id: SupplyChain.Information,
      start: {SupplyChain.Information, :start_link, [arg]}
    }
  end

  def start_link(args) do
    GenServer.start_link(SupplyChain.Information.Server, args, name: __MODULE__)
  end

  def info(layer) do
    GenServer.call(layer, :info)
  end
end

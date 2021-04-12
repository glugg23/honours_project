defmodule SupplyChain.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    topologies = [
      gossip: [
        strategy: Cluster.Strategy.Gossip
      ]
    ]

    children = [
      {Cluster.Supervisor, [topologies, [name: SupplyChain.ClusterSupervisor]]}
    ]

    opts = [strategy: :one_for_one, name: SupplyChain.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

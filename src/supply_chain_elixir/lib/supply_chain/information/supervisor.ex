defmodule SupplyChain.Information.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    children = [
      SupplyChain.Information,
      SupplyChain.Information.HeartBeat,
      {Task.Supervisor, name: SupplyChain.Information.TaskSupervisor}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

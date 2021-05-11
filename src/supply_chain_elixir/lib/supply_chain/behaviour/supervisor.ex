defmodule SupplyChain.Behaviour.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    config = SupplyChain.Knowledge.get_config()

    children = [
      {SupplyChain.Behaviour, config},
      {Task.Supervisor, name: SupplyChain.Behaviour.TaskSupervisor}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end

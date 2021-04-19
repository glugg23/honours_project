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
    type = String.to_atom(string)
    valid_types = Application.get_env(:supply_chain, :agent_types)

    if type not in valid_types do
      Logger.critical(
        "\"#{string}\" is invalid for AGENT_TYPE, use one of #{
          inspect(valid_types |> Enum.map(&to_string/1))
        }"
      )

      System.stop(1)
    end

    type
  end
end

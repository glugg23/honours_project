defmodule SupplyChain.Knowledge.Server do
  @moduledoc false

  require Logger

  use GenServer

  def init(_args) do
    type =
      Application.get_env(:supply_chain, :agent_type) ||
        case System.fetch_env("AGENT_TYPE") do
          {:ok, string} ->
            match_config_type(string)

          :error ->
            Logger.critical(
              "AGENT_TYPE is not set, use one of #{
                inspect(
                  Application.get_env(:supply_chain, :agent_types)
                  |> Enum.map(&to_string/1)
                )
              }"
            )

            System.stop(1)
        end

    state = %{config: Application.get_env(:supply_chain, type)}
    {:ok, state}
  end

  def handle_call(:get_config, _from, state) do
    {:reply, state.config, state}
  end

  def handle_call(:ready?, _from, state) do
    {:reply, true, state}
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

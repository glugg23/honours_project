-module(hello_agent_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    hello_agent_sup:start_link().

stop(_State) ->
    ok.

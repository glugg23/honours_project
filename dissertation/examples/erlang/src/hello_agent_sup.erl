-module(hello_agent_sup).

-behaviour(supervisor).

-export([start_link/0, init/1]).

-record(state, {name, count, discovery}).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    SupFlags = #{strategy => one_for_all},
    ChildSpecs =
        [#{id => counter,
           start =>
               {hello_agent_counter,
                start_link,
                [#state{name = "COUNTER",
                        count = 0,
                        discovery = nil}]},
           restart => transient},
         #{id => partner,
           start => {hello_agent_partner, start_link, ["PARTNER"]},
           restart => transient}],
    {ok, {SupFlags, ChildSpecs}}.

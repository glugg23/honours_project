-module(hello_agent_partner).

-behaviour(gen_server).

-export([start_link/1, init/1, hello/0, die/0, handle_call/3, handle_cast/2]).

-record(state, {name}).

start_link(Args) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, Args, []).

init(Name) ->
    logger:notice("[~s] Starting", [Name]),
    {ok, #state{name = Name}}.

hello() ->
    gen_server:call(?MODULE, hello).

die() ->
    gen_server:cast(?MODULE, die).

handle_call(hello, _From, State) ->
    logger:notice("[~s] Say hello!", [State#state.name]),
    {reply, self(), State}.

handle_cast(die, State) ->
    logger:notice("[~s] is dying", [State#state.name]),
    {stop, normal, State}.

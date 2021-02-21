-module(hello_agent_counter).

-behaviour(gen_server).

-export([start_link/1, init/1, handle_call/3, handle_cast/2, handle_info/2]).

-record(state, {name, count, discovery}).

start_link(Args) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, Args, []).

init(Args) ->
    logger:notice("[~s] Starting", [Args#state.name]),
    {ok, Ref} = timer:send_interval(1_000, self(), hello),
    ArgsInterval = Args#state{discovery = Ref},
    {ok, ArgsInterval}.

handle_info(hello, State) ->
    Pid = hello_agent_partner:hello(),

    if pid =/= nil ->
           {ok, cancel} = timer:cancel(State#state.discovery),
           logger:notice("[~s] found another agent ~p", [State#state.name, Pid]),
           logger:notice("[~s] I'm ~p", [State#state.name, self()]),

           logger:notice("[~s] Starting to count", [State#state.name]),
           ?MODULE ! count
    end,

    {noreply, State};

handle_info(count, State) ->
    logger:notice("[~s] count => ~w", [State#state.name, State#state.count]),

    if State#state.count == 3 ->
           logger:notice("[~s] orders Partner to die", [State#state.name]),
           hello_agent_partner:die(),
           {stop, normal, State};
       true ->
           timer:send_after(1_000, ?MODULE, count),
           {noreply, State#state{count = State#state.count + 1}}
    end.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

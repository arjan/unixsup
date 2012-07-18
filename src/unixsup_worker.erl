-module(unixsup_worker).
-behaviour(gen_server).

-define(DEFAULT_RESTART_TIMEOUT, 3000).

-record(state, {identifier, executable, args, dir, port=undefined, timeout=?DEFAULT_RESTART_TIMEOUT}).

%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

-export([start_link/3, start_link/4]).

%% ------------------------------------------------------------------
%% gen_server Function Exports
%% ------------------------------------------------------------------

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

%% ------------------------------------------------------------------
%% API Function Definitions
%% ------------------------------------------------------------------

start_link(Identifier, Executable, Args) when is_atom(Identifier) ->
    {ok, Dir} = file:get_cwd(),
    start_link(Identifier, Executable, Args, Dir).
start_link(Identifier, Executable, Args, Dir) when is_atom(Identifier) ->
    gen_server:start_link({local, Identifier}, ?MODULE, [Identifier, Executable, Args, Dir], []).

%% ------------------------------------------------------------------
%% gen_server Function Definitions
%% ------------------------------------------------------------------

init([Identifier, Executable, Args, Dir]) ->
    {ok, #state{identifier=Identifier,
                executable=Executable,
                args=Args,
                dir=Dir}, 0}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(timeout, State) ->
    lager:info("Restarting unixsup worker, ~p", [State#state.executable]),
    {noreply, restart_worker(State)};

handle_info({Port, {exit_status, _N}}, State=#state{port=Port, timeout=T}) ->
    lager:warning("_N: ~p", [_N]),
    {noreply, State, T};

handle_info({Port, {data, {eol, Line}}}, State=#state{port=Port, identifier=Id}) ->
    lager:info([{unixsup, Id}], "[~s] ~s", [Id, Line]), 
    {noreply, State};

handle_info(_Info, State) ->
    lager:warning("Unhandled message: ~p", [_Info]),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------


restart_worker(State) ->
    Port = erlang:open_port({spawn_executable, State#state.executable}, 
                            [{args, State#state.args}, {cd, State#state.dir}, {line, 1024}, stderr_to_stdout, exit_status]),
    State#state{port=Port}.

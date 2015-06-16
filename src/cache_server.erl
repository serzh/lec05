%%%-------------------------------------------------------------------
%%% @author serzh
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. Jun 2015 21:12
%%%-------------------------------------------------------------------
-module(cache_server).
-author("serzh").

-behaviour(gen_server).

%% API
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
  terminate/2, code_change/3, start_link/1, insert/2, lookup/1, stop/0,
  remove/1]).

start_link(Args) ->
  gen_server:start_link({global, cs}, ?MODULE, Args, []).

insert(Key, Value) ->
  gen_server:cast({global, cs}, {insert, {Key, Value}}),
  {ok, {Key, Value}}.

lookup(Key) ->
  gen_server:call({global, cs}, {lookup, Key}).

remove(Key) ->
  gen_server:cast({global, cs}, {remove, Key}).

init([{ttl, TTL}]) ->
  ets:new(cache_table, [named_table]),
  {ok, [{ttl, TTL}]}.

expire_time(TTL) ->
  calendar:datetime_to_gregorian_seconds(calendar:local_time()) + TTL.


stop() ->
  gen_server:call({global, cs}, {stop}).

handle_call(Request, _, State) ->
  case Request of
    {lookup, Key} ->
      Time = calendar:datetime_to_gregorian_seconds(calendar:local_time()),
      case ets:lookup(cache_table, Key)of
        [{_, _, ExpiredAt}]
          when ExpiredAt < Time -> {reply, {notfound}, State};

        [{_, Value, _}]         -> {reply, {ok, Value}, State};

        []                      -> {reply, {notfound}, State}
      end;
    {stop} ->
      {stop, normal, State}
  end.

handle_cast(Request, [{ttl, TTL}]=State) ->
  case Request of
    {insert, {K, V}} ->
      ets:insert(cache_table, {K, V, expire_time(TTL)}),
      timer:apply_after(timer:seconds(TTL), ?MODULE, remove, [K]),
      {noreply, State};
    {remove, K} ->
      ets:delete(cache_table, K),
      {noreply, State}
  end.

handle_info(_, State) ->
  {noreply, State}.

terminate(_Reason, _State) ->
  ets:delete(cache_table).

code_change(_, State, _) ->
  {ok, State}.
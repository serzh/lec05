%%%-------------------------------------------------------------------
%%% @author serzh
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. Jun 2015 20:36
%%%-------------------------------------------------------------------
-module(toppage_handler).
-author("serzh").

-export([init/3]).
-export([handle/2]).
-export([terminate/3]).

init(_Type, Req, []) ->
  {ok, Req, undefined}.

json_response(Req, State, Status, Body) ->
  JsonBody = jsx:encode(Body),
  {ok, Req2} = cowboy_req:reply(Status, [
    {<<"content-type">>, <<"application/json">>}
  ], JsonBody, Req),
  {ok, Req2, State}.

insert(Req, State, {Key, Value}) ->
  cache_server:insert(Key, Value),
  json_response(Req, State, 200, [{<<"ok">>, <<"ok">>}]).

lookup(Req, State, Key) ->
  case cache_server:lookup(Key) of
    {ok, Value}
      -> json_response(Req, State, 200, [{<<"key">>,  Key}, {<<"value">>, Value}]);

    {notfound}
      -> json_response(Req, State, 404, [{<<"notfound">>, <<"notfound">>}])
  end.

handle(Req, State) ->
  {ok, Body, _} = cowboy_req:body(Req),
  case jsx:decode(Body) of
    [{<<"action">>, <<"insert">>},
     {<<"key">>,    Key},
     {<<"value">>,  Value}]
      -> insert(Req, State, {Key, Value});

    [{<<"action">>, <<"lookup">>},
     {<<"key">>,    Key}]
      -> lookup(Req, State, Key)
  end.

terminate(_Reason, _Req, _State) ->
  ok.
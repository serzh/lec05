%%%-------------------------------------------------------------------
%%% @author serzh
%%% @copyright (C) 2015, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 15. Jun 2015 20:57
%%%-------------------------------------------------------------------
-module(repl).
-author("serzh").

%% API
-export([reload/0, start/0, stop/0, restart/0, go/0]).

reload_file(F) ->
  compile:file("src/" ++ atom_to_list(F) ++ ".erl", {outdir, "ebin"}),
  code:purge(F),
  code:load_abs("ebin/" ++ atom_to_list(F)),
  {ok, F}.

reload() ->
  Modules = [lec05_app, lec05_sup, toppage_handler, cache_server],
  [reload_file(F) || F <- Modules].

start() ->
  application:start(ranch),
  application:start(crypto),
  application:start(cowlib),
  application:start(cowboy),
  application:start(jsx),
  application:start(lec05).

stop() ->
  application:stop(lec05),
  application:stop(jsx),
  application:stop(cowboy),
  application:stop(cowlib),
  application:stop(crypto),
  application:stop(ranch).

go() -> reload(), start().

restart() -> stop(), go().
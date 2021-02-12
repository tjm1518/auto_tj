-module(rbot).
-behaviour(application).

-export([start/2, stop/1, init/0, loop/1]).
-include("priv_keys.hrl").
-on_load(init/0).

init() ->
  application:ensure_all_started(crypto),
  application:ensure_all_started(public_key),
  application:ensure_all_started(ssl),
  application:ensure_all_started(inets),
  ok.

start(_Type, _Args) ->
  case get_token() of
    nil -> {error, "Could not refresh token"};
    Token -> {ok, spawn(?MODULE, loop, [Token])}
  end.

stop(_State) ->
  ok.

loop(Token) ->
  test(Token),
  ok.

test(Token) ->
  Result = httpc:request(get, {"https://oauth.reddit.com/message/mentions.json", [{"Authorization", "bearer "++Token}, {"User-Agent", "TJ ? Auto_TJ"}]}, [], []),
  io:fwrite("~p~n~n", [Result]).


get_token() ->
  Body = "grant_type=refresh_token&refresh_token="++?REFRESH_TOKEN,
  {ok,
   {{"HTTP/1.1",200,"OK"},
    _Content,
    Result}} = httpc:request(post,
                {"https://www.reddit.com/api/v1/access_token",
                 [{"Authorization", "Basic " ++ base64:encode_to_string(?REDDIT_PERSONAL ++ ":" ++ ?REDDIT_SECRET)}],
                 "application/x-www-form-urlencoded",
                 Body
                 },
                [{ssl,[]}],
                []),
  case string:prefix(Result, "{\"access_token\": \"") of
    nomatch -> nil;
    Str -> lists:takewhile(fun ($") -> false; (_) -> true end, Str)
  end.

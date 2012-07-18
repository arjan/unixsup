
-module(unixsup_SUITE).

-compile(export_all).

all() ->
    [
     test_spawn
    ].

init_per_suite(Config) ->
    ok = application:start(lager),
    Config.

end_per_suite(Config) ->
    Config.


test_spawn(_) ->

    Workers = [
               {test_sup1,
                {unixsup_worker, start_link, [test_sup1, "/bin/cat", []]},
                permanent, 5000, worker, []}
              ],
    application:set_env(example, workers, Workers),

    ok = application:start(example),
    ct:print("started"),
    timer:sleep(20000).


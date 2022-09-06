-module(scratch).

-compile(export_all).

proc_a(List) ->
    receive
        terminate -> ok;
        print -> io:format("~w~n", [List]),
                proc_a(List);
        Msg -> proc_a([Msg | List])
    end.


a() ->
    receive
        terminate -> io:format("s")
    end.

dying() ->
    exit(bye).

supervisor_proc() ->
    spawn_monitor(?MODULE, dying, []),
    receive
        Msg -> 
            io:format("~w~n", [Msg])
    end.

send_msg() ->
    msg.

receiver() ->
    
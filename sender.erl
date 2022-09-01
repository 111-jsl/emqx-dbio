-module(sender).

-compile(export_all).

-define(Num_of_Proc, 10).

transition(Src, Dest, []) -> ok;
transition(Src, Dest, List) ->
    [Hd | Tail] = List,
    Dest ! {Src, {store, Hd}},
    transition(Src, Dest, Tail).



proc(List) ->
    receive
        {From, {store, Data}} ->
            From ! {self(), ok},
            proc([Data | List]);
        {From, {transition, Pid}} ->
            From ! {self(), transition(self(), Pid, List)},
            proc(List);
        terminate ->
            ok;
        Unexpected ->
            io:format("unexpected message: ~w~n", [Unexpected])
    end.

store(Src, Dest, List) ->
    Dest ! {Src, {store, List}},
    receive
        {From, Msg} -> Msg
    after 3000 ->
        timeout
    end.

start() ->
    


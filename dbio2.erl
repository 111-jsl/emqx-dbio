-module(dbio2).

-include_lib("eunit/include/eunit.hrl").



-export([
    put/5,
    get/4,
    test/2
    ]).

-define(Len_of_Fid, 8).
-define(Len_of_Sid, 16).
-define(Loop_time, 100000).
-define(Seg_num, 1000).
% -define(File_num, 10).


put(Db, AuxDb, Key, Value, Num_of_Seg) ->
    <<Fid:?Len_of_Fid, Sid:?Len_of_Sid>> = Key,
    % io:format("Sid:~w~n", [Sid]),
    case rocksdb:get(AuxDb, <<Fid>>, []) of
        {ok, Bitmap} -> 
            % io:format("retrieved value ~w~n", [Bitmap]),
            % io:format("Sid:~w, bit_size:~w~n", [Sid, bit_size(Bitmap)]),
            <<Front:(Sid - 1), Check:1, Back:(bit_size(Bitmap) - Sid)>> = Bitmap,
            if Check == 0 -> 
                rocksdb:put(Db, Key, Value, []),
                rocksdb:put(AuxDb, <<Fid>>, <<Front:(Sid - 1), 1:1, Back:(bit_size(Bitmap) - Sid)>>, []);
            Check == 1 -> already_exist;
            true -> error
            end;
        not_found -> 
            % io:format("value not found~n", []),
            <<Head:((bit_size(<<Num_of_Seg>>)) - 3), Remain:3>> = <<Num_of_Seg>>,
            Add =
                case Remain of
                    0 -> 0;
                    _ -> 8-Remain
                end,
            New_one = <<0:(Sid-1), 1:1, 0:(Num_of_Seg + Add - Sid)>>,
            % io:format("~w~n", [New_one]),
            rocksdb:put(AuxDb, <<Fid>>, New_one, []),
            rocksdb:put(Db, Key, Value, []);
        Error -> 
            io:format("operational problem encountered: %p~n", [Error])
    end.
    


get_exact(Db, Fid, Num_of_Seg) when Num_of_Seg == 0 -> [];
get_exact(Db, Fid, Num_of_Seg) when Num_of_Seg > 0 ->
    case rocksdb:get(Db, <<Fid, Num_of_Seg>>, []) of
        {ok, Value} -> 
            % io:format("retrieved value ~w~n", [Value]),
            Nxt = get_exact(Db, Fid, Num_of_Seg - 1),
            case Nxt of
                not_found -> 
                    % io:format("wasted: ~p", [Num_of_Seg]),
                    not_found;
                error -> error;
                _ -> list_to_binary([Value | Nxt])
            end;
        not_found -> not_found;
        Error -> 
            io:format("error encountered: ~w~n", [Error]),
            error
        
    end.
    


get(Db, AuxDb, Fid, Num_of_Seg) ->
    case rocksdb:get(AuxDb, <<Fid>>, []) of
        {ok, Bitmap} -> 
            % io:format("retrieved value ~w~n", [Bitmap]),
            % <<Validmap:Num_of_Seg, _:((bit_size(Bitmap)) - Num_of_Seg)>> = Bitmap,
            % io:format("before~n", []),
            Check = << <<Bit:1>> || <<Bit:1>> <= Bitmap, Bit == 1 >>,
            % io:format("after~n", []),
            % io:format("~w~n", [bit_size(Check)]),
            if bit_size(Check) == Num_of_Seg -> get_exact(Db, Fid, Num_of_Seg);
            true -> not_intact
            end;
        not_found -> not_found;
            % io:format("value not found~n", []);
        Error -> 
            io:format("operational problem encountered: %p~n", [Error])
    end.
    

seg_loop(Db, AuxDb, Fid, Loop) when Loop == 0 -> 0;
seg_loop(Db, AuxDb, Fid, Loop) when Loop > 0 ->
    put(Db, AuxDb, <<Fid:?Len_of_Fid, Loop:?Len_of_Sid>>, <<(erlang:system_time())>>, ?Seg_num).


time_test(Db, AuxDb, Loop) when Loop == 0 -> 0;
time_test(Db, AuxDb, Loop) when Loop > 0 ->
    seg_loop(Db, AuxDb, Loop, ?Seg_num),
%     case rand:uniform(2) of
%         1 -> 
%             % put(Db, <<(rand:uniform(?File_num)):?Len_of_Fid, (rand:uniform(?Seg_num)):?Len_of_Sid>>, <<(erlang:system_time())>>);
            
%         2 -> 
% % Debug mode
%             % io:format("get~n"),
%             % case get(Db, rand:uniform(?File_num), ?Seg_num) of
%             %     not_found -> io:format("not intact~n", []);
%             %     error -> io:format("error~n", []);
%             %     _ -> io:format("done~n", [])
%             % end
% % Release mode
%             get(Db, AuxDb, rand:uniform(?Loop_time), ?Seg_num)
%             % if Value == not_found -> idle;
%             % true -> io:format("Value: ~w~n", [Value])
%             % end
%     end,
    time_test(Db, AuxDb, Loop-1).


test(Path, AuxPath) ->
    
    
    Options = [{create_if_missing, true}],
    {ok, Db} = rocksdb:open(Path, Options),
    {ok, AuxDb} = rocksdb:open(AuxPath, Options),

    io:format("----------functional test----------~n"),
    % put(Db, AuxDb, <<1, 1>>, <<"one">>, 1),
    % Value = get(Db, AuxDb, 1, 1),
    % io:format("ans: ~w~n", [Value]),

    io:format("----------time test----------~n"),
    % random:seed(erlang:now()),
    statistics(runtime),
    time_test(Db, AuxDb, ?Loop_time),
    {_, Time} = statistics(runtime),
    io:format("Runtime ~p Miliseconds~n", [Time]),


    ok = rocksdb:close(AuxDb),
    rocksdb:destroy(AuxPath, []),
    ok = rocksdb:close(Db),
    rocksdb:destroy(Path, []).

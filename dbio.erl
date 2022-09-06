-module(dbio).

-include_lib("eunit/include/eunit.hrl").
-include("./macro.hrl").


-export([
    put/3,
    get/3, get/2,
    test/1
    ]).


% -define(File_num, 10).


put(Db, Key, Value) ->
    rocksdb:put(Db, Key, Value, []).




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
            io:format("error encountered: ~p", [Error]),
            error
        
    end.
    

get(Db, Key) -> rocksdb:get(Db, Key, []).

get(Db, Fid, Num_of_Seg) ->
    get_exact(Db, Fid, Num_of_Seg).

seg_loop(Db, Fid, Loop) when Loop == 0 -> 0;
seg_loop(Db, Fid, Loop) when Loop > 0 ->
    put(Db, <<Fid:?FID_LEN, Loop:?SID_LEN>>, <<(erlang:system_time())>>).


time_test(Db, Loop) when Loop == 0 -> 0;
time_test(Db, Loop) when Loop > 0 ->
    seg_loop(Db, Loop, ?Seg_num),
%     case rand:uniform(2) of
%         1 -> 
%             % put(Db, <<(rand:uniform(?File_num)):?FID_LEN, (rand:uniform(?Seg_num)):?SID_LEN>>, <<(erlang:system_time())>>);
            
%         2 -> 
% % Debug mode
%             % io:format("get~n"),
%             % case get(Db, rand:uniform(?File_num), ?Seg_num) of
%             %     not_found -> io:format("not intact~n", []);
%             %     error -> io:format("error~n", []);
%             %     _ -> io:format("done~n", [])
%             % end
% % Release mode
%             get(Db, rand:uniform(?Loop_time), ?Seg_num)
%             % if Value == not_found -> idle;
%             % true -> io:format("Value: ~w~n", [Value])
%             % end
%     end,
    time_test(Db, Loop-1).



test(Path) ->
    
    
    {ok, Db} = rocksdb:open(Path, [{create_if_missing, true}]),
    
    io:format("----------functional test----------~n"),
    dbio:put(Db, <<1, 1>>, <<"one">>),
    <<"one">> = dbio:get(Db, 1, 1),

    dbio:get(Db, 2, 1),

    dbio:get(Db, 1, 2),

    io:format("----------time test----------~n"),
    % random:seed(erlang:now()),
    statistics(runtime),
    time_test(Db, ?Loop_time),
    {_, Time} = statistics(runtime),
    io:format("Runtime ~p Miliseconds~n", [Time]),
    ok = rocksdb:close(Db),
    rocksdb:destroy(Path, []).
    

multiproc_test() ->

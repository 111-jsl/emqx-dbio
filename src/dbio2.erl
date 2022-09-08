-module(dbio2).


-include("../include/macro.hrl").


-compile(export_all).

% -define(File_num, 10).

open() ->
    Options = 
    [
        {create_if_missing, true}, 
        {allow_concurrent_memtable_write, true}, 
        {enable_piplined_write, true},
        {enable_write_thread_adaptive_yield, true}
    ],
    ok = filelib:ensure_dir(?DB_PATH),
    rocksdb:open(?DB_PATH, Options).


close(Db) ->
    rocksdb:close(Db).
    

destroy() ->
    rocksdb:destroy(?DB_PATH, []).



get_all(Db, Fid, Num_of_Seg) when Num_of_Seg < 0 -> 
    ?TRACE("Fid:~w Sid:~w~n", [Fid, Num_of_Seg]),
    [];
get_all(Db, Fid, Num_of_Seg) when Num_of_Seg >= 0 ->
    ?TRACE("Fid:~w Sid:~w~n", [Fid, Num_of_Seg]),
    case rocksdb:get(Db, <<Fid:?FID_LEN, Num_of_Seg:?SID_LEN>>, []) of
        {ok, Value} -> 
            % io:format("retrieved value ~w~n", [Value]),
            Nxt = get_all(Db, Fid, Num_of_Seg - 1),
            case Nxt of
                not_found -> 
                    % io:format("wasted: ~p", [Num_of_Seg]),
                    not_found;
                error -> error;
                _ -> list_to_binary([Nxt | Value])
            end;
        not_found -> not_found;
        Error -> 
            io:format("error encountered: ~w~n", [Error]),
            error
    end.
    

    








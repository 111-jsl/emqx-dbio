-module(dbio2).

-include_lib("eunit/include/eunit.hrl").
-include("./macro.hrl").


-compile(export_all).

% -define(File_num, 10).

open() ->
    Options = [{create_if_missing, true}],
    ok = filelib:ensure_dir(?DB_PATH),
    rocksdb:open(?DB_PATH, Options).


close(Db) ->
    ok = rocksdb:close(Db).
    

destroy() ->
    rocksdb:destroy(?DB_PATH, []).



get_all(Db, Fid, Num_of_Seg) when Num_of_Seg == 0 -> [];
get_all(Db, Fid, Num_of_Seg) when Num_of_Seg > 0 ->
    case rocksdb:get(Db, <<Fid, Num_of_Seg>>, []) of
        {ok, Value} -> 
            % io:format("retrieved value ~w~n", [Value]),
            Nxt = get_all(Db, Fid, Num_of_Seg - 1),
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
    

    








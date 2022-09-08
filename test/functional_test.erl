-module(functional_test).
-include_lib("eunit/include/eunit.hrl").
-include("../include/macro.hrl").
-compile(export_all).


functional_test() ->

    file_handle:input_clean_up(),
    dbio2:destroy(),

    ?TRACE("~ngenerating input files~n", []),
    file_handle:input_proc(?INPUT_FILE_NUM_LIMIT),
    
    ?TRACE("start time recording~n", []),
    statistics(runtime),

    ?TRACE("opening Rocksdb~n", []),
    {ok, Db} = dbio2:open(),

    ?TRACE("start processing~n", []),
    {ok, File_name_list} = file:list_dir_all("./" ++ ?INPUT_DIR_NAME),
    File_num = tuple_size(list_to_tuple(File_name_list)),
    % ?TRACE("File_num: ~w~n", [File_num]),
    
    File_name_index_list = [{Index, lists:nth(Index, File_name_list)} || Index <- lists:seq(1, File_num)],


    [file_handle:bind(File, Fid, Db) || {Fid, File} <- File_name_index_list],
    
    ?TRACE("start verification~n", []),
    % Expected = [file:read_file("./" ++ ?INPUT_DIR_NAME ++ "/" ++ File) || File <- File_name_list],
    % Actual = [rocksdb:get(Db, <<Key>>, []) || Key <- lists:seq(1, File_num)],
    {ok, Expected} = file:read_file(?INPUT_FILE_PATH ++ "1"),
    % ?TRACE("~w~n", [Expected]),
    {ok, Actual} = rocksdb:get(Db, <<1>>, []),
    % ?TRACE("~w~n", [Actual]),
    Expected = Actual,

    {_, Time} = statistics(runtime),
    ?TRACE("Time record result: ~w ms~n", [Time]),

    ok = dbio2:close(Db),
    ?TRACE("clean up all the things~n", []),
    file_handle:input_clean_up(),
    dbio2:destroy(),
    
    ok.
-module(file_handle).

-include("./macro.hrl").

-compile(export_all).


% input file



generator(0) -> ok;
generator(File_num) when File_num > 0 ->
    file:write_file(?INPUT_FILE_PATH ++ integer_to_list(File_num), rand:bytes(rand:uniform(?INPUT_FILE_SIZE_LIMIT))),
    generator(File_num - 1).

input_proc(File_num) ->
    ok = filelib:ensure_dir(?INPUT_FILE_PATH),
    generator(File_num).

input_clean_up() ->
    file:del_dir_r("./" ++ ?INPUT_DIR_NAME).


% output api
get_file(Fid) ->
    {ok, Db} = dbio2:open(),
    rocksdb:get(Db, <<Fid>>, []).

% output file
output_dir() ->
    file:make_dir("./" ++ ?INPUT_DIR_NAME).

output_file(Fid) ->
    file:write_file(?INPUT_FILE_PATH ++ integer_to_list(Fid), get_file(Fid)).
    

% test
test() ->
    input_proc(?INPUT_FILE_NUM_LIMIT),

    {ok, Db} = dbio2:open(),

    {ok, File_name_list} = file:list_dir_all("./" ++ ?INPUT_DIR_NAME),
    File_num = tuple_size(list_to_tuple(File_name_list)),

    [bind(File, Fid, Db) || File <- File_name_list, Fid <- lists:seq(1, File_num)],
    input_clean_up(),
    ok.
    

bind(File, Fid, Db) ->
    File_size = filelib:file_size(File),
    Seg_num = ceil(File_size / ?SEG_SIZE),
    Det = spawn(?MODULE, detector, [list_to_tuple(lists:duplicate(Seg_num, 0)), Fid, Db]),
    Sen_list = [spawn(?MODULE, sender, [File, Sid, Fid, Det, Db]) || Sid <- lists:seq(0, Seg_num - 1)],
    {Det, Sen_list}.

    

detector(Bitmap, Fid, Db) ->
    receive
        {From, Sid} -> New_Bitmap = setelement(Sid, Bitmap, 1)
    end,
    Check = lists:member(0, tuple_to_list(Bitmap)),
    % io:format("~w~n", [Check]),
    case Check of
        true -> detector(New_Bitmap, Fid, Db);
        false -> rocksdb:put(Db, <<Fid>>, dbio2:get_all(Db, <<Fid>>, tuple_size(Bitmap)), [])
    end.


% sender
sender(File, Sid, Fid, Bound_Det, Db) ->
    Offset = Sid * ?SEG_SIZE,
    try (bit_size(<<Sid>>) =< ?SID_LEN) and (bit_size(<<Fid>>) =< ?FID_LEN) of
        true -> ok
    catch
        false -> throw("key length out of the bound")
    end,
    Key = <<Fid:?FID_LEN, Sid:?SID_LEN>>,

    {ok, Pid} = file:open(File, read),
    {ok, _} = file:position(Pid, Offset),
    Value = file:read(Pid, ?SEG_SIZE),
    ok = file:close(Pid),
    rocksdb:put(Db, Key, Value, []),
    Bound_Det ! {self(), Sid}.






% MODULE input
-define(INPUT_FILE_SIZE_LIMIT, 10000).
-define(INPUT_DIR_NAME, "input_file").
-define(INPUT_FILE_NAME, "file").
-define(INPUT_FILE_PATH, "./" ++ ?INPUT_DIR_NAME ++ "/" ++ ?INPUT_FILE_NAME).
-define(INPUT_FILE_NUM_LIMIT, 100).

% MODULE output
-define(OUTPUT_DIR_NAME, "output_file").
-define(OUTPUT_FILE_NAME, "file").
-define(OUTPUT_FILE_PATH, "./" ++ ?OUTPUT_DIR_NAME ++ "/" ++ ?OUTPUT_FILE_NAME).

% MODULE sender
-define(SEG_SIZE, 1000).

% MODULE dbio
-define(DB_DIR, "db_file").
-define(DB, "db").
-define(AUXDB, "auxdb").
-define(DB_PATH, "./" ++ ?DB_DIR ++ "/" ++ ?DB).
-define(AUXDB_PATH, "./" ++ ?DB_DIR ++ "/" ++ ?AUXDB).

-define(FID_LEN, 8). % bit
-define(SID_LEN, 16). % bit
-define(Loop_time, 100000).
-define(Seg_num, 1000).
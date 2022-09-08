emqx-dbio
=====

The files will turn into segments while transporting. Now the case is, we have to transport these segments to clients in the concurrent circumstance.

#### Traditional method:

Use Erlang, directly send the segments to clients

#### Problem:

##### Case1:

clients' receiving files remain open, which means that clients have to keep a lot of `fds`, which may be out of limit and lead to VM crash.

##### Case2:

clients' receiving files don't remain open, meaning that each transportation will trigger open and close. Both of them are related to `syscall()` and reduce the performance.



#### The method in this project:

When segments arrive, they are stored into `Rocksdb`.

There is a process named detector, constantly checking if all the segments of a file have arrived by checking Bitmap. The advantage of using erlang process checking Bitmap instead of storing it into `Rocksdb` is that we don't need to concern about race condition.

If detector finds that all segments of a file have arrived(Bitmap all 1), it will get all the segments and merge them together and store them into `Rocksdb` again.

For clients, they can call `rocksdb:get(Db, <<Fid>>, [])` to get the file of Fid.

#### The problem of this project(will be modified in the near future):

clients have to wait for the segments to come. If they try to get file before all the segments are prepared, they only get `not_found` and have no idea which segments are lost.

Build
-----

```bash
$ rebar3 compile
```

## Test

```bash
$ rebar3 eunit -d "test"
```


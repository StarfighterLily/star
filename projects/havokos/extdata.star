# State of the HavokOS-only extensions -- todo.md HavokOS P1 #6 (M7 part 3),
# and the SQLite handles of P1 #7 (`sqldb.star`).
# `ext.star` holds the code and says what each piece follows in the
# reference; this file only holds the rows the Vm keeps for them (Vm fields
# under "the HavokOS-only extensions"), apart so `vm.star` can name the
# types without importing the efun code, as `sockdata.star` is for
# `sockets.star`.

import "value.star" as val

# find_files(): a crawl made at the call, answered on the next pass
# (driver.pike runs the crawl in a thread and answers by call_out). `dirs`
# are the directories visited, in visiting order, and `files[i]` the
# matching names in `dirs[i]`; `saved` the matching paths the save store
# holds under the root (P1 #10), joined to their directories' results.
struct PendingFind:
    ob: val::Value
    root: str
    dirs: List<str>
    files: List<List<str>>
    cb: val::Value
    saved: List<str> = List<str>()

# A watched directory (driver.pike WatchDir): the files it held at the last
# listing, with the (mtime, size) last seen, and its subdirectories.
struct WatchDir:
    path: str
    mut names: List<str> = List<str>()
    mut mtimes: List<i64> = List<i64>()
    mut sizes: List<i64> = List<i64>()
    mut subdirs: List<str> = List<str>()

# An object that called watch_path(), and the directories it asked for
# (recursive or not).
struct Watcher:
    ob: val::Value
    mut dirs: List<str> = List<str>()
    mut recs: List<bool> = List<bool>()

# One quota group's counts (driver.pike QuotaUse), "*" for every object.
struct QuotaUse:
    group: str
    mut call_outs: i64 = 0 as i64
    mut clones: i64 = 0 as i64
    # wall time charged this minute, and in the minute before
    mut eval_us: i64 = 0 as i64
    mut eval_last: i64 = 0 as i64
    # time() / 60 that eval_us belongs to, and the minute already reported
    # to the master
    mut minute: i64 = 0 as i64
    mut warned: i64 = 0 as i64 - (1 as i64)

# A group's limits as the master's quota_limits() gave them: its string
# keys with int values, in the order it gave them.
struct QuotaLimits:
    mut keys: List<str> = List<str>()
    mut vals: List<i64> = List<i64>()

# One compiled program's dependencies (compiler.pike dep_graph): its direct
# inherits, the source and every file it included with the (mtime, size)
# they had (-1 when missing), the inherits' stamps it was built against,
# and when it was compiled. Kept after the program is forgotten, so a file
# whose blueprint was destructed can still be checked.
struct DepEntry:
    path: str
    mut inherits: List<str> = List<str>()
    mut inh_stamps: List<str> = List<str>()
    mut files: List<str> = List<str>()
    mut mtimes: List<i64> = List<i64>()
    mut sizes: List<i64> = List<i64>()
    mut compiled: i64 = 0 as i64
    # the files it included (not its own source), for dependents()
    mut includes: List<str> = List<str>()

# function_profile() with `havok profiling`: one function's calls and
# microseconds in itself and in what it called (driver.pike fn_profile).
struct ProfRec:
    key: str
    mut calls: i64 = 0 as i64
    mut self_us: i64 = 0 as i64
    mut child_us: i64 = 0 as i64

# The sampling profiler's count for one function (driver.pike sample_fns):
# self and total microseconds, and the samples that landed in it.
struct SampleRec:
    key: str
    mut self_us: i64 = 0 as i64
    mut total_us: i64 = 0 as i64
    mut samples: i64 = 0 as i64

# A db_open() handle (sqldb.pike Db, P1 #7): the SQLite connection, the
# object that opened it (generation-checked, so a destructed owner reads as
# gone), its mudlib path or ":memory:", and the columns of its last query.
# The reference numbers handles from a counter that never goes back, so
# `Vm.dbs` keeps one row per handle ever handed out (handle = index + 1),
# `open` false once closed.
struct SqlDb:
    mut open: bool = true
    mut conn: ptr = null_ptr()
    mut owner: val::Value = val::Value::Int(0 as i64)
    mut file: str = ""
    mut columns: List<str> = List<str>()

# The save store (P1 #10; savestore.star, savestore.pike). `index` is every
# stored path's size and mtime, pending writes included, and its slot in
# `paths`, which lists the stored paths for iteration ("" where one was
# removed, `dead` of them, until compacted). Writes not committed yet are
# in `pending` (path -> data) and deletes in `pend_del`, both in
# `pend_order`; `flush_due` is when they commit (clock_ms(), 0: nothing
# waiting). `import_dir` is where a new database's import moved the
# mudlib's .o files.
struct SaveEntry:
    size: i64
    mtime: i64
    slot: i32

struct SaveStore:
    mut on: bool = false
    mut db: ptr = null_ptr()
    mut file: str = ""
    mut index: Map<str, SaveEntry> = Map<str, SaveEntry>()
    mut paths: List<str> = List<str>()
    mut dead: i32 = 0
    mut pending: Map<str, str> = Map<str, str>()
    mut pend_del: Set<str> = Set<str>()
    mut pend_order: List<str> = List<str>()
    mut flush_due: i64 = 0 as i64
    mut import_dir: str = ""

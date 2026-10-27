# The save store -- todo.md HavokOS P1 #10, `havok/savestore.pike` and the
# store's half of `havok/efuns.pike`'s file efuns.
#
# With `havok save store : sqlite` in the config, every save file (a path
# ending ".o") lives in one SQLite database, `havok save database` (saves.db
# beside the config file by default), and LPC still sees each one as a file:
# save_object()/restore_object() and the file efuns (file_size, stat,
# get_dir, read_file, read_bytes, write_file, write_bytes, rm, rmdir, cp,
# rename, find_files) look in the store first and fall through to the disk
# for a path it doesn't hold, and a save written to a path that also exists
# on disk replaces (deletes) the disk copy. `efuns_file.star` and `ext.star`
# call in here at each of the reference's hook points, in its order.
#
# M4 left this out as "off by default, changes nothing LPC can observe".
# That held for a fresh mudlib, but not for one the reference has already
# run with the store on: its first boot imported every .o into the database
# and moved the originals out of the mudlib, so a driver without the store
# boots it with no saves at all. That is what happened on E:\dsdev: no
# players; an empty races daemon (every NPC heart beat then indexed NULL with
# "Rtype", and character creation offered no races); and FUNCTION_D's cache
# gone, so it re-scanned all of /lib in call_outs until one ran out of
# evaluation time. Those daemons also wrote their empty state out as new .o
# files on disk, which the store now shadows (it is looked in first) and
# deletes on their next save.
#
# The mechanism is the reference's: an in-memory index of every stored
# path's size and mtime (pending writes included), so stat() and get_dir()
# cost no SQL; writes and deletes collect in memory and commit in one
# transaction about a second later (`driver_tick()`), at shutdown() and when
# the main loop ends, so a crash can lose the last second of saves, as on
# the reference; a failed commit is rolled back and retried. The database is
# the reference's own, table and all, so either driver (and the reference's
# `pike havok/savestore.pike <db> export <dir>`) reads what the other wrote.
# A new database imports the mudlib's .o files and moves the originals out
# to runtime/save_import_<yyyymmdd>-<time>/ (same layout), here beside the
# running exe's directory as tls.star's runtime/tls/ is (the reference uses
# its own pike/runtime/). One move suffices: `file_rename()` copies across
# drives, where the reference needs Pike's mv() then a copy, check and rm.
#
# Differences from the reference: `Map` has no iteration, so the index keeps
# its paths in a list beside it (`paths`, "" where one was removed, compacted
# once most are); SQLite is reached through sqldb.star's wrappers (an
# `extern "C"` can't be declared twice); text goes in and out as the bytes it
# is, as in sqldb.star (deviation #14); and a database that can't be opened
# stops the boot (boot.star), where the reference's open would throw out of
# its driver's creation. Not ported: savestore.pike's command line (list,
# export), which works on these databases as it is.

import "value.star" as val
import "vm.star" as vm
import "extdata.star" as xd
import "paths.star" as paths
import "sqldb.star" as sq
import "efun_table.star" as et
import "efuns_file.star" as ef

fn store_last_slash(s: str) -> i32:
    let b = bytes_from_str(s)
    let mut i = b.len() - 1
    while i >= 0:
        if (b[i] as i32) == 47:
            return i
        i -= 1
    -1

# A drive letter or a leading slash (efuns.pike create())
fn store_abs_file(f: str) -> bool:
    let b = bytes_from_str(f)
    (b.len() > 1 and (b[1] as i32) == 58) or str_starts_with(f, "/")

# mkdir -p of an OS directory
fn store_make_dirs(d: str):
    if d == "" or path_kind(d) != 0:
        return
    let cut = store_last_slash(d)
    if cut > 0:
        store_make_dirs(vm::substr(d, 0, cut))
    dir_create(d)

fn store_two(v: i64) -> str:
    if v < (10 as i64):
        return f"0{v}"
    f"{v}"

# Calendar.now()->format_ymd_short()
fn store_ymd(t: i64) -> str:
    let lt = local_time(t)
    if lt.len() < 6:
        return "00000000"
    f"{lt[5]}{store_two(lt[4] + (1 as i64))}{store_two(lt[3])}"

impl vm::Vm:
    # efuns.pike create(): `havok save store : sqlite` opens `havok save
    # database` (saves.db), relative to the config file's directory, and a
    # new one imports the mudlib's saves. False, with the reason logged, if
    # it can't be opened: booting on without it would mean booting with no
    # saves (see the header).
    fn store_configure(mut self) -> bool:
        let mut kind = ""
        if let Option::Some(x) = self.config.get("havok save store"):
            kind = x
        if kind != "sqlite":
            return true
        let mut file = "saves.db"
        if let Option::Some(x) = self.config.get("havok save database"):
            if x != "":
                file = x
        if !store_abs_file(file):
            let mut dir = "."
            if let Option::Some(x) = self.config.get("havok config dir"):
                dir = x
            file = paths::combine_path(dir, file)
        self.store_open(file, self.root)

    # savestore.pike open(): the table, made if missing, and the index of
    # what it holds. With import_root (an OS directory) a database that
    # didn't exist yet imports that mudlib's .o files.
    fn store_open(mut self, file_in: str, import_root: str) -> bool:
        let file = str_replace(file_in, "\\", "/")
        let fresh = path_kind(file) == 0
        let cut = store_last_slash(file)
        if cut > 0:
            store_make_dirs(vm::substr(file, 0, cut))
        let conn = sqlite_open(file)
        if is_null(conn):
            self.log_msg(f"[save store] cannot open {file}")
            return false
        if sq::sq_errcode(conn) != 0:
            self.log_msg(f"[save store] cannot open {file}: {sq::sq_errmsg(conn)}")
            sq::sq_close(conn)
            return false
        self.store = xd::SaveStore(on = true, db = conn, file = file)
        if !self.store_exec("create table if not exists saves (path text primary key, data text not null, size integer not null, mtime integer not null)"):
            self.log_msg(f"[save store] cannot use {file}: {sq::sq_errmsg(conn)}")
            self.store_close()
            return false
        let st = sqlite_prepare(conn, "select path, size, mtime from saves")
        if !is_null(st):
            while sq::sq_step(st) == sq::SQLITE_ROW:
                self.store_index_put(sq::sq_text(st, 0), sq::sq_col_int(st, 1), sq::sq_col_int(st, 2))
            sq::sq_finalize(st)
        if fresh and import_root != "":
            self.store_import(import_root)
        true

    # Close without committing (store_flush() first to keep pending writes).
    fn store_close(mut self):
        if !is_null(self.store.db):
            sq::sq_close(self.store.db)
        self.store = xd::SaveStore()

    fn store_exec(mut self, sql: str) -> bool:
        let st = sqlite_prepare(self.store.db, sql)
        if is_null(st):
            return false
        let rc = sq::sq_step(st)
        sq::sq_finalize(st)
        rc == sq::SQLITE_DONE or rc == sq::SQLITE_ROW

    fn store_index_put(mut self, p: str, size: i64, mtime: i64):
        if let Option::Some(e) = self.store.index.get(p):
            self.store.index.insert(p, xd::SaveEntry(size = size, mtime = mtime, slot = e.slot))
            return
        self.store.index.insert(p, xd::SaveEntry(size = size, mtime = mtime, slot = self.store.paths.len()))
        self.store.paths.push(p)

    # --- efuns.pike's helpers ------------------------------------------------

    # save_path(): the absolute path if the store is on and path is a save
    # file, else ""
    fn save_path(self, path: str) -> str:
        if !self.store.on:
            return ""
        let a = self.mud_abs(path)
        if str_ends_with(a, ".o"):
            return a
        ""

    # stored_path(): the same, if the store also holds it
    fn stored_path(self, path: str) -> str:
        let a = self.save_path(path)
        if a != "" and self.store.index.contains(a):
            return a
        ""

    fn store_has(self, a: str) -> bool:
        self.store.on and self.store.index.contains(a)

    # save_data(): a save path's contents, from the store or the disk
    fn save_data(mut self, a: str) -> ef::FileText:
        if self.store_has(a):
            return ef::FileText(ok = true, text = self.store_read(a))
        self.read_whole(self.mud_real(a))

    # drop_disk_copy(): once a save is in the store, a disk copy is stale
    fn drop_disk_copy(self, a: str):
        let rp = self.mud_real(a)
        if path_kind(rp) == 1:
            file_remove(rp)

    # --- savestore.pike ------------------------------------------------------

    # read() of a path the store holds
    fn store_read(mut self, a: str) -> str:
        if let Option::Some(d) = self.store.pending.get(a):
            return d
        let st = sqlite_prepare(self.store.db, "select data from saves where path = ?1")
        if is_null(st):
            return ""
        sq::sq_bind_str(st, 1, a)
        let mut out = ""
        if sq::sq_step(st) == sq::SQLITE_ROW:
            out = sq::sq_text(st, 0)
        sq::sq_finalize(st)
        out

    fn store_write(mut self, a: str, data: str):
        self.store_index_put(a, len(data) as i64, vm::epoch_now())
        if !self.store.pending.contains(a) and !self.store.pend_del.contains(a):
            self.store.pend_order.push(a)
        self.store.pending.insert(a, data)
        if self.store.pend_del.contains(a):
            self.store.pend_del.remove(a)
        self.store_schedule()

    # remove(): true if the store held a
    fn store_remove(mut self, a: str) -> bool:
        if !self.store_has(a):
            return false
        if let Option::Some(e) = self.store.index.get(a):
            self.store.paths[e.slot] = ""
        self.store.index.remove(a)
        self.store.dead += 1
        if !self.store.pending.contains(a) and !self.store.pend_del.contains(a):
            self.store.pend_order.push(a)
        if self.store.pending.contains(a):
            self.store.pending.remove(a)
        self.store.pend_del.insert(a)
        self.store_schedule()
        if self.store.dead > 64 and self.store.dead * 2 > self.store.paths.len():
            self.store_compact()
        true

    fn store_compact(mut self):
        let old = self.store.paths
        self.store.paths = List<str>()
        self.store.dead = 0
        for i in 0..old.len():
            if old[i] != "":
                if let Option::Some(e) = self.store.index.get(old[i]):
                    self.store.index.insert(old[i], xd::SaveEntry(size = e.size, mtime = e.mtime, slot = self.store.paths.len()))
                    self.store.paths.push(old[i])

    # list(): the saves directly in dir ("/a/b"), by name
    fn store_list(self, dir: str) -> List<str>:
        let pre = if dir == "/": "/" else: concat(dir, "/")
        let n = len(pre)
        let mut out: List<str> = List<str>()
        for i in 0..self.store.paths.len():
            let p = self.store.paths[i]
            if p != "" and str_starts_with(p, pre):
                let rest = vm::substr(p, n, len(p))
                if !str_contains(rest, "/"):
                    out.push(rest)
        out

    # under(): every stored path under dir, at any depth
    fn store_under(self, dir: str) -> List<str>:
        let pre = if dir == "/": "/" else: concat(dir, "/")
        let mut out: List<str> = List<str>()
        for i in 0..self.store.paths.len():
            let p = self.store.paths[i]
            if p != "" and str_starts_with(p, pre):
                out.push(p)
        out

    # move_tree(): rename() of a directory takes its saves along
    fn store_move_tree(mut self, from: str, to: str):
        let ps = self.store_under(from)
        for i in 0..ps.len():
            let data = self.store_read(ps[i])
            let r = self.store_remove(ps[i])
            self.store_write(concat(to, vm::substr(ps[i], len(from), len(ps[i]))), data)

    fn store_schedule(mut self):
        if self.store.flush_due == (0 as i64):
            self.store.flush_due = clock_ms() + (1000 as i64)

    # flush(): commit the pending writes in one transaction; on a failure
    # roll back, keep them, and try again a second later.
    fn store_flush(mut self):
        self.store.flush_due = 0 as i64
        if !self.store.on or self.store.pend_order.len() == 0:
            return
        let work = self.store.pend_order
        let mut ok = self.store_exec("begin")
        let mut i = 0
        while ok and i < work.len():
            if let Option::Some(data) = self.store.pending.get(work[i]):
                ok = self.store_put_row(work[i], data)
            else:
                ok = self.store_delete_row(work[i])
            i += 1
        if ok:
            ok = self.store_exec("commit")
        if !ok:
            let msg = sq::sq_errmsg(self.store.db)
            let r = self.store_exec("rollback")
            self.log_msg(f"[save store] commit failed, will retry: {msg}")
            self.store_schedule()
            return
        self.store.pending = Map<str, str>()
        self.store.pend_del = Set<str>()
        self.store.pend_order = List<str>()

    fn store_put_row(mut self, p: str, data: str) -> bool:
        let st = sqlite_prepare(self.store.db, "insert or replace into saves (path, data, size, mtime) values (?1, ?2, ?3, ?4)")
        if is_null(st):
            return false
        let mut mt = vm::epoch_now()
        if let Option::Some(e) = self.store.index.get(p):
            mt = e.mtime
        sq::sq_bind_str(st, 1, p)
        sq::sq_bind_str(st, 2, data)
        sq::sq_bind_int(st, 3, len(data) as i64)
        sq::sq_bind_int(st, 4, mt)
        let rc = sq::sq_step(st)
        sq::sq_finalize(st)
        rc == sq::SQLITE_DONE

    fn store_delete_row(mut self, p: str) -> bool:
        let st = sqlite_prepare(self.store.db, "delete from saves where path = ?1")
        if is_null(st):
            return false
        sq::sq_bind_str(st, 1, p)
        let rc = sq::sq_step(st)
        sq::sq_finalize(st)
        rc == sq::SQLITE_DONE

    # import_mudlib(): a new database takes in every .o file under root (an
    # OS directory), and the originals move out to the backup directory.
    fn store_import(mut self, root: str):
        let mut found: List<str> = List<str>()
        let mut todo: List<str> = List<str>()
        todo.push("")
        let mut qi = 0
        while qi < todo.len():
            let rel = todo[qi]
            qi += 1
            let names = dir_list(concat(root, rel))
            for i in 0..names.len():
                let p = concat(concat(rel, "/"), names[i])
                let k = path_kind(concat(root, p))
                if k == 2:
                    todo.push(p)
                elif k == 1 and str_ends_with(names[i], ".o"):
                    found.push(p)
        if found.len() == 0:
            return
        let now = vm::epoch_now()
        let backup = concat(concat(concat(self.store_runtime_dir(), "/save_import_"), store_ymd(now)), f"-{now}")
        let mut ok = self.store_exec("begin")
        for i in 0..found.len():
            let rp = concat(root, found[i])
            let ft = self.read_whole(rp)
            if !ft.ok or !ok:
                continue
            self.store_index_put(found[i], len(ft.text) as i64, file_mtime(rp))
            ok = self.store_put_row(found[i], ft.text)
        if ok:
            ok = self.store_exec("commit")
        if !ok:
            # nothing imported: the originals stay where they are
            self.log_msg(f"[save store] import into {self.store.file} failed: {sq::sq_errmsg(self.store.db)}")
            let r = self.store_exec("rollback")
            self.store.index = Map<str, xd::SaveEntry>()
            self.store.paths = List<str>()
            return
        let mut left: List<str> = List<str>()
        for i in 0..found.len():
            if !self.store.index.contains(found[i]):
                continue
            let dest = concat(backup, found[i])
            store_make_dirs(vm::substr(dest, 0, store_last_slash(dest)))
            if !file_rename(concat(root, found[i]), dest):
                left.push(found[i])
        self.store.import_dir = backup
        self.log_msg(f"[save store] imported {found.len() - left.len()} save files into {self.store.file}; the originals are in {backup}")
        if left.len() > 0:
            self.log_msg(concat("[save store] could not move these out of the mudlib (the store's copies are used): ", str_join(left, ", ")))

    # runtime/ beside the directory of the running exe (tls.star's
    # tls_self_signed_file())
    fn store_runtime_dir(self) -> str:
        let exe = str_replace(args()[0], "\\", "/")
        let cut = store_last_slash(exe)
        paths::combine_path(if cut < 0: "." else: vm::substr(exe, 0, cut), "../runtime")

    # The stored paths, sorted
    fn store_paths_sorted(self) -> List<str>:
        let mut live: List<str> = List<str>()
        for i in 0..self.store.paths.len():
            if self.store.paths[i] != "":
                live.push(self.store.paths[i])
        ef::sort_strs(live)

    # --- the case runner's hooks (P1 #10, efun_table.star; ref_cases.pike
    # gives the reference the same ones) --------------------------------------
    #
    #   test_store_open(db)            the store on, over the database at the
    #                                  mudlib path db (no import); 1 if open
    #   test_store_close()             commit and close; the store off
    #   test_store_flush()             commit now
    #   test_store_reopen(db, path)    a second store on db: ({ its sorted
    #                                  paths, its data for path or 0 })
    #   test_store_import(lib, db)     a new store on db importing the mudlib
    #                                  directory lib: ({ sorted paths, their
    #                                  data, the moved originals' data (0 if
    #                                  missing) }); the backup is then removed
    #   test_disk(path)                the disk file's contents, or 0,
    #                                  past the store and the master
    fn efun_store_test(mut self, code: i32, args: List<val::Value>, self_ob: i32) -> val::Value:
        let zero = val::Value::Int(0 as i64)
        if code == et::E_TEST_DISK:
            let ft = self.read_whole(self.mud_real(self.str_arg(args, 0)))
            return if ft.ok: val::Value::Str(ft.text) else: zero
        if code == et::E_TEST_STORE_FLUSH:
            self.store_flush()
            return zero
        if code == et::E_TEST_STORE_OPEN or code == et::E_TEST_STORE_CLOSE:
            self.store_flush()
            self.store_close()
            if code == et::E_TEST_STORE_CLOSE:
                return zero
            return self.bool_v(self.store_open(self.mud_real(self.str_arg(args, 0)), ""))
        let keep = self.store
        self.store = xd::SaveStore()
        let mut r = zero
        if code == et::E_TEST_STORE_REOPEN:
            if self.store_open(self.mud_real(self.str_arg(args, 0)), ""):
                let p = self.mud_abs(self.str_arg(args, 1))
                let data = if self.store_has(p): val::Value::Str(self.store_read(p)) else: zero
                r = self.new_arr([self.str_list_value(self.store_paths_sorted()), data])
        if code == et::E_TEST_STORE_IMPORT:
            if self.store_open(self.mud_real(self.str_arg(args, 1)), self.mud_real(self.str_arg(args, 0))):
                let ps = self.store_paths_sorted()
                let mut datas: List<val::Value> = List<val::Value>()
                let mut moved: List<val::Value> = List<val::Value>()
                for i in 0..ps.len():
                    datas.push(val::Value::Str(self.store_read(ps[i])))
                    let ft = self.read_whole(concat(self.store.import_dir, ps[i]))
                    moved.push(if ft.ok and self.store.import_dir != "": val::Value::Str(ft.text) else: zero)
                if self.store.import_dir != "":
                    self.rm_tree(self.store.import_dir)
                r = self.new_arr([self.str_list_value(ps), self.new_arr(datas), self.new_arr(moved)])
        self.store_close()
        self.store = keep
        r

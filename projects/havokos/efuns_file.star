# File, time and save_object() efuns -- todo.md HavokOS M4 (efuns), the
# "Time", "Files" and "Save / restore" parts of `havok/efuns.pike`.
#
# Every file efun runs the master's valid_read/valid_write first, as FluffOS
# (and the reference's check_read()/check_write()) do, with the same
# fallback: no master loaded yet means allowed, which is how boot reads the
# master's own includes. On a denial each efun returns its own failure value
# (0, or -1 for file_size()/file_length(), -2 for cp()'s destination); only
# save_object()/restore_object() raise an error. Paths are mudlib paths,
# normalised with combine_path and mapped under the mudlib root, so `..`
# can't climb out of it.
#
# The OS side is the Star compiler's filesystem builtins (`dir_list`,
# `path_kind`, `file_size`, `file_rename`, `local_time`, ...;
# `src/codegen/fs.rs`), added for this milestone because Star's FFI can't
# read a C struct out-parameter.
#
# Deliberately not ported from the reference: its asynchronous save writer
# (a thread; save_object() here writes synchronously, still through a temp
# file renamed over the old save so a crash never loses it) and the
# held-open append handles (a Windows open/close cost optimisation). Neither
# changes what LPC code can observe. The SQLite save store (`havok save
# store`), first left out with them, does (P1 #10): each efun below consults
# it where the reference's does, through `savestore.star`.
#
# ctime() follows the reference's MSVC C runtime: the day of the month is
# zero-padded ("Sat Sep 08 20:46:40 2001"), where glibc pads with a space.

import "value.star" as val
import "vm.star" as vm
import "efun_table.star" as et
import "paths.star" as paths
import "saveformat.star" as sav
import "buf.star" as bf
import "objects.star" as objm

fn day_name(d: i64) -> str:
    let n = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    n[d as i32]

fn month_name(m: i64) -> str:
    let n = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    n[m as i32]

fn two(v: i64) -> str:
    if v < (10 as i64):
        return f"0{v}"
    f"{v}"

# The C runtime's ctime() without its trailing newline
fn ctime_str(t: i64) -> str:
    let lt = local_time(t)
    if lt.len() < 10:
        return ""
    f"{day_name(lt[6])} {month_name(lt[4])} {two(lt[3])} {two(lt[2])}:{two(lt[1])}:{two(lt[0])} {lt[5]}"

fn base_name_of(p: str) -> str:
    let parts = str_split(p, "/")
    parts[parts.len() - 1]

fn strip_slash(p: str) -> str:
    if len(p) > 1 and str_ends_with(p, "/"):
        return vm::substr(p, 0, len(p) - 1)
    p

# Glob match of name against a pattern with * and ? (get_dir())
fn glob_match(name: Bytes, pat: Bytes, ni: i32, pi: i32) -> bool:
    let mut n = ni
    let mut p = pi
    while p < pat.len():
        let c = pat[p] as i32
        if c == 42:
            let mut k = n
            while k <= name.len():
                if glob_match(name, pat, k, p + 1):
                    return true
                k += 1
            return false
        if n >= name.len():
            return false
        if c != 63 and name[n] != pat[p]:
            return false
        n += 1
        p += 1
    n == name.len()

fn sort_strs(a_in: List<str>) -> List<str>:
    let mut a = a_in
    let mut i = 1
    while i < a.len():
        let x = a[i]
        let mut j = i - 1
        while j >= 0 and vm::str_cmp(x, a[j]) < 0:
            a[j + 1] = a[j]
            j -= 1
        a[j + 1] = x
        i += 1
    a

impl vm::Vm:
    # efuns.pike absolute(): a normalised mudlib path
    fn mud_abs(self, p: str) -> str:
        let q = if str_starts_with(p, "/"): p else: concat("/", p)
        paths::combine_path("/", q)

    # efuns.pike realpath(): the OS path of a mudlib path
    fn mud_real(self, p: str) -> str:
        concat(self.root, strip_slash(self.mud_abs(p)))

    fn is_dir_path(self, abs: str) -> bool:
        path_kind(concat(self.root, strip_slash(abs))) == 2

    fn check_read(mut self, self_ob: i32, file: str, fun: str) -> bool:
        if self.master_ob < 0:
            return true
        # while the simul_efun object (re)loads, its trusted initializers run
        # before it has privs (efuns.pike check_read())
        if self.loading.contains(self.sefun_path):
            return true
        let r = self.master_apply("valid_read", [val::Value::Str(self.mud_abs(file)), self.obj_value(self_ob), val::Value::Str(fun)], self_ob)
        if self.err:
            return false
        self.truthy(r)

    fn check_write(mut self, self_ob: i32, file: str, fun: str) -> bool:
        if self.master_ob < 0:
            return true
        let r = self.master_apply("valid_write", [val::Value::Str(self.mud_abs(file)), self.obj_value(self_ob), val::Value::Str(fun)], self_ob)
        if self.err:
            return false
        self.truthy(r)

    # The whole file, or "" with ok false
    fn read_whole(self, rp: str) -> FileText:
        if path_kind(rp) != 1:
            return FileText(ok = false, text = "")
        let f = file_open(rp, "rb")
        if is_null(f):
            return FileText(ok = false, text = "")
        let b = file_read_bytes(f)
        file_close(f)
        FileText(ok = true, text = str_from_bytes(b))

    fn write_whole(self, rp: str, text: str, append: bool) -> bool:
        let f = file_open(rp, if append: "ab" else: "wb")
        if is_null(f):
            return false
        let ok = file_write_bytes(f, bytes_from_str(text))
        file_close(f)
        ok

    fn efun_file(mut self, code: i32, name: str, args: List<val::Value>, self_ob: i32) -> val::Value:
        # a file efun may change files: compiles stat afresh (ext.star dep_stat())
        self.dep_stat_ms = 0 as i64
        # --- time
        if code == et::E_TIME or code == et::E_REAL_TIME:
            return val::Value::Int(vm::epoch_now())
        if code == et::E_UPTIME:
            return val::Value::Int(vm::epoch_now() - self.boot_time)
        if code == et::E_CTIME or code == et::E_ZONETIME:
            let ti = if code == et::E_ZONETIME: 1 else: 0
            let t = if args.len() <= ti: vm::epoch_now() else: val::int_of(args[ti])
            return val::Value::Str(ctime_str(t))
        if code == et::E_LOCALTIME or code == et::E_IS_DST:
            let t = if code == et::E_IS_DST: vm::epoch_now() else: val::int_of(self.arg(args, 0))
            let lt = local_time(t)
            if lt.len() < 10:
                self.fail("localtime(): bad time\n")
                return val::Value::Undef
            if code == et::E_IS_DST:
                return val::Value::Int(if lt[8] > (0 as i64): 1 as i64 else: 0 as i64)
            let mut out: List<val::Value> = List<val::Value>()
            for i in 0..8:
                out.push(val::Value::Int(lt[i]))
            out.push(val::Value::Int(lt[9]))
            out.push(val::Value::Str(if lt[8] > (0 as i64): "DST" else: "STD"))
            out.push(val::Value::Int(if lt[8] > (0 as i64): 1 as i64 else: 0 as i64))
            return self.new_arr(out)
        if code == et::E_SAVE_OBJECT or code == et::E_RESTORE_OBJECT:
            return self.efun_save_restore(code == et::E_SAVE_OBJECT, args, self_ob)
        # --- files
        let pv = self.arg(args, 0)
        let path = match pv:
            val::Value::Str(s) -> s
            _ -> ""
        let is_str = match pv:
            val::Value::Str(s) -> true
            _ -> false
        if code == et::E_FILE_SIZE:
            if !is_str or !self.check_read(self_ob, path, "file_size"):
                return val::Value::Int((0 - 1) as i64)
            let sa = self.stored_path(path)
            if sa != "":
                if let Option::Some(e) = self.store.index.get(sa):
                    return val::Value::Int(e.size)
            let rp = self.mud_real(path)
            let k = path_kind(rp)
            if k == 0:
                return val::Value::Int((0 - 1) as i64)
            if k == 2:
                return val::Value::Int((0 - 2) as i64)
            return val::Value::Int(file_size(rp))
        if code == et::E_FILE_LENGTH:
            if !is_str or !self.check_read(self_ob, path, "file_size"):
                return val::Value::Int((0 - 1) as i64)
            let r = self.read_text(self_ob, path, args, false)
            match r:
                val::Value::Str(s) ->
                    let n = str_split(s, "\n").len()
                    return val::Value::Int((if str_ends_with(s, "\n"): n - 1 else: n) as i64)
                _ ->
                    return val::Value::Int((0 - 1) as i64)
        if code == et::E_READ_FILE:
            if !is_str:
                self.fail("Bad argument 1 to read_file()\n")
                return val::Value::Undef
            if !self.check_read(self_ob, path, "read_file"):
                return val::Value::Int(0 as i64)
            return self.read_text(self_ob, path, args, true)
        if code == et::E_READ_BYTES:
            if !is_str or !self.check_read(self_ob, path, "read_bytes"):
                return val::Value::Int(0 as i64)
            let sa = self.stored_path(path)
            let ft = if sa != "": self.save_data(sa) else: self.read_whole(self.mud_real(path))
            if !ft.ok:
                return val::Value::Int(0 as i64)
            let b = bytes_from_str(ft.text)
            let mut start = val::int_of(self.arg(args, 1)) as i32
            if start < 0:
                start = b.len() + start
            if start < 0:
                start = 0
            let ln = val::int_of(self.arg(args, 2)) as i32
            let mut end = b.len()
            if ln > 0 and start + ln < end:
                end = start + ln
            let mut o: Bytes = Bytes()
            let mut i = start
            while i < end:
                o.push(b[i])
                i += 1
            return val::Value::Str(str_from_bytes(o))
        if code == et::E_WRITE_FILE:
            if !is_str:
                self.fail("Bad argument 1 to write_file()\n")
                return val::Value::Undef
            if !self.check_write(self_ob, path, "write_file"):
                return val::Value::Int(0 as i64)
            let tv = self.arg(args, 1)
            let text = match tv:
                val::Value::Str(s) -> s
                val::Value::Int(x) -> if x == (0 as i64): "" else: vm::int_str(x)
                val::Value::Real(x) -> vm::fmt_float(x)
                _ -> ""
            let over = self.truthy(self.arg(args, 2))
            let sa = self.save_path(path)
            if sa != "":
                if !self.is_dir_path(paths::dirname(sa)):
                    return val::Value::Int(0 as i64)
                let old = if over: "" else: self.save_data(sa).text
                self.store_write(sa, concat(old, text))
                self.drop_disk_copy(sa)
                return val::Value::Int(1 as i64)
            return self.bool_v(self.write_whole(self.mud_real(path), text, !over))
        if code == et::E_WRITE_BYTES:
            if !is_str or !self.check_write(self_ob, path, "write_bytes"):
                return val::Value::Int(0 as i64)
            let text = match self.arg(args, 2):
                val::Value::Str(s) -> s
                _ -> ""
            let rp = self.mud_real(path)
            if !self.is_dir_path(paths::dirname(self.mud_abs(path))):
                return val::Value::Int(0 as i64)
            let sa = self.save_path(path)
            let old = bytes_from_str(if sa != "": self.save_data(sa).text else: self.read_whole(rp).text)
            let mut start = val::int_of(self.arg(args, 1)) as i32
            if start < 0:
                start = old.len() + start
            if start > old.len() or start < 0:
                return val::Value::Int(0 as i64)
            let tb = bytes_from_str(text)
            let mut o = bf::Buf()
            for i in 0..start:
                o.b.push(old[i])
            o.add(tb)
            let mut i = start + tb.len()
            while i < old.len():
                o.b.push(old[i])
                i += 1
            if sa != "":
                self.store_write(sa, o.to_str())
                self.drop_disk_copy(sa)
                return val::Value::Int(1 as i64)
            return self.bool_v(self.write_whole(rp, o.to_str(), false))
        if code == et::E_GET_DIR:
            if !is_str or !self.check_read(self_ob, path, "get_dir"):
                return val::Value::Int(0 as i64)
            return self.efun_get_dir(path, val::int_of(self.arg(args, 1)))
        if code == et::E_MKDIR:
            if !is_str or !self.check_write(self_ob, path, "mkdir"):
                return val::Value::Int(0 as i64)
            return self.bool_v(dir_create(self.mud_real(path)))
        if code == et::E_RMDIR:
            if !is_str or !self.check_write(self_ob, path, "rmdir"):
                return val::Value::Int(0 as i64)
            # a directory holding stored saves isn't empty
            if self.store.on and self.store_under(self.mud_abs(path)).len() > 0:
                return val::Value::Int(0 as i64)
            return self.bool_v(dir_remove(self.mud_real(path)))
        if code == et::E_RM:
            if !is_str or !self.check_write(self_ob, path, "rm"):
                return val::Value::Int(0 as i64)
            let rp = self.mud_real(path)
            let sa = self.stored_path(path)
            if sa != "":
                let r = self.store_remove(sa)
                if path_kind(rp) == 1:
                    file_remove(rp)
                return val::Value::Int(1 as i64)
            if path_kind(rp) != 1:
                return val::Value::Int(0 as i64)
            return self.bool_v(file_remove(rp))
        let tov = self.arg(args, 1)
        let to = match tov:
            val::Value::Str(s) -> s
            _ -> ""
        if code == et::E_RENAME:
            if !is_str or !self.check_write(self_ob, path, "rename") or !self.check_write(self_ob, to, "rename"):
                return val::Value::Int(1 as i64)
            if self.store.on:
                let sr = self.store_rename(path, to)
                if sr >= 0:
                    return val::Value::Int(sr as i64)
            if path_kind(self.mud_real(path)) == 0:
                return val::Value::Int(1 as i64)
            return val::Value::Int(if file_rename(self.mud_real(path), self.mud_real(to)): 0 as i64 else: 1 as i64)
        if code == et::E_CP or code == et::E_LINK:
            let r = self.efun_cp(is_str, path, to, self_ob)
            if code == et::E_LINK:
                return val::Value::Int(if r > 0: 0 as i64 else: (0 - 1) as i64)
            return val::Value::Int(r as i64)
        if code == et::E_STAT:
            if !is_str or !self.check_read(self_ob, path, "stat"):
                return val::Value::Int(0 as i64)
            let sa = self.stored_path(path)
            if sa != "":
                if let Option::Some(e) = self.store.index.get(sa):
                    return self.new_arr([val::Value::Int(e.size), val::Value::Int(e.mtime), val::Value::Int(0 as i64)])
            let rp = self.mud_real(path)
            let k = path_kind(rp)
            if k == 0:
                return self.new_arr(List<val::Value>())
            if k == 2:
                return self.new_arr([val::Value::Int((0 - 2) as i64), val::Value::Int(file_mtime(rp)), val::Value::Int(0 as i64)])
            let o = self.find_object(path)
            let lt = if o >= 0: self.objs[o].load_time else: 0 as i64
            return self.new_arr([val::Value::Int(file_size(rp)), val::Value::Int(file_mtime(rp)), val::Value::Int(lt)])
        self.fail(f"Efun {name}() is not implemented by this driver.\n")
        val::Value::Undef

    fn efun_cp(mut self, is_str: bool, from: str, to: str, self_ob: i32) -> i32:
        if !is_str or !self.check_read(self_ob, from, "move_file"):
            return -1
        if !self.check_write(self_ob, to, "move_file"):
            return -2
        let fa = self.stored_path(from)
        let ft = if fa != "": self.save_data(fa) else: self.read_whole(self.mud_real(from))
        if !ft.ok:
            return -1
        let mut dest = self.mud_real(to)
        let mut da = self.mud_abs(to)
        if self.is_dir_path(da):
            dest = concat(concat(dest, "/"), base_name_of(from))
            da = paths::combine_path(da, base_name_of(from))
        if self.save_path(da) != "":
            if !self.is_dir_path(paths::dirname(da)):
                return -1
            self.store_write(da, ft.text)
            self.drop_disk_copy(da)
            return 1
        if self.write_whole(dest, ft.text, false):
            return 1
        -1

    # rename() with the store on (efuns.pike rename()): a save, or a file
    # moving to a save name, goes through the store, and a directory takes
    # its stored saves along. The efun's answer (0 done, 1 failed), or -1 for
    # a rename the store has no part in.
    fn store_rename(mut self, from: str, to: str) -> i32:
        let fa = self.mud_abs(from)
        let mut ta = self.mud_abs(to)
        if self.is_dir_path(ta) and !self.is_dir_path(fa):
            ta = paths::combine_path(ta, base_name_of(fa))
        let to_save = str_ends_with(ta, ".o")
        if self.store_has(fa) or to_save:
            let ft = self.save_data(fa)
            if !ft.ok:
                return 1
            if to_save:
                if !self.is_dir_path(paths::dirname(ta)):
                    return 1
                self.store_write(ta, ft.text)
                self.drop_disk_copy(ta)
            elif !self.write_whole(self.mud_real(ta), ft.text, false):
                return 1
            if !self.store_remove(fa) or path_kind(self.mud_real(fa)) == 1:
                file_remove(self.mud_real(fa))
            return 0
        if self.is_dir_path(fa):
            if !file_rename(self.mud_real(from), self.mud_real(to)):
                return 1
            self.store_move_tree(fa, self.mud_abs(to))
            return 0
        -1

    # read_file(path, start, lines) once the read was allowed
    fn read_text(mut self, self_ob: i32, path: str, args: List<val::Value>, ranged: bool) -> val::Value:
        let sa = self.stored_path(path)
        let ft = if sa != "": self.save_data(sa) else: self.read_whole(self.mud_real(path))
        if !ft.ok:
            return val::Value::Int(0 as i64)
        let mut s = ft.text
        if str_contains(s, "\r"):
            s = str_replace(s, "\r\n", "\n")
        if !ranged:
            return val::Value::Str(s)
        let mut start = val::int_of(self.arg(args, 1)) as i32
        let ln = val::int_of(self.arg(args, 2)) as i32
        if start == 0 and ln == 0:
            return val::Value::Str(s)
        let lines = str_split(s, "\n")
        if start > 0:
            start -= 1
        if start < 0:
            start = 0
        if start >= lines.len():
            return val::Value::Int(0 as i64)
        let mut end = lines.len()
        if ln > 0 and start + ln < end:
            end = start + ln
        let mut part: List<str> = List<str>()
        for i in start..end:
            part.push(lines[i])
        let mut out = str_join(part, "\n")
        if ln > 0 and part.len() == ln:
            out = concat(out, "\n")
        val::Value::Str(out)

    # get_dir(path, flag): efuns.pike get_dir(); stored saves show up in
    # their directory
    fn efun_get_dir(mut self, path: str, flag: i64) -> val::Value:
        let abs = self.mud_abs(path)
        let rp = self.mud_real(path)
        let mut dir = rp
        let mut pat = ""
        let mut has_pat = false
        if !self.is_dir_path(abs):
            dir = paths::dirname(rp)
            pat = base_name_of(strip_slash(abs))
            has_pat = true
            if !self.is_dir_path(paths::dirname(abs)):
                return self.new_arr(List<val::Value>())
        elif !str_ends_with(path, "/"):
            # "dir" without its slash names the directory entry itself
            pat = base_name_of(strip_slash(abs))
            dir = paths::dirname(rp)
            has_pat = true
        let mut names = dir_list(dir)
        let mut ldir = ""
        if self.store.on:
            ldir = if has_pat: paths::dirname(abs) else: strip_slash(abs)
            let saved = self.store_list(ldir)
            if saved.len() > 0:
                let mut seen: Set<str> = Set<str>()
                for i in 0..names.len():
                    seen.insert(names[i])
                for i in 0..saved.len():
                    if !seen.contains(saved[i]):
                        names.push(saved[i])
        if has_pat:
            let mut keep: List<str> = List<str>()
            if str_contains(pat, "*") or str_contains(pat, "?"):
                let pb = bytes_from_str(pat)
                for i in 0..names.len():
                    if glob_match(bytes_from_str(names[i]), pb, 0, 0):
                        keep.push(names[i])
            else:
                for i in 0..names.len():
                    if names[i] == pat:
                        keep.push(names[i])
            names = keep
        names = sort_strs(names)
        let mut out: List<val::Value> = List<val::Value>()
        for i in 0..names.len():
            if flag == ((0 - 1) as i64):
                if self.store.on:
                    if let Option::Some(e) = self.store.index.get(paths::combine_path(ldir, names[i])):
                        out.push(self.new_arr([val::Value::Str(names[i]), val::Value::Int(e.size), val::Value::Int(e.mtime)]))
                        continue
                let p = concat(concat(dir, "/"), names[i])
                let k = path_kind(p)
                let size = if k == 0: (0 - 1) as i64 elif k == 2: (0 - 2) as i64 else: file_size(p)
                let mt = if k == 0: 0 as i64 else: file_mtime(p)
                out.push(self.new_arr([val::Value::Str(names[i]), val::Value::Int(size), val::Value::Int(mt)]))
            else:
                out.push(val::Value::Str(names[i]))
        self.new_arr(out)

    fn efun_save_restore(mut self, save: bool, args: List<val::Value>, self_ob: i32) -> val::Value:
        let fv = self.arg(args, 0)
        let file = match fv:
            val::Value::Str(s) -> s
            _ -> ""
        let ok = match fv:
            val::Value::Str(s) -> true
            _ -> false
        if !ok:
            self.fail(if save: "Bad argument 1 to save_object()\n" else: "Bad argument 1 to restore_object()\n")
            return val::Value::Undef
        let path = if str_ends_with(file, ".o"): file else: concat(file, ".o")
        if self_ob < 0:
            return val::Value::Int(0 as i64)
        if save:
            if !self.check_write(self_ob, path, "save_object"):
                # an error inside valid_write itself propagates as it is
                self.fail("Denied write permission in save_object().\n")
                return val::Value::Undef
            let text = self.encode_object(self_ob, (val::int_of(self.arg(args, 1)) & (1 as i64)) != (0 as i64))
            if !self.is_dir_path(paths::dirname(self.mud_abs(path))):
                return val::Value::Int(0 as i64)
            if self.store.on:
                let a = self.mud_abs(path)
                self.store_write(a, text)
                self.drop_disk_copy(a)
                return val::Value::Int(1 as i64)
            # a temp file renamed over the old save, so a crash mid-write
            # never leaves the save missing
            let rp = self.mud_real(path)
            let tmp = concat(rp, ".tmp")
            if !self.write_whole(tmp, text, false):
                return val::Value::Int(0 as i64)
            return self.bool_v(file_rename(tmp, rp))
        if !self.check_read(self_ob, path, "restore_object"):
            self.fail("Denied read permission in restore_object().\n")
            return val::Value::Undef
        let sa = self.stored_path(path)
        let ft = if sa != "": self.save_data(sa) else: self.read_whole(self.mud_real(path))
        if !ft.ok:
            return val::Value::Int(0 as i64)
        self.decode_object(self_ob, ft.text, !self.truthy(self.arg(args, 1)))
        if self.err:
            return val::Value::Undef
        val::Value::Int(1 as i64)

struct FileText:
    ok: bool
    text: str

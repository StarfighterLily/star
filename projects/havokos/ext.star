# The reference's HavokOS-only extensions -- todo.md HavokOS P1 #6 (M7 part
# 3): every efun `boot_ds.exe -unimplemented` still listed that needs no
# outside library (efun codes 402-416; json_encode()/json_decode() are in
# `json.star`), with the driver machinery behind them, each following
# `havok/efuns.pike` and `havok/driver.pike` (or `lpc/compiler.pike`):
#
# - astar_path(): the grid A* search, line for line: the same binary heap
#   with insertion order breaking ties, so the same path, node table and
#   "most cells waiting" come out. Its estimate is in doubles (deviation #3;
#   the reference's floats are 32-bit), which only shows past the 6th digit.
# - find_files(): the reference crawls in a thread and answers by call_out;
#   here the crawl runs at the call (Star has no threads the VM could share)
#   and the answer comes on the driver's next pass (`run_finds()`, from
#   net_poll(), like resolve()'s), so the callback still never runs inside
#   the caller's evaluation. Directories the caller may not read are dropped
#   then, through the master, as in the reference, and the matching saves
#   the save store holds join their directories' results (P1 #10,
#   `savestore.star`). NOTES.md deviation #20.
# - watch_path()/unwatch_path(): driver.pike's "File watching" -- listings
#   show added and removed files at once, `havok watch stats` (40) stats a
#   tick spread edits out, every `havok watch interval` (2) seconds from the
#   driver's timer step; files_changed(string *files) to each watcher.
# - quota_info()/quota_refresh() and the quotas themselves (driver.pike
#   "Resource quotas"): the master's quota_group()/quota_limits()/
#   quota_exceeded(), clones and pending call_outs counted per group and
#   refused over the limit, call_out and heart beat wall time charged per
#   minute.
# - stale_programs()/dependents() (compiler.pike "Dependencies"): each
#   compile records its source and include stats and its inherits' stamps;
#   a stamp is a hash of the program's token stream and its inherits'
#   stamps (the reference hashes its generated Pike source), so recompiling
#   unchanged code keeps it.
# - function_profile()/profile_start()/profile_stop()/profile_report(): with
#   `havok profiling` every named LPC function's calls, self and callee time
#   (the reference instruments the code it emits; here the interpreter's
#   frame entry and return do it, so no recompile is needed, though the
#   reference needs one), else the sampling profiler, which charges the
#   time between samples to the stack at the evaluation-limit tick, the
#   reference's own mechanism. Efun calls are counted for opcprof() while
#   profiling -- every call, where the reference counts only instrumented
#   code's (deviation #21).
# - cache_stats(), malloc_status(), memory_summary(): the same reports, with
#   this driver's own numbers (deviation #19): there's no function lookup
#   cache (calls resolve through per-program dispatch tables built at
#   compile time), no disk cache of compiled programs, and no allocator to
#   ask, so malloc_status() estimates each value table's size from what it
#   holds.
#
# The SQLite efuns (db_open() and the rest) are `sqldb.star`'s (P1 #7). Still
# not here: http_respond() (the HTTP ports), which needs the HTTP and TLS
# layers.

import "value.star" as val
import "vm.star" as vm
import "efun_table.star" as et
import "extdata.star" as xd
import "paths.star" as paths
import "efuns_file.star" as ef
import "buf.star" as bf
import "token.star" as tk
import "program.star" as pg

fn base_of(p: str) -> str:
    let parts = str_split(p, "/")
    parts[parts.len() - 1]

fn wjoin(d: str, n: str) -> str:
    if d == "/":
        return concat("/", n)
    concat(concat(d, "/"), n)

fn idx_of(l: List<str>, s: str) -> i32:
    for i in 0..l.len():
        if l[i] == s:
            return i
    -1

fn hex64(h: i64) -> str:
    let digits = bytes_from_str("0123456789abcdef")
    let mut o: Bytes = Bytes()
    let mut x = h
    for i in 0..16:
        let d = vm::wshr(x, (60 - i * 4) as i64) % (16 as i64)
        let dd = if d < (0 as i64): d + (16 as i64) else: d
        o.push(digits[dd as i32])
    str_from_bytes(o)

# FNV-1a over a string's bytes, then a 0 separator.
fn fnv_str(h_in: i64, s: str) -> i64:
    let b = bytes_from_str(s)
    let mut h = h_in
    # the 64-bit FNV prime, 2^40 + 435
    let prime = vm::wmul(16777216 as i64, 65536 as i64) + (435 as i64)
    for i in 0..b.len():
        h = h ^ (b[i] as i64)
        h = vm::wmul(h, prime)
    vm::wmul(h, prime)

# Any fixed start does for a stamp; this is FNV's own offset basis
# (0xcbf29ce484222325), built up since literals stop at 2^31.
fn fnv_seed() -> i64:
    let hi = vm::wmul(52210 as i64, 65536 as i64) + (40164 as i64)
    let lo = vm::wmul(33826 as i64, 65536 as i64) + (8997 as i64)
    vm::wadd(vm::wmul(hi, vm::wmul(65536 as i64, 65536 as i64)), lo)

# A min-heap entry of the A* open list: f, then insertion order.
fn heap_before(fa: f64, sa: i32, fb: f64, sb: i32) -> bool:
    fa < fb or (fa == fb and sa < sb)

struct WantList:
    mut dirs: List<str> = List<str>()
    mut levels: List<i32> = List<i32>()

impl vm::Vm:
    fn efun_ext(mut self, code: i32, name: str, args: List<val::Value>, self_ob: i32) -> val::Value:
        let zero = val::Value::Int(0 as i64)
        if code == et::E_ASTAR_PATH:
            return self.efun_astar(args)
        if code == et::E_FIND_FILES:
            return val::Value::Int(self.efun_find_files(args, self_ob) as i64)
        if code == et::E_WATCH_PATH:
            match self.arg(args, 0):
                val::Value::Str(d) ->
                    if !self.check_read(self_ob, d, "watch_path"):
                        if self.err:
                            return val::Value::Undef
                        return zero
                    return val::Value::Int(self.watch_add(self_ob, self.mud_abs(d), self.truthy(self.arg(args, 1))) as i64)
                _ ->
                    return zero
        if code == et::E_UNWATCH_PATH:
            if args.len() < 1:
                self.unwatch(self_ob, "", true)
            else:
                match args[0]:
                    val::Value::Str(d) ->
                        self.unwatch(self_ob, self.mud_abs(d), false)
                    _ -> 0
            return zero
        if code == et::E_QUOTA_INFO:
            if args.len() < 1:
                return self.quota_info_all()
            match args[0]:
                val::Value::Str(g) ->
                    return self.quota_info_one(g)
                _ ->
                    return zero
        if code == et::E_QUOTA_REFRESH:
            self.quota_lims = Map<str, xd::QuotaLimits>()
            return zero
        if code == et::E_STALE_PROGRAMS:
            return self.efun_stale_programs(args)
        if code == et::E_DEPENDENTS:
            match self.arg(args, 0):
                val::Value::Str(f) ->
                    let mut file = self.mud_abs(f)
                    if !str_contains(base_of(file), "."):
                        file = concat(file, ".c")
                    return self.dot_c_list(self.dependents_of(file))
                _ ->
                    self.fail("Bad argument 1 to dependents()\n")
                    return val::Value::Undef
        if code == et::E_FUNCTION_PROFILE:
            return self.efun_function_profile(args, self_ob)
        if code == et::E_PROFILE_START:
            let iv = self.arg(args, 0)
            if !self.is_int(iv):
                self.fail("Bad argument 1 to profile_start()\n")
                return val::Value::Undef
            let n = val::int_of(iv)
            self.profile_start(if n != (0 as i64): n else: 1000 as i64)
            return zero
        if code == et::E_PROFILE_STOP:
            self.sample_interval = 0 as i64
            return zero
        if code == et::E_PROFILE_REPORT:
            return self.profile_report(self.truthy(self.arg(args, 0)))
        if code == et::E_CACHE_STATS:
            return self.efun_cache_stats(self_ob)
        if code == et::E_MALLOC_STATUS:
            return self.efun_malloc_status(self_ob)
        if code == et::E_MEMORY_SUMMARY:
            return val::Value::Map(self.new_map())
        self.fail(f"Efun {name}() is not implemented by this driver.\n")
        val::Value::Undef

    fn str_list_value(mut self, l: List<str>) -> val::Value:
        let mut out: List<val::Value> = List<val::Value>()
        for i in 0..l.len():
            out.push(val::Value::Str(l[i]))
        self.new_arr(out)

    fn dot_c_list(mut self, l: List<str>) -> val::Value:
        let mut out: List<val::Value> = List<val::Value>()
        for i in 0..l.len():
            out.push(val::Value::Str(concat(l[i], ".c")))
        self.new_arr(out)

    fn num_f(self, v: val::Value) -> f64:
        match v:
            val::Value::Int(x) -> x as f64
            val::Value::Real(x) -> x
            _ -> 0.0 as f64

    # --- astar_path() -------------------------------------------------------------

    # astar_path(map, sx, sy, gx, gy, costs): `map` is lines of cells, padded
    # to the longest; `costs` maps each walkable character to its step cost.
    # Moves are e, n, w, s; the estimate is 0.975 times the straight-line
    # distance. ({ path, ([ pos: ({ parent, x, y, g, h, g + h }) ]), most
    # cells waiting at once }), or ({}) when there is no way.
    fn efun_astar(mut self, args: List<val::Value>) -> val::Value:
        let empty = self.new_arr(List<val::Value>())
        let mut text = ""
        match self.arg(args, 0):
            val::Value::Str(s) ->
                text = s
            _ ->
                return empty
        let mut ch = -1
        match self.arg(args, 5):
            val::Value::Map(h) ->
                ch = h
            _ ->
                return empty
        let mut rows: List<Bytes> = List<Bytes>()
        let tb = bytes_from_str(text)
        let mut cur: Bytes = Bytes()
        for i in 0..tb.len():
            if (tb[i] as i32) == 10:
                rows.push(cur)
                cur = Bytes()
            else:
                cur.push(tb[i])
        # Pike's `map / "\n"` ends with the piece after the last newline,
        # which is dropped when empty
        if cur.len() > 0:
            rows.push(cur)
        let hgt = rows.len()
        let mut w = 0
        for i in 0..hgt:
            if rows[i].len() > w:
                w = rows[i].len()
        let sx = val::int_of(self.arg(args, 1))
        let sy = val::int_of(self.arg(args, 2))
        let gx = val::int_of(self.arg(args, 3))
        let gy = val::int_of(self.arg(args, 4))
        if !self.astar_walkable(rows, w, ch, sx, sy) or !self.astar_walkable(rows, w, ch, gx, gy):
            return empty
        let k975 = (975.0 as f64) / (1000.0 as f64)
        let start = (sx + sy * (w as i64)) as i32
        let goal = (gx + gy * (w as i64)) as i32
        # the node table, by position through `at`, in the order reached
        let mut at: Map<i32, i32> = Map<i32, i32>()
        let mut npos: List<i32> = List<i32>()
        let mut npar: List<i32> = List<i32>()
        let mut ng: List<val::Value> = List<val::Value>()
        let mut nh: List<f64> = List<f64>()
        let mut nf: List<f64> = List<f64>()
        let sdx = (sx - gx) as f64
        let sdy = (sy - gy) as f64
        let h0 = sqrt(sdx * sdx + sdy * sdy) * k975
        at.insert(start, 0)
        npos.push(start)
        npar.push(-1)
        ng.push(val::Value::Int(0 as i64))
        nh.push(h0)
        nf.push(h0)
        let mut closed: Set<i32> = Set<i32>()
        # the binary min-heap of (f, seq, pos); stale entries are skipped
        let mut hf: List<f64> = List<f64>()
        let mut hs: List<i32> = List<i32>()
        let mut hp: List<i32> = List<i32>()
        hf.push(h0)
        hs.push(0)
        hp.push(start)
        let mut seq = 1
        let mut most = 1
        let dxs = [1, 0, -1, 0]
        let dys = [0, -1, 0, 1]
        while hf.len() > 0 and !closed.contains(goal):
            # pop the least entry
            let topf = hf[0]
            let ep = hp[0]
            let last = hf.len() - 1
            let lf = hf[last]
            let ls = hs[last]
            let lp = hp[last]
            hf.pop()
            hs.pop()
            hp.pop()
            if hf.len() > 0:
                hf[0] = lf
                hs[0] = ls
                hp[0] = lp
                let n = hf.len()
                let mut i = 0
                while true:
                    let l = 2 * i + 1
                    let r = l + 1
                    let mut m = i
                    if l < n and heap_before(hf[l], hs[l], hf[m], hs[m]):
                        m = l
                    if r < n and heap_before(hf[r], hs[r], hf[m], hs[m]):
                        m = r
                    if m == i:
                        break
                    let tf = hf[i]
                    let ts = hs[i]
                    let tp = hp[i]
                    hf[i] = hf[m]
                    hs[i] = hs[m]
                    hp[i] = hp[m]
                    hf[m] = tf
                    hs[m] = ts
                    hp[m] = tp
                    i = m
            let mut ci = -1
            if let Option::Some(x) = at.get(ep):
                ci = x
            if closed.contains(ep) or topf > nf[ci]:
                continue
            closed.insert(ep)
            let cx = ep % w
            let cy = ep / w
            for k in 0..4:
                let nx = cx + dxs[k]
                let ny = cy + dys[k]
                if !self.astar_walkable(rows, w, ch, nx as i64, ny as i64):
                    continue
                let np = nx + ny * w
                if closed.contains(np):
                    continue
                let cost = self.map_get(ch, val::Value::Int(rows[ny][nx] as i64))
                let g = self.binop(pg::B_ADD, ng[ci], cost)
                if self.err:
                    return val::Value::Undef
                let mut ni = -1
                if let Option::Some(x) = at.get(np):
                    ni = x
                if ni >= 0 and self.num_f(g) >= self.num_f(ng[ni]):
                    continue
                let ddx = (nx as i64 - gx) as f64
                let ddy = (ny as i64 - gy) as f64
                let h = sqrt(ddx * ddx + ddy * ddy) * k975
                let f = self.num_f(g) + h
                if ni < 0:
                    ni = npos.len()
                    at.insert(np, ni)
                    npos.push(np)
                    npar.push(ep)
                    ng.push(g)
                    nh.push(h)
                    nf.push(f)
                else:
                    npar[ni] = ep
                    ng[ni] = g
                    nh[ni] = h
                    nf[ni] = f
                # push (f, seq, np) and sift it up
                hf.push(f)
                hs.push(seq)
                hp.push(np)
                seq += 1
                let mut j = hf.len() - 1
                while j > 0:
                    let p = (j - 1) / 2
                    if !heap_before(hf[j], hs[j], hf[p], hs[p]):
                        break
                    let tf = hf[j]
                    let ts = hs[j]
                    let tp = hp[j]
                    hf[j] = hf[p]
                    hs[j] = hs[p]
                    hp[j] = hp[p]
                    hf[p] = tf
                    hs[p] = ts
                    hp[p] = tp
                    j = p
                if hf.len() > most:
                    most = hf.len()
        if !closed.contains(goal):
            return empty
        let mut path: List<i32> = List<i32>()
        let mut p = goal
        while p != start:
            let mut ni = 0
            if let Option::Some(x) = at.get(p):
                ni = x
            let parent = npar[ni]
            let dx = p % w - parent % w
            let dy = p / w - parent / w
            path.push(if dx > 0: 101 elif dx < 0: 119 elif dy < 0: 110 else: 115)
            p = parent
        let mut pb: Bytes = Bytes()
        let mut q = path.len() - 1
        while q >= 0:
            pb.push(path[q] as u8)
            q -= 1
        let nodes = self.new_map()
        for i in 0..npos.len():
            let row = [val::Value::Int(npar[i] as i64), val::Value::Int((npos[i] % w) as i64), val::Value::Int((npos[i] / w) as i64), ng[i], val::Value::Real(nh[i]), val::Value::Real(nf[i])]
            let a = self.new_arr(row)
            self.map_set(nodes, val::Value::Int(npos[i] as i64), a)
        self.new_arr([val::Value::Str(str_from_bytes(pb)), val::Value::Map(nodes), val::Value::Int(most as i64)])

    fn astar_walkable(self, rows: List<Bytes>, w: i32, ch: i32, x: i64, y: i64) -> bool:
        if x < (0 as i64) or y < (0 as i64) or x >= (w as i64) or y >= (rows.len() as i64):
            return false
        let r = rows[y as i32]
        if x >= (r.len() as i64):
            return false
        self.map_find(ch, val::Value::Int(r[x as i32] as i64)) >= 0

    # --- find_files() -------------------------------------------------------------

    # find_files(dir, pattern, callback, skip): 1 if the crawl started, 0 if
    # dir isn't a readable directory (or an argument is wrong). The answer,
    # callback(files, dirs), comes on the next pass (run_finds()).
    fn efun_find_files(mut self, args: List<val::Value>, self_ob: i32) -> i32:
        let mut dir = ""
        let mut pat = ""
        match self.arg(args, 0):
            val::Value::Str(s) ->
                dir = s
            _ ->
                return 0
        match self.arg(args, 1):
            val::Value::Str(s) ->
                pat = s
            _ ->
                return 0
        let cb = self.arg(args, 2)
        let callable = match cb:
            val::Value::Fn(h) -> !self.fn_dead(h)
            _ -> false
        if !callable:
            return 0
        if !self.check_read(self_ob, dir, "find_files"):
            return 0
        let mut root = self.mud_abs(dir)
        if str_ends_with(root, "/") and len(root) > 1:
            root = vm::substr(root, 0, len(root) - 1)
        if !self.is_dir_path(root):
            return 0
        let mut skips: List<str> = List<str>()
        match self.arg(args, 3):
            val::Value::Arr(h) ->
                let items = self.arrs[h].items
                for i in 0..items.len():
                    match items[i]:
                        val::Value::Str(s) ->
                            skips.push(s)
                        _ -> 0
            _ -> 0
        let pb = bytes_from_str(pat)
        let mut dirs: List<str> = List<str>()
        let mut files: List<List<str>> = List<List<str>>()
        let mut todo: List<str> = List<str>()
        todo.push(root)
        let mut qi = 0
        while qi < todo.len():
            let d = todo[qi]
            qi += 1
            let names = ef::sort_strs(dir_list(if d == "/": self.root else: concat(self.root, d)))
            let mut matched: List<str> = List<str>()
            for i in 0..names.len():
                let n = names[i]
                let p = wjoin(d, n)
                let k = path_kind(concat(self.root, p))
                if k == 0:
                    continue
                if k != 2:
                    if ef::glob_match(bytes_from_str(n), pb, 0, 0):
                        matched.push(n)
                    continue
                let mut skipped = false
                for s in 0..skips.len():
                    if str_starts_with(p, skips[s]):
                        skipped = true
                if !skipped:
                    todo.push(p)
            dirs.push(d)
            files.push(matched)
        let mut saved: List<str> = List<str>()
        if self.store.on:
            let under = self.store_under(root)
            for i in 0..under.len():
                if ef::glob_match(bytes_from_str(ef::base_name_of(under[i])), pb, 0, 0):
                    saved.push(under[i])
        self.finds.push(xd::PendingFind(ob = self.obj_value(self_ob), root = root, dirs = dirs, files = files, cb = cb, saved = saved))
        1

    # The answers of the crawls the last pass made (driver found_files()),
    # each its own top-level evaluation: directories the caller may not read
    # are left out, then callback(files, dirs), both sorted.
    fn run_finds(mut self):
        if self.finds.len() == 0:
            return
        let todo = self.finds
        self.finds = List<xd::PendingFind>()
        for i in 0..todo.len():
            let f = todo[i]
            let o = self.obj_of(f.ob)
            if o < 0:
                continue
            let ol = self.ostack.len()
            let sl = self.stack.len()
            self.begin_eval()
            let mut out: List<str> = List<str>()
            let mut dirs: List<str> = List<str>()
            for k in 0..f.dirs.len():
                let d = f.dirs[k]
                # listing a directory reads "dir/", as get_dir() does
                if d != f.root and !self.check_read(o, concat(d, "/"), "find_files"):
                    if self.err:
                        break
                    continue
                if d != f.root:
                    dirs.push(d)
                let names = f.files[k]
                for j in 0..names.len():
                    out.push(wjoin(d, names[j]))
                for j in 0..f.saved.len():
                    if paths::dirname(f.saved[j]) == d:
                        out.push(f.saved[j])
            if !self.err:
                # a save both stored and on disk is listed once (Array.uniq)
                let mut seen: Set<str> = Set<str>()
                let mut uniq: List<str> = List<str>()
                for j in 0..out.len():
                    if !seen.contains(out[j]):
                        seen.insert(out[j])
                        uniq.push(out[j])
                out = uniq
                let files_v = self.str_list_value(ef::sort_strs(out))
                let dirs_v = self.str_list_value(ef::sort_strs(dirs))
                self.run_fn_value(o, f.cb, [files_v, dirs_v])
            if self.err:
                self.report_error("find_files callback")
            self.truncate_ostack(ol)
            self.truncate_stack(sl)
            self.end_eval()

    # --- file watching ------------------------------------------------------------

    fn watch_real(self, lpc: str) -> str:
        if lpc == "/":
            return self.root
        concat(self.root, lpc)

    fn watch_dir_at(self, path: str) -> i32:
        for i in 0..self.watch_dirs.len():
            if self.watch_dirs[i].path == path:
                return i
        -1

    fn watcher_at(self, o: i32) -> i32:
        for i in 0..self.watchers.len():
            if self.obj_of(self.watchers[i].ob) == o:
                return i
        -1

    # List a watched directory: the files added and removed since the last
    # listing (none reported when `quiet`, the first time), keeping its
    # subdirectories up to date (driver watch_list()).
    fn watch_list(mut self, wi: i32, quiet: bool) -> List<str>:
        let w = self.watch_dirs[wi]
        let real = self.watch_real(w.path)
        let mut out: List<str> = List<str>()
        if path_kind(real) != 2:
            for i in 0..w.names.len():
                out.push(wjoin(w.path, w.names[i]))
            self.watch_dirs[wi] = xd::WatchDir(path = w.path)
            return out
        let names = dir_list(real)
        let mut seen: Set<str> = Set<str>()
        for i in 0..names.len():
            seen.insert(names[i])
        let mut nn: List<str> = List<str>()
        let mut nm: List<i64> = List<i64>()
        let mut ns: List<i64> = List<i64>()
        let mut have: Set<str> = Set<str>()
        for i in 0..w.names.len():
            if seen.contains(w.names[i]):
                nn.push(w.names[i])
                nm.push(w.mtimes[i])
                ns.push(w.sizes[i])
                have.insert(w.names[i])
            else:
                out.push(wjoin(w.path, w.names[i]))
        let mut subs: List<str> = List<str>()
        for i in 0..w.subdirs.len():
            if seen.contains(w.subdirs[i]):
                subs.push(w.subdirs[i])
                have.insert(w.subdirs[i])
        for i in 0..names.len():
            let n = names[i]
            if have.contains(n):
                continue
            let rp = self.watch_real(wjoin(w.path, n))
            let k = path_kind(rp)
            if k == 0:
                continue
            if k == 2:
                subs.push(n)
                continue
            nn.push(n)
            nm.push(file_mtime(rp))
            ns.push(file_size(rp))
            if !quiet:
                out.push(wjoin(w.path, n))
        self.watch_dirs[wi] = xd::WatchDir(path = w.path, names = nn, mtimes = nm, sizes = ns, subdirs = subs)
        out

    # The directories the watchers ask for, with the subdirectories of
    # recursive watches as far as they have been listed (driver
    # watch_wanted()); watchers that were destructed are dropped.
    fn watch_wanted(mut self) -> WantList:
        let mut keep: List<xd::Watcher> = List<xd::Watcher>()
        for i in 0..self.watchers.len():
            if self.obj_of(self.watchers[i].ob) >= 0:
                keep.push(self.watchers[i])
        self.watchers = keep
        let mut want = WantList()
        let mut at: Map<str, i32> = Map<str, i32>()
        let mut sd: List<str> = List<str>()
        let mut sr: List<i32> = List<i32>()
        for i in 0..self.watchers.len():
            let x = self.watchers[i]
            for k in 0..x.dirs.len():
                sd.push(x.dirs[k])
                sr.push(if x.recs[k]: 1 else: 0)
        while sd.len() > 0:
            let d = sd[sd.len() - 1]
            let rec = sr[sr.len() - 1]
            sd.pop()
            sr.pop()
            let mut cur = 0
            let mut ai = -1
            if let Option::Some(x) = at.get(d):
                ai = x
                cur = want.levels[x]
            if cur > rec:
                continue
            if ai < 0:
                at.insert(d, want.dirs.len())
                want.dirs.push(d)
                want.levels.push(rec + 1)
            else:
                want.levels[ai] = rec + 1
            let wi = self.watch_dir_at(d)
            if rec > 0 and wi >= 0:
                let subs = self.watch_dirs[wi].subdirs
                for s in 0..subs.len():
                    sd.push(wjoin(d, subs[s]))
                    sr.push(1)
        want

    # Bring the watched directories in line with the watchers; new ones are
    # listed quietly, their files the baseline (driver watch_sync()).
    fn watch_sync(mut self):
        let mut grew = true
        while grew:
            grew = false
            let want = self.watch_wanted()
            let mut keep: List<xd::WatchDir> = List<xd::WatchDir>()
            for i in 0..self.watch_dirs.len():
                if idx_of(want.dirs, self.watch_dirs[i].path) >= 0:
                    keep.push(self.watch_dirs[i])
            self.watch_dirs = keep
            for i in 0..want.dirs.len():
                if self.watch_dir_at(want.dirs[i]) >= 0:
                    continue
                self.watch_dirs.push(xd::WatchDir(path = want.dirs[i]))
                let wi = self.watch_dirs.len() - 1
                self.watch_list(wi, true)
                if self.watch_dirs[wi].subdirs.len() > 0:
                    grew = true

    fn watch_interval_ms(self) -> i64:
        let v = val::int_of(self.cfg_int("havok watch interval", 2 as i64))
        (if v > (0 as i64): v else: 2 as i64) * (1000 as i64)

    # driver watch_path(): 0 unless dir is a directory.
    fn watch_add(mut self, o: i32, dir_in: str, recursive: bool) -> i32:
        let dir = paths::combine_path("/", dir_in)
        if path_kind(self.watch_real(dir)) != 2:
            return 0
        let mut wi = self.watcher_at(o)
        if wi < 0:
            self.watchers.push(xd::Watcher(ob = self.obj_value(o)))
            wi = self.watchers.len() - 1
        let k = idx_of(self.watchers[wi].dirs, dir)
        if k >= 0:
            self.watchers[wi].recs[k] = recursive
        else:
            self.watchers[wi].dirs.push(dir)
            self.watchers[wi].recs.push(recursive)
        self.objs[o].watching = true
        self.watch_sync()
        if self.next_watch_ms == (0 as i64):
            self.next_watch_ms = clock_ms() + self.watch_interval_ms()
        1

    # driver unwatch_path(): one directory, or every one (`all`).
    fn unwatch(mut self, o: i32, dir_in: str, all: bool):
        let wi = self.watcher_at(o)
        if wi < 0:
            return
        let mut drop = all
        if !all:
            let dir = paths::combine_path("/", dir_in)
            let w = self.watchers[wi]
            let mut nd: List<str> = List<str>()
            let mut nr: List<bool> = List<bool>()
            for i in 0..w.dirs.len():
                if w.dirs[i] != dir:
                    nd.push(w.dirs[i])
                    nr.push(w.recs[i])
            self.watchers[wi].dirs = nd
            self.watchers[wi].recs = nr
            drop = nd.len() == 0
        if drop:
            let mut keep: List<xd::Watcher> = List<xd::Watcher>()
            for i in 0..self.watchers.len():
                if i != wi:
                    keep.push(self.watchers[i])
            self.watchers = keep
            if o > 0 and o < self.objs.len():
                self.objs[o].watching = false
        self.watch_sync()

    # One poll (driver watch_poll()): every listing, then the next
    # `havok watch stats` files' stats; the changed files, sorted, go to
    # their watchers.
    fn watch_poll(mut self) -> List<str>:
        let mut changed: List<str> = List<str>()
        let mut grew = false
        for wi in 0..self.watch_dirs.len():
            let before = self.watch_dirs[wi].subdirs.len()
            let got = self.watch_list(wi, false)
            for i in 0..got.len():
                changed.push(got[i])
            if self.watch_dirs[wi].subdirs.len() != before:
                grew = true
        if grew:
            # new subdirectories of recursive watches: their files are new too
            let mut had: Set<str> = Set<str>()
            for i in 0..self.watch_dirs.len():
                had.insert(self.watch_dirs[i].path)
            self.watch_sync()
            for i in 0..self.watch_dirs.len():
                let w = self.watch_dirs[i]
                if had.contains(w.path):
                    continue
                for k in 0..w.names.len():
                    changed.push(wjoin(w.path, w.names[k]))
        let stats = val::int_of(self.cfg_int("havok watch stats", 40 as i64)) as i32
        let mut n = stats
        while n > 0:
            if self.watch_qi >= self.watch_queue.len():
                if n < stats:
                    break
                # a new round
                let mut q: List<str> = List<str>()
                for i in 0..self.watch_dirs.len():
                    let w = self.watch_dirs[i]
                    for k in 0..w.names.len():
                        q.push(wjoin(w.path, w.names[k]))
                self.watch_queue = q
                self.watch_qi = 0
                if q.len() == 0:
                    break
            let f = self.watch_queue[self.watch_qi]
            self.watch_qi += 1
            n -= 1
            let wi = self.watch_dir_at(paths::dirname(f))
            if wi < 0:
                continue
            let k = idx_of(self.watch_dirs[wi].names, base_of(f))
            if k < 0:
                continue
            let rp = self.watch_real(f)
            let kind = path_kind(rp)
            # a removal shows in the next listing
            if kind == 0 or kind == 2:
                continue
            let mt = file_mtime(rp)
            let sz = file_size(rp)
            if mt != self.watch_dirs[wi].mtimes[k] or sz != self.watch_dirs[wi].sizes[k]:
                self.watch_dirs[wi].mtimes[k] = mt
                self.watch_dirs[wi].sizes[k] = sz
                changed.push(f)
        let sorted = ef::sort_strs(changed)
        let mut uniq: List<str> = List<str>()
        for i in 0..sorted.len():
            if uniq.len() == 0 or uniq[uniq.len() - 1] != sorted[i]:
                uniq.push(sorted[i])
        if uniq.len() > 0:
            self.watch_deliver(uniq)
        uniq

    # files_changed(files) to each watcher, with the files under the
    # directories it watches (driver watch_deliver()).
    fn watch_deliver(mut self, changed: List<str>):
        let ws = self.watchers
        for i in 0..ws.len():
            let o = self.obj_of(ws[i].ob)
            if o < 0:
                continue
            let mut mine: List<str> = List<str>()
            for c in 0..changed.len():
                let d = paths::dirname(changed[c])
                let mut hit = false
                for k in 0..ws[i].dirs.len():
                    let w = ws[i].dirs[k]
                    if d == w or (ws[i].recs[k] and str_starts_with(d, wjoin(w, ""))):
                        hit = true
                if hit:
                    mine.push(changed[c])
            if mine.len() > 0:
                let a = self.str_list_value(mine)
                self.safe_apply(o, "files_changed", [a], concat("files_changed in ", self.obj_name(o)))

    # The driver's timer step (objects.star driver_tick()): a poll every
    # `havok watch interval` seconds while anything is watched.
    fn watch_tick(mut self, now: i64):
        if self.next_watch_ms == (0 as i64) or now < self.next_watch_ms:
            return
        self.watch_poll()
        if self.watchers.len() > 0:
            self.next_watch_ms = now + self.watch_interval_ms()
        else:
            self.next_watch_ms = 0 as i64

    # --- resource quotas ----------------------------------------------------------

    # The group the master files a base name in, asked once per base name
    # (driver quota_group()); "" with qhas false for none. Before the master
    # is established nothing is asked or remembered.
    fn quota_assign(mut self, o: i32, base: str):
        self.objs[o].qhas = false
        self.objs[o].qgroup = ""
        if let Option::Some(g) = self.quota_groups.get(base):
            self.objs[o].qhas = true
            self.objs[o].qgroup = g
            return
        if self.quota_none.contains(base):
            return
        if !self.alive(self.master_ob) or !self.master_established:
            return
        let saved = self.err
        let g = self.master_apply("quota_group", [val::Value::Str(base)], -1)
        if self.err and !saved:
            self.clear_err()
            self.quota_none.insert(base)
            return
        match g:
            val::Value::Str(s) ->
                self.quota_groups.insert(base, s)
                self.objs[o].qhas = true
                self.objs[o].qgroup = s
            _ ->
                self.quota_none.insert(base)

    # A group's limits (driver quota_limits_of()), asked once per group
    # until quota_refresh().
    fn quota_limits_of(mut self, group: str) -> xd::QuotaLimits:
        if let Option::Some(l) = self.quota_lims.get(group):
            return l
        let mut l = xd::QuotaLimits()
        if !self.alive(self.master_ob) or !self.master_established:
            return l
        let saved = self.err
        let m = self.master_apply("quota_limits", [val::Value::Str(group)], -1)
        if self.err and !saved:
            self.clear_err()
        else:
            match m:
                val::Value::Map(h) ->
                    let ks = self.maps[h].keys
                    let vs = self.maps[h].vals
                    for i in 0..ks.len():
                        match ks[i]:
                            val::Value::Str(k) ->
                                match vs[i]:
                                    val::Value::Int(x) ->
                                        l.keys.push(k)
                                        l.vals.push(x)
                                    _ -> 0
                            _ -> 0
                _ -> 0
        self.quota_lims.insert(group, l)
        l

    fn quota_limit(mut self, group: str, res: str) -> i64:
        let l = self.quota_limits_of(group)
        let k = idx_of(l.keys, res)
        if k < 0:
            return 0 as i64
        l.vals[k]

    fn quota_use_at(mut self, group: str) -> i32:
        if let Option::Some(i) = self.quota_idx.get(group):
            return i
        let i = self.quota_uses.len()
        self.quota_uses.push(xd::QuotaUse(group = group))
        self.quota_idx.insert(group, i)
        i

    # A clone or call_out that would go over its group's limit asks the
    # master's quota_exceeded(); unless that says yes, the efun fails.
    fn quota_check(mut self, o: i32, has: bool, group: str, res: str):
        if !has:
            return
        let limit = self.quota_limit(group, res)
        if limit <= (0 as i64):
            return
        let u = self.quota_use_at(group)
        let count = if res == "clones": self.quota_uses[u].clones else: self.quota_uses[u].call_outs
        if count < limit:
            return
        let saved = self.err
        let ok = self.master_apply("quota_exceeded", [self.obj_value(o), val::Value::Str(group), val::Value::Str(res), val::Value::Int(count), val::Value::Int(limit)], -1)
        let mut yes = self.truthy(ok)
        if self.err and !saved:
            self.clear_err()
            yes = false
        if !yes:
            self.fail(f"Quota exceeded: too many {res} for {group}.\n")

    fn quota_count_clone(mut self, o: i32):
        if self.objs[o].qclone:
            return
        self.objs[o].qclone = true
        self.quota_total.clones = self.quota_total.clones + (1 as i64)
        if self.objs[o].qhas:
            let u = self.quota_use_at(self.objs[o].qgroup)
            self.quota_uses[u].clones = self.quota_uses[u].clones + (1 as i64)

    fn quota_uncount_clone(mut self, o: i32):
        if !self.objs[o].qclone:
            return
        self.objs[o].qclone = false
        self.quota_total.clones = self.quota_total.clones - (1 as i64)
        if self.objs[o].qhas:
            let u = self.quota_use_at(self.objs[o].qgroup)
            self.quota_uses[u].clones = self.quota_uses[u].clones - (1 as i64)

    # A pending call_out leaves the counts (it ran, was removed, or its
    # object was destructed).
    fn quota_uncount_call_out(mut self, c: vm::CallOut):
        self.quota_total.call_outs = self.quota_total.call_outs - (1 as i64)
        if c.qhas:
            let u = self.quota_use_at(c.quota)
            self.quota_uses[u].call_outs = self.quota_uses[u].call_outs - (1 as i64)

    fn quota_minute(self) -> i64:
        vm::epoch_now() / (60 as i64)

    fn quota_roll_total(mut self, minute: i64):
        if self.quota_total.minute == minute:
            return
        self.quota_total.eval_last = if self.quota_total.minute == minute - (1 as i64): self.quota_total.eval_us else: 0 as i64
        self.quota_total.eval_us = 0 as i64
        self.quota_total.minute = minute

    fn quota_roll(mut self, u: i32, minute: i64):
        if self.quota_uses[u].minute == minute:
            return
        self.quota_uses[u].eval_last = if self.quota_uses[u].minute == minute - (1 as i64): self.quota_uses[u].eval_us else: 0 as i64
        self.quota_uses[u].eval_us = 0 as i64
        self.quota_uses[u].minute = minute

    # Wall time of a call_out or heart beat, charged to the object it ran in
    # (driver quota_charge_eval()). It can't be refused after the fact: the
    # master's quota_exceeded() is told once a minute and its answer ignored.
    fn quota_charge_eval(mut self, has: bool, group: str, us: i64, o: i32):
        let minute = self.quota_minute()
        self.quota_roll_total(minute)
        self.quota_total.eval_us = self.quota_total.eval_us + us
        if !has:
            return
        let u = self.quota_use_at(group)
        self.quota_roll(u, minute)
        self.quota_uses[u].eval_us = self.quota_uses[u].eval_us + us
        let limit = self.quota_limit(group, "eval")
        if limit > (0 as i64) and self.quota_uses[u].eval_us > limit and self.quota_uses[u].warned != minute:
            self.quota_uses[u].warned = minute
            let used = self.quota_uses[u].eval_us
            let ov = if self.alive(o): self.obj_value(o) else: val::Value::Int(0 as i64)
            self.safe_master_apply("quota_exceeded", [ov, val::Value::Str(group), val::Value::Str("eval"), val::Value::Int(used), val::Value::Int(limit)], "quota_exceeded")

    fn quota_report(mut self, g: str, u: i32) -> val::Value:
        let minute = self.quota_minute()
        let mut q = self.quota_total
        if u >= 0:
            self.quota_roll(u, minute)
            q = self.quota_uses[u]
        else:
            self.quota_roll_total(minute)
            q = self.quota_total
        let lims = self.new_map()
        if g != "*":
            let l = self.quota_limits_of(g)
            for i in 0..l.keys.len():
                self.map_set(lims, val::Value::Str(l.keys[i]), val::Value::Int(l.vals[i]))
        let m = self.new_map()
        self.map_set(m, val::Value::Str("call_outs"), val::Value::Int(q.call_outs))
        self.map_set(m, val::Value::Str("clones"), val::Value::Int(q.clones))
        self.map_set(m, val::Value::Str("eval"), val::Value::Int(q.eval_us))
        self.map_set(m, val::Value::Str("eval_last"), val::Value::Int(q.eval_last))
        self.map_set(m, val::Value::Str("limits"), val::Value::Map(lims))
        val::Value::Map(m)

    fn quota_info_one(mut self, g: str) -> val::Value:
        if g == "*":
            return self.quota_report(g, -1)
        if let Option::Some(u) = self.quota_idx.get(g):
            return self.quota_report(g, u)
        val::Value::Int(0 as i64)

    fn quota_info_all(mut self) -> val::Value:
        let m = self.new_map()
        for i in 0..self.quota_uses.len():
            let g = self.quota_uses[i].group
            let r = self.quota_report(g, i)
            self.map_set(m, val::Value::Str(g), r)
        let t = self.quota_report("*", -1)
        self.map_set(m, val::Value::Str("*"), t)
        val::Value::Map(m)

    # --- dependencies (stale_programs(), dependents()) ------------------------------

    # A compile of `path` finished (vm.star compile_tokens()): its stamp, a
    # hash of its tokens and its inherits' stamps, and unless it was
    # compiled from a string, its dependency entry (compiler.pike
    # record_deps()). `incs` are the files its preprocessing included.
    fn dep_compiled(mut self, path: str, toks: List<tk::Token>, inherits: List<str>, incs: List<str>, record: bool):
        self.compiled_count += 1
        let mut h = fnv_seed()
        for i in 0..toks.len():
            h = fnv_str(h, toks[i].text)
        let mut istamps: List<str> = List<str>()
        for i in 0..inherits.len():
            let mut s = ""
            if let Option::Some(x) = self.stamps.get(inherits[i]):
                s = x
            istamps.push(s)
            h = fnv_str(h, s)
        self.stamps.insert(path, hex64(h))
        if !self.prog_path_seen.contains(path):
            self.prog_path_seen.insert(path)
            self.prog_paths.push(path)
        if !record:
            return
        let mut e = xd::DepEntry(path = path, inherits = inherits, inh_stamps = istamps, compiled = vm::epoch_now())
        let mut files: List<str> = List<str>()
        files.push(concat(path, ".c"))
        for i in 0..incs.len():
            if idx_of(files, incs[i]) < 0:
                files.push(incs[i])
                e.includes.push(incs[i])
        for i in 0..files.len():
            let st = self.dep_stat(files[i])
            e.files.push(files[i])
            e.mtimes.push(st[0])
            e.sizes.push(st[1])
        if let Option::Some(k) = self.dep_idx.get(path):
            self.deps[k] = e
        else:
            self.dep_idx.insert(path, self.deps.len())
            self.deps.push(e)

    # (mtime, size) of a mudlib file as a compile records it, (-1, -1) when
    # missing. Remembered for up to a second: a stat costs about 0.2 ms on
    # this disk and every compile records its whole include list (most of
    # Dead Souls' headers), which took the 2378-file compile sweep from 23 s
    # to 35 s unmemoized. A remembered stat can only be older than the
    # files the compile read, so at worst stale_programs() reports a program
    # stale that isn't -- never an edit missed (the compiler.pike stat memo
    # lasts an evaluation for the same reason). Queries stat afresh.
    fn dep_stat(mut self, f: str) -> List<i64>:
        let now = clock_ms()
        if now - self.dep_stat_ms > (1000 as i64):
            self.dep_stat_memo = Map<str, List<i64>>()
            self.dep_stat_ms = now
        if let Option::Some(st) = self.dep_stat_memo.get(f):
            return st
        let rp = concat(self.root, f)
        let mt = file_mtime(rp)
        let none = 0 as i64 - (1 as i64)
        let st = if mt < (0 as i64): [none, none] else: [mt, file_size(rp)]
        self.dep_stat_memo.insert(f, st)
        st

    # The next load of `path` compiles it again (compiler.pike forget()).
    fn forget_program(mut self, path: str):
        self.prog_by_path.remove(path)
        self.stamps.remove(path)

    fn in_memory(self, path: str) -> bool:
        if let Option::Some(x) = self.prog_by_path.get(path):
            return true
        false

    fn programs_in_memory(self) -> List<str>:
        let mut out: List<str> = List<str>()
        for i in 0..self.prog_paths.len():
            if self.in_memory(self.prog_paths[i]):
                out.push(self.prog_paths[i])
        out

    # The source or an include no longer matches its recorded stat, or was
    # stamped within a second of the compile (a same-size edit in that
    # second wouldn't show).
    fn dep_source_changed(self, e: xd::DepEntry) -> bool:
        for i in 0..e.files.len():
            let rp = concat(self.root, e.files[i])
            let mt = file_mtime(rp)
            if e.mtimes[i] < (0 as i64) or mt < (0 as i64):
                return true
            if mt != e.mtimes[i] or file_size(rp) != e.sizes[i]:
                return true
            if e.mtimes[i] >= e.compiled - (1 as i64):
                return true
        false

    # compiler.pike is_stale(), with this query's verdicts in `dep_memo`
    # (which also stops inherit cycles).
    fn dep_is_stale(mut self, p: str) -> bool:
        if let Option::Some(v) = self.dep_memo.get(p):
            return v
        self.dep_memo.insert(p, false)
        let mut r = true
        if let Option::Some(k) = self.dep_idx.get(p):
            let e = self.deps[k]
            r = self.dep_source_changed(e)
            if !r:
                for i in 0..e.inherits.len():
                    let q = e.inherits[i]
                    let mut moved = false
                    if let Option::Some(s) = self.stamps.get(q):
                        moved = s != e.inh_stamps[i]
                    if self.dep_is_stale(q) or moved:
                        r = true
                        break
        self.dep_memo.insert(p, r)
        r

    fn dep_depth(mut self, p: str) -> i32:
        if let Option::Some(v) = self.dep_depths.get(p):
            return v
        self.dep_depths.insert(p, 0)
        let mut d = 0
        if let Option::Some(k) = self.dep_idx.get(p):
            let inh = self.deps[k].inherits
            for i in 0..inh.len():
                let x = self.dep_depth(inh[i]) + 1
                if x > d:
                    d = x
        self.dep_depths.insert(p, d)
        d

    # Parents first: by inherit depth, then by name (compiler.pike
    # parents_first()).
    fn parents_first(mut self, paths_in: List<str>) -> List<str>:
        self.dep_depths = Map<str, i32>()
        let mut a = paths_in
        let mut ds: List<i32> = List<i32>()
        for i in 0..a.len():
            ds.push(self.dep_depth(a[i]))
        let mut i = 1
        while i < a.len():
            let x = a[i]
            let xd_ = ds[i]
            let mut j = i - 1
            while j >= 0 and (ds[j] > xd_ or (ds[j] == xd_ and vm::str_cmp(a[j], x) > 0)):
                a[j + 1] = a[j]
                ds[j + 1] = ds[j]
                j -= 1
            a[j + 1] = x
            ds[j + 1] = xd_
            i += 1
        a

    # `p` and everything it inherits at any depth that is stale, parents
    # first; a file never compiled is stale itself.
    fn stale_chain(mut self, p: str) -> List<str>:
        let mut chain: List<str> = List<str>()
        let mut seen: Set<str> = Set<str>()
        chain.push(p)
        seen.insert(p)
        let mut qi = 0
        while qi < chain.len():
            let c = chain[qi]
            qi += 1
            if let Option::Some(k) = self.dep_idx.get(c):
                let inh = self.deps[k].inherits
                for i in 0..inh.len():
                    if !seen.contains(inh[i]):
                        seen.insert(inh[i])
                        chain.push(inh[i])
        self.dep_memo = Map<str, bool>()
        let mut out: List<str> = List<str>()
        for i in 0..chain.len():
            if self.dep_is_stale(chain[i]):
                out.push(chain[i])
        self.parents_first(out)

    fn stale_all(mut self) -> List<str>:
        self.dep_memo = Map<str, bool>()
        let ps = self.programs_in_memory()
        let mut out: List<str> = List<str>()
        for i in 0..ps.len():
            if self.dep_is_stale(ps[i]):
                out.push(ps[i])
        self.parents_first(out)

    fn dep_inherits_deep(self, p: str, r: str) -> bool:
        let mut todo: List<str> = List<str>()
        let mut seen: Set<str> = Set<str>()
        todo.push(p)
        let mut qi = 0
        while qi < todo.len():
            let c = todo[qi]
            qi += 1
            if let Option::Some(k) = self.dep_idx.get(c):
                let inh = self.deps[k].inherits
                for i in 0..inh.len():
                    if inh[i] == r:
                        return true
                    if !seen.contains(inh[i]):
                        seen.insert(inh[i])
                        todo.push(inh[i])
        false

    # The compiled programs a change to `file` must be recompiled into: for
    # a .c file every program inheriting it, for another file the programs
    # including it and every program inheriting those (compiler.pike
    # dependents_of()).
    fn dependents_of(mut self, file: str) -> List<str>:
        let ps = self.programs_in_memory()
        let mut roots: List<str> = List<str>()
        let mut out: List<str> = List<str>()
        if str_ends_with(file, ".c"):
            roots.push(vm::substr(file, 0, len(file) - 2))
        else:
            for i in 0..ps.len():
                if let Option::Some(k) = self.dep_idx.get(ps[i]):
                    if idx_of(self.deps[k].includes, file) >= 0:
                        roots.push(ps[i])
                        out.push(ps[i])
        for i in 0..ps.len():
            let p = ps[i]
            if idx_of(out, p) >= 0:
                continue
            for r in 0..roots.len():
                if p != roots[r] and self.dep_inherits_deep(p, roots[r]):
                    out.push(p)
                    break
        self.parents_first(out)

    fn efun_stale_programs(mut self, args: List<val::Value>) -> val::Value:
        if args.len() < 1:
            return self.dot_c_list(self.stale_all())
        match args[0]:
            val::Value::Str(s) ->
                return self.dot_c_list(self.stale_chain(self.normalize(s, "")))
            _ -> 0
        let o = self.obj_of(args[0])
        if o < 0:
            self.fail("Bad argument 1 to stale_programs()\n")
            return val::Value::Undef
        self.dot_c_list(self.stale_chain(self.progs[self.objs[o].prog].path))

    # --- profiling ----------------------------------------------------------------

    fn prof_key(self, prog: i32, fnidx: i32) -> str:
        concat(concat(self.progs[prog].path, ":"), self.progs[prog].fns[fnidx].name)

    # A named function's frame was entered (vm.star enter()).
    fn prof_enter(mut self, fi: i32):
        let fr = self.frames[fi]
        let name = self.progs[fr.prog].fns[fr.fnidx].name
        if name == "(closure)" or name == "__INIT":
            return
        let key = self.prof_key(fr.prog, fr.fnidx)
        let mut r = -1
        if let Option::Some(x) = self.prof_idx.get(key):
            r = x
        else:
            r = self.prof_recs.len()
            self.prof_recs.push(xd::ProfRec(key = key))
            self.prof_idx.insert(key, r)
        self.prof_recs[r].calls = self.prof_recs[r].calls + (1 as i64)
        self.frames[fi].pf = r
        self.frames[fi].pstart = clock_us()
        self.frames[fi].pchild = 0 as i64

    # Frame fi returns or is unwound: its time, less its callees', is its
    # own; all of it is its profiled caller's callee time (driver
    # prof_close_to()).
    fn prof_close(mut self, fi: i32):
        let fr = self.frames[fi]
        if fr.pf < 0:
            return
        let el = clock_us() - fr.pstart
        self.prof_recs[fr.pf].self_us = self.prof_recs[fr.pf].self_us + el - fr.pchild
        self.prof_recs[fr.pf].child_us = self.prof_recs[fr.pf].child_us + fr.pchild
        self.frames[fi].pf = -1
        let mut j = fi - 1
        while j >= 0:
            if self.frames[j].pf >= 0:
                self.frames[j].pchild = self.frames[j].pchild + el
                return
            j -= 1

    fn count_efun(mut self, name: str):
        let mut n = 0 as i64
        if let Option::Some(x) = self.efun_counts.get(name):
            n = x
        self.efun_counts.insert(name, n + (1 as i64))

    fn profile_start(mut self, interval: i64):
        self.sample_interval = if interval < (50 as i64): 50 as i64 else: interval
        self.sample_recs = List<xd::SampleRec>()
        self.sample_idx = Map<str, i32>()
        self.sample_count = 0 as i64
        self.sample_time = 0 as i64
        self.sample_pending = 0 as i64
        self.sample_started = vm::epoch_now()
        self.sample_left = self.sample_interval
        if self.eval_nest > 0:
            self.sample_resume()

    # The clock only runs inside evaluations and carries over between them
    # (objects.star begin_eval()/end_eval()), so evaluations shorter than
    # the interval are sampled in proportion too.
    fn sample_resume(mut self):
        self.sample_last = clock_us()
        self.sample_next = self.sample_last + self.sample_left

    fn sample_pause(mut self):
        let now = clock_us()
        self.sample_pending = self.sample_pending + now - self.sample_last
        let left = self.sample_next - now
        self.sample_left = if left > (0 as i64): left else: 0 as i64

    fn sample_charge(mut self, key: str, us: i64, own: bool):
        let mut r = -1
        if let Option::Some(x) = self.sample_idx.get(key):
            r = x
        else:
            r = self.sample_recs.len()
            self.sample_recs.push(xd::SampleRec(key = key))
            self.sample_idx.insert(key, r)
        self.sample_recs[r].total_us = self.sample_recs[r].total_us + us
        if own:
            self.sample_recs[r].self_us = self.sample_recs[r].self_us + us
            self.sample_recs[r].samples = self.sample_recs[r].samples + (1 as i64)

    # At the evaluation-limit tick, once the interval has passed (driver
    # take_sample()): the time since the last sample goes to the innermost
    # function as its own and once to every distinct function on the stack.
    fn sample_tick(mut self):
        let now = clock_us()
        if now < self.sample_next:
            return
        let us = self.sample_pending + now - self.sample_last
        self.sample_pending = 0 as i64
        self.sample_last = now
        self.sample_next = now + self.sample_interval
        self.sample_count = self.sample_count + (1 as i64)
        self.sample_time = self.sample_time + us
        let mut seen: Set<str> = Set<str>()
        let mut own = true
        let mut k = self.frames.len() - 1
        while k >= 0:
            let fr = self.frames[k]
            k -= 1
            let key = self.prof_key(fr.prog, fr.fnidx)
            if seen.contains(key):
                continue
            seen.insert(key)
            self.sample_charge(key, us, own)
            own = false
        if own:
            self.sample_charge("(driver)", us, true)

    # Compiling isn't LPC time: it goes to "(compile)", off the clock (driver
    # sample_compile()).
    fn sample_compile(mut self, t0: i64):
        if self.sample_interval <= (0 as i64) or self.eval_nest <= 0:
            return
        let now = clock_us()
        let us = now - t0
        self.sample_pending = self.sample_pending + t0 - self.sample_last
        self.sample_last = now
        self.sample_next = self.sample_next + us
        self.sample_time = self.sample_time + us
        self.sample_charge("(compile)", us, true)

    # profile_report(clear): ([ "running", "samples", "time", "since",
    # "functions": ({ ([ "file", "function", "self", "total", "samples" ]) })
    # by self time, largest first ]).
    fn profile_report(mut self, clear: bool) -> val::Value:
        let n = self.sample_recs.len()
        let mut order: List<i32> = List<i32>()
        for i in 0..n:
            order.push(i)
        let mut i = 1
        while i < n:
            let x = order[i]
            let mut j = i - 1
            while j >= 0 and self.sample_recs[order[j]].self_us < self.sample_recs[x].self_us:
                order[j + 1] = order[j]
                j -= 1
            order[j + 1] = x
            i += 1
        let mut fns: List<val::Value> = List<val::Value>()
        for k in 0..n:
            let r = self.sample_recs[order[k]]
            let kb = bytes_from_str(r.key)
            let mut c = -1
            if kb.len() > 0 and (kb[0] as i32) != 40:
                for q in 0..kb.len():
                    if c < 0 and (kb[q] as i32) == 58:
                        c = q
            let file = if c > 0: vm::substr(r.key, 0, c) else: r.key
            let fname = if c > 0: vm::substr(r.key, c + 1, kb.len()) else: r.key
            let m = self.new_map()
            self.map_set(m, val::Value::Str("file"), val::Value::Str(file))
            self.map_set(m, val::Value::Str("function"), val::Value::Str(fname))
            self.map_set(m, val::Value::Str("self"), val::Value::Int(r.self_us))
            self.map_set(m, val::Value::Str("total"), val::Value::Int(r.total_us))
            self.map_set(m, val::Value::Str("samples"), val::Value::Int(r.samples))
            fns.push(val::Value::Map(m))
        let out = self.new_map()
        self.map_set(out, val::Value::Str("running"), val::Value::Int(self.sample_interval))
        self.map_set(out, val::Value::Str("samples"), val::Value::Int(self.sample_count))
        self.map_set(out, val::Value::Str("time"), val::Value::Int(self.sample_time))
        self.map_set(out, val::Value::Str("since"), val::Value::Int(self.sample_started))
        let fa = self.new_arr(fns)
        self.map_set(out, val::Value::Str("functions"), fa)
        if clear:
            self.sample_recs = List<xd::SampleRec>()
            self.sample_idx = Map<str, i32>()
            self.sample_count = 0 as i64
            self.sample_time = 0 as i64
            self.sample_started = vm::epoch_now()
        val::Value::Map(out)

    # function_profile([ob]): a mapping per function ob's program defines
    # itself, by name: exact numbers with `havok profiling` on, else the
    # sampling profiler's (functions no sample landed in left out).
    fn efun_function_profile(mut self, args: List<val::Value>, self_ob: i32) -> val::Value:
        let o = if args.len() < 1: self_ob else: self.obj_of(args[0])
        if o < 0 or !self.alive(o):
            self.fail("Bad argument 1 to function_profile()\n")
            return val::Value::Undef
        let pid = self.objs[o].prog
        let p = self.progs[pid]
        let mut names: List<str> = List<str>()
        for i in 0..p.fns.len():
            let f = p.fns[i]
            if f.name == "(closure)" or f.name == "__INIT" or f.code.len() == 0:
                continue
            if idx_of(names, f.name) < 0:
                names.push(f.name)
        names = ef::sort_strs(names)
        let mut out: List<val::Value> = List<val::Value>()
        for i in 0..names.len():
            let key = concat(concat(p.path, ":"), names[i])
            let m = self.new_map()
            if self.profiling:
                let mut r = xd::ProfRec(key = key)
                if let Option::Some(x) = self.prof_idx.get(key):
                    r = self.prof_recs[x]
                self.map_set(m, val::Value::Str("name"), val::Value::Str(names[i]))
                self.map_set(m, val::Value::Str("calls"), val::Value::Int(r.calls))
                self.map_set(m, val::Value::Str("self"), val::Value::Int(r.self_us))
                self.map_set(m, val::Value::Str("children"), val::Value::Int(r.child_us))
                out.push(val::Value::Map(m))
            else:
                if let Option::Some(x) = self.sample_idx.get(key):
                    let r = self.sample_recs[x]
                    self.map_set(m, val::Value::Str("name"), val::Value::Str(names[i]))
                    self.map_set(m, val::Value::Str("calls"), val::Value::Int(r.samples))
                    self.map_set(m, val::Value::Str("self"), val::Value::Int(r.self_us))
                    self.map_set(m, val::Value::Str("children"), val::Value::Int(r.total_us - r.self_us))
                    out.push(val::Value::Map(m))
        self.new_arr(out)

    # --- the status reports -------------------------------------------------------

    fn report_to_player(mut self, s: str, self_ob: i32) -> val::Value:
        self.efun(et::E_WRITE, "write", [val::Value::Str(s)], self_ob)
        if self.err:
            return val::Value::Undef
        val::Value::Str(s)

    # cache_stats(): the reference's report with this driver's numbers (see
    # the header). Printed to this_player() too, since Dead Souls's `cache`
    # command ignores the returned string.
    fn efun_cache_stats(mut self, self_ob: i32) -> val::Value:
        let ps = self.programs_in_memory()
        let mut names = 0
        for i in 0..ps.len():
            if let Option::Some(pid) = self.prog_by_path.get(ps[i]):
                names += self.progs[pid].anyt_names.len()
        let mut sefuns = 0
        if self.alive(self.sefun_ob):
            sefuns = self.progs[self.objs[self.sefun_ob].prog].anyt_names.len()
        let mut b = bf::Buf()
        b.add_str("HavokOS cache statistics\n")
        b.add_str(f"Function lookups (applies, static calls): resolved through dispatch tables built at compile time\n")
        b.add_str(f"  dispatch names: {names} in {ps.len()} programs\n")
        b.add_str(f"Programs in memory: {ps.len()} ({self.compiled_count} compiled this boot, 0 from the disk cache)\n")
        b.add_str(f"Simul_efun functions bound: {sefuns}\n")
        self.report_to_player(b.to_str(), self_ob)

    # malloc_status(): the reference's report, its sizes estimated from what
    # each value table holds (Star has no allocator to ask).
    fn efun_malloc_status(mut self, self_ob: i32) -> val::Value:
        let mut kinds: List<str> = List<str>()
        let mut counts: List<i64> = List<i64>()
        let mut sizes: List<i64> = List<i64>()
        let mut n = 0 as i64
        let mut sz = 0 as i64
        for o in 1..self.objs.len():
            if self.objs[o].alive:
                n = n + (1 as i64)
                sz = sz + (256 as i64) + (self.objs[o].vars.len() as i64) * (24 as i64)
        kinds.push("object")
        counts.push(n)
        sizes.push(sz)
        let ps = self.programs_in_memory()
        sz = 0 as i64
        for i in 0..ps.len():
            if let Option::Some(pid) = self.prog_by_path.get(ps[i]):
                let p = self.progs[pid]
                sz = sz + (512 as i64)
                for k in 0..p.fns.len():
                    sz = sz + (64 as i64) + (p.fns[k].code.len() as i64) * (4 as i64) + (p.fns[k].lines.len() as i64) * (4 as i64)
                sz = sz + (p.consts.len() as i64) * (24 as i64)
        kinds.push("program")
        counts.push(ps.len() as i64)
        sizes.push(sz)
        n = 0 as i64
        sz = 0 as i64
        for h in 0..self.arrs.len():
            if !self.arr_free[h]:
                n = n + (1 as i64)
                sz = sz + (32 as i64) + (self.arrs[h].items.len() as i64) * (24 as i64)
        kinds.push("array")
        counts.push(n)
        sizes.push(sz)
        n = 0 as i64
        sz = 0 as i64
        for h in 0..self.maps.len():
            if !self.map_free[h]:
                n = n + (1 as i64)
                sz = sz + (64 as i64) + (self.maps[h].keys.len() as i64) * (72 as i64)
        kinds.push("mapping")
        counts.push(n)
        sizes.push(sz)
        n = 0 as i64
        for h in 0..self.fns.len():
            if !self.fn_free[h]:
                n = n + (1 as i64)
        kinds.push("function")
        counts.push(n)
        sizes.push(n * (96 as i64))
        n = 0 as i64
        for h in 0..self.clss.len():
            if !self.cls_free[h]:
                n = n + (1 as i64)
        kinds.push("class instance")
        counts.push(n)
        sizes.push(n * (64 as i64))
        # the top line is the process's own resident memory (the reference's
        # is its Pike heap); the rows estimate what each table holds
        let mut total = process_memory()
        if total < (0 as i64):
            total = 0 as i64
            for i in 0..sizes.len():
                total = total + sizes[i]
        # largest first (insertion sort, ties in the order above)
        let mut order: List<i32> = List<i32>()
        for i in 0..kinds.len():
            order.push(i)
        let mut i = 1
        while i < order.len():
            let x = order[i]
            let mut j = i - 1
            while j >= 0 and sizes[order[j]] < sizes[x]:
                order[j + 1] = order[j]
                j -= 1
            order[j + 1] = x
            i += 1
        let mut b = bf::Buf()
        b.add_str(self.lpc_sprintf("Memory in use: %d KB (%s heap)\n", [val::Value::Int(total / (1024 as i64)), val::Value::Str("Star")]))
        b.add_str(self.lpc_sprintf("%-26s %10s %12s\n", [val::Value::Str("kind"), val::Value::Str("count"), val::Value::Str("KB")]))
        for k in 0..order.len():
            let x = order[k]
            if sizes[x] < (1024 as i64):
                continue
            b.add_str(self.lpc_sprintf("%-26s %10d %12d\n", [val::Value::Str(kinds[x]), val::Value::Int(counts[x]), val::Value::Int(sizes[x] / (1024 as i64))]))
        self.report_to_player(b.to_str(), self_ob)

    # --- the case runner's hooks (920..) ------------------------------------------

    fn rm_tree(self, rp: str):
        let k = path_kind(rp)
        if k == 2:
            let names = dir_list(rp)
            for i in 0..names.len():
                self.rm_tree(concat(concat(rp, "/"), names[i]))
            dir_remove(rp)
        elif k != 0:
            file_remove(rp)

    fn efun_ext_test(mut self, code: i32, args: List<val::Value>, self_ob: i32) -> val::Value:
        let zero = val::Value::Int(0 as i64)
        # test_utime/test_put/test_rmtree change files (dep_stat())
        self.dep_stat_ms = 0 as i64
        if code == et::E_TEST_WATCH_POLL:
            return self.str_list_value(self.watch_poll())
        if code == et::E_TEST_WATCH_STATE:
            return self.new_arr([val::Value::Int(self.watchers.len() as i64), val::Value::Int(self.watch_dirs.len() as i64)])
        if code == et::E_TEST_RUN_CALL_OUT:
            # run one pending call_out now, its function first replaced
            # when a name is given (run_tests.pike's quota tests)
            let k = self.find_call_out_index(self_ob, val::Value::Int(val::int_of(self.arg(args, 0))))
            if k < 0:
                return zero
            let mut c = self.drop_call_out_at(k)
            match self.arg(args, 1):
                val::Value::Str(f) ->
                    c = vm::CallOut(handle = c.handle, ob = c.ob, owner = c.owner, fun = val::Value::Str(f), args = c.args, when = c.when, tp = c.tp, quota = c.quota, qhas = c.qhas)
                _ -> 0
            self.run_call_out(c)
            return zero
        if code == et::E_TEST_UTIME:
            let p = self.mud_real(self.str_arg(args, 0))
            let ok = file_set_mtime(p, vm::epoch_now() - val::int_of(self.arg(args, 1)))
            return val::Value::Int(if ok: 1 as i64 else: 0 as i64)
        if code == et::E_TEST_FORGET:
            self.forget_program(self.normalize(self.str_arg(args, 0), ""))
            return zero
        if code == et::E_TEST_PUT:
            # a mudlib file written past the master (the reference's tests
            # write /secret/ with Stdio), its directories made as needed
            let path = self.mud_abs(self.str_arg(args, 0))
            let parts = str_split(path, "/")
            let mut d = self.root
            for i in 1..parts.len() - 1:
                d = concat(concat(d, "/"), parts[i])
                if path_kind(d) == 0:
                    dir_create(d)
            let ok = self.write_whole(self.mud_real(path), self.str_arg(args, 1), false)
            return val::Value::Int(if ok: 1 as i64 else: 0 as i64)
        if code == et::E_TEST_RMTREE:
            self.rm_tree(self.mud_real(self.str_arg(args, 0)))
            return zero
        if code == et::E_TEST_PROFILING:
            self.profiling = self.truthy(self.arg(args, 0))
            if self.truthy(self.arg(args, 1)):
                self.prof_recs = List<xd::ProfRec>()
                self.prof_idx = Map<str, i32>()
                self.efun_counts = Map<str, i64>()
            let mut open = 0
            for i in 0..self.frames.len():
                if self.frames[i].pf >= 0:
                    open += 1
            return val::Value::Int(open as i64)
        zero

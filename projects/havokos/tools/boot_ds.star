# Star half of the M5 boot comparison (todo.md HavokOS M5): boot a mudlib
# all the way -- simul_efun object, master, epilog() and every preload() --
# from its mudos.cfg, the way driver.pike boot() does, then print what the
# boot left behind in a canonical form `tools/ref_boot.pike` prints for the
# live Pike driver:
#   OBJ <name> <privs> <environment> [HB] [LIVING]   one per live object,
#       sorted, a clone's "#n" written as "#" (clone numbers depend on load
#       order, which mapping iteration order can change: NOTES.md deviation #9)
#   COUNT objects <n> / clones <n> / call_outs <n> / heart_beats <n>
# The driver's own messages (compile errors, runtime errors) follow as LOG
# lines, which aren't compared: the two drivers word them differently.
#
# Usage: boot_ds.exe <mudos.cfg> [<mudlib dir>] [-run <seconds>]
#            boot and report; with -run, first run the booted driver's timers
#            (driver_tick(): call_outs, heart beats, garbage collection) for
#            that many seconds, a soak test with nothing to compare against,
#            reported as RUN lines; -gcevery collects garbage on every tick
#            (a collector stress test on a real mudlib's heap)
#        boot_ds.exe -unimplemented                    the reference's efuns
#            this VM can't run yet, one per line (ref_boot.pike stubs the
#            same ones, so both drivers fail the same calls)
#
# Build: star build projects/havokos/tools/boot_ds.star -o projects/havokos/tools/boot_ds.exe

import "../vm.star" as vm
import "../efuns.star" as ef
import "../value.star" as val
import "../efun_table.star" as et
import "../efun_names.star" as en
import "../gc.star" as gc
import "../objects.star" as objm

extern "C" fn _sleep(ms: i32)

fn trim(s: str) -> str:
    let b = bytes_from_str(s)
    let mut a = 0
    let mut e = b.len()
    while a < e and ((b[a] as i32) == 32 or (b[a] as i32) == 9 or (b[a] as i32) == 13):
        a += 1
    while e > a and ((b[e - 1] as i32) == 32 or (b[e - 1] as i32) == 9 or (b[e - 1] as i32) == 13):
        e -= 1
    vm::substr(s, a, e)

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

fn no_clone_no(n: str) -> str:
    let h = str_index_of(n, "#")
    if h < 0:
        return n
    concat(vm::substr(n, 0, h), "#")

# a .c path from the config, as driver normalize_cfg_path()
fn cfg_path(p: str) -> str:
    let t = trim(p)
    if str_ends_with(t, ".c"):
        return vm::substr(t, 0, len(t) - 2)
    t

fn main() -> i32:
    let cli = args()
    if cli.len() >= 2 and cli[1] == "-unimplemented":
        let codes = et::efun_codes()
        let names = en::reference_efuns()
        let mut out: List<str> = List<str>()
        for i in 0..names.len():
            if !codes.contains(names[i]):
                out.push(names[i])
        let s = sort_strs(out)
        for i in 0..s.len():
            println(s[i])
        return 0
    if cli.len() < 2:
        println("usage: boot_ds <mudos.cfg> [<mudlib dir>] | -unimplemented")
        return 2
    let f = file_open(cli[1], "rb")
    if is_null(f):
        println("cannot read config")
        return 2
    let text = str_from_bytes(file_read_bytes(f))
    file_close(f)
    let mut cfg: Map<str, str> = Map<str, str>()
    let lines = str_split(str_replace(text, "\r", ""), "\n")
    for i in 0..lines.len():
        let l = lines[i]
        if l == "" or str_starts_with(l, "#"):
            continue
        let c = str_index_of(l, ":")
        if c < 0:
            continue
        cfg.insert(trim(vm::substr(l, 0, c)), trim(vm::substr(l, c + 1, len(l))))
    let mut root = ""
    let mut run_s = 0
    let mut gc_every = false
    let mut pos: List<str> = List<str>()
    let mut k = 1
    while k < cli.len():
        if cli[k] == "-gcevery":
            gc_every = true
            k += 1
        elif cli[k] == "-run" and k + 1 < cli.len():
            run_s = vm::parse_int_prefix(cli[k + 1]) as i32
            k += 2
        else:
            pos.push(cli[k])
            k += 1
    if pos.len() >= 2:
        root = pos[1]
    else:
        root = cli[1]
        let k = str_index_of(root, "/bin/")
        if k >= 0:
            root = concat(vm::substr(root, 0, k), "/lib")
    let mut m = vm::new_vm(root)
    let mut name = "HavokOS"
    if let Option::Some(x) = cfg.get("name"):
        name = x
    let mut port = 6666
    if let Option::Some(x) = cfg.get("external_port_1"):
        let parts = str_split(x, " ")
        port = vm::parse_int_prefix(parts[parts.len() - 1]) as i32
    let keys = ["master file", "simulated efun file", "include directories", "global include file", "time to reset", "time to clean up", "maximum evaluation cost", "log directory", "default fail message", "default error message", "mudlib directory", "binary directory", "address server ip", "address server port", "save binaries directory", "swap file", "debug log file"]
    for i in 0..keys.len():
        if let Option::Some(x) = cfg.get(keys[i]):
            m.config.insert(keys[i], x)
    m.configure(name, port)
    if let Option::Some(x) = cfg.get("include directories"):
        m.pp.include_dirs = str_split(x, ":")
    if let Option::Some(x) = cfg.get("global include file"):
        m.pp.global_include = str_replace(str_replace(str_replace(x, "<", ""), ">", ""), "\"", "")
    let mut sefun = "/secure/sefun/sefun"
    if let Option::Some(x) = cfg.get("simulated efun file"):
        sefun = cfg_path(x)
    let mut master = "/secure/daemon/master"
    if let Option::Some(x) = cfg.get("master file"):
        master = cfg_path(x)
    let t0 = clock_ms()
    let ok = m.boot(sefun, master)
    let took = clock_ms() - t0
    m.collect_garbage()
    if !ok:
        println("BOOT FAILED")
    if run_s > 0:
        let heap0 = m.heap_live()
        let gc0 = m.gc_runs
        let log0 = m.log.len()
        let end = clock_ms() + (run_s as i64) * (1000 as i64)
        let mut ticks = 0
        while clock_ms() < end:
            if gc_every:
                m.gc_requested = true
            m.driver_tick()
            ticks += 1
            _sleep(10)
        let mut errors = 0
        for i in log0..m.log.len():
            if str_starts_with(m.log[i], "*** "):
                errors += 1
        println(f"RUN {run_s} s: {ticks} driver ticks, {m.gc_runs - gc0} collections, heap {heap0} -> {m.heap_live()} slots, {errors} runtime errors, {m.callouts.len()} call_outs pending")
    let mut objs: List<str> = List<str>()
    let mut nobj = 0
    let mut nclone = 0
    let mut nhb = 0
    for o in 1..m.objs.len():
        let s = m.objs[o]
        if !s.alive:
            continue
        nobj += 1
        if s.clone:
            nclone += 1
        let privs = match s.privs:
            val::Value::Str(p) -> p
            _ -> "0"
        let env = if m.alive(s.env): no_clone_no(m.objs[s.env].name) else: "-"
        let mut line = f"OBJ {no_clone_no(s.name)} {privs} {env}"
        if s.hb != 0:
            line = concat(line, " HB")
            nhb += 1
        if s.living:
            line = concat(line, " LIVING")
        objs.push(line)
    let sorted = sort_strs(objs)
    for i in 0..sorted.len():
        println(sorted[i])
    println(f"COUNT objects {nobj}")
    println(f"COUNT clones {nclone}")
    println(f"COUNT call_outs {m.callouts.len()}")
    println(f"COUNT heart_beats {nhb}")
    for i in 0..m.log.len():
        println(concat("LOG ", str_replace(m.log[i], "\n", "\\n")))
    println(f"LOG boot took {took} ms")
    0

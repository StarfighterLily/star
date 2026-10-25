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
#        boot_ds.exe <mudos.cfg> [<mudlib dir>] [-wait <seconds>] -eval <file.lpc>
#            boot, run the timers for that long, then run the file as the body
#            of `mixed eval()` in a SECURE object, as the reference's
#            havok/eval.pike -f does (tools/ref_eval.pike is the reference
#            side); prints `EVAL <result>` and the driver's log
#        boot_ds.exe -unimplemented                    the reference's efuns
#            this VM can't run yet, one per line (ref_boot.pike stubs the
#            same ones, so both drivers fail the same calls)
#
# Build: star build projects/havokos/tools/boot_ds.star -o projects/havokos/tools/boot_ds.exe -l ws2_32

import "../vm.star" as vm
import "../efuns.star" as ef
import "../value.star" as val
import "../efun_table.star" as et
import "../efun_names.star" as en
import "../gc.star" as gc
import "../objects.star" as objm
import "../config.star" as cfgm
import "../net.star" as net

extern "C" fn _sleep(ms: i32)

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

impl vm::Vm:
    # havok/eval.pike's snippet run: compile, instantiate with SECURE privs,
    # call eval() with the object pushed, destruct it.
    fn run_eval(mut self, body: str) -> str:
        let path = "/tmp/__havok_eval_0"
        let src = concat(concat("#include <lib.h>\n#include <daemons.h>\nmixed eval() {\n", body), "\n}\n")
        let pid = self.compile_source(path, src)
        if pid < 0:
            return concat("COMPILE ", self.compile_error)
        let o = self.new_object(pid, path, false)
        if o < 0:
            return "NO OBJECT"
        self.objs[o].privs = val::Value::Str("SECURE")
        self.opush(o, "")
        let e = self.any_fn(o, "eval")
        let r = self.call_direct(e.prog, e.fnidx, e.var_off, o, List<val::Value>())
        let mut out = ""
        if self.err:
            out = concat("ERR ", self.errmsg)
            self.clear_err()
        else:
            out = self.render(r)
        self.truncate_ostack(0)
        self.truncate_stack(0)
        self.destruct_object(-1, o)
        self.clear_err()
        out

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
    let cfg = cfgm::read_config(cli[1])
    if !cfg.ok:
        println("cannot read config")
        return 2
    let mut root = ""
    let mut run_s = 0
    let mut gc_every = false
    let mut wait_s = 0
    let mut eval_file = ""
    let mut pos: List<str> = List<str>()
    let mut k = 1
    while k < cli.len():
        if cli[k] == "-gcevery":
            gc_every = true
            k += 1
        elif cli[k] == "-wait" and k + 1 < cli.len():
            wait_s = vm::parse_int_prefix(cli[k + 1]) as i32
            k += 2
        elif cli[k] == "-eval" and k + 1 < cli.len():
            eval_file = cli[k + 1]
            k += 2
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
    let mut m = cfgm::setup_vm(cfg, root, cfgm::telnet_ports(cfg)[0])
    let sefun = cfgm::sefun_path(cfg)
    let master = cfgm::master_path(cfg)
    let t0 = clock_ms()
    let ok = m.boot(sefun, master)
    let took = clock_ms() - t0
    m.collect_garbage()
    if !ok:
        println("BOOT FAILED")
    if eval_file != "":
        let end = clock_ms() + (wait_s as i64) * (1000 as i64)
        while clock_ms() < end:
            m.net_poll(m.next_timer_ms())
            m.driver_tick()
        let f = file_open(eval_file, "rb")
        if is_null(f):
            println(f"cannot read {eval_file}")
            return 2
        let body = str_from_bytes(file_read_bytes(f))
        file_close(f)
        println(concat("EVAL ", m.run_eval(body)))
        for i in 0..m.log.len():
            println(concat("LOG ", str_replace(m.log[i], "\n", "\\n")))
        return 0
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

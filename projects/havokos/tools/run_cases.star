# Star half of the M3 golden comparison (todo.md HavokOS M3): boots the
# Star VM on the reference's test mudlib and runs each case of a fixture
# written by `ref_cases.pike` (the live Pike driver's results for HavokOS's
# own run_tests.pike cases), the way run_tests.pike's run_lpc() does it:
# compile "<globals>\nmixed eval() {\n<body>\n}\n" as /test/__case_<name>,
# instantiate it, call eval() with the object on the driver stack, and
# compare the result in the canonical form both sides print.
#
# Usage: run_cases.exe <minilib_root> <fixture.txt> [-v] [-ds] [-nogc] [name filter]
#   -ds: the root is Dead Souls 3.9's mudlib, booted (as ref_cases.pike -ds
#        does) only as far as its simul_efun object -- DS3.9's mudos.cfg
#        names, no master
#   -nogc: don't collect garbage between cases (M5). By default a
#        collection runs after every case, so every fixture also checks
#        that the collector frees nothing still in use.
# Prints one FAIL line per mismatch (every case with -v) and a summary;
# exits 0 when every case matched.
#
# The driver hooks (efun_table.star test_efun_codes(): test_hb(),
# test_callouts(), ...) are always available to cases; ref_cases.pike gives
# the reference the same ones.
#
# Build: star build projects/havokos/tools/run_cases.star -o projects/havokos/tools/run_cases.exe

import "../vm.star" as vm
import "../efuns.star" as ef
import "../value.star" as val
import "../gc.star" as gc

fn unescape(s: str) -> str:
    let b = bytes_from_str(s)
    let mut o: Bytes = Bytes()
    let mut i = 0
    while i < b.len():
        let c = b[i] as i32
        if c == 92 and i + 1 < b.len():
            let d = b[i + 1] as i32
            if d == 110:
                o.push(10 as u8)
            elif d == 116:
                o.push(9 as u8)
            elif d == 114:
                o.push(13 as u8)
            else:
                o.push(b[i + 1])
            i += 2
        else:
            o.push(b[i])
            i += 1
    str_from_bytes(o)

fn safe_name(s: str) -> str:
    let b = bytes_from_str(s)
    let mut o: Bytes = Bytes()
    for i in 0..b.len():
        let mut c = b[i] as i32
        if c >= 65 and c <= 90:
            c = c + 32
        if (c >= 97 and c <= 122) or (c >= 48 and c <= 57):
            o.push(b[i])
    str_from_bytes(o)

impl vm::Vm:
    fn run_case(mut self, name: str, body: str) -> str:
        let path = concat("/test/__case_", safe_name(name))
        let mut prelude = ""
        let mut code = body
        let at = str_index_of(body, "@@")
        if at >= 0:
            prelude = vm::substr(body, 0, at)
            code = vm::substr(body, at + 2, len(body))
        let src = concat(concat(concat(prelude, "\nmixed eval() {\n"), code), "\n}\n")
        let pid = self.compile_source(path, src)
        if pid < 0:
            return concat("COMPILE ", self.compile_error)
        # as run_tests.pike's run_lpc(): instantiate and register (no
        # create()), call eval() with the object pushed, then destruct it
        let o = self.new_object(pid, path, false)
        let mut out = ""
        if o >= 0:
            self.opush(o, "")
            let e = self.any_fn(o, "eval")
            let r = self.call_direct(e.prog, e.fnidx, e.var_off, o, List<val::Value>())
            if !self.err:
                out = self.render(r)
            let failed = self.err
            let msg = self.errmsg
            self.clear_err()
            self.truncate_ostack(0)
            self.truncate_stack(0)
            self.destruct_object(-1, o)
            self.clear_err()
            if failed:
                out = concat("ERR ", vm::esc_quoted(msg))
        if self.err:
            out = concat("ERR ", vm::esc_quoted(self.errmsg))
            self.clear_err()
        self.truncate_stack(0)
        self.truncate_ostack(0)
        out

fn main() -> i32:
    let cli = args()
    if cli.len() < 3:
        println("usage: run_cases <minilib_root> <fixture.txt> [-v] [filter]")
        return 2
    let mut verbose = false
    let mut ds = false
    let mut use_gc = true
    let mut filter = ""
    for i in 3..cli.len():
        if cli[i] == "-v":
            verbose = true
        elif cli[i] == "-ds":
            ds = true
        elif cli[i] == "-nogc":
            use_gc = false
        else:
            filter = cli[i]
    let mut m = vm::new_vm(cli[1])
    m.add_test_efuns()
    let mut booted = false
    if ds:
        m.pp.include_dirs = ["/secure/include", "/include"]
        m.configure("DeadSoulsNew", 6666)
        m.config.insert("master file", "/secure/daemon/master")
        m.config.insert("simulated efun file", "/secure/sefun/sefun")
        m.config.insert("include directories", "/secure/include:/include")
        m.config.insert("global include file", "<global.h>")
        booted = m.boot("/secure/sefun/sefun", "")
    else:
        m.pp.include_dirs = ["/include"]
        m.configure("HavokTest", 6699)
        m.config.insert("master file", "/secure/master")
        m.config.insert("simulated efun file", "/secure/sefun")
        m.config.insert("include directories", "/include")
        m.config.insert("global include file", "<global.h>")
        booted = m.boot("/secure/sefun", "/secure/master")
    if !booted:
        for i in 0..m.log.len():
            println(m.log[i])
        println("boot failed")
        return 1
    let f = file_open(cli[2], "rb")
    if is_null(f):
        println("cannot open fixture")
        return 2
    let lines = str_split(str_from_bytes(file_read_bytes(f)), "\n")
    file_close(f)
    let mut passed = 0
    let mut failed = 0
    for i in 0..lines.len():
        let line = str_replace(lines[i], "\r", "")
        if line == "":
            continue
        let cols = str_split(line, "\t")
        if cols.len() < 3:
            continue
        let mut name = cols[0]
        if str_starts_with(name, "error "):
            name = vm::substr(name, 6, len(name))
        if filter != "" and !str_contains(name, filter):
            continue
        let got = m.run_case(name, unescape(cols[1]))
        if use_gc:
            m.collect_garbage()
        let want = cols[2]
        if got == want:
            passed += 1
            if verbose:
                println(f"ok   {name}")
        else:
            failed += 1
            println(f"FAIL {name}")
            println(f"     expected {want}")
            println(f"     got      {got}")
    if verbose:
        for i in 0..m.log.len():
            println(f"log: {m.log[i]}")
    println(f"{passed} passed, {failed} failed")
    if failed > 0:
        return 1
    0

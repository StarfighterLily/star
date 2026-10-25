# Star half of the M3 compile sweep (todo.md HavokOS M3): compiles every
# listed DS3.9 file with `compiler.star` (inherits first, as the reference
# does) and prints the line `ref_compile_sweep.pike` prints for the live
# reference -- see that script for the format and why the function and
# variable tables are hashed rather than just reported OK. The case fixtures
# check what compiled code *does*; this checks the compiler copes with all
# of the real mudlib and builds the same inheritance tables doing it.
#
# The simul_efun program is compiled first and its function names used for
# every later file, as after a boot (ref_compile_sweep.pike does the same).
#
# Usage: compile_sweep.exe <mudlib_root> <file_list.txt> [-v]
# (-v adds the compile error after each FAIL)
#
# Build: star build projects/havokos/tools/compile_sweep.star -o projects/havokos/tools/compile_sweep.exe -l ws2_32

import "../vm.star" as vm
import "../efuns.star" as ef

fn fnv(s: str) -> i64:
    let mask = (65536 as i64) * (65536 as i64) - (1 as i64)
    let mut h = 2166136261 as i64
    let b = bytes_from_str(s)
    for k in 0..b.len():
        h = ((h ^ (b[k] as i64)) * (16777619 as i64)) & mask
    h

fn main() -> i32:
    let cli = args()
    if cli.len() < 3:
        println("usage: compile_sweep <mudlib_root> <file_list.txt> [-v]")
        return 2
    let verbose = cli.len() > 3 and cli[3] == "-v"
    let mut m = vm::new_vm(cli[1])
    m.sefun_path = "/secure/sefun/sefun"
    m.configure("Sweep", 6666)
    # compile the simul_efun program first and resolve against its names,
    # as a boot would (without running it: no objects are made)
    m.set_sefuns_from(m.compile_program(m.sefun_path))
    let mask = (65536 as i64) * (65536 as i64) - (1 as i64)
    let f = file_open(cli[2], "rb")
    if is_null(f):
        println("cannot open file list")
        return 2
    let list = str_split(str_from_bytes(file_read_bytes(f)), "\n")
    file_close(f)
    for i in 0..list.len():
        let vp = str_trim(list[i])
        if vp == "":
            continue
        let id = m.compile_program(m.normalize(vp, ""))
        if id < 0:
            if verbose:
                println(f"{vp} FAIL {m.compile_error}")
            else:
                println(f"{vp} FAIL")
            continue
        let p = m.progs[id]
        let mut fh = 0 as i64
        for j in 0..p.all_func_names.len():
            let name = p.all_func_names[j]
            if let Option::Some(d) = p.all_funcs.get(name):
                let kind = if d: "def" else: "proto"
                fh = (fh + fnv(f"{name}={kind}")) & mask
        let mut vh = 0 as i64
        for j in 0..p.all_var_names.len():
            vh = (vh + fnv(p.all_var_names[j])) & mask
        println(f"{vp} OK {p.all_func_names.len()} {fh} {p.all_var_names.len()} {vh}")
    0

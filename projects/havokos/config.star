# Driver configuration -- todo.md HavokOS M6: what `havok/boot.pike` does
# before it hands over to the driver, shared by the driver itself
# (`boot.star`) and the boot comparison tool (`tools/boot_ds.star`, which had
# its own copy in M5): read a FluffOS-style mudos.cfg (`key : value` lines,
# `#` comments), find the mudlib, collect the telnet ports, and set up a VM
# from it.

import "vm.star" as vm
import "paths.star" as paths

fn trim(s: str) -> str:
    let b = bytes_from_str(s)
    let mut a = 0
    let mut e = b.len()
    while a < e and ((b[a] as i32) == 32 or (b[a] as i32) == 9 or (b[a] as i32) == 13):
        a += 1
    while e > a and ((b[e - 1] as i32) == 32 or (b[e - 1] as i32) == 9 or (b[e - 1] as i32) == 13):
        e -= 1
    vm::substr(s, a, e)

struct Config:
    ok: bool
    file: str
    values: Map<str, str>

fn read_config(path_in: str) -> Config:
    let path = str_replace(path_in, "\\", "/")
    let mut values: Map<str, str> = Map<str, str>()
    let f = file_open(path, "rb")
    if is_null(f):
        return Config(ok = false, file = path, values = values)
    let text = str_from_bytes(file_read_bytes(f))
    file_close(f)
    let lines = str_split(str_replace(text, "\r", ""), "\n")
    for i in 0..lines.len():
        let l = lines[i]
        if l == "" or str_starts_with(l, "#"):
            continue
        let c = str_index_of(l, ":")
        if c < 0:
            continue
        values.insert(trim(vm::substr(l, 0, c)), trim(vm::substr(l, c + 1, len(l))))
    Config(ok = true, file = path, values = values)

fn cfg_get(c: Config, key: str, def: str) -> str:
    if let Option::Some(x) = c.values.get(key):
        return x
    def

# a .c path from the config, as driver normalize_cfg_path()
fn cfg_object_path(p: str) -> str:
    let t = trim(p)
    if str_ends_with(t, ".c"):
        return vm::substr(t, 0, len(t) - 2)
    t

# `mudlib directory`, relative to the config file's directory unless it is
# absolute (boot.pike)
fn mudlib_root(c: Config) -> str:
    let r = str_replace(cfg_get(c, "mudlib directory", "../lib"), "\\", "/")
    let b = bytes_from_str(r)
    let absolute = str_starts_with(r, "/") or (b.len() > 1 and (b[1] as i32) == 58)
    if absolute:
        return paths::combine_path(r, ".")
    paths::combine_path(paths::dirname(c.file), r)

# The telnet ports, `external_port_N : telnet <port>` for N = 1..20 in
# order (boot.pike); 6666 when there is none. Other port kinds (http) are
# not served by this driver yet.
fn telnet_ports(c: Config) -> List<i32>:
    let mut out: List<i32> = List<i32>()
    for n in 1..21:
        let v = cfg_get(c, f"external_port_{n}", "")
        if v == "":
            continue
        let parts = str_split(trim(v), " ")
        if parts.len() >= 2 and parts[0] == "telnet":
            out.push(vm::parse_int_prefix(parts[parts.len() - 1]) as i32)
    if out.len() == 0:
        out.push(6666)
    out

# A VM for the mudlib at `root`, configured as driver.pike create() does
# from the config: every key (get_config() reads them), the mud's name and
# port as predefined macros, include directories, the global include.
fn setup_vm(c: Config, root: str, port: i32) -> vm::Vm:
    let mut m = vm::new_vm(root)
    let keys = ["master file", "simulated efun file", "include directories", "global include file", "time to reset", "time to clean up", "maximum evaluation cost", "log directory", "default fail message", "default error message", "mudlib directory", "binary directory", "address server ip", "address server port", "save binaries directory", "swap file", "debug log file"]
    for i in 0..keys.len():
        if let Option::Some(x) = c.values.get(keys[i]):
            m.config.insert(keys[i], x)
    m.configure(cfg_get(c, "name", "HavokOS"), port)
    if let Option::Some(x) = c.values.get("include directories"):
        m.pp.include_dirs = str_split(x, ":")
    if let Option::Some(x) = c.values.get("global include file"):
        m.pp.global_include = str_replace(str_replace(str_replace(x, "<", ""), ">", ""), "\"", "")
    m

fn sefun_path(c: Config) -> str:
    cfg_object_path(cfg_get(c, "simulated efun file", "/secure/sefun/sefun"))

fn master_path(c: Config) -> str:
    cfg_object_path(cfg_get(c, "master file", "/secure/daemon/master"))

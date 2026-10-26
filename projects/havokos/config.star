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
    # the keys in file order (Map has no iteration)
    keys: List<str>

fn read_config(path_in: str) -> Config:
    let path = str_replace(path_in, "\\", "/")
    let mut values: Map<str, str> = Map<str, str>()
    let mut keys: List<str> = List<str>()
    let f = file_open(path, "rb")
    if is_null(f):
        return Config(ok = false, file = path, values = values, keys = keys)
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
        let k = trim(vm::substr(l, 0, c))
        if !values.contains(k):
            keys.push(k)
        values.insert(k, trim(vm::substr(l, c + 1, len(l))))
    Config(ok = true, file = path, values = values, keys = keys)

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

# One port to serve (boot.pike): `external_port_N : <telnet|http> <port>`,
# with `external_port_N_tls : [cert=<file> key=<file>]` serving it over TLS
# (a value of 0 means plain); `bad` is the error for a line it can't read.
struct PortSpec:
    kind: str
    port: i32
    tls: bool
    tls_spec: str
    bad: str

# Every port line for N = 1..20, in order, with the reference's errors for
# a malformed line or an unknown kind; a telnet port first when there is
# none (6666), and `cli_port` (if not 0) replacing the first telnet port.
fn port_specs(c: Config, cli_port: i32) -> List<PortSpec>:
    let mut out: List<PortSpec> = List<PortSpec>()
    for n in 1..21:
        let v = cfg_get(c, f"external_port_{n}", "")
        if v == "":
            continue
        let parts = str_split(trim(v), " ")
        let num = if parts.len() >= 2: vm::parse_int_prefix(parts[parts.len() - 1]) as i32 else: 0
        if parts.len() < 2 or num == 0:
            out.push(PortSpec(kind = "", port = 0, tls = false, tls_spec = "", bad = f"Bad external_port_{n}: \"{v}\""))
            continue
        let kind = lower_word(parts[0])
        if kind != "telnet" and kind != "http":
            out.push(PortSpec(kind = kind, port = num, tls = false, tls_spec = "", bad = f"external_port_{n}: unknown port kind \"{kind}\" (telnet or http)"))
            continue
        let t = cfg_get(c, f"external_port_{n}_tls", "")
        let has = c.values.contains(f"external_port_{n}_tls") and t != "0"
        out.push(PortSpec(kind = kind, port = num, tls = has, tls_spec = t, bad = ""))
    let mut first = -1
    for i in 0..out.len():
        if first < 0 and out[i].kind == "telnet" and out[i].bad == "":
            first = i
    if first < 0:
        let mut all: List<PortSpec> = [PortSpec(kind = "telnet", port = 6666, tls = false, tls_spec = "", bad = "")]
        for i in 0..out.len():
            all.push(out[i])
        out = all
        first = 0
    if cli_port > 0:
        let f = out[first]
        out[first] = PortSpec(kind = f.kind, port = cli_port, tls = f.tls, tls_spec = f.tls_spec, bad = f.bad)
    out

fn lower_word(s: str) -> str:
    let b = bytes_from_str(trim(s))
    let mut o: Bytes = Bytes()
    for i in 0..b.len():
        let ch = b[i] as i32
        o.push(if ch >= 65 and ch <= 90: (ch + 32) as u8 else: b[i])
    str_from_bytes(o)

# The first telnet port served (boot.pike's `port`), and the first telnet
# port over TLS (0: none; MSSP's TLS entry, __TLS_PORT__).
fn first_telnet(specs: List<PortSpec>) -> i32:
    for i in 0..specs.len():
        if specs[i].kind == "telnet" and specs[i].bad == "":
            return specs[i].port
    6666

fn first_tls_telnet(specs: List<PortSpec>) -> i32:
    for i in 0..specs.len():
        if specs[i].kind == "telnet" and specs[i].tls and specs[i].bad == "":
            return specs[i].port
    0

# The telnet ports, `external_port_N : telnet <port>` for N = 1..20 in
# order (boot.pike); 6666 when there is none.
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
# port as predefined macros, include directories, the global include; since
# P1 #8 also the config file's directory (`havok config dir`, where TLS
# file names are found) and, with a telnet port over TLS, its number
# (`havok tls telnet port`, and __TLS_PORT__ for MSSP).
fn setup_vm(c: Config, root: str, port: i32) -> vm::Vm:
    let mut m = vm::new_vm(root)
    let keys = ["master file", "simulated efun file", "include directories", "global include file", "time to reset", "time to clean up", "maximum evaluation cost", "log directory", "default fail message", "default error message", "mudlib directory", "binary directory", "address server ip", "address server port", "save binaries directory", "swap file", "debug log file"]
    for i in 0..keys.len():
        if let Option::Some(x) = c.values.get(keys[i]):
            m.config.insert(keys[i], x)
    # the driver's own settings (`havok mccp`, `havok http timeout`, the TLS
    # files, ...) and the port lines, which the reference reads from the
    # same table
    for i in 0..c.keys.len():
        let k = c.keys[i]
        if str_starts_with(k, "havok ") or str_starts_with(k, "external_port_"):
            if let Option::Some(x) = c.values.get(k):
                m.config.insert(k, x)
    m.configure(cfg_get(c, "name", "HavokOS"), port)
    let slash = last_slash(c.file)
    m.config.insert("havok config dir", if slash < 0: "." else: vm::substr(c.file, 0, slash))
    let tp = first_tls_telnet(port_specs(c, 0))
    if tp > 0:
        m.config.insert("havok tls telnet port", f"{tp}")
        m.pp.predefine("__TLS_PORT__", f"{tp}")
    if let Option::Some(x) = c.values.get("include directories"):
        m.pp.include_dirs = str_split(x, ":")
    if let Option::Some(x) = c.values.get("global include file"):
        m.pp.global_include = str_replace(str_replace(str_replace(x, "<", ""), ">", ""), "\"", "")
    m

fn last_slash(s: str) -> i32:
    let b = bytes_from_str(s)
    let mut i = b.len() - 1
    while i >= 0:
        if (b[i] as i32) == 47:
            return i
        i -= 1
    -1

fn sefun_path(c: Config) -> str:
    cfg_object_path(cfg_get(c, "simulated efun file", "/secure/sefun/sefun"))

fn master_path(c: Config) -> str:
    cfg_object_path(cfg_get(c, "master file", "/secure/daemon/master"))

# HavokOS entry point -- todo.md HavokOS M6, `havok/boot.pike`:
#
#   havokos.exe <mudos.cfg> [port]
#
# reads the FluffOS-style config, boots the mudlib (simul_efun object,
# master, epilog() and the preloads), then serves every
# `external_port_N : <telnet|http> <port>` of the config -- over TLS with
# `external_port_N_tls` (P1 #8) -- until the mudlib calls shutdown(). A port
# given on the command line replaces the first telnet port; with no telnet
# port configured, 6666 is served (boot.pike).
#
# The main loop is the reference's Pike backend made explicit: wait for
# input (tcp_wait(), inside net_poll()) no longer than until the next
# timer is due, handle what arrived, then run the timers (driver_tick():
# call_outs, the heart beat slot, the reset sweep, garbage collection) and
# write what is queued.
#
# Build: star build projects/havokos/boot.star -o projects/havokos/tools/havokos.exe -l ws2_32 -L sqlite/lib/x64 -l sqlite3 -L openssl/lib/x64 -l ssl -l crypto

import "vm.star" as vm
import "efuns.star" as ef
import "gc.star" as gc
import "objects.star" as objm
import "net.star" as net
import "config.star" as cfgm
import "netdata.star" as nd

fn main() -> i32:
    let cli = args()
    if cli.len() < 2:
        println("Usage: havokos <mudos.cfg> [port]")
        return 1
    let cfg = cfgm::read_config(cli[1])
    if !cfg.ok:
        println(f"Cannot read config {cli[1]}")
        return 1
    let mut cli_port = 0
    for k in 2..cli.len():
        let p = vm::parse_int_prefix(cli[k]) as i32
        if p > 0:
            cli_port = p
    let specs = cfgm::port_specs(cfg, cli_port)
    for i in 0..specs.len():
        if specs[i].bad != "":
            println(specs[i].bad)
            return 1
    let root = cfgm::mudlib_root(cfg)
    let mut m = cfgm::setup_vm(cfg, root, cfgm::first_telnet(specs))
    m.echo_log = true
    m.keep_log = false
    # `havok save store : sqlite` (savestore.star): without its database
    # the mudlib would boot with none of its saves
    if !m.store_configure():
        println("Cannot open the save store.")
        return 1
    println(f"HavokOS (Star) booting, mudlib {root}")
    let t0 = clock_ms()
    if !m.boot(cfgm::sefun_path(cfg), cfgm::master_path(cfg)):
        println("Boot failed.")
        return 1
    m.collect_garbage()
    println(f"Boot done in {clock_ms() - t0} ms")
    for i in 0..specs.len():
        let sp = specs[i]
        let mut ctx = null_ptr()
        if sp.tls:
            let files = m.tls_port_files(sp.tls_spec)
            ctx = m.tls_server_context(files[0], files[1])
            if is_null(ctx):
                print(f"Port {sp.port}: {m.tls_err}")
                return 1
        let kind = if sp.kind == "http": nd::LK_HTTP else: nd::LK_TELNET
        if m.net_listen_kind(sp.port, kind, ctx, false) == 0:
            return 1
    while !m.shutdown_requested:
        m.net_poll(m.next_timer_ms())
        m.driver_tick()
        m.net_flush_all()
    for i in 0..m.conns.len():
        if m.conn_ok(i):
            m.conn_flush(i)
    m.store_flush()
    m.shutdown_code

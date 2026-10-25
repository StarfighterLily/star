# HavokOS entry point -- todo.md HavokOS M6, `havok/boot.pike`:
#
#   havokos.exe <mudos.cfg> [port]
#
# reads the FluffOS-style config, boots the mudlib (simul_efun object,
# master, epilog() and the preloads), then serves telnet on every
# `external_port_N : telnet <port>` of the config (a port given on the
# command line replaces the first) until the mudlib calls shutdown().
#
# The main loop is the reference's Pike backend made explicit: wait for
# input (tcp_wait(), inside net_poll()) no longer than until the next
# timer is due, handle what arrived, then run the timers (driver_tick():
# call_outs, the heart beat slot, the reset sweep, garbage collection) and
# write what is queued. HTTP ports (`external_port_N : http <port>`) and
# TLS are not served yet.
#
# Build: star build projects/havokos/boot.star -o projects/havokos/tools/havokos.exe -l ws2_32

import "vm.star" as vm
import "efuns.star" as ef
import "gc.star" as gc
import "objects.star" as objm
import "net.star" as net
import "config.star" as cfgm

fn main() -> i32:
    let cli = args()
    if cli.len() < 2:
        println("Usage: havokos <mudos.cfg> [port]")
        return 1
    let cfg = cfgm::read_config(cli[1])
    if !cfg.ok:
        println(f"Cannot read config {cli[1]}")
        return 1
    let mut ports = cfgm::telnet_ports(cfg)
    for k in 2..cli.len():
        let p = vm::parse_int_prefix(cli[k]) as i32
        if p > 0:
            ports[0] = p
    let root = cfgm::mudlib_root(cfg)
    let mut m = cfgm::setup_vm(cfg, root, ports[0])
    m.echo_log = true
    m.keep_log = false
    println(f"HavokOS (Star) booting, mudlib {root}")
    let t0 = clock_ms()
    if !m.boot(cfgm::sefun_path(cfg), cfgm::master_path(cfg)):
        println("Boot failed.")
        return 1
    m.collect_garbage()
    println(f"Boot done in {clock_ms() - t0} ms")
    for i in 0..ports.len():
        if m.net_listen(ports[i]) == 0:
            return 1
    while !m.shutdown_requested:
        m.net_poll(m.next_timer_ms())
        m.driver_tick()
        m.net_flush_all()
    for i in 0..m.conns.len():
        if m.conn_ok(i):
            m.conn_flush(i)
    m.shutdown_code

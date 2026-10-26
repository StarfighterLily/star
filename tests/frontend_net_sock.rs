//! Event-loop socket builtins (`tcp_listen_at`, `tcp_connect_start`,
//! `tcp_sock_error`, `tcp_wait_io`, `tcp_local_ip`, `tcp_peer_port`,
//! `udp_open`, `udp_recv_from`, `udp_send_to`, `host_lookup`;
//! `crate::codegen::net_sock`), added for the HavokOS LPMUD driver's LPC
//! socket efuns (`todo.md` HavokOS P1 #5).
//!
//! Unlike `frontend_net_server.rs`, the runtime tests need no Rust peer: a
//! non-blocking connect lets one Star program be both ends, over loopback.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

/// Like `compile_and_run`, linking `ws2_32` (see `frontend_networking.rs`).
fn compile_and_run_ws2(name: &str, src: &str) -> std::process::Output {
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let exe = std::env::temp_dir().join(format!("star_test_{}.exe", name));
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap(), "-lws2_32"])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");
    let output = std::process::Command::new(&exe).output().expect("failed to execute compiled test binary");
    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
    output
}

fn stdout_of(name: &str, src: &str) -> String {
    let out = compile_and_run_ws2(name, src);
    let text = String::from_utf8_lossy(&out.stdout).replace("\r\n", "\n");
    assert!(out.status.success(), "{} failed: {}{}", name, text, String::from_utf8_lossy(&out.stderr));
    text
}

fn check_err(src: &str) -> String {
    let module = Driver::parse(src).expect("should parse");
    match Driver::check(&module) {
        Ok(_) => panic!("expected a type error"),
        Err(diags) => diags.iter().map(|d| d.message.clone()).collect::<Vec<_>>().join("\n"),
    }
}

/// Each builtin type-checks to its documented result type.
#[test]
fn checks_builtin_result_types() {
    let src = concat!(
        "fn t():\n",
        "    let l: ptr = tcp_listen_at(\"127.0.0.1\", 0)\n",
        "    let c: ptr = tcp_connect_start(\"127.0.0.1\", 80)\n",
        "    let e: int = tcp_sock_error(c)\n",
        "    let hs: List<ptr> = [l, c]\n",
        "    let r: Bytes = tcp_wait_io(hs, Bytes(), 10)\n",
        "    let ip: str = tcp_local_ip(c)\n",
        "    let pp: int = tcp_peer_port(c)\n",
        "    let u: ptr = udp_open(\"\", 0)\n",
        "    let d: Bytes = udp_recv_from(u)\n",
        "    let n: int = udp_send_to(u, \"127.0.0.1\", 9, d)\n",
        "    let a: str = host_lookup(\"localhost\")\n",
    );
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("should type-check");
}

/// Wrong argument types and counts are reported by builtin name.
#[test]
fn checker_rejects_bad_arguments() {
    assert!(check_err("fn t():\n    let l = tcp_listen_at(0, 0)\n").contains("`tcp_listen_at` argument 1"));
    assert!(check_err("fn t():\n    let l = tcp_connect_start(\"x\", \"80\")\n").contains("`tcp_connect_start` argument 2"));
    assert!(check_err("fn t():\n    let l = udp_open(\"x\")\n").contains("udp_open"));
    assert!(check_err("fn t():\n    let e = tcp_sock_error(3)\n").contains("`tcp_sock_error` expects a `ptr`"));
    let hs = "    let hs: List<ptr> = []\n";
    assert!(check_err(&format!("fn t():\n{}    let r = tcp_wait_io(hs, \"x\", 0)\n", hs)).contains("`tcp_wait_io` argument 2"));
    assert!(check_err(&format!("fn t():\n{}    let r = tcp_wait_io(hs, Bytes())\n", hs)).contains("tcp_wait_io"));
    let u = "    let u = udp_open(\"\", 0)\n";
    assert!(check_err(&format!("fn t():\n{}    let n = udp_send_to(u, \"a\", 1, \"text\")\n", u)).contains("`udp_send_to` argument 4"));
    assert!(check_err(&format!("fn t():\n{}    let n = udp_send_to(u, 1, 1, Bytes())\n", u)).contains("`udp_send_to` argument 2"));
    assert!(check_err("fn t():\n    let a = host_lookup(5)\n").contains("`host_lookup` expects a `str`"));
}

/// `sendto`/`recvfrom`/`getsockopt`/`gethostbyname` are declared only on use, so user functions of those names still compile.
#[test]
fn codegen_declares_externs_only_on_use() {
    let src = "fn sendto(x: i32) -> i32:\n    x * 2\nfn getsockopt() -> i32:\n    7\nfn main():\n    println(f\"{sendto(2)} {getsockopt()}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    for name in ["@sendto(", "@recvfrom(", "@getsockopt(", "@gethostbyname(", "@realloc("] {
        assert!(!ir.lines().any(|l| l.starts_with("declare") && l.contains(name)), "{} declared without use", name);
    }
    let output = compile_and_run("net_sock_user_sendto", src);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "4 7");
}

const ALL_BUILTINS_SRC: &str = concat!(
    "fn main():\n",
    "    let l = tcp_listen_at(\"0.0.0.0\", 4000)\n",
    "    let c = tcp_connect_start(\"127.0.0.1\", 4000)\n",
    "    let hs: List<ptr> = [l, c]\n",
    "    let mut want = Bytes()\n",
    "    want.push(1 as u8)\n",
    "    want.push(5 as u8)\n",
    "    let r = tcp_wait_io(hs, want, 10)\n",
    "    let u = udp_open(\"\", 0)\n",
    "    let d = udp_recv_from(u)\n",
    "    let n = udp_send_to(u, \"127.0.0.1\", 9, d)\n",
    "    let a = host_lookup(\"localhost\")\n",
    "    let ip = tcp_local_ip(c)\n",
    "    println(f\"{r.len()} {tcp_sock_error(c)} {tcp_peer_port(c)} {n} {a} {ip}\")\n",
);

/// The Windows arm polls with POLLWRNORM, reads SO_ERROR at SOL_SOCKET 0xffff/0x1007, and declares each extern once.
#[test]
fn codegen_windows_arm_shapes() {
    let module = Driver::parse(ALL_BUILTINS_SRC).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let v = Driver::codegen_verified_for_target(&typed, star::codegen::Target::WindowsGnu).expect("should codegen");
    assert!(v.errors.is_empty(), "{:?}", v.errors.iter().map(|d| &d.message).collect::<Vec<_>>());
    for decl in [
        "declare i32 @bind(i8*, i8*, i32)",
        "declare i32 @getsockopt(i8*, i32, i32, i8*, i32*)",
        "declare i32 @recvfrom(i8*, i8*, i32, i32, i8*, i32*)",
        "declare i32 @sendto(i8*, i8*, i32, i32, i8*, i32)",
        "declare i8* @gethostbyname(i8*)",
        "declare i32 @WSAPoll(i8*, i32, i32)",
        "declare i8* @inet_ntoa(i32)",
    ] {
        assert_eq!(v.ir.matches(decl).count(), 1, "{} should be declared once:\n{}", decl, v.ir);
    }
    assert!(v.ir.contains("i32 65535, i32 4103"), "SOL_SOCKET/SO_ERROR:\n{}", v.ir);
    assert!(v.ir.contains(", i32 16, i32 0"), "POLLWRNORM for write interest:\n{}", v.ir);
    assert!(v.ir.contains("icmp eq i32 %") && v.ir.contains(", 10035"), "WSAEWOULDBLOCK counts as started:\n{}", v.ir);
}

/// The Linux arm passes the IR verifier with EINPROGRESS, SO_ERROR 1/4 and 64-bit lengths, and compiles to an x86-64 Linux object.
#[test]
fn codegen_linux_arm_verifies_and_compiles_to_object() {
    let module = Driver::parse(ALL_BUILTINS_SRC).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let v = Driver::codegen_verified_for_target(&typed, star::codegen::Target::LinuxGnu).expect("should codegen");
    assert!(v.errors.is_empty(), "{:?}", v.errors.iter().map(|d| &d.message).collect::<Vec<_>>());
    assert!(v.ir.contains("declare i64 @sendto(i32, i8*, i64, i32, i8*, i32)"), "{}", v.ir);
    assert!(v.ir.contains("declare i64 @recvfrom(i32, i8*, i64, i32, i8*, i32*)"), "{}", v.ir);
    assert!(v.ir.contains(", i32 1, i32 4, i8* "), "SOL_SOCKET/SO_ERROR:\n{}", v.ir);
    assert!(v.ir.contains(", 115"), "EINPROGRESS:\n{}", v.ir);
    assert!(v.ir.contains(", i32 4, i32 0"), "POLLOUT for write interest:\n{}", v.ir);
    assert!(!v.ir.contains("WSA"), "{}", v.ir);
    let dir = std::env::temp_dir();
    let ll = dir.join("star_test_net_sock_linux.ll");
    let obj = dir.join("star_test_net_sock_linux.o");
    std::fs::write(&ll, &v.ir).unwrap();
    let status = std::process::Command::new("clang")
        .args(["-c", "--target=x86_64-unknown-linux-gnu", ll.to_str().unwrap(), "-o", obj.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&obj);
    assert!(status.success(), "the Linux IR should compile to an object");
}

/// End to end: a non-blocking connect to a loopback listener becomes writable with no error, and both ends report each other's addresses.
#[test]
fn runtime_connect_start_and_addresses_end_to_end() {
    let out = stdout_of(
        "net_sock_connect",
        concat!(
            "fn main():\n",
            "    let l = tcp_listen_at(\"127.0.0.1\", 0)\n",
            "    let port = tcp_local_port(l)\n",
            "    println(f\"listen {is_null(l)} {tcp_local_ip(l)}\")\n",
            "    let c = tcp_connect_start(\"127.0.0.1\", port)\n",
            "    let hs: List<ptr> = [c]\n",
            "    let mut want = Bytes()\n",
            "    want.push(4 as u8)\n",
            "    let r = tcp_wait_io(hs, want, 5000)\n",
            "    println(f\"writable {(r[0] as i32) & 4} err {tcp_sock_error(c)}\")\n",
            "    let lh: List<ptr> = [l]\n",
            "    let lr = tcp_wait(lh, 5000)\n",
            "    let a = tcp_accept(l)\n",
            "    println(f\"accepted {is_null(a)} {tcp_peer_ip(a)} {tcp_local_ip(a)}\")\n",
            "    println(f\"ports {tcp_peer_port(a) == tcp_local_port(c)} {tcp_peer_port(c) == port} {tcp_peer_port(l)}\")\n",
            "    let mut msg = Bytes()\n",
            "    msg.push(7 as u8)\n",
            "    let sent = tcp_send_bytes(c, msg, 0)\n",
            "    let ah: List<ptr> = [a]\n",
            "    let ar = tcp_wait(ah, 5000)\n",
            "    let got = tcp_recv_bytes(a)\n",
            "    println(f\"data {sent} {got.len()} {got[0] as i32}\")\n",
        ),
    );
    assert_eq!(
        out,
        "listen false 127.0.0.1\nwritable 4 err 0\naccepted false 127.0.0.1 127.0.0.1\nports true true -1\ndata 1 1 7\n"
    );
}

/// A connect to a closed port starts, then reports error/writable readiness and a nonzero SO_ERROR (ECONNREFUSED).
#[test]
fn runtime_refused_connect_reports_error_end_to_end() {
    let port = std::net::TcpListener::bind("127.0.0.1:0").unwrap().local_addr().unwrap().port();
    let out = stdout_of(
        "net_sock_refused",
        &format!(
            concat!(
                "fn main():\n",
                "    let c = tcp_connect_start(\"127.0.0.1\", {port})\n",
                "    let hs: List<ptr> = [c]\n",
                "    let mut want = Bytes()\n",
                "    want.push(5 as u8)\n",
                "    let r = tcp_wait_io(hs, want, 10000)\n",
                "    let e = tcp_sock_error(c)\n",
                "    println(f\"started {{!is_null(c)}} flagged {{(r[0] as i32) != 0}} refused {{e == 10061 or e == 111}}\")\n",
            ),
            port = port
        ),
    );
    assert_eq!(out, "started true flagged true refused true\n");
}

/// Malformed addresses fail cleanly: null handles, -1 sends, and an empty name lookup; "" means any address only for binding.
#[test]
fn runtime_malformed_addresses_fail_end_to_end() {
    let out = stdout_of(
        "net_sock_malformed",
        concat!(
            "fn main():\n",
            "    let a = tcp_connect_start(\"not.an.ip\", 80)\n",
            "    let b = tcp_connect_start(\"\", 80)\n",
            "    let c = tcp_listen_at(\"1.2.3\", 0)\n",
            "    let d = udp_open(\"300.1.1.1\", 0)\n",
            "    let u = udp_open(\"\", 0)\n",
            "    let n = udp_send_to(u, \"bogus\", 9, Bytes())\n",
            "    let any = tcp_listen_at(\"\", 0)\n",
            "    println(f\"{is_null(a)} {is_null(b)} {is_null(c)} {is_null(d)} {is_null(u)} {n} {is_null(any)} {tcp_local_ip(any)}\")\n",
        ),
    );
    assert_eq!(out, "true true true true false -1 false 0.0.0.0\n");
}

/// Binding an address already listened on gives null, as `tcp_listen` does.
#[test]
fn runtime_listen_at_taken_port_returns_null_end_to_end() {
    let out = stdout_of(
        "net_sock_taken",
        concat!(
            "fn main():\n",
            "    let l = tcp_listen_at(\"127.0.0.1\", 0)\n",
            "    let again = tcp_listen_at(\"127.0.0.1\", tcp_local_port(l))\n",
            "    println(f\"{is_null(l)} {is_null(again)}\")\n",
        ),
    );
    assert_eq!(out, "false true\n");
}

/// A datagram arrives with its sender's address and port in a 6-byte header, NUL bytes intact; an empty queue reads as empty.
#[test]
fn runtime_udp_round_trip_with_sender_header_end_to_end() {
    let out = stdout_of(
        "net_sock_udp",
        concat!(
            "fn main():\n",
            "    let rx = udp_open(\"127.0.0.1\", 0)\n",
            "    let tx = udp_open(\"\", 0)\n",
            "    let none = udp_recv_from(rx)\n",
            "    let mut d = Bytes()\n",
            "    d.push(65 as u8)\n",
            "    d.push(0 as u8)\n",
            "    d.push(255 as u8)\n",
            "    let sent = udp_send_to(tx, \"127.0.0.1\", tcp_local_port(rx), d)\n",
            "    let empty_sent = udp_send_to(tx, \"127.0.0.1\", tcp_local_port(rx), Bytes())\n",
            "    let hs: List<ptr> = [rx]\n",
            "    let r = tcp_wait_io(hs, Bytes(), 5000)\n",
            "    let g = udp_recv_from(rx)\n",
            "    let from = ((g[4] as i32) * 256) + (g[5] as i32)\n",
            "    println(f\"{none.len()} {sent} {empty_sent} {r[0] as i32} {g.len()}\")\n",
            "    println(f\"{g[0] as i32}.{g[1] as i32}.{g[2] as i32}.{g[3] as i32} {from == tcp_local_port(tx)} {g[6] as i32} {g[7] as i32} {g[8] as i32}\")\n",
            "    let r2 = tcp_wait_io(hs, Bytes(), 5000)\n",
            "    let g2 = udp_recv_from(rx)\n",
            "    let g3 = udp_recv_from(rx)\n",
            "    println(f\"{g2.len()} {g3.len()}\")\n",
        ),
    );
    assert_eq!(out, "0 3 0 1 9\n127.0.0.1 true 65 0 255\n6 0\n");
}

/// `tcp_wait_io` treats handles past the end of `interest` as read-only, and reports a write-only idle socket as not readable.
#[test]
fn runtime_wait_io_interest_defaults_and_bits_end_to_end() {
    let out = stdout_of(
        "net_sock_interest",
        concat!(
            "fn main():\n",
            "    let l = tcp_listen_at(\"127.0.0.1\", 0)\n",
            "    let c = tcp_connect_start(\"127.0.0.1\", tcp_local_port(l))\n",
            "    let lh: List<ptr> = [l]\n",
            "    let w = tcp_wait(lh, 5000)\n",
            "    let a = tcp_accept(l)\n",
            "    let hs: List<ptr> = [c, a]\n",
            "    let mut want = Bytes()\n",
            "    want.push(4 as u8)\n",
            "    let r = tcp_wait_io(hs, want, 200)\n",
            "    println(f\"{r[0] as i32} {r[1] as i32}\")\n",
        ),
    );
    // c: writable only; a: nothing to read yet (and write interest not asked)
    assert_eq!(out, "4 0\n");
}

/// `host_lookup` resolves localhost and numeric addresses, and gives "" for a name that can't exist.
#[test]
fn runtime_host_lookup_end_to_end() {
    let out = stdout_of(
        "net_sock_lookup",
        concat!(
            "fn main():\n",
            "    let a = host_lookup(\"localhost\")\n",
            "    let b = host_lookup(\"10.1.2.3\")\n",
            "    let c = host_lookup(\"no-such-host.invalid\")\n",
            "    println(f\"{a} {b} [{c}]\")\n",
        ),
    );
    assert_eq!(out, "127.0.0.1 10.1.2.3 []\n");
}

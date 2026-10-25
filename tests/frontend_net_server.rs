//! Server-side TCP builtins (`tcp_listen`/`tcp_accept`/`tcp_wait`/
//! `tcp_recv_bytes`/`tcp_send_bytes`/`tcp_peer_ip`/`tcp_local_port`,
//! `crate::codegen::net_server`), added for the HavokOS LPMUD driver's
//! telnet listener (`todo.md` HavokOS M6).
//!
//! The runtime tests run a Star *server* and drive it from a `std::net`
//! client thread in the Rust test, the mirror image of
//! `frontend_networking.rs` (Star client, Rust listener). The Rust side picks
//! a free port first and bakes it into the Star source, since the Star
//! program's stdout is only readable once it exits.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

use std::io::{Read, Write};
use std::time::{Duration, Instant};

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

/// A port nothing is listening on right now.
fn free_port() -> u16 {
    let l = std::net::TcpListener::bind("127.0.0.1:0").expect("bind scratch listener");
    l.local_addr().unwrap().port()
}

/// Connect to the Star server, retrying while it is still being compiled.
fn connect_retry(port: u16) -> std::net::TcpStream {
    let deadline = Instant::now() + Duration::from_secs(60);
    loop {
        match std::net::TcpStream::connect(("127.0.0.1", port)) {
            Ok(s) => return s,
            Err(e) => {
                assert!(Instant::now() < deadline, "the Star server never started listening: {}", e);
                std::thread::sleep(Duration::from_millis(50));
            }
        }
    }
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
fn checks_server_builtin_result_types() {
    let src = concat!(
        "fn t():\n",
        "    let l: ptr = tcp_listen(0, true)\n",
        "    let c: ptr = tcp_accept(l)\n",
        "    let hs: List<ptr> = [l, c]\n",
        "    let ready: Bytes = tcp_wait(hs, 10)\n",
        "    let d: Bytes = tcp_recv_bytes(c)\n",
        "    let n: int = tcp_send_bytes(c, d, 0)\n",
        "    let ip: str = tcp_peer_ip(c)\n",
        "    let p: int = tcp_local_port(l)\n",
    );
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("should type-check");
}

/// Wrong argument types and counts are reported by name.
#[test]
fn checker_rejects_bad_server_builtin_arguments() {
    assert!(check_err("fn t():\n    let l = tcp_listen(\"80\", true)\n").contains("`tcp_listen` argument 1"));
    assert!(check_err("fn t():\n    let l = tcp_listen(80, 1)\n").contains("`tcp_listen` argument 2"));
    assert!(check_err("fn t():\n    let c = tcp_accept(5)\n").contains("`tcp_accept` expects a `ptr`"));
    assert!(check_err("fn t():\n    let hs: List<str> = [\"a\"]\n    let r = tcp_wait(hs, 0)\n").contains("`tcp_wait` argument 1"));
    assert!(check_err("fn t():\n    let l = tcp_listen(80, true)\n    let n = tcp_send_bytes(l, \"text\", 0)\n").contains("`tcp_send_bytes` argument 2"));
    let arity = check_err("fn t():\n    let l = tcp_listen(80, true)\n    let n = tcp_send_bytes(l, Bytes())\n");
    assert!(arity.contains("tcp_send_bytes"), "{}", arity);
}

/// `bind`/`listen`/`accept`/`poll` are declared only by programs that use these builtins, so a user `fn bind` still compiles.
#[test]
fn codegen_declares_server_externs_only_on_use() {
    let module = Driver::parse("fn bind(x: i32) -> i32:\n    x + 1\nfn main():\n    println(f\"{bind(1)}\")\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("define i32 @bind(i32 %x)"), "{}", ir);
    for name in ["@bind(i8*", "@listen(", "@accept(", "@WSAPoll(", "@getpeername("] {
        assert!(!ir.contains(&format!("declare i32 {}", name)) && !ir.contains(&format!("declare i8* {}", name)), "{} declared without use", name);
    }
    let output = compile_and_run("net_server_user_bind", "fn bind(x: i32) -> i32:\n    x + 1\nfn main():\n    println(f\"{bind(1)}\")\n");
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "2");
}

const ALL_BUILTINS_SRC: &str = concat!(
    "fn main():\n",
    "    let l = tcp_listen(4000, false)\n",
    "    let c = tcp_accept(l)\n",
    "    let hs: List<ptr> = [l, c]\n",
    "    let ready = tcp_wait(hs, 10)\n",
    "    let d = tcp_recv_bytes(c)\n",
    "    let n = tcp_send_bytes(c, d, 1)\n",
    "    println(tcp_peer_ip(c))\n",
    "    println(f\"{tcp_local_port(l)} {n} {ready.len()}\")\n",
);

/// The Windows arm uses WSAPoll's 16-byte entries, Sleep for an empty wait, and each extern is declared exactly once.
#[test]
fn codegen_windows_arm_shapes() {
    let module = Driver::parse(ALL_BUILTINS_SRC).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let v = Driver::codegen_verified_for_target(&typed, star::codegen::Target::WindowsGnu).expect("should codegen");
    assert!(v.errors.is_empty(), "{:?}", v.errors.iter().map(|d| &d.message).collect::<Vec<_>>());
    for decl in ["declare i32 @bind(i8*, i8*, i32)", "declare i32 @listen(i8*, i32)", "declare i8* @accept(i8*, i8*, i32*)", "declare i32 @WSAPoll(i8*, i32, i32)", "declare void @Sleep(i32)", "declare i8* @inet_ntoa(i32)"] {
        assert_eq!(v.ir.matches(decl).count(), 1, "{} should be declared once:\n{}", decl, v.ir);
    }
    assert!(v.ir.contains("call i32 @WSAPoll("), "{}", v.ir);
    assert!(!v.ir.contains("@setsockopt"), "SO_REUSEADDR is Linux-only:\n{}", v.ir);
}

/// The Linux arm passes the IR verifier with poll(), SO_REUSEADDR and MSG_NOSIGNAL, and compiles to an x86-64 Linux object.
#[test]
fn codegen_linux_arm_verifies_and_compiles_to_object() {
    let module = Driver::parse(ALL_BUILTINS_SRC).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let v = Driver::codegen_verified_for_target(&typed, star::codegen::Target::LinuxGnu).expect("should codegen");
    assert!(v.errors.is_empty(), "{:?}", v.errors.iter().map(|d| &d.message).collect::<Vec<_>>());
    assert!(v.ir.contains("declare i32 @poll(i8*, i64, i32)"), "{}", v.ir);
    assert!(v.ir.contains("call i32 @setsockopt(i32 "), "{}", v.ir);
    assert!(v.ir.contains(", i32 1, i32 2, i8* "), "SOL_SOCKET/SO_REUSEADDR:\n{}", v.ir);
    assert!(v.ir.contains("i32 16384)"), "send should pass MSG_NOSIGNAL:\n{}", v.ir);
    assert!(!v.ir.contains("WSAPoll"), "{}", v.ir);
    let dir = std::env::temp_dir();
    let ll = dir.join("star_test_net_server_linux.ll");
    let obj = dir.join("star_test_net_server_linux.o");
    std::fs::write(&ll, &v.ir).unwrap();
    let status = std::process::Command::new("clang")
        .args(["-c", "--target=x86_64-unknown-linux-gnu", ll.to_str().unwrap(), "-o", obj.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&obj);
    assert!(status.success(), "the Linux IR should compile to an object");
}

/// End to end: accept a client, report its address, echo binary data (NUL and 0xff intact), and see the close as an empty read.
#[test]
fn runtime_server_accepts_and_echoes_binary_end_to_end() {
    let port = free_port();
    let client = std::thread::spawn(move || {
        let mut s = connect_retry(port);
        s.write_all(&[65, 0, 255, 13, 10, 0, 66]).unwrap();
        let mut got = [0u8; 7];
        s.read_exact(&mut got).unwrap();
        got
    });
    let src = format!(
        concat!(
            "fn main() -> i32:\n",
            "    let l = tcp_listen({port}, true)\n",
            "    if is_null(l):\n",
            "        println(\"listen failed\")\n",
            "        return 1\n",
            "    println(f\"port {{tcp_local_port(l)}}\")\n",
            "    let mut hs: List<ptr> = [l]\n",
            "    let deadline = clock_ms() + (90000 as i64)\n",
            "    while clock_ms() < deadline:\n",
            "        let ready = tcp_wait(hs, 1000)\n",
            "        if (ready[0] as i32) != 0:\n",
            "            let c = tcp_accept(l)\n",
            "            if !is_null(c):\n",
            "                println(f\"peer {{tcp_peer_ip(c)}}\")\n",
            "                hs.push(c)\n",
            "        if hs.len() > 1 and (ready.len() > 1 and (ready[1] as i32) != 0):\n",
            "            let d = tcp_recv_bytes(hs[1])\n",
            "            if d.len() == 0:\n",
            "                println(\"closed\")\n",
            "                return 0\n",
            "            let mut s = \"\"\n",
            "            for k in 0..d.len():\n",
            "                s = concat(s, f\"{{d[k] as i32}} \")\n",
            "            println(f\"got {{s}}\")\n",
            "            let mut off = 0\n",
            "            while off < d.len():\n",
            "                let n = tcp_send_bytes(hs[1], d, off)\n",
            "                if n < 0:\n",
            "                    return 3\n",
            "                off += n\n",
            "    2\n",
        ),
        port = port
    );
    let output = compile_and_run_ws2("net_server_echo", &src);
    let echoed = client.join().expect("client thread panicked");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(output.status.success(), "{:?} {}", output.status, stdout);
    assert_eq!(echoed, [65, 0, 255, 13, 10, 0, 66]);
    assert!(stdout.contains(&format!("port {}", port)), "{}", stdout);
    assert!(stdout.contains("peer 127.0.0.1"), "{}", stdout);
    assert!(stdout.contains("got 65 0 255 13 10 0 66 "), "a 0 byte must not truncate the read: {}", stdout);
    assert!(stdout.trim_end().ends_with("closed"), "{}", stdout);
}

/// With nothing pending, accept returns null at once, a timed wait reports nothing ready, and an empty wait just sleeps.
#[test]
fn runtime_idle_listener_accept_null_and_wait_times_out_end_to_end() {
    let port = free_port();
    let src = format!(
        concat!(
            "fn main():\n",
            "    let l = tcp_listen({port}, true)\n",
            "    let c = tcp_accept(l)\n",
            "    println(f\"accept null {{is_null(c)}}\")\n",
            "    let hs: List<ptr> = [l]\n",
            "    let t0 = clock_ms()\n",
            "    let r = tcp_wait(hs, 300)\n",
            "    let t1 = clock_ms()\n",
            "    println(f\"wait {{r.len()}} {{r[0] as i32}} slept {{t1 - t0 >= (250 as i64)}}\")\n",
            "    let none: List<ptr> = List<ptr>()\n",
            "    let r2 = tcp_wait(none, 200)\n",
            "    println(f\"empty {{r2.len()}} slept {{clock_ms() - t1 >= (150 as i64)}}\")\n",
        ),
        port = port
    );
    let output = compile_and_run_ws2("net_server_idle", &src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(stdout.trim_end().replace("\r", ""), "accept null true\nwait 1 0 slept true\nempty 0 slept true");
}

/// Listening on a port another socket already holds fails with a null handle rather than aborting.
#[test]
fn runtime_listen_on_taken_port_returns_null_end_to_end() {
    let holder = std::net::TcpListener::bind("127.0.0.1:0").expect("bind scratch listener");
    let port = holder.local_addr().unwrap().port();
    let src = format!("fn main():\n    let l = tcp_listen({port}, true)\n    println(f\"null {{is_null(l)}}\")\n", port = port);
    let output = compile_and_run_ws2("net_server_taken", &src);
    drop(holder);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "null true");
}

/// `tcp_send_bytes` sends from its start offset, and an offset at or past the end sends nothing and returns 0.
#[test]
fn runtime_send_bytes_start_offset_end_to_end() {
    let port = free_port();
    let client = std::thread::spawn(move || {
        let mut s = connect_retry(port);
        let mut got = Vec::new();
        s.read_to_end(&mut got).unwrap();
        got
    });
    let src = format!(
        concat!(
            "fn main():\n",
            "    let l = tcp_listen({port}, true)\n",
            "    let hs: List<ptr> = [l]\n",
            "    let mut c = null_ptr()\n",
            "    while is_null(c):\n",
            "        let r = tcp_wait(hs, 1000)\n",
            "        c = tcp_accept(l)\n",
            "    let d = bytes_from_str(\"abcdef\")\n",
            "    let n = tcp_send_bytes(c, d, 2)\n",
            "    let z = tcp_send_bytes(c, d, 6)\n",
            "    let z2 = tcp_send_bytes(c, d, 99)\n",
            "    println(f\"{{n}} {{z}} {{z2}}\")\n",
            "    tcp_close(c)\n",
        ),
        port = port
    );
    let output = compile_and_run_ws2("net_server_offset", &src);
    let got = client.join().expect("client thread panicked");
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "4 0 0");
    assert_eq!(got, b"cdef");
}

/// `host_name()` is the machine's name as gethostname() gives it (case kept), matching %COMPUTERNAME% case-insensitively.
#[test]
fn runtime_host_name_end_to_end() {
    let output = compile_and_run_ws2("net_server_host_name", "fn main():\n    println(host_name())\n");
    assert!(output.status.success(), "{:?}", output.status);
    let got = String::from_utf8_lossy(&output.stdout).trim().to_string();
    assert!(!got.is_empty());
    if let Ok(cn) = std::env::var("COMPUTERNAME") {
        assert_eq!(got.to_uppercase(), cn.to_uppercase());
    }
}

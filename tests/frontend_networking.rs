//! Raw TCP socket builtins
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Networking (todo.md #3: raw TCP socket builtins) ====================
//
// `tcp_connect`/`tcp_send`/`tcp_recv`/`tcp_close` (`crate::codegen::net`)
// wrap Winsock2's `socket`/`connect`/`send`/`recv`/`closesocket`, mirroring
// the file-I/O builtins' conventions: `tcp_connect` returns a null `ptr` on
// failure (checked with `is_null`, same as `file_open`), `tcp_recv` returns
// `""` on a closed connection (same EOF convention as `file_read`), and a
// null/closed handle passed to `tcp_send`/`tcp_recv`/`tcp_close` aborts
// loudly instead of corrupting/crashing. Unlike the file-I/O builtins these
// need `ws2_32` linked explicitly (`compile_and_run_linked` below), and the
// runtime tests need a real listening peer -- provided by a `std::net`
// `TcpListener` spun up inside the *Rust* test itself, not by another Star
// program.

/// Like `compile_and_run`, but also passes extra `-l<name>` link flags to
/// clang -- needed because Winsock2 isn't part of this target's implicitly-
/// linked default libraries (see `Codegen::emit_builtins`'s `net.rs` doc
/// comment), so any test exercising `tcp_*` builtins must link `ws2_32`
/// explicitly, the same way a real `star build` invocation would need
/// `-l ws2_32` passed on the command line.
fn compile_and_run_linked(name: &str, src: &str, libs: &[&str]) -> std::process::Output {
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let exe = std::env::temp_dir().join(format!("star_test_{}.exe", name));
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let mut cmd_args = vec!["-O0".to_string(), ll.to_str().unwrap().to_string(), "-o".to_string(), exe.to_str().unwrap().to_string()];
    cmd_args.extend(libs.iter().map(|l| format!("-l{}", l)));
    let status = std::process::Command::new("clang").args(&cmd_args).status().expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");
    let output = std::process::Command::new(&exe).output().expect("failed to execute compiled test binary");
    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
    output
}

/// `tcp_connect` type-checks to `ptr`, the same opaque-handle convention
/// `file_open` established.
#[test]
fn checks_tcp_connect_returns_ptr() {
    let src = "fn t():\n    let h: ptr = tcp_connect(\"127.0.0.1\", 80)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("tcp_connect(..) should type-check as ptr");
}

/// `tcp_send`/`tcp_recv` type-check to `bool`/`str` respectively.
#[test]
fn checks_tcp_send_and_recv_return_types() {
    let src = "fn t():\n    let h = tcp_connect(\"127.0.0.1\", 80)\n    let ok: bool = tcp_send(h, \"data\")\n    let r: str = tcp_recv(h)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("tcp_send/tcp_recv should type-check as bool/str");
}

/// `tcp_close` type-checks with no meaningful return value, same as
/// `file_close`.
#[test]
fn checks_tcp_close_type_checks() {
    let src = "fn t():\n    let h = tcp_connect(\"127.0.0.1\", 80)\n    tcp_close(h)\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("tcp_close(..) should type-check");
}

/// A wrong argument count for `tcp_connect` is caught at type-check time
/// (`Checker::check_builtin_call_args`), not left to fail confusingly at the
/// `clang` step -- mirrors `checker_rejects_file_open_wrong_arg_count`.
#[test]
fn checker_rejects_tcp_connect_wrong_arg_count() {
    let src = "fn t():\n    tcp_connect(\"127.0.0.1\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("tcp_connect with 1 argument should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`tcp_connect` expects 2 argument(s)")), "{:?}", diags);
}

/// `tcp_connect`'s second argument must be `int` (the port), not `str` --
/// exercises the argument-type check, not just arity.
#[test]
fn checker_rejects_tcp_connect_wrong_arg_type() {
    let src = "fn t():\n    tcp_connect(\"127.0.0.1\", \"80\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("tcp_connect with a str port should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`tcp_connect` argument 2 expected `int`")), "{:?}", diags);
}

/// Same check for `tcp_send`, which also takes 2 arguments (`ptr`, `str`).
#[test]
fn checker_rejects_tcp_send_wrong_arg_count() {
    let src = "fn t():\n    let h = tcp_connect(\"127.0.0.1\", 80)\n    tcp_send(h)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("tcp_send with 1 argument should fail to type-check") };
    assert!(diags.iter().any(|d| d.message.contains("`tcp_send` expects 2 argument(s)")), "{:?}", diags);
}

/// `tcp_close` on a possibly-null handle checks for null and aborts before
/// ever calling `@closesocket` -- same shape as
/// `codegen_file_close_aborts_on_null_handle`.
#[test]
fn codegen_tcp_close_aborts_on_null_handle() {
    let src = "fn t():\n    let h = tcp_connect(\"127.0.0.1\", 80)\n    tcp_close(h)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define void @t(");
    assert!(fn_ir.contains("icmp eq i8* "), "should compare the handle against null: {}", fn_ir);
    assert!(fn_ir.contains("call void @exit(i32 1)"), "should abort on a null handle: {}", fn_ir);
    assert!(fn_ir.contains("unreachable"), "{}", fn_ir);
    assert!(fn_ir.contains("call i32 @closesocket"), "the ok path should still call closesocket: {}", fn_ir);
}

/// `tcp_connect` against a port nobody is listening on returns a null `ptr`
/// (checked via `is_null`), the same "null on failure" convention
/// `file_open` established, rather than crashing or hanging.
#[test]
fn runtime_tcp_connect_refused_returns_null_end_to_end() {
    // Bind-then-immediately-drop a listener to claim an OS-assigned port
    // that's guaranteed to have nothing listening on it by the time the
    // compiled Star program tries to connect.
    let listener = std::net::TcpListener::bind("127.0.0.1:0").expect("failed to bind scratch listener");
    let port = listener.local_addr().expect("failed to read local addr").port();
    drop(listener);

    let src = format!("fn main():\n    let h = tcp_connect(\"127.0.0.1\", {port})\n    println(f\"{{is_null(h)}}\")\n", port = port);
    let output = compile_and_run_linked("tcp_connect_refused", &src, &["ws2_32"]);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "true", "connecting to a port with no listener should yield a null handle: {}", stdout);
}

/// The basic round trip the whole feature exists for (todo.md: "needed for
/// anything client/server"): connect to a real listener, send a message,
/// and receive a reply, driven against a `std::net::TcpListener` running in
/// this Rust test process itself (not another Star program).
#[test]
fn runtime_tcp_connect_send_recv_round_trip_end_to_end() {
    use std::io::{Read, Write};

    let listener = std::net::TcpListener::bind("127.0.0.1:0").expect("failed to bind scratch listener");
    let port = listener.local_addr().expect("failed to read local addr").port();
    let server = std::thread::spawn(move || {
        let (mut conn, _) = listener.accept().expect("failed to accept connection");
        let mut buf = [0u8; 64];
        let n = conn.read(&mut buf).expect("failed to read from client");
        assert_eq!(&buf[..n], b"ping", "server should receive exactly what the client sent");
        conn.write_all(b"pong").expect("failed to write reply");
    });

    let src = format!(
        "fn main():\n    let h = tcp_connect(\"127.0.0.1\", {port})\n    let ok = tcp_send(h, \"ping\")\n    println(f\"sent:{{ok}}\")\n    let reply = tcp_recv(h)\n    println(f\"reply:{{reply}}\")\n    tcp_close(h)\n",
        port = port
    );
    let output = compile_and_run_linked("tcp_round_trip", &src, &["ws2_32"]);
    server.join().expect("server thread panicked");
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["sent:true", "reply:pong"], "{}", stdout);
}

/// `tcp_recv` on a connection the peer has closed gracefully (without
/// sending anything) returns `""`, the same EOF convention
/// `file_read`/`read_line` established, rather than blocking forever or
/// reporting an error.
#[test]
fn runtime_tcp_recv_on_peer_closed_connection_returns_empty_end_to_end() {
    let listener = std::net::TcpListener::bind("127.0.0.1:0").expect("failed to bind scratch listener");
    let port = listener.local_addr().expect("failed to read local addr").port();
    let server = std::thread::spawn(move || {
        let (conn, _) = listener.accept().expect("failed to accept connection");
        drop(conn); // close immediately, sending nothing
    });

    let src = format!(
        "fn main():\n    let h = tcp_connect(\"127.0.0.1\", {port})\n    let reply = tcp_recv(h)\n    println(f\"reply:{{reply}}\")\n    tcp_close(h)\n",
        port = port
    );
    let output = compile_and_run_linked("tcp_recv_peer_closed", &src, &["ws2_32"]);
    server.join().expect("server thread panicked");
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "reply:", "a gracefully closed peer should yield an empty recv, not hang or error: {}", stdout);
}

/// Calling `tcp_send` on a null handle (from a failed `tcp_connect`, used
/// without an `is_null(..)` check) aborts loudly with a diagnostic and a
/// nonzero exit code instead of crashing/segfaulting -- mirrors
/// `runtime_file_read_aborts_on_null_handle_end_to_end`.
#[test]
fn runtime_tcp_send_aborts_on_null_handle_end_to_end() {
    let listener = std::net::TcpListener::bind("127.0.0.1:0").expect("failed to bind scratch listener");
    let port = listener.local_addr().expect("failed to read local addr").port();
    drop(listener);

    let src = format!(
        "fn main():\n    let h = tcp_connect(\"127.0.0.1\", {port})\n    println(\"before\")\n    let ok = tcp_send(h, \"x\")\n    println(\"should not reach here\")\n",
        port = port
    );
    let output = compile_and_run_linked("tcp_send_null_handle", &src, &["ws2_32"]);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(!stdout.contains("should not reach here"), "must abort before the null handle is ever used: {}", stdout);
    assert!(stdout.contains("null/closed socket handle"), "should print a diagnostic: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "should exit cleanly with code 1, not crash/segfault: {:?}", output.status);
}

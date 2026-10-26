//! `ptr_to_bytes(p, n)` and `ptr_write_bytes(dst, b, off, n)`: binary data
//! between a C buffer and a `Bytes` (`src/codegen/ffi_bytes.rs`).
//!
//! Added for the `projects/havokos` TLS layer (todo.md HavokOS P1 #8):
//! OpenSSL over memory BIOs moves every byte through `SSL_read`/`BIO_read`
//! (which fill a caller's buffer) and `SSL_write`/`BIO_write` (which read
//! one), and nothing in Star could cross that boundary with binary data --
//! `ptr_to_str` stops at the first NUL. The last test drives exactly that:
//! a TLS 1.3 handshake between two in-memory OpenSSL sessions, every byte
//! through these two builtins and OpenSSL's uppercase `extern "C"` names
//! (HavokOS P2 #1).

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

/// A C side to read from and write to: a buffer with NULs in it, and
/// functions reporting what a buffer holds.
const HELPER: &str = "#include <string.h>\n#include <stdio.h>\n\
static unsigned char data[8] = { 'a', 0, 'b', 255, 0, 'c', 1, 'z' };\n\
static unsigned char sink[64];\n\
void *star_data(void) { return data; }\n\
void *star_sink(void) { memset(sink, '.', sizeof sink); return sink; }\n\
int star_sink_sum(int n) { int s = 0; for (int i = 0; i < n; i++) s = s * 31 + sink[i]; return s; }\n\
int star_sink_at(int i) { return sink[i]; }\n";

fn build_run(name: &str, src: &str, helper: &str, libs: &[&str]) -> std::process::Output {
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let dir = std::env::temp_dir().join(format!("star_test_ffi_bytes_{}", name));
    std::fs::create_dir_all(&dir).unwrap();
    let ll = dir.join("t.ll");
    let c = dir.join("helper.c");
    let exe = dir.join("t.exe");
    std::fs::write(&ll, &ir).unwrap();
    std::fs::write(&c, helper).unwrap();
    let mut cmd = std::process::Command::new("clang");
    cmd.args(["-O0", ll.to_str().unwrap(), c.to_str().unwrap(), "-o", exe.to_str().unwrap()]);
    for l in libs {
        cmd.arg(l);
    }
    let status = cmd.status().expect("failed to invoke clang");
    assert!(status.success(), "clang should build the IR and the helper");
    let out = std::process::Command::new(&exe).current_dir(&dir).output().expect("failed to run");
    let _ = std::fs::remove_dir_all(&dir);
    out
}

fn stdout_of(out: &std::process::Output) -> String {
    assert!(out.status.success(), "exit {:?}, stderr {}", out.status, String::from_utf8_lossy(&out.stderr));
    String::from_utf8_lossy(&out.stdout).replace("\r\n", "\n")
}

const DECLS: &str = "extern \"C\" fn star_data() -> ptr\nextern \"C\" fn star_sink() -> ptr\nextern \"C\" fn star_sink_sum(n: i32) -> i32\nextern \"C\" fn star_sink_at(i: i32) -> i32\n";

/// ptr_to_bytes copies exactly n bytes, NULs and high bytes included.
#[test]
fn runtime_ptr_to_bytes_copies_binary_data_end_to_end() {
    let out = build_run("read", &format!("{}fn main():\n    let b = ptr_to_bytes(star_data(), 8)\n    let mut s = \"\"\n    for i in 0..b.len():\n        s = f\"{{s}}{{b[i]}} \"\n    println(f\"{{b.len()}}: {{s}}\")\n    let part = ptr_to_bytes(star_data(), 3)\n    println(f\"{{part.len()}} {{part[2]}}\")\n", DECLS), HELPER, &[]);
    assert_eq!(stdout_of(&out), "8: 97 0 98 255 0 99 1 122 \n3 98\n");
}

/// A length of 0 or less gives an empty Bytes without reading the pointer.
#[test]
fn runtime_ptr_to_bytes_nonpositive_length_is_empty_end_to_end() {
    let out = build_run("empty", &format!("{}fn main():\n    let a = ptr_to_bytes(null_ptr(), 0)\n    let b = ptr_to_bytes(null_ptr(), -5)\n    println(f\"{{a.len()}} {{b.len()}}\")\n", DECLS), HELPER, &[]);
    assert_eq!(stdout_of(&out), "0 0\n");
}

/// A null pointer with something to read aborts with a message, as ptr_to_str does.
#[test]
fn runtime_ptr_to_bytes_null_pointer_aborts_end_to_end() {
    let out = build_run("nullread", &format!("{}fn main():\n    let b = ptr_to_bytes(null_ptr(), 4)\n    println(f\"{{b.len()}}\")\n", DECLS), HELPER, &[]);
    assert!(!out.status.success(), "should abort");
    assert!(String::from_utf8_lossy(&out.stdout).contains("ptr_to_bytes(..) called with a null ptr"), "{:?}", out);
}

/// ptr_write_bytes copies a slice and returns its length, NULs included.
#[test]
fn runtime_ptr_write_bytes_copies_a_slice_end_to_end() {
    let out = build_run("write", &format!("{}fn main():\n    let mut b: Bytes = Bytes()\n    b.push(5 as u8)\n    b.push(0 as u8)\n    b.push(200 as u8)\n    b.push(7 as u8)\n    let dst = star_sink()\n    let n = ptr_write_bytes(dst, b, 1, 2)\n    println(f\"{{n}} {{star_sink_at(0)}} {{star_sink_at(1)}} {{star_sink_at(2)}}\")\n", DECLS), HELPER, &[]);
    assert_eq!(stdout_of(&out), "2 0 200 46\n");
}

/// The range is clamped to the Bytes: a negative start reads from 0, a negative or too long length to the end.
#[test]
fn runtime_ptr_write_bytes_clamps_the_range_end_to_end() {
    let out = build_run("clamp", &format!("{}fn main():\n    let b = bytes_from_str(\"hello\")\n    let dst = star_sink()\n    let a = ptr_write_bytes(dst, b, -3, 2)\n    let c = ptr_write_bytes(dst, b, 2, -1)\n    let d = ptr_write_bytes(dst, b, 1, 100)\n    let e = ptr_write_bytes(dst, b, 9, 3)\n    println(f\"{{a}} {{c}} {{d}} {{e}} {{star_sink_at(0)}} {{star_sink_at(3)}} {{star_sink_at(4)}}\")\n", DECLS), HELPER, &[]);
    // the last copy (4 bytes from 1) left "ello" at 0..4; index 4 was never written
    assert_eq!(stdout_of(&out), "2 3 4 0 101 111 46\n");
}

/// Nothing to copy never touches the destination, even a null one.
#[test]
fn runtime_ptr_write_bytes_nothing_to_copy_end_to_end() {
    let out = build_run("nothing", &format!("{}fn main():\n    let e: Bytes = Bytes()\n    println(f\"{{ptr_write_bytes(null_ptr(), e, 0, 10)}} {{ptr_write_bytes(null_ptr(), bytes_from_str(\"ab\"), 0, 0)}}\")\n", DECLS), HELPER, &[]);
    assert_eq!(stdout_of(&out), "0 0\n");
}

/// A null destination with something to copy aborts with a message.
#[test]
fn runtime_ptr_write_bytes_null_destination_aborts_end_to_end() {
    let out = build_run("nullwrite", &format!("{}fn main():\n    println(f\"{{ptr_write_bytes(null_ptr(), bytes_from_str(\"ab\"), 0, 2)}}\")\n", DECLS), HELPER, &[]);
    assert!(!out.status.success(), "should abort");
    assert!(String::from_utf8_lossy(&out.stdout).contains("ptr_write_bytes(..) called with a null ptr"), "{:?}", out);
}

/// The IR is target-independent (a malloc and a memcpy); the Linux build
/// verifies and compiles to an object.
#[test]
fn codegen_ffi_bytes_linux_target_compiles() {
    let src = "fn main():\n    let b = ptr_to_bytes(null_ptr(), 0)\n    let n = ptr_write_bytes(null_ptr(), b, 0, -1)\n    println(f\"{b.len()} {n}\")\n";
    let typed = Driver::check(&Driver::parse(src).unwrap()).unwrap();
    let v = Driver::codegen_verified_for_target(&typed, star::codegen::Target::LinuxGnu).expect("should codegen");
    assert!(v.errors.is_empty(), "{:?}", v.errors.iter().map(|d| &d.message).collect::<Vec<_>>());
    let dir = std::env::temp_dir();
    let ll = dir.join("star_test_ffi_bytes_linux.ll");
    let obj = dir.join("star_test_ffi_bytes_linux.o");
    std::fs::write(&ll, &v.ir).unwrap();
    let status = std::process::Command::new("clang")
        .args(["-c", "--target=x86_64-unknown-linux-gnu", ll.to_str().unwrap(), "-o", obj.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&obj);
    assert!(status.success(), "the Linux IR should compile to an object");
}

/// Wrong argument types are type errors.
#[test]
fn ffi_bytes_argument_types_are_checked() {
    for src in [
        "fn main():\n    let b = ptr_to_bytes(\"x\", 1)\n",
        "fn main():\n    let b = ptr_to_bytes(null_ptr(), \"1\")\n",
        "fn main():\n    let n = ptr_write_bytes(null_ptr(), \"ab\", 0, 1)\n",
        "fn main():\n    let n = ptr_write_bytes(null_ptr(), bytes_from_str(\"a\"), 0)\n",
    ] {
        let module = Driver::parse(src).expect("should parse");
        assert!(Driver::check(&module).is_err(), "should be rejected: {}", src);
    }
}

/// End to end with the library they were made for: two OpenSSL sessions
/// over memory BIOs, a TLS 1.3 handshake pumped in memory, then data both
/// ways, every byte through ptr_to_bytes/ptr_write_bytes.
#[test]
fn runtime_openssl_memory_bio_handshake_end_to_end() {
    let root = std::path::Path::new(env!("CARGO_MANIFEST_DIR"));
    let lib_dir = root.join("openssl").join("lib").join("x64");
    // a throwaway certificate, made with OpenSSL itself through extern "C"
    let src = r#"extern "C" fn TLS_server_method() -> ptr
extern "C" fn TLS_client_method() -> ptr
extern "C" fn SSL_CTX_new(m: ptr) -> ptr
extern "C" fn SSL_CTX_use_certificate(ctx: ptr, x: ptr) -> i32
extern "C" fn SSL_CTX_use_PrivateKey(ctx: ptr, k: ptr) -> i32
extern "C" fn SSL_new(ctx: ptr) -> ptr
extern "C" fn BIO_s_mem() -> ptr
extern "C" fn BIO_new(m: ptr) -> ptr
extern "C" fn SSL_set_bio(s: ptr, r: ptr, w: ptr)
extern "C" fn SSL_set_accept_state(s: ptr)
extern "C" fn SSL_set_connect_state(s: ptr)
extern "C" fn SSL_do_handshake(s: ptr) -> i32
extern "C" fn SSL_read(s: ptr, buf: ptr, n: i32) -> i32
extern "C" fn SSL_write(s: ptr, buf: ptr, n: i32) -> i32
extern "C" fn BIO_read(b: ptr, buf: ptr, n: i32) -> i32
extern "C" fn BIO_write(b: ptr, buf: ptr, n: i32) -> i32
extern "C" fn SSL_is_init_finished(s: ptr) -> i32
extern "C" fn CRYPTO_malloc(n: i64, file: str, line: i32) -> ptr
extern "C" fn BN_new() -> ptr
extern "C" fn BN_set_word(bn: ptr, w: i64) -> i32
extern "C" fn RSA_new() -> ptr
extern "C" fn RSA_generate_key_ex(rsa: ptr, bits: i32, e: ptr, cb: ptr) -> i32
extern "C" fn EVP_PKEY_new() -> ptr
extern "C" fn EVP_PKEY_assign(pkey: ptr, kind: i32, key: ptr) -> i32
extern "C" fn EVP_sha256() -> ptr
extern "C" fn X509_new() -> ptr
extern "C" fn X509_set_pubkey(x: ptr, pkey: ptr) -> i32
extern "C" fn X509_getm_notBefore(x: ptr) -> ptr
extern "C" fn X509_getm_notAfter(x: ptr) -> ptr
extern "C" fn X509_gmtime_adj(t: ptr, adj: i64) -> ptr
extern "C" fn X509_sign(x: ptr, pkey: ptr, md: ptr) -> i32

fn pipe(from: ptr, to: ptr, buf: ptr) -> i32:
    let mut moved = 0
    let mut n = BIO_read(from, buf, 4096)
    while n > 0:
        let chunk = ptr_to_bytes(buf, n)
        let k = ptr_write_bytes(buf, chunk, 0, -1)
        BIO_write(to, buf, k)
        moved += k
        n = BIO_read(from, buf, 4096)
    moved

fn main():
    let buf = CRYPTO_malloc(4096 as i64, "t", 0)
    let e = BN_new()
    BN_set_word(e, 65537 as i64)
    let rsa = RSA_new()
    RSA_generate_key_ex(rsa, 2048, e, null_ptr())
    let key = EVP_PKEY_new()
    EVP_PKEY_assign(key, 6, rsa)
    let x = X509_new()
    X509_gmtime_adj(X509_getm_notBefore(x), 0 as i64)
    X509_gmtime_adj(X509_getm_notAfter(x), 3600 as i64)
    X509_set_pubkey(x, key)
    X509_sign(x, key, EVP_sha256())
    let sctx = SSL_CTX_new(TLS_server_method())
    println(f"{SSL_CTX_use_certificate(sctx, x)} {SSL_CTX_use_PrivateKey(sctx, key)}")
    let s = SSL_new(sctx)
    let sr = BIO_new(BIO_s_mem())
    let sw = BIO_new(BIO_s_mem())
    SSL_set_bio(s, sr, sw)
    SSL_set_accept_state(s)
    let c = SSL_new(SSL_CTX_new(TLS_client_method()))
    let cr = BIO_new(BIO_s_mem())
    let cw = BIO_new(BIO_s_mem())
    SSL_set_bio(c, cr, cw)
    SSL_set_connect_state(c)
    for round in 0..8:
        SSL_do_handshake(c)
        pipe(cw, sr, buf)
        SSL_do_handshake(s)
        pipe(sw, cr, buf)
    println(f"{SSL_is_init_finished(s)} {SSL_is_init_finished(c)}")
    let mut msg = bytes_from_str("binary")
    msg.push(1 as u8)
    msg.push(111 as u8)
    msg.push(107 as u8)
    SSL_write(c, buf, ptr_write_bytes(buf, msg, 0, -1))
    pipe(cw, sr, buf)
    let n = SSL_read(s, buf, 4096)
    let got = ptr_to_bytes(buf, n)
    println(f"{n} {got[6]} {str_from_bytes(got)}")
"#;
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let dir = std::env::temp_dir().join("star_test_ffi_bytes_openssl");
    std::fs::create_dir_all(&dir).unwrap();
    let ll = dir.join("t.ll");
    let exe = dir.join("t.exe");
    std::fs::write(&ll, &ir).unwrap();
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .arg(format!("-L{}", lib_dir.display()))
        .args(["-lssl", "-lcrypto"])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should link against OpenSSL");
    for dll in ["libssl-3-x64.dll", "libcrypto-3-x64.dll"] {
        std::fs::copy(lib_dir.join(dll), dir.join(dll)).expect("stage the OpenSSL DLLs");
    }
    let out = std::process::Command::new(&exe).current_dir(&dir).output().expect("failed to run");
    let _ = std::fs::remove_dir_all(&dir);
    assert_eq!(stdout_of(&out), "1 1\n1 1\n9 1 binary\x01ok\n");
}

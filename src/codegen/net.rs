//! Raw TCP socket builtins (`tcp_connect`/`tcp_send`/`tcp_recv`/`tcp_close`),
//! the "floor" networking layer from `todo.md`'s #3 "Networking basics" --
//! thin wrappers over the Winsock2 C ABI (`socket`/`connect`/`send`/`recv`/
//! `closesocket`), the same "hand-emit calls to an existing C API" shape
//! `file_io.rs` already established for `fopen`/`fread`/`fwrite`. HTTP/DNS
//! are deliberately out of scope here (todo.md: "Defer HTTP parsing to a
//! library ... rather than building it into the compiler") -- `tcp_connect`
//! only accepts a dotted-decimal IPv4 address via `inet_addr`, not a
//! hostname; resolving hostnames would need `getaddrinfo`, a much larger
//! surface than this floor warrants.
//!
//! Error model: mirrors `file_open`'s "null `ptr` on failure" convention
//! (see `file_io.rs`'s module doc comment) rather than introducing a new
//! sentinel -- `tcp_connect` returns null `ptr` if *either* `socket()` or
//! `connect()` fails, checked with the existing `is_null` builtin. A
//! `SOCKET` (Winsock's `UINT_PTR` handle type) is the same pointer-sized
//! opaque-handle shape as a C `FILE*`, so it reuses `Ty::Ptr` the same way
//! file handles do. `tcp_send` returns `bool` (all bytes written or not,
//! matching `file_write`); `tcp_recv` returns an empty `str` on a graceful
//! close *or* a socket error alike, matching `file_read`/`read_line`'s
//! established EOF convention. Calling `tcp_send`/`tcp_recv`/`tcp_close`
//! with a null/closed handle aborts loudly (`abort_if_null_socket`), same
//! philosophy as `file_io.rs`'s `abort_if_null_handle`.
//!
//! Linking note: unlike `fopen`/`getenv`/`CreateThread` (resolved from
//! libraries already linked by default on this target), Winsock2 symbols
//! live in `ws2_32.dll` -- a Star program calling any of these builtins
//! must be built with `-l ws2_32` (`star build foo.star -l ws2_32`), the
//! same way binding an external library through `extern "C"` FFI needs an
//! explicit `--lib`/`-l`.
//!
//! ## `Target::LinuxGnu`: seamed, devbox-link-verified
//! Unlike `crate::codegen::system_font`'s GDI calls, this module has no
//! fundamental portability problem -- BSD sockets are Winsock's own
//! ancestor API, so `socket`/`connect`/`send`/`recv` already share Winsock's
//! names and signatures on Linux almost exactly. No `WSAStartup`/
//! `WSACleanup` equivalent is needed on POSIX (`emit_tcp_connect` skips that
//! call entirely under `Target::LinuxGnu`), `close` replaces `closesocket`,
//! and real `send`/`recv` take a 64-bit `size_t` length and return a 64-bit
//! `ssize_t` on x86-64 glibc rather than Winsock's `int`/`int` -- widened
//! with `sext`/`trunc` around the existing `i32` length/result this module's
//! callers already expect.
//!
//! The one real representation change: a POSIX socket is a plain `i32` fd,
//! not a pointer. Rather than giving socket handles a second `Ty` per
//! target (Star's `ptr` type has to stay `Ty::Ptr`/`i8*` either way -- every
//! call site here uses `untag(.., &Ty::Ptr)`), `socket_handle_to_fd`/the
//! `Target::LinuxGnu` arm of `sock` production in `emit_tcp_connect` pack
//! the fd into an `i8*`-shaped register with `sext`/`inttoptr` and unpack it
//! back with `ptrtoint`/`trunc` immediately before each real POSIX call.
//! That packing is why the existing `INVALID_SOCKET` check
//! (`icmp eq i8* sock, inttoptr (i64 -1 to i8*)`) and `abort_if_null_socket`
//! (`icmp eq i8* handle, null`) need no `Target` branch at all: `sext`ing a
//! `-1` fd to `i64` and `inttoptr`ing it produces the exact same bit pattern
//! Windows' own `INVALID_SOCKET` check already compares against, and
//! `tcp_connect`'s phi node collapses every failure path to a literal `i8*
//! null` on both targets, so a "no handle" socket is always genuinely null,
//! never a live-looking `-1`-tagged pointer.
//!
//! Link-verified against a real Debian devbox (`clang`/`ld`/glibc headers,
//! no cross-linking from this Windows-hosted toolchain -- `star emit llvm
//! --target=linux` produces the `.ll`, which is shipped to the devbox and
//! linked there) rather than eyeballed IR; see
//! `docs/cross_platform_scope.md`'s "Already seamed" section.

use crate::diagnostics::Span;
use crate::types::*;

use super::{Codegen, Target};

impl Codegen {
    /// `declare` every C symbol this module's `emit_*` methods call, for
    /// whichever `Target` this `Codegen` was constructed with -- called once
    /// from `emit_builtins`, unconditionally, mirroring
    /// `crate::codegen::platform::declare_platform_threading_externs`'s own
    /// reasoning (an unreferenced `declare` costs nothing at link time, so
    /// there's no reason to gate this on whether a program actually calls
    /// `tcp_*`). `htons`/`inet_addr` are POSIX-standard with identical
    /// signatures on both targets, so they're declared once, unconditionally,
    /// rather than duplicated in both match arms.
    pub(super) fn declare_net_externs(&mut self) {
        match self.target {
            Target::WindowsGnu => {
                self.line("declare i32 @WSAStartup(i16, i8*)");
                self.line("declare i8* @socket(i32, i32, i32)");
                self.line("declare i32 @connect(i8*, i8*, i32)");
                self.line("declare i32 @send(i8*, i8*, i32, i32)");
                self.line("declare i32 @recv(i8*, i8*, i32, i32)");
                self.line("declare i32 @closesocket(i8*)");
            }
            Target::LinuxGnu => {
                self.line("declare i32 @socket(i32, i32, i32)");
                self.line("declare i32 @connect(i32, i8*, i32)");
                // `size_t`/`ssize_t` are 64-bit on x86-64 glibc, unlike
                // Winsock's `int`-width `send`/`recv` -- see this module's
                // own doc comment.
                self.line("declare i64 @send(i32, i8*, i64, i32)");
                self.line("declare i64 @recv(i32, i8*, i64, i32)");
                self.line("declare i32 @close(i32)");
            }
        }
        self.line("declare i16 @htons(i16)");
        self.line("declare i32 @inet_addr(i8*)");
    }

    /// `closesocket(handle)` (Windows) or `close(fd)` (Linux, unpacked from
    /// `handle`'s stashed bit pattern via `socket_handle_to_fd`) -- shared by
    /// `emit_tcp_connect`'s own cleanup paths and `emit_tcp_close`, so the
    /// fd-packing scheme only needs writing once.
    fn emit_close_socket(&mut self, handle: &str) {
        match self.target {
            Target::WindowsGnu => {
                self.line(&format!("  call i32 @closesocket(i8* {})", handle));
            }
            Target::LinuxGnu => {
                let fd = self.socket_handle_to_fd(handle);
                self.line(&format!("  call i32 @close(i32 {})", fd));
            }
        }
    }

    /// Unpack the `i32` fd `emit_tcp_connect`'s `Target::LinuxGnu` arm
    /// packed into `handle` (an `i8*`-shaped Star `ptr` value) via
    /// `ptrtoint`/`trunc` -- the inverse of that packing step. Linux-only;
    /// every call site is itself inside a `Target::LinuxGnu` match arm.
    fn socket_handle_to_fd(&mut self, handle: &str) -> String {
        let as_i64 = self.tmp_name();
        self.line(&format!("  {} = ptrtoint i8* {} to i64", as_i64, handle));
        let fd = self.tmp_name();
        self.line(&format!("  {} = trunc i64 {} to i32", fd, as_i64));
        fd
    }
    /// Abort (matches `file_io.rs`'s `abort_if_null_handle` shape exactly,
    /// with socket-specific wording) if `handle` is a null `ptr`. Used by
    /// every builtin here except `tcp_connect`, which has no handle to
    /// misuse yet.
    fn abort_if_null_socket(&mut self, handle: &str, builtin_name: &str) {
        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, handle));
        let fail_label = self.block_label("tcp_null_handle");
        let ok_label = self.block_label("tcp_handle_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, fail_label, ok_label));

        self.open_block(&fail_label);
        let msg = format!("star runtime error: {}(..) called with a null/closed socket handle\n", builtin_name);
        let g = self.global_name();
        let escaped = msg.replace("\\", "\\\\").replace("\"", "\\22").replace("\n", "\\0A");
        self.global_defs.push(format!("{} = private unnamed_addr constant [{} x i8] c\"{}\\00\"", g, msg.len() + 1, escaped));
        let msg_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [{} x i8], [{} x i8]* {}, i64 0, i64 0", msg_ptr, msg.len() + 1, msg.len() + 1, g));
        self.line(&format!("  call i32 @puts(i8* {})", msg_ptr));
        self.line("  call void @exit(i32 1)");
        self.line("  unreachable");

        self.open_block(&ok_label);
    }

    /// `tcp_connect(host: str, port: int) -> ptr`: `WSAStartup` (called on
    /// every connect since Winsock reference-counts init/cleanup internally
    /// and this codegen never calls `WSACleanup` -- the OS tears sockets
    /// down at process exit -- so a redundant call here is cheap and keeps
    /// this builtin self-contained rather than depending on some other
    /// builtin having run first), then `socket(AF_INET, SOCK_STREAM,
    /// IPPROTO_TCP)` and `connect` against a hand-built 16-byte
    /// `sockaddr_in` (`{ i16 family, i16 port (network byte order), i32
    /// addr, [8 x i8] zero }`). Null `ptr` if either call fails -- same
    /// convention as `file_open`, checked with `is_null`.
    pub(super) fn emit_tcp_connect(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("tcp_connect(..) expects 2 arguments (host, port)", Span::dummy());
            return "i8* null".into();
        }

        // WSAStartup(MAKEWORD(2, 2), &wsaData) -- `wsaData` is discarded
        // (nothing here reads a `WSADATA` field), so a generously oversized
        // scratch buffer sidesteps needing to hand-lay-out the struct's
        // real (platform-dependent) size exactly. POSIX sockets need no
        // per-process init at all, so `Target::LinuxGnu` skips this whole
        // block.
        if self.target == Target::WindowsGnu {
            let wsa_buf = self.tmp_name();
            self.line(&format!("  {} = alloca [512 x i8]", wsa_buf));
            let wsa_ptr = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds [512 x i8], [512 x i8]* {}, i64 0, i64 0", wsa_ptr, wsa_buf));
            self.line(&format!("  call i32 @WSAStartup(i16 514, i8* {})", wsa_ptr));
        }

        // AF_INET, SOCK_STREAM, IPPROTO_TCP. Windows' `socket` already
        // returns the pointer-shaped `SOCKET` handle this module treats as
        // its uniform `i8*` "handle" everywhere; Linux's real `socket`
        // returns a plain `i32` fd, packed into the same `i8*` shape via
        // `sext`/`inttoptr` -- see this module's own doc comment for why
        // that keeps the `INVALID_SOCKET` check just below `Target`-agnostic.
        let sock = match self.target {
            Target::WindowsGnu => {
                let sock = self.tmp_name();
                self.line(&format!("  {} = call i8* @socket(i32 2, i32 1, i32 6)", sock));
                sock
            }
            Target::LinuxGnu => {
                let fd = self.tmp_name();
                self.line(&format!("  {} = call i32 @socket(i32 2, i32 1, i32 6)", fd));
                let fd64 = self.tmp_name();
                self.line(&format!("  {} = sext i32 {} to i64", fd64, fd));
                let sock = self.tmp_name();
                self.line(&format!("  {} = inttoptr i64 {} to i8*", sock, fd64));
                sock
            }
        };

        let is_invalid = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, inttoptr (i64 -1 to i8*)", is_invalid, sock)); // INVALID_SOCKET
        let sock_fail = self.block_label("tcp_socket_fail");
        let sock_ok = self.block_label("tcp_socket_ok");
        let end_label = self.block_label("tcp_connect_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_invalid, sock_fail, sock_ok));

        self.open_block(&sock_fail);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&sock_ok);
        let host = self.emit_raw_str_ptr(&args[0]);
        let port_v = self.emit_expr(&args[1]);
        let port = self.untag(&port_v, &Ty::Int);
        let port16 = self.tmp_name();
        self.line(&format!("  {} = trunc i32 {} to i16", port16, port));
        let port_be = self.tmp_name();
        self.line(&format!("  {} = call i16 @htons(i16 {})", port_be, port16));
        let addr = self.tmp_name();
        self.line(&format!("  {} = call i32 @inet_addr(i8* {})", addr, host));
        // `host` is done being read -- release whatever `emit_raw_str_ptr`
        // left us owning (see its own doc comment).
        self.line(&format!("  call void @star_rc_release(i8* {})", host));

        // `inet_addr` returns `INADDR_NONE` (`0xFFFFFFFF`, i.e. `-1` as a
        // signed `i32`) for a malformed address string -- indistinguishable
        // bit-for-bit from the legitimate broadcast address
        // `255.255.255.255`, but a real dotted-decimal host never resolves
        // to `-1` for a normal `connect()` target, and letting it through
        // unchecked would otherwise attempt a `connect()` using garbage
        // address bytes instead of failing cleanly and closing the socket
        // right away.
        let addr_invalid = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, -1", addr_invalid, addr));
        let addr_bad = self.block_label("tcp_addr_invalid");
        let addr_good = self.block_label("tcp_addr_valid");
        self.line(&format!("  br i1 {}, label %{}, label %{}", addr_invalid, addr_bad, addr_good));

        self.open_block(&addr_bad);
        self.emit_close_socket(&sock);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&addr_good);
        let sa_buf = self.tmp_name();
        self.line(&format!("  {} = alloca [16 x i8]", sa_buf));
        let sa_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [16 x i8], [16 x i8]* {}, i64 0, i64 0", sa_ptr, sa_buf));

        let family_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i16*", family_ptr, sa_ptr));
        self.line(&format!("  store i16 2, i16* {}", family_ptr)); // AF_INET

        let port_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 2", port_gep, sa_ptr));
        let port_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i16*", port_ptr, port_gep));
        self.line(&format!("  store i16 {}, i16* {}", port_be, port_ptr));

        let addr_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 4", addr_gep, sa_ptr));
        let addr_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", addr_ptr, addr_gep));
        self.line(&format!("  store i32 {}, i32* {}", addr, addr_ptr));

        let zero_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 8", zero_gep, sa_ptr));
        let zero_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i64*", zero_ptr, zero_gep));
        self.line(&format!("  store i64 0, i64* {}", zero_ptr));

        let conn = self.tmp_name();
        match self.target {
            Target::WindowsGnu => {
                self.line(&format!("  {} = call i32 @connect(i8* {}, i8* {}, i32 16)", conn, sock, sa_ptr));
            }
            Target::LinuxGnu => {
                let fd = self.socket_handle_to_fd(&sock);
                self.line(&format!("  {} = call i32 @connect(i32 {}, i8* {}, i32 16)", conn, fd, sa_ptr));
            }
        }
        let conn_failed = self.tmp_name();
        self.line(&format!("  {} = icmp ne i32 {}, 0", conn_failed, conn));
        let connect_fail = self.block_label("tcp_connect_fail");
        let connect_ok = self.block_label("tcp_connect_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", conn_failed, connect_fail, connect_ok));

        self.open_block(&connect_fail);
        self.emit_close_socket(&sock);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&connect_ok);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let result = self.tmp_name();
        self.line(&format!(
            "  {} = phi i8* [ null, %{} ], [ null, %{} ], [ null, %{} ], [ {}, %{} ]",
            result, sock_fail, addr_bad, connect_fail, sock, connect_ok
        ));
        format!("i8* {}", result)
    }

    /// `tcp_send(handle: ptr, data: str) -> bool`: `send`s `data`'s raw
    /// bytes verbatim (no framing/length-prefix added); returns whether
    /// every byte was actually accepted by the socket in one call --
    /// mirrors `file_write`'s "short write is a real runtime condition, not
    /// a programmer error" bool sentinel.
    pub(super) fn emit_tcp_send(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("tcp_send(..) expects 2 arguments (handle, data)", Span::dummy());
            return "i1 false".into();
        }
        let hval = self.emit_expr(&args[0]);
        let handle = self.untag(&hval, &Ty::Ptr);
        self.abort_if_null_socket(&handle, "tcp_send");
        let data = self.emit_raw_str_ptr(&args[1]);
        let len = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", len, data));
        let n = match self.target {
            Target::WindowsGnu => {
                let n = self.tmp_name();
                self.line(&format!("  {} = call i32 @send(i8* {}, i8* {}, i32 {}, i32 0)", n, handle, data, len));
                n
            }
            Target::LinuxGnu => {
                let fd = self.socket_handle_to_fd(&handle);
                let len64 = self.tmp_name();
                self.line(&format!("  {} = sext i32 {} to i64", len64, len));
                let n64 = self.tmp_name();
                self.line(&format!("  {} = call i64 @send(i32 {}, i8* {}, i64 {}, i32 0)", n64, fd, data, len64));
                let n32 = self.tmp_name();
                self.line(&format!("  {} = trunc i64 {} to i32", n32, n64));
                n32
            }
        };
        // `data` is done being read -- release whatever `emit_raw_str_ptr`
        // left us owning (see its own doc comment).
        self.line(&format!("  call void @star_rc_release(i8* {})", data));
        let ok = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, {}", ok, n, len));
        format!("i1 {}", ok)
    }

    /// `tcp_recv(handle: ptr) -> str`: a single `recv` call into a
    /// fixed 4095-byte buffer (the raw floor -- no read-until-length
    /// looping), returning exactly the bytes received as a fresh, owned
    /// `str`. A graceful close (`recv` returning `0`) and a socket error
    /// (a negative return) both normalize to `""`, matching
    /// `file_read`/`read_line`'s established EOF convention rather than
    /// introducing a distinct error signal.
    pub(super) fn emit_tcp_recv(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("tcp_recv(..) expects 1 argument", Span::dummy());
            return "i8* null".into();
        };
        let val = self.emit_expr(arg);
        let handle = self.untag(&val, &Ty::Ptr);
        self.abort_if_null_socket(&handle, "tcp_recv");

        const CAP: u64 = 4096;
        let buf = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 {}, i8* null)", buf, CAP));
        let n = match self.target {
            Target::WindowsGnu => {
                let n = self.tmp_name();
                self.line(&format!("  {} = call i32 @recv(i8* {}, i8* {}, i32 {}, i32 0)", n, handle, buf, CAP - 1));
                n
            }
            Target::LinuxGnu => {
                let fd = self.socket_handle_to_fd(&handle);
                let n64 = self.tmp_name();
                self.line(&format!("  {} = call i64 @recv(i32 {}, i8* {}, i64 {}, i32 0)", n64, fd, buf, CAP - 1));
                let n32 = self.tmp_name();
                self.line(&format!("  {} = trunc i64 {} to i32", n32, n64));
                n32
            }
        };

        let is_pos = self.tmp_name();
        self.line(&format!("  {} = icmp sgt i32 {}, 0", is_pos, n));
        let n64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", n64, n));
        let safe_n = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i64 {}, i64 0", safe_n, is_pos, n64));
        let nul_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", nul_ptr, buf, safe_n));
        self.line(&format!("  store i8 0, i8* {}", nul_ptr));
        buf
    }

    /// `tcp_close(handle: ptr)`: `closesocket`/`close`, no return value.
    pub(super) fn emit_tcp_close(&mut self, args: &[TypedExpr]) {
        let Some(arg) = args.first() else {
            self.err("tcp_close(..) expects 1 argument", Span::dummy());
            return;
        };
        let val = self.emit_expr(arg);
        let handle = self.untag(&val, &Ty::Ptr);
        self.abort_if_null_socket(&handle, "tcp_close");
        self.emit_close_socket(&handle);
        // Null out the caller's own variable, if `arg` is a bare one --
        // same fix, same rationale, as `file_io.rs`'s `emit_file_close`
        // (see its doc comment): `closesocket` doesn't invalidate the
        // handle *value* itself, which a later, unrelated `tcp_connect`
        // may reuse for a different socket.
        if let TypedExpr::Ident { .. } = arg {
            let place = self.emit_place(arg);
            self.line(&format!("  store i8* null, i8** {}", place));
        }
    }
}

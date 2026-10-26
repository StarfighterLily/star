//! Server-side TCP builtins: `tcp_listen`, `tcp_accept`, `tcp_wait`,
//! `tcp_recv_bytes`, `tcp_send_bytes`, `tcp_peer_ip`, `tcp_local_port`.
//!
//! Why: the LPMUD driver in `projects/havokos` (`todo.md` HavokOS M6) has
//! to accept telnet connections, and `crate::codegen::net` only had the
//! client half (`tcp_connect`/`tcp_send`/`tcp_recv`). An `extern "C"`
//! binding can't fill the gap: `bind` needs a `sockaddr_in` built in
//! memory, `getpeername` answers through one, and Star's FFI can neither
//! lay out nor read a C struct (`projects/havokos/NOTES.md` constraints #8
//! and #9). So these are thin wrappers emitted by the compiler, the same
//! shape as `net.rs`, sharing its handle representation (a `ptr` holding
//! the Winsock `SOCKET`, or a POSIX fd packed with `inttoptr`) and its
//! helpers.
//!
//! ## Why `tcp_wait`, and why recv/send take and give `Bytes`
//! Telnet is binary: option negotiation carries arbitrary bytes, NUL among
//! them (a NAWS report of an 80-column window is `0 80 0 24`, and a client
//! may end a line with CR NUL). `tcp_recv`/`tcp_send` move a NUL-terminated
//! `str`, which truncates at the first zero byte, so the server pair moves
//! `Bytes` instead.
//!
//! That rules out `tcp_recv`'s "null `str` means would-block" signal: an
//! empty `Bytes` *is* a null object pointer in this compiler
//! (`crate::codegen::list::emit_list_new`), so "nothing yet" and "peer
//! closed" would both come back as the same empty value. An `Option<Bytes>`
//! return was considered, but a builtin's return type has no hook into the
//! checker's generic-enum instantiation. Instead readiness comes from
//! `tcp_wait(handles, timeout_ms) -> Bytes`, one `poll()`/`WSAPoll()` over
//! every handle, which reports per handle 1 (readable: data, end of
//! stream, or for a listener a pending connection), 2 (error or hang-up),
//! 3 (both) or 0. A `tcp_recv_bytes` on a handle reported nonzero returns
//! empty only when the peer has closed. That doubles as the driver's idle
//! wait, so a MUD sleeps in the kernel until input arrives or its next
//! timer is due instead of waking every few milliseconds to poll.
//! `tcp_wait` with no handles just sleeps (`Sleep` on Windows, `poll` with
//! no descriptors on Linux).
//!
//! `tcp_send_bytes(handle, data, start) -> int` sends `data[start..]` and
//! returns how many bytes the kernel took (a non-blocking socket can take
//! fewer than offered), 0 if it would block, -1 on a broken connection, so
//! a caller keeps the unsent tail and retries on its next pass. On Linux it
//! passes `MSG_NOSIGNAL`: writing to a connection the peer reset otherwise
//! raises `SIGPIPE`, which would kill the whole server for one dropped
//! player.
//!
//! The integer argument of `tcp_wait`/`tcp_send_bytes` is evaluated before
//! the `List`/`Bytes` argument's fields are read, so the borrowed data
//! pointer is used immediately after it is taken (the same stale-snapshot
//! rule `crate::codegen::map` follows).
//!
//! ## The listener
//! `tcp_listen(port, loopback_only) -> ptr`: `socket`, `bind` to
//! `INADDR_ANY` (or 127.0.0.1 when `loopback_only`; a test binds port 0 on
//! loopback and reads the port back with `tcp_local_port`), `listen`, and
//! non-blocking mode. Null on any failure, like `tcp_connect`. On Linux it
//! sets `SO_REUSEADDR` first, so a restarted driver can bind its port while
//! the previous run's connections sit in `TIME_WAIT`; on Windows that
//! option means something else (letting another process steal a bound
//! port), and Windows doesn't refuse the rebind in the first place, so it
//! isn't set there.
//!
//! `tcp_accept(listener) -> ptr` returns the next pending connection, or
//! null when there is none. The accepted socket is put in non-blocking mode
//! explicitly on both targets: Winsock copies the mode from the listener,
//! Linux doesn't, and a server must never block on one client.
//!
//! `tcp_peer_ip(handle) -> str` is the peer's dotted-decimal address
//! (`getpeername` + `inet_ntoa`), "" on failure; `tcp_local_port(handle) ->
//! int` is the bound port (`getsockname`), -1 on failure.
//!
//! `host_name() -> str` is the machine's host name (`gethostname`; LPC's
//! `query_host_name()`), "" on failure. It lives here because on Windows
//! it's a Winsock call that fails until `WSAStartup` has run, which this
//! builtin does first, and Star code can't bind it itself: a buffer
//! out-parameter, and `GetComputerNameExA` is a capitalized name an
//! `extern "C"` can't declare (`todo.md` HavokOS P2 #1). `COMPUTERNAME`
//! from the environment isn't a substitute: it's upper-cased.
//!
//! ## Declared on first use
//! Unlike `net.rs`'s externs these are `declare`d only by programs that
//! call one of these builtins (`declare_lazy`, into `global_defs`). Star
//! functions keep their own names in the IR (`fn bind(..)` is `@bind`), and
//! `bind`/`listen`/`accept`/`poll` are ordinary function names: the test
//! suite already has a `fn bind`, which an unconditional `declare i32
//! @bind(..)` would collide with. A program that both defines such a
//! function and uses these builtins still collides; renaming its function
//! is the fix.
//!
//! ## `Target::LinuxGnu`: seamed, not yet devbox-verified
//! The Linux arm emits glibc's x86-64 shapes (`int` fds, `pollfd` of 8
//! bytes, `POLLIN` 1, `MSG_NOSIGNAL` 0x4000, `SOL_SOCKET` 1, `SO_REUSEADDR`
//! 2) and is checked by the IR verifier and by compiling to an object for
//! `x86_64-unknown-linux-gnu`, but hasn't been linked and run there, like
//! `crate::codegen::fs` and `crate::codegen::clock`. See
//! `docs/cross_platform_scope.md`.

use crate::diagnostics::Span;
use crate::types::*;

use super::{Codegen, Target};

/// `recv` buffer size for one `tcp_recv_bytes` call: a telnet client sends
/// a line or a negotiation burst at a time, and anything beyond this stays
/// in the kernel and is reported ready again by the next `tcp_wait`.
const RECV_CHUNK: u64 = 16384;

impl Codegen {
    /// `declare` a C symbol the first time a builtin here needs it -- see
    /// the module doc comment's "Declared on first use".
    pub(super) fn declare_lazy(&mut self, decl: &str) {
        if !self.global_defs.iter().any(|g| g == decl) {
            self.global_defs.push(decl.to_string());
        }
    }

    /// The real call argument for a socket handle: the `SOCKET` itself on
    /// Windows, the unpacked fd on Linux (see `net.rs`'s doc comment).
    pub(super) fn sock_arg(&mut self, handle: &str) -> String {
        match self.target {
            Target::WindowsGnu => format!("i8* {}", handle),
            Target::LinuxGnu => {
                let fd = self.socket_handle_to_fd(handle);
                format!("i32 {}", fd)
            }
        }
    }

    /// `ioctlsocket(FIONBIO)` / `fcntl(F_SETFL, flags | O_NONBLOCK)` on a
    /// fresh socket; the result is ignored (a socket that stays blocking
    /// is still usable, just not ideal).
    pub(super) fn emit_make_nonblocking(&mut self, handle: &str) {
        match self.target {
            Target::WindowsGnu => {
                const FIONBIO: i32 = 0x8004667Eu32 as i32;
                let mode = self.tmp_name();
                self.line(&format!("  {} = alloca i32", mode));
                self.line(&format!("  store i32 1, i32* {}", mode));
                self.line(&format!("  call i32 @ioctlsocket(i8* {}, i32 {}, i32* {})", handle, FIONBIO, mode));
            }
            Target::LinuxGnu => {
                let fd = self.socket_handle_to_fd(handle);
                let flags = self.tmp_name();
                self.line(&format!("  {} = call i32 @fcntl(i32 {}, i32 3, i32 0)", flags, fd));
                let nb = self.tmp_name();
                self.line(&format!("  {} = or i32 {}, {}", nb, flags, 0o4000));
                self.line(&format!("  call i32 @fcntl(i32 {}, i32 4, i32 {})", fd, nb));
            }
        }
    }

    /// Whether the last socket call failed only because it would block
    /// (`WSAEWOULDBLOCK` / `EAGAIN`).
    pub(super) fn emit_last_error_would_block(&mut self) -> String {
        match self.target {
            Target::WindowsGnu => {
                let err = self.tmp_name();
                self.line(&format!("  {} = call i32 @WSAGetLastError()", err));
                let wb = self.tmp_name();
                self.line(&format!("  {} = icmp eq i32 {}, 10035", wb, err));
                wb
            }
            Target::LinuxGnu => {
                let p = self.tmp_name();
                self.line(&format!("  {} = call i32* @__errno_location()", p));
                let err = self.tmp_name();
                self.line(&format!("  {} = load i32, i32* {}", err, p));
                let wb = self.tmp_name();
                self.line(&format!("  {} = icmp eq i32 {}, 11", wb, err));
                wb
            }
        }
    }

    /// A fresh, owned empty `str` (an RC buffer holding just the NUL).
    pub(super) fn emit_empty_owned_str(&mut self) -> String {
        let s = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 1, i8* null)", s));
        self.line(&format!("  store i8 0, i8* {}", s));
        s
    }

    /// A 16-byte `sockaddr_in` scratch buffer, zeroed, returned as `i8*`.
    pub(super) fn emit_sockaddr_buf(&mut self) -> String {
        let sa = self.tmp_name();
        self.line(&format!("  {} = alloca [16 x i8], align 8", sa));
        let p = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [16 x i8], [16 x i8]* {}, i64 0, i64 0", p, sa));
        let w0 = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i64*", w0, p));
        self.line(&format!("  store i64 0, i64* {}", w0));
        let g1 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 8", g1, p));
        let w1 = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i64*", w1, g1));
        self.line(&format!("  store i64 0, i64* {}", w1));
        p
    }

    /// `tcp_listen(port: int, loopback_only: bool) -> ptr`; see the module
    /// doc comment.
    pub(super) fn emit_tcp_listen(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("tcp_listen(..) expects 2 arguments (port, loopback_only)", Span::dummy());
            return "i8* null".into();
        }
        let pv = self.emit_expr(&args[0]);
        let port = self.untag(&pv, &Ty::Int);
        let lv = self.emit_expr(&args[1]);
        let loopback = self.untag(&lv, &Ty::Bool);
        // 127.0.0.1 in network byte order, read as a little-endian i32
        let addr = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i32 16777343, i32 0", addr, loopback));
        self.emit_listen_on(&port, &addr)
    }

    /// The body of `tcp_listen`, shared with `crate::codegen::net_sock`'s
    /// `tcp_listen_at`: listen on `port` (an `i32`) at `addr` (an `i32`
    /// IPv4 address in network byte order, 0 for any).
    pub(super) fn emit_listen_on(&mut self, port: &str, addr: &str) -> String {
        match self.target {
            Target::WindowsGnu => {
                self.declare_lazy("declare i32 @bind(i8*, i8*, i32)");
                self.declare_lazy("declare i32 @listen(i8*, i32)");
                let wsa = self.tmp_name();
                self.line(&format!("  {} = alloca [512 x i8]", wsa));
                let wp = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds [512 x i8], [512 x i8]* {}, i64 0, i64 0", wp, wsa));
                self.line(&format!("  call i32 @WSAStartup(i16 514, i8* {})", wp));
            }
            Target::LinuxGnu => {
                self.declare_lazy("declare i32 @bind(i32, i8*, i32)");
                self.declare_lazy("declare i32 @listen(i32, i32)");
                self.declare_lazy("declare i32 @setsockopt(i32, i32, i32, i8*, i32)");
            }
        }
        let sock = match self.target {
            Target::WindowsGnu => {
                let s = self.tmp_name();
                self.line(&format!("  {} = call i8* @socket(i32 2, i32 1, i32 6)", s));
                s
            }
            Target::LinuxGnu => {
                let fd = self.tmp_name();
                self.line(&format!("  {} = call i32 @socket(i32 2, i32 1, i32 6)", fd));
                let fd64 = self.tmp_name();
                self.line(&format!("  {} = sext i32 {} to i64", fd64, fd));
                let s = self.tmp_name();
                self.line(&format!("  {} = inttoptr i64 {} to i8*", s, fd64));
                s
            }
        };
        let end = self.block_label("tcp_listen_end");
        let sock_fail = self.block_label("tcp_listen_nosock");
        let sock_ok = self.block_label("tcp_listen_sock");
        let bad = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, inttoptr (i64 -1 to i8*)", bad, sock));
        self.line(&format!("  br i1 {}, label %{}, label %{}", bad, sock_fail, sock_ok));
        self.open_block(&sock_fail);
        self.line(&format!("  br label %{}", end));

        self.open_block(&sock_ok);
        if self.target == Target::LinuxGnu {
            let one = self.tmp_name();
            self.line(&format!("  {} = alloca i32", one));
            self.line(&format!("  store i32 1, i32* {}", one));
            let onep = self.tmp_name();
            self.line(&format!("  {} = bitcast i32* {} to i8*", onep, one));
            let fd = self.socket_handle_to_fd(&sock);
            self.line(&format!("  call i32 @setsockopt(i32 {}, i32 1, i32 2, i8* {}, i32 4)", fd, onep));
        }
        let sa = self.emit_sockaddr_buf();
        let fam = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i16*", fam, sa));
        self.line(&format!("  store i16 2, i16* {}", fam));
        let p16 = self.tmp_name();
        self.line(&format!("  {} = trunc i32 {} to i16", p16, port));
        let pbe = self.tmp_name();
        self.line(&format!("  {} = call i16 @htons(i16 {})", pbe, p16));
        let pg = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 2", pg, sa));
        let pp = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i16*", pp, pg));
        self.line(&format!("  store i16 {}, i16* {}", pbe, pp));
        let ag = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 4", ag, sa));
        let ap = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", ap, ag));
        self.line(&format!("  store i32 {}, i32* {}", addr, ap));
        let sarg = self.sock_arg(&sock);
        let br = self.tmp_name();
        self.line(&format!("  {} = call i32 @bind({}, i8* {}, i32 16)", br, sarg, sa));
        let lr = self.tmp_name();
        let bind_ok = self.block_label("tcp_listen_bound");
        let bind_fail = self.block_label("tcp_listen_unbound");
        let bfailed = self.tmp_name();
        self.line(&format!("  {} = icmp ne i32 {}, 0", bfailed, br));
        self.line(&format!("  br i1 {}, label %{}, label %{}", bfailed, bind_fail, bind_ok));
        self.open_block(&bind_ok);
        let sarg2 = self.sock_arg(&sock);
        self.line(&format!("  {} = call i32 @listen({}, i32 64)", lr, sarg2));
        let lfailed = self.tmp_name();
        self.line(&format!("  {} = icmp ne i32 {}, 0", lfailed, lr));
        let listening = self.block_label("tcp_listen_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", lfailed, bind_fail, listening));
        self.open_block(&bind_fail);
        self.emit_close_socket(&sock);
        self.line(&format!("  br label %{}", end));
        self.open_block(&listening);
        self.emit_make_nonblocking(&sock);
        let ok_pred = self.current_label.clone();
        self.line(&format!("  br label %{}", end));

        self.open_block(&end);
        let r = self.tmp_name();
        self.line(&format!("  {} = phi i8* [ null, %{} ], [ null, %{} ], [ {}, %{} ]", r, sock_fail, bind_fail, sock, ok_pred));
        format!("i8* {}", r)
    }

    /// `tcp_accept(listener: ptr) -> ptr`; null when nothing is pending.
    pub(super) fn emit_tcp_accept(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("tcp_accept(..) expects 1 argument", Span::dummy());
            return "i8* null".into();
        };
        let v = self.emit_expr(arg);
        let h = self.untag(&v, &Ty::Ptr);
        self.abort_if_null_socket(&h, "tcp_accept");
        let s = match self.target {
            Target::WindowsGnu => {
                self.declare_lazy("declare i8* @accept(i8*, i8*, i32*)");
                let s = self.tmp_name();
                self.line(&format!("  {} = call i8* @accept(i8* {}, i8* null, i32* null)", s, h));
                s
            }
            Target::LinuxGnu => {
                self.declare_lazy("declare i32 @accept(i32, i8*, i32*)");
                let fd = self.socket_handle_to_fd(&h);
                let nfd = self.tmp_name();
                self.line(&format!("  {} = call i32 @accept(i32 {}, i8* null, i32* null)", nfd, fd));
                let n64 = self.tmp_name();
                self.line(&format!("  {} = sext i32 {} to i64", n64, nfd));
                let s = self.tmp_name();
                self.line(&format!("  {} = inttoptr i64 {} to i8*", s, n64));
                s
            }
        };
        let none = self.block_label("tcp_accept_none");
        let got = self.block_label("tcp_accept_got");
        let end = self.block_label("tcp_accept_end");
        let bad = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, inttoptr (i64 -1 to i8*)", bad, s));
        self.line(&format!("  br i1 {}, label %{}, label %{}", bad, none, got));
        self.open_block(&none);
        self.line(&format!("  br label %{}", end));
        self.open_block(&got);
        self.emit_make_nonblocking(&s);
        let got_pred = self.current_label.clone();
        self.line(&format!("  br label %{}", end));
        self.open_block(&end);
        let r = self.tmp_name();
        self.line(&format!("  {} = phi i8* [ null, %{} ], [ {}, %{} ]", r, none, s, got_pred));
        format!("i8* {}", r)
    }

    /// `getsockname`/`getpeername` into a fresh `sockaddr_in`; returns the
    /// buffer and an `i1` that is true on success.
    pub(super) fn emit_sock_name(&mut self, handle: &str, peer: bool) -> (String, String) {
        let which = if peer { "getpeername" } else { "getsockname" };
        match self.target {
            Target::WindowsGnu => self.declare_lazy(&format!("declare i32 @{}(i8*, i8*, i32*)", which)),
            Target::LinuxGnu => self.declare_lazy(&format!("declare i32 @{}(i32, i8*, i32*)", which)),
        }
        let sa = self.emit_sockaddr_buf();
        let len = self.tmp_name();
        self.line(&format!("  {} = alloca i32", len));
        self.line(&format!("  store i32 16, i32* {}", len));
        let sarg = self.sock_arg(handle);
        let rc = self.tmp_name();
        self.line(&format!("  {} = call i32 @{}({}, i8* {}, i32* {})", rc, which, sarg, sa, len));
        let ok = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 0", ok, rc));
        (sa, ok)
    }

    /// `tcp_local_port(handle: ptr) -> int`
    pub(super) fn emit_tcp_local_port(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("tcp_local_port(..) expects 1 argument", Span::dummy());
            return "i32 0".into();
        };
        let v = self.emit_expr(arg);
        let h = self.untag(&v, &Ty::Ptr);
        self.abort_if_null_socket(&h, "tcp_local_port");
        self.emit_sock_port(&h, false)
    }

    /// The port of a socket's own (`peer` false) or its peer's address, -1
    /// on failure; shared with `crate::codegen::net_sock`'s `tcp_peer_port`.
    pub(super) fn emit_sock_port(&mut self, h: &str, peer: bool) -> String {
        let (sa, ok) = self.emit_sock_name(h, peer);
        let pg = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 2", pg, sa));
        let pp = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i16*", pp, pg));
        let pbe = self.tmp_name();
        self.line(&format!("  {} = load i16, i16* {}", pbe, pp));
        // htons is its own inverse (a byte swap on a little-endian host)
        let p16 = self.tmp_name();
        self.line(&format!("  {} = call i16 @htons(i16 {})", p16, pbe));
        let p32 = self.tmp_name();
        self.line(&format!("  {} = zext i16 {} to i32", p32, p16));
        let r = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i32 {}, i32 -1", r, ok, p32));
        format!("i32 {}", r)
    }

    /// `tcp_peer_ip(handle: ptr) -> str`
    pub(super) fn emit_tcp_peer_ip(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("tcp_peer_ip(..) expects 1 argument", Span::dummy());
            return "i8* null".into();
        };
        let v = self.emit_expr(arg);
        let h = self.untag(&v, &Ty::Ptr);
        self.abort_if_null_socket(&h, "tcp_peer_ip");
        self.emit_sock_ip(&h, true)
    }

    /// The dotted-decimal address of a socket's peer (`peer`) or its own
    /// end, "" on failure; shared with `crate::codegen::net_sock`'s
    /// `tcp_local_ip`.
    pub(super) fn emit_sock_ip(&mut self, h: &str, peer: bool) -> String {
        let (sa, ok) = self.emit_sock_name(h, peer);
        let ag = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 4", ag, sa));
        let ap = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", ap, ag));
        let addr = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", addr, ap));
        self.emit_ipv4_to_str(&addr, &ok)
    }

    /// An `i32` IPv4 address (network byte order) as a fresh dotted-decimal
    /// `str` (`inet_ntoa`), or "" when `ok` (an `i1`) is false.
    pub(super) fn emit_ipv4_to_str(&mut self, addr: &str, ok: &str) -> String {
        self.declare_lazy("declare i8* @inet_ntoa(i32)");
        let have = self.block_label("tcp_peer_have");
        let none = self.block_label("tcp_peer_none");
        let end = self.block_label("tcp_peer_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", ok, have, none));

        self.open_block(&have);
        // `struct in_addr` is one 32-bit field, passed by value in a
        // register on both x86-64 ABIs; the result is the C runtime's
        // static buffer, copied out at once
        let cs = self.tmp_name();
        self.line(&format!("  {} = call i8* @inet_ntoa(i32 {})", cs, addr));
        let cs_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", cs_null, cs));
        let copy = self.block_label("tcp_peer_copy");
        self.line(&format!("  br i1 {}, label %{}, label %{}", cs_null, none, copy));
        self.open_block(&copy);
        let n = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", n, cs));
        let n1 = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", n1, n));
        let n64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", n64, n1));
        let buf = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 {}, i8* null)", buf, n64));
        self.line(&format!("  call i8* @strcpy(i8* {}, i8* {})", buf, cs));
        let copy_pred = self.current_label.clone();
        self.line(&format!("  br label %{}", end));

        self.open_block(&none);
        let empty = self.emit_empty_owned_str();
        let none_pred = self.current_label.clone();
        self.line(&format!("  br label %{}", end));

        self.open_block(&end);
        let r = self.tmp_name();
        self.line(&format!("  {} = phi i8* [ {}, %{} ], [ {}, %{} ]", r, buf, copy_pred, empty, none_pred));
        format!("i8* {}", r)
    }

    /// `host_name() -> str`; see the module doc comment.
    pub(super) fn emit_host_name(&mut self) -> String {
        match self.target {
            Target::WindowsGnu => {
                self.declare_lazy("declare i32 @gethostname(i8*, i32)");
                let wsa = self.tmp_name();
                self.line(&format!("  {} = alloca [512 x i8]", wsa));
                let wp = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds [512 x i8], [512 x i8]* {}, i64 0, i64 0", wp, wsa));
                self.line(&format!("  call i32 @WSAStartup(i16 514, i8* {})", wp));
            }
            Target::LinuxGnu => self.declare_lazy("declare i32 @gethostname(i8*, i64)"),
        }
        let buf = self.tmp_name();
        self.line(&format!("  {} = alloca [256 x i8]", buf));
        let bp = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [256 x i8], [256 x i8]* {}, i64 0, i64 0", bp, buf));
        self.line(&format!("  store i8 0, i8* {}", bp));
        let rc = self.tmp_name();
        match self.target {
            Target::WindowsGnu => self.line(&format!("  {} = call i32 @gethostname(i8* {}, i32 255)", rc, bp)),
            Target::LinuxGnu => self.line(&format!("  {} = call i32 @gethostname(i8* {}, i64 255)", rc, bp)),
        }
        // gethostname needn't terminate a name that fills the buffer
        let last = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [256 x i8], [256 x i8]* {}, i64 0, i64 255", last, buf));
        self.line(&format!("  store i8 0, i8* {}", last));
        let failed = self.tmp_name();
        self.line(&format!("  {} = icmp ne i32 {}, 0", failed, rc));
        let fail = self.block_label("host_name_fail");
        let ok = self.block_label("host_name_ok");
        let end = self.block_label("host_name_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", failed, fail, ok));
        self.open_block(&fail);
        let empty = self.emit_empty_owned_str();
        self.line(&format!("  br label %{}", end));
        self.open_block(&ok);
        let n = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", n, bp));
        let n1 = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", n1, n));
        let n64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", n64, n1));
        let s = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 {}, i8* null)", s, n64));
        self.line(&format!("  call i8* @strcpy(i8* {}, i8* {})", s, bp));
        self.line(&format!("  br label %{}", end));
        self.open_block(&end);
        let r = self.tmp_name();
        self.line(&format!("  {} = phi i8* [ {}, %{} ], [ {}, %{} ]", r, empty, fail, s, ok));
        format!("i8* {}", r)
    }

    /// `tcp_wait(handles: List<ptr>, timeout_ms: int) -> Bytes`; see the
    /// module doc comment. A negative timeout waits indefinitely (with no
    /// handles it sleeps 0 ms instead, rather than forever).
    pub(super) fn emit_tcp_wait(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("tcp_wait(..) expects 2 arguments (handles, timeout_ms)", Span::dummy());
            return "i8* null".into();
        }
        self.emit_poll_wait(&args[0], None, &args[1])
    }

    /// The body of `tcp_wait`, shared with `crate::codegen::net_sock`'s
    /// `tcp_wait_io`, whose `interest` (a `Bytes`, one byte per handle: 1
    /// read, 4 write, 5 both; a handle past its end is 1) also asks for
    /// write readiness, reported as bit 4. Without `interest` every handle
    /// is polled for reading only, as `tcp_wait` always has been.
    pub(super) fn emit_poll_wait(&mut self, handles: &TypedExpr, interest: Option<&TypedExpr>, timeout_e: &TypedExpr) -> String {
        let tv = self.emit_expr(timeout_e);
        let timeout = self.untag(&tv, &Ty::Int);
        let (data, len) = self.list_fields(handles, &Ty::Ptr);
        let want_io = match interest {
            Some(e) => Some(self.list_fields(e, &Ty::U8)),
            None => None,
        };
        // WSAPOLLFD { SOCKET fd; SHORT events; SHORT revents; } is 16 bytes,
        // glibc's pollfd { int fd; short events; short revents; } 8
        let (stride, ev_off, rev_off, want, read_mask, hup_mask, write_mask) = match self.target {
            Target::WindowsGnu => {
                self.declare_lazy("declare i32 @WSAPoll(i8*, i32, i32)");
                self.declare_lazy("declare void @Sleep(i32)");
                // POLLRDNORM; POLLRDNORM | POLLRDBAND; POLLERR | POLLHUP |
                // POLLNVAL; POLLWRNORM
                (16u64, 8u64, 10u64, 0x0100, 0x0300, 0x0007, 0x0010)
            }
            Target::LinuxGnu => {
                self.declare_lazy("declare i32 @poll(i8*, i64, i32)");
                // POLLIN; POLLIN | POLLPRI; POLLERR | POLLHUP | POLLNVAL;
                // POLLOUT
                (8u64, 4u64, 6u64, 0x0001, 0x0003, 0x0038, 0x0004)
            }
        };
        let empty = self.block_label("tcp_wait_empty");
        let work = self.block_label("tcp_wait_work");
        let end = self.block_label("tcp_wait_end");
        let is_empty = self.tmp_name();
        self.line(&format!("  {} = icmp eq i64 {}, 0", is_empty, len));
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_empty, empty, work));

        self.open_block(&empty);
        let neg = self.tmp_name();
        self.line(&format!("  {} = icmp slt i32 {}, 0", neg, timeout));
        let t0 = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i32 0, i32 {}", t0, neg, timeout));
        match self.target {
            Target::WindowsGnu => self.line(&format!("  call void @Sleep(i32 {})", t0)),
            Target::LinuxGnu => self.line(&format!("  call i32 @poll(i8* null, i64 0, i32 {})", t0)),
        }
        self.line(&format!("  br label %{}", end));

        self.open_block(&work);
        let bytes = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, {}", bytes, len, stride));
        let fds = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", fds, bytes));
        let out = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", out, len));
        let idx = self.tmp_name();
        self.line(&format!("  {} = alloca i64", idx));

        // fill the poll array
        self.line(&format!("  store i64 0, i64* {}", idx));
        let fill_head = self.block_label("tcp_wait_fill");
        let fill_body = self.block_label("tcp_wait_fill_body");
        let fill_done = self.block_label("tcp_wait_fill_done");
        self.line(&format!("  br label %{}", fill_head));
        self.open_block(&fill_head);
        let i = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", i, idx));
        let more = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", more, i, len));
        self.line(&format!("  br i1 {}, label %{}, label %{}", more, fill_body, fill_done));
        self.open_block(&fill_body);
        let hp = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8*, i8** {}, i64 {}", hp, data, i));
        let hv = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", hv, hp));
        let off = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, {}", off, i, stride));
        let slot = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", slot, fds, off));
        match self.target {
            Target::WindowsGnu => {
                let sp = self.tmp_name();
                self.line(&format!("  {} = bitcast i8* {} to i8**", sp, slot));
                self.line(&format!("  store i8* {}, i8** {}", hv, sp));
            }
            Target::LinuxGnu => {
                let fd = self.socket_handle_to_fd(&hv);
                let sp = self.tmp_name();
                self.line(&format!("  {} = bitcast i8* {} to i32*", sp, slot));
                self.line(&format!("  store i32 {}, i32* {}", fd, sp));
            }
        }
        let eg = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", eg, slot, ev_off));
        let ep = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", ep, eg));
        let events = match &want_io {
            None => want.to_string(),
            Some((idata, ilen)) => {
                // interest byte i, or 1 (read) past the end of `interest`
                // (an empty `Bytes` has a null data pointer, never read)
                let inside = self.tmp_name();
                self.line(&format!("  {} = icmp slt i64 {}, {}", inside, i, ilen));
                let read_here = self.block_label("tcp_wait_interest");
                let after = self.block_label("tcp_wait_interest_done");
                let before = self.current_label.clone();
                self.line(&format!("  br i1 {}, label %{}, label %{}", inside, read_here, after));
                self.open_block(&read_here);
                let bp = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", bp, idata, i));
                let raw = self.tmp_name();
                self.line(&format!("  {} = load i8, i8* {}", raw, bp));
                self.line(&format!("  br label %{}", after));
                self.open_block(&after);
                let iv = self.tmp_name();
                self.line(&format!("  {} = phi i8 [ 1, %{} ], [ {}, %{} ]", iv, before, raw, read_here));
                let rbit = self.tmp_name();
                self.line(&format!("  {} = and i8 {}, 1", rbit, iv));
                let rset = self.tmp_name();
                self.line(&format!("  {} = icmp ne i8 {}, 0", rset, rbit));
                let wbit = self.tmp_name();
                self.line(&format!("  {} = and i8 {}, 4", wbit, iv));
                let wset = self.tmp_name();
                self.line(&format!("  {} = icmp ne i8 {}, 0", wset, wbit));
                let r = self.tmp_name();
                self.line(&format!("  {} = select i1 {}, i32 {}, i32 0", r, rset, want));
                let w = self.tmp_name();
                self.line(&format!("  {} = select i1 {}, i32 {}, i32 0", w, wset, write_mask));
                let ev = self.tmp_name();
                self.line(&format!("  {} = or i32 {}, {}", ev, r, w));
                ev
            }
        };
        // events in the low half, revents (zeroed) in the high half
        self.line(&format!("  store i32 {}, i32* {}", events, ep));
        let inext = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", inext, i));
        self.line(&format!("  store i64 {}, i64* {}", inext, idx));
        self.line(&format!("  br label %{}", fill_head));

        self.open_block(&fill_done);
        let rc = self.tmp_name();
        match self.target {
            Target::WindowsGnu => {
                let n32 = self.tmp_name();
                self.line(&format!("  {} = trunc i64 {} to i32", n32, len));
                self.line(&format!("  {} = call i32 @WSAPoll(i8* {}, i32 {}, i32 {})", rc, fds, n32, timeout));
            }
            Target::LinuxGnu => {
                self.line(&format!("  {} = call i32 @poll(i8* {}, i64 {}, i32 {})", rc, fds, len, timeout));
            }
        }
        let failed = self.tmp_name();
        self.line(&format!("  {} = icmp slt i32 {}, 0", failed, rc));

        // read back revents
        self.line(&format!("  store i64 0, i64* {}", idx));
        let rd_head = self.block_label("tcp_wait_read");
        let rd_body = self.block_label("tcp_wait_read_body");
        let rd_done = self.block_label("tcp_wait_read_done");
        self.line(&format!("  br label %{}", rd_head));
        self.open_block(&rd_head);
        let j = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", j, idx));
        let jmore = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", jmore, j, len));
        self.line(&format!("  br i1 {}, label %{}, label %{}", jmore, rd_body, rd_done));
        self.open_block(&rd_body);
        let joff = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, {}", joff, j, stride));
        let jslot = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", jslot, fds, joff));
        let rg = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", rg, jslot, rev_off));
        let rp = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i16*", rp, rg));
        let rev = self.tmp_name();
        self.line(&format!("  {} = load i16, i16* {}", rev, rp));
        let rd = self.tmp_name();
        self.line(&format!("  {} = and i16 {}, {}", rd, rev, read_mask));
        let is_rd = self.tmp_name();
        self.line(&format!("  {} = icmp ne i16 {}, 0", is_rd, rd));
        let hu = self.tmp_name();
        self.line(&format!("  {} = and i16 {}, {}", hu, rev, hup_mask));
        let is_hu = self.tmp_name();
        self.line(&format!("  {} = icmp ne i16 {}, 0", is_hu, hu));
        let b1 = self.tmp_name();
        self.line(&format!("  {} = zext i1 {} to i8", b1, is_rd));
        let b2a = self.tmp_name();
        self.line(&format!("  {} = zext i1 {} to i8", b2a, is_hu));
        let b2 = self.tmp_name();
        self.line(&format!("  {} = shl i8 {}, 1", b2, b2a));
        let fl0 = self.tmp_name();
        self.line(&format!("  {} = or i8 {}, {}", fl0, b1, b2));
        let fl = if want_io.is_some() {
            let wr = self.tmp_name();
            self.line(&format!("  {} = and i16 {}, {}", wr, rev, write_mask));
            let is_wr = self.tmp_name();
            self.line(&format!("  {} = icmp ne i16 {}, 0", is_wr, wr));
            let b4 = self.tmp_name();
            self.line(&format!("  {} = select i1 {}, i8 4, i8 0", b4, is_wr));
            let f = self.tmp_name();
            self.line(&format!("  {} = or i8 {}, {}", f, fl0, b4));
            f
        } else {
            fl0
        };
        let flag = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i8 0, i8 {}", flag, failed, fl));
        let og = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", og, out, j));
        self.line(&format!("  store i8 {}, i8* {}", flag, og));
        let jnext = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", jnext, j));
        self.line(&format!("  store i64 {}, i64* {}", jnext, idx));
        self.line(&format!("  br label %{}", rd_head));

        self.open_block(&rd_done);
        self.line(&format!("  call void @free(i8* {})", fds));
        let wrapped = self.emit_bytes_wrap_raw_buf(&out, &len);
        let wrapped_reg = self.reg_of(&wrapped);
        let work_pred = self.current_label.clone();
        self.line(&format!("  br label %{}", end));

        self.open_block(&end);
        let r = self.tmp_name();
        self.line(&format!("  {} = phi i8* [ null, %{} ], [ {}, %{} ]", r, empty, wrapped_reg, work_pred));
        format!("i8* {}", r)
    }

    /// `tcp_recv_bytes(handle: ptr) -> Bytes`: whatever one `recv` returns
    /// (up to `RECV_CHUNK` bytes); empty when the peer closed, the
    /// connection broke, or (on a handle `tcp_wait` didn't report ready)
    /// nothing has arrived yet.
    pub(super) fn emit_tcp_recv_bytes(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("tcp_recv_bytes(..) expects 1 argument", Span::dummy());
            return "i8* null".into();
        };
        let v = self.emit_expr(arg);
        let h = self.untag(&v, &Ty::Ptr);
        self.abort_if_null_socket(&h, "tcp_recv_bytes");
        let buf = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", buf, RECV_CHUNK));
        let n = match self.target {
            Target::WindowsGnu => {
                let n = self.tmp_name();
                self.line(&format!("  {} = call i32 @recv(i8* {}, i8* {}, i32 {}, i32 0)", n, h, buf, RECV_CHUNK));
                n
            }
            Target::LinuxGnu => {
                let fd = self.socket_handle_to_fd(&h);
                let n64 = self.tmp_name();
                self.line(&format!("  {} = call i64 @recv(i32 {}, i8* {}, i64 {}, i32 0)", n64, fd, buf, RECV_CHUNK));
                let n = self.tmp_name();
                self.line(&format!("  {} = trunc i64 {} to i32", n, n64));
                n
            }
        };
        let got = self.block_label("tcp_recvb_got");
        let none = self.block_label("tcp_recvb_none");
        let end = self.block_label("tcp_recvb_end");
        let pos = self.tmp_name();
        self.line(&format!("  {} = icmp sgt i32 {}, 0", pos, n));
        self.line(&format!("  br i1 {}, label %{}, label %{}", pos, got, none));
        self.open_block(&got);
        let n64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", n64, n));
        let wrapped = self.emit_bytes_wrap_raw_buf(&buf, &n64);
        let wreg = self.reg_of(&wrapped);
        let got_pred = self.current_label.clone();
        self.line(&format!("  br label %{}", end));
        self.open_block(&none);
        self.line(&format!("  call void @free(i8* {})", buf));
        self.line(&format!("  br label %{}", end));
        self.open_block(&end);
        let r = self.tmp_name();
        self.line(&format!("  {} = phi i8* [ {}, %{} ], [ null, %{} ]", r, wreg, got_pred, none));
        format!("i8* {}", r)
    }

    /// `tcp_send_bytes(handle: ptr, data: Bytes, start: int) -> int`; see
    /// the module doc comment.
    pub(super) fn emit_tcp_send_bytes(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 3 {
            self.err("tcp_send_bytes(..) expects 3 arguments (handle, data, start)", Span::dummy());
            return "i32 -1".into();
        }
        let hv = self.emit_expr(&args[0]);
        let h = self.untag(&hv, &Ty::Ptr);
        self.abort_if_null_socket(&h, "tcp_send_bytes");
        let sv = self.emit_expr(&args[2]);
        let start = self.untag(&sv, &Ty::Int);
        let (data, len) = self.list_fields(&args[1], &Ty::U8);
        let s64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", s64, start));
        let sneg = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, 0", sneg, s64));
        let s0 = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i64 0, i64 {}", s0, sneg, s64));
        let rem = self.tmp_name();
        self.line(&format!("  {} = sub i64 {}, {}", rem, len, s0));
        let nothing = self.block_label("tcp_sendb_nothing");
        let go = self.block_label("tcp_sendb_go");
        let end = self.block_label("tcp_sendb_end");
        let none_left = self.tmp_name();
        self.line(&format!("  {} = icmp sle i64 {}, 0", none_left, rem));
        self.line(&format!("  br i1 {}, label %{}, label %{}", none_left, nothing, go));
        self.open_block(&nothing);
        self.line(&format!("  br label %{}", end));

        self.open_block(&go);
        let p = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", p, data, s0));
        let n = match self.target {
            Target::WindowsGnu => {
                let big = self.tmp_name();
                self.line(&format!("  {} = icmp sgt i64 {}, 1073741824", big, rem));
                let capped = self.tmp_name();
                self.line(&format!("  {} = select i1 {}, i64 1073741824, i64 {}", capped, big, rem));
                let r32 = self.tmp_name();
                self.line(&format!("  {} = trunc i64 {} to i32", r32, capped));
                let n = self.tmp_name();
                self.line(&format!("  {} = call i32 @send(i8* {}, i8* {}, i32 {}, i32 0)", n, h, p, r32));
                n
            }
            Target::LinuxGnu => {
                let fd = self.socket_handle_to_fd(&h);
                let n64 = self.tmp_name();
                // MSG_NOSIGNAL: see the module doc comment
                self.line(&format!("  {} = call i64 @send(i32 {}, i8* {}, i64 {}, i32 16384)", n64, fd, p, rem));
                let n = self.tmp_name();
                self.line(&format!("  {} = trunc i64 {} to i32", n, n64));
                n
            }
        };
        let neg = self.tmp_name();
        self.line(&format!("  {} = icmp slt i32 {}, 0", neg, n));
        let errb = self.block_label("tcp_sendb_err");
        let okb = self.block_label("tcp_sendb_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", neg, errb, okb));
        self.open_block(&errb);
        let wb = self.emit_last_error_would_block();
        let code = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i32 0, i32 -1", code, wb));
        let err_pred = self.current_label.clone();
        self.line(&format!("  br label %{}", end));
        self.open_block(&okb);
        self.line(&format!("  br label %{}", end));

        self.open_block(&end);
        let r = self.tmp_name();
        self.line(&format!("  {} = phi i32 [ 0, %{} ], [ {}, %{} ], [ {}, %{} ]", r, nothing, code, err_pred, n, okb));
        format!("i32 {}", r)
    }
}

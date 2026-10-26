//! Socket builtins for an event loop that talks to other servers:
//! `tcp_listen_at`, `tcp_connect_start`, `tcp_sock_error`, `tcp_wait_io`,
//! `tcp_local_ip`, `tcp_peer_port`, `udp_open`, `udp_recv_from`,
//! `udp_send_to`, `host_lookup`.
//!
//! Why: the HavokOS LPMUD driver (`projects/havokos`, `todo.md` HavokOS
//! P1 #5) implements LPC's socket efuns (`socket_create`/`bind`/`listen`/
//! `accept`/`connect`/`write`/..., FluffOS PACKAGE_SOCKETS), which Dead
//! Souls uses for its intermud clients and its small servers.
//! `crate::codegen::net_server` covers a telnet listener, but an LPC
//! socket also needs things a listener never does:
//! - **bind a chosen address** (`socket_bind(fd, port, "10.0.0.5")`):
//!   `tcp_listen_at(ip, port)`, "" meaning any;
//! - **connect without blocking the whole driver**: `tcp_connect_start(ip,
//!   port)` returns as soon as the connect is under way (`connect` on a
//!   non-blocking socket, `WSAEWOULDBLOCK`/`EINPROGRESS` counting as
//!   success), and the caller learns the outcome from write readiness plus
//!   `tcp_sock_error(h)` (`getsockopt(SO_ERROR)`: 0 once connected, the
//!   OS error code if it failed). `crate::codegen::net`'s `tcp_connect`
//!   blocks until the peer answers, which for a refused loopback port on
//!   Windows is about two seconds of the driver doing nothing;
//! - **write readiness**: a connect finishing, or a socket whose send
//!   buffer filled draining again. `tcp_wait_io(handles, interest,
//!   timeout_ms)` is `tcp_wait` with one interest byte per handle (1 read,
//!   4 write, 5 both), and reports bit 4 for writable beside `tcp_wait`'s 1
//!   (readable) and 2 (error/hang-up). It shares `tcp_wait`'s body
//!   (`emit_poll_wait`), so the main loop still makes one `poll` over
//!   every telnet and LPC socket;
//! - **both ends' addresses** (`socket_address()`, `socket_status()`):
//!   `tcp_local_ip` and `tcp_peer_port` complete `net_server`'s
//!   `tcp_peer_ip`/`tcp_local_port`, and all four work on UDP sockets too;
//! - **datagrams** (DATAGRAM modes): `udp_open(ip, port)` binds a
//!   non-blocking UDP socket (port 0 picks one), `udp_send_to(h, ip, port,
//!   data)` returns the bytes sent or -1, and `udp_recv_from(h)` returns
//!   one datagram as `Bytes` *prefixed with its sender*: 4 bytes of IPv4
//!   address and 2 of port, both in network byte order, then the payload.
//!   A builtin can't return a tuple or an `Option` (`net_server`'s doc
//!   comment explains why the latter is out), and a header keeps the
//!   sender attached to its datagram, where a separate "last sender" query
//!   would be global state. Empty means nothing was waiting (a datagram of
//!   zero bytes is still 6 bytes long). On Windows a `recvfrom` can fail
//!   with `WSAECONNRESET` after an earlier `sendto` drew an ICMP "port
//!   unreachable"; that reads as empty too, and the error is consumed;
//! - **names**: `host_lookup(name)` is the first IPv4 address of a host
//!   name (`gethostbyname`), "" when there is none. It blocks for as long
//!   as the system resolver takes. An asynchronous resolver would mean
//!   writing a DNS client; LPC's `resolve()` is called by a few Dead Souls
//!   daemons at startup or on a creator's command, so the driver accepts
//!   the stall (`projects/havokos/NOTES.md` documents this) rather than
//!   the compiler growing one.
//!
//! IP arguments are dotted-decimal (`inet_addr`); a malformed one makes
//! the builtin fail (null or -1) instead of using garbage address bytes,
//! the same rule `tcp_connect` follows.
//!
//! Every C symbol here is declared on first use, as in `net_server`: these
//! are common function names (`sendto`, `getsockopt`, ...).
//!
//! ## `Target::LinuxGnu`: seamed, not yet devbox-verified
//! The Linux arm uses glibc's x86-64 values (`SOL_SOCKET` 1, `SO_ERROR` 4,
//! `EINPROGRESS` 115, `size_t` lengths, `POLLOUT` 4 in `emit_poll_wait`)
//! and is checked by the IR verifier and by compiling to an object for
//! `x86_64-unknown-linux-gnu` (`tests/frontend_net_sock.rs`), but hasn't
//! been linked and run there, like the rest of the HavokOS socket layer.
//! See `docs/cross_platform_scope.md`.

use crate::diagnostics::Span;
use crate::types::*;

use super::{Codegen, Target};

/// Largest datagram `udp_recv_from` takes: the most an IPv4 UDP datagram
/// can carry is 65507 bytes, so nothing is ever cut short.
const UDP_CHUNK: u64 = 65536;

impl Codegen {
    /// `WSAStartup` on Windows (reference-counted by Winsock, so calling it
    /// again is harmless); nothing on Linux. Every builtin here that can be
    /// a program's first socket call starts with it, as `tcp_connect` does.
    fn emit_wsa_startup(&mut self) {
        if self.target == Target::WindowsGnu {
            let wsa = self.tmp_name();
            self.line(&format!("  {} = alloca [512 x i8]", wsa));
            let wp = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds [512 x i8], [512 x i8]* {}, i64 0, i64 0", wp, wsa));
            self.line(&format!("  call i32 @WSAStartup(i16 514, i8* {})", wp));
        }
    }

    /// Parse a dotted-decimal IPv4 argument: returns the `i32` address in
    /// network byte order and an `i1` that is true when it is usable. An
    /// empty (or null) string is the "any" address 0 when `empty_is_any`,
    /// and invalid otherwise.
    fn emit_ipv4_arg(&mut self, e: &TypedExpr, empty_is_any: bool) -> (String, String) {
        let raw = self.emit_raw_str_ptr(e);
        let p = self.emit_str_or_empty(&raw);
        let first = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", first, p));
        let empty = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8 {}, 0", empty, first));
        let a = self.tmp_name();
        self.line(&format!("  {} = call i32 @inet_addr(i8* {})", a, p));
        self.line(&format!("  call void @star_rc_release(i8* {})", raw));
        // INADDR_NONE: see `emit_tcp_connect`
        let valid = self.tmp_name();
        self.line(&format!("  {} = icmp ne i32 {}, -1", valid, a));
        let addr = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i32 0, i32 {}", addr, empty, a));
        let ok = self.tmp_name();
        if empty_is_any {
            self.line(&format!("  {} = or i1 {}, {}", ok, empty, valid));
        } else {
            let nonempty = self.tmp_name();
            self.line(&format!("  {} = xor i1 {}, true", nonempty, empty));
            self.line(&format!("  {} = and i1 {}, {}", ok, nonempty, valid));
        }
        (addr, ok)
    }

    /// A zeroed `sockaddr_in` for `addr`:`port` (both registers; `port` an
    /// `i32` in host order).
    fn emit_sockaddr_for(&mut self, addr: &str, port: &str) -> String {
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
        sa
    }

    /// `socket(AF_INET, type, proto)` packed into the uniform `i8*` handle
    /// shape (see `net.rs`), plus an `i1` that is true when it failed.
    fn emit_new_socket(&mut self, sock_type: i32, proto: i32) -> (String, String) {
        let s = match self.target {
            Target::WindowsGnu => {
                let s = self.tmp_name();
                self.line(&format!("  {} = call i8* @socket(i32 2, i32 {}, i32 {})", s, sock_type, proto));
                s
            }
            Target::LinuxGnu => {
                let fd = self.tmp_name();
                self.line(&format!("  {} = call i32 @socket(i32 2, i32 {}, i32 {})", fd, sock_type, proto));
                let fd64 = self.tmp_name();
                self.line(&format!("  {} = sext i32 {} to i64", fd64, fd));
                let s = self.tmp_name();
                self.line(&format!("  {} = inttoptr i64 {} to i8*", s, fd64));
                s
            }
        };
        let bad = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, inttoptr (i64 -1 to i8*)", bad, s));
        (s, bad)
    }

    /// `tcp_listen_at(ip: str, port: int) -> ptr`; see the module doc
    /// comment. Null when the address is malformed or the port can't be
    /// bound.
    pub(super) fn emit_tcp_listen_at(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("tcp_listen_at(..) expects 2 arguments (ip, port)", Span::dummy());
            return "i8* null".into();
        }
        let pv = self.emit_expr(&args[1]);
        let port = self.untag(&pv, &Ty::Int);
        self.emit_wsa_startup();
        let (addr, ok) = self.emit_ipv4_arg(&args[0], true);
        let go = self.block_label("tcp_listen_at_go");
        let bad = self.block_label("tcp_listen_at_bad");
        let end = self.block_label("tcp_listen_at_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", ok, go, bad));
        self.open_block(&bad);
        self.line(&format!("  br label %{}", end));
        self.open_block(&go);
        let l = self.emit_listen_on(&port, &addr);
        let lreg = self.reg_of(&l);
        let go_pred = self.current_label.clone();
        self.line(&format!("  br label %{}", end));
        self.open_block(&end);
        let r = self.tmp_name();
        self.line(&format!("  {} = phi i8* [ null, %{} ], [ {}, %{} ]", r, bad, lreg, go_pred));
        format!("i8* {}", r)
    }

    /// `tcp_connect_start(ip: str, port: int) -> ptr`; see the module doc
    /// comment. Null when the address is malformed, no socket could be
    /// made, or the connect failed at once.
    pub(super) fn emit_tcp_connect_start(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("tcp_connect_start(..) expects 2 arguments (ip, port)", Span::dummy());
            return "i8* null".into();
        }
        let pv = self.emit_expr(&args[1]);
        let port = self.untag(&pv, &Ty::Int);
        self.emit_wsa_startup();
        let (addr, ok) = self.emit_ipv4_arg(&args[0], false);
        let end = self.block_label("tcp_cstart_end");
        let bad_addr = self.block_label("tcp_cstart_badaddr");
        let go = self.block_label("tcp_cstart_go");
        self.line(&format!("  br i1 {}, label %{}, label %{}", ok, go, bad_addr));
        self.open_block(&bad_addr);
        self.line(&format!("  br label %{}", end));

        self.open_block(&go);
        let (sock, sbad) = self.emit_new_socket(1, 6);
        let no_sock = self.block_label("tcp_cstart_nosock");
        let have = self.block_label("tcp_cstart_sock");
        self.line(&format!("  br i1 {}, label %{}, label %{}", sbad, no_sock, have));
        self.open_block(&no_sock);
        self.line(&format!("  br label %{}", end));

        self.open_block(&have);
        self.emit_make_nonblocking(&sock);
        let sa = self.emit_sockaddr_for(&addr, &port);
        let sarg = self.sock_arg(&sock);
        let rc = self.tmp_name();
        self.line(&format!("  {} = call i32 @connect({}, i8* {}, i32 16)", rc, sarg, sa));
        let done_now = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 0", done_now, rc));
        // in progress: WSAEWOULDBLOCK / EINPROGRESS
        let in_progress = match self.target {
            Target::WindowsGnu => {
                let e = self.tmp_name();
                self.line(&format!("  {} = call i32 @WSAGetLastError()", e));
                let w = self.tmp_name();
                self.line(&format!("  {} = icmp eq i32 {}, 10035", w, e));
                w
            }
            Target::LinuxGnu => {
                let ep = self.tmp_name();
                self.line(&format!("  {} = call i32* @__errno_location()", ep));
                let e = self.tmp_name();
                self.line(&format!("  {} = load i32, i32* {}", e, ep));
                let w = self.tmp_name();
                self.line(&format!("  {} = icmp eq i32 {}, 115", w, e));
                w
            }
        };
        let started = self.tmp_name();
        self.line(&format!("  {} = or i1 {}, {}", started, done_now, in_progress));
        let failed = self.block_label("tcp_cstart_failed");
        let ok_b = self.block_label("tcp_cstart_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", started, ok_b, failed));
        self.open_block(&failed);
        self.emit_close_socket(&sock);
        self.line(&format!("  br label %{}", end));
        self.open_block(&ok_b);
        self.line(&format!("  br label %{}", end));

        self.open_block(&end);
        let r = self.tmp_name();
        self.line(&format!(
            "  {} = phi i8* [ null, %{} ], [ null, %{} ], [ null, %{} ], [ {}, %{} ]",
            r, bad_addr, no_sock, failed, sock, ok_b
        ));
        format!("i8* {}", r)
    }

    /// `tcp_sock_error(h: ptr) -> int`: the socket's pending error
    /// (`SO_ERROR`), 0 for none, -1 if it can't be read.
    pub(super) fn emit_tcp_sock_error(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("tcp_sock_error(..) expects 1 argument", Span::dummy());
            return "i32 -1".into();
        };
        let v = self.emit_expr(arg);
        let h = self.untag(&v, &Ty::Ptr);
        self.abort_if_null_socket(&h, "tcp_sock_error");
        let (level, name) = match self.target {
            Target::WindowsGnu => {
                self.declare_lazy("declare i32 @getsockopt(i8*, i32, i32, i8*, i32*)");
                // SOL_SOCKET, SO_ERROR
                (0xffff, 0x1007)
            }
            Target::LinuxGnu => {
                self.declare_lazy("declare i32 @getsockopt(i32, i32, i32, i8*, i32*)");
                (1, 4)
            }
        };
        let val = self.tmp_name();
        self.line(&format!("  {} = alloca i32", val));
        self.line(&format!("  store i32 0, i32* {}", val));
        let len = self.tmp_name();
        self.line(&format!("  {} = alloca i32", len));
        self.line(&format!("  store i32 4, i32* {}", len));
        let vp = self.tmp_name();
        self.line(&format!("  {} = bitcast i32* {} to i8*", vp, val));
        let sarg = self.sock_arg(&h);
        let rc = self.tmp_name();
        self.line(&format!("  {} = call i32 @getsockopt({}, i32 {}, i32 {}, i8* {}, i32* {})", rc, sarg, level, name, vp, len));
        let e = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", e, val));
        let failed = self.tmp_name();
        self.line(&format!("  {} = icmp ne i32 {}, 0", failed, rc));
        let r = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i32 -1, i32 {}", r, failed, e));
        format!("i32 {}", r)
    }

    /// `tcp_wait_io(handles: List<ptr>, interest: Bytes, timeout_ms: int)
    /// -> Bytes`; see the module doc comment.
    pub(super) fn emit_tcp_wait_io(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 3 {
            self.err("tcp_wait_io(..) expects 3 arguments (handles, interest, timeout_ms)", Span::dummy());
            return "i8* null".into();
        }
        self.emit_poll_wait(&args[0], Some(&args[1]), &args[2])
    }

    /// `tcp_local_ip(h: ptr) -> str`: the socket's own address, "" on
    /// failure ("0.0.0.0" for one bound to any address).
    pub(super) fn emit_tcp_local_ip(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("tcp_local_ip(..) expects 1 argument", Span::dummy());
            return "i8* null".into();
        };
        let v = self.emit_expr(arg);
        let h = self.untag(&v, &Ty::Ptr);
        self.abort_if_null_socket(&h, "tcp_local_ip");
        self.emit_sock_ip(&h, false)
    }

    /// `tcp_peer_port(h: ptr) -> int`: the peer's port, -1 when there is
    /// no peer.
    pub(super) fn emit_tcp_peer_port(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("tcp_peer_port(..) expects 1 argument", Span::dummy());
            return "i32 -1".into();
        };
        let v = self.emit_expr(arg);
        let h = self.untag(&v, &Ty::Ptr);
        self.abort_if_null_socket(&h, "tcp_peer_port");
        self.emit_sock_port(&h, true)
    }

    /// `udp_open(ip: str, port: int) -> ptr`; see the module doc comment.
    /// Null when the address is malformed or can't be bound.
    pub(super) fn emit_udp_open(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("udp_open(..) expects 2 arguments (ip, port)", Span::dummy());
            return "i8* null".into();
        }
        let pv = self.emit_expr(&args[1]);
        let port = self.untag(&pv, &Ty::Int);
        self.emit_wsa_startup();
        let (addr, ok) = self.emit_ipv4_arg(&args[0], true);
        match self.target {
            Target::WindowsGnu => self.declare_lazy("declare i32 @bind(i8*, i8*, i32)"),
            Target::LinuxGnu => self.declare_lazy("declare i32 @bind(i32, i8*, i32)"),
        }
        let end = self.block_label("udp_open_end");
        let bad_addr = self.block_label("udp_open_badaddr");
        let go = self.block_label("udp_open_go");
        self.line(&format!("  br i1 {}, label %{}, label %{}", ok, go, bad_addr));
        self.open_block(&bad_addr);
        self.line(&format!("  br label %{}", end));

        self.open_block(&go);
        // SOCK_DGRAM, IPPROTO_UDP
        let (sock, sbad) = self.emit_new_socket(2, 17);
        let no_sock = self.block_label("udp_open_nosock");
        let have = self.block_label("udp_open_sock");
        self.line(&format!("  br i1 {}, label %{}, label %{}", sbad, no_sock, have));
        self.open_block(&no_sock);
        self.line(&format!("  br label %{}", end));

        self.open_block(&have);
        let sa = self.emit_sockaddr_for(&addr, &port);
        let sarg = self.sock_arg(&sock);
        let br = self.tmp_name();
        self.line(&format!("  {} = call i32 @bind({}, i8* {}, i32 16)", br, sarg, sa));
        let bfailed = self.tmp_name();
        self.line(&format!("  {} = icmp ne i32 {}, 0", bfailed, br));
        let unbound = self.block_label("udp_open_unbound");
        let bound = self.block_label("udp_open_bound");
        self.line(&format!("  br i1 {}, label %{}, label %{}", bfailed, unbound, bound));
        self.open_block(&unbound);
        self.emit_close_socket(&sock);
        self.line(&format!("  br label %{}", end));
        self.open_block(&bound);
        self.emit_make_nonblocking(&sock);
        let ok_pred = self.current_label.clone();
        self.line(&format!("  br label %{}", end));

        self.open_block(&end);
        let r = self.tmp_name();
        self.line(&format!(
            "  {} = phi i8* [ null, %{} ], [ null, %{} ], [ null, %{} ], [ {}, %{} ]",
            r, bad_addr, no_sock, unbound, sock, ok_pred
        ));
        format!("i8* {}", r)
    }

    /// `udp_recv_from(h: ptr) -> Bytes`: one datagram behind its sender's
    /// 6-byte address header, or empty; see the module doc comment.
    pub(super) fn emit_udp_recv_from(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("udp_recv_from(..) expects 1 argument", Span::dummy());
            return "i8* null".into();
        };
        let v = self.emit_expr(arg);
        let h = self.untag(&v, &Ty::Ptr);
        self.abort_if_null_socket(&h, "udp_recv_from");
        let buf = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", buf, UDP_CHUNK + 6));
        let payload = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 6", payload, buf));
        let sa = self.emit_sockaddr_buf();
        let salen = self.tmp_name();
        self.line(&format!("  {} = alloca i32", salen));
        self.line(&format!("  store i32 16, i32* {}", salen));
        let n = match self.target {
            Target::WindowsGnu => {
                self.declare_lazy("declare i32 @recvfrom(i8*, i8*, i32, i32, i8*, i32*)");
                let n = self.tmp_name();
                self.line(&format!("  {} = call i32 @recvfrom(i8* {}, i8* {}, i32 {}, i32 0, i8* {}, i32* {})", n, h, payload, UDP_CHUNK, sa, salen));
                n
            }
            Target::LinuxGnu => {
                self.declare_lazy("declare i64 @recvfrom(i32, i8*, i64, i32, i8*, i32*)");
                let fd = self.socket_handle_to_fd(&h);
                let n64 = self.tmp_name();
                self.line(&format!("  {} = call i64 @recvfrom(i32 {}, i8* {}, i64 {}, i32 0, i8* {}, i32* {})", n64, fd, payload, UDP_CHUNK, sa, salen));
                let n = self.tmp_name();
                self.line(&format!("  {} = trunc i64 {} to i32", n, n64));
                n
            }
        };
        let got = self.block_label("udp_recv_got");
        let none = self.block_label("udp_recv_none");
        let end = self.block_label("udp_recv_end");
        let nonneg = self.tmp_name();
        self.line(&format!("  {} = icmp sge i32 {}, 0", nonneg, n));
        self.line(&format!("  br i1 {}, label %{}, label %{}", nonneg, got, none));

        self.open_block(&got);
        // sender: sin_addr (offset 4, 4 bytes) then sin_port (offset 2, 2
        // bytes), both already in network byte order
        let ag = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 4", ag, sa));
        self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 4)", buf, ag));
        let pg = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 2", pg, sa));
        let dst = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 4", dst, buf));
        self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 2)", dst, pg));
        let n64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", n64, n));
        let total = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 6", total, n64));
        // give back the unused part of the 64 KB receive buffer
        self.declare_lazy("declare i8* @realloc(i8*, i64)");
        let shrunk = self.tmp_name();
        self.line(&format!("  {} = call i8* @realloc(i8* {}, i64 {})", shrunk, buf, total));
        let shrunk_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", shrunk_null, shrunk));
        let keep = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i8* {}, i8* {}", keep, shrunk_null, buf, shrunk));
        let wrapped = self.emit_bytes_wrap_raw_buf(&keep, &total);
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

    /// `udp_send_to(h: ptr, ip: str, port: int, data: Bytes) -> int`: the
    /// bytes sent, -1 on failure or a malformed address.
    pub(super) fn emit_udp_send_to(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 4 {
            self.err("udp_send_to(..) expects 4 arguments (handle, ip, port, data)", Span::dummy());
            return "i32 -1".into();
        }
        let hv = self.emit_expr(&args[0]);
        let h = self.untag(&hv, &Ty::Ptr);
        self.abort_if_null_socket(&h, "udp_send_to");
        let pv = self.emit_expr(&args[2]);
        let port = self.untag(&pv, &Ty::Int);
        let (addr, ok) = self.emit_ipv4_arg(&args[1], false);
        // the borrowed data pointer is read last, right before its use (see
        // `net_server`'s doc comment)
        let (data, len) = self.list_fields(&args[3], &Ty::U8);
        let go = self.block_label("udp_send_go");
        let bad = self.block_label("udp_send_bad");
        let end = self.block_label("udp_send_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", ok, go, bad));
        self.open_block(&bad);
        self.line(&format!("  br label %{}", end));
        self.open_block(&go);
        let sa = self.emit_sockaddr_for(&addr, &port);
        let n = match self.target {
            Target::WindowsGnu => {
                self.declare_lazy("declare i32 @sendto(i8*, i8*, i32, i32, i8*, i32)");
                let l32 = self.tmp_name();
                self.line(&format!("  {} = trunc i64 {} to i32", l32, len));
                let n = self.tmp_name();
                self.line(&format!("  {} = call i32 @sendto(i8* {}, i8* {}, i32 {}, i32 0, i8* {}, i32 16)", n, h, data, l32, sa));
                n
            }
            Target::LinuxGnu => {
                self.declare_lazy("declare i64 @sendto(i32, i8*, i64, i32, i8*, i32)");
                let fd = self.socket_handle_to_fd(&h);
                let n64 = self.tmp_name();
                self.line(&format!("  {} = call i64 @sendto(i32 {}, i8* {}, i64 {}, i32 0, i8* {}, i32 16)", n64, fd, data, len, sa));
                let n = self.tmp_name();
                self.line(&format!("  {} = trunc i64 {} to i32", n, n64));
                n
            }
        };
        let neg = self.tmp_name();
        self.line(&format!("  {} = icmp slt i32 {}, 0", neg, n));
        let res = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i32 -1, i32 {}", res, neg, n));
        let go_pred = self.current_label.clone();
        self.line(&format!("  br label %{}", end));
        self.open_block(&end);
        let r = self.tmp_name();
        self.line(&format!("  {} = phi i32 [ -1, %{} ], [ {}, %{} ]", r, bad, res, go_pred));
        format!("i32 {}", r)
    }

    /// `host_lookup(name: str) -> str`; see the module doc comment.
    pub(super) fn emit_host_lookup(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("host_lookup(..) expects 1 argument", Span::dummy());
            return "i8* null".into();
        };
        self.emit_wsa_startup();
        self.declare_lazy("declare i8* @gethostbyname(i8*)");
        let raw = self.emit_raw_str_ptr(arg);
        let p = self.emit_str_or_empty(&raw);
        let he = self.tmp_name();
        self.line(&format!("  {} = call i8* @gethostbyname(i8* {})", he, p));
        self.line(&format!("  call void @star_rc_release(i8* {})", raw));
        let have = self.block_label("host_lookup_have");
        let list = self.block_label("host_lookup_list");
        let join = self.block_label("host_lookup_join");
        let start = self.current_label.clone();
        let he_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", he_null, he));
        self.line(&format!("  br i1 {}, label %{}, label %{}", he_null, join, have));

        // struct hostent: h_addr_list sits at offset 24 on both x86-64 ABIs
        // (h_name, h_aliases, then two shorts on Windows or two ints on
        // glibc, padded to 8)
        self.open_block(&have);
        let lg = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 24", lg, he));
        let lpp = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i8***", lpp, lg));
        let lp = self.tmp_name();
        self.line(&format!("  {} = load i8**, i8*** {}", lp, lpp));
        let lp_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8** {}, null", lp_null, lp));
        self.line(&format!("  br i1 {}, label %{}, label %{}", lp_null, join, list));

        self.open_block(&list);
        let first = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", first, lp));
        let first_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", first_null, first));
        let read = self.block_label("host_lookup_read");
        self.line(&format!("  br i1 {}, label %{}, label %{}", first_null, join, read));
        self.open_block(&read);
        let ap = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", ap, first));
        let a = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", a, ap));
        self.line(&format!("  br label %{}", join));

        self.open_block(&join);
        let addr = self.tmp_name();
        self.line(&format!("  {} = phi i32 [ 0, %{} ], [ 0, %{} ], [ 0, %{} ], [ {}, %{} ]", addr, start, have, list, a, read));
        let found = self.tmp_name();
        self.line(&format!("  {} = phi i1 [ false, %{} ], [ false, %{} ], [ false, %{} ], [ true, %{} ]", found, start, have, list, read));
        self.emit_ipv4_to_str(&addr, &found)
    }
}

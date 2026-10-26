# LPC socket efuns -- todo.md HavokOS P1 #5: `havok/sockets.pike` (FluffOS
# PACKAGE_SOCKETS semantics) followed method for method, with its efun glue
# from `havok/efuns.pike` (efun_table.star codes 380-399): socket_create,
# socket_bind, socket_listen, socket_accept, socket_connect, socket_write,
# socket_close, socket_release, socket_acquire, socket_error,
# socket_address, socket_status, plus resolve() and dump_file_descriptors().
# Every return code, error text and callback order is the reference's;
# `sockdata.star` says how the socket table is kept.
#
# Where the reference reacts to Pike backend callbacks on non-blocking
# files (a listening port's accept callback, a stream's read/write/close
# callbacks, async_connect()'s completion, a UDP port's read callback), the
# driver's main loop polls: `net.star` net_poll() adds every open socket to
# its one tcp_wait_io() with the interest the reference's callbacks imply
# (read on a listener, a datagram socket or a connected stream; write while
# a connect is under way or output is queued), then hands what came back to
# sock_ready() here. The OS calls are the compiler's
# (`src/codegen/net_server.rs`, `src/codegen/net_sock.rs`): this milestone
# added a non-blocking connect, write readiness, UDP and address queries.
#
# One event per socket per pass, as the reference's backend runs one
# callback per ready file per round: a listener takes one pending
# connection, a datagram socket reads one datagram, a stream one read. A
# stream's read takes everything that has arrived (up to 1 MB), as a Pike
# read callback does, rather than one 16 KB tcp_recv_bytes(): at one chunk
# a pass, draining a stalled peer's 4 MB took 256 passes, where the
# reference needs a handful (the M7 socket cases caught it). LPC can close,
# create or destruct anything from a callback, so every step re-reads
# `self.socks[fd]` and checks it is still the same open socket.
#
# Callbacks are function names in the owner (any function, static ones
# included) or function pointers, run as their own top-level evaluations
# (the reference's drv->safe(), context "socket callback"): an error is
# reported to the master's error_handler() and doesn't reach whatever was
# running.
#
# Outbound connections are refused unless the config has `havok outbound
# sockets : 1` (sockets.pike outbound_allowed()), so a test boot never
# dials the real intermud routers; Dead Souls' daemons then see
# EECONNREFUSED, as on the reference.
#
# Deliberate deviations (NOTES.md #16, #17):
# - The two TLS modes the reference adds (STREAM_TLS 5, STREAM_TLS_BINARY 6)
#   can be created, but listening on one fails with EELISTEN (the
#   reference's answer when it has no certificate) and connecting one with
#   EECONNECT: Star has no TLS library yet (todo.md HavokOS P1 #6).
# - resolve() looks names up with the system resolver (`host_lookup()`),
#   which blocks the driver for as long as the lookup takes; the reference
#   uses Pike's asynchronous DNS client. A numeric address is answered with
#   itself as the name, without the reverse lookup the reference makes, since
#   a failing reverse lookup on Windows blocks for about five seconds (the
#   reference answers 127.0.0.1 with this network's reverse DNS name). Dead
#   Souls only resolves host names (its intermud and HTTP daemons). Names
#   resolve to IPv4 only, for resolve() and socket_connect() alike: the
#   reference connects "localhost" to ::1 first, so a socket_connect() to
#   "localhost <port>" of an IPv4 listener is refused there and connects
#   here. A name that doesn't resolve at all behaves as the reference's
#   does (EECONNECT, the socket left CONNECTING).
# And from deviation #7 (no NUL bytes in strings): a stream read or a
# datagram with a NUL byte in it reaches LPC cut short at the NUL.

import "value.star" as val
import "vm.star" as vm
import "efun_table.star" as et
import "sockdata.star" as sd

# socket_error() codes (sockets.pike EE*)
const EESUCCESS: i32 = 1
const EEMODENOTSUPP: i32 = -12
const EEBADF: i32 = -6
const EESECURITY: i32 = -7
const EEISBOUND: i32 = -8
const EEADDRINUSE: i32 = -9
const EEBIND: i32 = -10
const EENOADDR: i32 = -13
const EEISCONN: i32 = -14
const EELISTEN: i32 = -15
const EENOTLISTN: i32 = -16
const EEWOULDBLOCK: i32 = -17
const EEISLISTEN: i32 = -20
const EEBADADDR: i32 = -21
const EEALREADY: i32 = -22
const EECONNREFUSED: i32 = -23
const EECONNECT: i32 = -24
const EENOTCONN: i32 = -25
const EETYPENOTSUPP: i32 = -26
const EESENDTO: i32 = -27
const EESEND: i32 = -28
const EECALLBACK: i32 = -29
const EESOCKRLSD: i32 = -30
const EESOCKNOTRLSD: i32 = -31

fn mode_name(m: i32) -> str:
    let names = ["MUD", "STREAM", "DATAGRAM", "STREAM_BINARY", "DATAGRAM_BINARY", "STREAM_TLS", "STREAM_TLS_BINARY"]
    names[m]

fn state_name(s: i32) -> str:
    let names = ["CLOSED", "UNBOUND", "BOUND", "LISTEN", "DATA_XFER", "CONNECTING"]
    names[s]

# socket_error()'s texts (sockets.pike ERROR_STRINGS). Dead Souls greps the
# EECONNECT one for "Problem with connect".
fn error_text(code: i64) -> str:
    let c = (0 as i64) - code
    if code == (EESUCCESS as i64):
        return "No error"
    let mut texts: List<str> = [""]
    texts.push("Could not create the socket")
    texts.push("Could not set a socket option")
    texts.push("Could not make the socket non-blocking")
    texts.push("Every efun socket is already in use")
    texts.push("Socket descriptor is outside the valid range")
    texts.push("No such socket descriptor")
    texts.push("Not permitted by the socket security check")
    texts.push("The socket has a bound address already")
    texts.push("That address is taken by another socket")
    texts.push("Binding the socket failed")
    texts.push("Could not read the socket's local address")
    texts.push("This socket mode does not allow that operation")
    texts.push("The socket has no bound address")
    texts.push("The socket has a connection already")
    texts.push("Could not listen on the socket")
    texts.push("The socket is not accepting connections")
    texts.push("Nothing ready yet; the call would have to wait")
    texts.push("A signal interrupted the call")
    texts.push("Accepting the connection failed")
    texts.push("Not allowed on a socket that is listening")
    texts.push("The address is malformed (expected \"host port\")")
    texts.push("An earlier operation on the socket has not finished")
    texts.push("The remote end refused the connection")
    texts.push("Problem with connect: the connection could not be made")
    texts.push("The socket has no connection")
    texts.push("Cannot send a value of that type")
    texts.push("Sending the datagram failed")
    texts.push("Sending the data failed")
    texts.push("Output is queued; wait for the write callback")
    texts.push("The socket has been released already")
    texts.push("The socket was not released to this object")
    if c >= (1 as i64) and c <= (31 as i64):
        return texts[c as i32]
    "socket_error: invalid error number"

fn is_dgram_mode(m: i32) -> bool:
    m == sd::SM_DATAGRAM or m == sd::SM_DATAGRAM_BINARY

fn is_tls_mode(m: i32) -> bool:
    m == sd::SM_STREAM_TLS or m == sd::SM_STREAM_TLS_BINARY

# A dotted-decimal IPv4 address (what the compiler's socket builtins take);
# anything else is a host name to look up.
fn is_dotted_quad(s: str) -> bool:
    let b = bytes_from_str(s)
    let mut parts = 0
    let mut digits = 0
    for i in 0..b.len():
        let c = b[i] as i32
        if c >= 48 and c <= 57:
            digits += 1
            if digits > 3:
                return false
        elif c == 46 and digits > 0:
            parts += 1
            digits = 0
        else:
            return false
    parts == 3 and digits > 0

# big-endian 4-byte length (sprintf("%4c"))
fn push_be32(mut b: Bytes, n: i64) -> Bytes:
    b.push(((n >> 24) & (255 as i64)) as u8)
    b.push(((n >> 16) & (255 as i64)) as u8)
    b.push(((n >> 8) & (255 as i64)) as u8)
    b.push((n & (255 as i64)) as u8)
    b

impl vm::Vm:
    fn sock_open(self, fd: i32) -> bool:
        fd >= 0 and fd < self.socks.len() and self.socks[fd].open

    fn sock_owned_by(self, fd: i32, o: i32) -> bool:
        self.obj_of(self.socks[fd].owner) == o and o >= 0

    fn outbound_allowed(self) -> bool:
        if let Option::Some(v) = self.config.get("havok outbound sockets"):
            return vm::parse_int_prefix(v) != (0 as i64)
        false

    # The master's valid_socket(ob, what, ({ fd, owner, addr, port })); with
    # no master everything is allowed. An LPC error in it propagates.
    fn sock_valid(mut self, self_ob: i32, what: str, fd: i32, addr: str, port: i32) -> bool:
        if !self.alive(self.master_ob):
            return true
        let owner = if fd >= 0: self.socks[fd].owner else: self.obj_value(self_ob)
        let info = self.new_arr([val::Value::Int(fd as i64), owner, val::Value::Str(addr), val::Value::Int(port as i64)])
        let r = self.master_apply("valid_socket", [self.obj_value(self_ob), val::Value::Str(what), info], self_ob)
        if self.err:
            return false
        !val::is_zero(r)

    # Run a socket callback as its own top-level evaluation (sockets.pike
    # call_cb()): a name in the owner, or a function pointer with its owner
    # pushed; nothing when the owner is gone or there is no callback.
    fn sock_callback(mut self, fd: i32, cb: val::Value, args: List<val::Value>):
        let owner = self.obj_of(self.socks[fd].owner)
        if val::is_zero(cb) or owner < 0:
            return
        let ol = self.ostack.len()
        let sl = self.stack.len()
        self.begin_eval()
        match cb:
            val::Value::Str(name) ->
                let e = self.any_fn(owner, name)
                if e.prog >= 0:
                    self.run_entry(owner, e, "", args)
            _ ->
                self.run_fn_value(self.fn_owner(cb), cb, args)
        if self.err:
            self.report_error("socket callback")
        self.truncate_ostack(ol)
        self.truncate_stack(sl)
        self.end_eval()

    # Drop the OS side of a socket: queued output gets one last write
    # (socket_close()), then the stream, listener or datagram socket and any
    # unaccepted connections close.
    fn sock_shut(mut self, fd: i32, flush: bool):
        let h = self.socks[fd].handle
        if !is_null(h):
            if flush and !self.socks[fd].listener and self.socks[fd].outbuf.len() > self.socks[fd].out_off:
                tcp_send_bytes(h, self.socks[fd].outbuf, self.socks[fd].out_off)
            tcp_close(h)
        let p = self.socks[fd].pending
        for i in 0..p.len():
            tcp_close(p[i])
        self.socks[fd].handle = null_ptr()
        self.socks[fd].pending = List<ptr>()
        self.socks[fd].inbuf = Bytes()
        self.socks[fd].in_off = 0
        self.socks[fd].outbuf = Bytes()
        self.socks[fd].out_off = 0
        self.socks[fd].open = false
        self.socks[fd].state = sd::SS_CLOSED

    fn sock_forget_callbacks(mut self, fd: i32):
        self.socks[fd].read_cb = val::Value::Int(0 as i64)
        self.socks[fd].write_cb = val::Value::Int(0 as i64)
        self.socks[fd].close_cb = val::Value::Int(0 as i64)
        self.socks[fd].release_ob = val::Value::Int(0 as i64)

    # The peer closed, a write failed or a connect didn't complete
    # (sockets.pike handle_close()): the socket goes, then its close callback.
    fn sock_lost(mut self, fd: i32):
        if !self.sock_open(fd):
            return
        self.sock_shut(fd, false)
        self.sock_callback(fd, self.socks[fd].close_cb, [val::Value::Int(fd as i64)])
        self.sock_forget_callbacks(fd)

    # --- the efuns --------------------------------------------------------------

    fn efun_sock(mut self, code: i32, name: str, args: List<val::Value>, self_ob: i32) -> val::Value:
        if code == et::E_SOCKET_CREATE:
            return self.sock_create(args, self_ob)
        if code == et::E_SOCKET_ERROR:
            match self.arg(args, 0):
                val::Value::Int(c) ->
                    return val::Value::Str(error_text(c))
                _ ->
                    return val::Value::Str(error_text(0 as i64))
        if code == et::E_SOCKET_ADDRESS:
            return self.sock_address(args)
        if code == et::E_SOCKET_STATUS:
            return self.sock_status(args)
        if code == et::E_RESOLVE:
            return self.efun_resolve(args, self_ob)
        if code == et::E_DUMP_FILE_DESCRIPTORS:
            return val::Value::Int(0 as i64)
        let fdv = self.arg(args, 0)
        let mut fd = -1
        match fdv:
            val::Value::Int(x) ->
                if x >= (0 as i64) and x < (self.socks.len() as i64):
                    fd = x as i32
            _ -> 0
        let mut r = EEBADF
        if fd < 0 or !self.socks[fd].open:
            r = EEBADF
        elif code == et::E_SOCKET_ACQUIRE:
            r = self.sock_acquire(fd, args, self_ob)
        elif code == et::E_SOCKET_CLOSE:
            r = self.sock_close(fd, self_ob)
        elif !self.sock_owned_by(fd, self_ob):
            r = EESECURITY
        elif code == et::E_SOCKET_BIND:
            r = self.sock_bind(fd, args, self_ob)
        elif code == et::E_SOCKET_LISTEN:
            r = self.sock_listen(fd, args, self_ob)
        elif code == et::E_SOCKET_ACCEPT:
            r = self.sock_accept(fd, args, self_ob)
        elif code == et::E_SOCKET_CONNECT:
            r = self.sock_connect(fd, args, self_ob)
        elif code == et::E_SOCKET_WRITE:
            r = self.sock_write(fd, args)
        elif code == et::E_SOCKET_RELEASE:
            r = self.sock_release(fd, args, self_ob)
        if self.err:
            return val::Value::Undef
        val::Value::Int(r as i64)

    fn sock_create(mut self, args: List<val::Value>, self_ob: i32) -> val::Value:
        let mode = val::int_of(self.arg(args, 0))
        if mode < (0 as i64) or mode > (sd::SM_STREAM_TLS_BINARY as i64):
            return val::Value::Int(EEMODENOTSUPP as i64)
        # the number is taken before the security check, as in the reference
        let fd = self.socks.len()
        self.socks.push(sd::LSock(open = false, mode = mode as i32, owner = self.obj_value(self_ob), read_cb = self.arg(args, 1), close_cb = self.arg(args, 2)))
        if !self.sock_valid(self_ob, "create", fd, "", 0):
            if self.err:
                return val::Value::Undef
            self.sock_forget_callbacks(fd)
            return val::Value::Int(EESECURITY as i64)
        self.socks[fd].open = true
        val::Value::Int(fd as i64)

    fn sock_bind(mut self, fd: i32, args: List<val::Value>, self_ob: i32) -> i32:
        if self.socks[fd].state != sd::SS_UNBOUND:
            return EEISBOUND
        let port = val::int_of(self.arg(args, 1)) as i32
        let addr = self.str_arg(args, 2)
        let has_addr = self.is_str(self.arg(args, 2))
        if !self.sock_valid(self_ob, "bind", fd, addr, port):
            return EESECURITY
        if !self.sock_open(fd):
            return EEBADF
        self.socks[fd].local_port = port
        if has_addr:
            self.socks[fd].local_addr = addr
        if is_dgram_mode(self.socks[fd].mode):
            if has_addr and addr != "0.0.0.0" and !is_dotted_quad(addr):
                return EEBIND
            let u = udp_open(if has_addr and addr != "0.0.0.0": addr else: "", port)
            if is_null(u):
                return EEADDRINUSE
            self.socks[fd].handle = u
            self.socks[fd].local_port = tcp_local_port(u)
        self.socks[fd].state = sd::SS_BOUND
        EESUCCESS

    fn sock_listen(mut self, fd: i32, args: List<val::Value>, self_ob: i32) -> i32:
        let s = self.socks[fd]
        if is_dgram_mode(s.mode):
            return EEMODENOTSUPP
        if s.state == sd::SS_LISTEN:
            return EEISLISTEN
        if s.state != sd::SS_BOUND:
            return EENOADDR
        if !self.sock_valid(self_ob, "listen", fd, "", s.local_port):
            return EESECURITY
        if !self.sock_open(fd):
            return EEBADF
        if is_tls_mode(s.mode):
            self.log_msg(f"[sockets] TLS listen on {s.local_port}: no TLS support in this driver")
            return EELISTEN
        self.socks[fd].read_cb = self.arg(args, 1)
        let la = self.socks[fd].local_addr
        let ip = if la != "0.0.0.0": la else: ""
        let l = if ip == "" or is_dotted_quad(ip): tcp_listen_at(ip, s.local_port) else: null_ptr()
        if is_null(l):
            return EEADDRINUSE
        self.socks[fd].handle = l
        self.socks[fd].listener = true
        self.socks[fd].state = sd::SS_LISTEN
        EESUCCESS

    fn sock_accept(mut self, fd: i32, args: List<val::Value>, self_ob: i32) -> i32:
        let s = self.socks[fd]
        if is_dgram_mode(s.mode):
            return EEMODENOTSUPP
        if s.state != sd::SS_LISTEN:
            return EENOTLISTN
        if s.pending.len() == 0:
            return EEWOULDBLOCK
        let h = s.pending[0]
        let mut rest: List<ptr> = List<ptr>()
        for i in 1..s.pending.len():
            rest.push(s.pending[i])
        self.socks[fd].pending = rest
        let n = self.socks.len()
        let pip = tcp_peer_ip(h)
        let lip = tcp_local_ip(h)
        let pport = tcp_peer_port(h)
        let lport = tcp_local_port(h)
        self.socks.push(sd::LSock(mode = s.mode, state = sd::SS_DATA_XFER, owner = self.obj_value(self_ob), read_cb = self.arg(args, 1), write_cb = self.arg(args, 2), close_cb = s.close_cb, handle = h, remote_addr = if pip == "": "0.0.0.0" else: pip, remote_port = if pport < 0: 0 else: pport, local_addr = if lip == "": "0.0.0.0" else: lip, local_port = if lport < 0: 0 else: lport))
        n

    fn sock_connect(mut self, fd: i32, args: List<val::Value>, self_ob: i32) -> i32:
        let s = self.socks[fd]
        if is_dgram_mode(s.mode):
            return EEMODENOTSUPP
        if s.state == sd::SS_LISTEN:
            return EEISLISTEN
        if s.state == sd::SS_DATA_XFER or s.state == sd::SS_CONNECTING:
            return EEISCONN
        let av = self.arg(args, 1)
        if !self.is_str(av):
            return EEBADADDR
        let parsed = self.lpc_sscanf(av, val::Value::Str("%s %d"), 2)
        if self.err:
            return EEBADADDR
        let mut host = ""
        let mut port = 0
        let mut count = 0 as i64
        match parsed:
            val::Value::Arr(h) ->
                let items = self.arrs[h].items
                count = val::int_of(items[0])
                if count == (2 as i64):
                    host = match items[1]:
                        val::Value::Str(x) -> x
                        _ -> ""
                    port = val::int_of(items[2]) as i32
            _ -> 0
        if count != (2 as i64):
            return EEBADADDR
        if !self.sock_valid(self_ob, "connect", fd, host, port):
            return EESECURITY
        if !self.sock_open(fd):
            return EEBADF
        self.socks[fd].read_cb = self.arg(args, 2)
        self.socks[fd].write_cb = self.arg(args, 3)
        self.socks[fd].remote_addr = host
        self.socks[fd].remote_port = port
        if !self.outbound_allowed():
            self.log_msg(f"[sockets] outbound connect to {host}:{port} blocked by config")
            return EECONNREFUSED
        if is_tls_mode(s.mode):
            self.log_msg(f"[sockets] TLS connect to {host}:{port}: no TLS support in this driver")
            return EECONNECT
        self.socks[fd].state = sd::SS_CONNECTING
        self.socks[fd].blocked = true
        # a host name that doesn't resolve makes the reference's
        # async_connect() throw: EECONNECT, and the socket stays CONNECTING
        # for good, with no callback
        let ip = if is_dotted_quad(host): host else: host_lookup(host)
        if ip == "":
            self.socks[fd].stalled = true
            return EECONNECT
        # a connect the OS refuses at once fails the way a slow one does: on
        # the next pass, through the close callback
        self.socks[fd].handle = tcp_connect_start(ip, port)
        EESUCCESS

    # A MUD mode frame (sockets.pike mud_frame()): the value's
    # save_variable() text and a NUL, behind its big-endian length.
    fn mud_frame(mut self, v: val::Value) -> Bytes:
        let payload = self.save_variable_str(v)
        let mut b = push_be32(Bytes(), (len(payload) + 1) as i64)
        let pb = bytes_from_str(payload)
        for i in 0..pb.len():
            b.push(pb[i])
        b.push(0 as u8)
        b

    fn sock_write(mut self, fd: i32, args: List<val::Value>) -> i32:
        let s = self.socks[fd]
        let msg = self.arg(args, 1)
        let addr_v = self.arg(args, 2)
        if is_dgram_mode(s.mode):
            if !self.is_str(addr_v):
                return EENOADDR
            let parsed = self.lpc_sscanf(addr_v, val::Value::Str("%s %d"), 2)
            if self.err:
                return EEBADADDR
            let mut host = ""
            let mut port = 0
            match parsed:
                val::Value::Arr(h) ->
                    let items = self.arrs[h].items
                    if val::int_of(items[0]) != (2 as i64):
                        return EEBADADDR
                    host = match items[1]:
                        val::Value::Str(x) -> x
                        _ -> ""
                    port = val::int_of(items[2]) as i32
                _ ->
                    return EEBADADDR
            if is_null(self.socks[fd].handle):
                self.socks[fd].handle = udp_open("", 0)
            let mut data = Bytes()
            match msg:
                val::Value::Str(m) ->
                    data = bytes_from_str(m)
                _ ->
                    return EETYPENOTSUPP
            if s.mode == sd::SM_DATAGRAM:
                data.push(0 as u8)
            let ip = if is_dotted_quad(host): host else: host_lookup(host)
            if is_null(self.socks[fd].handle) or udp_send_to(self.socks[fd].handle, ip, port, data) < 0:
                return EESENDTO
            return EESUCCESS
        if s.state != sd::SS_DATA_XFER:
            return EENOTCONN
        if !val::is_zero(addr_v) or self.is_str(addr_v):
            return EEBADADDR
        if s.blocked:
            return EEALREADY
        let mut data = Bytes()
        if s.mode == sd::SM_MUD:
            if self.obj_of(msg) >= 0:
                return EETYPENOTSUPP
            data = self.mud_frame(msg)
            if self.err:
                return EESEND
        else:
            match msg:
                val::Value::Str(m) ->
                    data = bytes_from_str(m)
                val::Value::Arr(h) ->
                    let items = self.arrs[h].items
                    for i in 0..items.len():
                        match items[i]:
                            val::Value::Int(x) ->
                                data = push_be32(data, x)
                            val::Value::Undef ->
                                data = push_be32(data, 0 as i64)
                            _ -> 0
                _ ->
                    return EETYPENOTSUPP
        if data.len() == 0:
            return EESUCCESS
        let n = tcp_send_bytes(s.handle, data, 0)
        if n < 0:
            self.sock_lost(fd)
            return EESEND
        if n < data.len():
            self.socks[fd].outbuf = data
            self.socks[fd].out_off = n
            self.socks[fd].blocked = true
            return EECALLBACK
        EESUCCESS

    # socket_close(): the owner, or the master, may close it; no callback.
    fn sock_close(mut self, fd: i32, self_ob: i32) -> i32:
        if !self.sock_owned_by(fd, self_ob) and !(self_ob == self.master_ob and self_ob >= 0):
            return EESECURITY
        self.sock_shut(fd, true)
        self.sock_forget_callbacks(fd)
        EESUCCESS

    # socket_release(fd, ob, cb): offer the socket to ob through
    # ob->cb(fd, owner) (or a function pointer), run as its own evaluation;
    # ob takes it with socket_acquire() from inside that call.
    fn sock_release(mut self, fd: i32, args: List<val::Value>, self_ob: i32) -> i32:
        if self.obj_of(self.socks[fd].release_ob) >= 0:
            return EESOCKRLSD
        let ob = self.arg(args, 1)
        let cb = self.arg(args, 2)
        self.socks[fd].release_ob = ob
        let fdv = val::Value::Int(fd as i64)
        let ol = self.ostack.len()
        let sl = self.stack.len()
        self.begin_eval()
        match cb:
            val::Value::Str(fname) ->
                self.call_other_value(self_ob, ob, cb, [fdv, self.obj_value(self_ob)])
            val::Value::Fn(h) ->
                self.call_value(cb, [fdv, self.obj_value(self_ob)])
            _ -> 0
        if self.err:
            self.report_error("socket_release")
        self.truncate_ostack(ol)
        self.truncate_stack(sl)
        self.end_eval()
        if self.lpc_eq(self.socks[fd].release_ob, ob):
            self.socks[fd].release_ob = val::Value::Int(0 as i64)
        EESUCCESS

    fn sock_acquire(mut self, fd: i32, args: List<val::Value>, self_ob: i32) -> i32:
        let ro = self.obj_of(self.socks[fd].release_ob)
        if ro < 0 or ro != self_ob:
            return EESOCKNOTRLSD
        self.socks[fd].owner = self.obj_value(self_ob)
        self.socks[fd].release_ob = val::Value::Int(0 as i64)
        self.socks[fd].read_cb = self.arg(args, 1)
        self.socks[fd].write_cb = self.arg(args, 2)
        self.socks[fd].close_cb = self.arg(args, 3)
        EESUCCESS

    # socket_address(fd or interactive object, [want_local]): "addr port", 0
    # when there is no such socket or connection.
    fn sock_address(mut self, args: List<val::Value>) -> val::Value:
        let what = self.arg(args, 0)
        let want_local = self.truthy(self.arg(args, 1))
        let zero = val::Value::Int(0 as i64)
        let o = self.obj_of(what)
        if o >= 0:
            let ci = self.user_conn(o)
            if ci < 0:
                return zero
            if want_local:
                return val::Value::Str(f"127.0.0.1 {self.conns[ci].local_port}")
            return val::Value::Str(f"{self.conns[ci].ip} 0")
        let mut fd = -1
        match what:
            val::Value::Int(x) ->
                if x >= (0 as i64) and x < (self.socks.len() as i64):
                    fd = x as i32
            _ -> 0
        if fd < 0 or !self.socks[fd].open:
            return zero
        let s = self.socks[fd]
        if want_local:
            return val::Value::Str(f"{s.local_addr} {s.local_port}")
        val::Value::Str(f"{s.remote_addr} {s.remote_port}")

    fn sock_row(mut self, fd: i32) -> val::Value:
        if !self.socks[fd].open:
            return self.new_arr([val::Value::Int((0 - 1) as i64), val::Value::Str("CLOSED"), val::Value::Str("MUD"), val::Value::Str("0.0.0.0.0"), val::Value::Str("0.0.0.0.0"), val::Value::Int(0 as i64)])
        let s = self.socks[fd]
        let o = self.obj_of(s.owner)
        self.new_arr([val::Value::Int(fd as i64), val::Value::Str(state_name(s.state)), val::Value::Str(mode_name(s.mode)), val::Value::Str(f"{s.local_addr}.{s.local_port}"), val::Value::Str(f"{s.remote_addr}.{s.remote_port}"), self.obj_value(o)])

    # socket_status(): a row per socket number ever handed out;
    # socket_status(fd) just that row (FluffOS goes by the argument count).
    fn sock_status(mut self, args: List<val::Value>) -> val::Value:
        if args.len() > 0:
            match args[0]:
                val::Value::Int(x) ->
                    if x < (0 as i64) or x >= (self.socks.len() as i64):
                        return val::Value::Int(0 as i64)
                    return self.sock_row(x as i32)
                val::Value::Undef ->
                    return if self.socks.len() > 0: self.sock_row(0) else: val::Value::Int(0 as i64)
                _ ->
                    return val::Value::Int(0 as i64)
        let mut rows: List<val::Value> = List<val::Value>()
        for i in 0..self.socks.len():
            rows.push(self.sock_row(i))
        self.new_arr(rows)

    # resolve(addr, callback): callback(name, ip, key) on the driver's next
    # pass (see the header for the lookup itself); returns the key.
    fn efun_resolve(mut self, args: List<val::Value>, self_ob: i32) -> val::Value:
        let a = self.arg(args, 0)
        if !self.is_str(a):
            self.fail("Bad argument 1 to resolve()\n")
            return val::Value::Undef
        let addr = self.str_arg(args, 0)
        self.resolve_seq += 1
        let key = self.resolve_seq
        let ab = bytes_from_str(addr)
        let numeric = ab.len() > 0 and (ab[0] as i32) >= 48 and (ab[0] as i32) <= 57
        let ip = if numeric: addr else: host_lookup(addr)
        self.resolves.push(sd::PendingResolve(ob = self.obj_value(self_ob), fun = self.arg(args, 1), name = addr, ip = ip, has_ip = ip != "", key = key))
        val::Value::Int(key as i64)

    # The resolve() answers waiting when this pass began.
    fn run_resolves(mut self):
        if self.resolves.len() == 0:
            return
        let due = self.resolves
        self.resolves = List<sd::PendingResolve>()
        for i in 0..due.len():
            let r = due[i]
            let ob = self.obj_of(r.ob)
            if ob < 0:
                continue
            let args = [val::Value::Str(r.name), if r.has_ip: val::Value::Str(r.ip) else: val::Value::Int(0 as i64), val::Value::Int(r.key as i64)]
            let ol = self.ostack.len()
            let sl = self.stack.len()
            self.begin_eval()
            match r.fun:
                val::Value::Str(fname) ->
                    let e = self.any_fn(ob, fname)
                    if e.prog >= 0:
                        self.run_entry(ob, e, "", args)
                val::Value::Fn(h) ->
                    if self.fns[h].owner < 0 or self.fn_owner(r.fun) >= 0:
                        self.run_fn_value(ob, r.fun, args)
                _ -> 0
            if self.err:
                self.report_error("resolve callback")
            self.truncate_ostack(ol)
            self.truncate_stack(sl)
            self.end_eval()

    # Destructing an object closes the sockets it owns (sockets.pike
    # forget_object()), without callbacks.
    fn sock_forget(mut self, o: i32):
        for fd in 0..self.socks.len():
            if self.socks[fd].open and self.obj_of(self.socks[fd].owner) == o:
                self.sock_shut(fd, true)
                self.sock_forget_callbacks(fd)

    # --- the main loop's part -------------------------------------------------

    # What net_poll() should wait for on socket fd: 1 read, 4 write, 0 not
    # polled (no OS socket yet, or a failed connect handled at once).
    fn sock_interest(self, fd: i32) -> i32:
        let s = self.socks[fd]
        if !s.open or is_null(s.handle):
            return 0
        if s.listener or is_dgram_mode(s.mode):
            return 1
        if s.state == sd::SS_CONNECTING:
            return 4
        if s.outbuf.len() > s.out_off:
            return 5
        1

    # A connect with no OS socket (the host didn't resolve, or the OS
    # refused at once) fails on the pass after socket_connect(), and a pass
    # must come at once when one is waiting.
    fn sock_work_waiting(self) -> bool:
        # find_files() answers (ext.star) wait for a pass too
        if self.resolves.len() > 0 or self.finds.len() > 0:
            return true
        for fd in 0..self.socks.len():
            let s = self.socks[fd]
            if s.open and s.state == sd::SS_CONNECTING and is_null(s.handle) and !s.stalled:
                return true
        false

    fn sock_fail_dead_connects(mut self):
        for fd in 0..self.socks.len():
            let k = self.socks[fd]
            if k.open and k.state == sd::SS_CONNECTING and is_null(k.handle) and !k.stalled:
                self.sock_lost(fd)

    # tcp_wait_io() reported `flags` (1 readable, 2 error/hang-up, 4
    # writable) for socket fd, polled with OS socket `h`.
    fn sock_ready(mut self, fd: i32, h: ptr, flags: i32):
        if !self.sock_open(fd) or self.socks[fd].handle != h:
            return
        let s = self.socks[fd]
        if s.listener:
            let c = tcp_accept(h)
            if is_null(c):
                return
            self.socks[fd].pending.push(c)
            self.sock_callback(fd, self.socks[fd].read_cb, [val::Value::Int(fd as i64)])
            return
        if is_dgram_mode(s.mode):
            self.sock_datagram(fd)
            return
        if s.state == sd::SS_CONNECTING:
            if tcp_sock_error(h) != 0 or (flags & 4) == 0:
                self.sock_lost(fd)
                return
            self.socks[fd].state = sd::SS_DATA_XFER
            let lip = tcp_local_ip(h)
            self.socks[fd].local_addr = if lip == "": "0.0.0.0" else: lip
            let lp = tcp_local_port(h)
            self.socks[fd].local_port = if lp < 0: 0 else: lp
            self.socks[fd].blocked = false
            self.sock_callback(fd, self.socks[fd].write_cb, [val::Value::Int(fd as i64)])
            return
        if (flags & 4) != 0 and s.outbuf.len() > s.out_off:
            self.sock_writable(fd)
            if !self.sock_open(fd) or self.socks[fd].handle != h:
                return
        if (flags & 3) != 0:
            let mut d = tcp_recv_bytes(h)
            if d.len() == 0:
                self.sock_lost(fd)
                return
            # the reference's read callback gets everything that has arrived,
            # where one tcp_recv_bytes() takes at most 16 KB: read on while
            # more is waiting (a zero-timeout poll tells "nothing yet" from
            # "closed", which both read as empty), up to 1 MB a pass
            let mut closed = false
            let one: List<ptr> = [h]
            let mut chunks = 1
            while chunks < 64:
                let rr = tcp_wait(one, 0)
                if rr.len() == 0 or (rr[0] as i32) == 0:
                    break
                let more = tcp_recv_bytes(h)
                if more.len() == 0:
                    closed = true
                    break
                for i in 0..more.len():
                    d.push(more[i])
                chunks += 1
            self.sock_input(fd, d)
            if closed and self.sock_open(fd) and self.socks[fd].handle == h:
                self.sock_lost(fd)

    # sockets.pike handle_writable(): write what's queued; once all of it is
    # gone, a blocked socket's write callback.
    fn sock_writable(mut self, fd: i32):
        let h = self.socks[fd].handle
        let n = tcp_send_bytes(h, self.socks[fd].outbuf, self.socks[fd].out_off)
        if n < 0:
            self.sock_lost(fd)
            return
        self.socks[fd].out_off = self.socks[fd].out_off + n
        if self.socks[fd].out_off < self.socks[fd].outbuf.len():
            return
        self.socks[fd].outbuf = Bytes()
        self.socks[fd].out_off = 0
        if self.socks[fd].blocked:
            self.socks[fd].blocked = false
            self.sock_callback(fd, self.socks[fd].write_cb, [val::Value::Int(fd as i64)])

    # sockets.pike handle_read(): MUD mode delivers each complete frame,
    # decoded (its text if it doesn't decode); streams deliver what arrived.
    fn sock_input(mut self, fd: i32, d: Bytes):
        if self.socks[fd].mode != sd::SM_MUD:
            self.sock_callback(fd, self.socks[fd].read_cb, [val::Value::Int(fd as i64), val::Value::Str(str_from_bytes(d))])
            return
        for i in 0..d.len():
            self.socks[fd].inbuf.push(d[i])
        while self.sock_open(fd):
            let b = self.socks[fd].inbuf
            let off = self.socks[fd].in_off
            if b.len() - off < 4:
                break
            let n = ((b[off] as i32) << 24) | ((b[off + 1] as i32) << 16) | ((b[off + 2] as i32) << 8) | (b[off + 3] as i32)
            if n < 0 or b.len() - off - 4 < n:
                break
            let mut end = off + 4 + n
            if n > 0 and (b[end - 1] as i32) == 0:
                end -= 1
            let mut pb = Bytes()
            for k in (off + 4)..end:
                pb.push(b[k])
            self.socks[fd].in_off = off + 4 + n
            if self.socks[fd].in_off == b.len():
                self.socks[fd].inbuf = Bytes()
                self.socks[fd].in_off = 0
            let text = str_from_bytes(pb)
            let mut v = self.restore_variable_str(text)
            if self.err:
                self.clear_err()
                v = val::Value::Str(text)
            self.sock_callback(fd, self.socks[fd].read_cb, [val::Value::Int(fd as i64), v])

    # One datagram: read callback (fd, data, "ip port"), a DATAGRAM mode
    # datagram's trailing NUL dropped.
    fn sock_datagram(mut self, fd: i32):
        let g = udp_recv_from(self.socks[fd].handle)
        if g.len() < 6:
            return
        let ip = f"{g[0] as i32}.{g[1] as i32}.{g[2] as i32}.{g[3] as i32}"
        let port = ((g[4] as i32) << 8) | (g[5] as i32)
        let mut end = g.len()
        if self.socks[fd].mode == sd::SM_DATAGRAM and end > 6 and (g[end - 1] as i32) == 0:
            end -= 1
        let mut pb = Bytes()
        for k in 6..end:
            pb.push(g[k])
        self.sock_callback(fd, self.socks[fd].read_cb, [val::Value::Int(fd as i64), val::Value::Str(str_from_bytes(pb)), val::Value::Str(f"{ip} {port}")])

    # The case runner's socket hooks (efun_table.star test_efun_codes(); the
    # reference's are in tools/ref_cases.pike):
    #   test_sock_pump(ob, fn)  run the driver's network passes (10 ms each)
    #                           until ob->fn() is true or about two seconds
    #                           pass; returns ob->fn()'s last answer. With
    #                           ob 0, ten passes of 20 ms.
    #   test_config(key, val)   set a config value (as a string)
    fn efun_sock_test(mut self, code: i32, args: List<val::Value>, self_ob: i32) -> val::Value:
        if code == et::E_TEST_CONFIG:
            self.config.insert(self.str_arg(args, 0), self.str_arg(args, 1))
            return val::Value::Int(0 as i64)
        let target = self.arg(args, 0)
        if self.obj_of(target) < 0:
            for i in 0..10:
                self.net_pass(20)
            return val::Value::Int(0 as i64)
        let fname = self.arg(args, 1)
        let mut last = val::Value::Int(0 as i64)
        for i in 0..200:
            last = self.call_other_value(self_ob, target, fname, List<val::Value>())
            if self.err:
                return val::Value::Undef
            if self.truthy(last):
                break
            self.net_pass(10)
        last

    # One pass of the main loop's network half, for the hooks: wait, handle
    # sockets and connections, run resolve() answers.
    fn net_pass(mut self, ms: i32):
        self.net_poll(ms)

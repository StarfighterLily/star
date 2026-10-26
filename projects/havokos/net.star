# The network layer -- todo.md HavokOS M6: `havok/net.pike` (telnet, user
# connections, the session start) followed method for method, on top of the
# compiler's server-socket builtins (`src/codegen/net_server.rs`, added for
# this milestone: Star had only client sockets, and its FFI can't build the
# `sockaddr_in` that `bind` needs, NOTES.md constraint #8).
#
# Shape. A connection's state is a `conn.star` Conn in `Vm.conns`; every
# operation is a `Vm` method taking the connection's index, because nearly
# all of them can run LPC (an apply on the user for each telnet event, the
# input_to callback, the command) and LPC can do anything to any connection
# meanwhile -- exec() it to another object, close it, destruct its user. So
# nothing here holds a copy of a Conn across an LPC call; fields are read
# through `self.conns[ci]` again afterwards, and `closed` is checked the way
# the reference checks it.
#
# Where the reference reacts to Pike backend callbacks (read_cb, write_cb,
# close_cb on a non-blocking socket), the driver's main loop (`boot.star`)
# calls `net_poll()`: one `tcp_wait()` over the listeners and every
# connection, bounded by the time the next call_out or heart beat slot is
# due, then accept, read and flush. Output is queued per connection and
# written at the end of each pass, or at once on close; the bytes, and their
# order, are the reference's.
#
# Telnet follows docs/telnet-spec.md and the reference exactly, with two
# deliberate differences (NOTES.md deviations #13, #14):
# - No MCCP: COMPRESS2 is never offered and is refused (WONT), as with the
#   reference's `havok mccp : 0`. Star has no zlib, and a compression stream
#   is an optimisation clients do without.
# - LPC strings are byte strings here (value.star), not Pike's wide strings,
#   so a UTF-8 connection (CHARSET accepted) passes text through unchanged
#   both ways: what a client sends arrives as its UTF-8 bytes, and the
#   mudlib's text goes out as it is. The reference converts both ways
#   (Latin-1 text reaches a UTF-8 client re-encoded).
#
# Connections with no socket (`sock` null) exist only for the case runner's
# test_tel_* hooks (efuns_net.star): their output stays in `outbuf` for the
# test to drain, and input is fed straight to conn_input().

import "value.star" as val
import "vm.star" as vm
import "conn.star" as cn

const IAC: i32 = 255
const DONT: i32 = 254
const DO: i32 = 253
const WONT: i32 = 252
const WILL: i32 = 251
const SB: i32 = 250
const GA: i32 = 249
const SE: i32 = 240
const EOR_MARK: i32 = 239

const TELOPT_ECHO: i32 = 1
const TELOPT_SGA: i32 = 3
const TELOPT_TTYPE: i32 = 24
const TELOPT_EOR: i32 = 25
const TELOPT_NAWS: i32 = 31
const TELOPT_NEW_ENVIRON: i32 = 39
const TELOPT_CHARSET: i32 = 42
const TELOPT_MSDP: i32 = 69
const TELOPT_MSSP: i32 = 70
const TELOPT_COMPRESS2: i32 = 86
const TELOPT_MSP: i32 = 90
const TELOPT_MXP: i32 = 91
const TELOPT_ZMP: i32 = 93
const TELOPT_GMCP: i32 = 201

const TTYPE_IS: i32 = 0
const TTYPE_SEND: i32 = 1
const ENV_IS: i32 = 0
const ENV_SEND: i32 = 1
const ENV_INFO: i32 = 2
const ENV_VAR: i32 = 0
const ENV_VALUE: i32 = 1
const ENV_ESC: i32 = 2
const ENV_USERVAR: i32 = 3
const MSSP_VAR: i32 = 1
const MSSP_VAL: i32 = 2
const MSDP_VAR: i32 = 1
const MSDP_VAL: i32 = 2
const MSDP_TABLE_OPEN: i32 = 3
const MSDP_TABLE_CLOSE: i32 = 4
const MSDP_ARRAY_OPEN: i32 = 5
const MSDP_ARRAY_CLOSE: i32 = 6
const CHARSET_REQUEST: i32 = 1
const CHARSET_ACCEPTED: i32 = 2
const CHARSET_REJECTED: i32 = 3
# TTYPE answers asked for (MTTS: name, terminal, "MTTS n", ...)
const MAX_TTYPE: i32 = 4
# longest subnegotiation kept
const MAX_SB: i32 = 65536

# telnet parser states
const TS_DATA: i32 = 0
const TS_IAC: i32 = 1
const TS_OPT: i32 = 2
const TS_SB: i32 = 3
const TS_SB_IAC: i32 = 4

# input_to() flags (FluffOS)
const I_NOECHO: i32 = 1

# Options this side performs (WILL) and asks the client to perform (DO).
# COMPRESS2 is left out: see the header.
fn local_opt(o: i32) -> bool:
    o == TELOPT_ECHO or o == TELOPT_EOR or o == TELOPT_CHARSET or o == TELOPT_MSSP or o == TELOPT_MXP or o == TELOPT_ZMP or o == TELOPT_GMCP or o == TELOPT_MSDP or o == TELOPT_MSP

fn remote_opt(o: i32) -> bool:
    o == TELOPT_TTYPE or o == TELOPT_NAWS or o == TELOPT_NEW_ENVIRON or o == TELOPT_CHARSET or o == TELOPT_MXP or o == TELOPT_GMCP

fn upper_ascii(s: str) -> str:
    let b = bytes_from_str(s)
    let mut o: Bytes = Bytes()
    for i in 0..b.len():
        let c = b[i] as i32
        if c >= 97 and c <= 122:
            o.push((c - 32) as u8)
        else:
            o.push(b[i])
    str_from_bytes(o)

fn bytes_sub(b: Bytes, a: i32, e: i32) -> Bytes:
    let mut o: Bytes = Bytes()
    let mut i = a
    while i < e:
        o.push(b[i])
        i += 1
    o

# String.trim_all_whites() is empty
fn all_white(s: str) -> bool:
    let b = bytes_from_str(s)
    for i in 0..b.len():
        let c = b[i] as i32
        if c != 32 and c != 9 and c != 10 and c != 13:
            return false
    true

# Text without the bytes MSSP/MSDP structure uses (0 .. `top`).
fn strip_low(s: str, top: i32) -> str:
    let b = bytes_from_str(s)
    let mut o: Bytes = Bytes()
    for i in 0..b.len():
        if (b[i] as i32) > top:
            o.push(b[i])
    str_from_bytes(o)

impl vm::Vm:
    # --- the connection table ----------------------------------------------------

    # A new connection in a free slot (or a new one); its index.
    fn conn_new(mut self, sock: ptr, port: i32) -> i32:
        self.conn_seq += 1
        let c = cn::Conn(sock = sock, seq = self.conn_seq, local_port = port, last_input = vm::epoch_now())
        for i in 0..self.conns.len():
            if !self.conns[i].alive:
                self.conns[i] = c
                return i
        self.conns.push(c)
        self.conns.len() - 1

    fn conn_ok(self, ci: i32) -> bool:
        ci >= 0 and ci < self.conns.len() and self.conns[ci].alive and !self.conns[ci].closed

    # The connection of an object, or -1 (user_conn()).
    fn user_conn(self, o: i32) -> i32:
        if !self.alive(o):
            return -1
        let ci = self.objs[o].conn
        if ci >= 0 and self.conn_ok(ci) and self.conns[ci].user == o:
            return ci
        -1

    # Whether the object is interactive (has a connection attached).
    fn is_interactive(self, o: i32) -> bool:
        self.user_conn(o) >= 0

    # users(): every object driven by a live connection, oldest first.
    fn users_list(self) -> List<i32>:
        let mut cis: List<i32> = List<i32>()
        for i in 0..self.conns.len():
            if self.conn_ok(i) and self.user_conn(self.conns[i].user) == i:
                cis.push(i)
        # by connection order (insertion sort: a few hundred at most)
        let mut a = 1
        while a < cis.len():
            let x = cis[a]
            let mut b = a - 1
            while b >= 0 and self.conns[cis[b]].seq > self.conns[x].seq:
                cis[b + 1] = cis[b]
                b -= 1
            cis[b + 1] = x
            a += 1
        let mut out: List<i32> = List<i32>()
        for i in 0..cis.len():
            out.push(self.conns[cis[i]].user)
        out

    fn count_traffic(mut self, port: i32, dir: i32, n: i32):
        let mut k = -1
        for i in 0..self.traffic_ports.len():
            if self.traffic_ports[i] == port:
                k = i
        if k < 0:
            self.traffic_ports.push(port)
            for j in 0..4:
                self.traffic.push(0 as i64)
            k = self.traffic_ports.len() - 1
        self.traffic[k * 4 + dir * 2] = self.traffic[k * 4 + dir * 2] + (1 as i64)
        self.traffic[k * 4 + dir * 2 + 1] = self.traffic[k * 4 + dir * 2 + 1] + (n as i64)

    # --- output --------------------------------------------------------------------

    fn raw_byte(mut self, ci: i32, c: i32):
        self.conns[ci].outbuf.push(c as u8)

    # IAC <verb> <opt>
    fn tel_cmd(mut self, ci: i32, verb: i32, opt: i32):
        if !self.conn_ok(ci):
            return
        self.raw_byte(ci, IAC)
        self.raw_byte(ci, verb)
        self.raw_byte(ci, opt)

    # IAC SB <opt> <data, 0xff doubled> IAC SE
    fn tel_sub(mut self, ci: i32, opt: i32, data: Bytes):
        if !self.conn_ok(ci):
            return
        self.raw_byte(ci, IAC)
        self.raw_byte(ci, SB)
        self.raw_byte(ci, opt)
        for i in 0..data.len():
            self.conns[ci].outbuf.push(data[i])
            if (data[i] as i32) == IAC:
                self.raw_byte(ci, IAC)
        self.raw_byte(ci, IAC)
        self.raw_byte(ci, SE)

    # Text for the user (Connection send()): `\r\n` goes out as `\n` and a
    # lone `\n` as `\r\n` -- the reference's replace(s, ({ "\r\n", "\n" }),
    # ({ "\n", "\r\n" })), which swaps the two rather than leaving `\r\n`
    # alone as its comment says; this is what it sends -- and a 0xff byte is
    # doubled (IAC IAC). The snooper gets a copy first.
    fn conn_send(mut self, ci: i32, s: str):
        if !self.conn_ok(ci):
            return
        if !val::is_zero(self.conns[ci].snooped_by):
            self.deliver_snoop(ci, s)
            if !self.conn_ok(ci):
                return
        let b = bytes_from_str(s)
        let n = b.len()
        let mut i = 0
        while i < n:
            let c = b[i] as i32
            if c == 13 and i + 1 < n and (b[i + 1] as i32) == 10:
                self.raw_byte(ci, 10)
                i += 2
                continue
            if c == 10:
                self.raw_byte(ci, 13)
                self.raw_byte(ci, 10)
            elif c == IAC:
                self.raw_byte(ci, IAC)
                self.raw_byte(ci, IAC)
            else:
                self.conns[ci].outbuf.push(b[i])
            i += 1

    # The end of a prompt: IAC EOR once the client asked for EOR, else IAC GA.
    fn mark_prompt(mut self, ci: i32):
        if !self.conn_ok(ci):
            return
        self.raw_byte(ci, IAC)
        self.raw_byte(ci, if self.conns[ci].local_on.contains(TELOPT_EOR): EOR_MARK else: GA)

    # Write what is queued; false when the socket broke. A connection with no
    # socket keeps its output for the test hooks.
    fn conn_flush(mut self, ci: i32) -> bool:
        if ci < 0 or ci >= self.conns.len() or !self.conns[ci].alive:
            return true
        let s = self.conns[ci].sock
        if is_null(s):
            return true
        while self.conns[ci].out_off < self.conns[ci].outbuf.len():
            let n = tcp_send_bytes(s, self.conns[ci].outbuf, self.conns[ci].out_off)
            if n < 0:
                self.conns[ci].outbuf = Bytes()
                self.conns[ci].out_off = 0
                return false
            if n == 0:
                break
            self.conns[ci].out_off = self.conns[ci].out_off + n
            self.count_traffic(self.conns[ci].local_port, 1, n)
        if self.conns[ci].out_off >= self.conns[ci].outbuf.len():
            self.conns[ci].outbuf = Bytes()
            self.conns[ci].out_off = 0
        elif self.conns[ci].out_off > 65536:
            self.conns[ci].outbuf = bytes_sub(self.conns[ci].outbuf, self.conns[ci].out_off, self.conns[ci].outbuf.len())
            self.conns[ci].out_off = 0
        true

    # Everything queued on a socketless connection, taken (test hooks).
    fn conn_take_output(mut self, ci: i32) -> Bytes:
        if ci < 0 or ci >= self.conns.len():
            return Bytes()
        let b = bytes_sub(self.conns[ci].outbuf, self.conns[ci].out_off, self.conns[ci].outbuf.len())
        self.conns[ci].outbuf = Bytes()
        self.conns[ci].out_off = 0
        b

    # --- opening and closing ---------------------------------------------------------

    # Connection create(): the offers, in the reference's order.
    fn conn_offer(mut self, ci: i32):
        let dos = [TELOPT_TTYPE, TELOPT_NAWS, TELOPT_NEW_ENVIRON]
        for i in 0..dos.len():
            self.conns[ci].remote_asked.insert(dos[i])
            self.tel_cmd(ci, DO, dos[i])
        let wills = [TELOPT_MSSP, TELOPT_GMCP, TELOPT_MSDP, TELOPT_MSP, TELOPT_ZMP, TELOPT_MXP, TELOPT_EOR, TELOPT_CHARSET]
        for i in 0..wills.len():
            self.conns[ci].local_asked.insert(wills[i])
            self.tel_cmd(ci, WILL, wills[i])

    # The pending input_to's values go; its function might be all that
    # holds some object.
    fn clear_input_to(mut self, ci: i32):
        self.conns[ci].input_fn = val::Value::Int(0 as i64)
        self.conns[ci].input_owner = val::Value::Int(0 as i64)
        self.conns[ci].input_args = List<val::Value>()

    fn conn_shut(mut self, ci: i32):
        self.conn_flush(ci)
        self.conns[ci].closed = true
        self.conns[ci].snooped_by = val::Value::Int(0 as i64)
        self.clear_input_to(ci)
        let s = self.conns[ci].sock
        if !is_null(s):
            tcp_close(s)
            self.conns[ci].sock = null_ptr()
        self.conns[ci].alive = false

    # Connection close(): the user, if still attached, goes net-dead, with
    # this_player() 0 afterwards, as in the reference.
    fn conn_close(mut self, ci: i32, why: str):
        if !self.conn_ok(ci):
            return
        let u = self.conns[ci].user
        self.conn_shut(ci)
        self.conns[ci].user = -1
        if self.alive(u) and self.objs[u].conn == ci:
            self.objs[u].conn = -1
            self.cur_player = u
            self.safe_apply(u, "net_dead", List<val::Value>(), "net_dead")
            self.cur_player = -1

    # The user object was destructed (driver destruct_object()).
    fn conn_destructed(mut self, ci: i32):
        if ci < 0 or ci >= self.conns.len() or !self.conns[ci].alive:
            return
        self.conns[ci].user = -1
        self.conn_shut(ci)

    # A new connection (net.pike start_session()): the master's connect(port)
    # names the object to drive, which gets logon().
    fn start_session(mut self, ci: i32):
        let port = self.conns[ci].local_port
        self.log_msg(f"[net] connection from {self.conns[ci].ip}")
        let ol = self.ostack.len()
        let sl = self.stack.len()
        self.begin_eval()
        let r = self.master_apply("connect", [val::Value::Int(port as i64)], -1)
        if !self.err:
            let u = self.obj_of(r)
            if u < 0:
                self.conn_send(ci, "Connection refused.\n")
                self.conn_close(ci, "no connect object")
            else:
                self.attach_user(ci, u)
                self.cur_player = u
                self.cur_interactive = u
                self.apply_value(u, "logon", List<val::Value>())
        if self.err:
            self.report_error("logon")
        self.truncate_ostack(ol)
        self.truncate_stack(sl)
        self.end_eval()
        if self.conn_ok(ci):
            self.mark_prompt(ci)
        self.cur_player = -1
        self.cur_interactive = -1

    fn attach_user(mut self, ci: i32, u: i32):
        self.conns[ci].user = u
        self.objs[u].conn = ci
        self.objs[u].once_interactive = true

    # exec(to, from): `from`'s connection moves to `to`; 0 if `from` has none
    # or `to` already has another.
    fn net_exec(mut self, to: i32, from: i32) -> bool:
        let ci = self.user_conn(from)
        if ci < 0:
            return false
        let tci = self.user_conn(to)
        if tci >= 0 and tci != ci:
            return false
        self.objs[from].conn = -1
        self.attach_user(ci, to)
        if self.cur_player == from:
            self.cur_player = to
        if self.cur_interactive == from:
            self.cur_interactive = to
        true

    # --- snoop -------------------------------------------------------------------------

    # snooper->receive_snoop(text); errors there are the snooper's problem
    fn deliver_snoop(mut self, ci: i32, s: str):
        let by = self.obj_of(self.conns[ci].snooped_by)
        if by < 0:
            self.conns[ci].snooped_by = val::Value::Int(0 as i64)
            return
        # the snooper writing back to us
        if self.conns[ci].in_snoop:
            return
        self.conns[ci].in_snoop = true
        self.safe_apply(by, "receive_snoop", [val::Value::Str(s)], "receive_snoop")
        if ci < self.conns.len():
            self.conns[ci].in_snoop = false

    fn stop_snoop(mut self, by: i32):
        let bv = self.obj_value(by)
        for i in 0..self.conns.len():
            if self.conn_ok(i) and self.lpc_eq(self.conns[i].snooped_by, bv) and !self.dead_obj(self.conns[i].snooped_by):
                self.conns[i].snooped_by = val::Value::Int(0 as i64)

    fn snoop_target(self, by: i32) -> i32:
        let bv = self.obj_value(by)
        for i in 0..self.conns.len():
            if self.conn_ok(i) and self.lpc_eq(self.conns[i].snooped_by, bv) and !self.dead_obj(self.conns[i].snooped_by) and self.alive(self.conns[i].user):
                return self.conns[i].user
        -1

    # --- telnet input ------------------------------------------------------------------

    # Strip telnet commands from incoming bytes, acting on them; the data
    # bytes go to `inbuf`.
    fn telnet_filter(mut self, ci: i32, data: Bytes):
        let n = data.len()
        let mut k = 0
        while k < n:
            if !self.conn_ok(ci):
                return
            let c = data[k] as i32
            let st = self.conns[ci].tstate
            if st == TS_DATA:
                if c == IAC:
                    self.conns[ci].tstate = TS_IAC
                else:
                    self.conns[ci].inbuf.push(data[k])
            elif st == TS_IAC:
                if c == IAC:
                    self.conns[ci].inbuf.push(data[k])
                    self.conns[ci].tstate = TS_DATA
                elif c == SB:
                    self.conns[ci].sbuf = Bytes()
                    self.conns[ci].tstate = TS_SB
                elif c == WILL or c == WONT or c == DO or c == DONT:
                    self.conns[ci].tcmd = c
                    self.conns[ci].tstate = TS_OPT
                else:
                    # NOP, GA, AYT, ... ignored
                    self.conns[ci].tstate = TS_DATA
            elif st == TS_OPT:
                self.conns[ci].tstate = TS_DATA
                self.negotiate(ci, self.conns[ci].tcmd, c)
            elif st == TS_SB:
                if c == IAC:
                    self.conns[ci].tstate = TS_SB_IAC
                elif self.conns[ci].sbuf.len() < MAX_SB:
                    self.conns[ci].sbuf.push(data[k])
            elif st == TS_SB_IAC:
                if c == SE:
                    self.conns[ci].tstate = TS_DATA
                    let s = self.conns[ci].sbuf
                    self.conns[ci].sbuf = Bytes()
                    if s.len() > 0:
                        self.subnegotiation(ci, s[0] as i32, bytes_sub(s, 1, s.len()))
                else:
                    if c == IAC and self.conns[ci].sbuf.len() < MAX_SB:
                        self.conns[ci].sbuf.push(IAC as u8)
                    self.conns[ci].tstate = TS_SB
            k += 1

    # WILL/WONT/DO/DONT from the client. Only changes of state are answered,
    # so two ends can't loop.
    fn negotiate(mut self, ci: i32, verb: i32, opt: i32):
        if verb == DO:
            if !local_opt(opt):
                self.tel_cmd(ci, WONT, opt)
                return
            # only on while a noecho input_to waits
            if opt == TELOPT_ECHO:
                return
            if self.conns[ci].local_on.contains(opt):
                return
            if !self.conns[ci].local_asked.contains(opt):
                self.tel_cmd(ci, WILL, opt)
            self.conns[ci].local_asked.remove(opt)
            self.conns[ci].local_on.insert(opt)
            self.local_enabled(ci, opt)
        elif verb == DONT:
            self.conns[ci].local_asked.remove(opt)
            if !self.conns[ci].local_on.contains(opt):
                return
            self.conns[ci].local_on.remove(opt)
            self.tel_cmd(ci, WONT, opt)
            self.local_disabled(ci, opt)
        elif verb == WILL:
            if !remote_opt(opt):
                self.tel_cmd(ci, DONT, opt)
                return
            if self.conns[ci].remote_on.contains(opt):
                return
            if !self.conns[ci].remote_asked.contains(opt):
                self.tel_cmd(ci, DO, opt)
            self.conns[ci].remote_asked.remove(opt)
            self.conns[ci].remote_on.insert(opt)
            self.remote_enabled(ci, opt)
        elif verb == WONT:
            self.conns[ci].remote_asked.remove(opt)
            if !self.conns[ci].remote_on.contains(opt):
                return
            self.conns[ci].remote_on.remove(opt)
            self.tel_cmd(ci, DONT, opt)
            self.remote_disabled(ci, opt)

    fn local_enabled(mut self, ci: i32, opt: i32):
        if opt == TELOPT_GMCP:
            self.enable_gmcp(ci)
        elif opt == TELOPT_MXP:
            self.enable_mxp(ci)
        elif opt == TELOPT_ZMP:
            self.conns[ci].zmp = true
        elif opt == TELOPT_MSDP:
            self.conns[ci].msdp = true
            self.user_apply(ci, "msdp_enable", List<val::Value>())
        elif opt == TELOPT_MSP:
            self.conns[ci].msp = true
        elif opt == TELOPT_MSSP:
            self.send_mssp(ci)
        elif opt == TELOPT_CHARSET:
            let mut d: Bytes = Bytes()
            d.push(CHARSET_REQUEST as u8)
            let t = bytes_from_str(";UTF-8")
            for i in 0..t.len():
                d.push(t[i])
            self.tel_sub(ci, TELOPT_CHARSET, d)

    fn local_disabled(mut self, ci: i32, opt: i32):
        if !self.conn_ok(ci):
            return
        if opt == TELOPT_GMCP:
            if !self.conns[ci].remote_on.contains(TELOPT_GMCP):
                self.conns[ci].gmcp = false
        elif opt == TELOPT_MXP:
            if !self.conns[ci].remote_on.contains(TELOPT_MXP):
                self.conns[ci].mxp = false
        elif opt == TELOPT_ZMP:
            self.conns[ci].zmp = false
        elif opt == TELOPT_MSDP:
            self.conns[ci].msdp = false
        elif opt == TELOPT_MSP:
            self.conns[ci].msp = false

    fn remote_enabled(mut self, ci: i32, opt: i32):
        if opt == TELOPT_TTYPE:
            let mut d: Bytes = Bytes()
            d.push(TTYPE_SEND as u8)
            self.tel_sub(ci, TELOPT_TTYPE, d)
        elif opt == TELOPT_NEW_ENVIRON:
            let mut d: Bytes = Bytes()
            d.push(ENV_SEND as u8)
            self.tel_sub(ci, TELOPT_NEW_ENVIRON, d)
        elif opt == TELOPT_GMCP:
            # FluffOS asks for these with DO, so clients written for it answer WILL
            self.enable_gmcp(ci)
        elif opt == TELOPT_MXP:
            self.enable_mxp(ci)

    fn remote_disabled(mut self, ci: i32, opt: i32):
        if !self.conn_ok(ci):
            return
        if opt == TELOPT_GMCP:
            if !self.conns[ci].local_on.contains(TELOPT_GMCP):
                self.conns[ci].gmcp = false
        elif opt == TELOPT_MXP:
            if !self.conns[ci].local_on.contains(TELOPT_MXP):
                self.conns[ci].mxp = false

    fn enable_gmcp(mut self, ci: i32):
        if self.conns[ci].gmcp:
            return
        self.conns[ci].gmcp = true
        self.user_apply(ci, "gmcp_enable", List<val::Value>())

    fn enable_mxp(mut self, ci: i32):
        if self.conns[ci].mxp:
            return
        self.conns[ci].mxp = true
        self.user_apply(ci, "mxp_enable", List<val::Value>())

    fn subnegotiation(mut self, ci: i32, opt: i32, data: Bytes):
        if opt == TELOPT_TTYPE:
            if data.len() > 0 and (data[0] as i32) == TTYPE_IS:
                self.ttype_answer(ci, str_from_bytes(bytes_sub(data, 1, data.len())))
            return
        if opt == TELOPT_NAWS:
            if data.len() == 4:
                let w = (data[0] as i32) * 256 + (data[1] as i32)
                let h = (data[2] as i32) * 256 + (data[3] as i32)
                self.conns[ci].window = [w, h]
                self.user_apply(ci, "window_size", [val::Value::Int(w as i64), val::Value::Int(h as i64)])
            return
        if opt == TELOPT_NEW_ENVIRON:
            # IS/INFO, then the VAR/VALUE/USERVAR list as sent, with VAR's
            # NUL shown as \x1e (FluffOS passes it that way)
            if data.len() > 0 and ((data[0] as i32) == ENV_IS or (data[0] as i32) == ENV_INFO):
                let rest = bytes_sub(data, 1, data.len())
                self.parse_environ(ci, rest)
                let mut shown: Bytes = Bytes()
                for i in 0..rest.len():
                    shown.push(if (rest[i] as i32) == 0: 30 as u8 else: rest[i])
                self.user_apply(ci, "receive_environ", [val::Value::Str(str_from_bytes(shown))])
            return
        if opt == TELOPT_GMCP:
            if self.conns[ci].gmcp:
                self.user_apply(ci, "gmcp", [val::Value::Str(str_from_bytes(data))])
            return
        if opt == TELOPT_MSDP:
            if self.conns[ci].msdp:
                let pairs = self.msdp_pairs(data)
                let mut k = 0
                while k + 1 < pairs.len():
                    self.user_apply(ci, "msdp", [pairs[k], pairs[k + 1]])
                    k += 2
            return
        if opt == TELOPT_MSP:
            return
        if opt == TELOPT_ZMP:
            if !self.conns[ci].zmp or data.len() == 0 or (data[data.len() - 1] as i32) != 0:
                return
            # NUL-separated parts, the last terminated
            let mut parts: List<val::Value> = List<val::Value>()
            let mut cur: Bytes = Bytes()
            for i in 0..data.len() - 1:
                if (data[i] as i32) == 0:
                    parts.push(val::Value::Str(str_from_bytes(cur)))
                    cur = Bytes()
                else:
                    cur.push(data[i])
            parts.push(val::Value::Str(str_from_bytes(cur)))
            let head = self.to_str(parts[0])
            if head != "":
                let mut rest: List<val::Value> = List<val::Value>()
                for i in 1..parts.len():
                    rest.push(parts[i])
                let ra = self.new_arr(rest)
                self.user_apply(ci, "zmp_command", [parts[0], ra])
            return
        if opt == TELOPT_CHARSET:
            self.charset_sub(ci, data)
            return
        if opt == TELOPT_MSSP or opt == TELOPT_COMPRESS2:
            return
        let mut d: Bytes = Bytes()
        d.push(opt as u8)
        for i in 0..data.len():
            d.push(data[i])
        self.user_apply(ci, "telnet_suboption", [val::Value::Str(str_from_bytes(d))])

    # TTYPE (MTTS): the first answer goes to terminal_type(); SEND is
    # repeated until the client repeats itself, sends "MTTS <bits>", or has
    # given MAX_TTYPE names.
    fn ttype_answer(mut self, ci: i32, name: str):
        if !self.conns[ci].has_terminal:
            self.conns[ci].has_terminal = true
            self.conns[ci].terminal = name
            self.user_apply(ci, "terminal_type", [val::Value::Str(name)])
            if !self.conn_ok(ci):
                return
        if self.conns[ci].ttype_done:
            return
        let ts = self.conns[ci].terminals
        if ts.len() > 0 and (name == ts[ts.len() - 1] or name == ts[0]):
            self.conns[ci].ttype_done = true
            return
        self.conns[ci].terminals.push(name)
        let up = upper_ascii(name)
        if str_starts_with(up, "MTTS "):
            # Pike sscanf("%d"): optional sign, digits
            let rest = vm::substr(up, 5, len(up))
            let rb = bytes_from_str(rest)
            if rb.len() > 0 and (((rb[0] as i32) >= 48 and (rb[0] as i32) <= 57) or (((rb[0] as i32) == 45 or (rb[0] as i32) == 43) and rb.len() > 1 and (rb[1] as i32) >= 48 and (rb[1] as i32) <= 57)):
                self.conns[ci].mtts = vm::parse_int_prefix(rest)
                self.conns[ci].ttype_done = true
                return
        if self.conns[ci].terminals.len() >= MAX_TTYPE:
            self.conns[ci].ttype_done = true
            return
        let mut d: Bytes = Bytes()
        d.push(TTYPE_SEND as u8)
        self.tel_sub(ci, TELOPT_TTYPE, d)

    fn env_set(mut self, ci: i32, k: str, v: str):
        if !self.conns[ci].env_vals.contains(k):
            self.conns[ci].env_keys.push(k)
        self.conns[ci].env_vals.insert(k, v)

    fn env_delete(mut self, ci: i32, k: str):
        if !self.conns[ci].env_vals.contains(k):
            return
        self.conns[ci].env_vals.remove(k)
        let old = self.conns[ci].env_keys
        let mut keep: List<str> = List<str>()
        for i in 0..old.len():
            if old[i] != k:
                keep.push(old[i])
        self.conns[ci].env_keys = keep

    # NEW-ENVIRON IS/INFO list: (VAR|USERVAR) name [VALUE value] ..., ESC
    # quoting the next byte. A variable sent without VALUE is removed.
    fn parse_environ(mut self, ci: i32, data: Bytes):
        let mut cur: Bytes = Bytes()
        let mut name = ""
        let mut in_value = false
        let n = data.len()
        let mut k = 0
        while k <= n:
            let at_end = k == n
            let c = if at_end: -1 else: data[k] as i32
            if !at_end and c == ENV_ESC and k + 1 < n:
                k += 1
                cur.push(data[k])
            elif at_end or c == ENV_VAR or c == ENV_USERVAR:
                # finish()
                let text = str_from_bytes(cur)
                cur = Bytes()
                if in_value:
                    self.env_set(ci, name, text)
                elif text != "":
                    self.env_delete(ci, text)
                in_value = false
            elif c == ENV_VALUE and !in_value:
                name = str_from_bytes(cur)
                cur = Bytes()
                in_value = true
            else:
                cur.push(data[k])
            k += 1

    # CHARSET: our REQUEST answered, or the client's own REQUEST.
    fn charset_sub(mut self, ci: i32, data: Bytes):
        if data.len() == 0:
            return
        let kind = data[0] as i32
        if kind == CHARSET_ACCEPTED:
            self.conns[ci].utf8 = upper_ascii(str_from_bytes(bytes_sub(data, 1, data.len()))) == "UTF-8"
            return
        if kind == CHARSET_REJECTED:
            return
        if kind == CHARSET_REQUEST:
            let mut list = str_from_bytes(bytes_sub(data, 1, data.len()))
            # a version byte follows "[TTABLE]"
            if str_starts_with(list, "[TTABLE]"):
                list = vm::substr(list, 9, len(list))
            if list == "":
                return
            let sep = vm::substr(list, 0, 1)
            let names = str_split(vm::substr(list, 1, len(list)), sep)
            let mut ok = false
            for i in 0..names.len():
                let u = upper_ascii(names[i])
                if u == "UTF-8" or u == "UTF8":
                    ok = true
            let mut d: Bytes = Bytes()
            if ok:
                self.conns[ci].utf8 = true
                d.push(CHARSET_ACCEPTED as u8)
                let t = bytes_from_str("UTF-8")
                for i in 0..t.len():
                    d.push(t[i])
            else:
                d.push(CHARSET_REJECTED as u8)
            self.tel_sub(ci, TELOPT_CHARSET, d)

    # --- MSDP and MSSP -------------------------------------------------------------

    # MSDP payload -> var, value, var, value, ... A value is a string, a
    # mapping (TABLE) or an array (ARRAY); a variable given several VALs gets
    # an array of them. Malformed input never errors, it just stops early
    # (net.pike MsdpReader).
    fn msdp_pairs(mut self, s: Bytes) -> List<val::Value>:
        let mut out: List<val::Value> = List<val::Value>()
        let mut p = 0
        while p < s.len():
            if (s[p] as i32) != MSDP_VAR:
                p += 1
                continue
            p += 1
            let vname = self.msdp_text(s, p)
            p += len(vname)
            let vr = self.msdp_values(s, p)
            out.push(val::Value::Str(vname))
            out.push(vr.v)
            p = vr.pos
        out

    # the text run at `p` (up to a structure byte)
    fn msdp_text(self, s: Bytes, p: i32) -> str:
        let mut e = p
        while e < s.len() and (s[e] as i32) > MSDP_ARRAY_CLOSE:
            e += 1
        str_from_bytes(bytes_sub(s, p, e))

    fn msdp_value(mut self, s: Bytes, p_in: i32) -> MsdpRead:
        let mut p = p_in
        if p < s.len() and (s[p] as i32) == MSDP_TABLE_OPEN:
            p += 1
            let m = self.new_map()
            while p < s.len() and (s[p] as i32) != MSDP_TABLE_CLOSE:
                if (s[p] as i32) != MSDP_VAR:
                    p += 1
                    continue
                p += 1
                let k = self.msdp_text(s, p)
                p += len(k)
                let vr = self.msdp_values(s, p)
                self.map_set(m, val::Value::Str(k), vr.v)
                p = vr.pos
            return MsdpRead(v = val::Value::Map(m), pos = p + 1)
        if p < s.len() and (s[p] as i32) == MSDP_ARRAY_OPEN:
            p += 1
            let mut a: List<val::Value> = List<val::Value>()
            while p < s.len() and (s[p] as i32) != MSDP_ARRAY_CLOSE:
                if (s[p] as i32) != MSDP_VAL:
                    p += 1
                    continue
                p += 1
                let vr = self.msdp_value(s, p)
                a.push(vr.v)
                p = vr.pos
            return MsdpRead(v = self.new_arr(a), pos = p + 1)
        let t = self.msdp_text(s, p)
        MsdpRead(v = val::Value::Str(t), pos = p + len(t))

    # the VAL list after a VAR name
    fn msdp_values(mut self, s: Bytes, p_in: i32) -> MsdpRead:
        let mut p = p_in
        let mut vals: List<val::Value> = List<val::Value>()
        while p < s.len() and (s[p] as i32) == MSDP_VAL:
            p += 1
            let vr = self.msdp_value(s, p)
            vals.push(vr.v)
            p = vr.pos
        if vals.len() == 1:
            return MsdpRead(v = vals[0], pos = p)
        if vals.len() > 0:
            return MsdpRead(v = self.new_arr(vals), pos = p)
        MsdpRead(v = val::Value::Str(""), pos = p)

    # Keys of a mapping in Pike sort() order.
    fn sorted_keys(mut self, m: i32) -> List<val::Value>:
        let mut ks = self.maps[m].keys
        let mut a = 1
        while a < ks.len():
            let x = ks[a]
            let mut b = a - 1
            while b >= 0 and self.sort_less(x, ks[b]):
                ks[b + 1] = ks[b]
                b -= 1
            ks[b + 1] = x
            a += 1
        ks

    # Text inside MSDP can't hold the structure bytes 0-6.
    fn msdp_out_value(mut self, out: Bytes, v: val::Value) -> Bytes:
        let mut o = out
        match v:
            val::Value::Str(s) ->
                let t = bytes_from_str(strip_low(s, MSDP_ARRAY_CLOSE))
                for i in 0..t.len():
                    o.push(t[i])
            val::Value::Int(x) ->
                let t = bytes_from_str(vm::int_str(x))
                for i in 0..t.len():
                    o.push(t[i])
            val::Value::Real(x) ->
                let t = bytes_from_str(self.to_str(v))
                for i in 0..t.len():
                    o.push(t[i])
            val::Value::Map(h) ->
                o.push(MSDP_TABLE_OPEN as u8)
                let ks = self.sorted_keys(h)
                for i in 0..ks.len():
                    let k = ks[i]
                    let is_key = match k:
                        val::Value::Str(s) -> true
                        val::Value::Int(x) -> true
                        _ -> false
                    if is_key:
                        o.push(MSDP_VAR as u8)
                        let t = bytes_from_str(strip_low(self.to_str(k), MSDP_ARRAY_CLOSE))
                        for j in 0..t.len():
                            o.push(t[j])
                        o.push(MSDP_VAL as u8)
                        o = self.msdp_out_value(o, self.map_get(h, k))
                o.push(MSDP_TABLE_CLOSE as u8)
            val::Value::Arr(h) ->
                o.push(MSDP_ARRAY_OPEN as u8)
                let items = self.arrs[h].items
                for i in 0..items.len():
                    o.push(MSDP_VAL as u8)
                    o = self.msdp_out_value(o, items[i])
                o.push(MSDP_ARRAY_CLOSE as u8)
            _ -> 0
        o

    # MSDP: one VAR/VAL pair per mapping entry, in sorted order.
    fn send_msdp(mut self, ci: i32, m: i32):
        if !self.conn_ok(ci) or !self.conns[ci].msdp:
            return
        let mut b: Bytes = Bytes()
        let ks = self.sorted_keys(m)
        for i in 0..ks.len():
            let k = ks[i]
            let is_key = match k:
                val::Value::Str(s) -> true
                val::Value::Int(x) -> true
                _ -> false
            if !is_key:
                continue
            b.push(MSDP_VAR as u8)
            let t = bytes_from_str(strip_low(self.to_str(k), MSDP_ARRAY_CLOSE))
            for j in 0..t.len():
                b.push(t[j])
            b.push(MSDP_VAL as u8)
            b = self.msdp_out_value(b, self.map_get(m, k))
        if b.len() > 0:
            self.tel_sub(ci, TELOPT_MSDP, b)

    # MSSP: the master's get_mud_stats() mapping, with PLAYERS and UPTIME
    # (boot time) filled in by the driver as FluffOS does. Values: strings
    # and ints, or arrays of them (one VAL each).
    fn send_mssp(mut self, ci: i32):
        let stats = self.safe_master_apply("get_mud_stats", List<val::Value>(), "get_mud_stats")
        if !self.conn_ok(ci):
            return
        let m = self.new_map()
        match stats:
            val::Value::Map(h) ->
                let ks = self.maps[h].keys
                for i in 0..ks.len():
                    self.map_set(m, ks[i], self.map_get(h, ks[i]))
            _ -> 0
        self.map_set(m, val::Value::Str("PLAYERS"), val::Value::Str(vm::int_str(self.users_list().len() as i64)))
        self.map_set(m, val::Value::Str("UPTIME"), val::Value::Str(vm::int_str(self.boot_time)))
        let mut b: Bytes = Bytes()
        let ks = self.sorted_keys(m)
        for i in 0..ks.len():
            let k = ks[i]
            let ks_ = match k:
                val::Value::Str(s) -> s
                _ -> ""
            if !self.is_str(k):
                continue
            let v = self.map_get(m, k)
            let mut vals: List<val::Value> = List<val::Value>()
            match v:
                val::Value::Arr(h) ->
                    vals = self.arrs[h].items
                _ ->
                    vals = [v]
            let mut usable: List<str> = List<str>()
            for j in 0..vals.len():
                match vals[j]:
                    val::Value::Str(s) ->
                        usable.push(s)
                    val::Value::Int(x) ->
                        usable.push(vm::int_str(x))
                    _ -> 0
            if usable.len() == 0:
                continue
            b.push(MSSP_VAR as u8)
            let t = bytes_from_str(strip_low(ks_, 2))
            for j in 0..t.len():
                b.push(t[j])
            for j in 0..usable.len():
                b.push(MSSP_VAL as u8)
                let u = bytes_from_str(strip_low(usable[j], 2))
                for q in 0..u.len():
                    b.push(u[q])
        self.tel_sub(ci, TELOPT_MSSP, b)

    # --- applies for telnet events ---------------------------------------------------

    # An apply on the user object for a telnet event, as a top-level
    # evaluation with the user as this_player().
    fn user_apply(mut self, ci: i32, fname: str, args: List<val::Value>):
        let u = self.conns[ci].user
        if !self.alive(u):
            return
        let saved = self.cur_player
        self.cur_player = u
        self.safe_apply(u, fname, args, fname)
        self.restore_tp(saved)

    # --- lines -------------------------------------------------------------------------

    # Bytes from the client (read_cb()): telnet commands acted on, then each
    # complete line (or, in charmode with a get_char() waiting, each
    # character) handled in turn.
    fn conn_input(mut self, ci: i32, data: Bytes):
        if !self.conn_ok(ci):
            return
        self.count_traffic(self.conns[ci].local_port, 0, data.len())
        self.telnet_filter(ci, data)
        while self.conn_ok(ci) and self.conns[ci].in_off < self.conns[ci].inbuf.len():
            let off = self.conns[ci].in_off
            let buf = self.conns[ci].inbuf
            if self.conns[ci].skip_lf:
                self.conns[ci].skip_lf = false
                if (buf[off] as i32) == 10 or (buf[off] as i32) == 0:
                    self.conns[ci].in_off = off + 1
                    continue
            # a line ends at LF, CR LF, CR NUL or a lone CR
            let mut end = -1
            let mut j = off
            while j < buf.len():
                let c = buf[j] as i32
                if c == 10 or c == 13:
                    end = j
                    break
                j += 1
            if end < 0:
                if self.conns[ci].charmode and !val::is_zero(self.conns[ci].input_fn):
                    let n = if self.conns[ci].utf8: utf8_length(buf, off) else: 1
                    if n == 0:
                        break
                    self.conns[ci].in_off = off + n
                    self.handle_line(ci, str_from_bytes(bytes_sub(buf, off, off + n)))
                    continue
                break
            let mut line: Bytes = Bytes()
            for q in off..end:
                # NUL bytes are dropped
                if (buf[q] as i32) != 0:
                    line.push(buf[q])
            let mut e2 = end
            if (buf[end] as i32) == 13:
                if end + 1 < buf.len():
                    if (buf[end + 1] as i32) == 10 or (buf[end + 1] as i32) == 0:
                        e2 = end + 1
                else:
                    # the LF may come in the next packet
                    self.conns[ci].skip_lf = true
            self.conns[ci].in_off = e2 + 1
            self.handle_line(ci, str_from_bytes(line))
        if ci < self.conns.len() and self.conns[ci].alive:
            if self.conns[ci].in_off >= self.conns[ci].inbuf.len():
                self.conns[ci].inbuf = Bytes()
                self.conns[ci].in_off = 0
            elif self.conns[ci].in_off > 4096:
                self.conns[ci].inbuf = bytes_sub(self.conns[ci].inbuf, self.conns[ci].in_off, self.conns[ci].inbuf.len())
                self.conns[ci].in_off = 0

    # One line (or character) from the user: to the pending input_to, or as
    # a command, then the prompt.
    fn handle_line(mut self, ci: i32, line: str):
        self.conns[ci].last_input = vm::epoch_now()
        let u = self.conns[ci].user
        if !self.alive(u):
            return
        self.cur_player = u
        self.cur_interactive = u
        # the snooper sees typed input, but not passwords (noecho input_to)
        let pending = !val::is_zero(self.conns[ci].input_fn)
        if !val::is_zero(self.conns[ci].snooped_by) and !(pending and (self.conns[ci].input_flags & I_NOECHO) != 0):
            self.deliver_snoop(ci, concat(line, "\n"))
        if !self.conn_ok(ci):
            self.cur_player = -1
            self.cur_interactive = -1
            return
        let ol = self.ostack.len()
        let sl = self.stack.len()
        if !val::is_zero(self.conns[ci].input_fn):
            let f = self.conns[ci].input_fn
            let owner = self.obj_of(self.conns[ci].input_owner)
            let args = self.conns[ci].input_args
            let flags = self.conns[ci].input_flags
            self.clear_input_to(ci)
            self.conns[ci].charmode = false
            if (flags & I_NOECHO) != 0 and self.conns[ci].noecho_active:
                self.tel_cmd(ci, WONT, TELOPT_ECHO)
                self.raw_byte(ci, 13)
                self.raw_byte(ci, 10)
                self.conns[ci].noecho_active = false
            let mut all: List<val::Value> = [val::Value::Str(line)]
            for i in 0..args.len():
                all.push(args[i])
            self.begin_eval()
            if owner >= 0:
                self.run_fn_value(owner, f, all)
            else:
                self.call_value(f, all)
            if self.err:
                self.report_error("input_to")
            self.truncate_ostack(ol)
            self.truncate_stack(sl)
            self.end_eval()
        else:
            self.begin_eval()
            self.process_command(ci, u, line)
            if self.err:
                self.report_error("command")
            self.truncate_ostack(ol)
            self.truncate_stack(sl)
            self.end_eval()
        if self.conn_ok(ci):
            let nu = self.conns[ci].user
            if self.alive(nu) and val::is_zero(self.conns[ci].input_fn):
                self.begin_eval()
                let r = self.apply_value(nu, "write_prompt", List<val::Value>())
                if !self.err:
                    match r:
                        val::Value::Undef ->
                            self.conn_send(ci, "> ")
                        _ -> 0
                if self.err:
                    self.report_error("write_prompt")
                self.truncate_ostack(ol)
                self.truncate_stack(sl)
                self.end_eval()
        if self.conn_ok(ci):
            self.mark_prompt(ci)
        self.cur_player = -1
        self.cur_interactive = -1

    fn process_command(mut self, ci: i32, u: i32, line_in: str):
        let mut line = line_in
        let r = self.apply_value(u, "process_input", [val::Value::Str(line)])
        if self.err:
            return
        match r:
            val::Value::Str(s) ->
                line = s
            val::Value::Int(x) ->
                if x != (0 as i64):
                    return
            _ -> 0
        if !self.alive(u) or all_white(line):
            return
        let ok = self.do_command(u, line)
        if self.err or ok or !self.alive(u):
            return
        let nf = self.objs[u].notify_fail
        let mut msg = val::Value::Int(0 as i64)
        if self.is_callable(nf):
            msg = self.call_value(nf, List<val::Value>())
            if self.err:
                return
        elif self.is_str(nf):
            msg = nf
        else:
            let mut dflt = "What?"
            if let Option::Some(x) = self.config.get("default fail message"):
                if x != "":
                    dflt = x
            msg = val::Value::Str(concat(dflt, "\n"))
        if self.is_str(msg) and self.alive(u):
            self.tell_object(u, msg)

    # input_to()/get_char(): only one may be pending (FluffOS); later calls
    # fail. A noecho one turns the client's echo off while it waits.
    fn set_input_to(mut self, ci: i32, f: val::Value, owner: i32, flags: i32, args: List<val::Value>, is_char: bool) -> bool:
        if !val::is_zero(self.conns[ci].input_fn):
            return false
        self.conns[ci].input_fn = f
        self.conns[ci].input_owner = self.obj_value(owner)
        self.conns[ci].input_flags = flags
        self.conns[ci].input_args = args
        self.conns[ci].charmode = is_char
        if (flags & I_NOECHO) != 0 and !self.conns[ci].noecho_active:
            self.tel_cmd(ci, WILL, TELOPT_ECHO)
            self.conns[ci].noecho_active = true
        true

    # --- out-of-band senders ---------------------------------------------------------

    fn send_gmcp(mut self, ci: i32, msg: str):
        if !self.conn_ok(ci) or !self.conns[ci].gmcp:
            return
        self.tel_sub(ci, TELOPT_GMCP, bytes_from_str(msg))

    fn send_zmp(mut self, ci: i32, command: str, args: List<str>):
        if !self.conn_ok(ci) or !self.conns[ci].zmp:
            return
        let mut b: Bytes = bytes_from_str(command)
        b.push(0 as u8)
        for i in 0..args.len():
            let t = bytes_from_str(args[i])
            for j in 0..t.len():
                b.push(t[j])
            b.push(0 as u8)
        self.tel_sub(ci, TELOPT_ZMP, b)

    # MXP: IAC SB MXP IAC SE starts MXP mode on the client.
    fn act_mxp(mut self, ci: i32):
        self.tel_sub(ci, TELOPT_MXP, Bytes())

    # MSP trigger as a subnegotiation: the out-of-band form Mudlet reads.
    fn send_msp(mut self, ci: i32, trigger: str):
        if !self.conn_ok(ci) or !self.conns[ci].msp:
            return
        self.tel_sub(ci, TELOPT_MSP, bytes_from_str(trigger))

    # What is known about the client (client_info()).
    fn client_info(mut self, ci: i32) -> val::Value:
        let m = self.new_map()
        let c = self.conns[ci]
        self.map_set(m, val::Value::Str("terminal"), if c.has_terminal: val::Value::Str(c.terminal) else: val::Value::Int(0 as i64))
        let mut ts: List<val::Value> = List<val::Value>()
        for i in 0..c.terminals.len():
            ts.push(val::Value::Str(c.terminals[i]))
        let tsa = self.new_arr(ts)
        self.map_set(m, val::Value::Str("terminals"), tsa)
        let em = self.new_map()
        for i in 0..c.env_keys.len():
            if let Option::Some(v) = c.env_vals.get(c.env_keys[i]):
                self.map_set(em, val::Value::Str(c.env_keys[i]), val::Value::Str(v))
        self.map_set(m, val::Value::Str("environ"), val::Value::Map(em))
        self.map_set(m, val::Value::Str("utf8"), self.bool_v(c.utf8))
        self.map_set(m, val::Value::Str("tls"), val::Value::Int(0 as i64))
        self.map_set(m, val::Value::Str("websocket"), val::Value::Int(0 as i64))
        self.map_set(m, val::Value::Str("mccp"), val::Value::Int(0 as i64))
        self.map_set(m, val::Value::Str("eor"), self.bool_v(c.local_on.contains(TELOPT_EOR)))
        self.map_set(m, val::Value::Str("gmcp"), self.bool_v(c.gmcp))
        self.map_set(m, val::Value::Str("msdp"), self.bool_v(c.msdp))
        self.map_set(m, val::Value::Str("msp"), self.bool_v(c.msp))
        self.map_set(m, val::Value::Str("mxp"), self.bool_v(c.mxp))
        self.map_set(m, val::Value::Str("zmp"), self.bool_v(c.zmp))
        if c.mtts >= (0 as i64):
            self.map_set(m, val::Value::Str("mtts"), val::Value::Int(c.mtts))
        if c.window.len() == 2:
            let wa = self.new_arr([val::Value::Int(c.window[0] as i64), val::Value::Int(c.window[1] as i64)])
            self.map_set(m, val::Value::Str("window"), wa)
        val::Value::Map(m)

    # --- sockets: the main loop's part -----------------------------------------------

    # Telnet on `port` (net.pike listen()); false when the port can't be
    # bound. Port 0 binds a free port on loopback, as the reference does.
    fn net_listen(mut self, port: i32) -> i32:
        let l = tcp_listen(port, port == 0)
        if is_null(l):
            self.log_msg(f"Cannot bind port {port}")
            return 0
        let p = tcp_local_port(l)
        self.listeners.push(l)
        self.listener_ports.push(p)
        self.log_msg(f"Accepting connections on port {p}")
        p

    # One pass: wait up to `timeout_ms` for input, take new connections, read
    # what arrived, and write what's queued. The LPC sockets (sockets.star)
    # share the wait: what the previous pass left for this one (resolve()
    # answers, connects that never started) runs first, then every open
    # socket is polled with the interest sock_interest() gives it, and
    # what's ready is handed to sock_ready() after the telnet connections.
    fn net_poll(mut self, timeout_ms: i32):
        self.run_resolves()
        self.run_finds()
        self.sock_fail_dead_connects()
        let mut handles: List<ptr> = List<ptr>()
        let mut which: List<i32> = List<i32>()
        let mut interest = Bytes()
        for i in 0..self.listeners.len():
            handles.push(self.listeners[i])
            which.push(-1 - i)
            interest.push(1 as u8)
        for i in 0..self.conns.len():
            if self.conn_ok(i) and !is_null(self.conns[i].sock):
                handles.push(self.conns[i].sock)
                which.push(i)
                interest.push(1 as u8)
        let first_sock = handles.len()
        let mut sock_fds: List<i32> = List<i32>()
        for fd in 0..self.socks.len():
            let want = self.sock_interest(fd)
            if want != 0:
                handles.push(self.socks[fd].handle)
                sock_fds.push(fd)
                interest.push(want as u8)
        let wait = if self.sock_work_waiting(): 0 else: timeout_ms
        let ready = tcp_wait_io(handles, interest, wait)
        for k in 0..which.len():
            if k >= ready.len() or (ready[k] as i32) == 0:
                continue
            let w = which[k]
            if w < 0:
                self.accept_all(-1 - w)
            elif self.conn_ok(w) and !is_null(self.conns[w].sock):
                let d = tcp_recv_bytes(self.conns[w].sock)
                if d.len() == 0:
                    self.conn_close(w, "connection closed by peer")
                else:
                    self.conn_input(w, d)
        for j in 0..sock_fds.len():
            let k = first_sock + j
            if k < ready.len() and (ready[k] as i32) != 0:
                self.sock_ready(sock_fds[j], handles[k], ready[k] as i32)
        self.net_flush_all()

    # Milliseconds the main loop may wait for input before a timer is due:
    # the next heart beat slot, call_out or reset sweep, at most a second.
    fn next_timer_ms(self) -> i32:
        if self.sock_work_waiting():
            return 0
        let now = clock_ms()
        let mut due = now + (1000 as i64)
        if self.next_hb_ms != (0 as i64) and self.next_hb_ms < due:
            due = self.next_hb_ms
        if self.callouts.len() > 0:
            let co = self.clock_epoch + self.callouts[0].when * (10 as i64)
            if co < due:
                due = co
        if self.next_sweep_ms != (0 as i64) and self.next_sweep_ms < due:
            due = self.next_sweep_ms
        if due <= now:
            return 0
        (due - now) as i32

    fn net_flush_all(mut self):
        for i in 0..self.conns.len():
            if self.conn_ok(i) and self.conns[i].outbuf.len() > self.conns[i].out_off:
                if !self.conn_flush(i):
                    self.conn_close(i, "write failed")

    fn accept_all(mut self, li: i32):
        let l = self.listeners[li]
        let port = self.listener_ports[li]
        let mut s = tcp_accept(l)
        while !is_null(s):
            let ci = self.conn_new(s, port)
            self.conns[ci].ip = tcp_peer_ip(s)
            self.conn_offer(ci)
            self.start_session(ci)
            self.conn_flush(ci)
            s = tcp_accept(l)

# One parsed MSDP value and the offset after it.
struct MsdpRead:
    v: val::Value
    pos: i32

# Bytes in the UTF-8 sequence starting at b[p] (0: not all here yet).
fn utf8_length(b: Bytes, p: i32) -> i32:
    let c = b[p] as i32
    let n = if c < 192: 1 elif c < 224: 2 elif c < 240: 3 else: 4
    if b.len() - p >= n:
        return n
    0

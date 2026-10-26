"""Generates tests/fixtures/cases/m7_sock_cases.txt (todo.md HavokOS P1 #5,
the LPC socket efuns).

The cases drive both drivers' sockets over loopback on the test minilib:
a helper object (/test/tmp_m7_sock.c, written by the first case, removed by
the last) logs every callback, and the case runner's hooks run the network
(test_sock_pump(ob, fn): network passes until ob->fn() is true) and turn
outbound connections on (test_config("havok outbound sockets", "1")); both
are given to the reference by tools/ref_cases.pike. Expected results
(m7_sock.expected.txt) are whatever the live reference returns, never
hand-predicted.

What the cases avoid, because the two drivers can't agree on it by design
or by environment (sockets.star's header, NOTES.md deviations #16-#17):
- ephemeral ports and anything containing one (a client's local port is
  compared with the server's view of it instead);
- the TLS modes (no TLS in the Star driver yet);
- connecting by host name (the reference resolves "localhost" to ::1, the
  Star driver is IPv4) and resolve() of a numeric address (the reference
  answers with this network's reverse DNS name);
- NUL bytes in data (deviation #7), and objects in results (the two case
  runners render them differently).
Fixed ports 47801-47899 are used for listeners and bound datagram sockets.

Usage: python tools/gen_m7_sock_cases.py > tests/fixtures/cases/m7_sock_cases.txt
"""

def lpc_str(src):
    """An LPC string literal holding src."""
    return '"' + src.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'

CASES = []

def case(name, body, globals_=""):
    CASES.append((name, (globals_ + " @@ " if globals_ else "") + body))

P = "/test/tmp_m7_sock"

HELPER = r'''// socket fixture for the M7 socket cases: every callback is logged
mixed *log = ({});
int want, lfd = -1, cfd = -1, echo, quiet, total, boom, acquire, lazy;
mixed *replies = ({});
void ev(mixed *e) { log += ({ e }); }
mixed *take() { mixed *r = log; log = ({}); return r; }
void expect(int n) { want = n; }
int ready() { return sizeof(log) >= want; }
int got_all() { return total >= want; }
void set_echo(int e) { echo = e; }
void set_quiet(int q) { quiet = q; total = 0; }
void set_boom(int b) { boom = b; }
void set_acquire(int a) { acquire = a; }
void set_lazy(int l) { lazy = l; }
int query_total() { return total; }
int query_lfd() { return lfd; }
int query_cfd() { return cfd; }
void on_read(int fd, mixed data) {
    if (quiet) { total += sizeof(data); return; }
    ev(({ "read", fd, data }));
    if (boom && data == "boom") error("socket callback failure\n");
    if (echo) ev(({ "echoed", socket_write(fd, stringp(data) ? "echo:" + data : data) }));
}
void on_dgram(int fd, mixed data, string addr) { ev(({ "dgram", fd, data, addr })); }
void on_write(int fd) {
    ev(({ "write", fd }));
    if (sizeof(replies)) { mixed m = replies[0]; replies = replies[1..]; ev(({ "sent", socket_write(fd, m) })); }
}
void on_close(int fd) { ev(({ "close", fd })); }
void on_listen(int fd) {
    if (lazy) { ev(({ "pending", fd })); return; }
    int n = socket_accept(fd, "on_read", "on_write");
    ev(({ "accept", fd, n }));
    if (n >= 0) cfd = n;
}
void accept_now() {
    int n = socket_accept(lfd, "on_read", "on_write");
    ev(({ "accept", lfd, n }));
    if (n >= 0) cfd = n;
}
void fp_read(int fd, mixed data) { ev(({ "fp_read", fd, data })); }
void fp_close(int fd) { ev(({ "fp_close", fd })); }
mixed *serve(int mode, int port) {
    lfd = socket_create(mode, "on_read", "on_close");
    return ({ socket_bind(lfd, port), socket_listen(lfd, "on_listen") });
}
mixed *serve_fp(int mode, int port) {
    lfd = socket_create(mode, (: fp_read :), (: fp_close :));
    return ({ socket_bind(lfd, port), socket_listen(lfd, (: on_listen :)) });
}
int dial(int mode, string addr, mixed *msgs) {
    replies = msgs;
    cfd = socket_create(mode, "on_read", "on_close");
    return socket_connect(cfd, addr, "on_read", "on_write");
}
int dial_fp(int mode, string addr) {
    cfd = socket_create(mode, (: fp_read :), (: fp_close :));
    return socket_connect(cfd, addr, (: fp_read :), (: on_write :));
}
mixed *dbind(int mode, int port, mixed addr) {
    cfd = socket_create(mode, "on_dgram", "on_close");
    return ({ cfd, stringp(addr) ? socket_bind(cfd, port, addr) : socket_bind(cfd, port) });
}
int dsend(mixed msg, mixed addr) { return socket_write(cfd, msg, addr); }
int send(mixed m) { return socket_write(cfd, m); }
int send_on(int fd, mixed m) { return socket_write(fd, m); }
int shut(int fd) { return socket_close(fd); }
int mine() { return cfd = socket_create(1, "on_read", "on_close"); }
int conn(int fd, mixed addr) { return socket_connect(fd, addr, "on_read", "on_write"); }
int give(int fd, object to) { return socket_release(fd, to, "adopt"); }
void adopt(int fd, object from) {
    ev(({ "adopt", fd, from == previous_object(), acquire ? socket_acquire(fd, "on_read", "on_write", "on_close") : 0 }));
}
void stop() {
    if (cfd != -1) socket_close(cfd);
    if (lfd != -1) socket_close(lfd);
}
'''

ON = 'test_config("havok outbound sockets", "1");'
STATE = "(: socket_status($1) ? socket_status($1)[1] : 0 :)"

case("m7s setup helpers",
     "write_file(%s, %s, 1); %s return 1;" % (lpc_str(P + ".c"), lpc_str(HELPER), ON))

# --- table answers
case("socket_error texts",
     'mixed *r = ({}); for (int i = 1; i >= -32; i--) r += ({ socket_error(i) }); '
     'mixed x = "x"; r += ({ socket_error(x), socket_error(5) }); return r;')

case("socket_create modes and socket_status rows",
     'mixed *fds = ({}); for (int m = -1; m <= 7; m++) fds += ({ socket_create(m, "a", "b") }); '
     'mixed *live = filter(fds, (: $1 >= 0 :)); '
     'mixed *rows = map(live, (: socket_status($1)[0..4] :)); '
     'mixed *own = map(live, (: socket_status($1)[5] == this_object() :)); '
     'int n = sizeof(socket_status()); '
     'mixed *closes = map(live, (: socket_close($1) :)); '
     'mixed y = "x"; mixed u; '
     'return ({ fds, rows, own, n == live[<1] + 1, closes, map(live, (: socket_status($1) :)), '
     'map(live, (: socket_close($1) :)), socket_status(-1), socket_status(99999), socket_status(y), sizeof(socket_status(u)) });')

# --- state machine errors on one object's own sockets
case("socket state errors",
     'int s = socket_create(1, "r", "c"); int d = socket_create(2, "r"); mixed five = 5; '
     'mixed *r = ({ socket_listen(s, "l"), socket_accept(s, "r", "w"), socket_write(s, "x"), '
     'socket_address(s), socket_address(s, 1), socket_bind(s, 47821), socket_bind(s, 47822), socket_status(s)[1], '
     'socket_address(s), socket_address(s, 1), socket_status(s)[3], '
     'socket_accept(s, "r", "w"), socket_write(s, "x"), socket_listen(s, "l"), socket_status(s)[1], socket_listen(s, "l"), '
     'socket_accept(s, "r", "w"), socket_connect(s, "127.0.0.1 47821", "r", "w"), socket_write(s, "x"), '
     'socket_listen(d, "l"), socket_accept(d, "r", "w"), socket_connect(d, "127.0.0.1 1", "r", "w"), '
     'socket_bind(d, 47823), socket_bind(d, 47824), socket_status(d)[1..3], '
     'socket_bind(five, 1), socket_listen(-1, "l"), socket_accept(99999, "r", "w"), socket_write(-5, "x"), socket_close(-1) }); '
     'int s2 = socket_create(1, "r", "c"); r += ({ socket_bind(s2, 47821), socket_listen(s2, "l"), socket_status(s2)[1] }); '
     'int s3 = socket_create(1, "r", "c"); r += ({ socket_bind(s3, 47825, "127.0.0.1"), socket_listen(s3, "l"), socket_address(s3, 1), socket_status(s3)[3] }); '
     'r += ({ socket_close(s), socket_close(s2), socket_close(s3), socket_close(d), socket_close(d) }); return r;')

case("socket ownership",
     'object a = clone_object("%s"); int fd = a->mine(); mixed *r = ({ '
     'socket_bind(fd, 47826), socket_listen(fd, "l"), socket_connect(fd, "127.0.0.1 1", "r", "w"), socket_write(fd, "x"), '
     'socket_accept(fd, "r", "w"), socket_release(fd, this_object(), "x"), socket_acquire(fd, "r", "w", "c"), socket_close(fd), '
     'socket_status(fd)[1], socket_status(fd)[5] == a }); '
     'destruct(a); r += ({ socket_status(fd)[0..1], socket_close(fd) }); return r;' % P)

case("socket_address of objects and other values",
     'object a = clone_object("%s"); mixed s = "x"; mixed r = ({ socket_address(a), socket_address(a, 1), socket_address(0), socket_address(s), socket_address(-1) }); destruct(a); return r;' % P)

# --- streams over loopback
case("stream: connect, write callback, echo, close",
     'object S = clone_object("%s"), C = clone_object("%s"); S->set_echo(1); '
     'mixed sr = S->serve(1, 47831); int cr = C->dial(1, "127.0.0.1 47831", ({ "hello" })); '
     'mixed st0 = socket_status(C->query_cfd())[1]; '
     'C->expect(3); int okc = test_sock_pump(C, "ready"); S->expect(3); int oks = test_sock_pump(S, "ready"); '
     'string sa = socket_address(S->query_cfd()), ca = socket_address(C->query_cfd(), 1); '
     'mixed *rows = ({ socket_status(S->query_lfd())[1..2], socket_status(S->query_cfd())[1..2], socket_status(C->query_cfd())[1..2] }); '
     'mixed *addrs = ({ sa == ca, sa[0..9], socket_address(C->query_cfd()), socket_address(S->query_cfd(), 1), socket_status(C->query_cfd())[4] }); '
     'mixed *cl = C->take(), *sl = S->take(); '
     'int shut = C->shut(C->query_cfd()); S->expect(1); int okx = test_sock_pump(S, "ready"); '
     'mixed *sl2 = S->take(); mixed *after = ({ socket_status(S->query_cfd())[0], socket_status(S->query_lfd())[1] }); '
     'S->stop(); destruct(S); destruct(C); '
     'return ({ sr, cr, st0, okc, oks, cl, sl, rows, addrs, shut, okx, sl2, after });' % (P, P))

case("stream: function pointer callbacks",
     'object S = clone_object("%s"), C = clone_object("%s"); '
     'mixed sr = S->serve_fp(1, 47832); int cr = C->dial_fp(1, "127.0.0.1 47832"); '
     'C->expect(1); test_sock_pump(C, "ready"); int w = C->send("ping"); '
     'S->expect(2); test_sock_pump(S, "ready"); int w2 = S->send_on(S->query_cfd(), "pong"); '
     'C->expect(2); test_sock_pump(C, "ready"); S->shut(S->query_cfd()); C->expect(3); test_sock_pump(C, "ready"); '
     'mixed r = ({ sr, cr, w, w2, C->take(), S->take() }); S->stop(); destruct(S); destruct(C); return r;' % (P, P))

case("stream: int arrays, empty writes, bad types",
     'object S = clone_object("%s"), C = clone_object("%s"); '
     'S->serve(3, 47833); C->dial(1, "127.0.0.1 47833", ({})); C->expect(1); test_sock_pump(C, "ready"); '
     'S->expect(1); test_sock_pump(S, "ready"); '
     'mixed m = ([ "a": 1 ]), f = 1.5; '
     'mixed *w = ({ C->send(({ 1094861636, "skip", 1145258561 })), C->send(""), C->send(({})), C->send(m), C->send(f), C->send("!") }); '
     'S->expect(2); test_sock_pump(S, "ready"); '
     'string got = ""; foreach (mixed *e in S->take()) if (e[0] == "read") got += e[2]; '
     'mixed r = ({ w, got, socket_status(S->query_cfd())[2] }); C->stop(); S->stop(); destruct(S); destruct(C); return r;' % (P, P))

case("stream: a full send buffer, EECALLBACK and the write callback",
     'object S = clone_object("%s"), C = clone_object("%s"); '
     'S->serve(1, 47834); C->dial(1, "127.0.0.1 47834", ({})); C->expect(1); test_sock_pump(C, "ready"); C->take(); '
     'S->expect(1); test_sock_pump(S, "ready"); S->take(); '
     'string big = repeat_string("0123456789", 1600000); S->set_quiet(1); '
     'int w1 = C->send(big), w2 = C->send("more"); '
     'S->expect(sizeof(big)); int ok = test_sock_pump(S, "got_all"); for (int i = 0; i < 5 && !ok; i++) ok = test_sock_pump(S, "got_all"); '
     'C->expect(1); test_sock_pump(C, "ready"); int w3 = C->send("tail"); '
     'S->expect(sizeof(big) + 4); test_sock_pump(S, "got_all"); '
     'mixed r = ({ w1, w2, ok, C->take(), w3, S->query_total() }); C->stop(); S->stop(); destruct(S); destruct(C); return r;' % (P, P))

case("stream: a stalled peer, EECALLBACK, EEALREADY and the write callback",
     'object S = clone_object("%s"), C = clone_object("%s"); S->set_lazy(1); '
     'S->serve(1, 47837); C->dial(1, "127.0.0.1 47837", ({})); C->expect(1); test_sock_pump(C, "ready"); C->take(); '
     'S->expect(1); test_sock_pump(S, "ready"); mixed sl = S->take(); '
     'string mb = repeat_string("0123456789", 100000); int n = 0, w = 1; '
     'while (w == 1 && n < 64) { w = C->send(mb); n++; } '
     'int w2 = C->send("more"); mixed st = socket_status(C->query_cfd())[1]; '
     'S->set_quiet(1); S->accept_now(); mixed al = S->take(); '
     'C->expect(1); int ok = 0; for (int i = 0; i < 5 && !ok; i++) ok = test_sock_pump(C, "ready"); '
     'S->expect(n * sizeof(mb)); int ok2 = test_sock_pump(S, "got_all"); '
     'int w3 = C->send("tail"); S->expect(n * sizeof(mb) + 4); test_sock_pump(S, "got_all"); '
     'mixed r = ({ sl, w, n < 64, w2, st, sizeof(al), al[0][2] >= 0, ok, C->take(), ok2, w3, S->query_total() == n * sizeof(mb) + 4 }); '
     'C->stop(); S->stop(); destruct(S); destruct(C); return r;' % (P, P))

case("stream: callback errors are reported, not fatal",
     'object S = clone_object("%s"), C = clone_object("%s"); S->set_boom(1); S->set_echo(1); '
     'S->serve(1, 47835); C->dial(1, "127.0.0.1 47835", ({ "boom" })); C->expect(2); test_sock_pump(C, "ready"); '
     'S->expect(2); test_sock_pump(S, "ready"); C->send("after"); S->expect(4); test_sock_pump(S, "ready"); '
     'C->expect(3); test_sock_pump(C, "ready"); '
     'mixed r = ({ S->take(), C->take() }); C->stop(); S->stop(); destruct(S); destruct(C); return r;' % (P, P))

case("stream: destructing an end closes its sockets",
     'object S = clone_object("%s"), C = clone_object("%s"); '
     'S->serve(1, 47836); C->dial(1, "127.0.0.1 47836", ({})); C->expect(1); test_sock_pump(C, "ready"); '
     'S->expect(1); test_sock_pump(S, "ready"); int cfd = C->query_cfd(), lfd = S->query_lfd(); '
     'destruct(C); S->expect(2); test_sock_pump(S, "ready"); '
     'mixed r = ({ socket_status(cfd)[0], S->take(), socket_status(S->query_cfd())[0] }); '
     'destruct(S); r += ({ socket_status(lfd)[0..1] }); return r;' % (P, P))

case("stream: release and acquire",
     'object A = clone_object("%s"), B = clone_object("%s"); int fd = A->mine(); '
     'B->set_acquire(1); int r1 = A->give(fd, B); mixed own1 = socket_status(fd)[5] == B; '
     'mixed bl = B->take(); int r2 = A->give(fd, B); '
     'A->set_acquire(0); int r3 = B->give(fd, A); mixed own2 = socket_status(fd)[5] == B; mixed al = A->take(); '
     'int r4 = socket_acquire(fd, "r", "w", "c"); int r5 = B->shut(fd); '
     'destruct(A); destruct(B); return ({ r1, own1, bl, r2, r3, own2, al, r4, r5 });' % (P, P))

case("stream: get_garbage keeps a socket's owner",
     'clone_object("%s")->mine(); int a = count(); children("%s")->stop(); int b = count(); '
     'foreach (object o in children("%s")) if (clonep(o)) destruct(o); return ({ a, b });' % (P, P, P),
     'int count() { return sizeof(filter(get_garbage(), (: base_name($1) == "%s" :))); }' % P)

# --- MUD mode
case("mud mode: values round trip",
     'object S = clone_object("%s"), C = clone_object("%s"); S->set_echo(1); '
     'S->serve(0, 47841); C->dial(0, "127.0.0.1 47841", ({ ({ 1, "two", ([ "k": 3 ]) }) })); '
     'C->expect(4); test_sock_pump(C, "ready"); '
     'mixed *w = ({ C->send(([ "a": ({ 1.5 }) ])), C->send(7), C->send("plain"), C->send(this_object()), C->send(0) }); '
     'C->expect(9); test_sock_pump(C, "ready"); S->expect(11); test_sock_pump(S, "ready"); '
     'mixed r = ({ w, C->take(), S->take() }); C->stop(); S->stop(); destruct(S); destruct(C); return r;' % (P, P))

case("mud mode: frames from a stream peer",
     'object S = clone_object("%s"), C = clone_object("%s"); '
     'S->serve(0, 47842); C->dial(3, "127.0.0.1 47842", ({})); C->expect(1); test_sock_pump(C, "ready"); '
     'S->expect(1); test_sock_pump(S, "ready"); '
     'C->send(({ 5 })); C->send("\\"abc\\""); C->send(({ 6 })); C->send("\\"pa"); test_sock_pump(0, 0); C->send("rt\\""); '
     'C->send(({ 3 })); C->send("xyz"); C->send(({ 2 })); C->send("42"); '
     'S->expect(5); test_sock_pump(S, "ready"); '
     'mixed r = S->take(); C->stop(); S->stop(); destruct(S); destruct(C); return r;' % (P, P))

# --- connects that don't connect
case("connect: refused by config",
     'test_config("havok outbound sockets", "0"); object C = clone_object("%s"); '
     'int r = C->dial(1, "127.0.0.1 47851", ({})); int fd = C->query_cfd(); '
     'mixed st = ({ socket_status(fd)[1], socket_address(fd), socket_address(fd, 1) }); %s '
     'int r2 = C->dial(1, "127.0.0.1 47851", ({})); mixed st2 = socket_status(C->query_cfd())[1]; '
     'C->stop(); socket_close(fd); destruct(C); return ({ r, st, r2, st2 });' % (P, ON))

case("connect: nothing listening",
     'object C = clone_object("%s"); int r = C->dial(1, "127.0.0.1 47852", ({})); int fd = C->query_cfd(); '
     'mixed st = socket_status(fd)[1]; int again = C->conn(fd, "127.0.0.1 47852"); '
     'int ok = 0; C->expect(1); for (int i = 0; i < 6 && !ok; i++) ok = test_sock_pump(C, "ready"); '
     'mixed r2 = ({ r, st, again, ok, C->take(), socket_status(fd)[0..1] }); destruct(C); return r2;' % P)

case("connect: malformed and unresolvable addresses",
     'object C = clone_object("%s"); mixed five = 5; '
     'int fd = C->mine(); mixed *r = ({ C->conn(fd, "127.0.0.1"), C->conn(fd, five), '
     'C->conn(fd, "127.0.0.1 x"), socket_status(fd)[1], '
     'C->conn(fd, "no-such-host.invalid 80"), socket_status(fd)[1], socket_address(fd), '
     'C->conn(fd, "127.0.0.1 80") }); test_sock_pump(0, 0); '
     'r += ({ C->take(), socket_status(fd)[1], C->shut(fd) }); destruct(C); return r;' % P)

# --- datagrams
case("datagram: round trip and addressing errors",
     'object A = clone_object("%s"), B = clone_object("%s"); mixed none; '
     'mixed *ba = ({ A->dbind(2, 47861, none), B->dbind(2, 47862, none) }); '
     'mixed arr = ({ 1 }); '
     'mixed *w = ({ A->dsend("ping", "127.0.0.1 47862"), A->dsend("x", none), A->dsend("x", "nohost"), A->dsend(arr, "127.0.0.1 47862"), A->dsend("", "127.0.0.1 47862") }); '
     'B->expect(2); test_sock_pump(B, "ready"); int w2 = B->dsend("pong", "127.0.0.1 47861"); A->expect(1); test_sock_pump(A, "ready"); '
     'mixed *rows = ({ socket_status(A->query_cfd())[1..4], socket_address(A->query_cfd(), 1), socket_address(A->query_cfd()) }); '
     'mixed r = ({ ba, w, w2, B->take(), A->take(), rows }); A->stop(); B->stop(); destruct(A); destruct(B); return r;' % (P, P))

case("datagram: binary mode, a bound address, an unbound sender",
     'object A = clone_object("%s"), B = clone_object("%s"); mixed none; '
     'mixed *ba = ({ A->dbind(4, 47863, none), B->dbind(4, 47864, "127.0.0.1") }); '
     'int w = A->dsend("bin", "127.0.0.1 47864"); B->expect(1); test_sock_pump(B, "ready"); '
     'int fd = socket_create(4, "r"); int w2 = socket_write(fd, "from nowhere", "127.0.0.1 47864"); '
     'B->expect(2); test_sock_pump(B, "ready"); mixed *bl = B->take(); '
     'mixed *rows = ({ socket_status(B->query_cfd())[1..3], socket_status(fd)[1..3], bl[1][3][0..9], sizeof(bl[1]) }); '
     'bl[1] = bl[1][0..2]; socket_close(fd); '
     'mixed r = ({ ba, w, w2, bl, rows }); A->stop(); B->stop(); destruct(A); destruct(B); return r;' % (P, P))

# --- resolve()
case("resolve: names, failures, callbacks",
     'int k1 = resolve("localhost", "on_res"), k2 = resolve("no-such-host.invalid", (: on_res :)), k3 = resolve("localhost", "no_such_fn"); '
     'mixed bad = 5; mixed e = catch(resolve(bad, "on_res")); '
     'for (int i = 0; i < 6 && sizeof(got) < 2; i++) test_sock_pump(this_object(), "two"); test_sock_pump(0, 0); '
     'mixed *out = ({}); foreach (mixed *g in got) out += ({ ({ g[0], g[1], g[2] - k1 }) }); '
     'return ({ k2 - k1, k3 - k1, e, sort_array(out, (: $1[2] - $2[2] :)) });',
     'mixed *got = ({}); void on_res(string n, mixed ip, int k) { got += ({ ({ n, ip, k }) }); } int two() { return sizeof(got) >= 2; }')

case("m7s remove helpers", 'rm("%s.c"); test_config("havok outbound sockets", "0"); return 1;' % P)

def esc(s):
    return s.replace("\\", "\\\\").replace("\n", "\\n").replace("\t", "\\t")

print("# HavokOS M7 socket cases (todo.md HavokOS P1 #5): the LPC socket efuns and")
print("# resolve() over loopback, through the test_sock_pump()/test_config() hooks.")
print("# GENERATED by tools/gen_m7_sock_cases.py -- edit that, not this file. One case")
print("# per line, <name><TAB><body>; expected results in m7_sock.expected.txt are the")
print("# live Pike driver's own (tools/ref_cases.pike -extra).")
for name, body in CASES:
    print(name + "\t" + esc(body.strip()))

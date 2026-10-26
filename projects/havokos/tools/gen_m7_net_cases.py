"""Generates tests/fixtures/cases/m7_net_cases.txt (todo.md HavokOS P1 #8).

The rest of M7's network: MCCP v2 on telnet connections, the HTTP port and
http_respond(), WebSockets, and TLS (telnet over TLS, HTTPS, STREAM_TLS
sockets). The MCCP cases drive both drivers through the test_tel_* hooks
(efuns_net.star's header) plus test_inflate(), which inflates a zlib stream:
the two drivers compress differently (the reference with Pike's zlib, this
port with zlib.star), so what is compared is the text a client inflates,
never the compressed bytes. The rest go through raw client hooks (see the
section below and tools/ref_net_hooks.pike) on a scratch minilib with
tests/fixtures/netlib laid over it.
Expected results (m7_net.expected.txt) are whatever the live reference
returns (tools/ref_cases.pike -extra), never hand-predicted.

MCCP is off in both case runners (the M6 cases were recorded that way);
each case here turns it on with test_config("havok mccp", "1") -- which
ref_cases.pike passes on to net.pike's flag -- and off again at its end.

Usage: python tools/gen_m7_net_cases.py > tests/fixtures/cases/m7_net_cases.txt
"""

CASES = []


def lpc_str(src):
    """An LPC string literal holding src."""
    return '"' + src.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'


def case(name, body, globals_=""):
    CASES.append((name, (globals_ + " @@ " if globals_ else "") + body))


ON = 'test_config("havok mccp", "1");'
OFF = 'test_config("havok mccp", "0");'
OPEN = ON + ' object u = clone_object("/test/tel_user"); int c = test_tel_open(u); string offers = test_tel_drain(c);'
CLOSE = 'test_tel_hangup(c); if (u) destruct(u); ' + OFF

# --- MCCP v2 ---------------------------------------------------------------------

case("mccp: COMPRESS2 offered when on", OPEN + " " + CLOSE + " return offers;")

case("mccp: refused when off", OFF + """
object u = clone_object("/test/tel_user"); int c = test_tel_open(u); string offers = test_tel_drain(c);
string r = test_tel_say(c, "~ff~fd~56");
mixed m = client_info(u)["mccp"];
test_tel_hangup(c); destruct(u);
return ({ offers, r, m });""")

# run_tests.pike's own MCCP check: the start marker goes out plain, then
# everything is one stream
case("mccp: DO starts the stream after a plain IAC SB COMPRESS2 IAC SE", OPEN + """
string start = test_tel_say(c, "~ff~fd~56");
mixed m = client_info(u)["mccp"];
tell_object(u, "compressed hello\\n");
string z = test_tel_drain(c);
mixed r = ({ start, m, test_inflate(z) });
""" + CLOSE + " return r;")

case("mccp: one stream across writes, drains and input", OPEN + """
test_tel_say(c, "~ff~fd~56");
string all = "";
tell_object(u, "first\\n");
all += test_tel_drain(c);
tell_object(u, "second\\n");
tell_object(u, "third with ~ an iac \\xff byte\\n");
all += test_tel_drain(c);
all += test_tel_say(c, "look~0d~0a");
string big = "";
for (int i = 0; i < 400; i++) big += "The quick brown fox " + i + " jumps over the lazy dog.\\n";
tell_object(u, big);
all += test_tel_drain(c);
tell_object(u, big);
all += test_tel_drain(c);
string text = test_inflate(all);
mixed r = ({ sizeof(text), text[0..200], text[<200..], u->query_log() });
""" + CLOSE + " return r;")

case("mccp: DONT ends the stream, plain after, DO starts a new one", OPEN + """
test_tel_say(c, "~ff~fd~56");
string all = "";
tell_object(u, "before\\n");
all += test_tel_drain(c);
all += test_tel_say(c, "~ff~fe~56");
mixed r = ({ test_inflate(all), client_info(u)["mccp"] });
tell_object(u, "plain again\\n");
r += ({ test_tel_drain(c) });
string again = test_tel_say(c, "~ff~fd~56");
tell_object(u, "second stream\\n");
r += ({ again, test_inflate(test_tel_drain(c)), client_info(u)["mccp"] });
""" + CLOSE + " return r;")

case("mccp: a repeated DO changes nothing", OPEN + """
test_tel_say(c, "~ff~fd~56");
string all = test_tel_say(c, "~ff~fd~56");
tell_object(u, "once\\n");
all += test_tel_drain(c);
mixed r = test_inflate(all);
""" + CLOSE + " return r;")

case("mccp: destructing the user ends the stream", OPEN + """
test_tel_say(c, "~ff~fd~56");
tell_object(u, "last words\\n");
string all = test_tel_drain(c);
destruct(u);
string tail = test_tel_drain(c);
mixed r = ({ test_inflate(all + tail), sizeof(tail) > 0 });
""" + CLOSE + " return r;")


# --- HTTP, WebSocket and TLS (todo.md HavokOS P1 #8) ----------------------------
#
# These run on a scratch copy of the minilib with tests/fixtures/netlib laid
# over it (its /test/web.c is a superset of the reference's own; see its
# header), through the raw client hooks: test_cli_* is a plain byte pipe
# (TLS when asked), so what is compared is exactly what each driver's server
# sent. The helpers below take a reply apart in the `~xx` form: Date and
# Last-Modified (the clock) and Server (each driver names itself) are
# masked, once checked to be well-formed.

def tx(raw):
    """Raw protocol bytes in the hooks' `~xx` form."""
    out = []
    for ch in raw.encode('latin-1'):
        out.append(chr(ch) if 32 <= ch < 127 and ch != 0x7e else '~%02x' % ch)
    return ''.join(out)


def lit(raw):
    """An LPC string literal holding raw's `~xx` form."""
    return lpc_str(tx(raw))


HELP = r'''
int hexval(int c) { return c >= '0' && c <= '9' ? c - '0' : c >= 'a' && c <= 'f' ? c - 'a' + 10 : -1; }
// (linear on purpose: the Star VM keeps every intermediate copy an
// `a += ({ x })` loop makes until the evaluation ends -- todo.md)
int *bytes_of(string s) {
    int *out = allocate(sizeof(s));
    int n = 0;
    for (int i = 0; i < sizeof(s); i++) {
        if (s[i] == '~' && i + 2 < sizeof(s) && hexval(s[i + 1]) >= 0 && hexval(s[i + 2]) >= 0) {
            out[n++] = hexval(s[i + 1]) * 16 + hexval(s[i + 2]);
            i += 2;
        } else out[n++] = s[i];
    }
    return out[0..n - 1];
}
string enc_bytes(int *b) {
    string *p = allocate(sizeof(b));
    for (int i = 0; i < sizeof(b); i++) {
        int c = b[i];
        p[i] = (c >= 32 && c < 127 && c != '~') ? sprintf("%c", c) : sprintf("~%02x", c);
    }
    return implode(p, "");
}
string unx(string s) {
    int *b = bytes_of(s);
    string *p = allocate(sizeof(b));
    for (int i = 0; i < sizeof(b); i++) p[i] = sprintf("%c", b[i]);
    return implode(p, "");
}
int skip_bytes(string s, int at, int n) {
    while (n > 0 && at < sizeof(s)) {
        if (s[at] == '~' && at + 2 < sizeof(s) && hexval(s[at + 1]) >= 0 && hexval(s[at + 2]) >= 0) at += 3;
        else at++;
        n--;
    }
    return at;
}
string mask_line(string l) {
    string a, b; int d, y, h, m, s;
    if (l[0..4] == "Date:" && sscanf(l, "Date: %s, %d %s %d %d:%d:%d GMT", a, d, b, y, h, m, s) == 7) return "Date: *";
    if (l[0..13] == "Last-Modified:" && sscanf(l, "Last-Modified: %s, %d %s %d %d:%d:%d GMT", a, d, b, y, h, m, s) == 7)
        return "Last-Modified: *";
    if (l[0..6] == "Server:") return "Server: *";
    return l;
}
// one reply from the start of got: ({ status line, header lines, body, rest })
mixed *resp1(string got) {
    int e = strsrch(got, "~0d~0a~0d~0a");
    if (e < 0) return ({ "NOHEAD", ({}), got, "" });
    string *lines = explode(got[0..e - 1], "~0d~0a");
    string *hs = ({});
    int len = -1;
    foreach (string l in lines[1..]) {
        hs += ({ mask_line(l) });
        sscanf(l, "Content-Length: %d", len);
    }
    // a 1xx reply (100 Continue, 101 Switching Protocols) has no body
    if (sizeof(lines[0]) > 9 && lines[0][9] == '1') len = 0;
    int start = e + 12;
    int stop = len < 0 ? sizeof(got) : skip_bytes(got, start, len);
    return ({ lines[0], hs, got[start..stop - 1], got[stop..] });
}
mixed resp(string got) { mixed *r = resp1(got); return r[3] == "" ? r[0..2] : r; }
mixed *resps(string got) {
    mixed *out = ({});
    while (sizeof(got)) { mixed *r = resp1(got); out += ({ r[0..2] }); if (r[0] == "NOHEAD") break; got = r[3]; }
    return out;
}
// WebSocket frames, built and taken apart in the `~xx` form
string frame(int op, string payload, int fin, int masked) {
    int n = sizeof(payload);
    int *h = ({ (fin ? 128 : 0) | op });
    int mbit = masked ? 128 : 0;
    if (n < 126) h += ({ mbit | n });
    else if (n < 65536) h += ({ mbit | 126, n >> 8, n & 255 });
    else h += ({ mbit | 127, 0, 0, 0, 0, (n >> 24) & 255, (n >> 16) & 255, (n >> 8) & 255, n & 255 });
    int *mask = ({ 0x37, 0xfa, 0x21, 0x3d });
    if (masked) h += mask;
    int *p = allocate(n);
    for (int i = 0; i < n; i++) p[i] = masked ? payload[i] ^ mask[i % 4] : payload[i];
    return enc_bytes(h + p);
}
mixed *frames(string got) {
    int *b = bytes_of(got);
    mixed *out = ({});
    int i = 0;
    while (i + 2 <= sizeof(b)) {
        int op = b[i] & 15, fin = b[i] >> 7, n = b[i + 1] & 127, h = 2;
        if (n == 126) { n = b[i + 2] * 256 + b[i + 3]; h = 4; }
        else if (n == 127) { n = 0; for (int k = 0; k < 8; k++) n = n * 256 + b[i + 2 + k]; h = 10; }
        if (b[i + 1] & 128) h += 4;
        if (i + h + n > sizeof(b)) break;
        out += ({ ({ op, fin, n < 300 ? enc_bytes(b[i + h..i + h + n - 1]) : n }) });
        i += h + n;
    }
    if (i < sizeof(b)) out += ({ ({ "rest", enc_bytes(b[i..]) }) });
    return out;
}
string WSKEY = "dGhlIHNhbXBsZSBub25jZQ==";
string upgrade(string extra) {
    return "GET /chat HTTP/1.1~0d~0aHost: x~0d~0aUpgrade: websocket~0d~0aConnection: Upgrade~0d~0a"
        "Sec-WebSocket-Key: " + WSKEY + "~0d~0aSec-WebSocket-Version: 13~0d~0a" + extra + "~0d~0a";
}
object newest_user() { object *u = users(); return sizeof(u) ? u[<1] : 0; }
'''


def http_case(name, request, until='1', secure=0, post=''):
    """One request on a fresh connection: the reply, taken apart."""
    case(name, f'''
int port = test_http_listen({secure});
int c = test_cli_open(port, {secure});
test_cli_send(c, {lit(request)});
string got = test_cli_recv(c, {until});
mixed r = resp(got);
{post}
test_ports_close();
return r;''', HELP)


def answer_case(name, answer_json, method='POST', extra='', sort=False):
    """What the driver makes of an http_request() answer (/answer: the body is the answer, as JSON).

    sort: compare the header lines sorted -- an answer's extra headers go out
    in Pike's hash order on the reference, which changes from run to run."""
    req = f'{method} /answer HTTP/1.0\r\n{extra}Content-Length: {len(answer_json)}\r\n\r\n{answer_json}'
    http_case(name, req, post='r = ({ r[0], sort_array(r[1], 1), r[2] });' if sort else '')


# the reference's own run_tests.pike HTTP checks
http_case("http: a string answer is a 200 page", "GET /hello HTTP/1.0\r\n\r\n")
case("http: request mapping, status, type and headers", f'''
int port = test_http_listen(0);
int c = test_cli_open(port, 0);
test_cli_send(c, {lit("POST /echo?x=1 HTTP/1.0" + chr(13) + chr(10) + "Cookie: c=v" + chr(13) + chr(10) + "User-Agent: t" + chr(13) + chr(10) + "Content-Type: application/x-www-form-urlencoded" + chr(13) + chr(10) + "Content-Length: 3" + chr(13) + chr(10) + chr(13) + chr(10) + "a=b")});
mixed r = resp(test_cli_recv(c, 1));
test_ports_close();
return ({{ r[0], r[1], json_decode(unx(r[2])) }});''', HELP)
http_case("http: a mudlib file", "GET /file HTTP/1.0\r\n\r\n")
case("http: keep-alive serves a second request on the connection", f'''
int port = test_http_listen(0);
int c = test_cli_open(port, 0);
test_cli_send(c, {lit("GET /hello HTTP/1.1" + chr(13) + chr(10) + "Host: x" + chr(13) + chr(10) + chr(13) + chr(10))});
string got = test_cli_recv(c, "<b>hi</b>");
test_cli_send(c, {lit("GET /file HTTP/1.1" + chr(13) + chr(10) + "Host: x" + chr(13) + chr(10) + chr(13) + chr(10))});
got += test_cli_recv(c, "plain file");
mixed r = ({{ resps(got), test_cli_closed(c) }});
test_ports_close();
return r;''', HELP)
case("http: status codes, nothing, errors", '''
int port = test_http_listen(0);
mixed r = ({});
foreach (string p in ({ "/teapot", "/nothing", "/boom" })) {
    int c = test_cli_open(port, 0);
    test_cli_send(c, "GET " + p + " HTTP/1.0~0d~0a~0d~0a");
    r += ({ resp(test_cli_recv(c, 1)) });
}
test_ports_close();
return r;''', HELP)
case("http: an answer given later with http_respond()", '''
object web = load_object("/test/web");
int port = test_http_listen(0);
int c = test_cli_open(port, 0);
test_cli_send(c, "GET /later HTTP/1.0~0d~0a~0d~0a");
string early = test_cli_recv(c, 0);
int answered = http_respond(web->query_later(), ([ "body": "late", "type": "text/plain" ]));
mixed r = ({ early, answered, resp(test_cli_recv(c, 1)), http_respond(web->query_later(), "again") });
test_ports_close();
return r;''', HELP)

# the request: what http_request() gets
REQ = '''
int port = test_http_listen(0);
int c = test_cli_open(port, 0);
test_cli_send(c, %s);
mixed r = resp(test_cli_recv(c, 1));
test_ports_close();
return ({ r[0], r[1], member_array("Content-Type: application/json", r[1]) >= 0 ? json_decode(unx(r[2])) : r[2] });'''


def req_case(name, request):
    case(name, REQ % lit(request), HELP)


CRLF = "\r\n"
req_case("http request: query variables, repeated headers and cookies",
         "GET /req?a=1&a=2&b=%41+c&d&e=&%7a=q HTTP/1.0\r\nX-Mixed-Case: One\r\nx-mixed-case: Two\r\n"
         "Cookie: a=1; b=2; a=3\r\nCookie: d=4\r\nUser-Agent:   spaced value  \r\n\r\n")
req_case("http request: the path is not decoded, the query is kept raw",
         "GET /req%20x/../a%20b%2fc+d?q=%u0041%42&r=%7e&s=a%2bb+c HTTP/1.0\r\n\r\n")
req_case("http request: urlencoded body variables join the query's",
         "POST /req?x=1&y=2 HTTP/1.0\r\nContent-Type: application/x-www-form-urlencoded; charset=utf-8\r\n"
         "Content-Length: 15\r\n\r\nx=3&z=%26+%3d&w")
req_case("http request: a body without urlencoded type stays raw",
         "POST /req HTTP/1.0\r\nContent-Type: text/plain\r\nContent-Length: 7\r\n\r\na=b&c=d")
req_case("http request: chunked body", "POST /req HTTP/1.1\r\nHost: x\r\nTransfer-Encoding: chunked\r\n"
         "Connection: close\r\n\r\n3\r\nabc\r\nA;ext=1\r\n0123456789\r\n0\r\nX-Trailer: t\r\n\r\n")
req_case("http request: multipart form data",
         "POST /req HTTP/1.0\r\nContent-Type: multipart/form-data; boundary=XyZ\r\nContent-Length: %d\r\n\r\n%s" % (
             len(b := "--XyZ\r\nContent-Disposition: form-data; name=\"f\"\r\n\r\nval\r\n--XyZ\r\n"
                      "Content-Disposition: form-data; name=\"up\"; filename=\"a.txt\"\r\nContent-Type: text/plain\r\n\r\n"
                      "file body\r\n--XyZ\r\nContent-Disposition: form-data; name=\"f\"\r\n\r\nagain\r\n--XyZ--\r\n"), b))
req_case("http request: method, protocol and header oddities",
         "\r\n\r\nput /req?z HTTP/1.1\r\nHost: x\r\nConnection: close\r\nNoColonLine\r\n  Folded: x\r\nEmpty:\r\n"
         "Content-Length: 4\r\nContent-Length: 2\r\n\r\nabcd")
req_case("http request: absolute URI and HTTP/0.9", "GET http://example.com/req?z=1 HTTP/1.1\r\nHost: x\r\nConnection: close\r\n\r\n")
req_case("http request: bare LF line ends", "GET /req?lf=1 HTTP/1.0\nX-A: b\n\n")
req_case("http request: HTTP/1.1 without Host", "GET /req HTTP/1.1\r\nConnection: close\r\n\r\n")
http_case("http: a request line with no protocol is HTTP/0.9 answered as 1.0", "GET /hello\r\n\r\n")
http_case("http: an unparseable request line", "GARBAGE\r\n\r\n")
http_case("http: an unknown protocol version", "GET /hello HTTP/2.5\r\nConnection: close\r\n\r\n")
http_case("http: HEAD sends the headers only", "HEAD /hello HTTP/1.0\r\n\r\n")
http_case("http: HTTP/1.0 with keep-alive asked keeps the connection",
          "GET /hello HTTP/1.0\r\nConnection: Keep-Alive\r\n\r\n", until='"<b>hi</b>"',
          post='r = ({ r, test_cli_closed(c) });')
http_case("http: HTTP/1.1 with close asked closes", "GET /hello HTTP/1.1\r\nHost: x\r\nConnection: close\r\n\r\n")
case("http: Expect 100-continue", f'''
int port = test_http_listen(0);
int c = test_cli_open(port, 0);
test_cli_send(c, {lit("POST /hello HTTP/1.1" + CRLF + "Host: x" + CRLF + "Expect: 100-continue" + CRLF + "Connection: close" + CRLF + "Content-Length: 2" + CRLF + CRLF + "hi")});
mixed r = resps(test_cli_recv(c, 1));
test_ports_close();
return r;''', HELP)
http_case("http: a byte range of a page", "GET /hello HTTP/1.0\r\nRange: bytes=1-3\r\n\r\n")
http_case("http: a suffix range", "GET /hello HTTP/1.0\r\nRange: bytes=-4\r\n\r\n")
http_case("http: an open range", "GET /hello HTTP/1.0\r\nRange: bytes=5-\r\n\r\n")
http_case("http: a range past the end", "GET /hello HTTP/1.0\r\nRange: bytes=20-30\r\n\r\n")
http_case("http: several ranges", "GET /hello HTTP/1.0\r\nRange: bytes=0-1,3-4\r\n\r\n")

case("http: pipelined requests in one packet: the second is dropped", f'''
int port = test_http_listen(0);
int c = test_cli_open(port, 0);
test_cli_send(c, {lit("GET /hello HTTP/1.1" + CRLF + "Host: x" + CRLF + CRLF + "GET /teapot HTTP/1.1" + CRLF + "Host: x" + CRLF + CRLF)});
string got = test_cli_recv(c, "<b>hi</b>");
got += test_cli_recv(c, 0);
mixed r = ({{ resps(got), test_cli_closed(c) }});
test_cli_send(c, {lit("GET /file HTTP/1.1" + CRLF + "Host: x" + CRLF + "Connection: close" + CRLF + CRLF)});
r += ({{ resps(test_cli_recv(c, 1)) }});
test_ports_close();
return r;''', HELP)
case("http: a request in pieces", f'''
int port = test_http_listen(0);
int c = test_cli_open(port, 0);
test_cli_send(c, "GET /he");
string a = test_cli_recv(c, 0);
test_cli_send(c, "llo HTTP/1.0~0d~0aX: y~0d~0a");
string b = test_cli_recv(c, 0);
test_cli_send(c, "~0d~0a");
mixed r = ({{ a, b, resp(test_cli_recv(c, 1)) }});
c = test_cli_open(port, 0);
test_cli_send(c, {lit("POST /req HTTP/1.0" + CRLF + "Content-Length: 10" + CRLF + CRLF + "abc")});
string d = test_cli_recv(c, 0);
test_cli_send(c, "defghij");
mixed e = resp(test_cli_recv(c, 1));
r += ({{ d, e[0], json_decode(unx(e[2]))["body"] }});
test_ports_close();
return r;''', HELP)
case("http: a large body", '''
int port = test_http_listen(0);
int c = test_cli_open(port, 0);
string body = "";
for (int i = 0; i < 2000; i++) body += "0123456789abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGHIJ" + i + "\\n";
test_cli_send(c, "POST /req HTTP/1.0~0d~0aContent-Length: " + sizeof(body) + "~0d~0a~0d~0a");
for (int i = 0; i < sizeof(body); i += 10000) test_cli_send(c, replace_string(body[i..i + 9999], "\\n", "~0a"));
mixed r = resp(test_cli_recv(c, 1));
mapping m = json_decode(unx(r[2]));
test_ports_close();
return ({ r[0], sizeof(body), sizeof(m["body"]), m["body"] == body, m["headers"] });''', HELP)
case("http: the client goes before a late answer", '''
object web = load_object("/test/web");
int port = test_http_listen(0);
int c = test_cli_open(port, 0);
test_cli_send(c, "GET /later HTTP/1.0~0d~0a~0d~0a");
test_cli_recv(c, 0);
test_cli_close(c);
mixed r = ({ http_respond(web->query_later(), "too late"), http_respond(web->query_later(), "again") });
test_ports_close();
return r;''', HELP)
case("http: an unanswered request times out with 504", '''
test_config("havok http timeout", "1");
int port = test_http_listen(0);
int c = test_cli_open(port, 0);
test_cli_send(c, "GET /later HTTP/1.0~0d~0a~0d~0a");
mixed r = resp(test_cli_recv(c, 1));
test_config("havok http timeout", "30");
test_ports_close();
return r;''', HELP)
case("http_respond() with no such request", 'return ({ http_respond(12345, "x"), http_respond(0, 200) });')

# answers: what the driver makes of each kind
answer_case("http answer: a status, headers and a type",
            '{"status":302,"type":"text/x-a","body":"moved","headers":{"Location":"/x"}}')
answer_case("http answer: a header with several values", '{"headers":{"Set-Cookie":["a=1","b=2"]}}')
answer_case("http answer: header names are capitalized, odd values dropped",
            '{"headers":{"x-lower":"v","content-type":"over/ride","num":5,"Arr":[]}}', sort=True)
answer_case("http answer: a status as a string, a body that isn't one", '{"status":"203","body":17}')
answer_case("http answer: an unknown status", '{"status":299}')
answer_case("http answer: a status the text table lacks, as a bare int", '299')
answer_case("http answer: 200 as a bare int", '200')
answer_case("http answer: 0 is 404", '0')
answer_case("http answer: an empty mapping", '{}')
answer_case("http answer: an array is a bad answer", '[1,2]')
answer_case("http answer: a float is a bad answer", '1.5')
answer_case("http answer: a file with a status and a type",
            '{"file":"/test/web.txt","status":202,"type":"x/y","headers":{"X-F":"1"}}')
answer_case("http answer: a missing file is 404", '{"file":"/test/nope.txt"}')
answer_case("http answer: a file path is made absolute", '{"file":"test/../test/web.txt"}')
answer_case("http answer: a status with no text and its 404 body", '{"status":404}')
answer_case("http answer: an ETag the client has", '{"body":"x","headers":{"ETag":"abc"}}',
            extra='If-None-Match: abc\r\n')
answer_case("http answer: a range on a mapping answer is ignored", '{"body":"0123456789"}', extra='Range: bytes=2-4\r\n')
case("http answer: file types follow the extension", '''
foreach (string f in ({ "a.html", "a.HTM", "a.css", "a.js", "a.json", "a.png", "a.gif", "a.jpg", "a.svg", "a.txt",
                       "a.c", "a.xml", "a.ico", "a.mp3", "a.wasm", "a.zzz", "noext", "dir.d/x", "a.tar.gz" }))
    test_put("/test/tmp_types/" + f, "data");
int port = test_http_listen(0);
mapping r = ([]);
foreach (string f in ({ "a.html", "a.HTM", "a.css", "a.js", "a.json", "a.png", "a.gif", "a.jpg", "a.svg", "a.txt",
                       "a.c", "a.xml", "a.ico", "a.mp3", "a.wasm", "a.zzz", "noext", "dir.d/x", "a.tar.gz" })) {
    string j = "{\\"file\\":\\"/test/tmp_types/" + f + "\\"}";
    int c = test_cli_open(port, 0);
    test_cli_send(c, "POST /answer HTTP/1.0~0d~0aContent-Length: " + sizeof(j) + "~0d~0a~0d~0a" + j);
    mixed x = resp(test_cli_recv(c, 1));
    r[f] = x[0] + " | " + x[1][0];
}
test_ports_close();
test_rmtree("/test/tmp_types");
return r;''', HELP)

# WebSocket
WS_OPEN = '''
"/secure/master"->set_connect("/test/tel_user");
int port = test_http_listen(0);
int c = test_cli_open(port, 0);
'''
WS_CLOSE = '''
test_ports_close();
"/secure/master"->set_connect(0);
foreach (object o in users()) if (base_name(o) == "/test/tel_user") destruct(o);
'''
case("websocket: the handshake, then text frames are lines", WS_OPEN + '''
test_cli_send(c, upgrade(""));
mixed hs = resp1(test_cli_recv(c, "~0d~0a~0d~0a"));
object u = newest_user();
test_cli_send(c, frame(1, "look\\nsmile", 1, 1));
string got = test_cli_recv(c, 0);
mixed ci = client_info(u);
mixed r = ({ hs[0], sort_array(hs[1], 1), u && u->query_log(), frames(got), ci["websocket"], ci["tls"], ci["utf8"], interactive(u) });
''' + WS_CLOSE + 'return r;', HELP)
case("websocket: output as text frames, one per write, Latin-1 as UTF-8", WS_OPEN + '''
test_cli_send(c, upgrade(""));
test_cli_recv(c, "~0d~0a~0d~0a");
object u = newest_user();
tell_object(u, "Hello \\xe9\\n");
tell_object(u, "caf\\xc3\\xa9 ok\\n");
tell_object(u, "second\\n");
string big = "";
for (int i = 0; i < 30; i++) big += "line " + i + " of a long one\\n";
tell_object(u, big);
mixed r = frames(test_cli_recv(c, 0));
''' + WS_CLOSE + 'return r;', HELP)
case("websocket: unmasked and fragmented frames, binary in text mode", WS_OPEN + '''
test_cli_send(c, upgrade(""));
test_cli_recv(c, "~0d~0a~0d~0a");
object u = newest_user();
test_cli_send(c, frame(1, "plain", 1, 0));
test_cli_send(c, frame(1, "frag", 0, 1) + frame(0, "ment", 1, 1));
test_cli_send(c, frame(2, "bin\\nary\\n", 1, 1));
test_cli_recv(c, 0);
mixed r = u->query_log();
''' + WS_CLOSE + 'return r;', HELP)
case("websocket: ping is answered with pong", WS_OPEN + '''
test_cli_send(c, upgrade(""));
test_cli_recv(c, "~0d~0a~0d~0a");
object u = newest_user();
test_cli_send(c, frame(9, "are you there", 1, 1));
mixed r = ({ frames(test_cli_recv(c, 0)), u->query_log() });
test_cli_send(c, frame(10, "unasked pong", 1, 1));
r += ({ frames(test_cli_recv(c, 0)), u->query_log() });
''' + WS_CLOSE + 'return r;', HELP)
case("websocket: the client's close is echoed and the user goes net-dead", WS_OPEN + '''
test_cli_send(c, upgrade(""));
test_cli_recv(c, "~0d~0a~0d~0a");
object u = newest_user();
test_cli_send(c, enc_bytes(({ 0x88, 0x82, 1, 2, 3, 4, 0x03 ^ 1, 0xe9 ^ 2 })));
string got = test_cli_recv(c, 0);
mixed r = ({ frames(got), interactive(u), test_cli_closed(c) });
test_cli_send(c, frame(1, "after close", 1, 1));
r += ({ test_cli_recv(c, 0), u->query_log() });
''' + WS_CLOSE + 'return r;', HELP)
case("websocket: destructing the user sends a close frame", WS_OPEN + '''
test_cli_send(c, upgrade(""));
test_cli_recv(c, "~0d~0a~0d~0a");
object u = newest_user();
destruct(u);
string got = test_cli_recv(c, 0);
mixed r = ({ frames(got), test_cli_closed(c) });
test_cli_send(c, enc_bytes(({ 0x88, 0x80, 9, 9, 9, 9 })));
r += ({ test_cli_recv(c, 1), test_cli_closed(c) });
''' + WS_CLOSE + 'return r;', HELP)
case("websocket: the telnet subprotocol carries raw telnet in binary frames", WS_OPEN + '''
test_cli_send(c, upgrade("Sec-WebSocket-Protocol: chat, telnet~0d~0a"));
mixed hs = resp1(test_cli_recv(c, "~0d~0a~0d~0a"));
string offers = hs[3] + test_cli_recv(c, 0);
object u = newest_user();
test_cli_send(c, frame(2, "\\xff\\xfb\\x18x\\r\\n", 1, 1));
string more = test_cli_recv(c, 0);
test_cli_send(c, frame(1, "text line", 1, 1));
test_cli_recv(c, 0);
mixed ci = client_info(u);
mixed r = ({ sort_array(hs[1], 1), frames(offers), frames(more), u->query_log(), ci["websocket"], ci["utf8"] });
''' + WS_CLOSE + 'return r;', HELP)
case("websocket: a long frame each way", WS_OPEN + '''
test_cli_send(c, upgrade(""));
test_cli_recv(c, "~0d~0a~0d~0a");
object u = newest_user();
string line = "";
for (int i = 0; i < 40; i++) line += "word" + i + " ";
test_cli_send(c, frame(1, line, 1, 1));
test_cli_recv(c, 0);
mixed log = u->query_log();
string big = "";
for (int i = 0; i < 7000; i++) big += "0123456789";
tell_object(u, big);
mixed r = ({ sizeof(log[0][1]), log[0][1] == line, frames(test_cli_recv(c, 0)) });
''' + WS_CLOSE + 'return r;', HELP)
for nm, extra, req_line in [
    ("version 8", "Sec-WebSocket-Version: 8", None),
    ("a short key", "Sec-WebSocket-Key: c2hvcnQ=", None),
    ("no Connection: Upgrade", None, None),
    ("HTTP/1.0", None, "HTTP/1.0"),
]:
    base = ("GET /chat HTTP/1.1\r\nHost: x\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
            "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n")
    if nm == "version 8":
        base = base.replace("Sec-WebSocket-Version: 13", extra)
    elif nm == "a short key":
        base = base.replace("Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==", extra)
    elif nm == "no Connection: Upgrade":
        base = base.replace("Connection: Upgrade", "Connection: keep-alive")
    else:
        base = base.replace("HTTP/1.1", "HTTP/1.0")
    http_case(f"websocket: not an upgrade with {nm}", base + "\r\n", until='"~0d~0a~0d~0a"',
              post='r = r[0..1];')

# TLS
case("tls telnet: offers arrive decrypted, input reaches the user, output, net-dead", '''
"/secure/master"->set_connect("/test/tel_user");
int port = test_tel_listen(1);
int c = test_cli_open(port, 1);
string offers = test_cli_recv(c, "~ff~fb*");
object u = newest_user();
test_cli_send(c, "hello~0d~0a");
test_cli_recv(c, 0);
mixed ci = client_info(u);
mixed r = ({ offers, u && u->query_log(), ci["tls"], ci["websocket"] });
tell_object(u, "over tls\\n");
r += ({ test_cli_recv(c, "over tls") });
test_cli_close(c);
r += ({ interactive(u) });
test_ports_close();
"/secure/master"->set_connect(0);
if (u) destruct(u);
return r;''', HELP)
case("tls: a plain client on a TLS port gets nowhere", '''
"/secure/master"->set_connect("/test/tel_user");
int port = test_tel_listen(1);
int n = sizeof(users());
int c = test_cli_open(port, 0);
test_cli_send(c, "hello~0d~0a~0d~0a");
test_cli_recv(c, 1);
mixed r = ({ test_cli_closed(c), sizeof(users()) - n });
test_ports_close();
"/secure/master"->set_connect(0);
return r;''', HELP)
case("https: the same request mapping over TLS", f'''
int port = test_http_listen(1);
int c = test_cli_open(port, 1);
test_cli_send(c, {lit("GET /echo HTTP/1.0" + CRLF + CRLF)});
mixed r = resp(test_cli_recv(c, 1));
test_ports_close();
return ({{ r[0], json_decode(unx(r[2]))["secure"] }});''', HELP)
case("https: keep-alive and a websocket over TLS", '''
"/secure/master"->set_connect("/test/tel_user");
int port = test_http_listen(1);
int c = test_cli_open(port, 1);
test_cli_send(c, "GET /hello HTTP/1.1~0d~0aHost: x~0d~0a~0d~0a");
mixed a = resp(test_cli_recv(c, "<b>hi</b>"));
test_cli_send(c, upgrade(""));
mixed hs = resp1(test_cli_recv(c, "~0d~0a~0d~0a"));
object u = newest_user();
test_cli_send(c, frame(1, "secure line", 1, 1));
test_cli_recv(c, 0);
mixed ci = client_info(u);
mixed r = ({ a[0], hs[0], u->query_log(), ci["tls"], ci["websocket"] });
test_ports_close();
"/secure/master"->set_connect(0);
if (u) destruct(u);
return r;''', HELP)
case("STREAM_TLS: a listening socket serves TLS", '''
object fx = clone_object("/test/tls_sock");
int port = test_free_port();
int lr = fx->listen_on(port);
int c = test_cli_open(port, 1);
test_cli_send(c, "ping");
string got = test_cli_recv(c, "echo:");
mixed r = ({ lr, fx->query_got(), got, fx->query_mode() });
test_cli_close(c);
fx->stop();
destruct(fx);
test_ports_close();
return r;''', HELP)
case("STREAM_TLS: a connecting socket does the client handshake", '''
test_config("havok outbound sockets", "1");
int port = test_srv_listen(1);
object fx = clone_object("/test/tls_sock");
int cr = fx->connect_to("127.0.0.1 " + port);
int s = test_srv_take(port);
string hello = test_cli_recv(s, "hello");
test_cli_send(s, "hi lpc");
test_cli_recv(s, 0);
mixed r = ({ cr, hello, fx->query_got(), fx->query_events()[0], fx->query_mode() });
fx->stop();
destruct(fx);
test_config("havok outbound sockets", "0");
test_ports_close();
return r;''', HELP)
# (Not here: a STREAM_TLS connect whose peer answers with something that
# isn't TLS. The reference reports nothing to LPC and leaves the socket open;
# this driver closes it and calls the close callback -- NOTES.md deviation
# #24.)


def esc(s):
    return s.replace("\\", "\\\\").replace("\n", "\\n").replace("\t", "\\t")


print("# HavokOS P1 #8 cases (todo.md HavokOS P1 #8): MCCP v2, the HTTP port, WebSockets")
print("# and TLS, through the test_* hooks. GENERATED by tools/gen_m7_net_cases.py -- edit that,")
print("# not this file. One case per line, <name><TAB><body>; expected results in")
print("# m7_net.expected.txt are the live Pike driver's own (tools/ref_cases.pike -extra).")
for name, body in CASES:
    print(name + "\t" + esc(body.strip()))

# The HTTP port and WebSockets -- todo.md HavokOS P1 #8: `havok/http.pike`
# and, beneath it, the behavior of Pike's Protocols.HTTP.Server.Request and
# Protocols.WebSocket that the reference serves through, probed on the live
# reference first (tests/fixtures/cases/m7_net_cases.txt) and read in Pike's
# own library where a probe couldn't show the rule (Request.pike; Pike's
# library is the reference's runtime, not FluffOS, so the clean room
# allows it).
#
# `external_port_N : http <port>` in the config (over TLS with
# `external_port_N_tls`). Every request becomes one call of the master's
#   mixed http_request(mapping request)
# with request = ([ "id", "method", "path", "query", "variables", "headers"
# (lower-case names), "cookies", "body", "ip", "port", "secure" ]), and the
# answer -- a mapping ([ "status", "type", "headers", "body" ]) or
# ([ "file": "/www/x.png" ]), a string (a 200 page), a status code, -1 (no
# answer yet: http_respond(id, answer) later, 504 after `havok http
# timeout` seconds), 0 or an error (404 / 500) -- goes back as the
# reference's server writes it. A WebSocket upgrade becomes an interactive
# connection instead (net.star): the master's connect(port) names the
# object, which gets logon(); with the "telnet" subprotocol binary frames
# carry raw telnet, otherwise each text frame is a line and output goes out
# as text frames.
#
# The request, as Pike's parser makes it (each point checked by a case):
# - Leading whitespace before the request line is skipped; the head ends at
#   an empty line, LF or CRLF line ends alike. Header names are
#   lower-cased (leading spaces kept), values lose their leading
#   whitespace only; a line without a colon is dropped. A header given
#   more than once is an array, except content-length, content-type,
#   connection, transfer-encoding, if-modified-since, date, pragma and
#   range (the last one counts) and cookie/cookie2 (joined with ";").
# - The request line splits at single spaces: "GET /p HTTP/1.1"; one word
#   is HTTP/0.9 GET of that path; a last word not starting "HTTP" makes it
#   HTTP/0.9 with the rest as the path. The path is never decoded; the
#   query is everything after the first "?".
# - Variables come from the query, then (once the body is in) an
#   urlencoded body or a multipart/form-data one; a repeated name becomes
#   an array; "+" is a space except in a bare name; a multipart file field
#   also sets "<name>.filename" and, as Pike does, "<name>.mimetype" to the
#   file name.
# - The body is Content-Length bytes (a PUT doesn't wait for it), or a
#   chunked body (its trailers join the headers, and content-length is set
#   to its size). Anything after the request in the same read is dropped,
#   so a pipelined second request goes unanswered, as there.
# - "Expect: 100-continue" is answered at once with HTTP/1.1 100 Continue.
#
# The reply, as Pike's response_and_finish() writes it: the status line
# (the request's protocol, HTTP/1.0 unless it was 1.1; Pike's own status
# texts, "<code> ERROR" for one it lacks), Content-Type, Content-Length,
# Server, Date, Last-Modified (always now: an answer's file is read into
# the body first), the answer's headers (names capitalized, one line per
# value of an array), Connection: keep-alive (HTTP/1.1 unless "close" was
# asked, or HTTP/1.0 asking keep-alive) or close. Its quirks are kept: a
# Range header applies only to a plain string answer, with the byte
# arithmetic Pike gets wrong (Content-Length stays the whole size, the
# body runs from the start offset to the end, a suffix range is always
# 416, and the connection closes after any reply whose length it
# miscounted); an ETag the client already has (If-None-Match) is 304; HEAD
# gets the headers only.
#
# Deliberate differences (NOTES.md deviation #23): the Server header names
# this driver (SERVER_ID, where the reference's is Pike's HTTP module); a malformed %-escape in the query or an urlencoded body
# (which makes Pike's parser throw inside its event loop, leaving the client
# unanswered for good) closes the connection; %uXXXX escapes above U+00FF
# and wide text become UTF-8 bytes (deviation #14); the extra headers of an
# answer go out in the mapping's order, where the reference's follow Pike's
# hash order; and the 1 MB request size limit cuts the body to nothing
# rather than whatever Pike's buffer read gives.
#
# Shape: an accepted connection is an HttpConn (netdata.star) in
# `Vm.https`, read and written by net.star's one poll like everything else
# (net_poll() calls http_ready()/http_flush()); a TLS port's connections
# start with the handshake (tls.star). While an answer is awaited the
# socket isn't read, as the reference's request goes blocking; requests
# waiting for http_respond() are `Vm.http_pending`.

import "value.star" as val
import "vm.star" as vm
import "netdata.star" as nd
import "sha1.star" as sh
import "mimetypes.star" as mt
import "paths.star" as paths
import "efun_table.star" as et

# the request size limit (http.pike: set_max_request_size(1 << 20))
const MAX_REQUEST: i32 = 1048576
# Pike's Request: connection_timeout_delay, send_timeout_delay (seconds)
const CONN_TIMEOUT_MS: i32 = 180000
const WS_GUID: str = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
# the Server header: this driver, with the version __VERSION__ gives
# (preprocess.star), where the reference names Pike's HTTP module
const SERVER_ID: str = "HavokOS/0.2 (Star)"

fn lower_ascii(s: str) -> str:
    let b = bytes_from_str(s)
    let mut o: Bytes = Bytes()
    for i in 0..b.len():
        let c = b[i] as i32
        o.push(if c >= 65 and c <= 90: (c + 32) as u8 else: b[i])
    str_from_bytes(o)

fn is_white(c: i32) -> bool:
    c == 32 or c == 9 or c == 10 or c == 13

# String.trim_whites() (spaces and tabs) / trim_all_whites() (and newlines)
fn trim_all(s: str) -> str:
    let b = bytes_from_str(s)
    let mut a = 0
    let mut e = b.len()
    while a < e and is_white(b[a] as i32):
        a += 1
    while e > a and is_white(b[e - 1] as i32):
        e -= 1
    vm::substr(s, a, e)

fn sub_bytes(b: Bytes, a: i32, e: i32) -> Bytes:
    let mut o: Bytes = Bytes()
    let mut i = a
    while i < e:
        o.push(b[i])
        i += 1
    o

fn push_str(o: Bytes, s: str) -> Bytes:
    let mut r = o
    let t = bytes_from_str(s)
    for i in 0..t.len():
        r.push(t[i])
    r

fn hex_digit(c: i32) -> i32:
    if c >= 48 and c <= 57:
        return c - 48
    if c >= 97 and c <= 102:
        return c - 87
    if c >= 65 and c <= 70:
        return c - 55
    -1

# One character as UTF-8 (a %u escape above U+00FF, deviation #14).
fn utf8_of(cp: i32) -> Bytes:
    let mut o: Bytes = Bytes()
    if cp < 128:
        o.push(cp as u8)
    elif cp < 2048:
        o.push((192 | (cp >> 6)) as u8)
        o.push((128 | (cp & 63)) as u8)
    else:
        o.push((224 | (cp >> 12)) as u8)
        o.push((128 | ((cp >> 6) & 63)) as u8)
        o.push((128 | (cp & 63)) as u8)
    o

# Pike's http_decode_string(): %XX and %uXXXX; "" with ok false for a
# truncated or illegal escape (where Pike throws).
struct Decoded:
    ok: bool
    s: str

fn url_decode(s: str) -> Decoded:
    let b = bytes_from_str(s)
    let mut o: Bytes = Bytes()
    let mut i = 0
    while i < b.len():
        let c = b[i] as i32
        if c != 37:
            o.push(b[i])
            i += 1
            continue
        if i + 1 < b.len() and ((b[i + 1] as i32) == 117 or (b[i + 1] as i32) == 85):
            if i + 5 >= b.len():
                return Decoded(ok = false, s = "")
            let mut cp = 0
            for k in 2..6:
                let d = hex_digit(b[i + k] as i32)
                if d < 0:
                    return Decoded(ok = false, s = "")
                cp = cp * 16 + d
            if cp < 256:
                o.push(cp as u8)
            else:
                let u = utf8_of(cp)
                for k in 0..u.len():
                    o.push(u[k])
            i += 6
            continue
        if i + 2 >= b.len():
            return Decoded(ok = false, s = "")
        let hi = hex_digit(b[i + 1] as i32)
        let lo = hex_digit(b[i + 2] as i32)
        if hi < 0 or lo < 0:
            return Decoded(ok = false, s = "")
        if hi * 16 + lo == 0:
            # a NUL can't be held (deviation #7): it ends the value
            return Decoded(ok = true, s = str_from_bytes(o))
        o.push((hi * 16 + lo) as u8)
        i += 3
    Decoded(ok = true, s = str_from_bytes(o))

# Name/value lists in first-seen order, a repeated name collecting values
# (Pike's mapping of string or array).
struct NamedVals:
    mut names: List<str> = List<str>()
    mut vals: List<List<str>> = List<List<str>>()

impl NamedVals:
    fn add(mut self, k: str, v: str):
        for i in 0..self.names.len():
            if self.names[i] == k:
                self.vals[i].push(v)
                return
        self.names.push(k)
        self.vals.push([v])

    fn put(mut self, k: str, v: str):
        for i in 0..self.names.len():
            if self.names[i] == k:
                self.vals[i] = [v]
                return
        self.names.push(k)
        self.vals.push([v])

    fn get1(self, k: str) -> str:
        for i in 0..self.names.len():
            if self.names[i] == k and self.vals[i].len() > 0:
                return self.vals[i][self.vals[i].len() - 1]
        ""

    fn has(self, k: str) -> bool:
        for i in 0..self.names.len():
            if self.names[i] == k:
                return true
        false

    # http_decode_urlencoded_query(); false on a bad escape
    fn add_query(mut self, q: str) -> bool:
        let parts = str_split(q, "&")
        for i in 0..parts.len():
            let s = parts[i]
            let eq = str_index_of(s, "=")
            if eq < 0:
                let d = url_decode(s)
                if !d.ok:
                    return false
                self.add(d.s, d.s)
            else:
                let k = url_decode(str_replace(vm::substr(s, 0, eq), "+", " "))
                let v = url_decode(str_replace(vm::substr(s, eq + 1, len(s)), "+", " "))
                if !k.ok or !v.ok:
                    return false
                self.add(k.s, v.s)
        true

# Request.pike's singular headers (the last value counts) and the joined ones
fn singular_header(k: str) -> bool:
    k == "content-length" or k == "content-type" or k == "connection" or k == "transfer-encoding" or k == "if-modified-since" or k == "date" or k == "pragma" or k == "range"

# Pike's Protocols.HTTP.response_codes
fn status_text(code: i32) -> str:
    let codes = [100, 101, 102, 103, 122, 200, 201, 202, 203, 204, 205, 206, 207, 208, 226, 300, 301, 302, 303, 304, 305, 306, 307, 308, 400, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417, 418, 421, 422, 423, 424, 425, 426, 428, 429, 431, 451, 500, 501, 502, 503, 504, 505, 506, 507, 508, 509, 510, 511, 598, 599]
    let texts = ["100 Continue", "101 Switching Protocols", "102 Processing", "103 Early Hints", "122 Request-URI too long", "200 OK", "201 Created, URI follows", "202 Accepted", "203 Non-Authoritative Information", "204 No Content", "205 Reset Content", "206 Partial Content", "207 Multi-Status", "208 Already Reported", "226 IM Used", "300 Moved", "301 Permanent Relocation", "302 Found", "303 See Other", "304 Not Modified", "305 Use Proxy", "306 Switch Proxy", "307 Temporary Redirect", "308 Permanent Redirect", "400 Bad Request", "401 Access denied", "402 Payment Required", "403 Forbidden", "404 No such file or directory.", "405 Method not allowed", "406 Not Acceptable", "407 Proxy authorization needed", "408 Request timeout", "409 Conflict", "410 Gone", "411 Length Required", "412 Precondition Failed", "413 Request Entity Too Large", "414 Request-URI Too Large", "415 Unsupported Media Type", "416 Requested range not statisfiable", "417 Expectation Failed", "418 I'm a teapot", "421 Misdirected Request", "422 Unprocessable Entity", "423 Locked", "424 Failed Dependency", "425 Too Early", "426 Upgrade Required", "428 Precondition Required", "429 Too Many Requests", "431 Request Header Fields Too Large", "451 Unavailable For Legal Reasons", "500 Internal Server Error.", "501 Not Implemented", "502 Bad Gateway", "503 Service unavailable", "504 Gateway Timeout", "505 HTTP Version Not Supported", "506 Variant Also Negotiates", "507 Insufficient Storage", "508 Loop Detected", "509 Bandwidth Limit Exceeded", "510 Not Extended", "511 Network Authentication Required", "598 Network read timeout error", "599 Network connect timeout error"]
    for i in 0..codes.len():
        if codes[i] == code:
            return texts[i]
    ""

# http.pike's own short texts for the int answers
fn short_text(code: i32) -> str:
    let codes = [400, 403, 404, 500, 503, 504]
    let texts = ["Bad Request", "Forbidden", "Not Found", "Internal Server Error", "Service Unavailable", "Gateway Timeout"]
    for i in 0..codes.len():
        if codes[i] == code:
            return texts[i]
    ""

fn two(n: i32) -> str:
    if n < 10:
        return f"0{n}"
    f"{n}"

# Pike's http_date(): "Mon, 26 Oct 2026 09:58:54 GMT" (days from the epoch
# by the civil-from-days rule, no calendar library needed)
fn http_date(t: i64) -> str:
    let days = t / (86400 as i64)
    let secs = (t % (86400 as i64)) as i32
    let wd = ["Thu", "Fri", "Sat", "Sun", "Mon", "Tue", "Wed"]
    let mon = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    let z = days + (719468 as i64)
    let era = z / (146097 as i64)
    let doe = z - era * (146097 as i64)
    let yoe = (doe - doe / (1460 as i64) + doe / (36524 as i64) - doe / (146096 as i64)) / (365 as i64)
    let y0 = yoe + era * (400 as i64)
    let doy = doe - ((365 as i64) * yoe + yoe / (4 as i64) - yoe / (100 as i64))
    let mp = ((5 as i64) * doy + (2 as i64)) / (153 as i64)
    let d = (doy - ((153 as i64) * mp + (2 as i64)) / (5 as i64) + (1 as i64)) as i32
    let m = (if mp < (10 as i64): mp + (3 as i64) else: mp - (9 as i64)) as i32
    let y = (if m <= 2: y0 + (1 as i64) else: y0) as i32
    let w = wd[(days % (7 as i64)) as i32]
    f"{w}, {two(d)} {mon[m - 1]} {y} {two(secs / 3600)}:{two((secs / 60) % 60)}:{two(secs % 60)} GMT"

# String.capitalize(): the first character upper-cased
fn capitalize(s: str) -> str:
    let b = bytes_from_str(s)
    if b.len() == 0 or (b[0] as i32) < 97 or (b[0] as i32) > 122:
        return s
    let mut o = b
    o[0] = ((b[0] as i32) - 32) as u8
    str_from_bytes(o)

# Latin-1 bytes as UTF-8 (string_to_utf8() of an 8-bit string): every byte
# above 127 becomes two
fn latin1_to_utf8(b: Bytes) -> Bytes:
    let mut o: Bytes = Bytes()
    for i in 0..b.len():
        let c = b[i] as i32
        if c < 128:
            o.push(b[i])
        else:
            o.push((192 | (c >> 6)) as u8)
            o.push((128 | (c & 63)) as u8)
    o

# A reply being made (http.pike response() -> Pike's response mapping).
struct HttpReply:
    mut status: i32 = 200
    # the answer set a status ("error" defined): Range doesn't apply
    mut has_status: bool = false
    mut data: Bytes = Bytes()
    mut kind: str = "text/html; charset=utf-8"
    mut hnames: List<str> = List<str>()
    mut hvals: List<str> = List<str>()

impl vm::Vm:
    # http_respond(id, answer) (efun code 430): 1 if request id was waiting.
    fn efun_http(mut self, code: i32, args: List<val::Value>, self_ob: i32) -> val::Value:
        if code == et::E_HTTP_RESPOND:
            let id = val::int_of(self.arg(args, 0)) as i32
            return self.bool_v(self.http_respond_id(id, self.arg(args, 1)))
        self.fail("unknown efun\n")
        val::Value::Undef

    # --- connections --------------------------------------------------------------

    fn http_new(mut self, sock: ptr, port: i32, ctx: ptr) -> i32:
        self.http_seq += 1
        let mut hc = nd::HttpConn(sock = sock, port = port, secure = !is_null(ctx), ip = tcp_peer_ip(sock), active_ms = clock_ms(), seq = self.http_seq)
        if !is_null(ctx):
            hc.tls = self.tls_open(ctx, true, "")
            hc.state = nd::HS_TLS
        for i in 0..self.https.len():
            if !self.https[i].used:
                self.https[i] = hc
                return i
        self.https.push(hc)
        self.https.len() - 1

    fn http_ok(self, h: i32) -> bool:
        h >= 0 and h < self.https.len() and self.https[h].used

    # Bytes for the socket, through TLS on a secure port.
    fn http_write(mut self, h: i32, b: Bytes):
        let li = self.https[h].tls
        if li >= 0:
            self.tls_send(li, b)
            let c = self.tls_take(li)
            for i in 0..c.len():
                self.https[h].out.push(c[i])
        else:
            for i in 0..b.len():
                self.https[h].out.push(b[i])

    fn http_close(mut self, h: i32):
        if !self.http_ok(h):
            return
        let li = self.https[h].tls
        if li >= 0:
            self.tls_close(li)
            let c = self.tls_take(li)
            for i in 0..c.len():
                self.https[h].out.push(c[i])
        self.http_flush(h)
        if !is_null(self.https[h].sock):
            tcp_close(self.https[h].sock)
        if li >= 0:
            self.tls_free(li)
        self.https[h] = nd::HttpConn(used = false)

    # What net_poll() should wait for: 1 read, 4 write, 5 both, 0 nothing.
    fn http_interest(self, h: i32) -> i32:
        if !self.http_ok(h) or is_null(self.https[h].sock):
            return 0
        let st = self.https[h].state
        let w = if self.https[h].out.len() > self.https[h].out_off: 4 else: 0
        if st == nd::HS_WAIT or st == nd::HS_SEND or st == nd::HS_DONE:
            return w
        1 | w

    # Write what is queued; then a finished reply closes the connection or
    # starts the next request on it.
    fn http_flush(mut self, h: i32):
        if !self.http_ok(h) or is_null(self.https[h].sock):
            return
        while self.https[h].out_off < self.https[h].out.len():
            let n = tcp_send_bytes(self.https[h].sock, self.https[h].out, self.https[h].out_off)
            if n < 0:
                self.https[h].out = Bytes()
                self.https[h].out_off = 0
                self.https[h].state = nd::HS_DONE
                self.https[h].close_after = true
                break
            if n == 0:
                return
            self.https[h].out_off = self.https[h].out_off + n
        self.https[h].out = Bytes()
        self.https[h].out_off = 0
        if self.https[h].state == nd::HS_SEND:
            if self.https[h].close_after:
                self.https[h].state = nd::HS_DONE
            else:
                self.http_next_request(h)
        if self.https[h].state == nd::HS_DONE:
            let s = self.https[h].sock
            let li = self.https[h].tls
            self.https[h].sock = null_ptr()
            tcp_close(s)
            if li >= 0:
                self.tls_free(li)
            self.https[h] = nd::HttpConn(used = false)

    # finish(1) on a kept-alive connection: a fresh request on it
    fn http_next_request(mut self, h: i32):
        let keep = self.https[h]
        self.https[h] = nd::HttpConn(sock = keep.sock, tls = keep.tls, port = keep.port, secure = keep.secure, ip = keep.ip, active_ms = clock_ms(), seq = keep.seq)

    # The socket is readable (or hung up).
    fn http_ready(mut self, h: i32):
        if !self.http_ok(h):
            return
        let s = self.https[h].sock
        let d = tcp_recv_bytes(s)
        if d.len() == 0:
            self.http_close(h)
            return
        self.https[h].active_ms = clock_ms()
        let li = self.https[h].tls
        if li < 0:
            self.http_input(h, d)
            return
        let plain = self.tls_feed(li, d)
        let c = self.tls_take(li)
        for i in 0..c.len():
            self.https[h].out.push(c[i])
        if self.tlss[li].failed or self.tlss[li].peer_closed:
            self.http_close(h)
            return
        if self.https[h].state == nd::HS_TLS:
            if !self.tlss[li].up:
                return
            self.https[h].state = nd::HS_HEAD
        if plain.len() > 0:
            self.http_input(h, plain)

    # Request bytes (read_cb / read_cb_post / read_cb_chunked).
    fn http_input(mut self, h: i32, data_in: Bytes):
        let st = self.https[h].state
        if st == nd::HS_WAIT or st == nd::HS_SEND or st == nd::HS_DONE or st == nd::HS_TLS:
            return
        let mut data = data_in
        if !self.https[h].seen:
            # the first data loses its leading whitespace
            let mut a = 0
            while a < data.len() and is_white(data[a] as i32):
                a += 1
            if a == data.len():
                return
            data = sub_bytes(data, a, data.len())
            self.https[h].seen = true
        for i in 0..data.len():
            self.https[h].inb.push(data[i])
        if st == nd::HS_HEAD:
            self.http_try_head(h)
        elif st == nd::HS_BODY:
            self.http_try_body(h)
        elif st == nd::HS_CHUNKED:
            self.http_try_chunked(h)

    # --- the request head ---------------------------------------------------------

    # The head is complete once an empty line has come.
    fn http_try_head(mut self, h: i32):
        let b = self.https[h].inb
        let mut lines: List<str> = List<str>()
        let mut start = 0
        let mut end = -1
        let mut i = 0
        while i < b.len():
            if (b[i] as i32) == 10:
                let mut e = i
                if e > start and (b[e - 1] as i32) == 13:
                    e -= 1
                if e == start:
                    end = i + 1
                    break
                lines.push(str_from_bytes(sub_bytes(b, start, e)))
                start = i + 1
            i += 1
        if end < 0:
            return
        let rest = sub_bytes(b, end, b.len())
        self.https[h].inb = Bytes()
        self.https[h].in_off = 0
        let mut hd = NamedVals()
        for k in 1..lines.len():
            let l = lines[k]
            let c = str_index_of(l, ":")
            if c < 0:
                continue
            let lb = bytes_from_str(l)
            let mut v = c + 1
            while v < lb.len() and ((lb[v] as i32) == 32 or (lb[v] as i32) == 9):
                v += 1
            hd.add(lower_ascii(vm::substr(l, 0, c)), vm::substr(l, v, len(l)))
        self.https[h].hnames = hd.names
        self.https[h].hvals = hd.vals
        self.http_parse_request(h, if lines.len() > 0: lines[0] else: "")
        self.http_parse_variables(h, rest)

    # parse_request(): method, protocol, path and query from the first line
    fn http_parse_request(mut self, h: i32, line: str):
        let v = str_split(line, " ")
        let mut method = "GET"
        let mut proto = "HTTP/0.9"
        let mut fq = ""
        if v.len() == 1:
            fq = v[0]
        elif v.len() >= 2:
            let last = v[v.len() - 1]
            if v.len() > 2 and vm::substr(last, 0, 4) == "HTTP":
                method = v[0]
                proto = last
                if proto != "HTTP/1.0" and proto != "HTTP/1.1":
                    proto = norm_protocol(proto)
                let mut mid: List<str> = List<str>()
                for k in 1..v.len() - 1:
                    mid.push(v[k])
                fq = str_join(mid, " ")
            else:
                method = v[0]
                let mut mid: List<str> = List<str>()
                for k in 1..v.len():
                    mid.push(v[k])
                fq = str_join(mid, " ")
        self.https[h].method = method
        self.https[h].protocol = proto
        self.https[h].full_query = fq
        let q = str_index_of(fq, "?")
        if q < 0:
            self.https[h].path = fq
            self.https[h].query = ""
        else:
            self.https[h].path = vm::substr(fq, 0, q)
            self.https[h].query = vm::substr(fq, q + 1, len(fq))

    fn http_header(self, h: i32, k: str) -> str:
        let names = self.https[h].hnames
        for i in 0..names.len():
            if names[i] == k:
                let vs = self.https[h].hvals[i]
                return if vs.len() > 0: vs[vs.len() - 1] else: ""
        ""

    fn http_has_header(self, h: i32, k: str) -> bool:
        let names = self.https[h].hnames
        for i in 0..names.len():
            if names[i] == k:
                return true
        false

    # flatten_headers()
    fn http_flatten(mut self, h: i32):
        let names = self.https[h].hnames
        for i in 0..names.len():
            let vs = self.https[h].hvals[i]
            if vs.len() > 1:
                if singular_header(names[i]):
                    self.https[h].hvals[i] = [vs[vs.len() - 1]]
                elif names[i] == "cookie" or names[i] == "cookie2":
                    self.https[h].hvals[i] = [str_join(vs, ";")]

    # parse_variables(): a WebSocket upgrade, or on to the body
    fn http_parse_variables(mut self, h: i32, rest: Bytes):
        if self.http_is_upgrade(h):
            self.http_upgrade(h)
            return
        self.https[h].body = Bytes()
        self.http_flatten(h)
        if lower_ascii(self.http_header(h, "expect")) == "100-continue":
            self.http_write(h, bytes_from_str("HTTP/1.1 100 Continue\r\n\r\n"))
        if str_contains(lower_ascii(self.http_header(h, "transfer-encoding")), "chunked"):
            self.https[h].state = nd::HS_CHUNKED
            self.https[h].ck_state = nd::CK_SIZE
            self.https[h].inb = rest
            self.http_try_chunked(h)
            return
        let l = vm::parse_int_prefix(self.http_header(h, "content-length")) as i32
        if l <= rest.len():
            self.https[h].body = sub_bytes(rest, 0, if l < 0: 0 else: l)
            self.http_finalize(h)
            return
        if self.https[h].method == "PUT":
            self.https[h].body = rest
            self.http_finalize(h)
            return
        self.https[h].want = l
        self.https[h].state = nd::HS_BODY
        self.https[h].inb = rest
        self.http_try_body(h)

    fn http_try_body(mut self, h: i32):
        let have = self.https[h].inb.len()
        let l = self.https[h].want
        if have >= l:
            self.https[h].body = sub_bytes(self.https[h].inb, 0, l)
        elif have > MAX_REQUEST:
            self.https[h].body = Bytes()
        else:
            return
        self.https[h].inb = Bytes()
        self.http_finalize(h)

    # read_cb_chunked(): size lines, chunks, the CRLF after each, trailers
    fn http_try_chunked(mut self, h: i32):
        while true:
            let st = self.https[h].ck_state
            let b = self.https[h].inb
            let off = self.https[h].in_off
            if st == nd::CK_SIZE:
                let mut e = -1
                let mut i = off
                while i + 1 < b.len():
                    if (b[i] as i32) == 13 and (b[i + 1] as i32) == 10:
                        e = i
                        break
                    i += 1
                if e < 0:
                    return
                let mut n = 0
                let mut k = off
                while k < e and hex_digit(b[k] as i32) >= 0:
                    n = n * 16 + hex_digit(b[k] as i32)
                    k += 1
                self.https[h].in_off = e + 2
                if n == 0:
                    self.https[h].ck_state = nd::CK_TRAILER
                else:
                    self.https[h].ck_left = n
                    self.https[h].ck_state = nd::CK_DATA
            elif st == nd::CK_DATA:
                let avail = b.len() - off
                if avail <= 0:
                    return
                let take = if avail < self.https[h].ck_left: avail else: self.https[h].ck_left
                for i in off..off + take:
                    self.https[h].body.push(b[i])
                self.https[h].in_off = off + take
                self.https[h].ck_left = self.https[h].ck_left - take
                if self.https[h].ck_left == 0:
                    self.https[h].ck_state = nd::CK_POSTNL
            elif st == nd::CK_POSTNL:
                if b.len() - off < 2:
                    return
                if (b[off] as i32) == 13 and (b[off + 1] as i32) == 10:
                    self.https[h].in_off = off + 2
                self.https[h].ck_state = nd::CK_SIZE
            else:
                for i in off..b.len():
                    self.https[h].ck_trailer.push(b[i])
                self.https[h].inb = Bytes()
                self.https[h].in_off = 0
                let t = str_from_bytes(self.https[h].ck_trailer)
                if !str_starts_with(t, "\r\n") and !str_contains(t, "\r\n\r\n"):
                    return
                let mut text = t
                if str_starts_with(t, "\r\n"):
                    text = ""
                else:
                    text = vm::substr(t, 0, str_index_of(t, "\r\n\r\n"))
                let lines = str_split(text, "\r\n")
                let mut hd = NamedVals(names = self.https[h].hnames, vals = self.https[h].hvals)
                for k in 0..lines.len():
                    let c = str_index_of(lines[k], ":")
                    if lines[k] == "" or c < 0:
                        continue
                    hd.add(trim_all(lower_ascii(vm::substr(lines[k], 0, c))), trim_all(vm::substr(lines[k], c + 1, len(lines[k]))))
                hd.put("content-length", f"{self.https[h].body.len()}")
                self.https[h].hnames = hd.names
                self.https[h].hvals = hd.vals
                self.http_finalize(h)
                return

    # Is this GET a WebSocket upgrade (Protocols.WebSocket.Request)?
    fn http_is_upgrade(self, h: i32) -> bool:
        if self.https[h].method != "GET":
            return false
        let p = self.https[h].protocol
        if !str_starts_with(p, "HTTP/") or str_less(vm::substr(p, 5, len(p)), "1.1"):
            return false
        if !str_contains(lower_ascii(self.http_header(h, "upgrade")), "websocket"):
            return false
        if !str_contains(lower_ascii(self.http_header(h, "connection")), "upgrade"):
            return false
        if sh::base64_decode(self.http_header(h, "sec-websocket-key")).len() != 16:
            return false
        self.http_header(h, "sec-websocket-version") == "13"

    # --- the request, complete --------------------------------------------------

    # finalize(): the body's variables and the cookies, then the master
    fn http_finalize(mut self, h: i32):
        self.http_flatten(h)
        let mut vars = NamedVals()
        if self.https[h].query != "":
            if !vars.add_query(self.https[h].query):
                self.log_msg(f"[http] bad escape in the query of {self.https[h].path}")
                self.http_close(h)
                return
        let ctype = self.http_header(h, "content-type")
        if self.http_has_header(h, "content-type") and str_starts_with(ctype, "multipart/form-data"):
            vars = self.http_multipart(h, ctype, vars)
        elif self.http_has_header(h, "content-type") and (str_contains(ctype, "url-encoded") or str_contains(ctype, "urlencoded")):
            if !vars.add_query(str_from_bytes(self.https[h].body)):
                self.log_msg(f"[http] bad escape in the body of {self.https[h].path}")
                self.http_close(h)
                return
        let cookies = NamedVals()
        let mut ck = cookies
        if self.http_has_header(h, "cookie"):
            let parts = str_split(self.http_header(h, "cookie"), ";")
            for i in 0..parts.len():
                let c = trim_all(parts[i])
                let eq = str_index_of(c, "=")
                if eq >= 0:
                    ck.put(vm::substr(c, 0, eq), vm::substr(c, eq + 1, len(c)))
        self.https[h].state = nd::HS_WAIT
        self.http_handle(h, vars, ck)

    # parse_post()'s multipart branch (MIME.Message): each part's
    # Content-Disposition name; a file field also gets .filename and, as in
    # Pike, .mimetype set to the file name
    fn http_multipart(mut self, h: i32, ctype: str, vars_in: NamedVals) -> NamedVals:
        let mut vars = vars_in
        let mut boundary = ""
        let params = str_split(ctype, ";")
        for i in 1..params.len():
            let p = trim_all(params[i])
            if str_starts_with(lower_ascii(p), "boundary="):
                boundary = vm::substr(p, 9, len(p))
                if str_starts_with(boundary, "\"") and str_ends_with(boundary, "\"") and len(boundary) >= 2:
                    boundary = vm::substr(boundary, 1, len(boundary) - 1)
        if boundary == "":
            return vars
        let body = str_from_bytes(self.https[h].body)
        let parts = str_split(body, concat("--", boundary))
        for i in 1..parts.len():
            let part = parts[i]
            if str_starts_with(part, "--"):
                break
            let mut p = part
            if str_starts_with(p, "\r\n"):
                p = vm::substr(p, 2, len(p))
            if str_ends_with(p, "\r\n"):
                p = vm::substr(p, 0, len(p) - 2)
            let sep = str_index_of(p, "\r\n\r\n")
            if sep < 0:
                continue
            let head = vm::substr(p, 0, sep)
            let data = vm::substr(p, sep + 4, len(p))
            let mut name = ""
            let mut has_name = false
            let mut filename = ""
            let mut has_file = false
            let hl = str_split(head, "\r\n")
            for k in 0..hl.len():
                let c = str_index_of(hl[k], ":")
                if c < 0 or lower_ascii(trim_all(vm::substr(hl[k], 0, c))) != "content-disposition":
                    continue
                let ps = str_split(vm::substr(hl[k], c + 1, len(hl[k])), ";")
                for q in 1..ps.len():
                    let kv = trim_all(ps[q])
                    let eq = str_index_of(kv, "=")
                    if eq < 0:
                        continue
                    let pk = lower_ascii(trim_all(vm::substr(kv, 0, eq)))
                    let mut pv = trim_all(vm::substr(kv, eq + 1, len(kv)))
                    if str_starts_with(pv, "\"") and str_ends_with(pv, "\"") and len(pv) >= 2:
                        pv = vm::substr(pv, 1, len(pv) - 1)
                    if pk == "name":
                        name = pv
                        has_name = true
                    elif pk == "filename":
                        filename = pv
                        has_file = true
            if !has_name:
                continue
            if has_file:
                vars.add(name, data)
                vars.add(concat(name, ".filename"), filename)
                vars.add(concat(name, ".mimetype"), filename)
            else:
                vars.put(name, data)
        vars

    # A string, or an array when there are several.
    fn http_value(mut self, vs: List<str>) -> val::Value:
        if vs.len() == 1:
            return val::Value::Str(vs[0])
        let mut a: List<val::Value> = List<val::Value>()
        for i in 0..vs.len():
            a.push(val::Value::Str(vs[i]))
        self.new_arr(a)

    fn http_named_map(mut self, nv: NamedVals) -> val::Value:
        let m = self.new_map()
        for i in 0..nv.names.len():
            let v = self.http_value(nv.vals[i])
            self.map_set(m, val::Value::Str(nv.names[i]), v)
        val::Value::Map(m)

    # http.pike handle_request(): the master's http_request(), then the
    # answer now, or later through http_respond().
    fn http_handle(mut self, h: i32, vars: NamedVals, cookies: NamedVals):
        self.http_next_id += 1
        let id = self.http_next_id
        let req = self.new_map()
        self.map_set(req, val::Value::Str("id"), val::Value::Int(id as i64))
        self.map_set(req, val::Value::Str("method"), val::Value::Str(self.https[h].method))
        self.map_set(req, val::Value::Str("path"), val::Value::Str(self.https[h].path))
        self.map_set(req, val::Value::Str("query"), val::Value::Str(self.https[h].query))
        let vm_ = self.http_named_map(vars)
        self.map_set(req, val::Value::Str("variables"), vm_)
        let hm = self.http_named_map(NamedVals(names = self.https[h].hnames, vals = self.https[h].hvals))
        self.map_set(req, val::Value::Str("headers"), hm)
        let cm = self.http_named_map(cookies)
        self.map_set(req, val::Value::Str("cookies"), cm)
        self.map_set(req, val::Value::Str("body"), val::Value::Str(str_from_bytes(self.https[h].body)))
        self.map_set(req, val::Value::Str("ip"), val::Value::Str(self.https[h].ip))
        self.map_set(req, val::Value::Str("port"), val::Value::Int(self.https[h].port as i64))
        self.map_set(req, val::Value::Str("secure"), self.bool_v(self.https[h].secure))
        self.http_pending.push(nd::HttpPending(id = id, hc = h, seq = self.https[h].seq, due_ms = 0 as i64))
        let mut answer = val::Value::Int(503 as i64)
        if self.alive(self.master_ob):
            let ol = self.ostack.len()
            let sl = self.stack.len()
            self.begin_eval()
            answer = self.master_apply("http_request", [val::Value::Map(req)], -1)
            if self.err:
                self.report_error(f"http_request {self.https[h].method} {self.https[h].path}")
                answer = val::Value::Int(500 as i64)
            self.truncate_ostack(ol)
            self.truncate_stack(sl)
            self.end_eval()
        let later = match answer:
            val::Value::Int(x) -> x == ((0 - 1) as i64)
            _ -> false
        if later:
            let mut secs = 30 as i64
            if let Option::Some(t) = self.config.get("havok http timeout"):
                secs = vm::parse_int_prefix(t)
            for i in 0..self.http_pending.len():
                if self.http_pending[i].id == id:
                    self.http_pending[i] = nd::HttpPending(id = id, hc = h, seq = self.http_pending[i].seq, due_ms = clock_ms() + secs * (1000 as i64))
            return
        self.http_respond_id(id, answer)

    # http.pike respond(): send the answer to request id; false when it
    # wasn't waiting.
    fn http_respond_id(mut self, id: i32, answer: val::Value) -> bool:
        let mut k = -1
        for i in 0..self.http_pending.len():
            if self.http_pending[i].id == id:
                k = i
        if k < 0:
            return false
        let p = self.http_pending[k]
        let mut keep: List<nd::HttpPending> = List<nd::HttpPending>()
        for i in 0..self.http_pending.len():
            if i != k:
                keep.push(self.http_pending[i])
        self.http_pending = keep
        let h = p.hc
        if !self.http_ok(h) or self.https[h].seq != p.seq or self.https[h].state != nd::HS_WAIT:
            return true
        let mut r = self.http_reply(answer)
        if r.status < 0:
            self.log_msg(f"[http] bad answer to {self.https[h].path}: expected a mapping, string or int")
            r = self.http_reply(val::Value::Int(500 as i64))
        self.http_send_reply(h, r)
        true

    # The answers that time out (`havok http timeout`): 504.
    fn http_timeouts(mut self):
        if self.http_pending.len() == 0 and self.https.len() == 0:
            return
        let now = clock_ms()
        let mut due: List<i32> = List<i32>()
        for i in 0..self.http_pending.len():
            let d = self.http_pending[i].due_ms
            if d != (0 as i64) and d <= now:
                due.push(self.http_pending[i].id)
        for i in 0..due.len():
            self.http_respond_id(due[i], val::Value::Int(504 as i64))
        # Pike's connection timeout: a request that doesn't complete
        for h in 0..self.https.len():
            if self.http_ok(h):
                let st = self.https[h].state
                if (st == nd::HS_TLS or st == nd::HS_HEAD or st == nd::HS_BODY or st == nd::HS_CHUNKED) and now - self.https[h].active_ms >= (CONN_TIMEOUT_MS as i64):
                    self.http_close(h)

    # When the next HTTP timer falls due (0: none).
    fn http_next_due(self) -> i64:
        let mut due = 0 as i64
        for i in 0..self.http_pending.len():
            let d = self.http_pending[i].due_ms
            if d != (0 as i64) and (due == (0 as i64) or d < due):
                due = d
        due

    # --- the reply ------------------------------------------------------------------

    # http.pike response(): status < 0 for an answer of the wrong type
    fn http_reply(mut self, answer: val::Value) -> HttpReply:
        let mut r = HttpReply()
        match answer:
            val::Value::Str(s) ->
                r.data = bytes_from_str(s)
                return r
            val::Value::Int(x) ->
                r.has_status = true
                r.status = if x == (0 as i64): 404 else: x as i32
                let t = short_text(r.status)
                r.data = bytes_from_str(if t == "": "" else: concat(t, "\n"))
                r.kind = "text/plain"
                return r
            val::Value::Undef ->
                r.has_status = true
                r.status = 404
                r.data = bytes_from_str("Not Found\n")
                r.kind = "text/plain"
                return r
            val::Value::Map(m) ->
                r.has_status = true
                let st = self.map_get(m, val::Value::Str("status"))
                r.status = 200
                if self.truthy(st):
                    r.status = match st:
                        val::Value::Int(x) -> x as i32
                        val::Value::Str(s) -> vm::parse_int_prefix(s) as i32
                        val::Value::Real(f) -> f as i32
                        _ -> 0
                let typ = self.map_get(m, val::Value::Str("type"))
                let file = self.map_get(m, val::Value::Str("file"))
                match file:
                    val::Value::Str(fname) ->
                        let path = paths::combine_path("/", fname)
                        let f = file_open(self.mud_real(path), "rb")
                        if is_null(f):
                            return self.http_reply(val::Value::Int(404 as i64))
                        r.data = file_read_bytes(f)
                        file_close(f)
                        r.kind = match typ:
                            val::Value::Str(t) -> t
                            _ -> self.http_file_type(path)
                    _ ->
                        r.data = match self.map_get(m, val::Value::Str("body")):
                            val::Value::Str(b) -> bytes_from_str(b)
                            _ -> Bytes()
                        r.kind = match typ:
                            val::Value::Str(t) -> t
                            _ -> "text/html; charset=utf-8"
                match self.map_get(m, val::Value::Str("headers")):
                    val::Value::Map(hm) ->
                        let ks = self.maps[hm].keys
                        for i in 0..ks.len():
                            match ks[i]:
                                val::Value::Str(name) ->
                                    let v = self.map_get(hm, ks[i])
                                    match v:
                                        val::Value::Str(one) ->
                                            r.hnames.push(name)
                                            r.hvals.push(one)
                                        val::Value::Arr(ah) ->
                                            let items = self.arrs[ah].items
                                            for j in 0..items.len():
                                                r.hnames.push(name)
                                                r.hvals.push(self.to_str(items[j]))
                                        _ -> 0
                                _ -> 0
                    _ -> 0
                return r
            _ ->
                r.status = -1
                return r

    # filename_to_type(): by the lower-cased last extension
    fn http_file_type(mut self, path: str) -> str:
        if self.mime.len() == 0:
            self.mime = mt::mime_table()
        let parts = str_split(lower_ascii(path), ".")
        let ext = if parts.len() < 2: "default" else: parts[parts.len() - 1]
        if let Option::Some(t) = self.mime.get(ext):
            return t
        "application/octet-stream"

    # response_and_finish() + low_make_response_header(), and the send
    fn http_send_reply(mut self, h: i32, r_in: HttpReply):
        let mut r = r_in
        let mut start = -1
        let mut stop = 0
        let size = r.data.len()
        let range = self.http_header(h, "range")
        if self.http_has_header(h, "range") and !r.has_status:
            let rr = parse_range(range)
            if rr.kind == 1:
                start = rr.a
                stop = rr.b
            elif rr.kind == 2:
                # Pike compares the suffix with a size it hasn't worked out
                # yet (0): always unsatisfiable
                if rr.b > 0:
                    r.data = Bytes()
                    r.has_status = true
                    r.status = 416
                else:
                    start = 0
                    stop = -1
            elif rr.kind == 3:
                start = rr.a
                stop = -1
            elif str_contains(range, ","):
                r.data = Bytes()
                r.has_status = true
                r.status = 416
        if self.http_has_header(h, "if-none-match"):
            let inm = self.http_header(h, "if-none-match")
            let mut et = ""
            let mut found = false
            for i in 0..r.hnames.len():
                if !found and (r.hnames[i] == "ETag" or r.hnames[i] == "etag"):
                    et = r.hvals[i]
                    found = true
            if found and inm == et:
                r.data = Bytes()
                r.has_status = true
                r.status = 304
        let mut proto = self.https[h].protocol
        if proto != "HTTP/1.0" and proto != "HTTP/1.1":
            proto = "HTTP/1.0"
        let msize = r.data.len()
        let mut head: Bytes = Bytes()
        if !r.has_status or r.status == 0 or r.status == 200:
            if start < 0:
                head = push_str(head, concat(proto, " 200 OK\r\n"))
            else:
                head = push_str(head, concat(proto, " 206 Partial content\r\n"))
                r.status = 206
        else:
            let t = status_text(r.status)
            if t != "":
                head = push_str(head, f"{proto} {t}\r\n")
            else:
                head = push_str(head, f"{proto} {r.status} ERROR\r\n")
        if r.status == 206:
            let last = if stop == -1: msize - 1 else: stop
            head = push_str(head, f"Content-Range: bytes {start}-{last}/{msize}\r\n")
        head = push_str(head, f"Content-Type: {r.kind}\r\n")
        head = push_str(head, f"Content-Length: {msize}\r\n")
        head = push_str(head, concat(concat("Server: ", SERVER_ID), "\r\n"))
        let now = http_date(vm::epoch_now())
        head = push_str(head, f"Date: {now}\r\n")
        head = push_str(head, f"Last-Modified: {now}\r\n")
        for i in 0..r.hnames.len():
            head = push_str(head, f"{capitalize(r.hnames[i])}: {r.hvals[i]}\r\n")
        let cc = lower_ascii(self.http_header(h, "connection"))
        let keep = (proto == "HTTP/1.1" and !str_contains(cc, "close")) or cc == "keep-alive"
        head = push_str(head, if keep: "Connection: keep-alive\r\n" else: "Connection: close\r\n")
        head = push_str(head, "\r\n")
        # the body Pike sends: from the start offset on (whatever the stop),
        # and the byte count it expects: the whole size, or the range's
        # stop - start + 1; a mismatch closes the connection
        let mut expect = msize
        if stop > 0:
            expect = 1 + stop - start
        let mut body = r.data
        if start > 0:
            body = if start < r.data.len(): sub_bytes(r.data, start, r.data.len()) else: Bytes()
        if self.https[h].method == "HEAD":
            body = Bytes()
            expect = 0
        let mut all = head
        for i in 0..body.len():
            all.push(body[i])
        self.https[h].close_after = !keep or body.len() != (if expect > 0: expect else: 0)
        self.https[h].state = nd::HS_SEND
        self.http_write(h, all)

    # --- WebSockets -----------------------------------------------------------------

    # websocket_accept() and http.pike handle_websocket(): the 101 reply,
    # then an interactive connection on the same socket (net.star). What
    # followed the request in the same read is dropped, as there.
    fn http_upgrade(mut self, h: i32):
        let proto = self.http_header(h, "sec-websocket-protocol")
        let protocols = if self.http_has_header(h, "sec-websocket-protocol"): str_split(proto, ", ") else: List<str>()
        let mut binary = false
        for i in 0..protocols.len():
            if protocols[i] == "telnet":
                binary = true
        let accept = sh::base64_encode(sh::sha1(bytes_from_str(concat(self.http_header(h, "sec-websocket-key"), WS_GUID))))
        let mut reply = "HTTP/1.1 101 SwitchingProtocols\r\nConnection: Upgrade\r\nUpgrade: websocket\r\n"
        if binary:
            reply = concat(reply, "Sec-WebSocket-Protocol: telnet\r\n")
        reply = concat(reply, concat(concat("Sec-WebSocket-Version: 13\r\nSec-WebSocket-Accept: ", accept), "\r\n\r\n"))
        let hc = self.https[h]
        # the socket and TLS session move to the connection
        self.https[h] = nd::HttpConn(used = false)
        self.ws_start(hc.sock, hc.tls, hc.port, hc.ip, binary, bytes_from_str(reply), hc.out, hc.out_off)

# A Range header (response_and_finish()'s sscanf patterns): 1 "bytes=a-b",
# 2 "bytes=-b", 3 "bytes=a-", 0 none of them.
struct RangeSpec:
    kind: i32
    a: i32
    b: i32

fn parse_range(r: str) -> RangeSpec:
    if !str_starts_with(r, "bytes"):
        return RangeSpec(kind = 0, a = 0, b = 0)
    let b = bytes_from_str(r)
    let mut i = 5
    while i < b.len() and ((b[i] as i32) == 32 or (b[i] as i32) == 61):
        i += 1
    let neg = i < b.len() and (b[i] as i32) == 45
    if neg:
        let n = read_int(b, i + 1)
        if n.ok:
            return RangeSpec(kind = 2, a = 0, b = n.v)
        return RangeSpec(kind = 0, a = 0, b = 0)
    let a = read_int(b, i)
    if !a.ok or a.end >= b.len() or (b[a.end] as i32) != 45:
        return RangeSpec(kind = 0, a = 0, b = 0)
    let c = read_int(b, a.end + 1)
    if c.ok:
        return RangeSpec(kind = 1, a = a.v, b = c.v)
    RangeSpec(kind = 3, a = a.v, b = 0)

# sscanf("%d") at b[i]: an optional sign, digits
struct IntRead:
    ok: bool
    v: i32
    end: i32

fn read_int(b: Bytes, at: i32) -> IntRead:
    let mut i = at
    let mut neg = false
    if i < b.len() and ((b[i] as i32) == 45 or (b[i] as i32) == 43):
        neg = (b[i] as i32) == 45
        i += 1
    let s = i
    let mut v = 0
    while i < b.len() and (b[i] as i32) >= 48 and (b[i] as i32) <= 57 and v < 100000000:
        v = v * 10 + ((b[i] as i32) - 48)
        i += 1
    if i == s:
        return IntRead(ok = false, v = 0, end = at)
    IntRead(ok = true, v = if neg: 0 - v else: v, end = i)

# Pike's `a < b` on strings: byte by byte, a prefix first
fn str_less(a: str, b: str) -> bool:
    let x = bytes_from_str(a)
    let y = bytes_from_str(b)
    let mut i = 0
    while i < x.len() and i < y.len():
        if x[i] != y[i]:
            return (x[i] as i32) < (y[i] as i32)
        i += 1
    x.len() < y.len()

# "HTTP/<maj>.<min>" normalised (Pike's sprintf("HTTP/%d.%d")), or as given
fn norm_protocol(p: str) -> str:
    let b = bytes_from_str(p)
    if b.len() < 6:
        return p
    let maj = read_int(b, 5)
    if !maj.ok or maj.end >= b.len() or (b[maj.end] as i32) != 46:
        return p
    let mn = read_int(b, maj.end + 1)
    if !mn.ok:
        return p
    f"HTTP/{maj.v}.{mn.v}"

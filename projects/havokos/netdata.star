# Rows for the network's P1 #8 additions -- todo.md HavokOS P1 #8: TLS
# links (tls.star), HTTP connections (http.star) and listening ports
# (net.star). In their own file, as conn.star's Conn and sockdata.star's
# LSock are, so vm.star can hold the tables without importing the code.

# One TLS session over memory BIOs (tls.star): the socket's bytes go into
# `rbio`, OpenSSL's go out of `wbio`, so the driver's one poll keeps doing
# all the socket I/O. `Vm.tlss` holds them; a freed row is reused.
struct TlsLink:
    mut used: bool = true
    mut ssl: ptr = null_ptr()
    mut rbio: ptr = null_ptr()
    mut wbio: ptr = null_ptr()
    mut server: bool = false
    # the handshake finished
    mut up: bool = false
    # a fatal TLS error, or the peer's close_notify
    mut failed: bool = false
    mut peer_closed: bool = false
    # plaintext written before the handshake finished
    mut pend: Bytes = Bytes()

# What a listening socket serves (net.star net_listen_kind()).
const LK_TELNET: i32 = 0
const LK_HTTP: i32 = 1

# A connection a STREAM_TLS listener accepted, in its handshake (the
# reference's SSL.Port hands a connection to LPC only once that is done):
# the listening socket number, the OS socket, the TLS session, and bytes
# for the socket not sent yet.
struct TlsAccept:
    fd: i32
    sock: ptr
    tls: i32
    mut out: Bytes = Bytes()
    mut early: Bytes = Bytes()
    mut done: bool = false

# The case runner's clients (efuns_net.star test_cli_*): a socket, TLS when
# asked, what arrived and hasn't been taken, what wasn't sent yet, and
# whether the peer closed.
struct TestCli:
    mut used: bool = true
    mut sock: ptr = null_ptr()
    mut tls: i32 = -1
    mut got: Bytes = Bytes()
    mut out: Bytes = Bytes()
    mut out_off: i32 = 0
    mut closed: bool = false

# The case runner's listeners (test_srv_listen()): connections accepted and
# not taken yet.
struct TestSrv:
    sock: ptr
    port: i32
    secure: bool
    mut accepted: List<ptr> = List<ptr>()

# HTTP connection states (http.star): reading the request line and headers,
# a Content-Length body, a chunked body; then waiting for the answer (the
# socket isn't read, as the reference's request goes blocking), sending it,
# and done.
const HS_TLS: i32 = 0
const HS_HEAD: i32 = 1
const HS_BODY: i32 = 2
const HS_CHUNKED: i32 = 3
const HS_WAIT: i32 = 4
const HS_SEND: i32 = 5
const HS_DONE: i32 = 6

# chunked body states (Pike's Request read_cb_chunked())
const CK_SIZE: i32 = 1
const CK_DATA: i32 = 2
const CK_POSTNL: i32 = 3
const CK_TRAILER: i32 = 4

# One connection to an HTTP port: Pike's Protocols.HTTP.Server.Request, one
# request at a time (a kept-alive connection starts the next when the
# answer is out).
struct HttpConn:
    mut used: bool = true
    # tells a reused row from the connection a pending answer was for
    mut seq: i32 = 0
    mut sock: ptr = null_ptr()
    mut tls: i32 = -1
    mut port: i32 = 0
    mut secure: bool = false
    mut ip: str = "0.0.0.0"
    mut state: i32 = 1
    # request bytes not parsed yet, from `in_off`; whether anything but
    # leading whitespace has come (the reference strips that from the first
    # data only)
    mut inb: Bytes = Bytes()
    mut in_off: i32 = 0
    mut seen: bool = false
    # bytes for the socket not taken yet, from `out_off`
    mut out: Bytes = Bytes()
    mut out_off: i32 = 0
    # the request
    mut method: str = ""
    mut protocol: str = ""
    mut full_query: str = ""
    mut path: str = ""
    mut query: str = ""
    # header names (lower-cased, first-seen order) and each one's values
    mut hnames: List<str> = List<str>()
    mut hvals: List<List<str>> = List<List<str>>()
    mut body: Bytes = Bytes()
    mut want: i32 = 0
    # chunked body: state, bytes left in the chunk, the trailer text
    mut ck_state: i32 = 1
    mut ck_left: i32 = 0
    mut ck_trailer: Bytes = Bytes()
    # the answer: close once sent (no keep-alive, or a ranged reply whose
    # length the reference miscounts)
    mut close_after: bool = true
    # last activity (clock_ms), for the reference's 180 s connection timeout
    mut active_ms: i64 = 0 as i64

# A request waiting for http_respond(): its id, connection, and when the
# `havok http timeout` answers it with 504 (clock_ms).
struct HttpPending:
    id: i32
    hc: i32
    seq: i32
    due_ms: i64

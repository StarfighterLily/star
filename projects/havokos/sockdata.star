# One LPC socket's state -- todo.md HavokOS P1 #5, the fields of
# `havok/sockets.pike`'s LSock class without its methods (those are
# `sockets.star`'s, on the Vm, since every event runs an LPC callback). In
# its own file so `vm.star` can hold the socket table without importing the
# socket layer, as `conn.star` does for connections.
#
# The reference numbers sockets from a counter that never goes back
# (`next_fd++`, for accepted connections too) and socket_status() lists
# every number ever handed out, closed ones included. So `Vm.socks` is
# indexed by that number: a closed socket keeps its row (`open` false, its
# buffers and callbacks dropped) and is never reused.
#
# Object references (the owner, the object a socket is released to) are
# generation-checked object values, so a destructed owner reads as gone.
# Buffers are `Bytes` with a read offset, as in `conn.star`.

import "value.star" as val

# MUD mode framing, stream and datagram modes (FluffOS PACKAGE_SOCKETS, with
# the reference's two TLS modes after them)
const SM_MUD: i32 = 0
const SM_STREAM: i32 = 1
const SM_DATAGRAM: i32 = 2
const SM_STREAM_BINARY: i32 = 3
const SM_DATAGRAM_BINARY: i32 = 4
const SM_STREAM_TLS: i32 = 5
const SM_STREAM_TLS_BINARY: i32 = 6

# socket states (sockets.pike STATE_*)
const SS_CLOSED: i32 = 0
const SS_UNBOUND: i32 = 1
const SS_BOUND: i32 = 2
const SS_LISTEN: i32 = 3
const SS_DATA_XFER: i32 = 4
const SS_CONNECTING: i32 = 5

struct LSock:
    mut open: bool = true
    mut mode: i32 = 0
    mut state: i32 = 1
    mut owner: val::Value = val::Value::Int(0 as i64)
    # socket_release(): the object it was offered to, until it acquires
    mut release_ob: val::Value = val::Value::Int(0 as i64)
    mut read_cb: val::Value = val::Value::Int(0 as i64)
    mut write_cb: val::Value = val::Value::Int(0 as i64)
    mut close_cb: val::Value = val::Value::Int(0 as i64)
    # the OS socket: a listener, a stream or a datagram socket (null for
    # none yet); `listener` tells the first apart
    mut handle: ptr = null_ptr()
    mut listener: bool = false
    mut local_addr: str = "0.0.0.0"
    mut local_port: i32 = 0
    mut remote_addr: str = "0.0.0.0"
    mut remote_port: i32 = 0
    # MUD mode: bytes of a frame not complete yet, from `in_off`
    mut inbuf: Bytes = Bytes()
    mut in_off: i32 = 0
    # bytes the kernel hasn't taken yet, from `out_off`
    mut outbuf: Bytes = Bytes()
    mut out_off: i32 = 0
    # a write is pending (EECALLBACK) or a connect is under way: the write
    # callback is due once it completes
    mut blocked: bool = false
    # a connect to a host name that didn't resolve: CONNECTING for good, as
    # in the reference (sockets.star sock_connect())
    mut stalled: bool = false
    # a listener's accepted connections LPC hasn't socket_accept()ed yet,
    # and (STREAM_TLS, P1 #8) each one's TLS session, its handshake done
    mut pending: List<ptr> = List<ptr>()
    mut pending_tls: List<i32> = List<i32>()
    mut pending_early: List<Bytes> = List<Bytes>()
    # STREAM_TLS (P1 #8): the stream's TLS session (tls.star), -1 for none,
    # and what its peer sent with the end of the handshake, delivered on the
    # pass after socket_accept() (Pike's SSL.File holds it until then)
    mut tls: i32 = -1
    mut early: Bytes = Bytes()

# A resolve() answer waiting for the driver's next pass (efuns.pike
# resolve(), which delivers through a Pike call_out): callback(name, ip, key)
# in `ob`. `ip` is "" for a name that didn't resolve (the reference's 0).
struct PendingResolve:
    ob: val::Value
    fun: val::Value
    name: str
    ip: str
    has_ip: bool
    key: i32

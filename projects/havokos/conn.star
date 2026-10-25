# One user connection's state -- todo.md HavokOS M6, `havok/net.pike`'s
# Connection class without its methods (those are `net.star`'s, on the Vm,
# since every one of them can call back into LPC). It lives in its own file
# so `vm.star` can hold the connection table without importing the network
# layer.
#
# The reference keeps a Connection per socket and drops it from its
# `connections` set when it closes. Here connections sit in `Vm.conns` and a
# closed one's slot is reused by the next connection (`alive` false), so an
# object's `ObjSlot.conn` index stays valid while it is attached; it is set
# to -1 the moment the object stops being interactive.
#
# Telnet option flags are `Set<i32>`s of option bytes (the reference's
# multisets). Input and output are `Bytes` with a read offset, so a line or
# a partly sent buffer is consumed without copying what's left on every
# read (NOTES.md constraint #10).

import "value.star" as val

struct Conn:
    mut alive: bool = true
    # null for a connection with no socket (the case runner's test_tel_*
    # hooks): output collects in `outbuf` until the test drains it
    mut sock: ptr = null_ptr()
    mut closed: bool = false
    # users() lists in connection order
    mut seq: i32 = 0
    mut ip: str = "0.0.0.0"
    mut local_port: i32 = 0
    # the object this connection drives, or -1
    mut user: i32 = -1
    # snoop(): an object value (generation-checked), 0 for none
    mut snooped_by: val::Value = val::Value::Int(0 as i64)
    mut in_snoop: bool = false
    mut last_input: i64 = 0 as i64
    mut charmode: bool = false
    # negotiated state: options this side performs (the client said DO),
    # options the client performs (it said WILL), and our pending offers
    mut local_on: Set<i32> = Set<i32>()
    mut remote_on: Set<i32> = Set<i32>()
    mut local_asked: Set<i32> = Set<i32>()
    mut remote_asked: Set<i32> = Set<i32>()
    mut gmcp: bool = false
    mut mxp: bool = false
    mut zmp: bool = false
    mut msdp: bool = false
    mut msp: bool = false
    mut utf8: bool = false
    # TTYPE: the first answer, every distinct answer, the MTTS bits (-1
    # until sent), and whether the driver stopped asking
    mut terminal: str = ""
    mut has_terminal: bool = false
    mut terminals: List<str> = List<str>()
    mut mtts: i64 = (0 - 1) as i64
    mut ttype_done: bool = false
    # NEW-ENVIRON variables, in the order first set
    mut env_keys: List<str> = List<str>()
    mut env_vals: Map<str, str> = Map<str, str>()
    # last NAWS report (empty until one came)
    mut window: List<i32> = List<i32>()
    # telnet-filtered input not yet split into lines, from `in_off`
    mut inbuf: Bytes = Bytes()
    mut in_off: i32 = 0
    # bytes for the wire not yet taken by the socket, from `out_off`
    mut outbuf: Bytes = Bytes()
    mut out_off: i32 = 0
    # telnet parser state (net.star TS_*), the WILL/WONT/DO/DONT being
    # read, the subnegotiation being collected
    mut tstate: i32 = 0
    mut tcmd: i32 = 0
    mut sbuf: Bytes = Bytes()
    # the last line ended with CR: drop a following LF or NUL
    mut skip_lf: bool = false
    # pending input_to()/get_char(): the function (0 for none), the object
    # that asked (pushed on the driver stack for the call), its flags and
    # extra arguments
    mut input_fn: val::Value = val::Value::Int(0 as i64)
    mut input_owner: val::Value = val::Value::Int(0 as i64)
    mut input_flags: i32 = 0
    mut input_args: List<val::Value> = List<val::Value>()
    mut noecho_active: bool = false

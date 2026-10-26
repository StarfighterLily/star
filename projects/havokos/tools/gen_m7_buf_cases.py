"""Generates tests/fixtures/cases/m7_buf.expected.txt (todo.md HavokOS P1 #8).

LPC buffers (buffers.star) have no oracle: the reference has no buffer type
at all. So, unlike every other fixture, the expected column here is written
by hand -- from Dead Souls 3.9's own documentation of FluffOS buffers
(E:/ds3.9/lib/doc/efun/buffers/*, doc/efun/mixed/bufferp,
doc/lpc/types/buffer) and, where it is silent, from the choices
buffers.star's header spells out -- and the generator writes the fixture
directly, in the form tools/run_cases.star reads (name, body, expected).
Values are in run_cases' canonical form; a buffer renders as BUF<hex>, a
form only this fixture uses.

Usage: python tools/gen_m7_buf_cases.py > tests/fixtures/cases/m7_buf.expected.txt
"""

CASES = []


def case(name, body, expected, globals_=""):
    CASES.append((name, (globals_ + " @@ " if globals_ else "") + body, expected))


case("buffer: allocate_buffer gives zero bytes",
     'buffer b = allocate_buffer(4); return ({ b, sizeof(b), bufferp(b), typeof(b), bufferp("x"), bufferp(({})) });',
     '({BUF<00000000>,4,1,"buffer",0,0})')
case("buffer: an empty buffer",
     'buffer b = allocate_buffer(0); return ({ b, sizeof(b) });',
     '({BUF<>,0})')
case("buffer: a negative size is an error",
     'return allocate_buffer(-1);',
     'ERR "Illegal buffer size.\\n"')
case("buffer: a size past the maximum buffer size is an error",
     'return allocate_buffer(400001);',
     'ERR "Illegal buffer size.\\n"')
case("buffer: elements are bytes",
     'buffer b = allocate_buffer(4); b[0] = 65; b[1] = 256 + 66; b[-1] = 255; b[2] = -1; '
     'return ({ b, b[0], b[1], b[-1], b[2] });',
     '({BUF<4142ffff>,65,66,255,255})')
case("buffer: an index past the end is an error",
     'buffer b = allocate_buffer(4); return b[4];',
     'ERR "Buffer index out of bounds (4/4).\\n"')
case("buffer: storing a non-int is an error",
     'buffer b = allocate_buffer(2); b[0] = "x"; return b;',
     'ERR "Bad buffer index assignment.\\n"')
case("buffer: ranges are new buffers",
     'buffer b = allocate_buffer(5); for (int i = 0; i < 5; i++) b[i] = 97 + i; '
     'buffer c = b[1..2]; c[0] = 0; return ({ b[1..2], b[3..], b[..1], b[<2..], b[4..9], b[3..1], c, b });',
     '({BUF<6263>,BUF<6465>,BUF<6162>,BUF<6465>,BUF<65>,BUF<>,BUF<0063>,BUF<6162636465>})')
case("buffer: + makes a new buffer, += too",
     'buffer a = allocate_buffer(1); buffer b = allocate_buffer(2); a[0] = 1; b[1] = 2; '
     'buffer c = a + b; buffer d = a; d += b; return ({ c, d, a, d == a, c == a + b });',
     '({BUF<010002>,BUF<010002>,BUF<01>,0,0})')
case("buffer: shared by reference, equal only to itself",
     'buffer a = allocate_buffer(2); buffer b = a; b[0] = 7; '
     'return ({ a, a == b, a == allocate_buffer(2), allocate_buffer(0) == allocate_buffer(0) });',
     '({BUF<0700>,1,0,0})')
case("buffer: a mapping key by identity",
     'buffer a = allocate_buffer(1); buffer b = allocate_buffer(1); mapping m = ([ a: "a" ]); '
     'return ({ m[a], m[b], sizeof(m) });',
     '({"a",0,1})')
case("read_buffer: a buffer's bytes as a string",
     'buffer b = allocate_buffer(5); for (int i = 0; i < 5; i++) b[i] = 104 + i; '
     'return ({ read_buffer(b), read_buffer(b, 1, 2), read_buffer(b, -2), read_buffer(b, 3, 0), read_buffer(b, 9) });',
     '({"hijkl","ij","kl","kl",""})')
case("read_buffer: a string stops at a NUL",
     'buffer b = allocate_buffer(3); b[0] = 97; b[2] = 98; return ({ read_buffer(b), sizeof(read_buffer(b)) });',
     '({"a",1})')
case("write_buffer: strings, ints and buffers into a buffer",
     'buffer b = allocate_buffer(8); buffer c = allocate_buffer(2); c[0] = 9; c[1] = 8; '
     'mixed r = ({ write_buffer(b, 0, "hi"), write_buffer(b, 2, 0x01020304), write_buffer(b, 6, c) }); '
     'return ({ r, b });',
     '({({1,1,1}),BUF<6869010203040908>})')
case("write_buffer: a negative start counts from the end",
     'buffer b = allocate_buffer(4); write_buffer(b, -1, "z"); return b;',
     'BUF<0000007a>')
case("write_buffer: data that doesn't fit is an error",
     'buffer b = allocate_buffer(3); return write_buffer(b, 2, "xy");',
     'ERR "write_buffer: the data doesn\'t fit in the buffer.\\n"')
case("write_buffer: a bad source is an error",
     'buffer b = allocate_buffer(3); return write_buffer(b, 0, ({}));',
     'ERR "Bad argument 3 to write_buffer()\\n"')
case("buffer files: written and read back, NULs and all",
     'buffer b = allocate_buffer(5); b[0] = 1; b[2] = 255; b[4] = 7; '
     'int w = write_buffer("/test/tmp_buf.bin", 0, b); buffer back = read_buffer("/test/tmp_buf.bin"); '
     'mixed r = ({ w, back, read_buffer("/test/tmp_buf.bin", 2, 2), file_size("/test/tmp_buf.bin"), back == b }); '
     'rm("/test/tmp_buf.bin"); return r;',
     '({1,BUF<0100ff0007>,BUF<ff00>,5,0})')
case("buffer files: writing in the middle, and past the end",
     'write_file("/test/tmp_buf.txt", "abcdef", 1); '
     'mixed r = ({ write_buffer("/test/tmp_buf.txt", 2, "XY"), read_buffer("/test/tmp_buf.txt"), '
     'write_buffer("/test/tmp_buf.txt", 8, "Z"), read_buffer("/test/tmp_buf.txt") }); '
     'rm("/test/tmp_buf.txt"); return r;',
     '({1,BUF<616258596566>,1,BUF<61625859656600005a>})')
case("buffer files: missing, denied, and the transfer limit",
     'string big = ""; for (int i = 0; i < 1100; i++) big += "0123456789"; write_file("/test/tmp_buf_big.txt", big, 1); '
     'mixed r = ({ read_buffer("/test/no_such_file"), read_buffer("/secret/x"), write_buffer("/secret/x", 0, "y"), '
     'sizeof(read_buffer("/test/tmp_buf_big.txt", 0, 10000)) }); '
     'mixed e = catch(read_buffer("/test/tmp_buf_big.txt")); rm("/test/tmp_buf_big.txt"); return ({ r, e });',
     '({({0,0,0,10000}),"*read_buffer: transfer exceeds the maximum byte transfer.\\n"})')
case("buffer files: Dead Souls' GetBuffer() reads a file in chunks",
     'string txt = ""; for (int i = 0; i < 2500; i++) txt += "line " + i + "\\n"; write_file("/test/tmp_buf_ds.txt", txt, 1); '
     'int size = file_size("/test/tmp_buf_ds.txt"); int max = get_config(31); int count = (size / max) + 1; '
     'buffer data = allocate_buffer(size); '
     'for (int i = 0; i < count; i++) { int ptr = i * max; int length = size - ptr > max ? max : size - ptr; '
     'write_buffer(data, ptr, read_buffer("/test/tmp_buf_ds.txt", ptr, length)); } '
     'rm("/test/tmp_buf_ds.txt"); return ({ size, count, sizeof(data), read_buffer(data, 0, 7), read_buffer(data) == txt });',
     '({23890,3,23890,"line 0\\n",1})')
case("buffer: %O and typeof",
     'buffer b = allocate_buffer(3); return ({ sprintf("%O", b), typeof(b), sprintf("%O", ({ b })) });',
     '({"<buffer of 3 bytes>","buffer","({ /* 1 element */\\n    <buffer of 3 bytes>\\n})"})')
# sockets: a STREAM_BINARY listener reads buffers and writes one back to a
# plain STREAM client (sockets.star; deviation #25)
case("buffer sockets: STREAM_BINARY reads a buffer, writes one back",
     'test_config("havok outbound sockets", "1"); '
     'object s = clone_object("/test/tmp_buf_sock"); object c = clone_object("/test/tmp_buf_sock"); '
     'int port = test_free_port(); s->serve(port); c->dial(port); c->say("ping"); '
     'test_sock_pump(s, "got_some"); test_sock_pump(c, "got_some"); '
     'mixed r = ({ s->query_got(), c->query_got() }); s->stop(); c->stop(); destruct(s); destruct(c); '
     'test_config("havok outbound sockets", "0"); return r;',
     '({({1,"ping"}),({0,"pong"})})')

HELPER = r'''// buffer socket fixture: a STREAM_BINARY server answering with a buffer,
// or a STREAM client; each records ({ bufferp(data), the bytes as a string })
int lfd = -1, cfd = -1;
mixed *got = ({});
int got_some() { return sizeof(got); }
mixed *query_got() { return got; }
void on_read(int fd, mixed data) {
    got = ({ bufferp(data), bufferp(data) ? read_buffer(data) : data });
    if (lfd != -1) {
        buffer b = allocate_buffer(4);
        write_buffer(b, 0, "pong");
        socket_write(fd, b);
    }
}
void on_close(int fd) { }
void on_write(int fd) { }
void on_listen(int fd) { cfd = socket_accept(fd, "on_read", "on_write"); }
void serve(int port) {
    lfd = socket_create(3, "on_read", "on_close");
    socket_bind(lfd, port);
    socket_listen(lfd, "on_listen");
}
void dial(int port) {
    cfd = socket_create(1, "on_read", "on_close");
    socket_connect(cfd, "127.0.0.1 " + port, "on_read", "on_write");
}
void say(string s) { test_sock_pump(this_object(), "connected"); socket_write(cfd, s); }
int connected() { return cfd != -1 && socket_status(cfd)[1] == "DATA_XFER"; }
void stop() { if (cfd != -1) socket_close(cfd); if (lfd != -1) socket_close(lfd); }
'''


def lpc_str(src):
    return '"' + src.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'


def esc(s):
    return s.replace("\\", "\\\\").replace("\n", "\\n").replace("\t", "\\t")


setup = ("buffer setup helpers", 'write_file("/test/tmp_buf_sock.c", %s, 1); return 1;' % lpc_str(HELPER), "1")
teardown = ("buffer remove helpers", 'rm("/test/tmp_buf_sock.c"); return 1;', "1")

print("# HavokOS P1 #8 LPC buffer cases (buffers.star). GENERATED by")
print("# tools/gen_m7_buf_cases.py -- edit that, not this file. The expected column is")
print("# hand-written from Dead Souls' own documentation of FluffOS buffers: the")
print("# reference has no buffer type, so there is no live run to record.")
for name, body, expected in [setup] + CASES + [teardown]:
    print(name + "\t" + esc(body.strip()) + "\t" + expected)

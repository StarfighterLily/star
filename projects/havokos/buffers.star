# LPC buffers -- todo.md HavokOS P1 #8: FluffOS's `buffer` type and its
# efuns, allocate_buffer(), read_buffer() and write_buffer() (codes
# 440-442), with bufferp() (efuns_str.star), sizeof(), typeof(), indexing,
# index assignment, ranges and `+` on buffers (vm.star).
#
# Why, with no oracle: the reference has no buffers at all (its bufferp()
# is always 0, read_buffer()/write_buffer() don't exist), but Dead Souls
# 3.9's own servers are written for FluffOS's: its HTTP service is a
# STREAM_BINARY socket (secure/save/inet.o) whose read callback takes a
# buffer and turns it into text with read_buffer(), and its file object
# serves pages as buffers (secure/lib/file.c GetBuffer(): allocate_buffer,
# then write_buffer() of read_buffer() chunks). On the reference every page
# request fails on read_buffer(). So this file follows FluffOS as Dead
# Souls' own documentation describes it (E:/ds3.9/lib/doc/efun/buffers/*,
# doc/lpc/types/buffer -- mudlib text, never FluffOS source), and the
# binary socket modes deliver and accept buffers (sockets.star), NOTES.md
# deviation #25. Where the documentation is silent, the choices are this
# port's and are spelled out below; the buffer cases (m7_buf, hand-checked
# against the documentation, there being no reference run to record) pin
# them.
#
# A buffer is a Value::Buf handle into `Vm.bufs` (value.star), shared by
# reference like an array, holding its bytes NULs included.
# - allocate_buffer(n): n zero bytes; n must be 0 .. `maximum buffer size`.
# - read_buffer(buf, start, len): the bytes as a string. read_buffer(file,
#   start, len): the file's bytes as a buffer, behind the master's
#   valid_read(). start and len as read_bytes() takes them (a negative start
#   counts from the end, a missing or non-positive len reads to the end);
#   a read from a file may not exceed `maximum byte transfer`.
# - write_buffer(buf, start, src) / write_buffer(file, start, src): src is a
#   buffer, a string, or an int written as four bytes, big-endian; into a
#   buffer it must fit (a buffer keeps its size), into a file it overwrites
#   from `start` on (behind valid_write()), the file growing as needed. 1
#   on success.
# A string made from a buffer stops at its first NUL (deviation #7).

import "value.star" as val
import "vm.star" as vm
import "efun_table.star" as et

fn bytes_range(b: Bytes, start_in: i32, ln: i32) -> Bytes:
    let mut start = start_in
    if start < 0:
        start = b.len() + start
    if start < 0:
        start = 0
    let mut end = b.len()
    if ln > 0 and start + ln < end:
        end = start + ln
    let mut o: Bytes = Bytes()
    let mut i = start
    while i < end:
        o.push(b[i])
        i += 1
    o

impl vm::Vm:
    fn efun_buffer(mut self, code: i32, args: List<val::Value>, self_ob: i32) -> val::Value:
        let zero = val::Value::Int(0 as i64)
        if code == et::E_ALLOCATE_BUFFER:
            if !self.is_int(self.arg(args, 0)):
                self.fail("Bad argument 1 to allocate_buffer()\n")
                return val::Value::Undef
            let n = val::int_of(self.arg(args, 0))
            let max = val::int_of(self.efun_get_config(27))
            if n < (0 as i64) or n > max:
                self.fail("Illegal buffer size.\n")
                return val::Value::Undef
            let mut d: Bytes = Bytes()
            for i in 0..(n as i32):
                d.push(0 as u8)
            return self.new_buf(d)
        if code == et::E_READ_BUFFER:
            let start = val::int_of(self.arg(args, 1)) as i32
            let ln = val::int_of(self.arg(args, 2)) as i32
            match self.arg(args, 0):
                val::Value::Buf(h) ->
                    return val::Value::Str(str_from_bytes(bytes_range(self.bufs[h].data, start, ln)))
                val::Value::Str(path) ->
                    if !self.check_read(self_ob, path, "read_buffer"):
                        return zero
                    let rp = self.mud_real(path)
                    if path_kind(rp) != 1:
                        return zero
                    let f = file_open(rp, "rb")
                    if is_null(f):
                        return zero
                    let all = file_read_bytes(f)
                    file_close(f)
                    let part = bytes_range(all, start, ln)
                    if part.len() as i64 > val::int_of(self.efun_get_config(31)):
                        self.fail("read_buffer: transfer exceeds the maximum byte transfer.\n")
                        return val::Value::Undef
                    return self.new_buf(part)
                _ ->
                    self.fail("Bad argument 1 to read_buffer()\n")
                    return val::Value::Undef
        if code == et::E_WRITE_BUFFER:
            let start_v = self.arg(args, 1)
            if !self.is_int(start_v):
                self.fail("Bad argument 2 to write_buffer()\n")
                return val::Value::Undef
            let mut src: Bytes = Bytes()
            match self.arg(args, 2):
                val::Value::Buf(k) ->
                    src = self.bufs[k].data
                val::Value::Str(s) ->
                    src = bytes_from_str(s)
                val::Value::Int(x) ->
                    for s in 0..4:
                        src.push(((x >> (24 - 8 * s)) & (255 as i64)) as u8)
                val::Value::Undef ->
                    for s in 0..4:
                        src.push(0 as u8)
                _ ->
                    self.fail("Bad argument 3 to write_buffer()\n")
                    return val::Value::Undef
            let mut start = val::int_of(start_v) as i32
            match self.arg(args, 0):
                val::Value::Buf(h) ->
                    let n = self.bufs[h].data.len()
                    if start < 0:
                        start = n + start
                    if start < 0 or start + src.len() > n:
                        self.fail("write_buffer: the data doesn't fit in the buffer.\n")
                        return val::Value::Undef
                    for i in 0..src.len():
                        self.bufs[h].data[start + i] = src[i]
                    return val::Value::Int(1 as i64)
                val::Value::Str(path) ->
                    if !self.check_write(self_ob, path, "write_buffer"):
                        return zero
                    let rp = self.mud_real(path)
                    let mut old: Bytes = Bytes()
                    if path_kind(rp) == 1:
                        let f = file_open(rp, "rb")
                        if !is_null(f):
                            old = file_read_bytes(f)
                            file_close(f)
                    if start < 0:
                        start = old.len() + start
                    if start < 0:
                        start = 0
                    let mut out: Bytes = Bytes()
                    for i in 0..start:
                        out.push(if i < old.len(): old[i] else: 0 as u8)
                    for i in 0..src.len():
                        out.push(src[i])
                    let mut i = start + src.len()
                    while i < old.len():
                        out.push(old[i])
                        i += 1
                    let w = file_open(rp, "wb")
                    if is_null(w):
                        return zero
                    let ok = file_write_bytes(w, out)
                    file_close(w)
                    return self.bool_v(ok)
                _ ->
                    self.fail("Bad argument 1 to write_buffer()\n")
                    return val::Value::Undef
        self.fail("unknown efun\n")
        val::Value::Undef

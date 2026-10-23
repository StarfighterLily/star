# A growable byte buffer -- todo.md HavokOS M4 (efuns).
#
# Why a struct and not `fn push_all(mut o: Bytes, x: Bytes) -> Bytes`:
# a free function's `mut` parameter is a copy (NOTES.md constraint #2), and
# because the caller still holds its reference during `o = f(o, x)`, the
# first push inside copies the whole buffer -- every call, so building a
# string piece by piece is quadratic (measured: 20k ten-byte appends take
# 188 ms that way, 1 ms through a `mut self` method). `mut self` methods
# mutate in place, so every string-building efun (sprintf, replace_string,
# the save format, terminal_colour, ...) appends through a `Buf`.

struct Buf:
    mut b: Bytes = Bytes()

impl Buf:
    fn add(mut self, x: Bytes):
        for i in 0..x.len():
            self.b.push(x[i])

    fn add_str(mut self, s: str):
        let x = bytes_from_str(s)
        for i in 0..x.len():
            self.b.push(x[i])

    fn byte(mut self, c: i32):
        self.b.push(c as u8)

    fn repeat(mut self, c: i32, n: i32):
        for i in 0..n:
            self.b.push(c as u8)

    fn len(self) -> i32:
        self.b.len()

    fn to_str(self) -> str:
        str_from_bytes(self.b)

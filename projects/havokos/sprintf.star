# sprintf() -- todo.md HavokOS M4 (efuns).
#
# The reference's sprintf() (`havok/efuns.pike`) maps each top-level object
# argument to its file name and hands everything to *Pike's* own
# predef::sprintf; any error (a type mismatch, too few arguments, an unknown
# conversion) makes it return the format string unchanged. So the rules here
# are Pike's, probed against the live interpreter rather than taken from
# FluffOS or C, and several surprise a FluffOS user:
#   - conversions are strictly typed: %d/%x/%c want an int, %f/%e/%g a float,
#     %s a string; `sprintf("%f", 3)` and `sprintf("%s", 5)` both fail, and
#     so the reference returns the format. `%i` isn't a Pike conversion at
#     all (DS3.9 uses it twice and gets its format back).
#   - %f, %e and %g default to precision 3, not 6 ("%f" of 1.5 is "1.500",
#     "%g" of 100000.0 is "1e+005").
#   - `+`, ` ` and `0` apply to strings too ("%05s" pads with zeros), and
#     `0` right-justifies even with `-`.
#   - `%:N` sets the width *and* the precision, so "%:2s" truncates.
#   - %Nc with a width writes the value as N bytes, big-endian (`-`: little).
#   - %O is Pike's describe format: multi-line, element counts in comments,
#     mapping keys sorted int < float < string.
#   - column mode (`=`) word-wraps a field into lines of its width; text
#     before or between column fields is printed on the first line and
#     blanked on the following ones, text after the last one comes once, at
#     the end.
# Not implemented (an error, so the format comes back): table mode (`#`),
# `$`, `~`, `@`, `/` and `^`. DS3.9 uses none of them.
#
# Floats are formatted exactly (`numfmt.star`); see deviation #3 for why the
# reference's own results differ past the 7th digit.

import "value.star" as val
import "vm.star" as vm
import "numfmt.star" as nf
import "buf.star" as bf

struct Piece:
    mut b: Bytes
    mut col: bool = false
    mut width: i32 = 0
    mut lines: List<Bytes> = List<Bytes>()

fn spaces(n: i32) -> Bytes:
    let mut o: Bytes = Bytes()
    for i in 0..n:
        o.push(32 as u8)
    o

fn pad_bytes(pat: Bytes, n: i32) -> Bytes:
    let mut o: Bytes = Bytes()
    if pat.len() == 0:
        return spaces(n)
    for i in 0..n:
        o.push(pat[i % pat.len()])
    o

fn uint_digits(v: i64, base: i64, upper: bool) -> Bytes:
    let hex = bytes_from_str(if upper: "0123456789ABCDEF" else: "0123456789abcdef")
    let mut x = v
    let mut rev: Bytes = Bytes()
    if x == (0 as i64):
        rev.push(48 as u8)
    # a negative value prints as '-' and its magnitude, so this sees x >= 0
    # except for the most negative int, whose magnitude doesn't fit
    while x != (0 as i64):
        let mut d = x % base
        if d < (0 as i64):
            d = (0 as i64) - d
        rev.push(hex[d as i32])
        x = x / base
    let mut o: Bytes = Bytes()
    let mut i = rev.len() - 1
    while i >= 0:
        o.push(rev[i])
        i -= 1
    o

# UTF-8 for a code point above 255 (Pike strings are wide; LPC strings
# here are bytes)
fn char_bytes(c: i64) -> Bytes:
    let mut o: Bytes = Bytes()
    let v = c as i32
    if c < (0 as i64) or c < (256 as i64):
        o.push(v as u8)
    elif v < 2048:
        o.push((192 + v / 64) as u8)
        o.push((128 + v % 64) as u8)
    elif v < 65536:
        o.push((224 + v / 4096) as u8)
        o.push((128 + (v / 64) % 64) as u8)
        o.push((128 + v % 64) as u8)
    else:
        o.push((240 + v / 262144) as u8)
        o.push((128 + (v / 4096) % 64) as u8)
        o.push((128 + (v / 64) % 64) as u8)
        o.push((128 + v % 64) as u8)
    o

fn is_digit(c: i32) -> bool:
    c >= 48 and c <= 57

# Column mode: the field's text cut into lines of at most `w` characters,
# breaking after the last blank that fits (or inside a word with none);
# a newline in the text ends a line.
fn wrap_lines(b: Bytes, w: i32) -> List<Bytes>:
    let mut out: List<Bytes> = List<Bytes>()
    let mut segs: List<Bytes> = List<Bytes>()
    let mut cur: Bytes = Bytes()
    for i in 0..b.len():
        if (b[i] as i32) == 10:
            segs.push(cur)
            cur = Bytes()
        else:
            cur.push(b[i])
    if cur.len() > 0 or segs.len() == 0:
        segs.push(cur)
    for s in 0..segs.len():
        let seg = segs[s]
        let n = seg.len()
        if n == 0:
            out.push(Bytes())
            continue
        let mut pos = 0
        while pos < n:
            let mut line: Bytes = Bytes()
            if n - pos <= w:
                for i in pos..n:
                    line.push(seg[i])
                pos = n
            else:
                let mut j = pos + w
                while j > pos and (seg[j] as i32) != 32:
                    j -= 1
                if j > pos:
                    for i in pos..j:
                        line.push(seg[i])
                    pos = j + 1
                else:
                    for i in pos..pos + w:
                        line.push(seg[i])
                    pos = pos + w
            out.push(line)
    out

fn justify(b: Bytes, w: i32, left: bool, center: bool, pat: Bytes) -> Bytes:
    let n = w - b.len()
    if n <= 0:
        return b
    let mut o = bf::Buf()
    if center:
        o.add(pad_bytes(pat, n / 2))
        o.add(b)
        o.add(pad_bytes(pat, n - n / 2))
    elif left:
        o.add(b)
        o.add(pad_bytes(pat, n))
    else:
        o.add(pad_bytes(pat, n))
        o.add(b)
    o.b

# Pike's %O string literal: escapes, and a long string split into one
# literal per line after each embedded newline.
fn pike_quote(s: str, indent: i32) -> Bytes:
    let b = bytes_from_str(s)
    let mut o = bf::Buf()
    o.byte(34)
    for i in 0..b.len():
        let c = b[i] as i32
        if c == 34 or c == 92:
            o.byte(92)
            o.byte(c)
        elif c == 10:
            o.byte(92)
            o.byte(110)
            if i + 1 < b.len():
                o.byte(34)
                o.byte(10)
                o.repeat(32, indent)
                o.byte(34)
        elif c == 9:
            o.byte(92)
            o.byte(116)
        elif c == 13:
            o.byte(92)
            o.byte(114)
        elif c == 7:
            o.byte(92)
            o.byte(97)
        elif c == 8:
            o.byte(92)
            o.byte(98)
        elif c == 11:
            o.byte(92)
            o.byte(118)
        elif c == 12:
            o.byte(92)
            o.byte(102)
        elif c < 32 or (c >= 127 and c < 160):
            o.byte(92)
            o.add(uint_digits(c as i64, 8 as i64, false))
            # an octal escape followed by a digit would read as one escape
            if i + 1 < b.len() and is_digit(b[i + 1] as i32):
                o.byte(34)
                o.byte(34)
        else:
            o.byte(c)
    o.byte(34)
    o.b

fn count_comment(n: i32) -> str:
    if n == 1:
        return "/* 1 element */"
    f"/* {n} elements */"

impl vm::Vm:
    # Pike's sort order for mixed values (the %O mapping key order):
    # ints, then floats, then strings, then everything else by handle.
    fn pike_rank(self, v: val::Value) -> i32:
        match v:
            val::Value::Undef -> 0
            val::Value::Int(x) -> 0
            val::Value::Real(x) -> 1
            val::Value::Str(s) -> 2
            val::Value::Arr(h) -> 3
            val::Value::Map(h) -> 4
            val::Value::Obj(h, g) -> 5
            val::Value::Fn(h) -> 6
            val::Value::Cls(h) -> 7
            val::Value::Buf(h) -> 8

    fn pike_before(self, a: val::Value, b: val::Value) -> bool:
        let ra = self.pike_rank(a)
        let rb = self.pike_rank(b)
        if ra != rb:
            return ra < rb
        match a:
            val::Value::Real(x) ->
                match b:
                    val::Value::Real(y) ->
                        return x < y
                    _ ->
                        return false
            val::Value::Str(s) ->
                match b:
                    val::Value::Str(t) ->
                        return vm::str_cmp(s, t) < 0
                    _ ->
                        return false
            _ -> 0
        if ra == 0:
            return val::int_of(a) < val::int_of(b)
        val::mkey(a).a < val::mkey(b).a

    # Pike's %O of v, appended to self.dsc (a VM-owned buffer, so the
    # recursion appends in place: buf.star explains why not a returned Bytes)
    fn describe_into(mut self, v: val::Value, indent: i32):
        match v:
            val::Value::Undef ->
                self.dsc.add_str("0")
            val::Value::Int(x) ->
                self.dsc.add_str(vm::int_str(x))
            val::Value::Real(x) ->
                self.dsc.add_str(vm::fmt_float(x))
            val::Value::Str(s) ->
                self.dsc.add(pike_quote(s, indent))
            val::Value::Arr(h) ->
                let items = self.arrs[h].items
                if items.len() == 0:
                    self.dsc.add_str("({ })")
                    return
                self.dsc.add_str("({ ")
                self.dsc.add_str(count_comment(items.len()))
                self.dsc.byte(10)
                for i in 0..items.len():
                    self.dsc.repeat(32, indent + 4)
                    self.describe_into(items[i], indent + 4)
                    if i + 1 < items.len():
                        self.dsc.byte(44)
                    self.dsc.byte(10)
                self.dsc.repeat(32, indent)
                self.dsc.add_str("})")
            val::Value::Map(h) ->
                let ks = self.maps[h].keys
                if ks.len() == 0:
                    self.dsc.add_str("([ ])")
                    return
                let vs = self.maps[h].vals
                let mut order: List<i32> = List<i32>()
                for i in 0..ks.len():
                    order.push(i)
                let mut a = 1
                while a < order.len():
                    let x = order[a]
                    let mut b = a - 1
                    while b >= 0 and self.pike_before(ks[x], ks[order[b]]):
                        order[b + 1] = order[b]
                        b -= 1
                    order[b + 1] = x
                    a += 1
                self.dsc.add_str("([ ")
                self.dsc.add_str(count_comment(ks.len()))
                self.dsc.byte(10)
                for i in 0..order.len():
                    let k = order[i]
                    self.dsc.repeat(32, indent + 2)
                    self.describe_into(ks[k], indent + 2)
                    self.dsc.add_str(": ")
                    self.describe_into(vs[k], indent + 4)
                    if i + 1 < order.len():
                        self.dsc.byte(44)
                    self.dsc.byte(10)
                self.dsc.repeat(32, indent)
                self.dsc.add_str("])")
            val::Value::Obj(h, g) ->
                if self.objs[h].alive and self.objs[h].gen == g:
                    self.dsc.add_str(self.objs[h].name)
                else:
                    self.dsc.add_str("0")
            val::Value::Fn(h) ->
                self.dsc.add_str(self.fns[h].name)
                self.dsc.add_str("()")
            val::Value::Cls(h) ->
                self.dsc.add_str("class ")
                self.dsc.add_str(self.clss[h].name)
                self.dsc.add_str("()")
            # (no reference to follow: the reference has no buffers)
            val::Value::Buf(h) ->
                self.dsc.add_str(f"<buffer of {self.bufs[h].data.len()} bytes>")

    fn pike_describe(mut self, v: val::Value) -> Bytes:
        self.dsc = bf::Buf()
        self.describe_into(v, 0)
        let out = self.dsc.b
        self.dsc = bf::Buf()
        out

    # The reference's sprintf(): Pike's sprintf, or the format itself when
    # Pike's raises an error.
    fn lpc_sprintf(mut self, fmt: str, args_in: List<val::Value>) -> str:
        let mut args: List<val::Value> = List<val::Value>()
        for i in 0..args_in.len():
            let o = self.obj_of(args_in[i])
            if o >= 0:
                args.push(val::Value::Str(self.objs[o].name))
            else:
                args.push(args_in[i])
        let f = bytes_from_str(fmt)
        let n = f.len()
        let mut pieces: List<Piece> = List<Piece>()
        let mut text = bf::Buf()
        let mut ai = 0
        let mut i = 0
        let mut has_col = false
        while i < n:
            let c = f[i] as i32
            if c != 37:
                text.b.push(f[i])
                i += 1
                continue
            i += 1
            let mut left = false
            let mut plus = false
            let mut space = false
            let mut zero = false
            let mut center = false
            let mut column = false
            let mut pat: Bytes = Bytes()
            pat.push(32 as u8)
            let mut width = -1
            let mut prec = -1
            # where the next number goes: 0 width, 1 precision, 2 both (`:`),
            # 3 nowhere (`;`, Pike's column width for table mode)
            let mut target = 0
            let mut conv = -1
            while i < n and conv < 0:
                let d = f[i] as i32
                if d == 45:
                    left = true
                    i += 1
                elif d == 43:
                    plus = true
                    i += 1
                elif d == 32:
                    space = true
                    i += 1
                elif d == 124:
                    center = true
                    i += 1
                elif d == 61:
                    column = true
                    i += 1
                elif d == 48 and target == 0:
                    zero = true
                    i += 1
                elif d == 39:
                    let mut p: Bytes = Bytes()
                    i += 1
                    while i < n and (f[i] as i32) != 39:
                        p.push(f[i])
                        i += 1
                    i += 1
                    if p.len() > 0:
                        pat = p
                elif d == 46:
                    target = 1
                    prec = 0
                    i += 1
                elif d == 58:
                    target = 2
                    i += 1
                elif d == 59:
                    target = 3
                    i += 1
                elif is_digit(d) or d == 42:
                    let mut num = 0
                    if d == 42:
                        if ai >= args.len():
                            return fmt
                        match args[ai]:
                            val::Value::Int(x) ->
                                num = x as i32
                            val::Value::Undef ->
                                num = 0
                            _ ->
                                return fmt
                        ai += 1
                        i += 1
                        if num < 0 and target != 1:
                            return fmt
                    else:
                        while i < n and is_digit(f[i] as i32):
                            num = num * 10 + ((f[i] as i32) - 48)
                            i += 1
                    if target == 0:
                        width = num
                    elif target == 1:
                        prec = num
                    elif target == 2:
                        width = num
                        prec = num
                    target = 0
                else:
                    conv = d
                    i += 1
            if conv < 0:
                return fmt
            if conv == 37:
                text.byte(37)
                continue
            if conv == 110:
                continue
            let is_num_conv = conv == 100 or conv == 117 or conv == 120 or conv == 88 or conv == 111 or conv == 98 or conv == 99
            let is_float_conv = conv == 102 or conv == 101 or conv == 69 or conv == 103 or conv == 71
            if !is_num_conv and !is_float_conv and conv != 115 and conv != 79 and conv != 116:
                return fmt
            if ai >= args.len():
                return fmt
            let a = args[ai]
            ai += 1
            let mut sign: Bytes = Bytes()
            let mut body: Bytes = Bytes()
            let mut no_pad = false
            if is_num_conv:
                let mut x = 0 as i64
                match a:
                    val::Value::Int(v) ->
                        x = v
                    val::Value::Undef ->
                        x = 0 as i64
                    _ ->
                        return fmt
                if conv == 99:
                    if width > 0:
                        # %Nc: N bytes of the value, big-endian (`-`: little)
                        let mut be: Bytes = Bytes()
                        let mut y = x
                        for k in 0..width:
                            be.push((y & (255 as i64)) as u8)
                            y = y >> 8
                        if left:
                            body = be
                        else:
                            let mut k = be.len() - 1
                            while k >= 0:
                                body.push(be[k])
                                k -= 1
                        no_pad = true
                    else:
                        body = char_bytes(x)
                else:
                    let mut base = 10 as i64
                    if conv == 120 or conv == 88:
                        base = 16 as i64
                    elif conv == 111:
                        base = 8 as i64
                    elif conv == 98:
                        base = 2 as i64
                    body = uint_digits(x, base, conv == 88)
                    if x < (0 as i64):
                        sign.push(45 as u8)
                    elif plus:
                        sign.push(43 as u8)
                    elif space:
                        sign.push(32 as u8)
            elif is_float_conv:
                let mut x = 0.0 as f64
                match a:
                    val::Value::Real(v) ->
                        x = v
                    _ ->
                        return fmt
                let p = if prec < 0: 3 else: prec
                let zf = 0.0 as f64
                let neg = x < zf
                let ax = if neg: zf - x else: x
                if x != x:
                    body = bytes_from_str("nan")
                elif ax - ax != zf:
                    body = bytes_from_str("inf")
                elif conv == 102:
                    body = nf::fixed_abs(ax, p)
                elif conv == 101 or conv == 69:
                    body = nf::exp_abs(ax, p, conv == 69)
                else:
                    body = nf::gen_abs(ax, p, conv == 71, false)
                if neg:
                    sign.push(45 as u8)
                elif plus:
                    sign.push(43 as u8)
                elif space:
                    sign.push(32 as u8)
            elif conv == 115:
                match a:
                    val::Value::Str(s) ->
                        body = bytes_from_str(s)
                    _ ->
                        return fmt
                if prec >= 0 and prec < body.len() and !column:
                    let mut t: Bytes = Bytes()
                    for k in 0..prec:
                        t.push(body[k])
                    body = t
                if plus:
                    sign.push(43 as u8)
                elif space:
                    sign.push(32 as u8)
            elif conv == 79:
                body = self.pike_describe(a)
            else:
                let tn = match a:
                    val::Value::Cls(h) -> "object"
                    _ -> self.type_name(a)
                body = bytes_from_str(tn)
            let mut piece = Piece(b = Bytes())
            if column:
                if width <= 0:
                    return fmt
                let mut whole = bf::Buf(b = sign)
                whole.add(body)
                let ls = wrap_lines(whole.b, width)
                let mut jl: List<Bytes> = List<Bytes>()
                for k in 0..ls.len():
                    jl.push(justify(ls[k], width, left, center, pat))
                pieces.push(Piece(b = text.b))
                text = bf::Buf()
                pieces.push(Piece(b = Bytes(), col = true, width = width, lines = jl))
                has_col = true
                continue
            let total = sign.len() + body.len()
            if no_pad or width <= total:
                text.add(sign)
                text.add(body)
            elif zero:
                text.add(sign)
                text.repeat(48, width - total)
                text.add(body)
            else:
                let mut whole = bf::Buf(b = sign)
                whole.add(body)
                text.add(justify(whole.b, width, left, center, pat))
        if !has_col:
            return text.to_str()
        pieces.push(Piece(b = text.b))
        let mut last_col = 0
        let mut nlines = 0
        for k in 0..pieces.len():
            if pieces[k].col:
                last_col = k
                if pieces[k].lines.len() > nlines:
                    nlines = pieces[k].lines.len()
        let mut o = bf::Buf()
        for li in 0..nlines:
            if li > 0:
                o.byte(10)
            for k in 0..last_col + 1:
                let p = pieces[k]
                if p.col:
                    if li < p.lines.len():
                        o.add(p.lines[li])
                    else:
                        o.repeat(32, p.width)
                elif li == 0:
                    o.add(p.b)
                else:
                    let mut tail = 0
                    for q in 0..p.b.len():
                        if (p.b[q] as i32) == 10:
                            tail = 0
                        else:
                            tail += 1
                    o.repeat(32, tail)
        for k in last_col + 1..pieces.len():
            o.add(pieces[k].b)
        o.to_str()

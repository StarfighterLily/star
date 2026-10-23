# terminal_colour() -- todo.md HavokOS M4 (efuns), `havok/efuns.pike`'s
# terminal_colour(); the rules are HavokOS's docs/terminal-colour-spec.md,
# pinned by the reference's black-box cases (minilib/test/tc_cases.h, whose
# expected values came from the FluffOS 2.23 binary).
#
# The string is cut at "%^". A piece (after the calling object's
# terminal_colour_replace() apply, if it has one) that is a key of the map
# with a string value is a code and becomes that value; anything else is
# text. Without a wrap width the result is just the pieces joined. With one,
# text goes into the current line a character at a time while the visible
# column is counted and the last blank remembered (the break point); when
# the column reaches wrap + 1 the line is cut there (or before the last
# character if there was no blank), closed with the reset string, and the
# colour in effect is reopened on the next line, which starts with `indent`
# spaces. A negative wrap also pads each line out to the width. The
# reference's fast path (copying a run of plain text up to the cut column in
# one go, its last blank becoming the break point) is kept, because it is
# not just an optimisation: it decides which blank is the break point.
#
# Like the reference (and FluffOS), a map without a usable "RESET" string
# gets the default reset *written into it*: the caller sees the change.

import "value.star" as val
import "vm.star" as vm
import "buf.star" as bf
import "efuns_str.star" as estr

fn bslice(b: Bytes, from: i32, to: i32) -> Bytes:
    let mut o: Bytes = Bytes()
    let mut i = if from < 0: 0 else: from
    let end = if to > b.len(): b.len() else: to
    while i < end:
        o.push(b[i])
        i += 1
    o

fn bfind(b: Bytes, c: i32, from: i32) -> i32:
    let mut i = from
    while i < b.len():
        if (b[i] as i32) == c:
            return i
        i += 1
    -1

fn bytes_eq(a: Bytes, b: Bytes) -> bool:
    if a.len() != b.len():
        return false
    for i in 0..a.len():
        if a[i] != b[i]:
            return false
    true

struct Tc:
    mut out: bf::Buf = bf::Buf()
    mut line: bf::Buf = bf::Buf()
    reset: Bytes
    indent: i32
    fill_out: bool

impl Tc:
    # The reference's line.get(): the line so far, and the line emptied
    fn take_line(mut self) -> Bytes:
        let s = self.line.b
        self.line = bf::Buf()
        s

    # Close the current line (already taken) with `content`, start the next
    # one; returns the indent put into it (none when no text follows)
    fn end_line(mut self, content: Bytes, pad: i32, reopen: Bytes, more: bool) -> i32:
        self.out.add(content)
        self.out.add(self.reset)
        if self.fill_out and pad > 0:
            self.out.repeat(32, pad)
        self.out.byte(10)
        self.out.add(reopen)
        if !more:
            return 0
        self.line.repeat(32, self.indent)
        self.indent

impl vm::Vm:
    fn efun_terminal_colour(mut self, args: List<val::Value>, self_ob: i32) -> val::Value:
        let sv = self.arg(args, 0)
        let s = match sv:
            val::Value::Str(x) -> x
            _ -> ""
        let s_ok = match sv:
            val::Value::Str(x) -> true
            _ -> false
        if !s_ok:
            self.fail("Bad argument 1 to terminal_colour()\n")
            return val::Value::Undef
        let mh = match self.arg(args, 1):
            val::Value::Map(h) -> h
            _ -> -1
        if mh < 0:
            self.fail("Bad argument 2 to terminal_colour()\n")
            return val::Value::Undef
        let mut wrap = if args.len() >= 3: val::int_of(args[2]) as i32 else: 0
        let mut indent = if args.len() >= 4: val::int_of(args[3]) as i32 else: 0
        let mut fill_out = false
        if wrap < 0:
            fill_out = true
            wrap = 0 - wrap
        if wrap == 1:
            wrap = 2
        if wrap != 0 and (indent < 0 or indent >= wrap - 1):
            indent = wrap - 2
        let has_codes = str_contains(s, "%^")
        if !has_codes and wrap == 0:
            return sv
        let mut pieces: List<Bytes> = List<Bytes>()
        if has_codes:
            let parts = estr::split_all(bytes_from_str(s), bytes_from_str("%^"))
            for i in 0..parts.len():
                if parts[i].len() > 0:
                    pieces.push(parts[i])
        else:
            pieces.push(bytes_from_str(s))
        let n = pieces.len()
        if n == 0:
            return val::Value::Str("")
        let mut reset: Bytes = Bytes()
        match self.map_get(mh, val::Value::Str("RESET")):
            val::Value::Str(r) ->
                reset = bytes_from_str(r)
            _ -> 0
        if reset.len() == 0:
            # "\e[49;49m\e[0;10m"
            let mut d = bf::Buf()
            d.byte(27)
            d.add_str("[49;49m")
            d.byte(27)
            d.add_str("[0;10m")
            reset = d.b
            self.map_set(mh, val::Value::Str("RESET"), val::Value::Str(str_from_bytes(reset)))
        let mut rprog = -1
        let mut rfn = -1
        let mut rvar = 0
        if self_ob >= 0 and self.objs[self_ob].alive:
            let e = self.any_fn(self_ob, "terminal_colour_replace")
            rprog = e.prog
            rfn = e.fnidx
            rvar = e.var_off
        let mut is_code: List<bool> = List<bool>()
        let mut last_text = -1
        for i in 0..n:
            let mut p = pieces[i]
            if rprog >= 0:
                let r = self.call_direct(rprog, rfn, rvar, self_ob, [val::Value::Str(str_from_bytes(p))])
                if self.err:
                    return val::Value::Undef
                match r:
                    val::Value::Str(x) ->
                        p = bytes_from_str(x)
                    _ -> 0
            let mut code = false
            match self.map_get(mh, val::Value::Str(str_from_bytes(p))):
                val::Value::Str(v) ->
                    p = bytes_from_str(v)
                    code = true
                _ -> 0
            if !code:
                last_text = i
            is_code.push(code)
            pieces[i] = p
        if wrap == 0:
            let mut o = bf::Buf()
            for i in 0..n:
                o.add(pieces[i])
            return val::Value::Str(o.to_str())
        let mut st = Tc(reset = reset, indent = indent, fill_out = fill_out)
        let mut colour: Bytes = Bytes()
        let mut col = 0
        let mut threshold = -1
        let mut bp_mark = 0
        let mut bp_pos = 0
        let mut bp_colour: Bytes = Bytes()
        for i in 0..n:
            let p = pieces[i]
            if is_code[i]:
                st.line.add(p)
                if bytes_eq(p, reset):
                    colour = Bytes()
                elif colour.len() + p.len() < 199:
                    for k in 0..p.len():
                        colour.push(p[k])
                continue
            let plen = p.len()
            let mut j = 0
            while j < plen:
                # fast path: a run with no newline or tab that stays short of
                # the cut column only grows the line; its last blank is the
                # new break point
                if col > threshold:
                    let mut stop = plen
                    let k1 = bfind(p, 10, j)
                    if k1 >= 0:
                        stop = k1
                    let k2 = bfind(p, 9, j)
                    if k2 >= 0 and k2 < stop:
                        stop = k2
                    let m = if stop - j < wrap - col: stop - j else: wrap - col
                    if m > 1:
                        let mut b = m - 1
                        while b >= 0 and (p[j + b] as i32) != 32:
                            b -= 1
                        if b >= 0:
                            bp_mark = col + b + 1
                            bp_pos = st.line.len() + b + 1
                            bp_colour = colour
                        st.line.add(bslice(p, j, j + m))
                        col += m
                        j += m
                        continue
                let c = p[j] as i32
                let more = j < plen - 1 or i < last_text
                if c == 10:
                    let ln = st.take_line()
                    col = st.end_line(ln, wrap - col, colour, more)
                    threshold = -1
                    bp_mark = 0
                    j += 1
                    continue
                let blank = c == 32 or c == 9
                if blank and col <= threshold:
                    # a leading blank on a continuation line: dropped, but
                    # still a break point
                    bp_mark = col
                    bp_pos = st.line.len()
                    bp_colour = colour
                    j += 1
                    continue
                st.line.byte(c)
                col += 1
                if c == 9:
                    col += 8 - (col - 1) % 8
                if blank:
                    bp_mark = col
                    bp_pos = st.line.len()
                    bp_colour = colour
                if col != wrap + 1:
                    j += 1
                    continue
                let sline = st.take_line()
                if bp_mark != 0:
                    # cut just after the blank and drop the one character
                    # before the cut; what follows moves down
                    let rest = col - bp_mark
                    col = rest + st.end_line(bslice(sline, 0, bp_pos - 1), wrap - bp_mark, bp_colour, more or rest > 0)
                    st.line.add(bslice(sline, bp_pos, sline.len()))
                else:
                    # no blank on this line: c moves down on its own
                    col = 1 + st.end_line(bslice(sline, 0, sline.len() - 1), 0, colour, true)
                    st.line.byte(c)
                threshold = indent
                bp_mark = 0
                j += 1
        st.out.add(st.line.b)
        val::Value::Str(st.out.to_str())

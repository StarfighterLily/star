# sscanf() -- todo.md HavokOS M4 (efuns).
#
# The reference (`havok/driver.pike` lpc_sscanf()) rewrites the LPC format
# for Pike's array_sscanf() and post-processes the result into FluffOS's
# rules: `%*` conversions are matched (Pike sees them without the `*`) but
# their values dropped, while still counting towards the result; and when
# the format runs out with input left over, the rest goes into the next
# variable and counts as a match (`sscanf("abc def", "abc", x)` is 1 with x
# " def"), done by appending a `%s` the original format doesn't end with.
# `prepare` and `lpc_sscanf` port that driver code; `pike_scan` is the
# array_sscanf() it calls, whose matching rules were probed against the live
# Pike interpreter (nothing here backtracks, as Pike doesn't):
#   - a literal must match exactly; whitespace in the format is literal too.
#   - %d/%i/%x/%o/%b/%f skip leading whitespace, then need a digit after an
#     optional sign; %i reads 0x/0b/0 prefixes, %x accepts a 0x prefix. A
#     width counts characters after the skipped whitespace.
#   - %s followed by literal text stops at the first occurrence of it and
#     fails if there is none; followed by a number conversion it stops at the
#     first character that could start one (a digit or `-` for %d, so in
#     "abc 12" it takes "abc "); followed by %[set], at the first character
#     in the set; at the end of the format it takes everything, even "".
#     Two adjacent %s are an error.
#   - %Nc reads N bytes as a big-endian int (`-`: little-endian); %c one.
#   - %[set] takes the longest run of characters in the set (`^` negates, a
#     leading `]` is literal, a-z ranges, a trailing `-` literal).
# The compiler side (`compiler.star`, the Sscanf node) assigns the values
# to the lvalue arguments exactly as the emitter's assign_results() does.

import "value.star" as val
import "vm.star" as vm

struct ScanFmt:
    pike: Bytes
    skips: List<bool>
    tail: bool

struct Scan:
    mut vals: List<val::Value> = List<val::Value>()
    mut err: str = ""

# One conversion of the rewritten format: its letter (or 91 for a set), the
# '-' flag, its width (-1 none) and the set's bytes.
struct Conv:
    mut letter: i32 = 0
    mut minus: bool = false
    mut width: i32 = -1
    mut set: Bytes = Bytes()
    mut next: i32 = 0

fn is_ws(c: i32) -> bool:
    c == 32 or c == 9 or c == 10 or c == 13 or c == 11 or c == 12

fn digit_val(c: i32) -> i32:
    if c >= 48 and c <= 57:
        return c - 48
    if c >= 97 and c <= 102:
        return c - 87
    if c >= 65 and c <= 70:
        return c - 55
    99

# driver.pike prepare_sscanf_format()
fn prepare(fmt: str) -> ScanFmt:
    let f = bytes_from_str(fmt)
    let mut out: Bytes = Bytes()
    let mut skips: List<bool> = List<bool>()
    let mut ends_with_s = false
    let mut ends_with_conv = false
    let mut i = 0
    while i < f.len():
        let ch = f[i] as i32
        if ch != 37:
            out.push(f[i])
            ends_with_conv = false
            i += 1
            continue
        if i + 1 < f.len() and (f[i + 1] as i32) == 37:
            out.push(37 as u8)
            out.push(37 as u8)
            i += 2
            ends_with_conv = false
            continue
        let mut skip = false
        out.push(37 as u8)
        i += 1
        if i < f.len() and (f[i] as i32) == 42:
            skip = true
            i += 1
        let mut conv = 0
        while i < f.len():
            conv = f[i] as i32
            out.push(f[i])
            if conv == 91:
                i += 1
                while i < f.len() and (f[i] as i32) != 93:
                    out.push(f[i])
                    i += 1
                if i < f.len():
                    out.push(93 as u8)
                break
            if (conv >= 97 and conv <= 122) or (conv >= 65 and conv <= 90):
                break
            i += 1
        i += 1
        skips.push(skip)
        ends_with_conv = true
        ends_with_s = conv == 115
    let tail = !(ends_with_conv and ends_with_s)
    if tail:
        out.push(37 as u8)
        out.push(115 as u8)
    ScanFmt(pike = out, skips = skips, tail = tail)

# Parse the conversion starting just after a '%' at f[i].
fn parse_conv(f: Bytes, start: i32) -> Conv:
    let mut c = Conv()
    let mut i = start
    while i < f.len():
        let d = f[i] as i32
        if d == 45:
            c.minus = true
            i += 1
        elif d >= 48 and d <= 57:
            let mut w = 0
            while i < f.len() and (f[i] as i32) >= 48 and (f[i] as i32) <= 57:
                w = w * 10 + ((f[i] as i32) - 48)
                i += 1
            c.width = w
        elif d == 91:
            c.letter = 91
            i += 1
            # a leading ']' (after an optional '^') is a member, not the end
            if i < f.len() and (f[i] as i32) == 94:
                c.set.push(f[i])
                i += 1
            if i < f.len() and (f[i] as i32) == 93:
                c.set.push(f[i])
                i += 1
            while i < f.len() and (f[i] as i32) != 93:
                c.set.push(f[i])
                i += 1
            c.next = i + 1
            return c
        else:
            c.letter = d
            c.next = i + 1
            return c
    c.letter = 0
    c.next = i
    c

# Whether byte b is in a %[...] set
fn in_set(set: Bytes, b: i32) -> bool:
    let mut i = 0
    let mut neg = false
    if set.len() > 0 and (set[0] as i32) == 94:
        neg = true
        i = 1
    let mut hit = false
    while i < set.len():
        let lo = set[i] as i32
        if i + 2 < set.len() and (set[i + 1] as i32) == 45:
            let hi = set[i + 2] as i32
            if b >= lo and b <= hi:
                hit = true
            i += 3
        else:
            if b == lo:
                hit = true
            i += 1
    if neg:
        return !hit
    hit

# Can byte b begin a match of conversion `letter`? (what a %s right before
# it stops at)
fn starts_conv(c: Conv, b: i32) -> bool:
    let l = c.letter
    if l == 91:
        return in_set(c.set, b)
    if b == 45:
        return l == 100 or l == 105 or l == 117 or l == 120 or l == 88 or l == 111 or l == 98 or l == 102 or l == 101 or l == 103 or l == 69 or l == 71
    if l == 100 or l == 105 or l == 117:
        return b >= 48 and b <= 57
    if l == 120 or l == 88:
        return digit_val(b) < 16
    if l == 111:
        return b >= 48 and b <= 55
    if l == 98:
        return b == 48 or b == 49
    if l == 102 or l == 101 or l == 103 or l == 69 or l == 71:
        return (b >= 48 and b <= 57) or b == 46
    false

fn pow10(n: i32) -> f64:
    let mut r = 1.0 as f64
    let ten = 10.0 as f64
    if n >= 0:
        for i in 0..n:
            r = r * ten
    else:
        for i in 0..(0 - n):
            r = r / ten
    r

# Pike's array_sscanf(s, fmt): the values of the conversions that matched,
# up to the first that didn't.
fn pike_scan(s: Bytes, f: Bytes) -> Scan:
    let mut r = Scan()
    let mut si = 0
    let mut fi = 0
    while fi < f.len():
        let fc = f[fi] as i32
        if fc != 37:
            if si >= s.len() or (s[si] as i32) != fc:
                return r
            si += 1
            fi += 1
            continue
        if fi + 1 < f.len() and (f[fi + 1] as i32) == 37:
            if si >= s.len() or (s[si] as i32) != 37:
                return r
            si += 1
            fi += 2
            continue
        let c = parse_conv(f, fi + 1)
        fi = c.next
        let l = c.letter
        if l == 115:
            if c.width >= 0:
                if s.len() - si < c.width:
                    return r
                let mut o: Bytes = Bytes()
                for k in si..si + c.width:
                    o.push(s[k])
                si += c.width
                r.vals.push(val::Value::Str(str_from_bytes(o)))
                continue
            let mut end = s.len()
            if fi < f.len():
                let nc = f[fi] as i32
                if nc == 37 and fi + 1 < f.len() and (f[fi + 1] as i32) != 37:
                    let nx = parse_conv(f, fi + 1)
                    if nx.letter == 115:
                        r.err = "Illegal to have two adjecent %s.\n"
                        return r
                    if nx.letter != 99:
                        end = si
                        while end < s.len() and !starts_conv(nx, s[end] as i32):
                            end += 1
                else:
                    # the literal text up to the next conversion
                    let mut lit: Bytes = Bytes()
                    let mut k = fi
                    while k < f.len():
                        if (f[k] as i32) == 37:
                            if k + 1 < f.len() and (f[k + 1] as i32) == 37:
                                lit.push(37 as u8)
                                k += 2
                                continue
                            break
                        lit.push(f[k])
                        k += 1
                    let mut found = -1
                    let mut p = si
                    while p + lit.len() <= s.len() and found < 0:
                        let mut ok = true
                        let mut q = 0
                        while q < lit.len() and ok:
                            if s[p + q] != lit[q]:
                                ok = false
                            q += 1
                        if ok:
                            found = p
                        p += 1
                    if found < 0:
                        return r
                    end = found
            let mut o: Bytes = Bytes()
            for k in si..end:
                o.push(s[k])
            si = end
            r.vals.push(val::Value::Str(str_from_bytes(o)))
            continue
        if l == 91:
            if c.set.len() == 0 or (c.set.len() == 1 and (c.set[0] as i32) == 94):
                r.err = "Empty sscanf range.\n"
                return r
            let mut o: Bytes = Bytes()
            while si < s.len() and in_set(c.set, s[si] as i32) and (c.width < 0 or o.len() < c.width):
                o.push(s[si])
                si += 1
            r.vals.push(val::Value::Str(str_from_bytes(o)))
            continue
        if l == 99:
            let w = if c.width > 0: c.width else: 1
            if s.len() - si < w:
                return r
            let mut v = 0 as i64
            if c.minus:
                let mut k = w - 1
                while k >= 0:
                    v = vm::wadd(vm::wshl(v, 8 as i64), (s[si + k] as i32) as i64)
                    k -= 1
            else:
                for k in 0..w:
                    v = vm::wadd(vm::wshl(v, 8 as i64), (s[si + k] as i32) as i64)
            si += w
            r.vals.push(val::Value::Int(v))
            continue
        if l == 110:
            r.vals.push(val::Value::Int(si as i64))
            continue
        let is_int = l == 100 or l == 105 or l == 117 or l == 120 or l == 88 or l == 111 or l == 98
        let is_float = l == 102 or l == 101 or l == 103 or l == 69 or l == 71
        if !is_int and !is_float:
            r.err = "Bad sscanf format.\n"
            return r
        while si < s.len() and is_ws(s[si] as i32):
            si += 1
        let lim = if c.width >= 0: si + c.width else: s.len()
        let stop = if lim < s.len(): lim else: s.len()
        let mut p = si
        let mut neg = false
        if p < stop and ((s[p] as i32) == 45 or (s[p] as i32) == 43):
            neg = (s[p] as i32) == 45
            p += 1
        if is_float:
            let mut ip = 0.0 as f64
            let ten = 10.0 as f64
            let mut nd = 0
            while p < stop and (s[p] as i32) >= 48 and (s[p] as i32) <= 57:
                ip = ip * ten + (((s[p] as i32) - 48) as f64)
                p += 1
                nd += 1
            let mut frac_digits = 0
            if p + 1 <= stop and p < s.len() and (s[p] as i32) == 46 and p + 1 < stop + 1:
                let save = p
                p += 1
                let mut nf = 0
                while p < stop and (s[p] as i32) >= 48 and (s[p] as i32) <= 57:
                    ip = ip * ten + (((s[p] as i32) - 48) as f64)
                    p += 1
                    nf += 1
                if nf == 0 and nd == 0:
                    p = save
                frac_digits = nf
                nd += nf
            if nd == 0:
                return r
            let mut ex = 0
            if p < stop and ((s[p] as i32) == 101 or (s[p] as i32) == 69):
                let mut q = p + 1
                let mut eneg = false
                if q < stop and ((s[q] as i32) == 45 or (s[q] as i32) == 43):
                    eneg = (s[q] as i32) == 45
                    q += 1
                if q < stop and (s[q] as i32) >= 48 and (s[q] as i32) <= 57:
                    let mut e = 0
                    while q < stop and (s[q] as i32) >= 48 and (s[q] as i32) <= 57:
                        e = e * 10 + ((s[q] as i32) - 48)
                        q += 1
                    ex = if eneg: 0 - e else: e
                    p = q
            let mut v = ip
            let shift = ex - frac_digits
            if shift > 0:
                v = v * pow10(shift)
            elif shift < 0:
                v = v / pow10(0 - shift)
            if neg:
                v = (0.0 as f64) - v
            si = p
            r.vals.push(val::Value::Real(v))
            continue
        let mut base = 10 as i64
        if l == 120 or l == 88:
            base = 16 as i64
            if p + 1 < stop and (s[p] as i32) == 48 and ((s[p + 1] as i32) == 120 or (s[p + 1] as i32) == 88) and p + 2 < stop + 1 and p + 2 < s.len() and digit_val(s[p + 2] as i32) < 16:
                p += 2
        elif l == 111:
            base = 8 as i64
        elif l == 98:
            base = 2 as i64
            if p + 1 < stop and (s[p] as i32) == 48 and ((s[p + 1] as i32) == 98 or (s[p + 1] as i32) == 66):
                p += 2
        elif l == 105:
            if p + 1 < stop and (s[p] as i32) == 48 and ((s[p + 1] as i32) == 120 or (s[p + 1] as i32) == 88):
                base = 16 as i64
                p += 2
            elif p + 1 < stop and (s[p] as i32) == 48 and ((s[p + 1] as i32) == 98 or (s[p + 1] as i32) == 66):
                base = 2 as i64
                p += 2
            elif p < stop and (s[p] as i32) == 48:
                base = 8 as i64
        let mut v = 0 as i64
        let mut nd = 0
        while p < stop and (digit_val(s[p] as i32) as i64) < base:
            v = vm::wadd(vm::wmul(v, base), digit_val(s[p] as i32) as i64)
            p += 1
            nd += 1
        if nd == 0:
            return r
        if neg:
            v = vm::wsub(0 as i64, v)
        si = p
        r.vals.push(val::Value::Int(v))
    r

impl vm::Vm:
    # driver.pike lpc_sscanf(): ({ count, values... }) for the compiler's
    # lvalue assignments (at most `nvars` values).
    fn lpc_sscanf(mut self, sv: val::Value, fv: val::Value, nvars: i32) -> val::Value:
        let s = match sv:
            val::Value::Str(x) -> x
            _ -> ""
        let s_ok = match sv:
            val::Value::Str(x) -> true
            _ -> false
        if !s_ok:
            self.fail("Bad argument 1 to sscanf()\n")
            return val::Value::Undef
        let fmt = match fv:
            val::Value::Str(x) -> x
            _ -> ""
        let f_ok = match fv:
            val::Value::Str(x) -> true
            _ -> false
        if !f_ok:
            self.fail("Bad argument 2 to sscanf()\n")
            return val::Value::Undef
        let pf = prepare(fmt)
        let sc = pike_scan(bytes_from_str(s), pf.pike)
        if sc.err != "":
            self.fail(sc.err)
            return val::Value::Undef
        let mut r = sc.vals
        let nconv = pf.skips.len()
        let mut rest = ""
        let mut has_rest = false
        if pf.tail and r.len() > nconv:
            match r[nconv]:
                val::Value::Str(x) ->
                    rest = x
                _ -> 0
            has_rest = true
            let mut t: List<val::Value> = List<val::Value>()
            for i in 0..nconv:
                t.push(r[i])
            r = t
        let mut count = r.len()
        let mut vals: List<val::Value> = List<val::Value>()
        for i in 0..r.len():
            if !pf.skips[i]:
                vals.push(r[i])
        if count == nconv and has_rest and rest != "" and vals.len() < nvars:
            vals.push(val::Value::Str(rest))
            count += 1
        let mut out: List<val::Value> = [val::Value::Int(count as i64)]
        let mut i = 0
        while i < vals.len() and i < nvars:
            out.push(vals[i])
            i += 1
        self.new_arr(out)

# String efuns -- todo.md HavokOS M4 (efuns), the "Messages and I/O" and
# string parts of `havok/efuns.pike`. sprintf() and sscanf() have files of
# their own (`sprintf.star`, `sscanf.star`), as do regexp() (`regex.star`),
# crypt() (`md5.star`) and terminal_colour() (`tcolour.star`); this file
# holds the smaller ones and the dispatch for all of them.
#
# Each follows its reference counterpart, which in turn follows FluffOS 2.23
# as configured for Dead Souls -- including where the reference leans on a
# Pike built-in whose behavior then *is* the semantics (strsrch() with an int
# needle searches for that character; replace_string()'s count forms split on
# the pattern the way Pike's `/` does). Strings are worked on as `Bytes`
# copies (NOTES.md constraint #3: `str` indexing is O(n)).

import "value.star" as val
import "vm.star" as vm
import "efun_table.star" as et
import "sprintf.star" as spf
import "sscanf.star" as ssc
import "buf.star" as bf
import "regex.star" as rx
import "md5.star" as md5

# Pike's `s / d` for a non-empty d: every piece, empty ones included.
fn split_all(s: Bytes, d: Bytes) -> List<Bytes>:
    let mut out: List<Bytes> = List<Bytes>()
    let mut cur: Bytes = Bytes()
    let mut i = 0
    while i < s.len():
        let mut hit = i + d.len() <= s.len()
        let mut k = 0
        while hit and k < d.len():
            if s[i + k] != d[k]:
                hit = false
            k += 1
        if hit:
            out.push(cur)
            cur = Bytes()
            i += d.len()
        else:
            cur.push(s[i])
            i += 1
    out.push(cur)
    out

# First index of d in s at or after `from`, or -1
fn find_bytes(s: Bytes, d: Bytes, from: i32) -> i32:
    let mut i = from
    while i + d.len() <= s.len():
        let mut k = 0
        let mut ok = true
        while k < d.len() and ok:
            if s[i + k] != d[k]:
                ok = false
            k += 1
        if ok:
            return i
        i += 1
    -1

fn lower_bytes(s: str) -> str:
    let b = bytes_from_str(s)
    let mut o: Bytes = Bytes()
    for i in 0..b.len():
        let c = b[i] as i32
        if c >= 65 and c <= 90:
            o.push((c + 32) as u8)
        else:
            o.push(b[i])
    str_from_bytes(o)

fn suffix(s: str, t: str) -> bool:
    str_ends_with(s, t)

# s without its last n bytes
fn chop(s: str, n: i32) -> str:
    let l = len(s)
    if n >= l:
        return ""
    vm::substr(s, 0, l - n)

fn second_last_vowel(lw: str) -> bool:
    let b = bytes_from_str(lw)
    if b.len() < 2:
        return false
    let c = b[b.len() - 2] as i32
    c == 97 or c == 101 or c == 105 or c == 111 or c == 117

# --- pluralize(): docs/contrib-efuns-spec.md, as the reference implements it

fn plural_irregular(lw: str) -> str:
    if lw == "child":
        return "hildren"
    if lw == "mouse" or lw == "louse":
        return "ice"
    if lw == "goose":
        return "eese"
    if lw == "tooth":
        return "eeth"
    if lw == "foot":
        return "eet"
    if lw == "ox":
        return "xen"
    if lw == "die":
        return "ice"
    if lw == "datum":
        return "ata"
    if lw == "forum":
        return "ora"
    if lw == "index":
        return "ndices"
    if lw == "matrix":
        return "atrices"
    if lw == "sphinx":
        return "phinges"
    if lw == "have":
        return "as"
    if lw == "was":
        return "ere"
    ""

fn plural_word(w: str) -> str:
    let lw = lower_bytes(w)
    let n = len(w)
    if lw == "sheep" or lw == "deer" or lw == "fish" or lw == "moose" or lw == "pants" or lw == "glasses":
        return w
    if lw == "are":
        return "is"
    let tail = plural_irregular(lw)
    if tail != "":
        return concat(vm::substr(w, 0, 1), tail)
    if lw == "roof" or lw == "chief" or lw == "belief" or lw == "beef" or lw == "cliff" or lw == "safe" or lw == "giraffe" or lw == "fife" or lw == "lotus" or lw == "human" or lw == "shaman" or lw == "talisman":
        return concat(w, "s")
    if lw == "bus" or lw == "virus" or lw == "bonus":
        return concat(w, "es")
    if suffix(w, "man"):
        return concat(chop(w, 2), "en")
    if suffix(lw, "ff") or suffix(lw, "fe"):
        return concat(chop(w, 2), "ves")
    if suffix(lw, "f"):
        return concat(chop(w, 1), "ves")
    if suffix(lw, "us"):
        return concat(chop(w, 2), "i")
    if suffix(lw, "is"):
        return concat(chop(w, 2), "es")
    if suffix(w, "as") or suffix(w, "es") or suffix(w, "os"):
        return concat(w, "ses")
    if suffix(lw, "s") or suffix(lw, "x") or suffix(lw, "sh") or suffix(lw, "ch"):
        return concat(w, "es")
    if suffix(lw, "z"):
        return concat(w, if n > 1 and second_last_vowel(lw): "zes" else: "es")
    if suffix(lw, "y") and n > 1:
        if second_last_vowel(lw):
            return concat(w, "s")
        return concat(chop(w, 1), "ies")
    if suffix(lw, "o") and n > 1:
        let b = bytes_from_str(lw)
        if (b[n - 2] as i32) != 111:
            return concat(w, "es")
    concat(w, "s")

fn plural_phrase(s_in: str) -> str:
    let mut s = s_in
    let ls = lower_bytes(s)
    if str_starts_with(ls, "a "):
        s = vm::substr(s, 2, len(s))
    elif str_starts_with(ls, "an "):
        s = vm::substr(s, 3, len(s))
    let b = bytes_from_str(s)
    let mut sp = b.len() - 1
    while sp >= 0 and (b[sp] as i32) != 32:
        sp -= 1
    if sp < 0:
        return plural_word(s)
    concat(vm::substr(s, 0, sp + 1), plural_word(vm::substr(s, sp + 1, b.len())))

# --- query_num()

fn num_small(n: i32) -> str:
    let names = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen"]
    names[n]

fn num_below_100(n: i32) -> str:
    if n < 20:
        return num_small(n)
    let tens = ["", "", "twenty", "thirty", "forty", "fifty", "sixty", "seventy", "eighty", "ninety"]
    if n % 10 != 0:
        return concat(concat(tens[n / 10], "-"), num_small(n % 10))
    tens[n / 10]

fn num_below_1000(n: i32) -> str:
    if n < 100:
        return num_below_100(n)
    let h = concat(num_small(n / 100), " hundred")
    if n % 100 != 0:
        return concat(concat(h, " and "), num_below_100(n % 100))
    h

# --- crc32(): the standard (IEEE 802.3, reflected) CRC-32, Pike's Gz.crc32

fn crc32_of(b: Bytes) -> i64:
    # i64 literals above 2^31 need arithmetic (NOTES.md constraint #6)
    let mask = ((1 as i64) << 32) - (1 as i64)
    let poly = ((1 as i64) << 31) + (1840808736 as i64)    # 0xEDB88320
    let mut crc = mask
    for i in 0..b.len():
        crc = crc ^ ((b[i] as i32) as i64)
        for k in 0..8:
            if (crc & (1 as i64)) != (0 as i64):
                crc = (crc >> 1) ^ poly
            else:
                crc = crc >> 1
    crc ^ mask

impl vm::Vm:
    # efuns.pike compile_re(): the pattern with FluffOS's \< \> word
    # anchors made PCRE's \b, or the reference's error for a bad one
    fn compile_re(mut self, pat: str) -> rx::Regex:
        let r = rx::rx_compile(rx::spencer_to_pcre(pat))
        if !r.ok:
            self.fail(concat(concat("regexp: bad pattern ", pat), "\n"))
        r

    # reg_assoc(str, patterns, tokens, default): ({ pieces, tokens }), the
    # pieces alternating between unmatched text and matches -- the earliest
    # match of any pattern each time (the first pattern on a tie), stopping
    # at an empty one (efuns.pike reg_assoc()).
    fn efun_reg_assoc(mut self, args: List<val::Value>) -> val::Value:
        let s = match self.arg(args, 0):
            val::Value::Str(x) -> x
            _ -> ""
        let pats = self.arr_items(self.arg(args, 1))
        let toks = self.arr_items(self.arg(args, 2))
        let def = self.arg(args, 3)
        let mut res: List<rx::Regex> = List<rx::Regex>()
        for i in 0..pats.len():
            let p = match pats[i]:
                val::Value::Str(x) -> x
                _ -> ""
            res.push(self.compile_re(p))
            if self.err:
                return val::Value::Undef
        let mut pieces: List<val::Value> = List<val::Value>()
        let mut tokens: List<val::Value> = List<val::Value>()
        let mut rest = bytes_from_str(s)
        while rest.len() > 0:
            let mut best = -1
            let mut bstart = 0
            let mut bend = 0
            for i in 0..res.len():
                let m = rx::rx_search(res[i], rest)
                if m.len() > 0 and (best < 0 or m[0] < bstart):
                    best = i
                    bstart = m[0]
                    bend = m[1]
            if best < 0 or bend <= bstart:
                break
            let mut pre: Bytes = Bytes()
            for k in 0..bstart:
                pre.push(rest[k])
            let mut hit: Bytes = Bytes()
            for k in bstart..bend:
                hit.push(rest[k])
            pieces.push(val::Value::Str(str_from_bytes(pre)))
            pieces.push(val::Value::Str(str_from_bytes(hit)))
            tokens.push(def)
            tokens.push(if best < toks.len(): toks[best] else: val::Value::Int(0 as i64))
            let mut nr: Bytes = Bytes()
            for k in bend..rest.len():
                nr.push(rest[k])
            rest = nr
        pieces.push(val::Value::Str(str_from_bytes(rest)))
        tokens.push(def)
        let pa = self.new_arr(pieces)
        let ta = self.new_arr(tokens)
        self.new_arr([pa, ta])

    fn efun_str(mut self, code: i32, name: str, args: List<val::Value>, self_ob: i32) -> val::Value:
        if code == et::E_SPRINTF or code == et::E_PRINTF:
            let fv = self.arg(args, 0)
            let fmt = match fv:
                val::Value::Str(s) -> s
                _ -> ""
            let ok = match fv:
                val::Value::Str(s) -> true
                _ -> false
            if !ok:
                self.fail(if code == et::E_SPRINTF: "Bad argument 1 to sprintf()\n" else: "Bad argument 1 to printf()\n")
                return val::Value::Undef
            let mut rest: List<val::Value> = List<val::Value>()
            for i in 1..args.len():
                rest.push(args[i])
            let r = self.lpc_sprintf(fmt, rest)
            if code == et::E_PRINTF:
                print(r)
                return val::Value::Int(0 as i64)
            return val::Value::Str(r)
        if code == et::E_SSCANF:
            return self.lpc_sscanf(self.arg(args, 0), self.arg(args, 1), val::int_of(self.arg(args, 2)) as i32)
        if code == et::E_PARSE_COMMAND:
            self.fail("parse_command() is not supported by HavokOS\n")
            return val::Value::Undef
        if code == et::E_CAPITALIZE:
            let v = self.arg(args, 0)
            match v:
                val::Value::Str(s) ->
                    if s == "":
                        return v
                    let b = bytes_from_str(s)
                    let c = b[0] as i32
                    if c >= 97 and c <= 122:
                        let mut o: Bytes = Bytes()
                        o.push((c - 32) as u8)
                        for i in 1..b.len():
                            o.push(b[i])
                        return val::Value::Str(str_from_bytes(o))
                    return v
                _ ->
                    return v
        if code == et::E_STRWIDTH:
            match self.arg(args, 0):
                val::Value::Str(s) ->
                    return val::Value::Int(len(s) as i64)
                _ ->
                    return val::Value::Int(0 as i64)
        if code == et::E_STRSRCH:
            let sv = self.arg(args, 0)
            let s = match sv:
                val::Value::Str(x) -> x
                _ -> ""
            let s_ok = match sv:
                val::Value::Str(x) -> true
                _ -> false
            if !s_ok:
                self.fail("Bad argument 1 to strsrch()\n")
                return val::Value::Undef
            let nv = self.arg(args, 1)
            let mut needle: Bytes = Bytes()
            match nv:
                val::Value::Str(x) ->
                    needle = bytes_from_str(x)
                val::Value::Int(c) ->
                    needle = spf::char_bytes(c)
                val::Value::Undef ->
                    needle = spf::char_bytes(0 as i64)
                _ ->
                    return val::Value::Int((0 - 1) as i64)
            if needle.len() == 0:
                return val::Value::Int((0 - 1) as i64)
            let b = bytes_from_str(s)
            if val::int_of(self.arg(args, 2)) == ((0 - 1) as i64):
                let mut r = -1
                let mut pos = find_bytes(b, needle, 0)
                while pos >= 0:
                    r = pos
                    pos = find_bytes(b, needle, pos + 1)
                return val::Value::Int(r as i64)
            return val::Value::Int(find_bytes(b, needle, 0) as i64)
        if code == et::E_REPLACE_STRING:
            let sv = self.arg(args, 0)
            let s = match sv:
                val::Value::Str(x) -> x
                _ -> ""
            let s_ok = match sv:
                val::Value::Str(x) -> true
                _ -> false
            if !s_ok:
                return sv
            let from = match self.arg(args, 1):
                val::Value::Str(x) -> x
                _ -> ""
            if from == "":
                return sv
            let to = match self.arg(args, 2):
                val::Value::Str(x) -> x
                _ -> ""
            let parts = split_all(bytes_from_str(s), bytes_from_str(from))
            let fb = bytes_from_str(from)
            let tb = bytes_from_str(to)
            let mut first = 1 as i64
            let mut last = 0 as i64
            let counted = args.len() > 3
            if args.len() == 4:
                last = val::int_of(args[3])
            elif args.len() > 4:
                first = val::int_of(args[3])
                last = val::int_of(args[4])
            let mut o = bf::Buf(b = parts[0])
            for i in 1..parts.len():
                let ii = i as i64
                let use_to = !counted or (ii >= first and (last <= (0 as i64) or ii <= last))
                o.add(if use_to: tb else: fb)
                o.add(parts[i])
            return val::Value::Str(o.to_str())
        if code == et::E_REPEAT_STRING:
            let n = val::int_of(self.arg(args, 1))
            match self.arg(args, 0):
                val::Value::Str(s) ->
                    if n <= (0 as i64):
                        return val::Value::Str("")
                    let b = bytes_from_str(s)
                    let mut o = bf::Buf()
                    let mut k = 0 as i64
                    while k < n:
                        o.add(b)
                        k = k + (1 as i64)
                    return val::Value::Str(o.to_str())
                _ ->
                    return val::Value::Str("")
        if code == et::E_STRCMP:
            let a = self.arg(args, 0)
            let b = self.arg(args, 1)
            match a:
                val::Value::Str(s) ->
                    match b:
                        val::Value::Str(t) ->
                            let c = vm::str_cmp(s, t)
                            if c < 0:
                                return val::Value::Int((0 - 1) as i64)
                            if c > 0:
                                return val::Value::Int(1 as i64)
                            return val::Value::Int(0 as i64)
                        _ -> 0
                _ -> 0
            self.fail("Bad argument to strcmp()\n")
            return val::Value::Undef
        if code == et::E_STRING_DIFFERENCE:
            let a = self.arg(args, 0)
            let b = self.arg(args, 1)
            if self.lpc_eq(a, b):
                return val::Value::Str("")
            return b
        if code == et::E_PLURALIZE:
            match self.arg(args, 0):
                val::Value::Str(s) ->
                    if s == "":
                        return val::Value::Int(0 as i64)
                    let b = bytes_from_str(s)
                    let of = find_bytes(b, bytes_from_str(" of "), 0)
                    if of >= 0:
                        return val::Value::Str(concat(plural_phrase(vm::substr(s, 0, of)), vm::substr(s, of, b.len())))
                    return val::Value::Str(plural_phrase(s))
                _ ->
                    self.fail("Bad argument 1 to pluralize()\n")
                    return val::Value::Undef
        if code == et::E_QUERY_NUM:
            let nv = self.arg(args, 0)
            if !self.is_int(nv):
                self.fail("Bad argument 1 to query_num()\n")
                return val::Value::Undef
            let n = val::int_of(nv)
            let many = val::int_of(self.arg(args, 1))
            if n < (0 as i64) or n > (99999 as i64) or (many != (0 as i64) and n > many):
                return val::Value::Str("many")
            let ni = n as i32
            if ni < 1000:
                return val::Value::Str(num_below_1000(ni))
            let out = concat(num_below_100(ni / 1000), " thousand")
            let rest = ni % 1000
            if rest == 0:
                return val::Value::Str(out)
            let joiner = if rest < 100 or rest % 100 == 0: " and " else: ", "
            return val::Value::Str(concat(concat(out, joiner), num_below_1000(rest)))
        if code == et::E_CRC32:
            let b = match self.arg(args, 0):
                val::Value::Str(s) -> bytes_from_str(s)
                _ -> Bytes()
            return val::Value::Int(crc32_of(b))
        if code == et::E_BUFFERP:
            return val::Value::Int(0 as i64)
        if code == et::E_REGEXP:
            let pat = match self.arg(args, 1):
                val::Value::Str(p) -> p
                _ -> ""
            let r = self.compile_re(pat)
            if self.err:
                return val::Value::Undef
            let sv = self.arg(args, 0)
            match sv:
                val::Value::Str(s) ->
                    let m = rx::rx_search(r, bytes_from_str(s))
                    return val::Value::Int(if m.len() > 0: 1 as i64 else: 0 as i64)
                val::Value::Arr(h) ->
                    let items = self.arrs[h].items
                    let flag = val::int_of(self.arg(args, 2))
                    let mut out: List<val::Value> = List<val::Value>()
                    for i in 0..items.len():
                        match items[i]:
                            val::Value::Str(s) ->
                                let mut m = rx::rx_search(r, bytes_from_str(s)).len() > 0
                                if (flag & (2 as i64)) != (0 as i64):
                                    m = !m
                                if m:
                                    out.push(items[i])
                                    if (flag & (1 as i64)) != (0 as i64):
                                        out.push(val::Value::Int((i + 1) as i64))
                            _ -> 0
                    return self.new_arr(out)
                _ ->
                    self.fail("Bad argument 1 to regexp()\n")
                    return val::Value::Undef
        if code == et::E_REG_ASSOC:
            return self.efun_reg_assoc(args)
        if code == et::E_CRYPT:
            let pv = self.arg(args, 0)
            let pw = match pv:
                val::Value::Str(s) -> s
                _ -> ""
            let ok = match pv:
                val::Value::Str(s) -> true
                _ -> false
            if !ok:
                self.fail(if name == "oldcrypt": "Bad argument 1 to oldcrypt()\n" else: "Bad argument 1 to crypt()\n")
                return val::Value::Undef
            let mut salt = ""
            let mut have = false
            match self.arg(args, 1):
                val::Value::Str(s) ->
                    if str_starts_with(s, "$1$"):
                        let parts = split_all(bytes_from_str(s), bytes_from_str("$"))
                        salt = if parts.len() > 2: str_from_bytes(parts[2]) else: ""
                        have = true
                    elif len(s) >= 2:
                        salt = vm::substr(s, 0, if len(s) < 8: len(s) else: 8)
                        have = true
                _ -> 0
            if !have:
                let chars = bytes_from_str("./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
                let mut sb: Bytes = Bytes()
                for i in 0..8:
                    sb.push(chars[self.rand_below(64 as i64) as i32])
                salt = str_from_bytes(sb)
            let h = md5::md5_crypt_hash(bytes_from_str(pw), bytes_from_str(salt))
            return val::Value::Str(concat(concat(concat("$1$", salt), "$"), h))
        self.fail(f"Efun {name}() is not implemented by this driver.\n")
        val::Value::Undef

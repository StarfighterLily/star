# json_encode()/json_decode() -- todo.md HavokOS P1 #6 (M7 part 3), the
# reference's HavokOS-only JSON efuns (`havok/efuns.pike` "JSON", efun codes
# 400-401). The reference hands the work to Pike's Standards.JSON, so what
# Pike's encoder and decoder do *is* the semantics, and every rule below was
# probed against the live reference rather than taken from RFC 8259:
#
# Encoding (ASCII_ONLY, plus HUMAN_READABLE for flag 1 and PIKE_CANONICAL
# for flag 2):
# - ints, strings, floats, arrays and mappings; a mapping's int keys become
#   strings, any other key is "mapping keys must be strings or ints"; an
#   object, function or class is "cannot encode <type>"; an array or mapping
#   that contains itself is "cyclic structure" (the same one twice side by
#   side is fine); nesting deeper than 512 is "structure too deep", checked
#   before the type, as the reference's json_value() does.
# - Strings escape `"` `\` \b \f \n \r \t, every other byte below 0x20 and
#   every byte from 0x7f up as \u00xx (lower-case hex); `/` is left alone.
# - Floats print as LPC's (string)float (vm.star fmt_float(): "1e+010",
#   "3.0"); inf and nan are null.
# - Pretty printing indents by two spaces and puts each element and
#   mapping entry on its own line, except that an array of exactly one
#   element stays on the line it starts on: `[1]`, `[[\n  1,\n  2\n]]`,
#   `[{\n  "a": 1\n}]`. Empty containers are `[]` and `{}`.
# - flag 2 sorts the keys bytewise; without it they come in the mapping's
#   own order, insertion order here, Pike's hash order there (deviation
#   #9), so the cases only leave one-key mappings unsorted.
# - A non-int flags argument is the error Pike's `flags & 1` raises,
#   "Bad argument 2 to `&(). Expected <type>.".
#
# Decoding is Pike's decoder, which is laxer than RFC 8259 in two places:
# a trailing comma closes an array or object (`[1,]`, `{"a":1,}`, but not
# `[,]`), and an unsigned number may start with its point (`.5`, but not
# `-.5`). true/false/null are 1/0/0, an object is a mapping (a repeated
# key keeps its last value), a number with a point or exponent is a float.
# Whitespace is space, tab, CR and LF only. A syntax error reports the
# position of the first character the grammar can't take ("syntax error at
# position N"), except that running out of text inside a string reports
# the string's opening quote; a literal is matched character by character,
# so `nulx` fails at 3.
#
# Byte strings and wide strings. The reference decodes text that is valid
# UTF-8 to a wide string first (so positions count characters), and its
# results are Pike wide strings. LPC strings here are byte strings
# (NOTES.md deviation #14), so text that is valid UTF-8 and holds nothing
# above U+00FF is decoded to its Latin-1 bytes, which is exactly the
# reference's answer; text with characters above U+00FF is parsed as the
# bytes it is (its strings come out as UTF-8, positions count bytes), and a
# \u escape above U+00FF becomes UTF-8. A \u0000 cuts its string short
# (deviation #7). NOTES.md deviation #18.
#
# The encoder writes into the VM-owned `jbuf` and the decoder reads `jtext`
# through `jpos`, because both recurse and have to allocate LPC values, and
# only `mut self` methods mutate in place (NOTES.md constraints #2, #10).

import "value.star" as val
import "vm.star" as vm
import "efun_table.star" as et
import "buf.star" as bf

const JSON_MAX_DEPTH: i32 = 512

fn is_ws(c: i32) -> bool:
    c == 32 or c == 9 or c == 10 or c == 13

fn is_digit(c: i32) -> bool:
    c >= 48 and c <= 57

fn hex_val(c: i32) -> i32:
    if c >= 48 and c <= 57:
        return c - 48
    if c >= 97 and c <= 102:
        return c - 87
    if c >= 65 and c <= 70:
        return c - 55
    -1

# One code point as UTF-8.
fn push_utf8(mut o: Bytes, cp: i32) -> Bytes:
    if cp < 128:
        o.push(cp as u8)
    elif cp < 2048:
        o.push((192 + cp / 64) as u8)
        o.push((128 + cp % 64) as u8)
    elif cp < 65536:
        o.push((224 + cp / 4096) as u8)
        o.push((128 + (cp / 64) % 64) as u8)
        o.push((128 + cp % 64) as u8)
    else:
        o.push((240 + cp / 262144) as u8)
        o.push((128 + (cp / 4096) % 64) as u8)
        o.push((128 + (cp / 64) % 64) as u8)
        o.push((128 + cp % 64) as u8)
    o

# The text json_decode() parses: its Latin-1 bytes when it is valid UTF-8
# (shortest forms, no surrogates, at most U+10FFFF, as Pike's
# utf8_to_string() requires) with nothing above U+00FF, else the bytes as
# they are (see the header).
fn json_text(b: Bytes) -> Bytes:
    let mut o: Bytes = Bytes()
    let mut i = 0
    let n = b.len()
    while i < n:
        let c = b[i] as i32
        if c < 128:
            o.push(b[i])
            i += 1
            continue
        let mut need = 0
        let mut cp = 0
        let mut min = 0
        if c >= 194 and c <= 223:
            need = 1
            cp = c - 192
            min = 128
        elif c >= 224 and c <= 239:
            need = 2
            cp = c - 224
            min = 2048
        elif c >= 240 and c <= 244:
            need = 3
            cp = c - 240
            min = 65536
        else:
            return b
        if i + need >= n:
            return b
        for k in 1..need + 1:
            let d = b[i + k] as i32
            if d < 128 or d > 191:
                return b
            cp = cp * 64 + (d - 128)
        if cp < min or cp > 1114111 or (cp >= 55296 and cp <= 57343) or cp > 255:
            return b
        o.push(cp as u8)
        i += need + 1
    o

impl vm::Vm:
    fn efun_json(mut self, code: i32, args: List<val::Value>) -> val::Value:
        if code == et::E_JSON_ENCODE:
            return self.json_encode(args)
        self.json_decode(args)

    # --- encoding ---------------------------------------------------------------

    fn json_encode(mut self, args: List<val::Value>) -> val::Value:
        let mut flags = 0 as i64
        if args.len() > 1:
            match args[1]:
                val::Value::Int(f) ->
                    flags = f
                val::Value::Undef ->
                    flags = 0 as i64
                _ ->
                    self.fail(f"Bad argument 2 to `&(). Expected {self.type_name(args[1])}.\n")
                    return val::Value::Undef
        self.jbuf = bf::Buf()
        self.jseen = List<val::Value>()
        let pretty = (flags % (2 as i64)) != (0 as i64)
        let canon = ((flags / (2 as i64)) % (2 as i64)) != (0 as i64)
        self.json_put(self.arg(args, 0), 0, 0, pretty, canon)
        if self.err:
            return val::Value::Undef
        let s = self.jbuf.to_str()
        self.jbuf = bf::Buf()
        val::Value::Str(s)

    fn json_indent(mut self, depth: i32):
        self.jbuf.byte(10)
        self.jbuf.repeat(32, depth * 2)

    fn json_put_str(mut self, s: str):
        let hex = bytes_from_str("0123456789abcdef")
        let b = bytes_from_str(s)
        self.jbuf.byte(34)
        for i in 0..b.len():
            let c = b[i] as i32
            if c == 34:
                self.jbuf.byte(92)
                self.jbuf.byte(34)
            elif c == 92:
                self.jbuf.byte(92)
                self.jbuf.byte(92)
            elif c == 8:
                self.jbuf.byte(92)
                self.jbuf.byte(98)
            elif c == 12:
                self.jbuf.byte(92)
                self.jbuf.byte(102)
            elif c == 10:
                self.jbuf.byte(92)
                self.jbuf.byte(110)
            elif c == 13:
                self.jbuf.byte(92)
                self.jbuf.byte(114)
            elif c == 9:
                self.jbuf.byte(92)
                self.jbuf.byte(116)
            elif c < 32 or c >= 127:
                self.jbuf.add_str("\\u00")
                self.jbuf.byte(hex[c / 16] as i32)
                self.jbuf.byte(hex[c % 16] as i32)
            else:
                self.jbuf.byte(c)
        self.jbuf.byte(34)

    fn json_seen(self, v: val::Value) -> bool:
        for i in 0..self.jseen.len():
            let same = match self.jseen[i]:
                val::Value::Arr(a) ->
                    match v:
                        val::Value::Arr(b) -> a == b
                        _ -> false
                val::Value::Map(a) ->
                    match v:
                        val::Value::Map(b) -> a == b
                        _ -> false
                _ -> false
            if same:
                return true
        false

    # `depth` is the nesting json_value() counts; `ind` the indentation
    # level, which a one-element array doesn't raise.
    fn json_put(mut self, v: val::Value, depth: i32, ind: i32, pretty: bool, canon: bool):
        if self.err:
            return
        match v:
            val::Value::Undef ->
                self.jbuf.byte(48)
                return
            val::Value::Int(x) ->
                self.jbuf.add_str(vm::int_str(x))
                return
            val::Value::Str(s) ->
                self.json_put_str(s)
                return
            val::Value::Real(x) ->
                if x != x or x - x != (0.0 as f64):
                    self.jbuf.add_str("null")
                else:
                    self.jbuf.add_str(vm::fmt_float(x))
                return
            _ -> 0
        if depth > JSON_MAX_DEPTH:
            self.fail("json_encode: structure too deep\n")
            return
        let is_arr = match v:
            val::Value::Arr(h) -> true
            _ -> false
        let is_map = match v:
            val::Value::Map(h) -> true
            _ -> false
        if !is_arr and !is_map:
            self.fail(f"json_encode: cannot encode {self.type_name(v)}\n")
            return
        if self.json_seen(v):
            self.fail("json_encode: cyclic structure\n")
            return
        self.jseen.push(v)
        if is_arr:
            self.json_put_arr(self.arr_items(v), depth, ind, pretty, canon)
        else:
            match v:
                val::Value::Map(h) ->
                    self.json_put_map(h, depth, ind, pretty, canon)
                _ -> 0
        self.jseen.pop()

    fn json_put_arr(mut self, items: List<val::Value>, depth: i32, ind: i32, pretty: bool, canon: bool):
        self.jbuf.byte(91)
        if pretty and items.len() == 1:
            self.json_put(items[0], depth + 1, ind, pretty, canon)
            self.jbuf.byte(93)
            return
        for i in 0..items.len():
            if i > 0:
                self.jbuf.byte(44)
            if pretty:
                self.json_indent(ind + 1)
            self.json_put(items[i], depth + 1, ind + 1, pretty, canon)
            if self.err:
                return
        if pretty and items.len() > 0:
            self.json_indent(ind)
        self.jbuf.byte(93)

    # The reference builds a string-keyed copy first (json_value()), so an
    # int key and its string spelling are one key there; the later one's
    # value wins, in the earlier one's place.
    fn json_put_map(mut self, h: i32, depth: i32, ind: i32, pretty: bool, canon: bool):
        let ks = self.maps[h].keys
        let vs = self.maps[h].vals
        let mut names: List<str> = List<str>()
        let mut vals: List<val::Value> = List<val::Value>()
        let mut at: Map<str, i32> = Map<str, i32>()
        for i in 0..ks.len():
            let mut name = ""
            match ks[i]:
                val::Value::Int(x) ->
                    name = vm::int_str(x)
                val::Value::Undef ->
                    name = "0"
                val::Value::Str(s) ->
                    name = s
                _ ->
                    self.fail("json_encode: mapping keys must be strings or ints\n")
                    return
            if let Option::Some(j) = at.get(name):
                vals[j] = vs[i]
            else:
                at.insert(name, names.len())
                names.push(name)
                vals.push(vs[i])
        let mut order: List<i32> = List<i32>()
        for i in 0..names.len():
            order.push(i)
        if canon:
            let mut i = 1
            while i < order.len():
                let x = order[i]
                let mut j = i - 1
                while j >= 0 and vm::str_cmp(names[x], names[order[j]]) < 0:
                    order[j + 1] = order[j]
                    j -= 1
                order[j + 1] = x
                i += 1
        self.jbuf.byte(123)
        for i in 0..order.len():
            if i > 0:
                self.jbuf.byte(44)
            if pretty:
                self.json_indent(ind + 1)
            self.json_put_str(names[order[i]])
            self.jbuf.byte(58)
            if pretty:
                self.jbuf.byte(32)
            self.json_put(vals[order[i]], depth + 1, ind + 1, pretty, canon)
            if self.err:
                return
        if pretty and order.len() > 0:
            self.json_indent(ind)
        self.jbuf.byte(125)

    # --- decoding ---------------------------------------------------------------

    fn json_decode(mut self, args: List<val::Value>) -> val::Value:
        let mut text = ""
        match self.arg(args, 0):
            val::Value::Str(s) ->
                text = s
            _ ->
                self.fail("Bad argument 1 to json_decode()\n")
                return val::Value::Undef
        self.jtext = json_text(bytes_from_str(text))
        self.jpos = 0
        self.jerr = -1
        self.jd_ws()
        let v = self.jd_value()
        if self.jerr < 0:
            self.jd_ws()
            if self.jpos < self.jtext.len():
                self.jerr = self.jpos
        self.jtext = Bytes()
        if self.jerr >= 0:
            self.fail(f"json_decode: syntax error at position {self.jerr}\n")
            return val::Value::Undef
        v

    fn jd_at(self, i: i32) -> i32:
        if i < self.jtext.len():
            return self.jtext[i] as i32
        -1

    fn jd_ws(mut self):
        while self.jpos < self.jtext.len() and is_ws(self.jtext[self.jpos] as i32):
            self.jpos += 1

    fn jd_fail(mut self, at: i32) -> val::Value:
        if self.jerr < 0:
            self.jerr = at
        val::Value::Undef

    fn jd_value(mut self) -> val::Value:
        let c = self.jd_at(self.jpos)
        if c == 123:
            return self.jd_object()
        if c == 91:
            return self.jd_array()
        if c == 34:
            let s = self.jd_string()
            if self.jerr >= 0:
                return val::Value::Undef
            return val::Value::Str(s)
        if c == 116:
            return self.jd_literal("true", val::Value::Int(1 as i64))
        if c == 102:
            return self.jd_literal("false", val::Value::Int(0 as i64))
        if c == 110:
            return self.jd_literal("null", val::Value::Int(0 as i64))
        if c == 45 or c == 46 or is_digit(c):
            return self.jd_number()
        self.jd_fail(self.jpos)

    fn jd_literal(mut self, word: str, v: val::Value) -> val::Value:
        let w = bytes_from_str(word)
        for k in 0..w.len():
            if self.jd_at(self.jpos) != (w[k] as i32):
                return self.jd_fail(self.jpos)
            self.jpos += 1
        v

    fn jd_digits(mut self) -> bool:
        if !is_digit(self.jd_at(self.jpos)):
            self.jd_fail(self.jpos)
            return false
        while is_digit(self.jd_at(self.jpos)):
            self.jpos += 1
        true

    fn jd_number(mut self) -> val::Value:
        let start = self.jpos
        let mut is_float = false
        if self.jd_at(self.jpos) == 46:
            # Pike's decoder takes an unsigned number that starts at its point
            self.jpos += 1
            is_float = true
            if !self.jd_digits():
                return val::Value::Undef
        else:
            if self.jd_at(self.jpos) == 45:
                self.jpos += 1
            let d = self.jd_at(self.jpos)
            if !is_digit(d):
                return self.jd_fail(self.jpos)
            self.jpos += 1
            if d != 48:
                while is_digit(self.jd_at(self.jpos)):
                    self.jpos += 1
            if self.jd_at(self.jpos) == 46:
                self.jpos += 1
                is_float = true
                if !self.jd_digits():
                    return val::Value::Undef
        let e = self.jd_at(self.jpos)
        if e == 101 or e == 69:
            self.jpos += 1
            is_float = true
            let sg = self.jd_at(self.jpos)
            if sg == 43 or sg == 45:
                self.jpos += 1
            if !self.jd_digits():
                return val::Value::Undef
        let mut t: Bytes = Bytes()
        for i in start..self.jpos:
            t.push(self.jtext[i])
        if is_float:
            return val::Value::Real(atof(str_from_bytes(t)))
        val::Value::Int(vm::parse_int_prefix(str_from_bytes(t)))

    # Four hex digits at jpos, or -1 (the error is set).
    fn jd_hex4(mut self, start: i32) -> i32:
        let mut v = 0
        for k in 0..4:
            let c = self.jd_at(self.jpos)
            if c < 0:
                self.jd_fail(start)
                return -1
            let h = hex_val(c)
            if h < 0:
                self.jd_fail(self.jpos)
                return -1
            v = v * 16 + h
            self.jpos += 1
        v

    fn jd_string(mut self) -> str:
        let start = self.jpos
        self.jpos += 1
        let mut o: Bytes = Bytes()
        while true:
            let c = self.jd_at(self.jpos)
            if c < 0:
                self.jd_fail(start)
                return ""
            if c == 34:
                self.jpos += 1
                return str_from_bytes(o)
            if c < 32:
                self.jd_fail(self.jpos)
                return ""
            if c != 92:
                o.push(c as u8)
                self.jpos += 1
                continue
            self.jpos += 1
            let e = self.jd_at(self.jpos)
            if e < 0:
                self.jd_fail(start)
                return ""
            self.jpos += 1
            if e == 34 or e == 92 or e == 47:
                o.push(e as u8)
            elif e == 98:
                o.push(8 as u8)
            elif e == 102:
                o.push(12 as u8)
            elif e == 110:
                o.push(10 as u8)
            elif e == 114:
                o.push(13 as u8)
            elif e == 116:
                o.push(9 as u8)
            elif e == 117:
                let mut cp = self.jd_hex4(start)
                if cp < 0:
                    return ""
                if cp >= 55296 and cp <= 56319:
                    # a high surrogate must be followed by its low half
                    if self.jd_at(self.jpos) < 0:
                        self.jd_fail(start)
                        return ""
                    if self.jd_at(self.jpos) != 92:
                        self.jd_fail(self.jpos)
                        return ""
                    self.jpos += 1
                    if self.jd_at(self.jpos) != 117:
                        self.jd_fail(if self.jd_at(self.jpos) < 0: start else: self.jpos)
                        return ""
                    self.jpos += 1
                    let lo_at = self.jpos
                    let lo = self.jd_hex4(start)
                    if lo < 0:
                        return ""
                    if lo < 56320 or lo > 57343:
                        self.jd_fail(lo_at)
                        return ""
                    cp = 65536 + (cp - 55296) * 1024 + (lo - 56320)
                if cp < 256:
                    o.push(cp as u8)
                else:
                    o = push_utf8(o, cp)
            else:
                self.jd_fail(self.jpos - 1)
                return ""
        ""

    fn jd_array(mut self) -> val::Value:
        self.jpos += 1
        let mut items: List<val::Value> = List<val::Value>()
        self.jd_ws()
        if self.jd_at(self.jpos) == 93:
            self.jpos += 1
            return self.new_arr(items)
        while true:
            let v = self.jd_value()
            if self.jerr >= 0:
                return val::Value::Undef
            items.push(v)
            self.jd_ws()
            let c = self.jd_at(self.jpos)
            if c == 93:
                self.jpos += 1
                return self.new_arr(items)
            if c != 44:
                return self.jd_fail(self.jpos)
            self.jpos += 1
            self.jd_ws()
            if self.jd_at(self.jpos) == 93:
                self.jpos += 1
                return self.new_arr(items)
        val::Value::Undef

    fn jd_object(mut self) -> val::Value:
        self.jpos += 1
        let h = self.new_map()
        self.jd_ws()
        if self.jd_at(self.jpos) == 125:
            self.jpos += 1
            return val::Value::Map(h)
        while true:
            if self.jd_at(self.jpos) != 34:
                return self.jd_fail(self.jpos)
            let k = self.jd_string()
            if self.jerr >= 0:
                return val::Value::Undef
            self.jd_ws()
            if self.jd_at(self.jpos) != 58:
                return self.jd_fail(self.jpos)
            self.jpos += 1
            self.jd_ws()
            let v = self.jd_value()
            if self.jerr >= 0:
                return val::Value::Undef
            self.map_set(h, val::Value::Str(k), v)
            self.jd_ws()
            let c = self.jd_at(self.jpos)
            if c == 125:
                self.jpos += 1
                return val::Value::Map(h)
            if c != 44:
                return self.jd_fail(self.jpos)
            self.jpos += 1
            self.jd_ws()
            if self.jd_at(self.jpos) == 125:
                self.jpos += 1
                return val::Value::Map(h)
        val::Value::Undef

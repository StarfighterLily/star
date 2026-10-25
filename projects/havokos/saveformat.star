# The save format -- todo.md HavokOS M4 (efuns): `havok/saveformat.pike`
# (save_variable()/restore_variable() and the .o files of save_object()/
# restore_object()), plus the per-program variable walk the reference's
# emitter generates as `__lpc_save`/`__lpc_restore`.
#
#   ints      123  -5
#   floats    %.6f (1.500000)
#   strings   "..." with \" and \\ escaped, a newline stored as a raw \r
#   arrays    ({v,v,})
#   mappings  ([k:v,k:v,])
#   classes   (/v,v,/)
#   anything else (objects, functions) saves as 0, and an empty slot
#   (`({1,,2,})`, what FluffOS writes for an object) reads back as 0
#
# A .o file is `#<program>.c` and then one `name value` line per saveable
# variable, sorted by name, int zeros left out unless save_object()'s flag
# asks for them. Saveable means not `static`/`nosave`; inherited programs'
# variables are collected first and an object's own same-named variable
# wins, exactly the order of the emitter's `__lpc_save` (each inherit's,
# then its own `__m[name] = value`). A restored class has no name (the
# reference's `LPCClass(0, 0, values)`): members are positional, so it
# reads back fine through any class type.
#
# The encoder appends to the VM's `enc` buffer (buf.star says why it can't
# pass a Bytes along); the decoder passes the text and a position along and
# returns the new position with each value, because a free function's `mut`
# parameter is a copy in Star (NOTES.md constraint #2).

import "value.star" as val
import "vm.star" as vm
import "numfmt.star" as nf
import "buf.star" as bf

struct DV:
    v: val::Value
    pos: i32

fn float_text(x: f64) -> str:
    let zero = 0.0 as f64
    let a = if x < zero: zero - x else: x
    let body = str_from_bytes(nf::fixed_abs(a, 6))
    if x < zero:
        return concat("-", body)
    body

fn at(s: Bytes, i: i32) -> i32:
    if i >= 0 and i < s.len():
        return s[i] as i32
    0 - 1

impl vm::Vm:
    fn save_encode(mut self, v: val::Value):
        match v:
            val::Value::Str(s) ->
                self.enc.byte(34)
                let b = bytes_from_str(s)
                for i in 0..b.len():
                    let c = b[i] as i32
                    if c == 92 or c == 34:
                        self.enc.byte(92)
                        self.enc.byte(c)
                    elif c == 10:
                        self.enc.byte(13)
                    else:
                        self.enc.byte(c)
                self.enc.byte(34)
            val::Value::Int(x) ->
                self.enc.add_str(vm::int_str(x))
            val::Value::Undef ->
                self.enc.byte(48)
            val::Value::Real(x) ->
                self.enc.add_str(float_text(x))
            val::Value::Arr(h) ->
                let items = self.arrs[h].items
                self.enc.add_str("({")
                for i in 0..items.len():
                    self.save_encode(items[i])
                    self.enc.byte(44)
                self.enc.add_str("})")
            val::Value::Map(h) ->
                let ks = self.maps[h].keys
                let vs = self.maps[h].vals
                self.enc.add_str("([")
                for i in 0..ks.len():
                    self.save_encode(ks[i])
                    self.enc.byte(58)
                    self.save_encode(vs[i])
                    self.enc.byte(44)
                self.enc.add_str("])")
            val::Value::Cls(h) ->
                let vals = self.clss[h].vals
                self.enc.add_str("(/")
                for i in 0..vals.len():
                    self.save_encode(vals[i])
                    self.enc.byte(44)
                self.enc.add_str("/)")
            _ ->
                self.enc.byte(48)

    fn save_variable_str(mut self, v: val::Value) -> str:
        self.enc = bf::Buf()
        self.save_encode(v)
        let out = self.enc.to_str()
        self.enc = bf::Buf()
        out

    fn dec_fail(mut self, msg: str) -> DV:
        self.fail(msg)
        DV(v = val::Value::Undef, pos = 0)

    # saveformat.pike decode_value()
    fn dec_value(mut self, s: Bytes, pos_in: i32) -> DV:
        let mut pos = pos_in
        if pos >= s.len():
            return self.dec_fail("Unexpected end of saved value\n")
        let c = s[pos] as i32
        if c == 44 or c == 58 or ((c == 125 or c == 93 or c == 47) and at(s, pos + 1) == 41):
            return DV(v = val::Value::Int(0 as i64), pos = pos)
        if c == 34:
            pos += 1
            let mut b: Bytes = Bytes()
            while pos < s.len():
                let d = s[pos] as i32
                pos += 1
                if d == 34:
                    return DV(v = val::Value::Str(str_from_bytes(b)), pos = pos)
                if d == 92:
                    if pos < s.len():
                        b.push(s[pos])
                        pos += 1
                    continue
                if d == 13:
                    b.push(10 as u8)
                else:
                    b.push(s[pos - 1])
            return self.dec_fail("Unterminated string in saved value\n")
        if c == 40:
            let kind = at(s, pos + 1)
            pos += 2
            if kind == 123 or kind == 47:
                let close = if kind == 123: 125 else: 47
                let mut items: List<val::Value> = List<val::Value>()
                while true:
                    if pos >= s.len():
                        return self.dec_fail("Unexpected end of saved value\n")
                    if at(s, pos) == close and at(s, pos + 1) == 41:
                        pos += 2
                        if kind == 123:
                            return DV(v = self.new_arr(items), pos = pos)
                        return DV(v = self.new_cls(val::ClsSlot(name = "", vals = items)), pos = pos)
                    let r = self.dec_value(s, pos)
                    if self.err:
                        return r
                    items.push(r.v)
                    pos = r.pos
                    if at(s, pos) == 44:
                        pos += 1
            if kind == 91:
                let m = self.new_map()
                while true:
                    if pos >= s.len():
                        return self.dec_fail("Unexpected end of saved value\n")
                    if at(s, pos) == 93 and at(s, pos + 1) == 41:
                        return DV(v = val::Value::Map(m), pos = pos + 2)
                    let k = self.dec_value(s, pos)
                    if self.err:
                        return k
                    pos = k.pos
                    if at(s, pos) != 58:
                        return self.dec_fail("Expected ':' in saved mapping\n")
                    pos += 1
                    let v = self.dec_value(s, pos)
                    if self.err:
                        return v
                    pos = v.pos
                    self.map_set(m, k.v, v.v)
                    if at(s, pos) == 44:
                        pos += 1
            return self.dec_fail("Bad aggregate in saved value\n")
        # a number, int or float
        let start = pos
        if c == 45:
            pos += 1
        let mut is_float = false
        let mut going = true
        while pos < s.len() and going:
            let d = s[pos] as i32
            if (d >= 48 and d <= 57):
                pos += 1
            elif d == 46 or d == 101 or d == 69:
                is_float = true
                pos += 1
            elif (d == 43 or d == 45) and (at(s, pos - 1) == 101 or at(s, pos - 1) == 69):
                pos += 1
            else:
                going = false
        let mut nb: Bytes = Bytes()
        for i in start..pos:
            nb.push(s[i])
        let num = str_from_bytes(nb)
        if num == "" or num == "-":
            let mut near: Bytes = Bytes()
            let mut i = start
            while i < s.len() and i <= start + 20:
                near.push(s[i])
                i += 1
            return self.dec_fail(concat(concat("Bad saved value at ", vm::esc_quoted(str_from_bytes(near))), "\n"))
        if is_float:
            return DV(v = val::Value::Real(atof(num)), pos = pos)
        DV(v = val::Value::Int(vm::parse_int_prefix(num)), pos = pos)

    fn restore_variable_str(mut self, text: str) -> val::Value:
        let r = self.dec_value(bytes_from_str(text), 0)
        if self.err:
            return val::Value::Undef
        r.v

    # The emitter's __lpc_save: saveable variables of program `pid` (whose
    # block starts at `base` in object o), inherits first, into names/vals.
    fn collect_saveable(mut self, o: i32, pid: i32, base: i32, names: Map<str, i32>, order: List<str>, vals: List<val::Value>) -> SaveSet:
        let mut ss = SaveSet(names = names, order = order, vals = vals)
        let p = self.progs[pid]
        for i in 0..p.inherits.len():
            ss = self.collect_saveable(o, p.inherits[i].prog, base + p.inherits[i].var_off, ss.names, ss.order, ss.vals)
        for j in 0..p.var_names.len():
            if p.var_nosave[j]:
                continue
            let v = self.objs[o].vars[base + p.own_var_start + j]
            let n = p.var_names[j]
            if let Option::Some(k) = ss.names.get(n):
                ss.vals[k] = v
            else:
                ss.names.insert(n, ss.order.len())
                ss.order.push(n)
                ss.vals.push(v)
        ss

    # saveformat.pike encode_file()
    fn encode_object(mut self, o: i32, save_zeros: bool) -> str:
        let ss = self.collect_saveable(o, self.objs[o].prog, 0, Map<str, i32>(), List<str>(), List<val::Value>())
        let mut idx: List<i32> = List<i32>()
        for i in 0..ss.order.len():
            idx.push(i)
        let mut a = 1
        while a < idx.len():
            let x = idx[a]
            let mut b = a - 1
            while b >= 0 and vm::str_cmp(ss.order[x], ss.order[idx[b]]) < 0:
                idx[b + 1] = idx[b]
                b -= 1
            idx[b + 1] = x
            a += 1
        self.enc = bf::Buf()
        self.enc.byte(35)
        self.enc.add_str(self.progs[self.objs[o].prog].path)
        self.enc.add_str(".c")
        self.enc.byte(10)
        for i in 0..idx.len():
            let v = ss.vals[idx[i]]
            if !save_zeros and val::is_zero(v):
                continue
            self.enc.add_str(ss.order[idx[i]])
            self.enc.byte(32)
            self.save_encode(v)
            self.enc.byte(10)
        let out = self.enc.to_str()
        self.enc = bf::Buf()
        out

    # The emitter's __lpc_restore at every level: a variable named in the
    # file gets its value, any other saveable one 0 when `zero`.
    fn restore_saveable(mut self, o: i32, pid: i32, base: i32, m: i32, zero: bool):
        let p = self.progs[pid]
        for i in 0..p.inherits.len():
            self.restore_saveable(o, p.inherits[i].prog, base + p.inherits[i].var_off, m, zero)
        for j in 0..p.var_names.len():
            if p.var_nosave[j]:
                continue
            let k = self.map_find(m, val::Value::Str(p.var_names[j]))
            if k >= 0:
                self.objs[o].vars[base + p.own_var_start + j] = self.maps[m].vals[k]
            elif zero:
                self.objs[o].vars[base + p.own_var_start + j] = val::Value::Int(0 as i64)

    # saveformat.pike decode_file() + __lpc_restore(vals, zero)
    fn decode_object(mut self, o: i32, text: str, zero: bool):
        let m = self.new_map()
        let lines = str_split(text, "\n")
        for i in 0..lines.len():
            let mut line = lines[i]
            if line == "" or str_starts_with(line, "#"):
                continue
            if str_ends_with(line, "\r"):
                line = vm::substr(line, 0, len(line) - 1)
            let b = bytes_from_str(line)
            let mut sp = 0
            while sp < b.len() and (b[sp] as i32) != 32:
                sp += 1
            if sp <= 0 or sp >= b.len():
                continue
            let name = vm::substr(line, 0, sp)
            let vt = vm::substr(line, sp + 1, b.len())
            if vt == "":
                self.map_set(m, val::Value::Str(name), val::Value::Int(0 as i64))
                continue
            let r = self.dec_value(bytes_from_str(vt), 0)
            if self.err:
                let msg = self.errmsg
                self.clear_err()
                self.fail(concat(concat(concat("Error restoring variable ", name), ": "), msg))
                return
            self.map_set(m, val::Value::Str(name), r.v)
        self.restore_saveable(o, self.objs[o].prog, 0, m, zero)

struct SaveSet:
    mut names: Map<str, i32>
    mut order: List<str>
    mut vals: List<val::Value>

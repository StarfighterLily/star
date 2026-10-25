# Efuns -- `havok/efuns.pike`. This file is the dispatch and the M3 subset
# (what the language-semantics cases needed: type predicates, the
# function-pointer efuns, error/throw, the object-loading core of
# call_other); todo.md HavokOS M4 added the rest of the library in one file
# per area (`efuns_str.star`, `efuns_arr.star`, `efuns_file.star`, ...),
# reached by efun_table.star's code ranges, and M5 the object model's
# (`efuns_obj.star`), M6 connections and telnet (`efuns_net.star`) and the
# verb parser (`verbparse.star`, `verbmatch.star`). Efuns of later
# milestones (ed, sockets, M7) still raise the reference's own "not
# implemented" error: the compiler already resolves their names as efuns.
# A program that includes this file uses the compiler's socket builtins,
# so it is built with `-l ws2_32`.
#
# Every efun gets the calling object (`self_ob`, the reference's `self`) --
# the frame's object for a direct call, the owner for an efun pointer.

import "value.star" as val
import "vm.star" as vm
import "efun_table.star" as et
import "efuns_str.star" as estr
import "efuns_arr.star" as earr
import "saveformat.star" as sav
import "efuns_file.star" as efile
import "tcolour.star" as tcol
import "efuns_obj.star" as eobj
import "efuns_net.star" as enet
import "verbparse.star" as vp
import "verbmatch.star" as vpm

impl vm::Vm:
    fn arg(self, args: List<val::Value>, i: i32) -> val::Value:
        if i < args.len():
            return args[i]
        val::Value::Undef

    fn efun(mut self, code: i32, name: str, args: List<val::Value>, self_ob: i32) -> val::Value:
        # M4's library, one file per area (efun_table.star's code ranges)
        if code == et::E_TERMINAL_COLOUR:
            return self.efun_terminal_colour(args, self_ob)
        if code >= 40 and code < 70:
            return self.efun_str(code, name, args, self_ob)
        if code >= 70 and code < 110:
            return self.efun_arr(code, name, args, self_ob)
        if code >= 110 and code < 142:
            return self.efun_file(code, name, args, self_ob)
        if code >= 300 and code < 350:
            return self.efun_net(code, name, args, self_ob)
        if code >= 350 and code < 370:
            return self.efun_parse(code, name, args, self_ob)
        if code >= 200:
            return self.efun_obj(code, name, args, self_ob)
        if code == et::E_MASTER:
            return self.obj_value(self.master_ob)
        if code == et::E_GET_CONFIG:
            return self.efun_get_config(val::int_of(self.arg(args, 0)) as i32)
        if code == et::E_SAVE_VARIABLE:
            return val::Value::Str(self.save_variable_str(self.arg(args, 0)))
        if code == et::E_RESTORE_VARIABLE:
            match self.arg(args, 0):
                val::Value::Str(s) ->
                    return self.restore_variable_str(s)
                _ ->
                    self.fail("Bad argument 1 to restore_variable()\n")
                    return val::Value::Undef
        if code == et::E_UNDEFINEDP:
            match self.arg(args, 0):
                val::Value::Undef ->
                    return val::Value::Int(1 as i64)
                _ ->
                    return val::Value::Int(0 as i64)
        if code == et::E_SIZEOF:
            let v = self.arg(args, 0)
            match v:
                val::Value::Str(s) ->
                    return val::Value::Int(len(s) as i64)
                val::Value::Arr(h) ->
                    return val::Value::Int(self.arrs[h].items.len() as i64)
                val::Value::Map(h) ->
                    return val::Value::Int(self.maps[h].keys.len() as i64)
                val::Value::Cls(h) ->
                    return val::Value::Int(self.clss[h].vals.len() as i64)
                _ ->
                    return val::Value::Int(0 as i64)
        if code == et::E_EVALUATE:
            let f = self.arg(args, 0)
            match f:
                val::Value::Fn(h) ->
                    let mut rest: List<val::Value> = List<val::Value>()
                    for i in 1..args.len():
                        rest.push(args[i])
                    return self.call_value(f, rest)
                _ ->
                    return f
        if code == et::E_EXPLODE:
            return self.efun_explode(self.arg(args, 0), self.arg(args, 1))
        if code == et::E_IMPLODE:
            return self.efun_implode(self.arg(args, 0), self.arg(args, 1))
        if code == et::E_MAP or code == et::E_FILTER:
            return self.efun_map_filter(code == et::E_MAP, args, self_ob)
        if code == et::E_SORT_ARRAY:
            return self.efun_sort_array(args, self_ob)
        if code == et::E_UPPER_CASE or code == et::E_LOWER_CASE:
            let v = self.arg(args, 0)
            match v:
                val::Value::Str(s) ->
                    return val::Value::Str(change_case(s, code == et::E_UPPER_CASE))
                _ ->
                    return v
        if code == et::E_FUNCTIONP:
            match self.arg(args, 0):
                val::Value::Fn(h) ->
                    let s = self.fns[h]
                    if !s.lpcfn:
                        # a function of a destructed object reads as 0 (Pike)
                        return val::Value::Int(if self.fn_dead(h): 0 as i64 else: 1 as i64)
                    let mut f = 5
                    if s.kind == val::FK_EFUN:
                        f = 3
                    elif s.kind == val::FK_SEFUN:
                        f = 4
                    elif s.kind == val::FK_SELF:
                        f = 2
                    if s.bound.len() > 0:
                        f = f | 16
                    # FP_OWNER_DESTED: the owner was destructed
                    let ow = if s.bound_owner >= 0: s.bound_owner else: s.owner
                    if ow > 0 and self.fn_owner(self.arg(args, 0)) < 0:
                        f = f | 32
                    return val::Value::Int(f as i64)
                _ ->
                    return val::Value::Int(0 as i64)
        if code == et::E_ERROR:
            let m = self.arg(args, 0)
            match m:
                val::Value::Str(s) -> self.fail(s)
                _ -> self.fail(self.render(m))
            return val::Value::Undef
        if code == et::E_THROW:
            self.throw_value(self.arg(args, 0))
            return val::Value::Undef
        if code == et::E_CLASSP:
            match self.arg(args, 0):
                val::Value::Cls(h) ->
                    return val::Value::Int(1 as i64)
                _ ->
                    return val::Value::Int(0 as i64)
        if code == et::E_LOAD_OBJECT:
            match self.arg(args, 0):
                val::Value::Str(s) ->
                    return self.load_object(s, self_ob)
                _ ->
                    self.fail("Bad argument 1 to load_object()\n")
                    return val::Value::Undef
        if code == et::E_FIND_OBJECT:
            match self.arg(args, 0):
                val::Value::Str(s) ->
                    let o = self.find_object(s)
                    if o < 0 and args.len() > 1 and self.truthy(args[1]):
                        return self.load_object(s, self_ob)
                    return self.obj_value(o)
                _ ->
                    return val::Value::Int(0 as i64)
        if code == et::E_CLONE_OBJECT:
            let mut rest: List<val::Value> = List<val::Value>()
            for i in 1..args.len():
                rest.push(args[i])
            let p = self.arg(args, 0)
            let ob = self.obj_of(p)
            if ob >= 0:
                let n = self.objs[ob].name
                let parts = str_split(n, "#")
                return self.clone_object(parts[0], rest, self_ob)
            match p:
                val::Value::Str(s) ->
                    return self.clone_object(s, rest, self_ob)
                _ ->
                    self.fail("Bad argument 1 to clone_object()\n")
                    return val::Value::Undef
        if code == et::E_THIS_OBJECT:
            return self.obj_value(self_ob)
        if code == et::E_PREVIOUS_OBJECT:
            let n = val::int_of(self.arg(args, 0)) as i32
            return self.previous(self_ob, n)
        if code == et::E_CALL_OTHER:
            let mut rest: List<val::Value> = List<val::Value>()
            for i in 2..args.len():
                rest.push(args[i])
            return self.call_other_value(self_ob, self.arg(args, 0), self.arg(args, 1), rest)
        if code == et::E_FILE_NAME:
            let o = if args.len() < 1: self_ob else: self.obj_of(args[0])
            if o < 0:
                return val::Value::Int(0 as i64)
            return val::Value::Str(self.objs[o].name)
        if code == et::E_INTP:
            return self.bool_v(self.is_int(self.arg(args, 0)))
        if code == et::E_STRINGP:
            match self.arg(args, 0):
                val::Value::Str(s) ->
                    return val::Value::Int(1 as i64)
                _ ->
                    return val::Value::Int(0 as i64)
        if code == et::E_FLOATP:
            match self.arg(args, 0):
                val::Value::Real(x) ->
                    return val::Value::Int(1 as i64)
                _ ->
                    return val::Value::Int(0 as i64)
        if code == et::E_ARRAYP:
            match self.arg(args, 0):
                val::Value::Arr(h) ->
                    return val::Value::Int(1 as i64)
                _ ->
                    return val::Value::Int(0 as i64)
        if code == et::E_MAPP:
            match self.arg(args, 0):
                val::Value::Map(h) ->
                    return val::Value::Int(1 as i64)
                _ ->
                    return val::Value::Int(0 as i64)
        if code == et::E_OBJECTP:
            return self.bool_v(self.obj_of(self.arg(args, 0)) >= 0)
        if code == et::E_TYPEOF:
            return val::Value::Str(self.type_name(self.arg(args, 0)))
        if code == et::E_WRITE:
            self.do_write(self.arg(args, 0))
            return val::Value::Int(0 as i64)
        if code == et::E_ALLOCATE:
            let n = val::int_of(self.arg(args, 0))
            if n < (0 as i64):
                self.fail("Bad argument 1 to allocate()\n")
                return val::Value::Undef
            let fill = self.arg(args, 1)
            let mut items: List<val::Value> = List<val::Value>()
            let mut i = 0 as i64
            while i < n:
                match fill:
                    val::Value::Fn(h) ->
                        let r = self.call_value(fill, [val::Value::Int(i)])
                        if self.err:
                            return val::Value::Undef
                        items.push(r)
                    val::Value::Undef -> items.push(val::Value::Int(0 as i64))
                    _ -> items.push(fill)
                i = i + (1 as i64)
            return self.new_arr(items)
        if code == et::E_KEYS or code == et::E_VALUES:
            match self.arg(args, 0):
                val::Value::Map(h) ->
                    if code == et::E_KEYS:
                        return self.new_arr(self.maps[h].keys)
                    return self.new_arr(self.maps[h].vals)
                _ ->
                    self.fail(if code == et::E_KEYS: "Bad argument 1 to keys()\n" else: "Bad argument 1 to values()\n")
                    return val::Value::Undef
        if code == et::E_MEMBER_ARRAY:
            let item = self.arg(args, 0)
            let a = self.arg(args, 1)
            let start = val::int_of(self.arg(args, 2)) as i32
            match a:
                val::Value::Arr(h) ->
                    let items = self.arrs[h].items
                    let mut i = start
                    while i < items.len():
                        if self.lpc_eq(items[i], item):
                            return val::Value::Int(i as i64)
                        i += 1
                    return val::Value::Int((0 - 1) as i64)
                val::Value::Str(s) ->
                    if !self.is_int(item):
                        return val::Value::Int((0 - 1) as i64)
                    let b = bytes_from_str(s)
                    let mut i = start
                    while i < b.len():
                        if (b[i] as i64) == val::int_of(item):
                            return val::Value::Int(i as i64)
                        i += 1
                    return val::Value::Int((0 - 1) as i64)
                _ ->
                    if val::is_zero(a):
                        return val::Value::Int((0 - 1) as i64)
                    self.fail("Bad argument 2 to member_array()\n")
                    return val::Value::Undef
        if code == et::E_STRLEN:
            let v = self.arg(args, 0)
            match v:
                val::Value::Str(s) ->
                    return val::Value::Int(len(s) as i64)
                _ ->
                    if val::is_zero(v):
                        return val::Value::Int(0 as i64)
                    self.fail("Bad argument 1 to strlen()\n")
                    return val::Value::Undef
        if code == et::E_TO_INT:
            let v = self.arg(args, 0)
            match v:
                val::Value::Undef ->
                    return v
                val::Value::Int(x) ->
                    return v
                val::Value::Real(x) ->
                    return self.conv(3, v)
                val::Value::Str(s) ->
                    return self.conv(3, v)
                _ ->
                    return val::Value::Int(0 as i64)
        if code == et::E_TO_FLOAT:
            let v = self.arg(args, 0)
            match v:
                val::Value::Real(x) ->
                    return v
                val::Value::Int(x) ->
                    return self.conv(4, v)
                val::Value::Undef ->
                    return self.conv(4, v)
                val::Value::Str(s) ->
                    return self.conv(4, v)
                _ ->
                    return val::Value::Real(0.0 as f64)
        self.fail(f"Efun {name}() is not implemented by this driver.\n")
        val::Value::Undef

    fn cfg_str(self, key: str, def: str) -> val::Value:
        if let Option::Some(v) = self.config.get(key):
            if v != "":
                return val::Value::Str(v)
        val::Value::Str(def)

    fn cfg_int(self, key: str, def: i64) -> val::Value:
        if let Option::Some(v) = self.config.get(key):
            let n = vm::parse_int_prefix(v)
            if n != (0 as i64):
                return val::Value::Int(n)
        val::Value::Int(def)

    # get_config(i): the reference's table (efuns.pike get_config()), the
    # runtime_config.h index order, with its defaults
    fn efun_get_config(self, idx: i32) -> val::Value:
        if idx == 0:
            return self.cfg_str("name", "HavokOS")
        if idx == 1:
            return self.cfg_str("address server ip", "localhost")
        if idx == 2:
            return val::Value::Str(self.root)
        if idx == 3:
            return self.cfg_str("binary directory", "")
        if idx == 4:
            return self.cfg_str("log directory", "/log")
        if idx == 5:
            return self.cfg_str("include directories", "/secure/include:/include")
        if idx == 6:
            return self.cfg_str("save binaries directory", "")
        if idx == 7:
            return self.cfg_str("master file", "/secure/daemon/master")
        if idx == 8:
            return self.cfg_str("simulated efun file", "/secure/sefun/sefun")
        if idx == 9:
            return self.cfg_str("swap file", "")
        if idx == 10:
            return self.cfg_str("debug log file", "debug.log")
        if idx == 11:
            return self.cfg_str("default error message", "")
        if idx == 12:
            return self.cfg_str("default fail message", "What?")
        if idx == 13:
            return self.cfg_str("global include file", "<global.h>")
        if idx == 14:
            return val::Value::Str("127.0.0.1")
        if idx == 15:
            return self.cfg_int("port", 6666 as i64)
        let keys = ["address server port", "time to clean up", "time to reset", "time to swap", "compiler stack size", "evaluator stack size", "inherit chain size", "maximum evaluation cost", "maximum local variables", "maximum call depth", "maximum array size", "maximum buffer size", "maximum mapping size", "maximum string length", "maximum bits in a bitfield", "maximum byte transfer", "maximum read file size"]
        let defs = [0, 0, 0, 0, 200, 1000, 30, 5000000, 35, 30, 64000, 400000, 64000, 200000, 1200, 10000, 200000]
        if idx >= 16 and idx <= 32:
            return self.cfg_int(keys[idx - 16], defs[idx - 16] as i64)
        val::Value::Int(0 as i64)

    # explode() with FluffOS's "sane" rules (__SANE_EXPLODE_STRING__): one
    # leading delimiter and one trailing empty piece are dropped.
    fn efun_explode(mut self, sv: val::Value, dv: val::Value) -> val::Value:
        let s = match sv:
            val::Value::Str(x) -> x
            _ -> ""
        let d = match dv:
            val::Value::Str(x) -> x
            _ -> ""
        let s_ok = match sv:
            val::Value::Str(x) -> true
            _ -> false
        let d_ok = match dv:
            val::Value::Str(x) -> true
            _ -> false
        if !s_ok:
            self.fail("Bad argument 1 to explode()\n")
            return val::Value::Undef
        if !d_ok:
            self.fail("Bad argument 2 to explode()\n")
            return val::Value::Undef
        let mut out: List<val::Value> = List<val::Value>()
        if s == "":
            return self.new_arr(out)
        if d == "":
            let b = bytes_from_str(s)
            for i in 0..b.len():
                let mut one: Bytes = Bytes()
                one.push(b[i])
                out.push(val::Value::Str(str_from_bytes(one)))
            return self.new_arr(out)
        let mut str_v = s
        if str_starts_with(str_v, d):
            str_v = vm::substr(str_v, len(d), len(str_v))
        if str_v == "":
            return self.new_arr(out)
        let parts = str_split(str_v, d)
        let mut n = parts.len()
        if n > 0 and parts[n - 1] == "" and str_ends_with(str_v, d):
            n -= 1
        for i in 0..n:
            out.push(val::Value::Str(parts[i]))
        self.new_arr(out)

    fn efun_implode(mut self, av: val::Value, dv: val::Value) -> val::Value:
        let items = match av:
            val::Value::Arr(h) -> self.arrs[h].items
            _ -> List<val::Value>()
        let a_ok = match av:
            val::Value::Arr(h) -> true
            _ -> false
        if !a_ok:
            self.fail("Bad argument 1 to implode()\n")
            return val::Value::Undef
        match dv:
            val::Value::Fn(h) ->
                if items.len() == 0:
                    return val::Value::Int(0 as i64)
                let mut acc = items[0]
                for i in 1..items.len():
                    acc = self.call_value(dv, [acc, items[i]])
                    if self.err:
                        return val::Value::Undef
                return acc
            val::Value::Str(d) ->
                let mut parts: List<str> = List<str>()
                for i in 0..items.len():
                    match items[i]:
                        val::Value::Str(s) -> parts.push(s)
                        _ -> 0
                return val::Value::Str(str_join(parts, d))
            _ ->
                self.fail("Bad argument 2 to implode()\n")
                return val::Value::Undef

    # map()/filter(arr, fn, extra...) and (arr, "fun", ob, extra...)
    fn efun_map_filter(mut self, is_map: bool, args: List<val::Value>, self_ob: i32) -> val::Value:
        let arr = self.arg(args, 0)
        if val::is_zero(arr):
            return arr
        let f = self.arg(args, 1)
        let mut extra: List<val::Value> = List<val::Value>()
        let mut by_name = false
        let mut fname = ""
        let mut target = val::Value::Undef
        match f:
            val::Value::Fn(h) ->
                for i in 2..args.len():
                    extra.push(args[i])
            val::Value::Str(s) ->
                by_name = true
                fname = s
                target = if args.len() > 2: args[2] else: self.obj_value(self_ob)
                match target:
                    val::Value::Str(t) ->
                        let o = self.find_object(t)
                        target = if o >= 0: self.obj_value(o) else: self.load_object(t, self_ob)
                        if self.err:
                            return val::Value::Undef
                    _ -> 0
                for i in 3..args.len():
                    extra.push(args[i])
            _ ->
                self.fail("Bad function argument\n")
                return val::Value::Undef
        match arr:
            val::Value::Arr(h) ->
                let items = self.arrs[h].items
                let mut out: List<val::Value> = List<val::Value>()
                for i in 0..items.len():
                    let mut a: List<val::Value> = [items[i]]
                    for j in 0..extra.len():
                        a.push(extra[j])
                    let r = if by_name: self.call_other_value(self_ob, target, val::Value::Str(fname), a) else: self.call_value(f, a)
                    if self.err:
                        return val::Value::Undef
                    if is_map:
                        out.push(r)
                    elif self.truthy(r):
                        out.push(items[i])
                return self.new_arr(out)
            val::Value::Map(h) ->
                let ks = self.maps[h].keys
                let vs = self.maps[h].vals
                let m = self.new_map()
                for i in 0..ks.len():
                    let mut a: List<val::Value> = [ks[i], vs[i]]
                    for j in 0..extra.len():
                        a.push(extra[j])
                    let r = if by_name: self.call_other_value(self_ob, target, val::Value::Str(fname), a) else: self.call_value(f, a)
                    if self.err:
                        return val::Value::Undef
                    if is_map:
                        self.map_set(m, ks[i], r)
                    elif self.truthy(r):
                        self.map_set(m, ks[i], vs[i])
                return val::Value::Map(m)
            val::Value::Str(s) ->
                let b = bytes_from_str(s)
                let mut out: Bytes = Bytes()
                for i in 0..b.len():
                    let mut a: List<val::Value> = [val::Value::Int(b[i] as i64)]
                    for j in 0..extra.len():
                        a.push(extra[j])
                    let r = if by_name: self.call_other_value(self_ob, target, val::Value::Str(fname), a) else: self.call_value(f, a)
                    if self.err:
                        return val::Value::Undef
                    if is_map:
                        if self.is_int(r):
                            out.push(val::int_of(r) as u8)
                    elif self.truthy(r):
                        out.push(b[i])
                return val::Value::Str(str_from_bytes(out))
            _ ->
                self.fail(if is_map: "Bad argument 1 to map()\n" else: "Bad argument 1 to filter()\n")
                return val::Value::Undef

    # Ordering for sort_array(arr, 1/-1): Pike's sort() on ints/floats or
    # strings.
    fn sort_less(self, a: val::Value, b: val::Value) -> bool:
        match a:
            val::Value::Str(s) ->
                match b:
                    val::Value::Str(t) ->
                        return vm::str_cmp(s, t) < 0
                    _ ->
                        return false
            _ -> 0
        if self.is_num(a) and self.is_num(b):
            let x = match a:
                val::Value::Real(f) -> f
                _ -> val::int_of(a) as f64
            let y = match b:
                val::Value::Real(f) -> f
                _ -> val::int_of(b) as f64
            return x < y
        false

    # sort_array(): a stable merge sort, which for a consistent comparator
    # gives the same order as Pike's Array.sort_array (`cmp(a, b) > 0` puts
    # a after b).
    fn efun_sort_array(mut self, args: List<val::Value>, self_ob: i32) -> val::Value:
        let arr = self.arg(args, 0)
        let items = match arr:
            val::Value::Arr(h) -> self.arrs[h].items
            _ -> List<val::Value>()
        let ok = match arr:
            val::Value::Arr(h) -> true
            _ -> false
        if !ok:
            self.fail("Bad argument 1 to sort_array()\n")
            return val::Value::Undef
        let how = self.arg(args, 1)
        let mut extra: List<val::Value> = List<val::Value>()
        let mut by_int = false
        let mut desc = false
        let mut f = how
        match how:
            val::Value::Fn(h) ->
                for i in 2..args.len():
                    extra.push(args[i])
            val::Value::Str(s) ->
                let target = if args.len() > 2: args[2] else: self.obj_value(self_ob)
                let o = self.obj_of(target)
                let tob = if o >= 0: o else: self_ob
                let e = self.any_fn(tob, s)
                if e.prog < 0:
                    self.fail(f"sort_array: function {s} not found\n")
                    return val::Value::Undef
                f = self.new_fn(val::FnSlot(kind = val::FK_DIRECT, owner = tob, owner_gen = self.objs[tob].gen, name = s, prog = e.prog, fnidx = e.fnidx, var_base = e.var_off))
                for i in 3..args.len():
                    extra.push(args[i])
            _ ->
                by_int = true
                desc = val::int_of(how) < (0 as i64)
        let mut a = items
        let n = a.len()
        let mut width = 1
        while width < n:
            let mut out: List<val::Value> = List<val::Value>()
            let mut lo = 0
            while lo < n:
                let mid = if lo + width < n: lo + width else: n
                let hi = if lo + 2 * width < n: lo + 2 * width else: n
                let mut i = lo
                let mut j = mid
                while i < mid and j < hi:
                    # take the right element first only if left > right
                    let mut right_first = false
                    if by_int:
                        right_first = self.sort_less(a[j], a[i])
                    else:
                        let mut ca: List<val::Value> = [a[i], a[j]]
                        for k in 0..extra.len():
                            ca.push(extra[k])
                        let r = self.call_value(f, ca)
                        if self.err:
                            return val::Value::Undef
                        right_first = match r:
                            val::Value::Int(x) -> x > (0 as i64)
                            val::Value::Real(x) -> x > (0.0 as f64)
                            _ -> false
                    if right_first:
                        out.push(a[j])
                        j += 1
                    else:
                        out.push(a[i])
                        i += 1
                while i < mid:
                    out.push(a[i])
                    i += 1
                while j < hi:
                    out.push(a[j])
                    j += 1
                lo = hi
            a = out
            width = width * 2
        if desc:
            let mut r: List<val::Value> = List<val::Value>()
            let mut i = a.len() - 1
            while i >= 0:
                r.push(a[i])
                i -= 1
            a = r
        self.new_arr(a)

fn change_case(s: str, upper: bool) -> str:
    let b = bytes_from_str(s)
    let mut o: Bytes = Bytes()
    for i in 0..b.len():
        let c = b[i] as i32
        if upper and c >= 97 and c <= 122:
            o.push((c - 32) as u8)
        elif !upper and c >= 65 and c <= 90:
            o.push((c + 32) as u8)
        else:
            o.push(b[i])
    str_from_bytes(o)

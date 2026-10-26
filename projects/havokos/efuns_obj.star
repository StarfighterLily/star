# Object-model efuns -- todo.md HavokOS M5, the "Objects", "Living / users",
# "Privileges", "Shadows", "Commands", "Messages", "call_out / heart_beat"
# and system parts of `havok/efuns.pike` (efun_table.star codes 200-299),
# plus the case runner's driver hooks (900-999). The mechanisms are
# `objects.star`'s; this file is argument handling and result shapes.
#
# Optional object arguments follow FluffOS (and the reference): only an
# *omitted* argument means this_object(). A 0 or undefined that was passed
# -- an uninitialised variable, a missed mapping lookup -- is no object,
# and the efun gives its "no object" result.
#
# users(), interactive() and shout() see the connections of M6
# (`net.star`); the other efuns of connections (exec, input_to, snoop,
# query_ip_*, the telnet protocols) are `efuns_net.star`'s.

import "value.star" as val
import "vm.star" as vm
import "efun_table.star" as et
import "program.star" as pg
import "objects.star" as objm
import "gc.star" as gc

impl vm::Vm:
    # args[i] as an object handle; an omitted argument is `self_ob`
    fn obj_arg(self, args: List<val::Value>, i: i32, self_ob: i32) -> i32:
        if args.len() <= i:
            return self_ob
        self.obj_of(args[i])

    fn str_arg(self, args: List<val::Value>, i: i32) -> str:
        if i < args.len():
            match args[i]:
                val::Value::Str(s) ->
                    return s
                _ ->
                    return ""
        ""

    fn is_str(self, v: val::Value) -> bool:
        match v:
            val::Value::Str(s) -> true
            _ -> false

    fn objs_value(mut self, l: List<i32>) -> val::Value:
        let mut out: List<val::Value> = List<val::Value>()
        for i in 0..l.len():
            out.push(self.obj_value(l[i]))
        self.new_arr(out)

    fn strs_value(mut self, l: List<str>) -> val::Value:
        let mut out: List<val::Value> = List<val::Value>()
        for i in 0..l.len():
            out.push(val::Value::Str(l[i]))
        self.new_arr(out)

    fn base_of_name(self, n: str) -> str:
        let mut s = n
        if str_ends_with(s, ".c"):
            s = vm::substr(s, 0, len(s) - 2)
        let h = str_index_of(s, "#")
        if h >= 0:
            s = vm::substr(s, 0, h)
        s

    # present()'s id() match: call_other(o, "id", str), errors ignored
    fn id_match(mut self, o: i32, s: str) -> bool:
        let r = self.call_other_value(-1, self.obj_value(o), val::Value::Str("id"), [val::Value::Str(s)])
        if self.err:
            self.clear_err()
            return false
        self.truthy(r)

    fn present_in(mut self, s: str, num: i64, inv: List<i32>) -> i32:
        let mut count = 0 as i64
        for i in 0..inv.len():
            let o = inv[i]
            if !self.alive(o):
                continue
            if self.id_match(o, s):
                count = count + (1 as i64)
                if count == num:
                    return o
        -1

    # present(str|ob[, env]). "name N" asks for the Nth match, split the way
    # the reference's Pike sscanf("%s %d") splits it: the name is the first
    # word, so "red sword 2" is looked up whole.
    fn efun_present(mut self, args: List<val::Value>, self_ob: i32) -> val::Value:
        let what = self.arg(args, 0)
        let env = if args.len() > 1: self.obj_of(args[1]) else: -1
        let wo = self.obj_of(what)
        if wo >= 0:
            let e = self.objs[wo].env
            if env >= 0:
                return if e == env: what else: val::Value::Int(0 as i64)
            let myenv = if self.alive(self_ob): self.objs[self_ob].env else: -1
            if e == self_ob or (myenv >= 0 and e == myenv):
                return what
            return val::Value::Int(0 as i64)
        if !self.is_str(what):
            return val::Value::Int(0 as i64)
        let mut s = self.str_arg(args, 0)
        let mut num = 1 as i64
        let r = self.lpc_sscanf(what, val::Value::Str("%s %d"), 2)
        let ri = self.arr_items(r)
        if ri.len() == 3 and val::int_of(ri[0]) == (2 as i64) and val::int_of(ri[2]) > (0 as i64):
            s = self.to_str(ri[1])
            num = val::int_of(ri[2])
        if env >= 0:
            return self.obj_value(self.present_in(s, num, self.live_inventory(env)))
        if !self.alive(self_ob):
            return val::Value::Int(0 as i64)
        let mine = self.present_in(s, num, self.live_inventory(self_ob))
        if self.err:
            return val::Value::Undef
        if mine >= 0:
            return self.obj_value(mine)
        let e = self.objs[self_ob].env
        if self.alive(e):
            return self.obj_value(self.present_in(s, num, self.live_inventory(e)))
        val::Value::Int(0 as i64)

    fn deep_inv(mut self, o: i32) -> List<i32>:
        let mut out: List<i32> = List<i32>()
        let inv = self.live_inventory(o)
        for i in 0..inv.len():
            out.push(inv[i])
            let sub = self.deep_inv(inv[i])
            for j in 0..sub.len():
                out.push(sub[j])
        out

    # origin(): "local" when the calling function was called by another
    # function of the same object, else "call_other", or "driver" at the top
    # of an evaluation (efuns.pike origin(): a frame entered by a call_other
    # remembers the function it was entered by).
    fn efun_origin(self) -> val::Value:
        let n = self.frames.len()
        if n == 0:
            return val::Value::Str("driver")
        let fr = self.frames[n - 1]
        let top = self.ostack.len() - 1
        if top >= 0 and self.ostack[top] == fr.obj and self.ostack_fn[top] != "":
            let name = self.progs[fr.prog].fns[fr.fnidx].name
            return val::Value::Str(if name != self.ostack_fn[top]: "local" else: "call_other")
        if n > 1 and !fr.driver and self.frames[n - 2].obj == fr.obj:
            return val::Value::Str("local")
        val::Value::Str(if self.ostack.len() > 1: "call_other" else: "driver")

    # call_stack(flag): 0 program files, 1 objects, 2 function names, 3
    # origins, innermost first, for the LPC frames of live objects.
    fn efun_call_stack(mut self, flag: i64) -> val::Value:
        let mut out: List<val::Value> = List<val::Value>()
        let mut i = self.frames.len() - 1
        while i >= 0:
            let fr = self.frames[i]
            if self.alive(fr.obj):
                if flag == (0 as i64):
                    out.push(val::Value::Str(concat(self.progs[fr.prog].path, ".c")))
                elif flag == (1 as i64):
                    out.push(self.obj_value(fr.obj))
                elif flag == (2 as i64):
                    out.push(val::Value::Str(self.progs[fr.prog].fns[fr.fnidx].name))
                else:
                    out.push(val::Value::Str("call_other"))
            i -= 1
        self.new_arr(out)

    # bind(f, ob): the same function pointer, owned by ob. An efun, simul_efun
    # or by-name pointer changes owner; a plain local function or closure
    # keeps running in its object, with ob as the owner the driver sees (it
    # is pushed as current object around the call, as in the reference).
    fn efun_bind(mut self, f: val::Value, ov: val::Value) -> val::Value:
        let o = self.obj_of(ov)
        match f:
            val::Value::Fn(h) ->
                let mut s = self.fns[h]
                if self.fn_owner(f) == o:
                    return f
                if s.kind == val::FK_DIRECT or s.kind == val::FK_CLOSURE:
                    s.bound_owner = o
                    s.bound_gen = if o >= 0: self.objs[o].gen else: 0
                else:
                    s.owner = o
                    s.owner_gen = if o >= 0: self.objs[o].gen else: 0
                s.lpcfn = true
                return self.new_fn(s)
            _ ->
                self.fail("Bad argument 1 to bind()\n")
                return val::Value::Undef

    # replaceable(ob, fnames): 1 when ob's program defines no functions of
    # its own besides fnames (default ({ "create" })); a closure makes it 0.
    fn efun_replaceable(mut self, args: List<val::Value>) -> val::Value:
        let o = self.obj_of(self.arg(args, 0))
        if o < 0:
            self.fail("Bad argument 1 to replaceable()\n")
            return val::Value::Undef
        let mut names: List<val::Value> = [val::Value::Str("create")]
        if args.len() >= 2:
            match args[1]:
                val::Value::Arr(h) ->
                    names = self.arrs[h].items
                _ ->
                    self.fail("Bad argument 2 to replaceable()\n")
                    return val::Value::Undef
        let fns = self.progs[self.objs[o].prog].fns
        for i in 0..fns.len():
            let n = fns[i].name
            if n == "(closure)":
                return val::Value::Int(0 as i64)
            if n == "__INIT" or fns[i].code.len() == 0:
                continue
            if !self.arr_has(names, val::Value::Str(n)):
                return val::Value::Int(0 as i64)
        val::Value::Int(1 as i64)

    fn efun_obj(mut self, code: i32, name: str, args: List<val::Value>, self_ob: i32) -> val::Value:
        let zero = val::Value::Int(0 as i64)
        if code == et::E_DESTRUCT:
            let o = self.obj_arg(args, 0, self_ob)
            if o > 0:
                self.destruct_object(self_ob, o)
            return zero
        if code == et::E_ENVIRONMENT:
            let o = self.obj_arg(args, 0, self_ob)
            if !self.alive(o):
                return zero
            let e = self.objs[o].env
            return if self.alive(e): self.obj_value(e) else: zero
        if code == et::E_ALL_INVENTORY:
            let o = self.obj_arg(args, 0, self_ob)
            return self.objs_value(self.live_inventory(o))
        if code == et::E_DEEP_INVENTORY:
            if args.len() > 0:
                match args[0]:
                    val::Value::Arr(h) ->
                        let items = self.arrs[h].items
                        let mut out: List<i32> = List<i32>()
                        for i in 0..items.len():
                            let x = self.obj_of(items[i])
                            if x >= 0:
                                out.push(x)
                                let sub = self.deep_inv(x)
                                for j in 0..sub.len():
                                    out.push(sub[j])
                        return self.objs_value(out)
                    _ -> 0
            return self.objs_value(self.deep_inv(self.obj_arg(args, 0, self_ob)))
        if code == et::E_FIRST_INVENTORY:
            let mut o = self.obj_arg(args, 0, self_ob)
            if args.len() > 0 and self.is_str(args[0]):
                o = self.obj_of(self.load_object(self.str_arg(args, 0), self_ob))
                if self.err:
                    return val::Value::Undef
            let inv = self.live_inventory(o)
            return if inv.len() > 0: self.obj_value(inv[0]) else: zero
        if code == et::E_NEXT_INVENTORY:
            let o = self.obj_arg(args, 0, self_ob)
            if !self.alive(o) or !self.alive(self.objs[o].env):
                return zero
            let inv = self.live_inventory(self.objs[o].env)
            for i in 0..inv.len():
                if inv[i] == o:
                    return if i + 1 < inv.len(): self.obj_value(inv[i + 1]) else: zero
            return zero
        if code == et::E_PRESENT:
            return self.efun_present(args, self_ob)
        if code == et::E_MOVE_OBJECT:
            self.move_object(self_ob, self.arg(args, 0))
            return zero
        if code == et::E_BASE_NAME:
            let mut n = ""
            if args.len() > 0 and self.is_str(args[0]):
                n = self.str_arg(args, 0)
            else:
                let o = self.obj_arg(args, 0, self_ob)
                if !self.alive(o):
                    return zero
                n = self.objs[o].name
            return val::Value::Str(self.base_of_name(n))
        if code == et::E_CLONEP or code == et::E_VIRTUALP:
            let o = self.obj_arg(args, 0, self_ob)
            if !self.alive(o):
                return zero
            let f = if code == et::E_CLONEP: self.objs[o].clone else: self.objs[o].is_virtual
            return self.bool_v(f)
        if code == et::E_CHILDREN:
            let p = self.normalize(self.str_arg(args, 0), "")
            let mut out: List<i32> = List<i32>()
            for o in 1..self.objs.len():
                if self.objs[o].alive and self.base_of_name(self.objs[o].name) == p:
                    out.push(o)
            return self.objs_value(out)
        if code == et::E_INHERITORS:
            if args.len() < 1 or !self.is_str(args[0]):
                return self.new_arr(List<val::Value>())
            let p = self.normalize(self.str_arg(args, 0), "")
            let mut out: List<i32> = List<i32>()
            for o in 1..self.objs.len():
                if self.objs[o].alive and self.deep_inherits_p(self.objs[o].prog, p):
                    out.push(o)
            return self.objs_value(out)
        if code == et::E_OBJECTS:
            let f = self.arg(args, 0)
            let mut out: List<val::Value> = List<val::Value>()
            for o in 1..self.objs.len():
                if self.objs[o].alive:
                    let ov = self.obj_value(o)
                    if self.is_callable(f):
                        let r = self.call_value(f, [ov])
                        if self.err:
                            return val::Value::Undef
                        if !self.truthy(r):
                            continue
                    out.push(ov)
            return self.new_arr(out)
        if code == et::E_INHERITS:
            let o = self.obj_arg(args, 1, self_ob)
            if !self.alive(o) or !self.is_str(self.arg(args, 0)):
                return zero
            let p = self.normalize(self.str_arg(args, 0), "")
            let pid = self.objs[o].prog
            if !self.deep_inherits_p(pid, p):
                return zero
            let inh = self.progs[pid].inherits
            for i in 0..inh.len():
                if inh[i].path == p:
                    return val::Value::Int(1 as i64)
            return val::Value::Int(2 as i64)
        if code == et::E_INHERIT_LIST:
            let o = self.obj_arg(args, 0, self_ob)
            let mut out: List<str> = List<str>()
            if self.alive(o):
                let inh = self.progs[self.objs[o].prog].inherits
                for i in 0..inh.len():
                    out.push(concat(inh[i].path, ".c"))
            return self.strs_value(out)
        if code == et::E_DEEP_INHERIT_LIST:
            let o = self.obj_arg(args, 0, self_ob)
            let mut out: List<str> = List<str>()
            if self.alive(o):
                let d = self.deep_inherit_paths(self.objs[o].prog)
                for i in 0..d.len():
                    out.push(concat(d[i], ".c"))
            return self.strs_value(out)
        if code == et::E_FUNCTION_EXISTS:
            let o = self.obj_arg(args, 1, self_ob)
            if !self.alive(o) or !self.is_str(self.arg(args, 0)):
                return zero
            let fname = self.str_arg(args, 0)
            let e = if self.truthy(self.arg(args, 2)): self.any_fn(o, fname) else: self.public_fn(o, fname)
            if e.prog < 0:
                return zero
            return val::Value::Str(self.progs[e.prog].path)
        if code == et::E_FUNCTIONS or code == et::E_VARIABLES:
            let o = self.obj_of(self.arg(args, 0))
            if !self.alive(o):
                return self.new_arr(List<val::Value>())
            let p = self.progs[self.objs[o].prog]
            let mut out: List<str> = List<str>()
            let mut seen: Set<str> = Set<str>()
            let first = if code == et::E_FUNCTIONS: p.all_func_names else: p.all_var_names
            for i in 0..first.len():
                if !seen.contains(first[i]):
                    seen.insert(first[i])
                    out.push(first[i])
            if code == et::E_FUNCTIONS:
                for i in 0..p.fns.len():
                    let n = p.fns[i].name
                    if n != "__INIT" and n != "(closure)" and !seen.contains(n):
                        seen.insert(n)
                        out.push(n)
            else:
                for i in 0..p.var_names.len():
                    if !seen.contains(p.var_names[i]):
                        seen.insert(p.var_names[i])
                        out.push(p.var_names[i])
            return self.strs_value(out)
        if code == et::E_FETCH_VARIABLE or code == et::E_STORE_VARIABLE:
            let oi = if code == et::E_FETCH_VARIABLE: 1 else: 2
            let mut o = self.obj_of(self.arg(args, oi))
            if o < 0:
                o = self_ob
            if !self.alive(o):
                return zero
            let vname = self.str_arg(args, 0)
            if let Option::Some(k) = self.progs[self.objs[o].prog].all_vars.get(vname):
                if code == et::E_FETCH_VARIABLE:
                    return self.objs[o].vars[k]
                self.objs[o].vars[k] = self.arg(args, 1)
            return zero
        if code == et::E_QUERY_PRIVS:
            let o = self.obj_arg(args, 0, self_ob)
            if !self.alive(o):
                return zero
            return self.objs[o].privs
        if code == et::E_SET_PRIVS:
            let o = self.obj_of(self.arg(args, 0))
            if !self.alive(o):
                return zero
            if self.alive(self.master_ob):
                self.master_apply("valid_override", [val::Value::Str(self.obj_name(self_ob)), val::Value::Str("set_privs")], self_ob)
                if self.err:
                    return val::Value::Undef
            self.objs[o].privs = if self.is_str(self.arg(args, 1)): self.arg(args, 1) else: zero
            return zero
        if code == et::E_SHADOW:
            let o = self.obj_of(self.arg(args, 0))
            if args.len() < 2 or self.truthy(args[1]):
                return self.obj_value(self.shadow(self_ob, o))
            if !self.alive(o):
                return zero
            return self.obj_value(self.objs[o].shadowed_by)
        if code == et::E_QUERY_SHADOWING:
            let o = self.obj_of(self.arg(args, 0))
            if !self.alive(o):
                return zero
            return self.obj_value(self.objs[o].shadowing)
        if code == et::E_REMOVE_SHADOW:
            let o = self.obj_arg(args, 0, self_ob)
            if !self.alive(o):
                return zero
            self.remove_shadow(o)
            return val::Value::Int(1 as i64)
        if code == et::E_ORIGIN:
            return self.efun_origin()
        if code == et::E_CALL_STACK:
            return self.efun_call_stack(val::int_of(self.arg(args, 0)))
        if code == et::E_ALL_PREVIOUS_OBJECTS:
            return self.previous(self_ob, -1)
        if code == et::E_THIS_PLAYER or code == et::E_THIS_INTERACTIVE:
            let use_i = code == et::E_THIS_INTERACTIVE or self.truthy(self.arg(args, 0))
            let p = if use_i: self.cur_interactive else: self.cur_player
            if p == vm::DESTRUCTED_OB or self.alive(p):
                return self.obj_value(p)
            return zero
        if code == et::E_BIND:
            return self.efun_bind(self.arg(args, 0), self.arg(args, 1))
        if code == et::E_FUNCTION_OWNER:
            return self.obj_value(self.fn_owner(self.arg(args, 0)))
        if code == et::E_REPLACE_PROGRAM:
            if !self.is_str(self.arg(args, 0)):
                self.fail("Bad argument 1 to replace_program()\n")
                return val::Value::Undef
            self.request_replace(self_ob, self.str_arg(args, 0))
            return zero
        if code == et::E_QUERY_REPLACED_PROGRAM:
            let o = self.obj_arg(args, 0, self_ob)
            if !self.alive(o) or self.objs[o].replaced == "":
                return zero
            return val::Value::Str(concat(self.objs[o].replaced, ".c"))
        if code == et::E_REPLACEABLE:
            return self.efun_replaceable(args)
        if code == et::E_RELOAD_OBJECT or code == et::E_SET_AUTHOR or code == et::E_FLUSH_MESSAGES:
            return zero
        if code == et::E_REFS:
            return val::Value::Int(1 as i64)
        if code == et::E_AUTHOR_STATS:
            return val::Value::Map(self.new_map())
        if code == et::E_GET_GARBAGE:
            return self.objs_value(self.garbage_clones())
        if code == et::E_RECLAIM_OBJECTS:
            # a collection only runs between evaluations (gc.star); ask for one
            self.gc_requested = true
            return zero
        # --- livings and commands
        if code == et::E_ENABLE_COMMANDS:
            if self.alive(self_ob):
                self.objs[self_ob].living = true
                self.cur_player = self_ob
            return zero
        if code == et::E_DISABLE_COMMANDS:
            if self.alive(self_ob):
                self.objs[self_ob].living = false
                self.objs[self_ob].actions = List<vm::Action>()
            return zero
        if code == et::E_LIVING:
            let o = self.obj_arg(args, 0, self_ob)
            return self.bool_v(self.alive(o) and self.objs[o].living)
        if code == et::E_LIVINGS or code == et::E_NAMED_LIVINGS:
            let mut out: List<i32> = List<i32>()
            for o in 1..self.objs.len():
                if self.objs[o].alive and self.objs[o].living and (code == et::E_LIVINGS or self.objs[o].living_name != ""):
                    out.push(o)
            return self.objs_value(out)
        if code == et::E_SET_LIVING_NAME:
            if !self.is_str(self.arg(args, 0)):
                self.fail("Bad argument 1 to set_living_name()\n")
                return val::Value::Undef
            self.set_living_name(self_ob, self.str_arg(args, 0))
            return zero
        if code == et::E_FIND_LIVING or code == et::E_FIND_PLAYER:
            if !self.is_str(self.arg(args, 0)):
                return zero
            return self.obj_value(self.find_living(self.str_arg(args, 0), code == et::E_FIND_PLAYER))
        if code == et::E_ADD_ACTION:
            let tp = self.cur_player
            if !self.alive(tp):
                return zero
            let mut verbs: List<val::Value> = List<val::Value>()
            match self.arg(args, 1):
                val::Value::Arr(h) ->
                    verbs = self.arrs[h].items
                _ ->
                    verbs = [self.arg(args, 1)]
            let flag = val::int_of(self.arg(args, 2)) as i32
            for i in 0..verbs.len():
                # newest actions take precedence (FluffOS adds at the front)
                let mut acts: List<vm::Action> = [vm::Action(owner = self.obj_value(self_ob), verb = self.to_str(verbs[i]), fun = self.arg(args, 0), flag = flag)]
                let old = self.objs[tp].actions
                for j in 0..old.len():
                    acts.push(old[j])
                self.objs[tp].actions = acts
            return zero
        if code == et::E_REMOVE_ACTION:
            let tp = self.cur_player
            if !self.alive(tp):
                return zero
            let fun = self.arg(args, 0)
            let verb = self.str_arg(args, 1)
            let me = self.obj_value(self_ob)
            let old = self.objs[tp].actions
            let mut keep: List<vm::Action> = List<vm::Action>()
            for i in 0..old.len():
                let s = old[i]
                let same_fun = self.lpc_eq(s.fun, fun) or !self.is_str(s.fun)
                if !(self.lpc_eq(s.owner, me) and !self.dead_obj(s.owner) and s.verb == verb and same_fun):
                    keep.push(s)
            self.objs[tp].actions = keep
            return self.bool_v(keep.len() != old.len())
        if code == et::E_COMMANDS:
            let mut out: List<val::Value> = List<val::Value>()
            if self.alive(self_ob):
                let acts = self.objs[self_ob].actions
                for i in 0..acts.len():
                    let s = acts[i]
                    let fname = if self.is_str(s.fun): s.fun else: val::Value::Str("<function>")
                    let row = self.new_arr([val::Value::Str(s.verb), val::Value::Int(s.flag as i64), s.owner, fname])
                    out.push(row)
            return self.new_arr(out)
        if code == et::E_QUERY_VERB:
            return self.cur_verb
        if code == et::E_NOTIFY_FAIL:
            if self.alive(self.cur_player):
                self.objs[self.cur_player].notify_fail = self.arg(args, 0)
            return zero
        if code == et::E_QUERY_NOTIFY_FAIL:
            if self.alive(self.cur_player):
                return self.objs[self.cur_player].notify_fail
            return zero
        if code == et::E_COMMAND:
            let mut w = self_ob
            if args.len() > 1 and self.obj_of(args[1]) >= 0:
                w = self.obj_of(args[1])
            let t0 = clock_ms()
            let ok = self.do_command(w, self.str_arg(args, 0))
            if self.err:
                return val::Value::Undef
            if !ok:
                return zero
            # elapsed microseconds, at least 1
            let us = (clock_ms() - t0) * (1000 as i64)
            return val::Value::Int(if us > (0 as i64): us else: 1 as i64)
        if code == et::E_SET_HIDE:
            if self.alive(self_ob):
                self.objs[self_ob].hidden = self.truthy(self.arg(args, 0))
            return zero
        # --- messages
        if code == et::E_TELL_OBJECT:
            self.tell_object(self.obj_of(self.arg(args, 0)), self.arg(args, 1))
            return zero
        if code == et::E_RECEIVE:
            if self.alive(self_ob):
                let s = self.to_text(self.arg(args, 0))
                self.tell_user(self_ob, s)
            return zero
        if code == et::E_SAY:
            let mut avoid: List<val::Value> = List<val::Value>()
            match self.arg(args, 1):
                val::Value::Arr(h) ->
                    avoid = self.arrs[h].items
                val::Value::Obj(h, g) ->
                    avoid = [self.arg(args, 1)]
                _ -> 0
            let s = self.to_text(self.arg(args, 0))
            self.say_to(self_ob, s, avoid)
            return zero
        if code == et::E_TELL_ROOM:
            let mut room = self.obj_of(self.arg(args, 0))
            if self.is_str(self.arg(args, 0)):
                room = self.find_object(self.str_arg(args, 0))
                if room < 0:
                    room = self.obj_of(self.load_object(self.str_arg(args, 0), self_ob))
                    if self.err:
                        return val::Value::Undef
            let mut avoid: List<val::Value> = List<val::Value>()
            match self.arg(args, 2):
                val::Value::Arr(h) ->
                    avoid = self.arrs[h].items
                val::Value::Obj(h, g) ->
                    avoid = [self.arg(args, 2)]
                _ -> 0
            self.tell_room(room, self.arg(args, 1), avoid)
            return zero
        if code == et::E_SHOUT:
            # to every user but this_player()
            let s = val::Value::Str(self.to_text(self.arg(args, 0)))
            let us = self.users_list()
            for i in 0..us.len():
                if us[i] != self.cur_player:
                    self.tell_object(us[i], s)
                    if self.err:
                        return val::Value::Undef
            return zero
        if code == et::E_MESSAGE:
            let mut scope: List<val::Value> = List<val::Value>()
            match self.arg(args, 2):
                val::Value::Arr(h) ->
                    scope = self.arrs[h].items
                _ ->
                    scope = [self.arg(args, 2)]
            let mut exclude: List<val::Value> = List<val::Value>()
            match self.arg(args, 3):
                val::Value::Arr(h) ->
                    exclude = self.arrs[h].items
                val::Value::Obj(h, g) ->
                    exclude = [self.arg(args, 3)]
                _ -> 0
            self.deliver_message(self.arg(args, 0), self.arg(args, 1), scope, exclude, true)
            return zero
        # --- call_outs and heart beats
        if code == et::E_CALL_OUT:
            let f = self.arg(args, 0)
            if !self.is_str(f) and !self.is_callable(f):
                self.fail("Bad argument 1 to call_out()\n")
                return val::Value::Undef
            let mut rest: List<val::Value> = List<val::Value>()
            for i in 2..args.len():
                rest.push(args[i])
            return val::Value::Int(self.add_call_out(self_ob, f, self.arg(args, 1), rest) as i64)
        if code == et::E_REMOVE_CALL_OUT:
            if args.len() < 1:
                self.remove_call_outs_for(self_ob)
                return zero
            let k = self.find_call_out_index(self_ob, args[0])
            if k < 0:
                return val::Value::Int((0 - 1) as i64)
            let c = self.drop_call_out_at(k)
            return val::Value::Int(self.call_out_left(c))
        if code == et::E_FIND_CALL_OUT:
            let k = self.find_call_out_index(self_ob, self.arg(args, 0))
            if k < 0:
                return val::Value::Int((0 - 1) as i64)
            return val::Value::Int(self.call_out_left(self.callouts[k]))
        if code == et::E_CALL_OUT_INFO:
            let mut out: List<val::Value> = List<val::Value>()
            for i in 0..self.callouts.len():
                let c = self.callouts[i]
                if self.obj_of(c.owner) < 0:
                    continue
                let fname = if self.is_str(c.fun): c.fun else: val::Value::Str("<function>")
                let row = self.new_arr([c.owner, fname, val::Value::Int(self.call_out_left(c))])
                out.push(row)
            return self.new_arr(out)
        if code == et::E_SET_HEART_BEAT:
            return val::Value::Int(self.set_heart_beat(self_ob, val::int_of(self.arg(args, 0)) as i32) as i64)
        if code == et::E_QUERY_HEART_BEAT:
            let o = self.obj_arg(args, 0, self_ob)
            if !self.alive(o):
                return zero
            return val::Value::Int(self.objs[o].hb as i64)
        if code == et::E_HEART_BEATS:
            return self.objs_value(self.hb_objects())
        if code == et::E_SET_RESET:
            let o = self.obj_of(self.arg(args, 0))
            if !self.alive(o):
                self.fail("Bad argument 1 to set_reset()\n")
                return val::Value::Undef
            if args.len() >= 2 and !self.is_int(args[1]):
                self.fail("Bad argument 2 to set_reset()\n")
                return val::Value::Undef
            self.set_reset(o, val::int_of(self.arg(args, 1)), args.len() >= 2)
            return zero
        # --- the evaluation limit (wall-clock microseconds per evaluation)
        if code == et::E_EVAL_COST:
            return val::Value::Int(self.eval_remaining())
        if code == et::E_MAX_EVAL_COST:
            return val::Value::Int(self.max_cost)
        if code == et::E_RESET_EVAL_COST:
            self.reset_eval()
            return val::Value::Int(self.max_cost)
        if code == et::E_SET_EVAL_LIMIT:
            # 0 resets, -1 gives what is left, 1 the maximum, else a new maximum
            let n = self.arg(args, 0)
            if !self.is_int(n):
                self.fail("Bad argument 1 to set_eval_limit()\n")
                return val::Value::Undef
            let x = val::int_of(n)
            if x == (0 as i64):
                self.reset_eval()
                return val::Value::Int(self.max_cost)
            if x == (0 as i64) - (1 as i64):
                return val::Value::Int(self.eval_remaining())
            if x == (1 as i64):
                return val::Value::Int(self.max_cost)
            self.max_cost = x
            return n
        # --- system
        if code == et::E_SHUTDOWN:
            self.log_msg(f"Shutdown requested by {self.obj_name(self_ob)}")
            self.shutdown_requested = true
            self.shutdown_code = val::int_of(self.arg(args, 0)) as i32
            return zero
        if code == et::E_MUD_STATUS:
            let mut n = 0
            let mut hb = 0
            for o in 1..self.objs.len():
                if self.objs[o].alive:
                    n += 1
                    if self.objs[o].hb != 0:
                        hb += 1
            return val::Value::Str(f"HavokOS: {n} objects, {self.callouts.len()} call_outs, {hb} heart beats\n")
        if code == et::E_MEMORY_INFO:
            # per object there is no cheap measure (as in the reference, which
            # gives a nominal 1024); the whole driver: the process's resident
            # bytes (process_memory(), P1 #6; it was heap slots in use times
            # 64 until then)
            if args.len() >= 1:
                return val::Value::Int(1024 as i64)
            let m = process_memory()
            if m >= (0 as i64):
                return val::Value::Int(m)
            return val::Value::Int((self.heap_live() as i64) * (64 as i64))
        if code == et::E_DEBUG_INFO:
            return val::Value::Str("")
        if code == et::E_DEBUG_MESSAGE:
            self.log_msg(self.to_str(self.arg(args, 0)))
            return zero
        if code == et::E_QUERY_LOAD_AVERAGE:
            return val::Value::Str("0.00 cmds/s, 0.00 comp lines/s")
        if code == et::E_USERS:
            return self.objs_value(self.users_list())
        if code == et::E_INTERACTIVE:
            return self.bool_v(self.is_interactive(self.obj_arg(args, 0, self_ob)))
        if code == et::E_USERP:
            let o = self.obj_of(self.arg(args, 0))
            return self.bool_v(self.alive(o) and self.objs[o].once_interactive)
        if code == et::E_RUSAGE:
            let m = self.new_map()
            self.map_set(m, val::Value::Str("utime"), val::Value::Int((clock_ms() - self.clock_epoch) as i64))
            self.map_set(m, val::Value::Str("stime"), zero)
            self.map_set(m, val::Value::Str("maxrss"), zero)
            return val::Value::Map(m)
        if code == et::E_OPCPROF:
            return self.efun_opcprof(args, self_ob)
        if code == et::E_DUMPALLOBJ:
            return self.efun_dumpallobj(args, self_ob)
        if code >= 900:
            return self.efun_test(code, args, self_ob)
        self.fail(f"Efun {name}() is not implemented by this driver.\n")
        val::Value::Undef

    # opcprof([file]): efun call counts to <file>.efun (default /OPCPROF),
    # one "name<padding>: count" line per efun, and an empty <file>.eoper.
    # The counts are the calls made while `havok profiling` was on (ext.star,
    # P1 #6), so without it every count is 0, as in the reference, but the
    # list is right: Dead Souls's master reads it for efuns() and
    # efun_exists(). It lists the reference's efuns, the names this driver
    # compiles as efun calls.
    fn efun_opcprof(mut self, args: List<val::Value>, self_ob: i32) -> val::Value:
        let mut file = "/OPCPROF"
        if args.len() >= 1:
            if !self.is_str(args[0]):
                self.fail("Bad argument 1 to opcprof()\n")
                return val::Value::Undef
            file = self.str_arg(args, 0)
        let names = self.sorted_ref_efuns()
        let mut b: Bytes = Bytes()
        for i in 0..names.len():
            let mut n = 0 as i64
            if let Option::Some(x) = self.efun_counts.get(names[i]):
                n = x
            let line = bytes_from_str(self.lpc_sprintf("%-30s: %10d\n", [val::Value::Str(names[i]), val::Value::Int(n)]))
            for j in 0..line.len():
                b.push(line[j])
        let one = val::Value::Int(1 as i64)
        self.efun(et::E_WRITE_FILE, "write_file", [val::Value::Str(concat(file, ".efun")), val::Value::Str(str_from_bytes(b)), one], self_ob)
        if self.err:
            return val::Value::Undef
        self.efun(et::E_WRITE_FILE, "write_file", [val::Value::Str(concat(file, ".eoper")), val::Value::Str(""), one], self_ob)
        val::Value::Int(0 as i64)

    fn sorted_ref_efuns(self) -> List<str>:
        let r = self.ref_efun_list
        let mut a = r
        let mut i = 1
        while i < a.len():
            let x = a[i]
            let mut j = i - 1
            while j >= 0 and vm::str_cmp(x, a[j]) < 0:
                a[j + 1] = a[j]
                j -= 1
            a[j + 1] = x
            i += 1
        a

    # dumpallobj([file]): one line per object (default /OBJ_DUMP): name,
    # size, reference count, HB when it has a heart beat, its environment
    # or --. Sizes and counts are nominal here (no per-object measure).
    fn efun_dumpallobj(mut self, args: List<val::Value>, self_ob: i32) -> val::Value:
        let mut file = "/OBJ_DUMP"
        if args.len() >= 1:
            if !self.is_str(args[0]):
                self.fail("Bad argument 1 to dumpallobj()\n")
                return val::Value::Undef
            file = self.str_arg(args, 0)
        let mut lines: List<str> = List<str>()
        for o in 1..self.objs.len():
            let s = self.objs[o]
            if !s.alive:
                continue
            let env = if self.alive(s.env): self.objs[s.env].name else: "--"
            let hb = if s.hb != 0: "HB" else: "--"
            lines.push(self.lpc_sprintf("%-40s %8d ref %3d %s %s\n", [val::Value::Str(s.name), val::Value::Int((s.vars.len() * 16) as i64), val::Value::Int(1 as i64), val::Value::Str(hb), val::Value::Str(env)]))
        let mut a = lines
        let mut i = 1
        while i < a.len():
            let x = a[i]
            let mut j = i - 1
            while j >= 0 and vm::str_cmp(x, a[j]) < 0:
                a[j + 1] = a[j]
                j -= 1
            a[j + 1] = x
            i += 1
        self.efun(et::E_WRITE_FILE, "write_file", [val::Value::Str(file), val::Value::Str(str_join(a, "")), val::Value::Int(1 as i64)], self_ob)
        val::Value::Int(0 as i64)

    # The case runner's driver hooks (efun_table.star test_efun_codes()).
    fn efun_test(mut self, code: i32, args: List<val::Value>, self_ob: i32) -> val::Value:
        let zero = val::Value::Int(0 as i64)
        if code >= et::E_TEST_WATCH_POLL:
            return self.efun_ext_test(code, args, self_ob)
        if code >= et::E_TEST_SOCK_PUMP:
            return self.efun_sock_test(code, args, self_ob)
        if code >= et::E_TEST_TEL_OPEN:
            return self.efun_tel_test(code, args, self_ob)
        if code == et::E_TEST_HB:
            let n = val::int_of(self.arg(args, 0))
            let mut k = 0 as i64
            while k < n:
                self.heart_beat_tick()
                k = k + (1 as i64)
            return zero
        if code == et::E_TEST_HB_ROUND:
            for i in 0..self.hb_slots.len():
                self.heart_beat_slot_tick()
            # each slot's size, so a case can check they are balanced
            let mut sizes: List<val::Value> = List<val::Value>()
            for i in 0..self.hb_slots.len():
                sizes.push(val::Value::Int(self.hb_slots[i].len() as i64))
            return self.new_arr(sizes)
        if code == et::E_TEST_CALLOUTS:
            return val::Value::Int(self.run_all_call_outs() as i64)
        if code == et::E_TEST_RESET_CFG:
            self.reset_interval = val::int_of(self.arg(args, 0))
            self.cleanup_interval = val::int_of(self.arg(args, 1))
            self.lazy_resets = self.truthy(self.arg(args, 2))
            self.now_sec = vm::epoch_now()
            return zero
        if code == et::E_TEST_SET_RESET_TIME or code == et::E_TEST_SET_LAST_USED:
            let o = self.obj_of(self.arg(args, 0))
            if !self.alive(o):
                return zero
            let t = val::int_of(self.arg(args, 1))
            if code == et::E_TEST_SET_RESET_TIME:
                self.objs[o].reset_time = t
            else:
                self.objs[o].last_used = t
            return zero
        if code == et::E_TEST_RESET_TIME:
            let o = self.obj_of(self.arg(args, 0))
            if !self.alive(o):
                return zero
            return val::Value::Int(self.objs[o].reset_time)
        if code == et::E_TEST_NO_CLEAN_UP:
            let o = self.obj_of(self.arg(args, 0))
            if !self.alive(o):
                return zero
            return self.bool_v(self.objs[o].no_clean_up)
        if code == et::E_TEST_SWEEP:
            self.reset_sweep_once()
            return zero
        if code == et::E_TEST_LIMITED:
            # call fn() in this object as a top-level evaluation with a budget
            # of `usec` (the reference test suite's run_limited())
            # (an error, "Too long evaluation" included, passes on to the case)
            self.max_cost = val::int_of(self.arg(args, 1))
            self.begin_eval()
            let r = self.call_other_value(self_ob, self.obj_value(self_ob), self.arg(args, 0), List<val::Value>())
            self.end_eval()
            self.max_cost = 0 as i64
            return r
        if code == et::E_TEST_EVAL_STATE:
            return self.new_arr([val::Value::Int(self.eval_nest as i64), self.bool_v(self.outoftime), self.bool_v(self.eval_deadline != (0 as i64))])
        self.fail("unknown test hook\n")
        val::Value::Undef

    # Make the case runner's driver hooks callable from LPC (never done by a
    # real boot).
    fn add_test_efuns(mut self):
        let t = et::test_efun_codes()
        let names = ["test_hb", "test_hb_round", "test_callouts", "test_reset_cfg", "test_set_reset_time", "test_set_last_used", "test_reset_time", "test_no_clean_up", "test_sweep", "test_limited", "test_eval_state", "test_tel_open", "test_tel_say", "test_tel_drain", "test_tel_hangup", "test_tel_tp", "test_tel_connect", "test_tel_user", "test_sock_pump", "test_config", "test_watch_poll", "test_run_call_out", "test_utime", "test_forget", "test_profiling", "test_watch_state", "test_put", "test_rmtree"]
        for i in 0..names.len():
            if let Option::Some(c) = t.get(names[i]):
                self.efun_codes.insert(names[i], c)
                self.ref_efuns.insert(names[i])
                self.pp.efun_names.insert(names[i])

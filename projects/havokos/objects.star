# The object model -- todo.md HavokOS M5: what `havok/driver.pike` does
# beyond running code. Driver applies and top-level evaluations (with the
# evaluation time limit and the master's error_handler()), destruct
# (including the vital master/simul_efun objects, which reload before they
# go), the environment/inventory tree and init(), livings and living names,
# shadows, add_action() command dispatch, message delivery, call_outs,
# heart beats, reset()/clean_up(), replace_program() and get_garbage().
# The efuns over all this are `efuns_obj.star`.
#
# The reference keeps per-object driver state in an `ObInfo` beside each
# Pike object; here it's the object's own `vm.star` `ObjSlot`. Its
# behaviour is followed function for function (the names match
# driver.pike's), with these differences in mechanism:
#
# - A call made by the driver (an apply, a call_out, a heart beat, init())
#   runs a nested interpreter loop, like an efun calling back into LPC. A
#   top-level evaluation (driver safe()) is a wrapper that reports an
#   error to the master instead of propagating it and restores the stacks.
# - The evaluation limit is ticked on function entry and on loop back
#   edges (vm.star), as the reference's emitter ticks at the top of every
#   function and loop body, and measured with the compiler's `clock_ms()`
#   builtin (`src/codegen/clock.rs`, added for this milestone).
# - Destructed objects stay in their slot with `alive` false, so code that
#   is still running in one goes on until it returns, as in FluffOS and the
#   reference (its pending_destructs). Values referring to a dead object
#   read as 0 (vm.star dead_obj()).
# - Lists here can only push and pop, so taking an element out of the
#   middle (an inventory, a heart beat slot, a pending call_out) rebuilds
#   the list. Inventories and call_out queues are short enough that a
#   linear pass costs less than keeping an index in step.
# - Driver-side references to objects that outlive the object (call_out
#   owners, add_action owners) are object values carrying the slot's
#   generation, so a slot reused after a destruct can't inherit them.
#
# Connections (M6) are `net.star`'s: tell_user() writes to one, an
# interactive object hears messages like a living, and destructing one
# closes its connection.

import "value.star" as val
import "vm.star" as vm
import "program.star" as pg

# the driver's log goes to stdout as it happens, so a log redirected to a
# file must not sit in the C runtime's buffer (boot.star runs for months)
extern "C" fn fflush(f: ptr) -> i32

fn without(items: List<i32>, x: i32) -> List<i32>:
    let mut out: List<i32> = List<i32>()
    for i in 0..items.len():
        if items[i] != x:
            out.push(items[i])
    out

fn has_i32(items: List<i32>, x: i32) -> bool:
    for i in 0..items.len():
        if items[i] == x:
            return true
    false

impl vm::Vm:
    fn log_msg(mut self, s: str):
        if self.keep_log:
            self.log.push(s)
        if self.echo_log:
            println(s)
            fflush(null_ptr())

    fn alive(self, o: i32) -> bool:
        o > 0 and o < self.objs.len() and self.objs[o].alive

    fn obj_name(self, o: i32) -> str:
        if o > 0 and o < self.objs.len():
            return self.objs[o].name
        "?"

    # --- applies ----------------------------------------------------------------

    # Run `name` in `ob` (any function, static included, as for every driver
    # apply) to completion, with `ob` pushed on the driver stack. Undefined
    # when the object doesn't define it. Driver apply(), which also lets the
    # object's shadows intercept.
    fn apply_value(mut self, ob: i32, name: str, args: List<val::Value>) -> val::Value:
        if !self.alive(ob):
            return val::Value::Undef
        let mut target = ob
        let sb = self.objs[ob].shadowed_by
        if sb >= 0:
            let mut s = sb
            while s >= 0 and s != ob:
                if self.public_fn(s, name).prog >= 0:
                    target = s
                    break
                s = self.objs[s].shadowing
        let e = self.any_fn(target, name)
        if e.prog < 0:
            return val::Value::Undef
        self.run_entry(target, e, name, args)

    # Run a resolved function of `ob` to completion, `ob` pushed on the
    # driver stack as entered by `fname`.
    fn run_entry(mut self, ob: i32, e: pg::DispEntry, fname: str, args: List<val::Value>) -> val::Value:
        let depth = self.frames.len()
        let before = self.ostack.len()
        let sl = self.stack.len()
        self.opush(ob, fname)
        if self.err:
            return val::Value::Undef
        self.push_all(args)
        self.enter(e.prog, e.fnidx, e.var_off, ob, args.len(), List<i32>(), before)
        if self.err:
            self.truncate_stack(sl)
            self.truncate_ostack(before)
            return val::Value::Undef
        self.frames[depth].driver = true
        self.execute(depth)
        if self.err:
            return val::Value::Undef
        self.pop()

    # A function value called by the driver (a call_out, an add_action
    # function pointer) with `ob` pushed on the driver stack.
    fn run_fn_value(mut self, ob: i32, f: val::Value, args: List<val::Value>) -> val::Value:
        let before = self.ostack.len()
        if self.alive(ob):
            self.opush(ob, "")
            if self.err:
                return val::Value::Undef
        let r = self.call_value(f, args)
        self.truncate_ostack(before)
        r

    # Apply on the master object. A destructed master is reloaded first, as
    # FluffOS does; before boot has one (or while it reloads) applies are
    # skipped.
    fn master_apply(mut self, fname: str, args: List<val::Value>, caller: i32) -> val::Value:
        if !self.alive(self.master_ob):
            if !self.master_established or self.loading.contains(self.master_path):
                return val::Value::Undef
            self.master_ob = -1
            let saved_err = self.err
            self.load_object(self.master_path, -1)
            if self.err or !self.alive(self.master_ob):
                self.log_msg(f"*** Unable to reload the master object: {self.errmsg}")
                if !saved_err:
                    self.clear_err()
                return val::Value::Undef
        self.apply_value(self.master_ob, fname, args)

    # --- top-level evaluations and the evaluation limit -------------------------

    # Top-level evaluations nest (a heart beat can start a call_out run, a
    # command can trigger init()s); only the outermost starts and ends the
    # time budget.
    fn begin_eval(mut self):
        self.eval_nest += 1
        if self.eval_nest > 1:
            return
        self.now_sec = vm::epoch_now()
        self.reset_eval()

    # A fresh budget for the evaluation now running (reset_eval_cost()).
    fn reset_eval(mut self):
        if self.eval_nest > 0 and self.max_cost > (0 as i64):
            let ms = self.max_cost / (1000 as i64)
            self.eval_deadline = clock_ms() + (if ms > (0 as i64): ms else: 1 as i64)
        else:
            self.eval_deadline = 0 as i64
        self.outoftime = false

    fn end_eval(mut self):
        self.eval_nest -= 1
        if self.eval_nest > 0:
            return
        self.eval_nest = 0
        if self.pending_replace.len() > 0:
            self.apply_replaces()
        self.eval_deadline = 0 as i64
        self.outoftime = false

    # Every 256 ticks (function entries and loop back edges). FluffOS's
    # "maximum evaluation cost" is wall-clock microseconds for one top-level
    # evaluation; once it's spent every tick raises again, so catch() can't
    # swallow a runaway loop.
    fn eval_tick(mut self):
        self.ticks = 0
        if !self.outoftime:
            if self.eval_deadline == (0 as i64) or clock_ms() <= self.eval_deadline:
                return
            self.outoftime = true
            self.log_msg(f"object {self.obj_name(self.cur_obj())}: eval_cost too big {self.max_cost}")
        # the next tick comes straight back here
        self.ticks = 256
        self.fail("Too long evaluation. Execution aborted.\n")

    # Microseconds left (eval_cost()).
    fn eval_remaining(self) -> i64:
        if self.eval_deadline != (0 as i64):
            return (self.eval_deadline - clock_ms()) * (1000 as i64)
        self.max_cost

    # Run apply(ob, name) as a top-level evaluation (driver safe()): an error
    # is reported to the master instead of propagating, and the stacks are
    # back where they were afterwards.
    fn safe_apply(mut self, ob: i32, name: str, args: List<val::Value>, context: str) -> val::Value:
        let ol = self.ostack.len()
        let sl = self.stack.len()
        self.begin_eval()
        let r = self.apply_value(ob, name, args)
        let failed = self.err
        if failed:
            self.report_error(context)
        self.truncate_ostack(ol)
        self.truncate_stack(sl)
        self.end_eval()
        if failed:
            return val::Value::Undef
        r

    fn safe_master_apply(mut self, name: str, args: List<val::Value>, context: str) -> val::Value:
        let ol = self.ostack.len()
        let sl = self.stack.len()
        self.begin_eval()
        let r = self.master_apply(name, args, -1)
        let failed = self.err
        if failed:
            self.report_error(context)
        self.truncate_ostack(ol)
        self.truncate_stack(sl)
        self.end_eval()
        if failed:
            return val::Value::Undef
        r

    # --- error reporting --------------------------------------------------------

    # The LPC error string: a thrown string as it is, an error "*message\n".
    fn error_string(self) -> str:
        if self.err_thrown:
            match self.errv:
                val::Value::Str(s) ->
                    return s
                _ ->
                    return "*Unknown error thrown\n"
        let mut m = self.errmsg
        if !str_ends_with(m, "\n"):
            m = concat(m, "\n")
        if !str_starts_with(m, "*"):
            m = concat("*", m)
        m

    # The source line of `pc` in a function, from the compiler's line table
    # (pc, line, file id triples, in pc order); 0 when there is none.
    fn line_at(self, prog: i32, fnidx: i32, pc: i32) -> List<i32>:
        let t = self.progs[prog].fns[fnidx].lines
        let mut line = 0
        let mut file = -1
        let mut i = 0
        while i + 2 < t.len() and t[i] < pc:
            line = t[i + 1]
            file = t[i + 2]
            i += 3
        [line, file]

    # FluffOS's error mapping for master->error_handler(): the innermost
    # frame's program, file, line and object, and the whole trace, innermost
    # first (driver error_mapping()).
    fn error_mapping(mut self, msg: str, frames: List<vm::Frame>) -> val::Value:
        let mut trace: List<val::Value> = List<val::Value>()
        let mut top_file = val::Value::Int(0 as i64)
        let mut top_prog = val::Value::Int(0 as i64)
        let mut top_line = 0
        let mut top_ob = val::Value::Int(0 as i64)
        let mut i = frames.len() - 1
        while i >= 0:
            let fr = frames[i]
            let pfile = concat(self.progs[fr.prog].path, ".c")
            let lf = self.line_at(fr.prog, fr.fnidx, fr.pc)
            let file = if lf[1] >= 0 and lf[1] < self.pp.files.len(): self.pp.files[lf[1]] else: pfile
            let ob = if self.alive(fr.obj): self.obj_value(fr.obj) else: val::Value::Int(0 as i64)
            let m = self.new_map()
            self.map_set(m, val::Value::Str("function"), val::Value::Str(self.progs[fr.prog].fns[fr.fnidx].name))
            self.map_set(m, val::Value::Str("program"), val::Value::Str(pfile))
            self.map_set(m, val::Value::Str("file"), val::Value::Str(file))
            self.map_set(m, val::Value::Str("line"), val::Value::Int(lf[0] as i64))
            self.map_set(m, val::Value::Str("object"), ob)
            trace.push(val::Value::Map(m))
            if i == frames.len() - 1:
                top_file = val::Value::Str(file)
                top_prog = val::Value::Str(pfile)
                top_line = lf[0]
                top_ob = ob
            i -= 1
        let r = self.new_map()
        self.map_set(r, val::Value::Str("error"), val::Value::Str(msg))
        self.map_set(r, val::Value::Str("program"), top_prog)
        self.map_set(r, val::Value::Str("file"), top_file)
        self.map_set(r, val::Value::Str("line"), val::Value::Int(top_line as i64))
        self.map_set(r, val::Value::Str("object"), top_ob)
        let tr = self.new_arr(trace)
        self.map_set(r, val::Value::Str("trace"), tr)
        val::Value::Map(r)

    # An uncaught runtime error (FluffOS: master->error_handler(map, 0)). The
    # error is cleared; error_handler()'s own evaluation gets a fresh budget.
    fn report_error(mut self, context: str):
        let msg = self.error_string()
        let frames = self.err_frames
        self.clear_err()
        self.err_frames = List<vm::Frame>()
        let where_ = if context != "": concat(" in ", context) else: ""
        self.log_msg(f"*** Runtime error{where_}: {str_replace(msg, "\n", "")}")
        if !self.alive(self.master_ob) or self.in_error_handler:
            return
        self.in_error_handler = true
        let saved_deadline = self.eval_deadline
        let saved_out = self.outoftime
        self.reset_eval()
        let m = self.error_mapping(msg, frames)
        let r = self.apply_value(self.master_ob, "error_handler", [m, val::Value::Int(0 as i64)])
        if self.err:
            self.log_msg(f"*** Error in error_handler: {self.errmsg}")
            self.clear_err()
        else:
            match r:
                val::Value::Str(s) ->
                    if self.alive(self.cur_player):
                        self.tell_user(self.cur_player, s)
                _ -> 0
        self.eval_deadline = saved_deadline
        self.outoftime = saved_out
        if saved_out:
            self.ticks = 256
        self.in_error_handler = false

    # Text straight to a user's connection, bypassing catch_tell(); nothing
    # for an object that isn't interactive.
    fn tell_user(mut self, ob: i32, msg: str):
        let ci = self.user_conn(ob)
        if ci >= 0:
            self.conn_send(ci, msg)

    # --- destruct ---------------------------------------------------------------

    # FluffOS destruct_object(): the master and simul_efun objects are vital,
    # so a fresh copy is loaded *before* the old one goes away. The old object
    # stays master()/the sefun object while the new copy compiles and runs
    # create() (its name hidden so find_object() can't see it); if the copy
    # fails to load the destruct is refused.
    fn replace_vital_object(mut self, caller: i32, ob: i32):
        let name = self.objs[ob].name
        self.obj_by_name.remove(name)
        self.prog_by_path.remove(self.objs[ob].base_prog)
        let r = self.load_object(name, caller)
        let failed = self.err
        if failed:
            self.clear_err()
        let new_ob = self.obj_of(r)
        if failed or new_ob < 0 or new_ob == ob:
            if self.alive(ob):
                self.obj_by_name.insert(name, ob)
            self.fail("Destruct on vital object failed: new copy failed to reload.\n")
            return
        if ob == self.master_ob:
            self.master_ob = new_ob
            self.objs[new_ob].privs = val::Value::Str("SECURE")
        if ob == self.sefun_ob:
            self.sefun_ob = new_ob
            self.refresh_sefuns()

    fn destruct_object(mut self, caller: i32, ob: i32):
        if !self.alive(ob):
            return
        let vital = ob == self.master_ob or ob == self.sefun_ob
        if vital:
            self.replace_vital_object(caller, ob)
            if self.err:
                return
        if self.objs[ob].shadowing >= 0:
            self.remove_shadow(ob)
        while self.objs[ob].shadowed_by >= 0:
            self.remove_shadow(self.objs[ob].shadowed_by)
        # inventory: move_or_destruct(dest) on each item, else destruct it
        let dest = self.objs[ob].env
        let items = self.objs[ob].inv
        for i in 0..items.len():
            let item = items[i]
            if !self.alive(item):
                continue
            if dest >= 0:
                self.apply_value(item, "move_or_destruct", [self.obj_value(dest)])
                if self.err:
                    self.clear_err()
            if self.alive(item) and self.objs[item].env == ob:
                self.destruct_object(caller, item)
                if self.err:
                    return
        if !self.alive(ob):
            return
        let env = self.objs[ob].env
        if env >= 0:
            self.objs[env].inv = without(self.objs[env].inv, ob)
            self.remove_actions_between(ob, env)
        # interactive: its connection closes
        let ci = self.objs[ob].conn
        if ci >= 0:
            self.objs[ob].conn = -1
            if ci < self.conns.len() and self.conns[ci].alive and self.conns[ci].user == ob:
                self.conn_destructed(ci)
        # editing: its session ends, unsaved changes rescued (ed.star)
        self.ed_destructed(ob)
        self.remove_heart_beat(ob)
        self.remove_call_outs_for(ob)
        self.remove_living_name(ob)
        self.vp_forget(ob)
        let name = self.objs[ob].name
        if let Option::Some(x) = self.obj_by_name.get(name):
            if x == ob:
                self.obj_by_name.remove(name)
        self.objs[ob].alive = false
        self.objs[ob].living = false
        self.objs[ob].env = -1
        self.objs[ob].inv = List<i32>()
        self.objs[ob].actions = List<vm::Action>()
        if self.cur_player == ob:
            self.cur_player = vm::DESTRUCTED_OB
        if self.cur_interactive == ob:
            self.cur_interactive = vm::DESTRUCTED_OB
        if ob == self.sefun_ob:
            self.sefun_ob = -1
        # FluffOS recompiles a file when its blueprint is loaded again (what
        # `update` relies on); clones keep their program, and vital objects
        # already did
        if !vital and !self.objs[ob].clone and !self.objs[ob].is_virtual:
            self.prog_by_path.remove(self.objs[ob].base_prog)

    # --- inheritance --------------------------------------------------------------

    # Every program a program inherits, deep, in FluffOS order (each inherit
    # followed by its own inherits), no duplicates (compiler.pike
    # deep_inherits()).
    fn deep_inherit_paths(self, pid: i32) -> List<str>:
        let mut out: List<str> = List<str>()
        let mut seen: Set<str> = Set<str>()
        let inh = self.progs[pid].inherits
        for i in 0..inh.len():
            let p = inh[i].path
            if !seen.contains(p):
                out.push(p)
                seen.insert(p)
            let sub = self.deep_inherit_paths(inh[i].prog)
            for j in 0..sub.len():
                if !seen.contains(sub[j]):
                    out.push(sub[j])
                    seen.insert(sub[j])
        out

    fn deep_inherits_p(self, pid: i32, path: str) -> bool:
        let inh = self.progs[pid].inherits
        for i in 0..inh.len():
            if inh[i].path == path or self.deep_inherits_p(inh[i].prog, path):
                return true
        false

    # The variable offset of inherited program `path` inside program `pid`'s
    # layout, and its program id (replace_program()); [-1, -1] if not found.
    fn find_inherit_block(self, pid: i32, path: str, base: i32) -> List<i32>:
        let inh = self.progs[pid].inherits
        for i in 0..inh.len():
            if inh[i].path == path:
                return [inh[i].prog, base + inh[i].var_off]
        for i in 0..inh.len():
            let r = self.find_inherit_block(inh[i].prog, path, base + inh[i].var_off)
            if r[0] >= 0:
                return r
        [-1, -1]

    # --- environment, inventory and init() -----------------------------------------

    # Actions defined by a on b and by b on a are removed when they part.
    fn remove_actions_between(mut self, a: i32, b: i32):
        self.drop_actions_of(b, a)
        self.drop_actions_of(a, b)

    # Drop the sentences `owner` defined on living `on`.
    fn drop_actions_of(mut self, on: i32, owner: i32):
        if !self.alive(on) or self.objs[on].actions.len() == 0:
            return
        let acts = self.objs[on].actions
        let ov = self.obj_value(owner)
        let mut keep: List<vm::Action> = List<vm::Action>()
        for i in 0..acts.len():
            if !self.lpc_eq(acts[i].owner, ov) or self.dead_obj(acts[i].owner):
                keep.push(acts[i])
        self.objs[on].actions = keep

    # Put back a saved this_player(). One destructed meanwhile reads as 0, as
    # the destructed Pike object the reference restores does (only a command
    # giver destructed *while it is this_player()* becomes DESTRUCTED_OB);
    # keeping its handle would hand this_player() to whatever object reuses
    # the slot (gc.star).
    fn restore_tp(mut self, saved: i32):
        self.cur_player = if saved == vm::DESTRUCTED_OB or self.alive(saved): saved else: -1

    # initer->init() with this_player() = tp.
    fn do_init(mut self, initer: i32, tp: i32):
        let saved = self.cur_player
        self.cur_player = tp
        self.apply_value(initer, "init", List<val::Value>())
        self.restore_tp(saved)

    # The object is being used: note it, and run a due reset first.
    fn touch(mut self, o: i32):
        if !self.alive(o):
            return
        self.objs[o].last_used = self.now_sec
        let rt = self.objs[o].reset_time
        if rt != (0 as i64) and rt <= self.now_sec:
            self.run_reset(o)

    # driver move_object()
    fn move_object(mut self, item: i32, dest_v: val::Value):
        let mut dest = self.obj_of(dest_v)
        match dest_v:
            val::Value::Str(s) ->
                dest = self.find_object(s)
                if dest < 0:
                    dest = self.obj_of(self.load_object(s, item))
                    if self.err:
                        return
                if dest < 0:
                    self.fail(f"Bad argument 1 to move_object(): could not load {s}\n")
                    return
            _ -> 0
        if dest < 0:
            self.fail("Bad argument 1 to move_object()\n")
            return
        if !self.alive(item):
            self.fail("move_object() on destructed object\n")
            return
        # a room resets as someone walks in
        self.touch(dest)
        self.touch(item)
        if !self.alive(dest):
            self.fail("Bad argument 1 to move_object()\n")
            return
        if !self.alive(item):
            self.fail("move_object() on destructed object\n")
            return
        let mut e = dest
        while e >= 0:
            if e == item:
                self.fail("Can't move object inside itself.\n")
                return
            e = self.objs[e].env
        let old = self.objs[item].env
        if old >= 0:
            self.objs[old].inv = without(self.objs[old].inv, item)
            # actions between the item and its old environment and that
            # environment's inventory go away
            self.remove_actions_between(item, old)
            let oinv = self.objs[old].inv
            for i in 0..oinv.len():
                self.remove_actions_between(item, oinv[i])
        self.objs[item].env = dest
        let mut ninv: List<i32> = [item]
        let dinv = self.objs[dest].inv
        for i in 0..dinv.len():
            ninv.push(dinv[i])
        self.objs[dest].inv = ninv
        # init() calls, in FluffOS order
        if self.objs[item].living:
            self.do_init(dest, item)
            if self.err:
                return
        let inv = self.objs[dest].inv
        for i in 0..inv.len():
            let o = inv[i]
            if o == item or !self.alive(o) or !self.alive(item):
                continue
            if self.objs[item].living:
                self.do_init(o, item)
                if self.err:
                    return
            if self.alive(o) and self.objs[o].living and self.alive(item):
                self.do_init(item, o)
                if self.err:
                    return
        if self.alive(item) and self.alive(dest) and self.objs[dest].living:
            self.do_init(item, dest)

    fn live_inventory(self, o: i32) -> List<i32>:
        let mut out: List<i32> = List<i32>()
        if !self.alive(o):
            return out
        let inv = self.objs[o].inv
        for i in 0..inv.len():
            if self.alive(inv[i]):
                out.push(inv[i])
        out

    # --- livings -------------------------------------------------------------------

    fn remove_living_name(mut self, o: i32):
        let n = self.objs[o].living_name
        if n == "":
            return
        if let Option::Some(l) = self.living_names.get(n):
            let rest = without(l, o)
            if rest.len() > 0:
                self.living_names.insert(n, rest)
            else:
                self.living_names.remove(n)
        self.objs[o].living_name = ""

    fn set_living_name(mut self, o: i32, name: str):
        if !self.alive(o):
            return
        self.remove_living_name(o)
        self.objs[o].living_name = name
        let mut l: List<i32> = [o]
        if let Option::Some(old) = self.living_names.get(name):
            for i in 0..old.len():
                l.push(old[i])
        self.living_names.insert(name, l)

    # Like FluffOS's living hash: most recently named (or found) first; an
    # object whose commands are disabled is skipped, and `user` wants one
    # that has been interactive.
    fn find_living(mut self, name: str, user: bool) -> i32:
        let mut l: List<i32> = List<i32>()
        if let Option::Some(x) = self.living_names.get(name):
            l = x
        for k in 0..l.len():
            let o = l[k]
            if !self.alive(o) or !self.objs[o].living or (user and !self.objs[o].once_interactive):
                continue
            if k > 0:
                let mut moved: List<i32> = [o]
                for j in 0..l.len():
                    if j != k:
                        moved.push(l[j])
                self.living_names.insert(name, moved)
            return o
        -1

    # --- shadows -------------------------------------------------------------------

    fn shadow(mut self, shadower: i32, victim: i32) -> i32:
        if !self.alive(shadower) or !self.alive(victim):
            return -1
        if self.objs[shadower].shadowing >= 0 or victim == shadower:
            return -1
        if self.alive(self.master_ob):
            let ok = self.master_apply("valid_shadow", [self.obj_value(shadower)], shadower)
            if self.err or !self.truthy(ok):
                return -1
        # attach as the outermost shadow; the chain inwards follows the
        # `shadowing` links
        let outer = self.objs[victim].shadowed_by
        self.objs[shadower].shadowing = if outer >= 0: outer else: victim
        self.objs[victim].shadowed_by = shadower
        victim

    fn remove_shadow(mut self, s: i32):
        if s < 0 or self.objs[s].shadowing < 0:
            return
        let mut base = self.objs[s].shadowing
        while self.objs[base].shadowing >= 0:
            base = self.objs[base].shadowing
        if self.objs[base].shadowed_by == s:
            let inner = self.objs[s].shadowing
            self.objs[base].shadowed_by = if inner == base: -1 else: inner
        else:
            # unlink from the middle of the chain
            let mut x = self.objs[base].shadowed_by
            while x >= 0:
                if self.objs[x].shadowing == s:
                    self.objs[x].shadowing = self.objs[s].shadowing
                    break
                x = self.objs[x].shadowing
        self.objs[s].shadowing = -1

    # --- commands --------------------------------------------------------------------

    # Run a command for `who` through its add_action sentences (FluffOS
    # user_parser): flag 0 wants the verb to be the first word ("" matches
    # anything), 1 a prefix of the command, 2 a prefix with everything after
    # it as the argument. True when an action accepted it.
    fn do_command(mut self, who: i32, cmd_in: str) -> bool:
        if !self.alive(who):
            return false
        let b = bytes_from_str(cmd_in)
        let mut e = b.len()
        while e > 0 and (b[e - 1] as i32) == 32:
            e -= 1
        let cmd = vm::substr(cmd_in, 0, e)
        if cmd == "":
            return false
        let sp = str_index_of(cmd, " ")
        let verb = if sp >= 0: vm::substr(cmd, 0, sp) else: cmd
        let saved_tp = self.cur_player
        let saved_verb = self.cur_verb
        self.cur_player = who
        self.objs[who].notify_fail = val::Value::Int(0 as i64)
        let mut done = false
        let acts = self.objs[who].actions
        for i in 0..acts.len():
            let s = acts[i]
            let owner = self.obj_of(s.owner)
            if owner < 0:
                continue
            let av = s.verb
            let flag = s.flag
            if (flag & 3) != 0:
                if !str_starts_with(cmd, av):
                    continue
            elif av != "" and av != verb:
                continue
            if (flag & 2) != 0:
                self.cur_verb = val::Value::Str(if len(av) < len(verb): vm::substr(verb, len(av), len(verb)) else: "")
            elif av == "" or (flag & 1) != 0:
                self.cur_verb = val::Value::Str(verb)
            else:
                self.cur_verb = val::Value::Str(av)
            let mut a = val::Value::Undef
            if (flag & 2) != 0:
                a = val::Value::Str(vm::substr(cmd, len(av), len(cmd)))
            elif sp >= 0:
                a = val::Value::Str(vm::substr(cmd, sp + 1, len(cmd)))
            let mut r = val::Value::Undef
            match s.fun:
                val::Value::Str(fname) ->
                    let en = self.any_fn(owner, fname)
                    if en.prog < 0:
                        self.fail(f"Function for verb '{av}' not found.\n")
                    else:
                        r = self.run_entry(owner, en, "", [a])
                _ ->
                    r = self.run_fn_value(owner, s.fun, [a])
            if self.err:
                break
            if !self.alive(who) or self.truthy(r):
                done = true
                break
        self.restore_tp(saved_tp)
        self.cur_verb = saved_verb
        done

    # --- messages ----------------------------------------------------------------------

    fn to_text(mut self, v: val::Value) -> str:
        match v:
            val::Value::Str(s) -> s
            val::Value::Int(x) -> vm::int_str(x)
            val::Value::Real(x) -> self.lpc_sprintf("%f", [v])
            val::Value::Obj(h, g) ->
                if self.obj_of(v) >= 0:
                    return self.objs[h].name
                ""
            _ -> ""

    # Text to an object the way tell_object() delivers it: its catch_tell(),
    # else its connection.
    fn tell_object(mut self, ob: i32, msg: val::Value):
        if !self.alive(ob):
            return
        let s = self.to_text(msg)
        let e = self.any_fn(ob, "catch_tell")
        if e.prog >= 0:
            self.run_entry(ob, e, "", [val::Value::Str(s)])
            return
        self.tell_user(ob, s)

    # write(): to this_player(), or the driver's output when there is none
    fn do_write(mut self, msg: val::Value):
        let tp = self.cur_player
        if !self.alive(tp):
            let s = self.to_text(msg)
            if s != "":
                self.log_msg(s)
            return
        self.tell_object(tp, msg)

    # Is `o` someone messages are for: living or interactive.
    fn hears(self, o: i32) -> bool:
        self.alive(o) and (self.objs[o].living or self.is_interactive(o))

    fn say_to(mut self, self_ob: i32, msg: str, avoid: List<val::Value>):
        let tp = self.cur_player
        let origin = if self.alive(tp): tp else: self_ob
        if !self.alive(origin):
            return
        let env = self.objs[origin].env
        let mut targets: List<i32> = List<i32>()
        if self.alive(env):
            targets.push(env)
            let ei = self.live_inventory(env)
            for i in 0..ei.len():
                targets.push(ei[i])
        let oi = self.live_inventory(origin)
        for i in 0..oi.len():
            targets.push(oi[i])
        for i in 0..targets.len():
            let o = targets[i]
            if o == origin or self.arr_has(avoid, self.obj_value(o)):
                continue
            if self.hears(o):
                self.tell_object(o, val::Value::Str(msg))
                if self.err:
                    return

    fn tell_room(mut self, room: i32, msg: val::Value, avoid: List<val::Value>):
        if !self.alive(room):
            return
        let s = val::Value::Str(self.to_text(msg))
        let mut targets: List<i32> = [room]
        let ri = self.live_inventory(room)
        for i in 0..ri.len():
            targets.push(ri[i])
        for i in 0..targets.len():
            let o = targets[i]
            if self.arr_has(avoid, self.obj_value(o)):
                continue
            if self.hears(o):
                self.tell_object(o, s)
                if self.err:
                    return

    # message(): receive_message(class, msg) in every living or interactive
    # target not excluded; any other target passes it on to its inventory
    # (one level).
    fn deliver_message(mut self, cls: val::Value, msg: val::Value, scope: List<val::Value>, exclude: List<val::Value>, recurse: bool):
        for i in 0..scope.len():
            let mut ob = self.obj_of(scope[i])
            match scope[i]:
                val::Value::Str(s) ->
                    ob = self.find_object(s)
                _ -> 0
            if !self.alive(ob):
                continue
            if self.hears(ob):
                if self.arr_has(exclude, self.obj_value(ob)):
                    continue
                self.apply_value(ob, "receive_message", [cls, msg])
                if self.err:
                    return
            elif recurse:
                let inv = self.live_inventory(ob)
                let mut sub: List<val::Value> = List<val::Value>()
                for j in 0..inv.len():
                    sub.push(self.obj_value(inv[j]))
                self.deliver_message(cls, msg, sub, exclude, false)
                if self.err:
                    return

    # --- call_outs -----------------------------------------------------------------------

    # Centiseconds since boot, the call_out clock (driver call_out_clock()).
    fn call_out_clock(self) -> i64:
        (clock_ms() - self.clock_epoch) / (10 as i64)

    # The object a function value belongs to (bind() may have moved it), or
    # -1 (none, or destructed).
    fn fn_owner(self, f: val::Value) -> i32:
        match f:
            val::Value::Fn(h) ->
                let s = self.fns[h]
                if s.bound_owner >= 0:
                    if self.alive(s.bound_owner) and self.objs[s.bound_owner].gen == s.bound_gen:
                        return s.bound_owner
                    return -1
                if self.alive(s.owner) and self.objs[s.owner].gen == s.owner_gen:
                    return s.owner
                -1
            _ -> -1

    fn add_call_out(mut self, ob: i32, fun: val::Value, delay: val::Value, args: List<val::Value>) -> i32:
        self.callout_seq += 1
        let h = self.callout_seq
        let owner = match fun:
            val::Value::Str(s) -> ob
            _ -> self.fn_owner(fun)
        let mut cs = 0 as i64
        match delay:
            val::Value::Int(x) ->
                cs = vm::wmul(x, 100 as i64)
            val::Value::Real(x) ->
                cs = (x * (100.0 as f64)) as i64
            _ -> 0
        if cs < (0 as i64):
            cs = 0 as i64
        let c = vm::CallOut(handle = h, ob = self.obj_value(ob), owner = if owner >= 0: self.obj_value(owner) else: val::Value::Int(0 as i64), fun = fun, args = args, when = vm::wadd(self.call_out_clock(), cs), tp = if self.alive(self.cur_player): self.obj_value(self.cur_player) else: val::Value::Int(0 as i64))
        # keep the queue sorted by (when, handle): the new one goes after
        # everything due no later than it
        let mut out: List<vm::CallOut> = List<vm::CallOut>()
        let mut placed = false
        for i in 0..self.callouts.len():
            if !placed and self.callouts[i].when > c.when:
                out.push(c)
                placed = true
            out.push(self.callouts[i])
        if !placed:
            out.push(c)
        self.callouts = out
        h

    fn call_out_index(self, h: i32) -> i32:
        for i in 0..self.callouts.len():
            if self.callouts[i].handle == h:
                return i
        -1

    # Take a pending call_out out of the queue (it has not run).
    fn drop_call_out_at(mut self, k: i32) -> vm::CallOut:
        let c = self.callouts[k]
        let mut out: List<vm::CallOut> = List<vm::CallOut>()
        for i in 0..self.callouts.len():
            if i != k:
                out.push(self.callouts[i])
        self.callouts = out
        c

    # Whole seconds until it is due (FluffOS time_left()).
    fn call_out_left(self, c: vm::CallOut) -> i64:
        let cs = c.when - self.call_out_clock()
        if cs > (0 as i64):
            return (cs + (99 as i64)) / (100 as i64)
        0 as i64

    # FluffOS remove_all_call_out(): named call_outs of ob and function
    # call_outs owned by it.
    fn remove_call_outs_for(mut self, ob: i32):
        let ov = self.obj_value(ob)
        let mut out: List<vm::CallOut> = List<vm::CallOut>()
        let mut changed = false
        for i in 0..self.callouts.len():
            let c = self.callouts[i]
            if self.lpc_eq(c.owner, ov) and !self.dead_obj(c.owner) and !val::is_zero(c.owner):
                changed = true
            else:
                out.push(c)
        if changed:
            self.callouts = out

    # The call_out remove_call_out()/find_call_out() mean: a handle, or the
    # caller's own named call_out due first. -1 for none.
    fn find_call_out_index(self, self_ob: i32, what: val::Value) -> i32:
        match what:
            val::Value::Str(s) ->
                let ov = self.obj_value(self_ob)
                for i in 0..self.callouts.len():
                    let c = self.callouts[i]
                    if self.lpc_eq(c.ob, ov) and self.lpc_eq(c.owner, ov) and !self.dead_obj(c.ob):
                        match c.fun:
                            val::Value::Str(f) ->
                                if f == s:
                                    return i
                            _ -> 0
                return -1
            val::Value::Int(h) ->
                return self.call_out_index(h as i32)
            val::Value::Undef ->
                return -1
            _ ->
                return -1

    # Run one call_out that has been taken out of the queue (driver
    # run_call_out()): a named one in the object that made it, a function
    # pointer in its owner -- dropped if that object is gone -- with
    # this_player() as it was, as its own top-level evaluation.
    fn run_call_out(mut self, c: vm::CallOut):
        let mut owner = -1
        let mut by_name = ""
        match c.fun:
            val::Value::Str(s) ->
                owner = self.obj_of(c.ob)
                if owner < 0:
                    return
                by_name = s
            val::Value::Fn(h) ->
                let fo = self.fns[h].owner
                if fo >= 0:
                    owner = self.fn_owner(c.fun)
                    if owner < 0:
                        return
                if !val::is_zero(c.owner) and self.obj_of(c.owner) < 0:
                    return
            _ ->
                return
        self.cur_player = self.obj_of(c.tp)
        let ol = self.ostack.len()
        let sl = self.stack.len()
        self.begin_eval()
        if by_name != "":
            let e = self.any_fn(owner, by_name)
            if e.prog >= 0:
                self.run_entry(owner, e, "", c.args)
        else:
            self.run_fn_value(owner, c.fun, c.args)
        if self.err:
            self.report_error("call_out")
        self.truncate_ostack(ol)
        self.truncate_stack(sl)
        self.end_eval()
        self.cur_player = -1

    # Every call_out due now, in due order. Ones made while these run (even
    # with no delay) wait for the next round, as on the reference's backend.
    fn run_due_call_outs(mut self):
        let now = self.call_out_clock()
        let mut due: List<i32> = List<i32>()
        for i in 0..self.callouts.len():
            if self.callouts[i].when > now:
                break
            due.push(self.callouts[i].handle)
        self.run_call_out_handles(due)

    # Every pending call_out, due or not, in due order (the reference's tests
    # drive call_outs this way: drv->run_call_out() on each).
    fn run_all_call_outs(mut self) -> i32:
        let mut hs: List<i32> = List<i32>()
        for i in 0..self.callouts.len():
            hs.push(self.callouts[i].handle)
        self.run_call_out_handles(hs)

    fn run_call_out_handles(mut self, hs: List<i32>) -> i32:
        let mut n = 0
        for i in 0..hs.len():
            let k = self.call_out_index(hs[i])
            if k < 0:
                continue
            let c = self.drop_call_out_at(k)
            self.run_call_out(c)
            n += 1
        n

    # --- heart beats ----------------------------------------------------------------------

    # Every object with a heart beat, slot by slot.
    fn hb_objects(self) -> List<i32>:
        let mut out: List<i32> = List<i32>()
        for s in 0..self.hb_slots.len():
            let l = self.hb_slots[s]
            for i in 0..l.len():
                out.push(l[i])
        out

    # Heart beats are split into slots run evenly spaced over the beat
    # interval (`havok heart beat slots`, default 4), so a command arriving
    # mid-beat waits for one slot's work; each object keeps one slot, so it
    # still beats once per interval, and new ones join the emptiest.
    fn configure_hb_slots(mut self, n_in: i32):
        let all = self.hb_objects()
        let n = if n_in < 1: 1 elif n_in > 20: 20 else: n_in
        self.hb_slots = List<List<i32>>()
        for i in 0..n:
            self.hb_slots.push(List<i32>())
        self.hb_cur = 0
        for i in 0..all.len():
            self.hb_join(all[i])

    fn hb_join(mut self, o: i32):
        let mut s = 0
        for k in 1..self.hb_slots.len():
            if self.hb_slots[k].len() < self.hb_slots[s].len():
                s = k
        self.hb_slots[s].push(o)

    fn hb_leave(mut self, o: i32):
        for s in 0..self.hb_slots.len():
            if has_i32(self.hb_slots[s], o):
                self.hb_slots[s] = without(self.hb_slots[s], o)
                return

    # FluffOS: a nonzero interval is in beats (negative means 1 when
    # enabling, and is refused when already on); the first call comes one
    # interval later.
    fn set_heart_beat(mut self, o: i32, to_in: i32) -> i32:
        if !self.alive(o):
            return 0
        let mut to = to_in
        if to == 0:
            if self.objs[o].hb == 0:
                return 0
            self.objs[o].hb = 0
            self.hb_leave(o)
            return 1
        if self.objs[o].hb != 0:
            if to < 0:
                return 0
        else:
            if to < 0:
                to = 1
            self.hb_join(o)
        self.objs[o].hb = to
        self.objs[o].hb_ticks = to
        1

    fn remove_heart_beat(mut self, o: i32):
        self.objs[o].hb = 0
        self.hb_leave(o)

    # One whole beat: every slot in turn.
    fn heart_beat_tick(mut self):
        for s in 0..self.hb_slots.len():
            self.run_hb_slot(s)

    # The scheduler's step: one slot per call, len(hb_slots) calls per beat.
    fn heart_beat_slot_tick(mut self):
        let s = self.hb_cur
        self.hb_cur = (self.hb_cur + 1) % self.hb_slots.len()
        self.run_hb_slot(s)

    fn run_hb_slot(mut self, s: i32):
        let l = self.hb_slots[s]
        for i in 0..l.len():
            let o = l[i]
            if !self.alive(o) or self.objs[o].hb == 0:
                continue
            self.objs[o].hb_ticks = self.objs[o].hb_ticks - 1
            if self.objs[o].hb_ticks > 0:
                continue
            self.objs[o].hb_ticks = self.objs[o].hb
            self.cur_player = if self.objs[o].living: o else: -1
            let ol = self.ostack.len()
            let sl = self.stack.len()
            self.begin_eval()
            self.apply_value(o, "heart_beat", List<val::Value>())
            if self.err:
                let name = self.objs[o].name
                self.report_error(concat("heart_beat of ", name))
                self.set_heart_beat(o, 0)
                self.log_msg(f"Heart beat in {name} turned off.")
            self.truncate_ostack(ol)
            self.truncate_stack(sl)
            self.end_eval()
        self.cur_player = -1

    # --- reset() and clean_up() (havokos docs/reset-cleanup-spec.md) ------------------------

    # `time to reset : R` gives every object a reset time R/2 + random(R/2)
    # seconds after it is made, and again after each reset. Resets are lazy:
    # reset() runs when an object that is due is next used (a call_other from
    # another object, or a move involving it). `time to clean up : C` calls
    # clean_up(inherited) in objects nobody used for C seconds. Intervals of
    # 0, negative or >= 2^30 turn either off: Dead Souls ships both as
    # 2100000000 and runs its own reset cycle.
    fn interval_cfg(self, key: str) -> i64:
        let mut v = 0 as i64
        if let Option::Some(s) = self.config.get(key):
            v = vm::parse_int_prefix(s)
        if v > (0 as i64) and v < ((1 as i64) << 30):
            return v
        0 as i64

    fn configure_resets(mut self):
        self.reset_interval = self.interval_cfg("time to reset")
        self.cleanup_interval = self.interval_cfg("time to clean up")
        self.lazy_resets = true
        if let Option::Some(s) = self.config.get("havok lazy resets"):
            self.lazy_resets = s != "0"
        if self.reset_interval > (0 as i64):
            self.pp.undefine("__NO_RESETS__")
            if self.lazy_resets:
                self.pp.predefine("__LAZY_RESETS__", "")

    fn reset_delay(mut self) -> i64:
        if self.reset_interval == (0 as i64):
            return 0 as i64
        let half = self.reset_interval / (2 as i64)
        half + self.rand_below(if half > (1 as i64): half else: 1 as i64)

    fn run_reset(mut self, o: i32):
        self.objs[o].reset_time = if self.reset_interval > (0 as i64): vm::wadd(vm::epoch_now(), self.reset_delay()) else: 0 as i64
        let saved = self.cur_player
        let ol = self.ostack.len()
        let sl = self.stack.len()
        self.cur_player = -1
        self.apply_value(o, "reset", List<val::Value>())
        if self.err:
            self.report_error(concat("reset of ", self.objs[o].name))
        self.truncate_ostack(ol)
        self.truncate_stack(sl)
        self.restore_tp(saved)

    # set_reset(ob[, secs])
    fn set_reset(mut self, o: i32, secs: i64, has_secs: bool):
        if !self.alive(o):
            return
        if has_secs:
            self.objs[o].reset_time = vm::wadd(vm::epoch_now(), if secs > (0 as i64): secs else: 0 as i64)
        elif self.reset_interval > (0 as i64):
            self.objs[o].reset_time = vm::wadd(vm::epoch_now(), self.reset_delay())
        else:
            self.objs[o].reset_time = 0 as i64

    # clean_up()'s argument: 1 when the object's program is inherited by the
    # program of some other live object.
    fn inherited_programs(self) -> Set<str>:
        let mut out: Set<str> = Set<str>()
        for o in 1..self.objs.len():
            if self.objs[o].alive:
                let d = self.deep_inherit_paths(self.objs[o].prog)
                for i in 0..d.len():
                    out.insert(d[i])
        out

    # One sweep: clean_up() in idle objects, and (when not lazy) due resets.
    # Each call is its own top-level evaluation.
    fn reset_sweep_once(mut self):
        let t = vm::epoch_now()
        let mut clean: List<i32> = List<i32>()
        let mut resets: List<i32> = List<i32>()
        for o in 1..self.objs.len():
            if !self.objs[o].alive:
                continue
            let s = self.objs[o]
            if self.cleanup_interval > (0 as i64) and !s.no_clean_up and t - s.last_used >= self.cleanup_interval and !self.is_interactive(o) and o != self.master_ob and o != self.sefun_ob:
                clean.push(o)
            elif !self.lazy_resets and s.reset_time != (0 as i64) and s.reset_time <= t:
                resets.push(o)
        let inh = if clean.len() > 0: self.inherited_programs() else: Set<str>()
        for i in 0..clean.len():
            let o = clean[i]
            if !self.alive(o):
                continue
            let flag = if !self.objs[o].clone and inh.contains(self.progs[self.objs[o].prog].path): 1 else: 0
            if self.any_fn(o, "clean_up").prog < 0:
                self.objs[o].no_clean_up = true
                continue
            let r = self.safe_apply(o, "clean_up", [val::Value::Int(flag as i64)], concat("clean_up of ", self.objs[o].name))
            if !self.alive(o):
                continue
            if !self.truthy(r):
                self.objs[o].no_clean_up = true
            else:
                self.objs[o].last_used = vm::epoch_now()
        for i in 0..resets.len():
            let o = resets[i]
            if !self.alive(o) or self.objs[o].reset_time == (0 as i64) or self.objs[o].reset_time > vm::epoch_now():
                continue
            self.begin_eval()
            self.run_reset(o)
            self.end_eval()

    # --- replace_program() -------------------------------------------------------------------

    # FluffOS swaps the object's program for an inherited one when the
    # evaluation ends: the object keeps its name and the variables of that
    # program, and functions defined above it are gone. The reference can't
    # change a Pike object's program, so it keeps the object and looks
    # functions up through a view of the inherited program, which leaves
    # code inside that program still reaching functions the replaced program
    # overrode. Here the object really switches (deviation #10): its
    # variable block is cut down to the inherited program's. Dead Souls only
    # replaces programs that define nothing but create(), where the two
    # can't differ.
    fn request_replace(mut self, o: i32, path_in: str):
        if !self.alive(o):
            return
        let path = self.normalize(path_in, "")
        if !self.deep_inherits_p(self.objs[o].prog, path):
            self.fail(f"replace_program(): {path} is not inherited by {self.objs[o].name}\n")
            return
        # the last request in an evaluation wins
        self.objs[o].replace_to = path
        if !has_i32(self.pending_replace, o):
            self.pending_replace.push(o)

    fn apply_replaces(mut self):
        let ps = self.pending_replace
        self.pending_replace = List<i32>()
        for i in 0..ps.len():
            let o = ps[i]
            if !self.alive(o) or self.objs[o].replace_to == "":
                continue
            let to = self.objs[o].replace_to
            self.objs[o].replace_to = ""
            let blk = self.find_inherit_block(self.objs[o].prog, to, 0)
            if blk[0] < 0:
                continue
            let n = self.progs[blk[0]].nvars
            let old = self.objs[o].vars
            let mut vars: List<val::Value> = List<val::Value>()
            for k in 0..n:
                vars.push(old[blk[1] + k])
            self.objs[o].vars = vars
            self.objs[o].prog = blk[0]
            self.objs[o].replaced = to

    # --- the driver's timers --------------------------------------------------------------------

    # One pass of the driver's timers, for the main loop to call between
    # input events (`net.star` net_poll() does the sockets): every due call_out, the heart beat
    # slot whose turn has come (the reference schedules one slot every
    # interval / slots, so a beat stays one per interval), the reset sweep
    # when resets or clean_up are on, and a garbage collection when the
    # heap has grown or reclaim_objects() asked -- only here, between
    # top-level evaluations (gc.star).
    fn driver_tick(mut self):
        self.run_due_call_outs()
        let now = clock_ms()
        if self.next_hb_ms == (0 as i64):
            self.next_hb_ms = now
        if now >= self.next_hb_ms:
            self.heart_beat_slot_tick()
            self.next_hb_ms = now + self.hb_interval_ms / (self.hb_slots.len() as i64)
        let sweep = self.sweep_interval_s()
        if sweep > (0 as i64):
            if self.next_sweep_ms == (0 as i64):
                self.next_sweep_ms = now + sweep * (1000 as i64)
            if now >= self.next_sweep_ms:
                self.reset_sweep_once()
                self.next_sweep_ms = now + sweep * (1000 as i64)
        if self.gc_requested:
            self.gc_requested = false
            self.collect_garbage()
        else:
            self.maybe_collect()

    # Seconds between reset sweeps (driver configure_resets()): half the
    # clean_up interval (or the reset interval when resets aren't lazy and
    # it's shorter), between 1 and 60; 0 when neither is on.
    fn sweep_interval_s(self) -> i64:
        let mut s = self.cleanup_interval
        if self.reset_interval > (0 as i64) and !self.lazy_resets and (s == (0 as i64) or self.reset_interval < s):
            s = self.reset_interval
        if s == (0 as i64):
            return 0 as i64
        let h = s / (2 as i64)
        if h < (1 as i64):
            return 1 as i64
        if h > (60 as i64):
            return 60 as i64
        h

    # --- get_garbage() -------------------------------------------------------------------------

    # Clones without an environment that nothing references (FluffOS 2.23,
    # which the reference matches with Pike's reference counts): what holds
    # an object is a variable anywhere (deep: arrays, mappings, closures,
    # function pointers), a running function's locals, a pending call_out,
    # being a living or this_player(), an add_action() sentence or a shadow.
    # Its heart beat and its own inventory don't count. Newest first.
    fn garbage_clones(mut self) -> List<i32>:
        let held = self.referenced_objects()
        let mut out: List<i32> = List<i32>()
        let mut o = self.objs.len() - 1
        while o > 0:
            let s = self.objs[o]
            if s.alive and s.clone and !s.is_virtual and s.env < 0 and !held[o]:
                out.push(o)
            o -= 1
        # newest first: by clone number, highest first
        let mut a = 1
        while a < out.len():
            let x = out[a]
            let mut b = a - 1
            while b >= 0 and self.objs[out[b]].clone_no < self.objs[x].clone_no:
                out[b + 1] = out[b]
                b -= 1
            out[b + 1] = x
            a += 1
        out

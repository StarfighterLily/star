# Garbage collection -- todo.md HavokOS M5 (NOTES.md "Value representation").
#
# LPC arrays, mappings, function pointers, class instances and closure cells
# live in VM-owned tables (value.star says why), so nothing frees them by
# itself: until M5 the tables only grew, which a test run could afford and a
# MUD that runs for months can't. The full collection is a mark-and-sweep
# *between* top-level evaluations, when no LPC code is running: then the
# value stack and the frames are empty, and every live value is reachable
# from a short list of roots -- the variables of live objects, pending
# call_outs, add_action() sentences, what connections hold (M6: a pending
# input_to()'s function and arguments) and a few driver-held values. No stack
# maps are needed, and no handle can be hiding in a Star local of some efun
# halfway through its work. Unreachable slots go on a free list that the
# allocators (vm.star new_arr/new_map/new_fn/new_cell/new_cls) take from
# first. Destructed objects' slots are reused too: an object value carries
# its slot's generation, so a stale reference to the old object still reads
# as destructed.
#
# Why not reference counting: every LPC value copy (a stack push, a local
# store, a mapping lookup) would have to touch a count, in a VM whose
# values are plain enum copies, and cycles (an object holding a closure
# over itself, a mapping in its own values) would still need a collector.
#
# The same marking answers get_garbage()'s question mid-evaluation
# (`referenced_objects()`): which objects does anything hold? There the
# running functions' locals are roots too. A local captured by a closure
# sits on the stack as a cell id, an int that can't be told apart from any
# other int, so that pass treats every allocated cell as a root. That can
# only make get_garbage() keep a clone a little longer, until a collection
# frees the cells nothing reaches.
#
# Collections inside an evaluation (todo.md HavokOS P1 #9). Collecting only
# between evaluations meant one evaluation's garbage lived until it ended:
# an `a += ({ x })` loop copies the whole array each time, so 30,000
# appends held 7 GB and 40,000 killed the driver. `collect_young()` runs at
# the interpreter's safe points instead, and is generational in one sense
# only: each heap slot records the serial of the interpreter loop
# (vm.star execute()) it was allocated under, and a collection frees only
# slots at least as young as the loop it runs in. That is what makes it
# safe with native Star frames on the stack, which the alternatives
# weren't: rooting what those frames hold (stack maps, or a pin list every
# efun that calls back into LPC would have to keep exactly right) or
# reference counts (rejected above). collect_young() gives the argument.
# Objects and cells are still freed only between evaluations.

import "value.star" as val
import "vm.star" as vm

impl vm::Vm:
    fn gc_reset_marks(mut self):
        self.gc_arr = List<bool>()
        self.gc_map = List<bool>()
        self.gc_fn = List<bool>()
        self.gc_cls = List<bool>()
        self.gc_buf = List<bool>()
        self.gc_cell = List<bool>()
        self.gc_obj = List<bool>()
        for i in 0..self.arrs.len():
            self.gc_arr.push(false)
        for i in 0..self.maps.len():
            self.gc_map.push(false)
        for i in 0..self.fns.len():
            self.gc_fn.push(false)
        for i in 0..self.clss.len():
            self.gc_cls.push(false)
        for i in 0..self.bufs.len():
            self.gc_buf.push(false)
        for i in 0..self.cells.len():
            self.gc_cell.push(false)
        for i in 0..self.objs.len():
            self.gc_obj.push(false)
        self.gc_work = List<val::Value>()
        self.gc_min = 0
        # the one shared empty array
        self.gc_arr[0] = true

    # Queue a value for marking. A collection inside an evaluation
    # (`gc_min` > 0) never frees an older slot and has already queued what
    # every older slot holds, so it only queues younger ones.
    fn gc_root(mut self, v: val::Value):
        match v:
            val::Value::Arr(h) ->
                if self.arr_ser[h] >= self.gc_min:
                    self.gc_work.push(v)
            val::Value::Map(h) ->
                if self.map_ser[h] >= self.gc_min:
                    self.gc_work.push(v)
            val::Value::Fn(h) ->
                if self.fn_ser[h] >= self.gc_min:
                    self.gc_work.push(v)
            val::Value::Cls(h) ->
                if self.cls_ser[h] >= self.gc_min:
                    self.gc_work.push(v)
            # a buffer holds no values: marked at once
            val::Value::Buf(h) ->
                if h >= 0 and h < self.gc_buf.len():
                    self.gc_buf[h] = true
            val::Value::Obj(h, g) ->
                if self.objs[h].alive and self.objs[h].gen == g:
                    self.gc_obj[h] = true
            _ -> 0

    fn gc_root_all(mut self, vs: List<val::Value>):
        for i in 0..vs.len():
            self.gc_root(vs[i])

    fn gc_mark_cell(mut self, c: i32):
        if c < 0 or c >= self.gc_cell.len() or self.gc_cell[c]:
            return
        self.gc_cell[c] = true
        self.gc_root(self.cells[c])

    # Mark everything reachable from the values queued so far.
    fn gc_drain(mut self):
        while self.gc_work.len() > 0:
            let v = self.gc_work[self.gc_work.len() - 1]
            self.gc_work.pop()
            match v:
                val::Value::Arr(h) ->
                    if !self.gc_arr[h]:
                        self.gc_arr[h] = true
                        self.gc_root_all(self.arrs[h].items)
                val::Value::Map(h) ->
                    if !self.gc_map[h]:
                        self.gc_map[h] = true
                        self.gc_root_all(self.maps[h].keys)
                        self.gc_root_all(self.maps[h].vals)
                val::Value::Fn(h) ->
                    if !self.gc_fn[h]:
                        self.gc_fn[h] = true
                        let s = self.fns[h]
                        self.gc_root_all(s.bound)
                        for i in 0..s.cells.len():
                            self.gc_mark_cell(s.cells[i])
                        # a function pointer holds its object
                        if s.owner > 0 and s.owner < self.objs.len() and self.objs[s.owner].alive and self.objs[s.owner].gen == s.owner_gen:
                            self.gc_obj[s.owner] = true
                val::Value::Cls(h) ->
                    if !self.gc_cls[h]:
                        self.gc_cls[h] = true
                        self.gc_root_all(self.clss[h].vals)
                _ -> 0

    # The roots that hold between evaluations: live objects' variables and
    # driver-held values, plus the driver's own references to objects.
    fn gc_mark_driver_roots(mut self):
        for o in 1..self.objs.len():
            let s = self.objs[o]
            if !s.alive:
                continue
            self.gc_root_all(s.vars)
            self.gc_root(s.notify_fail)
            for i in 0..s.actions.len():
                self.gc_root(s.actions[i].owner)
                self.gc_root(s.actions[i].fun)
            if s.shadowing > 0:
                self.gc_obj[s.shadowing] = true
            if s.shadowed_by > 0:
                self.gc_obj[s.shadowed_by] = true
            # a living is held by the living table, a named one by the name
            # table (FluffOS counts both); the verb parser holds every object
            # that called parse_init() or registered a rule (the reference's
            # parser tables keep a reference: such a clone is never garbage),
            # and an ed session its editor (the reference's EdIO holds it)
            if s.living or s.living_name != "" or s.vp_known or s.vp_handler or s.ed >= 0:
                self.gc_obj[o] = true
        for i in 0..self.callouts.len():
            let c = self.callouts[i]
            self.gc_root(c.ob)
            self.gc_root(c.owner)
            self.gc_root(c.fun)
            self.gc_root(c.tp)
            self.gc_root_all(c.args)
        # a connection holds its user, its snooper and a pending input_to()
        for i in 0..self.conns.len():
            let c = self.conns[i]
            if !c.alive or c.closed:
                continue
            if c.user > 0 and self.objs[c.user].alive:
                self.gc_obj[c.user] = true
            self.gc_root(c.snooped_by)
            self.gc_root(c.input_fn)
            self.gc_root(c.input_owner)
            self.gc_root_all(c.input_args)
        # an open socket holds its owner, the object it is offered to and its
        # callbacks (the reference's LSock), and a pending resolve() its
        # object and callback
        for i in 0..self.socks.len():
            let k = self.socks[i]
            if !k.open:
                continue
            self.gc_root(k.owner)
            self.gc_root(k.release_ob)
            self.gc_root(k.read_cb)
            self.gc_root(k.write_cb)
            self.gc_root(k.close_cb)
        for i in 0..self.resolves.len():
            self.gc_root(self.resolves[i].ob)
            self.gc_root(self.resolves[i].fun)
        # a find_files() answer holds its object and callback, and the
        # watcher table its objects (ext.star; the reference's watchers
        # mapping keeps a reference)
        for i in 0..self.finds.len():
            self.gc_root(self.finds[i].ob)
            self.gc_root(self.finds[i].cb)
        for i in 0..self.watchers.len():
            self.gc_root(self.watchers[i].ob)
        self.gc_root(self.cur_verb)
        self.gc_root(self.errv)
        if self.cur_player > 0 and self.objs[self.cur_player].alive:
            self.gc_obj[self.cur_player] = true
        if self.cur_interactive > 0 and self.objs[self.cur_interactive].alive:
            self.gc_obj[self.cur_interactive] = true

    # Which objects something holds, mid-evaluation (get_garbage()).
    fn referenced_objects(mut self) -> List<bool>:
        self.gc_reset_marks()
        self.gc_mark_driver_roots()
        self.gc_root_all(self.stack)
        for i in 0..self.frames.len():
            let fr = self.frames[i]
            if fr.obj > 0:
                self.gc_obj[fr.obj] = true
            for j in 0..fr.cells.len():
                self.gc_mark_cell(fr.cells[j])
        for i in 0..self.ostack.len():
            let o = self.ostack[i]
            if o > 0 and o < self.gc_obj.len():
                self.gc_obj[o] = true
        # a boxed local is an int cell id on the stack: every allocated cell
        # counts (see the header)
        for c in 0..self.cells.len():
            if !self.cell_free[c]:
                self.gc_mark_cell(c)
        self.gc_drain()
        let r = self.gc_obj
        self.gc_reset_marks()
        r

    # A full collection. Only between top-level evaluations: with LPC
    # running, Star locals of the efuns on the native stack can hold handles
    # no root reaches (collect_young() is the collection that can run then).
    fn collect_garbage(mut self) -> i32:
        if self.frames.len() > 0 or self.eval_nest > 0 or self.exec_ser != 0:
            return 0
        self.gc_reset_marks()
        self.gc_mark_driver_roots()
        self.gc_root_all(self.stack)
        self.gc_drain()
        let mut freed = self.gc_sweep(0)
        for h in 0..self.cells.len():
            if !self.gc_cell[h] and !self.cell_free[h]:
                self.cells[h] = val::Value::Int(0 as i64)
                self.cell_free[h] = true
                self.cell_free_list.push(h)
                freed += 1
        # destructed objects' slots (never slot 0, the DESTRUCTED placeholder)
        for o in 1..self.objs.len():
            if !self.objs[o].alive and !self.obj_free[o]:
                self.objs[o].vars = List<val::Value>()
                self.objs[o].inv = List<i32>()
                self.objs[o].actions = List<vm::Action>()
                self.objs[o].notify_fail = val::Value::Int(0 as i64)
                self.obj_free[o] = true
                self.obj_free_list.push(o)
        self.err_frames = List<vm::Frame>()
        # a this_player() left pointing at a freed slot would become
        # whatever object reuses it
        if self.cur_player > 0 and !self.objs[self.cur_player].alive:
            self.cur_player = -1
        if self.cur_interactive > 0 and !self.objs[self.cur_interactive].alive:
            self.cur_interactive = -1
        # every slot left is older than any evaluation still to come, so the
        # serials can start again (and never run out)
        self.gc_reset_serials()
        self.gc_set_budget(self.gc_kept)
        self.gc_reset_marks()
        self.gc_runs += 1
        self.gc_live_at_last = self.heap_live()
        freed

    # A collection inside an evaluation (todo.md HavokOS P1 #9), at a safe
    # point of the running interpreter loop (vm.star run_frames(): between
    # instructions, where everything the loop holds is on the value stack,
    # in a frame or in a cell). It frees only slots allocated since that
    # loop began (serial >= its own, nested loops already finished
    # included), which is what makes it safe without knowing what native
    # Star frames hold. Every native frame below the running loop was
    # suspended in the call that started it, so it can only hold handles
    # that existed before: an efun's popped arguments, map()'s results so
    # far, the verb parser's candidates, a call_out's function. Nothing
    # older is freed, so those stay valid, and everything an older slot
    # holds counts as a root, which covers a young value stored into an
    # array only a native frame still holds (no write barrier needed: the
    # older slots are scanned, shallowly, each time). Cells are never freed
    # here, and all of them are roots: a boxed local is an int cell id on
    # the stack (see the header). Objects aren't freed either.
    #
    # So `a += ({ x })` in a loop (a command, a call_out, a create()) no
    # longer keeps every copy until the evaluation ends. What still waits
    # is garbage made under an outer loop while an inner one runs (map()'s
    # callbacks' leftovers are freed once map() returns to its caller's
    # loop), and whatever a cell holds.
    fn collect_young(mut self) -> i32:
        let min = self.exec_ser
        # an error being unwound: its stacks are half torn down, and the
        # next safe point comes soon enough
        if min <= 0 or self.err:
            return 0
        let t0 = clock_ms()
        self.gc_reset_marks()
        self.gc_min = min
        # everything an older slot holds (and the older slots' size, for the
        # next budget)
        let mut old = 0 as i64
        for h in 1..self.arrs.len():
            if !self.arr_free[h] and self.arr_ser[h] < min:
                self.gc_root_all(self.arrs[h].items)
                old += (self.arrs[h].items.len() + 1) as i64
        for h in 0..self.maps.len():
            if !self.map_free[h] and self.map_ser[h] < min:
                self.gc_root_all(self.maps[h].keys)
                self.gc_root_all(self.maps[h].vals)
                old += (self.maps[h].keys.len() * 2 + 1) as i64
        for h in 0..self.fns.len():
            if !self.fn_free[h] and self.fn_ser[h] < min:
                self.gc_root_all(self.fns[h].bound)
                old += (self.fns[h].bound.len() + 1) as i64
        for h in 0..self.clss.len():
            if !self.cls_free[h] and self.cls_ser[h] < min:
                self.gc_root_all(self.clss[h].vals)
                old += (self.clss[h].vals.len() + 1) as i64
        for h in 0..self.bufs.len():
            if !self.buf_free[h] and self.buf_ser[h] < min:
                old += (self.bufs[h].data.len() / 16 + 1) as i64
        # every object's variables, destructed ones not yet freed included:
        # code running in one goes on until it returns
        for o in 1..self.objs.len():
            if !self.obj_free[o]:
                self.gc_root_all(self.objs[o].vars)
        self.gc_mark_driver_roots()
        self.gc_root_all(self.stack)
        for c in 0..self.cells.len():
            if !self.cell_free[c]:
                self.gc_mark_cell(c)
        # driver state an efun keeps on the Vm while it calls back into LPC:
        # the verb parser's parses (verbmatch.star) and the JSON encoder's
        # containers. By the argument above nothing in them can be younger
        # than the loop, but they're cheap to cover.
        for i in 0..self.vp_ps.len():
            self.gc_root(self.vp_ps[i].env)
            self.gc_root(self.vp_ps[i].nicks)
            for j in 0..self.vp_ps[i].phrases.len():
                self.gc_root(self.vp_ps[i].phrases[j].earg)
        for i in 0..self.vp_its.len():
            let it = self.vp_its[i]
            self.gc_root(it.earg)
            self.gc_root(it.pair_refusal)
            self.gc_root_all(it.val)
            self.gc_root_all(it.memo_msg)
            for j in 0..it.pobjs.len():
                self.gc_root_all(it.pobjs[j])
            for j in 0..it.pstr_obs.len():
                self.gc_root_all(it.pstr_obs[j])
            for j in 0..it.pstr_msgs.len():
                self.gc_root_all(it.pstr_msgs[j])
        self.gc_root_all(self.jseen)
        self.gc_drain()
        let freed = self.gc_sweep(min)
        self.gc_set_budget(old + self.gc_kept)
        self.gc_reset_marks()
        self.gc_young_runs += 1
        # the evaluation limit is the LPC code's time, not the driver's
        if self.eval_deadline != (0 as i64):
            self.eval_deadline = self.eval_deadline + (clock_ms() - t0)
        freed

    # Free every unmarked array, mapping, function, class and buffer slot
    # allocated under serial `min` or later; `gc_kept` gets the size of
    # those kept, in values.
    fn gc_sweep(mut self, min: i32) -> i32:
        let mut freed = 0
        let mut kept = 0 as i64
        for h in 1..self.arrs.len():
            if self.arr_free[h] or self.arr_ser[h] < min:
                continue
            if self.gc_arr[h]:
                kept += (self.arrs[h].items.len() + 1) as i64
            else:
                self.arrs[h] = val::ArrSlot(items = List<val::Value>())
                self.arr_free[h] = true
                self.arr_free_list.push(h)
                freed += 1
        for h in 0..self.maps.len():
            if self.map_free[h] or self.map_ser[h] < min:
                continue
            if self.gc_map[h]:
                kept += (self.maps[h].keys.len() * 2 + 1) as i64
            else:
                self.maps[h] = val::MapSlot(keys = List<val::Value>(), vals = List<val::Value>(), idx = Map<val::MKey, i32>())
                self.map_free[h] = true
                self.map_free_list.push(h)
                freed += 1
        for h in 0..self.fns.len():
            if self.fn_free[h] or self.fn_ser[h] < min:
                continue
            if self.gc_fn[h]:
                kept += (self.fns[h].bound.len() + 1) as i64
            else:
                self.fns[h] = val::FnSlot(kind = 0, owner = -1, owner_gen = 0)
                self.fn_free[h] = true
                self.fn_free_list.push(h)
                freed += 1
        for h in 0..self.clss.len():
            if self.cls_free[h] or self.cls_ser[h] < min:
                continue
            if self.gc_cls[h]:
                kept += (self.clss[h].vals.len() + 1) as i64
            else:
                self.clss[h] = val::ClsSlot(name = "", vals = List<val::Value>())
                self.cls_free[h] = true
                self.cls_free_list.push(h)
                freed += 1
        for h in 0..self.bufs.len():
            if self.buf_free[h] or self.buf_ser[h] < min:
                continue
            if self.gc_buf[h]:
                kept += (self.bufs[h].data.len() / 16 + 1) as i64
            else:
                self.bufs[h] = val::BufSlot(data = Bytes())
                self.buf_free[h] = true
                self.buf_free_list.push(h)
                freed += 1
        self.gc_kept = kept
        freed

    fn gc_reset_serials(mut self):
        for h in 0..self.arr_ser.len():
            self.arr_ser[h] = 0
        for h in 0..self.map_ser.len():
            self.map_ser[h] = 0
        for h in 0..self.fn_ser.len():
            self.fn_ser[h] = 0
        for h in 0..self.cls_ser.len():
            self.cls_ser[h] = 0
        for h in 0..self.buf_ser.len():
            self.buf_ser[h] = 0
        self.ser_next = 0

    # The next collection comes once as many values have been allocated as
    # are live now (the heap doubling), but never before `gc_floor` (1M
    # values, about 16 MB); in stress mode, at the first allocation.
    fn gc_set_budget(mut self, live: i64):
        self.gc_alloc = 0 as i64
        if self.gc_stress:
            self.gc_budget = 1 as i64
        elif live > self.gc_floor:
            self.gc_budget = live
        else:
            self.gc_budget = self.gc_floor

    # Heap slots in use (all tables).
    fn heap_live(self) -> i32:
        (self.arrs.len() - self.arr_free_list.len()) + (self.maps.len() - self.map_free_list.len()) + (self.fns.len() - self.fn_free_list.len()) + (self.clss.len() - self.cls_free_list.len()) + (self.cells.len() - self.cell_free_list.len()) + (self.bufs.len() - self.buf_free_list.len())

    # Collect when the heap has doubled since the last collection, by slots
    # (past a floor where collecting isn't worth it) or by values allocated
    # (gc_set_budget()), or before the evaluation serials could run out.
    # Call between top-level evaluations.
    fn maybe_collect(mut self):
        let live = self.heap_live()
        let floor = if self.gc_live_at_last * 2 > 50000: self.gc_live_at_last * 2 else: 50000
        if live > floor or self.gc_alloc >= self.gc_budget or self.ser_next > (1 << 30):
            self.collect_garbage()

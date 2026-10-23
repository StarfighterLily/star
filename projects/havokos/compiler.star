# LPC bytecode compiler -- todo.md HavokOS M3. Turns one program's
# `ast.star` nodes into a `program.star` `Program`.
#
# This replaces `pike/lpc/emitter.pike`, which writes Pike source for
# Pike's runtime compiler; Star can't compile at runtime (NOTES.md
# "Architecture"), so the semantics the emitter delegates to Pike are made
# explicit here and in `vm.star`. The emitter still defines every decision a
# program's meaning depends on, and this file follows it function for
# function where it makes one:
#   - Call resolution order (`emit_call`): `this_object()`, a function
#     defined here or inherited (a virtual call), one only prototyped (looked
#     up by name at runtime), a simul_efun, a variable holding a function
#     (unless the name is an efun), then the efun. Efun-ness comes from the
#     reference's own name sets (`efun_names.star`).
#   - `label::f` resolution at compile time (`find_inherit`), FluffOS rules.
#   - The int <-> float assignment conversions (`static_type`,
#     `emit_assigned`, `never_float`, `pure_expr`, `COMPOUND_ARITH`): a
#     compound assignment to an int slot stays an int unless the lvalue has
#     side effects in it, in which case it's Pike's own op= (flooring `/=`).
#   - Class member positions (`member_index`), switch duplicate labels
#     (first wins), foreach variable declaration (`emit_foreach_var`).
#
# Closures. Pike lambdas -- which the emitter makes of both `(: expr :)` and
# `function(..) { .. }` -- capture enclosing locals *by reference*, so this
# does too: a local referenced from a nested closure is "boxed" into a VM
# cell at its declaration and both sides go through the cell. Which locals
# need boxing is only known once the closure body has been compiled, after
# the code before it was emitted, so a function containing a capture is
# simply compiled twice: the first pass records the captured declarations
# (by declaration order, which doesn't change between passes) and the second
# boxes them. Most functions have no captures and compile once. `$(expr)` is
# compiled into the *enclosing* function's code, so it's evaluated when the
# pointer is made, and handed to the closure as an extra cell.
#
# One deliberate difference: Pike shares one variable between every closure
# made in the same call of a function, while a cell here is made each time
# its declaration runs, so closures made in different iterations of a loop
# see different copies of a variable declared inside the loop body. No DS3.9
# code is known to depend on either behavior.
#
# Lvalues. An assignment target is a variable followed by a chain of
# `[index]`/`->member` steps. The chain is evaluated once, left to right,
# leaving each container and key on the stack (so `a[f()] += 1` calls `f`
# once, as the reference requires), the innermost store is done in place,
# and the stores ripple outwards (`OP_ISTORE_UP`) only for the one container
# that isn't shared by reference -- a string, where `s[1] = 'x'` makes a new
# string the variable must be given back. The stores report "unchanged" as
# undefined, so the base variable is only rewritten when it really changed;
# writing an unchanged array back could undo an assignment the right-hand
# side made to that variable meanwhile. Range assignment is the same chain
# with `OP_RANGE_SET` as the innermost store.

import "ast.star" as ast
import "value.star" as val
import "program.star" as pg

struct InhIn:
    id: i32
    prog: pg::Program
    path: str
    label: str

struct Local:
    name: str
    slot: i32
    typ: str
    boxed: bool
    decl: i32

struct Upval:
    kind: i32
    # UV_REF: the cell's source in the enclosing context -- one of its
    # upvalues (`from_upval`) or a boxed local slot
    from_upval: bool = false
    src: i32 = 0
    name: str = ""
    typ: str = "mixed"

struct Loop:
    is_switch: bool
    mut breaks: List<i32> = List<i32>()
    mut conts: List<i32> = List<i32>()
    catch_depth: i32

struct Ctx:
    mut code: List<i32> = List<i32>()
    mut scopes: List<Map<str, i32>> = List<Map<str, i32>>()
    mut locals: List<Local> = List<Local>()
    mut nslots: i32 = 0
    is_closure: bool = false
    is_functional: bool = false
    mut upvals: List<Upval> = List<Upval>()
    mut loops: List<Loop> = List<Loop>()
    mut catch_depth: i32 = 0

struct CaseRec:
    node: i32
    target: i32

struct SwitchCtx:
    mut cases: List<CaseRec> = List<CaseRec>()
    mut default_target: i32 = -1

enum VarRef:
    NoVar
    LocalV(slot: i32, boxed: bool, typ: str)
    UpvalV(idx: i32, typ: str)
    GlobalV(idx: i32, typ: str)

fn str_less(a: str, b: str) -> bool:
    let x = bytes_from_str(a)
    let y = bytes_from_str(b)
    let n = if x.len() < y.len(): x.len() else: y.len()
    for i in 0..n:
        let p = x[i] as i32
        let q = y[i] as i32
        if p != q:
            return p < q
    x.len() < y.len()

fn has_mod(mods: List<str>, m: str) -> bool:
    for i in 0..mods.len():
        if mods[i] == m:
            return true
    false

fn base_name_of(path: str) -> str:
    let parts = str_split(path, "/")
    parts[parts.len() - 1]

struct Compiler:
    nodes: List<ast::Node>
    files: List<str>
    vpath: str
    prog_id: i32
    inh: List<InhIn>
    sefun_names: Set<str>
    sefun_types: Map<str, str>
    is_sefun: bool
    efun_codes: Map<str, i32>
    ref_efuns: Set<str>
    known_efuns: Set<str>
    # --- declarations ---
    mut own_funcs: Map<str, i32> = Map<str, i32>()
    mut own_fn_index: Map<str, i32> = Map<str, i32>()
    mut own_vars: Map<str, i32> = Map<str, i32>()
    mut inh_funcs: Map<str, bool> = Map<str, bool>()
    mut inh_func_names: List<str> = List<str>()
    mut inh_func_types: Map<str, str> = Map<str, str>()
    mut inh_vars: Map<str, i32> = Map<str, i32>()
    mut global_types: Map<str, str> = Map<str, str>()
    mut classes: Map<str, pg::ClassDef> = Map<str, pg::ClassDef>()
    mut class_names: List<str> = List<str>()
    # --- output ---
    mut fns: List<pg::FnDef> = List<pg::FnDef>()
    mut consts: List<val::Value> = List<val::Value>()
    mut const_strs: Map<str, i32> = Map<str, i32>()
    # --- function compilation state ---
    mut ctxs: List<Ctx> = List<Ctx>()
    mut switches: List<SwitchCtx> = List<SwitchCtx>()
    mut decl_counter: i32 = 0
    mut captured: Set<i32> = Set<i32>()
    mut need_recompile: bool = false
    mut had_error: bool = false
    mut error: str = ""

impl Compiler:
    fn fail(mut self, msg: str, n: i32):
        if self.had_error:
            return
        self.had_error = true
        if n >= 0:
            let node = self.nodes[n]
            self.error = f"{self.files[node.file]}:{node.line}: {msg}"
        else:
            self.error = f"{self.vpath}.c: {msg}"

    # --- emission helpers ---------------------------------------------------

    fn top(self) -> i32:
        self.ctxs.len() - 1

    fn emit(mut self, x: i32):
        let t = self.ctxs.len() - 1
        self.ctxs[t].code.push(x)

    fn emit2(mut self, a: i32, b: i32):
        self.emit(a)
        self.emit(b)

    fn emit3(mut self, a: i32, b: i32, c: i32):
        self.emit(a)
        self.emit(b)
        self.emit(c)

    fn pos(self) -> i32:
        self.ctxs[self.ctxs.len() - 1].code.len()

    # emit a jump-like op with a placeholder target; returns the operand index
    fn emit_jump(mut self, op: i32) -> i32:
        self.emit(op)
        let at = self.pos()
        self.emit(-1)
        at

    fn patch(mut self, at: i32, target: i32):
        let t = self.ctxs.len() - 1
        self.ctxs[t].code[at] = target

    fn patch_here(mut self, at: i32):
        let p = self.pos()
        self.patch(at, p)

    fn konst(mut self, v: val::Value) -> i32:
        let k = self.consts.len()
        self.consts.push(v)
        k

    fn kstr(mut self, s: str) -> i32:
        if let Option::Some(k) = self.const_strs.get(s):
            return k
        let k = self.konst(val::Value::Str(s))
        self.const_strs.insert(s, k)
        k

    fn push_int(mut self, v: i64):
        let lo = (0 as i64) - (2147483647 as i64)
        if v >= lo and v <= (2147483647 as i64):
            self.emit2(pg::OP_PUSH_INT, v as i32)
        else:
            let k = self.konst(val::Value::Int(v))
            self.emit2(pg::OP_PUSH_CONST, k)

    fn new_slot(mut self) -> i32:
        let t = self.ctxs.len() - 1
        let s = self.ctxs[t].nslots
        self.ctxs[t].nslots = s + 1
        s

    fn push_scope(mut self):
        let t = self.ctxs.len() - 1
        self.ctxs[t].scopes.push(Map<str, i32>())

    fn pop_scope(mut self):
        let t = self.ctxs.len() - 1
        self.ctxs[t].scopes.pop()

    # Declare a local in the innermost scope; returns its slot.
    fn declare(mut self, name: str, typ: str) -> i32:
        let t = self.ctxs.len() - 1
        let slot = self.new_slot()
        let decl = self.decl_counter
        self.decl_counter = decl + 1
        let boxed = self.captured.contains(decl)
        let li = self.ctxs[t].locals.len()
        self.ctxs[t].locals.push(Local(name = name, slot = slot, typ = typ, boxed = boxed, decl = decl))
        let sc = self.ctxs[t].scopes.len() - 1
        self.ctxs[t].scopes[sc].insert(name, li)
        slot

    fn local_boxed(self, slot: i32) -> bool:
        let c = self.ctxs[self.ctxs.len() - 1]
        for i in 0..c.locals.len():
            if c.locals[i].slot == slot:
                return c.locals[i].boxed
        false

    # --- name resolution ----------------------------------------------------

    fn find_local(self, level: i32, name: str) -> i32:
        let c = self.ctxs[level]
        let mut i = c.scopes.len() - 1
        while i >= 0:
            if let Option::Some(li) = c.scopes[i].get(name):
                return li
            i -= 1
        -1

    fn resolve_in(mut self, level: i32, name: str) -> VarRef:
        let li = self.find_local(level, name)
        if li >= 0:
            let l = self.ctxs[level].locals[li]
            return VarRef::LocalV(slot = l.slot, boxed = l.boxed, typ = l.typ)
        if level == 0 or !self.ctxs[level].is_closure:
            return VarRef::NoVar
        let ups = self.ctxs[level].upvals
        for i in 0..ups.len():
            if ups[i].kind == pg::UV_REF and ups[i].name == name:
                return VarRef::UpvalV(idx = i, typ = ups[i].typ)
        let parent = self.resolve_in(level - 1, name)
        match parent:
            VarRef::LocalV(slot, boxed, typ) ->
                let pli = self.find_local(level - 1, name)
                let decl = self.ctxs[level - 1].locals[pli].decl
                self.captured.insert(decl)
                if !boxed:
                    self.need_recompile = true
                let idx = self.ctxs[level].upvals.len()
                self.ctxs[level].upvals.push(Upval(kind = pg::UV_REF, from_upval = false, src = slot, name = name, typ = typ))
                VarRef::UpvalV(idx = idx, typ = typ)
            VarRef::UpvalV(pidx, typ) ->
                let idx = self.ctxs[level].upvals.len()
                self.ctxs[level].upvals.push(Upval(kind = pg::UV_REF, from_upval = true, src = pidx, name = name, typ = typ))
                VarRef::UpvalV(idx = idx, typ = typ)
            _ -> VarRef::NoVar

    fn global_index(self, name: str) -> i32:
        if let Option::Some(i) = self.own_vars.get(name):
            return i
        if let Option::Some(i) = self.inh_vars.get(name):
            return i
        -1

    fn resolve_var(mut self, name: str) -> VarRef:
        let r = self.resolve_in(self.ctxs.len() - 1, name)
        match r:
            VarRef::NoVar ->
                let g = self.global_index(name)
                if g >= 0:
                    return VarRef::GlobalV(idx = g, typ = self.global_type(name))
                VarRef::NoVar
            _ -> r

    fn is_var(mut self, name: str) -> bool:
        match self.resolve_var(name):
            VarRef::NoVar -> false
            _ -> true

    fn global_type(self, name: str) -> str:
        if let Option::Some(t) = self.global_types.get(name):
            return t
        "mixed"

    fn emit_load(mut self, r: VarRef):
        match r:
            VarRef::LocalV(slot, boxed, typ) ->
                if boxed:
                    self.emit2(pg::OP_LOAD_CELL, slot)
                else:
                    self.emit2(pg::OP_LOAD_LOCAL, slot)
            VarRef::UpvalV(idx, typ) -> self.emit2(pg::OP_LOAD_UPVAL, idx)
            VarRef::GlobalV(idx, typ) -> self.emit2(pg::OP_LOAD_GLOBAL, idx)
            VarRef::NoVar -> self.emit(pg::OP_PUSH_UNDEF)

    fn emit_store(mut self, r: VarRef):
        match r:
            VarRef::LocalV(slot, boxed, typ) ->
                if boxed:
                    self.emit2(pg::OP_STORE_CELL, slot)
                else:
                    self.emit2(pg::OP_STORE_LOCAL, slot)
            VarRef::UpvalV(idx, typ) -> self.emit2(pg::OP_STORE_UPVAL, idx)
            VarRef::GlobalV(idx, typ) -> self.emit2(pg::OP_STORE_GLOBAL, idx)
            VarRef::NoVar -> self.emit(pg::OP_POP)

    # "def" (true), "proto" (false), or none -- the emitter's func_kind()
    fn func_kind(self, name: str) -> i32:
        if let Option::Some(_n) = self.own_fn_index.get(name):
            return 2
        if let Option::Some(d) = self.inh_funcs.get(name):
            if d:
                return 2
            return 1
        if let Option::Some(_f) = self.own_funcs.get(name):
            return 1
        0

    fn own_private(self, name: str) -> bool:
        if let Option::Some(n) = self.own_funcs.get(name):
            match self.nodes[n].kind:
                ast::NodeKind::Func(nm, mods, typ, params, body) ->
                    return has_mod(mods, "private")
                _ ->
                    return false
        false

    fn is_sefun_name(self, name: str) -> bool:
        !self.is_sefun and self.sefun_names.contains(name)

    fn is_efun_name(self, name: str) -> bool:
        self.ref_efuns.contains(name)

    fn efun_code(self, name: str) -> i32:
        if let Option::Some(c) = self.efun_codes.get(name):
            return c
        0

    # The inherit `label::name` refers to (the emitter's find_inherit);
    # -1 for none. "" matches any inherit (the first defining `name`).
    fn find_inherit(self, label: str, name: str) -> i32:
        for i in 0..self.inh.len():
            let h = self.inh[i]
            if label != "":
                let p = h.path
                let full = concat("/", label)
                if !(p == full or str_ends_with(p, full) or h.label == label):
                    continue
            if let Option::Some(_d) = h.prog.all_funcs.get(name):
                return i
            if label != "":
                return i
        -1

    # --- static types (the emitter's view, for int <-> float conversion) ---

    fn call_type(mut self, name: str, args: List<i32>) -> str:
        if self.func_kind(name) > 0:
            if let Option::Some(n) = self.own_funcs.get(name):
                match self.nodes[n].kind:
                    ast::NodeKind::Func(nm, mods, typ, params, body) ->
                        return typ
                    _ ->
                        return "mixed"
            if let Option::Some(t) = self.inh_func_types.get(name):
                return t
            return "mixed"
        if self.is_sefun_name(name):
            if let Option::Some(t) = self.sefun_types.get(name):
                return t
            return "mixed"
        if !self.is_efun_name(name) and !self.known_efuns.contains(name) and self.is_var(name):
            return "mixed"
        if name == "to_float" or name == "sqrt" or name == "exp" or name == "log" or name == "pow" or name == "sin" or name == "cos" or name == "tan" or name == "asin" or name == "acos" or name == "atan" or name == "floor" or name == "ceil" or name == "angle" or name == "distance" or name == "norm" or name == "dotprod":
            return "float"
        if is_int_efun(name):
            return "int"
        if name == "abs" and args.len() == 1:
            return self.static_type(args[0])
        "mixed"

    fn static_type(mut self, e: i32) -> str:
        match self.nodes[e].kind:
            ast::NodeKind::LitInt(v) -> "int"
            ast::NodeKind::LitFloat(v) -> "float"
            ast::NodeKind::LitStr(v) -> "string"
            ast::NodeKind::Id(name) ->
                match self.resolve_var(name):
                    VarRef::LocalV(slot, boxed, typ) -> typ
                    VarRef::UpvalV(idx, typ) -> typ
                    _ -> self.global_type(name)
            ast::NodeKind::Paren(x) -> self.static_type(x)
            ast::NodeKind::Cast(typ, x) -> typ
            ast::NodeKind::Index(x, i, fe) ->
                let t = self.static_type(x)
                if t == "string":
                    return "int"
                if str_ends_with(t, "*"):
                    let b = bytes_from_str(t)
                    let mut o: Bytes = Bytes()
                    for j in 0..b.len() - 1:
                        o.push(b[j])
                    return str_from_bytes(o)
                "mixed"
            ast::NodeKind::Member(obj, name) ->
                let t = self.static_type(obj)
                if str_starts_with(t, "class ") and !str_ends_with(t, "*"):
                    let cname = str_replace(t, "class ", "")
                    if let Option::Some(c) = self.classes.get(cname):
                        for j in 0..c.members.len():
                            if c.members[j] == name:
                                if j < c.types.len():
                                    return c.types[j]
                                return "mixed"
                "mixed"
            ast::NodeKind::Assign(op, l, r) ->
                let lt = self.static_type(l)
                if op == "=" and lt == "mixed":
                    return self.static_type(r)
                lt
            ast::NodeKind::Un(op, x) ->
                if op == "!" or op == "~":
                    return "int"
                self.static_type(x)
            ast::NodeKind::Post(op, x) -> self.static_type(x)
            ast::NodeKind::Bin(op, l, r) ->
                if op == "==" or op == "!=" or op == "<" or op == ">" or op == "<=" or op == ">=":
                    return "int"
                if op == "+" or op == "-" or op == "*" or op == "/" or op == "%" or op == "&" or op == "|" or op == "^" or op == "<<" or op == ">>":
                    let lt = self.static_type(l)
                    let rt = self.static_type(r)
                    if op == "+" and (lt == "string" or rt == "string"):
                        return "string"
                    if lt == "int" and rt == "int":
                        return "int"
                    if (op == "+" or op == "-" or op == "*" or op == "/") and (lt == "int" or lt == "float") and (rt == "int" or rt == "float"):
                        return "float"
                    return "mixed"
                "mixed"
            ast::NodeKind::Cond(c, a, b) ->
                let at = self.static_type(a)
                if at == self.static_type(b):
                    return at
                "mixed"
            ast::NodeKind::Call(name, args) -> self.call_type(name, args)
            ast::NodeKind::Scall(label, name, args, is_ref) ->
                if label != "efun":
                    if let Option::Some(t) = self.inh_func_types.get(name):
                        return t
                "mixed"
            ast::NodeKind::Sscanf(args) -> "int"
            ast::NodeKind::TimeExpr(x, b) -> "int"
            ast::NodeKind::NewClass(name, fields, values) -> concat("class ", name)
            _ -> "mixed"

    fn never_float(self, e: i32) -> bool:
        match self.nodes[e].kind:
            ast::NodeKind::LitFloat(v) -> false
            ast::NodeKind::LitInt(v) -> true
            ast::NodeKind::LitStr(v) -> true
            ast::NodeKind::LitOpen -> true
            ast::NodeKind::Arr(i) -> true
            ast::NodeKind::Map(p) -> true
            ast::NodeKind::FptrName(a, b) -> true
            ast::NodeKind::FptrScoped(a, b, c) -> true
            ast::NodeKind::FptrExpr(a) -> true
            ast::NodeKind::Lambda(a, b) -> true
            ast::NodeKind::New(a) -> true
            ast::NodeKind::NewClass(a, b, c) -> true
            ast::NodeKind::Paren(x) -> self.never_float(x)
            ast::NodeKind::Cast(typ, x) -> typ == "int" or typ == "string" or self.never_float(x)
            ast::NodeKind::Cond(c, a, b) -> self.never_float(a) and self.never_float(b)
            ast::NodeKind::Bin(op, l, r) -> op == "+" and (self.is_str_lit(l) or self.is_str_lit(r))
            ast::NodeKind::Call(name, args) -> is_nonfloat_efun(name) and self.func_kind(name) == 0
            _ -> false

    fn is_str_lit(self, e: i32) -> bool:
        match self.nodes[e].kind:
            ast::NodeKind::LitStr(v) -> true
            _ -> false

    fn pure_expr(self, e: i32) -> bool:
        match self.nodes[e].kind:
            ast::NodeKind::LitInt(v) -> true
            ast::NodeKind::LitFloat(v) -> true
            ast::NodeKind::LitStr(v) -> true
            ast::NodeKind::LitOpen -> true
            ast::NodeKind::Id(n) -> true
            ast::NodeKind::Paren(x) -> self.pure_expr(x)
            ast::NodeKind::Member(obj, n) -> self.pure_expr(obj)
            ast::NodeKind::Index(x, i, fe) -> self.pure_expr(x) and self.pure_expr(i)
            ast::NodeKind::Un(op, x) -> op != "++" and op != "--" and self.pure_expr(x)
            ast::NodeKind::Bin(op, l, r) -> self.pure_expr(l) and self.pure_expr(r)
            ast::NodeKind::Cond(c, a, b) -> self.pure_expr(c) and self.pure_expr(a) and self.pure_expr(b)
            ast::NodeKind::Cast(t, x) -> self.pure_expr(x)
            _ -> false

    # Position of `member` in the class value `obj` (FluffOS: the declared
    # class if known, otherwise the first class in scope, by name, that has it).
    fn member_index(mut self, obj: i32, member: str, n: i32) -> i32:
        let t = self.static_type(obj)
        if str_starts_with(t, "class ") and !str_ends_with(t, "*"):
            let cname = str_replace(t, "class ", "")
            if let Option::Some(c) = self.classes.get(cname):
                for j in 0..c.members.len():
                    if c.members[j] == member:
                        return j
        for i in 0..self.class_names.len():
            if let Option::Some(c) = self.classes.get(self.class_names[i]):
                for j in 0..c.members.len():
                    if c.members[j] == member:
                        return j
        self.fail(f"No class in scope has member '{member}'", n)
        0

    # Emit `e` as a value assigned to something declared `target`.
    fn emit_assigned(mut self, e: i32, target: str):
        if target == "int" or target == "float":
            let from = self.static_type(e)
            if target == "int" and from == "float":
                match self.nodes[e].kind:
                    ast::NodeKind::LitFloat(v) ->
                        self.push_int(v as i64)
                        return
                    _ ->
                        self.expr(e)
                        self.emit2(pg::OP_CONV, pg::CONV_F2I)
                        return
            if target == "float" and from == "int":
                match self.nodes[e].kind:
                    ast::NodeKind::LitInt(v) ->
                        let k = self.konst(val::Value::Real(v as f64))
                        self.emit2(pg::OP_PUSH_CONST, k)
                        return
                    _ ->
                        self.expr(e)
                        self.emit2(pg::OP_CONV, pg::CONV_I2F)
                        return
        self.expr(e)

    # --- program -------------------------------------------------------------

    fn compile_program(mut self, top: List<i32>) -> pg::Program:
        let mut prog = pg::Program(path = self.vpath)
        # Pass 1: declarations
        let mut funcs: List<i32> = List<i32>()
        let mut var_nodes: List<i32> = List<i32>()
        for i in 0..top.len():
            let n = top[i]
            match self.nodes[n].kind:
                ast::NodeKind::Func(name, mods, typ, params, body) ->
                    let mut take = true
                    if let Option::Some(prev) = self.own_funcs.get(name):
                        match self.nodes[prev].kind:
                            ast::NodeKind::Func(a, b, c, d, pbody) ->
                                take = pbody < 0
                            _ ->
                                take = true
                    if take:
                        self.own_funcs.insert(name, n)
                    if body >= 0:
                        funcs.push(n)
                ast::NodeKind::Var(mods, decls) -> var_nodes.push(n)
                ast::NodeKind::Class(name, mods, members, types) ->
                    if !self.classes.contains(name):
                        self.class_names.push(name)
                    self.classes.insert(name, pg::ClassDef(name = name, members = members, types = types))
                _ -> 0
        # inherits: variable layout, visible names, tables
        let mut off = 0
        for i in 0..self.inh.len():
            let h = self.inh[i]
            prog.inherits.push(pg::InheritInfo(prog = h.id, path = h.path, label = h.label, var_off = off))
            let p = h.prog
            for j in 0..p.all_func_names.len():
                let f = p.all_func_names[j]
                if let Option::Some(d) = p.all_funcs.get(f):
                    let mut known = false
                    let mut cur = false
                    if let Option::Some(c) = self.inh_funcs.get(f):
                        known = true
                        cur = c
                    if !known:
                        self.inh_func_names.push(f)
                    if !cur:
                        self.inh_funcs.insert(f, d)
            for j in 0..p.all_var_names.len():
                let v = p.all_var_names[j]
                if let Option::Some(rel) = p.all_vars.get(v):
                    self.inh_vars.insert(v, off + rel)
            for j in 0..p.class_names.len():
                let cn = p.class_names[j]
                if !self.classes.contains(cn):
                    if let Option::Some(c) = p.classes.get(cn):
                        self.classes.insert(cn, c)
                        self.class_names.push(cn)
            for j in 0..p.all_var_names.len():
                let v = p.all_var_names[j]
                if !self.global_types.contains(v):
                    if let Option::Some(t) = p.global_types.get(v):
                        self.global_types.insert(v, t)
            for j in 0..p.all_func_names.len():
                let f = p.all_func_names[j]
                if !self.inh_func_types.contains(f):
                    if let Option::Some(t) = p.func_types.get(f):
                        self.inh_func_types.insert(f, t)
            off += p.nvars
        prog.own_var_start = off
        # own variables (a repeated name keeps its first slot)
        let mut var_order: List<i32> = List<i32>()
        for i in 0..var_nodes.len():
            match self.nodes[var_nodes[i]].kind:
                ast::NodeKind::Var(mods, decls) ->
                    for j in 0..decls.len():
                        match self.nodes[decls[j]].kind:
                            ast::NodeKind::Decl(name, typ, init) ->
                                self.global_types.insert(name, typ)
                                if !self.own_vars.contains(name):
                                    self.own_vars.insert(name, off + prog.var_names.len())
                                    prog.var_names.push(name)
                                    prog.var_nosave.push(has_mod(mods, "static") or has_mod(mods, "nosave"))
                                    var_order.push(decls[j])
                            _ -> 0
                _ -> 0
        prog.nvars = off + prog.var_names.len()
        # sort class names (member_index's fallback walks them in name order)
        let mut cn = self.class_names
        let mut a = 1
        while a < cn.len():
            let x = cn[a]
            let mut b = a - 1
            while b >= 0 and str_less(x, cn[b]):
                cn[b + 1] = cn[b]
                b -= 1
            cn[b + 1] = x
            a += 1
        self.class_names = cn
        # function slots: own definitions first, so their indices are fixed
        for i in 0..funcs.len():
            match self.nodes[funcs[i]].kind:
                ast::NodeKind::Func(name, mods, typ, params, body) ->
                    if !self.own_fn_index.contains(name):
                        self.own_fn_index.insert(name, self.fns.len())
                        self.fns.push(pg::FnDef(name = name))
                _ -> 0
        let init_idx = self.fns.len()
        self.fns.push(pg::FnDef(name = "__INIT"))
        # bodies: the first definition of each name (the emitter's own_funcs)
        let mut done: Set<str> = Set<str>()
        for i in 0..funcs.len():
            match self.nodes[funcs[i]].kind:
                ast::NodeKind::Func(name, mods, typ, params, body) ->
                    if !done.contains(name):
                        done.insert(name)
                        if let Option::Some(fi) = self.own_fn_index.get(name):
                            let d = self.compile_function(funcs[i])
                            self.fns[fi] = d
                _ -> 0
        let init = self.compile_init(var_order)
        self.fns[init_idx] = init
        prog.init_fn = init_idx
        # tables
        self.build_tables(prog)

    fn build_tables(mut self, prog_in: pg::Program) -> pg::Program:
        let mut prog = prog_in
        prog.fns = self.fns
        prog.consts = self.consts
        # vt: inherits in order (later wins), then own non-private definitions
        for i in 0..self.inh.len():
            let h = self.inh[i]
            let off = prog.inherits[i].var_off
            for j in 0..h.prog.all_func_names.len():
                let f = h.prog.all_func_names[j]
                if let Option::Some(e) = h.prog.vt.get(f):
                    prog.vt.insert(f, pg::DispEntry(prog = e.prog, fnidx = e.fnidx, var_off = e.var_off + off, is_static = e.is_static))
        # anyt: own definitions (private too), then inherits in order
        for i in 0..self.nodes.len():
            match self.nodes[i].kind:
                ast::NodeKind::Func(name, mods, typ, params, body) ->
                    if body >= 0:
                        if let Option::Some(fi) = self.own_fn_index.get(name):
                            if !prog.anyt.contains(name):
                                let is_st = has_mod(mods, "static") or has_mod(mods, "protected")
                                let e = pg::DispEntry(prog = self.prog_id, fnidx = fi, var_off = 0, is_static = is_st or has_mod(mods, "private"))
                                prog.anyt.insert(name, e)
                                prog.anyt_names.push(name)
                                if !has_mod(mods, "private"):
                                    prog.vt.insert(name, e)
                _ -> 0
        for i in 0..self.inh.len():
            let h = self.inh[i]
            let off = prog.inherits[i].var_off
            let names = h.prog.anyt_names
            for j in 0..names.len():
                let f = names[j]
                if !prog.anyt.contains(f):
                    if let Option::Some(e) = h.prog.anyt.get(f):
                        prog.anyt.insert(f, pg::DispEntry(prog = e.prog, fnidx = e.fnidx, var_off = e.var_off + off, is_static = e.is_static))
                        prog.anyt_names.push(f)
        # meta for inheritors
        for i in 0..self.inh_func_names.len():
            let f = self.inh_func_names[i]
            if let Option::Some(d) = self.inh_funcs.get(f):
                prog.all_funcs.insert(f, d)
                prog.all_func_names.push(f)
        let mut ft = self.inh_func_types
        let own_list = self.own_func_list()
        for i in 0..own_list.len():
            let n = own_list[i]
            match self.nodes[n].kind:
                ast::NodeKind::Func(name, mods, typ, params, body) ->
                    if !has_mod(mods, "private"):
                        ft.insert(name, typ)
                        let mut known = false
                        let mut cur = false
                        if let Option::Some(c) = prog.all_funcs.get(name):
                            known = true
                            cur = c
                        if !known:
                            prog.all_func_names.push(name)
                        if body >= 0 or self.own_fn_index.contains(name):
                            prog.all_funcs.insert(name, true)
                        elif !known:
                            prog.all_funcs.insert(name, false)
                _ -> 0
        prog.func_types = ft
        # variables visible to inheritors: inherited (non-private), own non-private
        let names_inh = self.inh_var_names()
        for i in 0..names_inh.len():
            let v = names_inh[i]
            if let Option::Some(rel) = self.inh_vars.get(v):
                prog.all_vars.insert(v, rel)
                prog.all_var_names.push(v)
        for i in 0..self.nodes.len():
            match self.nodes[i].kind:
                ast::NodeKind::Var(mods, decls) ->
                    if !has_mod(mods, "private"):
                        for j in 0..decls.len():
                            match self.nodes[decls[j]].kind:
                                ast::NodeKind::Decl(name, typ, init) ->
                                    if let Option::Some(rel) = self.own_vars.get(name):
                                        if !prog.all_vars.contains(name):
                                            prog.all_var_names.push(name)
                                        prog.all_vars.insert(name, rel)
                                _ -> 0
                _ -> 0
        prog.global_types = self.global_types
        prog.classes = self.classes
        prog.class_names = self.class_names
        prog

    # own functions, one node per name (the one own_funcs chose)
    fn own_func_list(self) -> List<i32>:
        let mut out: List<i32> = List<i32>()
        let mut seen: Set<str> = Set<str>()
        for i in 0..self.nodes.len():
            match self.nodes[i].kind:
                ast::NodeKind::Func(name, mods, typ, params, body) ->
                    if !seen.contains(name):
                        seen.insert(name)
                        if let Option::Some(n) = self.own_funcs.get(name):
                            out.push(n)
                _ -> 0
        out

    fn inh_var_names(self) -> List<str>:
        let mut out: List<str> = List<str>()
        let mut seen: Set<str> = Set<str>()
        for i in 0..self.inh.len():
            let p = self.inh[i].prog
            for j in 0..p.all_var_names.len():
                let v = p.all_var_names[j]
                if !seen.contains(v):
                    seen.insert(v)
                    out.push(v)
        out

    # --- functions -------------------------------------------------------------

    fn begin_ctx(mut self, is_closure: bool, is_functional: bool):
        let mut c = Ctx(is_closure = is_closure, is_functional = is_functional)
        c.scopes.push(Map<str, i32>())
        self.ctxs.push(c)

    fn end_ctx(mut self) -> Ctx:
        let c = self.ctxs[self.ctxs.len() - 1]
        self.ctxs.pop()
        c

    fn compile_function(mut self, fnode: i32) -> pg::FnDef:
        let saved = self.fns.len()
        self.captured = Set<i32>()
        let mut d = pg::FnDef(name = "")
        let mut pass = 0
        while pass < 3:
            while self.fns.len() > saved:
                self.fns.pop()
            self.decl_counter = 0
            self.need_recompile = false
            d = self.compile_function_once(fnode)
            if !self.need_recompile:
                break
            pass += 1
        d

    fn declare_params(mut self, params: List<i32>) -> List<i32>:
        let mut cells: List<i32> = List<i32>()
        for i in 0..params.len():
            match self.nodes[params[i]].kind:
                ast::NodeKind::Param(typ, name, is_ref, varargs, default) ->
                    if name != "":
                        let s = self.declare(name, typ)
                        if self.local_boxed(s):
                            cells.push(s)
                    else:
                        self.new_slot()
                _ -> 0
        cells

    fn param_defaults(mut self, params: List<i32>):
        for i in 0..params.len():
            match self.nodes[params[i]].kind:
                ast::NodeKind::Param(typ, name, is_ref, varargs, default) ->
                    if default >= 0 and name != "":
                        let r = self.resolve_var(name)
                        self.emit_load(r)
                        let k = self.kstr("undefinedp")
                        self.emit(pg::OP_CALL_EFUN)
                        self.emit3(self.efun_code("undefinedp"), k, 1)
                        let skip = self.emit_jump(pg::OP_JZ)
                        self.expr(default)
                        self.emit(pg::OP_EVAL_DEFAULT)
                        self.emit_store(r)
                        self.patch_here(skip)
                _ -> 0

    fn is_varargs(self, params: List<i32>) -> bool:
        if params.len() == 0:
            return false
        match self.nodes[params[params.len() - 1]].kind:
            ast::NodeKind::Param(typ, name, is_ref, varargs, default) -> varargs
            _ -> false

    fn compile_function_once(mut self, fnode: i32) -> pg::FnDef:
        match self.nodes[fnode].kind:
            ast::NodeKind::Func(name, mods, typ, params, body) ->
                self.begin_ctx(false, false)
                let cells = self.declare_params(params)
                self.param_defaults(params)
                self.block_body(body)
                self.emit2(pg::OP_PUSH_INT, 0)
                self.emit(pg::OP_RET)
                let c = self.end_ctx()
                let is_st = has_mod(mods, "static") or has_mod(mods, "protected")
                pg::FnDef(name = name, typ = typ, nparams = params.len(), varargs = self.is_varargs(params), nlocals = c.nslots, code = c.code, cell_params = cells, is_static = is_st, is_private = has_mod(mods, "private"))
            _ -> pg::FnDef(name = "?")

    fn compile_init(mut self, decls: List<i32>) -> pg::FnDef:
        let saved = self.fns.len()
        self.captured = Set<i32>()
        let mut d = pg::FnDef(name = "__INIT")
        let mut pass = 0
        while pass < 3:
            while self.fns.len() > saved:
                self.fns.pop()
            self.decl_counter = 0
            self.need_recompile = false
            self.begin_ctx(false, false)
            for i in 0..decls.len():
                match self.nodes[decls[i]].kind:
                    ast::NodeKind::Decl(name, typ, init) ->
                        if init >= 0:
                            self.emit_assigned(init, typ)
                            if let Option::Some(g) = self.own_vars.get(name):
                                self.emit2(pg::OP_STORE_GLOBAL, g)
                    _ -> 0
            self.emit2(pg::OP_PUSH_INT, 0)
            self.emit(pg::OP_RET)
            let c = self.end_ctx()
            d = pg::FnDef(name = "__INIT", nlocals = c.nslots, code = c.code)
            if !self.need_recompile:
                break
            pass += 1
        d

    # --- statements -------------------------------------------------------------

    fn block_body(mut self, b: i32):
        match self.nodes[b].kind:
            ast::NodeKind::Block(stmts) ->
                self.push_scope()
                for i in 0..stmts.len():
                    self.stmt(stmts[i])
                self.pop_scope()
            _ -> self.stmt(b)

    # a statement used as the body of if/while/for: its own scope
    fn sub(mut self, s: i32):
        self.push_scope()
        self.stmt(s)
        self.pop_scope()

    fn decls(mut self, ds: List<i32>):
        for i in 0..ds.len():
            match self.nodes[ds[i]].kind:
                ast::NodeKind::Decl(name, typ, init) ->
                    if init >= 0:
                        self.emit_assigned(init, typ)
                    else:
                        self.emit(pg::OP_PUSH_UNDEF)
                    let s = self.declare(name, typ)
                    self.emit2(pg::OP_STORE_LOCAL, s)
                    if self.local_boxed(s):
                        self.emit2(pg::OP_MKCELL, s)
                _ -> 0

    fn push_loop(mut self, is_switch: bool):
        let t = self.ctxs.len() - 1
        let cd = self.ctxs[t].catch_depth
        self.ctxs[t].loops.push(Loop(is_switch = is_switch, catch_depth = cd))

    fn pop_loop(mut self, brk: i32, cont: i32):
        let t = self.ctxs.len() - 1
        let l = self.ctxs[t].loops[self.ctxs[t].loops.len() - 1]
        for i in 0..l.breaks.len():
            self.patch(l.breaks[i], brk)
        for i in 0..l.conts.len():
            self.patch(l.conts[i], cont)
        self.ctxs[t].loops.pop()

    fn stmt(mut self, s: i32):
        if self.had_error:
            return
        match self.nodes[s].kind:
            ast::NodeKind::Block(stmts) -> self.block_body(s)
            ast::NodeKind::Empty -> 0
            ast::NodeKind::Ldecl(ds) -> self.decls(ds)
            ast::NodeKind::ExprStmt(e) -> self.expr_discard(e)
            ast::NodeKind::If(cond, then, els) ->
                self.expr(cond)
                let j = self.emit_jump(pg::OP_JZ)
                self.sub(then)
                if els >= 0:
                    let j2 = self.emit_jump(pg::OP_JMP)
                    self.patch_here(j)
                    self.sub(els)
                    self.patch_here(j2)
                else:
                    self.patch_here(j)
            ast::NodeKind::While(cond, body) ->
                let top = self.pos()
                self.expr(cond)
                let j = self.emit_jump(pg::OP_JZ)
                self.push_loop(false)
                self.sub(body)
                self.emit2(pg::OP_JMP, top)
                let end = self.pos()
                self.pop_loop(end, top)
                self.patch(j, end)
            ast::NodeKind::Do(cond, body) ->
                let top = self.pos()
                self.push_loop(false)
                self.sub(body)
                let cont = self.pos()
                self.expr(cond)
                self.emit2(pg::OP_JNZ, top)
                let end = self.pos()
                self.pop_loop(end, cont)
            ast::NodeKind::For(init, cond, step, body) ->
                self.push_scope()
                if init >= 0:
                    match self.nodes[init].kind:
                        ast::NodeKind::Ldecl(ds) -> self.decls(ds)
                        ast::NodeKind::ExprStmt(e) -> self.expr_discard(e)
                        _ -> self.expr_discard(init)
                let top = self.pos()
                let mut j = -1
                if cond >= 0:
                    self.expr(cond)
                    j = self.emit_jump(pg::OP_JZ)
                self.push_loop(false)
                self.sub(body)
                let cont = self.pos()
                if step >= 0:
                    self.expr_discard(step)
                self.emit2(pg::OP_JMP, top)
                let end = self.pos()
                self.pop_loop(end, cont)
                if j >= 0:
                    self.patch(j, end)
                self.pop_scope()
            ast::NodeKind::Foreach(vars, e, body) -> self.foreach_stmt(vars, e, body)
            ast::NodeKind::Switch(e, body) -> self.switch_stmt(e, body)
            ast::NodeKind::Case(lo, hi, open_lo) ->
                if self.switches.len() == 0:
                    self.fail("case outside of switch", s)
                    return
                let si = self.switches.len() - 1
                let p = self.pos()
                self.switches[si].cases.push(CaseRec(node = s, target = p))
            ast::NodeKind::Default ->
                if self.switches.len() == 0:
                    self.fail("default outside of switch", s)
                    return
                let si = self.switches.len() - 1
                if self.switches[si].default_target < 0:
                    self.switches[si].default_target = self.pos()
            ast::NodeKind::Break -> self.break_continue(true, s)
            ast::NodeKind::Continue -> self.break_continue(false, s)
            ast::NodeKind::Return(e) ->
                if e >= 0:
                    self.expr(e)
                else:
                    self.emit2(pg::OP_PUSH_INT, 0)
                self.emit(pg::OP_RET)
            _ -> self.fail("Unknown statement kind", s)

    fn break_continue(mut self, is_break: bool, s: i32):
        let t = self.ctxs.len() - 1
        let mut li = self.ctxs[t].loops.len() - 1
        if !is_break:
            while li >= 0 and self.ctxs[t].loops[li].is_switch:
                li -= 1
        if li < 0:
            self.fail(if is_break: "break outside of loop or switch" else: "continue outside of loop", s)
            return
        let drop = self.ctxs[t].catch_depth - self.ctxs[t].loops[li].catch_depth
        for i in 0..drop:
            self.emit(pg::OP_CATCH_END)
        let at = self.emit_jump(pg::OP_JMP)
        if is_break:
            self.ctxs[t].loops[li].breaks.push(at)
        else:
            self.ctxs[t].loops[li].conts.push(at)

    fn foreach_target(mut self, v: i32) -> VarRef:
        match self.nodes[v].kind:
            ast::NodeKind::FeVar(name, typ) ->
                if typ != "" or !self.is_var(name):
                    let ty = if typ == "": "mixed" else: typ
                    let s = self.declare(name, ty)
                    return VarRef::LocalV(slot = s, boxed = self.local_boxed(s), typ = ty)
                self.resolve_var(name)
            _ -> VarRef::NoVar

    fn store_fe(mut self, r: VarRef):
        match r:
            VarRef::LocalV(slot, boxed, typ) ->
                if boxed:
                    # a fresh cell each iteration, as a declaration would make
                    self.emit2(pg::OP_STORE_LOCAL, slot)
                    self.emit2(pg::OP_MKCELL, slot)
                else:
                    self.emit2(pg::OP_STORE_LOCAL, slot)
            _ -> self.emit_store(r)

    fn foreach_stmt(mut self, vars: List<i32>, e: i32, body: i32):
        self.push_scope()
        self.expr(e)
        let st = self.new_slot()
        self.new_slot()
        self.new_slot()
        let n = vars.len()
        self.emit3(pg::OP_FE_INIT, n, st)
        let v1 = self.foreach_target(vars[0])
        let mut v2 = VarRef::NoVar
        if n > 1:
            v2 = self.foreach_target(vars[1])
        let top = self.pos()
        self.emit3(pg::OP_FE_NEXT, n, st)
        let jend = self.pos()
        self.emit(-1)
        if n > 1:
            self.store_fe(v2)
        self.store_fe(v1)
        self.push_loop(false)
        self.sub(body)
        self.emit2(pg::OP_JMP, top)
        let end = self.pos()
        self.pop_loop(end, top)
        self.patch(jend, end)
        self.pop_scope()

    fn switch_stmt(mut self, e: i32, body: i32):
        self.expr(e)
        let hs = self.new_slot()
        self.emit2(pg::OP_STORE_LOCAL, hs)
        let jd = self.emit_jump(pg::OP_JMP)
        self.switches.push(SwitchCtx())
        self.push_loop(true)
        self.block_body(body)
        let jend = self.emit_jump(pg::OP_JMP)
        # dispatch: every label in source order, first match wins
        self.patch_here(jd)
        let sw = self.switches[self.switches.len() - 1]
        for i in 0..sw.cases.len():
            let c = sw.cases[i]
            match self.nodes[c.node].kind:
                ast::NodeKind::Case(lo, hi, open_lo) ->
                    let mut hi_open = hi < 0
                    if hi >= 0:
                        match self.nodes[hi].kind:
                            ast::NodeKind::LitOpen ->
                                hi_open = true
                            _ ->
                                hi_open = false
                    if open_lo:
                        self.emit2(pg::OP_LOAD_LOCAL, hs)
                        self.expr(hi)
                        self.emit2(pg::OP_BIN, pg::B_LE)
                        self.emit2(pg::OP_JNZ, c.target)
                    elif hi < 0:
                        self.emit2(pg::OP_LOAD_LOCAL, hs)
                        self.expr(lo)
                        self.emit2(pg::OP_BIN, pg::B_EQ)
                        self.emit2(pg::OP_JNZ, c.target)
                    else:
                        self.emit2(pg::OP_LOAD_LOCAL, hs)
                        self.expr(lo)
                        self.emit2(pg::OP_BIN, pg::B_GE)
                        if hi_open:
                            self.emit2(pg::OP_JNZ, c.target)
                        else:
                            let skip = self.emit_jump(pg::OP_JZ)
                            self.emit2(pg::OP_LOAD_LOCAL, hs)
                            self.expr(hi)
                            self.emit2(pg::OP_BIN, pg::B_LE)
                            self.emit2(pg::OP_JNZ, c.target)
                            self.patch_here(skip)
                _ -> 0
        let mut jno = -1
        if sw.default_target >= 0:
            self.emit2(pg::OP_JMP, sw.default_target)
        else:
            jno = self.emit_jump(pg::OP_JMP)
        let end = self.pos()
        self.patch(jend, end)
        if jno >= 0:
            self.patch(jno, end)
        self.pop_loop(end, end)
        self.switches.pop()

    # --- expressions --------------------------------------------------------------

    fn expr_discard(mut self, e: i32):
        self.expr(e)
        self.emit(pg::OP_POP)

    # Arguments: pushes them and returns the count, or -1 when a spread
    # (`@arr`/`arr...`) made the count dynamic -- then one array holding
    # them all is pushed instead.
    fn args(mut self, args: List<i32>) -> i32:
        let mut spread = false
        for i in 0..args.len():
            match self.nodes[args[i]].kind:
                ast::NodeKind::Spread(x) ->
                    spread = true
                _ -> 0
        if !spread:
            for i in 0..args.len():
                self.expr(args[i])
            return args.len()
        self.emit2(pg::OP_MKARRAY, 0)
        for i in 0..args.len():
            match self.nodes[args[i]].kind:
                ast::NodeKind::Spread(x) ->
                    self.expr(x)
                    self.emit(pg::OP_ARR_EXTEND)
                _ ->
                    self.expr(args[i])
                    self.emit(pg::OP_ARR_APPEND)
        -1

    fn efun_call(mut self, name: str, args: List<i32>):
        if name == "call_other" and args.len() >= 2:
            let n = self.args(args)
            if n < 0:
                self.emit2(pg::OP_CALL_OTHER, -1)
            else:
                self.emit2(pg::OP_CALL_OTHER, n - 2)
            return
        let n = self.args(args)
        let k = self.kstr(name)
        self.emit(pg::OP_CALL_EFUN)
        self.emit3(self.efun_code(name), k, n)

    fn call(mut self, n: i32, name: str, args: List<i32>):
        if name == "this_object" and args.len() == 0:
            self.emit(pg::OP_THIS)
            return
        let kind = self.func_kind(name)
        if kind == 2:
            if self.own_private(name) and self.own_fn_index.contains(name):
                if let Option::Some(fi) = self.own_fn_index.get(name):
                    let c = self.args(args)
                    self.emit(pg::OP_CALL_DIRECT)
                    self.emit3(self.prog_id, fi, 0)
                    self.emit(c)
                    return
            let c = self.args(args)
            let k = self.kstr(name)
            self.emit3(pg::OP_CALL_VIRT, k, c)
            return
        if kind == 1:
            let c = self.args(args)
            let k = self.kstr(name)
            self.emit3(pg::OP_CALL_SELF, k, c)
            return
        if self.is_sefun_name(name):
            let c = self.args(args)
            let k = self.kstr(name)
            self.emit3(pg::OP_CALL_SEFUN, k, c)
            return
        if !self.is_efun_name(name) and !self.known_efuns.contains(name) and self.is_var(name):
            let r = self.resolve_var(name)
            self.emit_load(r)
            let c = self.args(args)
            self.emit2(pg::OP_CALLV, c)
            return
        self.efun_call(name, args)

    # A pointer to the function `name` as an rvalue (the emitter's
    # `emit_fptr` "name" form without arguments, and a bare function name).
    fn fn_value(mut self, name: str):
        let kind = self.func_kind(name)
        if kind == 2:
            if self.own_private(name):
                if let Option::Some(fi) = self.own_fn_index.get(name):
                    self.emit(pg::OP_FN_DIRECT)
                    self.emit3(self.prog_id, fi, 0)
                    return
            let k = self.kstr(name)
            self.emit2(pg::OP_FN_VIRT, k)
            return
        if kind == 1:
            let k = self.kstr(name)
            self.emit2(pg::OP_FN_SELF, k)
            return
        if self.is_sefun_name(name):
            let k = self.kstr(name)
            self.emit2(pg::OP_FN_SEFUN, k)
            return
        if self.is_efun_name(name):
            let k = self.kstr(name)
            self.emit3(pg::OP_FN_EFUN, self.efun_code(name), k)
            return
        let k = self.kstr(name)
        self.emit2(pg::OP_FN_UNDEF, k)

    fn bind(mut self, args: List<i32>):
        if args.len() == 0:
            return
        for i in 0..args.len():
            self.expr(args[i])
        self.emit2(pg::OP_BIND, args.len())

    # `inh::name` as a direct call target: (prog, fnidx, var_off) or none
    fn scoped_entry(self, ii: i32, name: str) -> pg::DispEntry:
        let h = self.inh[ii]
        if let Option::Some(e) = h.prog.vt.get(name):
            return pg::DispEntry(prog = e.prog, fnidx = e.fnidx, var_off = e.var_off + self.inherit_off(ii))
        if let Option::Some(e) = h.prog.anyt.get(name):
            return pg::DispEntry(prog = e.prog, fnidx = e.fnidx, var_off = e.var_off + self.inherit_off(ii))
        pg::DispEntry(prog = -1, fnidx = -1, var_off = 0)

    fn inherit_off(self, ii: i32) -> i32:
        let mut off = 0
        for i in 0..ii:
            off += self.inh[i].prog.nvars
        off

    fn scall(mut self, n: i32, label: str, name: str, args: List<i32>, is_ref: bool):
        if label == "efun":
            if is_ref:
                let k = self.kstr(name)
                self.emit3(pg::OP_FN_EFUN, self.efun_code(name), k)
                return
            self.efun_call(name, args)
            return
        let ii = self.find_inherit(label, name)
        if ii < 0:
            if label == "":
                self.emit2(pg::OP_PUSH_INT, 0)
                return
            self.fail(f"No inherit matches {label}::{name}", n)
            return
        let e = self.scoped_entry(ii, name)
        let mut has = false
        if let Option::Some(_d) = self.inh[ii].prog.all_funcs.get(name):
            has = true
        if !has or e.prog < 0:
            let c = self.args(args)
            let k = self.kstr(name)
            self.emit3(pg::OP_CALL_SELF, k, c)
            return
        if is_ref:
            self.emit(pg::OP_FN_DIRECT)
            self.emit3(e.prog, e.fnidx, e.var_off)
            return
        let c = self.args(args)
        self.emit(pg::OP_CALL_DIRECT)
        self.emit3(e.prog, e.fnidx, e.var_off)
        self.emit(c)

    fn max_dollar(self, e: i32) -> i64:
        if e < 0:
            return 0 as i64
        let mut m = 0 as i64
        match self.nodes[e].kind:
            ast::NodeKind::Dollar(v) ->
                return v
            ast::NodeKind::DollarExpr(x) ->
                return 0 as i64
            ast::NodeKind::FptrExpr(x) ->
                return 0 as i64
            ast::NodeKind::Lambda(p, b) ->
                return 0 as i64
            _ ->
                m = 0 as i64
        let kids = self.children(e)
        for i in 0..kids.len():
            let d = self.max_dollar(kids[i])
            if d > m:
                m = d
        m

    # every child node of an expression (for max_dollar's scan)
    fn children(self, e: i32) -> List<i32>:
        match self.nodes[e].kind:
            ast::NodeKind::Bin(op, l, r) -> [l, r]
            ast::NodeKind::Assign(op, l, r) -> [l, r]
            ast::NodeKind::Un(op, x) -> [x]
            ast::NodeKind::Post(op, x) -> [x]
            ast::NodeKind::Cond(c, a, b) -> [c, a, b]
            ast::NodeKind::Comma(l, r) -> [l, r]
            ast::NodeKind::Call(name, args) -> args
            ast::NodeKind::Callv(f, args) ->
                let mut o: List<i32> = [f]
                for i in 0..args.len():
                    o.push(args[i])
                o
            ast::NodeKind::Scall(l, n, args, r) -> args
            ast::NodeKind::Arrow(obj, n, ne, args) ->
                let mut o: List<i32> = [obj, ne]
                for i in 0..args.len():
                    o.push(args[i])
                o
            ast::NodeKind::Member(obj, n) -> [obj]
            ast::NodeKind::Index(x, i, fe) -> [x, i]
            ast::NodeKind::Range(x, lo, le, hi, he) -> [x, lo, hi]
            ast::NodeKind::Paren(x) -> [x]
            ast::NodeKind::Arr(items) -> items
            ast::NodeKind::Map(pairs) -> pairs
            ast::NodeKind::FptrName(n, args) -> args
            ast::NodeKind::FptrScoped(l, n, args) -> args
            ast::NodeKind::Cast(t, x) -> [x]
            ast::NodeKind::Catch(x, b) -> [x]
            ast::NodeKind::Sscanf(args) -> args
            ast::NodeKind::New(args) -> args
            ast::NodeKind::NewClass(n, f, values) -> values
            ast::NodeKind::Spread(x) -> [x]
            _ -> List<i32>()

    # Emit the closure-creation sequence for a just-compiled closure context.
    fn finish_closure(mut self, c: Ctx, fi: i32, nparams: i32, varargs: bool, cells: List<i32>):
        let mut kinds: List<i32> = List<i32>()
        let mut ndv = 0
        let mut nref = 0
        for i in 0..c.upvals.len():
            kinds.push(c.upvals[i].kind)
            if c.upvals[i].kind == pg::UV_DOLLAR:
                ndv += 1
        for i in 0..c.upvals.len():
            let u = c.upvals[i]
            if u.kind == pg::UV_REF:
                nref += 1
                if u.from_upval:
                    self.emit2(pg::OP_PUSH_UPVAL_REF, u.src)
                else:
                    self.emit2(pg::OP_LOAD_LOCAL, u.src)
        self.fns[fi] = pg::FnDef(name = "(closure)", nparams = nparams, varargs = varargs, nlocals = c.nslots, code = c.code, cell_params = cells, upval_kinds = kinds)
        self.emit(pg::OP_MKCLOSURE)
        self.emit3(fi, ndv, nref)

    fn functional(mut self, e: i32):
        let fi = self.fns.len()
        self.fns.push(pg::FnDef(name = "(closure)"))
        let maxd = self.max_dollar(e) as i32
        self.begin_ctx(true, true)
        for i in 0..maxd:
            self.new_slot()
        self.expr(e)
        self.emit(pg::OP_RET)
        let c = self.end_ctx()
        self.finish_closure(c, fi, maxd, false, List<i32>())

    fn lambda(mut self, params: List<i32>, body: i32):
        let fi = self.fns.len()
        self.fns.push(pg::FnDef(name = "(closure)"))
        self.begin_ctx(true, false)
        let cells = self.declare_params(params)
        self.param_defaults(params)
        self.block_body(body)
        self.emit2(pg::OP_PUSH_INT, 0)
        self.emit(pg::OP_RET)
        let c = self.end_ctx()
        self.finish_closure(c, fi, params.len(), self.is_varargs(params), cells)

    fn dollar_expr(mut self, e: i32):
        let t = self.ctxs.len() - 1
        if !self.ctxs[t].is_functional:
            self.expr(e)
            return
        # compiled into the enclosing context: evaluated when the pointer is made
        let c = self.end_ctx()
        self.expr(e)
        self.ctxs.push(c)
        let idx = self.ctxs[t].upvals.len()
        self.ctxs[t].upvals.push(Upval(kind = pg::UV_DOLLAR))
        self.emit2(pg::OP_LOAD_UPVAL, idx)

    fn expr(mut self, e: i32):
        if self.had_error:
            return
        match self.nodes[e].kind:
            ast::NodeKind::LitInt(v) -> self.push_int(v)
            ast::NodeKind::LitFloat(v) ->
                let k = self.konst(val::Value::Real(v))
                self.emit2(pg::OP_PUSH_CONST, k)
            ast::NodeKind::LitStr(v) ->
                let k = self.kstr(v)
                self.emit2(pg::OP_PUSH_CONST, k)
            ast::NodeKind::LitOpen -> self.emit(pg::OP_PUSH_UNDEF)
            ast::NodeKind::Id(name) ->
                let r = self.resolve_var(name)
                match r:
                    VarRef::NoVar ->
                        let kind = self.func_kind(name)
                        if kind > 0:
                            self.fn_value(name)
                        elif self.classes.contains(name):
                            self.emit2(pg::OP_PUSH_INT, 0)
                        else:
                            self.fail(f"Undefined variable '{name}'", e)
                    _ -> self.emit_load(r)
            ast::NodeKind::Paren(x) -> self.expr(x)
            ast::NodeKind::Bin(op, l, r) -> self.binary(op, l, r)
            ast::NodeKind::Assign(op, l, r) -> self.assign(e, op, l, r)
            ast::NodeKind::Un(op, x) ->
                if op == "++" or op == "--":
                    self.incdec(e, x, op == "++", false)
                elif op == "-":
                    self.expr(x)
                    self.emit(pg::OP_NEG)
                elif op == "!":
                    self.expr(x)
                    self.emit(pg::OP_NOT)
                elif op == "~":
                    self.expr(x)
                    self.emit(pg::OP_COMPL)
                else:
                    self.expr(x)
            ast::NodeKind::Post(op, x) -> self.incdec(e, x, op == "++", true)
            ast::NodeKind::Cond(c, a, b) ->
                self.expr(c)
                let j = self.emit_jump(pg::OP_JZ)
                self.expr(a)
                let j2 = self.emit_jump(pg::OP_JMP)
                self.patch_here(j)
                self.expr(b)
                self.patch_here(j2)
            ast::NodeKind::Comma(l, r) ->
                self.expr_discard(l)
                self.expr(r)
            ast::NodeKind::Call(name, args) -> self.call(e, name, args)
            ast::NodeKind::Callv(f, args) ->
                self.expr(f)
                let c = self.args(args)
                self.emit2(pg::OP_CALLV, c)
            ast::NodeKind::Scall(label, name, args, is_ref) -> self.scall(e, label, name, args, is_ref)
            ast::NodeKind::Arrow(obj, name, name_expr, args) ->
                self.expr(obj)
                if name_expr >= 0:
                    self.expr(name_expr)
                else:
                    let k = self.kstr(name)
                    self.emit2(pg::OP_PUSH_CONST, k)
                let c = self.args(args)
                self.emit2(pg::OP_CALL_OTHER, c)
            ast::NodeKind::Member(obj, name) ->
                let p = self.member_index(obj, name, e)
                self.expr(obj)
                self.emit2(pg::OP_MEMBER, p)
            ast::NodeKind::Index(x, i, from_end) ->
                self.expr(x)
                self.expr(i)
                if from_end:
                    self.emit(pg::OP_NEG)
                self.emit(pg::OP_INDEX)
            ast::NodeKind::Range(x, lo, lo_end, hi, hi_end) ->
                self.expr(x)
                let flags = self.range_operands(lo, lo_end, hi, hi_end)
                self.emit2(pg::OP_RANGE, flags)
            ast::NodeKind::Arr(items) ->
                let n = self.args(items)
                if n >= 0:
                    self.emit2(pg::OP_MKARRAY, n)
            ast::NodeKind::Map(pairs) ->
                for i in 0..pairs.len():
                    self.expr(pairs[i])
                self.emit2(pg::OP_MKMAP, pairs.len() / 2)
            ast::NodeKind::FptrName(name, args) ->
                let r = self.resolve_var(name)
                match r:
                    VarRef::NoVar -> self.fn_value(name)
                    _ -> self.emit_load(r)
                self.bind(args)
            ast::NodeKind::FptrScoped(label, name, args) ->
                if label == "efun":
                    let k = self.kstr(name)
                    self.emit3(pg::OP_FN_EFUN, self.efun_code(name), k)
                else:
                    let ii = self.find_inherit(label, name)
                    if ii < 0:
                        self.fail(f"No inherited function {label}::{name}", e)
                        return
                    let en = self.scoped_entry(ii, name)
                    if en.prog < 0:
                        let k = self.kstr(name)
                        self.emit2(pg::OP_FN_SELF, k)
                    else:
                        self.emit(pg::OP_FN_DIRECT)
                        self.emit3(en.prog, en.fnidx, en.var_off)
                self.bind(args)
            ast::NodeKind::FptrExpr(x) -> self.functional(x)
            ast::NodeKind::Lambda(params, body) -> self.lambda(params, body)
            ast::NodeKind::Cast(typ, x) ->
                self.expr(x)
                if typ == "int":
                    self.emit2(pg::OP_CONV, pg::CONV_INT)
                elif typ == "float":
                    self.emit2(pg::OP_CONV, pg::CONV_FLOAT)
                elif typ == "string":
                    self.emit2(pg::OP_CONV, pg::CONV_STRING)
            ast::NodeKind::Catch(x, block) ->
                let h = self.emit_jump(pg::OP_CATCH_BEGIN)
                let t = self.ctxs.len() - 1
                self.ctxs[t].catch_depth += 1
                if block >= 0:
                    self.block_body(block)
                else:
                    self.expr_discard(x)
                self.ctxs[t].catch_depth -= 1
                self.emit(pg::OP_CATCH_END)
                self.emit2(pg::OP_PUSH_INT, 0)
                let j = self.emit_jump(pg::OP_JMP)
                self.patch_here(h)
                self.patch_here(j)
            ast::NodeKind::TimeExpr(x, block) ->
                let s = self.new_slot()
                self.emit2(pg::OP_TIME_BEGIN, s)
                if block >= 0:
                    self.block_body(block)
                else:
                    self.expr_discard(x)
                self.emit2(pg::OP_TIME_END, s)
            ast::NodeKind::Sscanf(args) -> self.efun_call("sscanf", args)
            ast::NodeKind::ParseCommand(args) -> self.efun_call("parse_command", args)
            ast::NodeKind::New(args) ->
                if args.len() == 0:
                    self.fail("new() needs arguments", e)
                    return
                let n = self.args(args)
                let k = self.kstr("clone_object")
                self.emit(pg::OP_CALL_EFUN)
                self.emit3(self.efun_code("clone_object"), k, n)
            ast::NodeKind::NewClass(name, fields, values) ->
                let mut size = 0
                let mut positions: List<i32> = List<i32>()
                if let Option::Some(c) = self.classes.get(name):
                    size = c.members.len()
                    for i in 0..fields.len():
                        let mut p = -1
                        for j in 0..c.members.len():
                            if c.members[j] == fields[i] and p < 0:
                                p = j
                        if p < 0:
                            self.fail(f"Class {name} has no member {fields[i]}", e)
                            return
                        positions.push(p)
                else:
                    self.fail(f"Undefined class {name}", e)
                    return
                for i in 0..values.len():
                    self.expr(values[i])
                let k = self.kstr(name)
                self.emit(pg::OP_NEWCLASS)
                self.emit3(k, size, positions.len())
                for i in 0..positions.len():
                    self.emit(positions[i])
            ast::NodeKind::Spread(x) -> self.fail("Unexpected spread", e)
            ast::NodeKind::Dollar(v) ->
                let t = self.ctxs.len() - 1
                if !self.ctxs[t].is_functional:
                    self.fail(f"${v} outside of functional", e)
                    return
                self.emit2(pg::OP_LOAD_LOCAL, (v as i32) - 1)
            ast::NodeKind::DollarExpr(x) -> self.dollar_expr(x)
            _ -> self.fail("Unknown expression kind", e)

    fn range_operands(mut self, lo: i32, lo_end: bool, hi: i32, hi_end: bool) -> i32:
        let mut flags = 0
        if lo >= 0:
            self.expr(lo)
            flags += pg::R_HAS_LO
            if lo_end:
                flags += pg::R_LO_END
        else:
            self.emit(pg::OP_PUSH_UNDEF)
        if hi >= 0:
            self.expr(hi)
            flags += pg::R_HAS_HI
            if hi_end:
                flags += pg::R_HI_END
        else:
            self.emit(pg::OP_PUSH_UNDEF)
        flags

    fn binary(mut self, op: str, l: i32, r: i32):
        if op == "&&" or op == "||":
            self.expr(l)
            let j = self.emit_jump(if op == "&&": pg::OP_JZ_KEEP else: pg::OP_JNZ_KEEP)
            self.expr(r)
            self.patch_here(j)
            return
        self.expr(l)
        self.expr(r)
        self.emit2(pg::OP_BIN, binop_code(op))

    # --- lvalues --------------------------------------------------------------------

    # The lvalue's base node and its index/member steps, outermost last.
    fn lv_steps(self, l: i32) -> List<i32>:
        let mut steps: List<i32> = List<i32>()
        let mut cur = l
        let mut going = true
        while going:
            match self.nodes[cur].kind:
                ast::NodeKind::Index(x, i, fe) ->
                    steps.push(cur)
                    cur = x
                ast::NodeKind::Member(obj, n) ->
                    steps.push(cur)
                    cur = obj
                ast::NodeKind::Paren(x) ->
                    if steps.len() == 0:
                        cur = x
                    else:
                        going = false
                _ ->
                    going = false
        steps.push(cur)
        steps

    # Push the chain's containers/keys: for steps s1 (outermost) .. sn, leaves
    # c0 k1 c1 k2 .. c(n-1) kn on the stack. Returns the base variable (or
    # NoVar when the base is an rvalue, which then gets no writeback).
    fn lv_push(mut self, chain: List<i32>) -> VarRef:
        let base = chain[chain.len() - 1]
        let mut bref = VarRef::NoVar
        match self.nodes[base].kind:
            ast::NodeKind::Id(name) ->
                bref = self.resolve_var(name)
            _ ->
                bref = VarRef::NoVar
        match bref:
            VarRef::NoVar -> self.expr(base)
            _ -> self.emit_load(bref)
        let mut i = chain.len() - 2
        while i >= 0:
            self.lv_key(chain[i])
            if i > 0:
                self.emit(pg::OP_DUP2)
                self.lv_get(chain[i])
            i -= 1
        bref

    fn lv_key(mut self, step: i32):
        match self.nodes[step].kind:
            ast::NodeKind::Index(x, i, fe) ->
                self.expr(i)
                if fe:
                    self.emit(pg::OP_NEG)
            ast::NodeKind::Member(obj, name) ->
                let p = self.member_index(obj, name, step)
                self.emit2(pg::OP_PUSH_INT, p)
            _ -> 0

    # (c k -- v) for one step
    fn lv_get(mut self, step: i32):
        match self.nodes[step].kind:
            ast::NodeKind::Member(obj, name) ->
                self.emit(pg::OP_POP)
                let p = self.member_index(obj, name, step)
                self.emit2(pg::OP_MEMBER, p)
            _ -> self.emit(pg::OP_INDEX)

    # (c k v -- c' v) for the innermost step
    fn lv_store(mut self, step: i32):
        match self.nodes[step].kind:
            ast::NodeKind::Member(obj, name) ->
                let p = self.member_index(obj, name, step)
                self.emit(pg::OP_SWAP)
                self.emit(pg::OP_POP)
                self.emit2(pg::OP_MSTORE, p)
            _ -> self.emit(pg::OP_ISTORE)

    # after the innermost store: ripple (c k c' v -- c'' v) outwards, then
    # give a changed base container (a string) back to the base variable
    fn lv_finish(mut self, chain: List<i32>, bref: VarRef):
        let mut i = 1
        while i < chain.len() - 1:
            match self.nodes[chain[i]].kind:
                ast::NodeKind::Member(obj, name) ->
                    let p = self.member_index(obj, name, chain[i])
                    # (c k sub v): the key is a position; drop it under the values
                    self.emit2(pg::OP_MSTORE_UP, p)
                _ -> self.emit(pg::OP_ISTORE_UP)
            i += 1
        # (c' v): c' is undefined unless the base container changed (a string)
        match bref:
            VarRef::NoVar ->
                self.emit(pg::OP_SWAP)
                self.emit(pg::OP_POP)
            _ ->
                self.emit(pg::OP_SWAP)
                self.emit(pg::OP_DUP)
                let j = self.emit_jump(pg::OP_JZ)
                self.emit_store(bref)
                let j2 = self.emit_jump(pg::OP_JMP)
                self.patch_here(j)
                self.emit(pg::OP_POP)
                self.patch_here(j2)

    fn compound_op(self, op: str, l: i32, r: i32) -> i32:
        let div_op = op == "/=" or op == "%="
        let arith = op == "+=" or op == "-=" or op == "*=" or div_op
        if arith and (div_op or !self.never_float(r)) and self.pure_expr(l):
            if op == "+=":
                return pg::B_CADD
            if op == "-=":
                return pg::B_CSUB
            if op == "*=":
                return pg::B_CMUL
            if op == "/=":
                return pg::B_CDIV
            return pg::B_MOD
        if op == "+=":
            return pg::B_ADD
        if op == "-=":
            return pg::B_SUB
        if op == "*=":
            return pg::B_MUL
        if op == "/=":
            return pg::B_PDIV
        if op == "%=":
            return pg::B_PMOD
        if op == "&=":
            return pg::B_AND
        if op == "|=":
            return pg::B_OR
        if op == "^=":
            return pg::B_XOR
        if op == "<<=":
            return pg::B_SHL
        pg::B_SHR

    fn assign(mut self, n: i32, op: str, l: i32, r: i32):
        match self.nodes[l].kind:
            ast::NodeKind::Range(x, lo, lo_end, hi, hi_end) ->
                if op != "=":
                    self.fail("Compound assignment to a range is not supported", n)
                    return
                self.range_assign(x, lo, lo_end, hi, hi_end, r)
                return
            _ -> 0
        let chain = self.lv_steps(l)
        if chain.len() == 1:
            let base = chain[0]
            match self.nodes[base].kind:
                ast::NodeKind::Id(name) ->
                    let v = self.resolve_var(name)
                    match v:
                        VarRef::NoVar ->
                            self.fail(f"Undefined variable '{name}'", base)
                            return
                        _ -> 0
                    if op == "=":
                        let lt = self.static_type(l)
                        self.emit_assigned(r, lt)
                    else:
                        let bop = self.compound_op(op, l, r)
                        self.emit_load(v)
                        self.expr(r)
                        self.emit2(pg::OP_BIN, bop)
                    self.emit(pg::OP_DUP)
                    self.emit_store(v)
                    return
                _ ->
                    self.fail("Illegal lvalue", n)
                    return
        let bref = self.lv_push(chain)
        let inner = chain[0]
        if op == "=":
            let lt = self.static_type(l)
            self.emit_assigned(r, lt)
        else:
            let bop = self.compound_op(op, l, r)
            self.emit(pg::OP_DUP2)
            self.lv_get(inner)
            self.expr(r)
            self.emit2(pg::OP_BIN, bop)
        self.lv_store(inner)
        self.lv_finish(chain, bref)

    fn incdec(mut self, n: i32, x: i32, inc: bool, post: bool):
        let bop = if inc: pg::B_ADD else: pg::B_SUB
        let chain = self.lv_steps(x)
        let tmp = self.new_slot()
        if chain.len() == 1:
            match self.nodes[chain[0]].kind:
                ast::NodeKind::Id(name) ->
                    let v = self.resolve_var(name)
                    match v:
                        VarRef::NoVar ->
                            self.fail(f"Undefined variable '{name}'", chain[0])
                            return
                        _ -> 0
                    self.emit_load(v)
                    if post:
                        self.emit(pg::OP_DUP)
                        self.emit2(pg::OP_STORE_LOCAL, tmp)
                    self.emit2(pg::OP_PUSH_INT, 1)
                    self.emit2(pg::OP_BIN, bop)
                    self.emit(pg::OP_DUP)
                    self.emit_store(v)
                    if post:
                        self.emit(pg::OP_POP)
                        self.emit2(pg::OP_LOAD_LOCAL, tmp)
                    return
                _ ->
                    self.fail("Illegal lvalue", n)
                    return
        let bref = self.lv_push(chain)
        let inner = chain[0]
        self.emit(pg::OP_DUP2)
        self.lv_get(inner)
        if post:
            self.emit(pg::OP_DUP)
            self.emit2(pg::OP_STORE_LOCAL, tmp)
        self.emit2(pg::OP_PUSH_INT, 1)
        self.emit2(pg::OP_BIN, bop)
        self.lv_store(inner)
        self.lv_finish(chain, bref)
        if post:
            self.emit(pg::OP_POP)
            self.emit2(pg::OP_LOAD_LOCAL, tmp)

    # `x[lo..hi] = r`: the new string/array replaces x (which may itself be
    # an index chain)
    fn range_assign(mut self, x: i32, lo: i32, lo_end: bool, hi: i32, hi_end: bool, r: i32):
        let chain = self.lv_steps(x)
        if chain.len() == 1:
            match self.nodes[chain[0]].kind:
                ast::NodeKind::Id(name) ->
                    let v = self.resolve_var(name)
                    self.emit_load(v)
                    let flags = self.range_operands(lo, lo_end, hi, hi_end)
                    self.expr(r)
                    self.emit2(pg::OP_RANGE_SET, flags)
                    self.emit(pg::OP_DUP)
                    self.emit_store(v)
                    return
                _ ->
                    self.expr(chain[0])
                    let flags = self.range_operands(lo, lo_end, hi, hi_end)
                    self.expr(r)
                    self.emit2(pg::OP_RANGE_SET, flags)
                    return
        let bref = self.lv_push(chain)
        let inner = chain[0]
        self.emit(pg::OP_DUP2)
        self.lv_get(inner)
        let flags = self.range_operands(lo, lo_end, hi, hi_end)
        self.expr(r)
        self.emit2(pg::OP_RANGE_SET, flags)
        # (c k s') -> store s' at c[k], value s'
        self.emit(pg::OP_DUP)
        self.lv_store(inner)
        self.lv_finish(chain, bref)

fn binop_code(op: str) -> i32:
    if op == "+":
        return pg::B_ADD
    if op == "-":
        return pg::B_SUB
    if op == "*":
        return pg::B_MUL
    if op == "/":
        return pg::B_DIV
    if op == "%":
        return pg::B_MOD
    if op == "&":
        return pg::B_AND
    if op == "|":
        return pg::B_OR
    if op == "^":
        return pg::B_XOR
    if op == "<<":
        return pg::B_SHL
    if op == ">>":
        return pg::B_SHR
    if op == "==":
        return pg::B_EQ
    if op == "!=":
        return pg::B_NE
    if op == "<":
        return pg::B_LT
    if op == "<=":
        return pg::B_LE
    if op == ">":
        return pg::B_GT
    pg::B_GE

# The emitter's INT_EFUNS: efuns whose result is an int, for static_type().
fn is_int_efun(n: str) -> bool:
    n == "sizeof" or n == "strlen" or n == "to_int" or n == "random" or n == "time" or n == "member_array" or n == "strsrch" or n == "file_size" or n == "query_idle" or n == "sscanf" or n == "uptime" or n == "intp" or n == "floatp" or n == "stringp" or n == "objectp" or n == "arrayp" or n == "mapp" or n == "functionp" or n == "pointerp" or n == "undefinedp" or n == "living" or n == "interactive" or n == "userp" or n == "wizardp" or n == "find_call_out" or n == "remove_call_out" or n == "call_out" or n == "memory_info" or n == "strcmp" or n == "rm" or n == "mkdir" or n == "rmdir" or n == "cp" or n == "rename" or n == "write_file" or n == "file_length" or n == "member_group" or n == "query_heart_beat" or n == "set_heart_beat" or n == "crc32" or n == "regexp_match"

# The emitter's NONFLOAT_EFUNS: efuns whose result is never a float.
fn is_nonfloat_efun(n: str) -> bool:
    n == "sprintf" or n == "implode" or n == "explode" or n == "capitalize" or n == "lower_case" or n == "upper_case" or n == "replace_string" or n == "sizeof" or n == "strlen" or n == "strsrch" or n == "member_array" or n == "random" or n == "time" or n == "to_int" or n == "keys" or n == "values" or n == "allocate" or n == "sort_array" or n == "filter" or n == "filter_array" or n == "map" or n == "map_array" or n == "file_name" or n == "base_name" or n == "identify" or n == "save_variable" or n == "this_object" or n == "this_player" or n == "previous_object" or n == "environment" or n == "all_inventory" or n == "deep_inventory" or n == "users" or n == "query_verb"

fn new_compiler(nodes: List<ast::Node>, files: List<str>, vpath: str, prog_id: i32, inh: List<InhIn>, sefun_names: Set<str>, sefun_types: Map<str, str>, is_sefun: bool, efun_codes: Map<str, i32>, ref_efuns: Set<str>, known_efuns: Set<str>) -> Compiler:
    Compiler(nodes = nodes, files = files, vpath = vpath, prog_id = prog_id, inh = inh, sefun_names = sefun_names, sefun_types = sefun_types, is_sefun = is_sefun, efun_codes = efun_codes, ref_efuns = ref_efuns, known_efuns = known_efuns)

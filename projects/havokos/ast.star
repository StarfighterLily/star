# LPC abstract syntax tree -- the Star counterpart of the mapping-based AST
# HavokOS `pike/lpc/parser.pike` builds, todo.md HavokOS M2.
#
# The reference makes every node a Pike mapping (`([ "k": kind, "line": ..,
# "file": .., ... ])`) and lets each kind carry whatever keys it likes. Star
# has neither heterogeneous mappings nor heap references between structs, so
# this follows the arena shape `projects/nova/NoBASIC/ast.star` settled on
# (see that file's header for the recursive-layout reasoning): one flat
# `List<Node>`, children referenced by `i32` index, one `NodeKind` variant
# per reference node kind with exactly the fields that kind's mapping holds.
#
# One arena for statements, expressions *and* the reference's three key-less
# helper mappings (variable declarators, function parameters, foreach
# variables), rather than NoBASIC's separate `exprs`/`stmts` lists: LPC
# nests them in both directions all the time (`catch { block }` and
# `function(..) { block }` are expressions holding statements, `for (int i =
# 0; ..)` is a statement holding declarators holding expressions), and one
# index type keeps every parse method's return type the same.
#
# Conventions, chosen so the AST dump (`dump_program`) can say exactly what
# the reference mapping holds:
#   - An absent child is index `-1`. Where the reference *omits the key*
#     (`func` prototype has no "body", `return;` has no "e") the dump omits
#     it too; where the reference stores an explicit 0 (`case` "lo"/"hi",
#     `range` "lo"/"hi", `inherit` "label") the dump prints `0`.
#   - An absent name is `""` (LPC identifiers are never empty), with the
#     same omit-or-0 split.
#   - Type strings are the reference's own spelling: base word plus one `*`
#     per array level, `class foo` for a class, `unknown` already mapped to
#     `mixed`.
#   - Modifiers are a `List<str>` of the words as written, duplicates
#     dropped; the reference keeps a multiset, so order carries no meaning.

enum NodeKind:
    # --- top level ---
    Inherit(path: str, label: str, mods: List<str>)
    # `body` -1 = prototype
    Func(name: str, mods: List<str>, typ: str, params: List<i32>, body: i32)
    Var(mods: List<str>, decls: List<i32>)
    Class(name: str, mods: List<str>, members: List<str>, member_types: List<str>)
    # --- key-less helper mappings ---
    # variable declarator (`var`/`ldecl` "decls"); `init` -1 = none
    Decl(name: str, typ: str, init: i32)
    # function parameter; `name` "" = unnamed, `default` -1 = none
    Param(typ: str, name: str, is_ref: bool, varargs: bool, default: i32)
    # foreach variable; `typ` "" = not a declaration
    FeVar(name: str, typ: str)
    # --- statements ---
    Block(stmts: List<i32>)
    Ldecl(decls: List<i32>)
    ExprStmt(e: i32)
    If(cond: i32, then: i32, els: i32)
    While(cond: i32, body: i32)
    Do(cond: i32, body: i32)
    For(init: i32, cond: i32, step: i32, body: i32)
    Foreach(vars: List<i32>, e: i32, body: i32)
    Switch(e: i32, body: i32)
    # `case lo:` / `case lo..hi:` / `case ..hi:` (`open_lo`) / `case lo..:`
    # (`hi` is then a `LitOpen`)
    Case(lo: i32, hi: i32, open_lo: bool)
    Default
    Break
    Continue
    Return(e: i32)
    Empty
    # --- expressions ---
    LitInt(v: i64)
    LitFloat(v: f64)
    LitStr(v: str)
    # the open upper bound of `case lo..:` (reference: `v` UNDEFINED, `open` 1)
    LitOpen
    Id(name: str)
    Dollar(n: i64)
    DollarExpr(e: i32)
    Bin(op: str, l: i32, r: i32)
    Assign(op: str, l: i32, r: i32)
    Un(op: str, e: i32)
    Post(op: str, e: i32)
    Cond(c: i32, a: i32, b: i32)
    Comma(l: i32, r: i32)
    Call(name: str, args: List<i32>)
    Callv(f: i32, args: List<i32>)
    # `label::name(args)`; `label` "" for a bare `::name`; `is_ref` = no
    # argument list (a function reference, reference key "ref")
    Scall(label: str, name: str, args: List<i32>, is_ref: bool)
    # `obj->name(args)` / `obj->(name_expr)(args)`: always a call; an
    # uncalled `->` becomes `Member`
    Arrow(obj: i32, name: str, name_expr: i32, args: List<i32>)
    # `name` "" when it was `obj->(expr)` with no call: the reference drops
    # the expression and stores name 0, and so does this port
    Member(obj: i32, name: str)
    Index(e: i32, i: i32, from_end: bool)
    Range(e: i32, lo: i32, lo_end: bool, hi: i32, hi_end: bool)
    Paren(e: i32)
    Arr(items: List<i32>)
    # key/value pairs flattened: [k0, v0, k1, v1, ...]
    Map(pairs: List<i32>)
    FptrName(name: str, args: List<i32>)
    FptrScoped(label: str, name: str, args: List<i32>)
    FptrExpr(e: i32)
    Lambda(params: List<i32>, body: i32)
    Cast(typ: str, e: i32)
    # exactly one of `e`/`block` is set
    Catch(e: i32, block: i32)
    TimeExpr(e: i32, block: i32)
    Sscanf(args: List<i32>)
    ParseCommand(args: List<i32>)
    New(args: List<i32>)
    NewClass(name: str, fields: List<str>, values: List<i32>)
    Spread(e: i32)

struct Node:
    kind: NodeKind
    line: i32
    # file id, indexing `preprocess.star`'s `Pp.files`
    file: i32

# ---------------------------------------------------------------------------
# Canonical dump -- the Star half of the M2 golden comparison
# (`tools/ref_astdump.pike` is the reference half).
#
# The format is the reference mapping printed generically: a mapping is
# `{key=value ...}` with keys in sorted (byte) order, an array `[a b]`, a
# multiset `<a b>` sorted, a string `"..."` with `tools/tokdump.star`'s
# escapes, an int in decimal, a float as `f` + `(int)(v * 1e6)`. Star has no
# ordering on `str`, so each kind's keys are written in an order sorted by
# hand below; any slip there is a guaranteed mismatch against the
# generically-sorted reference dump, so the sweep checks it. `with_lines`
# false leaves out every "line" key (the `@MARK` text-block files, see
# NOTES.md deviation #1).
# ---------------------------------------------------------------------------

# Every modifier word, in sorted order, so a modifier set prints sorted.
fn sorted_modifiers() -> List<str>:
    ["nomask", "nosave", "private", "protected", "public", "static", "varargs"]

struct Dumper:
    nodes: List<Node>
    files: List<str>
    with_lines: bool
    mut out: Bytes = Bytes()

fn new_dumper(nodes: List<Node>, files: List<str>, with_lines: bool) -> Dumper:
    Dumper(nodes = nodes, files = files, with_lines = with_lines)

impl Dumper:
    fn raw(mut self, s: str):
        let b = bytes_from_str(s)
        for i in 0..b.len():
            self.out.push(b[i])

    fn byte(mut self, c: i32):
        self.out.push(c as u8)

    fn quoted(mut self, s: str):
        let hex = bytes_from_str("0123456789abcdef")
        self.byte(34)
        let b = bytes_from_str(s)
        for i in 0..b.len():
            let c = b[i] as i32
            if c == 92:
                self.byte(92)
                self.byte(92)
            elif c == 34:
                self.byte(92)
                self.byte(34)
            elif c == 10:
                self.byte(92)
                self.byte(110)
            elif c == 9:
                self.byte(92)
                self.byte(116)
            elif c == 13:
                self.byte(92)
                self.byte(114)
            elif c < 32 or c >= 127:
                self.byte(92)
                self.byte(120)
                self.out.push(hex[c / 16])
                self.out.push(hex[c % 16])
            else:
                self.out.push(b[i])
        self.byte(34)

    # `key=` with a leading separator unless it opens the mapping
    fn key(mut self, k: str):
        let n = self.out.len()
        if n > 0 and (self.out[n - 1] as i32) != 123:
            self.byte(32)
        self.raw(k)
        self.byte(61)

    fn kstr(mut self, k: str, v: str):
        self.key(k)
        self.quoted(v)

    fn kint(mut self, k: str, v: i64):
        self.key(k)
        self.raw(f"{v}")

    fn kbool(mut self, k: str, v: bool):
        self.kint(k, if v: 1 as i64 else: 0 as i64)

    # a child slot the reference always stores (0 when absent)
    fn kchild(mut self, k: str, i: i32):
        self.key(k)
        self.node(i)

    # a child slot the reference only stores when present
    fn kopt(mut self, k: str, i: i32):
        if i >= 0:
            self.kchild(k, i)

    fn klist(mut self, k: str, items: List<i32>):
        self.key(k)
        self.byte(91)
        for i in 0..items.len():
            if i > 0:
                self.byte(32)
            self.node(items[i])
        self.byte(93)

    fn kstrs(mut self, k: str, items: List<str>):
        self.key(k)
        self.byte(91)
        for i in 0..items.len():
            if i > 0:
                self.byte(32)
            self.quoted(items[i])
        self.byte(93)

    fn kmods(mut self, k: str, mods: List<str>):
        self.key(k)
        self.byte(60)
        let all = sorted_modifiers()
        let mut first = true
        for i in 0..all.len():
            let mut has = false
            for j in 0..mods.len():
                if mods[j] == all[i]:
                    has = true
            if has:
                if !first:
                    self.byte(32)
                self.quoted(all[i])
                first = false
        self.byte(62)

    fn kfile(mut self, n: Node):
        self.kstr("file", self.files[n.file])

    fn kline(mut self, n: Node):
        if self.with_lines:
            self.kint("line", n.line as i64)

    # The common "file k line" run for a node with no keys sorting between
    # them (the reference keys "form", "from_end", "i", "inits", "items",
    # "l", "label" do, and those kinds write the run out by hand).
    fn fkl(mut self, n: Node, k: str):
        self.kfile(n)
        self.kstr("k", k)
        self.kline(n)

    fn node(mut self, i: i32):
        if i < 0:
            self.byte(48)
            return
        let n = self.nodes[i]
        self.byte(123)
        match n.kind:
            NodeKind::Inherit(path, label, mods) ->
                self.kfile(n)
                self.kstr("k", "inherit")
                if label == "":
                    self.kint("label", 0 as i64)
                else:
                    self.kstr("label", label)
                self.kline(n)
                self.kmods("mods", mods)
                self.kstr("path", path)
            NodeKind::Func(name, mods, typ, params, body) ->
                self.kopt("body", body)
                self.fkl(n, "func")
                self.kmods("mods", mods)
                self.kstr("name", name)
                self.klist("params", params)
                self.kstr("type", typ)
            NodeKind::Var(mods, decls) ->
                self.klist("decls", decls)
                self.fkl(n, "var")
                self.kmods("mods", mods)
            NodeKind::Class(name, mods, members, member_types) ->
                self.fkl(n, "class")
                self.kstrs("member_types", member_types)
                self.kstrs("members", members)
                self.kmods("mods", mods)
                self.kstr("name", name)
            NodeKind::Decl(name, typ, init) ->
                self.kfile(n)
                self.kopt("init", init)
                self.kline(n)
                self.kstr("name", name)
                self.kstr("type", typ)
            NodeKind::Param(typ, name, is_ref, varargs, default) ->
                self.kopt("default", default)
                if name != "":
                    self.kstr("name", name)
                self.kbool("ref", is_ref)
                self.kstr("type", typ)
                if varargs:
                    self.kint("varargs", 1 as i64)
            NodeKind::FeVar(name, typ) ->
                if typ != "":
                    self.kint("decl", 1 as i64)
                self.kstr("name", name)
                if typ != "":
                    self.kstr("type", typ)
            NodeKind::Block(stmts) ->
                self.fkl(n, "block")
                self.klist("stmts", stmts)
            NodeKind::Ldecl(decls) ->
                self.klist("decls", decls)
                self.fkl(n, "ldecl")
            NodeKind::ExprStmt(e) ->
                self.kchild("e", e)
                self.fkl(n, "expr")
            NodeKind::If(cond, then, els) ->
                self.kchild("cond", cond)
                self.kopt("else_", els)
                self.fkl(n, "if")
                self.kchild("then", then)
            NodeKind::While(cond, body) ->
                self.kchild("body", body)
                self.kchild("cond", cond)
                self.fkl(n, "while")
            NodeKind::Do(cond, body) ->
                self.kchild("body", body)
                self.kchild("cond", cond)
                self.fkl(n, "do")
            NodeKind::For(init, cond, step, body) ->
                self.kchild("body", body)
                self.kopt("cond", cond)
                self.kfile(n)
                self.kopt("init", init)
                self.kstr("k", "for")
                self.kline(n)
                self.kopt("step", step)
            NodeKind::Foreach(vars, e, body) ->
                self.kchild("body", body)
                self.kchild("e", e)
                self.fkl(n, "foreach")
                self.klist("vars", vars)
            NodeKind::Switch(e, body) ->
                self.kchild("body", body)
                self.kchild("e", e)
                self.fkl(n, "switch")
            NodeKind::Case(lo, hi, open_lo) ->
                self.kfile(n)
                self.kchild("hi", hi)
                self.kstr("k", "case")
                self.kline(n)
                self.kchild("lo", lo)
                self.kbool("open_lo", open_lo)
            NodeKind::Default ->
                self.fkl(n, "default")
            NodeKind::Break ->
                self.fkl(n, "break")
            NodeKind::Continue ->
                self.fkl(n, "continue")
            NodeKind::Return(e) ->
                self.kopt("e", e)
                self.fkl(n, "return")
            NodeKind::Empty ->
                self.fkl(n, "empty")
            NodeKind::LitInt(v) ->
                self.fkl(n, "lit")
                self.kint("v", v)
            NodeKind::LitFloat(v) ->
                self.fkl(n, "lit")
                self.key("v")
                self.raw(f"f{(v * (1000000.0 as f64)) as i64}")
            NodeKind::LitStr(v) ->
                self.fkl(n, "lit")
                self.kstr("v", v)
            NodeKind::LitOpen ->
                self.fkl(n, "lit")
                self.kint("open", 1 as i64)
                self.kint("v", 0 as i64)
            NodeKind::Id(name) ->
                self.fkl(n, "id")
                self.kstr("name", name)
            NodeKind::Dollar(v) ->
                self.fkl(n, "dollar")
                self.kint("n", v)
            NodeKind::DollarExpr(e) ->
                self.kchild("e", e)
                self.fkl(n, "dollarexpr")
            NodeKind::Bin(op, l, r) ->
                self.kfile(n)
                self.kstr("k", "bin")
                self.kchild("l", l)
                self.kline(n)
                self.kstr("op", op)
                self.kchild("r", r)
            NodeKind::Assign(op, l, r) ->
                self.kfile(n)
                self.kstr("k", "assign")
                self.kchild("l", l)
                self.kline(n)
                self.kstr("op", op)
                self.kchild("r", r)
            NodeKind::Un(op, e) ->
                self.kchild("e", e)
                self.fkl(n, "un")
                self.kstr("op", op)
            NodeKind::Post(op, e) ->
                self.kchild("e", e)
                self.fkl(n, "post")
                self.kstr("op", op)
            NodeKind::Cond(c, a, b) ->
                self.kchild("a", a)
                self.kchild("b", b)
                self.kchild("c", c)
                self.fkl(n, "cond")
            NodeKind::Comma(l, r) ->
                self.kfile(n)
                self.kstr("k", "comma")
                self.kchild("l", l)
                self.kline(n)
                self.kchild("r", r)
            NodeKind::Call(name, args) ->
                self.klist("args", args)
                self.fkl(n, "call")
                self.kstr("name", name)
            NodeKind::Callv(f, args) ->
                self.klist("args", args)
                self.kchild("f", f)
                self.fkl(n, "callv")
            NodeKind::Scall(label, name, args, is_ref) ->
                if !is_ref:
                    self.klist("args", args)
                self.kfile(n)
                self.kstr("k", "scall")
                self.kstr("label", label)
                self.kline(n)
                self.kstr("name", name)
                if is_ref:
                    self.kint("ref", 1 as i64)
            NodeKind::Arrow(obj, name, name_expr, args) ->
                self.klist("args", args)
                self.kint("called", 1 as i64)
                self.fkl(n, "arrow")
                if name_expr >= 0:
                    self.kchild("name_expr", name_expr)
                else:
                    self.kstr("name", name)
                self.kchild("obj", obj)
            NodeKind::Member(obj, name) ->
                self.fkl(n, "member")
                if name == "":
                    self.kint("name", 0 as i64)
                else:
                    self.kstr("name", name)
                self.kchild("obj", obj)
            NodeKind::Index(e, idx, from_end) ->
                self.kchild("e", e)
                self.kfile(n)
                self.kbool("from_end", from_end)
                self.kchild("i", idx)
                self.kstr("k", "index")
                self.kline(n)
            NodeKind::Range(e, lo, lo_end, hi, hi_end) ->
                self.kchild("e", e)
                self.kfile(n)
                self.kchild("hi", hi)
                self.kbool("hi_end", hi_end)
                self.kstr("k", "range")
                self.kline(n)
                self.kchild("lo", lo)
                self.kbool("lo_end", lo_end)
            NodeKind::Paren(e) ->
                self.kchild("e", e)
                self.fkl(n, "paren")
            NodeKind::Arr(items) ->
                self.kfile(n)
                self.klist("items", items)
                self.kstr("k", "arr")
                self.kline(n)
            NodeKind::Map(pairs) ->
                self.fkl(n, "map")
                self.key("pairs")
                self.byte(91)
                let mut i = 0
                while i < pairs.len():
                    if i > 0:
                        self.byte(32)
                    self.byte(91)
                    self.node(pairs[i])
                    self.byte(32)
                    self.node(pairs[i + 1])
                    self.byte(93)
                    i += 2
                self.byte(93)
            NodeKind::FptrName(name, args) ->
                self.klist("args", args)
                self.kfile(n)
                self.kstr("form", "name")
                self.kstr("k", "fptr")
                self.kline(n)
                self.kstr("name", name)
            NodeKind::FptrScoped(label, name, args) ->
                self.klist("args", args)
                self.kfile(n)
                self.kstr("form", "scoped")
                self.kstr("k", "fptr")
                self.kstr("label", label)
                self.kline(n)
                self.kstr("name", name)
            NodeKind::FptrExpr(e) ->
                self.kchild("e", e)
                self.kfile(n)
                self.kstr("form", "expr")
                self.kstr("k", "fptr")
                self.kline(n)
            NodeKind::Lambda(params, body) ->
                self.kchild("body", body)
                self.fkl(n, "lambda")
                self.klist("params", params)
            NodeKind::Cast(typ, e) ->
                self.kchild("e", e)
                self.fkl(n, "cast")
                self.kstr("type", typ)
            NodeKind::Catch(e, block) ->
                self.kopt("block", block)
                self.kopt("e", e)
                self.fkl(n, "catch")
            NodeKind::TimeExpr(e, block) ->
                self.kopt("block", block)
                self.kopt("e", e)
                self.fkl(n, "time_expr")
            NodeKind::Sscanf(args) ->
                self.klist("args", args)
                self.fkl(n, "sscanf")
            NodeKind::ParseCommand(args) ->
                self.klist("args", args)
                self.fkl(n, "parse_command")
            NodeKind::New(args) ->
                self.klist("args", args)
                self.fkl(n, "new")
            NodeKind::NewClass(name, fields, values) ->
                self.kfile(n)
                self.key("inits")
                self.byte(91)
                for j in 0..fields.len():
                    if j > 0:
                        self.byte(32)
                    self.byte(91)
                    self.quoted(fields[j])
                    self.byte(32)
                    self.node(values[j])
                    self.byte(93)
                self.byte(93)
                self.kstr("k", "newclass")
                self.kline(n)
                self.kstr("name", name)
            NodeKind::Spread(e) ->
                self.kchild("e", e)
                self.fkl(n, "spread")
        self.byte(125)

# One canonical line per top-level node.
fn dump_program(nodes: List<Node>, top: List<i32>, files: List<str>, with_lines: bool) -> List<str>:
    let mut d = new_dumper(nodes, files, with_lines)
    let mut lines: List<str> = List<str>()
    for i in 0..top.len():
        d.out = Bytes()
        d.node(top[i])
        lines.push(str_from_bytes(d.out))
    lines

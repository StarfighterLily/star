# LPC parser -- ported from HavokOS `pike/lpc/parser.pike`, todo.md HavokOS
# M2. Recursive descent over `preprocess.star`'s final token stream,
# building `ast.star`'s node arena.
#
# The port follows the reference method for method, including the parts of
# its grammar that are deliberately loose (contextual type words, `*`/`&`
# prefixes ignored, FluffOS's "assignment binds to the nearest lvalue"
# rule in `parse_unary`), because the parse it produces is the contract the
# compiler in M3 is written against. Behavior the reference gets from Pike
# rather than from its own code is reproduced too:
#   - A node built with no explicit token takes its line from the token
#     current *when it is built*, after its children were parsed (Pike
#     evaluates the mapping-literal argument first). That's why a `for`
#     loop's init-expression `expr` node reports the line of the `;`, and
#     the implicit `1` of a `([ key ])` mapping entry the line of the token
#     after the key. `here()` marks those spots.
#   - Optional keys the reference leaves unset versus sets to 0 are kept
#     apart (see `ast.star`'s conventions), since the compiler will read
#     them and the dump checks them.
#
# Errors: there are no exceptions in Star, so the first `fail` records its
# message (the reference's "file:line: msg near X" shape) in `error`, sets
# `had_error`, and every parse method returns `-1` from then on. Every loop
# also tests `had_error`, since a failed `expect` doesn't advance and the
# loop would otherwise spin. Only success/failure is compared against the
# reference, the same bar M1 set for the token stream.
#
# Not ported: the reference's `class_names` multiset, which records class
# names and is never read.

import "token.star" as tk
import "ast.star" as ast

fn is_type_word(w: str) -> bool:
    w == "int" or w == "string" or w == "object" or w == "mapping" or w == "mixed" or w == "void" or w == "float" or w == "function" or w == "buffer" or w == "status" or w == "array" or w == "class" or w == "struct" or w == "unknown"

fn is_modifier(w: str) -> bool:
    w == "static" or w == "private" or w == "public" or w == "protected" or w == "nomask" or w == "varargs" or w == "nosave"

fn binary_prec(op: str) -> i32:
    if op == "||":
        return 1
    if op == "&&":
        return 2
    if op == "|":
        return 3
    if op == "^":
        return 4
    if op == "&":
        return 5
    if op == "==" or op == "!=":
        return 6
    if op == "<" or op == "<=" or op == ">" or op == ">=":
        return 7
    if op == "<<" or op == ">>":
        return 8
    if op == "+" or op == "-":
        return 9
    if op == "*" or op == "/" or op == "%":
        return 10
    0

fn is_assign_op(op: str) -> bool:
    op == "=" or op == "+=" or op == "-=" or op == "*=" or op == "/=" or op == "%=" or op == "&=" or op == "|=" or op == "^=" or op == "<<=" or op == ">>="

fn stars(n: i32) -> str:
    let mut s = ""
    for i in 0..n:
        s = concat(s, "*")
    s

# Pike `%O` of a token value, for the "near X" part of an error message.
fn describe(t: tk::Token) -> str:
    match t.kind:
        tk::Tk::Eof -> "end of file"
        tk::Tk::Int -> f"{t.ival}"
        tk::Tk::Dollar -> f"{t.ival}"
        tk::Tk::Float -> f"{t.fval}"
        _ -> concat(concat("\"", t.text), "\"")

struct Parser:
    toks: List<tk::Token>
    # file id -> vpath, for error messages (`Pp.files`)
    files: List<str>
    mut p: i32 = 0
    mut nodes: List<ast::Node> = List<ast::Node>()
    mut top: List<i32> = List<i32>()
    mut had_error: bool = false
    mut error: str = ""

fn new_parser(toks: List<tk::Token>, files: List<str>) -> Parser:
    Parser(toks = toks, files = files)

impl Parser:
    # --- token helpers ---------------------------------------------------

    fn peek(self, off: i32) -> tk::Token:
        let i = self.p + off
        if i < self.toks.len():
            self.toks[i]
        else:
            self.toks[self.toks.len() - 1]

    fn cur(self) -> tk::Token:
        self.peek(0)

    fn at_op(self, op: str) -> bool:
        tk::is_op(self.cur(), op)

    fn at_id(self) -> bool:
        self.cur().kind == tk::Tk::Id

    fn at_word(self, name: str) -> bool:
        tk::is_id(self.cur(), name)

    fn at_eof(self) -> bool:
        self.cur().kind == tk::Tk::Eof

    fn advance(mut self) -> tk::Token:
        let t = self.cur()
        self.p += 1
        t

    fn fail(mut self, msg: str):
        if self.had_error:
            return
        let t = self.cur()
        self.had_error = true
        self.error = f"{self.files[t.file]}:{t.line}: {msg} near {describe(t)}"

    fn expect_op(mut self, op: str) -> tk::Token:
        if !self.at_op(op):
            self.fail(concat(concat("Expected '", op), "'"))
            return self.cur()
        self.advance()

    fn expect_id(mut self) -> str:
        if !self.at_id():
            self.fail("Expected identifier")
            return ""
        self.advance().text

    fn accept_op(mut self, op: str) -> bool:
        if !self.had_error and self.at_op(op):
            self.p += 1
            return true
        false

    fn add(mut self, kind: ast::NodeKind, t: tk::Token) -> i32:
        if self.had_error:
            return -1
        self.nodes.push(ast::Node(kind = kind, line = t.line, file = t.file))
        self.nodes.len() - 1

    # the token a reference `node()` call without `at` would take its line from
    fn here(self) -> tk::Token:
        self.cur()

    # --- program ---------------------------------------------------------

    fn parse_program(mut self):
        while !self.had_error and !self.at_eof():
            if self.accept_op(";"):
                continue
            let n = self.parse_toplevel()
            if n >= 0:
                self.top.push(n)

    fn parse_modifiers(mut self) -> List<str>:
        let mut mods: List<str> = List<str>()
        while self.at_id() and is_modifier(self.cur().text):
            let w = self.advance().text
            let mut seen = false
            for i in 0..mods.len():
                if mods[i] == w:
                    seen = true
            if !seen:
                mods.push(w)
        mods

    # Is the token at p+off the start of a type?
    fn type_at(self, off: i32) -> bool:
        let t = self.peek(off)
        if t.kind != tk::Tk::Id:
            return false
        let w = t.text
        if w == "class" or w == "struct":
            return self.peek(off + 1).kind == tk::Tk::Id
        if !is_type_word(w):
            return false
        # type words are contextual: `status = 1;` uses `status` as a variable
        let nx = self.peek(off + 1)
        nx.kind == tk::Tk::Id or tk::is_op(nx, "*")

    # A base type, not including per-declarator stars.
    fn parse_base_type(mut self) -> str:
        let w = self.expect_id()
        let mut t = w
        if w == "class" or w == "struct":
            t = concat("class ", self.expect_id())
        elif w == "unknown":
            t = "mixed"
        # `string array foo` style
        while !self.had_error and self.at_word("array"):
            self.advance()
            t = concat(t, "*")
        t

    fn count_stars(mut self) -> i32:
        let mut n = 0
        while !self.had_error and self.at_op("*"):
            self.advance()
            n += 1
        n

    fn parse_toplevel(mut self) -> i32:
        let start = self.cur()

        if self.at_word("inherit") or (self.at_id() and is_modifier(self.cur().text) and tk::is_id(self.peek(1), "inherit")):
            let mods = self.parse_modifiers()
            self.advance()
            let mut parts: List<str> = List<str>()
            let mut got = false
            while !self.had_error:
                while self.cur().kind == tk::Tk::Str:
                    parts.push(self.advance().text)
                    got = true
                if got and self.at_op("+") and self.peek(1).kind == tk::Tk::Str:
                    self.advance()
                    continue
                break
            if !got:
                self.fail("Expected inherit path string")
                return -1
            let mut label = ""
            if self.at_id():
                label = self.advance().text
            self.expect_op(";")
            return self.add(ast::NodeKind::Inherit(path = str_join(parts, ""), label = label, mods = mods), start)

        let mods = self.parse_modifiers()

        # class definition: class Name { ... }
        if (self.at_word("class") or self.at_word("struct")) and self.peek(1).kind == tk::Tk::Id and tk::is_op(self.peek(2), "{"):
            self.advance()
            let name = self.expect_id()
            self.expect_op("{")
            let mut members: List<str> = List<str>()
            let mut member_types: List<str> = List<str>()
            while !self.had_error and !self.at_op("}"):
                if self.accept_op(";"):
                    continue
                self.parse_modifiers()
                let mt = self.parse_base_type()
                let mut more = true
                while more and !self.had_error:
                    member_types.push(concat(mt, stars(self.count_stars())))
                    members.push(self.expect_id())
                    more = self.accept_op(",")
                self.expect_op(";")
            self.expect_op("}")
            self.accept_op(";")
            return self.add(ast::NodeKind::Class(name = name, mods = mods, members = members, member_types = member_types), start)

        let mut base_type = "mixed"
        if self.type_at(0):
            base_type = self.parse_base_type()

        let mut vars: List<i32> = List<i32>()
        while !self.had_error:
            let st = stars(self.count_stars())
            let name_tok = self.cur()
            let name = self.expect_id()
            if self.at_op("("):
                if vars.len() > 0:
                    self.fail("Function definition after variable declarator")
                    return -1
                return self.parse_function_rest(name, mods, concat(base_type, st), name_tok)
            let mut init = -1
            if self.accept_op("="):
                init = self.parse_assign()
            vars.push(self.add(ast::NodeKind::Decl(name = name, typ = concat(base_type, st), init = init), name_tok))
            if self.accept_op(","):
                continue
            self.expect_op(";")
            break
        self.add(ast::NodeKind::Var(mods = mods, decls = vars), start)

    fn parse_params(mut self) -> List<i32>:
        self.expect_op("(")
        let mut params: List<i32> = List<i32>()
        if self.at_word("void") and tk::is_op(self.peek(1), ")"):
            self.advance()
        while !self.had_error and !self.at_op(")"):
            let pt = self.cur()
            while self.at_word("varargs") or self.at_word("ref") or self.at_word("const"):
                self.advance()
            let mut typ = "mixed"
            if self.type_at(0):
                typ = self.parse_base_type()
            typ = concat(typ, stars(self.count_stars()))
            let mut is_ref = false
            if self.at_word("ref"):
                self.advance()
                is_ref = true
            let mut name = ""
            if self.at_id():
                name = self.advance().text
            let varargs = self.accept_op("...")
            # FluffOS default-argument syntax: `int x: (: 5 :)`
            let mut default = -1
            if self.accept_op(":"):
                default = self.parse_assign()
            params.push(self.add(ast::NodeKind::Param(typ = typ, name = name, is_ref = is_ref, varargs = varargs, default = default), pt))
            if !self.accept_op(","):
                break
        self.expect_op(")")
        params

    fn parse_function_rest(mut self, name: str, mods: List<str>, rtype: str, at: tk::Token) -> i32:
        let params = self.parse_params()
        let mut body = -1
        if !self.accept_op(";"):
            body = self.parse_block()
        self.add(ast::NodeKind::Func(name = name, mods = mods, typ = rtype, params = params, body = body), at)

    # --- statements ------------------------------------------------------

    fn parse_block(mut self) -> i32:
        let t = self.cur()
        self.expect_op("{")
        let mut stmts: List<i32> = List<i32>()
        while !self.had_error and !self.at_op("}"):
            if self.at_eof():
                self.fail("Unexpected end of file in block")
                return -1
            stmts.push(self.parse_statement())
        self.expect_op("}")
        self.add(ast::NodeKind::Block(stmts = stmts), t)

    # Does a local declaration start here?
    fn decl_at(self) -> bool:
        if !self.at_id():
            return false
        let w = self.cur().text
        if w == "function":
            return !tk::is_op(self.peek(1), "(")
        if w == "class" or w == "struct":
            return self.peek(1).kind == tk::Tk::Id and !tk::is_op(self.peek(2), "{")
        if is_modifier(w):
            return self.peek(1).kind == tk::Tk::Id
        self.type_at(0)

    fn parse_local_decl(mut self, semicolon: bool) -> i32:
        let t = self.cur()
        self.parse_modifiers()
        let base = self.parse_base_type()
        let mut decls: List<i32> = List<i32>()
        let mut more = true
        while more and !self.had_error:
            let st = stars(self.count_stars())
            let nt = self.cur()
            let name = self.expect_id()
            let mut init = -1
            if self.accept_op("="):
                init = self.parse_assign()
            decls.push(self.add(ast::NodeKind::Decl(name = name, typ = concat(base, st), init = init), nt))
            more = self.accept_op(",")
        if semicolon:
            self.expect_op(";")
        self.add(ast::NodeKind::Ldecl(decls = decls), t)

    # `( expr )` after a statement keyword
    fn paren_cond(mut self) -> i32:
        self.expect_op("(")
        let c = self.parse_comma()
        self.expect_op(")")
        c

    fn parse_statement(mut self) -> i32:
        let t = self.cur()
        if self.at_op("{"):
            return self.parse_block()
        if self.at_op(";"):
            self.advance()
            return self.add(ast::NodeKind::Empty, t)

        if t.kind == tk::Tk::Id:
            let w = t.text
            if w == "if":
                self.advance()
                let c = self.paren_cond()
                let then = self.parse_statement()
                let mut els = -1
                if !self.had_error and self.at_word("else"):
                    self.advance()
                    els = self.parse_statement()
                return self.add(ast::NodeKind::If(cond = c, then = then, els = els), t)
            if w == "while":
                self.advance()
                let c = self.paren_cond()
                let body = self.parse_statement()
                return self.add(ast::NodeKind::While(cond = c, body = body), t)
            if w == "do":
                self.advance()
                let body = self.parse_statement()
                if !self.had_error and !self.at_word("while"):
                    self.fail("Expected 'while' after do body")
                    return -1
                self.advance()
                let c = self.paren_cond()
                self.expect_op(";")
                return self.add(ast::NodeKind::Do(cond = c, body = body), t)
            if w == "for":
                self.advance()
                self.expect_op("(")
                let mut init = -1
                if !self.had_error and !self.at_op(";"):
                    if self.decl_at():
                        init = self.parse_local_decl(false)
                    else:
                        let e = self.parse_comma()
                        init = self.add(ast::NodeKind::ExprStmt(e = e), self.here())
                self.expect_op(";")
                let mut cond = -1
                if !self.had_error and !self.at_op(";"):
                    cond = self.parse_comma()
                self.expect_op(";")
                let mut step = -1
                if !self.had_error and !self.at_op(")"):
                    step = self.parse_comma()
                self.expect_op(")")
                let body = self.parse_statement()
                return self.add(ast::NodeKind::For(init = init, cond = cond, step = step, body = body), t)
            if w == "foreach":
                return self.parse_foreach(t)
            if w == "switch":
                self.advance()
                let e = self.paren_cond()
                let body = self.parse_block()
                return self.add(ast::NodeKind::Switch(e = e, body = body), t)
            if w == "case":
                self.advance()
                let mut lo = -1
                let mut hi = -1
                let mut open_lo = false
                if self.at_op(".."):
                    self.advance()
                    open_lo = true
                    hi = self.parse_cond()
                else:
                    lo = self.parse_cond()
                    if self.accept_op(".."):
                        if !self.at_op(":"):
                            hi = self.parse_cond()
                        else:
                            hi = self.add(ast::NodeKind::LitOpen, self.here())
                self.expect_op(":")
                return self.add(ast::NodeKind::Case(lo = lo, hi = hi, open_lo = open_lo), t)
            if w == "default" and tk::is_op(self.peek(1), ":"):
                self.advance()
                self.advance()
                return self.add(ast::NodeKind::Default, t)
            if w == "break":
                self.advance()
                self.expect_op(";")
                return self.add(ast::NodeKind::Break, t)
            if w == "continue":
                self.advance()
                self.expect_op(";")
                return self.add(ast::NodeKind::Continue, t)
            if w == "return":
                self.advance()
                let mut e = -1
                if !self.at_op(";"):
                    e = self.parse_comma()
                self.expect_op(";")
                return self.add(ast::NodeKind::Return(e = e), t)
            if self.decl_at():
                return self.parse_local_decl(true)

        let e = self.parse_comma()
        self.expect_op(";")
        self.add(ast::NodeKind::ExprStmt(e = e), t)

    fn parse_foreach(mut self, t: tk::Token) -> i32:
        self.advance()
        self.expect_op("(")
        let mut vars: List<i32> = List<i32>()
        let mut more = true
        while more and !self.had_error:
            let vt = self.cur()
            if self.at_word("ref"):
                self.advance()
            let mut typ = ""
            if self.decl_at():
                typ = self.parse_base_type()
                typ = concat(typ, stars(self.count_stars()))
            if self.at_word("ref"):
                self.advance()
            let name = self.expect_id()
            vars.push(self.add(ast::NodeKind::FeVar(name = name, typ = typ), vt))
            more = self.accept_op(",")
        if !self.had_error and !self.at_word("in"):
            self.fail("Expected 'in' in foreach")
            return -1
        self.advance()
        let e = self.parse_comma()
        self.expect_op(")")
        let body = self.parse_statement()
        self.add(ast::NodeKind::Foreach(vars = vars, e = e, body = body), t)

    # --- expressions -----------------------------------------------------

    fn parse_comma(mut self) -> i32:
        let mut e = self.parse_assign()
        while !self.had_error and self.at_op(","):
            let t = self.advance()
            let r = self.parse_assign()
            e = self.add(ast::NodeKind::Comma(l = e, r = r), t)
        e

    fn parse_assign(mut self) -> i32:
        let l = self.parse_cond()
        let t = self.cur()
        if !self.had_error and t.kind == tk::Tk::Op and is_assign_op(t.text):
            self.advance()
            let r = self.parse_assign()
            return self.add(ast::NodeKind::Assign(op = t.text, l = l, r = r), t)
        l

    fn parse_cond(mut self) -> i32:
        let c = self.parse_binary(1)
        if !self.had_error and self.at_op("?"):
            let t = self.advance()
            let a = self.parse_comma()
            self.expect_op(":")
            let b = self.parse_assign()
            return self.add(ast::NodeKind::Cond(c = c, a = a, b = b), t)
        c

    fn parse_binary(mut self, min_prec: i32) -> i32:
        let mut l = self.parse_unary()
        while !self.had_error:
            let t = self.cur()
            if t.kind != tk::Tk::Op:
                break
            let prec = binary_prec(t.text)
            if prec == 0 or prec < min_prec:
                break
            self.advance()
            let r = self.parse_binary(prec + 1)
            l = self.add(ast::NodeKind::Bin(op = t.text, l = l, r = r), t)
        l

    # Is "(" at p the start of a cast?
    fn cast_at(self) -> bool:
        if !self.at_op("("):
            return false
        let t = self.peek(1)
        if t.kind != tk::Tk::Id:
            return false
        let w = t.text
        let mut off = 2
        if w == "class" or w == "struct":
            if self.peek(2).kind != tk::Tk::Id:
                return false
            off = 3
        elif !is_type_word(w):
            return false
        elif w == "function" and tk::is_op(self.peek(2), "("):
            return false
        while tk::is_op(self.peek(off), "*") or tk::is_id(self.peek(off), "array"):
            off += 1
        if !tk::is_op(self.peek(off), ")"):
            return false
        # the cast operand must follow; `(status) + 1` is a parenthesised name
        let nx = self.peek(off + 1)
        if nx.kind == tk::Tk::Op:
            let o = nx.text
            return o == "(" or o == "({" or o == "([" or o == "(:" or o == "!" or o == "~" or o == "::" or o == "-" or o == "++" or o == "--" or o == "*"
        nx.kind != tk::Tk::Eof

    fn parse_unary(mut self) -> i32:
        let t = self.cur()
        if t.kind == tk::Tk::Op:
            let o = t.text
            if o == "!" or o == "~" or o == "-" or o == "+" or o == "++" or o == "--":
                self.advance()
                let e = self.parse_unary()
                return self.add(ast::NodeKind::Un(op = o, e = e), t)
            # `*f` (function dereference) and `&x` (reference-taking) are no-ops
            if o == "*" or o == "&":
                self.advance()
                return self.parse_unary()
            if o == "(" and self.cast_at():
                self.advance()
                let mut typ = self.parse_base_type()
                typ = concat(typ, stars(self.count_stars()))
                self.expect_op(")")
                let e = self.parse_unary()
                return self.add(ast::NodeKind::Cast(typ = typ, e = e), t)
        let prim = self.parse_primary()
        let e = self.parse_postfix(prim)
        if self.had_error:
            return -1
        # FluffOS's grammar binds an assignment to the nearest lvalue on its
        # left, whatever operators precede it: `!x = f()` is `!(x = f())`
        # and `a && b = c` is `a && (b = c)`.
        let at = self.cur()
        if at.kind == tk::Tk::Op and is_assign_op(at.text) and self.is_lvalue_kind(e):
            self.advance()
            let r = self.parse_assign()
            return self.add(ast::NodeKind::Assign(op = at.text, l = e, r = r), at)
        e

    fn is_lvalue_kind(self, e: i32) -> bool:
        match self.nodes[e].kind:
            ast::NodeKind::Id(a) -> true
            ast::NodeKind::Index(a, b, c) -> true
            ast::NodeKind::Member(a, b) -> true
            ast::NodeKind::Range(a, b, c, d, f) -> true
            _ -> false

    fn parse_args(mut self, close: str) -> List<i32>:
        let mut args: List<i32> = List<i32>()
        while !self.had_error and !self.at_op(close):
            let t = self.cur()
            if self.at_word("ref") and self.peek(1).kind == tk::Tk::Id:
                self.advance()
            let mut a = self.parse_assign()
            if self.accept_op("..."):
                a = self.add(ast::NodeKind::Spread(e = a), t)
            args.push(a)
            if !self.accept_op(","):
                break
        self.expect_op(close)
        args

    fn parse_postfix(mut self, start: i32) -> i32:
        let mut e = start
        while !self.had_error:
            let t = self.cur()
            if t.kind != tk::Tk::Op:
                break
            let o = t.text
            if o == "[":
                self.advance()
                let mut lo_end = false
                let mut hi_end = false
                let mut hi = -1
                if self.at_op(".."):
                    self.advance()
                    if self.accept_op("<"):
                        hi_end = true
                    if !self.at_op("]"):
                        hi = self.parse_comma()
                    self.expect_op("]")
                    e = self.add(ast::NodeKind::Range(e = e, lo = -1, lo_end = false, hi = hi, hi_end = hi_end), t)
                    continue
                if self.accept_op("<"):
                    lo_end = true
                let lo = self.parse_comma()
                if self.accept_op(".."):
                    if self.accept_op("<"):
                        hi_end = true
                    if !self.had_error and !self.at_op("]"):
                        hi = self.parse_comma()
                    self.expect_op("]")
                    e = self.add(ast::NodeKind::Range(e = e, lo = lo, lo_end = lo_end, hi = hi, hi_end = hi_end), t)
                else:
                    self.expect_op("]")
                    e = self.add(ast::NodeKind::Index(e = e, i = lo, from_end = lo_end), t)
            elif o == "->":
                self.advance()
                let mut name = ""
                let mut name_expr = -1
                if self.at_op("("):
                    # ob->(expr)(args)
                    self.advance()
                    name_expr = self.parse_comma()
                    self.expect_op(")")
                else:
                    name = self.expect_id()
                if !self.had_error and self.at_op("("):
                    self.advance()
                    let args = self.parse_args(")")
                    e = self.add(ast::NodeKind::Arrow(obj = e, name = name, name_expr = name_expr, args = args), t)
                else:
                    e = self.add(ast::NodeKind::Member(obj = e, name = name), t)
            elif o == "(":
                self.advance()
                let args = self.parse_args(")")
                e = self.add(ast::NodeKind::Callv(f = e, args = args), t)
            elif o == "++" or o == "--":
                self.advance()
                e = self.add(ast::NodeKind::Post(op = o, e = e), t)
            else:
                break
        e

    # `catch`/`time_expression`: a block or a parenthesised expression
    # Returns (expr, block) packed as a two-element list.
    fn block_or_paren(mut self) -> List<i32>:
        if self.at_op("{"):
            return [-1, self.parse_block()]
        [self.paren_cond(), -1]

    # `label::name(args)` / `label::name` after the `::`
    fn parse_scall_rest(mut self, label: str, t: tk::Token) -> i32:
        let name = self.expect_id()
        if !self.had_error and self.at_op("("):
            self.advance()
            let args = self.parse_args(")")
            return self.add(ast::NodeKind::Scall(label = label, name = name, args = args, is_ref = false), t)
        self.add(ast::NodeKind::Scall(label = label, name = name, args = List<i32>(), is_ref = true), t)

    fn parse_primary(mut self) -> i32:
        if self.had_error:
            return -1
        let t = self.cur()
        if t.kind == tk::Tk::Int:
            self.advance()
            return self.add(ast::NodeKind::LitInt(v = t.ival), t)
        if t.kind == tk::Tk::Float:
            self.advance()
            return self.add(ast::NodeKind::LitFloat(v = t.fval), t)
        if t.kind == tk::Tk::Str:
            let mut parts: List<str> = List<str>()
            while self.cur().kind == tk::Tk::Str:
                parts.push(self.advance().text)
            return self.add(ast::NodeKind::LitStr(v = str_join(parts, "")), t)
        if t.kind == tk::Tk::Dollar:
            self.advance()
            if t.ival == (0 as i64):
                let e = self.parse_comma()
                self.expect_op(")")
                return self.add(ast::NodeKind::DollarExpr(e = e), t)
            return self.add(ast::NodeKind::Dollar(n = t.ival), t)
        if t.kind == tk::Tk::Op:
            return self.parse_primary_op(t)
        if t.kind == tk::Tk::Id:
            return self.parse_primary_id(t)
        self.fail("Unexpected token")
        -1

    fn parse_primary_op(mut self, t: tk::Token) -> i32:
        let o = t.text
        if o == "(":
            self.advance()
            let e = self.parse_comma()
            self.expect_op(")")
            return self.add(ast::NodeKind::Paren(e = e), t)
        if o == "({":
            self.advance()
            let mut items: List<i32> = List<i32>()
            while !self.had_error and !self.at_op("}"):
                let it = self.cur()
                let mut a = self.parse_assign()
                if self.accept_op("..."):
                    a = self.add(ast::NodeKind::Spread(e = a), it)
                items.push(a)
                if !self.accept_op(","):
                    break
            self.expect_op("}")
            self.expect_op(")")
            return self.add(ast::NodeKind::Arr(items = items), t)
        if o == "([":
            self.advance()
            let mut pairs: List<i32> = List<i32>()
            while !self.had_error and !self.at_op("]"):
                let k = self.parse_cond()
                let mut v = -1
                if self.accept_op(":"):
                    v = self.parse_assign()
                else:
                    v = self.add(ast::NodeKind::LitInt(v = 1 as i64), self.here())
                pairs.push(k)
                pairs.push(v)
                if !self.accept_op(","):
                    break
            self.expect_op("]")
            self.expect_op(")")
            return self.add(ast::NodeKind::Map(pairs = pairs), t)
        if o == "(:":
            return self.parse_functional()
        if o == "::":
            self.advance()
            return self.parse_scall_rest("", t)
        self.fail("Unexpected token")
        -1

    fn parse_primary_id(mut self, t: tk::Token) -> i32:
        let w = t.text
        if tk::is_op(self.peek(1), "::"):
            self.advance()
            self.advance()
            return self.parse_scall_rest(w, t)
        if w == "catch":
            self.advance()
            let eb = self.block_or_paren()
            return self.add(ast::NodeKind::Catch(e = eb[0], block = eb[1]), t)
        if w == "time_expression":
            self.advance()
            let eb = self.block_or_paren()
            return self.add(ast::NodeKind::TimeExpr(e = eb[0], block = eb[1]), t)
        if (w == "sscanf" or w == "parse_command") and tk::is_op(self.peek(1), "("):
            self.advance()
            self.advance()
            let args = self.parse_args(")")
            if w == "sscanf":
                return self.add(ast::NodeKind::Sscanf(args = args), t)
            return self.add(ast::NodeKind::ParseCommand(args = args), t)
        if w == "new" and tk::is_op(self.peek(1), "("):
            self.advance()
            self.advance()
            if self.at_word("class") or self.at_word("struct"):
                self.advance()
                let cname = self.expect_id()
                let mut fields: List<str> = List<str>()
                let mut values: List<i32> = List<i32>()
                while self.accept_op(","):
                    fields.push(self.expect_id())
                    self.expect_op(":")
                    values.push(self.parse_assign())
                self.expect_op(")")
                return self.add(ast::NodeKind::NewClass(name = cname, fields = fields, values = values), t)
            let args = self.parse_args(")")
            return self.add(ast::NodeKind::New(args = args), t)
        if w == "function" and tk::is_op(self.peek(1), "("):
            self.advance()
            let params = self.parse_params()
            let body = self.parse_block()
            return self.add(ast::NodeKind::Lambda(params = params, body = body), t)
        self.advance()
        if self.at_op("("):
            self.advance()
            let args = self.parse_args(")")
            return self.add(ast::NodeKind::Call(name = w, args = args), t)
        self.add(ast::NodeKind::Id(name = w), t)

    # `, args... :)` tail of a named function pointer
    fn fptr_args(mut self) -> List<i32>:
        let mut args: List<i32> = List<i32>()
        while self.accept_op(","):
            if self.at_op(":)"):
                break
            args.push(self.parse_assign())
        self.expect_op(":)")
        args

    fn parse_functional(mut self) -> i32:
        let t = self.expect_op("(:")
        let p1 = self.peek(1)
        # (: name :)  /  (: name, args... :)
        if self.at_id() and (tk::is_op(p1, ":)") or tk::is_op(p1, ",")):
            let name = self.advance().text
            let args = self.fptr_args()
            return self.add(ast::NodeKind::FptrName(name = name, args = args), t)
        # (: label::name :) / (: efun::name, args :)
        let p2 = self.peek(2)
        let p3 = self.peek(3)
        let labelled = self.at_id() and tk::is_op(p1, "::") and p2.kind == tk::Tk::Id and (tk::is_op(p3, ":)") or tk::is_op(p3, ","))
        let bare = self.at_op("::") and p1.kind == tk::Tk::Id and (tk::is_op(p2, ":)") or tk::is_op(p2, ","))
        if labelled or bare:
            let mut label = ""
            if self.at_id():
                label = self.advance().text
            self.advance()
            let name = self.expect_id()
            let args = self.fptr_args()
            return self.add(ast::NodeKind::FptrScoped(label = label, name = name, args = args), t)
        let e = self.parse_comma()
        self.expect_op(":)")
        self.add(ast::NodeKind::FptrExpr(e = e), t)

# Parse a whole token stream (ending in `Eof`). On success `p.top` holds the
# top-level node indices in source order; on failure `p.had_error`/`p.error`.
fn parse_tokens(toks: List<tk::Token>, files: List<str>) -> Parser:
    let mut p = new_parser(toks, files)
    p.parse_program()
    p

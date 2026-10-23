# LPC preprocessor -- replaces HavokOS `pike/lpc/preprocess.pike` *and* the
# Pike built-in `cpp()` it wraps, todo.md HavokOS M1.
#
# The reference leans on Pike's own C preprocessor and spends most of its
# 370 lines working around it: rewriting `#include MACRO` to a literal
# because of a Pike 8.0 conditional-stack bug (`fix_includes`), splicing
# `efun_defined(x)` to 0/1 by text substitution (`fix_efun_defined`),
# trimming junk after `#ifdef NAME` (`fix_lexical`), turning text blocks and
# raw-newline strings into something `cpp()` accepts. None of that is
# needed when the preprocessor is ours: `#include MACRO` is just ordinary
# macro expansion of the directive's operand, `efun_defined` is evaluated
# where it appears, `#ifdef` reads one identifier, and the lexer
# (`lexer.star`) already handles text blocks and raw newlines. What *is*
# kept from the reference is every observable behavior: the predefined
# macro set (`create()`), the include search rules (`Handler::
# handle_include`), the auto-included `<global.h>`, `__FILE__` always naming
# the file being compiled (the reference `#undef`s Pike's own per-include
# `__FILE__`), and the line numbers the reference's tokens end up with.
#
# Design: token-level, not text-level. Each file is lexed once (header
# token lists are cached, since every program pulls in the same
# `<global.h>` tree), then walked a run at a time: the tokens between two
# directives are macro-expanded as one batch (`expand_all`), then the
# directive is executed. Flushing before every directive is what makes a
# `#define`/`#undef` take effect at exactly its own position.
#
# Macro expansion follows Pike `cpp()`, which is *not* quite ISO C, so
# these rules were pinned down by diffing against it
# (`tests/fixtures/pplib/sub/pp_cases.c`), not taken from the C standard:
#   - Each expansion is rescanned in isolation. A function-like macro name
#     only starts an invocation if its `(` and arguments are in the same
#     token frame, so `#define H F` then `H(5)` leaves `F (5)` alone, where
#     C would let `F` take `(5)` from the text after the expansion.
#   - A macro is disabled while its own expansion is being rescanned, but
#     there's no permanent C-style "blue paint". With `#define foo foo + 1`,
#     `FIRST(foo, 0)` gives `foo + 1 + 1`: the argument is pre-expanded once
#     (`foo + 1`, the inner `foo` blocked), then rescanning `FIRST`'s body
#     expands that bare `foo` one more time.
#   - Arguments are fully expanded before substitution, except where used
#     with `#`/`##`.
# Implementation: a stack of token frames, an expansion pushing its
# substituted body as a new frame. Every token an expansion produces
# carries the line and file of the outermost invocation that started it
# (the macro name's line for an object-like macro, the closing paren's for
# a function-like one), since `cpp()` emits the expansion inline there.

import "token.star" as tk
import "lexer.star" as lx
import "paths.star" as paths

struct Macro:
    func: bool
    params: List<str>
    body: List<tk::Token>

struct Frame:
    toks: List<tk::Token>
    mut pos: i32 = 0
    macro: str = ""

struct Cond:
    mut active: bool
    mut taken: bool
    parent: bool
    file_depth: i32

struct Pp:
    # filesystem path of the mudlib root, no trailing slash
    root: str
    ops: List<List<lx::OpEntry>>
    mut include_dirs: List<str>
    mut global_include: str = "global.h"
    mut predefines: Map<str, Macro> = Map<str, Macro>()
    # names efun_defined() reports as defined
    mut efun_names: Set<str> = Set<str>()
    # file id -> vpath, and back
    mut files: List<str> = List<str>()
    mut file_ids: Map<str, i32> = Map<str, i32>()
    # lexed header token lists, by vpath
    mut lex_cache: Map<str, List<tk::Token>> = Map<str, List<tk::Token>>()
    # --- per-run state, reset by preprocess() ---
    mut macros: Map<str, Macro> = Map<str, Macro>()
    mut conds: List<Cond> = List<Cond>()
    mut out: List<tk::Token> = List<tk::Token>()
    mut included: List<str> = List<str>()
    mut depth: i32 = 0
    mut had_error: bool = false
    mut error: str = ""

fn new_pp(root: str) -> Pp:
    let mut pp = Pp(root = root, ops = lx::op_table(), include_dirs = ["/secure/include", "/include"])
    pp.init_predefines()
    pp

# The reference's spelling of the host OS for __ARCH__ (`host_arch()`).
fn host_arch() -> str:
    "\"Microsoft Windows NT\""

impl Pp:
    fn fail(mut self, file: i32, line: i32, msg: str):
        if !self.had_error:
            self.had_error = true
            self.error = f"{self.files[file]}:{line}: {msg}"

    fn file_id(mut self, vpath: str) -> i32:
        if let Option::Some(id) = self.file_ids.get(vpath):
            return id
        let id = self.files.len()
        self.files.push(vpath)
        self.file_ids.insert(vpath, id)
        id

    fn object_macro(self, value: str) -> Macro:
        Macro(func = false, params = List<str>(), body = lx::lex_fragment(value, 0, 0, self.ops))

    fn predefine(mut self, name: str, value: str):
        let m = self.object_macro(value)
        self.predefines.insert(name, m)

    # The reference `preprocess.pike::create()` table, value for value.
    fn init_predefines(mut self):
        let empty: List<str> = ["MUDOS", "FLUFFOS", "__FLUFFOS__", "__DSLIB__",
            "__PACKAGE_DSLIB__", "__SANE_EXPLODE_STRING__", "__NO_LIGHT__",
            "__CUSTOM_CRYPT__", "__GET_CHAR_IS_BUFFERED__",
            "__ARRAY_RESERVED_WORD__", "__REF_RESERVED_WORD__",
            "__PACKAGE_MATH__", "__PACKAGE_DEVELOP__", "__PACKAGE_CONTRIB__",
            "__PACKAGE_PARSER__", "__PACKAGE_MUDLIB_STATS__",
            "__PACKAGE_SOCKETS__", "__PRIVS__", "__STRUCT_CLASS__",
            "__CALLOUT_HANDLES__", "__THIS_PLAYER_IN_CALL_OUT__",
            "__NO_RESETS__", "__INTERACTIVE_CATCH_TELL__",
            "__MUDLIB_ERROR_HANDLER__", "HAS_ED", "HAS_PRINTF",
            "__WINDOWS__", "__WIN32__"]
        for i in 0..empty.len():
            self.predefine(empty[i], "")
        self.predefine("__SAVE_EXTENSION__", "\".o\"")
        self.predefine("__SAVE_GZ_EXTENSION__", "\".o.gz\"")
        self.predefine("__LARGEST_PRINTABLE_STRING__", "32768")
        self.predefine("__HEARTBEAT_INTERVAL__", "1")
        self.predefine("__CFG_MAX_CALL_DEPTH__", "150")
        self.predefine("__VERSION__", "\"HavokOS 0.2\"")
        self.predefine("__ARCH__", host_arch())
        self.predefine("__COMPILER__", "\"pike\"")
        self.predefine("__OPTIMIZATION__", "\"\"")
        self.predefine("__PORT__", "6666")
        self.predefine("__FD_SETSIZE__", "1024")
        self.predefine("SIZEOFINT", "8")
        self.predefine("MAX_INT", "9223372036854775807")

    fn define(mut self, name: str, value: str):
        let m = self.object_macro(value)
        self.macros.insert(name, m)

    fn active(self) -> bool:
        if self.conds.len() == 0:
            true
        else:
            self.conds[self.conds.len() - 1].active

    fn read_file(self, vpath: str) -> Option<Bytes>:
        let f = file_open(concat(self.root, vpath), "rb")
        if is_null(f):
            return Option<Bytes>::None
        let b = file_read_bytes(f)
        file_close(f)
        Option<Bytes>::Some(b)

    fn exists(self, vpath: str) -> bool:
        file_exists(concat(self.root, vpath))

    # Lex `vpath`, from the cache if `cache` and it was lexed before.
    fn lex_vpath(mut self, vpath: str, cache: bool) -> Option<List<tk::Token>>:
        if cache:
            if let Option::Some(t) = self.lex_cache.get(vpath):
                return Option<List<tk::Token>>::Some(t)
        let fid = self.file_id(vpath)
        match self.read_file(vpath):
            Option::Some(raw) ->
                let toks = lx::lex_file(raw, fid, self.ops)
                if cache:
                    self.lex_cache.insert(vpath, toks)
                Option<List<tk::Token>>::Some(toks)
            Option::None -> Option<List<tk::Token>>::None

    # --- macro expansion -------------------------------------------------

    fn is_disabled(self, name: str, frames: List<Frame>, outer: List<str>) -> bool:
        for i in 0..frames.len():
            if frames[i].macro == name:
                return true
        for i in 0..outer.len():
            if outer[i] == name:
                return true
        false

    # Spelling of a token sequence, for `#param` stringification.
    fn spell(self, toks: List<tk::Token>) -> str:
        let mut parts: List<str> = List<str>()
        for i in 0..toks.len():
            let t = toks[i]
            if i > 0 and t.space:
                parts.push(" ")
            parts.push(self.spell_one(t))
        str_join(parts, "")

    fn spell_one(self, t: tk::Token) -> str:
        match t.kind:
            tk::Tk::Int -> f"{t.ival}"
            tk::Tk::Float -> t.text
            tk::Tk::Str -> concat(concat("\"", str_replace(str_replace(t.text, "\\", "\\\\"), "\"", "\\\"")), "\"")
            tk::Tk::Dollar -> if t.ival == (0 as i64): "$(" else: f"${t.ival}"
            _ -> t.text

    fn stamp(self, t: tk::Token, line: i32, file: i32) -> tk::Token:
        tk::Token(kind = t.kind, text = t.text, ival = t.ival, fval = t.fval, line = line, file = file, bol = false, space = t.space)

    fn param_index(self, m: Macro, name: str) -> i32:
        for i in 0..m.params.len():
            if m.params[i] == name:
                return i
        -1

    # Substitute `args` (raw) / `xargs` (pre-expanded) into `m`'s body.
    fn substitute(mut self, m: Macro, args: List<List<tk::Token>>, xargs: List<List<tk::Token>>, line: i32, file: i32) -> List<tk::Token>:
        let mut res: List<tk::Token> = List<tk::Token>()
        let body = m.body
        let mut i = 0
        while i < body.len():
            let t = body[i]
            # `#param` -> string literal of the raw argument
            if m.func and tk::is_op(t, "#") and i + 1 < body.len() and body[i + 1].kind == tk::Tk::Id:
                let p = self.param_index(m, body[i + 1].text)
                if p >= 0:
                    res.push(tk::Token(kind = tk::Tk::Str, text = self.spell(args[p]), line = line, file = file, space = t.space))
                    i += 2
                    continue
            # `a ## b` -> one token re-lexed from the joined spelling
            if tk::is_op(t, "#") and i + 1 < body.len() and tk::is_op(body[i + 1], "#") and !body[i + 1].space and res.len() > 0 and i + 2 < body.len():
                let left = res.pop()
                let rt = body[i + 2]
                let mut right: List<tk::Token> = List<tk::Token>()
                let mut p = -1
                if m.func and rt.kind == tk::Tk::Id:
                    p = self.param_index(m, rt.text)
                if p >= 0:
                    right = args[p]
                else:
                    right.push(rt)
                let joined = if right.len() > 0: concat(self.spell_one(left), self.spell_one(right[0])) else: self.spell_one(left)
                let pasted = lx::lex_fragment(joined, file, line, self.ops)
                for k in 0..pasted.len():
                    res.push(self.stamp(pasted[k], line, file))
                for k in 1..right.len():
                    res.push(self.stamp(right[k], line, file))
                i += 3
                continue
            if m.func and t.kind == tk::Tk::Id:
                let p = self.param_index(m, t.text)
                if p >= 0:
                    # an argument adjacent to `##` is used unexpanded
                    let pasting = i + 2 < body.len() and tk::is_op(body[i + 1], "#") and tk::is_op(body[i + 2], "#") and !body[i + 2].space
                    let src = if pasting: args[p] else: xargs[p]
                    for k in 0..src.len():
                        let a = src[k]
                        let s = if k == 0: t.space else: a.space
                        res.push(tk::Token(kind = a.kind, text = a.text, ival = a.ival, fval = a.fval, line = line, file = file, space = s))
                    i += 1
                    continue
            res.push(self.stamp(t, line, file))
            i += 1
        res

    # Fully macro-expand `input` with the macros in `outer` disabled.
    fn expand_all(mut self, input: List<tk::Token>, outer: List<str>) -> List<tk::Token>:
        let mut out: List<tk::Token> = List<tk::Token>()
        let mut frames: List<Frame> = List<Frame>()
        frames.push(Frame(toks = input))
        let mut sline = 0
        let mut sfile = 0
        while true:
            while frames.len() > 0 and frames[frames.len() - 1].pos >= frames[frames.len() - 1].toks.len():
                frames.pop()
            if frames.len() == 0:
                break
            let top = frames.len() - 1
            let t = frames[top].toks[frames[top].pos]
            frames[top].pos += 1
            if t.kind != tk::Tk::Id:
                out.push(t)
                continue
            let name = t.text
            if name == "__LINE__":
                let ln = if frames.len() > 1: sline else: t.line
                out.push(tk::Token(kind = tk::Tk::Int, ival = ln as i64, line = t.line, file = t.file, space = t.space))
                continue
            let found = self.macros.get(name)
            if let Option::Some(m) = found:
                if self.is_disabled(name, frames, outer):
                    out.push(t)
                    continue
                let at_base = frames.len() == 1
                if at_base:
                    sline = t.line
                    sfile = t.file
                if !m.func:
                    let empty: List<List<tk::Token>> = List<List<tk::Token>>()
                    let body = self.substitute(m, empty, empty, sline, sfile)
                    frames.push(Frame(toks = body, macro = name))
                    continue
                # function-like: only an invocation if `(` comes next *in the
                # same frame* -- cpp() rescans each expansion in isolation,
                # so `#define H F` then `H(5)` leaves `F (5)` unexpanded
                let ftoks = frames[top].toks
                let mut ap = frames[top].pos
                if ap >= ftoks.len() or !tk::is_op(ftoks[ap], "("):
                    out.push(t)
                    continue
                ap += 1
                # collect the arguments, again within this frame only
                let mut args: List<List<tk::Token>> = List<List<tk::Token>>()
                let mut cur: List<tk::Token> = List<tk::Token>()
                let mut level = 0
                let mut closed = false
                while ap < ftoks.len():
                    let a = ftoks[ap]
                    ap += 1
                    if a.kind == tk::Tk::Op and (a.text == "(" or a.text == "({" or a.text == "([" or a.text == "(:"):
                        level += 1
                    elif a.kind == tk::Tk::Dollar and a.ival == (0 as i64):
                        level += 1
                    elif a.kind == tk::Tk::Op and (a.text == ")" or a.text == ":)"):
                        if level == 0:
                            closed = true
                            # cpp() emits a function-like expansion where
                            # the invocation *ends*, so a multi-line call's
                            # tokens report its closing paren's line
                            if at_base:
                                sline = a.line
                            break
                        level -= 1
                    elif level == 0 and tk::is_op(a, ","):
                        args.push(cur)
                        cur = List<tk::Token>()
                        continue
                    cur.push(a)
                frames[top].pos = ap
                if !closed:
                    self.fail(t.file, t.line, f"Unterminated call to macro {name}")
                    return out
                if args.len() > 0 or cur.len() > 0 or m.params.len() > 0:
                    args.push(cur)
                if args.len() != m.params.len():
                    self.fail(t.file, t.line, f"Wrong number of arguments to macro {name}")
                    return out
                let mut dis: List<str> = List<str>()
                for k in 0..outer.len():
                    dis.push(outer[k])
                for k in 0..frames.len():
                    if frames[k].macro != "":
                        dis.push(frames[k].macro)
                let mut xargs: List<List<tk::Token>> = List<List<tk::Token>>()
                for k in 0..args.len():
                    xargs.push(self.expand_all(args[k], dis))
                let body = self.substitute(m, args, xargs, sline, sfile)
                frames.push(Frame(toks = body, macro = name))
                continue
            if name == "efun_defined":
                # efun_defined(name) -> 1 / 0, wherever it appears
                let ti = frames.len() - 1
                let ft = frames[ti].toks
                let p = frames[ti].pos
                if p + 2 < ft.len() and tk::is_op(ft[p], "(") and ft[p + 1].kind == tk::Tk::Id and tk::is_op(ft[p + 2], ")"):
                    let v = if self.efun_names.contains(ft[p + 1].text): 1 else: 0
                    frames[ti].pos += 3
                    out.push(tk::Token(kind = tk::Tk::Int, ival = v as i64, line = t.line, file = t.file, space = t.space))
                    continue
            out.push(t)
        out

    fn emit_run(mut self, run: List<tk::Token>):
        if run.len() == 0:
            return
        let none: List<str> = List<str>()
        let x = self.expand_all(run, none)
        for i in 0..x.len():
            self.out.push(x[i])

    # --- directives ------------------------------------------------------

    fn directive(mut self, d: tk::Token):
        let dt = lx::lex_fragment(d.text, d.file, d.line, self.ops)
        if dt.len() == 0:
            return
        let kw = dt[0].text
        if dt[0].kind != tk::Tk::Id:
            # `# 12 "file"` line markers and the like
            return
        if kw == "if" or kw == "ifdef" or kw == "ifndef":
            let parent = self.active()
            let mut c = false
            if parent:
                if kw == "if":
                    c = self.eval_if(dt, d)
                elif dt.len() > 1:
                    let has = self.macros.contains(dt[1].text)
                    c = if kw == "ifdef": has else: !has
                else:
                    self.fail(d.file, d.line, f"#{kw} without a name")
            self.conds.push(Cond(active = c, taken = c, parent = parent, file_depth = self.depth))
            return
        if kw == "elif" or kw == "else" or kw == "endif":
            if self.conds.len() == 0 or self.conds[self.conds.len() - 1].file_depth != self.depth:
                self.fail(d.file, d.line, f"#{kw} without #if")
                return
            let top = self.conds.len() - 1
            if kw == "endif":
                self.conds.pop()
                return
            let c = self.conds[top]
            if kw == "else":
                self.conds[top].active = c.parent and !c.taken
                self.conds[top].taken = true
                return
            if c.taken or !c.parent:
                self.conds[top].active = false
                return
            let v = self.eval_if(dt, d)
            self.conds[top].active = v
            self.conds[top].taken = v
            return
        if !self.active():
            return
        if kw == "define":
            self.do_define(dt, d)
        elif kw == "undef":
            if dt.len() > 1:
                self.macros.remove(dt[1].text)
        elif kw == "include":
            self.do_include(dt, d)
        elif kw == "error":
            self.fail(d.file, d.line, str_trim(d.text))
        # #pragma, #warning, #line, #echo and unknown directives: no effect
        # on the token stream (the reference's lexer skips what cpp leaves)

    fn do_define(mut self, dt: List<tk::Token>, d: tk::Token):
        if dt.len() < 2 or dt[1].kind != tk::Tk::Id:
            self.fail(d.file, d.line, "Bad #define")
            return
        let name = dt[1].text
        let mut i = 2
        let mut func = false
        let mut params: List<str> = List<str>()
        if dt.len() > 2 and tk::is_op(dt[2], "(") and !dt[2].space:
            func = true
            i = 3
            while i < dt.len() and !tk::is_op(dt[i], ")"):
                if dt[i].kind == tk::Tk::Id:
                    params.push(dt[i].text)
                elif tk::is_op(dt[i], "..."):
                    params.push("__VA_ARGS__")
                i += 1
            i += 1
        let mut body: List<tk::Token> = List<tk::Token>()
        while i < dt.len():
            body.push(dt[i])
            i += 1
        self.macros.insert(name, Macro(func = func, params = params, body = body))

    # The reference `Handler::handle_include` search rules.
    fn resolve_include(self, f: str, current: str, local: bool) -> str:
        if str_starts_with(f, "/"):
            return f
        if local:
            let r = paths::combine_path(paths::dirname(current), f)
            if self.exists(r):
                return r
        for k in 0..self.include_dirs.len():
            let r = concat(concat(self.include_dirs[k], "/"), f)
            if self.exists(r):
                return r
        ""

    fn do_include(mut self, dt: List<tk::Token>, d: tk::Token):
        let mut name = ""
        let mut local = false
        let mut ok = false
        let mut rest: List<tk::Token> = List<tk::Token>()
        for i in 1..dt.len():
            rest.push(dt[i])
        if rest.len() > 0 and rest[0].kind != tk::Tk::Str and !tk::is_op(rest[0], "<"):
            let none: List<str> = List<str>()
            rest = self.expand_all(rest, none)
        if rest.len() > 0 and rest[0].kind == tk::Tk::Str:
            name = rest[0].text
            local = true
            ok = true
        elif rest.len() > 0 and tk::is_op(rest[0], "<"):
            # <a/b.h>: rebuild the name from the raw directive text, since
            # the tokens lost the spelling of e.g. `.h`
            let raw = d.text
            let lt = str_index_of(raw, "<")
            let gt = str_index_of(raw, ">")
            if lt >= 0 and gt > lt:
                let b = bytes_from_str(raw)
                let mut w: Bytes = Bytes()
                for k in lt + 1..gt:
                    w.push(b[k])
                name = str_trim(str_from_bytes(w))
                ok = true
        if !ok:
            self.fail(d.file, d.line, "Bad #include")
            return
        let current = self.files[d.file]
        let r = self.resolve_include(name, current, local)
        if r == "":
            self.fail(d.file, d.line, f"Couldn't read include file \"{name}\".")
            return
        self.include_vpath(r, d)

    fn include_vpath(mut self, r: str, d: tk::Token):
        if self.depth > 64:
            self.fail(d.file, d.line, "Include nesting too deep")
            return
        match self.lex_vpath(r, true):
            Option::Some(toks) ->
                self.included.push(r)
                self.run_tokens(toks)
            Option::None -> self.fail(d.file, d.line, f"Couldn't read include file \"{r}\".")

    # --- #if expressions -------------------------------------------------

    fn eval_if(mut self, dt: List<tk::Token>, d: tk::Token) -> bool:
        # defined X / defined(X) / efun_defined(X) first, then expand
        let mut pre: List<tk::Token> = List<tk::Token>()
        let mut i = 1
        while i < dt.len():
            let t = dt[i]
            if t.kind == tk::Tk::Id and (t.text == "defined" or t.text == "efun_defined"):
                let mut nm = ""
                if i + 3 < dt.len() + 0 and tk::is_op(dt[i + 1], "(") and dt[i + 2].kind == tk::Tk::Id and tk::is_op(dt[i + 3], ")"):
                    nm = dt[i + 2].text
                    i += 4
                elif t.text == "defined" and i + 1 < dt.len() and dt[i + 1].kind == tk::Tk::Id:
                    nm = dt[i + 1].text
                    i += 2
                else:
                    self.fail(d.file, d.line, f"Bad {t.text}() in #if")
                    return false
                let has = if t.text == "defined": self.macros.contains(nm) else: self.efun_names.contains(nm)
                pre.push(tk::Token(kind = tk::Tk::Int, ival = if has: 1 as i64 else: 0 as i64, line = d.line, file = d.file))
                continue
            pre.push(t)
            i += 1
        let none: List<str> = List<str>()
        let x = self.expand_all(pre, none)
        let mut ev = IfEval(toks = x)
        let v = ev.ternary()
        if ev.bad or ev.pos < x.len():
            self.fail(d.file, d.line, "Bad #if expression")
            return false
        v != (0 as i64)

    # --- driving ---------------------------------------------------------

    fn run_tokens(mut self, toks: List<tk::Token>):
        self.depth += 1
        let mut run: List<tk::Token> = List<tk::Token>()
        for i in 0..toks.len():
            if self.had_error:
                break
            let t = toks[i]
            if t.kind == tk::Tk::Eof:
                continue
            if t.kind == tk::Tk::Directive:
                self.emit_run(run)
                run = List<tk::Token>()
                self.directive(t)
                continue
            if self.active():
                run.push(t)
        if !self.had_error:
            self.emit_run(run)
        if !self.had_error:
            while self.conds.len() > 0 and self.conds[self.conds.len() - 1].file_depth == self.depth:
                self.conds.pop()
                self.fail(toks[0].file, toks[toks.len() - 1].line, "Missing #endif")
        self.depth -= 1

    # Preprocess one mudlib file (vpath like "/obj/torch.c"). On success
    # `self.out` holds the final token stream ending in `Eof`; on failure
    # `self.had_error`/`self.error` say why.
    fn preprocess(mut self, vpath: str):
        self.macros = self.predefines
        self.conds = List<Cond>()
        self.out = List<tk::Token>()
        self.included = List<str>()
        self.depth = 0
        self.had_error = false
        self.error = ""
        let fid = self.file_id(vpath)
        let dir = paths::dirname(vpath)
        let dir_slash = if str_ends_with(dir, "/"): dir else: concat(dir, "/")
        self.define("__FILE__", concat(concat("\"", vpath), "\""))
        self.define("__DIR__", concat(concat("\"", dir_slash), "\""))
        let main = self.lex_vpath(vpath, false)
        if let Option::None = main:
            self.had_error = true
            self.error = f"Cannot read {vpath}"
            return
        if self.global_include != "":
            let g = self.resolve_include(self.global_include, vpath, false)
            let dummy = tk::Token(kind = tk::Tk::Directive, line = 1, file = fid)
            if g == "":
                self.fail(fid, 1, f"Couldn't read include file \"{self.global_include}\".")
                return
            self.include_vpath(g, dummy)
            if self.had_error:
                return
        let mut last = 1
        if let Option::Some(toks) = main:
            self.run_tokens(toks)
            last = toks[toks.len() - 1].line
        self.out.push(tk::Token(kind = tk::Tk::Eof, line = last, file = fid))

# `#if` expression evaluator over already-expanded tokens; any identifier
# still standing is 0, as in C.
struct IfEval:
    toks: List<tk::Token>
    mut pos: i32 = 0
    mut bad: bool = false

impl IfEval:
    fn peek_op(self, op: str) -> bool:
        self.pos < self.toks.len() and tk::is_op(self.toks[self.pos], op)

    fn ternary(mut self) -> i64:
        let c = self.binary(0)
        if self.peek_op("?"):
            self.pos += 1
            let a = self.ternary()
            if !self.peek_op(":"):
                self.bad = true
                return 0 as i64
            self.pos += 1
            let b = self.ternary()
            return if c != (0 as i64): a else: b
        c

    fn prec(self, op: str) -> i32:
        if op == "||":
            1
        elif op == "&&":
            2
        elif op == "|":
            3
        elif op == "^":
            4
        elif op == "&":
            5
        elif op == "==" or op == "!=":
            6
        elif op == "<" or op == ">" or op == "<=" or op == ">=":
            7
        elif op == "<<" or op == ">>":
            8
        elif op == "+" or op == "-":
            9
        elif op == "*" or op == "/" or op == "%":
            10
        else:
            -1

    fn binary(mut self, min: i32) -> i64:
        let mut l = self.unary()
        while self.pos < self.toks.len() and self.toks[self.pos].kind == tk::Tk::Op:
            let op = self.toks[self.pos].text
            let p = self.prec(op)
            if p < 0 or p <= min - 1 or p < min:
                break
            self.pos += 1
            let r = self.binary(p + 1)
            let z = 0 as i64
            let one = 1 as i64
            if op == "||":
                l = if l != z or r != z: one else: z
            elif op == "&&":
                l = if l != z and r != z: one else: z
            elif op == "|":
                l = bit_or(l, r)
            elif op == "^":
                l = bit_xor(l, r)
            elif op == "&":
                l = bit_and(l, r)
            elif op == "==":
                l = if l == r: one else: z
            elif op == "!=":
                l = if l != r: one else: z
            elif op == "<":
                l = if l < r: one else: z
            elif op == ">":
                l = if l > r: one else: z
            elif op == "<=":
                l = if l <= r: one else: z
            elif op == ">=":
                l = if l >= r: one else: z
            elif op == "+":
                l = l + r
            elif op == "-":
                l = l - r
            elif op == "*":
                l = l * r
            elif op == "/" or op == "%":
                if r == z:
                    self.bad = true
                    return z
                l = if op == "/": l / r else: l % r
            elif op == "<<":
                l = l * pow2(r)
            elif op == ">>":
                l = l / pow2(r)
        l

    fn unary(mut self) -> i64:
        if self.pos >= self.toks.len():
            self.bad = true
            return 0 as i64
        let t = self.toks[self.pos]
        self.pos += 1
        let z = 0 as i64
        if tk::is_op(t, "!"):
            return if self.unary() == z: 1 as i64 else: z
        if tk::is_op(t, "-"):
            return z - self.unary()
        if tk::is_op(t, "+"):
            return self.unary()
        if tk::is_op(t, "~"):
            return bit_not(self.unary())
        if tk::is_op(t, "("):
            let v = self.ternary()
            if !self.peek_op(")"):
                self.bad = true
                return z
            self.pos += 1
            return v
        match t.kind:
            tk::Tk::Int -> t.ival
            tk::Tk::Id -> z
            _ ->
                self.bad = true
                z

fn pow2(n: i64) -> i64:
    let mut r = 1 as i64
    let mut k = 0 as i64
    while k < n and k < (63 as i64):
        r = r * (2 as i64)
        k += 1 as i64
    r

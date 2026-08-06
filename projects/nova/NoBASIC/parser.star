# NoBASIC parser -- ported from the reference Python `compiler/parser/
# parser.py` (`c:\Code\projects\Nova\NoBASIC\compiler\parser\parser.py`),
# todo.md P0 #2. See `ast.star` for the `Expr`/`Stmt`/`Ast` node shapes this
# builds and that file's own header comment for why they're an index-based
# arena rather than a Python-style object tree.
#
# Deliberate deviation -- `had_error` flag propagation, not `Result<T, E>`
# chains: `lexer.star`'s own header comment already establishes why for this
# project -- a postfix `?` requires the *enclosing function's* declared
# return type to be the exact same `Result<T, E>` instantiation as whatever
# it propagates (`docs/language_reference.md`'s "`?`-propagation" section),
# not merely a compatible success type. This parser's methods don't share
# one success type the way `lexer.star`'s all-`()`-returning scan helpers
# almost do: `consume` must hand back a real `Token` (callers read
# `.lexeme`), while every expression/statement parser hands back an `i32`
# arena index. Two genuinely different `Result` instantiations threaded
# through methods that call into each other in both directions (statement
# parsers call `self.expression()`; `if_statement` parses both a condition
# expression and a list of statement children in the same method) would
# force most of those call sites back onto manual `match`-based propagation
# anyway -- so, like `lexer.star`, this port carries `had_error` plus the
# failure's message/line/column as ordinary mutable `Parser` fields instead.
# Every parsing method checks/sets it directly; only the single public entry
# point, `parse`, turns the final flag into the `Result<Ast, ParseError>`
# callers actually see.
#
# On the error path, an `i32`-returning method returns the sentinel `-1`
# (never a real arena index) rather than a partially-built node. Every call
# site that might receive `-1` checks `self.had_error` immediately
# afterward and propagates (`return`s) before doing anything else with the
# value -- in particular, before ever indexing `self.exprs`/`self.stmts`
# with it. This is safe rather than merely convention: nothing during
# parsing ever *reads back* a child node's own stored `line`/`column` to
# compute a parent's position (which would risk indexing with `-1`) --
# instead, every expression-precedence method captures `let anchor =
# self.peek()` once, before parsing its leftmost operand, and reuses that
# same anchor for every node built on top of it in that method (including
# across a left-recursive `while` loop). This reproduces the reference's
# own `_mark_node(..., source_node=some_already_built_child)` exactly (that
# child's own `.line`/`.column` always itself traces back to the same
# leftmost token, by induction), without ever needing to read a node back
# out of the arena mid-parse.
#
# Corollary hazard, audited and guarded against throughout this file: the
# reference's `statement()` has a final fallback (`raise self.error(...)`)
# reached without consuming a token -- so any raw `while <cond>:
# body.append(self.statement())`-shaped scanning loop (an `if`/`for`/
# `while`/`repeat`/`Function` body, `struct`'s field list, ...) is a genuine
# infinite-loop risk once translated to this flag-based style, unlike the
# reference where the exception simply unwinds out of the whole loop.
# Every such loop below includes `and not self.had_error` in its own
# condition for exactly this reason -- confirmed necessary, not defensive
# boilerplate for its own sake.
#
# Deliberate simplification -- `_is_builtin_function_name` is not ported:
# in the reference, its one call site (`statement()`'s
# `elif token.type == IDENTIFIER and self._is_builtin_function_name(...):
# return self.assignment_statement()`) is *always* preceded by an `elif
# token.type == IDENTIFIER and self.check_next(COLON): return
# self.label_statement()` branch that takes priority regardless of the
# name, and is itself followed by a plain `elif token.type == IDENTIFIER:
# return self.assignment_statement()` branch with byte-identical behavior.
# Reading all three confirms the middle branch can never produce an
# observably different parse from the one either its neighbor already
# produces -- confirmed by direct inspection, not assumed -- so this port
# collapses the three into one `Identifier` case (label if followed by
# `:`, otherwise `assignment_statement()`) and never builds the ~70-name
# table at all.
#
# Deliberate, documented non-parity -- the `str(expr)` Python-repr fallback:
# `call()`/`assignable_expression()`'s function-call and bracket-index
# paths use `expr.name` when the callee/base is a `VariableExpr`, but fall
# back to Python's `str(expr)` dataclass repr (e.g. calling/indexing the
# *result* of a member access, like `a.b(x)`) when it isn't -- a corner the
# reference itself likely never intended to reach meaningfully (the
# resulting "name" is never a real function/list/matrix name either way).
# This port's `expr_variable_name_or_placeholder` synthesizes an equally
# nonsensical but deterministic placeholder (`<non-variable-...:expr#N>`)
# instead of reproducing Python's exact repr string, which has no
# Star equivalent and no meaningful downstream consumer regardless. Not
# exercised by this port's own parser test fixture.
#
# Preserved, not simplified away -- `assignable_expression`'s extra postfix
# round: the reference's `assignable_expression` starts from `self.call()`
# (which itself already resolves one full round of member-access/call/
# index/increment-decrement postfixes) and then applies *one more* round of
# member-access-or-call-or-index parsing on top before returning -- a real
# quirk that changes how something like `a(x)(y) = ...` or `a.b(x)[i] = ...`
# parses as an assignment target, not dead code. Shared via `postfix_once`
# (the member-access loop plus a single call-or-index attempt) so `call`
# and `assignable_expression` can each layer it on without duplicating the
# ~40-line body twice; `call` runs it once and then separately checks
# postfix `++`/`--` (which `assignable_expression` never does, matching the
# reference precisely), `assignable_expression` runs `self.call()` (which
# already includes one `postfix_once` round) and then a second bare
# `postfix_once` round with no `++`/`--` check at all.

import "tokens.star" as tok
import "ast.star" as ast

struct ParseError:
    message: str
    filename: str = "<stdin>"
    line: i32 = 0
    column: i32 = 0

fn format_parse_error(e: ParseError) -> str:
    if e.filename == "<stdin>":
        concat("Error: ", e.message)
    else:
        f"Error in {e.filename} at line {e.line}, column {e.column}: {e.message}"

# ---------------------------------------------------------------------------
# Byte/string helpers -- duplicated locally rather than imported from
# `lexer.star`, matching that file's own "self-contained tool" rationale
# (see its header comment) rather than this project's parser depending on
# lexer *scanning* internals it has no real business sharing.
# ---------------------------------------------------------------------------

fn is_digit_byte(c: i32) -> bool:
    c >= 48 and c <= 57

fn is_alpha_byte(c: i32) -> bool:
    (c >= 65 and c <= 90) or (c >= 97 and c <= 122)

fn to_lower_byte(c: i32) -> i32:
    if c >= 65 and c <= 90:
        c + 32
    else:
        c

fn str_lower(s: str) -> str:
    let mut parts: List<str> = List<str>()
    let mut i = 0
    while i < len(s):
        parts.push(chr(to_lower_byte(s[i])))
        i += 1
    str_join(parts, "")

# TI-83/84 style list name: 'L' followed by one or more digits (`L1`, `L23`,
# ...). Matches the reference `is_list_name`'s `startswith('L')` +
# `int(name[1:])` pair exactly (case-sensitive: a lowercase `l1` does not
# count, same as the reference's `str.startswith('L')`).
fn is_list_name(name: str) -> bool:
    if len(name) < 2:
        return false
    if name[0] != 76:
        return false
    let mut i = 1
    while i < len(name):
        if !is_digit_byte(name[i]):
            return false
        i += 1
    true

# TI-83/84 style matrix name: `Mat` followed by exactly one letter (`MatA`,
# `Matx`, ...). Matches the reference `is_matrix_name` exactly.
fn is_matrix_name(name: str) -> bool:
    if len(name) != 4:
        return false
    if name[0] != 77 or name[1] != 97 or name[2] != 116:
        return false
    is_alpha_byte(name[3])

# The ~20 built-in-function token kinds usable as a bare expression atom
# (`_is_function_token` in the reference).
fn is_function_token(t: tok::TokenType) -> bool:
    match t:
        tok::TokenType::Sin -> true
        tok::TokenType::Cos -> true
        tok::TokenType::Tan -> true
        tok::TokenType::Sqrt -> true
        tok::TokenType::Abs -> true
        tok::TokenType::Int -> true
        tok::TokenType::Round -> true
        tok::TokenType::Rand -> true
        tok::TokenType::Rndr -> true
        tok::TokenType::Randomize -> true
        tok::TokenType::Length -> true
        tok::TokenType::Sub -> true
        tok::TokenType::Concat -> true
        tok::TokenType::Sum -> true
        tok::TokenType::Mean -> true
        tok::TokenType::Memread -> true
        tok::TokenType::Memwrite -> true
        tok::TokenType::Instring -> true
        tok::TokenType::Upstring -> true
        tok::TokenType::Lowstring -> true
        tok::TokenType::Lenstring -> true
        _ -> false

# ---------------------------------------------------------------------------
# Parser
# ---------------------------------------------------------------------------

struct Parser:
    tokens: List<tok::Token>
    filename: str
    mut current: i32 = 0
    mut exprs: List<ast::Expr> = List<ast::Expr>()
    mut stmts: List<ast::Stmt> = List<ast::Stmt>()
    mut had_error: bool = false
    mut error_message: str = ""
    mut error_line: i32 = 0
    mut error_column: i32 = 0

fn new_parser(tokens: List<tok::Token>, filename: str) -> Parser:
    Parser(tokens = tokens, filename = filename)

impl Parser:
    # -- Low-level token helpers (mirrors reference "Helper methods") ------

    fn is_at_end(self) -> bool:
        self.peek().kind == tok::TokenType::Eof

    fn peek(self) -> tok::Token:
        self.tokens[self.current]

    fn previous(self) -> tok::Token:
        self.tokens[self.current - 1]

    fn advance(mut self) -> tok::Token:
        if !self.is_at_end():
            self.current += 1
        self.previous()

    fn check(self, kind: tok::TokenType) -> bool:
        if self.is_at_end():
            false
        else:
            self.peek().kind == kind

    fn check_next(self, kind: tok::TokenType) -> bool:
        if self.current + 1 >= self.tokens.len():
            false
        else:
            self.tokens[self.current + 1].kind == kind

    # Covers the reference's variadic `match(*token_types)` -- Star has no
    # variadic functions, so call sites pass a list literal instead.
    fn match_any(mut self, kinds: List<tok::TokenType>) -> bool:
        let mut i = 0
        while i < kinds.len():
            if self.check(kinds[i]):
                self.advance()
                return true
            i += 1
        false

    fn fail(mut self, message: str):
        if !self.had_error:
            self.had_error = true
            self.error_message = message
            self.error_line = self.peek().line
            self.error_column = self.peek().column

    fn consume(mut self, kind: tok::TokenType, message: str) -> tok::Token:
        if self.check(kind):
            return self.advance()
        self.fail(message)
        self.peek()

    # `consume` for callers that only care whether it succeeded (most
    # delimiter consumes -- `(`, `)`, `,`, keywords like `Then`/`End`).
    fn expect(mut self, kind: tok::TokenType, message: str) -> bool:
        self.consume(kind, message)
        !self.had_error

    fn push_expr(mut self, kind: ast::ExprKind, line: i32, column: i32) -> i32:
        let id = self.exprs.len()
        self.exprs.push(ast::Expr(kind = kind, line = line, column = column))
        id

    fn push_stmt(mut self, kind: ast::StmtKind, line: i32, column: i32) -> i32:
        let id = self.stmts.len()
        self.stmts.push(ast::Stmt(kind = kind, line = line, column = column))
        id

    # `self.exprs[expr_id]` is only ever read back once its caller has
    # already confirmed `!self.had_error` for `expr_id` -- see this file's
    # header comment.
    fn expr_variable_name(self, expr_id: i32) -> Option<str>:
        match self.exprs[expr_id].kind:
            ast::ExprKind::Variable(name) -> Option<str>::Some(name)
            _ -> Option<str>::None

    fn expr_variable_name_or_placeholder(self, expr_id: i32) -> str:
        match self.expr_variable_name(expr_id):
            Option::Some(name) -> name
            Option::None -> concat("<non-variable-base:expr#", concat(f"{expr_id}", ">"))

    # ------------------------------------------------------------------
    # Statements
    # ------------------------------------------------------------------

    fn statement(mut self) -> i32:
        let t = self.peek()
        match t.kind:
            tok::TokenType::Clrdraw ->
                self.advance()
                return self.push_stmt(ast::StmtKind::ClrDraw, t.line, t.column)
            tok::TokenType::Global ->
                return self.var_declaration_statement(ast::VarScope::Global)
            tok::TokenType::Local ->
                return self.var_declaration_statement(ast::VarScope::Local)
            tok::TokenType::Function ->
                return self.function_definition()
            tok::TokenType::Return ->
                return self.return_statement()
            tok::TokenType::Asm ->
                return self.asm_block_statement()
            tok::TokenType::Pxlon ->
                return self.pxl_on_statement()
            tok::TokenType::Pxloff ->
                return self.pxl_off_statement()
            tok::TokenType::Line ->
                return self.line_statement()
            tok::TokenType::Circle ->
                return self.circle_statement()
            tok::TokenType::Text ->
                return self.text_statement()
            tok::TokenType::Setlayer ->
                return self.set_layer_statement()
            tok::TokenType::Scrroll ->
                return self.srol_statement()
            tok::TokenType::Scrrotate ->
                return self.srot_statement()
            tok::TokenType::Scrshift ->
                return self.sshft_statement()
            tok::TokenType::Scrflip ->
                return self.sflip_statement()
            tok::TokenType::Spriteon ->
                return self.sprite_on_statement()
            tok::TokenType::Spriteoff ->
                return self.sprite_off_statement()
            tok::TokenType::Playtone ->
                return self.play_tone_statement()
            tok::TokenType::Playwave ->
                return self.play_wave_statement()
            tok::TokenType::Stopsound ->
                self.advance()
                return self.push_stmt(ast::StmtKind::StopSound, t.line, t.column)
            tok::TokenType::Setchannel ->
                return self.set_channel_statement()
            tok::TokenType::Getkey ->
                self.advance()
                return self.push_stmt(ast::StmtKind::GetKey, t.line, t.column)
            tok::TokenType::Serout ->
                return self.ser_out_statement()
            tok::TokenType::Serin ->
                return self.ser_in_statement()
            tok::TokenType::Serstat ->
                return self.ser_stat_statement()
            tok::TokenType::Serctrl ->
                return self.ser_ctrl_statement()
            tok::TokenType::Input ->
                return self.input_statement()
            tok::TokenType::Disp ->
                return self.disp_statement()
            tok::TokenType::Pause ->
                self.advance()
                return self.push_stmt(ast::StmtKind::Pause, t.line, t.column)
            tok::TokenType::If ->
                return self.if_statement(true)
            tok::TokenType::For ->
                return self.for_statement()
            tok::TokenType::While ->
                return self.while_statement()
            tok::TokenType::Repeat ->
                return self.repeat_statement()
            tok::TokenType::Goto ->
                return self.goto_statement()
            tok::TokenType::Struct ->
                return self.struct_declaration()
            tok::TokenType::Identifier ->
                if self.check_next(tok::TokenType::Colon):
                    return self.label_statement()
                return self.assignment_statement()
            _ -> 0
        if is_function_token(t.kind):
            return self.assignment_statement()
        self.fail("Expected statement")
        -1

    fn pxl_on_statement(mut self) -> i32:
        let t = self.advance()
        if !self.expect(tok::TokenType::Lparen, "Expected '(' after PxlOn"):
            return -1
        let x = self.expression()
        if self.had_error:
            return x
        if !self.expect(tok::TokenType::Comma, "Expected ',' after x"):
            return -1
        let y = self.expression()
        if self.had_error:
            return y
        if !self.expect(tok::TokenType::Comma, "Expected ',' after y"):
            return -1
        let color = self.expression()
        if self.had_error:
            return color
        if !self.expect(tok::TokenType::Rparen, "Expected ')' after color"):
            return -1
        self.push_stmt(ast::StmtKind::PxlOn(x = x, y = y, color = color), t.line, t.column)

    fn pxl_off_statement(mut self) -> i32:
        let t = self.advance()
        if !self.expect(tok::TokenType::Lparen, "Expected '(' after PxlOff"):
            return -1
        let x = self.expression()
        if self.had_error:
            return x
        if !self.expect(tok::TokenType::Comma, "Expected ',' after x"):
            return -1
        let y = self.expression()
        if self.had_error:
            return y
        if !self.expect(tok::TokenType::Rparen, "Expected ')' after y"):
            return -1
        self.push_stmt(ast::StmtKind::PxlOff(x = x, y = y), t.line, t.column)

    fn line_statement(mut self) -> i32:
        let t = self.advance()
        if !self.expect(tok::TokenType::Lparen, "Expected '(' after Line"):
            return -1
        let x1 = self.expression()
        if self.had_error:
            return x1
        if !self.expect(tok::TokenType::Comma, "Expected ',' after x1"):
            return -1
        let y1 = self.expression()
        if self.had_error:
            return y1
        if !self.expect(tok::TokenType::Comma, "Expected ',' after y1"):
            return -1
        let x2 = self.expression()
        if self.had_error:
            return x2
        if !self.expect(tok::TokenType::Comma, "Expected ',' after x2"):
            return -1
        let y2 = self.expression()
        if self.had_error:
            return y2
        if !self.expect(tok::TokenType::Comma, "Expected ',' after y2"):
            return -1
        let color = self.expression()
        if self.had_error:
            return color
        if !self.expect(tok::TokenType::Rparen, "Expected ')' after color"):
            return -1
        self.push_stmt(ast::StmtKind::Line(x1 = x1, y1 = y1, x2 = x2, y2 = y2, color = color), t.line, t.column)

    fn circle_statement(mut self) -> i32:
        let t = self.advance()
        if !self.expect(tok::TokenType::Lparen, "Expected '(' after Circle"):
            return -1
        let x = self.expression()
        if self.had_error:
            return x
        if !self.expect(tok::TokenType::Comma, "Expected ',' after x"):
            return -1
        let y = self.expression()
        if self.had_error:
            return y
        if !self.expect(tok::TokenType::Comma, "Expected ',' after y"):
            return -1
        let radius = self.expression()
        if self.had_error:
            return radius
        if !self.expect(tok::TokenType::Comma, "Expected ',' after radius"):
            return -1
        let color = self.expression()
        if self.had_error:
            return color
        let mut filled = Option<i32>::None
        if self.check(tok::TokenType::Comma):
            self.advance()
            let f = self.expression()
            if self.had_error:
                return f
            filled = Option<i32>::Some(f)
        if !self.expect(tok::TokenType::Rparen, "Expected ')' after arguments"):
            return -1
        self.push_stmt(ast::StmtKind::Circle(x = x, y = y, radius = radius, color = color, filled = filled), t.line, t.column)

    fn text_statement(mut self) -> i32:
        let t = self.advance()
        if !self.expect(tok::TokenType::Lparen, "Expected '(' after Text"):
            return -1
        let x = self.expression()
        if self.had_error:
            return x
        if !self.expect(tok::TokenType::Comma, "Expected ',' after x"):
            return -1
        let y = self.expression()
        if self.had_error:
            return y
        if !self.expect(tok::TokenType::Comma, "Expected ',' after y"):
            return -1
        let text = self.expression()
        if self.had_error:
            return text
        if !self.expect(tok::TokenType::Comma, "Expected ',' after text"):
            return -1
        let color = self.expression()
        if self.had_error:
            return color
        if !self.expect(tok::TokenType::Rparen, "Expected ')' after color"):
            return -1
        self.push_stmt(ast::StmtKind::Text(x = x, y = y, text = text, color = color), t.line, t.column)

    fn set_layer_statement(mut self) -> i32:
        let t = self.advance()
        if !self.expect(tok::TokenType::Lparen, "Expected '(' after SetLayer"):
            return -1
        let layer = self.expression()
        if self.had_error:
            return layer
        if !self.expect(tok::TokenType::Rparen, "Expected ')' after layer"):
            return -1
        self.push_stmt(ast::StmtKind::SetLayer(layer = layer), t.line, t.column)

    fn srol_statement(mut self) -> i32:
        let t = self.advance()
        if !self.expect(tok::TokenType::Lparen, "Expected '(' after ScrRoll"):
            return -1
        let axis = self.expression()
        if self.had_error:
            return axis
        if !self.expect(tok::TokenType::Comma, "Expected ',' after axis"):
            return -1
        let amount = self.expression()
        if self.had_error:
            return amount
        if !self.expect(tok::TokenType::Rparen, "Expected ')' after amount"):
            return -1
        self.push_stmt(ast::StmtKind::SRol(axis = axis, amount = amount), t.line, t.column)

    fn srot_statement(mut self) -> i32:
        let t = self.advance()
        if !self.expect(tok::TokenType::Lparen, "Expected '(' after ScrRotate"):
            return -1
        let direction = self.expression()
        if self.had_error:
            return direction
        if !self.expect(tok::TokenType::Comma, "Expected ',' after direction"):
            return -1
        let amount = self.expression()
        if self.had_error:
            return amount
        if !self.expect(tok::TokenType::Rparen, "Expected ')' after amount"):
            return -1
        self.push_stmt(ast::StmtKind::SRot(direction = direction, amount = amount), t.line, t.column)

    fn sshft_statement(mut self) -> i32:
        let t = self.advance()
        if !self.expect(tok::TokenType::Lparen, "Expected '(' after ScrShift"):
            return -1
        let axis = self.expression()
        if self.had_error:
            return axis
        if !self.expect(tok::TokenType::Comma, "Expected ',' after axis"):
            return -1
        let amount = self.expression()
        if self.had_error:
            return amount
        if !self.expect(tok::TokenType::Rparen, "Expected ')' after amount"):
            return -1
        self.push_stmt(ast::StmtKind::SShft(axis = axis, amount = amount), t.line, t.column)

    fn sflip_statement(mut self) -> i32:
        let t = self.advance()
        if !self.expect(tok::TokenType::Lparen, "Expected '(' after ScrFlip"):
            return -1
        let axis = self.expression()
        if self.had_error:
            return axis
        if !self.expect(tok::TokenType::Rparen, "Expected ')' after axis"):
            return -1
        self.push_stmt(ast::StmtKind::SFlip(axis = axis), t.line, t.column)

    fn sprite_on_statement(mut self) -> i32:
        let t = self.advance()
        if !self.expect(tok::TokenType::Lparen, "Expected '(' after SpriteOn"):
            return -1
        let sprite_id = self.expression()
        if self.had_error:
            return sprite_id
        if !self.expect(tok::TokenType::Comma, "Expected ',' after spriteId"):
            return -1
        let x = self.expression()
        if self.had_error:
            return x
        if !self.expect(tok::TokenType::Comma, "Expected ',' after x"):
            return -1
        let y = self.expression()
        if self.had_error:
            return y
        if !self.expect(tok::TokenType::Rparen, "Expected ')' after y"):
            return -1
        self.push_stmt(ast::StmtKind::SpriteOn(sprite_id = sprite_id, x = x, y = y), t.line, t.column)

    fn sprite_off_statement(mut self) -> i32:
        let t = self.advance()
        if !self.expect(tok::TokenType::Lparen, "Expected '(' after SpriteOff"):
            return -1
        let sprite_id = self.expression()
        if self.had_error:
            return sprite_id
        if !self.expect(tok::TokenType::Rparen, "Expected ')' after spriteId"):
            return -1
        self.push_stmt(ast::StmtKind::SpriteOff(sprite_id = sprite_id), t.line, t.column)

    fn play_tone_statement(mut self) -> i32:
        let t = self.advance()
        if !self.expect(tok::TokenType::Lparen, "Expected '(' after PlayTone"):
            return -1
        let frequency = self.expression()
        if self.had_error:
            return frequency
        if !self.expect(tok::TokenType::Comma, "Expected ',' after frequency"):
            return -1
        let duration = self.expression()
        if self.had_error:
            return duration
        if !self.expect(tok::TokenType::Comma, "Expected ',' after duration"):
            return -1
        let volume = self.expression()
        if self.had_error:
            return volume
        if !self.expect(tok::TokenType::Rparen, "Expected ')' after volume"):
            return -1
        self.push_stmt(ast::StmtKind::PlayTone(frequency = frequency, duration = duration, volume = volume), t.line, t.column)

    fn play_wave_statement(mut self) -> i32:
        let t = self.advance()
        if !self.expect(tok::TokenType::Lparen, "Expected '(' after PlayWave"):
            return -1
        let waveform = self.expression()
        if self.had_error:
            return waveform
        if !self.expect(tok::TokenType::Comma, "Expected ',' after waveform"):
            return -1
        let frequency = self.expression()
        if self.had_error:
            return frequency
        if !self.expect(tok::TokenType::Comma, "Expected ',' after frequency"):
            return -1
        let volume = self.expression()
        if self.had_error:
            return volume
        if !self.expect(tok::TokenType::Rparen, "Expected ')' after volume"):
            return -1
        self.push_stmt(ast::StmtKind::PlayWave(waveform = waveform, frequency = frequency, volume = volume), t.line, t.column)

    fn set_channel_statement(mut self) -> i32:
        let t = self.advance()
        if !self.expect(tok::TokenType::Lparen, "Expected '(' after SetChannel"):
            return -1
        let channel = self.expression()
        if self.had_error:
            return channel
        if !self.expect(tok::TokenType::Rparen, "Expected ')' after channel"):
            return -1
        self.push_stmt(ast::StmtKind::SetChannel(channel = channel), t.line, t.column)

    fn ser_out_statement(mut self) -> i32:
        let t = self.advance()
        if !self.expect(tok::TokenType::Lparen, "Expected '(' after SerOut"):
            return -1
        let value = self.expression()
        if self.had_error:
            return value
        if !self.expect(tok::TokenType::Rparen, "Expected ')' after value"):
            return -1
        self.push_stmt(ast::StmtKind::SerOut(value = value), t.line, t.column)

    fn ser_in_statement(mut self) -> i32:
        let t = self.advance()
        if !self.expect(tok::TokenType::Lparen, "Expected '(' after SerIn"):
            return -1
        let var_tok = self.consume(tok::TokenType::Identifier, "Expected variable name")
        if self.had_error:
            return -1
        if !self.expect(tok::TokenType::Rparen, "Expected ')' after variable"):
            return -1
        self.push_stmt(ast::StmtKind::SerIn(variable = var_tok.lexeme), t.line, t.column)

    fn ser_stat_statement(mut self) -> i32:
        let t = self.advance()
        if !self.expect(tok::TokenType::Lparen, "Expected '(' after SerStat"):
            return -1
        let var_tok = self.consume(tok::TokenType::Identifier, "Expected variable name")
        if self.had_error:
            return -1
        if !self.expect(tok::TokenType::Rparen, "Expected ')' after variable"):
            return -1
        self.push_stmt(ast::StmtKind::SerStat(variable = var_tok.lexeme), t.line, t.column)

    fn ser_ctrl_statement(mut self) -> i32:
        let t = self.advance()
        if !self.expect(tok::TokenType::Lparen, "Expected '(' after SerCtrl"):
            return -1
        let value = self.expression()
        if self.had_error:
            return value
        if !self.expect(tok::TokenType::Rparen, "Expected ')' after value"):
            return -1
        self.push_stmt(ast::StmtKind::SerCtrl(value = value), t.line, t.column)

    fn input_statement(mut self) -> i32:
        let t = self.advance()
        if self.check(tok::TokenType::Lparen):
            self.advance()
            let prompt = self.expression()
            if self.had_error:
                return prompt
            if !self.expect(tok::TokenType::Comma, "Expected ',' after prompt"):
                return -1
            let var_tok = self.consume(tok::TokenType::Identifier, "Expected variable name")
            if self.had_error:
                return -1
            if !self.expect(tok::TokenType::Rparen, "Expected ')' after variable"):
                return -1
            return self.push_stmt(ast::StmtKind::Input(prompt = Option<i32>::Some(prompt), variable = var_tok.lexeme), t.line, t.column)
        if self.check(tok::TokenType::StringLiteral):
            let prompt = self.expression()
            if self.had_error:
                return prompt
            if !self.expect(tok::TokenType::Comma, "Expected ',' after prompt"):
                return -1
            let var_tok = self.consume(tok::TokenType::Identifier, "Expected variable name")
            if self.had_error:
                return -1
            return self.push_stmt(ast::StmtKind::Input(prompt = Option<i32>::Some(prompt), variable = var_tok.lexeme), t.line, t.column)
        let var_tok = self.consume(tok::TokenType::Identifier, "Expected variable name")
        if self.had_error:
            return -1
        self.push_stmt(ast::StmtKind::Input(prompt = Option<i32>::None, variable = var_tok.lexeme), t.line, t.column)

    fn disp_statement(mut self) -> i32:
        let t = self.advance()
        let text = self.expression()
        if self.had_error:
            return text
        self.push_stmt(ast::StmtKind::Disp(text = text), t.line, t.column)

    fn assignment_statement(mut self) -> i32:
        let anchor = self.peek()
        let variable = self.assignable_expression()
        if self.had_error:
            return variable
        match self.exprs[variable].kind:
            ast::ExprKind::Call(name, arguments) ->
                if !self.check(tok::TokenType::Equal):
                    return self.push_stmt(ast::StmtKind::FunctionCall(call = variable), anchor.line, anchor.column)
            ast::ExprKind::Unary(operator, expr, is_post) ->
                if operator == "++" or operator == "--":
                    return self.push_stmt(ast::StmtKind::ExpressionStmt(expr = variable), anchor.line, anchor.column)
            _ -> 0
        if !self.check(tok::TokenType::Equal):
            self.fail("Expected '=' after variable or valid statement")
            return -1
        self.advance()
        let expr_val = self.expression()
        if self.had_error:
            return expr_val
        self.push_stmt(ast::StmtKind::Assignment(variable = variable, expr = expr_val), anchor.line, anchor.column)

    fn if_statement(mut self, consume_end: bool) -> i32:
        let t = self.advance()
        let condition = self.expression()
        if self.had_error:
            return condition
        if !self.expect(tok::TokenType::Then, "Expected 'Then' after condition"):
            return -1
        let mut then_branch: List<i32> = List<i32>()
        while !self.check(tok::TokenType::Else) and !self.check(tok::TokenType::End) and !self.had_error:
            let s = self.statement()
            if self.had_error:
                return s
            then_branch.push(s)
        let mut else_branch = Option<List<i32>>::None
        if self.match_any([tok::TokenType::Else]):
            if self.check(tok::TokenType::If):
                let nested = self.if_statement(false)
                if self.had_error:
                    return nested
                let mut eb: List<i32> = List<i32>()
                eb.push(nested)
                else_branch = Option<List<i32>>::Some(eb)
            else:
                let mut eb: List<i32> = List<i32>()
                while !self.check(tok::TokenType::End) and !self.had_error:
                    let s = self.statement()
                    if self.had_error:
                        return s
                    eb.push(s)
                else_branch = Option<List<i32>>::Some(eb)
        if consume_end:
            if !self.expect(tok::TokenType::End, "Expected 'End' after if statement"):
                return -1
        self.push_stmt(ast::StmtKind::If(condition = condition, then_branch = then_branch, else_branch = else_branch), t.line, t.column)

    fn for_statement(mut self) -> i32:
        let t = self.advance()
        let var_tok = self.consume(tok::TokenType::Identifier, "Expected variable name")
        if self.had_error:
            return -1
        let variable = var_tok.lexeme
        if !self.expect(tok::TokenType::Equal, "Expected '=' after variable"):
            return -1
        let start = self.expression()
        if self.had_error:
            return start
        if !self.expect(tok::TokenType::To, "Expected 'To' after start"):
            return -1
        let end_v = self.expression()
        if self.had_error:
            return end_v
        let mut step = Option<i32>::None
        if self.match_any([tok::TokenType::Step]):
            let s = self.expression()
            if self.had_error:
                return s
            step = Option<i32>::Some(s)
        let mut body: List<i32> = List<i32>()
        while !self.check(tok::TokenType::Next) and !self.check(tok::TokenType::End) and !self.had_error:
            let s = self.statement()
            if self.had_error:
                return s
            body.push(s)
        if self.match_any([tok::TokenType::Next]):
            0
        elif self.match_any([tok::TokenType::End]):
            0
        else:
            self.fail("Expected 'Next' or 'End' after for body")
            return -1
        self.push_stmt(ast::StmtKind::For(variable = variable, start = start, end = end_v, step = step, body = body), t.line, t.column)

    fn while_statement(mut self) -> i32:
        let t = self.advance()
        let condition = self.expression()
        if self.had_error:
            return condition
        let mut body: List<i32> = List<i32>()
        while !self.check(tok::TokenType::End) and !self.had_error:
            let s = self.statement()
            if self.had_error:
                return s
            body.push(s)
        if !self.expect(tok::TokenType::End, "Expected 'End' after while body"):
            return -1
        self.push_stmt(ast::StmtKind::While(condition = condition, body = body), t.line, t.column)

    fn repeat_statement(mut self) -> i32:
        let t = self.advance()
        let mut body: List<i32> = List<i32>()
        while !self.check(tok::TokenType::Until) and !self.had_error:
            let s = self.statement()
            if self.had_error:
                return s
            body.push(s)
        if !self.expect(tok::TokenType::Until, "Expected 'Until' after repeat body"):
            return -1
        let condition = self.expression()
        if self.had_error:
            return condition
        self.push_stmt(ast::StmtKind::Repeat(body = body, condition = condition), t.line, t.column)

    fn goto_statement(mut self) -> i32:
        let t = self.advance()
        let label_tok = self.consume(tok::TokenType::Identifier, "Expected label name")
        if self.had_error:
            return -1
        self.push_stmt(ast::StmtKind::Goto(label = label_tok.lexeme), t.line, t.column)

    fn label_statement(mut self) -> i32:
        let label_tok = self.consume(tok::TokenType::Identifier, "Expected label name")
        if self.had_error:
            return -1
        if !self.expect(tok::TokenType::Colon, "Expected ':' after label"):
            return -1
        self.push_stmt(ast::StmtKind::Label(label = label_tok.lexeme), label_tok.line, label_tok.column)

    fn struct_declaration(mut self) -> i32:
        let struct_tok = self.consume(tok::TokenType::Struct, "Expected 'STRUCT'")
        if self.had_error:
            return -1
        let name_tok = self.consume(tok::TokenType::Identifier, "Expected struct name")
        if self.had_error:
            return -1
        let name = name_tok.lexeme
        let mut fields: List<str> = List<str>()
        while !self.check(tok::TokenType::End) and !self.is_at_end() and !self.had_error:
            let field_tok = self.consume(tok::TokenType::Identifier, "Expected field name")
            if self.had_error:
                return -1
            fields.push(field_tok.lexeme)
        if !self.expect(tok::TokenType::End, "Expected 'END' after struct fields"):
            return -1
        if fields.len() > 10:
            self.fail(f"Struct '{name}' has {fields.len()} fields, maximum is 10")
            return -1
        if fields.len() == 0:
            self.fail(f"Struct '{name}' must have at least one field")
            return -1
        self.push_stmt(ast::StmtKind::StructDecl(name = name, fields = fields), struct_tok.line, struct_tok.column)

    fn var_declaration_statement(mut self, scope: ast::VarScope) -> i32:
        let t = self.advance()
        let mut variables: List<str> = List<str>()
        let first_tok = self.consume(tok::TokenType::Identifier, "Expected variable name")
        if self.had_error:
            return -1
        variables.push(first_tok.lexeme)
        while self.match_any([tok::TokenType::Comma]) and !self.had_error:
            let var_tok = self.consume(tok::TokenType::Identifier, "Expected variable name")
            if self.had_error:
                return -1
            variables.push(var_tok.lexeme)
        self.push_stmt(ast::StmtKind::VarDecl(scope = scope, variables = variables), t.line, t.column)

    fn asm_block_statement(mut self) -> i32:
        let asm_tok = self.consume(tok::TokenType::Asm, "Expected 'Asm'")
        if self.had_error:
            return -1
        let block_tok = self.consume(tok::TokenType::AsmBlock, "Expected assembly code block")
        if self.had_error:
            return -1
        if !self.expect(tok::TokenType::End, "Expected 'End' after assembly block"):
            return -1
        self.push_stmt(ast::StmtKind::AsmBlock(assembly_code = block_tok.str_value), asm_tok.line, asm_tok.column)

    fn function_definition(mut self) -> i32:
        let function_tok = self.consume(tok::TokenType::Function, "Expected 'Function'")
        if self.had_error:
            return -1
        let name_tok = self.consume(tok::TokenType::Identifier, "Expected function name")
        if self.had_error:
            return -1
        let name = str_lower(name_tok.lexeme)
        if !self.expect(tok::TokenType::Lparen, "Expected '(' after function name"):
            return -1
        let mut params: List<ast::Param> = List<ast::Param>()
        if !self.check(tok::TokenType::Rparen):
            let p1_tok = self.consume(tok::TokenType::Identifier, "Expected parameter name")
            if self.had_error:
                return -1
            let p1_name = str_lower(p1_tok.lexeme)
            let mut p1_default = Option<i32>::None
            if self.match_any([tok::TokenType::Equal]):
                let d = self.expression()
                if self.had_error:
                    return d
                p1_default = Option<i32>::Some(d)
            params.push(ast::Param(name = p1_name, default = p1_default))
            while self.match_any([tok::TokenType::Comma]) and !self.had_error:
                let pn_tok = self.consume(tok::TokenType::Identifier, "Expected parameter name")
                if self.had_error:
                    return -1
                let pn_name = str_lower(pn_tok.lexeme)
                let mut pn_default = Option<i32>::None
                if self.match_any([tok::TokenType::Equal]):
                    let d2 = self.expression()
                    if self.had_error:
                        return d2
                    pn_default = Option<i32>::Some(d2)
                params.push(ast::Param(name = pn_name, default = pn_default))
        if !self.expect(tok::TokenType::Rparen, "Expected ')' after parameters"):
            return -1
        let mut body: List<i32> = List<i32>()
        while !self.check(tok::TokenType::End) and !self.is_at_end() and !self.had_error:
            let s = self.statement()
            if self.had_error:
                return s
            body.push(s)
        if !self.expect(tok::TokenType::End, "Expected 'End' to close function definition"):
            return -1
        self.push_stmt(ast::StmtKind::FunctionDef(name = name, params = params, body = body), function_tok.line, function_tok.column)

    fn return_statement(mut self) -> i32:
        let t = self.advance()
        let mut value = Option<i32>::None
        if !self.is_at_end() and self.peek().line == t.line:
            let next_kind = self.peek().kind
            if next_kind != tok::TokenType::End and next_kind != tok::TokenType::Else and next_kind != tok::TokenType::Next:
                let v = self.expression()
                if self.had_error:
                    return v
                value = Option<i32>::Some(v)
        self.push_stmt(ast::StmtKind::Return(value = value), t.line, t.column)

    # ------------------------------------------------------------------
    # Expressions -- precedence-climbing chain, weakest-binds-first, one
    # method per reference method. Every method captures `anchor` once
    # (the first token of its own leftmost operand) and reuses it for every
    # node built on top in its own `while` fold -- see this file's header
    # comment.
    # ------------------------------------------------------------------

    fn expression(mut self) -> i32:
        self.logical_or()

    fn logical_or(mut self) -> i32:
        let anchor = self.peek()
        let mut expr = self.logical_and()
        if self.had_error:
            return expr
        while self.match_any([tok::TokenType::Or]):
            let right = self.logical_and()
            if self.had_error:
                return right
            expr = self.push_expr(ast::ExprKind::Binary(left = expr, operator = "or", right = right), anchor.line, anchor.column)
        expr

    fn logical_and(mut self) -> i32:
        let anchor = self.peek()
        let mut expr = self.bitwise_or()
        if self.had_error:
            return expr
        while self.match_any([tok::TokenType::And]):
            let right = self.bitwise_or()
            if self.had_error:
                return right
            expr = self.push_expr(ast::ExprKind::Binary(left = expr, operator = "and", right = right), anchor.line, anchor.column)
        expr

    fn bitwise_or(mut self) -> i32:
        let anchor = self.peek()
        let mut expr = self.bitwise_and()
        if self.had_error:
            return expr
        while self.match_any([tok::TokenType::BitwiseOr]):
            let right = self.bitwise_and()
            if self.had_error:
                return right
            expr = self.push_expr(ast::ExprKind::Binary(left = expr, operator = "|", right = right), anchor.line, anchor.column)
        expr

    fn bitwise_and(mut self) -> i32:
        let anchor = self.peek()
        let mut expr = self.equality()
        if self.had_error:
            return expr
        while self.match_any([tok::TokenType::BitwiseAnd]):
            let right = self.equality()
            if self.had_error:
                return right
            expr = self.push_expr(ast::ExprKind::Binary(left = expr, operator = "&", right = right), anchor.line, anchor.column)
        expr

    fn equality(mut self) -> i32:
        let anchor = self.peek()
        let mut expr = self.comparison()
        if self.had_error:
            return expr
        while self.match_any([tok::TokenType::Equal, tok::TokenType::NotEqual]):
            let operator = self.previous().lexeme
            let right = self.comparison()
            if self.had_error:
                return right
            expr = self.push_expr(ast::ExprKind::Binary(left = expr, operator = operator, right = right), anchor.line, anchor.column)
        expr

    fn comparison(mut self) -> i32:
        let anchor = self.peek()
        let mut expr = self.term()
        if self.had_error:
            return expr
        while self.match_any([tok::TokenType::Less, tok::TokenType::LessEqual, tok::TokenType::Greater, tok::TokenType::GreaterEqual]):
            let operator = self.previous().lexeme
            let right = self.term()
            if self.had_error:
                return right
            expr = self.push_expr(ast::ExprKind::Binary(left = expr, operator = operator, right = right), anchor.line, anchor.column)
        expr

    fn term(mut self) -> i32:
        let anchor = self.peek()
        let mut expr = self.shift()
        if self.had_error:
            return expr
        while self.match_any([tok::TokenType::Plus, tok::TokenType::Minus]):
            let operator = self.previous().lexeme
            let right = self.shift()
            if self.had_error:
                return right
            expr = self.push_expr(ast::ExprKind::Binary(left = expr, operator = operator, right = right), anchor.line, anchor.column)
        expr

    fn shift(mut self) -> i32:
        let anchor = self.peek()
        let mut expr = self.factor()
        if self.had_error:
            return expr
        while self.match_any([tok::TokenType::ShiftLeft, tok::TokenType::ShiftRight]):
            let operator = self.previous().lexeme
            let right = self.factor()
            if self.had_error:
                return right
            expr = self.push_expr(ast::ExprKind::Binary(left = expr, operator = operator, right = right), anchor.line, anchor.column)
        expr

    fn factor(mut self) -> i32:
        let anchor = self.peek()
        let mut expr = self.power()
        if self.had_error:
            return expr
        while self.match_any([tok::TokenType::Multiply, tok::TokenType::Divide]):
            let operator = self.previous().lexeme
            let right = self.power()
            if self.had_error:
                return right
            expr = self.push_expr(ast::ExprKind::Binary(left = expr, operator = operator, right = right), anchor.line, anchor.column)
        expr

    # Right-associative (recurses back into `power`, not `unary`), matching
    # the reference exactly.
    fn power(mut self) -> i32:
        let anchor = self.peek()
        let expr = self.unary()
        if self.had_error:
            return expr
        if self.match_any([tok::TokenType::Power]):
            let right = self.power()
            if self.had_error:
                return right
            return self.push_expr(ast::ExprKind::Binary(left = expr, operator = "^", right = right), anchor.line, anchor.column)
        expr

    fn unary(mut self) -> i32:
        if self.match_any([tok::TokenType::Increment]):
            let op_tok = self.previous()
            let expr = self.unary()
            if self.had_error:
                return expr
            return self.push_expr(ast::ExprKind::Unary(operator = "++", expr = expr, is_post = false), op_tok.line, op_tok.column)
        if self.match_any([tok::TokenType::Decrement]):
            let op_tok = self.previous()
            let expr = self.unary()
            if self.had_error:
                return expr
            return self.push_expr(ast::ExprKind::Unary(operator = "--", expr = expr, is_post = false), op_tok.line, op_tok.column)
        if self.match_any([tok::TokenType::Minus, tok::TokenType::Not]):
            let op_tok = self.previous()
            let operator = op_tok.lexeme
            let expr = self.unary()
            if self.had_error:
                return expr
            return self.push_expr(ast::ExprKind::Unary(operator = operator, expr = expr, is_post = false), op_tok.line, op_tok.column)
        self.call()

    # One round of member-access-loop then an optional single call-or-index
    # attempt -- shared by `call` and `assignable_expression`; see this
    # file's header comment ("Preserved, not simplified away") for why
    # `assignable_expression` runs this twice (once via `self.call()`, once
    # directly) while `call` itself only runs it once.
    fn postfix_once(mut self, base: i32, anchor: tok::Token) -> i32:
        let mut expr = base
        while self.match_any([tok::TokenType::Dot]) and !self.had_error:
            let member_tok = self.consume(tok::TokenType::Identifier, "Expected member name after '.'")
            if self.had_error:
                return expr
            expr = self.push_expr(ast::ExprKind::MemberAccess(object = expr, member = member_tok.lexeme), anchor.line, anchor.column)
        if self.had_error:
            return expr
        if self.match_any([tok::TokenType::Lparen]):
            match self.expr_variable_name(expr):
                Option::Some(name) ->
                    if is_list_name(name):
                        let index = self.expression()
                        if self.had_error:
                            return index
                        if !self.expect(tok::TokenType::Rparen, "Expected ')' after list index"):
                            return expr
                        return self.push_expr(ast::ExprKind::ListAccess(list_name = name, index = index), anchor.line, anchor.column)
                    elif is_matrix_name(name):
                        let row = self.expression()
                        if self.had_error:
                            return row
                        if !self.expect(tok::TokenType::Comma, "Expected ',' after row index"):
                            return expr
                        let col = self.expression()
                        if self.had_error:
                            return col
                        if !self.expect(tok::TokenType::Rparen, "Expected ')' after matrix indices"):
                            return expr
                        return self.push_expr(ast::ExprKind::MatrixAccess(matrix_name = name, row = row, col = col), anchor.line, anchor.column)
                    else:
                        let arguments = self.parse_arguments()
                        if self.had_error:
                            return expr
                        return self.push_expr(ast::ExprKind::Call(name = name, arguments = arguments), anchor.line, anchor.column)
                Option::None ->
                    let arguments = self.parse_arguments()
                    if self.had_error:
                        return expr
                    let placeholder = concat("<non-variable-callee:expr#", concat(f"{expr}", ">"))
                    return self.push_expr(ast::ExprKind::Call(name = placeholder, arguments = arguments), anchor.line, anchor.column)
        elif self.match_any([tok::TokenType::Lbracket]):
            let first_index = self.expression()
            if self.had_error:
                return first_index
            if self.match_any([tok::TokenType::Comma]):
                let second_index = self.expression()
                if self.had_error:
                    return second_index
                if !self.expect(tok::TokenType::Rbracket, "Expected ']' after matrix indices"):
                    return expr
                let name = self.expr_variable_name_or_placeholder(expr)
                return self.push_expr(ast::ExprKind::MatrixAccess(matrix_name = name, row = first_index, col = second_index), anchor.line, anchor.column)
            else:
                if !self.expect(tok::TokenType::Rbracket, "Expected ']' after array index"):
                    return expr
                let name = self.expr_variable_name_or_placeholder(expr)
                return self.push_expr(ast::ExprKind::ListAccess(list_name = name, index = first_index), anchor.line, anchor.column)
        expr

    # `if not check(RPAREN): args = [expression(), ...]`, then `consume(RPAREN,
    # "Expected ')' after arguments")` -- shared verbatim between `call`'s
    # function-call branch and `assignable_expression`'s (both use the
    # exact same message).
    fn parse_arguments(mut self) -> List<i32>:
        let mut arguments: List<i32> = List<i32>()
        if !self.check(tok::TokenType::Rparen):
            let first = self.expression()
            if self.had_error:
                return arguments
            arguments.push(first)
            while self.match_any([tok::TokenType::Comma]) and !self.had_error:
                let nxt = self.expression()
                if self.had_error:
                    return arguments
                arguments.push(nxt)
        if !self.expect(tok::TokenType::Rparen, "Expected ')' after arguments"):
            return arguments
        arguments

    fn call(mut self) -> i32:
        let anchor = self.peek()
        let base = self.primary()
        if self.had_error:
            return base
        let expr = self.postfix_once(base, anchor)
        if self.had_error:
            return expr
        if self.match_any([tok::TokenType::Increment]):
            return self.push_expr(ast::ExprKind::Unary(operator = "++", expr = expr, is_post = true), anchor.line, anchor.column)
        if self.match_any([tok::TokenType::Decrement]):
            return self.push_expr(ast::ExprKind::Unary(operator = "--", expr = expr, is_post = true), anchor.line, anchor.column)
        expr

    fn primary(mut self) -> i32:
        if self.match_any([tok::TokenType::NumberLiteral]):
            let t = self.previous()
            return self.push_expr(ast::ExprKind::Literal(data_type = ast::DataType::Number, num_value = t.num_value, is_float = t.is_float, str_value = ""), t.line, t.column)
        if self.match_any([tok::TokenType::StringLiteral]):
            let t = self.previous()
            return self.push_expr(ast::ExprKind::Literal(data_type = ast::DataType::String, num_value = 0 as f64, is_float = false, str_value = t.str_value), t.line, t.column)
        if self.match_any([tok::TokenType::Identifier, tok::TokenType::Dim, tok::TokenType::Getkey, tok::TokenType::Serin, tok::TokenType::Serstat]):
            let t = self.previous()
            return self.push_expr(ast::ExprKind::Variable(name = t.lexeme), t.line, t.column)
        if is_function_token(self.peek().kind):
            let t = self.advance()
            return self.push_expr(ast::ExprKind::Variable(name = t.lexeme), t.line, t.column)
        if self.match_any([tok::TokenType::Lparen]):
            let lparen_tok = self.previous()
            let inner = self.expression()
            if self.had_error:
                return inner
            if !self.expect(tok::TokenType::Rparen, "Expected ')' after expression"):
                return inner
            return self.push_expr(ast::ExprKind::Grouping(expr = inner), lparen_tok.line, lparen_tok.column)
        self.fail("Expected expression")
        -1

    # See this file's header comment ("Preserved, not simplified away") for
    # why this is `self.call()` (already one full postfix round) plus one
    # *more* bare `postfix_once` round, not just `self.call()` alone.
    fn assignable_expression(mut self) -> i32:
        let anchor = self.peek()
        let base = self.call()
        if self.had_error:
            return base
        self.postfix_once(base, anchor)

# Parses `tokens` into an `Ast`, or the first `ParseError` encountered (this
# port stops at the first problem rather than the reference's
# exception-unwind, but reports the same message/line/column) -- same
# top-level shape as `lexer.star`'s own `lex`.
fn parse(tokens: List<tok::Token>, filename: str) -> Result<ast::Ast, ParseError>:
    let mut p = new_parser(tokens, filename)
    let mut program: List<i32> = List<i32>()
    while !p.is_at_end() and !p.had_error:
        let s = p.statement()
        if p.had_error:
            break
        program.push(s)
    if p.had_error:
        return Result<ast::Ast, ParseError>::Err(ParseError(message = p.error_message, filename = filename, line = p.error_line, column = p.error_column))
    Result<ast::Ast, ParseError>::Ok(ast::Ast(exprs = p.exprs, stmts = p.stmts, program = program))

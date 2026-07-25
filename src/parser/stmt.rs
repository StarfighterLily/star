//! Block and statement grammar.

use crate::ast::*;
use crate::diagnostics::Span;
use crate::lexer::TokenKind;

use super::Parser;

impl Parser {
    /// A generous bound on nested block parsing -- see `Parser::block_depth`'s
    /// doc comment. Kept well below `MAX_EXPR_DEPTH` since each block-nesting
    /// level costs more Rust stack frames than an expression-nesting level
    /// (`parse_block` -> `parse_stmt` -> one of `parse_if_stmt`/
    /// `parse_while_stmt`/`parse_for_stmt`/`parse_match`/... -> `parse_block`
    /// again).
    const MAX_BLOCK_DEPTH: u32 = 60;

    pub(super) fn parse_block(&mut self) -> Option<Block> {
        if self.block_depth >= Self::MAX_BLOCK_DEPTH {
            let span = self.peek_span();
            self.error(
                "block nested too deeply (over 60 levels of if/while/for/match/frame/par) -- likely a runaway generated program",
                span,
            );
            return None;
        }
        self.block_depth += 1;
        let result = self.parse_block_inner();
        self.block_depth -= 1;
        result
    }

    fn parse_block_inner(&mut self) -> Option<Block> {
        let start = self.peek_span();
        self.expect(&TokenKind::Newline)?;
        self.expect(&TokenKind::Indent)?;
        let mut stmts = Vec::new();
        while !self.at(&TokenKind::Dedent) && !self.at(&TokenKind::Eof) {
            if let Some(stmt) = self.parse_stmt() {
                stmts.push(stmt);
            } else {
                self.recover_to_newline();
            }
            self.skip_newlines();
        }
        self.expect(&TokenKind::Dedent)?;
        self.block_just_closed = true;
        let span = start.to(self.prev_span());
        Some(Block { stmts, span })
    }

    fn parse_stmt(&mut self) -> Option<Stmt> {
        match self.peek_kind() {
            TokenKind::Let => self.parse_let(),
            TokenKind::Return => self.parse_return(),
            TokenKind::If => self.parse_if_stmt(),
            // `match` is dispatched here rather than falling through to the
            // generic bare-expression case below: like `if`/`while`/`for`,
            // its own arm list ends in a `Dedent` (see `Parser::parse_match`)
            // that already re-syncs the token stream with the enclosing
            // block, so calling `expect_line_end()` afterward (as the
            // generic case does for an ordinary expression statement) would
            // look for a `Newline`/`Dedent` that was already consumed and
            // reject whatever token starts the *next* statement instead.
            TokenKind::Match => self.parse_match_stmt(),
            TokenKind::While => self.parse_while_stmt(),
            TokenKind::For => self.parse_for_stmt(),
            TokenKind::Break => self.parse_break_stmt(),
            TokenKind::Continue => self.parse_continue_stmt(),
            TokenKind::Frame => self.parse_frame_stmt(),
            TokenKind::Yield => self.parse_yield_stmt(),
            TokenKind::Par | TokenKind::Swarm => self.parse_par_stmt(),
            TokenKind::Each => self.parse_each_stmt(),
            TokenKind::Spawn => self.parse_spawn_stmt(),
            TokenKind::Despawn => self.parse_despawn_stmt(),
            TokenKind::Parallel => self.parse_parallel_stmt(),
            _ => {
                // Either an assignment or a bare expression.
                let expr = self.parse_expr()?;
                if let Some(op) = self.assign_op() {
                    let start = expr.span();
                    self.advance();
                    let value = self.parse_expr()?;
                    self.expect_line_end()?;
                    let span = start.to(self.prev_span());
                    return Some(Stmt::Assign { target: expr, op, value, span });
                }
                self.expect_line_end()?;
                Some(Stmt::Expr(expr))
            }
        }
    }

    /// `frame:` or `frame(<byte-budget>):` -- the parenthesized literal
    /// overrides the shared bump allocator's default byte budget for this
    /// block (see `Stmt::Frame::budget`'s doc comment). Mirrors
    /// `Parser::parse_arena`'s `= <capacity>` grammar: the budget must be a
    /// bare positive integer literal, not an arbitrary expression, since it
    /// sizes a bounds check at codegen time and has to be known without
    /// evaluating anything.
    fn parse_frame_stmt(&mut self) -> Option<Stmt> {
        let start = self.peek_span();
        self.expect(&TokenKind::Frame)?;
        let budget = if self.eat(&TokenKind::LParen) {
            let budget_span = self.peek_span();
            let n = match self.peek_kind() {
                TokenKind::Int(n) => {
                    self.advance();
                    if n <= 0 {
                        self.error(format!("`frame` budget must be a positive integer literal, found `{}`", n), budget_span);
                        None
                    } else {
                        Some(n as u64)
                    }
                }
                other => {
                    self.error(format!("expected an integer literal `frame` byte budget, found {}", other.describe()), budget_span);
                    return None;
                }
            };
            self.expect(&TokenKind::RParen)?;
            n
        } else {
            None
        };
        self.expect(&TokenKind::Colon)?;
        let body = self.parse_block()?;
        let span = start.to(self.prev_span());
        Some(Stmt::Frame { budget, body, span })
    }

    fn parse_yield_stmt(&mut self) -> Option<Stmt> {
        let start = self.peek_span();
        self.expect(&TokenKind::Yield)?;
        self.expect_line_end()?;
        let span = start.to(self.prev_span());
        Some(Stmt::Yield { span })
    }

    /// Parse `par item in ArenaName:` (or the `swarm` spelling) followed by a
    /// loop body dispatched across worker threads.
    fn parse_par_stmt(&mut self) -> Option<Stmt> {
        let start = self.peek_span();
        self.advance(); // `par` or `swarm`
        let var = self.expect_ident()?;
        self.expect(&TokenKind::In)?;
        let arena = self.expect_ident()?;
        self.expect(&TokenKind::Colon)?;
        let body = self.parse_block()?;
        let span = start.to(self.prev_span());
        Some(Stmt::Par { var, arena, body, span })
    }

    /// Parse `parallel: SystemA() SystemB() ...`, one bare `Name()` call per
    /// line -- mirrors `parse_block_inner`'s `Newline`/`Indent`/loop-until-
    /// `Dedent`/`Dedent` shape, but each "statement" is just a system name
    /// (systems take no arguments, so there's nothing to parse between the
    /// parens). The listed names are resolved against the checker's system
    /// table later (`crate::types::system_analysis`), not here -- the
    /// parser has no notion of what's been declared yet.
    fn parse_parallel_stmt(&mut self) -> Option<Stmt> {
        let start = self.peek_span();
        self.expect(&TokenKind::Parallel)?;
        self.expect(&TokenKind::Colon)?;
        self.expect(&TokenKind::Newline)?;
        self.expect(&TokenKind::Indent)?;
        let mut systems = Vec::new();
        while !self.at(&TokenKind::Dedent) && !self.at(&TokenKind::Eof) {
            if let Some(entry) = self.parse_parallel_system_call() {
                systems.push(entry);
            } else {
                self.recover_to_newline();
            }
            self.skip_newlines();
        }
        self.expect(&TokenKind::Dedent)?;
        self.block_just_closed = true;
        let span = start.to(self.prev_span());
        Some(Stmt::Parallel { systems, span })
    }

    /// One `Name()` line inside a `parallel:` block -- a bare system name,
    /// always with empty parens (systems take no arguments).
    fn parse_parallel_system_call(&mut self) -> Option<(String, Span)> {
        let name_span = self.peek_span();
        let name = self.expect_ident()?;
        self.expect(&TokenKind::LParen)?;
        self.expect(&TokenKind::RParen)?;
        self.expect_line_end()?;
        Some((name, name_span))
    }

    /// Parse `each item in ArenaName:` (optionally `each item, idx in
    /// ArenaName:`) followed by an ordinary sequential loop body over the
    /// arena's live elements (see `Stmt::Each`'s doc comment for how this
    /// differs from `par`/`swarm`, and for what the optional `idx` binding
    /// is for -- passing it to `despawn ArenaName[idx]` to conditionally
    /// reclaim slots during the scan).
    fn parse_each_stmt(&mut self) -> Option<Stmt> {
        let start = self.peek_span();
        self.expect(&TokenKind::Each)?;
        let var = self.expect_ident()?;
        let index_var = if self.eat(&TokenKind::Comma) {
            Some(self.expect_ident()?)
        } else {
            None
        };
        self.expect(&TokenKind::In)?;
        let arena = self.expect_ident()?;
        self.expect(&TokenKind::Colon)?;
        let body = self.parse_block()?;
        let span = start.to(self.prev_span());
        Some(Stmt::Each { var, index_var, arena, body, span })
    }

    /// Parse `spawn ArenaName(args...)`: constructs a new element of the
    /// arena's declared type and appends it to the arena's live set.
    fn parse_spawn_stmt(&mut self) -> Option<Stmt> {
        let start = self.peek_span();
        self.expect(&TokenKind::Spawn)?;
        let arena = self.expect_ident()?;
        let (args, arg_names) = self.parse_call_args()?;
        self.expect_line_end()?;
        let span = start.to(self.prev_span());
        Some(Stmt::Spawn { arena, args, arg_names, span })
    }

    /// Parse `despawn ArenaName[index]`: bumps the generation counter of the
    /// arena slot at `index`, invalidating any `GenRef` pointing at it.
    fn parse_despawn_stmt(&mut self) -> Option<Stmt> {
        let start = self.peek_span();
        self.expect(&TokenKind::Despawn)?;
        let arena = self.expect_ident()?;
        self.expect(&TokenKind::LBracket)?;
        let index = self.parse_expr()?;
        self.expect(&TokenKind::RBracket)?;
        self.expect_line_end()?;
        let span = start.to(self.prev_span());
        Some(Stmt::Despawn { arena, index, span })
    }

    fn parse_let(&mut self) -> Option<Stmt> {
        let start = self.peek_span();
        self.expect(&TokenKind::Let)?;
        let is_mut = self.eat(&TokenKind::Mut);
        let name = self.expect_ident()?;
        let ty = if self.eat(&TokenKind::Colon) {
            Some(self.parse_type()?)
        } else {
            None
        };
        self.expect(&TokenKind::Assign)?;
        // `let name = spawn ArenaName(args...)` is the one place `spawn` is
        // recognized as a value-producing expression (see `Expr::Spawn`'s
        // doc comment) -- checked directly here, rather than folded into
        // `parse_expr`'s general recursive-descent grammar, so `spawn`
        // everywhere else keeps parsing exactly as before (a bare statement
        // via `parse_spawn_stmt`, or a hard parse error in any other
        // expression position).
        let value = if self.at(&TokenKind::Spawn) { self.parse_spawn_expr()? } else { self.parse_expr()? };
        self.expect_line_end()?;
        let span = start.to(self.prev_span());
        Some(Stmt::Let { is_mut, name, ty, value, span })
    }

    /// Parse `spawn ArenaName(args...)` in expression position -- only ever
    /// called from `parse_let` above, never reachable as a nested
    /// sub-expression. Shares `spawn`'s statement-form argument grammar
    /// (`parse_call_args`) with `parse_spawn_stmt` below; the only
    /// difference is this one produces a value (`Expr::Spawn`) instead of a
    /// void statement (`Stmt::Spawn`).
    fn parse_spawn_expr(&mut self) -> Option<Expr> {
        let start = self.peek_span();
        self.expect(&TokenKind::Spawn)?;
        let arena = self.expect_ident()?;
        let (args, arg_names) = self.parse_call_args()?;
        let span = start.to(self.prev_span());
        Some(Expr::Spawn { arena, args, arg_names, span })
    }

    fn parse_return(&mut self) -> Option<Stmt> {
        let start = self.peek_span();
        self.expect(&TokenKind::Return)?;
        let value = if self.at(&TokenKind::Newline) || self.at(&TokenKind::Eof) {
            None
        } else {
            Some(self.parse_expr()?)
        };
        self.expect_line_end()?;
        let span = start.to(self.prev_span());
        Some(Stmt::Return { value, span })
    }

    /// If the current token is an assignment operator, return its AST form.
    fn assign_op(&self) -> Option<AssignOp> {
        match self.peek_kind() {
            TokenKind::Assign => Some(AssignOp::Eq),
            TokenKind::PlusEq => Some(AssignOp::Add),
            TokenKind::MinusEq => Some(AssignOp::Sub),
            TokenKind::StarEq => Some(AssignOp::Mul),
            TokenKind::SlashEq => Some(AssignOp::Div),
            _ => None,
        }
    }

    /// Parse `if <cond>:` followed by a block and an optional `else:` block,
    /// producing a statement form of `if`.
    ///
    /// Each arm accepts either a full indented block or a single compact
    /// inline trailing expression on the same line as the `:` -- reuses
    /// `Parser::parse_if_expr_arm` (the *expression* form's arm grammar) so
    /// this statement form supports exactly the same two shapes. Previously
    /// this always called `parse_block()` directly, which only ever accepts
    /// the full-indented-block shape: `if cond: a else: b` (or a bare
    /// trailing `if`/`else` at the end of a function body, meant as an
    /// implicit return value with no `let`) failed to parse outright
    /// ("expected end of line, found identifier `a`"), even though the
    /// exact same compact syntax already works fine on a `let`'s RHS (`let x
    /// = if cond: a else: b`), which goes through `parse_if_expr` instead
    /// (`projects/snake/NOTES.md` section 1.4).
    fn parse_if_stmt(&mut self) -> Option<Stmt> {
        let start = self.peek_span();
        self.expect(&TokenKind::If)?;
        let cond = self.parse_expr()?;
        self.expect(&TokenKind::Colon)?;
        let then_block = self.parse_if_expr_arm()?;
        let else_block = if self.eat(&TokenKind::Else) {
            self.expect(&TokenKind::Colon)?;
            Some(self.parse_if_expr_arm()?)
        } else {
            None
        };
        // A full-indented-block arm already consumed through its own
        // `Dedent` (`block_just_closed` is set, so this is a no-op); a
        // compact inline arm left its own trailing `Newline` unconsumed --
        // `expect_line_end` handles both.
        self.expect_line_end()?;
        let span = start.to(self.prev_span());
        Some(Stmt::If { cond, then_block, else_block, span })
    }

    /// Parse a `match` used as a bare statement: shares `Parser::parse_match`
    /// (also used for `match` nested inside a larger expression, e.g. `let x
    /// = match ...`) but, like `parse_if_stmt`, does not call
    /// `expect_line_end()` afterward -- `parse_match`'s own arm list already
    /// consumes the `Dedent` that re-syncs with the enclosing block.
    fn parse_match_stmt(&mut self) -> Option<Stmt> {
        let expr = self.parse_match()?;
        Some(Stmt::Expr(expr))
    }

    /// Parse `while <cond>:` followed by a loop body and an optional `else:` block.
    fn parse_while_stmt(&mut self) -> Option<Stmt> {
        let start = self.peek_span();
        self.expect(&TokenKind::While)?;
        let cond = self.parse_expr()?;
        self.expect(&TokenKind::Colon)?;
        let body = self.parse_block()?;
        let else_block = self.parse_opt_else();
        let span = start.to(self.prev_span());
        Some(Stmt::While { cond, body, else_block, span })
    }

    /// Parse `for <var> in <start>..<end>:` followed by a loop body
    /// (exclusive-range iteration over `i32` bounds).
    fn parse_for_stmt(&mut self) -> Option<Stmt> {
        let start = self.peek_span();
        self.expect(&TokenKind::For)?;
        let var = self.expect_ident()?;
        self.expect(&TokenKind::In)?;
        let range_start = self.parse_expr()?;
        self.expect(&TokenKind::DotDot)?;
        let range_end = self.parse_expr()?;
        self.expect(&TokenKind::Colon)?;
        let body = self.parse_block()?;
        let span = start.to(self.prev_span());
        Some(Stmt::For { var, start: range_start, end: range_end, body, span })
    }

    fn parse_break_stmt(&mut self) -> Option<Stmt> {
        let start = self.peek_span();
        self.expect(&TokenKind::Break)?;
        self.expect_line_end()?;
        let span = start.to(self.prev_span());
        Some(Stmt::Break { span })
    }

    fn parse_continue_stmt(&mut self) -> Option<Stmt> {
        let start = self.peek_span();
        self.expect(&TokenKind::Continue)?;
        self.expect_line_end()?;
        let span = start.to(self.prev_span());
        Some(Stmt::Continue { span })
    }

    /// If an `else:` token is next (at the current indentation level), consume it
    /// and parse the following indented block. Otherwise returns `None`.
    pub(super) fn parse_opt_else(&mut self) -> Option<Block> {
        if !self.eat(&TokenKind::Else) {
            return None;
        }
        self.expect(&TokenKind::Colon)?;
        self.parse_block()
    }
}

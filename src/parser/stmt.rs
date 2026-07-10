//! Block and statement grammar.

use crate::ast::*;
use crate::lexer::TokenKind;

use super::Parser;

impl Parser {
    pub(super) fn parse_block(&mut self) -> Option<Block> {
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
        let span = start.to(self.prev_span());
        Some(Block { stmts, span })
    }

    fn parse_stmt(&mut self) -> Option<Stmt> {
        match self.peek_kind() {
            TokenKind::Let => self.parse_let(),
            TokenKind::Return => self.parse_return(),
            TokenKind::If => self.parse_if_stmt(),
            TokenKind::While => self.parse_while_stmt(),
            TokenKind::Frame => self.parse_frame_stmt(),
            TokenKind::Yield => self.parse_yield_stmt(),
            TokenKind::Par | TokenKind::Swarm => self.parse_par_stmt(),
            TokenKind::Spawn => self.parse_spawn_stmt(),
            TokenKind::Despawn => self.parse_despawn_stmt(),
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

    fn parse_frame_stmt(&mut self) -> Option<Stmt> {
        let start = self.peek_span();
        self.expect(&TokenKind::Frame)?;
        self.expect(&TokenKind::Colon)?;
        let body = self.parse_block()?;
        let span = start.to(self.prev_span());
        Some(Stmt::Frame { body, span })
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

    /// Parse `spawn ArenaName(args...)`: constructs a new element of the
    /// arena's declared type and appends it to the arena's live set.
    fn parse_spawn_stmt(&mut self) -> Option<Stmt> {
        let start = self.peek_span();
        self.expect(&TokenKind::Spawn)?;
        let arena = self.expect_ident()?;
        let args = self.parse_call_args()?;
        self.expect_line_end()?;
        let span = start.to(self.prev_span());
        Some(Stmt::Spawn { arena, args, span })
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
        let value = self.parse_expr()?;
        self.expect_line_end()?;
        let span = start.to(self.prev_span());
        Some(Stmt::Let { is_mut, name, ty, value, span })
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
    fn parse_if_stmt(&mut self) -> Option<Stmt> {
        let start = self.peek_span();
        self.expect(&TokenKind::If)?;
        let cond = self.parse_expr()?;
        self.expect(&TokenKind::Colon)?;
        let then_block = self.parse_block()?;
        let else_block = self.parse_opt_else();
        let span = start.to(self.prev_span());
        Some(Stmt::If { cond, then_block, else_block, span })
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

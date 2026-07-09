//! Recursive-descent parser for Star.
//!
//! Consumes the structural token stream produced by [`crate::lexer`] and builds
//! the [`crate::ast`] tree. Indentation is already encoded as `Indent`/`Dedent`/
//! `Newline` tokens, so blocks are parsed by matching those markers rather than
//! tracking columns. Expression parsing uses precedence climbing (a Pratt-style
//! loop) for binary operators.

use crate::ast::*;
use crate::diagnostics::{Diagnostic, Span};
use crate::lexer::{FStrPart, Lexer, Token, TokenKind};

/// Parser state over a token slice.
pub struct Parser {
    tokens: Vec<Token>,
    pos: usize,
    errors: Vec<Diagnostic>,
}

impl Parser {
    pub fn new(tokens: Vec<Token>) -> Self {
        Self { tokens, pos: 0, errors: Vec::new() }
    }

    /// Parse a complete module from source, running the lexer first.
    pub fn parse_source(src: &str) -> Result<Module, Vec<Diagnostic>> {
        let tokens = Lexer::new(src).tokenize()?;
        Parser::new(tokens).parse_module()
    }

    /// Parse the top-level list of items.
    pub fn parse_module(mut self) -> Result<Module, Vec<Diagnostic>> {
        let mut items = Vec::new();
        self.skip_newlines();
        while !self.at(&TokenKind::Eof) {
            match self.parse_item() {
                Some(item) => items.push(item),
                None => {
                    // Error recovery: skip to the next line and continue.
                    self.recover_to_newline();
                    // `recover_to_newline` deliberately stops at (without
                    // consuming) a `Dedent`, so nested block parsers can see
                    // their own terminator. At module scope there's no
                    // enclosing block to preserve it for -- e.g. a struct
                    // missing its `:` leaves its indented body's Indent/Dedent
                    // pair never claimed by `parse_struct`, so recovery skips
                    // the body but stalls forever re-parsing the same stray
                    // Dedent (this token is never `Eof`, so the loop
                    // condition above never sees it and stops). Discard it so
                    // recovery always makes forward progress.
                    self.eat(&TokenKind::Dedent);
                }
            }
            self.skip_newlines();
        }
        if self.errors.is_empty() {
            Ok(Module { items })
        } else {
            Err(self.errors)
        }
    }

    // --- items -----------------------------------------------------------

    fn parse_item(&mut self) -> Option<Item> {
        match self.peek_kind() {
            TokenKind::Struct => self.parse_struct().map(Item::Struct),
            TokenKind::Trait => self.parse_trait().map(Item::Trait),
            TokenKind::Impl => self.parse_impl().map(Item::Impl),
            TokenKind::Fn => self.parse_fn().map(Item::Fn),
            TokenKind::Arena => self.parse_arena().map(Item::Arena),
            TokenKind::Sequence => self.parse_sequence().map(Item::Sequence),
            TokenKind::At => {
                let span = self.peek_span();
                self.error("decorators are only supported on struct fields", span);
                None
            }
            _ => {
                let span = self.peek_span();
                self.error("expected a top-level item (struct, trait, impl, fn, arena)", span);
                None
            }
        }
    }

    fn parse_arena(&mut self) -> Option<ArenaDecl> {
        let start = self.peek_span();
        self.expect(&TokenKind::Arena)?;
        let name = self.expect_ident()?;
        self.expect(&TokenKind::Colon)?;
        let ty = self.parse_type()?;
        self.expect_line_end()?;
        let span = start.to(self.prev_span());
        Some(ArenaDecl { name, ty, span })
    }

    fn parse_sequence(&mut self) -> Option<SequenceDef> {
        let start = self.peek_span();
        self.expect(&TokenKind::Sequence)?;
        let name = self.expect_ident()?;
        self.expect(&TokenKind::LParen)?;
        let mut params = Vec::new();
        while !self.at(&TokenKind::RParen) && !self.at(&TokenKind::Eof) {
            params.push(self.parse_param()?);
            if !self.eat(&TokenKind::Comma) {
                break;
            }
        }
        self.expect(&TokenKind::RParen)?;
        self.expect(&TokenKind::Colon)?;
        let body = self.parse_block()?;
        let span = start.to(self.prev_span());
        Some(SequenceDef { name, params, body, span })
    }

    fn parse_struct(&mut self) -> Option<StructDef> {
        let start = self.peek_span();
        self.expect(&TokenKind::Struct)?;
        let name = self.expect_ident()?;
        self.expect(&TokenKind::Colon)?;
        self.expect(&TokenKind::Newline)?;
        self.expect(&TokenKind::Indent)?;

        let mut fields = Vec::new();
        while !self.at(&TokenKind::Dedent) && !self.at(&TokenKind::Eof) {
            if let Some(field) = self.parse_field() {
                fields.push(field);
            } else {
                self.recover_to_newline();
            }
            self.skip_newlines();
        }
        self.expect(&TokenKind::Dedent)?;
        let span = start.to(self.prev_span());
        Some(StructDef { name, fields, span })
    }

    fn parse_field(&mut self) -> Option<FieldDef> {
        let start = self.peek_span();
        // Optional decorators: @export, @tweakable, ...
        let mut decorators = Vec::new();
        while self.eat(&TokenKind::At) {
            decorators.push(self.expect_ident()?);
        }
        let is_mut = self.eat(&TokenKind::Mut);
        let name = self.expect_ident()?;
        self.expect(&TokenKind::Colon)?;
        let ty = self.parse_type()?;
        let default = if self.eat(&TokenKind::Assign) {
            Some(self.parse_expr()?)
        } else {
            None
        };
        self.expect_line_end()?;
        let span = start.to(self.prev_span());
        Some(FieldDef { is_mut, name, ty, default, decorators, span })
    }

    fn parse_trait(&mut self) -> Option<TraitDef> {
        let start = self.peek_span();
        self.expect(&TokenKind::Trait)?;
        let name = self.expect_ident()?;
        self.expect(&TokenKind::Colon)?;
        self.expect(&TokenKind::Newline)?;
        self.expect(&TokenKind::Indent)?;

        let mut methods = Vec::new();
        while !self.at(&TokenKind::Dedent) && !self.at(&TokenKind::Eof) {
            if let Some(sig) = self.parse_fn_sig() {
                self.expect_line_end();
                methods.push(sig);
            } else {
                self.recover_to_newline();
            }
            self.skip_newlines();
        }
        self.expect(&TokenKind::Dedent)?;
        let span = start.to(self.prev_span());
        Some(TraitDef { name, methods, span })
    }

    fn parse_impl(&mut self) -> Option<ImplBlock> {
        let start = self.peek_span();
        self.expect(&TokenKind::Impl)?;
        let first = self.expect_ident()?;
        // `impl Trait for Type` vs inherent `impl Type`.
        let (trait_name, type_name) = if self.eat(&TokenKind::For) {
            (Some(first), self.expect_ident()?)
        } else {
            (None, first)
        };
        self.expect(&TokenKind::Colon)?;
        self.expect(&TokenKind::Newline)?;
        self.expect(&TokenKind::Indent)?;

        let mut methods = Vec::new();
        while !self.at(&TokenKind::Dedent) && !self.at(&TokenKind::Eof) {
            if let Some(f) = self.parse_fn() {
                methods.push(f);
            } else {
                self.recover_to_newline();
            }
            self.skip_newlines();
        }
        self.expect(&TokenKind::Dedent)?;
        let span = start.to(self.prev_span());
        Some(ImplBlock { trait_name, type_name, methods, span })
    }

    fn parse_fn_sig(&mut self) -> Option<FnSig> {
        let start = self.peek_span();
        self.expect(&TokenKind::Fn)?;
        let name = self.expect_ident()?;
        self.expect(&TokenKind::LParen)?;
        let mut params = Vec::new();
        while !self.at(&TokenKind::RParen) && !self.at(&TokenKind::Eof) {
            params.push(self.parse_param()?);
            if !self.eat(&TokenKind::Comma) {
                break;
            }
        }
        self.expect(&TokenKind::RParen)?;
        let ret = if self.eat(&TokenKind::Arrow) {
            Some(self.parse_type()?)
        } else {
            None
        };
        let span = start.to(self.prev_span());
        Some(FnSig { name, params, ret, span })
    }

    fn parse_param(&mut self) -> Option<Param> {
        let start = self.peek_span();
        let is_mut = self.eat(&TokenKind::Mut);
        // `self` / `mut self` receiver.
        if self.at(&TokenKind::SelfKw) {
            self.advance();
            let span = start.to(self.prev_span());
            return Some(Param { is_self: true, is_mut, name: "self".into(), ty: None, span });
        }
        let name = self.expect_ident()?;
        self.expect(&TokenKind::Colon)?;
        let ty = self.parse_type()?;
        let span = start.to(self.prev_span());
        Some(Param { is_self: false, is_mut, name, ty: Some(ty), span })
    }

    fn parse_fn(&mut self) -> Option<FnDef> {
        let start = self.peek_span();
        let sig = self.parse_fn_sig()?;
        self.expect(&TokenKind::Colon)?;
        let body = self.parse_block()?;
        let span = start.to(self.prev_span());
        Some(FnDef { sig, body, span })
    }

    // --- types -----------------------------------------------------------

    fn parse_type(&mut self) -> Option<Type> {
        let name = self.expect_ident()?;
        if self.eat(&TokenKind::Lt) {
            let mut args = Vec::new();
            while !self.at(&TokenKind::Gt) && !self.at(&TokenKind::Eof) {
                args.push(self.parse_type()?);
                if !self.eat(&TokenKind::Comma) {
                    break;
                }
            }
            self.expect(&TokenKind::Gt)?;
            return Some(Type::Generic(name, args));
        }
        Some(Type::Named(name))
    }

    // --- blocks & statements --------------------------------------------

    fn parse_block(&mut self) -> Option<Block> {
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
    fn parse_opt_else(&mut self) -> Option<Block> {
        if !self.eat(&TokenKind::Else) {
            return None;
        }
        self.expect(&TokenKind::Colon)?;
        self.parse_block()
    }

    // --- expressions (precedence climbing) ------------------------------

    fn parse_expr(&mut self) -> Option<Expr> {
        self.parse_binary(0)
    }

    fn parse_binary(&mut self, min_bp: u8) -> Option<Expr> {
        let mut lhs = self.parse_unary()?;
        while let Some((op, bp)) = self.peek_binop() {
            if bp < min_bp {
                break;
            }
            self.advance();
            let rhs = self.parse_binary(bp + 1)?;
            let span = lhs.span().to(rhs.span());
            lhs = Expr::Binary { op, lhs: Box::new(lhs), rhs: Box::new(rhs), span };
        }
        Some(lhs)
    }

    /// Return the binary operator at the cursor with its binding power.
    fn peek_binop(&self) -> Option<(BinOp, u8)> {
        // Special case: GenRef followed by < is NOT a binary operator
        if let TokenKind::Ident(name) = self.peek_kind() {
            if name == "GenRef" {
                return None; // GenRef<T> is a type construction, not a comparison
            }
        }
        if let TokenKind::Lt = self.peek_kind() {
            // Check if previous expression was GenRef (we need to look at context)
            // This is complex, so we'll handle GenRef<T> in parse_postfix instead
            // For now, just return None at top-level when we're after GenRef
            return None;
        }
        let op = match self.peek_kind() {
            TokenKind::Star => (BinOp::Mul, 7),
            TokenKind::Slash => (BinOp::Div, 7),
            TokenKind::Percent => (BinOp::Rem, 7),
            TokenKind::Plus => (BinOp::Add, 6),
            TokenKind::Minus => (BinOp::Sub, 6),
            TokenKind::Lt => (BinOp::Lt, 4),
            TokenKind::Gt => (BinOp::Gt, 4),
            TokenKind::LtEq => (BinOp::Le, 4),
            TokenKind::GtEq => (BinOp::Ge, 4),
            TokenKind::EqEq => (BinOp::Eq, 3),
            TokenKind::NotEq => (BinOp::Ne, 3),
            _ => return None,
        };
        Some(op)
    }

    fn parse_unary(&mut self) -> Option<Expr> {
        let start = self.peek_span();
        match self.peek_kind() {
            TokenKind::Minus => {
                self.advance();
                let operand = self.parse_unary()?;
                let span = start.to(operand.span());
                Some(Expr::Unary { op: UnOp::Neg, operand: Box::new(operand), span })
            }
            TokenKind::Not => {
                self.advance();
                let operand = self.parse_unary()?;
                let span = start.to(operand.span());
                Some(Expr::Unary { op: UnOp::Not, operand: Box::new(operand), span })
            }
            _ => self.parse_postfix(),
        }
    }

    /// Parse a primary expression followed by any number of `.field` accesses,
    /// `(...)` calls (with optional `<T>` for GenRef), and `[...]` index operations.
    fn parse_postfix(&mut self) -> Option<Expr> {
        let mut expr = self.parse_primary()?;
        loop {
            match self.peek_kind() {
                TokenKind::Dot => {
                    self.advance();
                    let field = self.expect_ident()?;
                    let span = expr.span().to(self.prev_span());
                    expr = Expr::Field { base: Box::new(expr), field, span };
                }
                TokenKind::LParen => {
                    // Check if this is GenRef followed by < (generic type args)
                    // If we're at LParen and expr is GenRef, we check if <T> was before
                    // But in GenRef<T>(value), the <T> comes before (
                    // So we handle GenRef<i32>(value) in the Lt case above
                    // This handles GenRef(value) without type args
                    if let Expr::Ident(name, _) = &expr {
                        if name == "GenRef" {
                            let args = self.parse_call_args()?;
                            let value = args.into_iter().next().unwrap_or(Expr::Int(0, Span::dummy()));
                            let span = expr.span().to(self.prev_span());
                            return Some(Expr::GenRefCreate { inner_ty: Type::Named("i32".into()), value: Box::new(value), span });
                        }
                    }
                    let args = self.parse_call_args()?;
                    let span = expr.span().to(self.prev_span());
                    expr = Expr::Call { callee: Box::new(expr), args, span };
                }
                // GenRef<T>(value) - handle generic type args before parens
                TokenKind::Lt => {
                    if let Expr::Ident(name, _) = &expr {
                        if name == "GenRef" {
                            // Consume the <
                            self.advance();
                            // Parse the inner type <T>
                            let mut type_args = Vec::new();
                            while !self.at(&TokenKind::Gt) && !self.at(&TokenKind::Eof) {
                                type_args.push(self.parse_type()?);
                                if !self.eat(&TokenKind::Comma) {
                                    break;
                                }
                            }
                            self.expect(&TokenKind::Gt)?;
                            let inner_ty = type_args.into_iter().next().unwrap_or(Type::Named("unknown".into()));
                            // Now parse the call args (value)
                            let args = self.parse_call_args()?;
                            let value = args.into_iter().next().unwrap_or(Expr::Int(0, Span::dummy()));
                            let span = expr.span().to(self.prev_span());
                            return Some(Expr::GenRefCreate { inner_ty, value: Box::new(value), span });
                        }
                    }
                    // Just a comparison operator in a binary expression context
                    break;
                }
                TokenKind::LBracket => {
                    // GenRef dereference: expr[idx]
                    let start = expr.span();
                    self.advance();
                    let index = self.parse_expr()?;
                    self.expect(&TokenKind::RBracket)?;
                    let span = start.to(self.prev_span());
                    expr = Expr::GenRefIndex { base: Box::new(expr), index: Box::new(index), span };
                }
                _ => break,
            }
        }
        Some(expr)
    }

    fn parse_call_args(&mut self) -> Option<Vec<Expr>> {
        self.expect(&TokenKind::LParen)?;
        let mut args = Vec::new();
        while !self.at(&TokenKind::RParen) && !self.at(&TokenKind::Eof) {
            // Allow named-argument syntax `field = expr` used by struct literals;
            // the name is dropped here and positions are matched by the checker.
            if matches!(self.peek_kind(), TokenKind::Ident(_)) && self.peek_kind_at(1) == Some(TokenKind::Assign) {
                self.advance(); // ident
                self.advance(); // '='
            }
            args.push(self.parse_expr()?);
            if !self.eat(&TokenKind::Comma) {
                break;
            }
        }
        self.expect(&TokenKind::RParen)?;
        Some(args)
    }

    fn parse_primary(&mut self) -> Option<Expr> {
        let span = self.peek_span();
        match self.peek_kind() {
            TokenKind::Int(v) => {
                self.advance();
                Some(Expr::Int(v, span))
            }
            TokenKind::Float(v) => {
                self.advance();
                Some(Expr::Float(v, span))
            }
            TokenKind::Str(s) => {
                self.advance();
                Some(Expr::Str(s, span))
            }
            TokenKind::True => {
                self.advance();
                Some(Expr::Bool(true, span))
            }
            TokenKind::False => {
                self.advance();
                Some(Expr::Bool(false, span))
            }
            TokenKind::SelfKw => {
                self.advance();
                Some(Expr::SelfExpr(span))
            }
            TokenKind::Match => self.parse_match(),
            TokenKind::If => self.parse_if_expr(),
            TokenKind::LParen => {
                self.advance();
                let inner = self.parse_expr()?;
                self.expect(&TokenKind::RParen)?;
                Some(inner)
            }
            TokenKind::FStr(parts) => {
                self.advance();
                let lowered = self.lower_fstring(parts)?;
                Some(Expr::FStr(lowered, span))
            }
            TokenKind::Ident(name) => {
                self.advance();
                // Struct literal when an identifier is immediately called and the
                // name is capitalized (type-like), e.g. `Vec3(0, 0, 0)`.
                if self.at(&TokenKind::LParen) && starts_uppercase(&name) {
                    let args = self.parse_call_args()?;
                    let full = span.to(self.prev_span());
                    return Some(Expr::StructLit { name, args, span: full });
                }
                Some(Expr::Ident(name, span))
            }
            other => {
                self.error(format!("unexpected token in expression: {:?}", other), span);
                None
            }
        }
    }

    /// Parse `if <cond>:` followed by a block and an optional `else:` block,
    /// producing an expression form of `if` (used as a value, e.g. in `let`).
    fn parse_if_expr(&mut self) -> Option<Expr> {
        let start = self.peek_span();
        self.expect(&TokenKind::If)?;
        let cond = Box::new(self.parse_expr()?);
        self.expect(&TokenKind::Colon)?;
        let then_block = self.parse_block()?;
        let else_block = self.parse_opt_else();
        let span = start.to(self.prev_span());
        Some(Expr::If { cond, then_block, else_block, span })
    }

    /// Re-lex and parse the embedded expressions inside an f-string.
    fn lower_fstring(&mut self, parts: Vec<FStrPart>) -> Option<Vec<FStrExpr>> {
        let mut out = Vec::new();
        for part in parts {
            match part {
                FStrPart::Literal(s) => out.push(FStrExpr::Literal(s)),
                FStrPart::Expr(src) => {
                    let tokens = match Lexer::new(&src).tokenize() {
                        Ok(t) => t,
                        Err(mut errs) => {
                            self.errors.append(&mut errs);
                            return None;
                        }
                    };
                    let mut sub = Parser::new(tokens);
                    let expr = sub.parse_expr()?;
                    self.errors.append(&mut sub.errors);
                    out.push(FStrExpr::Expr(Box::new(expr)));
                }
            }
        }
        Some(out)
    }

    fn parse_match(&mut self) -> Option<Expr> {
        let start = self.peek_span();
        self.expect(&TokenKind::Match)?;
        let scrutinee = self.parse_expr()?;
        self.expect(&TokenKind::Colon)?;
        self.expect(&TokenKind::Newline)?;
        self.expect(&TokenKind::Indent)?;
        let mut arms = Vec::new();
        while !self.at(&TokenKind::Dedent) && !self.at(&TokenKind::Eof) {
            if let Some(arm) = self.parse_match_arm() {
                arms.push(arm);
            } else {
                self.recover_to_newline();
            }
            self.skip_newlines();
        }
        self.expect(&TokenKind::Dedent)?;
        let span = start.to(self.prev_span());
        Some(Expr::Match { scrutinee: Box::new(scrutinee), arms, span })
    }

    fn parse_match_arm(&mut self) -> Option<MatchArm> {
        let start = self.peek_span();
        let pattern = self.parse_pattern()?;
        self.expect(&TokenKind::Arrow)?;
        // Arm body: either an inline expression or an indented block.
        let body = if self.at(&TokenKind::Newline) {
            self.parse_block()?
        } else {
            let expr = self.parse_expr()?;
            self.expect_line_end()?;
            let span = expr.span();
            Block { stmts: vec![Stmt::Expr(expr)], span }
        };
        let span = start.to(self.prev_span());
        Some(MatchArm { pattern, body, span })
    }

    fn parse_pattern(&mut self) -> Option<Pattern> {
        match self.peek_kind() {
            TokenKind::Underscore => {
                self.advance();
                Some(Pattern::Wildcard)
            }
            TokenKind::LtEq => self.compare_pattern(BinOp::Le),
            TokenKind::GtEq => self.compare_pattern(BinOp::Ge),
            TokenKind::Lt => self.compare_pattern(BinOp::Lt),
            TokenKind::Gt => self.compare_pattern(BinOp::Gt),
            TokenKind::EqEq => self.compare_pattern(BinOp::Eq),
            TokenKind::Int(v) => {
                self.advance();
                Some(Pattern::Int(v))
            }
            TokenKind::True => {
                self.advance();
                Some(Pattern::Bool(true))
            }
            TokenKind::False => {
                self.advance();
                Some(Pattern::Bool(false))
            }
            TokenKind::Ident(name) => {
                self.advance();
                Some(Pattern::Binding(name))
            }
            other => {
                let span = self.peek_span();
                self.error(format!("unexpected token in pattern: {:?}", other), span);
                None
            }
        }
    }

    fn compare_pattern(&mut self, op: BinOp) -> Option<Pattern> {
        self.advance();
        let expr = self.parse_expr()?;
        Some(Pattern::Compare(op, Box::new(expr)))
    }

    // --- token helpers ---------------------------------------------------

    fn peek_kind(&self) -> TokenKind {
        self.tokens[self.pos].kind.clone()
    }

    fn peek_kind_at(&self, ahead: usize) -> Option<TokenKind> {
        self.tokens.get(self.pos + ahead).map(|t| t.kind.clone())
    }

    fn peek_span(&self) -> Span {
        self.tokens[self.pos].span
    }

    fn prev_span(&self) -> Span {
        self.tokens[self.pos.saturating_sub(1)].span
    }

    fn at(&self, kind: &TokenKind) -> bool {
        std::mem::discriminant(&self.tokens[self.pos].kind) == std::mem::discriminant(kind)
    }

    fn advance(&mut self) -> Token {
        let tok = self.tokens[self.pos].clone();
        if self.pos < self.tokens.len() - 1 {
            self.pos += 1;
        }
        tok
    }

    fn eat(&mut self, kind: &TokenKind) -> bool {
        if self.at(kind) {
            self.advance();
            true
        } else {
            false
        }
    }

    fn expect(&mut self, kind: &TokenKind) -> Option<()> {
        if self.at(kind) {
            self.advance();
            Some(())
        } else {
            let span = self.peek_span();
            self.error(
                format!("expected {}, found {}", kind.describe(), self.peek_kind().describe()),
                span,
            );
            None
        }
    }

    fn expect_ident(&mut self) -> Option<String> {
        if let TokenKind::Ident(name) = self.peek_kind() {
            self.advance();
            Some(name)
        } else {
            let span = self.peek_span();
            self.error(format!("expected an identifier, found {}", self.peek_kind().describe()), span);
            None
        }
    }

    /// Consume a newline or accept EOF/Dedent as an implicit line end.
    fn expect_line_end(&mut self) -> Option<()> {
        if self.at(&TokenKind::Newline) {
            self.advance();
            Some(())
        } else if self.at(&TokenKind::Eof) || self.at(&TokenKind::Dedent) {
            Some(())
        } else {
            let span = self.peek_span();
            self.error(format!("expected end of line, found {}", self.peek_kind().describe()), span);
            None
        }
    }

    fn skip_newlines(&mut self) {
        while self.at(&TokenKind::Newline) {
            self.advance();
        }
    }

    /// Error recovery: advance to just past the next newline.
    fn recover_to_newline(&mut self) {
        while !self.at(&TokenKind::Newline)
            && !self.at(&TokenKind::Eof)
            && !self.at(&TokenKind::Dedent)
        {
            self.advance();
        }
        self.eat(&TokenKind::Newline);
    }

    fn error(&mut self, msg: impl Into<String>, span: Span) {
        self.errors.push(Diagnostic::error(msg, span));
    }
}

fn starts_uppercase(name: &str) -> bool {
    name.chars().next().map(|c| c.is_ascii_uppercase()).unwrap_or(false)
}
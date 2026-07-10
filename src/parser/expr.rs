//! Expression grammar: precedence-climbing binary operators, unary/postfix
//! chains, `match`, and the `if` expression form.

use crate::ast::*;
use crate::diagnostics::Span;
use crate::lexer::{FStrPart, Lexer, TokenKind};

use super::{starts_uppercase, Parser};

impl Parser {
    pub(super) fn parse_expr(&mut self) -> Option<Expr> {
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
    ///
    /// `<` is both a comparison operator and the opener of a generic
    /// turbofish (`GenRef<T>(..)`, `Box<i32>(..)`); the turbofish forms are
    /// fully consumed by `parse_primary`/`parse_postfix` *before* control
    /// ever reaches this function for that `<` (a capitalized identifier
    /// immediately followed by `<` eagerly parses type arguments there), so
    /// by the time this is called, any `<` at the cursor genuinely is a
    /// comparison -- no special-casing needed here.
    fn peek_binop(&self) -> Option<(BinOp, u8)> {
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
            // Lower precedence than comparisons (so `a > 0 and b > 0` parses
            // as `(a > 0) and (b > 0)`, not `a > (0 and b) > 0`), and `and`
            // binds tighter than `or` (`a and b or c` == `(a and b) or c`),
            // mirroring Python's own logical-operator precedence.
            TokenKind::AndAnd => (BinOp::And, 2),
            TokenKind::OrOr => (BinOp::Or, 1),
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

    /// Parse an explicit generic turbofish `<Type, ...>` at an expression
    /// construction site (`Box<i32>(...)`, `Option<i32>::Some(...)`).
    /// Assumes the cursor is at `<`.
    fn parse_type_args(&mut self) -> Option<Vec<Type>> {
        self.expect(&TokenKind::Lt)?;
        let mut args = Vec::new();
        while !self.at(&TokenKind::Gt) && !self.at(&TokenKind::Eof) {
            args.push(self.parse_type()?);
            if !self.eat(&TokenKind::Comma) {
                break;
            }
        }
        self.expect(&TokenKind::Gt)?;
        Some(args)
    }

    pub(super) fn parse_call_args(&mut self) -> Option<Vec<Expr>> {
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
            TokenKind::Fn => self.parse_lambda(),
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
            TokenKind::LBracket => {
                self.advance();
                let mut elems = Vec::new();
                while !self.at(&TokenKind::RBracket) && !self.at(&TokenKind::Eof) {
                    elems.push(self.parse_expr()?);
                    if !self.eat(&TokenKind::Comma) {
                        break;
                    }
                }
                self.expect(&TokenKind::RBracket)?;
                let full = span.to(self.prev_span());
                Some(Expr::ListLit(elems, full))
            }
            TokenKind::Ident(name) => {
                self.advance();
                // Struct literal when an identifier is immediately called and the
                // name is capitalized (type-like), e.g. `Vec3(0, 0, 0)`.
                // Explicit generic type arguments: `Box<i32>(...)` or
                // `Option<i32>::Variant(...)`. Only attempted for
                // capitalized (type-like) names immediately followed by `<`,
                // mirroring the `GenRef<T>` special case below -- `<` is
                // otherwise never treated as a binary operator by
                // `peek_binop`, so this can't misfire on a real comparison.
                // `GenRef` itself is excluded: its own `<T>(value)` syntax is
                // handled entirely by `parse_postfix` below, and must see the
                // `<` untouched.
                let type_args = if name != "GenRef" && starts_uppercase(&name) && self.at(&TokenKind::Lt) {
                    self.parse_type_args()?
                } else {
                    Vec::new()
                };
                if self.at(&TokenKind::LParen) && starts_uppercase(&name) {
                    let args = self.parse_call_args()?;
                    let full = span.to(self.prev_span());
                    return Some(Expr::StructLit { name, type_args, args, span: full });
                }
                // A path into an imported module's namespace: either
                // `module::Enum::Variant[(args)]` or `module::item[(args)]`
                // (a function call or struct literal, told apart by the same
                // capitalization convention as the unqualified forms above).
                // Reproduces the `alias__name` mangling that
                // `crate::modules::resolve` applied to the imported file's
                // own top-level declarations.
                if self.import_aliases.contains(&name) && self.at(&TokenKind::ColonColon) {
                    self.advance();
                    let first = self.expect_ident()?;
                    if self.eat(&TokenKind::ColonColon) {
                        let variant = self.expect_ident()?;
                        let args = if self.at(&TokenKind::LParen) {
                            self.parse_call_args()?
                        } else {
                            Vec::new()
                        };
                        let full = span.to(self.prev_span());
                        let enum_name = crate::modules::mangle_name(&name, &first);
                        return Some(Expr::EnumVariant { enum_name, type_args: Vec::new(), variant, args, span: full });
                    }
                    let mangled = crate::modules::mangle_name(&name, &first);
                    if self.at(&TokenKind::LParen) {
                        let args = self.parse_call_args()?;
                        let full = span.to(self.prev_span());
                        if starts_uppercase(&first) {
                            return Some(Expr::StructLit { name: mangled, type_args: Vec::new(), args, span: full });
                        }
                        return Some(Expr::Call { callee: Box::new(Expr::Ident(mangled, span)), args, span: full });
                    }
                    let full = span.to(self.prev_span());
                    return Some(Expr::Ident(mangled, full));
                }
                // Enum variant literal: `EnumName::Variant` or, for a
                // payload variant, `EnumName::Variant(args...)`.
                if self.eat(&TokenKind::ColonColon) {
                    let variant = self.expect_ident()?;
                    let args = if self.at(&TokenKind::LParen) {
                        self.parse_call_args()?
                    } else {
                        Vec::new()
                    };
                    let full = span.to(self.prev_span());
                    return Some(Expr::EnumVariant { enum_name: name, type_args, variant, args, span: full });
                }
                if !type_args.is_empty() {
                    self.error("expected `(` or `::` after generic type arguments", span);
                    return None;
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

    /// Parse a lambda/closure literal: `fn(params) [-> RetType]: <body>`.
    /// Mirrors `parse_fn_sig`'s param-list/return-type grammar (reusing
    /// `parse_param`) but in expression position, and mirrors a `match`
    /// arm's body grammar (`parse_match_arm`): either a full indented block,
    /// or -- since a lambda is an *expression*, possibly nested inside a
    /// call's argument list rather than standing alone as a statement -- a
    /// single inline trailing expression that does *not* consume a line end
    /// itself (unlike a match arm, which owns its own line).
    fn parse_lambda(&mut self) -> Option<Expr> {
        let start = self.peek_span();
        self.expect(&TokenKind::Fn)?;
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
        self.expect(&TokenKind::Colon)?;
        let body = if self.at(&TokenKind::Newline) {
            self.parse_block()?
        } else {
            let expr = self.parse_expr()?;
            let span = expr.span();
            Block { stmts: vec![Stmt::Expr(expr)], span }
        };
        let span = start.to(self.prev_span());
        Some(Expr::Lambda { params, ret, body, span })
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
                    // Interpolated expressions can reference module aliases
                    // brought into scope by an outer `import`, so the
                    // sub-parser needs to know about them too.
                    sub.import_aliases = self.import_aliases.clone();
                    let expr = sub.parse_expr()?;
                    self.errors.append(&mut sub.errors);
                    out.push(FStrExpr::Expr(Box::new(expr)));
                }
            }
        }
        Some(out)
    }

    pub(super) fn parse_match(&mut self) -> Option<Expr> {
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
                // A qualified pattern into an imported module: either
                // `module::Enum::Variant(bindings...)` or
                // `module::StructName(bindings...)`, mirroring the qualified
                // expression forms in `parse_primary`.
                if self.import_aliases.contains(&name) && self.at(&TokenKind::ColonColon) {
                    self.advance();
                    let first = self.expect_ident()?;
                    if self.eat(&TokenKind::ColonColon) {
                        let variant = self.expect_ident()?;
                        let bindings = if self.eat(&TokenKind::LParen) {
                            let mut names = Vec::new();
                            while !self.at(&TokenKind::RParen) && !self.at(&TokenKind::Eof) {
                                names.push(self.expect_ident()?);
                                if !self.eat(&TokenKind::Comma) {
                                    break;
                                }
                            }
                            self.expect(&TokenKind::RParen)?;
                            names
                        } else {
                            Vec::new()
                        };
                        let enum_name = crate::modules::mangle_name(&name, &first);
                        return Some(Pattern::EnumVariant(enum_name, variant, bindings));
                    }
                    self.expect(&TokenKind::LParen)?;
                    let mut names = Vec::new();
                    while !self.at(&TokenKind::RParen) && !self.at(&TokenKind::Eof) {
                        names.push(self.expect_ident()?);
                        if !self.eat(&TokenKind::Comma) {
                            break;
                        }
                    }
                    self.expect(&TokenKind::RParen)?;
                    let struct_name = crate::modules::mangle_name(&name, &first);
                    return Some(Pattern::Struct(struct_name, names));
                }
                // Enum variant pattern: `EnumName::Variant` or, for a
                // payload variant, `EnumName::Variant(binding, ...)`.
                if self.eat(&TokenKind::ColonColon) {
                    let variant = self.expect_ident()?;
                    let bindings = if self.eat(&TokenKind::LParen) {
                        let mut names = Vec::new();
                        while !self.at(&TokenKind::RParen) && !self.at(&TokenKind::Eof) {
                            names.push(self.expect_ident()?);
                            if !self.eat(&TokenKind::Comma) {
                                break;
                            }
                        }
                        self.expect(&TokenKind::RParen)?;
                        names
                    } else {
                        Vec::new()
                    };
                    return Some(Pattern::EnumVariant(name, variant, bindings));
                }
                // Struct destructuring pattern: `StructName(binding, ...)`,
                // which binds each of the struct's fields in declaration
                // order (mirrors the enum payload pattern's binding syntax).
                if self.at(&TokenKind::LParen) && starts_uppercase(&name) {
                    self.advance();
                    let mut names = Vec::new();
                    while !self.at(&TokenKind::RParen) && !self.at(&TokenKind::Eof) {
                        names.push(self.expect_ident()?);
                        if !self.eat(&TokenKind::Comma) {
                            break;
                        }
                    }
                    self.expect(&TokenKind::RParen)?;
                    return Some(Pattern::Struct(name, names));
                }
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
}

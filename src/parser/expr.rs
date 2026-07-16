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
        let mut lhs = self.parse_cast()?;
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

    /// `expr as Type` -- binds tighter than any binary operator (so `x as
    /// i64 + 1` parses as `(x as i64) + 1`, matching Rust's own `as`
    /// precedence) but looser than unary/postfix (`-x as i64` is `(-x) as
    /// i64`). Zero or more casts may chain (`x as i64 as f64`).
    fn parse_cast(&mut self) -> Option<Expr> {
        let mut expr = self.parse_unary()?;
        while self.eat(&TokenKind::As) {
            let ty = self.parse_type()?;
            let span = expr.span().to(self.prev_span());
            expr = Expr::Cast { expr: Box::new(expr), ty, span };
        }
        Some(expr)
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

    /// A generous bound on nested expression parsing -- see
    /// `Parser::expr_depth`'s doc comment. High enough that no real,
    /// hand-written expression should ever hit it, but low enough to fail
    /// fast with a clean diagnostic well before exhausting the real Rust
    /// call stack. Empirically, a debug build's default (~1-2MiB) thread
    /// stack overflows for real somewhere between 100 and 150 levels of
    /// this recursion (each level costs six-odd stack frames across
    /// `parse_unary`/`parse_unary_inner`/`parse_postfix`/`parse_primary`/
    /// `parse_expr`/`parse_binary`) -- 80 keeps a comfortable margin below
    /// that observed cliff (mirrors `Checker::MAX_MONO_DEPTH`'s similarly
    /// conservative, empirically-chosen bound) while staying well above
    /// `runtime_moderately_nested_parens_end_to_end`'s 50-level sanity case.
    pub(super) const MAX_EXPR_DEPTH: u32 = 80;

    fn parse_unary(&mut self) -> Option<Expr> {
        if self.expr_depth >= Self::MAX_EXPR_DEPTH {
            let span = self.peek_span();
            self.error(
                "expression nested too deeply (over 200 levels of parentheses/unary operators/nested brackets) -- likely a runaway generated expression",
                span,
            );
            return None;
        }
        self.expr_depth += 1;
        let result = self.parse_unary_inner();
        self.expr_depth -= 1;
        result
    }

    fn parse_unary_inner(&mut self) -> Option<Expr> {
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
                    // `base.0`, `base.1`, ... - a tuple index, distinct from
                    // an ordinary named `.field` access (see
                    // `Expr::TupleIndex`'s doc comment). The lexer already
                    // tokenizes a standalone `.` as its own `Dot` (never
                    // folded into a following digit, see `Lexer`'s number
                    // scanning), so an `Int` here unambiguously means a
                    // tuple index rather than a field name.
                    if let TokenKind::Int(v) = self.peek_kind() {
                        self.advance();
                        let span = expr.span().to(self.prev_span());
                        if v < 0 {
                            self.error("tuple index cannot be negative", span);
                            return None;
                        }
                        expr = Expr::TupleIndex { base: Box::new(expr), index: v as usize, span };
                        continue;
                    }
                    let field = self.expect_ident()?;
                    let span = expr.span().to(self.prev_span());
                    expr = Expr::Field { base: Box::new(expr), field, span };
                }
                TokenKind::LParen => {
                    // `GenRef(value)`/`Handle(value)` (no type args) can
                    // never reach here: `parse_primary`'s `Ident` arm already
                    // intercepts any capitalized-identifier-followed-by-`(`
                    // (including `GenRef`/`Handle`) as a struct-literal call
                    // and returns before `parse_postfix`'s loop ever runs;
                    // that call site separately rejects a bare `GenRef(`/
                    // `Handle(` with a clear error requiring
                    // `GenRef<T>(value)`/`Handle<T>(value)`. The `<T>(value)`
                    // form (with type args) is handled below, in the `Lt` arm.
                    let args = self.parse_call_args()?;
                    let span = expr.span().to(self.prev_span());
                    expr = Expr::Call { callee: Box::new(expr), args, span };
                }
                // GenRef<T>(value) / Handle<T>(value) / Wrapping<T>(value) -
                // handle generic type args before parens. `Handle<T>` is
                // `Ty::Handle`'s surface syntax: the exact same
                // generation-checked construction as `GenRef<T>`, just a
                // nominally distinct wrapper type for engine resources rather
                // than arena entities (see `Ty::Handle`'s doc comment) -- so
                // it reuses this same parsing path and AST node, tagged via
                // `is_handle`. `Wrapping<T>` shares the identical `<T>(value)`
                // shape but produces a different, dedicated `Expr::WrappingNew`
                // node (see its doc comment) since it has nothing to do with
                // arenas/generation-checking.
                TokenKind::Lt => {
                    if let Expr::Ident(name, _) = &expr {
                        // `Fixed<Bits, Frac>(value)` has a different `<...>`
                        // shape (two bare integer literals, not one `Type`),
                        // so it can't share `parse_type_args` -- mirrors
                        // `Ring<T, N>`'s own dedicated probe/parse pair (see
                        // `parse_ring_new`/`probe_ring_shape`).
                        if name == "Fixed" {
                            match self.parse_fixed_new(expr.span()) {
                                Ok(Some(fixed_expr)) => return Some(fixed_expr),
                                Err(()) => return None,
                                Ok(None) => {}
                            }
                        }
                        let is_handle = name == "Handle";
                        let is_wrapping = name == "Wrapping";
                        if name == "GenRef" || is_handle || is_wrapping {
                            let kind = if is_handle { "Handle" } else if is_wrapping { "Wrapping" } else { "GenRef" };
                            // Speculative, like `try_parse_type_args`: a
                            // capitalized identifier followed by `<` is just
                            // as often a comparison on a shadowed local
                            // (`if GenRef < 5:`) as a real `GenRef<T>(..)`/
                            // `Handle<T>(..)`/`Wrapping<T>(..)` construction.
                            // Only commit once `<...>` parses cleanly *and* is
                            // immediately followed by `(` (the only valid
                            // continuation); otherwise restore the
                            // cursor/diagnostics and fall through to ordinary
                            // comparison handling.
                            let checkpoint = self.pos;
                            let err_checkpoint = self.errors.len();
                            match self.parse_type_args() {
                                Some(type_args) if self.at(&TokenKind::LParen) => {
                                    let args_span = expr.span().to(self.prev_span());
                                    if type_args.len() != 1 {
                                        self.error(
                                            format!(
                                                "`{}` expects exactly one type argument, found {}",
                                                kind,
                                                type_args.len()
                                            ),
                                            args_span,
                                        );
                                        return None;
                                    }
                                    let inner_ty = type_args.into_iter().next().unwrap();
                                    // Now parse the call args (value)
                                    let args = self.parse_call_args()?;
                                    let call_span = expr.span().to(self.prev_span());
                                    if args.len() != 1 {
                                        self.error(
                                            format!("`{}<T>(..)` expects exactly one argument, found {}", kind, args.len()),
                                            call_span,
                                        );
                                        return None;
                                    }
                                    let value = args.into_iter().next().unwrap();
                                    let span = expr.span().to(self.prev_span());
                                    if is_wrapping {
                                        return Some(Expr::WrappingNew { inner_ty, value: Box::new(value), span });
                                    }
                                    return Some(Expr::GenRefCreate {
                                        inner_ty,
                                        value: Box::new(value),
                                        is_handle,
                                        span,
                                    });
                                }
                                _ => {
                                    self.pos = checkpoint;
                                    self.errors.truncate(err_checkpoint);
                                }
                            }
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
                // `expr?` - Option/Result propagation sugar, same postfix
                // precedence tier as `.field`/call/index above (binds
                // tighter than any binary operator).
                TokenKind::Question => {
                    self.advance();
                    let span = expr.span().to(self.prev_span());
                    expr = Expr::Try { inner: Box::new(expr), span };
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

    /// Speculatively parse a turbofish the way [`parse_type_args`] does, but
    /// only commit to it when it's immediately followed by `(` or `::` -- the
    /// only two continuations a real turbofish can have (`Box<i32>(...)`,
    /// `Option<i32>::Some(...)`). Star doesn't restrict identifier casing, so
    /// a capitalized identifier followed by `<` is just as often a real
    /// comparison (`if Foo < Bar:`) as a generic construction; backtracking
    /// on failure (restoring both the cursor and any diagnostics raised
    /// during the failed attempt) lets that `<` fall through to
    /// `peek_binop`'s ordinary comparison handling instead of cascading into
    /// unrelated parse errors.
    fn try_parse_type_args(&mut self) -> Vec<Type> {
        let checkpoint = self.pos;
        let err_checkpoint = self.errors.len();
        match self.parse_type_args() {
            Some(args) if self.at(&TokenKind::LParen) || self.at(&TokenKind::ColonColon) => args,
            _ => {
                self.pos = checkpoint;
                self.errors.truncate(err_checkpoint);
                Vec::new()
            }
        }
    }

    /// Speculatively parse `Ring<T, N>()`'s `<T, N>` turbofish (mirroring
    /// `Type::Array`'s `[T; N]` handling in `Parser::parse_type_inner`) since
    /// `N` is a bare integer literal, not a `Type` -- `parse_type_args`'s
    /// ordinary comma-separated-`Type`-list loop has no way to parse that.
    /// Assumes the cursor is at `<`, immediately after having consumed the
    /// `Ring` identifier.
    ///
    /// `Ring` isn't a reserved keyword, so `Ring < 3` is just as legitimately
    /// a comparison against a plain value named `Ring` as it is a
    /// construction -- like `try_parse_type_args`, this probes the `<T, N>`
    /// shape (`probe_ring_shape`) and only commits once it's confirmed by an
    /// immediately-following `(` (the only real continuation a `Ring<T,
    /// N>()` construction can have). Returns `Ok(None)` on a shape mismatch,
    /// having already restored the cursor and discarded whatever diagnostics
    /// the probe raised, so the caller can fall through to ordinary
    /// identifier/comparison handling instead of cascading into unrelated
    /// parse errors -- exactly the failure mode `try_parse_type_args`'s own
    /// doc comment describes. Once shape-confirmed, this is unconditionally
    /// committed: `Err(())` means a real syntax error (a non-positive count,
    /// a malformed argument list) that the caller must propagate rather than
    /// fall through on, mirroring `Option<Expr>`'s usual "real failure"
    /// convention elsewhere in this parser.
    fn parse_ring_new(&mut self, start: Span) -> Result<Option<Expr>, ()> {
        let checkpoint = self.pos;
        let err_checkpoint = self.errors.len();

        let shape = self.probe_ring_shape();
        if shape.is_none() || !self.at(&TokenKind::LParen) {
            self.pos = checkpoint;
            self.errors.truncate(err_checkpoint);
            return Ok(None);
        }
        let (elem, count, count_span) = shape.unwrap();

        if count <= 0 {
            self.error("ring capacity must be a positive integer", count_span);
            return Err(());
        }
        let Some(args) = self.parse_call_args() else { return Err(()) };
        if !args.is_empty() {
            self.error("`Ring<T, N>()` takes no arguments -- it always starts empty", start.to(self.prev_span()));
        }
        let full = start.to(self.prev_span());
        Ok(Some(Expr::RingNew { elem_ty: elem, count: count as u64, span: full }))
    }

    /// The shape-only half of [`parse_ring_new`]'s speculation: `< Type ,
    /// IntLiteral >` with no validation of the count's sign (that's left to
    /// the caller, once it's known this really is a `Ring<T, N>` construction
    /// and not a false-positive backtrack candidate) and no argument-list
    /// parsing. Returns `None` on any shape mismatch; the caller is
    /// responsible for restoring the cursor/diagnostics in that case.
    fn probe_ring_shape(&mut self) -> Option<(Type, i64, Span)> {
        self.advance(); // consume '<'
        let elem = self.parse_type()?;
        if !self.eat(&TokenKind::Comma) {
            return None;
        }
        let count_span = self.peek_span();
        let TokenKind::Int(count) = self.peek_kind() else {
            return None;
        };
        self.advance();
        if !self.eat(&TokenKind::Gt) {
            return None;
        }
        Some((elem, count, count_span))
    }

    /// Speculatively parse `Fixed<Bits, Frac>(value)`'s `<Bits, Frac>`
    /// turbofish, mirroring [`parse_ring_new`]/`probe_ring_shape` exactly
    /// (two bare integer literals instead of one `Type`, so this can't share
    /// `parse_type_args` either). Assumes the cursor is at `<`, immediately
    /// after having consumed the `Fixed` identifier. Returns `Ok(None)` on a
    /// shape mismatch (having already restored the cursor/diagnostics), so
    /// the caller can fall through to ordinary identifier/comparison
    /// handling; `Err(())` means a real, committed syntax error.
    fn parse_fixed_new(&mut self, start: Span) -> Result<Option<Expr>, ()> {
        let checkpoint = self.pos;
        let err_checkpoint = self.errors.len();

        let shape = self.probe_fixed_shape();
        if shape.is_none() || !self.at(&TokenKind::LParen) {
            self.pos = checkpoint;
            self.errors.truncate(err_checkpoint);
            return Ok(None);
        }
        let (bits, bits_span, frac, frac_span) = shape.unwrap();

        if bits <= 0 {
            self.error("`Fixed<Bits, Frac>`'s bit width must be a positive integer", bits_span);
            return Err(());
        }
        if frac < 0 {
            self.error("`Fixed<Bits, Frac>`'s fractional-bit count cannot be negative", frac_span);
            return Err(());
        }
        let args = self.parse_call_args().ok_or(())?;
        let call_span = start.to(self.prev_span());
        if args.len() != 1 {
            self.error(format!("`Fixed<Bits, Frac>(..)` expects exactly one argument, found {}", args.len()), call_span);
            return Err(());
        }
        let value = args.into_iter().next().unwrap();
        let full = start.to(self.prev_span());
        Ok(Some(Expr::FixedNew { bits: bits as u32, frac: frac as u32, value: Box::new(value), span: full }))
    }

    /// The shape-only half of [`parse_fixed_new`]'s speculation: `< IntLiteral
    /// , IntLiteral >`, with no validation of either literal's sign (left to
    /// the caller) and no argument-list parsing. Returns `None` on any shape
    /// mismatch; the caller restores the cursor/diagnostics in that case.
    fn probe_fixed_shape(&mut self) -> Option<(i64, Span, i64, Span)> {
        self.advance(); // consume '<'
        let bits_span = self.peek_span();
        let TokenKind::Int(bits) = self.peek_kind() else {
            return None;
        };
        self.advance();
        if !self.eat(&TokenKind::Comma) {
            return None;
        }
        let frac_span = self.peek_span();
        let TokenKind::Int(frac) = self.peek_kind() else {
            return None;
        };
        self.advance();
        if !self.eat(&TokenKind::Gt) {
            return None;
        }
        Some((bits, bits_span, frac, frac_span))
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
            TokenKind::Char(c) => {
                self.advance();
                Some(Expr::Char(c, span))
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
                let mut elems = Vec::new();
                let mut trailing_comma = false;
                while !self.at(&TokenKind::RParen) && !self.at(&TokenKind::Eof) {
                    elems.push(self.parse_expr()?);
                    trailing_comma = self.eat(&TokenKind::Comma);
                    if !trailing_comma {
                        break;
                    }
                }
                self.expect(&TokenKind::RParen)?;
                let full = span.to(self.prev_span());
                if elems.is_empty() {
                    self.error("expected an expression inside `(...)`", full);
                    return None;
                }
                // A single parenthesized expression with no trailing comma
                // is just grouping, matching pre-existing behavior; a
                // trailing comma after one element (`(e,)`), or two or more
                // comma-separated elements, makes a tuple literal.
                if elems.len() == 1 && !trailing_comma {
                    return Some(elems.into_iter().next().unwrap());
                }
                Some(Expr::TupleLit(elems, full))
            }
            TokenKind::FStr(parts) => {
                self.advance();
                let lowered = self.lower_fstring(parts)?;
                Some(Expr::FStr(lowered, span))
            }
            TokenKind::LBracket => {
                self.advance();
                // An empty `[]` stays a (checker-rejected, with a helpful
                // "use `List<T>()`" diagnostic) empty `ListLit` -- there's no
                // first element to decide the repeat-vs-list-literal question
                // from, and no array-literal spelling has an empty form
                // either (an array's size is always in its type/annotation).
                if self.at(&TokenKind::RBracket) {
                    self.advance();
                    let full = span.to(self.prev_span());
                    return Some(Expr::ListLit(Vec::new(), full));
                }
                let first = self.parse_expr()?;
                // `[value; N]`: a fixed-size array repeat literal, unambiguous
                // against `ListLit` below since a list literal never contains
                // a `;` (see `Expr::ArrayRepeat`'s doc comment for why this is
                // deliberately the *only* array literal form).
                if self.eat(&TokenKind::Semi) {
                    let count_span = self.peek_span();
                    let TokenKind::Int(count) = self.peek_kind() else {
                        self.error("expected an integer literal array size after `;`", count_span);
                        return None;
                    };
                    self.advance();
                    if count < 0 {
                        self.error("array size cannot be negative", count_span);
                        return None;
                    }
                    self.expect(&TokenKind::RBracket)?;
                    let full = span.to(self.prev_span());
                    return Some(Expr::ArrayRepeat { value: Box::new(first), count: count as u64, span: full });
                }
                let mut elems = vec![first];
                while self.eat(&TokenKind::Comma) {
                    if self.at(&TokenKind::RBracket) {
                        break;
                    }
                    elems.push(self.parse_expr()?);
                }
                self.expect(&TokenKind::RBracket)?;
                let full = span.to(self.prev_span());
                Some(Expr::ListLit(elems, full))
            }
            TokenKind::Ident(name) => {
                self.advance();
                // `Ring<T, N>()` -- see `Expr::RingNew`'s doc comment for why
                // this can't go through the ordinary `try_parse_type_args`
                // turbofish machinery below (its second argument is a bare
                // integer literal, not a `Type`). `parse_ring_new` itself
                // backtracks on a shape mismatch (`Ok(None)`) rather than
                // erroring, since `Ring` isn't reserved and `Ring < 3` may
                // just be a comparison against a plain value named `Ring` --
                // only `return` out of `parse_primary` entirely once it's
                // either a confirmed construction (`Ok(Some(_))`) or a real,
                // committed syntax error (`Err(())`); on `Ok(None)` fall
                // through to the ordinary identifier handling below so the
                // `<` reaches `peek_binop` as a comparison operator.
                if name == "Ring" && self.at(&TokenKind::Lt) {
                    match self.parse_ring_new(span) {
                        Ok(Some(expr)) => return Some(expr),
                        Err(()) => return None,
                        Ok(None) => {}
                    }
                }
                // Struct literal when an identifier is immediately called and the
                // name is capitalized (type-like), e.g. `Vec3(0, 0, 0)`.
                // Explicit generic type arguments: `Box<i32>(...)` or
                // `Option<i32>::Variant(...)`. Only attempted for
                // capitalized (type-like) names immediately followed by `<`,
                // mirroring the `GenRef<T>`/`Handle<T>` special case below --
                // `<` is otherwise never treated as a binary operator by
                // `peek_binop`, so this can't misfire on a real comparison.
                // `GenRef`/`Handle`/`Wrapping`/`Fixed` themselves are
                // excluded: their own `<...>(value)` syntax is handled
                // entirely by `parse_postfix` below, and must see the `<`
                // untouched.
                let type_args = if name != "GenRef" && name != "Handle" && name != "Wrapping" && name != "Fixed"
                    && starts_uppercase(&name) && self.at(&TokenKind::Lt)
                {
                    self.try_parse_type_args()
                } else {
                    Vec::new()
                };
                if self.at(&TokenKind::LParen) && starts_uppercase(&name) {
                    // `GenRef`/`Handle`/`Wrapping`/`Fixed` always require an
                    // explicit type argument; without one this would
                    // otherwise fall through to the generic `StructLit` case
                    // below and construct a nonexistent struct, only failing
                    // later with a confusing, unrelated error at its first use.
                    if name == "GenRef" {
                        self.error("`GenRef` requires an explicit type argument: `GenRef<T>(value)`", span);
                        return None;
                    }
                    if name == "Handle" {
                        self.error("`Handle` requires an explicit type argument: `Handle<T>(value)`", span);
                        return None;
                    }
                    if name == "Wrapping" {
                        self.error("`Wrapping` requires an explicit type argument: `Wrapping<T>(value)`", span);
                        return None;
                    }
                    if name == "Fixed" {
                        self.error("`Fixed` requires explicit type arguments: `Fixed<Bits, Frac>(value)`", span);
                        return None;
                    }
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
                // Unreachable with an empty `type_args`: `try_parse_type_args`
                // only returns a non-empty `Vec` when it already confirmed
                // the turbofish is immediately followed by `(` or `::`, both
                // of which are handled above/below before control ever
                // reaches here.
                debug_assert!(type_args.is_empty());
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
                FStrPart::Expr(src, offset) => {
                    // `Lexer::new_with_offset`, not `Lexer::new`: this `src`
                    // is just the hole's extracted substring, so a plain
                    // `Lexer::new` would number its tokens' spans from byte 0
                    // as if the hole were its own standalone file --
                    // `offset` (the hole's real starting byte in the outer
                    // file, threaded through from `Lexer::scan_fstring`)
                    // corrects every span this produces back to the outer
                    // file's coordinates, so a checker/codegen error inside
                    // an interpolation (`f"{a == b}"` where `==` isn't
                    // defined for `a`/`b`'s type) points at the real `{...}`
                    // location instead of wherever that small, hole-relative
                    // offset happened to land when misread against the outer
                    // file's much larger source text (previously, always
                    // somewhere near the very start of the file).
                    let tokens = match Lexer::new_with_offset(&src, offset).tokenize() {
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
                    // Carry the outer parser's nesting counters into the
                    // fresh sub-parser -- otherwise a chain of nested
                    // f-string interpolations (`f"{f"{f"{...}"}"}"`) resets
                    // `expr_depth`/`block_depth`/`match_depth` to 0 at every
                    // level, so `MAX_EXPR_DEPTH`/`MAX_BLOCK_DEPTH`/
                    // `MAX_MATCH_DEPTH` never actually accumulate across
                    // levels and only the real (unbounded) Rust call stack
                    // does, defeating the guard entirely. `match_depth` was
                    // previously missing here despite the same reasoning
                    // applying to it as to the other two -- a `match` nested
                    // inside an f-string hole, itself containing a further
                    // f-string hole with its own nested `match`, repeated
                    // enough times, could reach the real stack limit before
                    // `MAX_MATCH_DEPTH` ever tripped.
                    sub.expr_depth = self.expr_depth;
                    sub.block_depth = self.block_depth;
                    sub.match_depth = self.match_depth;
                    let parsed = sub.parse_expr();
                    // Merge the sub-parser's errors *before* handling a
                    // `None` result -- `parse_expr` can fail (bad syntax,
                    // depth-guard trip, ...) while still having pushed a
                    // diagnostic into `sub.errors`; bailing out via `?`
                    // ahead of this merge would silently drop that
                    // diagnostic and make the whole enclosing statement
                    // vanish from the AST with no error reported at all.
                    self.errors.append(&mut sub.errors);
                    let expr = parsed?;
                    out.push(FStrExpr::Expr(Box::new(expr)));
                }
            }
        }
        Some(out)
    }

    /// A conservative bound on nested `match` parsing -- see
    /// `Parser::match_depth`'s doc comment for why this needs its own
    /// (lower) counter rather than reusing `MAX_EXPR_DEPTH`/`MAX_BLOCK_DEPTH`.
    pub(super) const MAX_MATCH_DEPTH: u32 = 30;

    pub(super) fn parse_match(&mut self) -> Option<Expr> {
        if self.match_depth >= Self::MAX_MATCH_DEPTH {
            let span = self.peek_span();
            self.error("`match` nested too deeply (over 30 levels) -- likely a runaway generated expression", span);
            return None;
        }
        self.match_depth += 1;
        let result = self.parse_match_inner();
        self.match_depth -= 1;
        result
    }

    fn parse_match_inner(&mut self) -> Option<Expr> {
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
        self.block_just_closed = true;
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
                // The lexer stores a literal's raw magnitude verbatim,
                // deferring range validation to context (see
                // `Lexer::scan_number`'s doc comment) -- whether `v` fits
                // whatever scrutinee type this pattern is ultimately matched
                // against is checked once that's known, by the `Pattern::Int`
                // arm of `Checker::check_match_arm` (mirroring `Expr::Int`'s
                // own default-width range check).
                Some(Pattern::Int(v))
            }
            // A bare negative-literal pattern (`-1 -> ...`), mirroring
            // `parse_unary_inner`'s `Minus` handling for ordinary
            // expressions -- without this, only the `== -1 -> ...` spelling
            // (routed through `compare_pattern`/`parse_expr`, which does
            // handle unary minus) could express a negative literal pattern.
            TokenKind::Minus => {
                self.advance();
                match self.peek_kind() {
                    TokenKind::Int(v) => {
                        self.advance();
                        // `v` is always a non-negative magnitude (see the
                        // `TokenKind::Int` arm's doc comment above), so
                        // negating it is always safely representable in the
                        // `i64` this token/pattern is stored in -- no
                        // special-casing needed (contrast `Expr::Unary`'s
                        // `i32::MIN` sentinel, which exists because `Ty::Int`
                        // arithmetic is `i32`-width; a bare `Pattern::Int`
                        // has no such width of its own until it meets its
                        // scrutinee).
                        Some(Pattern::Int(-v))
                    }
                    other => {
                        let span = self.peek_span();
                        self.error(format!("unexpected token in pattern after unary `-`: {:?}", other), span);
                        None
                    }
                }
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

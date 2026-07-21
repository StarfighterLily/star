//! Recursive-descent parser for Star.
//!
//! Consumes the structural token stream produced by [`crate::lexer`] and builds
//! the [`crate::ast`] tree. Indentation is already encoded as `Indent`/`Dedent`/
//! `Newline` tokens, so blocks are parsed by matching those markers rather than
//! tracking columns. Expression parsing uses precedence climbing (a Pratt-style
//! loop) for binary operators.
//!
//! The `Parser` struct, its token-cursor primitives, and top-level module
//! parsing live here; item/statement/expression grammar productions each
//! have their own `impl Parser` block in a sibling submodule: `items`
//! (struct/trait/impl/fn/arena/sequence declarations), `stmt` (blocks and
//! statements), and `expr` (precedence-climbing expression parsing).

mod expr;
mod items;
mod stmt;

use std::collections::HashSet;

use crate::ast::*;
use crate::diagnostics::{Diagnostic, Span};
use crate::lexer::{Lexer, Token, TokenKind};

/// Parser state over a token slice.
pub struct Parser {
    tokens: Vec<Token>,
    pos: usize,
    errors: Vec<Diagnostic>,
    /// Aliases introduced so far by `import "path" as alias` (imports must
    /// textually precede their use). Consulted when parsing an identifier
    /// followed by `::` to decide whether it's a module-qualified path
    /// (rewritten to the mangled name `crate::modules` will have produced)
    /// or a same-file enum-variant/struct pattern.
    import_aliases: HashSet<String>,
    /// Set immediately after a block-closing `Dedent` is consumed (by
    /// `parse_block`/`parse_match`) and cleared at the top of every
    /// `advance()`, so it's `true` only when nothing has been consumed since.
    /// A value expression that ends in an indented block (a block-bodied
    /// lambda, an `if`-expression, a `match`-expression) already consumes,
    /// via that nested block, the very `Newline`/`Dedent` that would
    /// otherwise terminate the *enclosing* statement's own line -- so
    /// `expect_line_end()` treats this flag as an already-satisfied
    /// terminator instead of erroring on whatever token starts the next
    /// statement.
    block_just_closed: bool,
    /// Nesting depth of `Parser::parse_unary` calls -- every layer of
    /// parenthesized grouping, unary chaining (`-`/`not`), or a nested
    /// `[...]`/call argument re-entering expression parsing goes through
    /// this one shared entry point, so bounding it here bounds all of them.
    /// Previously unguarded: a few hundred levels of nested parens or a long
    /// unary-minus chain overflowed the real Rust call stack with a bare
    /// process abort ("thread 'main' has overflowed its stack") and no
    /// diagnostic at all, the parser-side counterpart of the same class of
    /// bug `Checker::mono_depth` already guards against on the generic-
    /// monomorphization side.
    expr_depth: u32,
    /// Nesting depth of `Parser::parse_block` calls -- every layer of
    /// `if`/`while`/`for`/`match`-arm/`frame`/`par`/block-bodied-lambda body
    /// re-enters `parse_block` (directly or via `parse_stmt`), so bounding it
    /// here bounds all of them the same way `expr_depth` bounds expression
    /// nesting. Previously unguarded: a source with a few hundred levels of
    /// strictly increasing indentation (e.g. nested `if true:` blocks)
    /// overflowed the real Rust call stack with a bare process abort and no
    /// diagnostic, the block-nesting counterpart of the same class of bug
    /// `expr_depth` guards against.
    block_depth: u32,
    /// Nesting depth of `Parser::parse_match` calls -- a `match` reachable
    /// either as a bare statement (`parse_match_stmt`, uncounted by
    /// `expr_depth`/`block_depth` at the `parse_match` call site itself) or
    /// nested inline in another arm's body (`_ -> match ...`, going through
    /// `expr_depth` via `parse_unary`) recurses back into `parse_match`
    /// either way, so a dedicated counter here bounds both forms uniformly.
    /// Needed as its own counter, calibrated lower than `MAX_EXPR_DEPTH`,
    /// because each level of `match` nesting costs far more real stack per
    /// level than a plain paren/unary chain does (`parse_match` ->
    /// `parse_match_arm` -> `parse_pattern`/`parse_block`/`parse_expr`, each
    /// with their own locals) -- previously unguarded, 55-60 levels of
    /// nested `match` overflowed the real Rust call stack with a bare
    /// process abort ("thread 'main' has overflowed its stack") and no
    /// diagnostic, well under `MAX_EXPR_DEPTH`'s 80-level threshold, the
    /// same class of "guard calibrated for a lighter call chain doesn't
    /// trigger before a heavier one crashes" bug fixed elsewhere for
    /// `MAX_BLOCK_DEPTH`.
    match_depth: u32,
    /// The `crate::diagnostics::Span::file_id` this parser's tokens carry --
    /// derived from the first token at construction (every token in one
    /// `Parser`'s stream always comes from one `Lexer` run over one file, so
    /// they all agree). Threaded through to `Lexer::new_with_offset` when
    /// re-lexing an f-string interpolation hole (`lower_fstring`), so a
    /// hole's re-lexed tokens keep the *enclosing* file's id instead of
    /// silently resetting to `0` (the root file) regardless of which file
    /// the f-string itself was written in.
    file_id: u32,
}

impl Parser {
    pub fn new(tokens: Vec<Token>) -> Self {
        let file_id = tokens.first().map(|t| t.span.file_id).unwrap_or(0);
        Self {
            tokens,
            pos: 0,
            errors: Vec::new(),
            import_aliases: HashSet::new(),
            block_just_closed: false,
            expr_depth: 0,
            block_depth: 0,
            match_depth: 0,
            file_id,
        }
    }

    /// Parse a complete module from source, running the lexer first.
    pub fn parse_source(src: &str) -> Result<Module, Vec<Diagnostic>> {
        let tokens = Lexer::new(src).tokenize()?;
        Parser::new(tokens).parse_module()
    }

    /// Like `parse_source`, but for a non-root file (an `import`ed one) --
    /// every span this produces carries `file_id` instead of `0`. See
    /// `crate::diagnostics::Span::file_id`'s doc comment.
    pub fn parse_source_with_file(src: &str, file_id: u32) -> Result<Module, Vec<Diagnostic>> {
        let tokens = Lexer::new_with_file(src, file_id).tokenize()?;
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

    /// Same guard, same shared counter, as `Parser::parse_unary`'s
    /// `expr_depth`/`MAX_EXPR_DEPTH` (see that field's doc comment) --
    /// `Type::Fn`'s params/return and `Type::Generic`'s type arguments both
    /// recurse back into `parse_type` with no base case of their own, so a
    /// deeply nested type annotation (`List<List<List<...>>>`) previously
    /// overflowed the real Rust call stack with a bare process abort and no
    /// diagnostic, exactly like the expression-nesting case this same
    /// counter already guards against.
    fn parse_type(&mut self) -> Option<Type> {
        if self.expr_depth >= Self::MAX_EXPR_DEPTH {
            let span = self.peek_span();
            self.error(
                "type nested too deeply (over 80 levels of generic arguments/function types) -- likely a runaway generated type",
                span,
            );
            return None;
        }
        self.expr_depth += 1;
        let result = self.parse_type_inner();
        self.expr_depth -= 1;
        result
    }

    fn parse_type_inner(&mut self) -> Option<Type> {
        // A fixed-size array type `[T; N]` -- `N` is a plain non-negative
        // integer literal (no const-expression evaluator in this compiler),
        // matching `Expr::ArrayRepeat`'s own restriction at the value level.
        if self.at(&TokenKind::LBracket) {
            self.advance();
            let elem = self.parse_type()?;
            self.expect(&TokenKind::Semi)?;
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
            return Some(Type::Array(Box::new(elem), count as u64));
        }
        // A tuple type `(T, U, ...)`, or just a parenthesized type (no
        // comma) unwrapped back to that type directly -- types have no
        // infix operators needing grouping, so a lone `(T)` is never itself
        // meaningful; only a comma makes it a genuine tuple.
        if self.at(&TokenKind::LParen) {
            self.advance();
            let mut elems = Vec::new();
            let mut trailing_comma = false;
            while !self.at(&TokenKind::RParen) && !self.at(&TokenKind::Eof) {
                elems.push(self.parse_type()?);
                trailing_comma = self.eat(&TokenKind::Comma);
                if !trailing_comma {
                    break;
                }
            }
            self.expect(&TokenKind::RParen)?;
            if elems.len() == 1 && !trailing_comma {
                return Some(elems.into_iter().next().unwrap());
            }
            if elems.is_empty() {
                self.error("expected a type inside `(...)`", self.prev_span());
                return None;
            }
            return Some(Type::Tuple(elems));
        }
        // A closure/function type: `Fn(T1, T2, ...) -> Ret`. `Fn` is a plain
        // capitalized identifier here (distinct from the `fn` keyword used
        // for declarations/lambda literals), so it's recognized by name
        // rather than a dedicated token.
        if matches!(self.peek_kind(), TokenKind::Ident(ref n) if n == "Fn") {
            self.advance();
            self.expect(&TokenKind::LParen)?;
            let mut params = Vec::new();
            while !self.at(&TokenKind::RParen) && !self.at(&TokenKind::Eof) {
                params.push(self.parse_type()?);
                if !self.eat(&TokenKind::Comma) {
                    break;
                }
            }
            self.expect(&TokenKind::RParen)?;
            self.expect(&TokenKind::Arrow)?;
            let ret = self.parse_type()?;
            return Some(Type::Fn(params, Box::new(ret)));
        }
        let mut name = self.expect_ident()?;
        // A type from an imported module, e.g. `mymod::Point`, of arbitrary
        // depth (`a::b::Point`, reaching through a re-exported nested
        // import); reproduce the same mangled name `crate::modules::resolve`
        // gives that struct/enum, one level per `::` -- see the qualified
        // expression path's comment in `parser::expr::parse_primary` for why
        // chaining `mangle_name` calls here needs no knowledge of what an
        // intermediate segment actually names.
        if self.import_aliases.contains(&name) && self.at(&TokenKind::ColonColon) {
            self.advance();
            let mut item = self.expect_ident()?;
            name = crate::modules::mangle_name(&name, &item);
            while self.eat(&TokenKind::ColonColon) {
                item = self.expect_ident()?;
                name = crate::modules::mangle_name(&name, &item);
            }
        }
        // `Ring<T, N>` -- `N` is a plain non-negative integer literal (no
        // const-expression evaluator in this compiler), matching
        // `Type::Array`'s `[T; N]` restriction just above; special-cased by
        // name (rather than falling into the ordinary `Type::Generic`
        // comma-loop below, which only ever parses `Type`s) since there's no
        // general const-generic parameter machinery here.
        if name == "Ring" && self.eat(&TokenKind::Lt) {
            let elem = self.parse_type()?;
            self.expect(&TokenKind::Comma)?;
            let count_span = self.peek_span();
            let TokenKind::Int(count) = self.peek_kind() else {
                self.error("expected an integer literal capacity after `,` in `Ring<T, N>`", count_span);
                return None;
            };
            self.advance();
            if count <= 0 {
                self.error("ring capacity must be a positive integer", count_span);
                return None;
            }
            self.expect(&TokenKind::Gt)?;
            return Some(Type::Ring(Box::new(elem), count as u64));
        }
        // `Fixed<Bits, Frac>` -- both `Bits` and `Frac` are plain
        // non-negative integer literals (no const-expression evaluator in
        // this compiler), same reasoning/shape as `Ring<T, N>` just above;
        // full legality (`Bits` a supported width, `Frac < Bits`) is left to
        // `Checker::resolve_type` for a clearer diagnostic, mirroring how
        // `Ring<T, N>`'s own positive-count check is split between here (bare
        // parse-time sanity) and the checker.
        if name == "Fixed" && self.eat(&TokenKind::Lt) {
            let bits_span = self.peek_span();
            let TokenKind::Int(bits) = self.peek_kind() else {
                self.error("expected an integer literal bit width after `<` in `Fixed<Bits, Frac>`", bits_span);
                return None;
            };
            self.advance();
            if bits <= 0 {
                self.error("`Fixed<Bits, Frac>`'s bit width must be a positive integer", bits_span);
                return None;
            }
            self.expect(&TokenKind::Comma)?;
            let frac_span = self.peek_span();
            let TokenKind::Int(frac) = self.peek_kind() else {
                self.error("expected an integer literal fractional-bit count after `,` in `Fixed<Bits, Frac>`", frac_span);
                return None;
            };
            self.advance();
            if frac < 0 {
                self.error("`Fixed<Bits, Frac>`'s fractional-bit count cannot be negative", frac_span);
                return None;
            }
            self.expect(&TokenKind::Gt)?;
            return Some(Type::Fixed(bits as u32, frac as u32));
        }
        // `BitField<N>` -- `N` is a plain non-negative integer literal (no
        // const-expression evaluator in this compiler), same reasoning/shape
        // as `Fixed<Bits, Frac>` just above but with only one literal; full
        // legality (`N` a supported width) is left to `Checker::resolve_type`
        // for a clearer diagnostic, mirroring `Fixed<Bits, Frac>`'s own split.
        if name == "BitField" && self.eat(&TokenKind::Lt) {
            let bits_span = self.peek_span();
            let TokenKind::Int(bits) = self.peek_kind() else {
                self.error("expected an integer literal bit width after `<` in `BitField<N>`", bits_span);
                return None;
            };
            self.advance();
            if bits <= 0 {
                self.error("`BitField<N>`'s bit width must be a positive integer", bits_span);
                return None;
            }
            self.expect(&TokenKind::Gt)?;
            return Some(Type::BitField(bits as u32));
        }
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
        self.block_just_closed = false;
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

    /// Consume a newline or accept EOF/Dedent as an implicit line end. Also
    /// accepts `block_just_closed`: a value expression that ended in an
    /// indented block already consumed its own terminating Dedent via that
    /// nested block, so there's nothing left here to consume.
    fn expect_line_end(&mut self) -> Option<()> {
        if self.block_just_closed {
            Some(())
        } else if self.at(&TokenKind::Newline) {
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
        // The statement that just failed may have owned an indented body it
        // never got to claim -- e.g. `if x` missing its `:` bails out of
        // `parse_if_stmt` before `parse_block` ever runs for the body, but
        // the lexer already emitted a real Indent/Dedent pair for that
        // body's physical indentation (an Indent only ever follows a `:`-
        // terminated line, so one appearing right here can only be fallout
        // from the line just recovered past, never the start of an
        // unrelated sibling statement). Left alone, the first Dedent this
        // function's caller sees would be that orphaned body's closer, not
        // the enclosing block's own -- indistinguishable from a real
        // terminator, so the enclosing block would end early and strand
        // every following sibling statement in cascading "unexpected
        // token"/"expected a top-level item" errors. Swallow the whole
        // orphaned span (nesting-aware, since it can itself contain further
        // nested blocks) so recovery lands right after it, at the next real
        // sibling statement.
        if self.at(&TokenKind::Indent) {
            let mut depth = 0i32;
            loop {
                match self.peek_kind() {
                    TokenKind::Indent => {
                        depth += 1;
                        self.advance();
                    }
                    TokenKind::Dedent => {
                        depth -= 1;
                        self.advance();
                        if depth == 0 {
                            break;
                        }
                    }
                    TokenKind::Eof => break,
                    _ => {
                        self.advance();
                    }
                }
            }
        }
    }

    fn error(&mut self, msg: impl Into<String>, span: Span) {
        self.errors.push(Diagnostic::error(msg, span));
    }
}

fn starts_uppercase(name: &str) -> bool {
    name.chars().next().map(|c| c.is_ascii_uppercase()).unwrap_or(false)
}

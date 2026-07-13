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
}

impl Parser {
    pub fn new(tokens: Vec<Token>) -> Self {
        Self {
            tokens,
            pos: 0,
            errors: Vec::new(),
            import_aliases: HashSet::new(),
            block_just_closed: false,
            expr_depth: 0,
            block_depth: 0,
            match_depth: 0,
        }
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
        // A type from an imported module, e.g. `mymod::Point`; reproduce the
        // same mangled name `crate::modules::resolve` gave that struct/enum.
        if self.import_aliases.contains(&name) && self.at(&TokenKind::ColonColon) {
            self.advance();
            let item = self.expect_ident()?;
            name = crate::modules::mangle_name(&name, &item);
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
    }

    fn error(&mut self, msg: impl Into<String>, span: Span) {
        self.errors.push(Diagnostic::error(msg, span));
    }
}

fn starts_uppercase(name: &str) -> bool {
    name.chars().next().map(|c| c.is_ascii_uppercase()).unwrap_or(false)
}

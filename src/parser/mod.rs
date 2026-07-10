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
}

impl Parser {
    pub fn new(tokens: Vec<Token>) -> Self {
        Self { tokens, pos: 0, errors: Vec::new(), import_aliases: HashSet::new() }
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

    fn parse_type(&mut self) -> Option<Type> {
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

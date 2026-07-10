//! Top-level item grammar: `struct`, `trait`, `impl`, `fn`, `arena`, `sequence`.

use crate::ast::*;
use crate::lexer::TokenKind;

use super::Parser;

impl Parser {
    pub(super) fn parse_item(&mut self) -> Option<Item> {
        match self.peek_kind() {
            TokenKind::Struct => self.parse_struct().map(Item::Struct),
            TokenKind::Trait => self.parse_trait().map(Item::Trait),
            TokenKind::Impl => self.parse_impl().map(Item::Impl),
            TokenKind::Fn => self.parse_fn().map(Item::Fn),
            TokenKind::Arena => self.parse_arena().map(Item::Arena),
            TokenKind::Sequence => self.parse_sequence().map(Item::Sequence),
            TokenKind::Enum => self.parse_enum().map(Item::Enum),
            TokenKind::Import => self.parse_import().map(Item::Import),
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

    /// `import "path.star" as alias` - must appear before any use of
    /// `alias::...` elsewhere in the file (the parser learns the alias here
    /// and consults it later while parsing `::`-qualified paths).
    fn parse_import(&mut self) -> Option<ImportDecl> {
        let start = self.peek_span();
        self.expect(&TokenKind::Import)?;
        let path = match self.peek_kind() {
            TokenKind::Str(s) => {
                self.advance();
                s
            }
            other => {
                let span = self.peek_span();
                self.error(format!("expected a string literal path, found {}", other.describe()), span);
                return None;
            }
        };
        self.expect(&TokenKind::As)?;
        let alias = self.expect_ident()?;
        self.expect_line_end()?;
        let span = start.to(self.prev_span());
        self.import_aliases.insert(alias.clone());
        Some(ImportDecl { alias, path, span })
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

    fn parse_enum(&mut self) -> Option<EnumDef> {
        let start = self.peek_span();
        self.expect(&TokenKind::Enum)?;
        let name = self.expect_ident()?;
        let type_params = self.parse_opt_type_params()?;
        self.expect(&TokenKind::Colon)?;
        self.expect(&TokenKind::Newline)?;
        self.expect(&TokenKind::Indent)?;

        let mut variants = Vec::new();
        while !self.at(&TokenKind::Dedent) && !self.at(&TokenKind::Eof) {
            if let Some(variant) = self.parse_enum_variant() {
                variants.push(variant);
            } else {
                self.recover_to_newline();
            }
            self.skip_newlines();
        }
        self.expect(&TokenKind::Dedent)?;
        let span = start.to(self.prev_span());
        Some(EnumDef { name, type_params, variants, span })
    }

    /// Parse an optional `<T, U, ...>` type-parameter list following a
    /// `struct`/`enum`/`fn` name, returning an empty list when absent.
    fn parse_opt_type_params(&mut self) -> Option<Vec<String>> {
        if !self.eat(&TokenKind::Lt) {
            return Some(Vec::new());
        }
        let mut params = Vec::new();
        while !self.at(&TokenKind::Gt) && !self.at(&TokenKind::Eof) {
            params.push(self.expect_ident()?);
            if !self.eat(&TokenKind::Comma) {
                break;
            }
        }
        self.expect(&TokenKind::Gt)?;
        Some(params)
    }

    /// Parse a single enum variant line: a bare `Name`, or a payload variant
    /// `Name(field: Type, ...)`.
    fn parse_enum_variant(&mut self) -> Option<EnumVariantDef> {
        let start = self.peek_span();
        let name = self.expect_ident()?;
        let mut fields = Vec::new();
        if self.eat(&TokenKind::LParen) {
            while !self.at(&TokenKind::RParen) && !self.at(&TokenKind::Eof) {
                let fname = self.expect_ident()?;
                self.expect(&TokenKind::Colon)?;
                let fty = self.parse_type()?;
                fields.push(EnumFieldDef { name: fname, ty: fty });
                if !self.eat(&TokenKind::Comma) {
                    break;
                }
            }
            self.expect(&TokenKind::RParen)?;
        }
        self.expect_line_end();
        let span = start.to(self.prev_span());
        Some(EnumVariantDef { name, fields, span })
    }

    fn parse_struct(&mut self) -> Option<StructDef> {
        let start = self.peek_span();
        self.expect(&TokenKind::Struct)?;
        let name = self.expect_ident()?;
        let type_params = self.parse_opt_type_params()?;
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
        Some(StructDef { name, type_params, fields, span })
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
        let type_params = self.parse_opt_type_params()?;
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
        Some(FnSig { name, type_params, params, ret, span })
    }

    pub(super) fn parse_param(&mut self) -> Option<Param> {
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
}

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
}

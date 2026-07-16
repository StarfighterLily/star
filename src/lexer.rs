//! Lexer for Star: converts source text into a flat token stream.
//!
//! Star uses significant indentation like Python, so the lexer is responsible
//! for synthesizing [`TokenKind::Newline`], [`TokenKind::Indent`], and
//! [`TokenKind::Dedent`] tokens from leading whitespace. This keeps the parser
//! free of column-tracking logic — it simply consumes structural tokens.
//!
//! Indentation rules:
//! - Tabs are expanded to the next multiple of 8 columns.
//! - Blank lines and comment-only lines never emit structural tokens.
//! - A dedent that does not match a previously pushed indentation level is an
//!   error (inconsistent indentation).

use crate::diagnostics::{Diagnostic, Span};

/// The lexical category of a [`Token`].
#[derive(Clone, Debug, PartialEq)]
pub enum TokenKind {
    // Structural (indentation-driven).
    Newline,
    Indent,
    Dedent,

    // Literals.
    Int(i64),
    Float(f64),
    /// A single-quoted char literal (`'a'`, `'\n'`), already unescaped -- a
    /// Unicode scalar value, see `Ty::Char`.
    Char(char),
    /// A plain string literal, contents already unescaped.
    Str(String),
    /// An f-string, split into literal and interpolation parts.
    FStr(Vec<FStrPart>),
    Ident(String),

    // Keywords.
    Struct,
    Trait,
    Impl,
    Fn,
    Let,
    Mut,
    Match,
    Return,
    If,
    Else,
    For,
    In,
    While,
    Break,
    Continue,
    True,
    False,
    SelfKw,
    Enum,
    /// `import "path.star" as alias`.
    Import,
    As,
    /// `extern "C" fn ...` - a foreign function declaration with no body.
    Extern,
    // Memory / concurrency keywords (reserved now, used in later milestones).
    Frame,
    Arena,
    Swarm,
    Par,
    Sequence,
    Yield,
    Spawn,
    Despawn,

    // Punctuation & operators.
    Colon,
    ColonColon, // ::
    Comma,
    /// `;` -- used exactly once in the grammar, to separate the element
    /// type/value from the count in a fixed-size array type/expression
    /// (`[T; N]`/`[value; N]`); Star has no statement separator use for it
    /// at all (see `docs/design.md`'s "strips away the noise of semicolons").
    Semi,
    Dot,
    DotDot,     // ..
    Arrow,      // ->
    FatArrow,   // =>
    LParen,
    RParen,
    LBracket,
    RBracket,
    LBrace,
    RBrace,
    Plus,
    Minus,
    Star,
    Slash,
    Percent,
    Assign,     // =
    PlusEq,     // +=
    MinusEq,    // -=
    StarEq,     // *=
    SlashEq,    // /=
    EqEq,       // ==
    NotEq,      // !=
    Lt,         // <
    Gt,         // >
    LtEq,       // <=
    GtEq,       // >=
    Not,        // ! (also `not`)
    AndAnd,     // && (also `and`)
    OrOr,       // || (also `or`)
    At,         // @ (decorators)
    Underscore, // _ (wildcard pattern)
    Question,   // ? (Option/Result `?`-propagation)

    /// End of input.
    Eof,
}

impl TokenKind {
    /// A human-readable name for this token kind, used in parser diagnostics
    /// so messages read as `expected ':', found end of line` rather than
    /// `expected Colon, found Newline`.
    pub fn describe(&self) -> String {
        match self {
            TokenKind::Newline => "end of line".into(),
            TokenKind::Indent => "an indented block".into(),
            TokenKind::Dedent => "end of block".into(),
            TokenKind::Int(_) => "an integer literal".into(),
            TokenKind::Float(_) => "a float literal".into(),
            TokenKind::Char(_) => "a char literal".into(),
            TokenKind::Str(_) => "a string literal".into(),
            TokenKind::FStr(_) => "an f-string literal".into(),
            TokenKind::Ident(name) => format!("identifier `{}`", name),
            TokenKind::Struct => "'struct'".into(),
            TokenKind::Trait => "'trait'".into(),
            TokenKind::Impl => "'impl'".into(),
            TokenKind::Fn => "'fn'".into(),
            TokenKind::Let => "'let'".into(),
            TokenKind::Mut => "'mut'".into(),
            TokenKind::Match => "'match'".into(),
            TokenKind::Return => "'return'".into(),
            TokenKind::If => "'if'".into(),
            TokenKind::Else => "'else'".into(),
            TokenKind::For => "'for'".into(),
            TokenKind::In => "'in'".into(),
            TokenKind::While => "'while'".into(),
            TokenKind::Break => "'break'".into(),
            TokenKind::Continue => "'continue'".into(),
            TokenKind::True => "'true'".into(),
            TokenKind::False => "'false'".into(),
            TokenKind::SelfKw => "'self'".into(),
            TokenKind::Enum => "'enum'".into(),
            TokenKind::Import => "'import'".into(),
            TokenKind::As => "'as'".into(),
            TokenKind::Extern => "'extern'".into(),
            TokenKind::Frame => "'frame'".into(),
            TokenKind::Arena => "'arena'".into(),
            TokenKind::Swarm => "'swarm'".into(),
            TokenKind::Par => "'par'".into(),
            TokenKind::Sequence => "'sequence'".into(),
            TokenKind::Yield => "'yield'".into(),
            TokenKind::Spawn => "'spawn'".into(),
            TokenKind::Despawn => "'despawn'".into(),
            TokenKind::Colon => "':'".into(),
            TokenKind::ColonColon => "'::'".into(),
            TokenKind::Comma => "','".into(),
            TokenKind::Semi => "';'".into(),
            TokenKind::Dot => "'.'".into(),
            TokenKind::DotDot => "'..'".into(),
            TokenKind::Arrow => "'->'".into(),
            TokenKind::FatArrow => "'=>'".into(),
            TokenKind::LParen => "'('".into(),
            TokenKind::RParen => "')'".into(),
            TokenKind::LBracket => "'['".into(),
            TokenKind::RBracket => "']'".into(),
            TokenKind::LBrace => "'{'".into(),
            TokenKind::RBrace => "'}'".into(),
            TokenKind::Plus => "'+'".into(),
            TokenKind::Minus => "'-'".into(),
            TokenKind::Star => "'*'".into(),
            TokenKind::Slash => "'/'".into(),
            TokenKind::Percent => "'%'".into(),
            TokenKind::Assign => "'='".into(),
            TokenKind::PlusEq => "'+='".into(),
            TokenKind::MinusEq => "'-='".into(),
            TokenKind::StarEq => "'*='".into(),
            TokenKind::SlashEq => "'/='".into(),
            TokenKind::EqEq => "'=='".into(),
            TokenKind::NotEq => "'!='".into(),
            TokenKind::Lt => "'<'".into(),
            TokenKind::Gt => "'>'".into(),
            TokenKind::LtEq => "'<='".into(),
            TokenKind::GtEq => "'>='".into(),
            TokenKind::Not => "'!'".into(),
            TokenKind::AndAnd => "'&&'".into(),
            TokenKind::OrOr => "'||'".into(),
            TokenKind::At => "'@'".into(),
            TokenKind::Underscore => "'_'".into(),
            TokenKind::Question => "'?'".into(),
            TokenKind::Eof => "end of file".into(),
        }
    }
}

/// One segment of an f-string: either raw text or an embedded expression.
#[derive(Clone, Debug, PartialEq)]
pub enum FStrPart {
    /// Literal characters between `{ ... }` holes.
    Literal(String),
    /// Raw source of an interpolation `{expr}`, re-lexed/parsed later.
    Expr(String),
}

/// A token with its source span.
#[derive(Clone, Debug, PartialEq)]
pub struct Token {
    pub kind: TokenKind,
    pub span: Span,
}

/// Width of a tab stop when expanding leading tabs to columns.
const TAB_WIDTH: usize = 8;

/// The lexer holds the source and incremental scan state.
pub struct Lexer<'src> {
    src: &'src str,
    bytes: &'src [u8],
    /// Current byte offset.
    pos: usize,
    /// Stack of active indentation column widths; always starts with `0`.
    indents: Vec<usize>,
    /// Emitted tokens.
    tokens: Vec<Token>,
    /// Bracket nesting depth; newlines inside brackets are ignored.
    bracket_depth: usize,
    /// Accumulated errors (lexing continues where possible).
    errors: Vec<Diagnostic>,
}

impl<'src> Lexer<'src> {
    pub fn new(src: &'src str) -> Self {
        Self {
            src,
            bytes: src.as_bytes(),
            pos: 0,
            indents: vec![0],
            tokens: Vec::new(),
            bracket_depth: 0,
            errors: Vec::new(),
        }
    }

    /// Run the lexer, returning tokens on success or diagnostics on failure.
    pub fn tokenize(mut self) -> Result<Vec<Token>, Vec<Diagnostic>> {
        // Process the file line by line so indentation is handled uniformly.
        while self.pos < self.bytes.len() {
            if self.bracket_depth == 0 {
                self.handle_line_start();
            }
            self.scan_line_content();
        }

        // Emit a trailing newline if the last line had content.
        if matches!(
            self.tokens.last().map(|t| &t.kind),
            Some(k) if !matches!(k, TokenKind::Newline | TokenKind::Indent | TokenKind::Dedent)
        ) {
            self.push(TokenKind::Newline, self.pos, self.pos);
        }

        // Close any remaining open indentation blocks.
        while self.indents.len() > 1 {
            self.indents.pop();
            self.push(TokenKind::Dedent, self.pos, self.pos);
        }
        self.push(TokenKind::Eof, self.pos, self.pos);

        if self.errors.is_empty() {
            Ok(self.tokens)
        } else {
            Err(self.errors)
        }
    }

    /// At the beginning of a logical line, measure indentation and emit
    /// INDENT/DEDENT tokens relative to the indentation stack.
    fn handle_line_start(&mut self) {
        // Loop past any run of blank/comment-only lines (each contributes no
        // structural tokens and must not affect the indentation stack) until
        // a real content line is found, then measure its indentation exactly
        // once. Looping here (rather than a single skip-and-return) matters
        // because `tokenize()`'s driver loop calls this function once, then
        // `scan_line_content()` once, per iteration -- if a blank/comment
        // line's own trailing `\n` were consumed without also resolving the
        // *next* line's indentation before returning, `scan_line_content()`
        // would scan that next line's tokens with its indentation never
        // measured, silently dropping the `Indent`/`Dedent` it needs.
        loop {
            let line_start = self.pos;
            let mut width = 0;
            let mut i = self.pos;
            while i < self.bytes.len() {
                match self.bytes[i] {
                    b' ' => width += 1,
                    b'\t' => width = (width / TAB_WIDTH + 1) * TAB_WIDTH,
                    _ => break,
                }
                i += 1;
            }

            if i >= self.bytes.len() {
                self.pos = i;
                return;
            }

            // Skip blank or comment-only lines without emitting structural
            // tokens -- consuming the line's own trailing `\n` too, so
            // `scan_line_content()` never sees it and can't emit a spurious
            // `Newline` for a line that's supposed to produce no tokens.
            // A CRLF blank line is just `\r\n` with zero spaces/tabs before
            // it, so `bytes[i]` lands on `\r`, not `\n` -- without this arm
            // such a line falls through to the indentation branch below and
            // (since its measured width is 0) pops every open indent level,
            // corrupting the token stream for the rest of the block with no
            // diagnostic at all.
            if self.bytes[i] == b'\n' || self.bytes[i] == b'\r' || self.bytes[i] == b'#' {
                self.pos = i;
                self.skip_to_line_end();
                if self.pos < self.bytes.len() && self.bytes[self.pos] == b'\n' {
                    self.pos += 1;
                }
                continue;
            }

            self.pos = i;
            let current = *self.indents.last().unwrap();
            if width > current {
                self.indents.push(width);
                self.push(TokenKind::Indent, line_start, self.pos);
            } else if width < current {
                while *self.indents.last().unwrap() > width {
                    self.indents.pop();
                    self.push(TokenKind::Dedent, line_start, self.pos);
                }
                if *self.indents.last().unwrap() != width {
                    self.errors.push(Diagnostic::error(
                        "inconsistent indentation",
                        Span::new(line_start, self.pos),
                    ));
                }
            }
            return;
        }
    }

    /// Scan tokens until the end of the current physical line.
    fn scan_line_content(&mut self) {
        while self.pos < self.bytes.len() {
            let c = self.bytes[self.pos];
            match c {
                b'\n' => {
                    if self.bracket_depth == 0 {
                        self.push(TokenKind::Newline, self.pos, self.pos + 1);
                        self.pos += 1;
                        return;
                    }
                    self.pos += 1;
                }
                b' ' | b'\t' | b'\r' => self.pos += 1,
                b'#' => self.skip_to_line_end(),
                _ => self.scan_token(),
            }
        }
    }

    /// Advance past the remainder of the physical line (not the newline).
    fn skip_to_line_end(&mut self) {
        while self.pos < self.bytes.len() && self.bytes[self.pos] != b'\n' {
            self.pos += 1;
        }
    }

    /// Scan a single non-whitespace token.
    fn scan_token(&mut self) {
        let start = self.pos;
        let c = self.bytes[self.pos];
        match c {
            b'0'..=b'9' => self.scan_number(),
            b'"' => self.scan_string(start),
            b'\'' => self.scan_char(start),
            c if c == b'f' && self.peek(1) == Some(b'"') => self.scan_fstring(start),
            c if is_ident_start(c) => self.scan_ident(),
            _ => self.scan_operator(),
        }
    }

    fn scan_number(&mut self) {
        let start = self.pos;
        while self.pos < self.bytes.len() && self.bytes[self.pos].is_ascii_digit() {
            self.pos += 1;
        }
        let mut is_float = false;
        if self.pos < self.bytes.len()
            && self.bytes[self.pos] == b'.'
            && self.peek(1).map(|b| b.is_ascii_digit()).unwrap_or(false)
        {
            is_float = true;
            self.pos += 1;
            while self.pos < self.bytes.len() && self.bytes[self.pos].is_ascii_digit() {
                self.pos += 1;
            }
        }
        let text = &self.src[start..self.pos];
        let kind = if is_float {
            TokenKind::Float(text.parse().unwrap_or(0.0))
        } else {
            // Star's plain (un-cast) `Ty::Int` literal type is a 32-bit
            // `i32` (see `Checker::resolve_type`/`Codegen::llvm_ty`), but a
            // literal can also be the direct operand of a widening `as
            // <sized int type>` cast (`5000000000 as i64`), which needs the
            // literal's full magnitude preserved past `i32`'s range --
            // `Checker::infer_expr`'s `Expr::Cast` arm special-cases exactly
            // that shape. The lexer therefore only rejects a magnitude that
            // doesn't fit `i64` at all (this token's Rust-side storage
            // width, unrelated to any particular Star type); whether a
            // literal that fits `i64` but not `i32` is actually legal in
            // context is deferred entirely to the checker, which is the
            // first place that knows whether a cast is widening it.
            match text.parse::<i64>() {
                Ok(v) => TokenKind::Int(v),
                Err(_) => {
                    self.errors.push(Diagnostic::error(
                        format!("integer literal `{}` is too large (max 9223372036854775807)", text),
                        Span::new(start, self.pos),
                    ));
                    TokenKind::Int(0)
                }
            }
        };
        self.push(kind, start, self.pos);
    }

    fn scan_ident(&mut self) {
        let start = self.pos;
        while self.pos < self.bytes.len() && is_ident_continue(self.bytes[self.pos]) {
            self.pos += 1;
        }
        let text = &self.src[start..self.pos];
        let kind = keyword_or_ident(text);
        self.push(kind, start, self.pos);
    }

    /// Scan a plain `"..."` string with basic escape handling.
    fn scan_string(&mut self, start: usize) {
        self.pos += 1; // opening quote
        let mut value = String::new();
        while self.pos < self.bytes.len() {
            let c = self.bytes[self.pos];
            match c {
                b'"' => {
                    self.pos += 1;
                    self.push(TokenKind::Str(value), start, self.pos);
                    return;
                }
                b'\\' => {
                    self.pos += 1;
                    if let Some(esc) = self.scan_escape() {
                        value.push(esc);
                    }
                }
                b'\n' => break,
                _ => {
                    value.push(self.current_char());
                    self.pos += self.current_char_len();
                }
            }
        }
        self.errors.push(Diagnostic::error(
            "unterminated string literal",
            Span::new(start, self.pos),
        ));
    }

    /// Scan a `'c'` char literal: exactly one (possibly escaped) codepoint
    /// between single quotes -- see `Ty::Char`'s doc comment. Reuses
    /// `scan_escape` (already shared with `scan_string`/`scan_fstring`) for
    /// backslash escapes, so `'\n'`/`'\''`/etc. all work identically to their
    /// string-literal spelling.
    fn scan_char(&mut self, start: usize) {
        self.pos += 1; // opening quote
        if self.pos < self.bytes.len() && self.bytes[self.pos] == b'\'' {
            self.errors.push(Diagnostic::error("empty char literal", Span::new(start, self.pos + 1)));
            self.pos += 1;
            return;
        }
        let ch = if self.pos < self.bytes.len() && self.bytes[self.pos] == b'\\' {
            self.pos += 1;
            self.scan_escape().unwrap_or('\0')
        } else if self.pos < self.bytes.len() {
            let c = self.current_char();
            self.pos += self.current_char_len();
            c
        } else {
            self.errors.push(Diagnostic::error("unterminated char literal", Span::new(start, self.pos)));
            return;
        };
        if self.pos >= self.bytes.len() || self.bytes[self.pos] != b'\'' {
            self.errors.push(Diagnostic::error(
                "char literal must contain exactly one character (did you mean a string literal `\"...\"`?)",
                Span::new(start, self.pos),
            ));
            // Recover by skipping to the closing quote (or line end) so one
            // bad char literal doesn't cascade into unrelated errors for the
            // rest of the line.
            while self.pos < self.bytes.len() && self.bytes[self.pos] != b'\'' && self.bytes[self.pos] != b'\n' {
                self.pos += 1;
            }
            if self.pos < self.bytes.len() && self.bytes[self.pos] == b'\'' {
                self.pos += 1;
            }
            return;
        }
        self.pos += 1; // closing quote
        self.push(TokenKind::Char(ch), start, self.pos);
    }

    /// Scan an `f"..."` string, splitting `{expr}` holes from literal text.
    fn scan_fstring(&mut self, start: usize) {
        self.pos += 2; // consume f"
        let mut parts: Vec<FStrPart> = Vec::new();
        let mut literal = String::new();
        while self.pos < self.bytes.len() {
            let c = self.bytes[self.pos];
            match c {
                b'"' => {
                    self.pos += 1;
                    if !literal.is_empty() {
                        parts.push(FStrPart::Literal(literal));
                    }
                    self.push(TokenKind::FStr(parts), start, self.pos);
                    return;
                }
                b'{' => {
                    if !literal.is_empty() {
                        parts.push(FStrPart::Literal(std::mem::take(&mut literal)));
                    }
                    self.pos += 1;
                    let expr_start = self.pos;
                    let mut depth = 1;
                    // Tracks whether the scan is currently inside a nested
                    // `"..."` string literal within the hole's expression
                    // (e.g. `f"{concat("}", x)}"` ) -- brace bytes inside one
                    // don't affect nesting `depth`, and a `\"` inside it
                    // doesn't end it early. Bytes are compared against plain
                    // ASCII here (not full codepoints); that's safe even for
                    // multi-byte UTF-8 content because no continuation or
                    // lead byte of a multi-byte sequence ever collides with
                    // the ASCII values of `"`/`{`/`}`/`\`.
                    let mut in_str = false;
                    while self.pos < self.bytes.len() && depth > 0 {
                        match self.bytes[self.pos] {
                            b'\\' if in_str => {
                                // Skip the escaped byte too, so it's never
                                // mistaken for the closing `"`.
                                self.pos += 1;
                            }
                            b'"' => in_str = !in_str,
                            b'{' if !in_str => depth += 1,
                            b'}' if !in_str => depth -= 1,
                            // A `char` literal (`'x'`/`'\n'`/`'}'`/...) inside
                            // the hole's expression: unlike the nested-`"..."`-
                            // string handling above, this couldn't just toggle
                            // an `in_char` flag on `'` alone, since `'` is also
                            // a syntactically valid *content* byte inside a
                            // `str` literal -- the flag would flip incorrectly
                            // there. Instead, consume the whole `'...'` unit
                            // (opening quote, one possibly-backslash-escaped
                            // byte/codepoint, closing quote) right here as an
                            // atomic step so a brace *inside* it (`'}'`) is
                            // never separately matched against the `{`/`}`
                            // arms above and mistaken for closing the hole
                            // early. Previously missing entirely -- only
                            // string-literal nesting was ever considered (see
                            // this loop's own doc comment) -- so `f"{c == '}'}"`
                            // desynced the hole boundary at the `}` inside the
                            // char literal, producing a nonsensical downstream
                            // parse error far from the real (non-)issue.
                            b'\'' if !in_str => {
                                self.pos += 1; // opening quote
                                if self.pos < self.bytes.len() && self.bytes[self.pos] == b'\\' {
                                    self.pos += 1; // backslash
                                    if self.pos < self.bytes.len() {
                                        self.pos += 1; // escaped byte
                                    }
                                } else if self.pos < self.bytes.len() {
                                    self.pos += self.current_char_len();
                                }
                                // `self.pos` now sits on the closing `'` (if
                                // well-formed); the shared `self.pos += 1`
                                // below consumes it, same "already adjusted,
                                // then +1" shape every other arm here uses.
                            }
                            _ => {}
                        }
                        if depth == 0 {
                            break;
                        }
                        self.pos += 1;
                    }
                    let expr = self.src[expr_start..self.pos].to_string();
                    parts.push(FStrPart::Expr(expr));
                    self.pos += 1; // consume closing }
                }
                b'\\' => {
                    self.pos += 1;
                    if let Some(esc) = self.scan_escape() {
                        literal.push(esc);
                    }
                }
                b'\n' => break,
                _ => {
                    literal.push(self.current_char());
                    self.pos += self.current_char_len();
                }
            }
        }
        self.errors.push(Diagnostic::error(
            "unterminated f-string literal",
            Span::new(start, self.pos),
        ));
    }

    /// Decode a backslash escape; `self.pos` points just past the backslash.
    fn scan_escape(&mut self) -> Option<char> {
        if self.pos >= self.bytes.len() {
            return None;
        }
        // The escaped byte may be a multi-byte UTF-8 lead byte, so decode a
        // full codepoint (as elsewhere in the lexer) rather than a raw byte
        // -- otherwise `self.pos` desyncs from the byte stream and a later
        // `current_char()` call panics mid-codepoint.
        let esc_start = self.pos - 1; // the backslash itself
        let ch = self.current_char();
        self.pos += self.current_char_len();
        Some(match ch {
            'n' => '\n',
            't' => '\t',
            'r' => '\r',
            '\\' => '\\',
            '"' => '"',
            '0' => '\0',
            // A literal `{`/`}` inside an f-string's literal text -- unescaped,
            // `{` opens an interpolation hole (see `scan_fstring`), so there
            // was previously no way to spell a literal brace at all: `\{`
            // fell through to the `other` arm below as a bogus "unknown
            // escape sequence", and doubling (`{{`) doesn't work either,
            // since the first `{` unconditionally opens a hole. Recognized
            // here (not just inside `scan_fstring`) since plain string
            // literals share this same escape decoder; harmless there too,
            // as `{`/`}` are never special outside an f-string.
            '{' => '{',
            '}' => '}',
            other => {
                self.errors.push(Diagnostic::error(
                    format!("unknown escape sequence '\\{}'", other),
                    Span::new(esc_start, self.pos),
                ));
                other
            }
        })
    }

    /// Scan punctuation and multi-character operators.
    fn scan_operator(&mut self) {
        let start = self.pos;
        let c = self.bytes[self.pos];
        let two = self.peek(1);
        macro_rules! two_char {
            ($k:expr) => {{
                self.pos += 2;
                self.push($k, start, self.pos);
                return;
            }};
        }
        match (c, two) {
            (b'-', Some(b'>')) => two_char!(TokenKind::Arrow),
            (b'=', Some(b'>')) => two_char!(TokenKind::FatArrow),
            (b'.', Some(b'.')) => two_char!(TokenKind::DotDot),
            (b':', Some(b':')) => two_char!(TokenKind::ColonColon),
            (b'=', Some(b'=')) => two_char!(TokenKind::EqEq),
            (b'!', Some(b'=')) => two_char!(TokenKind::NotEq),
            (b'<', Some(b'=')) => two_char!(TokenKind::LtEq),
            (b'>', Some(b'=')) => two_char!(TokenKind::GtEq),
            (b'+', Some(b'=')) => two_char!(TokenKind::PlusEq),
            (b'-', Some(b'=')) => two_char!(TokenKind::MinusEq),
            (b'*', Some(b'=')) => two_char!(TokenKind::StarEq),
            (b'/', Some(b'=')) => two_char!(TokenKind::SlashEq),
            (b'&', Some(b'&')) => two_char!(TokenKind::AndAnd),
            (b'|', Some(b'|')) => two_char!(TokenKind::OrOr),
            _ => {}
        }
        let kind = match c {
            b':' => TokenKind::Colon,
            b',' => TokenKind::Comma,
            b';' => TokenKind::Semi,
            b'.' => TokenKind::Dot,
            b'(' => {
                self.bracket_depth += 1;
                TokenKind::LParen
            }
            b')' => {
                self.bracket_depth = self.bracket_depth.saturating_sub(1);
                TokenKind::RParen
            }
            b'[' => {
                self.bracket_depth += 1;
                TokenKind::LBracket
            }
            b']' => {
                self.bracket_depth = self.bracket_depth.saturating_sub(1);
                TokenKind::RBracket
            }
            b'{' => {
                self.bracket_depth += 1;
                TokenKind::LBrace
            }
            b'}' => {
                self.bracket_depth = self.bracket_depth.saturating_sub(1);
                TokenKind::RBrace
            }
            b'+' => TokenKind::Plus,
            b'-' => TokenKind::Minus,
            b'*' => TokenKind::Star,
            b'/' => TokenKind::Slash,
            b'%' => TokenKind::Percent,
            b'=' => TokenKind::Assign,
            b'<' => TokenKind::Lt,
            b'>' => TokenKind::Gt,
            b'!' => TokenKind::Not,
            b'@' => TokenKind::At,
            b'?' => TokenKind::Question,
            _ => {
                // `c` may be the lead byte of a multi-byte UTF-8 codepoint
                // (e.g. an accented identifier or stray symbol); consuming
                // only this one raw byte would leave `self.pos` mid-codepoint,
                // producing a `Span` that isn't a valid `str` slice boundary
                // and panics later when `diagnostics::line_text` slices the
                // source with it.
                let ch = self.current_char();
                self.pos += self.current_char_len().max(1);
                self.errors.push(Diagnostic::error(
                    format!("unexpected character '{}'", ch),
                    Span::new(start, self.pos),
                ));
                return;
            }
        };
        self.pos += 1;
        self.push(kind, start, self.pos);
    }

    // --- helpers ---------------------------------------------------------

    fn peek(&self, ahead: usize) -> Option<u8> {
        self.bytes.get(self.pos + ahead).copied()
    }

    fn current_char(&self) -> char {
        self.src[self.pos..].chars().next().unwrap_or('\0')
    }

    fn current_char_len(&self) -> usize {
        self.current_char().len_utf8()
    }

    fn push(&mut self, kind: TokenKind, start: usize, end: usize) {
        self.tokens.push(Token { kind, span: Span::new(start, end) });
    }
}

fn is_ident_start(c: u8) -> bool {
    c == b'_' || c.is_ascii_alphabetic()
}

fn is_ident_continue(c: u8) -> bool {
    c == b'_' || c.is_ascii_alphanumeric()
}

/// Map an identifier string to its keyword token, or a plain identifier.
fn keyword_or_ident(text: &str) -> TokenKind {
    match text {
        "struct" => TokenKind::Struct,
        "trait" => TokenKind::Trait,
        "impl" => TokenKind::Impl,
        "fn" => TokenKind::Fn,
        "let" => TokenKind::Let,
        "mut" => TokenKind::Mut,
        "match" => TokenKind::Match,
        "return" => TokenKind::Return,
        "if" => TokenKind::If,
        "else" => TokenKind::Else,
        "for" => TokenKind::For,
        "in" => TokenKind::In,
        "while" => TokenKind::While,
        "break" => TokenKind::Break,
        "continue" => TokenKind::Continue,
        "true" => TokenKind::True,
        "false" => TokenKind::False,
        "self" => TokenKind::SelfKw,
        "enum" => TokenKind::Enum,
        "import" => TokenKind::Import,
        "as" => TokenKind::As,
        "extern" => TokenKind::Extern,
        "frame" => TokenKind::Frame,
        "arena" => TokenKind::Arena,
        "swarm" => TokenKind::Swarm,
        "par" => TokenKind::Par,
        "sequence" => TokenKind::Sequence,
        "yield" => TokenKind::Yield,
        "spawn" => TokenKind::Spawn,
        "despawn" => TokenKind::Despawn,
        "and" => TokenKind::AndAnd,
        "or" => TokenKind::OrOr,
        "not" => TokenKind::Not,
        "_" => TokenKind::Underscore,
        _ => TokenKind::Ident(text.to_string()),
    }
}
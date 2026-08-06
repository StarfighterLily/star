# NoBASIC lexer -- ported from the reference Python `compiler/lexer/lexer.py`
# (`c:\Code\projects\Nova\NoBASIC\compiler\lexer\lexer.py`), todo.md P0 #1.
# See `tokens.star` for the `TokenType`/`Token` port this builds on and its
# own header comment for the reference-vs-implementation drift already
# found in the keyword table.
#
# Error handling shape: the reference raises `LexerError` (a Python
# exception) to unwind out of arbitrarily-nested scanning calls the moment
# something is wrong. Star has no exceptions, and its `Result<T, E>`/`?`
# operator require the *exact* same `Result<T, E>` instantiation at every
# propagation point (confirmed empirically -- differing success-value types
# across a `?` chain is a hard compile error, not something that unifies or
# coerces) -- so a `Result` per scan-helper (each returning a different
# success shape) doesn't work here. Instead, `Lexer` carries a `had_error`
# flag plus the failure's message/line/column as ordinary mutable fields;
# every scanning method checks/sets it directly and returns (implicit unit)
# rather than raising or threading a `Result` through every call. Only the
# single public entry point, `lex`, turns that final flag into the
# `Result<List<Token>, LexError>` callers actually see -- the same
# "stop at the first problem, report it once" shape `assembler.star`
# already established for this project.
#
# `start_position`/`start_line`/`start_column` are set exactly once per
# `scan_token` call (matching the reference precisely) and never touched
# again by `scan_identifier`/`scan_asm_block` even though those may call
# `add_token_*` more than once (an `Asm ... End` block emits three tokens
# -- `Asm`, `AsmBlock`, `End` -- from a single `scan_token` dispatch). This
# reproduces a real reference quirk faithfully rather than "fixing" it:
# the `AsmBlock` and `End` tokens both end up with the *same* oversized
# `lexeme` spanning all the way back to the original `Asm` keyword, because
# `nobasic_compiler.py`'s own `Token.__str__`/downstream consumers only
# ever read `.literal` for these two token kinds, never `.lexeme` -- so it
# is a real, harmless-in-practice accident of the reference implementation,
# not a deliberate design choice, and not this port's place to silently
# diverge from.

import "tokens.star" as tok

extern "C" fn atoi(s: str) -> i32
extern "C" fn atof(s: str) -> f64
extern "C" fn strtol(s: str, endptr: ptr, base: i32) -> i32

struct LexError:
    message: str
    filename: str = "<stdin>"
    line: i32 = 0
    column: i32 = 0

fn format_lex_error(e: LexError) -> str:
    if e.filename == "<stdin>":
        concat("Error: ", e.message)
    else:
        f"Error in {e.filename} at line {e.line}, column {e.column}: {e.message}"

# ---------------------------------------------------------------------------
# Byte-classification/substring helpers -- Star's `str` has no substring or
# character type (only `s[i] -> i32` single-byte indexing), the same
# constraint `assembler.star`'s own header comment documents and works
# around; these are that file's `substr`/`is_ws_byte`/`is_digit_byte`
# helpers, redefined locally so this file stays a self-contained tool like
# every other `projects/nova/*.star` file.
# ---------------------------------------------------------------------------

fn is_digit_byte(c: i32) -> bool:
    c >= 48 and c <= 57

fn is_alpha_byte(c: i32) -> bool:
    (c >= 65 and c <= 90) or (c >= 97 and c <= 122)

fn is_alnum_byte(c: i32) -> bool:
    is_alpha_byte(c) or is_digit_byte(c)

fn is_hex_digit_byte(c: i32) -> bool:
    is_digit_byte(c) or (c >= 65 and c <= 70) or (c >= 97 and c <= 102)

fn to_lower_byte(c: i32) -> i32:
    if c >= 65 and c <= 90:
        c + 32
    else:
        c

fn str_lower(s: str) -> str:
    let mut parts: List<str> = List<str>()
    let mut i = 0
    while i < len(s):
        parts.push(chr(to_lower_byte(s[i])))
        i += 1
    str_join(parts, "")

# Maps an escaped character (the byte right after a `\` in a string
# literal) to its resulting text, mirroring the reference `_STRING_ESCAPES`
# dict exactly, including its fallback: an unrecognized escape (`\q`)
# passes the escaped character through literally (`q`, not `\q`), matching
# Python's `dict.get(escaped_char, escaped_char)` default-to-the-key-itself
# behavior.
fn escape_char(c: i32) -> str:
    match c:
        110 -> "\n"   # \n
        114 -> "\r"   # \r
        116 -> "\t"   # \t
        34 -> "\""    # \"
        92 -> "\\"    # \\
        48 -> chr(0)  # \0 -- see this file's header comment's NUL caveat
        _ -> chr(c)

# ---------------------------------------------------------------------------
# Lexer
# ---------------------------------------------------------------------------

struct Lexer:
    source: str
    filename: str
    keywords: Map<str, tok::TokenType>
    mut position: i32 = 0
    mut line: i32 = 1
    mut column: i32 = 1
    mut start_position: i32 = 0
    mut start_line: i32 = 1
    mut start_column: i32 = 1
    mut tokens: List<tok::Token> = List<tok::Token>()
    mut had_error: bool = false
    mut error_message: str = ""
    mut error_line: i32 = 0
    mut error_column: i32 = 0

fn new_lexer(source: str, filename: str) -> Lexer:
    Lexer(source = source, filename = filename, keywords = tok::build_keywords())

impl Lexer:
    fn is_at_end(self) -> bool:
        self.position >= len(self.source)

    fn peek(self) -> i32:
        if self.is_at_end():
            0
        else:
            self.source[self.position]

    fn advance(mut self) -> i32:
        let c = self.source[self.position]
        self.position += 1
        self.column += 1
        c

    fn match_char(mut self, expected: i32) -> bool:
        if self.is_at_end() or self.source[self.position] != expected:
            false
        else:
            self.position += 1
            self.column += 1
            true

    fn substr(self, start: i32, end: i32) -> str:
        let mut parts: List<str> = List<str>()
        let mut i = start
        while i < end:
            parts.push(chr(self.source[i]))
            i += 1
        str_join(parts, "")

    fn fail(mut self, message: str, line: i32, column: i32):
        if !self.had_error:
            self.had_error = true
            self.error_message = message
            self.error_line = line
            self.error_column = column

    fn current_lexeme(self) -> str:
        self.substr(self.start_position, self.position)

    fn add_token_plain(mut self, kind: tok::TokenType):
        let lexeme = self.current_lexeme()
        self.tokens.push(tok::Token(kind = kind, lexeme = lexeme, line = self.start_line, column = self.start_column))

    fn add_token_num(mut self, kind: tok::TokenType, num_value: f64, is_float: bool):
        let lexeme = self.current_lexeme()
        self.tokens.push(tok::Token(kind = kind, lexeme = lexeme, num_value = num_value, is_float = is_float, line = self.start_line, column = self.start_column))

    fn add_token_str(mut self, kind: tok::TokenType, str_value: str):
        let lexeme = self.current_lexeme()
        self.tokens.push(tok::Token(kind = kind, lexeme = lexeme, str_value = str_value, line = self.start_line, column = self.start_column))

    # Scans a `0x`/`0b`-prefixed or plain decimal number literal. Called
    # with `self.start_position` pointing at the leading digit already
    # consumed by `scan_token`'s own `advance()` -- matches the reference
    # `number()`'s `start = self.position - 1`.
    fn scan_number(mut self):
        if self.source[self.start_position] == 48 and !self.is_at_end():
            let next_lower = to_lower_byte(self.peek())
            if next_lower == 120:
                self.advance()
                let hex_start = self.position
                while !self.is_at_end() and is_hex_digit_byte(self.peek()):
                    self.advance()
                if self.position == hex_start:
                    self.fail("Invalid hexadecimal number", self.line, self.column)
                    return
                let text = self.substr(hex_start, self.position)
                let value = strtol(text, null_ptr(), 16)
                self.add_token_num(tok::TokenType::NumberLiteral, value as f64, false)
                return
            elif next_lower == 98:
                self.advance()
                let bin_start = self.position
                while !self.is_at_end() and (self.peek() == 48 or self.peek() == 49):
                    self.advance()
                if self.position == bin_start:
                    self.fail("Invalid binary number", self.line, self.column)
                    return
                let text = self.substr(bin_start, self.position)
                let value = strtol(text, null_ptr(), 2)
                self.add_token_num(tok::TokenType::NumberLiteral, value as f64, false)
                return

        let mut has_dot = false
        while !self.is_at_end() and (is_digit_byte(self.peek()) or self.peek() == 46):
            if self.peek() == 46:
                if has_dot:
                    break
                has_dot = true
            self.advance()

        let text = self.substr(self.start_position, self.position)
        if has_dot:
            self.add_token_num(tok::TokenType::NumberLiteral, atof(text), true)
        else:
            self.add_token_num(tok::TokenType::NumberLiteral, atoi(text) as f64, false)

    fn scan_identifier(mut self):
        while !self.is_at_end() and (is_alnum_byte(self.peek()) or self.peek() == 95):
            self.advance()
        let word = str_lower(self.current_lexeme())
        let kind = tok::keyword_lookup(self.keywords, word)
        if kind == tok::TokenType::Asm:
            self.scan_asm_block()
        else:
            self.add_token_plain(kind)

    fn scan_string(mut self):
        let start_line = self.line
        let mut value_parts: List<str> = List<str>()
        while !self.is_at_end():
            let c = self.advance()
            if c == 34:
                self.add_token_str(tok::TokenType::StringLiteral, str_join(value_parts, ""))
                return
            if c == 92:
                if self.is_at_end():
                    self.fail("Unterminated string", start_line, self.column)
                    return
                let escaped = self.advance()
                value_parts.push(escape_char(escaped))
                if escaped == 10:
                    self.line += 1
                    self.column = 1
                continue
            if c == 10:
                self.line += 1
                self.column = 1
            value_parts.push(chr(c))
        self.fail("Unterminated string", start_line, self.column)

    # Captures raw text between `Asm` and a following `End` keyword as one
    # `AsmBlock` token -- see this file's header comment for the lexeme
    # quirk this (faithfully) inherits from the reference.
    fn scan_asm_block(mut self):
        self.add_token_plain(tok::TokenType::Asm)
        let start_line = self.line

        while !self.is_at_end() and (self.peek() == 32 or self.peek() == 9 or self.peek() == 13 or self.peek() == 10):
            if self.peek() == 10:
                self.line += 1
                self.column = 1
            self.advance()

        let asm_start = self.position
        while !self.is_at_end():
            if self.had_error:
                return
            if to_lower_byte(self.peek()) == 101:
                let saved_pos = self.position
                let saved_line = self.line
                let saved_col = self.column
                let word_start = self.position
                while !self.is_at_end() and (is_alnum_byte(self.peek()) or self.peek() == 95):
                    self.advance()
                let word = str_lower(self.substr(word_start, self.position))
                if word == "end":
                    let asm_code = str_trim(self.substr(asm_start, word_start))
                    self.add_token_str(tok::TokenType::AsmBlock, asm_code)
                    self.add_token_plain(tok::TokenType::End)
                    return
                else:
                    self.position = saved_pos
                    self.line = saved_line
                    self.column = saved_col
            if self.peek() == 10:
                self.line += 1
                self.column = 1
            self.advance()

        self.fail("Unterminated Asm block (missing 'End')", start_line, self.column)

    fn scan_token(mut self):
        self.start_position = self.position
        self.start_line = self.line
        self.start_column = self.column
        let c = self.advance()

        if c == 47 and self.match_char(47):
            while !self.is_at_end() and self.peek() != 10:
                self.advance()
            return

        if c == 60 and self.match_char(62):
            self.add_token_plain(tok::TokenType::NotEqual)
            return
        if c == 60 and self.match_char(61):
            self.add_token_plain(tok::TokenType::LessEqual)
            return
        if c == 60 and self.match_char(60):
            self.add_token_plain(tok::TokenType::ShiftLeft)
            return
        if c == 62 and self.match_char(61):
            self.add_token_plain(tok::TokenType::GreaterEqual)
            return
        if c == 62 and self.match_char(62):
            self.add_token_plain(tok::TokenType::ShiftRight)
            return
        if c == 43 and self.match_char(43):
            self.add_token_plain(tok::TokenType::Increment)
            return
        if c == 45 and self.match_char(45):
            self.add_token_plain(tok::TokenType::Decrement)
            return

        if c == 34:
            self.scan_string()
            return

        match tok::single_char_token(c):
            Option::Some(t) ->
                self.add_token_plain(t)
                return
            Option::None -> 0

        if is_digit_byte(c):
            self.scan_number()
            return
        elif is_alpha_byte(c) or c == 95:
            self.scan_identifier()
            return
        elif c == 32 or c == 13 or c == 9:
            return
        elif c == 10:
            self.line += 1
            self.column = 1
            return
        else:
            self.fail(concat("Unexpected character: ", chr(c)), self.start_line, self.start_column)
            return

# Tokenizes `source`, returning every token including a trailing `Eof`, or
# the first `LexError` encountered (this port stops at the first problem
# rather than the reference's exception-unwind, but reports the same
# message/line/column).
fn lex(source: str, filename: str) -> Result<List<tok::Token>, LexError>:
    let mut lexer = new_lexer(source, filename)
    while !lexer.is_at_end() and !lexer.had_error:
        lexer.scan_token()
    if lexer.had_error:
        return Result<List<tok::Token>, LexError>::Err(LexError(message = lexer.error_message, filename = filename, line = lexer.error_line, column = lexer.error_column))
    lexer.tokens.push(tok::Token(kind = tok::TokenType::Eof, line = lexer.line, column = lexer.column))
    Result<List<tok::Token>, LexError>::Ok(lexer.tokens)

# LPC lexer -- ported from HavokOS `pike/lpc/lexer.pike`, plus the lexical
# fix-ups `pike/lpc/preprocess.pike` applied before handing text to Pike's
# `cpp()` (`norm`, `fix_lexical`'s raw-newline-in-string and `@MARK` text
# block handling), todo.md HavokOS M1.
#
# Why the fix-ups moved in here: the reference runs `fix_lexical` (a text
# rewrite) -> Pike `cpp()` -> `tokenize`, so its lexer never sees comments,
# directives or text blocks. This port has no `cpp()` to lean on and does
# its own token-level preprocessing (`preprocess.star`), so lexing comes
# *first*, over raw file text. That means this lexer handles everything the
# reference's three stages did between them:
#   - `\r\n` / lone `\r` -> `\n` (`preprocess.pike::norm`)
#   - comments, backslash-newline continuations
#   - `#` directive lines, captured whole as one `Tk::Directive` token
#   - raw newlines inside string literals (FluffOS allows them; the
#     reference splits them into adjacent literals so `cpp()` accepts them)
#   - `@MARK` / `@@MARK` text blocks (`preprocess.pike::try_heredoc`)
#
# Performance: works on `Bytes`, never on `str` -- Star's `s[i]` re-runs
# `strlen` for its bounds check, which made a character-at-a-time scan of a
# 1 MB string take ~70 s versus ~1 ms over `Bytes` (see NOTES.md, "Star
# constraints" #3). `str` values are only built for finished token text.
#
# Faithfully reproduced reference quirks:
#   - A string token's line is the line its first piece *ends* on: the
#     reference pushes the token after the scan loop has already counted
#     any backslash-newline continuations, and the raw-newline split ends a
#     piece at the first raw newline.
#
# Deliberate deviation: line numbers after a `@MARK` text block. The
# reference rewrites the block to `sprintf("%O", content) + rest + "\n" *
# nlines` on the opening line. Pike's `%O` spells a multi-line string as one
# literal *per source line*, separated by newlines, which adds lines, so
# every token after a single-`@` block reports a line number too high by
# (content newlines - 1) for the rest of the file. That's a reference bug,
# visible in its error messages. Here the block's string token takes the
# `@` line and everything after the closing marker keeps its real line.
# `tests/run_tokdump_test.ps1` compares files containing text blocks with
# line numbers ignored (and only those), so their tokens are still checked.

import "token.star" as tk

extern "C" fn atof(s: str) -> f64

struct OpEntry:
    a: i32
    b: i32
    c: i32
    n: i32
    text: str

# Operators, longest first within each leading character -- the same order
# as the reference's `OPS` table, so the first match wins identically.
fn op_table() -> List<List<OpEntry>>:
    let ops: List<str> = ["...", "<<=", ">>=",
        "->", "::", "++", "--", "+=", "-=", "*=", "/=", "%=", "&=", "|=", "^=",
        "&&", "||", "==", "!=", "<=", ">=", "<<", ">>", "..",
        "({", "([", "(:", ":)",
        "+", "-", "*", "/", "%", "&", "|", "^", "~", "!", "<", ">", "=",
        "?", ":", ";", ",", ".", "(", ")", "[", "]", "{", "}", "#", "@"]
    let mut by_char: List<List<OpEntry>> = List<List<OpEntry>>()
    for i in 0..256:
        by_char.push(List<OpEntry>())
    for i in 0..ops.len():
        let b = bytes_from_str(ops[i])
        let n = b.len()
        let a = b[0] as i32
        let e = OpEntry(a = a, b = if n > 1: b[1] as i32 else: -1, c = if n > 2: b[2] as i32 else: -1, n = n, text = ops[i])
        by_char[a].push(e)
    by_char

fn is_id_start(c: i32) -> bool:
    (c >= 97 and c <= 122) or (c >= 65 and c <= 90) or c == 95

fn is_id_char(c: i32) -> bool:
    (c >= 97 and c <= 122) or (c >= 65 and c <= 90) or c == 95 or (c >= 48 and c <= 57)

fn is_digit(c: i32) -> bool:
    c >= 48 and c <= 57

fn hex_val(c: i32) -> i32:
    if c >= 48 and c <= 57:
        c - 48
    elif c >= 97 and c <= 102:
        c - 87
    elif c >= 65 and c <= 70:
        c - 55
    else:
        -1

# `\r\n` and lone `\r` both become `\n` (the reference's `norm`).
fn normalize_newlines(raw: Bytes) -> Bytes:
    let mut out: Bytes = Bytes()
    let n = raw.len()
    let mut i = 0
    while i < n:
        let c = raw[i] as i32
        if c == 13:
            out.push(10 as u8)
            if i + 1 < n and (raw[i + 1] as i32) == 10:
                i += 1
        else:
            out.push(raw[i])
        i += 1
    out

struct Lexer:
    src: Bytes
    n: i32
    file: i32
    ops: List<List<OpEntry>>
    # false when re-lexing a directive's own body (`#define F(x) #x` must
    # not treat that `#` as starting another directive)
    mut directives: bool = true
    mut pos: i32 = 0
    mut line: i32 = 1
    mut bol: bool = true
    mut space: bool = false

    mut toks: List<tk::Token> = List<tk::Token>()

fn new_lexer(src: Bytes, file: i32, ops: List<List<OpEntry>>) -> Lexer:
    Lexer(src = src, n = src.len(), file = file, ops = ops)

impl Lexer:
    fn at(self, i: i32) -> i32:
        if i >= 0 and i < self.n:
            self.src[i] as i32
        else:
            -1

    fn slice(self, a: i32, b: i32) -> str:
        let mut w: Bytes = Bytes()
        let mut i = a
        while i < b:
            w.push(self.src[i])
            i += 1
        str_from_bytes(w)

    fn emit(mut self, kind: tk::Tk, text: str, line: i32):
        self.toks.push(tk::Token(kind = kind, text = text, line = line, file = self.file, bol = self.bol, space = self.space))
        self.bol = false
        self.space = false

    fn emit_int(mut self, v: i64):
        self.toks.push(tk::Token(kind = tk::Tk::Int, ival = v, line = self.line, file = self.file, bol = self.bol, space = self.space))
        self.bol = false
        self.space = false

    fn newline(mut self):
        self.line += 1
        self.bol = true
        self.space = false

    # Decode one escape sequence whose first character (after the
    # backslash) is at `i`. Returns `[char_code, index_past_escape]`, the
    # reference's `({ char_code, new_index })`.
    fn decode_escape(self, i: i32) -> List<i32>:
        let c = self.at(i)
        if c == 110:
            return [10, i + 1]
        if c == 116:
            return [9, i + 1]
        if c == 114:
            return [13, i + 1]
        if c == 97:
            return [7, i + 1]
        if c == 98:
            return [8, i + 1]
        if c == 101:
            return [27, i + 1]
        if c == 102:
            return [12, i + 1]
        if c == 118:
            return [11, i + 1]
        if c == 120:
            let mut v = 0
            let mut j = i + 1
            let mut k = 0
            while j < self.n and k < 2:
                let d = hex_val(self.at(j))
                if d < 0:
                    break
                v = v * 16 + d
                j += 1
                k += 1
            return [v, j]
        if c >= 48 and c <= 55:
            let mut v = 0
            let mut j = i
            let mut k = 0
            while j < self.n and k < 3 and self.at(j) >= 48 and self.at(j) <= 55:
                v = v * 8 + self.at(j) - 48
                j += 1
                k += 1
            return [v, j]
        # \\ \" \' and unknown escapes yield the character itself
        [c, i + 1]

    # `#...` at the start of a line: capture the whole logical line
    # (continuations joined, comments dropped, string/char literals copied
    # verbatim so a `//` inside one isn't taken for a comment).
    fn scan_directive(mut self):
        let start_line = self.line
        let mut w: Bytes = Bytes()
        let mut i = self.pos + 1
        while i < self.n:
            let c = self.at(i)
            if c == 10:
                break
            if c == 92 and self.at(i + 1) == 10:
                self.line += 1
                i += 2
                continue
            if c == 47 and self.at(i + 1) == 47:
                while i < self.n and self.at(i) != 10:
                    i += 1
                break
            if c == 47 and self.at(i + 1) == 42:
                i += 2
                while i < self.n and !(self.at(i) == 42 and self.at(i + 1) == 47):
                    if self.at(i) == 10:
                        self.line += 1
                    i += 1
                i += 2
                w.push(32 as u8)
                continue
            if c == 34 or c == 39:
                w.push(self.src[i])
                i += 1
                while i < self.n and self.at(i) != c and self.at(i) != 10:
                    if self.at(i) == 92 and i + 1 < self.n and self.at(i + 1) != 10:
                        w.push(self.src[i])
                        i += 1
                    w.push(self.src[i])
                    i += 1
                if self.at(i) == c:
                    w.push(self.src[i])
                    i += 1
                continue
            w.push(self.src[i])
            i += 1
        self.pos = i
        self.emit(tk::Tk::Directive, str_from_bytes(w), start_line)

    # `@MARK\n ... \nMARK rest` / `@@MARK ...` (the reference's
    # `try_heredoc`). Returns false (consuming nothing) if this `@` doesn't
    # open a text block, so the caller lexes it as the `@` operator.
    fn try_heredoc(mut self) -> bool:
        let at_pos = self.pos
        let arr = self.at(at_pos + 1) == 64
        let s = if arr: at_pos + 2 else: at_pos + 1
        let mut e = s
        while e < self.n and is_id_char(self.at(e)):
            e += 1
        if e == s or e >= self.n or self.at(e) != 10:
            return false
        let mlen = e - s
        let body = e + 1
        let mut scan = body
        let mut end = -1
        while scan < self.n:
            let mut matched = scan + mlen <= self.n
            let mut k = 0
            while matched and k < mlen:
                if self.at(scan + k) != self.at(s + k):
                    matched = false
                k += 1
            if matched and (scan + mlen >= self.n or !is_id_char(self.at(scan + mlen))):
                end = scan
                break
            while scan < self.n and self.at(scan) != 10:
                scan += 1
            if scan >= self.n:
                break
            scan += 1
        if end < 0:
            return false
        # content = src[body .. end); count its lines the way Pike's
        # `sizeof(content / "\n")` does (pieces = newlines + 1).
        let mut nlines = 1
        let mut i = body
        while i < end:
            if self.at(i) == 10:
                nlines += 1
            i += 1
        let line = self.line
        if arr:
            self.emit(tk::Tk::Op, "({", line)
            let mut pieces: List<str> = List<str>()
            let mut ls = body
            i = body
            while i < end:
                if self.at(i) == 10:
                    pieces.push(self.slice(ls, i))
                    ls = i + 1
                i += 1
            if ls < end:
                pieces.push(self.slice(ls, end))
            for p in 0..pieces.len():
                if p > 0:
                    self.emit(tk::Tk::Op, ",", line)
                self.emit(tk::Tk::Str, pieces[p], line)
            # the reference rewrites to text "({...})", which lexes as
            # `({` ... `}` `)` -- there is no `})` operator
            self.emit(tk::Tk::Op, "}", line)
            self.emit(tk::Tk::Op, ")", line)
        else:
            self.emit(tk::Tk::Str, self.slice(body, end), line)
        self.pos = end + mlen
        # the `@MARK` line's newline plus the content's own (see the header
        # comment's "Deliberate deviation" note)
        self.line += nlines
        true

    fn scan_number(mut self):
        let i = self.pos
        let c = self.at(i)
        let mut j = i
        if c == 48 and (self.at(j + 1) == 120 or self.at(j + 1) == 88):
            j += 2
            let mut v = 0 as i64
            while j < self.n:
                let d = hex_val(self.at(j))
                if d < 0:
                    break
                v = v * (16 as i64) + (d as i64)
                j += 1
            self.emit_int(v)
            self.pos = j
            return
        if c == 48 and (self.at(j + 1) == 98 or self.at(j + 1) == 66) and (self.at(j + 2) == 48 or self.at(j + 2) == 49):
            j += 2
            let mut v = 0 as i64
            while j < self.n and (self.at(j) == 48 or self.at(j) == 49):
                v = v * (2 as i64) + ((self.at(j) - 48) as i64)
                j += 1
            self.emit_int(v)
            self.pos = j
            return
        while j < self.n and (is_digit(self.at(j)) or self.at(j) == 95):
            j += 1
        let mut is_float = false
        # a '.' followed by another '.' is a range operator, not a decimal point
        if self.at(j) == 46 and self.at(j + 1) != 46:
            is_float = true
            j += 1
            while j < self.n and is_digit(self.at(j)):
                j += 1
        if self.at(j) == 101 or self.at(j) == 69:
            let mut k = j + 1
            if self.at(k) == 43 or self.at(k) == 45:
                k += 1
            if is_digit(self.at(k)):
                is_float = true
                j = k
                while j < self.n and is_digit(self.at(j)):
                    j += 1
        let mut w: Bytes = Bytes()
        let mut v = 0 as i64
        let mut p = i
        while p < j:
            let d = self.at(p)
            if d != 95:
                w.push(self.src[p])
                if !is_float:
                    v = v * (10 as i64) + ((d - 48) as i64)
            p += 1
        if is_float:
            let text = str_from_bytes(w)
            self.toks.push(tk::Token(kind = tk::Tk::Float, text = text, fval = atof(text), line = self.line, file = self.file, bol = self.bol, space = self.space))
            self.bol = false
            self.space = false
        else:
            self.emit_int(v)
        self.pos = j

    fn scan_string(mut self):
        let mut w: Bytes = Bytes()
        let mut j = self.pos + 1
        let mut tok_line = -1
        while j < self.n and self.at(j) != 34:
            let d = self.at(j)
            if d == 92 and j + 1 < self.n:
                if self.at(j + 1) == 10:
                    self.line += 1
                    j += 2
                    continue
                let r = self.decode_escape(j + 1)
                w.push(r[0] as u8)
                j = r[1]
                continue
            if d == 10:
                if tok_line < 0:
                    tok_line = self.line
                self.line += 1
            w.push(self.src[j])
            j += 1
        if j >= self.n:
            self.emit(tk::Tk::Bad, "Unterminated string", self.line)
            self.pos = j
            return
        if tok_line < 0:
            tok_line = self.line
        self.emit(tk::Tk::Str, str_from_bytes(w), tok_line)
        self.pos = j + 1

    fn scan_char(mut self):
        let i = self.pos
        let mut v = 0
        let mut j = i + 1
        if self.at(i + 1) == 92:
            let r = self.decode_escape(i + 2)
            v = r[0]
            j = r[1]
        elif i + 1 < self.n:
            v = self.at(i + 1)
            j = i + 2
        if self.at(j) == 39:
            self.emit_int(v as i64)
            self.pos = j + 1
            return
        self.emit(tk::Tk::Bad, "Bad character constant", self.line)
        self.pos = i + 1

    fn scan_op(mut self, c: i32) -> bool:
        let cands = self.ops[c]
        for k in 0..cands.len():
            let e = cands[k]
            let mut ok = true
            if e.n > 1 and self.at(self.pos + 1) != e.b:
                ok = false
            if ok and e.n > 2 and self.at(self.pos + 2) != e.c:
                ok = false
            if ok:
                # "(::" is "(" followed by "::", not a functional opener
                if e.text == "(:" and self.at(self.pos + 2) == 58:
                    self.emit(tk::Tk::Op, "(", self.line)
                    self.pos += 1
                    return true
                self.emit(tk::Tk::Op, e.text, self.line)
                self.pos += e.n
                return true
        false

    fn run(mut self):
        while self.pos < self.n:
            let c = self.at(self.pos)
            if c == 10:
                self.newline()
                self.pos += 1
                continue
            if c == 32 or c == 9 or c == 12 or c == 11:
                self.space = true
                self.pos += 1
                continue
            if c == 92 and self.at(self.pos + 1) == 10:
                self.line += 1
                self.space = true
                self.pos += 2
                continue
            if c == 35 and self.bol and self.directives:
                self.scan_directive()
                continue
            if c == 47 and self.at(self.pos + 1) == 47:
                while self.pos < self.n and self.at(self.pos) != 10:
                    self.pos += 1
                self.space = true
                continue
            if c == 47 and self.at(self.pos + 1) == 42:
                let mut i = self.pos + 2
                while i < self.n and !(self.at(i) == 42 and self.at(i + 1) == 47):
                    if self.at(i) == 10:
                        self.line += 1
                    i += 1
                self.pos = if i < self.n: i + 2 else: self.n
                self.space = true
                continue
            if is_id_start(c):
                let mut j = self.pos + 1
                while j < self.n and is_id_char(self.at(j)):
                    j += 1
                self.emit(tk::Tk::Id, self.slice(self.pos, j), self.line)
                self.pos = j
                continue
            if is_digit(c) or (c == 46 and is_digit(self.at(self.pos + 1)) and self.at(self.pos - 1) != 46):
                self.scan_number()
                continue
            if c == 34:
                self.scan_string()
                continue
            if c == 39:
                self.scan_char()
                continue
            if c == 36:
                let mut j = self.pos + 1
                if is_digit(self.at(j)):
                    let mut v = 0 as i64
                    while j < self.n and is_digit(self.at(j)):
                        v = v * (10 as i64) + ((self.at(j) - 48) as i64)
                        j += 1
                    self.toks.push(tk::Token(kind = tk::Tk::Dollar, ival = v, line = self.line, file = self.file, bol = self.bol, space = self.space))
                    self.bol = false
                    self.space = false
                    self.pos = j
                    continue
                if self.at(j) == 40:
                    self.toks.push(tk::Token(kind = tk::Tk::Dollar, ival = 0 as i64, line = self.line, file = self.file, bol = self.bol, space = self.space))
                    self.bol = false
                    self.space = false
                    self.pos = j + 1
                    continue
                self.emit(tk::Tk::Bad, "Bad $ token", self.line)
                self.pos += 1
                continue
            if c == 64 and self.directives and self.try_heredoc():
                continue
            if c < 256 and self.scan_op(c):
                continue
            self.emit(tk::Tk::Bad, concat("Unexpected character ", chr(c)), self.line)
            self.pos += 1

# Lex a whole source file (raw bytes as read from disk).
fn lex_file(raw: Bytes, file: i32, ops: List<List<OpEntry>>) -> List<tk::Token>:
    let mut lx = new_lexer(normalize_newlines(raw), file, ops)
    lx.run()
    # carries the final line count: the reference's eof token reports the
    # line counter at end of text, not the last token's line
    lx.toks.push(tk::Token(kind = tk::Tk::Eof, line = lx.line, file = file))
    lx.toks

# Lex a directive fragment (a `#define` body, an `#if` expression): no
# directive or text-block recognition, every token stamped with `line`.
fn lex_fragment(text: str, file: i32, line: i32, ops: List<List<OpEntry>>) -> List<tk::Token>:
    let mut lx = new_lexer(bytes_from_str(text), file, ops)
    lx.directives = false
    lx.bol = false
    lx.line = line
    lx.run()
    lx.toks

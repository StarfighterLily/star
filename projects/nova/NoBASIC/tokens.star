# NoBASIC lexer tokens -- ported from the reference Python
# `compiler/lexer/tokens.py` (`c:\Code\projects\Nova\NoBASIC\compiler\lexer\
# tokens.py`), todo.md P0 #1. `TokenType` mirrors the reference `TokenType`
# enum variant-for-variant (grouped the same way: keywords, built-in
# functions, operators, delimiters, literals, special) so the two stay easy
# to eyeball-compare during the rest of this port.
#
# Reference/implementation drift found here (see todo.md's "Current focus"
# note): the reference `KEYWORDS` dict registers only the ~40 core
# statement/control-flow keywords below. The ~20 "built-in function"
# variants (`Sin`/`Cos`/`Sqrt`/...) are declared on `TokenType` but never
# wired into `KEYWORDS` by the reference lexer itself -- so `SIN`, `COS`,
# etc. actually lex as plain `Identifier` tokens in the live Python
# implementation, not as their own token kind. Kept as real variants here
# for parity with the reference enum (a later phase may still want them
# distinguishable), but `keyword_lookup` below deliberately does NOT map
# them, matching what the reference lexer actually does rather than what
# its own type declaration implies.
#
# Token literal representation: the reference `Token.literal: Optional[Any]`
# holds either a Python `int`/`float` (for `NUMBER_LITERAL`) or a `str` (for
# `STRING_LITERAL`/`ASM_BLOCK`). Star has no `Any`/union type, so `Token`
# below carries both a numeric and a string literal field side by side --
# only the one matching `kind` is ever populated, the same "flat struct
# with an unused-for-this-variant default" shape `assembler.star`'s
# `AsmLine` already uses for its own directive-vs-instruction split.
#
# Gotcha (not a bug, just non-obvious): `num_value`'s default below is
# written `0 as f64`, not a bare `0.0`. Star's numeric-literal defaults
# only ever infer as `i32`/`f32` -- any extended-width field (`f64`/`i64`/
# `u8`/`u16`/`u32`) needs its own literal explicitly cast to match, the
# same as any other use of one of those types in this codebase (`0 as
# u16`, etc., throughout `cpu.star`). Confirmed empirically: an *explicit*
# `Token(num_value = 0.0)` at a call site fails the exact same way a
# defaulted/omitted one does, so this isn't a default-filling-specific
# gap -- omitting the cast on a struct field of one of these types simply
# never works, default value or not.
#
# Known limitation carried over from this representation, not from the
# reference: a NoBASIC string literal containing a `\0` escape (the
# reference's `_STRING_ESCAPES` table maps `\0` to a real NUL byte) would
# embed a NUL in `Token.str_value`. Star strings are null-terminated
# underneath (see `docs/language_reference.md`'s C-interop/`extern "C"`
# notes), so a NUL byte inside one is likely to truncate anywhere the
# string later crosses that boundary. Not fixed here since no checked-in
# `.nobasic` source uses `\0`; flagged for whoever first needs it for real.

enum TokenType:
    # Keywords
    Clrdraw
    Pxloff
    Pxlon
    Line
    Circle
    Text
    Setlayer
    Scrroll
    Scrrotate
    Scrshift
    Scrflip
    Spriteon
    Spriteoff
    Playtone
    Playwave
    Stopsound
    Setchannel
    Getkey
    Input
    Disp
    Pause
    Serout
    Serin
    Serstat
    Serctrl
    If
    Then
    Else
    End
    For
    To
    Step
    Next
    While
    Repeat
    Until
    Goto
    Dim
    Let
    Struct
    Global
    Local
    Asm
    Function
    Return

    # Built-in functions -- see header comment: NOT reachable via
    # `keyword_lookup` today, matching the reference lexer's own behavior.
    Sin
    Cos
    Tan
    Sqrt
    Abs
    Int
    Round
    Rand
    Rndr
    Randomize
    Length
    Sub
    Concat
    Sum
    Mean
    Memread
    Memwrite
    Instring
    Upstring
    Lowstring
    Lenstring

    # Operators
    Plus
    Minus
    Multiply
    Divide
    Power
    Equal
    NotEqual
    Less
    LessEqual
    Greater
    GreaterEqual
    BitwiseAnd
    BitwiseOr
    ShiftLeft
    ShiftRight
    And
    Or
    Not
    Increment
    Decrement

    # Delimiters
    Lparen
    Rparen
    Lbracket
    Rbracket
    Comma
    Quote
    Colon
    At
    Dot

    # Literals
    NumberLiteral
    StringLiteral
    Identifier
    AsmBlock

    # Special
    Eof
    Comment
    Whitespace

# A lexed token. `lexeme` is always the exact original source slice (case
# preserved), matching the reference's own `add_token` -- keyword matching
# is case-insensitive, but the lexeme itself is not lower-cased.
#
# `num_value`/`is_float` are populated only when `kind == NumberLiteral`
# (`is_float` mirrors the reference distinguishing a Python `int` literal
# from a `float` one -- i.e. whether the source had a decimal point).
# `str_value` is populated only when `kind == StringLiteral` (the escaped
# string contents) or `kind == AsmBlock` (the raw captured assembly text).
struct Token:
    kind: TokenType
    lexeme: str = ""
    num_value: f64 = 0 as f64
    is_float: bool = false
    str_value: str = ""
    line: i32 = 0
    column: i32 = 0

# Transcribed from the reference `KEYWORDS` dict. Deliberately excludes the
# built-in-function `TokenType` variants -- see this file's header comment.
fn build_keywords() -> Map<str, TokenType>:
    let mut k: Map<str, TokenType> = Map<str, TokenType>()
    k.insert("clrdraw", TokenType::Clrdraw)
    k.insert("pxloff", TokenType::Pxloff)
    k.insert("pxlon", TokenType::Pxlon)
    k.insert("line", TokenType::Line)
    k.insert("circle", TokenType::Circle)
    k.insert("text", TokenType::Text)
    k.insert("setlayer", TokenType::Setlayer)
    k.insert("scrroll", TokenType::Scrroll)
    k.insert("scrrotate", TokenType::Scrrotate)
    k.insert("scrshift", TokenType::Scrshift)
    k.insert("scrflip", TokenType::Scrflip)
    k.insert("spriteon", TokenType::Spriteon)
    k.insert("spriteoff", TokenType::Spriteoff)
    k.insert("playtone", TokenType::Playtone)
    k.insert("playwave", TokenType::Playwave)
    k.insert("stopsound", TokenType::Stopsound)
    k.insert("setchannel", TokenType::Setchannel)
    k.insert("getkey", TokenType::Getkey)
    k.insert("serout", TokenType::Serout)
    k.insert("serin", TokenType::Serin)
    k.insert("serstat", TokenType::Serstat)
    k.insert("serctrl", TokenType::Serctrl)
    k.insert("input", TokenType::Input)
    k.insert("disp", TokenType::Disp)
    k.insert("pause", TokenType::Pause)
    k.insert("if", TokenType::If)
    k.insert("then", TokenType::Then)
    k.insert("else", TokenType::Else)
    k.insert("end", TokenType::End)
    k.insert("for", TokenType::For)
    k.insert("to", TokenType::To)
    k.insert("step", TokenType::Step)
    k.insert("next", TokenType::Next)
    k.insert("while", TokenType::While)
    k.insert("repeat", TokenType::Repeat)
    k.insert("until", TokenType::Until)
    k.insert("goto", TokenType::Goto)
    k.insert("dim", TokenType::Dim)
    k.insert("let", TokenType::Let)
    k.insert("struct", TokenType::Struct)
    k.insert("global", TokenType::Global)
    k.insert("local", TokenType::Local)
    k.insert("asm", TokenType::Asm)
    k.insert("function", TokenType::Function)
    k.insert("return", TokenType::Return)
    k.insert("and", TokenType::And)
    k.insert("or", TokenType::Or)
    k.insert("not", TokenType::Not)
    k

# `word` must already be lower-cased by the caller (matches the reference's
# own `text.lower()` before the dict lookup). Returns `Identifier` for
# anything not in the table, same as `KEYWORDS.get(text, TokenType.IDENTIFIER)`.
fn keyword_lookup(keywords: Map<str, TokenType>, word: str) -> TokenType:
    match keywords.get(word):
        Option::Some(t) -> t
        Option::None -> TokenType::Identifier

# Transcribed from the reference `SINGLE_CHAR_TOKENS` dict, keyed by byte
# value instead of a 1-character string (Star has no character type; see
# `assembler.star`'s own byte-indexed string helpers for the established
# idiom this follows).
fn single_char_token(c: i32) -> Option<TokenType>:
    match c:
        43 -> Option<TokenType>::Some(TokenType::Plus)         # '+'
        45 -> Option<TokenType>::Some(TokenType::Minus)        # '-'
        42 -> Option<TokenType>::Some(TokenType::Multiply)     # '*'
        47 -> Option<TokenType>::Some(TokenType::Divide)       # '/'
        94 -> Option<TokenType>::Some(TokenType::Power)        # '^'
        61 -> Option<TokenType>::Some(TokenType::Equal)        # '='
        60 -> Option<TokenType>::Some(TokenType::Less)         # '<'
        62 -> Option<TokenType>::Some(TokenType::Greater)      # '>'
        40 -> Option<TokenType>::Some(TokenType::Lparen)       # '('
        41 -> Option<TokenType>::Some(TokenType::Rparen)       # ')'
        91 -> Option<TokenType>::Some(TokenType::Lbracket)     # '['
        93 -> Option<TokenType>::Some(TokenType::Rbracket)     # ']'
        44 -> Option<TokenType>::Some(TokenType::Comma)        # ','
        34 -> Option<TokenType>::Some(TokenType::Quote)        # '"'
        58 -> Option<TokenType>::Some(TokenType::Colon)        # ':'
        64 -> Option<TokenType>::Some(TokenType::At)           # '@'
        46 -> Option<TokenType>::Some(TokenType::Dot)          # '.'
        38 -> Option<TokenType>::Some(TokenType::BitwiseAnd)   # '&'
        124 -> Option<TokenType>::Some(TokenType::BitwiseOr)   # '|'
        _ -> Option<TokenType>::None

# Human-readable token-kind name, used only by `tests/lexer_dump.star`'s
# fixture-comparison output (mirrors the reference `TokenType.value` string
# so a dump can be diffed directly against a Python-generated fixture).
fn token_type_name(t: TokenType) -> str:
    match t:
        TokenType::Clrdraw -> "CLRDRAW"
        TokenType::Pxloff -> "PXLOFF"
        TokenType::Pxlon -> "PXLON"
        TokenType::Line -> "LINE"
        TokenType::Circle -> "CIRCLE"
        TokenType::Text -> "TEXT"
        TokenType::Setlayer -> "SETLAYER"
        TokenType::Scrroll -> "SCRROLL"
        TokenType::Scrrotate -> "SCRROTATE"
        TokenType::Scrshift -> "SCRSHIFT"
        TokenType::Scrflip -> "SCRFLIP"
        TokenType::Spriteon -> "SPRITEON"
        TokenType::Spriteoff -> "SPRITEOFF"
        TokenType::Playtone -> "PLAYTONE"
        TokenType::Playwave -> "PLAYWAVE"
        TokenType::Stopsound -> "STOPSOUND"
        TokenType::Setchannel -> "SETCHANNEL"
        TokenType::Getkey -> "GETKEY"
        TokenType::Input -> "INPUT"
        TokenType::Disp -> "DISP"
        TokenType::Pause -> "PAUSE"
        TokenType::Serout -> "SEROUT"
        TokenType::Serin -> "SERIN"
        TokenType::Serstat -> "SERSTAT"
        TokenType::Serctrl -> "SERCTRL"
        TokenType::If -> "IF"
        TokenType::Then -> "THEN"
        TokenType::Else -> "ELSE"
        TokenType::End -> "END"
        TokenType::For -> "FOR"
        TokenType::To -> "TO"
        TokenType::Step -> "STEP"
        TokenType::Next -> "NEXT"
        TokenType::While -> "WHILE"
        TokenType::Repeat -> "REPEAT"
        TokenType::Until -> "UNTIL"
        TokenType::Goto -> "GOTO"
        TokenType::Dim -> "DIM"
        TokenType::Let -> "LET"
        TokenType::Struct -> "STRUCT"
        TokenType::Global -> "GLOBAL"
        TokenType::Local -> "LOCAL"
        TokenType::Asm -> "ASM"
        TokenType::Function -> "FUNCTION"
        TokenType::Return -> "RETURN"
        TokenType::Sin -> "SIN"
        TokenType::Cos -> "COS"
        TokenType::Tan -> "TAN"
        TokenType::Sqrt -> "SQRT"
        TokenType::Abs -> "ABS"
        TokenType::Int -> "INT"
        TokenType::Round -> "ROUND"
        TokenType::Rand -> "RAND"
        TokenType::Rndr -> "RNDR"
        TokenType::Randomize -> "RANDOMIZE"
        TokenType::Length -> "LENGTH"
        TokenType::Sub -> "SUB"
        TokenType::Concat -> "CONCAT"
        TokenType::Sum -> "SUM"
        TokenType::Mean -> "MEAN"
        TokenType::Memread -> "MEMREAD"
        TokenType::Memwrite -> "MEMWRITE"
        TokenType::Instring -> "INSTRING"
        TokenType::Upstring -> "UPSTRING"
        TokenType::Lowstring -> "LOWSTRING"
        TokenType::Lenstring -> "LENSTRING"
        TokenType::Plus -> "+"
        TokenType::Minus -> "-"
        TokenType::Multiply -> "*"
        TokenType::Divide -> "/"
        TokenType::Power -> "^"
        TokenType::Equal -> "="
        TokenType::NotEqual -> "<>"
        TokenType::Less -> "<"
        TokenType::LessEqual -> "<="
        TokenType::Greater -> ">"
        TokenType::GreaterEqual -> ">="
        TokenType::BitwiseAnd -> "&"
        TokenType::BitwiseOr -> "|"
        TokenType::ShiftLeft -> "<<"
        TokenType::ShiftRight -> ">>"
        TokenType::And -> "AND"
        TokenType::Or -> "OR"
        TokenType::Not -> "NOT"
        TokenType::Increment -> "++"
        TokenType::Decrement -> "--"
        TokenType::Lparen -> "("
        TokenType::Rparen -> ")"
        TokenType::Lbracket -> "["
        TokenType::Rbracket -> "]"
        TokenType::Comma -> ","
        TokenType::Quote -> "\""
        TokenType::Colon -> ":"
        TokenType::At -> "@"
        TokenType::Dot -> "."
        TokenType::NumberLiteral -> "NUMBER_LITERAL"
        TokenType::StringLiteral -> "STRING_LITERAL"
        TokenType::Identifier -> "IDENTIFIER"
        TokenType::AsmBlock -> "ASM_BLOCK"
        TokenType::Eof -> "EOF"
        TokenType::Comment -> "COMMENT"
        TokenType::Whitespace -> "WHITESPACE"

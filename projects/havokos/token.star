# LPC tokens -- the Star counterpart of `lpc/lexer.pike`'s token arrays
# (`({ kind, value, line, file })`), todo.md HavokOS M1.
#
# The reference token is a 4-element Pike array whose `value` slot holds
# whatever type suits the kind (identifier/operator text, decoded string, an
# int, a float). Star has no union type, so `Token` is a flat struct with a
# slot per payload shape and only the one matching `kind` populated -- the
# same shape `projects/nova/NoBASIC/tokens.star` settled on for the same
# reason.
#
# Two kinds exist here that the reference lexer never produces, because the
# reference lexes *after* Pike's built-in `cpp()` has already run, while this
# port lexes first and preprocesses the token stream (see `preprocess.star`'s
# header for why):
#   - `Directive`: one whole `#...` preprocessor line (continuations joined,
#     comments stripped), `text` = everything after the `#`. The preprocessor
#     re-lexes the parts it needs (a `#define` body, an `#if` expression).
#   - `Bad`: a lexical error, reported in-band (`text` = message) instead of
#     aborting the file. The reference never lexes text inside a skipped
#     `#if 0` block at all (cpp drops it first), so an apostrophe or stray
#     byte in there must not fail the file here either -- the preprocessor
#     only reports a `Bad` token that survives into live output.
#
# `bol` (first token on its source line) is how the preprocessor finds
# directives and is otherwise unused; `space` (whitespace/comment before
# this token) is what tells a function-like macro *definition* `F(x)` from an
# object-like `F (x)`.

enum Tk:
    Id
    Int
    Float
    Str
    Op
    Dollar
    Directive
    Bad
    Eof

struct Token:
    kind: Tk
    text: str = ""
    ival: i64 = 0 as i64
    fval: f64 = 0 as f64
    line: i32 = 0
    file: i32 = 0
    bol: bool = false
    space: bool = false

fn tk_name(k: Tk) -> str:
    match k:
        Tk::Id -> "id"
        Tk::Int -> "int"
        Tk::Float -> "float"
        Tk::Str -> "str"
        Tk::Op -> "op"
        Tk::Dollar -> "dollar"
        Tk::Directive -> "directive"
        Tk::Bad -> "bad"
        Tk::Eof -> "eof"

fn is_op(t: Token, text: str) -> bool:
    t.kind == Tk::Op and t.text == text

fn is_id(t: Token, text: str) -> bool:
    t.kind == Tk::Id and t.text == text

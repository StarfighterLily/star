# Exercises two related bugs fixed together (see todo.md's "Immediate"
# section, item 3 -- previously pre-existing, unrelated follow-ups from the
# §3.6 RC work):
#
# 1. A function returning a freshly-constructed `str` (a bare literal, or a
#    `concat` result) used to return the address of an `alloca` inside its
#    own dead stack frame -- the `Str` "box" indirection every `Str` value's
#    `emit_expr` result pointed through was always stack-allocated. Fixed by
#    removing the box entirely: a `Str` value is now just the raw `i8*`
#    bytes pointer directly, like every other type.
# 2. `println`/`print` with a non-f-string argument that isn't a plain
#    `Ident`/`Field` (a `List` index, a closure call) used to produce
#    malformed IR clang rejected, because the argument's tagged
#    `emit_expr` result was never stripped of its type tag before use.

fn fresh_literal() -> str:
    "fresh literal return"

fn fresh_concat(a: str, b: str) -> str:
    concat(a, b)

fn main():
    println(fresh_literal())
    println(fresh_concat("fresh ", "concat return"))

    let words: List<str> = ["alpha", "beta", "gamma"]
    println(words[1])

    let make_greeting = fn() -> str: concat("hello ", "from a closure call")
    println(make_greeting())

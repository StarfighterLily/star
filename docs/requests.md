# Requests — Language Niceties

Small quality-of-life features for Star, as opposed to `docs/features.md`'s
speculative game-engine-scale ideas (`swarm`, `sequence`, native SIMD types,
hot-reload reflection). Nothing here unblocks any current `todo.md` item or
fixes a bug — these are things that would make the language more pleasant
to write in, worth scoping if a slow cycle comes up. Each entry below was
checked against the current lexer/parser (`src/lexer.rs`, `src/parser/`) to
confirm it's an actual gap, not already-supported syntax.

## 1. Multi-line (block) comments

Today `src/lexer.rs` only recognizes `#`-prefixed line comments (see
`docs/language_reference.md`'s "Comments" section) — there's no way to
comment out a multi-line block without prefixing every line with `#`.
Worth a block-comment delimiter pair (something that doesn't collide with
`#` line comments or f-string braces — e.g. `#* ... *#`) that nests or at
least balances correctly around commented-out code containing its own `#`
line comments.

## 2. Digit separators in numeric literals

`Lexer::scan_number` (`src/lexer.rs:495`) only accepts `is_ascii_digit()`
runs — no `_` is allowed inside a numeric literal, so a constant like
`1000000` can't be written as `1_000_000` for readability. Rust and most
modern languages allow this purely as a lexer-level nicety (strip
underscores before parsing); no type-system or codegen change implied.

## 3. `if let` / `while let` pattern binding

There's no shorthand for "match one pattern, fall through otherwise" —
today unwrapping an `Option`/`Result` outside of `?`-propagation
(`docs/language_reference.md`'s "`?`-propagation" section) requires a full
`match` with an explicit wildcard arm even when only one variant is
interesting. `if let Some(x) = opt: ... else: ...` and a `while let`
loop-until-`None`/`Err` form would cover the common case without adding a
new pattern-matching engine — it'd desugar to the existing `match`.

## 4. Inclusive and stepped ranges in `for` loops

`parse_for_stmt` (`src/parser/stmt.rs:499`) hardcodes `<start>..<end>` as
an exclusive, ascending, step-1 range — the `DotDot` token has no `..=`
sibling and no `step` clause. Worth scoping: an inclusive `..=` operator
(`for i in 0..=10:`) and a way to iterate descending or by a stride other
than 1 (`for i in 10..0 step -1:` or similar), rather than the current
workaround of a `while` loop with manual increment/decrement.

## 5. Multi-line string literals

The lexer has no raw or triple-quoted string form (checked for
`TripleStr`/`RawStr`-shaped handling — there isn't one) — only single-line
`"..."` and f-string literals. Embedding a multi-line block of text (shader
source, help text, dialogue) currently means concatenation or an external
asset file. A `"""..."""` (or similar) literal that spans lines without
requiring escaped newlines would close this gap.

## 6. Default parameter values in function definitions

`parse_param` (`src/parser/items.rs:432`) has no default-value slot on
`Param` — call sites already support named arguments (`f(x = 1)`, reusing
`parse_call_args`'s `name = expr` shorthand, see `src/parser/expr.rs:642`),
but a function signature has no way to declare a default so that omitting
the argument is legal. `fn f(x: i32 = 0):` plus "omitted named/trailing
positional args fall back to their default" would make the existing named-
argument syntax actually useful for optional parameters instead of just
reordering required ones.

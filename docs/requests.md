# Requests — Language Niceties

Small quality-of-life features for Star, as opposed to `docs/features.md`'s
speculative game-engine-scale ideas (`swarm`, `sequence`, native SIMD types,
hot-reload reflection). Nothing here unblocked any current `todo.md` item or
fixed a bug — these were things that would make the language more pleasant
to write in. All six were implemented in one pass; see each entry's "Done."
note for the mechanism and the test file that covers it.

## 1. Multi-line (block) comments

**Done.** `#* ... *#` (`src/lexer.rs`'s `Lexer::skip_block_comment`), called
from both `scan_line_content` (mid-line) and `handle_line_start` (a comment
opening a logical line, which needs its own follow-up logic to decide
whether that line counts as blank or has real code trailing the close).
Balances/nests (an inner `#*` bumps a depth counter; only the matching
outer `*#` closes it) and may span multiple physical lines without emitting
a spurious `Newline`. Reuses the existing `TokenKind`/AST -- no parser or
checker change. Tests: `tests/frontend_lexer_niceties.rs`.

Today `src/lexer.rs` only recognizes `#`-prefixed line comments (see
`docs/language_reference.md`'s "Comments" section) — there's no way to
comment out a multi-line block without prefixing every line with `#`.
Worth a block-comment delimiter pair (something that doesn't collide with
`#` line comments or f-string braces — e.g. `#* ... *#`) that nests or at
least balances correctly around commented-out code containing its own `#`
line comments.

## 2. Digit separators in numeric literals

**Done.** `Lexer::scan_digit_run`/`Lexer::strip_digit_separators`
(`src/lexer.rs`) accept and strip `_` anywhere in a decimal/hex integer
literal's digit run, a float's fraction, and a scientific-notation
exponent, before handing the digits to `str::parse`/`from_str_radix`. Pure
lexer-level change, no type-system or codegen implications, exactly as
scoped. Tests: `tests/frontend_lexer_niceties.rs`.

`Lexer::scan_number` (`src/lexer.rs:495`) only accepts `is_ascii_digit()`
runs — no `_` is allowed inside a numeric literal, so a constant like
`1000000` can't be written as `1_000_000` for readability. Rust and most
modern languages allow this purely as a lexer-level nicety (strip
underscores before parsing); no type-system or codegen change implied.

## 3. `if let` / `while let` pattern binding

**Done.** `Parser::parse_if_let_stmt`/`Parser::parse_while_let_stmt`
(`src/parser/stmt.rs`) desugar directly into the existing `Expr::Match`/
`Stmt::While` AST: `if let <pattern> = <expr>: <then> [else: <else>]`
becomes `match <expr>: <pattern> -> <then> _ -> <else-or-empty>`; `while
let <pattern> = <expr>: <body>` becomes `while true: match <expr>:
<pattern> -> <body> _ -> break`. Reuses `Parser::parse_pattern` (widened
from private to `pub(super)`) and `Checker::check_match_exhaustive`
entirely for free — no new AST node, checker rule, or codegen path; the
synthesized wildcard arm makes the result trivially exhaustive regardless
of the scrutinee's real variant count. Statement-only (no `elif let`, no
expression-position form), matching the scope actually asked for. Tests:
`tests/frontend_if_let_while_let.rs`.

There's no shorthand for "match one pattern, fall through otherwise" —
today unwrapping an `Option`/`Result` outside of `?`-propagation
(`docs/language_reference.md`'s "`?`-propagation" section) requires a full
`match` with an explicit wildcard arm even when only one variant is
interesting. `if let Some(x) = opt: ... else: ...` and a `while let`
loop-until-`None`/`Err` form would cover the common case without adding a
new pattern-matching engine — it'd desugar to the existing `match`.

## 4. Inclusive and stepped ranges in `for` loops

**Done.** A new `DotDotEq` token (`..=`) plus an optional `step <n>` clause
after the range (`Parser::parse_opt_for_step`, `src/parser/stmt.rs`) --
`step` is a soft keyword (checked as a plain identifier spelled `step`,
never added to `crate::lexer::keyword_or_ident`) since
`projects/nova/cpu.star` already declares a real `fn step(mut self):`
method. `n` is a parse-time literal (optionally negated), not a general
expression, mirroring `Stmt::Frame::budget`'s identical restriction -- so
`Codegen::emit_for_stmt` (`src/codegen/stmt.rs`) can pick the loop's
`icmp` predicate (`slt`/`sle`/`sgt`/`sge`) once at codegen time from the
step's known sign, rather than a runtime sign check every iteration.
`Stmt::For`/`TypedStmt::For` gained `inclusive: bool`/`step: Option<i64>`
fields threaded through the ~8 call sites that construct or pattern-match
every field explicitly; every site already using a trailing `..` needed no
change. `continue` still advances by `step` before rechecking the
condition (routed through the loop's existing shared step-block, same as
the original step-1 form) -- the exact "manual `while` + increment"
footgun this was meant to replace. Tests: `tests/frontend_for_loop_ranges.rs`.

`parse_for_stmt` (`src/parser/stmt.rs:499`) hardcodes `<start>..<end>` as
an exclusive, ascending, step-1 range — the `DotDot` token has no `..=`
sibling and no `step` clause. Worth scoping: an inclusive `..=` operator
(`for i in 0..=10:`) and a way to iterate descending or by a stride other
than 1 (`for i in 10..0 step -1:` or similar), rather than the current
workaround of a `while` loop with manual increment/decrement.

## 5. Multi-line string literals

**Done.** `Lexer::scan_triple_string` (`src/lexer.rs`): `"""..."""` spans
physical lines (an embedded raw `\n` is ordinary content, not the
"unterminated string literal" error a plain `"..."` would raise) and still
supports the same backslash escapes via the shared `scan_escape`. Produces
the same `TokenKind::Str` the plain form does -- there's no separate
"triple string" token kind or AST node, so nothing downstream of the lexer
needed to change. Tests: `tests/frontend_lexer_niceties.rs`.

The lexer has no raw or triple-quoted string form (checked for
`TripleStr`/`RawStr`-shaped handling — there isn't one) — only single-line
`"..."` and f-string literals. Embedding a multi-line block of text (shader
source, help text, dialogue) currently means concatenation or an external
asset file. A `"""..."""` (or similar) literal that spans lines without
requiring escaped newlines would close this gap.

## 6. Default parameter values in function definitions

**Done.** `Param` gained a `default: Option<Expr>` field (parsed by
`Parser::parse_param`, same `= <expr>` grammar as `FieldDef::default`);
`Parser::check_defaults_trail` enforces that once one parameter has a
default, every later one must too. At the checker level, two new tables
(`Checker::fn_param_meta`/`method_param_meta`, keyed identically to the
existing `functions`/`methods` tables but storing declared parameter
name + default instead of resolved type) let `Checker::
resolve_call_arg_exprs` -- the call-site counterpart of
`resolve_ctor_arg_exprs`, which already did exactly this for struct/enum
construction -- match named arguments by name (any order) and splice in a
still-missing trailing default, producing an ordinary positional argument
list before any of the existing arity/type checks ever run. Only resolved
for a callee this can identify without a duplicate, potentially
double-diagnosing `infer_expr` call: a plain free-function name, or
`recv.method(..)` where `recv` is a bare identifier or `self` (a compound
receiver like `f().method(..)` keeps its previous positional-only
behavior; so do closures and generic-function calls, neither of which has
the necessary declared-name metadata available at a call site). A default
expression is evaluated in the *caller's* scope (spliced directly into the
caller's own argument list), exactly mirroring how a struct field default
already behaves. Tests: `tests/frontend_default_params.rs`.

`parse_param` (`src/parser/items.rs:432`) has no default-value slot on
`Param` — call sites already support named arguments (`f(x = 1)`, reusing
`parse_call_args`'s `name = expr` shorthand, see `src/parser/expr.rs:642`),
but a function signature has no way to declare a default so that omitting
the argument is legal. `fn f(x: i32 = 0):` plus "omitted named/trailing
positional args fall back to their default" would make the existing named-
argument syntax actually useful for optional parameters instead of just
reordering required ones.

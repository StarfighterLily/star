# Star Compiler — Next Steps

Prioritized from [projects/nova/NOTES.md](projects/nova/NOTES.md) — the
implementation log from porting the Nova-16 fantasy-computer emulator to
Star. That project is the language's largest real stress test to date (a
64KB memory space, a ~250-arm register-code dispatch, a ~1500-line `cpu.star`)
and it surfaced a concrete list of language gaps and one still-partial
compiler bug, each pinned to the exact point it bit. Ordered by how much
each item blocks Nova's own listed future work (sound synthesis, layer
compositing, a real binary program loader, splitting `cpu.star` further as
more opcode groups land) versus general ergonomics that would help any
future `.star` project.

## P0 — Blocks Nova's own next steps

1. **No binary-safe string/byte type.** — **done**: `str` is still
   NUL-terminated end to end (`len()`, concatenation, hashing, and every
   builtin in `src/codegen/builtins.rs`/`list.rs`/`hash.rs`/`file_io.rs`
   still compute length via `@strlen`, unchanged), but the actual blocker —
   `file_read` itself losing everything past the first `0x00` — is fixed by
   two new binary-safe builtins that bypass the C-string convention
   entirely: `file_read_bytes(handle) -> Bytes` and `file_write_bytes(handle,
   data: Bytes) -> bool` (`src/codegen/file_io.rs`), reusing the `Ty::Bytes`
   length-prefixed `{ u8*, i64, i64 }` payload that already existed
   (`Ty::Bytes`'s doc comment, `src/types/mod.rs`) but had no non-`strlen`
   way to get real binary data into it before this. `file_read_bytes` sizes
   its buffer via the same `ftell`/`fseek` scheme `file_read` uses and reads
   it with a single `fread` straight into a `Bytes` object, with no `@strlen`
   call or NUL terminator anywhere in the path; `file_write_bytes` writes via
   `fwrite` sized off `Bytes`' own explicit length field. Confirmed against
   the exact repro this item cites: a 6-byte file with an embedded `0x00`
   now round-trips with `len() == 6` and every byte intact
   (`runtime_file_read_bytes_preserves_embedded_nul_end_to_end`,
   `tests/frontend_file_io.rs`). `file_read`/`file_write` themselves are
   untouched and remain `str`-based/NUL-terminated — this doesn't change
   Nova's opcode encoding or unblock loading a `.bin` through the *old*
   builtins, but Nova's byte-accurate binary file loader can now use
   `file_read_bytes` directly instead.
2. **Struct/array by-value return and by-value parameters still hang or
   crash `clang` for large aggregates.** — **done**: the two shapes the
   array-repeat/struct-literal fix (`emit_array_repeat_into`/
   `emit_struct_lit_fields_into`, still only covering `let x =
   <array-repeat-or-struct-literal>` built directly into its own binding)
   left open — a function *returning* a struct/array by value, and an
   ordinary (non-`self`) parameter of a struct/array type — now both route
   through a pointer-passing convention once the aggregate's LLVM size
   exceeds `Codegen::LARGE_AGGREGATE_THRESHOLD` (512 bytes;
   `src/codegen/mod.rs`), mirroring how `self` was already always
   pointer-passed rather than copied. A large parameter arrives as a pointer
   and is `memcpy`'d (`Codegen::emit_memcpy_aggregate`, one intrinsic call
   regardless of size) into a private local in `emit_fn`'s prologue, giving
   real by-value copy semantics without ever loading the whole aggregate
   into an SSA register; a large return type gets a hidden trailing
   `sret`-style out-pointer (`%.sret`) instead of an ordinary by-value `ret`,
   and the returned value is built directly into it by the new
   `Codegen::emit_into_ptr` (`src/codegen/stmt.rs`), which special-cases a
   fresh struct/array literal (field-by-field, no copy at all), a nested
   call with a matching aggregate return type (forwards `%.sret` straight
   through as *its own* hidden argument, so a chain of constructor calls
   never copies anything), and a read of existing storage (retain + one
   `memcpy`) — falling back to the old whole-value `load`/`store` only for
   rarer shapes (a `match`/trailing-`if` result) that weren't the reported
   hang. Called from `TypedStmt::Let`/`TypedStmt::Return`/`emit_fn`'s own
   tail logic and a new `Codegen::emit_call_arg`/`emit_aggregate_place`
   pair that resolves call arguments to a pointer instead of a by-value
   register. The 512-byte threshold is deliberate, not incidental: gating on
   size (rather than switching every struct/array unconditionally) keeps
   every existing small struct — `Vec3`, `Box`, generic `Pair<A, B>`, and
   critically anything passed through a first-class function value/closure
   (`emit_fn_value`/`emit_closure_call`, which this fix does not update and
   would emit a mismatched signature for a large aggregate) — on the
   pre-existing by-value convention with zero behavior change, confirmed by
   the full pre-existing test suite passing unmodified
   (`codegen_self_returned_by_value_loads_struct_not_pointer` included) plus
   11 new tests in `tests/frontend_large_aggregate_by_value.rs` (IR-shape
   assertions for the `sret`/pointer-param/zero-copy-forwarding shapes at
   `N=1,000,000`, plus real `clang`-compiled runtime round trips at 8192
   bytes covering constructor-return, parameter value-independence, `let`
   copies, method-call returns, and an RC-bearing (`str`) field mixed with a
   large array field across 20 iterations). Plain reassignment (`x = <large
   aggregate expr>`) and a struct/array literal used in some other generic
   expression context (not a `let`/`return`/call argument) are explicitly
   out of scope and still use the old whole-value path — narrower gaps than
   the two shapes this item named, and not hit by Nova's own constructor-
   function use case.
3. **No bitwise or shift operators/functions at all.** — **done**: the
   lexer now has real `&`/`|`/`^`/`~`/`<<`/`>>` tokens (plus `&=`/`|=`/`^=`/
   `<<=`/`>>=` compound-assignment forms), new `BinOp::BitAnd`/`BitOr`/
   `BitXor`/`Shl`/`Shr` and `UnOp::BitNot` AST variants, a new precedence
   tier in `Parser::peek_binop` (`&` > `^` > `|`, both above comparisons and
   below `<<`/`>>`, which sit above `+`/`-`; unary `~` binds like `-`/`!`),
   and dedicated checker (`Checker::infer_bitwise_combine_ty`/
   `infer_shift_ty`, `src/types/expr.rs`) and codegen (`Codegen::
   emit_bitwise_binop`/`emit_shift_binop`, `src/codegen/bitfield.rs`)
   dispatch that reuse the exact `Ty::bit_shape()`/`bitwise_combine_shape()`
   legality the pre-existing `bit_get`/`bit_and`/etc. free functions already
   established — so `&`/`|`/`^`/`~` also work on `Wrapping<T>`/`BitField<N>`,
   and `&`/`|`/`^` additionally on `Flags<E>` (deliberately excluded from
   `<<`/`>>`/`~`, same as `bit_not`/`bit_get`). This directly gives Nova the
   missing "shift by N" primitive the free-function surface never had: `>>`
   dispatches to `ashr` (sign-extending) on a signed operand and `lshr`
   (zero-filling) on unsigned, matching real hardware `SAR`/`SHR` semantics
   rather than the truncating-division approximation that couldn't
   reproduce it; the shift count is masked mod the operand's own width
   before shifting (reusing `bit_get`'s existing masking helper, now
   factored into `Codegen::emit_shift_amount`) both to avoid an LLVM poison
   value on an out-of-range count and to match x86 hardware's own mod-width
   masking. `const` initializers fold all six operators at compile time too
   (`eval_const_binop`/`fold_const_expr`, `src/types/mod.rs`). Adding real
   `<`/`>`-adjacent tokens reopened the classic "nested generic closing
   bracket" ambiguity C++/Rust parsers hit (`List<List<i32>>`'s trailing
   `>>` now lexes as one `Shr` token, not two `Gt`s) — fixed by
   `Parser::at_close_generic`/`eat_close_generic`/`expect_close_generic`
   (`src/parser/mod.rs`), which transparently split a `Shr` back into two
   closes via a `split_gt_pending` flag (not a token-stream mutation) kept
   sound across every existing speculative/backtracking turbofish parse.
   37 new tests in `tests/frontend_bitwise_shift_operators.rs`: lexer-token,
   parser-precedence/AST-shape, the nested-generic-splitting regressions
   (including a dedicated test for the abandoned-turbofish-then-real-shift-
   then-later-nested-generic corruption scenario the `split_gt_pending`
   checkpoint fix specifically prevents), type-checking (positive and
   negative, across plain ints/`Wrapping`/`BitField`/`Flags`/`Fixed`),
   IR-shape assertions (`and`/`or`/`xor`/`ashr`/`lshr`/`shl` opcodes, not
   calls), and runtime end-to-end coverage (arithmetic-vs-logical shift,
   mod-width masking, compound assignment including a narrower-than-`int`
   target, operator precedence, `const` folding, and a realistic Nova-style
   8-bit rotate built entirely from the new operators).

## P1 — Ergonomics that scale badly as the project grows

4. **No hex integer literals.** — **done**: `Lexer::scan_number`
   (`src/lexer.rs`) now special-cases a `0x`/`0X` prefix ahead of the plain
   decimal scan (both start on a `0` byte), parsing the following hex digits
   as a `u64` bit pattern and bit-reinterpreting it via `as i64` into the
   exact same `TokenKind::Int(i64)` a decimal literal produces — a hex
   literal spells a bit pattern rather than a signed decimal magnitude, so
   `0xFFFFFFFF` (all bits of a 32-bit register set) is accepted here even
   though it exceeds `i32::MAX`, deferring the "does this fit the type it's
   actually used as" question to the checker exactly like an oversized
   decimal literal already does. Because the token produced is identical to
   a decimal one, every downstream stage — parser, checker's default-`i32`/
   widening-`as`-cast-fast-path rules, `const`-initializer folding, codegen —
   needed no changes at all; a hex literal is simply an alternate spelling
   of `Expr::Int`. `0x` with no digits after it, and a literal spanning more
   than 16 hex digits (doesn't fit any `u64` bit pattern), are both clean
   lexer diagnostics rather than a panic or silent truncation. 22 new tests
   in `tests/frontend_hex_integer_literals.rs`: lexer-token coverage
   (lowercase/uppercase digits and prefix, `0x0`, stopping at a non-hex-digit
   boundary, the empty-digits and >16-digit error cases, the `0xFFFF...FFFF`
   → `-1` bit-pattern boundary, and a regression that plain/leading-zero
   decimals and float literals are unaffected), parser/AST-shape assertions,
   checker coverage (default-`i32` typing, the oversized-without-cast
   rejection, the widening-cast and all-bits-set-`u32`-cast acceptance
   cases, and interop with the bitwise operators), a `const`-folding runtime
   test, an IR-shape assertion that a hex literal lowers to a plain `i32`
   constant, and runtime end-to-end coverage of a Nova-style register-mask
   program plus hex/decimal equivalence.
5. **No destructuring `let`.** — **done**: `let [mut] (a, b, ...) [: (T1,
   T2, ...)] = expr` (2+ names) now parses, as a pure parse-time desugaring
   in the new `Parser::parse_destructure_let` (`src/parser/stmt.rs`) rather
   than a new AST/`TypedStmt`/codegen shape — it rewrites to a synthetic
   `let __destructure_N = expr` holding the whole tuple, plus one ordinary
   `let <name> = __destructure_N.<i>` per pattern element, i.e. exactly the
   hand-written `ops.0`/`ops.1` workaround this item's own 93 call sites
   already used, just generated instead of typed out. Because the output is
   plain `Stmt::Let`/`Expr::TupleIndex` nodes, every downstream pass (the
   checker, `sequence`/`frame`/`par` analysis, codegen) needed zero new match
   arms — they already handle both from ordinary tuple support. `mut` (when
   present) applies uniformly to every bound name, matching the plain
   single-name form's "the one `mut` covers the one name" rule — there's no
   per-element `let (mut a, b) = ...` mixed-mutability spelling. `Parser::
   parse_stmt` changed from `Option<Stmt>` to `Option<Vec<Stmt>>` to allow
   this one-source-line-to-many-statements expansion (every other statement
   kind still returns a single-element `Vec`); `Parser::fresh_destructure_name`
   counters the synthetic temporary's name so two destructuring `let`s in one
   function never collide. An explicit tuple type annotation is split
   per-element onto each individual `let` *and* threaded onto the temporary
   as a whole `Type::Tuple` — needed so a destructuring `let` at the top
   level of a `sequence` body can still satisfy `sequence::desugar_sequence`'s
   pre-existing "every hoisted local needs an explicit type" rule; the
   unannotated form still can't (same as any other unannotated hoisted
   local), a known, tested limitation rather than a silent gap. 24 new tests
   in `tests/frontend_destructuring_let.rs`: parser/AST-shape coverage
   (desugared statement count/order, 2- and 3-name patterns, `mut`
   propagation, trailing comma, type-annotation splitting, two destructures'
   temporaries staying distinct), parse-error coverage (single-name and empty
   patterns, duplicate binding names, annotation arity/shape mismatches,
   nested patterns failing cleanly instead of panicking), checker coverage
   (element-type inference, non-tuple/arity-mismatch/type-mismatch
   rejection, shadowing, `mut` enforcement), and runtime end-to-end coverage
   (a destructured function return, a `mut` pair mutated after binding,
   three-element destructuring, two destructures in one function, re-
   evaluation inside a loop body, a struct-valued tuple element, and the
   annotated-vs-unannotated `sequence`-hoisting cases).
6. **`impl` can't reach into another module.** — **done**: `Parser::
   parse_impl` (`src/parser/items.rs`) called a bare `expect_ident()` for
   both the trait name and the type name, never consulting `self.
   import_aliases` the way every other qualified-path site already did
   (`parse_type_inner`, `parse_primary`, pattern parsing) — so `impl
   geo::Point:` left the parser sitting on the leftover `::` token when it
   next expected the block's `:`, producing exactly the reported "expected
   ':', found '::'". Fixed by a new `Parser::parse_impl_qualified_name`
   helper, called for both `first` and (when `for` is present) the
   post-`for` name, that reproduces the same chained `alias__name` mangling
   `parse_type_inner`'s qualified-path loop and `crate::modules::resolve`'s
   own renaming pass already agree on — an arbitrary-depth `a::b::Point`
   chains `mangle_name` once per `::` exactly like a qualified type
   annotation does. Because `ImplBlock::type_name`/`trait_name` are plain
   `String`s and every downstream consumer (`Checker::check_impl`'s flat
   `self.structs.contains_key(&blk.type_name)` lookup, `self.methods`'s
   `"{type_name}#{method}"` keying, codegen's `alias__Name__method` symbol
   emission) already worked purely by string equality with zero notion of
   "module," resolving the mangled name at parse time was the entire fix —
   no changes needed anywhere in `src/modules.rs`, `src/types/mod.rs`, or
   `src/codegen/mod.rs`. This directly unblocks splitting `cpu.star`'s
   opcode-handler methods across several files: a struct can now be declared
   in one file and have additional methods (including `mut self` methods,
   and trait impls satisfying a generic bound) added from any file that
   imports it, in any combination of which side (trait, type, both, neither)
   is itself qualified, including through a re-exported nested import
   (`impl mid::base::Base:`, chaining to `mid__base__Base`). 14 new tests in
   `tests/frontend_modules_imports.rs`: parser/AST-shape coverage (bare
   qualified inherent impl, qualified-trait-for-local-type and
   local-trait-for-qualified-type and both-qualified combinations, the
   3-segment chained-mangling case, a qualified generic impl's `<T>` still
   parsing, and a clean parse-error — not a panic — for `::` after an
   undeclared alias), a checker-rejection test (an impl naming a real alias
   but an undefined struct under it is a clean "undefined type" error, not a
   silently-dropped impl), and real multi-file resolve→check→codegen→
   clang-compiled-runtime tests: adding a method to an imported struct,
   splitting one struct's methods across two files (the exact motivating
   shape), a cross-module `mut self` method actually mutating the caller's
   value, a local trait implemented for an imported type satisfying a
   generic function's trait bound end to end, and the transitive
   nested-import chaining case.

## P2 — Smaller friction, worth batching with the above

7. **`elif` doesn't exist.** — **done**: a new `elif <cond>:` keyword/token
   (`TokenKind::Elif`, `src/lexer.rs`) is pure parser-level sugar for the
   `else:` + nested `if` workaround this item itself named — `Parser::
   parse_if_else_tail` (statement form, `src/parser/stmt.rs`) and `Parser::
   parse_if_else_tail_expr` (expression form, `src/parser/expr.rs`) desugar
   an `elif` arm into a synthetic nested `Stmt::If`/`Expr::If` held as the
   sole contents of the enclosing arm's `else_block` (the expression form
   wraps its nested `Expr::If` in a `Stmt::Expr`, the same shape any other
   trailing-expression block already uses), recursing into the same
   function for the next `elif`/`else`/end-of-chain — so an arbitrary
   `if`/`elif`/.../`elif`/`else` chain collapses into ordinary right-nested
   `if`s before the checker ever sees it. No new AST/`TypedStmt`/`TypedExpr`
   variant exists anywhere, and `elif` never reaches past the parser, so the
   checker, `sequence`/`frame`/`par` analysis, and codegen needed zero new
   match arms — confirmed by the full pre-existing test suite passing
   unmodified. Both the full-indented-block and compact single-line arm
   forms work (`if a: 1 elif b: 2 else: 3` all on one line, mirroring
   `parse_if_expr_arm`'s existing two shapes). 14 new tests in
   `tests/frontend_elif.rs`: parser/AST-shape coverage (the nested-`else_block`
   desugaring shape, a 3-way `if`/`elif`/`elif`/`else` chain nesting in
   order, the compact inline form, the expression form's `Stmt::Expr`-wrapped
   nesting, and clean parse errors — not panics — for a missing `:`/missing
   condition), checker coverage (non-`bool` `elif` condition rejected the
   same as a non-`bool` `if` condition, a full chain with agreeing arm types
   inferring the common type, and `elif` with no trailing `else` still
   checking fine), and runtime end-to-end coverage (a multi-way chain
   picking exactly the first matching branch, an `elif` chain with no
   `else` falling through cleanly, `elif` as an expression value re-evaluated
   across loop iterations, a Nova-style opcode-dispatch chain mutating outer
   state per branch, and an ordinary nested `if`/`else` correctly unaffected
   when it sits inside one branch of an outer `elif` chain).
8. **Single-line `fn foo(): body` doesn't parse.** — **done**: `Parser::
   parse_fn` (`src/parser/items.rs`) now mirrors the exact compact-arm
   grammar `parse_lambda` (closure literals) and `parse_if_expr_arm`
   (`if`/`elif` arms) already established elsewhere in the parser: when the
   `:` isn't immediately followed by a `Newline`, the body is a single
   inline expression parsed via `parse_expr()` and wrapped in a
   one-statement `Block { stmts: vec![Stmt::Expr(expr)] }` — the identical
   shape a full-block function whose only statement is a trailing
   expression already produces — instead of unconditionally calling
   `parse_block()`. No new AST/`TypedStmt`/codegen variant exists anywhere,
   so the checker, `sequence`/`frame`/`par` analysis, and codegen need zero
   new match arms, confirmed by the full pre-existing test suite passing
   unmodified. Because `parse_fn` is shared by both top-level `fn` items and
   `impl` methods, both get the compact form for free. Unlike `parse_lambda`
   (whose inline body doesn't consume its own trailing line end, since a
   lambda can sit nested inside a call's argument list) and
   `parse_if_expr_arm` (whose caller defers `expect_line_end` until an
   entire `if`/`elif`/`else` chain resolves), a function/method definition
   is always a standalone item, so `parse_fn` consumes its own trailing line
   end directly. Scope is deliberately narrow, matching the precedent: the
   compact form accepts exactly one *expression*, not an arbitrary
   statement — `while`/`for` never grew a compact form either, so an inline
   assignment (`fn bump(mut self): self.x += 1`) or inline `return` don't
   parse as a compact body, just a clean parse error. 23 new tests in
   `tests/frontend_single_line_fn_body.rs`: parser/AST-shape coverage
   (bare literal and compound-expression bodies, params + return type,
   methods inside `impl` blocks, back-to-back single-line functions,
   nesting a compact `if`/`else` or lambda inside the compact fn body, and
   the full-block form staying unaffected), parse-error coverage (trailing
   garbage after the inline body, the assignment/`return`-statement scope
   boundary), checker coverage (return-type matching/mismatch, a void
   function's discarded call-expression body, `self`-field resolution
   inside an inline method body), and runtime end-to-end coverage
   (arithmetic one-liners, a one-liner method reading struct fields, an
   inline `if`/`elif`/`else`-expression body, one single-line function
   calling another, single-line and full-block functions freely mixed and
   calling each other, and a recursive single-line factorial).
9. **`Flags` is a reserved builtin generic name with a misleading error.**
   — **done**: `Checker::infer_expr`'s `Expr::StructLit` arm
   (`src/types/expr.rs`) unconditionally hijacked any call named `Flags`
   to `infer_flags_new` before ever consulting `self.structs`, so
   `struct Flags:`'s declaration itself produced zero diagnostic and the
   confusing `` `Flags<E>(..)` needs an explicit type argument `` message
   only appeared later, at the construction call site. Fixed by guarding
   that dispatch with `&& !self.structs.contains_key(name)`, the same
   "declared struct shadows a same-named builtin" precedent already
   established for builtin scalars (`Vec2`, `Tick`, ...) in `resolve_type`
   (`src/types/mod.rs`) — once shadowed, construction falls through to the
   ordinary `resolve_type`/`check_builtin_ctor_arity`/`check_struct_ctor_args`
   path, which already prioritizes `self.structs` and reports the user
   struct's own arity/field-type errors. No new AST/diagnostic variant
   needed; `Flags<E>` used with an explicit type argument is unaffected
   since a shadowing struct is always non-generic. 8 new tests in
   `tests/frontend_flags_name_shadowing.rs`: the bare declaration
   producing no diagnostic, single- and multi-field construction plus
   named-argument construction running end-to-end, wrong-arity and
   wrong-field-type construction reporting the struct's own diagnostic
   (not the old misleading builtin one), and two regression tests
   confirming the real `Flags<E>` builtin — both its "needs an explicit
   type argument" diagnostic and full runtime bitset behavior — is
   unaffected in any module that never declares a colliding struct.
10. **No fixed-size array literal with differing values.** — **done**: no
    new syntax and no new AST node -- `[a, b, c]` still parses to the exact
    same `Expr::ListLit` it always has (`src/parser/expr.rs`). What changed
    is that the checker now coerces it to a fixed `[T; N]` array instead of
    its default `List<T>` whenever an *expected* type is reachable from
    context and the element count matches `N` (`Checker::
    try_infer_array_lit`, `src/types/expr.rs`), producing a new
    `TypedExpr::ArrayLit { elems, elem_ty, span }` HIR node
    (`src/types/hir.rs`) instead of `TypedExpr::ListLit`. This is
    deliberately narrow rather than a general expected-type-propagation
    pass threaded through every expression kind (this checker has never had
    one -- see the removed doc comment this same fix updated in
    `tests/frontend_fixed_arrays.rs`): exactly three call sites peek at the
    raw, not-yet-typed `Expr::ListLit` node before falling into ordinary
    `infer_expr`, mirroring the existing "peek at the raw literal shape"
    pattern `Expr::Cast`/`Expr::WrappingNew`/`Expr::BitFieldNew` already
    established for their own literal-fits-narrower-width fast path
    (`Checker::cast_literal_magnitude`) --
    `Stmt::Let`'s own `[T; N]` annotation, a struct-literal field whose
    declared type is `[T; N]` (`FontData(glyphs = [0, 1, 2, ...])`, the
    exact motivating Nova case), and `Stmt::Return` against a `[T; N]`
    -declared function. Function-call arguments, enum-variant payloads, and
    generic-struct fields are a deliberate scope cut, not a gap that was
    missed -- documented and regression-tested
    (`function_call_argument_position_is_not_a_coercion_site`). A bare
    integer literal element (which would otherwise default to `i32`) is
    typed directly as the array's own narrower declared element type when
    it fits, reusing `Wrapping<T>`/`BitField<N>`'s identical literal-narrowing
    logic (`Checker::int_shape_range`) -- without this, every one of Nova's
    2048 font bytes would still need its own explicit `as u8`, defeating
    most of the ergonomic point. Codegen (`src/codegen/array.rs`'s
    `emit_array_lit`/`emit_array_lit_into`) mirrors `TupleLit`'s shape, not
    `ArrayRepeat`'s: since every slot is a distinct expression rather than
    one value copied `N` times, there's no runtime loop to write, just `N`
    static GEP+store pairs -- and, mirroring `emit_array_repeat_into`'s own
    reasoning (`todo.md` P0 #2), a struct field or `let` binding gets the
    literal written directly into its own storage rather than materializing
    a whole `[N x T]` SSA value and copying it a second time, avoiding the
    same real `clang` hang/crash risk at Nova's actual 2048-byte
    `FontData.glyphs` size. `TypedExpr::ArrayLit` was threaded through every
    other exhaustive match over `TypedExpr` this required
    (`system_analysis.rs`/`par_analysis.rs`/`frame_analysis.rs`/
    `codegen/mod.rs`'s `expr_ty`), confirmed by a clean build with zero
    other match arms needing changes. 24 new tests in
    `tests/frontend_array_literal_coercion.rs`: coercion at each of the
    three call sites plus each one's non-coercing fallback (no annotation,
    wrong element count, a non-array annotation/field/return type), bare
    and negated integer literal narrowing (including an out-of-range
    rejection reusing `Wrapping<T>`'s own diagnostic wording), a non-literal
    element type mismatch, an array of a struct-typed element, the
    documented function-argument scope cut, IR-shape assertions (no
    runtime-loop block label, no whole-array `load` at Nova's real
    2048-element field size), and full runtime round trips (mutable
    indexing, the exact Nova struct-field shape, `return`, and a 300-element
    stress case). `projects/nova/font_data.star`'s own doc comment is
    updated to note the literal now exists, though the file itself is left
    as its original mechanical-assignment form rather than regenerated.

## P3 — Verify, don't just assume fixed

11. **Confirm the trailing-`if`/`else` `phi` fix also covers `let`
    initializers, not just function-final-expression position.** — **done**:
    confirming this turned up that `let x = if cond: .. else: ..` never
    actually goes through `Codegen::emit_trailing_if_value`/its
    `rsplit_once` fix at all -- it parses as a full `Expr::If`
    (`Parser::parse_if_expr`) and codegens through the entirely separate
    `TypedExpr::If` arm in `src/codegen/expr.rs`, which reads its merged
    `phi` type directly off the checker's own `ty` field rather than
    splitting a tagged value string, so it was never susceptible to that
    particular bug. But auditing that arm turned up a real, different bug in
    the same place: unlike every other `if` codegen path in the compiler, it
    never wrapped either arm in its own `push_scope`/`pop_scope`, so an
    RC-owning local declared inside an arm (a `str`, `List<T>`, ...) --
    whether or not it was the arm's own trailing value -- got tracked in
    whatever scope was already open *outside* the whole `if`. That
    outer scope's eventual release fired unconditionally for *both* arms'
    locals, including the untaken arm's, whose `alloca` was never stored to
    and held uninitialized stack garbage -- releasing that garbage as a
    supposed RC pointer segfaulted, confirmed with a real `star build`+run
    repro before the fix. Fixed by giving each arm its own scope in
    `Codegen::emit_expr`'s `TypedExpr::If` case, exactly matching
    `emit_trailing_if_value`/`TypedStmt::If`'s existing pattern. 8 new tests
    in `tests/frontend_closures_higher_order.rs`: the original multi-statement
    scalar and tuple-typed `let`-initializer shapes, the segfault repro (an
    unused RC-owning arm-local, and one where the trailing value itself is
    an RC-owning arm-local), a `List<T>`-typed arm-local, a multi-statement
    `elif` chain, and a sustained-iteration leak check (`assert_no_leak`)
    alternating branches across 400,000 iterations.

12. **No scientific-notation float literals (`1e10`/`3.0e38`).** — **done**:
    `Lexer::scan_number` (`src/lexer.rs`) now recognizes an optional
    `[eE][+-]?[0-9]+` exponent suffix immediately after the pre-existing
    integer-and-optional-`.`-fraction scan, parsed the same way Rust's own
    float-literal grammar does. Because the token produced is still the
    exact same `TokenKind::Float(f64)` a plain decimal float already
    produces, every downstream stage — parser, checker, const-folding,
    codegen — needed zero changes: a scientific-notation literal is simply
    an alternate spelling of `Expr::Float`, exactly like the hex-literal fix
    (`todo.md` P1 #4) was for `Expr::Int`. The exponent is only consumed when
    a digit genuinely follows the optional sign — `1e` alone, or `1eXYZ`,
    leaves `pos` completely untouched so the `e`/`E` is left to be scanned as
    its own identifier token next, mirroring exactly how an unfollowed `.`
    already falls through to being its own `Dot` rather than starting a
    float; a bare mantissa immediately after a member-access `.` (`t.0e3`)
    is excluded from the check for the same reason the fraction check is —
    nothing right after a tuple-index `Dot` can ever be a float. An exponent
    large enough to overflow even `f64` (`1e400`) parses to `f64::INFINITY`
    via plain IEEE-754 overflow-to-infinity semantics rather than an error,
    since Rust's own `f64::from_str` already treats that as legitimate
    rather than a parse failure — no new lexer diagnostic needed. This
    directly gives Nova's math library the literal magnitude its `op_exp`/
    `op_tan` overflow-guard constant needed without spelling it out by hand:
    `MATH_OVERFLOW_GUARD: f32 = 3.0e38` now replaces the 39-zero decimal
    expansion (`projects/nova/cpu.star`). 23 new tests in
    `tests/frontend_scientific_float_literals.rs`: lexer-token coverage
    (integer and decimal mantissas, uppercase/lowercase `e`, explicit `+`/
    implicit-negative exponent signs, stopping at a non-digit boundary, the
    no-digits-after-`e`/after-`e`-and-sign fallback leaving a separate
    identifier token, an ordinary identifier starting with `e` right after an
    int not being confused for an exponent, the tuple-index-after-dot
    exclusion, `f64`-overflow-to-infinity, and plain decimal/integer literals
    staying unaffected), parser/AST-shape coverage (a scientific literal as
    `Expr::Float`, a negated scientific literal under ordinary unary-negation
    grammar), checker coverage (default-`Ty::Float` typing, widening via
    `as f64`, rejecting assignment to an `i32`-typed `let`, and a clean parse
    error rather than a panic for the malformed no-exponent-digits `1e`
    case), a `const`-folding runtime test reproducing Nova's own
    `MATH_OVERFLOW_GUARD` shape, an IR-shape assertion that a scientific
    literal lowers to the exact same `f32` constant bit pattern the
    equivalent plain-decimal literal would, and runtime end-to-end coverage
    (a realistic overflow-guard comparison against a value that genuinely
    overflows `f32`, scientific-vs-decimal equivalence, and negative-exponent
    arithmetic).

# Previous Work
file_read_bytes(handle) -> Bytes and file_write_bytes(handle, data: Bytes) -> bool (src/codegen/file_io.rs) — binary-safe siblings of file_read/file_write that never call @strlen or append a NUL terminator. They reuse the Ty::Bytes explicit-length {u8*, i64, i64} payload that already existed but had no non-strlen way to load real binary data into it.
Factored a shared emit_bytes_wrap_raw_buf helper in src/codegen/list.rs and exposed list_fields for cross-module reuse.
Wired through the type checker (src/types/mod.rs, src/types/expr.rs) and codegen dispatch (src/codegen/expr.rs).
Added 37 new tests across tests/frontend_file_io.rs and tests/frontend_method_calls_and_builtin_validation.rs: type-checking, IR-level "never calls strlen" assertions, and end-to-end runtime tests — including the exact repro cited in todo.md (a 6-byte file with an embedded 0x00 now round-trips with len() == 6, not 1), a write-side round trip verified against raw on-disk bytes, null-handle abort behavior, empty-file/non-seekable-stream edge cases, and read-only-handle failure reporting.

Pointer-passing calling convention for large struct/array function parameters and return values (Codegen::is_large_aggregate_ty gating, src/codegen/mod.rs), fixing the by-value-return/by-value-parameter clang hang todo.md P0 #2 described. A parameter above the 512-byte threshold arrives as a pointer and is memcpy'd into a private local (emit_fn's prologue, src/codegen/stmt.rs); a matching return type gets a hidden sret out-pointer (%.sret) instead of a by-value ret, filled by the new Codegen::emit_into_ptr, which special-cases a fresh literal (no copy), a nested call (forwards %.sret straight through, zero copies through a whole constructor chain), and a read of existing storage (retain + one memcpy) — used by TypedStmt::Let/TypedStmt::Return/emit_fn's tail logic and the new Codegen::emit_call_arg/emit_aggregate_place pair for call arguments (src/codegen/expr.rs). Size-gated (not unconditional) specifically to leave every existing small struct, and anything passed through a first-class function value/closure (emit_fn_value/emit_closure_call, not updated by this fix), on the pre-existing by-value convention untouched — confirmed by the full pre-existing test suite passing with zero changes needed. Added 11 new tests in tests/frontend_large_aggregate_by_value.rs: IR-shape/compile-time-budget assertions (no clang) for the sret/pointer-param/zero-copy-chained-constructor shapes at a 1,000,000-byte field, plus real clang-compiled runtime tests at 8192 bytes covering constructor-return, parameter value-independence (mutation inside the callee doesn't leak back to the caller), let-copy independence, a method returning a large struct by value, and an RC-bearing (str) field mixed with a large array field round-tripped through both return and parameter across 20 iterations.

Real bitwise/shift operator grammar (`&`/`|`/`^`/`~`/`<<`/`>>`, plus `&=`/`|=`/`^=`/`<<=`/`>>=`), fixing todo.md P0 #3. New lexer tokens (src/lexer.rs), new BinOp::BitAnd/BitOr/BitXor/Shl/Shr and UnOp::BitNot AST variants with a new Parser::peek_binop precedence tier, and dedicated Checker::infer_bitwise_combine_ty/infer_shift_ty (src/types/expr.rs) and Codegen::emit_bitwise_binop/emit_shift_binop (src/codegen/bitfield.rs) dispatch reusing the pre-existing Ty::bit_shape()/bitwise_combine_shape() legality the bit_get/bit_and/etc. free functions already established, so the operators work on plain integers of any width, Wrapping<T>, BitField<N>, and (for &/|/^ only) Flags<E>. >> dispatches to ashr (signed) or lshr (unsigned) — the real hardware-matching arithmetic/logical distinction Nova's bit-manipulation code needs, which truncating-division could never substitute for — and the shift count is masked mod the operand's width (Codegen::emit_shift_amount, factored out of bit_get's existing masking helper) to avoid an LLVM poison value on an out-of-range count. const initializers fold all six operators at compile time too (src/types/mod.rs). Adding real `<`/`>`-adjacent tokens reopened the C++/Rust "nested generic closing bracket" ambiguity (List<List<i32>>'s trailing `>>` now lexes as one Shr token) — fixed by Parser::at_close_generic/eat_close_generic/expect_close_generic (src/parser/mod.rs) transparently splitting a Shr via a split_gt_pending flag (not a token mutation, so it composes safely with every existing speculative/backtracking turbofish parse). Added 37 new tests in tests/frontend_bitwise_shift_operators.rs: lexer-token, parser-precedence/AST-shape, nested-generic-splitting regressions (including the abandoned-turbofish-then-real-shift-then-later-nested-generic corruption scenario the split_gt_pending checkpoint fix specifically prevents), positive/negative type-checking across every accepted/rejected type, IR-shape assertions for the real opcodes, and runtime end-to-end coverage (arithmetic-vs-logical shift, mod-width masking, compound assignment onto a narrower-than-int target, precedence, const folding, and a realistic Nova-style 8-bit rotate built from the new operators).

Scientific-notation float literal exponent suffix (`1e10`/`3.0e38`/`1E-5`), fixing todo.md P3 #12. `Lexer::scan_number` (src/lexer.rs) now recognizes an optional `[eE][+-]?[0-9]+` suffix right after the pre-existing integer-and-optional-fraction scan, only consuming it when a digit genuinely follows the optional sign — `1e`/`1eXYZ` leave `pos` untouched so the `e`/`E` lexes as its own identifier token next, and a mantissa right after a member-access `.` (`t.0e3`) is excluded the same way the fraction check already is. Because the token produced is still the same TokenKind::Float(f64) a plain decimal float already produces, no parser/checker/codegen changes were needed at all — a scientific literal is just an alternate spelling of Expr::Float. An exponent large enough to overflow f64 (`1e400`) parses to f64::INFINITY via ordinary IEEE-754 semantics rather than erroring. Nova's `MATH_OVERFLOW_GUARD: f32 = 3.0e38` (projects/nova/cpu.star) now replaces the 39-zero decimal expansion this gap had forced. Added 23 new tests in tests/frontend_scientific_float_literals.rs: lexer-token coverage (integer/decimal mantissas, upper/lowercase `e`, explicit sign, negative exponent, non-digit-boundary stopping, the no-exponent-digits/no-digits-after-sign fallback to a separate identifier token, an `e`-prefixed identifier not being confused for an exponent, the tuple-index-after-dot exclusion, f64-overflow-to-infinity, and unaffected plain literals), parser/AST-shape coverage (scientific literal as Expr::Float, negated scientific literal), checker coverage (default Ty::Float typing, widening via `as f64`, int-typed-let rejection, clean parse error for malformed `1e`), a const-folding runtime test reproducing Nova's own overflow-guard shape, an IR-shape assertion that a scientific literal lowers to the identical f32 constant bit pattern a plain decimal literal would, and runtime end-to-end coverage (a realistic overflow-guard comparison, scientific-vs-decimal equivalence, negative-exponent arithmetic).
Cross-module `impl` block dedup, fixing a diamond-import bug found while writing a headless test harness for `projects/nova`'s new string-library opcodes: a struct whose fields come from two sibling modules that both import one common leaf module (an ordinary, entirely unrelated diamond dependency) silently deleted a *different*, unrelated `impl <alias>::Type:` block for that struct declared in a third file — exactly the "split a struct's methods across files" shape todo.md P1 #6 unblocked, and the shape `projects/nova`'s own `cpu.star` would need for its still-pending opcode-group file split. Root cause in `src/modules.rs`: `dedupe_by_origin`'s diamond-vs-genuine-duplicate provenance tracking (path + name + import-call-id) already handled this correctly for every *named* top-level item, but `Item::Impl` declares no name of its own (`item_top_level_name` returns `None` for it, by design — `collect_names` relies on that to skip mangling it) and so was never entered into that mechanism at all; a separate, later, unconditional sweep instead collapsed *any* two impl blocks sharing a `(trait_name, type_name)` pair down to one, with no check that they were actually the same source declaration re-visited via two import paths rather than two genuinely different, both-legitimately-authored impl blocks for the same type — and that sweep only ran at all once `dedupe_by_origin`'s main mechanism had already found some *unrelated* diamond to collapse elsewhere in the module. Fixed by giving `Item::Impl` a synthetic provenance identity in `resolve_inner`'s own `other =>` arm, keyed on `(trait_name, type_name, span.start..span.end)` instead of a real name — a genuine diamond re-visit re-parses the identical source text and produces the identical byte-offset span every time (even though `span.file_id` itself differs per visit, since each import edge allocates a fresh file id), while two independently-authored impl blocks for the same type necessarily have different spans and are never grouped together. This subsumes the old blanket `seen_impls` sweep entirely, so it was deleted rather than kept as a redundant (and, as this bug showed, actively harmful) second pass. Verified against a minimal, project-independent 5-file repro (now fixed) and the full `cargo test` suite (0 regressions across every suite, including the pre-existing diamond-import tests this mechanism was originally built for in `tests/frontend_modules_imports.rs`).

Nova's BCD opcode group (`SED CLD CLA BCDA BCDS BCDCMP BCD2BIN BIN2BCD BCDADD BCDSUB`, 0x4B-0x54), the last self-contained opcode subsystem NOTES.md still listed as skipped — no Star compiler changes needed (every language gap NOTES.md tracked is already fixed), so this was pure `projects/nova` work: `Flags::apply_bcd` (`projects/nova/flags.star`) mirroring `core/flags.py::set_from_bcd`, and ten new `Cpu` opcode handlers (`projects/nova/cpu.star`, right after `op_popcnt`) ported from `core/exec_handlers.py`. Verification turned up a real bug in this port's *own* first draft, not the reference: `_bcda`/`_bcds`/`_bcdadd`/`_bcdsub` all mask their raw result to `& 0xFF` *before* checking whether to set the BCD-carry flag, not after — meaning BCDS/BCDSUB's carry check (`result < 0` post-mask) can never fire at all, a genuine reference quirk. The first draft here checked the *pre-mask* value instead (the "obviously correct" reading), which silently disagreed with the live reference. Caught by verifying via byte-for-byte machine-code replay rather than independent hand-derivation: one `.asm` test program was assembled and single-stepped against the live Python reference over the Nova-16 MCP server (16 checkpoints, registers/flags read directly via `get_cpu_state`, no memory writes or `HLT` needed), then the *exact same assembled bytes* (not re-encoded by hand) were replayed through this port's own `Cpu::step()` in a standalone headless harness and diffed checkpoint-by-checkpoint — deliberately avoiding two independent hand-derivations of "the correct BCD answer," since idealized DAA math would have reproduced the idealized (wrong) algorithm on both sides and hidden exactly this class of bug. All 16 checkpoints matched after the fix. The harness's own first draft separately re-hit a footgun this project's NOTES.md had already documented once (string-library round): passing `Cpu` to a free function by value copies it even under the large-aggregate-by-value fix, silently mutating a throwaway copy — fixed by making the harness's helpers `impl cpu::Cpu:` methods instead, so `self` carries the mutation back. `projects/nova/NOTES.md` gained a new "BCD operations (0x4B-0x54)" section documenting all of this; the harness itself and its `.asm` source were scratch files, not checked in, matching this project's established no-test-suite convention.

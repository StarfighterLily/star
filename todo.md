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
5. **No destructuring `let`.** `let (a, b) = expr` doesn't parse — every
   tuple-returning call (`decode_operands`, `vxy`, `pop_key`, ...) had to be
   bound to a temporary and read back positionally (`ops.0`/`ops.1`). Cost
   93 call sites a mechanical regex fixup in this one project; will keep
   costing the same tax as more tuple-returning helpers get added for
   sprites/layers/sound.
6. **`impl` can't reach into another module.** `impl imported::Type:` is a
   parse error — only a bare identifier is accepted, confirmed empirically
   (`impl cpu::Cpu:` fails with "expected ':', found '::'"). Every method on
   a struct must live in the same file as the struct's own definition, which
   is why `cpu.star`'s ~90 opcode-handler methods are stuck in one
   ~1500-line file with no way to split it — a problem that only gets worse
   as sound/sprite/layer/string/math opcode groups are added. Calling a
   type's existing methods across modules already works fine (composition —
   `Cpu` holding `mem`/`screen`/`kbd`/`flags` as fields — is how Nova works
   around this today); only *defining new methods* on an imported type is
   blocked.

## P2 — Smaller friction, worth batching with the above

7. **`elif` doesn't exist.** Only `if`/`else`; a multi-way branch needs a
   `match` with comparison-guard arms or nested `else:` + `if`.
8. **Single-line `fn foo(): body` doesn't parse.** A function/method body
   must be on its own indented line(s) even for a one-expression body.
9. **`Flags` is a reserved builtin generic name with a misleading error.**
   `struct Flags:` collides with the builtin `Flags<E>` bitset and fails
   with a confusing "needs an explicit type argument" error *at the
   construction site*, not the declaration — costly to debug the first time
   it happens. Either let user structs shadow builtin generic names in
   their own module, or surface the diagnostic at the colliding
   declaration instead.
10. **No fixed-size array literal with differing values.** `[a, b, c]` is
    always a `List<T>`; the only `[T; N]` literal form is the `[value; N]`
    repeat. Nova's 256-glyph font table (`font_data.star`) had no way to be
    written as a literal at all and is instead ~1500 mechanical
    `f.glyphs[i] = v as u8` assignments generated from the upstream source.
    Worth a real `[a, b, c, ...]` fixed-array literal syntax that coerces to
    `[T; N]` when the element count matches.

## P3 — Verify, don't just assume fixed

11. **Confirm the trailing-`if`/`else` `phi` fix also covers `let`
    initializers, not just function-final-expression position.** The fix
    already landed for this project (`rsplit_once(' ')` instead of
    `split_once(' ')` in `Codegen::emit_trailing_if_value`,
    `src/codegen/stmt.rs`) and was verified against `Keyboard::pop_key`/
    `Cpu::decode_operands`, both trailing-return-position tuples. Nova's
    NOTES separately flagged `let x = if cond: <multi-stmt> else:
    <multi-stmt>` (not a function's final expression, an explicit `let`
    binding) as the same underlying shape, but that specific case was never
    re-tested after the fix landed. Add a direct regression test for the
    `let`-initializer form before assuming it's covered.

# Previous Work
file_read_bytes(handle) -> Bytes and file_write_bytes(handle, data: Bytes) -> bool (src/codegen/file_io.rs) — binary-safe siblings of file_read/file_write that never call @strlen or append a NUL terminator. They reuse the Ty::Bytes explicit-length {u8*, i64, i64} payload that already existed but had no non-strlen way to load real binary data into it.
Factored a shared emit_bytes_wrap_raw_buf helper in src/codegen/list.rs and exposed list_fields for cross-module reuse.
Wired through the type checker (src/types/mod.rs, src/types/expr.rs) and codegen dispatch (src/codegen/expr.rs).
Added 37 new tests across tests/frontend_file_io.rs and tests/frontend_method_calls_and_builtin_validation.rs: type-checking, IR-level "never calls strlen" assertions, and end-to-end runtime tests — including the exact repro cited in todo.md (a 6-byte file with an embedded 0x00 now round-trips with len() == 6, not 1), a write-side round trip verified against raw on-disk bytes, null-handle abort behavior, empty-file/non-seekable-stream edge cases, and read-only-handle failure reporting.

Pointer-passing calling convention for large struct/array function parameters and return values (Codegen::is_large_aggregate_ty gating, src/codegen/mod.rs), fixing the by-value-return/by-value-parameter clang hang todo.md P0 #2 described. A parameter above the 512-byte threshold arrives as a pointer and is memcpy'd into a private local (emit_fn's prologue, src/codegen/stmt.rs); a matching return type gets a hidden sret out-pointer (%.sret) instead of a by-value ret, filled by the new Codegen::emit_into_ptr, which special-cases a fresh literal (no copy), a nested call (forwards %.sret straight through, zero copies through a whole constructor chain), and a read of existing storage (retain + one memcpy) — used by TypedStmt::Let/TypedStmt::Return/emit_fn's tail logic and the new Codegen::emit_call_arg/emit_aggregate_place pair for call arguments (src/codegen/expr.rs). Size-gated (not unconditional) specifically to leave every existing small struct, and anything passed through a first-class function value/closure (emit_fn_value/emit_closure_call, not updated by this fix), on the pre-existing by-value convention untouched — confirmed by the full pre-existing test suite passing with zero changes needed. Added 11 new tests in tests/frontend_large_aggregate_by_value.rs: IR-shape/compile-time-budget assertions (no clang) for the sret/pointer-param/zero-copy-chained-constructor shapes at a 1,000,000-byte field, plus real clang-compiled runtime tests at 8192 bytes covering constructor-return, parameter value-independence (mutation inside the callee doesn't leak back to the caller), let-copy independence, a method returning a large struct by value, and an RC-bearing (str) field mixed with a large array field round-tripped through both return and parameter across 20 iterations.

Real bitwise/shift operator grammar (`&`/`|`/`^`/`~`/`<<`/`>>`, plus `&=`/`|=`/`^=`/`<<=`/`>>=`), fixing todo.md P0 #3. New lexer tokens (src/lexer.rs), new BinOp::BitAnd/BitOr/BitXor/Shl/Shr and UnOp::BitNot AST variants with a new Parser::peek_binop precedence tier, and dedicated Checker::infer_bitwise_combine_ty/infer_shift_ty (src/types/expr.rs) and Codegen::emit_bitwise_binop/emit_shift_binop (src/codegen/bitfield.rs) dispatch reusing the pre-existing Ty::bit_shape()/bitwise_combine_shape() legality the bit_get/bit_and/etc. free functions already established, so the operators work on plain integers of any width, Wrapping<T>, BitField<N>, and (for &/|/^ only) Flags<E>. >> dispatches to ashr (signed) or lshr (unsigned) — the real hardware-matching arithmetic/logical distinction Nova's bit-manipulation code needs, which truncating-division could never substitute for — and the shift count is masked mod the operand's width (Codegen::emit_shift_amount, factored out of bit_get's existing masking helper) to avoid an LLVM poison value on an out-of-range count. const initializers fold all six operators at compile time too (src/types/mod.rs). Adding real `<`/`>`-adjacent tokens reopened the C++/Rust "nested generic closing bracket" ambiguity (List<List<i32>>'s trailing `>>` now lexes as one Shr token) — fixed by Parser::at_close_generic/eat_close_generic/expect_close_generic (src/parser/mod.rs) transparently splitting a Shr via a split_gt_pending flag (not a token mutation, so it composes safely with every existing speculative/backtracking turbofish parse). Added 37 new tests in tests/frontend_bitwise_shift_operators.rs: lexer-token, parser-precedence/AST-shape, nested-generic-splitting regressions (including the abandoned-turbofish-then-real-shift-then-later-nested-generic corruption scenario the split_gt_pending checkpoint fix specifically prevents), positive/negative type-checking across every accepted/rejected type, IR-shape assertions for the real opcodes, and runtime end-to-end coverage (arithmetic-vs-logical shift, mod-width masking, compound assignment onto a narrower-than-int target, precedence, const folding, and a realistic Nova-style 8-bit rotate built from the new operators).
//! Compiler-audit regression tests
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Compiler-audit regression tests ======================================
//
// One test per bug found and fixed in a full lexer/parser/checker/codegen
// audit: two lexer panics on non-ASCII bytes outside a string/comment (one
// in `scan_operator`'s fallback, one in `scan_escape`'s), a silent-corruption
// bug in unrecognized escape sequences, a silent-corruption bug in oversized
// integer literals, a turbofish-heuristic misparse of a real `<` comparison
// between two capitalized identifiers, dead/silently-defaulting code in the
// `GenRef` constructor's parsing, and a compiler crash (or invalid LLVM IR)
// on a struct that's recursive by value with no cycle detection.

/// A stray non-ASCII byte outside a string/comment (e.g. an accented
/// identifier) must be a clean lexer error, not a panic -- previously
/// `scan_operator`'s fallback arm advanced by exactly one raw byte, splitting
/// a multi-byte UTF-8 codepoint across two tokens and producing a `Span` that
/// crashed `diagnostics::line_text`'s slicing with "byte index is not a char
/// boundary". If the fix regresses, this test fails via an unwinding panic
/// rather than a normal assertion failure.
#[test]
fn rejects_non_ascii_source_does_not_panic() {
    let src = "fn main():\n    let café = 1\n";
    let result = Driver::parse(src);
    assert!(result.is_err(), "a stray non-ASCII byte should be a clean parse error");
}

/// The same class of bug one level deeper: a non-ASCII byte immediately
/// after a `\` inside a string literal used to desync `scan_escape`'s
/// position tracking and panic inside `current_char()` while scanning the
/// rest of the string, at a different crash site than the bare-source case
/// above.
#[test]
fn rejects_non_ascii_escape_does_not_panic() {
    let src = "fn main():\n    let x = \"\\é\"\n";
    let result = Driver::lex(src);
    assert!(result.is_err(), "a non-ASCII escaped byte should be a clean lexer error");
}

/// An escape sequence the lexer doesn't recognize must be reported, not
/// silently accepted by dropping the backslash -- previously `"bad\qescape"`
/// silently became the string `"badqescape"` with zero diagnostics.
#[test]
fn rejects_unknown_escape_sequence() {
    let src = "fn main():\n    let x = \"bad\\qescape\"\n";
    let result = Driver::lex(src);
    let Err(diags) = result else { panic!("unknown escape sequence should be a lexer error") };
    assert!(
        diags.iter().any(|d| d.message.contains("unknown escape sequence")),
        "expected an 'unknown escape sequence' diagnostic, got: {:?}",
        diags
    );
}

/// An integer literal outside `i32`'s range must be a clean error --
/// previously `text.parse::<i64>().unwrap_or(0)` let anything in
/// `(i32::MAX, i64::MAX]` parse successfully and then silently reinterpret
/// as a negative `i32` at codegen with zero diagnostics anywhere.
#[test]
fn rejects_oversized_integer_literal() {
    // The lexer itself now only rejects a magnitude that doesn't fit `i64`
    // at all (see `Lexer::scan_number`'s doc comment) -- it defers whether
    // a literal like `3000000000` (which fits `i64` but not `i32`) is
    // actually legal to the checker, since a widening `as i64`/`as u64`
    // cast can make it so (`5000000000 as i64` must type-check). Used bare
    // here with no such cast, it still defaults to `Ty::Int` (`i32`) and is
    // rejected -- just one stage later than before.
    let src = "fn main():\n    let x = 3000000000\n";
    assert!(Driver::lex(src).is_ok(), "a literal fitting i64 should lex cleanly regardless of i32 range");
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("a bare, un-cast out-of-i32-range literal should be a checker error") };
    assert!(
        diags.iter().any(|d| d.message.contains("too large for a 32-bit integer")),
        "expected a 'too large' diagnostic, got: {:?}",
        diags
    );
}

/// The whole reason `3000000000` above is now deferred past the lexer:
/// widened via an explicit `as i64`, the exact same magnitude must
/// type-check cleanly instead of being rejected for not fitting `i32`.
#[test]
fn accepts_oversized_integer_literal_under_widening_cast() {
    let src = "fn main():\n    let x: i64 = 3000000000 as i64\n";
    Driver::check(&Driver::parse(src).expect("should parse")).expect("a literal cast to i64 should fit i64's own range");
}

/// `i32::MIN` written as a unary-minus literal must still parse and
/// type-check cleanly (regression guard for the magnitude special-case added
/// alongside the overflow fix above: the lexer stores the bare magnitude
/// `2147483648` as `i32::MIN`'s bit pattern, and codegen's wrapping negation
/// of that value round-trips back to `i32::MIN`).
#[test]
fn accepts_i32_min_literal() {
    let module = Driver::parse("fn main():\n    let x = -2147483648\n").expect("should parse");
    Driver::check(&module).expect("i32::MIN literal should type-check");
}

/// Deeply nested parenthesized groups must be a clean parse error, not a
/// Rust stack overflow -- previously `Parser::parse_unary`/`parse_postfix`/
/// `parse_primary` recursed one Rust stack frame per nesting level with no
/// depth limit at all; ~500 levels of nested parens reliably overflowed the
/// real call stack with a bare process abort ("thread 'main' has overflowed
/// its stack") and no diagnostic anywhere, the parser-side counterpart of
/// the same class of bug `Checker::mono_depth` already guards against for
/// generic monomorphization.
#[test]
fn rejects_deeply_nested_parens_does_not_overflow_stack() {
    let src = format!("fn main():\n    let x = {}1{}\n", "(".repeat(500), ")".repeat(500));
    let result = Driver::parse(&src);
    assert!(result.is_err(), "500 levels of nested parens should be a clean parse error, not succeed or crash");
}

/// Same fix, unary-chain side: a long chain of unary `-` also recurses
/// through `parse_unary` with no depth limit (this path never goes through
/// `parse_primary`'s paren-recursion at all, so it exercises the depth guard
/// independently of the nested-parens case above).
#[test]
fn rejects_deeply_nested_unary_minus_does_not_overflow_stack() {
    let src = format!("fn main():\n    let x = {}1\n", "-".repeat(200000));
    let result = Driver::parse(&src);
    assert!(result.is_err(), "200000 levels of unary `-` should be a clean parse error, not succeed or crash");
}

/// Same fix, type-grammar side: `parse_type` recurses into itself for both
/// `Type::Generic`'s type arguments (`List<List<...>>`) and `Type::Fn`'s
/// params/return with no depth guard of its own -- previously this could
/// overflow the real call stack with a bare process abort ("thread 'main'
/// has overflowed its stack") the same way unguarded expression nesting did,
/// just reached through a type annotation instead of a value expression.
/// `parse_type` now shares `Parser::expr_depth`/`MAX_EXPR_DEPTH` with
/// `parse_unary`.
#[test]
fn rejects_deeply_nested_generic_type_does_not_overflow_stack() {
    let src = format!(
        "fn main():\n    let x: {}int{} = 1\n",
        "List<".repeat(500),
        ">".repeat(500)
    );
    let result = Driver::parse(&src);
    assert!(result.is_err(), "500 levels of nested `List<...>` should be a clean parse error, not succeed or crash");
}

/// A reasonably (but not adversarially) nested generic type annotation --
/// well under the depth guard's threshold -- must still parse correctly (a
/// regression guard against the depth guard being so aggressive it rejects
/// sound, if unusual, code).
#[test]
fn parses_moderately_nested_generic_type() {
    let src = format!(
        "fn main():\n    let x: {}int{} = 1\n",
        "List<".repeat(20),
        ">".repeat(20)
    );
    Driver::parse(&src).expect("20 levels of nested `List<...>` should parse cleanly");
}

/// Same failure mode again, block-nesting side: `parse_block` re-enters
/// itself (via `parse_stmt` -> `parse_if_stmt`/`parse_while_stmt`/
/// `parse_for_stmt`/`parse_match`/...) with no depth guard of its own --
/// `expr_depth`/`MAX_EXPR_DEPTH` only bounds expression nesting, not
/// statement-block nesting, so a source with a few hundred levels of
/// strictly increasing indentation (nested `if true:` blocks) previously
/// overflowed the real call stack the same way. Guarded by the new,
/// separate `Parser::block_depth`/`MAX_BLOCK_DEPTH` counter.
#[test]
fn rejects_deeply_nested_if_blocks_does_not_overflow_stack() {
    let mut src = String::from("fn main():\n");
    for i in 0..300 {
        src.push_str(&"    ".repeat(i + 1));
        src.push_str("if true:\n");
    }
    src.push_str(&"    ".repeat(301));
    src.push_str("println(\"hi\")\n");
    let result = Driver::parse(&src);
    assert!(result.is_err(), "300 levels of nested `if` blocks should be a clean parse error, not succeed or crash");
}

/// A reasonably (but not adversarially) nested block -- well under
/// `MAX_BLOCK_DEPTH` -- must still parse and run correctly (a regression
/// guard against the depth guard being so aggressive it rejects sound, if
/// unusual, code).
#[test]
fn runtime_moderately_nested_if_blocks_end_to_end() {
    let mut src = String::from("fn main():\n");
    for i in 0..20 {
        src.push_str(&"    ".repeat(i + 1));
        src.push_str("if true:\n");
    }
    src.push_str(&"    ".repeat(21));
    src.push_str("println(\"hi\")\n");
    let output = compile_and_run("moderately_nested_if_blocks", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "hi", "{}", stdout);
}

/// Same failure mode again, `match`-nesting side: `parse_match` recurses
/// back into itself both as a bare statement (`parse_match_stmt`, uncounted
/// by `expr_depth`/`block_depth` at that call site) and inline in another
/// arm's body (`_ -> match ...`, going through `expr_depth` via
/// `parse_unary`) -- previously unguarded by any counter of its own, and
/// each level of `match` nesting costs far more real stack per level
/// (`parse_match` -> `parse_match_arm` -> `parse_pattern`/`parse_expr`, each
/// with their own locals) than a plain paren/unary chain does, so ~55-60
/// levels of nested inline `match` reliably overflowed the real call stack
/// with a bare process abort well *under* `MAX_EXPR_DEPTH`'s 80-level
/// threshold -- the same "guard calibrated for a lighter call chain doesn't
/// trigger before a heavier one crashes" bug already fixed once for
/// `MAX_BLOCK_DEPTH`. Guarded by the new, separate `Parser::match_depth`/
/// `MAX_MATCH_DEPTH` counter.
#[test]
fn rejects_deeply_nested_match_does_not_overflow_stack() {
    let mut src = String::from("fn main():\n    match a0:\n");
    for i in 1..60 {
        src.push_str(&"    ".repeat(i + 1));
        src.push_str(&format!("_ -> match a{}:\n", i));
    }
    src.push_str(&"    ".repeat(61));
    src.push_str("_ -> 1\n");
    let result = Driver::parse(&src);
    assert!(result.is_err(), "60 levels of nested `match` should be a clean parse error, not succeed or crash");
}

/// A reasonably (but not adversarially) nested `match` -- well under
/// `MAX_MATCH_DEPTH` -- must still parse correctly (a regression guard
/// against the depth guard being so aggressive it rejects sound, if
/// unusual, code).
#[test]
fn parses_moderately_nested_match() {
    let mut src = String::from("fn main():\n    match a0:\n");
    for i in 1..20 {
        src.push_str(&"    ".repeat(i + 1));
        src.push_str(&format!("_ -> match a{}:\n", i));
    }
    src.push_str(&"    ".repeat(21));
    src.push_str("_ -> 1\n");
    Driver::parse(&src).expect("20 levels of nested `match` should parse cleanly");
}

/// A *flat* chain of same-precedence binary operators (`1 + 1 + 1 + ...`, no
/// parens/unary at all) is a fundamentally different shape from the nested-
/// parens/unary case `rejects_deeply_nested_parens_does_not_overflow_stack`
/// covers: precedence climbing (`Parser::parse_binary`) absorbs the whole
/// chain into *one* invocation's iterative `while` loop, with every
/// recursive `parse_binary(bp + 1)` call for the next operand returning
/// immediately -- so `expr_depth`/`MAX_EXPR_DEPTH` never fires, real parser
/// stack usage stays flat, and parsing itself never overflows. But each loop
/// iteration still builds one more `Expr::Binary{ lhs: Box::new(previous),
/// .. }` layer on the left, so the *result* is a boxed linked list exactly as
/// deep as the operator count, and every later consumer that recurses on
/// `lhs`/`rhs` with no counter of its own pays for that depth on the real
/// Rust call stack. Confirmed via a real, unguarded stack overflow ("thread
/// 'main' has overflowed its stack") in `Checker::infer_expr`'s
/// `Expr::Binary` arm from a single `let x = 1 + 1 + ... + 1` line with as
/// few as ~370 `+`s -- reached from `star check`, before codegen (whose
/// `Codegen::emit_expr` has the identical unguarded recursion) ever runs.
/// Fixed by a new `Parser::MAX_BINARY_CHAIN` counter local to each
/// `parse_binary` invocation.
#[test]
fn rejects_long_flat_binary_chain_does_not_overflow_stack() {
    let src = format!("fn main():\n    let x = 1{}\n    println(\"hi\")\n", " + 1".repeat(5000));
    let result = Driver::parse(&src);
    assert!(result.is_err(), "5000 flat `+`s should be a clean parse error, not succeed or crash");
}

/// The same flat-chain shape, but built entirely from `*` (a different
/// precedence tier than `+`) -- guards that the chain-length counter is
/// checked in `parse_binary`'s own loop regardless of *which* operator is
/// repeated, not specifically tied to `+`.
#[test]
fn rejects_long_flat_multiply_chain_does_not_overflow_stack() {
    let src = format!("fn main():\n    let x = 1{}\n    println(\"hi\")\n", " * 1".repeat(5000));
    let result = Driver::parse(&src);
    assert!(result.is_err(), "5000 flat `*`s should be a clean parse error, not succeed or crash");
}

/// A reasonably (but not adversarially) long flat binary chain -- well under
/// `MAX_BINARY_CHAIN` -- must still parse, type-check, build, and run
/// correctly with the right computed value (a regression guard against the
/// new counter being so aggressive it rejects sound, if unusual, code).
#[test]
fn runtime_moderately_long_binary_chain_end_to_end() {
    let src = format!("fn main():\n    let x = 1{}\n    println(f\"{{x}}\")\n", " + 1".repeat(150));
    let output = compile_and_run("moderately_long_binary_chain", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "151", "{}", stdout);
}

/// The same failure mode as the flat binary-chain case above, but on
/// `Parser::parse_postfix`'s own loop (`.field` accesses/calls/index/`?`)
/// instead of `parse_binary`'s: that loop is likewise iterative (not
/// recursive) with no depth guard at all before this fix, so a long chain of
/// `.field` accesses (`a.b.b.b...b`) never grew `expr_depth` either, while
/// building an identically deep left-nested `Expr::Field` spine that
/// `Checker::infer_expr`/`Codegen::emit_expr`'s unconditional recursion on
/// `base` then paid for on the real call stack. Fixed by the same
/// `MAX_BINARY_CHAIN` counter, now also checked once per `parse_postfix`
/// iteration.
#[test]
fn rejects_long_flat_field_access_chain_does_not_overflow_stack() {
    let src = format!(
        "struct S:\n    b: i32\nfn main():\n    let s = S(1)\n    let x = s{}\n    println(\"hi\")\n",
        ".b".repeat(5000)
    );
    let result = Driver::parse(&src);
    assert!(result.is_err(), "5000 flat `.b` field accesses should be a clean parse error, not succeed or crash");
}

/// Same postfix-chain guard, exercised through a call chain (`f()()()...()`)
/// instead of field access -- a different `parse_postfix` branch
/// (`TokenKind::LParen` building `Expr::Call`) building the same shape of
/// left-nested tree.
#[test]
fn rejects_long_flat_call_chain_does_not_overflow_stack() {
    let src = format!("fn main():\n    let x = f{}\n    println(\"hi\")\n", "()".repeat(5000));
    let result = Driver::parse(&src);
    assert!(result.is_err(), "5000 flat `()` calls should be a clean parse error, not succeed or crash");
}

/// A reasonably (but not adversarially) long postfix chain -- well under
/// `MAX_BINARY_CHAIN` -- must still parse, type-check, build, and run
/// correctly (a regression guard against the new counter being so
/// aggressive it rejects sound, if unusual, code). Built the same way
/// `runtime_finitely_nested_generic_struct_end_to_end` does (nested
/// `Box(Box(Box(...)))` construction, `struct Box<T>: value: T`), just with
/// the depth parameterized. Note the *construction* side (`Box(Box(...))`)
/// is itself bounded by the pre-existing `MAX_EXPR_DEPTH` (80, since each
/// nested call argument re-enters `parse_unary`) -- unlike the flat-chain
/// cases above, a real nested `Box<Box<...>>` value can't be constructed any
/// deeper than that regardless of this fix, so 50 keeps comfortable margin
/// on *both* guards at once while still being a real, non-trivial
/// `.value.value.value...` postfix read chain.
#[test]
fn runtime_moderately_long_field_access_chain_end_to_end() {
    let depth = 50;
    let ctor = format!("{}42{}", "Box(".repeat(depth), ")".repeat(depth));
    let chain = ".value".repeat(depth);
    let src = format!(
        "struct Box<T>:\n    value: T\nfn main():\n    let b = {}\n    println(f\"{{b{}}}\")\n",
        ctor, chain
    );
    let output = compile_and_run("moderately_long_field_access_chain", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "42", "{}", stdout);
}

/// `[value; N]`/`[T; N]` and `Ring<T, N>` are both stored inline with no heap
/// allocation of their own (see `Ty::Array`/`Ty::Ring`'s doc comments), so an
/// absurd `N` previously flowed uncapped into `Codegen::emit_array_repeat`'s
/// `for i in 0..count` loop, which emits two LLVM IR text lines per element
/// -- confirmed via a real, reproducible hang (30+ seconds and counting, no
/// `.ll` file ever written, well past `star build`'s normal sub-second
/// runtime) on a single line, `let x: [i32; 999999999999] = [0;
/// 999999999999]`. Fixed by a new `Checker::MAX_INLINE_LEN` bound checked
/// wherever an array/ring element count is resolved (`Type::Array`/
/// `Type::Ring` in `resolve_type`, and `Expr::ArrayRepeat`/`Expr::RingNew`'s
/// own literal `count`, which never goes through `resolve_type` at all).
#[test]
fn rejects_huge_array_repeat_size_does_not_hang() {
    let src = "fn main():\n    let x: [i32; 999999999999] = [0; 999999999999]\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("an absurd inline array size should be rejected") };
    assert!(
        errs.iter().any(|d| d.message.contains("array size") && d.message.contains("too large")),
        "got: {:?}",
        errs
    );
}

/// Same bound, `Type::Array` annotation side (no `ArrayRepeat` value
/// expression at all) -- a struct field's declared type alone must trip the
/// same check, since `Codegen::type_size`'s `self.type_size(elem) * *count
/// as u32` (an unchecked, silently-wrapping-in-release `u32` multiply) is
/// reachable from a field type with no array literal anywhere in the source.
#[test]
fn rejects_huge_array_field_type_does_not_hang() {
    let src = "struct Buf:\n    data: [i32; 999999999999]\nfn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("an absurd inline array field type should be rejected") };
    assert!(
        errs.iter().any(|d| d.message.contains("array size") && d.message.contains("too large")),
        "got: {:?}",
        errs
    );
}

/// Same bound, `Ring<T, N>` construction-expression side.
#[test]
fn rejects_huge_ring_capacity_does_not_hang() {
    let src = "fn main():\n    let r = Ring<i32, 999999999999>()\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("an absurd `Ring<T, N>` capacity should be rejected") };
    assert!(
        errs.iter().any(|d| d.message.contains("Ring<T, N>") && d.message.contains("too large")),
        "got: {:?}",
        errs
    );
}

/// Same bound, `Ring<T, N>` used as a plain type annotation (a struct field)
/// rather than a construction expression -- mirrors
/// `rejects_huge_array_field_type_does_not_hang`.
#[test]
fn rejects_huge_ring_field_type_does_not_hang() {
    let src = "struct Buf:\n    data: Ring<i32, 999999999999>\nfn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("an absurd `Ring<T, N>` field type should be rejected") };
    assert!(
        errs.iter().any(|d| d.message.contains("Ring<T, N>") && d.message.contains("too large")),
        "got: {:?}",
        errs
    );
}

/// A reasonably-sized inline array/ring -- well under `MAX_INLINE_LEN` --
/// must still type-check, build, and run correctly (a regression guard
/// against the new bound being so aggressive it rejects sound, ordinary
/// fixed-size buffers).
#[test]
fn runtime_moderately_sized_array_and_ring_end_to_end() {
    let src = "fn main():\n    let a: [i32; 100] = [0; 100]\n    let r = Ring<i32, 1000>()\n    \
               println(f\"{a[0]}\")\n";
    let output = compile_and_run("moderately_sized_array_and_ring", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "0", "{}", stdout);
}

/// An array/ring size sitting exactly at `MAX_INLINE_LEN` must still be
/// accepted (a boundary/off-by-one regression guard) -- checked via
/// `Driver::check` only (not a full `compile_and_run`), since actually
/// building a million-element array would make this test itself slow for no
/// added coverage over the moderate-size runtime test above.
#[test]
fn accepts_array_size_at_max_inline_len_boundary() {
    let src = "fn main():\n    let x: [i32; 1000000] = [0; 1000000]\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("exactly MAX_INLINE_LEN elements should be accepted, not rejected");
}

/// `Codegen::emit_array_repeat` previously unrolled `[value; N]` at compile
/// time -- a Rust-side `for i in 0..count` loop emitting one
/// `getelementptr`+`store`(+retain) instruction group per element directly
/// into the generated IR -- a real compile-time DoS for large `N` even
/// though `Checker::MAX_INLINE_LEN` caps `N` at 1,000,000 (a `[0;
/// 1000000]` still built ~2M IR lines and took the compiler itself minutes;
/// `N=50,000` crashed `clang`'s own compilation with a stack overflow). Fixed
/// by lowering slots `1..N` to a genuine LLVM runtime loop (a counter
/// `alloca`, a `br i1` back-edge) instead of unrolling, so the emitted IR
/// size -- and codegen time -- no longer scales with `N`. This asserts the
/// fix directly: codegen for a 500,000-element array-repeat must be
/// near-instant and must emit only a small, `N`-independent number of
/// `getelementptr`s (a handful for the loop body, not 500,000).
#[test]
fn codegen_array_repeat_large_n_uses_runtime_loop_not_unrolled() {
    let src = "fn main():\n    let a: [i32; 500000] = [0; 500000]\n    println(f\"{a[0]}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let start = std::time::Instant::now();
    let ir = Driver::codegen(&typed).expect("should codegen");
    let elapsed = start.elapsed();
    assert!(
        elapsed.as_secs() < 5,
        "codegen for a 500,000-element array-repeat took {:?} -- should be near-instant with a runtime loop, not scale with N",
        elapsed
    );
    let fn_ir = extract_fn_body(&ir, "define i32 @main(");
    let gep_count = fn_ir.matches("getelementptr").count();
    assert!(
        gep_count < 10,
        "expected a small, N-independent number of `getelementptr`s from a runtime loop, found {} (looks unrolled): {}",
        gep_count,
        fn_ir
    );
    assert!(fn_ir.contains("br i1"), "expected a genuine conditional branch forming a runtime loop: {}", fn_ir);
}

/// Runtime correctness companion to the codegen-shape assertion above: a
/// large array-repeat lowered through the new runtime loop must still
/// populate every slot with the correct value, not just compile fast.
/// Checks the first, a middle, and the last slot so an off-by-one in the
/// loop's bound (`icmp ult i64 %i, count` starting from `i=1`, since slot 0
/// is filled separately before the loop) would be caught.
/// `N` here (20,000) is deliberately well short of `MAX_INLINE_LEN`
/// (1,000,000): it's chosen to comfortably clear the old per-element-unroll
/// concern while staying under an unrelated pre-existing ceiling this
/// array's *storage* shape (a plain, no-heap-allocation stack `alloca`, per
/// `array.rs`'s module doc comment) hits independent of this fix -- clang's
/// own `-O0` instruction selection for a single-function stack frame that
/// large crashes on this toolchain somewhere between 50,000 and 100,000
/// `i32` elements, confirmed by bisection and unrelated to whether the
/// slots are filled by a compile-time-unrolled or runtime loop.
#[test]
fn runtime_array_repeat_large_n_fills_every_slot_end_to_end() {
    let src = "fn main():\n    let a: [i32; 20000] = [7; 20000]\n    \
               println(f\"{a[0]} {a[9999]} {a[19999]}\")\n";
    let output = compile_and_run("array_repeat_large_n_fills_every_slot", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "7 7 7", "{}", stdout);
}

/// Runtime-loop-lowered array-repeat of an RC-bearing element type (`str`)
/// must still retain each of the `N-1` additional slots correctly -- the
/// loop body's `emit_retain_at` call is only reachable at runtime now
/// (previously each retain was a separate compile-time-emitted call per
/// slot), so this exercises that the retain still actually executes on
/// every iteration rather than e.g. only the loop's first pass. Mutating one
/// slot and reading a distant, untouched slot back confirms each slot owns
/// an independent string, not `N` aliases of the same one.
#[test]
fn runtime_array_repeat_large_n_rc_element_independent_slots_end_to_end() {
    let src = "fn main():\n    let mut a: [str; 5000] = [\"x\"; 5000]\n    a[0] = \"changed\"\n    \
               println(f\"{a[0]} {a[4999]}\")\n";
    let output = compile_and_run("array_repeat_large_n_rc_element", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "changed x", "{}", stdout);
}

/// A structurally-valid enum variant followed by garbage instead of a line
/// ending (`Red 123`) must produce exactly one diagnostic and recover
/// cleanly -- `parse_enum_variant` previously discarded `expect_line_end()`'s
/// `Option` outright (`self.expect_line_end();`, no `?`), so on failure it
/// still returned `Some(EnumVariantDef { .. })` as if nothing had gone
/// wrong, leaving the stray `123` for the next loop iteration to
/// misinterpret as the start of another variant and produce a second,
/// redundant diagnostic.
#[test]
fn rejects_enum_variant_with_garbage_after_it_with_single_diagnostic() {
    let src = "enum Color:\n    Red 123\n    Blue\n";
    let errs = Driver::parse(src).expect_err("garbage after an enum variant should be a parse error");
    assert_eq!(errs.len(), 1, "should recover after exactly one diagnostic, not cascade into a second: {:?}", errs);
    assert!(errs[0].message.contains("end of line"), "{:?}", errs);
}

/// Same fix, trait-method side: a structurally-valid method signature
/// followed by garbage instead of a line ending (`fn bar() 123`) must also
/// produce exactly one diagnostic -- `parse_trait`'s method loop called
/// `self.expect_line_end();` directly (also discarding the `Option`) rather
/// than recovering on failure, so the stray `123` was left for the next
/// iteration to misinterpret as the start of another method.
#[test]
fn rejects_trait_method_with_garbage_after_it_with_single_diagnostic() {
    let src = "trait Foo:\n    fn bar() 123\n    fn baz()\n";
    let errs = Driver::parse(src).expect_err("garbage after a trait method signature should be a parse error");
    assert_eq!(errs.len(), 1, "should recover after exactly one diagnostic, not cascade into a second: {:?}", errs);
    assert!(errs[0].message.contains("end of line"), "{:?}", errs);
}

/// Same failure mode a third time, f-string-interpolation side: each nested
/// `f"{...}"` interpolation lexes and parses its inner expression with a
/// brand-new `Parser` (see `Parser::lower_fstring`), which previously reset
/// `expr_depth` to `0` at every level -- so `MAX_EXPR_DEPTH` never actually
/// accumulated across nested interpolations and only the real, unbounded
/// Rust call stack did. Fixed by carrying the outer parser's `expr_depth`/
/// `block_depth` into the fresh sub-parser instead of starting it at zero.
#[test]
fn rejects_deeply_nested_fstring_interpolation_does_not_overflow_stack() {
    let mut src = String::from("1");
    for _ in 0..200 {
        src = format!("f\"{{{}}}\"", src);
    }
    let src = format!("fn main():\n    let x = {}\n", src);
    let result = Driver::parse(&src);
    assert!(result.is_err(), "200 levels of nested f-string interpolation should be a clean parse error, not succeed or crash");
}

/// A reasonably (but not adversarially) nested f-string interpolation --
/// well under the depth guard's threshold -- must still parse and run
/// correctly.
#[test]
fn runtime_moderately_nested_fstring_interpolation_end_to_end() {
    let mut src = String::from("1");
    for _ in 0..10 {
        src = format!("f\"{{{}}}\"", src);
    }
    let src = format!("fn main():\n    let x = {}\n    println(x)\n", src);
    let output = compile_and_run("moderately_nested_fstring_interpolation", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "1", "{}", stdout);
}

/// A reasonably (but not adversarially) nested expression -- well under the
/// depth guard's threshold -- must still parse and run correctly (a
/// regression guard against the depth guard being so aggressive it rejects
/// sound, if unusual, code).
#[test]
fn runtime_moderately_nested_parens_end_to_end() {
    let src = format!("fn main():\n    let x = {}1{}\n    println(f\"{{x}}\")\n", "(".repeat(50), ")".repeat(50));
    let output = compile_and_run("moderately_nested_parens", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "1", "{}", stdout);
}

/// `if Foo < Bar:` -- both real (capitalized) local variables -- must parse
/// as an ordinary comparison, not cascade into parse errors from an eager,
/// non-backtracking turbofish attempt on the capitalized `Foo`.
#[test]
fn accepts_comparison_between_capitalized_identifiers() {
    let src = "fn main():\n    let Foo = 1\n    let Bar = 2\n    if Foo < Bar:\n        println(\"yes\")\n";
    let module = Driver::parse(src).expect("a real `<` comparison between capitalized idents should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::If { cond, .. } = &f.body.stmts[2] else { panic!("expected If") };
    match cond {
        Expr::Binary { op: BinOp::Lt, lhs, rhs, .. } => {
            assert!(matches!(lhs.as_ref(), Expr::Ident(name, _) if name == "Foo"));
            assert!(matches!(rhs.as_ref(), Expr::Ident(name, _) if name == "Bar"));
        }
        other => panic!("expected a `<` comparison, got {:?}", other),
    }
}

/// Regression guard alongside the turbofish backtracking change: legitimate
/// turbofish generic construction must still work.
#[test]
fn accepts_turbofish_generic_constructions_after_backtracking_fix() {
    let src = include_str!("../examples/generics.star");
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("Box<T>/Option<T>::Variant turbofish forms should still type-check");
}

/// `GenRef(value)` with no explicit type argument must be a clear parse
/// error -- previously it silently fell through to an incorrect `StructLit`
/// for a nonexistent `GenRef` struct, surfacing a confusing, unrelated error
/// far from the actual mistake.
#[test]
fn rejects_genref_without_type_args() {
    let src = "arena Entities: i32\nfn main():\n    let g = GenRef(0)\n";
    let module = Driver::parse(src);
    let Err(diags) = module else { panic!("bare GenRef(..) should be a parse error") };
    assert!(
        diags.iter().any(|d| d.message.contains("requires an explicit type argument")),
        "got: {:?}",
        diags
    );
}

/// `GenRef<i32>()` (missing the value argument) must be a clear parse error
/// instead of silently synthesizing a placeholder `Int(0)` value with a
/// dummy span.
#[test]
fn rejects_genref_missing_value_arg() {
    let src = "arena Entities: i32\nfn main():\n    let g = GenRef<i32>()\n";
    let module = Driver::parse(src);
    let Err(diags) = module else { panic!("GenRef<T>() with no value should be a parse error") };
    assert!(
        diags.iter().any(|d| d.message.contains("expects exactly one argument")),
        "got: {:?}",
        diags
    );
}

/// `GenRef<>(0)` (missing the type argument) must be a clear parse error
/// instead of silently synthesizing a placeholder `Type::Named("unknown")`.
#[test]
fn rejects_genref_missing_type_arg() {
    let src = "arena Entities: i32\nfn main():\n    let g = GenRef<>(0)\n";
    let module = Driver::parse(src);
    let Err(diags) = module else { panic!("GenRef<>(..) with no type arg should be a parse error") };
    assert!(
        diags.iter().any(|d| d.message.contains("expects exactly one type argument")),
        "got: {:?}",
        diags
    );
}

/// A struct that's directly recursive by value has no finite size and must
/// be rejected at type-check time -- previously this either crashed the
/// compiler with a stack overflow (via `Codegen::type_size`'s unbounded
/// recursion, when a reflection decorator touched the field) or reached
/// `clang` as invalid, unrepresentable LLVM IR.
#[test]
fn rejects_directly_recursive_struct() {
    let src = "struct Node:\n    val: i32\n    next: Node\nfn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("a directly self-referential struct should be rejected") };
    assert!(
        errs.iter().any(|d| d.message.contains("recursive struct layout")),
        "got: {:?}",
        errs
    );
}

/// A struct that's recursive only through a generic by-value wrapper must
/// also be rejected -- `struct Box<T>: value: T` is a plain by-value
/// wrapper in this language, not a heap indirection, so `Box<Node>` used as
/// a field is just as much an infinite-size cycle as direct self-reference.
#[test]
fn rejects_struct_recursive_through_generic_wrapper() {
    let src = "struct Box<T>:\n    value: T\nstruct Node:\n    next: Box<Node>\nfn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("a struct recursive through a monomorphized generic wrapper should be rejected")
    };
    assert!(
        errs.iter().any(|d| d.message.contains("recursive struct layout")),
        "got: {:?}",
        errs
    );
}

/// A generic struct whose field wraps its *own* type parameter in another
/// generic each level (`Node<T>: next: Node<Box<T>>`) is a fundamentally
/// different shape from `rejects_directly_recursive_struct`/
/// `rejects_struct_recursive_through_generic_wrapper` above: those are
/// caught by `check_no_recursive_structs` walking the *already-instantiated*
/// items, but this one never gets that far -- `instantiate_struct`
/// memoizes by mangled name (`Node__Box__i32`, `Node__Box__Box__i32`, ...),
/// and every recursive step here produces a *new* mangled name the memo
/// check has never seen, so it recurses through Rust's own call stack
/// forever. Previously an unguarded stack-overflow ICE (the whole `star`
/// process aborting) on four lines of otherwise ordinary-looking source,
/// with no diagnostic at all. `Checker::mono_depth` bounds this to a clean
/// error instead.
#[test]
fn rejects_infinitely_nested_generic_struct_field_does_not_overflow_stack() {
    let src = concat!(
        "struct Box<T>:\n",
        "    value: T\n",
        "struct Node<T>:\n",
        "    next: Node<Box<T>>\n",
        "struct Root:\n",
        "    n: Node<i32>\n",
        "fn main():\n",
        "    println(\"hi\")\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("an infinitely-growing generic instantiation should be rejected, not silently accepted")
    };
    assert!(
        errs.iter().any(|d| d.message.contains("nests too deeply")),
        "got: {:?}",
        errs
    );
}

/// A generic wrapper nested several levels deep, but *finitely* (each level
/// is written explicitly in the source, not generated by recursive
/// instantiation), must still compile and run correctly -- guards against
/// `mono_depth`'s recursion guard being so aggressive it rejects sound,
/// ordinary nested-generic code.
#[test]
fn runtime_finitely_nested_generic_struct_end_to_end() {
    let src = concat!(
        "struct Box<T>:\n",
        "    value: T\n",
        "fn main():\n",
        "    let b = Box(Box(Box(5)))\n",
        "    println(f\"{b.value.value.value}\")\n",
    );
    let output = compile_and_run("finitely_nested_generic", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "5", "{}", stdout);
}

/// Runtime test for the RC atomicity fix: `examples/par_rc_race.exe` spawns
/// 16 arena entries, captures a heap-backed `Str` (`tag`), then reads it
/// from inside a `par` body dispatched across the persistent 4-worker pool
/// for 400 ticks (6400 concurrent reads total), and reads it once more
/// afterward. Before the fix, `star_rc_retain`/`star_rc_release` mutated the
/// shared refcount header with a plain (non-atomic) load/add-or-sub/store,
/// so concurrent retains/releases from different worker threads could lose
/// an update and free the block while a worker still held it live -- the
/// final read would then be a use-after-free (typically a crash or garbled
/// output). This can't deterministically *prove* the race is gone (it's
/// inherently timing-dependent), but running it several times multiplies the
/// chances of hitting the lost-update window, the same stress-testing
/// approach `runtime_rc_stress_memory_stays_bounded` uses for leaks.
#[test]
fn runtime_par_rc_race_reads_captured_str_without_corruption() {
    use std::process::Command;

    for _ in 0..5 {
        let output = Command::new("examples/par_rc_race.exe").output().expect("failed to run par_rc_race.exe");
        assert!(output.status.success(), "par_rc_race.exe should exit cleanly, not crash from a use-after-free");
        let stdout = String::from_utf8_lossy(&output.stdout);
        assert!(
            stdout.trim_end().ends_with("final: swarm-tag"),
            "expected the captured Str to still read correctly after the par loop, got tail: {:?}",
            &stdout[stdout.len().saturating_sub(80)..]
        );
        // Every retain/release pair inside the loop operates on the same
        // "swarm-tag" bytes; a corrupted refcount that freed the block
        // early (but didn't crash outright) would typically show up as a
        // truncated/garbled repetition somewhere in the middle instead of a
        // clean, uniform repeat -- a stronger check than only looking at the
        // very end.
        assert!(
            !stdout.contains('\0') && stdout.matches("swarm-tag").count() >= 6400,
            "expected 6400 clean repetitions of the captured Str, got {} (len {})",
            stdout.matches("swarm-tag").count(),
            stdout.len()
        );
    }
}

/// Runtime test for a `Symbol` intern-table thread-safety bug: `Symbol(s)`
/// (`crate::codegen::symbol::emit_symbol_intern`) mutates the process-wide
/// intern table (`@sym.data`/`@sym.len`/`@sym.cap`) via a plain scan, and (on
/// a miss) a `malloc`/`memcpy`/`free` doubling-grow -- with no lock. Unlike
/// `spawn`/`despawn`/`frame:`, calling `Symbol(..)` inside a `par`/`swarm`
/// body is *not* rejected by the checker's disjointness proof
/// (`types::par_analysis::walk_par_expr`'s `StructLit` arm just walks into
/// `Symbol(..)`'s argument like any other constructor, with no awareness
/// that construction itself touches shared global state) -- and `par`/
/// `swarm` genuinely dispatches the loop body across 4 concurrent OS worker
/// threads (`crate::codegen::par_pool`), so every worker interning strings
/// concurrently really did race on the table. Confirmed via
/// `examples/symbol_par_race.star` (64 entities, 200 ticks, every entity in
/// a tick interning the same tick-unique string concurrently and storing the
/// resulting id on itself): before the fix this crashed with a real, 5/5-run
/// `STATUS_HEAP_CORRUPTION` (`0xC0000374`, i.e. exit code `-1073740940`)
/// from the grow path's unsynchronized `malloc`/`memcpy`/`free`. Fixed by
/// adding `@sym.lock`, a binary semaphore guarding every `Symbol(..)`/
/// `symbol_name(..)` table access, created once in `main`'s prologue (before
/// any `par`/`swarm` dispatch can spin up the worker pool, so there's no
/// first-use race in creating the lock itself -- see `@sym.lock`'s own doc
/// comment in `Codegen::emit_builtins`).
///
/// This can't deterministically *prove* the race is gone (it's inherently
/// timing-dependent), so this runs the binary several times, checking both
/// that it never crashes and that every entity within a tick converged on
/// the same id for the same string (a lock failure could produce duplicate/
/// wrong ids without necessarily crashing the heap every time).
#[test]
fn runtime_symbol_par_race_interns_without_corruption() {
    use std::process::Command;

    for _ in 0..5 {
        let output = Command::new("examples/symbol_par_race.exe").output().expect("failed to run symbol_par_race.exe");
        assert!(
            output.status.success(),
            "symbol_par_race.exe should exit cleanly, not crash from intern-table heap corruption: {:?}",
            output.status
        );
        let stdout = String::from_utf8_lossy(&output.stdout);
        let lines: Vec<&str> = stdout.lines().collect();
        assert_eq!(lines.len(), 65, "expected 64 entity ids plus 1 check line, got: {:?}", lines);
        let ids = &lines[..64];
        let first = ids[0];
        assert!(
            ids.iter().all(|id| *id == first),
            "every entity should have interned the same last-tick string to the same id, got mixed ids: {:?}",
            ids
        );
        assert_eq!(
            lines[64],
            format!("check = {}", first),
            "re-interning the same string sequentially afterward should reproduce the same id every entity already saw"
        );
    }
}

/// Runtime test for an RNG-state thread-safety bug, the `Symbol` intern-table
/// race's sibling: `rand`/`rand_range` (`crate::codegen::vector_math::
/// emit_rand_next`) advance a single process-wide xorshift32 generator
/// (`@rng.state`) via a plain load-xorshift-store sequence, with no lock.
/// Like `Symbol(..)`, calling `rand_range(..)` inside a `par`/`swarm` body is
/// *not* rejected by the checker's disjointness proof (`types::par_analysis`
/// has no notion that `@rng.state` is shared global state), and `par`/
/// `swarm` genuinely dispatches across 4 concurrent OS worker threads
/// (`crate::codegen::par_pool`), so two threads really can both load
/// `@rng.state` before either stores back -- computing and storing the
/// *identical* next value, a lost-update race. Confirmed via
/// `examples/rand_par_race.star` (64 entities, 200 ticks, every entity in a
/// tick drawing an independent `rand_range(..)` value): before the fix,
/// roughly 5-15% of ticks showed dozens of entities converging on duplicate
/// values (a ~0.0000149 probability by chance alone with a 32-bit generator
/// and 64 draws), 5/5 runs. Unlike `Symbol`'s table, a plain aligned `i32`
/// load/store can't itself tear the heap, so this was a silent wrong-answer
/// race rather than a crash. Fixed by adding `@rng.lock`, a binary semaphore
/// guarding every `rand`/`rand_range`/`rand_seed` access to `@rng.state`,
/// created once in `main`'s prologue (before any `par`/`swarm` dispatch can
/// spin up the worker pool) -- the exact same shape as `@sym.lock`.
///
/// This can't deterministically *prove* the race is gone (it's inherently
/// timing-dependent), so this runs the binary several times, checking that
/// no tick's block of 64 drawn values ever contains a duplicate.
#[test]
fn runtime_rand_par_race_draws_without_duplicate_values() {
    use std::process::Command;

    for _ in 0..5 {
        let output = Command::new("examples/rand_par_race.exe").output().expect("failed to run rand_par_race.exe");
        assert!(output.status.success(), "rand_par_race.exe should exit cleanly: {:?}", output.status);
        let stdout = String::from_utf8_lossy(&output.stdout);
        let lines: Vec<&str> = stdout.lines().collect();
        assert_eq!(lines.len(), 200 * 65, "expected 200 ticks of 64 values + 1 blank line each, got {} lines", lines.len());
        for tick in 0..200 {
            let block = &lines[tick * 65..tick * 65 + 64];
            let unique: std::collections::HashSet<&&str> = block.iter().collect();
            assert_eq!(
                unique.len(),
                block.len(),
                "tick {} should draw 64 independent rand_range values with no duplicates (a duplicate means a lost-update race on @rng.state), got: {:?}",
                tick,
                block
            );
        }
    }
}

/// `print`/`println`'s non-f-string form passes its argument straight
/// through as `printf`'s format string (see `Codegen::emit_print_like`),
/// with no `%s` substitution -- previously the checker never validated this
/// argument's type at all, so `print(5)` (or `print(len(s))`, or any other
/// non-`str` argument) type-checked cleanly and only failed later at the
/// `clang` step with a confusing, mislocated backend error (a raw `i32`
/// value reaching an `i8*` format-string parameter).
#[test]
fn rejects_print_of_non_str_argument() {
    let module = Driver::parse("fn main():\n    print(5)\n").expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("print(5) should be a type error") };
    assert!(
        errs.iter().any(|d| d.message.contains("expects a `str` argument")),
        "got: {:?}",
        errs
    );
}

/// Regression guard for the cycle-detection fix: a struct referencing itself
/// through `GenRef<T>` (a fixed-size arena handle, not an inlined value)
/// must still type-check -- this is the language's actual intended pattern
/// for self-referential data structures.
#[test]
fn accepts_struct_with_genref_self_reference() {
    let src = "struct Node:\n    val: i32\n    next: GenRef<Node>\narena Nodes: Node\nfn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("GenRef<Self> should break the cycle and type-check cleanly");
}

// --- item 20: integer division/modulo by zero traps the process -----------
//
// `sdiv`/`srem i32` are undefined behavior in LLVM on a zero divisor, and
// on the lone overflowing case `i32::MIN / -1` (its true result doesn't fit
// in `i32`) -- both trap the whole process with SIGFPE and no diagnostic on
// x86 if emitted unchecked, exactly the "silently crash instead of erroring"
// failure mode item 1 (frame overflow) and item 9 (arena capacity) already
// fixed for other operations. `Codegen::emit_checked_int_div`
// (`src/codegen/vector_math.rs`) now guards both cases and aborts with a
// message, mirroring `emit_frame_alloc`'s check-then-abort shape.

/// `10 / e.hp` where `e.hp` is a runtime-computed `0` (not a literal, so the
/// checker's lack of constant folding can't be accused of catching this
/// statically) must abort loudly with a diagnostic instead of crashing the
/// process with an unexplained SIGFPE.
#[test]
fn runtime_int_division_by_zero_aborts_loudly_instead_of_trapping() {
    use std::process::Command;

    let output = Command::new("examples/int_div_by_zero.exe").output().expect("failed to execute int_div_by_zero.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("integer `/` by zero"), "should print a diagnostic: {}", stdout);
    assert!(!stdout.contains("should not reach here"), "the division must abort before its value is used: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "should exit cleanly with code 1, not crash/trap: {:?}", output.status);
}

/// Same guard, `%` instead of `/`, and reached at the very edge of `i32`.
#[test]
fn runtime_int_modulo_by_zero_aborts_loudly_instead_of_trapping() {
    let src = "struct Enemy:\n    mut hp: i32\nfn main():\n    let e = Enemy(0)\n    println(\"before\")\n    let x = 2147483647 % e.hp\n    println(f\"unreachable {x}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_int_mod_by_zero.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");

    let output = std::process::Command::new(&exe).output().expect("failed to execute int_mod_by_zero.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("integer `%` by zero"), "should print a diagnostic: {}", stdout);
    assert!(!stdout.contains("unreachable"), "the modulo must abort before its value is used: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "should exit cleanly with code 1, not crash/trap: {:?}", output.status);

    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
}

/// `i32::MIN / -1` is the one *non-zero*-divisor input that's still
/// undefined behavior for `sdiv` (the mathematical result, `2147483648`,
/// overflows `i32`) -- must be caught by the same guard, not just the
/// zero-divisor case.
#[test]
fn runtime_int_min_divided_by_negative_one_aborts_loudly_instead_of_trapping() {
    let src = "struct Enemy:\n    mut hp: i32\nfn main():\n    let e = Enemy(-1)\n    println(\"before\")\n    let x = -2147483648 / e.hp\n    println(f\"unreachable {x}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_int_min_div_neg1.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");

    let output = std::process::Command::new(&exe).output().expect("failed to execute int_min_div_neg1.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("integer `/` by zero"), "should print a diagnostic: {}", stdout);
    assert!(!stdout.contains("unreachable"), "the division must abort before its value is used: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "should exit cleanly with code 1, not crash/trap: {:?}", output.status);

    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
}

/// Ordinary division/modulo (including negative operands, where `srem`'s
/// sign convention matters) must still compute the correct value through
/// the new checked path -- the guard must not perturb the common case.
#[test]
fn codegen_ordinary_int_division_still_computes_correct_values() {
    let src = "fn main():\n    println(f\"{10 / 3}\")\n    println(f\"{-10 / 3}\")\n    println(f\"{10 % 3}\")\n    println(f\"{-10 % 3}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_ordinary_div.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");

    let output = std::process::Command::new(&exe).output().expect("failed to execute ordinary_div.exe");
    assert!(output.status.success(), "should exit cleanly");
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["3", "-3", "1", "-1"], "LLVM's sdiv/srem truncate toward zero, matching Star's semantics");

    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
}

/// Codegen for `/`/`%` on `i32` operands includes the zero/overflow guard
/// before the `sdiv`/`srem` instruction, with a call to `@exit` on the trap
/// path -- the direct IR-shape pin, alongside the end-to-end runtime tests
/// above.
#[test]
fn codegen_int_division_includes_zero_and_overflow_guard() {
    let src = "fn div(a: i32, b: i32) -> i32:\n    a / b\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("icmp eq i32 %"), "should compare the divisor against zero: {}", ir);
    assert!(ir.contains("-2147483648"), "should compare the dividend against i32::MIN for the overflow case: {}", ir);
    assert!(ir.contains("call void @exit(i32 1)"), "should abort on the trap path: {}", ir);
    assert!(ir.contains("sdiv i32"), "should still emit sdiv on the ok path: {}", ir);
}

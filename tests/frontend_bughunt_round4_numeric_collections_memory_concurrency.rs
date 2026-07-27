//! Bug-hunting round 4: numeric/type-checker, collections, memory model, concurrency/modules/parser/IO audits
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// =====================================================================
// ===== Bug-hunting round: four parallel audits (numeric/type-checker,
// ===== collections, memory model, concurrency/modules/parser/IO) each
// ===== confirmed real, reproducible bugs via an actual `star build`+run,
// ===== not just static reading. Every fix above this marker predates this
// ===== round; everything below is new coverage for what that round found
// ===== and fixed. =====================================================

// --- Numeric/type-checker audit -----------------------------------------

/// `-x` previously hardcoded `sub i32 0, ...`/`fsub float 0.0, ...`
/// regardless of `x`'s real type -- the checker never restricted `-x` to
/// `i32`/`float` (it preserves whatever numeric type the operand has), so
/// negating any other numeric type emitted an operand/opcode width
/// mismatch `clang` rejected outright. Now routed through the same
/// width/signedness-generic scalar-binop path real binary `-` uses.
#[test]
fn runtime_unary_negation_on_every_numeric_width_end_to_end() {
    let src = "fn main():\n    \
               let a: i64 = 5 as i64\n    let b: i64 = -a\n    println(f\"{b}\")\n    \
               let c: i8 = 100 as i8\n    let d: i8 = -c\n    println(f\"{d}\")\n    \
               let e: f64 = 2.5 as f64\n    let g: f64 = -e\n    println(f\"{g}\")\n";
    let output = compile_and_run("unary_neg_sized_types", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["-5", "-100", "-2.500000"], "{}", stdout);
}

/// `-i8::MIN` (`-(-128i8)`) overflows `i8` exactly like `0i8 - (-128i8)`
/// would -- routing `-x` through the checked-arithmetic path picks up the
/// same trap-on-overflow behavior every other sized-int arithmetic op
/// already has, for free.
#[test]
fn runtime_unary_negation_of_signed_min_traps_end_to_end() {
    let src = "struct Counter:\n    mut n: i8\nfn main():\n    println(\"before\")\n    let c = Counter(-128 as i8)\n    \
               let x = -c.n\n    println(f\"unreachable {x}\")\n";
    let output = compile_and_run("unary_neg_signed_min_overflow", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(stdout.contains("signed 8-bit integer overflow"), "should print a diagnostic: {}", stdout);
    assert!(!stdout.contains("unreachable"), "the negation must abort before its value is used: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}

/// A literal whose magnitude doesn't fit `i32` but does fit its cast
/// target must actually widen, not be rejected before the cast gets a
/// chance to run -- `Lexer::scan_number` used to cap every literal's
/// magnitude at `i32::MAX` unconditionally, defeating the entire reason
/// `i64`/`u64` exist (`docs/design.md`'s "large-world coordinates").
#[test]
fn runtime_large_integer_literal_widening_cast_end_to_end() {
    let src = "fn main():\n    let a: i64 = 5000000000 as i64\n    println(f\"{a}\")\n    \
               let b: u64 = 9000000000 as u64\n    println(f\"{b}\")\n    \
               let c: i64 = -5000000000 as i64\n    println(f\"{c}\")\n";
    let output = compile_and_run("large_literal_widening_cast", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["5000000000", "9000000000", "-5000000000"], "{}", stdout);
}

/// A literal that fits neither `i32` (its default type) nor its cast
/// target must still be a clean checker error, not a silent
/// misinterpretation -- the widening fast path above must not become a
/// license to skip range-checking against the *target* type too.
#[test]
fn rejects_out_of_i32_range_literal_cast_to_a_too_narrow_type() {
    let src = "fn main():\n    let a: i8 = 5000000000 as i8\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("a literal that doesn't fit i32 or the cast target should be a checker error");
    assert!(diags.iter().any(|d| d.message.contains("does not fit")), "{:?}", diags);
}

/// Plain `fptosi`/`fptoui` are undefined behavior (poison) whenever the
/// source float doesn't fit the destination integer width -- `emit_cast`
/// now routes through the saturating `llvm.fptosi.sat`/`llvm.fptoui.sat`
/// intrinsics instead, matching Rust's own (saturating since 1.45) `as`.
#[test]
fn runtime_float_to_int_cast_saturates_out_of_range_values_end_to_end() {
    let src = "fn main():\n    \
               let a: f32 = -1.0\n    let u: u8 = a as u8\n    println(f\"{u}\")\n    \
               let b: f32 = 500.0\n    let v: u8 = b as u8\n    println(f\"{v}\")\n    \
               let c: f32 = 3000000000.0\n    let w: i32 = c as i32\n    println(f\"{w}\")\n    \
               let d: f32 = -3000000000.0\n    let x: i32 = d as i32\n    println(f\"{x}\")\n";
    let output = compile_and_run("float_to_int_saturating_cast", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["0", "255", "2147483647", "-2147483648"], "{}", stdout);
}

/// `sqrt`/`abs`/`min`/`max` previously hard-rejected every numeric type
/// except the original `i32`/`f32` -- a narrower, shadowing `is_numeric`
/// helper in `check_builtin_call_args` was never widened when the sized
/// numeric types/`f64` landed.
#[test]
fn runtime_math_builtins_accept_every_numeric_width_end_to_end() {
    let src = "fn main():\n    \
               let a: f64 = 16 as f64\n    println(f\"{sqrt(a)}\")\n    \
               let b: i64 = -42 as i64\n    println(f\"{abs(b)}\")\n    \
               let c: u8 = 200 as u8\n    let d: u8 = 55 as u8\n    println(f\"{min(c, d)}\")\n    \
               println(f\"{max(c, d)}\")\n";
    let output = compile_and_run("math_builtins_sized_types", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["4.000000", "42", "55", "200"], "{}", stdout);
}

/// `pow`/`min`/`max` still require a matching numeric pair (the one
/// legacy `Int`/`Float` mix aside) -- the widened `is_numeric` check above
/// must not also silently accept a genuine cross-width mismatch.
#[test]
fn rejects_mismatched_numeric_types_passed_to_min() {
    let src = "fn main():\n    let a: i64 = 5 as i64\n    let b: u8 = 5 as u8\n    min(a, b)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("min(i64, u8) should be a checker error");
    assert!(diags.iter().any(|d| d.message.contains("same numeric type")), "{:?}", diags);
}

// --- Memory-model audit --------------------------------------------------

/// Writing an RC-bearing field through a stale (post-`despawn`) `GenRef`
/// must be a true no-op -- including releasing the already-owned RHS --
/// not a leak into `emit_genref_index_place`'s disconnected stale-path
/// dummy alloca. Mirrors `runtime_discarded_list_pop_statement_does_not_leak_end_to_end`'s
/// Working-Set-sampling technique.
#[test]
fn runtime_stale_genref_field_write_does_not_leak_end_to_end() {
    let src = "struct Item:\n    mut name: str\n\narena Items: Item\n\nfn main():\n    \
               spawn Items(\"seed\")\n    despawn Items[0]\n    let r = GenRef<Item>(0)\n    \
               let mut i: i32 = 0\n    while i < 3000000:\n        r[0].name = concat(\"x\", \"y\")\n        i += 1\n    \
               println(\"done\")\n";
    assert_no_leak("stale_genref_field_write_leak", src, 25 * 1024 * 1024);
}

/// A method call on an `if`/`match`-expression receiver built from plain
/// (non-`frame:`) locals, returning a closure that captures `self` by
/// pointer, must be rejected -- `local_struct_receiver` previously had no
/// arm for `TypedExpr::If`/`TypedExpr::Match`, so this fell through its
/// `_ => None` catch-all and the closure dangled the moment `make`
/// returned (mirrors `rejects_closure_capturing_self_via_chained_method_call_receiver`'s
/// same bug class, one receiver shape further).
#[test]
fn rejects_closure_capturing_self_via_if_expression_receiver() {
    let src = r#"struct Holder:
    val: i32

impl Holder:
    fn get_closure(self) -> Fn() -> i32:
        fn(): self.val

fn make(cond: bool) -> Fn() -> i32:
    let holder_a = Holder(111)
    let holder_b = Holder(222)
    return if cond:
        holder_a
    else:
        holder_b
    .get_closure()
"#;
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("a closure escaping with an if-expression receiver's self pointer should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("holder_a")), "{:?}", errs);
}

/// Same bug shape, a `match`-expression receiver instead of `if`.
#[test]
fn rejects_closure_capturing_self_via_match_expression_receiver() {
    let src = r#"struct Holder:
    val: i32

impl Holder:
    fn get_closure(self) -> Fn() -> i32:
        fn(): self.val

fn make(cond: i32) -> Fn() -> i32:
    let holder_a = Holder(111)
    let holder_b = Holder(222)
    return match cond:
        0 -> holder_a
        _ -> holder_b
    .get_closure()
"#;
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("a closure escaping with a match-expression receiver's self pointer should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("holder_a")), "{:?}", errs);
}

/// `r[0] = value` (a whole-element write through a `GenRef`) type-checks
/// but previously crashed codegen with an opaque "cannot store to this
/// expression" internal error -- `store_target` had no arm for a bare
/// `TypedExpr::GenRefIndex` target. Now supported, mirroring `table[i] = v`.
#[test]
fn runtime_genref_whole_element_write_end_to_end() {
    let src = "struct Item:\n    mut hp: i32\n\narena Items: Item\n\nfn main():\n    \
               spawn Items(1)\n    let r = GenRef<Item>(0)\n    r[0] = Item(999)\n    println(f\"{r[0].hp}\")\n";
    let output = compile_and_run("genref_whole_element_write", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "999");
}

/// A whole-element write through a stale (post-`despawn`) `GenRef` must be
/// a silent no-op, matching every sibling collection's out-of-bounds-write
/// contract -- not a crash, and not a leak of the discarded RHS.
#[test]
fn runtime_genref_whole_element_write_through_stale_handle_is_a_no_op_end_to_end() {
    // `name: str` (RC-bearing) specifically exercises `store_genref_whole`'s
    // release-the-discarded-RHS path with a real heap reference to release
    // -- a struct with only scalar fields (`contains_rc` false) would let
    // `emit_release_bare` short-circuit before ever emitting the `store`
    // whose tagging this round's fix corrected, silently passing either way.
    let src = "struct Item:\n    mut hp: i32\n    name: str\n\narena Items: Item\n\nfn main():\n    \
               spawn Items(1, \"a\")\n    despawn Items[0]\n    let r = GenRef<Item>(0)\n    r[0] = Item(999, \"b\")\n    println(\"done\")\n";
    let output = compile_and_run("genref_whole_element_write_stale", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "done");
}

// --- Concurrency/modules/parser/IO audit ---------------------------------

/// `yield` nested inside a `par`/`swarm` body within a `sequence` must be
/// rejected -- `scan_for_nested_yield` previously had no `Stmt::Par` arm,
/// so this fell through to a separate, generic type-checker fallback with
/// a worse diagnostic/location than every sibling nested-block case gets.
#[test]
fn rejects_yield_nested_inside_par_body_within_sequence() {
    let src = format!("{}sequence S():\n    par e in Enemies:\n        yield\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let errs = Driver::check(&module).expect_err("yield nested inside a par body within a sequence should be rejected");
    assert!(errs.iter().any(|d| d.message.contains("top level of a `sequence` body")), "{:?}", errs);
}

/// Writing through a file handle right after closing it must abort loudly
/// (matching this module's own documented contract), not silently hand
/// the C runtime a dangling `FILE*` that a later, unrelated `fopen` may
/// have already reused for a different file -- `file_close` now nulls out
/// the caller's own variable (when it's a bare one) so a later use through
/// *that* binding hits the existing null-handle guard.
#[test]
fn runtime_file_write_through_just_closed_handle_aborts_end_to_end() {
    let path = scratch_file_path("star_test_closed_handle_write.txt");
    let src = format!(
        "fn main():\n    let p = \"{p}\"\n    let w = file_open(p, \"w\")\n    file_close(w)\n    \
         file_write(w, \"oops\")\n    println(\"unreachable\")\n",
        p = path
    );
    let output = compile_and_run("file_write_through_closed_handle", &src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(
        !stdout.contains("unreachable"),
        "a write through a just-closed handle must abort, not silently corrupt an unrelated file: {}",
        stdout
    );
    assert!(stdout.contains("null/closed file handle"), "should print the null-handle diagnostic: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
    let _ = std::fs::remove_file(&path);
}

/// A `char` literal containing a brace (`'}'`/`'{'`) inside an f-string
/// interpolation hole must not desync the hole's boundary -- `scan_fstring`
/// previously only tracked nested `"..."` string literals, not `'...'`
/// char literals, so the `}`/`{` inside one was misread as closing (or
/// re-opening) the hole early.
#[test]
fn runtime_fstring_hole_with_char_literal_containing_brace_end_to_end() {
    let src = "fn main():\n    let c: char = '}'\n    println(f\"{c == '}'}\")\n    \
               let d: char = '{'\n    println(f\"{d == '{'}\")\n";
    let output = compile_and_run("fstring_char_brace", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "true"], "{}", stdout);
}

// --- Collections audit ----------------------------------------------------

/// `xs[idx] = v` on an out-of-bounds index is documented as a silent
/// no-op, but the RHS was already computed and retained by the caller --
/// the out-of-bounds branch jumped straight past any release of it,
/// leaking one heap reference per out-of-bounds write. Mirrors
/// `runtime_discarded_list_pop_statement_does_not_leak_end_to_end`'s
/// Working-Set-sampling technique.
#[test]
fn runtime_list_out_of_bounds_write_does_not_leak_end_to_end() {
    let src = "fn main():\n    let mut xs: List<str> = List<str>()\n    xs.push(\"seed\")\n    \
               let mut i: i32 = 0\n    while i < 2000000:\n        xs[999] = concat(\"x\", \"y\")\n        i += 1\n    \
               println(f\"done len={xs.len()}\")\n";
    assert_no_leak("list_oob_write_leak", src, 25 * 1024 * 1024);
}

/// Same bug, `Array<T,N>` (`[T; N]`) instead of `List<T>`.
#[test]
fn runtime_array_out_of_bounds_write_does_not_leak_end_to_end() {
    let src = "fn main():\n    let mut a: [str; 3] = [\"seed\"; 3]\n    \
               let mut i: i32 = 0\n    while i < 2000000:\n        a[999] = concat(\"x\", \"y\")\n        i += 1\n    \
               println(\"done\")\n";
    assert_no_leak("array_oob_write_leak", src, 25 * 1024 * 1024);
}

/// Same bug, `Ring<T,N>` instead of `List<T>`.
#[test]
fn runtime_ring_out_of_bounds_write_does_not_leak_end_to_end() {
    let src = "fn main():\n    let mut r: Ring<str, 3> = Ring<str, 3>()\n    r.push(\"seed\")\n    \
               let mut i: i32 = 0\n    while i < 2000000:\n        r[999] = concat(\"x\", \"y\")\n        i += 1\n    \
               println(\"done\")\n";
    assert_no_leak("ring_oob_write_leak", src, 25 * 1024 * 1024);
}

/// Same bug, `Table<T>` instead of `List<T>` -- here the whole RHS struct
/// (including any RC-bearing fields) was orphaned, not just one scalar
/// reference, since `store_table_index`'s out-of-bounds branch skipped its
/// per-column write loop (and thus any release) entirely.
#[test]
fn runtime_table_out_of_bounds_write_does_not_leak_end_to_end() {
    let src = "struct Item:\n    name: str\n\nfn main():\n    let mut t: Table<Item> = Table<Item>()\n    t.push(Item(\"seed\"))\n    \
               let mut i: i32 = 0\n    while i < 2000000:\n        t[999] = Item(concat(\"x\", \"y\"))\n        i += 1\n    \
               println(\"done\")\n";
    assert_no_leak("table_oob_write_leak", src, 25 * 1024 * 1024);
}

/// Same bug class, one field deep (todo.md P2 #10's new
/// `table[i].field = v` write path): `store_table_field`'s dedicated
/// bounds-check-and-branch (`crate::codegen::table`) must release an
/// out-of-bounds row's already-owned RHS value instead of storing it into
/// `emit_table_field_place`'s disconnected dummy alloca, which nothing else
/// ever reads or releases -- the exact leak `store_genref_field`/
/// `store_table_index`/`store_list_index` already close for their own
/// out-of-bounds write paths, now needed for this newly-supported one too.
#[test]
fn runtime_table_field_out_of_bounds_write_does_not_leak_end_to_end() {
    let src = "struct Item:\n    mut name: str\n\nfn main():\n    let mut t: Table<Item> = Table<Item>()\n    t.push(Item(name = \"seed\"))\n    \
               let mut i: i32 = 0\n    while i < 2000000:\n        t[999].name = concat(\"x\", \"y\")\n        i += 1\n    \
               println(f\"done name={t[0].name}\")\n";
    assert_no_leak("table_field_oob_write_leak", src, 25 * 1024 * 1024);
}

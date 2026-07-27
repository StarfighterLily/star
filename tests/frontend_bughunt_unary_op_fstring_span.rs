//! Bug-hunting round: unary operator / f-string span audit
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Bug-hunting round: unary operator / f-string span audit ============

/// `Expr::Unary`'s `Neg` arm used to accept *any* operand type -- it just
/// preserved whatever type the operand already had, with no legality check
/// at all (unlike binary `-`, which already routes through
/// `infer_binop_ty`'s real type-compatibility check). `-s` on a `str` (or a
/// struct, `List<T>`, `GenRef<T>`, ...) type-checked cleanly and only failed
/// later with an unlocated "unsupported operand types for binary operator"
/// error once `Codegen::emit_binop` actually saw it -- confirmed via a real
/// `star build` before this fix. Fixed by reusing `infer_binop_ty`'s own
/// `Sub` legality check (`-x` lowers to exactly `0 - x`), which both rejects
/// this with a real source location and preserves every previously-legal
/// case (numeric scalars of every width, `Wrapping<T>`, `Fixed<Bits,Frac>`,
/// `Vec2`/`Vec3`/`Vec4`, `Mat4`).
#[test]
fn rejects_unary_negation_of_a_str_value() {
    let src = "fn main():\n    let s: str = \"hello\"\n    let neg = -s\n    println(neg)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("negating a `str` should be a type error");
    assert!(diags.iter().any(|d| d.message.contains("`-` is not supported between") && d.message.contains("Str")), "{:?}", diags);
}

/// Unlike `str` above, a struct operand now gets its own dedicated message
/// (rather than falling through to `infer_binop_ty`'s generic "not supported
/// between" phrasing) pointing at the `Neg` trait -- added alongside operator
/// overloading, see `Expr::Unary`'s own `UnOp::Neg` arm doc comment for why a
/// struct is special-cased out of `infer_binop_ty(Sub, ...)` entirely rather
/// than reusing that same check.
#[test]
fn rejects_unary_negation_of_a_struct_value() {
    let src = "struct Point:\n    x: i32\nfn main():\n    let p = Point(1)\n    let neg = -p\n    println(f\"{neg.x}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("negating a struct should be a type error");
    assert!(diags.iter().any(|d| d.message.contains("unary `-` is not supported") && d.message.contains("Neg")), "{:?}", diags);
}

/// `Codegen::emit_unary`'s `Neg` case built its `0` operand for `0 - x` via
/// an unconditional `format!("{} 0", self.llvm_ty(&operand_ty))` -- correct
/// for a scalar (`i32 0`), but a vector/matrix's LLVM type is `<N x float>`/
/// `[4 x <4 x float>]`, so this produced a bare scalar `0` used as a vector
/// operand (`fsub <2 x float> 0, %t11`), malformed IR `clang` rejected
/// outright. Confirmed via a real `star build` failure before this fix.
/// Fixed by reusing `Codegen::zero_value` (already correct for every type,
/// including `zeroinitializer` for vectors/matrices) instead of the
/// ad-hoc scalar-only fallback.
#[test]
fn runtime_unary_negation_of_vectors_end_to_end() {
    let src = "fn main():\n    \
               let v2: Vec2 = Vec2(1.0, -2.5)\n    let n2 = -v2\n    println(f\"{n2.x} {n2.y}\")\n    \
               let v3: Vec3 = Vec3(1.0, 2.0, 3.0)\n    let n3 = -v3\n    println(f\"{n3.x} {n3.y} {n3.z}\")\n    \
               let v4: Vec4 = Vec4(1.0, 2.0, 3.0, 4.0)\n    let n4 = -v4\n    println(f\"{n4.x} {n4.y} {n4.z} {n4.w}\")\n";
    let output = compile_and_run("unary_neg_vectors", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(
        lines,
        vec!["-1.000000 2.500000", "-1.000000 -2.000000 -3.000000", "-1.000000 -2.000000 -3.000000 -4.000000"],
        "{}",
        stdout
    );
}

/// `Expr::Unary`'s `Not` arm used to return `Ty::Bool` unconditionally
/// regardless of the operand's real type -- `Codegen::emit_unary`'s `Not`
/// case unconditionally emits `xor i1 true, <operand>`, assuming an `i1`
/// operand, so `!5`/`!"x"`/`!my_struct` type-checked cleanly and only failed
/// later with an unlocated "defined with type 'iN' but expected 'i1'"
/// `clang` verifier error. Confirmed via a real `star build` failure before
/// this fix. Fixed by requiring the operand to actually be `bool`.
#[test]
fn rejects_not_operator_on_a_non_bool_value() {
    let src = "fn main():\n    let x: i32 = 5\n    let y = !x\n    println(f\"{y}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("`!`/`not` on a non-`bool` value should be a type error");
    assert!(diags.iter().any(|d| d.message.contains("`!`/`not` operand must be `bool`")), "{:?}", diags);
}

#[test]
fn runtime_not_operator_on_bool_still_works_end_to_end() {
    let src = "fn main():\n    let b: bool = true\n    println(f\"{!b}\")\n    println(f\"{not false}\")\n";
    let output = compile_and_run("not_operator_bool", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["false", "true"], "{}", stdout);
}

/// A checker error for an expression inside an f-string interpolation hole
/// (`f"{...}"`) used to always report a bogus span, typically landing near
/// the very start of the file regardless of where the hole actually was.
/// `Parser::lower_fstring` re-lexes each hole's *extracted substring*
/// through a fresh `Lexer` to parse it -- that sub-lexer's spans started
/// counting from byte 0 as if the hole were its own standalone one-off
/// file, but those byte offsets were then looked straight up against the
/// *outer* file's real, much larger source text when a diagnostic was
/// rendered, landing on unrelated (usually very early) content. Confirmed
/// via a real `Driver::check` before this fix always reporting `span.start
/// == 0` here regardless of the hole's actual position. Fixed by threading
/// the hole's real starting byte offset (already known to
/// `Lexer::scan_fstring`) through a new `Lexer::new_with_offset`.
#[test]
fn checker_error_inside_fstring_hole_reports_correct_span() {
    let src = "fn main():\n    let a: List<i32> = List<i32>()\n    let b: List<i32> = List<i32>()\n    println(f\"{a == b}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("`==` on `List<i32>` should be a type error");
    let d = diags.iter().find(|d| d.message.contains("is not supported between")).expect("expected the `==` type error");
    let expected_start = src.find("a == b").unwrap();
    assert_eq!(d.span.start, expected_start, "span should point at `a == b` inside the f-string hole: {:?}", diags);
}

/// Same fix, one level deeper: a hole nested inside another hole
/// (`f"{f"{...}"}"`) must fold *both* offsets together (the inner hole's
/// offset within the already-offset outer hole, plus that outer hole's own
/// offset within the real file) -- `Lexer::scan_fstring` folds in its own
/// `base_offset` when recording a nested hole's starting position for
/// exactly this reason.
#[test]
fn checker_error_inside_nested_fstring_hole_reports_correct_span() {
    let src = "fn main():\n    let a: List<i32> = List<i32>()\n    let b: List<i32> = List<i32>()\n    println(f\"outer {f\"inner {a == b}\"}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("`==` on `List<i32>` should be a type error");
    let d = diags.iter().find(|d| d.message.contains("is not supported between")).expect("expected the `==` type error");
    let expected_start = src.find("a == b").unwrap();
    assert_eq!(d.span.start, expected_start, "span should point at `a == b` inside the nested f-string hole: {:?}", diags);
}

// --- Bug-hunting round: numeric builtins, par/swarm, sequence, Table<T>, ---
// --- RC leaks, and cross-file diagnostics -----------------------------------
//
// Four parallel deep audits (numeric types/checker; List/Map/Set/Table/Ring/
// Array collections; the memory model/RC; concurrency/modules/parser/lexer/
// file-IO), each required to reproduce every candidate bug via a real
// `star build`+run before it was reported. Nine confirmed bugs, covered
// below.

/// `clamp(x, lo, hi)` previously hardcoded `i32`/`float` opcodes regardless
/// of the argument's real type (`Codegen::emit_clamp`'s doc comment used to
/// say "for `i32`/`f32`" even though the checker's `is_numeric()` gate
/// accepts every numeric width) -- any other type produced malformed IR
/// `clang` rejected outright (a tagged `i32`/`float` operand feeding an
/// opcode that expected the argument's real width). Confirmed via a real
/// `star build` failure on `clamp(500 as i64, 0 as i64, 100 as i64)` before
/// this fix. Now width/signedness-generic like `emit_minmax`/`emit_abs`.
#[test]
fn runtime_clamp_on_every_numeric_width_end_to_end() {
    let src = "fn main():\n    \
               let a: i64 = clamp(500 as i64, 0 as i64, 100 as i64)\n    println(f\"{a}\")\n    \
               let b: u8 = clamp(3 as u8, 10 as u8, 20 as u8)\n    println(f\"{b}\")\n    \
               let c: f64 = clamp(5.5 as f64, 0.0 as f64, 10.0 as f64)\n    println(f\"{c}\")\n";
    let output = compile_and_run("clamp_every_width", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["100", "10", "5.500000"], "{}", stdout);
}

/// `min(a, b)`/`max(a, b)` on `f64` arguments previously narrowed through
/// `promote_to_float` (down to `f32`) but still tagged the result `"float
/// "`, so an `F64`-typed call site received a value tagged `float` -- any
/// consumer that untagged it as `Ty::F64` (expecting `"double "`) produced
/// malformed IR (`store double float %t9, double* %t4`, a `clang`-rejected
/// double-tagged operand). Confirmed via a real `star build` failure on
/// `min(3.5 as f64, 7.5 as f64)` before this fix. Now dispatches to the
/// `llvm.minnum.f64`/`llvm.maxnum.f64` intrinsics and tags the result
/// `double`, matching `builtin_return_ty`'s "preserve the operand type"
/// contract.
#[test]
fn runtime_min_max_on_f64_end_to_end() {
    let src = "fn main():\n    \
               let a: f64 = 3.5 as f64\n    let b: f64 = 7.5 as f64\n    \
               println(f\"{min(a, b)}\")\n    println(f\"{max(a, b)}\")\n";
    let output = compile_and_run("min_max_f64", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["3.500000", "7.500000"], "{}", stdout);
}

/// `abs(i8::MIN)` (`abs(-128 as i8)`) previously used a raw, untrapped `sub
/// {ity} 0, {bare}` instead of routing through the same checked-arithmetic
/// path real binary `-`/unary `-` use -- every explicit-width signed
/// integer type traps on overflow by default, and `abs(MIN)` is exactly the
/// one input where `0 - x` overflows. Confirmed via `abs(-128 as i8)`
/// printing `-128` with exit 0 (silent wraparound, no trap) before this
/// fix, where the equivalent direct `(0 as i8) - (-128 as i8)` already
/// correctly trapped.
#[test]
fn runtime_abs_of_signed_min_traps_end_to_end() {
    let src = "fn main():\n    println(\"before\")\n    let a: i8 = -128 as i8\n    let r = abs(a)\n    println(f\"unreachable {r}\")\n";
    let output = compile_and_run("abs_signed_min_traps", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(stdout.contains("signed 8-bit integer overflow"), "should report an overflow trap: {}", stdout);
    assert!(!stdout.contains("unreachable"), "abs(i8::MIN) must abort before its wrapped value is used: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}

/// `abs` on every other numeric width (not just the `MIN`-boundary case
/// above) still behaves correctly after routing the signed-integer branch
/// through `emit_binop` -- a plain regression guard that ordinary,
/// non-overflowing `abs` calls weren't broken by that fix.
#[test]
fn runtime_abs_on_every_numeric_width_end_to_end() {
    let src = "fn main():\n    \
               println(f\"{abs(-42 as i64)}\")\n    println(f\"{abs(5 as u8)}\")\n    \
               println(f\"{abs(-3.5 as f64)}\")\n    println(f\"{abs(-7)}\")\n";
    let output = compile_and_run("abs_every_width", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["42", "5", "3.500000", "7"], "{}", stdout);
}

/// `par`/`swarm`'s disjointness proof previously only ever extracted an
/// assignment target's *root* identifier (`root_ident`) to decide whether a
/// write is to a safe body-local -- it never walked any *index*
/// sub-expression nested inside the target itself, so a hazardous call
/// (one that transitively `spawn`s, otherwise unconditionally banned
/// anywhere else in a par/swarm body) hidden inside an assignment target's
/// index expression (`arr[hazard()] = 1`) went completely unchecked, a
/// soundness hole letting an unsynchronized-across-worker-threads race
/// compile silently. Confirmed via a real `star check` accepting this
/// program (exit 0) before this fix, where the identical hazardous call in
/// a `let` value position was already correctly rejected.
#[test]
fn rejects_par_hazard_call_hidden_in_assignment_target_index() {
    let src = "struct Enemy:\n    mut hp: i32\n\narena Enemies: Enemy\n\n\
               fn hazard() -> i32:\n    spawn Enemies(0)\n    return 0\n\n\
               fn main():\n    for i in 0..8:\n        spawn Enemies(100)\n    \
               par e in Enemies:\n        let mut arr: [i32; 4] = [0; 4]\n        arr[hazard()] = 1\n        e.hp -= 1\n    \
               println(f\"done\")\n";
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("a spawn-hazard call hidden in an assignment target's index must be rejected");
    assert!(
        errs.iter().any(|d| d.message.contains("hazard") && d.message.contains("cannot be proven disjoint")),
        "{:?}",
        errs
    );
}

/// Companion control for the fix above: the exact same hazardous call in an
/// ordinary `let` value position was already rejected before this fix, and
/// must remain rejected after it -- guards against the new
/// `walk_par_assign_target` walk accidentally being the *only* path that
/// catches this class of hazard.
#[test]
fn rejects_par_hazard_call_in_let_value_control() {
    let src = "struct Enemy:\n    mut hp: i32\n\narena Enemies: Enemy\n\n\
               fn hazard() -> i32:\n    spawn Enemies(0)\n    return 0\n\n\
               fn main():\n    for i in 0..8:\n        spawn Enemies(100)\n    \
               par e in Enemies:\n        let x = hazard()\n        e.hp -= 1\n    \
               println(f\"done\")\n";
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("a spawn-hazard call in a let value should be rejected");
    assert!(errs.iter().any(|d| d.message.contains("hazard") && d.message.contains("cannot be proven disjoint")), "{:?}", errs);
}

/// A `yield` hidden inside a `match`-as-expression used as an `if`
/// condition previously fell all the way through to the generic
/// type-checker fallback (a less specific "`yield` is only valid at the top
/// level of a `sequence` body" message, wrong-sounding since this *is*
/// nominally the top level) instead of `sequence.rs`'s own dedicated,
/// better diagnostic every sibling nested construct (`if`/`while`/`frame`/
/// `for`/`par`/`swarm`/`match` bodies) already gets --
/// `scan_for_nested_yield`'s `If`/`While` arms never scanned the condition
/// expression itself, only the body blocks. Not a soundness bug (the
/// program was still correctly rejected either way), but confirmed via a
/// real `star check` reporting the generic fallback message before this
/// fix.
#[test]
fn sequence_yield_in_if_condition_reports_dedicated_diagnostic() {
    let src = "sequence Seq():\n    let mut x: i32 = 0\n    if match x:\n        0 ->\n            yield\n            true\n        _ ->\n            false\n    :\n        x = 1\n    yield\n\nfn main():\n    let mut s = Seq()\n    println(f\"{s.resume()}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("a yield nested inside a match-as-if-condition should still be rejected");
    assert!(
        errs.iter().any(|d| d.message.contains("only supported at the top level") && d.message.contains("if")),
        "expected the dedicated nested-yield diagnostic, not the generic fallback: {:?}",
        errs
    );
}

/// `t[i].tags[j] = v` (a `List<i32>` field of a `Table<T>` element, indexed
/// one level further) must actually reach the real column: `emit_place`'s
/// `ListIndex` arm (`emit_list_index_place`) resolves the list's own `i8*`
/// slot via `self.emit_place(base)`, where `base` is `t[i].tags` -- since
/// that now resolves (via `emit_table_field_place`) to a real pointer into
/// the `tags` column at row `i` rather than a disconnected copy, the CoW
/// clone-and-write happens on the genuine backing storage, and the mutation
/// is observable afterward.
#[test]
fn runtime_table_field_list_index_write_through_index_end_to_end() {
    let src = "struct Row:\n    mut tags: List<i32>\n\nfn main():\n    \
               let mut t: Table<Row> = Table<Row>()\n    t.push(Row(tags = [1, 2, 3]))\n    \
               t[0].tags[0] = 99\n    println(f\"{t[0].tags[0]}\")\n";
    let output = compile_and_run("table_field_list_index_write_through_index", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "99");
}

/// Same fix, an array field (`[i32; N]`) instead of a `List<i32>` one --
/// `emit_array_index_place` resolves its base pointer via `self.emit_place(base)`
/// too, composing with `emit_table_field_place` the same way.
#[test]
fn runtime_table_field_array_index_write_through_index_end_to_end() {
    let src = "struct Row:\n    mut cells: [i32; 4]\n\nfn main():\n    \
               let mut t: Table<Row> = Table<Row>()\n    t.push(Row(cells = [0; 4]))\n    \
               t[0].cells[0] = 999\n    println(f\"{t[0].cells[0]}\")\n";
    let output = compile_and_run("table_field_array_index_write_through_index", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "999");
}

/// Same fix, a compound assignment (`+=`) through the same chain --
/// `Stmt::Assign` handles every `AssignOp` through the identical
/// `target_typed`/`load_target`/`store_target` codegen, so this needed no
/// separate wiring once the plain-`=` shape worked.
#[test]
fn runtime_table_compound_assign_through_table_index_field_list_index_chain_end_to_end() {
    let src = "struct Row:\n    mut tags: List<i32>\n\nfn main():\n    \
               let mut t: Table<Row> = Table<Row>()\n    t.push(Row(tags = [1, 2, 3]))\n    \
               t[0].tags[0] += 100\n    println(f\"{t[0].tags[0]}\")\n";
    let output = compile_and_run("table_compound_assign_through_table_index_field_list_index_chain", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "101");
}

/// Control for the three fixes above: the whole-element write
/// `table[i] = v` (the one genuinely supported `Table<T>` mutation path
/// before this round) must remain accepted -- guards against the new
/// `emit_place`/`emit_table_field_place` wiring somehow overreaching.
#[test]
fn runtime_table_whole_element_write_still_works_end_to_end() {
    let src = "struct Row:\n    mut tags: List<i32>\n\nfn main():\n    \
               let mut t: Table<Row> = Table<Row>()\n    t.push(Row(tags = [1, 2, 3]))\n    \
               t[0] = Row(tags = [9, 9, 9])\n    println(f\"{t[0].tags[0]}\")\n";
    let output = compile_and_run("table_whole_element_write_control", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "9");
}

/// `[T; N]`/`Ring<T,N>` element reads previously retained a reference (both
/// codegen paths already call `emit_retain_at` on read, correctly) but
/// `Codegen::is_rc_borrowing_read` -- consulted by every *transient*
/// consumer (`len(..)`, `println(..)`, an f-string hole, `concat(..)`) to
/// decide whether to balance that retain back out with a release -- omitted
/// `ArrayIndex`/`RingIndex` from its match list, so every such read leaked
/// one reference permanently. Confirmed via real unbounded working-set
/// growth (~112MB -> 884MB over 30,000,000 iterations of `len(ring[0])` on
/// a `Ring<str,1>`) before this fix; this test uses a much smaller
/// iteration count suited to a unit-test time budget, relying on
/// `assert_no_leak`'s working-set-delta check rather than reproducing the
/// full-scale growth directly.
#[test]
fn runtime_ring_index_read_does_not_leak_end_to_end() {
    let src = "fn main():\n    \
               let mut buf: Ring<str, 1> = Ring<str, 1>()\n    buf.push(concat(\"seed\", \"0\"))\n    \
               let mut i: i32 = 0\n    let mut total: i32 = 0\n    while i < 400000:\n        \
               total = total + len(buf[0])\n        buf.push(concat(\"item\", \"x\"))\n        i += 1\n    \
               println(\"done\")\n";
    assert_no_leak("ring_index_read_leak", src, 20 * 1024 * 1024);
}

/// Same bug, the `[T; N]` array case (`emit_array_index`'s own missing
/// entry in `is_rc_borrowing_read`'s match list).
#[test]
fn runtime_array_index_read_does_not_leak_end_to_end() {
    let src = "fn main():\n    \
               let mut buf: [str; 1] = [\"seed\"; 1]\n    \
               let mut i: i32 = 0\n    let mut total: i32 = 0\n    while i < 400000:\n        \
               total = total + len(buf[0])\n        buf[0] = concat(\"item\", \"x\")\n        i += 1\n    \
               println(\"done\")\n";
    assert_no_leak("array_index_read_leak", src, 20 * 1024 * 1024);
}

/// `table[i].field` (a `Table<T>` element field read) previously
/// double-retained: `emit_table_index` (reached via `emit_place`'s generic
/// fallback, since `TableIndex` has no dedicated place arm -- a table
/// element has no single contiguous storage) already retains every
/// RC-bearing field while reassembling the struct copy, correctly treating
/// it as a fresh, independently-owned value -- but the outer `Field` read
/// then retained *again*, treating the already-owned copy as if it were a
/// borrowed read of persistent storage. Any single downstream release only
/// cancels one of the two retains, leaking one reference per read.
/// Confirmed via real unbounded working-set growth (~58MB -> 283MB over
/// 10,000,000 iterations) before this fix; fixed via
/// `Codegen::place_is_shared_storage`, which the `Field`/`TupleIndex`/
/// `ArrayIndex`/`RingIndex` read arms now consult before retaining.
#[test]
fn runtime_table_field_read_does_not_leak_end_to_end() {
    let src = "struct Enemy:\n    mut hp: i32\n    name: str\n\nfn main():\n    \
               let mut enemies: Table<Enemy> = Table<Enemy>()\n    enemies.push(Enemy(hp = 1, name = concat(\"seed\", \"0\")))\n    \
               let mut i: i32 = 0\n    let mut total: i32 = 0\n    while i < 300000:\n        \
               total = total + len(enemies[0].name)\n        enemies[0] = Enemy(hp = i, name = concat(\"item\", \"x\"))\n        i += 1\n    \
               println(\"done\")\n";
    assert_no_leak("table_field_read_leak", src, 20 * 1024 * 1024);
}

/// The same double-retain bug class, reached without `Table<T>` at all: any
/// struct-returning call chained directly into a `.field` access (no `let`
/// binding of its own) hits the identical `emit_place` generic-fallback
/// path (a freshly spilled, already-owned temporary) that `table[i].field`
/// does -- `Codegen::place_is_shared_storage` returning `false` for a
/// `Call` base fixes both at once. Confirmed via real unbounded working-set
/// growth (~280MB -> 408MB in under a second) on `make(i).name` before this
/// fix.
#[test]
fn runtime_call_result_field_read_does_not_leak_end_to_end() {
    let src = "struct Holder:\n    name: str\n\nfn make(n: i32) -> Holder:\n    Holder(name = concat(\"item\", \"x\"))\n\n\
               fn main():\n    let mut i: i32 = 0\n    let mut total: i32 = 0\n    while i < 400000:\n        \
               total = total + len(make(i).name)\n        i += 1\n    println(\"done\")\n";
    assert_no_leak("call_result_field_read_leak", src, 20 * 1024 * 1024);
}

/// Control for the two double-retain fixes above: reading a field off a
/// real, persistent local (an `Ident` base, not a freshly spilled
/// temporary) must still retain -- guards against
/// `place_is_shared_storage`'s `Ident`/`SelfExpr`/`GenRefIndex` arms (or the
/// recursive `Field`/`TupleIndex`/`ArrayIndex`/`RingIndex`/`ListIndex`
/// peel-through) being wrong and under-retaining a genuine read, which
/// would show up as a use-after-free/premature release instead of a leak --
/// this test's oracle is correct *output*, not just flat memory, so a
/// double-free corrupting `name` would fail the string-equality assertion.
#[test]
fn runtime_local_struct_field_read_still_retains_end_to_end() {
    let src = "struct Holder:\n    mut name: str\n\nfn main():\n    \
               let h = Holder(name = concat(\"hello\", \" world\"))\n    \
               let mut i: i32 = 0\n    let mut last: str = \"\"\n    while i < 200000:\n        \
               last = h.name\n        i += 1\n    println(last)\n";
    let output = compile_and_run("local_struct_field_read_control", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "hello world");
}

/// The other half of the same generic-fallback story `place_is_shared_storage`
/// was introduced for (see the two tests above): the *sibling*-field leak
/// that fix itself was still missing. `Codegen::emit_place`'s generic
/// fallback (reached whenever a struct-returning `Call`/`If`/`Match`/
/// `TableIndex` is used directly as a `Field`/`TupleIndex`/`ArrayIndex`/
/// `RingIndex` base with no intervening `let`) spills the freshly-owned
/// value into a scratch `alloca` and only ever `track_owned`'d it when its
/// type was `List`/`Map`/`Set`/`Table` -- for every other RC-bearing type
/// (a plain struct/tuple/array/ring), the read arms deliberately skipped
/// retaining the *one* field actually extracted (relying on nothing ever
/// releasing that spilled temporary to balance a retain back out), but
/// that same "nothing ever releases it" left every *other* RC-bearing field
/// of that temporary permanently unreleased -- a real leak whenever the
/// struct/tuple/array carried two or more RC-bearing leaves and only one
/// was ever read back out. `Table<T>`'s own `TableIndex`/`TableMethod::Pop`
/// (also routed through this same fallback, since a table element has no
/// single contiguous place of its own) inherited the identical gap for any
/// `T` with 2+ RC fields. Confirmed via real unbounded working-set growth
/// (~3MB flat control vs. ~790MB in under 4 seconds of 30,000,000
/// iterations of `make().a`, where `make()` returns a two-`str`-field
/// struct and only field `a` is ever read) before this fix. Fixed by always
/// `track_owned`-ing the fallback's spilled temporary for *any*
/// `contains_rc` type (not just the four collection types) paired with
/// retaining unconditionally on every `Field`/`TupleIndex`/`ArrayIndex`/
/// `RingIndex` read (removing the `place_is_shared_storage` guard
/// entirely): the two together reproduce plain `Ident`-field-read semantics
/// for a temporary exactly, so the accessed field ends up owned by its new
/// owner while every unaccessed sibling is correctly released once the
/// temporary's own tracked scope ends.
#[test]
fn runtime_multi_rc_field_temp_struct_read_does_not_leak_sibling_end_to_end() {
    let src = "struct Pair:\n    a: str\n    b: str\n\n\
               fn make() -> Pair:\n    Pair(a = concat(\"hello\", \"world\"), b = concat(\"foo\", \"bar\"))\n\n\
               fn main():\n    let mut i: i32 = 0\n    let mut total: i32 = 0\n    while i < 400000:\n        \
               total = total + len(make().a)\n        i += 1\n    println(\"done\")\n";
    assert_no_leak("multi_rc_field_temp_struct_sibling_leak", src, 20 * 1024 * 1024);
}

/// The same sibling-field leak, reached through `Table<T>::pop()` instead of
/// a plain function call -- `TableMethod::Pop` also reassembles the whole
/// element (moving every field's ownership into the returned struct with no
/// retain, mirroring `ListMethod::Pop`) and is reached through the exact
/// same `emit_place` generic fallback when only one field of the popped
/// struct is read (`t.pop().name`, `tag` never touched). Confirmed via real
/// unbounded working-set growth (~3MB flat vs. ~96MB over 5,000,000
/// iterations of push-then-`pop().name` on a two-`str`-field element,
/// discovered while root-causing the more general `make().a` leak above)
/// before this fix.
#[test]
fn runtime_table_pop_field_read_does_not_leak_sibling_end_to_end() {
    let src = "struct Item:\n    name: str\n    tag: str\n\nfn main():\n    \
               let mut t: Table<Item> = Table<Item>()\n    let mut i: i32 = 0\n    let mut total: i32 = 0\n    while i < 400000:\n        \
               t.push(Item(name = concat(\"nm\", \"xx\"), tag = concat(\"tg\", \"yy\")))\n        \
               total = total + len(t.pop().name)\n        i += 1\n    println(\"done\")\n";
    assert_no_leak("table_pop_field_read_sibling_leak", src, 20 * 1024 * 1024);
}

/// Correctness control for the sibling-field fix above: both fields of a
/// multi-RC-field struct temporary must independently read back correct,
/// uncorrupted values across many iterations -- guards against the fix
/// over-correcting into a double-release (retaining unconditionally, then
/// releasing the whole temporary, could double-free the accessed field if
/// the two weren't properly balanced) or under-releasing the sibling (which
/// would leak rather than corrupt, already covered by the leak test above,
/// but this test's oracle is *output correctness*, catching a
/// use-after-free/heap-corruption failure mode the leak test's flat-memory
/// oracle cannot).
#[test]
fn runtime_multi_rc_field_temp_struct_read_correctness_end_to_end() {
    let src = "struct Pair:\n    a: str\n    b: str\n\n\
               fn make() -> Pair:\n    Pair(a = concat(\"hello\", \"world\"), b = concat(\"foo\", \"bar\"))\n\n\
               fn main():\n    let mut i: i32 = 0\n    let mut last_a: str = \"\"\n    let mut last_b: str = \"\"\n    \
               while i < 5:\n        last_a = make().a\n        last_b = make().b\n        i += 1\n    \
               println(last_a)\n    println(last_b)\n";
    let output = compile_and_run("multi_rc_field_temp_struct_correctness", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["helloworld", "foobar"], "{}", stdout);
}

/// A checker/codegen diagnostic whose root cause lives inside an
/// **imported** file must render against *that* file's own source text --
/// not, as before this fix, unconditionally against the *importing* (root)
/// file's source at the same raw byte offset, landing on a wrong/garbled
/// location (`crate::modules::resolve`'s import-inlining pass preserves an
/// imported file's own byte-offset spans verbatim, but `Compilation` used
/// to store only the root file's source text and render every diagnostic
/// against it unconditionally). Confirmed via a real `star check` on a type
/// error inside an imported file rendering at `main.star:1:25` -- mid-way
/// through the `import` statement's string literal, nowhere near the real
/// `lib.star:2` error -- before this fix. Fixed via `Span::file_id` (stamped
/// by the lexer/parser at parse time, one id per distinct file) plus
/// `Compilation::imported_files`, so `render_diagnostics` looks up the
/// correct file per diagnostic.
#[test]
fn diagnostic_inside_imported_file_renders_against_that_files_own_source() {
    let dir = test_scratch_dir("diagnostic_inside_imported_file_renders_against_that_files_own_source");
    write_test_file(&dir, "lib.star", "fn broken() -> i32:\n    let x: i32 = \"not a number\"\n    return x\n");
    let main_path = write_test_file(&dir, "main.star", "import \"lib.star\" as lib\n\nfn main():\n    println(f\"hi\")\n");

    let compilation = Driver::new(main_path).compile().expect("file read should succeed");
    assert!(!compilation.is_ok(), "the imported file's type error should surface");
    let rendered = compilation.render_diagnostics();
    assert!(rendered.contains("lib.star"), "should render against the imported file's name, not main.star: {}", rendered);
    assert!(
        rendered.contains("let x: i32 = \"not a number\""),
        "should show the real offending line from lib.star, not a wrong/garbled snippet: {}",
        rendered
    );
    assert!(
        !rendered.contains("import \"lib.star\" as lib"),
        "must not render at the import statement's own line in main.star: {}",
        rendered
    );

    let _ = std::fs::remove_dir_all(&dir);
}

/// A diagnostic whose root cause is in the *root* file (no import involved
/// at all) must still render correctly -- guards against the `file_id`
/// plumbing regressing the overwhelmingly common single-file case.
#[test]
fn diagnostic_inside_root_file_still_renders_correctly() {
    let dir = test_scratch_dir("diagnostic_inside_root_file_still_renders_correctly");
    let main_path = write_test_file(&dir, "main.star", "fn main():\n    let x: i32 = \"oops\"\n");

    let compilation = Driver::new(main_path).compile().expect("file read should succeed");
    assert!(!compilation.is_ok());
    let rendered = compilation.render_diagnostics();
    assert!(rendered.contains("main.star:2:5"), "{}", rendered);
    assert!(rendered.contains("let x: i32 = \"oops\""), "{}", rendered);

    let _ = std::fs::remove_dir_all(&dir);
}

/// Import-resolution-level failures (a syntax error inside the imported
/// file itself, caught by `crate::modules::resolve_inner` before the
/// checker ever runs) already re-anchored on the importing file's own
/// `decl.span` before this round's fix, and must continue to -- this is a
/// deliberately different, working code path from the checker/codegen
/// diagnostic case above (see `resolve_inner`'s "Re-anchor on this level's
/// own (meaningful) span" comment), not something `file_id` changes.
#[test]
fn import_parse_error_still_reports_at_the_import_site() {
    let dir = test_scratch_dir("import_parse_error_still_reports_at_the_import_site");
    write_test_file(&dir, "broken_lib.star", "fn broken(:\n    return 1\n");
    let main_path = write_test_file(&dir, "main.star", "import \"broken_lib.star\" as lib\n\nfn main():\n    println(f\"hi\")\n");

    let compilation = Driver::new(main_path).compile().expect("file read should succeed");
    assert!(!compilation.is_ok());
    let rendered = compilation.render_diagnostics();
    assert!(rendered.contains("main.star"), "should re-anchor on the importing file: {}", rendered);
    assert!(rendered.contains("failed to parse import"), "{}", rendered);

    let _ = std::fs::remove_dir_all(&dir);
}

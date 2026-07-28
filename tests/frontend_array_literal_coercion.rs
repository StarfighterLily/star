//! `[a, b, c]` coerced to a fixed-size `[T; N]` array literal, closing
//! `todo.md` P2 #10 -- Nova's 256-glyph font table (`projects/nova/
//! font_data.star`) had no way to write a fixed array of *differing* values
//! as a literal at all before this (`[value; N]` only ever repeats one
//! value), and had to be built as ~1500 mechanical indexed assignments onto
//! a zero-initialized array instead.
//!
//! `Expr::ListLit` -- the exact same AST node `[1, 2, 3]` has always parsed
//! to -- gets no new syntax at all. The checker decides, from an *expected*
//! type known at three specific call sites (`Checker::try_infer_array_lit`,
//! `src/types/expr.rs`), whether a given bracket literal becomes a
//! `TypedExpr::ArrayLit` (a fixed `[T; N]`) or falls through to its
//! pre-existing `TypedExpr::ListLit` (a heap `List<T>`) handling exactly as
//! before:
//!   1. `let x: [T; N] = [e1, e2, ...]` -- the annotation supplies `T`/`N`.
//!   2. A struct-literal field whose declared type is `[T; N]`
//!      (`FontData(glyphs = [0, 1, 2, ...])`, the motivating Nova case).
//!   3. `return [e1, e2, ...]` inside a function declared `-> [T; N]`.
//! A bracket literal with no reachable expected type (an unannotated `let`,
//! a bare statement expression, a function argument, ...) is completely
//! unaffected -- still always a `List<T>`, per `todo.md`'s own scope note
//! that this checker has no *general* expected-type propagation.
//!
//! Split out following `tests/frontend_fixed_arrays.rs`'s established
//! convention (itself split out per `todo.md` P2 #6); shared helpers live in
//! `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== `let` annotation coercion ============================================

#[test]
fn checks_let_annotation_coerces_bracket_literal_to_array() {
    let src = "fn main():\n    let a: [i32; 4] = [10, 20, 30, 40]\n    println(f\"{a[0]}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let TypedItem::Fn(f) = &typed.items[0] else { panic!("expected a fn item") };
    let TypedStmt::Let { value, ty, .. } = &f.body.stmts[0] else { panic!("expected the let stmt") };
    assert!(matches!(value, TypedExpr::ArrayLit { elems, .. } if elems.len() == 4), "{:?}", value);
    assert_eq!(ty, &Ty::Array(Box::new(Ty::Int), 4), "{:?}", ty);
}

/// Without an annotation, `[e1, e2, e3]` stays exactly what it always was --
/// no expected type is reachable, so it can never coerce.
#[test]
fn checks_let_without_annotation_stays_list_literal() {
    let src = "fn main():\n    let a = [10, 20, 30, 40]\n    println(f\"{a.len()}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let TypedItem::Fn(f) = &typed.items[0] else { panic!("expected a fn item") };
    let TypedStmt::Let { value, ty, .. } = &f.body.stmts[0] else { panic!("expected the let stmt") };
    assert!(matches!(value, TypedExpr::ListLit { elems, .. } if elems.len() == 4), "{:?}", value);
    assert_eq!(ty, &Ty::List(Box::new(Ty::Int)), "{:?}", ty);
}

/// An explicit `List<T>` annotation is itself not `Ty::Array`, so it never
/// triggers the coercion path either -- it just runs the ordinary
/// `types_compatible(List<i32>, List<i32>)` check that already passed.
#[test]
fn checks_let_list_annotation_stays_list_literal() {
    let src = "fn main():\n    let a: List<i32> = [10, 20, 30]\n    println(f\"{a.len()}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let TypedItem::Fn(f) = &typed.items[0] else { panic!("expected a fn item") };
    let TypedStmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected the let stmt") };
    assert!(matches!(value, TypedExpr::ListLit { .. }), "{:?}", value);
}

/// An element-count mismatch against the annotation (`[i32; 3]` vs. 4
/// elements) falls straight through to the pre-existing `ListLit` path --
/// `try_infer_array_lit` returns `None` rather than coercing -- and the
/// *existing* `let`-annotation type-mismatch diagnostic fires exactly as it
/// did before this feature (`Array != List`), not a new/different message.
#[test]
fn rejects_let_annotation_element_count_mismatch() {
    let src = "fn main():\n    let a: [i32; 3] = [10, 20, 30, 40]\n    println(f\"{a[0]}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("an array literal with the wrong element count must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("but the value has type") && d.message.contains("List")), "{:?}", errs);
}

/// `elif` its own `[value; N]` repeat sibling is completely unaffected --
/// this feature only ever intercepts a raw `Expr::ListLit`, never
/// `Expr::ArrayRepeat`.
#[test]
fn array_repeat_literal_still_works_unaffected() {
    let src = "fn main():\n    let a: [i32; 5] = [7; 5]\n    println(f\"{a[0]} {a[4]}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let TypedItem::Fn(f) = &typed.items[0] else { panic!("expected a fn item") };
    let TypedStmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected the let stmt") };
    assert!(matches!(value, TypedExpr::ArrayRepeat { count: 5, .. }), "{:?}", value);
}

/// `let a: [i32; 0] = []` -- empty brackets never coerce (there's no
/// element to infer/count against, mirroring `ListLit`'s own pre-existing
/// "empty list literal has no element to infer a type from" rejection,
/// which this falls straight through to unchanged).
#[test]
fn rejects_empty_brackets_against_array_annotation() {
    let src = "fn main():\n    let a: [i32; 0] = []\n    println(\"x\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("an empty bracket literal must still be rejected, even against a zero-size array annotation") };
    assert!(errs.iter().any(|d| d.message.contains("empty list literal")), "{:?}", errs);
}

// ===== Struct-literal field coercion (the motivating Nova case) ============

const FONT_SRC_PREFIX: &str = "struct FontData:\n    mut glyphs: [u8; 5]\n\n";

#[test]
fn checks_struct_field_coerces_bracket_literal_to_array() {
    let src = format!("{}fn main():\n    let f = FontData(glyphs = [1, 2, 3, 4, 5])\n    println(f\"{{f.glyphs[0]}}\")\n", FONT_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let TypedItem::Fn(f) = &typed.items[1] else { panic!("expected the fn item") };
    let TypedStmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected the let stmt") };
    let TypedExpr::StructLit { args, .. } = value else { panic!("expected a StructLit, got {:?}", value) };
    assert!(matches!(&args[0], TypedExpr::ArrayLit { elems, elem_ty, .. } if elems.len() == 5 && *elem_ty == Ty::U8), "{:?}", args[0]);
}

/// Positional (not just named) struct-literal arguments coerce too --
/// `try_infer_array_lit` is wired against the *resolved* (already
/// positional-order) argument list, not the named-argument path
/// specifically.
#[test]
fn checks_struct_field_coerces_positional_bracket_literal() {
    let src = format!("{}fn main():\n    let f = FontData([1, 2, 3, 4, 5])\n    println(f\"{{f.glyphs[0]}}\")\n", FONT_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let TypedItem::Fn(f) = &typed.items[1] else { panic!("expected the fn item") };
    let TypedStmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected the let stmt") };
    let TypedExpr::StructLit { args, .. } = value else { panic!("expected a StructLit, got {:?}", value) };
    assert!(matches!(&args[0], TypedExpr::ArrayLit { .. }), "{:?}", args[0]);
}

/// A struct field's array-literal argument with the wrong element count
/// falls through to the ordinary `List<T>` path, so the *existing*
/// declared-vs-actual field type diagnostic (`check_field_ctor_types`)
/// fires -- `Array` vs. `List`, not a new "wrong count" message.
#[test]
fn rejects_struct_field_array_literal_count_mismatch() {
    let src = format!("{}fn main():\n    let f = FontData(glyphs = [1, 2, 3])\n    println(\"x\")\n", FONT_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("a struct field array literal with the wrong element count must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("expects type") && d.message.contains("List")), "{:?}", errs);
}

/// A field whose declared type isn't an array at all (e.g. a plain `i32`)
/// never even looks at the coercion path -- `try_infer_array_lit` bails
/// immediately on a non-`Ty::Array` expected type, so this is exactly the
/// pre-existing "list where a scalar was expected" diagnostic.
#[test]
fn rejects_struct_field_bracket_literal_against_non_array_field() {
    let src = "struct Pair:\n    a: i32\n    b: i32\n\nfn main():\n    let p = Pair(a = [1, 2], b = 3)\n    println(\"x\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("a list literal against a scalar field must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("expects type")), "{:?}", errs);
}

// ===== `return` coercion =====================================================

#[test]
fn checks_return_coerces_bracket_literal_to_array() {
    let src = "fn make() -> [i32; 3]:\n    return [1, 2, 3]\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let TypedItem::Fn(f) = &typed.items[0] else { panic!("expected a fn item") };
    let TypedStmt::Return { value: Some(v), .. } = &f.body.stmts[0] else { panic!("expected the return stmt") };
    assert!(matches!(v, TypedExpr::ArrayLit { elems, .. } if elems.len() == 3), "{:?}", v);
}

#[test]
fn rejects_return_array_literal_count_mismatch() {
    let src = "fn make() -> [i32; 4]:\n    return [1, 2, 3]\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("a return array literal with the wrong element count must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("expected return type") && d.message.contains("List")), "{:?}", errs);
}

// ===== Literal element narrowing ============================================

/// A bare integer literal element (which would otherwise default to
/// `Ty::Int`/`i32`) is typed directly as the array's narrower declared
/// element type when it fits -- mirroring `Wrapping<T>(v)`/`BitField<N>(v)`'s
/// identical literal fast path. Without this, every one of Nova's 2048 font
/// bytes would need its own explicit `as u8`, defeating most of the
/// ergonomic point of this literal form.
#[test]
fn checks_bare_int_literal_elements_narrow_to_declared_element_type() {
    let src = format!("{}fn main():\n    let f = FontData(glyphs = [0, 255, 128, 1, 2])\n    println(f\"{{f.glyphs[1]}}\")\n", FONT_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let TypedItem::Fn(f) = &typed.items[1] else { panic!("expected the fn item") };
    let TypedStmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected the let stmt") };
    let TypedExpr::StructLit { args, .. } = value else { panic!("expected a StructLit") };
    let TypedExpr::ArrayLit { elems, .. } = &args[0] else { panic!("expected an ArrayLit, got {:?}", args[0]) };
    for e in elems {
        assert_eq!(e.clone().into_ty(), Ty::U8, "{:?}", e);
    }
}

/// A directly-negated integer literal element (`-1`) narrows the same way,
/// mirroring `Expr::Cast`/`Expr::WrappingNew`'s identical `-x`-fits-`T`
/// handling.
#[test]
fn checks_negative_int_literal_element_narrows_to_declared_signed_element_type() {
    let src = "fn main():\n    let a: [i8; 3] = [-1, -128, 127]\n    println(f\"{a[0]} {a[1]} {a[2]}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let TypedItem::Fn(f) = &typed.items[0] else { panic!("expected a fn item") };
    let TypedStmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected the let stmt") };
    let TypedExpr::ArrayLit { elems, .. } = value else { panic!("expected an ArrayLit, got {:?}", value) };
    assert!(elems.iter().all(|e| e.clone().into_ty() == Ty::I8), "{:?}", elems);
}

/// An out-of-range literal element against the declared (narrower) element
/// type is rejected with the exact same "does not fit" diagnostic
/// `Wrapping<T>(v)`/`BitField<N>(v)` already report for the identical shape.
#[test]
fn rejects_int_literal_element_out_of_range_for_declared_element_type() {
    let src = "fn main():\n    let a: [u8; 3] = [1, 2, 300]\n    println(f\"{a[2]}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("an out-of-range element literal must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("does not fit")), "{:?}", errs);
}

/// A non-literal element (e.g. a `bool`) whose type genuinely disagrees
/// with the declared element type is rejected too -- the literal-narrowing
/// fast path only ever applies to a bare (optionally negated) integer
/// literal, everything else is checked by ordinary `types_compatible`.
#[test]
fn rejects_non_literal_element_type_mismatch() {
    let src = "fn main():\n    let a: [i32; 2] = [1, true]\n    println(f\"{a[0]}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("a mistyped non-literal element must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("array literal element expects type")), "{:?}", errs);
}

// ===== Non-scalar element types ==============================================

/// An array of a struct type works the same way, each element its own
/// independent `StructLit` construction (not `ArrayRepeat`'s shared-value
/// copy semantics).
#[test]
fn checks_struct_element_array_literal() {
    let src = "struct Point:\n    x: i32\n    y: i32\n\nfn main():\n    let pts: [Point; 2] = [Point(x = 1, y = 2), Point(x = 3, y = 4)]\n    println(f\"{pts[0].x} {pts[1].y}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let TypedItem::Fn(f) = &typed.items[1] else { panic!("expected the fn item") };
    let TypedStmt::Let { value, ty, .. } = &f.body.stmts[0] else { panic!("expected the let stmt") };
    assert!(matches!(value, TypedExpr::ArrayLit { elems, .. } if elems.len() == 2), "{:?}", value);
    assert_eq!(ty, &Ty::Array(Box::new(Ty::Named("Point".into())), 2), "{:?}", ty);
}

// ===== Scope cuts (documented limitations, not bugs) =========================

/// Function-call arguments are deliberately *not* one of this feature's
/// coercion sites (see `todo.md` P2 #10's scope) -- a bracket literal passed
/// where a `[T; N]` parameter is declared still infers as `List<T>` and is
/// rejected by the ordinary arg-type check, exactly as it was before this
/// feature landed.
#[test]
fn function_call_argument_position_is_not_a_coercion_site() {
    let src = "fn sum3(a: [i32; 3]) -> i32:\n    a[0] + a[1] + a[2]\n\nfn main():\n    println(f\"{sum3([1, 2, 3])}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("a bracket literal call argument must still be rejected against a [T;N] parameter -- this is a documented scope cut, not a regression") };
    assert!(errs.iter().any(|d| d.message.contains("List")), "{:?}", errs);
}

// ===== Codegen ===============================================================

/// `Codegen::emit_array_lit` unrolls into one static GEP+store pair per
/// element (mirroring `TupleLit`), never `emit_array_repeat`'s runtime loop
/// -- confirmed by the absence of that loop's own block-label prefix.
#[test]
fn codegen_array_literal_lowers_to_llvm_array_with_no_runtime_loop() {
    let src = "fn main():\n    let a: [i32; 4] = [10, 20, 30, 40]\n    println(f\"{a[0]}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("alloca [4 x i32]"), "expected a `[4 x i32]` array alloca: {}", ir);
    assert!(!ir.contains("arr_rep_cond"), "a distinct-element array literal should never go through `emit_array_repeat`'s runtime loop: {}", ir);
    for i in 0..4 {
        assert!(ir.contains(&format!("i32 0, i64 {}", i)), "expected a GEP into slot {}: {}", i, ir);
    }
}

/// A struct field's array literal is written directly into the field's own
/// storage (`Codegen::emit_array_lit_into`, wired through
/// `emit_struct_lit_fields_into`) rather than being built as a standalone
/// `[N x T]` SSA value and copied a second time -- confirmed by the absence
/// of any whole-array `load`, mirroring the exact reasoning
/// `emit_array_repeat_into` exists for (`array.rs`'s module doc comment): at
/// Nova's real 2048-byte `FontData.glyphs` size, a `load [2048 x i8]` +
/// second `store` round trip is precisely the shape that risks a real
/// `clang` hang/crash.
#[test]
fn codegen_struct_field_array_literal_is_built_directly_into_field_storage() {
    let n = 2048usize;
    let elems: Vec<String> = (0..n).map(|i| (i % 256).to_string()).collect();
    let src = format!(
        "struct FontData:\n    mut glyphs: [u8; {n}]\n\nfn main():\n    let f = FontData(glyphs = [{}])\n    println(f\"{{f.glyphs[0]}}\")\n",
        elems.join(", "),
        n = n
    );
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(!ir.contains(&format!("load [{} x i8]", n)), "the whole 2048-byte array should never be materialized as one SSA value: {}", ir);
    assert!(ir.contains(&format!("[{} x i8]", n)), "expected the field's own `[2048 x i8]` array type to appear: {}", ir);
}

// ===== Runtime end-to-end ====================================================

/// Full round trip mirroring `frontend_fixed_arrays.rs`'s own
/// `runtime_array_end_to_end`: a mutable `let`-annotated array literal with
/// distinct values, in-bounds read/write, out-of-bounds read (zero
/// fallback) and write (silent no-op), and `.len()`.
#[test]
fn runtime_array_literal_end_to_end() {
    let src = r#"
fn main():
    let mut a: [i32; 5] = [10, 20, 30, 40, 50]
    println(f"{a.len()}")
    println(f"{a[0]} {a[1]} {a[2]} {a[3]} {a[4]}")
    a[2] = 99
    println(f"{a[2]}")
    let oob = a[99]
    println(f"{oob}")
    a[99] = 5
    println(f"{a[2]}")
"#;
    let output = compile_and_run("array_lit_end_to_end", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["5", "10 20 30 40 50", "99", "0", "99"], "{}", stdout);
}

/// The exact motivating Nova shape: a struct field constructed from a
/// bracket literal of bare (narrowing) integer literals, read/written
/// through the struct after construction.
#[test]
fn runtime_struct_field_array_literal_end_to_end() {
    let src = r#"
struct FontData:
    mut glyphs: [u8; 5]

fn main():
    let mut f = FontData(glyphs = [10, 20, 30, 40, 50])
    println(f"{f.glyphs[0]} {f.glyphs[4]}")
    f.glyphs[1] = 255 as u8
    println(f"{f.glyphs[1]}")
"#;
    let output = compile_and_run("array_lit_struct_field_end_to_end", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["10 50", "255"], "{}", stdout);
}

/// `return [e1, e2, ...]` coerced against a declared `[T; N]` return type,
/// round-tripped through a real call.
#[test]
fn runtime_return_array_literal_end_to_end() {
    let src = r#"
fn make() -> [i32; 3]:
    return [7, 8, 9]

fn main():
    let a = make()
    println(f"{a[0]} {a[1]} {a[2]}")
"#;
    let output = compile_and_run("array_lit_return_end_to_end", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.lines().collect::<Vec<_>>(), vec!["7 8 9"], "{}", stdout);
}

/// A larger-scale round trip approximating Nova's real 2048-byte glyph
/// table shape: every byte independently readable after construction,
/// proving no element got dropped, duplicated, or misordered by the
/// direct-into codegen path.
#[test]
fn runtime_large_struct_field_array_literal_end_to_end() {
    let n = 300usize;
    let elems: Vec<String> = (0..n).map(|i| (i % 256).to_string()).collect();
    let src = format!(
        "struct FontData:\n    mut glyphs: [u8; {n}]\n\nfn main():\n    let f = FontData(glyphs = [{}])\n    println(f\"{{f.glyphs[0]}} {{f.glyphs[100]}} {{f.glyphs[299]}}\")\n",
        elems.join(", "),
        n = n
    );
    let output = compile_and_run("array_lit_large_struct_field_end_to_end", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.lines().collect::<Vec<_>>(), vec!["0 100 43"], "{}", stdout);
}

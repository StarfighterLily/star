//! Numeric widths and `char`
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Numeric widths and `char` (docs/design.md's Type System §2) =========
//
// `i8`/`u8`/`i16`/`u16`/`u32`/`i64`/`u64`/`f64` alongside the original
// `i32`/`f32`, plus `char` (a Unicode scalar) and `expr as Type` explicit
// casts -- see `Ty::I8`'s doc comment (`src/types/mod.rs`) for the full
// design rationale: no implicit widening between distinct numeric types
// (the original `Int`/`Float` mixed-pair promotion is the one preserved
// exception), and every explicit-width *integer* type traps on `+`/`-`/`*`
// overflow (unlike `Ty::Int`, which keeps its original silent wraparound).

#[test]
fn lexes_char_literal_token() {
    let tokens = Driver::lex("'a'").expect("lexing should succeed");
    assert!(matches!(tokens[0].kind, TokenKind::Char('a')), "{:?}", tokens[0].kind);
}

#[test]
fn lexes_char_literal_escape_sequence() {
    let tokens = Driver::lex("'\\n'").expect("lexing should succeed");
    assert!(matches!(tokens[0].kind, TokenKind::Char('\n')), "{:?}", tokens[0].kind);
}

#[test]
fn rejects_empty_char_literal() {
    let errs = Driver::lex("''").expect_err("empty char literal should fail to lex");
    assert!(errs.iter().any(|d| d.message.contains("empty char literal")), "{:?}", errs);
}

#[test]
fn rejects_multi_character_char_literal() {
    let errs = Driver::lex("'ab'").expect_err("multi-character char literal should fail to lex");
    assert!(errs.iter().any(|d| d.message.contains("exactly one character")), "{:?}", errs);
}

#[test]
fn parses_char_literal_expression() {
    let module = Driver::parse("fn main():\n    let c = 'x'\n").expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected let") };
    assert!(matches!(value, Expr::Char('x', _)), "{:?}", value);
}

#[test]
fn parses_cast_expression() {
    let module = Driver::parse("fn main():\n    let x = 5 as u8\n").expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected let") };
    let Expr::Cast { expr, ty, .. } = value else { panic!("expected cast, found {:?}", value) };
    assert!(matches!(expr.as_ref(), Expr::Int(5, _)));
    assert_eq!(ty, &Type::Named("u8".into()));
}

/// `as` binds tighter than any binary operator (`x as i64 + 1` is `(x as
/// i64) + 1`) but looser than unary (`-x as i64` is `(-x) as i64`), and
/// chains left-to-right (`x as i64 as f64`).
#[test]
fn parses_chained_and_prioritized_cast_expressions() {
    let module = Driver::parse("fn main():\n    let a = -5 as i64 as f64\n    let b = 1 + 2 as i64\n").expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value: a, .. } = &f.body.stmts[0] else { panic!("expected let") };
    let Expr::Cast { expr: outer_expr, ty: outer_ty, .. } = a else { panic!("expected outer cast, found {:?}", a) };
    assert_eq!(outer_ty, &Type::Named("f64".into()));
    let Expr::Cast { expr: inner_expr, ty: inner_ty, .. } = outer_expr.as_ref() else { panic!("expected inner cast") };
    assert_eq!(inner_ty, &Type::Named("i64".into()));
    assert!(matches!(inner_expr.as_ref(), Expr::Unary { op: UnOp::Neg, .. }));

    let Stmt::Let { value: b, .. } = &f.body.stmts[1] else { panic!("expected let") };
    // `1 + (2 as i64)`, not `(1 + 2) as i64`.
    let Expr::Binary { op: BinOp::Add, rhs, .. } = b else { panic!("expected binary add, found {:?}", b) };
    assert!(matches!(rhs.as_ref(), Expr::Cast { .. }));
}

#[test]
fn parses_every_numeric_width_and_char_type_annotation() {
    for ty_name in ["i8", "u8", "i16", "u16", "u32", "i64", "u64", "f64", "char"] {
        let src = format!("fn main():\n    let x: {} = 0 as {}\n", ty_name, ty_name);
        let module = Driver::parse(&src).unwrap_or_else(|e| panic!("`{}` should parse: {:?}", ty_name, e));
        let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
        let Stmt::Let { ty, .. } = &f.body.stmts[0] else { panic!("expected let") };
        assert_eq!(ty.as_ref(), Some(&Type::Named(ty_name.into())));
    }
}

#[test]
fn resolves_every_numeric_width_type_name_to_a_distinct_ty() {
    let src = "fn main():\n    let a: i8 = 0 as i8\n    let b: u8 = 0 as u8\n    let c: i16 = 0 as i16\n    \
               let d: u16 = 0 as u16\n    let e: u32 = 0 as u32\n    let g: i64 = 0 as i64\n    \
               let h: u64 = 0 as u64\n    let i: f64 = 0.0 as f64\n    let j: char = 'z'\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let TypedItem::Fn(f) = &typed.items[0] else { panic!("expected fn") };
    let tys: Vec<Ty> = f.body.stmts.iter().map(|s| match s {
        TypedStmt::Let { ty, .. } => ty.clone(),
        _ => panic!("expected let"),
    }).collect();
    assert_eq!(tys, vec![Ty::I8, Ty::U8, Ty::I16, Ty::U16, Ty::U32, Ty::I64, Ty::U64, Ty::F64, Ty::Char]);
    // `i64`/`f64` used to alias `Ty::Int`/`Ty::Float` (Star's only widths
    // before this addition) -- confirm they're now genuinely distinct.
    assert_ne!(Ty::I64, Ty::Int);
    assert_ne!(Ty::F64, Ty::Float);
}

#[test]
fn rejects_arithmetic_between_mismatched_numeric_widths() {
    let src = "fn main():\n    let a: i8 = 1 as i8\n    let b: i16 = 2 as i16\n    let c = a + b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("mismatched numeric types")), "{:?}", diags);
}

#[test]
fn rejects_comparison_between_mismatched_numeric_widths() {
    let src = "fn main():\n    let a: u8 = 1 as u8\n    let b: u32 = 2 as u32\n    let c = a < b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("mismatched numeric types")), "{:?}", diags);
}

#[test]
fn accepts_arithmetic_between_same_width_numeric_types() {
    let src = "fn main():\n    let a: u16 = 1 as u16\n    let b: u16 = 2 as u16\n    let c = a + b\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok());
}

/// The one preserved backward-compatible exception: `Int`/`Float` still
/// implicitly promote when mixed, exactly as before this addition.
#[test]
fn accepts_legacy_int_float_mixed_arithmetic() {
    let src = "fn main():\n    let a = 1\n    let b = 1.5\n    let c = a + b\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok());
}

#[test]
fn rejects_arithmetic_on_char_values() {
    let src = "fn main():\n    let c = 'a' + 'b'\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("is not supported between")), "{:?}", diags);
}

#[test]
fn accepts_char_equality_and_ordering_comparisons() {
    let src = "fn main():\n    let a = 'a' == 'b'\n    let b = 'a' < 'b'\n    let c = 'a' >= 'b'\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok());
}

#[test]
fn rejects_cast_between_unrelated_types() {
    let src = "fn main():\n    let s = \"hi\"\n    let x = s as i32\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("cannot cast")), "{:?}", diags);
}

#[test]
fn accepts_every_numeric_width_and_char_as_a_map_set_key() {
    let src = "fn main():\n    let mut m: Map<u8, i32> = Map<u8, i32>()\n    m.insert(1 as u8, 5)\n    \
               let mut s: Set<char> = Set<char>()\n    s.insert('a')\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok());
}

#[test]
fn runtime_numeric_width_casts_and_same_width_arithmetic_end_to_end() {
    let src = "fn main():\n    \
               let ua: u8 = 200 as u8\n    let ub: u8 = 55 as u8\n    println(f\"{ua + ub}\")\n    \
               let ia: i8 = -100 as i8\n    let ib: i8 = 20 as i8\n    println(f\"{ia - ib}\")\n    \
               let x: u32 = 2000000000 as u32\n    println(f\"{x + x}\")\n    \
               let y: i64 = 1073741824 as i64\n    let sixteen: i64 = 16 as i64\n    println(f\"{y * sixteen}\")\n    \
               let z: u64 = 2000000000 as u64\n    println(f\"{z + z + z}\")\n    \
               let fa: f64 = 10 as f64\n    let fb: f64 = 4 as f64\n    println(f\"{fa / fb}\")\n";
    let output = compile_and_run("numeric_widths_basic", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(
        lines,
        vec!["255", "-120", "4000000000", "17179869184", "6000000000", "2.500000"],
        "{}",
        stdout
    );
}

#[test]
fn runtime_char_literal_comparison_and_cast_round_trip_end_to_end() {
    let src = "fn main():\n    let c = 'A'\n    println(f\"{c as i32}\")\n    let n = 66\n    println(f\"{n as char}\")\n    \
               println(f\"{'a' == 'a'} {'a' == 'b'} {'a' < 'b'}\")\n";
    let output = compile_and_run("char_roundtrip", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["65", "B", "true false true"], "{}", stdout);
}

/// `Ty::Int` (i32) deliberately keeps its original silent two's-complement
/// wraparound on overflow -- only the new explicit-width integer types
/// trap (see `Ty::I8`'s doc comment on why this compiler didn't retrofit
/// trapping onto the pre-existing type as part of this addition).
#[test]
fn runtime_i32_add_overflow_still_wraps_silently_unlike_new_sized_int_types() {
    let src = "struct Counter:\n    mut n: i32\nfn main():\n    let c = Counter(2147483647)\n    let x = c.n + 1\n    println(f\"{x}\")\n";
    let output = compile_and_run("i32_add_wraps", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "-2147483648");
}

#[test]
fn runtime_u8_add_overflow_traps_end_to_end() {
    let src = "struct Counter:\n    mut n: u8\nfn main():\n    println(\"before\")\n    let c = Counter(250 as u8)\n    \
               let ten: u8 = 10 as u8\n    let x = c.n + ten\n    println(f\"unreachable {x}\")\n";
    let output = compile_and_run("u8_add_overflow", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(stdout.contains("unsigned 8-bit integer overflow"), "should print a diagnostic: {}", stdout);
    assert!(!stdout.contains("unreachable"), "the add must abort before its value is used: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "should exit cleanly with code 1, not crash/trap: {:?}", output.status);
}

#[test]
fn runtime_i8_sub_overflow_traps_end_to_end() {
    let src = "struct Counter:\n    mut n: i8\nfn main():\n    println(\"before\")\n    let c = Counter(-100 as i8)\n    \
               let hundred: i8 = 100 as i8\n    let x = c.n - hundred\n    println(f\"unreachable {x}\")\n";
    let output = compile_and_run("i8_sub_overflow", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(stdout.contains("signed 8-bit integer overflow"), "should print a diagnostic: {}", stdout);
    assert!(!stdout.contains("unreachable"), "the sub must abort before its value is used: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}

#[test]
fn runtime_i16_mul_overflow_traps_end_to_end() {
    let src = "struct Counter:\n    mut n: i16\nfn main():\n    println(\"before\")\n    let c = Counter(1000 as i16)\n    \
               let thousand: i16 = 1000 as i16\n    let x = c.n * thousand\n    println(f\"unreachable {x}\")\n";
    let output = compile_and_run("i16_mul_overflow", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(stdout.contains("signed 16-bit integer overflow"), "should print a diagnostic: {}", stdout);
    assert!(!stdout.contains("unreachable"), "the mul must abort before its value is used: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}

/// Unsigned subtraction underflow (`5u32 - 10u32`) is exactly as much an
/// overflow-trap case as a signed add/sub/mul, just detected via the
/// `usub.with.overflow` intrinsic's borrow flag instead of a sign check.
#[test]
fn runtime_u32_sub_underflow_traps_end_to_end() {
    let src = "struct Counter:\n    mut n: u32\nfn main():\n    println(\"before\")\n    let c = Counter(5 as u32)\n    \
               let ten: u32 = 10 as u32\n    let x = c.n - ten\n    println(f\"unreachable {x}\")\n";
    let output = compile_and_run("u32_sub_underflow", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(stdout.contains("unsigned 32-bit integer overflow"), "should print a diagnostic: {}", stdout);
    assert!(!stdout.contains("unreachable"), "the sub must abort before its value is used: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}

#[test]
fn runtime_sized_int_division_by_zero_traps_end_to_end() {
    let src = "struct Counter:\n    mut n: u16\nfn main():\n    println(\"before\")\n    let c = Counter(0 as u16)\n    \
               let five: u16 = 5 as u16\n    let x = five / c.n\n    println(f\"unreachable {x}\")\n";
    let output = compile_and_run("u16_div_by_zero", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(stdout.contains("integer `/` by zero"), "should print a diagnostic: {}", stdout);
    assert!(!stdout.contains("unreachable"), "the div must abort before its value is used: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}

/// `i16::MIN / -1` is the sized-width generalization of the pre-existing
/// `i32::MIN / -1` guard -- its mathematical result (`32768`) doesn't fit
/// back into `i16` either.
#[test]
fn runtime_sized_int_signed_min_divided_by_negative_one_traps_end_to_end() {
    let src = "struct Counter:\n    mut n: i16\nfn main():\n    println(\"before\")\n    let c = Counter(-1 as i16)\n    \
               let min: i16 = -32768 as i16\n    let x = min / c.n\n    println(f\"unreachable {x}\")\n";
    let output = compile_and_run("i16_min_div_neg1", src);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("before"), "{}", stdout);
    assert!(stdout.contains("integer `/` by zero"), "should print a diagnostic: {}", stdout);
    assert!(!stdout.contains("unreachable"), "the div must abort before its value is used: {}", stdout);
    assert_eq!(output.status.code(), Some(1), "{:?}", output.status);
}

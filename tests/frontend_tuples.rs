//! Tuple types
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Tuples (`docs/design.md`'s Type System plan, item 10's lowest-effort
// ===== slice: "Option/Result as builtins + Map/Set + fixed-size arrays" --
// ===== tuples are the same "connective tissue" gap, called out in that
// ===== section's item 3). `(T, U, ...)` lowers to an anonymous LLVM literal
// ===== struct type (no `%name` declaration), laid out and accessed exactly
// ===== like a nominal struct's fields -- no RC header, no heap allocation.
// ===== `.0`/`.1`/... is a dedicated `Expr::TupleIndex` node (not `Field`,
// ===== which looks a name up in a *declared* struct's field list) since a
// ===== tuple's positions are never named. A parenthesized expression/type
// ===== with no comma stays ordinary grouping, not a 1-tuple -- only a
// ===== trailing comma after exactly one element, or two-or-more
// ===== comma-separated elements, makes a tuple. ==========================

/// A single parenthesized expression with no comma is grouping, not a
/// 1-tuple -- must not become `Expr::TupleLit`.
#[test]
fn parses_single_paren_expr_as_grouping_not_tuple() {
    let src = "fn main():\n    let x = (5)\n    println(f\"{x}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected a fn item") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected a let stmt") };
    assert!(matches!(value, Expr::Int(5, _)), "a lone parenthesized expression should stay a plain `Int`, not a tuple: {:?}", value);
}

/// A trailing comma after exactly one element makes a genuine 1-tuple.
#[test]
fn parses_trailing_comma_single_element_as_tuple_literal() {
    let src = "fn main():\n    let x = (5,)\n    println(f\"{x.0}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected a fn item") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected a let stmt") };
    assert!(matches!(value, Expr::TupleLit(elems, _) if elems.len() == 1), "`(5,)` should parse as a 1-element tuple literal: {:?}", value);
}

/// Two or more comma-separated elements parse as `Expr::TupleLit`, and a
/// `.0` postfix parses as the dedicated `Expr::TupleIndex` node rather than
/// `Expr::Field` (which the lexer's `.`-then-`Int` tokenization -- a
/// standalone `Dot` never folds into a following digit -- makes possible to
/// tell apart unambiguously).
#[test]
fn parses_tuple_literal_and_tuple_index() {
    let src = "fn main():\n    let t = (1, \"a\", true)\n    println(f\"{t.1}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected a fn item") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected a let stmt") };
    assert!(matches!(value, Expr::TupleLit(elems, _) if elems.len() == 3), "{:?}", value);
    let Stmt::Expr(Expr::Call { args, .. }) = &f.body.stmts[1] else { panic!("expected the println call") };
    let Expr::FStr(parts, _) = &args[0] else { panic!("expected an f-string argument") };
    let FStrExpr::Expr(inner) = &parts[0] else { panic!("expected the f-string's sole interpolation") };
    assert!(matches!(inner.as_ref(), Expr::TupleIndex { index: 1, .. }), "{:?}", inner);
}

/// A parenthesized *type* with no comma unwraps back to that type directly
/// (grouping), mirroring the expression-level rule -- `(i32)` as a `let`
/// annotation is just `i32`, not a 1-tuple type.
#[test]
fn parses_single_paren_type_as_grouping_not_tuple_type() {
    let src = "fn main():\n    let x: (i32) = 5\n    println(f\"{x}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected a fn item") };
    let Stmt::Let { ty, .. } = &f.body.stmts[0] else { panic!("expected a let stmt") };
    assert_eq!(ty.as_ref(), Some(&Type::Named("i32".into())), "`(i32)` should resolve to plain `i32`, not a tuple type: {:?}", ty);
}

/// A tuple *type* annotation `(T, U)` parses as `Type::Tuple`.
#[test]
fn parses_tuple_type_annotation() {
    let src = "fn main():\n    let t: (i32, str) = (1, \"a\")\n    println(f\"{t.0}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected a fn item") };
    let Stmt::Let { ty, .. } = &f.body.stmts[0] else { panic!("expected a let stmt") };
    assert_eq!(ty.as_ref(), Some(&Type::Tuple(vec![Type::Named("i32".into()), Type::Named("str".into())])), "{:?}", ty);
}

/// End-to-end type inference: a tuple literal's type is `Ty::Tuple` of its
/// elements' own inferred types, and indexing yields the indexed element's
/// exact type.
#[test]
fn checks_tuple_literal_and_index_types() {
    let src = "fn main():\n    let t = (1, \"a\", true)\n    let a: i32 = t.0\n    let b: str = t.1\n    let c: bool = t.2\n    println(f\"{a}{b}{c}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let TypedItem::Fn(f) = &typed.items[0] else { panic!("expected a fn item") };
    let TypedStmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected the tuple let") };
    assert_eq!(value.clone().into_ty(), Ty::Tuple(vec![Ty::Int, Ty::Str, Ty::Bool]));
}

#[test]
fn rejects_tuple_index_out_of_range() {
    let src = "fn main():\n    let t = (1, 2)\n    println(f\"{t.5}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("an out-of-range tuple index must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("out of range")), "{:?}", errs);
}

#[test]
fn rejects_tuple_index_on_non_tuple() {
    let src = "fn main():\n    let x = 5\n    println(f\"{x.0}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("indexing a non-tuple must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("requires a tuple")), "{:?}", errs);
}

#[test]
fn rejects_tuple_let_annotation_arity_mismatch() {
    let src = "fn main():\n    let t: (i32, i32, i32) = (1, 2)\n    println(f\"{t.0}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("a tuple arity mismatch against its let annotation must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("but the value has type")), "{:?}", errs);
}

/// `mut` enforcement applies to a tuple element exactly like a struct field
/// through a `mut` binding -- a tuple has no per-element `mut` declaration
/// of its own (there's no field syntax to put one on), so the root
/// binding's own `mut` is the only gate, mirroring a swizzle write (`v.x =
/// ...`) on a `Vec2`/`Vec3`/`Vec4`, which has the same "no per-field
/// declaration" shape.
#[test]
fn rejects_assignment_to_tuple_index_without_mut() {
    let src = "fn main():\n    let t = (1, 2)\n    t.0 = 5\n    println(f\"{t.0}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("assigning into a tuple element through a non-`mut` binding must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("not declared `mut`")), "{:?}", errs);
}

#[test]
fn accepts_assignment_to_tuple_index_via_mut_binding() {
    let src = "fn main():\n    let mut t = (1, 2)\n    t.0 = 5\n    println(f\"{t.0}\")\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "assigning into a tuple element through a `mut` binding should type-check cleanly");
}

/// A tuple composed entirely of hashable element types is itself a valid
/// `Map`/`Set` key/element type, mirroring a struct composed entirely of
/// hashable fields.
#[test]
fn accepts_tuple_as_set_element_when_all_elements_hashable() {
    let src = "fn main():\n    let mut s = Set<(i32, str)>()\n    s.insert((1, \"a\"))\n    println(f\"{s.len()}\")\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "a tuple of hashable elements should be usable as a `Set` element type");
}

/// A tuple containing a non-hashable element (here, a `List<i32>`) is
/// rejected as a `Map`/`Set` key/element type, same as a struct with such a
/// field would be.
#[test]
fn rejects_tuple_as_set_element_when_an_element_is_unhashable() {
    let src = "fn main():\n    let mut s = Set<(i32, List<i32>)>()\n    println(\"x\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("a tuple containing a non-hashable element must be rejected as a Set element type") };
    assert!(errs.iter().any(|d| d.message.contains("cannot be used as a")), "{:?}", errs);
}

/// `llvm_ty` lowers `Ty::Tuple` to an anonymous LLVM literal struct type --
/// no `%name` declaration, unlike a nominal `struct`.
#[test]
fn codegen_tuple_lowers_to_anonymous_struct_type() {
    let src = "fn main():\n    let t = (1, true)\n    println(f\"{t.0}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("alloca { i32, i1 }"), "expected an anonymous `{{ i32, i1 }}` literal struct alloca: {}", ir);
}

/// Full runtime round trip: construction, positional reads, a mutation
/// through a `mut` binding, a tuple returned from a function, a tuple
/// nesting a struct (mutated through the tuple element), and a 1-element
/// trailing-comma tuple.
#[test]
fn runtime_tuple_end_to_end() {
    let src = r#"
struct Player:
    mut health: i32
    name: str

fn make_pair() -> (i32, str):
    (5, "five")

fn main():
    let mut t = (1, "one", true)
    println(f"{t.0} {t.1} {t.2}")
    let p = make_pair()
    println(f"{p.0} {p.1}")
    t.0 = 42
    println(f"{t.0}")
    let mut nested = (Player(health = 10, name = "Bob"), 7)
    nested.0.health -= 3
    println(f"{nested.0.name} hp={nested.0.health} n={nested.1}")
    let single = (99,)
    println(f"{single.0}")
"#;
    let output = compile_and_run("tuple_end_to_end", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["1 one true", "5 five", "42", "Bob hp=7 n=7", "99"], "{}", stdout);
}

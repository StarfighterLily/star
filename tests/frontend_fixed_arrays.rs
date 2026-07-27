//! Fixed-size array types
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Fixed-size arrays (`docs/design.md`'s Type System plan, item 10's
// ===== "fixed-size arrays" -- the last of that section's lowest-effort
// ===== slice, after Option/Result/Map/Set). `[T; N]` lowers to an inline
// ===== LLVM `[N x T]` array (like `Ty::Tuple`, no RC header, no heap
// ===== allocation). The *only* literal form is the `[value; N]` repeat
// ===== (a new `;` token, `TokenKind::Semi` -- the only place the grammar
// ===== ever uses one, see `Lexer`'s doc comment on it): a distinct-elements
// ===== form (`[e1, e2, e3]`) would collide with `List<T>`'s existing
// ===== `ListLit` syntax, and this checker has no expected-type propagation
// ===== to disambiguate the two by context. Indexing shares `Expr::GenRefIndex`'s
// ===== `[..]` syntax with `GenRef<T>`/`List<T>`/`str` (dispatched on the
// ===== base's resolved type), with the same bounds-checked, fails-safe
// ===== convention as `List<T>`: a zero value out of bounds on read, a
// ===== silent no-op out of bounds on write. `.len()` is resolved entirely
// ===== by the checker to the array's static size, with no runtime read at
// ===== all (unlike `List<T>::len()`). =====================================

#[test]
fn parses_array_type_annotation() {
    let src = "fn main():\n    let a: [i32; 3] = [0; 3]\n    println(f\"{a[0]}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected a fn item") };
    let Stmt::Let { ty, .. } = &f.body.stmts[0] else { panic!("expected a let stmt") };
    assert_eq!(ty.as_ref(), Some(&Type::Array(Box::new(Type::Named("i32".into())), 3)), "{:?}", ty);
}

#[test]
fn parses_array_repeat_literal() {
    let src = "fn main():\n    let a = [0; 5]\n    println(f\"{a[0]}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected a fn item") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected a let stmt") };
    assert!(matches!(value, Expr::ArrayRepeat { count: 5, .. }), "{:?}", value);
}

/// A list literal must not be confused for an array repeat -- `[1, 2, 3]`
/// (no `;`) stays an ordinary `ListLit`.
#[test]
fn parses_list_literal_unaffected_by_array_repeat_syntax() {
    let src = "fn main():\n    let l = [1, 2, 3]\n    println(f\"{l.len()}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected a fn item") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected a let stmt") };
    assert!(matches!(value, Expr::ListLit(elems, _) if elems.len() == 3), "{:?}", value);
}

/// An empty `[]` still parses as an (checker-rejected) empty `ListLit` --
/// there's no first element to decide repeat-vs-list from, and no
/// array-literal spelling has an empty form either.
#[test]
fn parses_empty_brackets_as_empty_list_literal() {
    let src = "fn main():\n    let l = []\n    println(\"x\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected a fn item") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected a let stmt") };
    assert!(matches!(value, Expr::ListLit(elems, _) if elems.is_empty()), "{:?}", value);
}

#[test]
fn checks_array_repeat_and_index_types() {
    let src = "fn main():\n    let a = [true; 4]\n    let x: bool = a[0]\n    println(f\"{x}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let TypedItem::Fn(f) = &typed.items[0] else { panic!("expected a fn item") };
    let TypedStmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected the array let") };
    assert_eq!(value.clone().into_ty(), Ty::Array(Box::new(Ty::Bool), 4));
}

#[test]
fn rejects_array_let_annotation_size_mismatch() {
    let src = "fn main():\n    let a: [i32; 3] = [1; 4]\n    println(f\"{a[0]}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("an array size mismatch against its let annotation must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("but the value has type")), "{:?}", errs);
}

/// `mut` enforcement applies to an array element exactly like a tuple
/// element or a swizzle write -- no per-slot declaration exists to check
/// independently, so the root binding's own `mut` is the only gate.
#[test]
fn rejects_assignment_to_array_index_without_mut() {
    let src = "fn main():\n    let a = [1; 3]\n    a[0] = 5\n    println(f\"{a[0]}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("assigning into an array element through a non-`mut` binding must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("not declared `mut`")), "{:?}", errs);
}

#[test]
fn accepts_assignment_to_array_index_via_mut_binding() {
    let src = "fn main():\n    let mut a = [1; 3]\n    a[0] = 5\n    println(f\"{a[0]}\")\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "assigning into an array element through a `mut` binding should type-check cleanly");
}

/// An array of hashable elements is itself a valid `Map`/`Set` key/element
/// type, mirroring a tuple of hashable elements.
#[test]
fn accepts_array_as_set_element_when_element_type_hashable() {
    let src = "fn main():\n    let mut s = Set<[i32; 3]>()\n    s.insert([1; 3])\n    println(f\"{s.len()}\")\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "an array of a hashable element type should be usable as a `Set` element type");
}

#[test]
fn rejects_array_as_set_element_when_element_type_unhashable() {
    let src = "fn main():\n    let mut s = Set<[List<i32>; 2]>()\n    println(\"x\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("an array of a non-hashable element type must be rejected as a Set element type") };
    assert!(errs.iter().any(|d| d.message.contains("cannot be used as a")), "{:?}", errs);
}

/// `llvm_ty` lowers `Ty::Array` to a plain LLVM array type.
#[test]
fn codegen_array_lowers_to_llvm_array_type() {
    let src = "fn main():\n    let a = [1; 4]\n    println(f\"{a[0]}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("alloca [4 x i32]"), "expected a `[4 x i32]` array alloca: {}", ir);
}

/// `.len()` never reads the array's runtime storage at all -- it's resolved
/// entirely at check time to the constant `count`.
#[test]
fn codegen_array_len_is_a_compile_time_constant() {
    let src = "fn t(a: [i32; 7]) -> i32:\n    a.len()\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i32 @t(");
    assert!(fn_ir.contains("ret i32 7"), "expected `.len()` to fold to the literal constant `7`: {}", fn_ir);
}

/// Full runtime round trip: a mutable `[i32; N]` repeat literal, `.len()`,
/// in-bounds read/write, out-of-bounds read (zero fallback) and write
/// (silent no-op), an explicit `[T; N]` `let` annotation, and a repeated
/// struct element mutated independently through one slot (proving the
/// repeat literal produces `N` independent copies, not `N` aliases of one
/// shared value).
#[test]
fn runtime_array_end_to_end() {
    let src = r#"
struct Player:
    mut health: i32
    name: str

fn main():
    let mut a = [0; 5]
    println(f"{a.len()}")
    a[2] = 42
    println(f"{a[0]} {a[1]} {a[2]} {a[3]} {a[4]}")
    let b: [i32; 3] = [7; 3]
    println(f"{b[0]} {b[1]} {b[2]}")
    let oob = a[99]
    println(f"{oob}")
    a[99] = 5
    println(f"{a[2]}")
    let mut players = [Player(health = 50, name = "Bob"); 2]
    players[0].health -= 10
    println(f"{players[0].name} hp={players[0].health} other_hp={players[1].health}")
"#;
    let output = compile_and_run("array_end_to_end", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(
        lines,
        vec!["5", "0 0 42 0 0", "7 7 7", "0", "42", "Bob hp=40 other_hp=50"],
        "{}",
        stdout
    );
}

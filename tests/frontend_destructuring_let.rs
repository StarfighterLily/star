//! Destructuring `let (a, b) = expr`
//!
//! Fixes `todo.md` P1 #5: every tuple-returning call previously had to be
//! bound to a temporary and read back positionally (`ops.0`/`ops.1`). This
//! is a pure parse-time desugaring -- `Parser::parse_destructure_let`
//! (`src/parser/stmt.rs`) rewrites `let [mut] (a, b, ...) [: (T1, T2, ...)]
//! = expr` into a synthetic `let __destructure_N = expr` holding the whole
//! tuple, plus one ordinary `let <name> = __destructure_N.<i>` per pattern
//! element -- exactly the hand-written workaround this todo item describes,
//! just generated instead of typed out. No new `Stmt`/`TypedStmt` variant
//! exists anywhere in the checker, `sequence`/`frame`/`par` analysis, or
//! codegen; they all see the same `Stmt::Let`/`Expr::TupleIndex` shapes
//! those passes already handle for ordinary tuples (`tests/frontend_tuples.
//! rs`).
//!
//! Shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Parser / AST-shape ==================================================

/// The basic two-name form desugars to exactly 3 statements: the tuple
/// temporary, then one indexed `let` per name, in source order.
#[test]
fn parses_destructuring_let_into_tmp_and_indexed_lets() {
    let src = "fn main():\n    let (a, b) = (1, 2)\n    println(f\"{a}{b}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected a fn item") };
    assert_eq!(f.body.stmts.len(), 4, "tmp-let + 2 indexed lets + println: {:?}", f.body.stmts);

    let Stmt::Let { name: tmp_name, ty: tmp_ty, value: tmp_value, is_mut: tmp_mut, .. } = &f.body.stmts[0] else {
        panic!("expected the tuple temporary's own let")
    };
    assert!(!tmp_mut, "the internal tuple temporary is never itself declared mut");
    assert!(tmp_ty.is_none(), "no annotation was written, so the temporary stays untyped for the checker to infer");
    assert!(matches!(tmp_value, Expr::TupleLit(elems, _) if elems.len() == 2), "{:?}", tmp_value);

    let Stmt::Let { name: a_name, value: a_value, .. } = &f.body.stmts[1] else { panic!("expected let a") };
    assert_eq!(a_name, "a");
    let Expr::TupleIndex { base, index: 0, .. } = a_value else { panic!("expected a `.0` tuple index: {:?}", a_value) };
    assert!(matches!(base.as_ref(), Expr::Ident(n, _) if n == tmp_name), "`a` should read the same temporary: {:?}", base);

    let Stmt::Let { name: b_name, value: b_value, .. } = &f.body.stmts[2] else { panic!("expected let b") };
    assert_eq!(b_name, "b");
    assert!(matches!(b_value, Expr::TupleIndex { index: 1, .. }), "expected a `.1` tuple index: {:?}", b_value);
}

/// More than two names works the same way, one indexed `let` per element in
/// order.
#[test]
fn parses_destructuring_let_with_three_names() {
    let src = "fn main():\n    let (a, b, c) = (1, 2, 3)\n    println(f\"{a}{b}{c}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected a fn item") };
    assert_eq!(f.body.stmts.len(), 5, "tmp-let + 3 indexed lets + println: {:?}", f.body.stmts);
    let names: Vec<&str> = f.body.stmts[1..4]
        .iter()
        .map(|s| {
            let Stmt::Let { name, .. } = s else { panic!("expected a let") };
            name.as_str()
        })
        .collect();
    assert_eq!(names, vec!["a", "b", "c"]);
    let indices: Vec<usize> = f.body.stmts[1..4]
        .iter()
        .map(|s| {
            let Stmt::Let { value: Expr::TupleIndex { index, .. }, .. } = s else { panic!("expected a tuple-index let") };
            *index
        })
        .collect();
    assert_eq!(indices, vec![0, 1, 2]);
}

/// `let mut (x, y) = ...` applies `mut` to every bound name -- there's no
/// per-element `let (mut a, b) = ...` mixed-mutability spelling, mirroring
/// how plain `let mut name = ...` covers the one name it precedes.
#[test]
fn parses_mut_destructuring_let_applies_mut_to_every_name() {
    let src = "fn main():\n    let mut (x, y) = (1, 2)\n    x += 1\n    println(f\"{x}{y}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected a fn item") };
    let Stmt::Let { is_mut: tmp_mut, .. } = &f.body.stmts[0] else { panic!() };
    assert!(!tmp_mut, "the internal temporary itself doesn't need to be mut, regardless of the pattern's own `mut`");
    let Stmt::Let { is_mut: x_mut, .. } = &f.body.stmts[1] else { panic!() };
    assert!(x_mut, "`x` should be mut");
    let Stmt::Let { is_mut: y_mut, .. } = &f.body.stmts[2] else { panic!() };
    assert!(y_mut, "`y` should be mut too, even though only `x` is later reassigned");
}

/// Without `mut`, every bound name is immutable, same as the plain
/// single-name form.
#[test]
fn parses_destructuring_let_without_mut_is_immutable() {
    let src = "fn main():\n    let (a, b) = (1, 2)\n    println(f\"{a}{b}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!() };
    let Stmt::Let { is_mut: a_mut, .. } = &f.body.stmts[1] else { panic!() };
    let Stmt::Let { is_mut: b_mut, .. } = &f.body.stmts[2] else { panic!() };
    assert!(!a_mut && !b_mut);
}

/// An explicit tuple type annotation (`(T1, T2)`) is split per element onto
/// each individual `let`, *and* threaded onto the temporary as a whole
/// `Type::Tuple` -- the latter matters for `sequence` bodies, which require
/// every hoisted top-level local (including this synthetic one) to carry an
/// explicit type (see `runtime_annotated_destructuring_let_in_sequence_
/// hoists_cleanly_end_to_end` below).
#[test]
fn parses_destructuring_let_with_tuple_type_annotation() {
    let src = "fn main():\n    let (a, b): (i32, str) = (1, \"x\")\n    println(f\"{a}{b}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!() };
    let Stmt::Let { ty: tmp_ty, .. } = &f.body.stmts[0] else { panic!() };
    assert_eq!(
        tmp_ty.as_ref(),
        Some(&Type::Tuple(vec![Type::Named("i32".into()), Type::Named("str".into())])),
        "{:?}",
        tmp_ty
    );
    let Stmt::Let { ty: a_ty, .. } = &f.body.stmts[1] else { panic!() };
    assert_eq!(a_ty.as_ref(), Some(&Type::Named("i32".into())));
    let Stmt::Let { ty: b_ty, .. } = &f.body.stmts[2] else { panic!() };
    assert_eq!(b_ty.as_ref(), Some(&Type::Named("str".into())));
}

/// A trailing comma after the last name (`(a, b,)`) is accepted, same as an
/// ordinary tuple/call-argument list.
#[test]
fn parses_destructuring_let_with_trailing_comma() {
    let src = "fn main():\n    let (a, b,) = (1, 2)\n    println(f\"{a}{b}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!() };
    assert_eq!(f.body.stmts.len(), 4, "{:?}", f.body.stmts);
}

/// Two destructuring `let`s in the same function must not share a
/// temporary -- `Parser::fresh_destructure_name`'s counter, not plain
/// `let`-shadowing, is what keeps the second one's tuple independent of the
/// first's.
#[test]
fn parses_two_destructuring_lets_use_distinct_temporaries() {
    let src = "fn main():\n    let (a, b) = (1, 2)\n    let (c, d) = (3, 4)\n    println(f\"{a}{b}{c}{d}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!() };
    let Stmt::Let { name: tmp1, .. } = &f.body.stmts[0] else { panic!() };
    let Stmt::Let { name: tmp2, .. } = &f.body.stmts[3] else { panic!() };
    assert_ne!(tmp1, tmp2, "each destructuring let should get its own temporary name");
}

/// A single parenthesized name after `let` -- `let (a) = expr` -- isn't a
/// destructuring pattern (there's nothing to destructure into just one
/// binding); rejected in favor of plain `let a = expr`.
#[test]
fn rejects_destructuring_let_with_single_name() {
    let src = "fn main():\n    let (a) = (1,)\n    println(f\"{a}\")\n";
    let errs = Driver::parse(src).expect_err("a single-name pattern should be rejected");
    assert!(errs.iter().any(|d| d.message.contains("at least 2 names")), "{:?}", errs);
}

/// A duplicate name within the same pattern (`let (a, a) = ...`) is a clean
/// parse error, not a silent last-write-wins shadow inside the desugared
/// output.
#[test]
fn rejects_destructuring_let_duplicate_name() {
    let src = "fn main():\n    let (a, a) = (1, 2)\n    println(f\"{a}\")\n";
    let errs = Driver::parse(src).expect_err("a duplicate binding name should be rejected");
    assert!(errs.iter().any(|d| d.message.contains("duplicate binding")), "{:?}", errs);
}

/// The type annotation's arity must match the pattern's own name count.
#[test]
fn rejects_destructuring_let_type_annotation_arity_mismatch() {
    let src = "fn main():\n    let (a, b): (i32, i32, i32) = (1, 2, 3)\n    println(f\"{a}{b}\")\n";
    let errs = Driver::parse(src).expect_err("annotation/pattern arity mismatch should be rejected");
    assert!(errs.iter().any(|d| d.message.contains("binds 2 name(s) but the type annotation has 3 element(s)")), "{:?}", errs);
}

/// A non-tuple type annotation (e.g. a bare `i32`) on a multi-name pattern
/// is rejected -- it can never describe more than one binding.
#[test]
fn rejects_destructuring_let_non_tuple_type_annotation() {
    let src = "fn main():\n    let (a, b): i32 = (1, 2)\n    println(f\"{a}{b}\")\n";
    let errs = Driver::parse(src).expect_err("a non-tuple annotation on a multi-name pattern should be rejected");
    assert!(errs.iter().any(|d| d.message.contains("needs a tuple type annotation")), "{:?}", errs);
}

/// Nested patterns (`let (a, (b, c)) = ...`) aren't supported -- each
/// pattern position must be a plain name -- and must fail with a clean parse
/// error rather than panicking.
#[test]
fn rejects_nested_destructuring_pattern() {
    let src = "fn main():\n    let (a, (b, c)) = (1, (2, 3))\n    println(f\"{a}\")\n";
    let errs = Driver::parse(src).expect_err("a nested pattern should be rejected, not panic");
    assert!(errs.iter().any(|d| d.message.contains("expected an identifier")), "{:?}", errs);
}

/// An empty pattern `let () = expr` is rejected the same way a single-name
/// one is (fewer than 2 names), not a parser panic on an empty loop.
#[test]
fn rejects_empty_destructuring_pattern() {
    let src = "fn main():\n    let () = (1, 2)\n    println(\"x\")\n";
    let errs = Driver::parse(src).expect_err("an empty pattern should be rejected");
    assert!(errs.iter().any(|d| d.message.contains("at least 2 names")), "{:?}", errs);
}

// ===== Type-checking ========================================================

/// End-to-end type inference: each bound name gets its corresponding tuple
/// element's own inferred type.
#[test]
fn checks_destructuring_let_infers_element_types_from_tuple_value() {
    let src = "fn main():\n    let (a, b) = (1, \"x\")\n    let n: i32 = a\n    let s: str = b\n    println(f\"{n}{s}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let TypedItem::Fn(f) = &typed.items[0] else { panic!("expected a fn item") };
    let TypedStmt::Let { value: a_value, .. } = &f.body.stmts[1] else { panic!("expected let a") };
    assert_eq!(a_value.clone().into_ty(), Ty::Int);
    let TypedStmt::Let { value: b_value, .. } = &f.body.stmts[2] else { panic!("expected let b") };
    assert_eq!(b_value.clone().into_ty(), Ty::Str);
}

/// Destructuring a non-tuple value reuses `TupleIndex`'s own "requires a
/// tuple" diagnostic -- there's no dedicated destructuring-specific error
/// message, since by the time the checker sees this it's just an ordinary
/// `.0` on a non-tuple.
#[test]
fn rejects_destructuring_let_against_non_tuple_value() {
    let src = "fn main():\n    let (a, b) = 5\n    println(f\"{a}{b}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("destructuring a non-tuple value must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("requires a tuple")), "{:?}", errs);
}

/// Binding more names than the value's tuple actually has elements reuses
/// `TupleIndex`'s own out-of-range diagnostic on the last (unsatisfiable)
/// name.
#[test]
fn rejects_destructuring_let_with_more_names_than_tuple_elements() {
    let src = "fn main():\n    let (a, b, c) = (1, 2)\n    println(f\"{a}{b}{c}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("binding more names than the tuple has elements must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("out of range")), "{:?}", errs);
}

/// A per-element type annotation that doesn't match the value's actual
/// element type is rejected, same as a mismatched plain `let x: T = v`.
#[test]
fn rejects_destructuring_let_element_type_mismatch() {
    let src = "fn main():\n    let (a, b): (str, i32) = (1, 2)\n    println(f\"{a}{b}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("a mismatched element annotation must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("but the value has type")), "{:?}", errs);
}

/// Reassigning a non-`mut` destructured binding is rejected exactly like a
/// non-`mut` plain `let`.
#[test]
fn rejects_assignment_to_non_mut_destructured_binding() {
    let src = "fn main():\n    let (a, b) = (1, 2)\n    a = 5\n    println(f\"{a}{b}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("assigning into a non-mut destructured binding must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("not declared `mut`")), "{:?}", errs);
}

/// A destructured binding shadowing an existing name behaves like ordinary
/// `let`-shadowing: the new binding's own (lack of) `mut` wins.
#[test]
fn checks_destructuring_let_shadows_existing_binding() {
    let src = "fn main():\n    let mut a = 99\n    let (a, b) = (1, 2)\n    println(f\"{a}{b}\")\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "re-destructuring into an already-bound name should shadow cleanly");
}

// ===== Runtime end-to-end ===================================================

/// Full runtime round trip: a destructured function return, a `mut`
/// destructured pair with a mutation surviving to the read, three-element
/// destructuring, and two destructuring `let`s in the same function (their
/// synthetic temporaries must not collide).
#[test]
fn runtime_destructuring_let_end_to_end() {
    let src = r#"
fn make_pair() -> (i32, str):
    (5, "five")

fn main():
    let (a, b) = make_pair()
    println(f"{a} {b}")
    let mut (x, y) = (1, 2)
    x += 10
    println(f"{x} {y}")
    let (p, q, r) = (7, 8, 9)
    println(f"{p} {q} {r}")
    let (c, d) = (100, 200)
    println(f"{c} {d}")
"#;
    let output = compile_and_run("destructure_end_to_end", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["5 five", "11 2", "7 8 9", "100 200"], "{}", stdout);
}

/// Destructuring inside a loop body re-evaluates the source expression each
/// iteration (the temporary isn't hoisted or cached across iterations).
#[test]
fn runtime_destructuring_let_inside_loop_end_to_end() {
    let src = r#"
fn pair_for(n: i32) -> (i32, i32):
    (n, n * n)

fn main():
    let mut i = 0
    while i < 3:
        let (n, sq) = pair_for(i)
        println(f"{n} {sq}")
        i += 1
"#;
    let output = compile_and_run("destructure_loop_end_to_end", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["0 0", "1 1", "2 4"], "{}", stdout);
}

/// A tuple element that's itself a struct is destructured by value like any
/// other tuple element, and mutating the struct through the destructured
/// (mut) binding doesn't reach back into the original tuple -- ordinary
/// struct-value-copy semantics, unaffected by going through this desugaring.
#[test]
fn runtime_destructuring_let_with_struct_element_end_to_end() {
    let src = r#"
struct Player:
    mut health: i32
    name: str

fn make() -> (Player, i32):
    (Player(health = 10, name = "Bob"), 3)

fn main():
    let mut (player, lives) = make()
    player.health -= 4
    println(f"{player.name} hp={player.health} lives={lives}")
"#;
    let output = compile_and_run("destructure_struct_element_end_to_end", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim(), "Bob hp=6 lives=3");
}

/// A destructuring `let` with an explicit tuple type annotation at the top
/// level of a `sequence` body hoists cleanly -- the annotation is threaded
/// onto the synthetic temporary (not just the per-element bindings), which
/// is exactly what `sequence::desugar_sequence`'s "hoisted local needs an
/// explicit type" rule requires.
#[test]
fn runtime_annotated_destructuring_let_in_sequence_hoists_cleanly_end_to_end() {
    let src = r#"
sequence Pairs():
    let (a, b): (i32, i32) = (1, 2)
    yield
    a += 1
    b += 10
    println(f"{a} {b}")

fn main():
    let mut s = Pairs()
    s.resume()
    s.resume()
"#;
    let output = compile_and_run("destructure_sequence_annotated_end_to_end", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim(), "2 12");
}

/// The unannotated form at the top level of a `sequence` body still fails
/// the pre-existing "hoisted local needs an explicit type" rule -- this
/// desugaring doesn't (and, without evaluating the value expression's type
/// at parse time, can't) exempt its own synthetic temporary from it. Locks
/// in the known limitation rather than leaving it to silently regress into
/// a panic.
#[test]
fn rejects_unannotated_destructuring_let_at_sequence_top_level() {
    let src = "sequence Pairs():\n    let (a, b) = (1, 2)\n    yield\n    println(f\"{a}{b}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("an unannotated destructuring let hoisted out of a sequence body should still need an explicit type")
    };
    assert!(errs.iter().any(|d| d.message.contains("needs an explicit type")), "{:?}", errs);
}

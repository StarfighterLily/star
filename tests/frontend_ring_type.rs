//! `Ring<T,N>` fixed-capacity ring buffer
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Ring<T, N> (`docs/design.md`'s Type System plan, §10's remaining
// ===== indie-tier gap alongside `Table<T>`) -- a fixed-capacity ring buffer,
// ===== lowered to an inline `{ [N x T], i64, i64 }` (data, head, len) like
// ===== `Ty::Array`: no RC header, no heap allocation, no copy-on-write. Its
// ===== `<T, N>` is parsed by a dedicated special case in both
// ===== `Parser::parse_type_inner` (type position) and `Parser::parse_ring_new`
// ===== (`Ring<T, N>()` construction), since `N` is a bare integer literal --
// ===== not a `Type` -- and the ordinary generic-turbofish machinery only ever
// ===== parses comma-separated `Type`s. `push`/`pop`/`len`/indexing mirror
// ===== `List<T>`'s method surface and fails-safe OOB conventions, except
// ===== `push` evicts the oldest element once full instead of growing/no-op'ing
// ===== (there is nowhere to grow to). =======================================

#[test]
fn parses_ring_type_annotation() {
    let src = "fn main():\n    let r: Ring<i32, 3> = Ring<i32, 3>()\n    println(f\"{r.len()}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected a fn item") };
    let Stmt::Let { ty, .. } = &f.body.stmts[0] else { panic!("expected a let stmt") };
    assert_eq!(ty.as_ref(), Some(&Type::Ring(Box::new(Type::Named("i32".into())), 3)), "{:?}", ty);
}

#[test]
fn parses_ring_new_construction() {
    let src = "fn main():\n    let r = Ring<i32, 3>()\n    println(f\"{r.len()}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected a fn item") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected a let stmt") };
    assert!(matches!(value, Expr::RingNew { count: 3, .. }), "{:?}", value);
}

/// Mirrors `Type::Array`'s own negative-size rejection: `N` has no
/// const-expression evaluator, just a plain non-negative integer literal --
/// and, unlike an array, `0` is rejected too (a zero-capacity ring can never
/// hold anything, and its `push`'s eviction path divides by `N`).
#[test]
fn rejects_ring_capacity_zero() {
    let src = "fn main():\n    let r: Ring<i32, 0> = Ring<i32, 0>()\n    println(f\"{r.len()}\")\n";
    assert!(Driver::parse(src).is_err(), "`Ring<T, 0>` should be a parse error");
}

/// `Ring<T, N>()` takes no arguments, mirroring `List<T>()`/`Map<K,V>()`/
/// `Set<T>()` -- unlike those (checked by the checker, since they're plain
/// `StructLit`s), this is caught directly in the parser (`parse_ring_new`),
/// since `Expr::RingNew` is a dedicated node with no generic "arity" concept
/// for the checker to validate against.
#[test]
fn rejects_ring_new_with_arguments() {
    let src = "fn main():\n    let r = Ring<i32, 3>(1)\n    println(f\"{r.len()}\")\n";
    assert!(Driver::parse(src).is_err(), "`Ring<T, N>(1)` should be a parse error -- it takes no arguments");
}

#[test]
fn rejects_ring_push_on_non_mut_receiver() {
    let module = Driver::parse("fn t(r: Ring<i32, 3>):\n    r.push(1)\n").expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("push on a non-mut Ring should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("not declared `mut`")), "{:?}", diags);
}

#[test]
fn rejects_ring_pop_on_non_mut_receiver() {
    let module = Driver::parse("fn t(r: Ring<i32, 3>):\n    r.pop()\n").expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("pop on a non-mut Ring should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("not declared `mut`")), "{:?}", diags);
}

#[test]
fn accepts_ring_push_pop_on_mut_receiver() {
    let module = Driver::parse("fn t(mut r: Ring<i32, 3>):\n    r.push(1)\n    r.pop()\n").expect("should parse");
    assert!(Driver::check(&module).is_ok(), "push/pop on a `mut` Ring should type-check cleanly");
}

#[test]
fn rejects_assignment_to_ring_index_without_mut() {
    let src = "fn main():\n    let r = Ring<i32, 3>()\n    r[0] = 5\n    println(f\"{r[0]}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("assigning into a ring element through a non-`mut` binding must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("not declared `mut`")), "{:?}", errs);
}

/// `Ring<T,N>` has no hashing/equality story (like `List<T>`), so it's
/// rejected as a `Map`/`Set` key/element type -- mirrors
/// `rejects_non_hashable_map_key`.
#[test]
fn rejects_ring_as_map_key() {
    let module = Driver::parse("fn t():\n    let m = Map<Ring<i32, 3>, i32>()\n").expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("Ring<T,N> as a Map key should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("cannot be used as a")), "{:?}", diags);
}

/// `Codegen::llvm_ty` lowers `Ty::Ring` to an anonymous inline
/// `{ [N x T], i64, i64 }` (data, head, len) -- no `%name` declaration, no RC
/// header, mirroring `Ty::Tuple`/`Ty::Array`.
#[test]
fn codegen_ring_lowers_to_inline_llvm_struct_type() {
    let src = "fn main():\n    let r = Ring<i32, 4>()\n    println(f\"{r.len()}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("alloca { [4 x i32], i64, i64 }"), "expected an inline `{{ [4 x i32], i64, i64 }}` alloca: {}", ir);
}

/// The `local_struct_receiver`/`frame_escape_source` gap `TupleIndex`/
/// `ArrayIndex` were fixed for (see
/// `rejects_closure_capturing_plain_local_self_escaping_through_tuple_projection`)
/// applies identically to `RingIndex`: a ring is stored inline, so
/// `ring[idx]` used as a method-call receiver resolves to a real pointer
/// into the ring's own (function-local) storage via `Codegen::emit_place`,
/// not a copy -- a closure capturing that pointer as `self` and escaping via
/// `return` must be rejected the same way.
#[test]
fn rejects_closure_capturing_plain_local_self_escaping_through_ring_projection() {
    let src = r#"struct Holder:
    val: i32

impl Holder:
    fn get_closure(self) -> Fn() -> i32:
        fn(): self.val

fn make() -> Fn() -> i32:
    let mut ring: Ring<Holder, 2> = Ring<Holder, 2>()
    ring.push(Holder(777))
    return ring[0].get_closure()
"#;
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("a closure escaping with a ring-projected local's self pointer should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("ring")), "{:?}", errs);
}

// ===== Regression: `local_struct_receiver` had no `TypedExpr::Call` arm, so
// ===== a method-call receiver that is itself another call's return value
// ===== (`Holder(777).identity().get_closure()`, where `identity()` returns
// ===== `Holder` by value) fell through to its `_ => None` catch-all --
// ===== even though that returned struct is spilled by `Codegen::emit_place`
// ===== into a fresh, function-scoped alloca exactly like a named local, so
// ===== a closure capturing it as `self` by pointer (`get_closure()`) dangles
// ===== the moment `make()` returns, identically to every other receiver
// ===== shape this check already covers. =====================================

/// A closure escaping with `self` captured from a method call chained one
/// level deeper (the receiver is itself another call's return value, not a
/// named local/field/tuple/array/ring projection) must still be rejected.
#[test]
fn rejects_closure_capturing_self_via_chained_method_call_receiver() {
    let src = r#"struct Holder:
    val: i32

impl Holder:
    fn identity(self) -> Holder:
        Holder(self.val)
    fn get_closure(self) -> Fn() -> i32:
        fn(): self.val

fn make() -> Fn() -> i32:
    return Holder(777).identity().get_closure()
"#;
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("a closure escaping with a call-result receiver's self pointer should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("method call's result")), "{:?}", errs);
}

/// Sanity/no-false-positive guard: a chained method call that does *not*
/// return a closure (just an ordinary value) must still type-check cleanly --
/// the fix above must not turn every chained method call into a rejection.
#[test]
fn accepts_chained_method_call_receiver_when_result_is_not_a_closure() {
    let src = r#"struct Holder:
    val: i32

impl Holder:
    fn identity(self) -> Holder:
        Holder(self.val)
    fn double(self) -> i32:
        self.val * 2

fn main():
    let x = Holder(21).identity().double()
    println(f"{x}")
"#;
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "a harmless chained method call should still type-check cleanly: {:?}", Driver::check(&module).err());
}

/// Full runtime round trip via `examples/ring.exe`: construction, `push`
/// filling to capacity, `push` past capacity evicting the oldest element
/// (sliding-window semantics), `pop` (FIFO, oldest first), the safe
/// zero-value fallback for an out-of-bounds read and for `pop` on an empty
/// ring, indexed write, a `str` element type (exercising the RC-safe
/// release-before-overwrite eviction path and zero-after-pop), and a struct
/// element type.
#[test]
fn runtime_ring_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/ring.exe").output().expect("failed to execute ring.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("empty len = 0"), "{}", stdout);
    assert!(stdout.contains("after 3 pushes len = 3"), "{}", stdout);
    assert!(stdout.contains("history = [1, 2, 3]"), "{}", stdout);
    assert!(stdout.contains("after push past capacity len = 3"), "push past capacity must evict, not grow: {}", stdout);
    assert!(stdout.contains("history = [2, 3, 4]"), "eviction must drop the oldest element: {}", stdout);
    assert!(stdout.contains("popped = 2"), "pop must return the oldest (front) element: {}", stdout);
    assert!(stdout.contains("len after pop = 2"), "{}", stdout);
    assert!(stdout.contains("history[99] = 0"), "OOB read yields the zero value: {}", stdout);
    assert!(stdout.contains("pop from empty = 0"), "pop on an empty ring yields the zero value: {}", stdout);
    assert!(stdout.contains("history[0] after set = 100"), "indexed write: {}", stdout);
    assert!(stdout.contains("names = [beta, gamma]"), "Ring<str,N> eviction: {}", stdout);
    assert!(stdout.contains("party[0] = Hero hp=100"), "Ring<Player,N> (struct element type): {}", stdout);
}

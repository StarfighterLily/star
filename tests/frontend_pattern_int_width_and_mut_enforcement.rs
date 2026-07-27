//! `Pattern::Int` width regression; `mut` enforcement
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Regression: `Pattern::Int`/`Pattern::Compare` were checked (and
// ===== lowered) as if every integer scrutinee were the original `i32`
// ===== `Ty::Int`, unconditionally rejecting every explicit-width type
// ===== (`i8`/`u8`/`i16`/`u16`/`u32`/`i64`/`u64`) added since -- `match x: 5
// ===== -> ..` against a `u8`/`i64`/etc. scrutinee was a compile error, and
// ===== codegen hardcoded `icmp eq i32` regardless of the scrutinee's real
// ===== width even if the checker had let it through. ========================

/// A literal-int match pattern against every explicit-width integer
/// scrutinee (not just the original `i32`) type-checks cleanly.
#[test]
fn accepts_int_pattern_against_every_sized_int_scrutinee() {
    for ty in ["i8", "u8", "i16", "u16", "u32", "i64", "u64"] {
        let src = format!("fn f(n: {}) -> i32:\n    match n:\n        0 -> 1\n        _ -> 2\n", ty);
        let module = Driver::parse(&src).expect("should parse");
        assert!(Driver::check(&module).is_ok(), "int pattern against a `{}` scrutinee should type-check cleanly", ty);
    }
}

/// Same widening for a comparison pattern (`<=`/`>=`/`<`/`>`), against both a
/// signed and an unsigned explicit-width scrutinee -- codegen must pick the
/// right signed/unsigned `icmp` predicate for each.
#[test]
fn accepts_compare_pattern_against_signed_and_unsigned_sized_int_scrutinees() {
    for ty in ["i8", "u8", "i64", "u32"] {
        let src = format!("fn f(n: {}) -> i32:\n    match n:\n        <= 5 -> 1\n        _ -> 2\n", ty);
        let module = Driver::parse(&src).expect("should parse");
        assert!(Driver::check(&module).is_ok(), "compare pattern against a `{}` scrutinee should type-check cleanly", ty);
    }
}

/// Full runtime round trip: a literal pattern against a `u8` scrutinee whose
/// value only fits because the pattern is compared at `u8`'s own width (`200`
/// doesn't fit a signed `i8`), a `<=` compare pattern against a negative
/// `i64` scrutinee, and a `>=` compare pattern against a `u32` scrutinee --
/// covering both signed and unsigned `icmp` lowering.
#[test]
fn runtime_match_int_and_compare_patterns_against_sized_int_scrutinees_end_to_end() {
    let src = "fn main():\n    let x: u8 = 200 as u8\n    match x:\n        200 -> println(\"two hundred\")\n        _ -> println(\"other\")\n    let y: i64 = -5 as i64\n    match y:\n        <= -1 -> println(\"negative\")\n        _ -> println(\"non-negative\")\n    let z: u32 = 40 as u32\n    match z:\n        >= 30 -> println(\"big unsigned\")\n        _ -> println(\"small\")\n";
    let output = compile_and_run("match_sized_int_patterns", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["two hundred", "negative", "big unsigned"], "{}", stdout);
}

/// A method declaring no `self` at all (an "associated function" still
/// called via `obj.method(...)` syntax) had its call-site argument count
/// silently mis-checked: `check_call_args` was always told `skip_self =
/// true` whenever the callee was `Field`-shaped, unconditionally dropping
/// the *first declared parameter* believing it was an implicit `self` --
/// regardless of whether the matched method actually declared one. A
/// missing/extra argument at the call site went completely undetected, and
/// codegen's call-site receiver-pointer-as-arg0 convention (also fixed
/// alongside this) would have produced silent argument-shape UB.
#[test]
fn rejects_wrong_arg_count_for_self_less_method_call() {
    let src = "struct Player:\n    health: i32\nimpl Player:\n    fn combine(a: i32, b: i32) -> i32:\n        return a + b\nfn main():\n    let p = Player(health = 100)\n    let r = p.combine(7)\n    println(f\"{r}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("calling a self-less method with the wrong argument count must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("expects 2 argument")), "{:?}", errs);
}

/// Functional regression guard: a correctly-called self-less method must
/// still compile and run, with no receiver pointer threaded into its call
/// (its LLVM signature has no leading pointer parameter at all).
#[test]
fn runtime_self_less_method_call_end_to_end() {
    let src = "struct Player:\n    health: i32\nimpl Player:\n    fn combine(a: i32, b: i32) -> i32:\n        return a + b\nfn main():\n    let p = Player(health = 100)\n    println(f\"{p.combine(3, 7)}\")\n";
    let output = compile_and_run("self_less_method_call", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "10", "{}", stdout);
}

// ===== `mut` enforcement (docs/design.md: "`mut` is required to change ==
// ===== state") -- previously parsed and threaded everywhere but never ===
// ===== once read by any check, so every binding was silently mutable ====
// ===== regardless of the keyword. ========================================

#[test]
fn rejects_assignment_to_non_mut_let_binding() {
    let src = "fn main():\n    let x = 5\n    x = 10\n    println(f\"{x}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("reassigning a non-`mut` binding must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("not declared `mut`")), "{:?}", errs);
}

#[test]
fn accepts_assignment_to_mut_let_binding() {
    let src = "fn main():\n    let mut x = 5\n    x = 10\n    println(f\"{x}\")\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "reassigning a `mut` binding should type-check cleanly");
}

#[test]
fn rejects_assignment_to_struct_field_not_declared_mut() {
    let src = "struct Player:\n    health: i32\nfn main():\n    let mut p = Player(health = 100)\n    p.health = 0\n    println(f\"{p.health}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("assigning to a field not declared `mut` must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("field `health` is not mutable")), "{:?}", errs);
}

#[test]
fn accepts_assignment_to_mut_struct_field_via_mut_binding() {
    let src = "struct Player:\n    mut health: i32\nfn main():\n    let mut p = Player(health = 100)\n    p.health = 0\n    println(f\"{p.health}\")\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "assigning to a `mut` field through a `mut` binding should type-check cleanly");
}

/// Both halves of the rule are independently required: a `mut` field can
/// still not be assigned through a *non-`mut`* binding.
#[test]
fn rejects_assignment_through_non_mut_binding_even_if_field_is_mut() {
    let src = "struct Player:\n    mut health: i32\nfn main():\n    let p = Player(health = 100)\n    p.health = 0\n    println(f\"{p.health}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("assigning through a non-`mut` binding must be rejected even if the field itself is `mut`") };
    assert!(errs.iter().any(|d| d.message.contains("not declared `mut`")), "{:?}", errs);
}

#[test]
fn rejects_assignment_to_non_mut_parameter() {
    let src = "fn f(x: i32):\n    x = 1\nfn main():\n    f(5)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("reassigning a non-`mut` parameter must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("not declared `mut`")), "{:?}", errs);
}

#[test]
fn accepts_assignment_to_mut_parameter() {
    let src = "fn f(mut x: i32):\n    x = 1\n    println(f\"{x}\")\nfn main():\n    f(5)\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "reassigning a `mut` parameter should type-check cleanly");
}

/// `fn foo(mut self)` is required to mutate `self`'s fields, exactly like
/// any other binding -- `self` is just a parameter named `self` under the
/// hood (see `Param { is_self: true, .. }`).
#[test]
fn rejects_assignment_to_field_via_non_mut_self_receiver() {
    let src = "struct Player:\n    mut health: i32\nimpl Player:\n    fn hurt(self, amount: i32):\n        self.health -= amount\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("mutating a field through a non-`mut self` receiver must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("cannot assign to self")), "{:?}", errs);
}

#[test]
fn accepts_assignment_to_mut_field_via_mut_self_receiver() {
    let src = "struct Player:\n    mut health: i32\nimpl Player:\n    fn hurt(mut self, amount: i32):\n        self.health -= amount\nfn main():\n    let mut p = Player(health = 100)\n    p.hurt(10)\n    println(f\"{p.health}\")\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "mutating a `mut` field through `mut self` should type-check cleanly");
}

/// A `GenRef<T>` is a handle into arena-owned storage, not a value the local
/// binding itself owns -- mirrors a Rust `&mut T` reference, where `let r =
/// &mut x; *r = v;` needs no `mut` on `r` itself. Mutating through one is
/// gated purely by the pointed-to struct's own per-field `mut` declaration,
/// independent of whether the binding holding the `GenRef` is `mut`.
#[test]
fn accepts_assignment_through_genref_index_without_mut_binding_on_handle() {
    let src = "struct Entity:\n    mut hp: i32\narena Entities: Entity\nfn main():\n    spawn Entities(100)\n    let r = GenRef<Entity>(0)\n    r[0].hp -= 10\n    println(f\"{r[0].hp}\")\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "mutating through a `GenRef` should not require the handle binding itself to be `mut`: {:?}", Driver::check(&module).err());
}

/// Same field-level gap as `rejects_list_push_on_non_mut_field_even_through_mut_self`,
/// reached through a `GenRef` receiver instead of `self`: `assign_root_name`
/// deliberately returns `None` for a `GenRefIndex` base (mutating through a
/// `GenRef` is gated purely by the pointed-to struct's own per-field `mut`
/// declaration, not by any `mut_vars` check on the handle), so
/// `check_mut_receiver`'s root-binding check alone can never catch this
/// case -- only the field-level `field_is_mut` check (added alongside this
/// test) does.
#[test]
fn rejects_list_push_through_genref_on_non_mut_field() {
    let src = concat!(
        "struct Entity:\n",
        "    mut hp: i32\n",
        "    items: List<i32>\n",
        "arena Entities: Entity\n",
        "fn main():\n",
        "    spawn Entities(hp = 100, items = List<i32>())\n",
        "    let r = GenRef<Entity>(0)\n",
        "    r[0].items.push(5)\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("push through a GenRef on a non-`mut` field must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("field `items` is not mutable")), "{:?}", errs);
}

/// Positive counterpart: a `mut`-declared field reached through a `GenRef`
/// still type-checks cleanly -- no false positive from the new check.
#[test]
fn accepts_list_push_through_genref_on_mut_field() {
    let src = concat!(
        "struct Entity:\n",
        "    mut hp: i32\n",
        "    mut items: List<i32>\n",
        "arena Entities: Entity\n",
        "fn main():\n",
        "    spawn Entities(hp = 100, items = List<i32>())\n",
        "    let r = GenRef<Entity>(0)\n",
        "    r[0].items.push(5)\n",
        "    println(f\"{r[0].items.len()}\")\n",
    );
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "push through a GenRef on a `mut` field should type-check cleanly: {:?}", Driver::check(&module).err());
}

/// `par`/`swarm`'s entire purpose is safe, disjointness-proven in-place
/// mutation of each worker's own arena element -- there's no `mut` keyword
/// available in `par var in arena:` syntax at all, so the loop variable must
/// be implicitly, unconditionally mutable (safety is enforced by
/// `check_par_disjoint`, not by requiring a keyword that can't be written).
#[test]
fn accepts_par_loop_var_field_mutation_without_mut_keyword() {
    let src = format!("{}fn t():\n    par e in Enemies:\n        e.hp -= 1\n", PAR_SRC_PREFIX);
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "mutating a par loop variable's field should not require a `mut` keyword that doesn't exist in the grammar");
}

/// `mut_vars` scoping regression guard: a lambda parameter shadowing an
/// outer `mut` variable of the same name, but itself *not* declared `mut`,
/// must not inherit the outer variable's mutability inside the lambda body
/// -- and, symmetrically, must not leak its own (non-)mutability back out
/// to the enclosing scope once the lambda literal ends.
#[test]
fn rejects_assignment_to_lambda_param_shadowing_outer_mut_var_when_param_not_mut() {
    let src = "fn main():\n    let mut x = 1\n    let f = fn(x: i32) -> i32:\n        x = x + 1\n        x\n    println(f\"{f(5)}\")\n    x = 2\n    println(f\"{x}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("reassigning a non-`mut` lambda parameter that shadows an outer `mut` variable must still be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("not declared `mut`")), "{:?}", errs);
}

/// `mut_vars` corruption-through-monomorphization regression guard:
/// on-demand generic instantiation (`Checker::instantiate_struct`/
/// `instantiate_impl_methods`/`instantiate_generic_fn`/`instantiate_enum`,
/// all of which route through `check_fn` -> `check_block` to type-check the
/// freshly-synthesized item's own body) can be triggered *mid-statement*,
/// while an enclosing block's own statement loop is still in progress --
/// e.g. the very first use of a generic struct's method inside a `while`
/// loop. `Checker::check_block` used to unconditionally `self.mut_vars.
/// clear()` at the start of *every* function body it checked, including one
/// triggered this way, silently wiping out whatever the enclosing (still
/// in-progress) block's own live `mut_vars` set was -- so a `mut` variable
/// declared earlier in the very same block (a loop counter, here) would
/// spuriously fail "cannot assign to `i` -- it was not declared `mut`" on
/// every assignment *after* the point where the first not-yet-instantiated
/// generic use appeared, purely because of unrelated code earlier in the
/// same block. Confirmed via a real `star check` run before this fix: a
/// `let mut i = 0` followed by a `while i < N:` body that calls a generic
/// struct's method before `i = i + 1` failed to type-check at all, even
/// though nothing about `i`'s own mutability changed.
#[test]
fn runtime_mut_loop_counter_survives_first_use_of_generic_struct_method_mid_loop_end_to_end() {
    let src = concat!(
        "struct Box<T>:\n    mut value: T\n    label: str\n",
        "impl Box<T>:\n    fn get_self(self) -> Box<T>:\n        return self\n",
        "fn main():\n",
        "    let mut i = 0\n",
        "    while i < 5:\n",
        "        let b = Box<i32>(value = i, label = \"x\")\n",
        "        let c = b.get_self()\n",
        "        i = i + 1\n",
        "    println(f\"{i}\")\n",
    );
    let output = compile_and_run("mut_counter_survives_generic_method_mid_loop", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "5");
}

/// Same shape, but the first-use-mid-loop trigger is a generic *function*
/// (`instantiate_generic_fn`) rather than a generic struct's method
/// (`instantiate_impl_methods`) -- guards the fix in `Checker::check_block`
/// is the shared root cause fix (every on-demand-instantiation path funnels
/// through it), not something that happened to only cover one call site.
#[test]
fn runtime_mut_loop_counter_survives_first_use_of_generic_fn_mid_loop_end_to_end() {
    let src = concat!(
        "fn identity<T>(x: T) -> T:\n    return x\n",
        "fn main():\n",
        "    let mut i = 0\n",
        "    while i < 5:\n",
        "        let y = identity(i)\n",
        "        i = i + 1\n",
        "    println(f\"{i}\")\n",
    );
    let output = compile_and_run("mut_counter_survives_generic_fn_mid_loop", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "5");
}

/// `loop_depth` corruption-through-monomorphization regression guard --
/// the exact same hazard class as `runtime_mut_loop_counter_survives_first_
/// use_of_generic_struct_method_mid_loop_end_to_end` above, just against
/// `Checker::check_fn_with_self_ty`'s own `loop_depth` reset instead of
/// `check_block`'s `mut_vars` reset. A `while` loop's body calling a generic
/// struct's method (triggering monomorphization, which re-enters
/// `check_fn_with_self_ty` for that method's own loop-free body) *before* a
/// trailing `if ...: break` used to make that `break` spuriously fail ``
/// `break` outside of a loop `` -- the nested method's own body-checking
/// zeroed `loop_depth` and never restored the enclosing `while` loop's
/// nesting count afterward.
#[test]
fn runtime_break_survives_first_use_of_generic_struct_method_mid_loop_end_to_end() {
    let src = concat!(
        "struct Box<T>:\n    mut value: T\n",
        "impl Box<T>:\n    fn get_self(self) -> Box<T>:\n        return self\n",
        "fn main():\n",
        "    let mut i = 0\n",
        "    while i < 5:\n",
        "        let b = Box<i32>(value = i)\n",
        "        let c = b.get_self()\n",
        "        i = i + 1\n",
        "        if i == 3:\n            break\n",
        "    println(f\"{i}\")\n",
    );
    let output = compile_and_run("break_survives_generic_method_mid_loop", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "3");
}

/// A `break` genuinely outside any loop is still rejected -- guards the
/// `loop_depth` save/restore fix above didn't also weaken the underlying
/// check itself.
#[test]
fn rejects_break_outside_loop_after_loop_depth_fix() {
    let src = "fn main():\n    break\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("`break` outside a loop should still be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("outside of a loop")), "{:?}", errs);
}

/// A match-arm binding pattern (`Pattern::Binding`) introduces an immutable
/// local by default, same as a plain `let` -- there's no `mut` syntax for a
/// pattern binding, so it can never be reassigned inside its arm.
#[test]
fn rejects_assignment_to_match_binding_pattern() {
    let src = "fn f(n: i32) -> i32:\n    match n:\n        v ->\n            v = v + 1\n            v\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("reassigning a match-arm binding pattern must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("not declared `mut`")), "{:?}", errs);
}

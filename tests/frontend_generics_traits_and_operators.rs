//! Trait-bounded generics, impl Trait, operator overloading, comparison typing, f-string lexing, duplicate top-level decls
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== trait-bounded generics (`todo.md` P2 #7) =============================
//
// `fn f<T: SomeTrait>(x: T)`: before this, a generic function's type
// parameter list (`FnSig`/`StructDef`/`EnumDef`/`ImplBlock::type_params`)
// was a bare `Vec<String>` of names with no bound syntax at all -- writing
// `T: SomeTrait` was a hard parse error. `TypeParam { name, bounds }`
// (`src/ast.rs`) adds the grammar; `Checker::check_type_bounds`
// (`src/types/mod.rs`), consulted from every call/construction site that
// infers a generic template's concrete type arguments
// (`infer_generic_call`/`infer_generic_struct_lit`/`infer_generic_enum_variant`,
// `src/types/expr.rs`), rejects a monomorphization whose concrete type
// argument doesn't implement every bound its type parameter declares --
// checked nominally (an actual `impl Trait for X:` block must exist,
// registered into `Checker::trait_impls` during pass 1), not structurally:
// a type with a same-named, same-shaped method but no matching `impl` block
// does not satisfy a bound naming that trait.

const TRAIT_BOUND_SPEAKER_SRC: &str = "trait Speaker:\n    fn speak(self) -> i32\n\nstruct Dog:\n    volume: i32\n\nimpl Speaker for Dog:\n    fn speak(self) -> i32:\n        return self.volume\n\n";

const TRAIT_BOUND_SPEAKER_AND_NAMED_SRC: &str = "trait Speaker:\n    fn speak(self) -> i32\n\ntrait Named:\n    fn name(self) -> i32\n\nstruct Dog:\n    volume: i32\n\nimpl Speaker for Dog:\n    fn speak(self) -> i32:\n        return self.volume\n\nimpl Named for Dog:\n    fn name(self) -> i32:\n        return 1\n\nstruct Cat:\n    pitch: i32\n\nimpl Speaker for Cat:\n    fn speak(self) -> i32:\n        return self.pitch\n\n";

/// A single trait bound (`T: Speaker`) parses into `TypeParam::bounds`.
#[test]
fn parses_generic_fn_type_param_with_single_trait_bound() {
    let src = "fn f<T: Speaker>(x: T) -> i32:\n    return 0\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected a fn") };
    assert_eq!(f.sig.type_params, vec![TypeParam { name: "T".into(), bounds: vec!["Speaker".into()] }]);
}

/// Multiple `+`-separated bounds (`T: Speaker + Named`) all parse into the
/// same type parameter's `bounds` list, in declaration order.
#[test]
fn parses_generic_fn_type_param_with_multiple_trait_bounds() {
    let src = "fn f<T: Speaker + Named>(x: T) -> i32:\n    return 0\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected a fn") };
    assert_eq!(f.sig.type_params, vec![TypeParam { name: "T".into(), bounds: vec!["Speaker".into(), "Named".into()] }]);
}

/// A generic struct's own type parameter can also carry a trait bound
/// (`struct Cage<T: Speaker>:`), parsed via the same `parse_opt_type_params`
/// path `fn`'s type parameters use.
#[test]
fn parses_generic_struct_type_param_with_trait_bound() {
    let src = "struct Cage<T: Speaker>:\n    occupant: T\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Struct(s) = &module.items[0] else { panic!("expected a struct") };
    assert_eq!(s.type_params, vec![TypeParam { name: "T".into(), bounds: vec!["Speaker".into()] }]);
}

/// Bounded and unbounded type parameters can appear side by side in the same
/// `<...>` list (`<T: Speaker, U>`) -- a bound is per-parameter, not
/// all-or-nothing for the whole list.
#[test]
fn parses_mixed_bounded_and_unbounded_type_params() {
    let src = "fn f<T: Speaker, U>(x: T, y: U) -> i32:\n    return 0\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected a fn") };
    assert_eq!(
        f.sig.type_params,
        vec![TypeParam { name: "T".into(), bounds: vec!["Speaker".into()] }, TypeParam { name: "U".into(), bounds: Vec::new() }]
    );
}

/// A generic function whose body calls a trait method on its bounded type
/// parameter, called with a type that *does* implement that trait, type-checks
/// cleanly -- the trait-bound ceiling `todo.md` names being lifted.
#[test]
fn accepts_generic_fn_calling_trait_method_on_bounded_type_param() {
    let src = format!("{}{}", TRAIT_BOUND_SPEAKER_SRC, "fn announce<T: Speaker>(x: T) -> i32:\n    return x.speak()\n\nfn main():\n    announce(Dog(volume = 3))\n");
    let module = Driver::parse(&src).expect("should parse");
    Driver::check(&module).expect("a bounded generic fn called with a type implementing the bound should type-check");
}

/// The core rejection case: calling a `T: Speaker`-bounded generic function
/// with a type that does not implement `Speaker` (a bare `i32`, which can
/// never implement any trait -- `impl` is struct-only in this language) is a
/// clean, located type error naming the offending type, the bound, and the
/// generic function -- not a raw "no method" error surfacing from deep
/// inside the substituted body.
#[test]
fn rejects_generic_fn_call_violating_trait_bound() {
    let src = format!("{}{}", TRAIT_BOUND_SPEAKER_SRC, "fn announce<T: Speaker>(x: T) -> i32:\n    return x.speak()\n\nfn main():\n    announce(5)\n");
    let module = Driver::parse(&src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("a generic call whose type argument doesn't implement the bound trait should be rejected")
    };
    assert!(
        errs.iter().any(|d| d.message.contains("does not satisfy the trait bound") && d.message.contains("Speaker") && d.message.contains("announce")),
        "{:?}", errs
    );
    // And no cascading "no field/method `speak`" diagnostic from also
    // type-checking the (substituted) body against the bad argument --
    // `check_type_bounds` returning `false` short-circuits the instantiation
    // entirely, see its own doc comment.
    assert!(!errs.iter().any(|d| d.message.contains("speak")), "should not cascade a second diagnostic: {:?}", errs);
}

/// A struct with a same-named, same-shaped *inherent* method (no `impl
/// Speaker for Robot:` at all) does not satisfy a `T: Speaker` bound --
/// trait bounds are nominal, not structural, even though plain (unbounded)
/// generic monomorphization elsewhere in this checker is fully duck-typed.
#[test]
fn rejects_generic_fn_call_with_structurally_matching_but_not_nominally_implementing_type() {
    let src = format!(
        "{}{}",
        TRAIT_BOUND_SPEAKER_SRC,
        "struct Robot:\n    id: i32\n\nimpl Robot:\n    fn speak(self) -> i32:\n        return self.id\n\nfn announce<T: Speaker>(x: T) -> i32:\n    return x.speak()\n\nfn main():\n    announce(Robot(id = 1))\n"
    );
    let module = Driver::parse(&src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("a structurally-matching but not nominally-trait-implementing type should still violate the bound")
    };
    assert!(errs.iter().any(|d| d.message.contains("does not satisfy the trait bound") && d.message.contains("Speaker")), "{:?}", errs);
}

/// Same rejection, reached through generic struct construction
/// (`resolve_generic_ctor_args`/`infer_generic_struct_lit` share the same
/// `check_type_bounds` call as the generic-fn-call path).
#[test]
fn rejects_generic_struct_ctor_violating_trait_bound() {
    let src = format!(
        "{}{}",
        TRAIT_BOUND_SPEAKER_SRC,
        "struct Cage<T: Speaker>:\n    occupant: T\n\nfn main():\n    Cage(occupant = 5)\n"
    );
    let module = Driver::parse(&src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("a generic struct literal whose type argument doesn't implement the bound trait should be rejected")
    };
    assert!(
        errs.iter().any(|d| d.message.contains("does not satisfy the trait bound") && d.message.contains("Speaker") && d.message.contains("Cage")),
        "{:?}", errs
    );
}

/// Same rejection again, reached through generic enum-variant construction
/// (`infer_generic_enum_variant` shares the same `check_type_bounds` call).
#[test]
fn rejects_generic_enum_variant_ctor_violating_trait_bound() {
    let src = format!(
        "{}{}",
        TRAIT_BOUND_SPEAKER_SRC,
        "enum Boxed<T: Speaker>:\n    Wrapped(value: T)\n\nfn main():\n    Boxed::Wrapped(5)\n"
    );
    let module = Driver::parse(&src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("a generic enum variant construction whose type argument doesn't implement the bound trait should be rejected")
    };
    assert!(
        errs.iter().any(|d| d.message.contains("does not satisfy the trait bound") && d.message.contains("Speaker") && d.message.contains("Boxed")),
        "{:?}", errs
    );
}

/// Multiple bounds (`T: Speaker + Named`) are checked independently -- a
/// type implementing only one of the two named traits is rejected with a
/// diagnostic naming specifically the one it's missing, not the one it
/// already satisfies.
#[test]
fn rejects_generic_fn_call_missing_one_of_multiple_trait_bounds() {
    let src = format!(
        "{}{}",
        TRAIT_BOUND_SPEAKER_AND_NAMED_SRC,
        "fn introduce<T: Speaker + Named>(x: T) -> i32:\n    return x.speak()\n\nfn main():\n    introduce(Cat(pitch = 2))\n"
    );
    let module = Driver::parse(&src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("Cat implements Speaker but not Named, so a T: Speaker + Named bound should reject it")
    };
    assert!(errs.iter().any(|d| d.message.contains("does not satisfy the trait bound") && d.message.contains("Named")), "{:?}", errs);
    assert!(!errs.iter().any(|d| d.message.contains("trait bound `T: Speaker`")), "should not also complain about the bound Cat already satisfies: {:?}", errs);
}

/// A type implementing *every* bound in a multi-bound list type-checks
/// cleanly and can call methods from each named trait.
#[test]
fn accepts_generic_fn_calling_methods_from_multiple_trait_bounds() {
    let src = format!(
        "{}{}",
        TRAIT_BOUND_SPEAKER_AND_NAMED_SRC,
        "fn introduce<T: Speaker + Named>(x: T) -> i32:\n    return x.speak() + x.name()\n\nfn main():\n    introduce(Dog(volume = 3))\n"
    );
    let module = Driver::parse(&src).expect("should parse");
    Driver::check(&module).expect("a type implementing every named bound should type-check");
}

/// A bound naming a trait that doesn't exist at all is a clean, dedicated
/// diagnostic (not a panic, not silently treated as always-satisfied) --
/// checked lazily at the same call-site point as bound satisfaction itself,
/// consistent with this checker's "a generic template is never checked on
/// its own, only its instantiations are" design (see `types/mod.rs`'s
/// "Generics: monomorphization support" module doc comment).
#[test]
fn rejects_generic_fn_call_with_bound_naming_undefined_trait() {
    let src = "fn f<T: Nonexistent>(x: T) -> i32:\n    return 0\nfn main():\n    f(5)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("a bound naming an undefined trait should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("undefined trait") && d.message.contains("Nonexistent")), "{:?}", errs);
}

/// An `impl Trait for GenericStruct<A, B>:` block implements the trait for
/// *every* instantiation of that struct, not just one -- `trait_impls` is
/// keyed by the template name (`"Pair"`), not any one mangled instantiation
/// (`"Pair__i32__str"`), consulted via `mono_struct_of`. Two different
/// instantiations of the same generic struct both satisfy a bound naming
/// that trait.
#[test]
fn trait_bound_satisfied_via_generic_struct_impl_covers_every_instantiation() {
    let src = "trait Describable:\n    fn describe(self) -> i32\n\nstruct Pair<A, B>:\n    first: A\n    second: B\n\nimpl Describable for Pair<A, B>:\n    fn describe(self) -> i32:\n        return 1\n\nfn report<T: Describable>(x: T) -> i32:\n    return x.describe()\n\nfn main():\n    report(Pair(first = 1, second = 2))\n    report(Pair(first = \"a\", second = 1.5))\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("every instantiation of a generic struct with a trait impl should satisfy a bound naming that trait");
}

/// A plain, unbounded type parameter (`<T>`, no `: Trait`) is completely
/// unaffected by bound checking -- it still accepts any concrete type at
/// all, exactly as before this feature existed. Guards `check_type_bounds`
/// (an empty `bounds` list short-circuits its inner loop to a no-op) against
/// accidentally becoming a blanket "every generic call must implement
/// something" gate.
#[test]
fn unbounded_type_param_still_accepts_any_concrete_type() {
    let src = "fn identity<T>(x: T) -> T:\n    return x\nfn main():\n    identity(5)\n    identity(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("an unbounded type parameter must keep accepting any concrete type");
}

/// Codegen for a trait-bounded generic function call: the monomorphized
/// body's `x.speak()` call dispatches to the concrete type's own trait-impl
/// method (`Dog__speak`, mangled the same way any inherent or trait method
/// is -- see `src/codegen/mod.rs`'s `"{}__{}"` method-name mangling), inside
/// the generic function's own mangled instantiation (`announce__Dog`).
#[test]
fn codegen_generic_fn_with_trait_bound_dispatches_to_correct_impl_method() {
    let src = format!("{}{}", TRAIT_BOUND_SPEAKER_SRC, "fn announce<T: Speaker>(x: T) -> i32:\n    return x.speak()\n\nfn main() -> i32:\n    announce(Dog(volume = 3))\n");
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("define i32 @announce__Dog("), "{}", ir);
    assert!(ir.contains("define i32 @Dog__speak("), "{}", ir);
    assert!(ir.contains("call i32 @Dog__speak("), "{}", ir);
}

/// Full end-to-end runtime coverage for the feature: `examples/trait_bounded_generics.exe`
/// exercises a single trait bound calling a trait method (`announce<T: Speaker>`),
/// a multi-bound function calling methods from two different traits
/// (`introduce<T: Speaker + Named>`), and a trait-bounded generic struct
/// (`Cage<T: Speaker>`) whose method calls a trait method on its own bounded
/// field -- through a real clang-compiled executable, not just the checker.
#[test]
fn runtime_trait_bounded_generics_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/trait_bounded_generics.exe").output().expect("failed to execute trait_bounded_generics.exe");
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("dog: Woof"), "single trait bound calling a trait method: {}", stdout);
    assert!(stdout.contains("cat: Meow"), "single trait bound instantiated at a second, unrelated implementing type: {}", stdout);
    assert!(stdout.contains("intro: Rex says Woof"), "multi-bound fn calling methods from two different traits: {}", stdout);
    assert!(stdout.contains("caged: Woof"), "trait-bounded generic struct method calling a trait method on its own bounded field: {}", stdout);
}

/// Inline (non-committed-example) runtime coverage for the rejection path
/// mirrored above at the checker level -- proves the diagnostic is real
/// `star check`-visible behavior via `Driver::check`, not just an artifact
/// of how these particular unit tests call the checker directly.
#[test]
fn runtime_generic_fn_call_satisfying_trait_bound_end_to_end() {
    let src = format!("{}{}", TRAIT_BOUND_SPEAKER_SRC, "fn announce<T: Speaker>(x: T) -> i32:\n    return x.speak()\n\nfn main():\n    let v = announce(Dog(volume = 9))\n    println(f\"{v}\")\n");
    let output = compile_and_run("trait_bound_satisfied", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "9", "{}", stdout);
}

/// A trait bound declared in one module is still correctly resolved (and
/// enforced) against an `impl` in another module reached through an import
/// alias -- `crate::modules::rename_type_params` mangles a bound's trait
/// name (`Speaker` -> `lib__Speaker`) the same way every other cross-module
/// reference is mangled, so `Checker::trait_impls`/`Checker::traits` (both
/// populated from the already-renamed, already-merged module) agree with
/// what the bound itself names. Before that fix, a bound's trait name was
/// cloned verbatim by every `rename_*` helper, so an imported bound would
/// name the trait's *original* (un-mangled) name while `self.traits` only
/// ever registered the mangled one -- silently failing every such bound
/// with "undefined trait" regardless of whether the referenced type
/// actually implemented it.
#[test]
fn cross_module_generic_fn_trait_bound_resolves_through_import_alias_end_to_end() {
    let dir = test_scratch_dir("cross_module_generic_fn_trait_bound_resolves_through_import_alias_end_to_end");
    write_test_file(
        &dir, "lib.star",
        "trait Speaker:\n    fn speak(self) -> i32\n\nstruct Dog:\n    volume: i32\n\nimpl Speaker for Dog:\n    fn speak(self) -> i32:\n        return self.volume\n\nfn announce<T: Speaker>(x: T) -> i32:\n    return x.speak()\n",
    );
    let main_path = write_test_file(
        &dir, "main.star",
        "import \"lib.star\" as lib\n\nfn main():\n    let v = lib::announce(lib::Dog(volume = 12))\n    println(f\"{v}\")\n",
    );

    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(compilation.is_ok(), "{}", compilation.render_diagnostics());

    let _ = std::fs::remove_dir_all(&dir);
}

/// Same cross-module setup, but the call site's type argument does *not*
/// implement the imported trait -- the bound violation must still be
/// reported (not silently accepted because the mangled names failed to
/// line up, which would be the failure mode of the bug described in
/// `cross_module_generic_fn_trait_bound_resolves_through_import_alias_end_to_end`'s
/// doc comment going the other, worse way).
#[test]
fn cross_module_generic_fn_trait_bound_violation_still_rejected_end_to_end() {
    let dir = test_scratch_dir("cross_module_generic_fn_trait_bound_violation_still_rejected_end_to_end");
    write_test_file(
        &dir, "lib.star",
        "trait Speaker:\n    fn speak(self) -> i32\n\nfn announce<T: Speaker>(x: T) -> i32:\n    return x.speak()\n",
    );
    let main_path = write_test_file(
        &dir, "main.star",
        "import \"lib.star\" as lib\n\nfn main():\n    let v = lib::announce(5)\n    println(f\"{v}\")\n",
    );

    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(!compilation.is_ok(), "a cross-module bound violation should still be rejected");
    let rendered = compilation.render_diagnostics();
    assert!(rendered.contains("does not satisfy the trait bound"), "{}", rendered);

    let _ = std::fs::remove_dir_all(&dir);
}

// ===== impl Trait completeness ===============================================

/// `impl Trait for Type` that never defines one of the trait's required
/// methods must be rejected -- previously nothing checked this, and (since
/// traits are purely nominal, with no dynamic dispatch anywhere in codegen)
/// there was no other point in the pipeline that could ever catch it either.
#[test]
fn rejects_impl_missing_trait_method() {
    let src = "trait Greeter:\n    fn greet(self) -> i32\nstruct Foo:\n    x: i32\nimpl Greeter for Foo:\n    fn other(self) -> i32:\n        return self.x\nfn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("an impl missing a required trait method should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("missing method") && d.message.contains("greet")), "{:?}", errs);
}

/// A method present under the trait's exact name but with the wrong arity
/// must also be rejected -- a name match alone doesn't mean the impl
/// actually provides what the trait requires.
#[test]
fn rejects_impl_method_wrong_arity_for_trait() {
    let src = "trait Greeter:\n    fn greet(self, n: i32) -> i32\nstruct Foo:\n    x: i32\nimpl Greeter for Foo:\n    fn greet(self) -> i32:\n        return self.x\nfn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("an impl method with the wrong arity for its trait method should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("parameter(s)") && d.message.contains("greet")), "{:?}", errs);
}

/// An impl that faithfully provides every trait method must still work end
/// to end -- guards against the two checks above being so aggressive they
/// reject sound, ordinary trait impls (mirrors `examples/player.star`'s
/// `Damageable`/`Player` shape).
#[test]
fn runtime_impl_satisfying_trait_exactly_end_to_end() {
    let src = "trait Greeter:\n    fn greet(self) -> i32\nstruct Foo:\n    x: i32\nimpl Greeter for Foo:\n    fn greet(self) -> i32:\n        return self.x\nfn main():\n    let f = Foo(x = 5)\n    println(f\"{f.greet()}\")\n";
    let output = compile_and_run("impl_satisfying_trait_exactly", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "5", "{}", stdout);
}

// ===== operator overloading ===================================================
//
// `todo.md`'s trait-bounded-generics entry named this the still-missing
// "other half" of that feature: a bounded generic body could call a trait
// *method* on `T`, but never use an *operator* on it, and no concrete type
// (generic or not) could overload an operator at all. `Checker::operator_trait_method`
// maps each overloadable operator to a canonical `(trait, method)` pair
// (`+` -> `Add::add`, `==`/`!=` -> `Eq::eq`, `< > <= >=` -> `Ord::{lt,gt,le,ge}`,
// unary `-` -> `Neg::neg`); `Checker::try_operator_overload_call`/
// `try_neg_overload_call` desugar the operator into an ordinary method call
// (`a.add(b)`) at type-check time whenever the left operand's type nominally
// implements that trait, reusing the exact same, already-tested method-call
// type-checking and codegen a hand-written `.add(...)` call gets.

const OP_OVERLOAD_ADD_SRC: &str = "trait Add:\n    fn add(self, rhs: Self) -> Self\n\nstruct Point:\n    x: i32\n    y: i32\n\nimpl Add for Point:\n    fn add(self, rhs: Point) -> Point:\n        return Point(x = self.x + rhs.x, y = self.y + rhs.y)\n\n";

const OP_OVERLOAD_EQ_SRC: &str = "trait Eq:\n    fn eq(self, rhs: Self) -> bool\n\nstruct Point:\n    x: i32\n    y: i32\n\nimpl Eq for Point:\n    fn eq(self, rhs: Point) -> bool:\n        return self.x == rhs.x and self.y == rhs.y\n\n";

const OP_OVERLOAD_ORD_SRC: &str = "trait Ord:\n    fn lt(self, rhs: Self) -> bool\n    fn gt(self, rhs: Self) -> bool\n    fn le(self, rhs: Self) -> bool\n    fn ge(self, rhs: Self) -> bool\n\nstruct Point:\n    x: i32\n\nimpl Ord for Point:\n    fn lt(self, rhs: Point) -> bool:\n        return self.x < rhs.x\n    fn gt(self, rhs: Point) -> bool:\n        return self.x > rhs.x\n    fn le(self, rhs: Point) -> bool:\n        return self.x <= rhs.x\n    fn ge(self, rhs: Point) -> bool:\n        return self.x >= rhs.x\n\n";

const OP_OVERLOAD_NEG_SRC: &str = "trait Neg:\n    fn neg(self) -> Self\n\nstruct Point:\n    x: i32\n    y: i32\n\nimpl Neg for Point:\n    fn neg(self) -> Point:\n        return Point(x = 0 - self.x, y = 0 - self.y)\n\n";

/// `+` on a struct implementing `Add` type-checks, resolving to `Point`
/// (the method's own return type), not falling through to the numeric-only
/// "not supported" error `Ty::Named` otherwise hits.
#[test]
fn accepts_struct_operator_overload_add() {
    let src = format!("{}{}", OP_OVERLOAD_ADD_SRC, "fn main():\n    let a = Point(x = 1, y = 2)\n    let b = Point(x = 3, y = 4)\n    let c = a + b\n");
    let module = Driver::parse(&src).expect("should parse");
    Driver::check(&module).expect("`+` on a struct implementing `Add` should type-check");
}

/// A struct implementing `Eq` gets both `==` and `!=` from the single `eq`
/// method -- `!=` is desugared to a negation of the same call, not a
/// separately-required method.
#[test]
fn accepts_struct_operator_overload_eq_and_ne() {
    let src = format!(
        "{}{}",
        OP_OVERLOAD_EQ_SRC,
        "fn main():\n    let a = Point(x = 1, y = 2)\n    let b = Point(x = 1, y = 2)\n    if a == b:\n        println(\"eq\")\n    if a != b:\n        println(\"ne\")\n"
    );
    let module = Driver::parse(&src).expect("should parse");
    Driver::check(&module).expect("`==`/`!=` on a struct implementing `Eq` should type-check");
}

/// A struct with no `Eq` impl at all keeps using the pre-existing structural
/// `==`/`!=` fallback -- overloading is opt-in, and a struct composed
/// entirely of structurally-comparable fields must not regress.
#[test]
fn structural_equality_fallback_still_works_without_eq_trait() {
    let src = "struct Point:\n    x: i32\n    y: i32\n\nfn main():\n    let a = Point(x = 1, y = 2)\n    let b = Point(x = 1, y = 2)\n    if a == b:\n        println(\"eq\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("structural `==` must still work for a struct that never implements `Eq`");
}

/// All four `Ord` methods (`lt`/`gt`/`le`/`ge`) back their corresponding
/// operator independently.
#[test]
fn accepts_struct_operator_overload_ord_all_four_comparisons() {
    let src = format!(
        "{}{}",
        OP_OVERLOAD_ORD_SRC,
        "fn main():\n    let a = Point(x = 1)\n    let b = Point(x = 2)\n    if a < b:\n        println(\"lt\")\n    if b > a:\n        println(\"gt\")\n    if a <= a:\n        println(\"le\")\n    if a >= a:\n        println(\"ge\")\n"
    );
    let module = Driver::parse(&src).expect("should parse");
    Driver::check(&module).expect("all four `Ord` comparison operators should type-check");
}

/// A trait declaring only a subset of the four comparison methods yields
/// support for only the corresponding operator(s) -- there's no
/// `Ordering`-shaped auto-derivation of the other three from one `cmp`, so a
/// type is free to support (say) just `<` without also being on the hook for
/// `> <= >=`.
#[test]
fn partial_ord_trait_yields_only_the_declared_comparison_operators() {
    let src = "trait Ord:\n    fn lt(self, rhs: Self) -> bool\n\nstruct Point:\n    x: i32\n\nimpl Ord for Point:\n    fn lt(self, rhs: Point) -> bool:\n        return self.x < rhs.x\n\nfn main():\n    let a = Point(x = 1)\n    let b = Point(x = 2)\n    if a < b:\n        println(\"lt\")\n    if a > b:\n        println(\"gt\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("`>` should still be rejected when the `Ord` impl only ever provided `lt`")
    };
    assert!(errs.iter().any(|d| d.message.contains("only `==`/`!=` are supported")), "{:?}", errs);
}

/// Unary `-` on a struct implementing `Neg` type-checks and resolves to the
/// method's own return type.
#[test]
fn accepts_struct_neg_overload() {
    let src = format!("{}{}", OP_OVERLOAD_NEG_SRC, "fn main():\n    let a = Point(x = 1, y = 2)\n    let b = -a\n");
    let module = Driver::parse(&src).expect("should parse");
    Driver::check(&module).expect("unary `-` on a struct implementing `Neg` should type-check");
}

/// The core motivating case named in `todo.md`: a trait-bounded generic
/// function body using an *operator* (not just a trait method call) on its
/// bounded type parameter. Once `Checker::instantiate_fn_inner` substitutes
/// the concrete type argument, `a + b` reaches `try_operator_overload_call`
/// resolved exactly as a hand-written `a.add(b)` on that concrete type would
/// be -- this is what actually closes the operator-overloading half of the
/// trait-bounded-generics ceiling.
#[test]
fn accepts_operator_used_inside_trait_bounded_generic_body() {
    let src = format!(
        "{}{}",
        OP_OVERLOAD_ADD_SRC,
        "fn total<T: Add>(a: T, b: T) -> T:\n    return a + b\n\nfn main():\n    let c = total(Point(x = 1, y = 2), Point(x = 3, y = 4))\n"
    );
    let module = Driver::parse(&src).expect("should parse");
    Driver::check(&module).expect("an operator used on a trait-bounded generic type parameter should type-check");
}

/// A struct with no `Add` impl at all keeps hitting the pre-existing
/// "not supported" error for `+` -- overloading must never make an
/// unrelated, non-overloaded struct's arithmetic silently accepted.
#[test]
fn rejects_struct_add_without_impl() {
    let src = "struct Point:\n    x: i32\n\nfn main():\n    let a = Point(x = 1)\n    let b = Point(x = 2)\n    let c = a + b\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("`+` on a struct with no `Add` impl should still be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("`+` is not supported")), "{:?}", errs);
}

/// The right-hand operand's type is checked against the overloaded method's
/// real parameter type, through the same `check_call_args` an ordinary
/// method call gets -- a mismatched type (`i32` where `Point` is expected)
/// is a clean, located argument-type error, not a silent success.
#[test]
fn rejects_operator_overload_with_mismatched_rhs_type() {
    let src = format!("{}{}", OP_OVERLOAD_ADD_SRC, "fn main():\n    let a = Point(x = 1, y = 2)\n    let c = a + 5\n");
    let module = Driver::parse(&src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("`+` with a mismatched right-hand operand type should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("argument 1 expected type") && d.message.contains("Point")), "{:?}", errs);
}

/// Only the *left* operand's type ever selects an overload -- there is no
/// right-hand/`impl Add<Point> for i32`-style dispatch, so `5 + point` still
/// hits `i32`'s own (numeric-only) arithmetic legality check, not `Point`'s
/// `Add` impl.
#[test]
fn rejects_operator_overload_dispatch_from_right_hand_operand() {
    let src = format!("{}{}", OP_OVERLOAD_ADD_SRC, "fn main():\n    let a = Point(x = 1, y = 2)\n    let c = 5 + a\n");
    let module = Driver::parse(&src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("`+` dispatched from the right-hand struct operand should still be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("not supported")), "{:?}", errs);
}

/// Unary `-` on a struct with no `Neg` impl gets a clear, dedicated error --
/// and must *not* silently succeed via `Sub`'s new operator-overload branch
/// even if the same struct happens to implement `Add`/`Sub` (`try_neg_overload_call`
/// is entirely independent of the binary-`-` overload path; see
/// `Expr::Unary`'s own `UnOp::Neg` arm doc comment for why routing this case
/// through `infer_binop_ty(Sub, ...)` would be a real codegen-mismatch bug).
#[test]
fn rejects_unary_neg_on_struct_without_neg_impl() {
    let src = format!("{}{}", OP_OVERLOAD_ADD_SRC, "fn main():\n    let a = Point(x = 1, y = 2)\n    let b = -a\n");
    let module = Driver::parse(&src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("unary `-` on a struct implementing `Add` (but not `Neg`) should still be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("unary `-` is not supported") && d.message.contains("Neg")), "{:?}", errs);
}

/// An overloaded comparison operator's backing method must return `bool` --
/// a trait declaring (unusually) a non-`bool` return for `lt` is a clean,
/// dedicated error naming the trait/method/operator, not a confusing
/// downstream "if condition must be bool" cascade.
#[test]
fn rejects_ord_method_returning_non_bool() {
    let src = "trait Ord:\n    fn lt(self, rhs: Self) -> i32\n\nstruct Point:\n    x: i32\n\nimpl Ord for Point:\n    fn lt(self, rhs: Point) -> i32:\n        return self.x - rhs.x\n\nfn main():\n    let a = Point(x = 1)\n    let b = Point(x = 2)\n    if a < b:\n        println(\"lt\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("an `Ord` method returning non-`bool` should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("must return `bool`") && d.message.contains("Ord") && d.message.contains("<")), "{:?}", errs);
    assert!(!errs.iter().any(|d| d.message.contains("if condition")), "should not cascade a second diagnostic: {:?}", errs);
}

/// A trait method signature written with `Self` (`fn add(self, rhs: Self) ->
/// Self`) parses into an ordinary `Type::Named("Self")` -- `Self` is just a
/// plain identifier at the grammar level, resolved to anything meaningful
/// only later, by the checker's `trait_sig_context`-gated special case in
/// `resolve_type`.
#[test]
fn parses_trait_method_signature_with_self_type() {
    let src = "trait Add:\n    fn add(self, rhs: Self) -> Self\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Trait(t) = &module.items[0] else { panic!("expected a trait") };
    assert_eq!(t.methods[0].ret, Some(Type::Named("Self".into())));
    assert_eq!(t.methods[0].params[1].ty, Some(Type::Named("Self".into())));
}

/// `Self` in a trait's own declared signature is substituted with the
/// concrete implementing type before `check_impl_satisfies_trait` compares
/// it against the impl's provided signature -- an impl that (correctly, the
/// only way it's spellable) writes the concrete type name in place of `Self`
/// must not be rejected as a mismatch against the trait's own literal `Self`
/// token.
#[test]
fn accepts_impl_matching_trait_self_type_substitution() {
    let src = format!("{}{}", OP_OVERLOAD_ADD_SRC, "fn main():\n    println(\"ok\")\n");
    let module = Driver::parse(&src).expect("should parse");
    Driver::check(&module).expect("an impl whose concrete types faithfully substitute the trait's `Self` should type-check");
}

/// The converse: an impl whose parameter type does *not* match the trait's
/// `Self`-declared type (once substituted) is still correctly rejected --
/// `subst_self_type` must actually compare against the substituted type, not
/// accidentally always pass.
#[test]
fn rejects_impl_mismatching_trait_self_type_substitution() {
    let src = "trait Add:\n    fn add(self, rhs: Self) -> Self\n\nstruct Point:\n    x: i32\n\nstruct Other:\n    z: i32\n\nimpl Add for Point:\n    fn add(self, rhs: Other) -> Point:\n        return Point(x = self.x + rhs.z)\n\nfn main():\n    println(\"unreachable\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("an impl parameter type disagreeing with the trait's substituted `Self` should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("has type") && d.message.contains("Other") && d.message.contains("Point")), "{:?}", errs);
}

/// Codegen shape: `a + b` on a struct implementing `Add` lowers to an
/// ordinary `call` to the mangled `{Struct}__{method}` function -- the exact
/// same shape a hand-written `a.add(b)` method call gets (see
/// `Codegen::emit_call_expr`'s `TypedExpr::Field` branch), since
/// `try_operator_overload_call` desugars into that same `TypedExpr::Call`
/// shape at type-check time rather than adding any new codegen path.
#[test]
fn codegen_operator_overload_add_dispatches_to_method_call() {
    let src = format!("{}{}", OP_OVERLOAD_ADD_SRC, "fn main() -> i32:\n    let a = Point(x = 1, y = 2)\n    let b = Point(x = 3, y = 4)\n    let c = a + b\n    return c.x\n");
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("define %Point @Point__add("), "{}", ir);
    let main_body = extract_fn_body(&ir, "define i32 @main(");
    assert!(main_body.contains("call %Point @Point__add("), "{}", main_body);
}

/// Codegen shape for `!=`: desugars to a `call` to the same `eq` method
/// `==` uses, followed by a boolean negation (`xor i1 ..., true`) -- not a
/// separately-generated method or a second codegen path.
#[test]
fn codegen_operator_overload_ne_desugars_to_negated_eq_call() {
    let src = format!("{}{}", OP_OVERLOAD_EQ_SRC, "fn main():\n    let a = Point(x = 1, y = 2)\n    let b = Point(x = 3, y = 4)\n    println(f\"{a != b}\")\n");
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let main_body = extract_fn_body(&ir, "define i32 @main(");
    assert!(main_body.contains("call i1 @Point__eq("), "{}", main_body);
    assert!(main_body.contains("xor i1"), "{}", main_body);
}

/// Full runtime coverage for `+`/`Add`: the mangled `Point__add` method
/// actually runs and produces the right field values through a real
/// clang-compiled executable.
#[test]
fn runtime_operator_overload_add_end_to_end() {
    let src = format!("{}{}", OP_OVERLOAD_ADD_SRC, "fn main():\n    let a = Point(x = 1, y = 2)\n    let b = Point(x = 3, y = 4)\n    let c = a + b\n    println(f\"{c.x} {c.y}\")\n");
    let output = compile_and_run("op_overload_add", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "4 6", "{}", stdout);
}

/// Full runtime coverage for `==`/`!=`/`Eq`, including a `false` case for
/// each so the test can't pass by an accidentally-always-true lowering.
#[test]
fn runtime_operator_overload_eq_and_ne_end_to_end() {
    let src = format!(
        "{}{}",
        OP_OVERLOAD_EQ_SRC,
        "fn main():\n    let a = Point(x = 1, y = 2)\n    let b = Point(x = 1, y = 2)\n    let c = Point(x = 9, y = 9)\n    println(f\"{a == b} {a == c} {a != b} {a != c}\")\n"
    );
    let output = compile_and_run("op_overload_eq_ne", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "true false false true", "{}", stdout);
}

/// Full runtime coverage for all four `Ord`-backed comparison operators.
#[test]
fn runtime_operator_overload_ord_end_to_end() {
    let src = format!(
        "{}{}",
        OP_OVERLOAD_ORD_SRC,
        "fn main():\n    let a = Point(x = 1)\n    let b = Point(x = 2)\n    println(f\"{a < b} {a > b} {a <= a} {a >= a} {b <= a} {b >= a}\")\n"
    );
    let output = compile_and_run("op_overload_ord", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "true false true true false true", "{}", stdout);
}

/// Full runtime coverage for unary `-`/`Neg`.
#[test]
fn runtime_neg_overload_end_to_end() {
    let src = format!("{}{}", OP_OVERLOAD_NEG_SRC, "fn main():\n    let a = Point(x = 3, y = -5)\n    let b = -a\n    println(f\"{b.x} {b.y}\")\n");
    let output = compile_and_run("neg_overload", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "-3 5", "{}", stdout);
}

/// Full runtime coverage tying the feature back to its motivating case: a
/// trait-bounded generic function using `+` on its bounded type parameter,
/// instantiated against a real struct, actually runs correctly end to end.
#[test]
fn runtime_operator_used_inside_trait_bounded_generic_body_end_to_end() {
    let src = format!(
        "{}{}",
        OP_OVERLOAD_ADD_SRC,
        "fn total<T: Add>(a: T, b: T) -> T:\n    return a + b\n\nfn main():\n    let c = total(Point(x = 1, y = 2), Point(x = 3, y = 4))\n    println(f\"{c.x} {c.y}\")\n"
    );
    let output = compile_and_run("op_overload_in_trait_bound_generic", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "4 6", "{}", stdout);
}

/// Full end-to-end runtime coverage via the committed example: a `Vec2`-like
/// `Point` implementing `Add`/`Sub`/`Eq`/`Neg`, plus a trait-bounded generic
/// summing function, all through a real clang-compiled executable rather
/// than just `compile_and_run`'s temp-file round trip -- mirrors
/// `runtime_trait_bounded_generics_end_to_end`'s committed-example
/// convention.
#[test]
fn runtime_operator_overloading_example_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/operator_overloading.exe").output().expect("failed to execute operator_overloading.exe");
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("sum: 4, 6"), "{}", stdout);
    assert!(stdout.contains("diff: -2, -2"), "{}", stdout);
    assert!(stdout.contains("neg: -1, -2"), "{}", stdout);
    assert!(stdout.contains("eq: true"), "{}", stdout);
    assert!(stdout.contains("ne: true"), "{}", stdout);
    assert!(stdout.contains("lt: true"), "{}", stdout);
    assert!(stdout.contains("total: 6, 9"), "{}", stdout);
}

// ===== comparison-operator type checking =====================================

/// Comparing two `GenRef<T>` values with `==` must be rejected by the
/// checker with a real, located diagnostic -- previously `Checker::infer_binop_ty`
/// returned `bool` unconditionally for any comparison whose operand types
/// weren't a vector/matrix, so this type-checked cleanly and only failed
/// once `Codegen::emit_binop` actually saw the (unsupported) `GenRef`
/// operands, with no span at all (`Span::dummy()`).
#[test]
fn rejects_genref_equality_comparison() {
    let src = "struct Enemy:\n    hp: i32\narena Enemies: Enemy\nfn main():\n    spawn Enemies(10)\n    spawn Enemies(20)\n    let a: GenRef<Enemy> = GenRef<Enemy>(0)\n    let b: GenRef<Enemy> = GenRef<Enemy>(1)\n    if a == b:\n        println(\"same\")\n    else:\n        println(\"different\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("comparing two `GenRef<T>` values with `==` should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("not supported") && d.message.contains("GenRef")), "{:?}", errs);
}

/// `str == str` / `str != str` is structural byte equality (the docs'
/// comparison table promises `==`/`!=` generally, and the `strcmp`-backed
/// lowering `Map<str, V>` key comparison uses already existed) -- it was
/// previously rejected outright by the checker for want of a
/// `Codegen::emit_binop` lowering, which now exists (see its `Str` arm).
/// Covers equal values in *distinct* allocations (`concat` result vs. a
/// literal), so pointer identity can't fake a pass.
#[test]
fn runtime_str_equality_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let a = \"xy\"\n",
        "    let b = concat(\"x\", \"y\")\n",
        "    println(f\"{a == b} {a == \"z\"} {a != b} {a != \"z\"}\")\n",
    );
    let output = compile_and_run("str_equality", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "true false false true", "{}", stdout);
}

/// Ordering comparisons between `str` values stay rejected -- there's no
/// collation story to promise anything sensible about, so only `==`/`!=`
/// are defined (see `Checker::infer_binop_ty`'s `Str` arm).
#[test]
fn rejects_str_ordering_comparison() {
    let src = "fn main():\n    let a = \"x\"\n    let b = \"y\"\n    if a < b:\n        println(\"lt\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("comparing two `str` values with `<` should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("only `==`/`!=` are supported between `str` values")), "{:?}", errs);
}

/// Comparing two entirely unrelated types (`i32` and `str`) with `==` must
/// also be rejected, not just same-typed-but-unsupported pairs.
#[test]
fn rejects_equality_comparison_between_unrelated_types() {
    let src = "fn main():\n    if 1 == \"x\":\n        println(\"eq\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("comparing an `i32` and a `str` with `==` should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("not supported")), "{:?}", errs);
}

/// Ordinary scalar comparisons -- including a mixed `i32`/`float` pair,
/// which promotes exactly like the arithmetic operators do -- must still
/// work; guards against the checks above being so aggressive they reject
/// sound, ordinary comparisons.
#[test]
fn runtime_mixed_scalar_comparison_still_works_end_to_end() {
    let src = "fn main():\n    let a = 1\n    let b = 2.5\n    if a < b:\n        println(\"less\")\n    else:\n        println(\"not less\")\n";
    let output = compile_and_run("mixed_scalar_comparison", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "less", "{}", stdout);
}

// ===== f-string lexing =======================================================

/// An f-string interpolation hole containing a nested `str` literal that
/// itself contains a `}` byte must not confuse the hole's brace-depth
/// scanner -- previously `Lexer::scan_fstring`'s `{`/`}` counting had no
/// awareness of quotes at all, so the `}` inside the nested string literal
/// was mistaken for the hole's own closing brace.
#[test]
fn runtime_fstring_hole_containing_string_literal_with_brace_end_to_end() {
    let src = "fn main():\n    let s = f\"result: {concat(\"a}b\", \"c\")}\"\n    println(s)\n";
    let output = compile_and_run("fstring_hole_nested_brace_string", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "result: a}bc", "{}", stdout);
}

// ===== duplicate top-level declarations ======================================

/// Two top-level functions declared with the same name in one file must be
/// rejected -- previously the checker's registration pass silently let the
/// second `HashMap::insert` overwrite the first with no diagnostic at all,
/// and the collision only ever surfaced once both reached the LLVM parser as
/// clang's opaque "invalid redefinition of function".
#[test]
fn rejects_duplicate_top_level_function_declaration() {
    let src = "fn helper() -> i32:\n    return 1\nfn helper() -> i32:\n    return 2\nfn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("two top-level functions with the same name should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("declared more than once")), "{:?}", errs);
}

/// Same bug, two top-level structs -- these share the LLVM named-type
/// namespace (`%Name`), not the function-symbol one.
#[test]
fn rejects_duplicate_top_level_struct_declaration() {
    let src = "struct Point:\n    x: i32\nstruct Point:\n    y: i32\nfn main():\n    println(\"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else {
        panic!("two top-level structs with the same name should be rejected")
    };
    assert!(errs.iter().any(|d| d.message.contains("declared more than once")), "{:?}", errs);
}

/// The scenario `todo.md` specifically called out: two *different* imported
/// files, both declaring a same-named top-level item, imported under the
/// *same* alias -- `crate::modules::rename_module` mangles both files'
/// `helper` to the identical `m__helper`, which the checker's new duplicate
/// check now catches with a real diagnostic instead of it silently reaching
/// codegen as a colliding `define @m__helper` pair (a raw clang
/// "invalid redefinition" error).
#[test]
fn rejects_duplicate_top_level_name_from_two_imports_sharing_one_alias() {
    let dir = test_scratch_dir("rejects_duplicate_top_level_name_from_two_imports_sharing_one_alias");
    write_test_file(&dir, "a.star", "fn helper() -> i32:\n    return 1\n");
    write_test_file(&dir, "b.star", "fn helper() -> i32:\n    return 2\n");
    let main_path = write_test_file(
        &dir,
        "main.star",
        "import \"a.star\" as m\nimport \"b.star\" as m\nfn main():\n    println(f\"{m::helper()}\")\n",
    );
    let module = Driver::parse(&std::fs::read_to_string(&main_path).unwrap()).expect("should parse");
    let (resolved, _files) = star::modules::resolve(module, &main_path).expect("import resolution itself should succeed");
    let Err(errs) = Driver::check(&resolved) else {
        panic!("two same-named top-level items imported under the same alias should be rejected by the checker")
    };
    assert!(errs.iter().any(|d| d.message.contains("declared more than once")), "{:?}", errs);
}

/// `Parser::lower_fstring` used to `?`-short-circuit out of `sub.parse_expr()`
/// on a syntax error inside an interpolation *before* merging `sub.errors`
/// into the outer parser's error list -- so a malformed interpolated
/// expression didn't fail parsing at all, it silently dropped the whole
/// enclosing statement from the AST with zero diagnostics (`Driver::parse`
/// returned `Ok` with the `let` statement simply missing from `main`'s body).
/// Found while investigating an unrelated deep-nesting stack-overflow fix
/// that happened to route through this same early-return path.
#[test]
fn rejects_malformed_expr_inside_fstring_interpolation() {
    let src = "fn main():\n    let x = f\"{1+}\"\n";
    let result = Driver::parse(src);
    assert!(result.is_err(), "a syntax error inside `f\"{{...}}\"` must be a parse error, not a silently dropped statement");
}

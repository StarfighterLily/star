//! User-defined generics and generic struct impl methods
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== user-defined generics (monomorphization) =============================
//
// `struct Name<T>`/`enum Name<T>`/`fn name<T>` are implemented by
// monomorphization: a generic template is never itself checked or emitted,
// only concrete instantiations produced on demand by substituting each type
// parameter for a concrete type throughout a syntactic copy of the
// declaration, then checking/emitting that copy exactly like an ordinary
// hand-written concrete declaration. See `Checker::instantiate_struct`/
// `instantiate_enum`/`instantiate_fn` in `src/types/mod.rs`.

/// Parse a generic struct's `<T, U>` type-parameter list.
#[test]
fn parses_generic_struct_type_params() {
    let src = "struct Pair<A, B>:\n    first: A\n    second: B\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Struct(def) = &module.items[0] else { panic!("expected a struct") };
    assert_eq!(def.type_params, vec![TypeParam { name: "A".into(), bounds: vec![] }, TypeParam { name: "B".into(), bounds: vec![] }]);
    assert_eq!(def.fields[0].ty, Type::Named("A".into()));
}

/// Parse a generic enum's `<T>` type-parameter list.
#[test]
fn parses_generic_enum_type_params() {
    let src = "enum Option<T>:\n    None\n    Some(value: T)\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Enum(EnumDef { type_params, variants, .. }) = &module.items[0] else { panic!("expected an enum") };
    assert_eq!(type_params, &vec![TypeParam { name: "T".into(), bounds: vec![] }]);
    assert_eq!(variants[1].fields[0].ty, Type::Named("T".into()));
}

/// Parse a generic function's `<T>` type-parameter list.
#[test]
fn parses_generic_fn_type_params() {
    let src = "fn identity<T>(x: T) -> T:\n    return x\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected a fn") };
    assert_eq!(f.sig.type_params, vec![TypeParam { name: "T".into(), bounds: vec![] }]);
}

/// Parse an explicit turbofish on a generic struct literal: `Box<i32>(value = 5)`.
#[test]
fn parses_generic_struct_lit_turbofish() {
    let src = "struct Box<T>:\n    value: T\n\nfn t():\n    Box<i32>(value = 5)\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected fn") };
    let Stmt::Expr(Expr::StructLit { name, type_args, args, .. }) = &f.body.stmts[0] else {
        panic!("expected struct literal, got {:?}", f.body.stmts[0])
    };
    assert_eq!(name, "Box");
    assert_eq!(type_args, &vec![Type::Named("i32".into())]);
    assert_eq!(args.len(), 1);
}

/// Parse an explicit turbofish on a generic enum variant path:
/// `Option<i32>::None`.
#[test]
fn parses_generic_enum_variant_turbofish() {
    let src = "enum Option<T>:\n    None\n    Some(value: T)\n\nfn t():\n    Option<i32>::None\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected fn") };
    let Stmt::Expr(Expr::EnumVariant { enum_name, type_args, variant, .. }) = &f.body.stmts[0] else {
        panic!("expected enum variant, got {:?}", f.body.stmts[0])
    };
    assert_eq!(enum_name, "Option");
    assert_eq!(type_args, &vec![Type::Named("i32".into())]);
    assert_eq!(variant, "None");
}

/// The 7 non-generic builtin geometry structs `Checker::check` always
/// appends a `TypedItem::Struct` for (`docs/design.md`'s "Math and
/// geometry" section, `crate::types::builtin_structs`) -- tests that assert
/// an *exact* list/count of `TypedItem::Struct`s in a checked module need to
/// exclude these (or account for them), since they're present regardless of
/// what the test's own source declares.
const BUILTIN_GEOMETRY_STRUCT_NAMES: &[&str] = &["Rect", "Aabb2", "Aabb3", "Transform", "Ray", "Plane", "Frustum"];

const GENERIC_BOX_SRC: &str = "struct Box<T>:\n    value: T\n\n";

// `Option<T>` is now a compiler builtin (pre-registered by `Checker::check`,
// see `builtin_generic_enums`), so tests exercising generic-enum
// monomorphization/pattern-matching no longer declare their own copy -- doing
// so would collide with the builtin ("the type `Option` is declared more than
// once"). Kept as an (empty) constant purely so the `format!("{}fn t()...`
// call sites below don't need editing.
const GENERIC_OPTION_SRC: &str = "";

/// A generic struct's template declaration produces no typed item of its
/// own; only a concrete instantiation (triggered by a use with an inferable
/// concrete type) is emitted, named by mangling the template with its type
/// argument.
#[test]
fn instantiates_generic_struct_with_inferred_type_arg() {
    let src = format!("{}fn t():\n    Box(value = 5)\n", GENERIC_BOX_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    // Excludes the 7 always-present builtin geometry structs (`docs/design.md`'s
    // "Math and geometry" section) every module now carries -- unrelated to
    // this test's actual assertion (that `Box`'s own generic template is
    // never emitted, only its `Box__i32` instantiation).
    let struct_names: Vec<&str> = typed.items.iter()
        .filter_map(|i| if let TypedItem::Struct(s) = i { Some(s.name.as_str()) } else { None })
        .filter(|n| !BUILTIN_GEOMETRY_STRUCT_NAMES.contains(n))
        .collect();
    assert_eq!(struct_names, vec!["Box__i32"], "generic template itself must not be emitted, only its instantiation");
}

/// Two uses of the same generic struct with different concrete type
/// arguments produce two distinct monomorphized instantiations.
#[test]
fn instantiates_generic_struct_once_per_distinct_type_arg() {
    let src = format!("{}fn t():\n    Box(value = 5)\n    Box(value = 2.5)\n    Box(value = 6)\n", GENERIC_BOX_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    // Excludes the 7 always-present builtin geometry structs -- see the
    // matching comment in `instantiates_generic_struct_with_inferred_type_arg`.
    let mut struct_names: Vec<&str> = typed.items.iter()
        .filter_map(|i| if let TypedItem::Struct(s) = i { Some(s.name.as_str()) } else { None })
        .filter(|n| !BUILTIN_GEOMETRY_STRUCT_NAMES.contains(n))
        .collect();
    struct_names.sort();
    assert_eq!(struct_names, vec!["Box__f32", "Box__i32"], "same (template, type arg) pair should be instantiated once: {:?}", struct_names);
}

/// A generic struct construction whose type argument can't be inferred from
/// its constructor arguments alone is resolved via an explicit turbofish.
#[test]
fn instantiates_generic_struct_via_explicit_turbofish() {
    let src = format!("{}fn t():\n    Box<i32>(value = 5)\n", GENERIC_BOX_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    assert!(typed.items.iter().any(|i| matches!(i, TypedItem::Struct(s) if s.name == "Box__i32")));
}

/// A field access on a monomorphized generic struct resolves against its
/// instantiation's own (substituted, concrete) field type.
#[test]
fn checks_generic_struct_field_access_has_substituted_type() {
    let src = format!("{}fn t() -> i32:\n    let b = Box(value = 5)\n    b.value\n", GENERIC_BOX_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let f = typed.items.iter().find_map(|i| if let TypedItem::Fn(f) = i { Some(f) } else { None }).expect("expected a fn item");
    let ty = match f.body.stmts.last().expect("body should have a statement") {
        TypedStmt::Expr(e) => e.clone().into_ty(),
        other => panic!("expected trailing expr statement, got {:?}", other),
    };
    assert_eq!(ty, Ty::Int);
}

/// A generic struct instantiated with another (already-monomorphized)
/// generic struct as its own type argument works -- nested instantiation.
#[test]
fn instantiates_nested_generic_struct() {
    let src = format!(
        "{}fn t() -> i32:\n    let b = Box(value = Box(value = 99))\n    b.value.value\n",
        GENERIC_BOX_SRC
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "nested generic instantiation should type-check");
}

/// A generic enum's fieldless variant with no arguments to infer a type
/// argument from requires an explicit turbofish; without one it's a type
/// error rather than a silent wrong instantiation.
#[test]
fn rejects_generic_enum_variant_without_inferable_type_arg() {
    let src = format!("{}fn t():\n    Option::None\n", GENERIC_OPTION_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("uninferable generic construction should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("cannot infer")), "{:?}", diags);
}

/// `Option<i32>::None` and `Option::Some(5)` (inferred `T = i32`) share the
/// same monomorphized `Option__i32` enum.
#[test]
fn instantiates_generic_enum_shared_across_variants() {
    let src = format!(
        "{}fn t():\n    let a = Option::Some(5)\n    let b = Option<i32>::None\n",
        GENERIC_OPTION_SRC
    );
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let enum_names: Vec<&str> = typed.items.iter().filter_map(|i| if let TypedItem::Enum(e) = i { Some(e.name.as_str()) } else { None }).collect();
    assert_eq!(enum_names, vec!["Option__i32"], "both constructions should share one instantiation: {:?}", enum_names);
}

/// A `match` pattern written against the generic template name
/// (`Option::Some(v)`) matches a scrutinee of any concrete instantiation --
/// the pattern doesn't need to spell out the mangled name.
#[test]
fn checks_match_pattern_against_generic_template_name() {
    let src = format!(
        "{}fn t(o: Option<i32>) -> i32:\n    match o:\n        Option::Some(v) ->\n            return v\n        Option::None ->\n            return -1\n",
        GENERIC_OPTION_SRC
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "a generic-template pattern should match a concrete instantiation: {:?}", Driver::check(&module).err());
}

/// A generic free function's type parameter is inferred from its call-site
/// argument types (no turbofish call syntax); two calls with different
/// concrete argument types produce two distinct monomorphized functions.
#[test]
fn instantiates_generic_fn_once_per_distinct_call_site_type() {
    let src = "fn identity<T>(x: T) -> T:\n    return x\n\nfn t():\n    identity(5)\n    identity(2.5)\n    identity(6)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let mut fn_names: Vec<&str> = typed.items.iter()
        .filter_map(|i| if let TypedItem::Fn(f) = i { Some(f.sig.name.as_str()) } else { None })
        .filter(|n| n.starts_with("identity"))
        .collect();
    fn_names.sort();
    assert_eq!(fn_names, vec!["identity__f32", "identity__i32"], "{:?}", fn_names);
}

/// Codegen for a generic function call: the call site lowers to a direct
/// call against the mangled, monomorphized function's own name.
#[test]
fn codegen_generic_fn_call_uses_mangled_name() {
    let src = "fn identity<T>(x: T) -> T:\n    return x\n\nfn t() -> i32:\n    identity(5)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("define i32 @identity__i32("), "{}", ir);
    assert!(ir.contains("call i32 @identity__i32("), "{}", ir);
}

/// A generic function whose body itself constructs another generic type
/// parameterized by its own type parameter (`fn wrap<T>(x: T) -> Box<T>`)
/// type-checks and codegens -- the body's own `Box(value = x)` is checked
/// against the already-substituted (concrete) parameter type of `x`.
#[test]
fn instantiates_generic_fn_that_constructs_generic_struct_of_its_own_param() {
    let src = format!("{}fn wrap<T>(x: T) -> Box<T>:\n    return Box(value = x)\n\nfn t() -> i32:\n    let b = wrap(5)\n    b.value\n", GENERIC_BOX_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    assert!(typed.items.iter().any(|i| matches!(i, TypedItem::Struct(s) if s.name == "Box__i32")));
    assert!(typed.items.iter().any(|i| matches!(i, TypedItem::Fn(f) if f.sig.name == "wrap__i32")));
}

/// Codegen for a monomorphized generic struct: the `%Box__i32 = type { i32
/// }` declaration and its field access lower exactly like an ordinary
/// hand-written concrete struct.
#[test]
fn codegen_generic_struct_emits_mangled_type_decl() {
    let src = format!("{}fn t() -> i32:\n    let b = Box(value = 5)\n    b.value\n", GENERIC_BOX_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("%Box__i32 = type { i32 }"), "{}", ir);
    assert!(ir.contains("alloca %Box__i32"), "{}", ir);
}

/// Codegen for a monomorphized generic payload enum: lowers to a tagged
/// union exactly like an ordinary hand-written concrete payload enum.
#[test]
fn codegen_generic_enum_emits_mangled_tagged_union() {
    let src = format!("{}fn t():\n    Option::Some(5)\n", GENERIC_OPTION_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("%Option__i32 = type { i32, [1 x i64] }"), "{}", ir);
}

/// Runtime test: `examples/generics.exe` exercises user-defined generics end
/// to end -- a generic struct (`Box<T>`, including a nested `Box<Box<i32>>`
/// instantiation), a generic `Option<T>`-style enum matched by its generic
/// template pattern name, a generic `Result<T, E>`-style enum needing an
/// explicit turbofish on both variants, and a generic free function
/// (`identity<T>`) instantiated at two different concrete types -- through a
/// real clang-compiled executable.
#[test]
fn runtime_generics_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/generics.exe").output().expect("failed to execute generics.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("box: 42"), "generic struct field read: {}", stdout);
    assert!(stdout.contains("nested box: 99"), "nested generic struct instantiation: {}", stdout);
    assert!(stdout.contains("unwrap some: 5"), "generic enum Some payload via generic-template match pattern: {}", stdout);
    assert!(stdout.contains("unwrap none: -1"), "generic enum None fallback via generic-template match pattern: {}", stdout);
    assert!(stdout.contains("ok: 10"), "generic two-param enum Ok payload: {}", stdout);
    assert!(stdout.contains("err: bad"), "generic two-param enum Err payload: {}", stdout);
    assert!(stdout.contains("identity int: 7"), "generic fn instantiated at i32: {}", stdout);
    assert!(stdout.contains("identity float: 3.500000"), "generic fn instantiated at f32 (separate instantiation from i32): {}", stdout);
}

// ===== generic struct impl methods (`projects/snake/NOTES.md` 2.3) =========
//
// `impl Box<T>:` used to be a hard parse error (`Parser::parse_impl` called a
// plain `expect_ident()` for the type name, with no `<...>` parsing at all),
// so a generic struct could only ever be field-accessed, never given
// methods. Fixed by: (1) `parse_impl` parsing an optional `<T, U, ...>` after
// the type name into `ImplBlock::type_params`, (2) the checker stashing such
// an `impl` block into `generic_impls` (keyed by the struct's template name)
// instead of checking it eagerly, exactly like a generic struct/enum/fn
// template, and (3) `Checker::instantiate_impl_methods`, called from
// `instantiate_struct_inner` right after a concrete instantiation (`Box__i32`)
// is registered, substituting that same instantiation's type arguments
// through every stashed impl block's methods and checking/emitting them
// alongside the struct itself -- see that function's doc comment for the
// full mechanism.

const GENERIC_IMPL_BOX_SRC: &str = "struct Box<T>:\n    mut value: T\n\nimpl Box<T>:\n    fn get(self) -> T:\n        return self.value\n\n    fn set(mut self, v: T):\n        self.value = v\n\n";

/// `impl Box<T>:` parses its own `<T>` into `ImplBlock::type_params`,
/// distinct from (but naming the same parameter as) `struct Box<T>:`'s own.
#[test]
fn parses_impl_type_params_on_generic_struct() {
    let src = "struct Box<T>:\n    value: T\n\nimpl Box<T>:\n    fn get(self) -> T:\n        return self.value\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Impl(blk) = &module.items[1] else { panic!("expected an impl block, got {:?}", module.items[1]) };
    assert_eq!(blk.type_name, "Box");
    assert_eq!(blk.type_params, vec![TypeParam { name: "T".into(), bounds: vec![] }]);
}

/// A trait impl on a generic struct also parses `<...>` after the type name,
/// not the trait name (`impl Trait for Box<T>:`, never `impl Trait<T> for
/// Box:`) -- traits have no type parameters of their own in this language.
#[test]
fn parses_impl_type_params_on_generic_struct_trait_impl() {
    let src = "trait Describable:\n    fn describe(self) -> str\n\nstruct Box<T>:\n    value: T\n\nimpl Describable for Box<T>:\n    fn describe(self) -> str:\n        return \"box\"\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Impl(blk) = &module.items[2] else { panic!("expected an impl block, got {:?}", module.items[2]) };
    assert_eq!(blk.trait_name.as_deref(), Some("Describable"));
    assert_eq!(blk.type_name, "Box");
    assert_eq!(blk.type_params, vec![TypeParam { name: "T".into(), bounds: vec![] }]);
}

/// `impl Box:` (no `<...>`) against a struct that *is* generic
/// (`struct Box<T>: ...`) is rejected with a diagnostic naming the fix,
/// rather than silently registering methods no call site could ever reach
/// (every real value has the *mangled* type `Box__i32`, never the bare
/// template name `Box`).
#[test]
fn rejects_impl_missing_type_params_for_generic_struct() {
    let src = "struct Box<T>:\n    value: T\n\nimpl Box:\n    fn get(self) -> i32:\n        return 0\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("impl on a generic struct missing <...> should be a type error") };
    assert!(
        diags.iter().any(|d| d.message.contains("missing type parameters") && d.message.contains("impl Box<T>")),
        "{:?}",
        diags
    );
    // Exactly one diagnostic for this -- `check_item` must not additionally
    // fall through to the ordinary (non-generic) impl path's own "undefined
    // type `Box`" check for the same root cause.
    assert_eq!(diags.len(), 1, "expected exactly one diagnostic: {:?}", diags);
}

/// `impl Plain<T>:` naming type parameters against a struct that is *not*
/// generic is rejected -- the type parameters have nothing to bind to.
#[test]
fn rejects_impl_type_params_on_non_generic_struct() {
    let src = "struct Plain:\n    value: i32\n\nimpl Plain<T>:\n    fn get(self) -> i32:\n        return self.value\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("impl <...> on a non-generic struct should be a type error") };
    assert!(
        diags.iter().any(|d| d.message.contains("is not a generic struct")),
        "{:?}",
        diags
    );
}

/// `impl Box<T, U>:` against `struct Box<T>: ...` (a type-parameter count
/// mismatch) is rejected rather than silently substituting only the first
/// argument and dropping the rest.
#[test]
fn rejects_impl_type_param_arity_mismatch_for_generic_struct() {
    let src = "struct Box<T>:\n    value: T\n\nimpl Box<T, U>:\n    fn get(self) -> T:\n        return self.value\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("impl type-parameter arity mismatch should be a type error") };
    assert!(
        diags.iter().any(|d| d.message.contains("declares 2 type parameter(s)") && d.message.contains("declares 1")),
        "{:?}",
        diags
    );
}

/// `impl NoSuchType<T>:` against a type that isn't declared at all (generic
/// or not) is rejected as an undefined type, same as the existing
/// non-generic `rejects_undefined_impl_type_with_suggestion` case.
#[test]
fn rejects_impl_type_params_on_undefined_type() {
    let src = "impl NoSuchType<T>:\n    fn get(self) -> i32:\n        return 0\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("impl on an undefined generic type should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("undefined type `NoSuchType`")), "{:?}", diags);
}

/// A generic struct's template `impl` block itself never reaches codegen as
/// a `TypedItem::Impl` -- only concrete, per-instantiation copies (mirroring
/// how the struct template itself is never emitted, only its
/// instantiations -- see `instantiates_generic_struct_with_inferred_type_arg`).
#[test]
fn generic_impl_template_itself_is_never_emitted() {
    let src = format!("{}fn t():\n    let b = Box(value = 5)\n    b.get()\n", GENERIC_IMPL_BOX_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let impl_type_names: Vec<&str> =
        typed.items.iter().filter_map(|i| if let TypedItem::Impl(blk) = i { Some(blk.type_name.as_str()) } else { None }).collect();
    assert_eq!(impl_type_names, vec!["Box__i32"], "only the mangled instantiation's impl block should be emitted: {:?}", impl_type_names);
}

/// Two uses of a generic struct's methods at different concrete type
/// arguments produce two distinct monomorphized `impl` blocks -- one per
/// mangled instantiation, mirroring `instantiates_generic_struct_once_per_distinct_type_arg`.
#[test]
fn instantiates_generic_impl_methods_once_per_distinct_type_arg() {
    let src = format!(
        "{}fn t():\n    let a = Box(value = 5)\n    let b = Box(value = 2.5)\n    a.get()\n    b.get()\n",
        GENERIC_IMPL_BOX_SRC
    );
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let mut impl_type_names: Vec<&str> =
        typed.items.iter().filter_map(|i| if let TypedItem::Impl(blk) = i { Some(blk.type_name.as_str()) } else { None }).collect();
    impl_type_names.sort();
    assert_eq!(impl_type_names, vec!["Box__f32", "Box__i32"], "{:?}", impl_type_names);
}

/// Calling a generic struct's method twice on two separately-constructed
/// values of the *same* concrete instantiation must not register (or emit)
/// a second copy -- otherwise codegen would produce two colliding
/// `define @Box__i32__get(...)` globals, rejected by clang.
#[test]
fn instantiating_generic_impl_methods_twice_at_same_type_arg_does_not_duplicate() {
    let src =
        format!("{}fn t():\n    let a = Box(value = 5)\n    let b = Box(value = 6)\n    a.get()\n    b.get()\n", GENERIC_IMPL_BOX_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let impl_blocks: Vec<&str> =
        typed.items.iter().filter_map(|i| if let TypedItem::Impl(blk) = i { Some(blk.type_name.as_str()) } else { None }).collect();
    assert_eq!(impl_blocks, vec!["Box__i32"], "one instantiation, used twice, should still emit exactly one impl block: {:?}", impl_blocks);
}

/// A generic struct method call's return type resolves to the substituted
/// concrete type (`T -> i32`), not the unsubstituted type-parameter name.
#[test]
fn checks_generic_impl_method_call_return_type_is_substituted() {
    let src = format!("{}fn t() -> i32:\n    let b = Box(value = 5)\n    b.get()\n", GENERIC_IMPL_BOX_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let f = typed.items.iter().find_map(|i| if let TypedItem::Fn(f) = i { Some(f) } else { None }).expect("expected a fn item");
    let ty = match f.body.stmts.last().expect("body should have a statement") {
        TypedStmt::Expr(e) => e.clone().into_ty(),
        other => panic!("expected trailing expr statement, got {:?}", other),
    };
    assert_eq!(ty, Ty::Int);
}

/// Two methods declared in the same generic `impl Box<T>:` block can call
/// each other regardless of order -- their signatures are all registered
/// before either body is checked, mirroring the non-generic-impl pass-1
/// registration this mirrors.
#[test]
fn runtime_generic_impl_method_calls_sibling_method_end_to_end() {
    let src = "struct Box<T>:\n    value: T\n\nimpl Box<T>:\n    fn get_twice(self) -> T:\n        return self.get()\n\n    fn get(self) -> T:\n        return self.value\n\nfn main():\n    let b = Box(value = 9)\n    println(f\"{b.get_twice()}\")\n";
    let output = compile_and_run("generic_impl_sibling_method_call", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "9", "{}", stdout);
}

/// A generic struct's LLVM method symbol is mangled by its *concrete*
/// instantiation (`Box__i32__get`), not the bare template name (`Box__get`)
/// -- mirrors `codegen_impl_method_llvm_name_is_mangled_by_struct` for the
/// non-generic case, since two different instantiations of the same generic
/// struct (`Box__i32`, `Box__f32`) would otherwise collide on one shared
/// `define @Box__get(...)` global despite having genuinely different
/// parameter/return types.
#[test]
fn codegen_generic_impl_method_llvm_name_is_mangled_by_instantiation() {
    let src = format!("{}fn t() -> i32:\n    let b = Box(value = 5)\n    b.get()\n", GENERIC_IMPL_BOX_SRC);
    let module = Driver::parse(&src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("define i32 @Box__i32__get(%Box__i32* %self)"), "{}", ir);
    assert!(!ir.contains("define i32 @Box__get("), "the unmangled template name must never be emitted as a global: {}", ir);
    assert!(!ir.contains("define i32 @get("), "the bare method name must never be emitted as a global: {}", ir);
}

/// Regression for a genuine codegen bug found while validating the fix
/// above: `self` used as a plain *value* (not immediately field-accessed --
/// `return self`, `let x = self`, ...) previously reused
/// `Codegen::emit_place`'s pointer-returning logic verbatim instead of
/// loading the struct value it points to, one load short of a real value.
/// This type-checked cleanly (both are "some SSA register" to the checker)
/// but produced a genuine LLVM type mismatch at whatever consumed it --
/// confirmed via a real `star build`: a `mut self` method declared to
/// return its own struct type and ending in a bare `return self` failed at
/// the `clang` step with `"'%tN' defined with type 'ptr' but expected
/// '%Struct = type { ... }'"`. Reproduces on a plain non-generic struct (see
/// `runtime_self_returned_by_value_from_mut_method_end_to_end` for the
/// generic case, which exercises the exact same codegen path).
#[test]
fn codegen_self_returned_by_value_loads_struct_not_pointer() {
    let src = "struct Box:\n    mut value: i32\n\nimpl Box:\n    fn set(mut self, v: i32) -> Box:\n        self.value = v\n        return self\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let body = extract_fn_body(&ir, "define %Box @Box__set(");
    assert!(body.contains("ret %Box %"), "must return the struct by value: {}", body);
    assert!(!body.contains("ret %Box* %"), "must not return a bare pointer where a value is declared: {}", body);
}

/// Runtime test: `examples/generic_impl_methods.exe` exercises `impl Box<T>:`
/// end to end -- an inherent impl on a generic struct (`get`/`set`/mutation
/// through `mut self`), `self` returned by value from a `mut self` method
/// (`replaced`, see `codegen_self_returned_by_value_loads_struct_not_pointer`),
/// one method calling a sibling method in the same impl block (`get_twice`),
/// a two-type-parameter generic struct's impl (`Pair<A, B>`), a trait impl on
/// a generic struct (`impl Describable for Pair<A, B>:`), and the exact
/// motivating use case from `projects/snake/NOTES.md` 2.3 -- a generic
/// `Stack<T>` wrapper with mutating methods backed by a `List<T>` field, used
/// as an undo-history stack -- through a real clang-compiled executable.
#[test]
fn runtime_generic_impl_methods_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/generic_impl_methods.exe").output().expect("failed to execute generic_impl_methods.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("box get: 5"), "generic method call: {}", stdout);
    assert!(stdout.contains("box after set: 10"), "generic method call through mut self: {}", stdout);
    assert!(stdout.contains("box get_twice: 10"), "one generic-impl method calling a sibling method: {}", stdout);
    assert!(stdout.contains("box replaced: 20"), "self returned by value from a mut self method: {}", stdout);
    assert!(stdout.contains("box str: hi"), "same generic struct instantiated at a second, unrelated type arg: {}", stdout);
    assert!(stdout.contains("pair: 1 two"), "two-type-parameter generic struct impl: {}", stdout);
    assert!(stdout.contains("describe: a pair"), "trait impl on a generic struct: {}", stdout);
    assert!(stdout.contains("history len: 3"), "generic Stack<T> wrapping List<T> -- the motivating NOTES.md 2.3 use case: {}", stdout);
    assert!(stdout.contains("undo: 3"), "{}", stdout);
    assert!(stdout.contains("undo: 2"), "{}", stdout);
    assert!(stdout.contains("history len: 1"), "{}", stdout);
}

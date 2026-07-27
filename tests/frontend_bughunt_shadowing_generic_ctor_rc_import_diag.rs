//! Bug-hunting round: builtin-name shadowing, generic ctor field validation, collection-return RC leak, transitive-import diagnostic
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Bug-hunting round: builtin-name shadowing / generic ctor field ======
// ===== validation / collection-return-value RC leak / transitive-import ===
// ===== diagnostic ===========================================================

/// `struct Tick: ...` (or any other name colliding with a builtin scalar
/// type -- `Vec2`/`Vec3`/`Vec4`/`Mat4`/`i32`/.../`Instant`) previously
/// type-checked with **no error at all**: `Checker::resolve_type`'s
/// hardcoded builtin-name match arm (`"Tick" => Some(Ty::Tick)`, ...) fired
/// before ever consulting `self.structs`, so the user's struct was silently
/// registered into `self.structs` but permanently unreachable -- every
/// reference to `Tick` kept resolving to the builtin scalar regardless.
/// `Tick(5)` then passed `check_builtin_ctor_arity` (a bare `i32` literal
/// satisfies "expects 1 integer argument") instead of validating against
/// the user's actual field list, and the subsequent `.x` field access on
/// the resulting bare-`i64`-typed value crashed codegen with an unlocated
/// "field access on non-struct type" instead of any diagnostic pointing at
/// the real problem. Fixed by letting a declared struct take priority over
/// a same-named builtin scalar in `resolve_type`, mirroring the priority
/// `self.enums` already had over the same builtin-name match.
#[test]
fn struct_named_after_a_builtin_scalar_type_shadows_it_end_to_end() {
    let src = "struct Tick:\n    x: i32\n\nfn main():\n    let t = Tick(5)\n    println(f\"{t.x}\")\n";
    let output = compile_and_run("struct_named_tick_shadows_builtin", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "5");
}

/// Same fix, for `Vec2` (a builtin with its own constructor-arity check,
/// unlike `Tick`) -- confirms the priority fix isn't specific to the time
/// types.
#[test]
fn struct_named_after_vec2_shadows_it_end_to_end() {
    let src = "struct Vec2:\n    x: i32\n\nfn main():\n    let t = Vec2(5)\n    println(f\"{t.x}\")\n";
    let output = compile_and_run("struct_named_vec2_shadows_builtin", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "5");
}

/// `infer_generic_struct_lit` previously only ran `resolve_generic_ctor_args`'s
/// `unify_ty` (which exists purely to solve type-*parameter* bindings and
/// silently no-ops on a field whose declared type is already concrete, e.g.
/// `tag: i8` here) -- never validating a constructor argument against such
/// a field the way `check_struct_ctor_args` already does for an ordinary,
/// non-generic struct. `Checker::check_field_ctor_types` closes that gap.
/// Without it, an untyped `i32` literal argument against a narrower
/// concrete field type-checked cleanly and kept its default `Ty::Int` all
/// the way to codegen, where the generic `StructLit` store path picks its
/// LLVM store width from the *argument's* inferred type rather than the
/// field's declared type -- a real, silent 4-byte store into a struct with
/// only 1 byte of room past that field, corrupting whatever sits directly
/// after it in memory.
#[test]
fn rejects_generic_struct_ctor_arg_with_wrong_width_for_a_concrete_field() {
    let src = "struct Box<T>:\n    value: T\n    tag: i8\n\nfn main():\n    let b = Box<u8>(value=250 as u8, tag=3)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("a plain `i32` literal against a declared `i8` field should be a type error");
    assert!(
        diags.iter().any(|d| d.message.contains("`Box`'s field `tag`") && d.message.contains("expects type `I8`")),
        "{:?}", diags
    );
}

/// Runtime confirmation of the fix above: once every argument is correctly
/// cast to its field's declared width, the narrow sibling field keeps its
/// own value instead of being clobbered by a wider store landing on top of
/// it.
#[test]
fn runtime_generic_struct_ctor_concrete_field_keeps_correct_width_end_to_end() {
    let src = "struct Box<T>:\n    value: T\n    tag: i8\n\nfn main():\n    \
               let b = Box<u8>(value=250 as u8, tag=3 as i8)\n    println(f\"{b.value} {b.tag as i32}\")\n";
    let output = compile_and_run("generic_struct_ctor_field_width", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "250 3");
}

/// Same missing-validation hazard as the generic-struct case above, for a
/// generic enum variant's payload fields instead.
#[test]
fn rejects_generic_enum_variant_ctor_arg_with_wrong_width_for_a_concrete_field() {
    let src = "enum Res<T>:\n    Ok(value: T, a: i8)\n    Err()\n\nfn main():\n    let r = Res<u8>::Ok(200 as u8, 1)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("a plain `i32` literal against a declared `i8` field should be a type error");
    assert!(
        diags.iter().any(|d| d.message.contains("`Res::Ok(..)`'s field `a`") && d.message.contains("expects type `I8`")),
        "{:?}", diags
    );
}

/// Runtime confirmation: with 7 correctly-cast `i8` payload fields following
/// the generic `value: T` field, none of them get clobbered by a wrong-width
/// store landing on top of a neighbor -- this is the same corruption shape
/// as the struct case, just inside a payload-enum's tagged-union storage
/// instead of a plain struct's fields.
#[test]
fn runtime_generic_enum_variant_ctor_concrete_fields_keep_correct_width_end_to_end() {
    let src = concat!(
        "enum Res<T>:\n",
        "    Ok(value: T, a: i8, b: i8, c: i8, d: i8, e: i8, f: i8, g: i8)\n",
        "    Err()\n",
        "\n",
        "fn main():\n",
        "    let r = Res<u8>::Ok(200 as u8, 1 as i8, 2 as i8, 3 as i8, 4 as i8, 5 as i8, 6 as i8, 7 as i8)\n",
        "    match r:\n",
        "        Res::Ok(value, a, b, c, d, e, f, g) -> println(f\"{value} {a as i32} {b as i32} {c as i32} {d as i32} {e as i32} {f as i32} {g as i32}\")\n",
        "        Res::Err() -> println(\"err\")\n",
    );
    let output = compile_and_run("generic_enum_variant_ctor_field_width", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "200 1 2 3 4 5 6 7");
}

/// A qualified path through an import alias with a *second* `::` segment
/// (`b::c::make_vec2`, reaching through `b`'s own re-exported import of `c`)
/// now parses by chaining `mangle_name` once per segment
/// (`mangle_name(mangle_name("b","c"), "make_vec2") == "b__c__make_vec2"`),
/// exactly the name `crate::modules::resolve` gives that function once `a`
/// imports `b` (`c`'s items are already genuine top-level items of `b`'s own
/// flattened module by the time `b` itself gets `b__`-prefixed -- see
/// `crate::modules`'s module-level doc comment). This is a pure parser-level
/// check (no on-disk files, no real `b.star`/`c.star`), confirming the
/// mangled name shape independent of whether the referenced symbol actually
/// exists -- `runtime_transitive_reexport_two_hops_end_to_end` below covers
/// the full pipeline with real files.
#[test]
fn parses_transitive_module_path_through_an_alias_as_chained_mangled_name() {
    let src = "import \"other.star\" as b\nfn main():\n    let v = b::c::make_vec2(3, 4)\n";
    let module = Driver::parse(src).expect("a transitive qualified path should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected let") };
    assert!(
        matches!(value, Expr::Call { callee, .. } if matches!(&**callee, Expr::Ident(n, _) if n == "b__c__make_vec2")),
        "{:?}", value
    );
}

/// Same shape, exercised through the mirrored qualified-*pattern* parser
/// path (`match v: b::c::Foo(x) -> ...`) rather than the qualified-expression
/// path above -- `b::c::Foo(x)` chains to `Pattern::Struct("b__c__Foo", ..)`.
#[test]
fn parses_transitive_module_path_in_a_match_pattern_as_chained_mangled_name() {
    let src = "import \"other.star\" as b\nfn main():\n    match 1:\n        b::c::Foo(x) -> println(f\"{x}\")\n        _ -> println(\"no\")\n";
    let module = Driver::parse(src).expect("a transitive qualified pattern should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected fn") };
    let Stmt::Expr(Expr::Match { arms, .. }) = &f.body.stmts[0] else { panic!("expected match stmt") };
    assert!(
        matches!(&arms[0].pattern, Pattern::Struct(name, bindings) if name == "b__c__Foo" && bindings == &vec!["x".to_string()]),
        "{:?}", arms[0].pattern
    );
}

/// End-to-end confirmation with real files on disk (mirroring
/// `diagnostic_inside_imported_file_renders_against_that_files_own_source`'s
/// pattern): `a` imports `b`, `b` imports `c`, and `a` reaches `c`'s struct
/// and free function *through* `b` with a two-hop qualified path
/// (`b::c::make_vec2`, `b::c::Vec2`). Guards the full pipeline (parse,
/// resolve/inline, type-check, codegen, real `clang`-compiled run), not just
/// the parser in isolation.
#[test]
fn runtime_transitive_reexport_two_hops_end_to_end() {
    let dir = test_scratch_dir("runtime_transitive_reexport_two_hops_end_to_end");
    write_test_file(
        &dir, "c.star",
        "struct Vec2:\n    x: i32\n    y: i32\n\nfn make_vec2(x: i32, y: i32) -> Vec2:\n    Vec2(x, y)\n",
    );
    write_test_file(
        &dir, "b.star",
        "import \"c.star\" as c\n\nfn b_make(x: i32, y: i32) -> c::Vec2:\n    c::make_vec2(x, y)\n",
    );
    let main_path = write_test_file(
        &dir, "a.star",
        "import \"b.star\" as b\n\nfn main():\n    let v: b::c::Vec2 = b::c::make_vec2(3, 4)\n    println(f\"sum = {v.x + v.y}\")\n",
    );

    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(compilation.is_ok(), "{}", compilation.render_diagnostics());
    let typed = compilation.typed.as_ref().unwrap();
    let ir = Driver::codegen(typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_transitive_reexport_two_hops.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");
    let output = std::process::Command::new(&exe).output().expect("failed to execute compiled test binary");
    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "sum = 7");

    let _ = std::fs::remove_dir_all(&dir);
}

/// The same two-hop shape, but reaching a *payload enum variant* declared in
/// the innermost file (`c::Shape::Circle(r)`) through `b`, matched inside
/// `a` -- guards that `EnumVariant`'s own chained-mangling branch (the
/// `starts_uppercase` terminal case in the qualified-path loop) is correct,
/// not just the plain-function/struct chaining case above.
#[test]
fn runtime_transitive_reexport_enum_variant_two_hops_end_to_end() {
    let dir = test_scratch_dir("runtime_transitive_reexport_enum_variant_two_hops_end_to_end");
    write_test_file(
        &dir, "c.star",
        "enum Shape:\n    Circle(r: i32)\n    Square(side: i32)\n",
    );
    write_test_file(
        &dir, "b.star",
        "import \"c.star\" as c\n\nfn make_circle(r: i32) -> c::Shape:\n    c::Shape::Circle(r)\n",
    );
    let main_path = write_test_file(
        &dir, "a.star",
        concat!(
            "import \"b.star\" as b\n\n",
            "fn main():\n",
            "    let s = b::make_circle(5)\n",
            "    match s:\n",
            "        b::c::Shape::Circle(r) -> println(f\"circle {r}\")\n",
            "        b::c::Shape::Square(side) -> println(f\"square {side}\")\n",
        ),
    );

    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(compilation.is_ok(), "{}", compilation.render_diagnostics());
    let typed = compilation.typed.as_ref().unwrap();
    let ir = Driver::codegen(typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_transitive_reexport_enum_two_hops.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");
    let output = std::process::Command::new(&exe).output().expect("failed to execute compiled test binary");
    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "circle 5");

    let _ = std::fs::remove_dir_all(&dir);
}

/// Three hops deep (`a` imports `b` imports `c` imports `d`), reaching `d`'s
/// function through the full `b::c::d::make` chain -- guards that the
/// qualified-path loop really generalizes past the two-hop case above rather
/// than special-casing exactly one extra `::` segment.
#[test]
fn runtime_transitive_reexport_three_hops_end_to_end() {
    let dir = test_scratch_dir("runtime_transitive_reexport_three_hops_end_to_end");
    write_test_file(&dir, "d.star", "fn make() -> i32:\n    return 99\n");
    write_test_file(&dir, "c.star", "import \"d.star\" as d\nfn via_c() -> i32:\n    return d::make()\n");
    write_test_file(&dir, "b.star", "import \"c.star\" as c\nfn via_b() -> i32:\n    return c::via_c()\n");
    let main_path = write_test_file(
        &dir, "a.star",
        "import \"b.star\" as b\n\nfn main():\n    println(f\"{b::c::d::make()}\")\n",
    );

    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(compilation.is_ok(), "{}", compilation.render_diagnostics());
    let typed = compilation.typed.as_ref().unwrap();
    let ir = Driver::codegen(typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_transitive_reexport_three_hops.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");
    let output = std::process::Command::new(&exe).output().expect("failed to execute compiled test binary");
    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "99");

    let _ = std::fs::remove_dir_all(&dir);
}

//! Top-level `const`, plus `dedupe_by_origin` duplicate-declaration regression
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== `const NAME: Type = <expr>` -- a top-level, compile-time-evaluated
// ===== constant, closing `projects/snake/NOTES.md` section 2.5: previously
// ===== only `struct`/`trait`/`impl`/`fn`/`arena`/`sequence`/`enum`/`import`
// ===== were legal top-level items, and a bare top-level `let` was a parse
// ===== error, so `grid.star`'s `cols()`/`rows()`/`cell_size()` were
// ===== zero-argument functions purely because there was no other way to
// ===== share a named constant across a module. `Checker::resolve_const`
// ===== folds a `const`'s initializer down to a literal at check time and
// ===== substitutes it directly at every reference site, so codegen never
// ===== emits a runtime global for one at all. See
// ===== `examples/top_level_const.star`. =====================================

/// `const NAME: Type = <expr>` parses into `Item::Const` with the expected
/// name/type/span; a plain integer-literal initializer round-trips intact.
#[test]
fn parses_top_level_const_item() {
    let src = "const COLS: i32 = 32\n";
    let module = Driver::parse(src).expect("should parse");
    assert_eq!(module.items.len(), 1);
    let Item::Const(c) = &module.items[0] else { panic!("expected Item::Const, found {:?}", module.items[0]) };
    assert_eq!(c.name, "COLS");
    assert_eq!(c.ty, Type::Named("i32".to_string()));
    assert!(matches!(c.value, Expr::Int(32, _)));
}

/// The parser accepts any expression as a `const`'s initializer (whether
/// it's actually a *constant* expression is the checker's job, tested
/// separately below) -- confirmed here with a binary-operator initializer
/// referencing another (not-yet-declared) name, which must still parse
/// cleanly into `Expr::Binary`.
#[test]
fn parses_const_initializer_as_a_full_expression() {
    let src = "const CELLS: i32 = COLS * ROWS\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Const(c) = &module.items[0] else { panic!("expected Item::Const") };
    assert!(matches!(&c.value, Expr::Binary { op: BinOp::Mul, .. }), "{:?}", c.value);
}

/// `const` requires its type annotation -- unlike `let`, there's no call
/// site to infer it from, so `const X = 5` (no `: Type`) must be a clean
/// parse error rather than silently accepting it or misparsing the `=` as
/// part of a type.
#[test]
fn rejects_const_missing_type_annotation() {
    let src = "const X = 5\n";
    let diags = Driver::parse(src).expect_err("const without a type annotation should fail to parse");
    assert!(!diags.is_empty());
}

/// A bare top-level `let` is still a parse error -- `const` is a distinct,
/// additional grammar production, not a rename of `let`'s existing
/// (function-body-only) grammar.
#[test]
fn top_level_let_is_still_a_parse_error() {
    let src = "let x = 5\nfn main():\n    println(f\"{x}\")\n";
    let diags = Driver::parse(src).expect_err("a bare top-level `let` should still be rejected");
    assert!(diags.iter().any(|d| d.message.contains("top-level item")), "{:?}", diags);
}

/// `const` is only a top-level item -- `const` inside a function body (where
/// `let` is legal) must be rejected rather than silently accepted as some
/// local-scope equivalent of `let`.
#[test]
fn rejects_const_inside_a_function_body() {
    let src = "fn main():\n    const X: i32 = 5\n    println(f\"{X}\")\n";
    let diags = Driver::parse(src).expect_err("`const` should not be legal inside a function body");
    assert!(!diags.is_empty());
}

/// A `const`'s value is folded and substituted at every reference site --
/// checked here by confirming the final `TypedModule` carries no
/// `TypedItem::Fn` (or any other kind) named `X` at all (nothing for codegen
/// to emit for the `const` itself -- there is no `TypedItem::Const`
/// variant), while a function referencing it type-checks its `return` down
/// to the constant's own literal value.
#[test]
fn checker_erases_const_items_and_substitutes_their_value() {
    let src = "const X: i32 = 5\nfn get() -> i32:\n    return X\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    assert!(
        !typed.items.iter().any(|i| matches!(i, TypedItem::Fn(f) if f.sig.name == "X")),
        "no item named `X` should survive into the typed module: {:?}",
        typed.items
    );
    let get_fn = typed.items.iter().find_map(|i| match i {
        TypedItem::Fn(f) if f.sig.name == "get" => Some(f),
        _ => None,
    });
    let f = get_fn.expect("`get` should survive into the typed module");
    let TypedStmt::Return { value: Some(v), .. } = &f.body.stmts[0] else { panic!("expected return") };
    assert!(matches!(v, TypedExpr::Int(5, Ty::Int, _)), "expected the const substituted to a literal, found {:?}", v);
}

/// `const`s may reference each other in any declaration order, including a
/// forward reference to a `const` declared later in the file -- mirrors how
/// a top-level `fn` may already call another `fn` declared later.
#[test]
fn const_supports_forward_reference_to_later_const() {
    let src = "const CELLS: i32 = COLS * ROWS\nconst COLS: i32 = 32\nconst ROWS: i32 = 24\nfn get() -> i32:\n    return CELLS\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let TypedItem::Fn(f) = &typed.items[0] else { panic!("expected TypedItem::Fn") };
    let TypedStmt::Return { value: Some(TypedExpr::Int(v, ..)), .. } = &f.body.stmts[0] else { panic!("expected return of an int literal") };
    assert_eq!(*v, 768);
}

/// Unary negation, a numeric cast, and a chain of const-to-const references
/// all fold correctly -- exercised together via a runtime end-to-end
/// program rather than only at the checker level, so a folding bug that only
/// shows up in the *emitted* literal (not just its checked type) would still
/// be caught.
#[test]
fn runtime_top_level_const_arithmetic_cast_and_negation_end_to_end() {
    let src = "const COLS: i32 = 32\n\
               const ROWS: i32 = 24\n\
               const CELLS: i32 = COLS * ROWS\n\
               const NEG: i32 = -5\n\
               const HALF: f32 = COLS as f32 / 2.0\n\
               const TITLE: str = \"snake\"\n\
               const BIG: bool = COLS > ROWS\n\
               fn main():\n    \
               println(f\"{COLS} {ROWS} {CELLS} {NEG} {HALF} {TITLE} {BIG}\")\n";
    let output = compile_and_run("top_level_const_arithmetic", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "32 24 768 -5 16.000000 snake true", "{}", stdout);
}

/// A local variable of the same name still shadows a top-level `const` --
/// ordinary lexical scoping, exactly like a local shadowing a function name.
#[test]
fn runtime_local_variable_shadows_same_named_const_end_to_end() {
    let src = "const X: i32 = 1\nfn main():\n    let x = 99\n    println(f\"{x}\")\n";
    let output = compile_and_run("const_shadowed_by_local", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "99");
}

/// A parameter of the same name as a `const` also shadows it within the
/// function body.
#[test]
fn runtime_parameter_shadows_same_named_const_end_to_end() {
    let src = "const X: i32 = 1\nfn show(X: i32):\n    println(f\"{X}\")\nfn main():\n    show(42)\n";
    let output = compile_and_run("const_shadowed_by_param", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "42");
}

/// A function call inside a `const` initializer is not a constant
/// expression -- rejected with a diagnostic naming the initializer, not
/// silently accepted (there is no compile-time interpreter for arbitrary
/// function bodies).
#[test]
fn rejects_const_initializer_calling_a_function() {
    let src = "fn five() -> i32:\n    return 5\nconst X: i32 = five()\nfn main():\n    println(f\"{X}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("a function call is not a constant expression");
    assert!(errs.iter().any(|d| d.message.contains("not allowed in a `const` initializer")), "{:?}", errs);
}

/// A field access inside a `const` initializer is likewise rejected --
/// covers a different non-constant `TypedExpr` shape than a bare call.
#[test]
fn rejects_const_initializer_using_a_field_access() {
    let src = "struct P:\n    x: i32\nconst X: i32 = P(x = 1).x\nfn main():\n    println(f\"{X}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("a field access is not a constant expression");
    assert!(errs.iter().any(|d| d.message.contains("not allowed in a `const` initializer")), "{:?}", errs);
}

/// A declared type that doesn't match the initializer's actual type is
/// rejected, mirroring `let`'s own annotation-mismatch diagnostic.
#[test]
fn rejects_const_declared_type_mismatch() {
    let src = "const X: i32 = 3.5\nfn main():\n    println(f\"{X}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("i32 declared but a float value given");
    assert!(errs.iter().any(|d| d.message.contains("but the value has type")), "{:?}", errs);
}

/// Every non-default numeric width (`i8`/`u8`/`i16`/`u16`/`u32`/`i64`/`u64`/
/// `f64`) is usable as a `const`'s declared type via an explicit `as` cast --
/// previously `fold_const_expr`'s `Cast` arm only ever folded `Int <-> Float`
/// (i.e. `i32 <-> f32`), so `const X: i8 = 100 as i8` failed with "this cast
/// is not supported in a constant expression" even though the identical cast
/// is legal everywhere else in the language, and even a bare `const X: i8 =
/// 100` (no cast at all) failed with `` `const X: I8` but the value has type
/// `Int` `` since a folded `ConstValue` carried no width of its own -- every
/// `const` narrower than `i32`/`f32` was completely unusable. Confirmed via
/// real `star check` runs before this fix (see this test's runtime
/// counterpart, `runtime_const_of_every_numeric_width_end_to_end`, for the
/// value-correctness half).
#[test]
fn accepts_const_of_every_numeric_width_via_explicit_cast() {
    let src = "const A: i8 = 100 as i8\n\
               const B: u8 = 200 as u8\n\
               const C: i16 = -1234 as i16\n\
               const D: u16 = 40000 as u16\n\
               const E: u32 = 4000000000 as u32\n\
               const F: i64 = 5000000000 as i64\n\
               const G: u64 = 5 as u64\n\
               const H: f64 = 3.5 as f64\n\
               fn main():\n    println(f\"{A} {B} {C} {D} {E} {F} {G} {H}\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("every non-default numeric const width should type-check via an explicit cast");
}

/// A `const` narrower than `i32` still requires the same explicit `as` cast
/// an ordinary `let`/function-argument literal already requires (`docs/
/// language_reference.md`'s numeric-literal-widening convention) -- a bare,
/// un-cast literal stays `Ty::Int` and is rejected against a narrower
/// declared type, exactly like `let y: i8 = 100` is (this fix legalizes the
/// *cast* path, not implicit literal narrowing).
#[test]
fn rejects_const_narrower_type_without_explicit_cast() {
    let src = "const X: i8 = 100\nfn main():\n    println(f\"{X}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("a bare i32-typed literal should not satisfy a narrower `const` type without a cast");
    assert!(errs.iter().any(|d| d.message.contains("but the value has type")), "{:?}", errs);
}

/// Runtime test: a `const` of every non-default numeric width folds to the
/// *correct* value, not just a type that happens to compile -- covers
/// straight-through values for the narrower widths and, more importantly,
/// width-correct wrapping arithmetic (`u8`/`i8` overflow), signed vs.
/// unsigned ordering (`i8`'s `-1 > 100` is false; `u8`'s `200 > 100` is
/// true), and unsigned division/comparison for `u64` computed from a
/// wrapping subtraction that goes through `i64`'s negative range internally
/// (`0u64 - 1u64` must fold to `u64::MAX`, not a negative-looking value, and
/// `u64::MAX / 2` must divide as unsigned, not signed) -- exactly the
/// canonicalization `cast_int_to_ty`/`int_cmp` exist to get right.
#[test]
fn runtime_const_of_every_numeric_width_end_to_end() {
    let src = "const WRAP_U8: u8 = (255 as u8) + (1 as u8)\n\
               const WRAP_I8: i8 = (127 as i8) + (1 as i8)\n\
               const SUB_U8: u8 = (5 as u8) - (10 as u8)\n\
               const CMP_U8: bool = (200 as u8) > (100 as u8)\n\
               const CMP_I8: bool = (-1 as i8) > (100 as i8)\n\
               const U64_MAX: u64 = (0 as u64) - (1 as u64)\n\
               const U64_MAX_GT: bool = U64_MAX > (1 as u64)\n\
               const U64_MAX_HALF: u64 = U64_MAX / (2 as u64)\n\
               const PI64: f64 = 3.25 as f64\n\
               fn main():\n    \
               println(f\"{WRAP_U8} {WRAP_I8} {SUB_U8} {CMP_U8} {CMP_I8} {U64_MAX} {U64_MAX_GT} {U64_MAX_HALF} {PI64}\")\n";
    let output = compile_and_run("const_every_numeric_width", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(
        stdout.replace("\r\n", "\n").trim_end(),
        "0 -128 251 true false 18446744073709551615 true 9223372036854775807 3.250000",
        "{}",
        stdout
    );
}

/// Integer division by zero inside a `const` initializer is a clean
/// diagnostic, not a panic in the compiler itself (`i64::wrapping_div`
/// panics on a zero divisor, unlike `wrapping_add`/`wrapping_sub`/
/// `wrapping_mul` -- `fold_const_expr` must special-case it).
#[test]
fn rejects_const_initializer_division_by_zero() {
    let src = "const X: i32 = 1 / 0\nfn main():\n    println(f\"{X}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("division by zero should be rejected, not panic");
    assert!(errs.iter().any(|d| d.message.contains("division by zero")), "{:?}", errs);
}

/// Integer remainder by zero is likewise rejected (the same
/// `wrapping_rem`-panics-on-zero hazard as division).
#[test]
fn rejects_const_initializer_remainder_by_zero() {
    let src = "const X: i32 = 1 % 0\nfn main():\n    println(f\"{X}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("remainder by zero should be rejected, not panic");
    assert!(errs.iter().any(|d| d.message.contains("division by zero")), "{:?}", errs);
}

/// A `const` directly referencing itself is a self-cycle, reported cleanly
/// rather than recursing forever.
#[test]
fn rejects_const_self_cycle() {
    let src = "const X: i32 = X\nfn main():\n    println(f\"{X}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("a const referencing itself should be a cycle error");
    assert!(errs.iter().any(|d| d.message.contains("recursively refers to itself")), "{:?}", errs);
}

/// A longer cycle (`A` -> `B` -> `A`) is also caught, not just the
/// single-node self-reference case -- confirms `in_progress` tracking spans
/// the whole recursive descent, not just one call frame.
#[test]
fn rejects_const_mutual_cycle() {
    let src = "const A: i32 = B\nconst B: i32 = A\nfn main():\n    println(f\"{A}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("A -> B -> A should be a cycle error");
    assert!(errs.iter().any(|d| d.message.contains("recursively refers to itself")), "{:?}", errs);
}

/// Two `const`s declared with the same name in one in-memory module (no
/// `import`/`crate::modules::resolve` involved at all) must be rejected --
/// the baseline case, confirming the checker's own duplicate-name pass
/// catches a `const` collision exactly like it already does for `fn`/
/// `struct`.
#[test]
fn rejects_duplicate_const_declaration_in_memory() {
    let src = "const X: i32 = 1\nconst X: i32 = 2\nfn main():\n    println(f\"{X}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("declaring `X` twice should be rejected");
    assert!(errs.iter().any(|d| d.message.contains("the constant `X` is declared more than once")), "{:?}", errs);
}

/// A `const` colliding with a `fn` of the same name (either declaration
/// order) is rejected -- `const`s and `fn`s share one flat value namespace,
/// same as any other top-level value-position name collision.
#[test]
fn rejects_const_name_colliding_with_function_name() {
    let src = "const foo: i32 = 1\nfn foo() -> i32:\n    return 2\nfn main():\n    println(f\"{foo}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("`const foo` and `fn foo` should collide");
    assert!(errs.iter().any(|d| d.message.contains("declared more than once")), "{:?}", errs);
}

/// `crate::modules::resolve` mangles an imported `const`'s name to
/// `alias__name`, exactly like it already does for `struct`/`fn`/`enum`/
/// `arena`/`sequence` -- confirms `Item::Const` was wired into
/// `item_top_level_name`/`rename_item`, not just the checker.
#[test]
fn resolve_mangles_imported_const_name() {
    let dir = test_scratch_dir("resolve_mangles_imported_const_name");
    write_test_file(&dir, "lib.star", "const ANSWER: i32 = 42\n");
    let main_path = write_test_file(&dir, "main.star", "import \"lib.star\" as lib\nfn main():\n    println(f\"{lib::ANSWER}\")\n");
    let module = Driver::parse(&std::fs::read_to_string(&main_path).unwrap()).expect("should parse");
    let (resolved, _files) = star::modules::resolve(module, &main_path).expect("should resolve imports");
    assert!(resolved.items.iter().any(|i| matches!(i, Item::Const(c) if c.name == "lib__ANSWER")));

    let typed = Driver::check(&resolved).expect("resolved module should type-check");
    Driver::codegen(&typed).expect("resolved module should codegen");
    let _ = std::fs::remove_dir_all(&dir);
}

/// End-to-end: a `const` declared in an imported file, referenced through a
/// qualified `alias::NAME` path, is folded correctly at the *importing*
/// file's use site -- the full pipeline `grid.star`'s real `COLS`/`ROWS`/
/// `CELL_SIZE` now exercises in the snake game.
#[test]
fn runtime_top_level_const_across_import_end_to_end() {
    let dir = test_scratch_dir("runtime_top_level_const_across_import_end_to_end");
    write_test_file(&dir, "grid.star", "const COLS: i32 = 32\nconst ROWS: i32 = 24\n");
    let main_path = write_test_file(
        &dir,
        "main.star",
        "import \"grid.star\" as grid\nfn board_cells() -> i32:\n    return grid::COLS * grid::ROWS\nfn main():\n    println(f\"{board_cells()}\")\n",
    );

    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(compilation.is_ok(), "{}", compilation.render_diagnostics());
    let typed = compilation.typed.as_ref().unwrap();
    let ir = Driver::codegen(typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_const_across_import.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = std::process::Command::new("clang").args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()]).status().expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");
    let output = std::process::Command::new(&exe).output().expect("failed to execute compiled test binary");
    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "768");

    let _ = std::fs::remove_dir_all(&dir);
}

/// A genuine diamond dependency involving a `const` (both `a.star` and
/// `b.star` import the same `grid.star` directly, `main` imports both `a`
/// and `b`) must still collapse `grid::COLS` to one canonical const, not a
/// "declared more than once" false positive -- the positive counterpart to
/// the duplicate-detection regression tests below, confirming the `CallId`
/// fix (see `crate::modules::ItemProvenance`) didn't overcorrect and start
/// rejecting the legitimate diamond case it was already handling correctly
/// for `struct`s.
#[test]
fn resolve_collapses_diamond_dependency_for_a_const() {
    let dir = test_scratch_dir("resolve_collapses_diamond_dependency_for_a_const");
    write_test_file(&dir, "grid.star", "const COLS: i32 = 32\n");
    write_test_file(&dir, "a.star", "import \"grid.star\" as grid\nfn cols_a() -> i32:\n    return grid::COLS\n");
    write_test_file(&dir, "b.star", "import \"grid.star\" as grid\nfn cols_b() -> i32:\n    return grid::COLS\n");
    let main_path = write_test_file(
        &dir,
        "main.star",
        "import \"a.star\" as a\nimport \"b.star\" as b\nfn main():\n    println(f\"{a::cols_a() + b::cols_b()}\")\n",
    );

    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(compilation.is_ok(), "{}", compilation.render_diagnostics());
    let typed = compilation.typed.as_ref().unwrap();
    Driver::codegen(typed).expect("should codegen");

    let _ = std::fs::remove_dir_all(&dir);
}

// ===== Regression: `crate::modules::dedupe_by_origin` previously collapsed
// ===== two *genuinely distinct* top-level declarations sharing one name
// ===== directly in the same real (on-disk) file -- no `import` involved at
// ===== all -- exactly as if they were a legitimate diamond-dependency
// ===== re-visit, silently keeping only the first and reporting no
// ===== diagnostic whatsoever. Found while testing top-level `const`
// ===== duplicate-name detection against a real file (every prior "declared
// ===== more than once" test in this suite drives `Checker::check` directly
// ===== on an in-memory `Module`, never through `crate::modules::resolve`,
// ===== so none of them exercised this path). Fixed by tagging each
// ===== provenance entry with the `resolve_inner` call frame that produced
// ===== it (`crate::modules::CallId`) and only collapsing entries whose
// ===== `CallId`s differ. =====================================================

/// The bug's original repro: two `const X` declarations directly in one
/// real file, no imports anywhere, must be rejected -- previously silently
/// accepted with only the first `X` surviving.
#[test]
fn resolve_does_not_silently_drop_duplicate_const_declared_directly_in_one_file() {
    let dir = test_scratch_dir("resolve_does_not_silently_drop_duplicate_const_declared_directly_in_one_file");
    let main_path = write_test_file(
        &dir,
        "main.star",
        "const X: i32 = 1\nconst X: i32 = 2\nfn main():\n    println(f\"{X}\")\n",
    );
    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(!compilation.is_ok(), "duplicate `const X` in one real file should be rejected");
    assert!(
        compilation.diagnostics.iter().any(|d| d.message.contains("declared more than once")),
        "{}",
        compilation.render_diagnostics()
    );
    let _ = std::fs::remove_dir_all(&dir);
}

/// Same bug, but for a plain `fn` -- confirms the fix isn't `const`-specific
/// and the underlying `dedupe_by_origin` defect applied to every top-level
/// item kind (`struct`/`enum`/`arena`/`sequence` all share the exact same
/// provenance-tagging code path).
#[test]
fn resolve_does_not_silently_drop_duplicate_fn_declared_directly_in_one_file() {
    let dir = test_scratch_dir("resolve_does_not_silently_drop_duplicate_fn_declared_directly_in_one_file");
    let main_path = write_test_file(
        &dir,
        "main.star",
        "fn foo() -> i32:\n    return 1\nfn foo() -> i32:\n    return 2\nfn main():\n    println(f\"{foo()}\")\n",
    );
    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(!compilation.is_ok(), "duplicate `fn foo` in one real file should be rejected");
    assert!(
        compilation.diagnostics.iter().any(|d| d.message.contains("declared more than once")),
        "{}",
        compilation.render_diagnostics()
    );
    let _ = std::fs::remove_dir_all(&dir);
}

/// Same bug, but for a plain `struct` -- covers the type-namespace duplicate
/// check (`type_names_seen`) rather than the value-namespace one
/// (`value_names_seen`) `fn`/`const` share.
#[test]
fn resolve_does_not_silently_drop_duplicate_struct_declared_directly_in_one_file() {
    let dir = test_scratch_dir("resolve_does_not_silently_drop_duplicate_struct_declared_directly_in_one_file");
    let main_path = write_test_file(
        &dir,
        "main.star",
        "struct P:\n    x: i32\nstruct P:\n    y: i32\nfn main():\n    let p = P(x = 1)\n    println(f\"{p.x}\")\n",
    );
    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(!compilation.is_ok(), "duplicate `struct P` in one real file should be rejected");
    assert!(
        compilation.diagnostics.iter().any(|d| d.message.contains("declared more than once")),
        "{}",
        compilation.render_diagnostics()
    );
    let _ = std::fs::remove_dir_all(&dir);
}

/// A real duplicate declared directly in one file, combined *in the same
/// file* with a genuine diamond dependency reaching the same name through an
/// import, must still flag the direct duplicate -- confirms the `CallId`
/// comparison (against the group's *first* entry) doesn't get confused when
/// both shapes appear in the same provenance group. `main.star` declares
/// `struct Cell` twice directly (a real duplicate) *and* imports `grid.star`
/// (also declaring `Cell`) twice through two separate aliases (a diamond) --
/// the diamond pair must still collapse to one, while the direct duplicate
/// pair must still be reported.
#[test]
fn resolve_reports_direct_duplicate_even_when_a_diamond_reimport_shares_the_same_name() {
    let dir = test_scratch_dir("resolve_reports_direct_duplicate_even_when_a_diamond_reimport_shares_the_same_name");
    write_test_file(&dir, "grid.star", "struct Cell:\n    x: i32\n");
    write_test_file(&dir, "a.star", "import \"grid.star\" as grid\nfn make_a() -> grid::Cell:\n    return grid::Cell(x = 1)\n");
    write_test_file(&dir, "b.star", "import \"grid.star\" as grid\nfn make_b() -> grid::Cell:\n    return grid::Cell(x = 2)\n");
    let main_path = write_test_file(
        &dir,
        "main.star",
        "import \"a.star\" as a\nimport \"b.star\" as b\nconst X: i32 = 1\nconst X: i32 = 2\nfn main():\n    println(f\"{a::make_a().x + b::make_b().x + X}\")\n",
    );
    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(!compilation.is_ok(), "the direct `const X` duplicate should still be reported");
    assert!(
        compilation.diagnostics.iter().any(|d| d.message.contains("the constant `X` is declared more than once")),
        "{}",
        compilation.render_diagnostics()
    );
    let _ = std::fs::remove_dir_all(&dir);
}

//! `import`/module resolution, search paths, manifest/`star.toml`
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== `import`/module resolution (namespaced modules) =====================

/// Parsing alone (no file I/O) must recognize the `import "path" as alias`
/// item and register the alias.
#[test]
fn parses_import_decl() {
    let src = "import \"geometry_lib.star\" as geo\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Import(decl) = &module.items[0] else { panic!("expected an import item") };
    assert_eq!(decl.alias, "geo");
    assert_eq!(decl.path, "geometry_lib.star");
}

/// A qualified struct literal `alias::Name(...)` parses straight to the
/// mangled name `crate::modules::resolve` would have given that struct --
/// the parser reproduces the mangling from source text alone, without ever
/// touching the imported file.
#[test]
fn parses_qualified_struct_literal_as_mangled_name() {
    let src = "import \"lib.star\" as geo\nfn main():\n    let p = geo::Point(1, 2)\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected let") };
    let Expr::StructLit { name, args, .. } = value else { panic!("expected struct literal, got {:?}", value) };
    assert_eq!(name, "geo__Point");
    assert_eq!(args.len(), 2);
}

/// A qualified free-function call `alias::name(...)` parses to a `Call`
/// whose callee is the mangled identifier (lowercase names never trigger
/// the struct-literal heuristic).
#[test]
fn parses_qualified_fn_call_as_mangled_name() {
    let src = "import \"lib.star\" as geo\nfn main():\n    let d = geo::dot(1, 2)\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected let") };
    let Expr::Call { callee, .. } = value else { panic!("expected call, got {:?}", value) };
    assert!(matches!(callee.as_ref(), Expr::Ident(name, _) if name == "geo__dot"));
}

/// A qualified free-function call `alias::name(...)`'s callee carries a span
/// covering the *whole* `alias::name` text, not just the `alias` segment --
/// previously it reused the qualified path's very first captured span (the
/// lone `alias` identifier token, from before `::name` was even parsed), so
/// an "undefined function" diagnostic on a genuinely undefined qualified
/// call -- or, for `star lsp`'s `textDocument/definition`, a click on the
/// meaningful `name` half of `alias::name` -- pointed at/covered only the
/// (perfectly valid) `alias` segment instead. The non-call qualified-path
/// case (a bare `geo::dot` with no trailing `(...)`, see
/// `parses_qualified_fn_call_as_mangled_name` just above) already got this
/// right; the call case just hadn't kept up.
#[test]
fn parses_qualified_fn_call_callee_span_covers_the_whole_alias_path() {
    let src = "import \"lib.star\" as geo\nfn main():\n    let d = geo::dot(1, 2)\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected let") };
    let Expr::Call { callee, .. } = value else { panic!("expected call, got {:?}", value) };
    let want = "geo::dot";
    let start = src.find(want).unwrap();
    assert_eq!(callee.span().start, start);
    assert_eq!(callee.span().end, start + want.len());
}

/// A 3-segment qualified path `alias::Enum::Variant(...)` parses to an
/// `EnumVariant` whose enum name is mangled but whose variant name is left
/// alone (variants aren't top-level declarations of their own).
#[test]
fn parses_qualified_enum_variant_as_mangled_enum_name() {
    let src = "import \"lib.star\" as geo\nfn main():\n    let s = geo::Shape::Circle(2)\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected let") };
    let Expr::EnumVariant { enum_name, variant, args, .. } = value else { panic!("expected enum variant, got {:?}", value) };
    assert_eq!(enum_name, "geo__Shape");
    assert_eq!(variant, "Circle");
    assert_eq!(args.len(), 1);
}

/// A qualified path used inside an f-string interpolation must see the same
/// import aliases as the rest of the file: interpolated expressions are
/// re-lexed/parsed by a fresh sub-parser (see `Parser::lower_fstring`), which
/// must inherit `import_aliases` rather than starting empty.
#[test]
fn parses_qualified_call_inside_fstring_interpolation() {
    let src = "import \"lib.star\" as geo\nfn main():\n    println(f\"{geo::dot(1, 2)}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected fn") };
    let Stmt::Expr(Expr::Call { args, .. }) = &f.body.stmts[0] else { panic!("expected call stmt") };
    let Expr::FStr(parts, _) = &args[0] else { panic!("expected f-string arg") };
    let FStrExpr::Expr(inner) = &parts[0] else { panic!("expected interpolated expr") };
    let Expr::Call { callee, .. } = inner.as_ref() else { panic!("expected call, got {:?}", inner) };
    assert!(matches!(callee.as_ref(), Expr::Ident(name, _) if name == "geo__dot"));
}

/// A qualified struct pattern `alias::Name(bindings...)` in a `match` arm
/// mangles the same way an expression-position struct literal would.
#[test]
fn parses_qualified_struct_pattern() {
    let src = "import \"lib.star\" as geo\nfn t(p: geo::Point) -> i32:\n    match p:\n        geo::Point(x, y) -> x\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected fn") };
    assert_eq!(f.sig.params[0].ty, Some(Type::Named("geo__Point".into())));
    let Stmt::Expr(Expr::Match { arms, .. }) = &f.body.stmts[0] else { panic!("expected match stmt") };
    assert!(matches!(&arms[0].pattern, Pattern::Struct(name, bindings) if name == "geo__Point" && bindings == &vec!["x".to_string(), "y".to_string()]));
}

/// A qualified *type* path reaching through a re-exported nested import
/// (`b::c::Point`, three segments) mangles by chaining, exactly like the
/// expression/pattern forms above -- `parser::mod::parse_type_inner`'s own
/// qualified-path loop, not `parse_primary`'s.
#[test]
fn parses_transitive_qualified_type_as_chained_mangled_name() {
    let src = "import \"lib.star\" as b\nfn t(p: b::c::Point) -> i32:\n    return 0\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected fn") };
    assert_eq!(f.sig.params[0].ty, Some(Type::Named("b__c__Point".into())));
}

/// A qualified enum-variant pattern `alias::Enum::Variant(bindings...)`.
#[test]
fn parses_qualified_enum_variant_pattern() {
    let src = "import \"lib.star\" as geo\nfn t(s: geo::Shape) -> i32:\n    match s:\n        geo::Shape::Circle(r) -> r\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected fn") };
    let Stmt::Expr(Expr::Match { arms, .. }) = &f.body.stmts[0] else { panic!("expected match stmt") };
    assert!(matches!(
        &arms[0].pattern,
        Pattern::EnumVariant(enum_name, variant, bindings)
            if enum_name == "geo__Shape" && variant == "Circle" && bindings == &vec!["r".to_string()]
    ));
}

/// Resolving a single import inlines the imported file's items, mangled to
/// `alias__name`, and leaves no `Item::Import` behind.
#[test]
fn resolve_inlines_and_mangles_imported_items() {
    let dir = test_scratch_dir("resolve_inlines_and_mangles_imported_items");
    write_test_file(&dir, "lib.star", "struct Point:\n    x: i32\n    y: i32\n\nfn dot(a: Point, b: Point) -> i32:\n    return a.x * b.x + a.y * b.y\n");
    let main_path = write_test_file(
        &dir,
        "main.star",
        "import \"lib.star\" as geo\nfn main() -> i32:\n    return geo::dot(geo::Point(1, 2), geo::Point(3, 4))\n",
    );
    let module = Driver::parse(&std::fs::read_to_string(&main_path).unwrap()).expect("should parse");
    let (resolved, _files) = star::modules::resolve(module, &main_path).expect("should resolve imports");

    assert!(!resolved.items.iter().any(|i| matches!(i, Item::Import(_))), "no Item::Import should remain");
    assert!(resolved.items.iter().any(|i| matches!(i, Item::Struct(s) if s.name == "geo__Point")));
    assert!(resolved.items.iter().any(|i| matches!(i, Item::Fn(f) if f.sig.name == "geo__dot")));

    // The merged module must also type-check and codegen cleanly end to end.
    let typed = Driver::check(&resolved).expect("resolved module should type-check");
    Driver::codegen(&typed).expect("resolved module should codegen");
}

/// A cyclic import (`a` imports `b`, `b` imports `a`) must be reported as an
/// error rather than recursing forever.
#[test]
fn resolve_detects_import_cycle() {
    let dir = test_scratch_dir("resolve_detects_import_cycle");
    write_test_file(&dir, "a.star", "import \"b.star\" as b\nfn from_a():\n    return\n");
    let b_path = write_test_file(&dir, "b.star", "import \"a.star\" as a\nfn from_b():\n    return\n");
    // Enter the cycle from b.star so both files are real, on-disk imports.
    let module = Driver::parse(&std::fs::read_to_string(&b_path).unwrap()).expect("should parse");
    let err = star::modules::resolve(module, &b_path).expect_err("cyclic import should fail to resolve");
    assert!(err.iter().any(|d| d.message.contains("cycle")), "{:?}", err);
}

/// A cyclic import chain three files deep (`a` -> `b` -> `c` -> `a`) must
/// also be caught -- guards that the cycle guard (`loading`, a shared
/// `HashSet<PathBuf>` threaded through every recursive `resolve_inner` call)
/// really does catch an *indirect* cycle, not just the direct two-file case
/// `resolve_detects_import_cycle` covers.
#[test]
fn resolve_detects_transitive_three_file_import_cycle() {
    let dir = test_scratch_dir("resolve_detects_transitive_three_file_import_cycle");
    write_test_file(&dir, "a.star", "import \"b.star\" as b\nfn from_a():\n    return\n");
    write_test_file(&dir, "b.star", "import \"c.star\" as c\nfn from_b():\n    return\n");
    let c_path = write_test_file(&dir, "c.star", "import \"a.star\" as a\nfn from_c():\n    return\n");
    // Enter the cycle from c.star so every file involved is a real, on-disk
    // import (mirroring `resolve_detects_import_cycle`'s own approach).
    let module = Driver::parse(&std::fs::read_to_string(&c_path).unwrap()).expect("should parse");
    let err = star::modules::resolve(module, &c_path).expect_err("a 3-file transitive import cycle should fail to resolve");
    assert!(err.iter().any(|d| d.message.contains("cycle")), "{:?}", err);
}

/// A long, genuinely *acyclic* chain of imports (`a` imports `b` imports `c`
/// imports ... some 800 levels deep, every file distinct, no cycle anywhere)
/// must be a clean error, not a Rust stack overflow. `resolve_inner`
/// recurses once per import level with no depth counter of its own --
/// unlike a cyclic chain, the shared `loading` cycle guard does nothing here
/// (every canonical path really is new), so previously this reliably
/// overflowed the real call stack with a bare process abort ("thread 'main'
/// has overflowed its stack") on a syntactically unremarkable chain of small
/// files -- plausible output from a code generator emitting one file per
/// module/scene and chaining them together, not just a hand-crafted
/// adversarial case. Fixed by a new `MAX_IMPORT_DEPTH` counter threaded
/// through `resolve_inner`.
#[test]
fn rejects_deeply_nested_acyclic_import_chain_does_not_overflow_stack() {
    let dir = test_scratch_dir("rejects_deeply_nested_acyclic_import_chain_does_not_overflow_stack");
    let n = 800;
    for i in 0..n {
        write_test_file(
            &dir,
            &format!("chain{}.star", i),
            &format!("import \"chain{}.star\" as nxt\nfn f{}() -> i32:\n    return nxt::f{}()\n", i + 1, i, i + 1),
        );
    }
    write_test_file(&dir, &format!("chain{}.star", n), &format!("fn f{}() -> i32:\n    return 42\n", n));
    let main_path = write_test_file(
        &dir, "main.star",
        "import \"chain0.star\" as c\nfn main() -> i32:\n    return c::f0()\n",
    );
    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(!compilation.is_ok(), "an 800-level-deep acyclic import chain should be a clean error, not succeed or crash");
    let rendered = compilation.render_diagnostics();
    assert!(rendered.contains("nests too deeply"), "{}", rendered);
    let _ = std::fs::remove_dir_all(&dir);
}

/// A reasonably (but not adversarially) deep acyclic import chain -- well
/// under `MAX_IMPORT_DEPTH` -- must still resolve, type-check, build, and run
/// correctly end to end (a regression guard against the new depth counter
/// being so aggressive it rejects sound, if unusual, multi-file programs).
#[test]
fn runtime_moderately_deep_acyclic_import_chain_end_to_end() {
    let dir = test_scratch_dir("runtime_moderately_deep_acyclic_import_chain_end_to_end");
    let n = 20;
    for i in 0..n {
        write_test_file(
            &dir,
            &format!("mchain{}.star", i),
            &format!("import \"mchain{}.star\" as nxt\nfn f{}() -> i32:\n    return nxt::f{}()\n", i + 1, i, i + 1),
        );
    }
    write_test_file(&dir, &format!("mchain{}.star", n), &format!("fn f{}() -> i32:\n    return 42\n", n));
    let main_path = write_test_file(
        &dir, "main.star",
        "import \"mchain0.star\" as c\nfn main():\n    println(f\"{c::f0()}\")\n",
    );
    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(compilation.is_ok(), "{}", compilation.render_diagnostics());
    let typed = compilation.typed.as_ref().unwrap();
    let ir = Driver::codegen(typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_moderately_deep_acyclic_import_chain.exe");
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
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "42", "{}", stdout);
    let _ = std::fs::remove_dir_all(&dir);
}

/// Importing a file that doesn't exist is a clean error, not a panic.
#[test]
fn resolve_reports_missing_import_file() {
    let dir = test_scratch_dir("resolve_reports_missing_import_file");
    let main_path = write_test_file(&dir, "main.star", "import \"does_not_exist.star\" as x\nfn main():\n    return\n");
    let module = Driver::parse(&std::fs::read_to_string(&main_path).unwrap()).expect("should parse");
    let err = star::modules::resolve(module, &main_path).expect_err("missing import should fail to resolve");
    assert!(err.iter().any(|d| d.message.contains("cannot import")), "{:?}", err);
}

// ===== `star::modules::resolve_with_search_paths` (todo.md P1 #4: module
// search-path resolution) ===================================================

/// An `import` that doesn't exist relative to the importing file's own
/// directory, but does exist in a configured search-path directory,
/// resolves through that directory instead of failing.
#[test]
fn resolve_with_search_paths_finds_import_in_a_search_directory() {
    let dir = test_scratch_dir("resolve_with_search_paths_finds_import_in_a_search_directory");
    let lib_dir = dir.join("libs");
    write_test_file(&lib_dir, "geo.star", "fn dot(a: i32, b: i32) -> i32:\n    return a * b\n");
    let main_path = write_test_file(&dir, "main.star", "import \"geo.star\" as geo\nfn main() -> i32:\n    return geo::dot(2, 3)\n");

    let module = Driver::parse(&std::fs::read_to_string(&main_path).unwrap()).expect("should parse");
    let search_paths = vec![lib_dir.clone()];
    let (resolved, _files) =
        star::modules::resolve_with_search_paths(module, &main_path, &search_paths).expect("should resolve via search path");
    assert!(resolved.items.iter().any(|i| matches!(i, Item::Fn(f) if f.sig.name == "geo__dot")));

    let typed = Driver::check(&resolved).expect("should type-check");
    Driver::codegen(&typed).expect("should codegen");
    let _ = std::fs::remove_dir_all(&dir);
}

/// The plain 2-argument `resolve` (no search paths at all) must not find an
/// import that only exists in some directory elsewhere on disk -- a
/// regression guard that adding search-path support didn't change
/// `resolve`'s existing relative-only behavior for the hundreds of callers
/// that never pass one.
#[test]
fn resolve_without_search_paths_still_only_looks_relative_to_the_importing_file() {
    let dir = test_scratch_dir("resolve_without_search_paths_still_only_looks_relative_to_the_importing_file");
    let lib_dir = dir.join("libs");
    write_test_file(&lib_dir, "geo.star", "fn dot(a: i32, b: i32) -> i32:\n    return a * b\n");
    let main_path = write_test_file(&dir, "main.star", "import \"geo.star\" as geo\nfn main() -> i32:\n    return geo::dot(2, 3)\n");

    let module = Driver::parse(&std::fs::read_to_string(&main_path).unwrap()).expect("should parse");
    let err = star::modules::resolve(module, &main_path).expect_err("should not find geo.star without a search path");
    assert!(err.iter().any(|d| d.message.contains("cannot import")), "{:?}", err);
    let _ = std::fs::remove_dir_all(&dir);
}

/// A file sitting right next to the importing file always wins over a
/// same-named file reachable through a search path -- relative resolution
/// is tried first, exactly like a C compiler's `#include "foo.h"` checking
/// the including file's own directory before any `-I` path.
#[test]
fn resolve_with_search_paths_prefers_relative_file_over_search_path_match() {
    let dir = test_scratch_dir("resolve_with_search_paths_prefers_relative_file_over_search_path_match");
    let lib_dir = dir.join("libs");
    write_test_file(&dir, "geo.star", "fn which() -> i32:\n    return 1\n");
    write_test_file(&lib_dir, "geo.star", "fn which() -> i32:\n    return 2\n");
    let main_path = write_test_file(&dir, "main.star", "import \"geo.star\" as geo\nfn main() -> i32:\n    return geo::which()\n");

    let module = Driver::parse(&std::fs::read_to_string(&main_path).unwrap()).expect("should parse");
    let search_paths = vec![lib_dir.clone()];
    let (resolved, _files) =
        star::modules::resolve_with_search_paths(module, &main_path, &search_paths).expect("should resolve");
    let Item::Fn(f) = resolved.items.iter().find(|i| matches!(i, Item::Fn(f) if f.sig.name == "geo__which")).unwrap() else {
        unreachable!()
    };
    let Stmt::Return { value: Some(Expr::Int(n, _)), .. } = &f.body.stmts[0] else { panic!("expected return of an int literal") };
    assert_eq!(*n, 1, "the relative-to-the-importing-file geo.star should win, not the one from the search path");
    let _ = std::fs::remove_dir_all(&dir);
}

/// With more than one search path configured, the first one (in the order
/// given) that actually contains the file wins -- mirrors how a linker/
/// compiler resolves `-I`/`-L` directories left-to-right.
#[test]
fn resolve_with_search_paths_first_matching_directory_wins() {
    let dir = test_scratch_dir("resolve_with_search_paths_first_matching_directory_wins");
    let first = dir.join("first");
    let second = dir.join("second");
    write_test_file(&first, "geo.star", "fn which() -> i32:\n    return 10\n");
    write_test_file(&second, "geo.star", "fn which() -> i32:\n    return 20\n");
    let main_path = write_test_file(&dir, "main.star", "import \"geo.star\" as geo\nfn main() -> i32:\n    return geo::which()\n");

    let module = Driver::parse(&std::fs::read_to_string(&main_path).unwrap()).expect("should parse");
    let search_paths = vec![first.clone(), second.clone()];
    let (resolved, _files) =
        star::modules::resolve_with_search_paths(module, &main_path, &search_paths).expect("should resolve");
    let Item::Fn(f) = resolved.items.iter().find(|i| matches!(i, Item::Fn(f) if f.sig.name == "geo__which")).unwrap() else {
        unreachable!()
    };
    let Stmt::Return { value: Some(Expr::Int(n, _)), .. } = &f.body.stmts[0] else { panic!("expected return of an int literal") };
    assert_eq!(*n, 10, "the first search path directory containing the file should win");
    let _ = std::fs::remove_dir_all(&dir);
}

/// A search path that exists but doesn't contain the requested file is
/// skipped in favor of a later one that does -- the search doesn't stop (or
/// error) at the first directory tried, only at the first directory that
/// actually resolves the import.
#[test]
fn resolve_with_search_paths_skips_non_matching_directories() {
    let dir = test_scratch_dir("resolve_with_search_paths_skips_non_matching_directories");
    let empty_dir = dir.join("empty");
    let real_dir = dir.join("real");
    std::fs::create_dir_all(&empty_dir).unwrap();
    write_test_file(&real_dir, "geo.star", "fn which() -> i32:\n    return 42\n");
    let main_path = write_test_file(&dir, "main.star", "import \"geo.star\" as geo\nfn main() -> i32:\n    return geo::which()\n");

    let module = Driver::parse(&std::fs::read_to_string(&main_path).unwrap()).expect("should parse");
    let search_paths = vec![empty_dir.clone(), real_dir.clone()];
    let (resolved, _files) =
        star::modules::resolve_with_search_paths(module, &main_path, &search_paths).expect("should resolve via the second directory");
    assert!(resolved.items.iter().any(|i| matches!(i, Item::Fn(f) if f.sig.name == "geo__which")));
    let _ = std::fs::remove_dir_all(&dir);
}

/// When an import can't be found anywhere (not relative to the importing
/// file, not in any search path), the error message lists every location
/// actually tried -- much friendlier than a bare "file not found" for a
/// project with several search directories configured.
#[test]
fn resolve_with_search_paths_missing_import_error_lists_every_location_tried() {
    let dir = test_scratch_dir("resolve_with_search_paths_missing_import_error_lists_every_location_tried");
    let first = dir.join("first");
    let second = dir.join("second");
    std::fs::create_dir_all(&first).unwrap();
    std::fs::create_dir_all(&second).unwrap();
    let main_path = write_test_file(&dir, "main.star", "import \"nope.star\" as x\nfn main():\n    return\n");

    let module = Driver::parse(&std::fs::read_to_string(&main_path).unwrap()).expect("should parse");
    let search_paths = vec![first.clone(), second.clone()];
    let err =
        star::modules::resolve_with_search_paths(module, &main_path, &search_paths).expect_err("should fail to resolve");
    let msg = &err[0].message;
    assert!(msg.contains("cannot import"), "{msg}");
    assert!(msg.contains(&dir.join("nope.star").display().to_string()), "{msg}");
    assert!(msg.contains(&first.join("nope.star").display().to_string()), "{msg}");
    assert!(msg.contains(&second.join("nope.star").display().to_string()), "{msg}");
    let _ = std::fs::remove_dir_all(&dir);
}

/// Search paths propagate through recursive import resolution: a file
/// that's itself only reachable via a search path can, in turn, import
/// another file that's *also* only reachable via a search path -- the
/// `search_paths` slice threaded through `resolve_inner`'s recursive call
/// doesn't get dropped or reset one level down.
#[test]
fn resolve_with_search_paths_propagates_into_nested_imports() {
    let dir = test_scratch_dir("resolve_with_search_paths_propagates_into_nested_imports");
    let lib_dir = dir.join("libs");
    write_test_file(&lib_dir, "base.star", "fn base_val() -> i32:\n    return 7\n");
    write_test_file(&lib_dir, "mid.star", "import \"base.star\" as base\nfn mid_val() -> i32:\n    return base::base_val() * 2\n");
    let main_path = write_test_file(&dir, "main.star", "import \"mid.star\" as mid\nfn main() -> i32:\n    return mid::mid_val()\n");

    let module = Driver::parse(&std::fs::read_to_string(&main_path).unwrap()).expect("should parse");
    let search_paths = vec![lib_dir.clone()];
    let (resolved, _files) =
        star::modules::resolve_with_search_paths(module, &main_path, &search_paths).expect("should resolve both levels via the search path");
    assert!(resolved.items.iter().any(|i| matches!(i, Item::Fn(f) if f.sig.name == "mid__base__base_val")));
    let typed = Driver::check(&resolved).expect("should type-check");
    Driver::codegen(&typed).expect("should codegen");
    let _ = std::fs::remove_dir_all(&dir);
}

/// Runtime test: an import resolved purely through a search path (no
/// relative path from `main.star` to the library at all) builds, links, and
/// runs correctly end to end -- not just type-checks/codegens.
#[test]
fn runtime_import_resolved_via_search_path_end_to_end() {
    let dir = test_scratch_dir("runtime_import_resolved_via_search_path_end_to_end");
    let lib_dir = dir.join("vendor");
    write_test_file(&lib_dir, "mathlib.star", "fn square(x: i32) -> i32:\n    return x * x\n");
    let main_path = write_test_file(
        &dir,
        "main.star",
        "import \"mathlib.star\" as m\nfn main():\n    println(f\"{m::square(9)}\")\n",
    );

    let driver = Driver::with_search_paths(&main_path, vec![lib_dir.clone()]);
    let compilation = driver.compile().expect("file read should succeed");
    assert!(compilation.is_ok(), "{}", compilation.render_diagnostics());
    let typed = compilation.typed.as_ref().unwrap();
    let ir = Driver::codegen(typed).expect("should codegen");

    let exe = std::env::temp_dir().join("star_test_import_resolved_via_search_path.exe");
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
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "81");
    let _ = std::fs::remove_dir_all(&dir);
}

// ===== `star::manifest`/`star::driver::resolve_input` (star.toml + the
// CLI-level directory/-I/STAR_PATH plumbing around search-path resolution)
// ===========================================================================

fn manifest_test_scratch_dir(name: &str) -> std::path::PathBuf {
    std::env::temp_dir().join("star_manifest_driver_tests").join(name)
}

/// A plain file argument with no `star.toml` anywhere in its ancestry
/// resolves to itself, unmodified, with `search_paths` equal to exactly
/// whatever `extra_search_paths` the caller passed in -- the no-manifest
/// case must be a no-op beyond that, so every pre-existing single-file
/// caller sees identical behavior to before this feature existed.
#[test]
fn resolve_input_file_with_no_manifest_is_unmodified_plus_extra_search_paths() {
    let dir = manifest_test_scratch_dir("resolve_input_file_with_no_manifest_is_unmodified_plus_extra_search_paths");
    let main_path = write_test_file(&dir, "main.star", "fn main():\n    return\n");
    let extra = vec![std::path::PathBuf::from("some/extra/dir")];

    let resolved = star::driver::resolve_input(&main_path, &extra).expect("should resolve");
    assert_eq!(resolved.entry, main_path);
    assert_eq!(resolved.search_paths, extra);
    assert_eq!(resolved.manifest_root, None);
    let _ = std::fs::remove_dir_all(&dir);
}

/// A file argument whose directory (or an ancestor of it) contains a
/// `star.toml` gets that manifest's search paths folded in automatically,
/// purely additively -- `extra_search_paths` (CLI `-I`/`STAR_PATH`) still
/// come first, then the manifest's own `[paths] search` entries, then the
/// manifest's own root directory.
#[test]
fn resolve_input_file_auto_discovers_ancestor_manifest_and_appends_its_search_paths() {
    let root = manifest_test_scratch_dir("resolve_input_file_auto_discovers_ancestor_manifest_and_appends_its_search_paths");
    write_test_file(&root, star::manifest::MANIFEST_FILE_NAME, "[package]\nname = \"proj\"\n[paths]\nsearch = [\"vendor\"]\n");
    let main_path = write_test_file(&root.join("src"), "main.star", "fn main():\n    return\n");
    let extra = vec![std::path::PathBuf::from("explicit")];

    let resolved = star::driver::resolve_input(&main_path, &extra).expect("should resolve");
    assert_eq!(resolved.entry, main_path, "an explicit file argument is used verbatim, never replaced by the manifest's entry");
    assert_eq!(resolved.search_paths, vec![std::path::PathBuf::from("explicit"), root.join("vendor"), root.clone()]);
    assert_eq!(resolved.manifest_root, Some(root.clone()));
    let _ = std::fs::remove_dir_all(&root);
}

/// A directory argument containing a `star.toml` resolves to that
/// manifest's declared `entry` (not a hardcoded `main.star`), with its
/// search paths appended after `extra_search_paths`.
#[test]
fn resolve_input_directory_with_manifest_uses_declared_entry_and_search_paths() {
    let root = manifest_test_scratch_dir("resolve_input_directory_with_manifest_uses_declared_entry_and_search_paths");
    write_test_file(&root, star::manifest::MANIFEST_FILE_NAME, "[package]\nentry = \"start.star\"\n[paths]\nsearch = [\"src\"]\n");
    write_test_file(&root, "start.star", "fn main():\n    return\n");

    let resolved = star::driver::resolve_input(&root, &[]).expect("should resolve");
    assert_eq!(resolved.entry, root.join("start.star"));
    assert_eq!(resolved.search_paths, vec![root.join("src"), root.clone()]);
    assert_eq!(resolved.manifest_root, Some(root.clone()));
    let _ = std::fs::remove_dir_all(&root);
}

/// A directory argument with no manifest's `entry` declared falls back to
/// `crate::manifest::DEFAULT_ENTRY` (`main.star`).
#[test]
fn resolve_input_directory_with_manifest_defaults_entry_to_main_star() {
    let root = manifest_test_scratch_dir("resolve_input_directory_with_manifest_defaults_entry_to_main_star");
    write_test_file(&root, star::manifest::MANIFEST_FILE_NAME, "[package]\nname = \"proj\"\n");

    let resolved = star::driver::resolve_input(&root, &[]).expect("should resolve");
    assert_eq!(resolved.entry, root.join("main.star"));
    let _ = std::fs::remove_dir_all(&root);
}

/// A directory argument with *no* `star.toml` directly inside it is a clean
/// error -- and, unlike the file-argument case, does not fall back to
/// walking further up looking for one: an explicit directory argument is an
/// explicit claim that it's the project root.
#[test]
fn resolve_input_directory_without_manifest_is_a_clean_error() {
    let root = manifest_test_scratch_dir("resolve_input_directory_without_manifest_is_a_clean_error");
    std::fs::create_dir_all(&root).unwrap();

    let err = star::driver::resolve_input(&root, &[]).expect_err("a directory with no star.toml should be an error");
    assert!(err.contains("star.toml"), "{err}");
    let _ = std::fs::remove_dir_all(&root);
}

/// A directory argument whose manifest is only present in a *parent*
/// directory (not directly inside the given directory) is still an error --
/// pins the "no ancestor walk for an explicit directory argument" contract
/// `resolve_input_directory_without_manifest_is_a_clean_error` names.
#[test]
fn resolve_input_directory_does_not_fall_back_to_an_ancestor_manifest() {
    let root = manifest_test_scratch_dir("resolve_input_directory_does_not_fall_back_to_an_ancestor_manifest");
    let nested = root.join("nested");
    write_test_file(&root, star::manifest::MANIFEST_FILE_NAME, "[package]\nname = \"parent\"\n");
    std::fs::create_dir_all(&nested).unwrap();

    let err = star::driver::resolve_input(&nested, &[]).expect_err("should not find the parent's manifest");
    assert!(err.contains("star.toml"), "{err}");
    let _ = std::fs::remove_dir_all(&root);
}

/// A malformed `star.toml` (parse error) surfaces as a clean `Err` from
/// `resolve_input` rather than a panic, whether reached via a directory
/// argument or auto-discovery from a file argument.
#[test]
fn resolve_input_reports_a_malformed_manifest_as_a_clean_error() {
    let root = manifest_test_scratch_dir("resolve_input_reports_a_malformed_manifest_as_a_clean_error");
    write_test_file(&root, star::manifest::MANIFEST_FILE_NAME, "this is not valid star.toml\n");

    let dir_err = star::driver::resolve_input(&root, &[]).expect_err("malformed manifest via directory arg should error");
    assert!(dir_err.contains("star.toml"), "{dir_err}");

    let main_path = write_test_file(&root, "main.star", "fn main():\n    return\n");
    let file_err = star::driver::resolve_input(&main_path, &[]).expect_err("malformed manifest via ancestor discovery should error");
    assert!(file_err.contains("star.toml"), "{file_err}");
    let _ = std::fs::remove_dir_all(&root);
}

/// End-to-end runtime test: a directory argument with a `star.toml`
/// declaring `[paths] search = ["src"]` builds, links, and runs correctly
/// through the exact same `resolve_input` -> `Driver::with_search_paths` ->
/// `compile` -> `codegen` pipeline `cmd_build`/`cmd_check` drive -- proving
/// the manifest-driven path works for a real multi-file layout, not just a
/// single flat directory of files.
#[test]
fn runtime_directory_argument_with_manifest_and_src_layout_end_to_end() {
    let root = manifest_test_scratch_dir("runtime_directory_argument_with_manifest_and_src_layout_end_to_end");
    write_test_file(&root, star::manifest::MANIFEST_FILE_NAME, "[package]\nname = \"proj\"\nentry = \"main.star\"\n[paths]\nsearch = [\"src\"]\n");
    write_test_file(&root.join("src"), "geo.star", "fn dot(a: i32, b: i32) -> i32:\n    return a * b\n");
    write_test_file(
        &root,
        "main.star",
        "import \"geo.star\" as geo\nfn main():\n    println(f\"{geo::dot(6, 7)}\")\n",
    );

    let resolved = star::driver::resolve_input(&root, &[]).expect("should resolve the directory argument");
    let driver = Driver::with_search_paths(&resolved.entry, resolved.search_paths);
    let compilation = driver.compile().expect("file read should succeed");
    assert!(compilation.is_ok(), "{}", compilation.render_diagnostics());
    let typed = compilation.typed.as_ref().unwrap();
    let ir = Driver::codegen(typed).expect("should codegen");

    let exe = std::env::temp_dir().join("star_test_directory_argument_with_manifest.exe");
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
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "42");
    let _ = std::fs::remove_dir_all(&root);
}

/// Runtime test: `examples/modules_main.exe` exercises `import "path" as
/// alias` end to end -- a qualified struct literal, a qualified
/// free-function call, and a qualified payload enum variant construction
/// (a 3-segment `geo::Shape::Circle(...)` path) reaching into
/// `geometry_lib.star`'s namespace, through a real clang-compiled
/// executable.
#[test]
fn runtime_modules_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/modules_main.exe").output().expect("failed to execute modules_main.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("dot: 11"), "qualified struct literal + free function call: {}", stdout);
    assert!(stdout.contains("circle area: 12"), "qualified 3-segment enum variant + match inside the imported module: {}", stdout);
    assert!(stdout.contains("rect area: 12"), "second variant of the same imported enum: {}", stdout);
}

// ===== `impl alias::Type:` reaching into another module (todo.md P1 #6) ====
//
// Previously `impl imported::Type:` was a flat parse error ("expected ':',
// found '::'") -- `Parser::parse_impl` called `expect_ident()` for the type
// (and trait) name and never consulted `import_aliases`, unlike every other
// qualified-path site (`parse_type_inner`, `parse_primary`, pattern parsing).
// The fix mirrors those sites exactly: once `Parser::parse_impl_qualified_
// name` (`src/parser/items.rs`) produces the same `alias__Name` mangled
// string `crate::modules::resolve` gives the struct once its own file is
// flattened in, the checker's flat, name-keyed `self.structs`/`self.methods`
// tables (`src/types/mod.rs`) and codegen's flat `alias__Name__method`
// symbol emission (`src/codegen/mod.rs`) require no changes at all -- so
// these tests exercise the parser's mangling directly, then prove the whole
// pipeline end to end (resolve -> check -> codegen -> real clang-compiled
// runtime), including the exact "split one struct's methods across two
// files" shape that motivated this item.

/// A bare qualified inherent impl (`impl geo::Point:`) mangles its type name
/// exactly like a qualified type annotation would, and records no trait.
#[test]
fn parses_qualified_impl_type_as_mangled_name() {
    let src = "import \"lib.star\" as geo\nimpl geo::Point:\n    fn dist(self) -> i32:\n        return 0\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Impl(blk) = &module.items[1] else { panic!("expected impl item, got {:?}", module.items[1]) };
    assert_eq!(blk.type_name, "geo__Point");
    assert_eq!(blk.trait_name, None);
    assert_eq!(blk.methods.len(), 1);
    assert_eq!(blk.methods[0].sig.name, "dist");
}

/// `impl Trait for alias::Type:` mangles only the type side -- a *local*
/// trait implemented for an *imported* type.
#[test]
fn parses_local_trait_for_qualified_type_mangles_only_type_name() {
    let src = "trait Describable:\n    fn describe(self) -> i32\n\nimport \"lib.star\" as geo\nimpl Describable for geo::Point:\n    fn describe(self) -> i32:\n        return 1\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Impl(blk) = &module.items[2] else { panic!("expected impl item, got {:?}", module.items[2]) };
    assert_eq!(blk.trait_name, Some("Describable".to_string()));
    assert_eq!(blk.type_name, "geo__Point");
}

/// `impl alias::Trait for Type:` mangles only the trait side -- an
/// *imported* trait implemented for a *local* type.
#[test]
fn parses_qualified_trait_for_local_type_mangles_only_trait_name() {
    let src = "struct Dog:\n    volume: i32\n\nimport \"lib.star\" as geo\nimpl geo::Describable for Dog:\n    fn describe(self) -> i32:\n        return 1\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Impl(blk) = &module.items[2] else { panic!("expected impl item, got {:?}", module.items[2]) };
    assert_eq!(blk.trait_name, Some("geo__Describable".to_string()));
    assert_eq!(blk.type_name, "Dog");
}

/// `impl alias::Trait for alias::Type:` mangles both sides independently.
#[test]
fn parses_qualified_trait_for_qualified_type_mangles_both_names() {
    let src = "import \"lib.star\" as geo\nimpl geo::Describable for geo::Point:\n    fn describe(self) -> i32:\n        return 1\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Impl(blk) = &module.items[1] else { panic!("expected impl item, got {:?}", module.items[1]) };
    assert_eq!(blk.trait_name, Some("geo__Describable".to_string()));
    assert_eq!(blk.type_name, "geo__Point");
}

/// A 3-segment qualified impl target (`b::c::Point`, reaching through a
/// re-exported nested import) chains `mangle_name` the same way the
/// qualified-type-annotation form does -- `parse_impl_qualified_name`'s own
/// loop, not `parse_type_inner`'s.
#[test]
fn parses_transitive_qualified_impl_type_as_chained_mangled_name() {
    let src = "import \"lib.star\" as b\nimpl b::c::Point:\n    fn dist(self) -> i32:\n        return 0\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Impl(blk) = &module.items[1] else { panic!("expected impl item, got {:?}", module.items[1]) };
    assert_eq!(blk.type_name, "b__c__Point");
}

/// A qualified generic impl target (`impl geo::Box<T>:`) mangles the base
/// name and still parses the trailing `<T, ...>` type-parameter list, same
/// as the unqualified generic-impl form.
#[test]
fn parses_qualified_generic_impl_type_params() {
    let src = "import \"lib.star\" as geo\nimpl geo::Box<T>:\n    fn get(self) -> i32:\n        return 0\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Impl(blk) = &module.items[1] else { panic!("expected impl item, got {:?}", module.items[1]) };
    assert_eq!(blk.type_name, "geo__Box");
    assert_eq!(blk.type_params.len(), 1);
    assert_eq!(blk.type_params[0].name, "T");
}

/// Using `::` after an identifier that was never declared as an import
/// alias must still be a clean parse diagnostic (mirroring the original
/// "expected ':', found '::'" bug report), not a panic -- an undeclared
/// name in front of `::` is simply not recognized as a qualified path (same
/// as the pre-existing behavior for expressions/types), so the parser falls
/// through to expecting the impl block's `:` and reports exactly that.
#[test]
fn parse_error_impl_qualified_type_with_undeclared_alias_is_clean_diagnostic() {
    let src = "impl nomod::Point:\n    fn dist(self) -> i32:\n        return 0\n";
    let err = Driver::parse(src).expect_err("an impl target qualified by an undeclared alias should fail to parse");
    assert!(!err.is_empty());
}

/// Resolving an import whose file defines a struct, then adding a method to
/// that struct via a qualified `impl` block in the *importing* file, must
/// type-check and codegen cleanly end to end -- the core scenario this item
/// was about: a method defined in a different file than the struct itself.
#[test]
fn resolve_cross_module_impl_adds_method_to_imported_struct() {
    let dir = test_scratch_dir("resolve_cross_module_impl_adds_method_to_imported_struct");
    write_test_file(&dir, "lib.star", "struct Point:\n    x: i32\n    y: i32\n");
    let main_path = write_test_file(
        &dir,
        "main.star",
        "import \"lib.star\" as geo\nimpl geo::Point:\n    fn sum(self) -> i32:\n        return self.x + self.y\n\nfn main() -> i32:\n    let p = geo::Point(3, 4)\n    return p.sum()\n",
    );
    let module = Driver::parse(&std::fs::read_to_string(&main_path).unwrap()).expect("should parse");
    let (resolved, _files) = star::modules::resolve(module, &main_path).expect("should resolve imports");

    assert!(resolved.items.iter().any(|i| matches!(i, Item::Impl(b) if b.type_name == "geo__Point")));
    let typed = Driver::check(&resolved).expect("resolved module should type-check");
    Driver::codegen(&typed).expect("resolved module should codegen");
    let _ = std::fs::remove_dir_all(&dir);
}

/// An `impl` block naming an imported alias that exists, but a struct name
/// under it that was never declared there, is still a clean "undefined
/// type" checker error (not a panic or a silently-ignored impl) -- proves
/// the flat `self.structs.contains_key` lookup in `Checker::check` really
/// does see through the mangled name to catch a genuine typo, not just a
/// successfully-resolved case.
#[test]
fn checker_rejects_cross_module_impl_on_undefined_imported_type() {
    let dir = test_scratch_dir("checker_rejects_cross_module_impl_on_undefined_imported_type");
    write_test_file(&dir, "lib.star", "struct Point:\n    x: i32\n    y: i32\n");
    let main_path = write_test_file(
        &dir,
        "main.star",
        "import \"lib.star\" as geo\nimpl geo::Missing:\n    fn f(self) -> i32:\n        return 0\n\nfn main():\n    return\n",
    );
    let module = Driver::parse(&std::fs::read_to_string(&main_path).unwrap()).expect("should parse");
    let (resolved, _files) = star::modules::resolve(module, &main_path).expect("should resolve imports");
    let errs = Driver::check(&resolved).expect_err("impl on an undefined imported type should be rejected");
    assert!(errs.iter().any(|d| d.message.contains("undefined type") && d.message.contains("geo__Missing")), "{:?}", errs);
    let _ = std::fs::remove_dir_all(&dir);
}

/// Runtime end-to-end: a struct's methods split across two files -- one
/// method defined alongside the struct itself, a second added later via a
/// qualified cross-module `impl` in the importing file -- both remain
/// callable on the same value, compiled and run through a real `clang`
/// invocation. This is the exact "split `cpu.star`'s ~90 opcode-handler
/// methods across several files" shape todo.md's P1 #6 cites as Nova's own
/// motivating use case.
#[test]
fn runtime_cross_module_impl_splits_struct_methods_across_two_files_end_to_end() {
    let dir = test_scratch_dir("runtime_cross_module_impl_splits_struct_methods_across_two_files_end_to_end");
    write_test_file(
        &dir,
        "shape.star",
        "struct Rect:\n    w: i32\n    h: i32\n\nimpl Rect:\n    fn area(self) -> i32:\n        return self.w * self.h\n",
    );
    let main_path = write_test_file(
        &dir,
        "main.star",
        "import \"shape.star\" as geo\nimpl geo::Rect:\n    fn perimeter(self) -> i32:\n        return 2 * (self.w + self.h)\n\nfn main():\n    let r = geo::Rect(3, 4)\n    println(f\"{r.area()} {r.perimeter()}\")\n",
    );
    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(compilation.is_ok(), "{}", compilation.render_diagnostics());
    let typed = compilation.typed.as_ref().unwrap();
    let ir = Driver::codegen(typed).expect("should codegen");

    let exe = std::env::temp_dir().join("star_test_cross_module_impl_split_methods.exe");
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
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "12 14");
    let _ = std::fs::remove_dir_all(&dir);
}

/// Runtime end-to-end: a `mut self` method added to an imported struct via a
/// qualified cross-module `impl` block actually mutates the caller's value,
/// not just a by-value copy -- proves the method's `self` receiver wiring
/// works identically whether the `impl` block lives in the struct's own
/// file or a different one.
#[test]
fn runtime_cross_module_impl_mut_self_method_mutates_struct_end_to_end() {
    let dir = test_scratch_dir("runtime_cross_module_impl_mut_self_method_mutates_struct_end_to_end");
    write_test_file(&dir, "counter.star", "struct Counter:\n    mut n: i32\n");
    let main_path = write_test_file(
        &dir,
        "main.star",
        "import \"counter.star\" as c\nimpl c::Counter:\n    fn bump(mut self) -> i32:\n        self.n = self.n + 1\n        return self.n\n\nfn main():\n    let mut counter = c::Counter(0)\n    counter.bump()\n    counter.bump()\n    println(f\"{counter.bump()}\")\n",
    );
    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(compilation.is_ok(), "{}", compilation.render_diagnostics());
    let typed = compilation.typed.as_ref().unwrap();
    let ir = Driver::codegen(typed).expect("should codegen");

    let exe = std::env::temp_dir().join("star_test_cross_module_impl_mut_self.exe");
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
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "3");
    let _ = std::fs::remove_dir_all(&dir);
}

/// Runtime end-to-end: a trait declared in the importing file, implemented
/// for an *imported* struct via a qualified `impl LocalTrait for alias::
/// Type:` block, correctly satisfies a generic function's trait bound and
/// dispatches to the right method -- proves cross-module `impl` interacts
/// correctly with this language's nominal nothing-changes-in-the-checker
/// trait-bound machinery (`Checker::check_impl_satisfies_trait`), not just
/// plain inherent methods.
#[test]
fn runtime_cross_module_trait_impl_for_imported_type_satisfies_generic_bound_end_to_end() {
    let dir = test_scratch_dir("runtime_cross_module_trait_impl_for_imported_type_satisfies_generic_bound_end_to_end");
    write_test_file(&dir, "animals.star", "struct Dog:\n    volume: i32\n");
    let main_path = write_test_file(
        &dir,
        "main.star",
        "import \"animals.star\" as zoo\ntrait Speaker:\n    fn speak(self) -> i32\n\nimpl Speaker for zoo::Dog:\n    fn speak(self) -> i32:\n        return self.volume\n\nfn announce<T: Speaker>(x: T) -> i32:\n    return x.speak()\n\nfn main():\n    println(f\"{announce(zoo::Dog(7))}\")\n",
    );
    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(compilation.is_ok(), "{}", compilation.render_diagnostics());
    let typed = compilation.typed.as_ref().unwrap();
    let ir = Driver::codegen(typed).expect("should codegen");

    let exe = std::env::temp_dir().join("star_test_cross_module_trait_impl.exe");
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
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "7");
    let _ = std::fs::remove_dir_all(&dir);
}

/// Runtime end-to-end: a qualified impl target reached through a
/// re-exported *nested* import (`impl mid::base::Base:`, mangling
/// transitively to `mid__base__Base`, the same name `crate::modules::
/// resolve` gives the struct after flattening `mid.star` -- which itself
/// imported `base.star` -- into `main.star`) still resolves, type-checks,
/// codegens, and runs correctly.
#[test]
fn runtime_transitive_qualified_impl_through_nested_import_end_to_end() {
    let dir = test_scratch_dir("runtime_transitive_qualified_impl_through_nested_import_end_to_end");
    write_test_file(&dir, "base.star", "struct Base:\n    n: i32\n");
    write_test_file(&dir, "mid.star", "import \"base.star\" as base\nfn make_base(n: i32) -> base::Base:\n    return base::Base(n)\n");
    let main_path = write_test_file(
        &dir,
        "main.star",
        "import \"mid.star\" as mid\nimpl mid::base::Base:\n    fn doubled(self) -> i32:\n        return self.n * 2\n\nfn main():\n    let b = mid::make_base(5)\n    println(f\"{b.doubled()}\")\n",
    );
    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(compilation.is_ok(), "{}", compilation.render_diagnostics());
    let typed = compilation.typed.as_ref().unwrap();
    let ir = Driver::codegen(typed).expect("should codegen");

    let exe = std::env::temp_dir().join("star_test_transitive_qualified_impl.exe");
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
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "10");
    let _ = std::fs::remove_dir_all(&dir);
}

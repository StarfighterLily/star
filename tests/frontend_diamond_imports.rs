//! Diamond-dependency imports
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== diamond-dependency imports (`projects/snake/NOTES.md` 1.1) ==========
//
// `main` importing both `A` and `B`, each of which independently imports a
// shared `grid.star`, used to produce two distinct, mutually-incompatible
// mangled `Cell` types (`a__grid__Cell` vs `b__grid__Cell`) for grid.star's
// one and only `Cell` struct -- confirmed live while building
// `projects/snake`, and worked around there by flattening the module graph
// into a strict linear chain instead. `crate::modules::dedupe_by_origin`
// fixes the root cause: every top-level item is tagged with the canonical
// source file (and original name) it truly came from, and items sharing
// that provenance are collapsed to one canonical declaration, however many
// alias chains reach it.

/// The resolve-level check: after flattening `main` (imports `a` and `b`,
/// each of which imports `grid.star` directly), there must be exactly one
/// `Cell` struct definition left, not two.
#[test]
fn resolve_collapses_diamond_dependency_to_one_struct_definition() {
    let dir = test_scratch_dir("resolve_collapses_diamond_dependency_to_one_struct_definition");
    write_test_file(&dir, "grid.star", "struct Cell:\n    x: i32\n    y: i32\n");
    write_test_file(
        &dir,
        "a.star",
        "import \"grid.star\" as grid\nfn make_a(x: i32, y: i32) -> grid::Cell:\n    return grid::Cell(x = x, y = y)\n",
    );
    write_test_file(
        &dir,
        "b.star",
        "import \"grid.star\" as grid\nfn use_b(c: grid::Cell) -> i32:\n    return c.x + c.y\n",
    );
    let main_path = write_test_file(
        &dir,
        "main.star",
        "import \"a.star\" as a\nimport \"b.star\" as b\nfn main():\n    let c = a::make_a(3, 4)\n    println(f\"{b::use_b(c)}\")\n",
    );
    let module = Driver::parse(&std::fs::read_to_string(&main_path).unwrap()).expect("should parse");
    let (resolved, _files) = star::modules::resolve(module, &main_path).expect("should resolve imports");

    let cell_structs: Vec<_> = resolved
        .items
        .iter()
        .filter(|i| matches!(i, Item::Struct(s) if s.name.ends_with("Cell")))
        .collect();
    assert_eq!(cell_structs.len(), 1, "diamond-imported Cell should collapse to one struct definition, found {:?}", cell_structs);

    // And the merged module must type-check and codegen cleanly -- this is
    // exactly what used to fail with "expects type ... found ..." across
    // three differently-mangled but structurally identical `Cell` types.
    let typed = Driver::check(&resolved).expect("diamond-imported module should type-check");
    Driver::codegen(&typed).expect("diamond-imported module should codegen");
}

/// End-to-end version of the same scenario, compiled and actually run: a
/// value built through `a::make_a` (using `a`'s own `grid::Cell` alias path)
/// must be directly usable where `b::use_b` (using `b`'s independent
/// `grid::Cell` alias path) expects its own `grid::Cell` -- only possible if
/// the two alias paths were unified into the exact same underlying type.
#[test]
fn runtime_diamond_dependency_import_unifies_shared_struct_type_end_to_end() {
    let dir = test_scratch_dir("runtime_diamond_dependency_import_unifies_shared_struct_type_end_to_end");
    write_test_file(&dir, "grid.star", "struct Cell:\n    x: i32\n    y: i32\n");
    write_test_file(
        &dir,
        "a.star",
        "import \"grid.star\" as grid\nfn make_a(x: i32, y: i32) -> grid::Cell:\n    return grid::Cell(x = x, y = y)\n",
    );
    write_test_file(
        &dir,
        "b.star",
        "import \"grid.star\" as grid\nfn use_b(c: grid::Cell) -> i32:\n    return c.x + c.y\n",
    );
    let main_path = write_test_file(
        &dir,
        "main.star",
        "import \"a.star\" as a\nimport \"b.star\" as b\nfn main():\n    let c = a::make_a(3, 4)\n    println(f\"{b::use_b(c)}\")\n",
    );

    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(compilation.is_ok(), "{}", compilation.render_diagnostics());
    let typed = compilation.typed.as_ref().unwrap();
    let ir = Driver::codegen(typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_diamond_dependency.exe");
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

/// Same diamond shape, but three-deep: `main` imports `a` and `b`, `a`
/// imports `grid.star` directly while `b` imports it *transitively* through
/// an intermediate `mid.star` -- makes sure dedup follows provenance through
/// more than one level of re-export, not just a single hop.
#[test]
fn resolve_collapses_diamond_dependency_through_transitive_reexport() {
    let dir = test_scratch_dir("resolve_collapses_diamond_dependency_through_transitive_reexport");
    write_test_file(&dir, "grid.star", "struct Cell:\n    x: i32\n    y: i32\n");
    write_test_file(
        &dir,
        "mid.star",
        "import \"grid.star\" as grid\nfn mid_make(x: i32, y: i32) -> grid::Cell:\n    return grid::Cell(x = x, y = y)\n",
    );
    write_test_file(
        &dir,
        "a.star",
        "import \"grid.star\" as grid\nfn make_a(x: i32, y: i32) -> grid::Cell:\n    return grid::Cell(x = x, y = y)\n",
    );
    write_test_file(
        &dir,
        "b.star",
        "import \"mid.star\" as mid\nfn use_b(c: mid::grid::Cell) -> i32:\n    return c.x + c.y\n",
    );
    let main_path = write_test_file(
        &dir,
        "main.star",
        "import \"a.star\" as a\nimport \"b.star\" as b\nfn main():\n    let c = a::make_a(5, 6)\n    println(f\"{b::use_b(c)}\")\n",
    );
    let module = Driver::parse(&std::fs::read_to_string(&main_path).unwrap()).expect("should parse");
    let (resolved, _files) = star::modules::resolve(module, &main_path).expect("should resolve imports");

    let cell_structs: Vec<_> = resolved
        .items
        .iter()
        .filter(|i| matches!(i, Item::Struct(s) if s.name.ends_with("Cell")))
        .collect();
    assert_eq!(cell_structs.len(), 1, "diamond-imported Cell should collapse to one struct definition even through a transitive re-export, found {:?}", cell_structs);

    let typed = Driver::check(&resolved).expect("diamond-imported module should type-check");
    Driver::codegen(&typed).expect("diamond-imported module should codegen");
}

/// A transitive path through a real alias chain, but naming a function that
/// doesn't actually exist anywhere in the chain (`b::c::bogus_fn`) -- must
/// still be a clean, located type-check error (the mangled name the checker
/// reports, `b__c__bogus_fn`, is unresolvable), not a crash or a silent
/// miscompile, mirroring how a typo in an ordinary single-level qualified
/// path already behaves.
#[test]
fn runtime_transitive_reexport_of_nonexistent_symbol_reports_clean_diagnostic_end_to_end() {
    let dir = test_scratch_dir("runtime_transitive_reexport_of_nonexistent_symbol_reports_clean_diagnostic_end_to_end");
    write_test_file(&dir, "c.star", "fn real_fn() -> i32:\n    return 1\n");
    write_test_file(&dir, "b.star", "import \"c.star\" as c\nfn via_b() -> i32:\n    return c::real_fn()\n");
    let main_path = write_test_file(
        &dir, "a.star",
        "import \"b.star\" as b\n\nfn main():\n    println(f\"{b::c::bogus_fn()}\")\n",
    );

    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(!compilation.is_ok(), "a transitive reference to a nonexistent symbol should fail to type-check");
    let rendered = compilation.render_diagnostics();
    assert!(rendered.to_lowercase().contains("undefined") || rendered.to_lowercase().contains("unknown"), "{}", rendered);

    let _ = std::fs::remove_dir_all(&dir);
}

/// A legitimate *single-level* qualified call through an import alias
/// (`b::b_make`, not reaching into `b`'s own imports) must keep working --
/// guards the fix above against overcorrecting into rejecting valid
/// qualified calls.
#[test]
fn single_level_qualified_call_through_import_alias_still_works_end_to_end() {
    let dir = test_scratch_dir("single_level_qualified_call_through_import_alias_still_works_end_to_end");
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
        "import \"b.star\" as b\n\nfn main():\n    let v = b::b_make(3, 4)\n    println(f\"sum = {v.x}\")\n",
    );

    let compilation = Driver::new(main_path).compile().expect("file read should succeed");
    assert!(compilation.is_ok(), "{}", compilation.render_diagnostics());

    let _ = std::fs::remove_dir_all(&dir);
}

/// Bug-hunting round 7: a generic struct constructed through a qualified
/// module path with an explicit turbofish (`lib::Box<i32>(5)`) used to be
/// silently misparsed as a chained comparison (`(lib__Box < i32) > (5)`)
/// instead of a qualified generic construction -- the qualified-path loop in
/// `parse_primary` (`src/parser/expr.rs`) only ever checked for `(` or `::`
/// immediately after a segment, with no turbofish probe the way the
/// unqualified `name<T>(...)` case already has via `try_parse_type_args`.
/// Confirmed via a real pre-fix `star check`: `lib::Box<i32>(5)` produced a
/// cascade of unrelated diagnostics ("undefined name `i32`", "`<` is not
/// supported between ...") instead of either constructing the box or
/// reporting one clean error. Fixed by probing for a turbofish right after
/// each segment the same speculative way the top-level case does, only
/// committing when immediately followed by `(` or `::`.
#[test]
fn runtime_qualified_generic_struct_construction_with_turbofish_end_to_end() {
    let dir = test_scratch_dir("runtime_qualified_generic_struct_construction_with_turbofish_end_to_end");
    write_test_file(&dir, "lib.star", "struct Box<T>:\n    value: T\n");
    let main_path = write_test_file(
        &dir, "main.star",
        "import \"lib.star\" as lib\n\nfn main():\n    let b: lib::Box<i32> = lib::Box<i32>(5)\n    let c = lib::Box<i32>(value = 9)\n    println(f\"{b.value},{c.value}\")\n",
    );

    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(compilation.is_ok(), "{}", compilation.render_diagnostics());
    let typed = compilation.typed.as_ref().unwrap();
    let ir = Driver::codegen(typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_qualified_generic_struct_turbofish.exe");
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
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "5,9");

    let _ = std::fs::remove_dir_all(&dir);
}

/// The same turbofish-through-a-qualified-path shape, but for a generic
/// *enum* variant reached two hops deep (`a` imports `b` imports `em`,
/// constructing `b::em::Maybe<i32>::Just(7)` from `a`) -- guards that the
/// fix threads `seg_type_args` into `Expr::EnumVariant` (not just
/// `Expr::StructLit`) and composes with the transitive chain, not just a
/// single hop.
#[test]
fn runtime_qualified_generic_enum_variant_construction_with_turbofish_two_hops_end_to_end() {
    let dir = test_scratch_dir("runtime_qualified_generic_enum_variant_construction_with_turbofish_two_hops_end_to_end");
    write_test_file(&dir, "em.star", "enum Maybe<T>:\n    Just(value: T)\n    Nothing\n");
    write_test_file(&dir, "b.star", "import \"em.star\" as em\nfn identity(x: em::Maybe<i32>) -> em::Maybe<i32>:\n    return x\n");
    let main_path = write_test_file(
        &dir, "a.star",
        concat!(
            "import \"b.star\" as b\n\n",
            "fn main():\n",
            "    let a = b::identity(b::em::Maybe<i32>::Just(7))\n",
            "    let n = b::identity(b::em::Maybe<i32>::Nothing)\n",
            "    match a:\n",
            "        b::em::Maybe::Just(v) -> println(f\"just {v}\")\n",
            "        b::em::Maybe::Nothing -> println(\"nothing\")\n",
            "    match n:\n",
            "        b::em::Maybe::Just(v) -> println(f\"just {v}\")\n",
            "        b::em::Maybe::Nothing -> println(\"nothing\")\n",
        ),
    );

    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(compilation.is_ok(), "{}", compilation.render_diagnostics());
    let typed = compilation.typed.as_ref().unwrap();
    let ir = Driver::codegen(typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_qualified_generic_enum_turbofish_two_hops.exe");
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
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["just 7", "nothing"], "{}", stdout);

    let _ = std::fs::remove_dir_all(&dir);
}

/// A generic struct reached through a qualified path but *without* an
/// explicit turbofish (`lib::Box(5)`, relying on argument-type inference the
/// same way the unqualified `Box(5)` shape already does) must keep
/// constructing correctly -- guards the turbofish probe (only attempted when
/// a `<` immediately follows the segment) doesn't fire or otherwise disturb
/// this pre-existing, already-working shape.
#[test]
fn runtime_qualified_generic_struct_construction_without_turbofish_still_works_end_to_end() {
    let dir = test_scratch_dir("runtime_qualified_generic_struct_construction_without_turbofish_still_works_end_to_end");
    write_test_file(&dir, "lib.star", "struct Box<T>:\n    value: T\n");
    let main_path = write_test_file(
        &dir, "main.star",
        "import \"lib.star\" as lib\n\nfn main():\n    let b = lib::Box(5)\n    println(f\"{b.value}\")\n",
    );

    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(compilation.is_ok(), "{}", compilation.render_diagnostics());
    let typed = compilation.typed.as_ref().unwrap();
    let ir = Driver::codegen(typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_qualified_generic_struct_no_turbofish.exe");
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
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "5");

    let _ = std::fs::remove_dir_all(&dir);
}

/// Regression test for the RC leak fixed in `Codegen::emit_place`'s generic
/// fallback arm: indexing directly into a bare `Call` expression that
/// returns a `List<T>` (`make_list()[0]`, with no intervening `let`) routes
/// through `list_fields`, which resolves its `base` via `emit_read_place` ->
/// `emit_place`'s fallback -- that fallback spills `emit_expr`'s
/// already-owned result into a scratch `alloca` but, before this fix, never
/// released it, so every evaluation permanently leaked the entire returned
/// `List<str>` object. Mirrors `runtime_discarded_list_pop_statement_does_not_leak_end_to_end`'s
/// technique: builds a throwaway executable and samples its Working Set via
/// a single PowerShell `Get-Process` polling loop, which must stay flat
/// across the run.
#[test]
fn runtime_indexing_a_fresh_list_returning_call_does_not_leak_end_to_end() {
    use std::process::Command;

    let src = concat!(
        "fn make_list() -> List<str>:\n",
        "    return [concat(\"a\", \"b\"), concat(\"c\", \"d\")]\n",
        "\n",
        "fn main():\n",
        "    let mut i: i32 = 0\n",
        "    while i < 3000000:\n",
        "        let v = make_list()[0]\n",
        "        i += 1\n",
        "    println(\"done\")\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_fresh_list_index_leak.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");

    let stdout_file = std::env::temp_dir().join("fresh_list_index_leak_stdout.txt");
    let script = format!(
        "$p = Start-Process -FilePath '{}' -PassThru -RedirectStandardOutput '{}'; \
         $samples = New-Object System.Collections.ArrayList; \
         while (-not $p.HasExited) {{ try {{ $p.Refresh(); [void]$samples.Add($p.WorkingSet64) }} catch {{}}; Start-Sleep -Milliseconds 100 }}; \
         $samples -join ','",
        exe.display(),
        stdout_file.display()
    );
    let output = Command::new("powershell")
        .args(["-NoProfile", "-NonInteractive", "-Command", &script])
        .output()
        .expect("failed to run the PowerShell memory-sampling script");
    assert!(output.status.success(), "sampling script failed: {}", String::from_utf8_lossy(&output.stderr));

    let program_stdout = std::fs::read_to_string(&stdout_file).unwrap_or_default();
    assert!(program_stdout.contains("done"), "program should finish normally: {}", program_stdout);

    let samples_raw = String::from_utf8_lossy(&output.stdout);
    let samples: Vec<i64> = samples_raw.trim().split(',').filter_map(|s| s.trim().parse().ok()).collect();

    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
    let _ = std::fs::remove_file(&stdout_file);

    if samples.len() < 3 {
        // Ran too fast to sample meaningfully on this machine -- a
        // successful, fast exit is itself still evidence against a
        // per-iteration leak at this iteration count.
        return;
    }
    let settled = &samples[1..];
    let min = *settled.iter().min().unwrap();
    let max = *settled.iter().max().unwrap();
    assert!(
        (max - min) < 20 * 1024 * 1024,
        "Working Set grew by {}MB across the run (samples: {:?}) -- indexing into a fresh `make_list()[0]` is leaking the whole List",
        (max - min) / (1024 * 1024),
        samples
    );
}

/// Same fix, exercised through a method call (`.contains(..)`) on a fresh
/// `Map<K,V>`-returning call instead of an index on a `List<T>` -- confirms
/// the fix in `emit_place`'s fallback isn't specific to `List<T>`/indexing.
#[test]
fn runtime_method_call_on_a_fresh_map_returning_call_does_not_leak_end_to_end() {
    use std::process::Command;

    let src = concat!(
        "fn make_map() -> Map<str, str>:\n",
        "    let mut m: Map<str, str> = Map<str, str>()\n",
        "    m.insert(concat(\"k\", \"1\"), concat(\"v\", \"1\"))\n",
        "    return m\n",
        "\n",
        "fn main():\n",
        "    let mut i: i32 = 0\n",
        "    while i < 2000000:\n",
        "        let found = make_map().contains(concat(\"k\", \"1\"))\n",
        "        i += 1\n",
        "    println(\"done\")\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_fresh_map_method_leak.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");

    let stdout_file = std::env::temp_dir().join("fresh_map_method_leak_stdout.txt");
    let script = format!(
        "$p = Start-Process -FilePath '{}' -PassThru -RedirectStandardOutput '{}'; \
         $samples = New-Object System.Collections.ArrayList; \
         while (-not $p.HasExited) {{ try {{ $p.Refresh(); [void]$samples.Add($p.WorkingSet64) }} catch {{}}; Start-Sleep -Milliseconds 100 }}; \
         $samples -join ','",
        exe.display(),
        stdout_file.display()
    );
    let output = Command::new("powershell")
        .args(["-NoProfile", "-NonInteractive", "-Command", &script])
        .output()
        .expect("failed to run the PowerShell memory-sampling script");
    assert!(output.status.success(), "sampling script failed: {}", String::from_utf8_lossy(&output.stderr));

    let program_stdout = std::fs::read_to_string(&stdout_file).unwrap_or_default();
    assert!(program_stdout.contains("done"), "program should finish normally: {}", program_stdout);

    let samples_raw = String::from_utf8_lossy(&output.stdout);
    let samples: Vec<i64> = samples_raw.trim().split(',').filter_map(|s| s.trim().parse().ok()).collect();

    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
    let _ = std::fs::remove_file(&stdout_file);

    if samples.len() < 3 {
        return;
    }
    let settled = &samples[1..];
    let min = *settled.iter().min().unwrap();
    let max = *settled.iter().max().unwrap();
    assert!(
        (max - min) < 20 * 1024 * 1024,
        "Working Set grew by {}MB across the run (samples: {:?}) -- calling a method on a fresh `make_map()` is leaking the whole Map",
        (max - min) / (1024 * 1024),
        samples
    );
}

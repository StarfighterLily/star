//! Bug-hunting round: lexer/CRLF, phi merges, enum payload sizing, list COW, sequence hoisting, mut enforcement, self-less methods, match-pattern typing, undefined types
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Bug-hunting round: lexer/CRLF, phi merges, enum payload sizing, ===
// ===== list COW-on-read, sequence hoisting, mut enforcement, ============
// ===== self-less methods, match-pattern typing, undefined types ==========

/// `Lexer::handle_line_start`'s blank-line detection only recognized `\n`/`#`
/// at the first non-whitespace byte of a line -- a CRLF blank line (just
/// `\r\n`, no leading spaces) lands on `\r` instead, so it fell through to
/// the indentation branch and (since its measured width is 0) popped every
/// open indent level, injecting spurious `Dedent`/`Indent` tokens in the
/// middle of an otherwise-contiguous block with no diagnostic at all.
#[test]
fn lexer_treats_crlf_blank_line_as_blank_not_dedent_boundary() {
    let src = "struct P:\r\n    health: i32\r\n\r\n    speed: i32\r\n";
    let tokens = Driver::lex(src).expect("lexing should succeed");
    let indents = tokens.iter().filter(|t| t.kind == TokenKind::Indent).count();
    let dedents = tokens.iter().filter(|t| t.kind == TokenKind::Dedent).count();
    assert_eq!(indents, 1, "a CRLF blank line must not open a spurious second indent level");
    assert_eq!(dedents, 1, "a CRLF blank line must not close the block early");
}

/// End-to-end repro of the same bug through the parser: a blank CRLF line
/// inside a nested `if` block used to corrupt the token stream badly enough
/// that the trailing statement was left dangling at module scope, reported
/// as "expected a top-level item" pointing at ordinary statement text.
#[test]
fn parses_program_with_crlf_blank_line_inside_nested_block() {
    let src = "fn main():\r\n    if true:\r\n        println(\"a\")\r\n\r\n        println(\"b\")\r\n";
    let result = Driver::parse(src);
    assert!(result.is_ok(), "a CRLF blank line inside a nested block must not corrupt parsing: {:?}", result.err());
}

/// `emit_logical_binop`'s `phi` merge hardcoded the `rhs` operand's *entry*
/// label (`logic_rhs_N`) as its incoming block -- correct only if `rhs`
/// itself opens no further basic blocks. A `list[i]` bounds check on the
/// right-hand side of `&&` opens its own internal blocks, so the real
/// predecessor falling through to `logic_end` is whichever block
/// `current_label` names after `rhs` is evaluated, not `logic_rhs_N` --
/// previously this produced invalid LLVM IR ("PHI node entries do not match
/// predecessors"), rejected by `clang`.
#[test]
fn runtime_logical_and_with_list_index_rhs_end_to_end() {
    let src = "fn compute(cond: bool, nums: List<i32>) -> bool:\n    return cond && nums[0] > 0\n\nfn main():\n    let mut nums = List<i32>()\n    nums.push(5)\n    println(f\"{compute(true, nums)}\")\n    println(f\"{compute(false, nums)}\")\n";
    let output = compile_and_run("logical_and_list_index_rhs", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "false"], "{}", stdout);
}

/// Same bug, `||` with a nested `&&` (itself opening its own `phi`) as the
/// right-hand operand -- two levels of the same stale-label bug stacked.
#[test]
fn runtime_logical_or_with_nested_and_rhs_end_to_end() {
    let src = "fn compute(a: bool, b: bool, c: bool) -> bool:\n    return a || (b && c)\n\nfn main():\n    println(f\"{compute(false, true, true)}\")\n    println(f\"{compute(false, true, false)}\")\n    println(f\"{compute(true, false, false)}\")\n";
    let output = compile_and_run("logical_or_nested_and_rhs", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "false", "true"], "{}", stdout);
}

/// `enum_payload_words` naively summed each variant's field sizes with no
/// inter-field alignment padding, unlike `type_size`'s `Ty::Named` (struct)
/// case -- but construction/destructuring bitcasts the same `[W x i64]`
/// buffer to the variant's real, alignment-padded LLVM struct type. A
/// variant mixing sub-8-byte fields with an 8-byte-aligned one (`bool`,
/// `str`, `bool`) needs 24 padded bytes but was only allocated 16, so
/// writing the trailing field silently overran the buffer into whatever
/// followed it in memory.
#[test]
fn runtime_enum_payload_with_mixed_alignment_fields_does_not_corrupt_adjacent_field_end_to_end() {
    let src = "enum Msg:\n    Triple(a: bool, b: str, c: bool)\n    None\n\nstruct Wrapper:\n    mut m: Msg\n    mut canary: i32\n\nfn main():\n    let mut w = Wrapper(m = Msg::None, canary = 305419896)\n    w.m = Msg::Triple(true, \"hello\", false)\n    println(f\"{w.canary}\")\n";
    let output = compile_and_run("enum_payload_mixed_alignment", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "305419896", "constructing the payload variant must not corrupt the adjacent `canary` field: {}", stdout);
}

/// Same bug, a 16-byte-aligned `Vec3` payload field -- exceeds the
/// `[W x i64]` array's 8-byte-per-element granularity entirely, so this
/// reproduces the undersizing even more directly than the `bool`/`str`/`bool`
/// case above.
#[test]
fn runtime_enum_payload_with_vec3_field_does_not_corrupt_adjacent_field_end_to_end() {
    let src = "enum Shape:\n    Ball(flag: bool, pos: Vec3)\n    None\n\nstruct Wrapper:\n    mut s: Shape\n    mut canary: i32\n\nfn main():\n    let mut w = Wrapper(s = Shape::None, canary = 305419896)\n    w.s = Shape::Ball(true, Vec3(1.0, 2.0, 3.0))\n    println(f\"{w.canary}\")\n";
    let output = compile_and_run("enum_payload_vec3_alignment", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "305419896", "constructing the payload variant must not corrupt the adjacent `canary` field: {}", stdout);
}

/// `type_align` hardcoded alignment 8 for *every* `Ty::Enum`, but a
/// fieldless enum lowers to a bare `i32` (align 4, see `llvm_ty`) -- only a
/// payload enum is the actual 8-byte-aligned tagged union. Reflect metadata
/// offsets computed with the wrong alignment over-pad any field following a
/// fieldless enum whenever the running offset isn't already 8-aligned.
#[test]
fn codegen_reflect_offset_correct_after_fieldless_enum_field() {
    let src = "enum Color:\n    Red\n    Green\n    Blue\n\nstruct Player:\n    flag: bool = true\n    color: Color = Color::Red\n    @export tag: i32 = 0\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("%Player = type { i1, i32, i32 }"), "{}", ir);
    assert!(ir.contains("tag:8:i32:export"), "a fieldless enum field aligns to 4, so `tag` should land at offset 8 (i1 padded to 4, plus color's own 4 bytes), not 12: {}", ir);
}

/// A field read off a `List<T>`-of-structs element (`points[0].x`) used to
/// route through `Codegen::emit_place`'s `ListIndex` arm -- a write-only
/// path that unconditionally clones/un-aliases the list via
/// `emit_list_ensure_unique` -- as a side effect of a plain read. Same bug
/// class as the already-fixed `list_fields`/`list_index_read_obj` split for
/// scalar/nested-list-element reads, just for a struct-element field
/// projection instead.
#[test]
fn codegen_list_of_structs_field_read_does_not_trigger_cow_clone() {
    let module = Driver::parse("struct Point:\n    x: i32\n    y: i32\nfn t(points: List<Point>) -> i32:\n    points[0].x\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i32 @t(");
    assert!(!fn_ir.contains("list_cow_clone"), "a pure struct-field read must not clone/unshare the list: {}", fn_ir);
}

/// Same shape, but a *write* through a chained field (`points[0].x = 5`)
/// still must run the copy-on-write gate -- a regression guard alongside the
/// read-side fix above so it doesn't overcorrect into skipping a real
/// mutation's uniqueness check.
#[test]
fn codegen_list_of_structs_field_write_still_triggers_cow_clone() {
    let module = Driver::parse("struct Point:\n    mut x: i32\n    mut y: i32\nfn t(mut points: List<Point>):\n    points[0].x = 5\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("list_cow_clone"), "a struct-field write must still uniquify the list before mutating: {}", ir);
}

/// Functional regression guard: reading a field off a `List<T>`-of-structs
/// element must still produce the correct value (not just "doesn't clone").
#[test]
fn runtime_list_of_structs_field_read_end_to_end() {
    let src = "struct Point:\n    x: i32\n    y: i32\nfn main():\n    let points: List<Point> = [Point(1, 2), Point(3, 4)]\n    println(f\"{points[0].x}, {points[1].y}\")\n";
    let output = compile_and_run("list_of_structs_field_read", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "1, 4", "{}", stdout);
}

/// `sequence`'s hoisted-name rewrite (`rewrite_expr`'s `Expr::Ident` arm)
/// had no lexical hygiene at all: a `for` loop's own induction variable
/// sharing a name with a hoisted field got rewritten to `self.<name>`
/// throughout the loop body just like any other reference to that name,
/// so the loop variable itself became unreachable/dead and every use inside
/// the loop silently read the stale, unrelated outer field instead.
#[test]
fn runtime_sequence_for_loop_var_shadowing_hoisted_field_end_to_end() {
    let src = "sequence Counter(mut i: i32, mut total: i32):\n    for i in 0..3:\n        total = total + i\n    yield\n\nfn main():\n    let mut t = Counter(100, 0)\n    t.resume()\n    println(f\"{t.total}\")\n";
    let output = compile_and_run("sequence_for_var_shadowing", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "3", "the for-loop's own `i` (0+1+2=3) must shadow the hoisted `i` field (100), not be rewritten to it: {}", stdout);
}

/// Same shadowing-hygiene bug, a `match` binding pattern (`Pattern::Binding`)
/// that shares a name with a hoisted field -- the arm's own binding must
/// win, not the outer `self.<name>`.
#[test]
fn runtime_sequence_match_binding_shadowing_hoisted_field_end_to_end() {
    let src = "sequence Counter(mut n: i32, mut total: i32):\n    match n:\n        n ->\n            total = n + 1\n    yield\n\nfn main():\n    let mut t = Counter(41, 0)\n    t.resume()\n    println(f\"{t.total}\")\n";
    let output = compile_and_run("sequence_match_binding_shadowing", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "42", "the match arm's own bound `n` must shadow the hoisted `n` field: {}", stdout);
}

// --- `crate::modules`'s import-mangling rename pass had the same shadowing-
// hygiene bug as `crate::sequence`'s hoisting rewrite above, just never
// fixed: `rename_expr`'s `Expr::Ident` arm mangled *every* identifier
// matching one of the imported file's top-level declaration names on pure
// text, regardless of whether it actually referred to that declaration or to
// a same-named local (parameter, `let`, loop variable, match binding,
// closure parameter) currently shadowing it. Unlike the struct/enum-name
// collision the old doc comment dismissed as "not a concern in practice"
// (PascalCase types can't collide with snake_case locals), a top-level
// *function*/const/arena name shares the exact same snake_case convention as
// an ordinary parameter or local, so this was a real, silently-reachable
// miscompile, not just a theoretical gap -- confirmed via a real pre-fix
// `star check` producing `` `+` is not supported between `Closure([], Int)`
// and `Int` `` for the `helper`/`compute` case below instead of type-checking
// and running at all. Each test below is end to end through a real
// `clang`-compiled executable, covering every kind of local binding
// `rename_*` had to learn to track: a parameter, a `let`, a `for` loop
// variable, a `match` binding, and a lambda parameter -- plus one regression
// guard confirming a *genuine* (non-shadowed) reference to the top-level
// declaration is still correctly mangled, so the fix doesn't overcorrect into
// never mangling anything.

/// The original repro: `lib.star` declares a top-level `fn helper() -> i32`
/// and, separately, `fn compute(helper: i32) -> i32: return helper + 1` --
/// `compute`'s own parameter is named `helper`, shadowing the unrelated
/// top-level function of the same name for the extent of `compute`'s body.
#[test]
fn runtime_imported_fn_param_shadowing_top_level_fn_name_end_to_end() {
    let dir = test_scratch_dir("runtime_imported_fn_param_shadowing_top_level_fn_name_end_to_end");
    write_test_file(
        &dir, "lib.star",
        "fn helper() -> i32:\n    return 1\n\nfn compute(helper: i32) -> i32:\n    return helper + 1\n",
    );
    let main_path = write_test_file(
        &dir, "main.star",
        "import \"lib.star\" as lib\nfn main():\n    println(f\"{lib::compute(5)}\")\n",
    );

    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(compilation.is_ok(), "{}", compilation.render_diagnostics());
    let typed = compilation.typed.as_ref().unwrap();
    let ir = Driver::codegen(typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_imported_fn_param_shadowing.exe");
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
    assert_eq!(
        String::from_utf8_lossy(&output.stdout).trim_end(),
        "6",
        "compute(5)'s own `helper` parameter must shadow the unrelated top-level `helper` function, not get rewritten to `lib__helper`"
    );

    let _ = std::fs::remove_dir_all(&dir);
}

/// Same bug, a `let` binding: `via_let` shadows a top-level `count() -> i32`
/// function with a same-named local.
#[test]
fn runtime_imported_let_shadowing_top_level_fn_name_end_to_end() {
    let dir = test_scratch_dir("runtime_imported_let_shadowing_top_level_fn_name_end_to_end");
    write_test_file(
        &dir, "lib.star",
        "fn count() -> i32:\n    return 100\n\nfn via_let() -> i32:\n    let count = 5\n    return count + 1\n",
    );
    let main_path = write_test_file(
        &dir, "main.star",
        "import \"lib.star\" as lib\nfn main():\n    println(f\"{lib::via_let()}\")\n",
    );

    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(compilation.is_ok(), "{}", compilation.render_diagnostics());
    let typed = compilation.typed.as_ref().unwrap();
    let ir = Driver::codegen(typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_imported_let_shadowing.exe");
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
    assert_eq!(
        String::from_utf8_lossy(&output.stdout).trim_end(),
        "6",
        "the local `let count = 5` must shadow the unrelated top-level `count()` function"
    );

    let _ = std::fs::remove_dir_all(&dir);
}

/// Same bug, a `for` loop's own induction variable shadowing a top-level
/// function name.
#[test]
fn runtime_imported_for_loop_var_shadowing_top_level_fn_name_end_to_end() {
    let dir = test_scratch_dir("runtime_imported_for_loop_var_shadowing_top_level_fn_name_end_to_end");
    write_test_file(
        &dir, "lib.star",
        "fn count() -> i32:\n    return 100\n\nfn via_for() -> i32:\n    let mut total = 0\n    for count in 0..3:\n        total = total + count\n    return total\n",
    );
    let main_path = write_test_file(
        &dir, "main.star",
        "import \"lib.star\" as lib\nfn main():\n    println(f\"{lib::via_for()}\")\n",
    );

    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(compilation.is_ok(), "{}", compilation.render_diagnostics());
    let typed = compilation.typed.as_ref().unwrap();
    let ir = Driver::codegen(typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_imported_for_loop_var_shadowing.exe");
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
    assert_eq!(
        String::from_utf8_lossy(&output.stdout).trim_end(),
        "3",
        "the for-loop's own `count` (0+1+2=3) must shadow the unrelated top-level `count()` function"
    );

    let _ = std::fs::remove_dir_all(&dir);
}

/// Same bug, a `match` arm's `Pattern::Binding` shadowing a top-level
/// function name.
#[test]
fn runtime_imported_match_binding_shadowing_top_level_fn_name_end_to_end() {
    let dir = test_scratch_dir("runtime_imported_match_binding_shadowing_top_level_fn_name_end_to_end");
    write_test_file(
        &dir, "lib.star",
        "fn count() -> i32:\n    return 100\n\nfn via_match(x: i32) -> i32:\n    match x:\n        count -> count + 1\n",
    );
    let main_path = write_test_file(
        &dir, "main.star",
        "import \"lib.star\" as lib\nfn main():\n    println(f\"{lib::via_match(9)}\")\n",
    );

    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(compilation.is_ok(), "{}", compilation.render_diagnostics());
    let typed = compilation.typed.as_ref().unwrap();
    let ir = Driver::codegen(typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_imported_match_binding_shadowing.exe");
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
    assert_eq!(
        String::from_utf8_lossy(&output.stdout).trim_end(),
        "10",
        "the match arm's own bound `count` must shadow the unrelated top-level `count()` function"
    );

    let _ = std::fs::remove_dir_all(&dir);
}

/// Same bug, a lambda's own parameter shadowing a top-level function name.
#[test]
fn runtime_imported_lambda_param_shadowing_top_level_fn_name_end_to_end() {
    let dir = test_scratch_dir("runtime_imported_lambda_param_shadowing_top_level_fn_name_end_to_end");
    write_test_file(
        &dir, "lib.star",
        "fn count() -> i32:\n    return 100\n\nfn via_lambda() -> i32:\n    let f = fn(count: i32) -> i32:\n        return count * 2\n    return f(4)\n",
    );
    let main_path = write_test_file(
        &dir, "main.star",
        "import \"lib.star\" as lib\nfn main():\n    println(f\"{lib::via_lambda()}\")\n",
    );

    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(compilation.is_ok(), "{}", compilation.render_diagnostics());
    let typed = compilation.typed.as_ref().unwrap();
    let ir = Driver::codegen(typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_imported_lambda_param_shadowing.exe");
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
    assert_eq!(
        String::from_utf8_lossy(&output.stdout).trim_end(),
        "8",
        "the lambda's own `count` parameter must shadow the unrelated top-level `count()` function"
    );

    let _ = std::fs::remove_dir_all(&dir);
}

/// Regression guard against overcorrecting: a genuine, non-shadowed reference
/// to a top-level function from another function in the same imported module
/// must still be mangled and resolve correctly, not accidentally left
/// referring to the wrong (unmangled, and therefore undefined post-import)
/// name.
#[test]
fn runtime_imported_fn_reference_still_mangled_when_not_shadowed_end_to_end() {
    let dir = test_scratch_dir("runtime_imported_fn_reference_still_mangled_when_not_shadowed_end_to_end");
    write_test_file(
        &dir, "lib.star",
        "fn count() -> i32:\n    return 100\n\nfn real_reference() -> i32:\n    return count() + 1\n",
    );
    let main_path = write_test_file(
        &dir, "main.star",
        "import \"lib.star\" as lib\nfn main():\n    println(f\"{lib::real_reference()}\")\n",
    );

    let compilation = Driver::new(&main_path).compile().expect("file read should succeed");
    assert!(compilation.is_ok(), "{}", compilation.render_diagnostics());
    let typed = compilation.typed.as_ref().unwrap();
    let ir = Driver::codegen(typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_imported_fn_reference_still_mangled.exe");
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
    assert_eq!(
        String::from_utf8_lossy(&output.stdout).trim_end(),
        "101",
        "a genuine (non-shadowed) reference to the top-level `count()` function must still resolve correctly"
    );

    let _ = std::fs::remove_dir_all(&dir);
}

/// `sequence.rs`'s `check_no_nested_yield` only recognized statement-form
/// control flow (`Stmt::If`/`While`/`Frame`/`For`) -- a `match` used as a
/// statement is `Stmt::Expr(Expr::Match{..})`, so a `yield` nested inside a
/// match arm slipped past this dedicated check entirely and was only caught
/// later by the generic type-checker fallback, with a strictly worse,
/// unrelated-sounding diagnostic.
#[test]
fn rejects_yield_nested_inside_match_arm_in_sequence() {
    let src = "sequence S(mut n: i32):\n    match n:\n        0 ->\n            yield\n        _ ->\n            n = n + 1\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("yield nested inside a match arm must be rejected") };
    assert!(
        errs.iter().any(|d| d.message.contains("only supported at the top level")),
        "expected sequence.rs's own dedicated nested-yield diagnostic, got: {:?}", errs
    );
}

/// `tcp_connect`'s `inet_addr` result was never checked against its
/// `INADDR_NONE` (`0xFFFFFFFF`, i.e. `-1` as `i32`) failure sentinel before
/// being stored into the `sockaddr_in` and handed to `connect()`.
#[test]
fn codegen_tcp_connect_checks_inet_addr_invalid_sentinel() {
    let module = Driver::parse("fn t(host: str, port: i32) -> ptr:\n    tcp_connect(host, port)\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("call i32 @inet_addr"), "{}", ir);
    assert!(ir.contains("icmp eq i32") && ir.contains(", -1"), "inet_addr's INADDR_NONE sentinel should be checked: {}", ir);
    assert!(ir.contains("tcp_addr_invalid"), "a dedicated failure path for an invalid address should exist: {}", ir);
}

/// A typo'd/undeclared type name in a parameter position previously
/// resolved to a blind `Ty::Named(name.clone())` with no lookup against
/// `self.structs` at all -- `resolve_field_type` then treats that bogus
/// named type as "already reported elsewhere" and silently widens to the
/// `unknown` placeholder, masking what should be a clean diagnostic here.
#[test]
fn rejects_undefined_type_name_in_param_position() {
    let src = "fn heal(p: Play):\n    println(\"x\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("an undeclared type name must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("undefined type `Play`")), "{:?}", errs);
}

/// Same check, with a real struct close enough to trigger the "did you
/// mean" suggestion path (mirrors `check_impl`'s existing undefined-type
/// suggestion for `impl Foo for Bar`).
#[test]
fn rejects_undefined_type_name_with_suggestion() {
    let src = "struct Player:\n    health: i32\nfn heal(p: Playr):\n    println(\"x\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("an undeclared type name must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("undefined type `Playr`")), "{:?}", errs);
    assert!(errs.iter().any(|d| d.note.as_deref().is_some_and(|n| n.contains("Player"))), "expected a \"did you mean `Player`?\" note: {:?}", errs);
}

/// `Pattern::Int`/`Pattern::Bool`/`Pattern::Compare` were never checked
/// against the scrutinee's type -- only their *coverage* was validated.
/// Codegen's match-arm lowering hardcodes `icmp eq i32`/`icmp sle i32` for
/// these regardless of the scrutinee's real LLVM type, so a mismatch here
/// previously type-checked cleanly and only failed at the opaque `clang` IR
/// verifier step.
#[test]
fn rejects_int_pattern_against_non_int_scrutinee() {
    let src = "fn f(s: str) -> i32:\n    match s:\n        5 -> 1\n        _ -> 0\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("an int pattern against a str scrutinee must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("does not match scrutinee type")), "{:?}", errs);
}

#[test]
fn rejects_bool_pattern_against_non_bool_scrutinee() {
    let src = "fn f(n: i32) -> i32:\n    match n:\n        true -> 1\n        _ -> 0\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("a bool pattern against an int scrutinee must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("does not match scrutinee type")), "{:?}", errs);
}

#[test]
fn rejects_compare_pattern_against_non_int_scrutinee() {
    let src = "fn f(s: str) -> i32:\n    match s:\n        <= 5 -> 1\n        _ -> 0\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("a comparison pattern against a non-int scrutinee must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("requires an integer scrutinee")), "{:?}", errs);
}

/// Sanity/no-false-positive guard alongside the three rejection tests above.
#[test]
fn accepts_int_and_compare_patterns_against_int_scrutinee() {
    let src = "fn f(n: i32) -> i32:\n    match n:\n        0 -> 1\n        <= 5 -> 2\n        _ -> 3\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "int/compare patterns against an int scrutinee should type-check cleanly");
}

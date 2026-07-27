//! `List<T>` / arrays / collections basics
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Arrays/Lists/Collections (`List<T>`) Tests ==========================

/// A non-empty list literal `[e1, e2, ...]` parses to `Expr::ListLit`.
#[test]
fn parses_list_literal() {
    let src = "fn t():\n    let x = [1, 2, 3]\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected Let") };
    let Expr::ListLit(elems, _) = value else { panic!("expected ListLit, got {:?}", value) };
    assert_eq!(elems.len(), 3);
}

/// `List<T>()` parses like any other generic-turbofish constructor call,
/// as an ordinary `Expr::StructLit` naming `List` (see
/// `Checker::infer_list_new` for how the checker special-cases it).
#[test]
fn parses_empty_list_construction() {
    let src = "fn t():\n    let x = List<i32>()\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected Let") };
    let Expr::StructLit { name, type_args, args, .. } = value else { panic!("expected StructLit, got {:?}", value) };
    assert_eq!(name, "List");
    assert_eq!(type_args, &vec![Type::Named("i32".into())]);
    assert!(args.is_empty());
}

/// `list[idx]` parses to the shared bracket-index AST node (also used for
/// `GenRef<T>` dereferencing); the checker tells them apart later.
#[test]
fn parses_list_index() {
    let src = "fn t(nums: List<i32>) -> i32:\n    nums[0]\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected fn") };
    assert!(matches!(f.body.stmts[0], Stmt::Expr(Expr::GenRefIndex { .. })));
}

/// A non-empty list literal's element type is inferred from its elements.
#[test]
fn checks_list_literal_infers_element_type() {
    let ty = typed_fn_result_ty("fn t() -> List<i32>:\n    [1, 2, 3]\n");
    assert_eq!(ty, Ty::List(Box::new(Ty::Int)));
}

/// `list[idx]` resolves to the list's element type.
#[test]
fn checks_list_index_returns_elem_type() {
    let ty = typed_fn_result_ty("fn t(nums: List<i32>) -> i32:\n    nums[0]\n");
    assert_eq!(ty, Ty::Int);
}

/// `list.len()` always resolves to `i32`, regardless of element type.
#[test]
fn checks_list_len_returns_int() {
    let ty = typed_fn_result_ty("fn t(nums: List<f32>) -> i32:\n    nums.len()\n");
    assert_eq!(ty, Ty::Int);
}

/// `list.pop()` resolves to the list's element type.
#[test]
fn checks_list_pop_returns_elem_type() {
    let ty = typed_fn_result_ty("fn t(mut nums: List<i32>) -> i32:\n    nums.pop()\n");
    assert_eq!(ty, Ty::Int);
}

/// `List<T>` is usable as an ordinary struct field type, and a method call
/// through a field access (`inv.items.len()`) resolves correctly.
#[test]
fn checks_list_as_struct_field_type() {
    let src = "struct Inventory:\n    items: List<i32>\n\nfn t(inv: Inventory) -> i32:\n    inv.items.len()\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "List<T> should be usable as a struct field type");
}

/// An empty list literal `[]` has no element to infer a type from and is
/// rejected -- `List<T>()` is the empty-list spelling instead.
#[test]
fn rejects_empty_list_literal() {
    let module = Driver::parse("fn t():\n    let x = []\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "an empty list literal should be a type error");
}

/// A list literal whose elements don't all share the same type is rejected.
#[test]
fn rejects_mismatched_list_literal_element_types() {
    let module = Driver::parse("fn t():\n    let x = [1, \"two\"]\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "mismatched list literal element types should be a type error");
}

/// `List()` with no `<T>` turbofish has nothing to infer an element type
/// from and is rejected.
#[test]
fn rejects_list_new_without_type_arg() {
    let module = Driver::parse("fn t():\n    let x = List()\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "`List()` with no type argument should be a type error");
}

/// `push` requires exactly one argument matching the list's element type.
#[test]
fn rejects_list_push_wrong_type() {
    let module = Driver::parse("fn t(mut nums: List<i32>):\n    nums.push(\"oops\")\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "pushing a mismatched type should be a type error");
}

/// An unrecognized method name on a `List<T>` receiver is a type error
/// (rather than, say, silently resolving to nothing).
#[test]
fn rejects_unknown_list_method() {
    let module = Driver::parse("fn t(nums: List<i32>):\n    nums.sort()\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "an unknown List<T> method should be a type error");
}

/// `[..]` indexing requires a `GenRef<T>` or `List<T>` base; indexing a
/// plain scalar is a type error.
#[test]
fn rejects_indexing_non_indexable_type() {
    let module = Driver::parse("fn t(x: i32):\n    x[0]\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "indexing a non-List/GenRef type should be a type error");
}

/// A `par`/`swarm` body that calls a mutating `List<T>` method (`push`) on
/// a list captured from the enclosing scope is rejected: the mutation can't
/// be proven disjoint across worker threads (mirrors
/// `rejects_par_mutating_captured_var`).
#[test]
fn rejects_par_pushing_captured_list() {
    let src = format!(
        "{}fn t():\n    let mut nums: List<i32> = [1, 2, 3]\n    par e in Enemies:\n        nums.push(e.hp)\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "pushing a captured list inside a par/swarm body should be a type error");
}

/// `len()` only reads, so calling it on a captured list inside a
/// `par`/`swarm` body is fine (unlike `push`/`pop` above).
#[test]
fn accepts_par_len_on_captured_list() {
    let src = format!(
        "{}fn t():\n    let nums: List<i32> = [1, 2, 3]\n    par e in Enemies:\n        e.hp -= nums.len()\n",
        PAR_SRC_PREFIX
    );
    let module = Driver::parse(&src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "reading a captured list's len() should be allowed");
}

/// `List<T>()` (the empty list) lowers to `null` -- no allocation needed
/// up front; a real, uniquely-owned empty object is only lazily allocated
/// by the copy-on-write gate the first time the list is actually mutated.
#[test]
fn codegen_list_new_is_null() {
    let module = Driver::parse("fn t() -> List<i32>:\n    List<i32>()\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("ret i8* null"), "{}", ir);
}

/// A non-empty list literal `malloc`s a tightly-sized buffer and stores
/// each element into it via GEP.
#[test]
fn codegen_list_literal_allocates_and_stores() {
    let module = Driver::parse("fn t() -> List<i32>:\n    [1, 2, 3]\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    // The element size is asked of LLVM itself at codegen time (`getelementptr
    // i32, i32* null, i32 1` + `ptrtoint`) rather than baked in as a Rust-side
    // constant -- see `Codegen::emit_sizeof_llvm_ty`'s doc comment (a
    // Rust-side estimate previously undersized any struct element type
    // needing internal padding, silently overflowing this buffer).
    assert!(ir.contains("getelementptr i32, i32* null, i32 1"), "element size should be computed via LLVM's own sizeof idiom: {}", ir);
    assert!(ir.contains("ptrtoint i32* ") && ir.contains(" to i64"), "{}", ir);
    assert!(ir.contains("call i8* @malloc(i64 "), "{}", ir);
    assert!(ir.contains("store i32 1,") && ir.contains("store i32 2,") && ir.contains("store i32 3,"), "{}", ir);
}

/// `push` growing past capacity copies the old buffer into a new, larger
/// one (`memcpy`) and frees the old one, rather than leaking it.
#[test]
fn codegen_list_push_grows_and_copies_old_buffer() {
    let src = "fn t():\n    let mut nums: List<i32> = List<i32>()\n    nums.push(1)\n    nums.push(2)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("icmp sge i64"), "push must check len >= cap before growing: {}", ir);
    assert!(ir.contains("call i8* @memcpy("), "growing a non-empty list should copy its old contents: {}", ir);
    assert!(ir.contains("call void @free("), "the old buffer should be freed after copying: {}", ir);
}

/// `list[idx]` (read) is bounds-checked via an unsigned compare against the
/// list's `len`, phi-merging the element's zero value on the OOB path
/// (mirrors `emit_genref_index`'s stale/OOB handling).
#[test]
fn codegen_list_index_read_is_bounds_checked() {
    let module = Driver::parse("fn t(nums: List<i32>) -> i32:\n    nums[0]\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("icmp ult i64"), "{}", ir);
    assert!(ir.contains("phi i32 ["), "{}", ir);
}

/// `list[idx] = v` (write) is bounds-checked too; an out-of-bounds write is
/// a silent no-op rather than writing out of bounds.
#[test]
fn codegen_list_index_write_is_bounds_checked() {
    let module = Driver::parse("fn t(mut nums: List<i32>):\n    nums[0] = 5\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("icmp ult i64"), "{}", ir);
    assert!(ir.contains("list_set_do"), "{}", ir);
}

/// A *nested* list-index read (`m[0][1]`, where `m`'s own element type is
/// itself a `List<T>`) must not trigger the copy-on-write uniqueness gate
/// on `m` -- `list_fields` (the read path) previously resolved a
/// `ListIndex` base through `Codegen::emit_place`, whose `ListIndex` arm
/// exists for *writes* and unconditionally runs `emit_list_ensure_unique`
/// (identifiable by the `list_cow_clone` block it emits) before returning a
/// pointer, silently cloning and un-aliasing `m` from any other variable
/// sharing its buffer as a side effect of a plain read. Fixed by resolving
/// the inner object through a dedicated, retain-free, COW-free read path
/// (`Codegen::list_index_read_obj`) instead.
#[test]
fn codegen_nested_list_index_read_does_not_trigger_cow_clone() {
    let module = Driver::parse("fn t(nums: List<List<i32>>) -> i32:\n    nums[0][1]\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i32 @t(");
    assert!(!fn_ir.contains("list_cow_clone"), "a pure nested read must not clone/unshare the outer list: {}", fn_ir);
}

/// Same nested shape, but a *write* (`m[0][1] = 5`) still must run the
/// copy-on-write gate on the outer list -- a regression guard alongside
/// `codegen_nested_list_index_read_does_not_trigger_cow_clone` so the read
/// fix above doesn't overcorrect into skipping the uniqueness check a real
/// mutation still needs.
#[test]
fn codegen_nested_list_index_write_still_triggers_cow_clone() {
    let module = Driver::parse("fn t(mut nums: List<List<i32>>):\n    nums[0][1] = 5\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("list_cow_clone"), "a nested write must still uniquify the outer list before mutating: {}", ir);
}

/// A nested list-index read (`m[i][j]`) on a `List<List<i32>>` must still
/// produce correct values end to end -- a functional regression guard for
/// the `list_fields`/`list_fields_from_obj`/`list_index_read_obj` split
/// introduced to fix the unwanted-COW-clone-on-read bug above. Also
/// exercises the out-of-bounds path on both index levels (zero value, not a
/// crash), mirroring `emit_list_index`'s established OOB convention.
#[test]
fn runtime_nested_list_index_read_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let m: List<List<i32>> = [[1, 2], [3, 4, 5]]\n",
        "    println(f\"{m[0][1]}\")\n",
        "    println(f\"{m[1][2]}\")\n",
        "    println(f\"{m[0][99]}\")\n",
        "    println(f\"{m[99][0]}\")\n",
    );
    let output = compile_and_run("nested_list_index_read", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["2", "5", "0", "0"], "{}", stdout);
}

/// A pure nested read (`n[0][1]`) must not un-alias two variables sharing
/// the same outer list's buffer -- a subsequent mutation through *either*
/// alias must still behave exactly as plain copy-on-write semantics
/// predict (mutating one never affects the other), regardless of whether a
/// read happened first. This can't distinguish "never cloned" from
/// "clone­d-then-still-correctly-isolated" by final values alone (both are
/// observably identical, which is precisely why the bug was invisible from
/// program output) -- `codegen_nested_list_index_read_does_not_trigger_cow_clone`
/// is what actually pins the fix; this is a functional companion guarding
/// against a botched fix breaking ordinary COW isolation.
#[test]
fn runtime_nested_list_read_then_mutate_preserves_cow_isolation_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let mut m: List<List<i32>> = [[1, 2]]\n",
        "    let n = m\n",
        "    let x = n[0][1]\n",
        "    m[0].push(99)\n",
        "    println(f\"x={x} m0len={m[0].len()} n0len={n[0].len()}\")\n",
    );
    let output = compile_and_run("nested_list_read_then_mutate", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "x=2 m0len=3 n0len=2", "{}", stdout);
}

/// `len()` truncates the internal `i64` length counter down to the
/// language's `i32` int type.
#[test]
fn codegen_list_len_truncates_to_i32() {
    let module = Driver::parse("fn t(nums: List<i32>) -> i32:\n    nums.len()\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("trunc i64"), "{}", ir);
}

/// Runtime test: `examples/lists.exe` exercises `List<T>` end to end
/// through a real clang-compiled executable -- a non-empty list literal,
/// `push`/`pop`/`len`, indexed read and write, passing a list by value into
/// a function, capacity growth past the initial buffer, `List<String>`,
/// `List<Point>` (a struct element type), and the "safe zero value" fallback
/// for out-of-bounds reads/pops on an empty list.
#[test]
fn runtime_lists_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/lists.exe").output().expect("failed to execute lists.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("initial len = 3"), "list literal: {}", stdout);
    assert!(stdout.contains("after push len = 5"), "push: {}", stdout);
    assert!(stdout.contains("nums[0] = 1"), "{}", stdout);
    assert!(stdout.contains("nums[4] = 5"), "{}", stdout);
    assert!(stdout.contains("nums[0] after set = 100"), "indexed write: {}", stdout);
    assert!(stdout.contains("popped = 5"), "pop: {}", stdout);
    assert!(stdout.contains("len after pop = 4"), "{}", stdout);
    assert!(stdout.contains("sum via function = 109"), "list passed by value into a function: {}", stdout);
    assert!(stdout.contains("empty len = 0"), "{}", stdout);
    assert!(stdout.contains("pop from empty = 0"), "OOB pop yields the zero value: {}", stdout);
    assert!(stdout.contains("index oob = 0"), "OOB read yields the zero value: {}", stdout);
    assert!(stdout.contains("grown len = 20"), "repeated push grows capacity past the initial buffer: {}", stdout);
    assert!(stdout.contains("grown[19] = 19"), "{}", stdout);
    assert!(stdout.contains("grown[0] = 0"), "{}", stdout);
    assert!(stdout.contains("words len = 3"), "List<String>: {}", stdout);
    assert!(stdout.contains("words[1] = beta"), "{}", stdout);
    assert!(stdout.contains("points[1] = (3, 4)"), "List<Point> (struct element type): {}", stdout);
}

// ===== match-statement label uniqueness (found while testing Map/Set) =====

/// A function containing more than one `match` (of two or more arms each)
/// previously corrupted the emitted IR: `TypedExpr::Match`'s per-arm
/// `then`/`next` block labels (`codegen/expr.rs`) were named only by the
/// arm's index (`match_then_0`, `match_next_0`, ...) with no uniqueness
/// suffix, so a *second* `match` statement in the same function reused the
/// exact same label text as the first, producing "Terminator found in the
/// middle of a basic block!" once LLVM's parser saw two logically distinct
/// blocks sharing one name. Two ordinary matches in one function is enough
/// to trigger it, with no `Map`/`Set` involved at all -- this is a codegen
/// bug found incidentally while writing `examples/map_set.star` (which has
/// several `match` statements in `main()`), not specific to those types.
#[test]
fn codegen_multiple_matches_in_one_function_use_distinct_block_labels() {
    let src = "fn main():\n    let a = 5\n    match a:\n        1 -> println(\"one\")\n        _ -> println(\"other\")\n    let b = 7\n    match b:\n        1 -> println(\"one-b\")\n        _ -> println(\"other-b\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    // Every `match_then_0_<N>:` label *definition* line must be distinct --
    // previously both matches' first arm reused the identical
    // `match_then_0` label with no uniqueness suffix at all, which LLVM's
    // parser rejects as a terminator appearing mid-block once the two
    // same-named blocks' instructions get concatenated (see this test
    // section's own doc comment above).
    let then_0_labels: std::collections::HashSet<&str> = ir
        .lines()
        .filter_map(|l| l.trim().strip_suffix(':'))
        .filter(|l| l.starts_with("match_then_0_"))
        .collect();
    assert_eq!(then_0_labels.len(), 2, "expected two distinct `match_then_0_*` labels (one per match statement), found {:?} in:\n{}", then_0_labels, ir);
}

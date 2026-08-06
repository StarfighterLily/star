//! Regression: reading an RC-bearing element out of a `List<T>` (`list[i]`)
//! or through a `GenRef<T>` (`gen_ref[i]`), where `T` is a `struct`/`enum`
//! containing a `str` (or other RC-bearing) field, previously produced
//! malformed LLVM IR and made `star build` fail outright.
//!
//! Found while porting `projects/nova/NoBASIC`'s parser to Star
//! (`todo.md` P0 #2): `parser_dump.star`'s `dump_expr`/`dump_stmt` read
//! `a.exprs[id]`/`a.stmts[id]` (a `List<Expr>`/`List<Stmt>`, each wrapping
//! a payload-carrying `enum` with `str` fields) and then `match`ed on the
//! result's `.kind` -- `star build` failed with "internal compiler error:
//! malformed LLVM IR emitted ... `phi` ... lists incoming blocks
//! [list_idx_ok_N, list_idx_oob_N] but the actual predecessors are
//! [enum_rc_next_N, list_idx_oob_N]". Root cause:
//! `Codegen::emit_list_index`/`Codegen::emit_genref_index`
//! (`src/codegen/list.rs`/`src/codegen/arena.rs`) each captured their own
//! `ok_label` block-name *before* calling `emit_retain_at` on the freshly
//! loaded element, then reused that same captured name as the `phi`'s
//! predecessor for that edge once execution reached the shared `end_label`.
//! But `emit_retain_at` is not a straight-line call when the element type
//! is RC-bearing and payload-carrying: retaining an `enum`'s active variant
//! requires checking its tag at runtime, which opens its own conditional
//! block(s) (`enum_rc_variant_N`/`enum_rc_next_N`) -- so the block that
//! actually falls through to `br label %end_label` is whichever one
//! `emit_retain_at` left current, not the original `ok_label`, and the
//! `phi`'s declared predecessor silently went stale. A non-RC element type
//! (`i32`, ...) never tripped this, since `emit_retain_at` is a no-op for
//! those and never opens a block -- which is why this went unnoticed until
//! a real `List<Struct-with-str-field>` was indexed and matched on.
//! `MapMethod::Get` (`src/codegen/map.rs`) already did this correctly
//! (captures `self.current_label.clone()` *after* its own `emit_retain_at`
//! call, right before branching to its `end_label`) -- both fixes just
//! apply that same already-established pattern.
//!
//! Shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

/// `list[i]` where the element is a `struct` wrapping a payload-carrying
/// `enum` with a `str` field, immediately `match`ed on -- the exact shape
/// `parser_dump.star`'s AST-arena walk hit first. Must actually run (not
/// just compile) and read back the right variant/field for both a
/// str-carrying and a bare variant, matching against a fixed index (not
/// just index 0) so the fix isn't accidentally validated by a
/// bounds-check path that never takes the in-range branch.
#[test]
fn list_index_of_struct_with_str_enum_field_end_to_end() {
    let src = "\
enum Kind:
    Named(name: str)
    Bare

struct Node:
    kind: Kind

fn describe(nodes: List<Node>, id: i32) -> str:
    let n = nodes[id]
    match n.kind:
        Kind::Named(name) -> concat(\"named:\", name)
        Kind::Bare -> \"bare\"

fn main():
    let mut nodes: List<Node> = List<Node>()
    nodes.push(Node(kind = Kind::Named(name = \"alpha\")))
    nodes.push(Node(kind = Kind::Bare))
    nodes.push(Node(kind = Kind::Named(name = \"gamma\")))
    println(describe(nodes, 0))
    println(describe(nodes, 1))
    println(describe(nodes, 2))
";
    let output = compile_and_run("list_index_rc_retain_phi", src);
    assert!(output.status.success(), "compiled binary should run cleanly: {:?}", output);
    let stdout = String::from_utf8_lossy(&output.stdout).replace("\r\n", "\n");
    assert_eq!(stdout, "named:alpha\nbare\nnamed:gamma\n", "reading each list element and matching its enum payload must round-trip correctly: {stdout:?}");
}

/// Same hazard through a `GenRef<T>` arena dereference (`gen_ref[0]`)
/// instead of `List<T>` indexing -- `emit_genref_index` had the identical
/// stale-`ok_label` bug, fixed the same way.
#[test]
fn genref_index_of_struct_with_str_enum_field_end_to_end() {
    let src = "\
enum Kind:
    Named(name: str)
    Bare

struct Node:
    kind: Kind

arena Nodes: Node

fn main():
    spawn Nodes(Kind::Named(name = \"hello\"))
    spawn Nodes(Kind::Bare)
    let r0: GenRef<Node> = GenRef<Node>(0)
    let r1: GenRef<Node> = GenRef<Node>(1)
    match r0[0].kind:
        Kind::Named(name) -> println(concat(\"named:\", name))
        Kind::Bare -> println(\"bare\")
    match r1[0].kind:
        Kind::Named(name) -> println(concat(\"named:\", name))
        Kind::Bare -> println(\"bare\")
";
    let output = compile_and_run("genref_index_rc_retain_phi", src);
    assert!(output.status.success(), "compiled binary should run cleanly: {:?}", output);
    let stdout = String::from_utf8_lossy(&output.stdout).replace("\r\n", "\n");
    assert_eq!(stdout, "named:hello\nbare\n", "dereferencing each GenRef and matching its enum payload must round-trip correctly: {stdout:?}");
}

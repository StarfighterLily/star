//! Collections bugfix round: List COW-on-read, Map/Set refcount leaks, ctor arg validation, while/else CFG, f-string leaks/escaping, par/swarm closure hazard, frame-escape projections
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Bug-fix round: List's own `list_fields` COW-on-read gap =============

/// `List<T>`'s equivalent of `codegen_map_method_on_field_behind_list_index_does_not_trigger_cow_clone`:
/// a `List` reached through a *struct field* behind a list index
/// (`players[0].scores.len()`) must not clone/un-share the *outer* list --
/// `list_fields` (`crate::codegen::list`) only special-cased `base` itself
/// being a direct `ListIndex`, not a `Field` wrapping one, so this exact
/// shape still fell into `emit_place`'s write path (which unconditionally
/// runs `emit_list_ensure_unique` on the outer list) even after the
/// direct-`ListIndex` case was fixed. `list_fields` now routes its fallback
/// through `Codegen::emit_read_place` (already used by `map_fields`/
/// `set_fields` for the identical reason) instead of `emit_place`.
#[test]
fn codegen_list_method_on_field_behind_list_index_does_not_trigger_cow_clone() {
    let src = "struct Player:\n    scores: List<i32>\nfn t(players: List<Player>) -> i32:\n    players[0].scores.len()\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i32 @t(");
    assert!(!fn_ir.contains("list_cow_clone"), "a List field read behind a list index must not clone/unshare the outer list: {}", fn_ir);
}

/// Regression guard alongside the read test above: a *mutation* through the
/// same nested shape (`players[0].scores.push(v)`) still must run the
/// copy-on-write gate on the outer list.
#[test]
fn codegen_list_method_on_field_behind_list_index_write_still_triggers_cow_clone() {
    let src = "struct Player:\n    mut scores: List<i32>\nfn t(mut players: List<Player>):\n    players[0].scores.push(1)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("list_cow_clone"), "a List mutation behind a list index must still uniquify the outer list: {}", ir);
}

/// Functional companion, mirroring `runtime_map_method_on_list_index_receiver_preserves_cow_isolation_end_to_end`:
/// reading a nested `List` field behind a list index must not un-alias two
/// variables sharing the same outer list's buffer, so a later mutation
/// through one is still invisible through the other.
#[test]
fn runtime_list_method_on_field_behind_list_index_preserves_cow_isolation_end_to_end() {
    let src = concat!(
        "struct Player:\n",
        "    mut scores: List<i32>\n",
        "fn main():\n",
        "    let mut m: List<Player> = [Player(scores = [1, 2])]\n",
        "    let n = m\n",
        "    let read_len = n[0].scores.len()\n",
        "    m[0].scores.push(3)\n",
        "    println(f\"read_len={read_len} m0len={m[0].scores.len()} n0len={n[0].scores.len()}\")\n",
    );
    let output = compile_and_run("list_field_list_index_read_then_mutate", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "read_len=2 m0len=3 n0len=2", "{}", stdout);
}

// ===== Bug-fix round: Map/Set key/element refcount leaks ====================

/// `Map::contains(k)` only ever compares `k` against each stored key, never
/// stores it -- so the retain `emit_expr` performs when reading an `Ident`
/// argument (see `rc.rs`'s "read of an existing owned slot" convention) must
/// be balanced back out, or every `.contains(k)` call on an RC-valued key
/// (`str`, or a struct/tuple containing one) leaked one reference. Previously
/// missing entirely.
#[test]
fn codegen_map_contains_releases_borrowed_str_key() {
    let src = "fn t(mut m: Map<str, i32>, k: str) -> bool:\n    m.contains(k)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i1 @t(");
    assert!(fn_ir.contains("call void @star_rc_release"), "Map::contains must release the borrowed key: {}", fn_ir);
}

/// Same leak, `Map::get`.
#[test]
fn codegen_map_get_releases_borrowed_str_key() {
    let src = "fn t(m: Map<str, i32>, k: str):\n    m.get(k)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("call void @star_rc_release"), "Map::get must release the borrowed key: {}", ir);
}

/// Same leak, `Map::remove` (the query key, not the stored one that's
/// released separately when the slot is torn down).
#[test]
fn codegen_map_remove_releases_borrowed_str_key() {
    let src = "fn t(mut m: Map<str, i32>, k: str):\n    m.remove(k)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("call void @star_rc_release"), "Map::remove must release the borrowed query key: {}", ir);
}

/// `Map::insert(k, v)` when `k` already exists overwrites the value in
/// place and never stores the newly-passed `k` -- so its borrowed retain
/// must be released in that branch specifically (the sibling "new key"
/// branch legitimately stores it, transferring ownership instead).
#[test]
fn codegen_map_insert_overwrite_releases_borrowed_str_key() {
    let src = "fn t(mut m: Map<str, i32>, k: str):\n    m.insert(k, 1)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    // The label `map_insert_overwrite_N` appears twice: once as a `br`
    // instruction's operand (`br i1 ..., label %map_insert_overwrite_N,
    // label %map_insert_new_M` -- which also mentions `map_insert_new_M` on
    // that same line), and once as the block's own header line a few lines
    // later. Skip past the first (br-operand) occurrence so `overwrite_start`
    // lands on the real block header, not the branch instruction that
    // mentions both labels together.
    let after_br = ir.find("map_insert_overwrite_").expect("expected a map_insert_overwrite block") + "map_insert_overwrite_".len();
    let overwrite_start = after_br + ir[after_br..].find("map_insert_overwrite_").expect("expected the map_insert_overwrite block header");
    let overwrite_end = ir[overwrite_start..].find("map_insert_new_").map(|i| overwrite_start + i).unwrap_or(ir.len());
    let overwrite_block = &ir[overwrite_start..overwrite_end];
    assert!(
        overwrite_block.contains("call void @star_rc_release"),
        "Map::insert's overwrite branch must release the discarded borrowed key: {}",
        overwrite_block
    );
}

/// `Set<T>`'s equivalent of the `Map::contains` leak above.
#[test]
fn codegen_set_contains_releases_borrowed_str_element() {
    let src = "fn t(s: Set<str>, k: str) -> bool:\n    s.contains(k)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i1 @t(");
    assert!(fn_ir.contains("call void @star_rc_release"), "Set::contains must release the borrowed element: {}", fn_ir);
}

/// `Set<T>`'s equivalent of the `Map::remove` leak above.
#[test]
fn codegen_set_remove_releases_borrowed_str_element() {
    let src = "fn t(mut s: Set<str>, k: str):\n    s.remove(k)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("call void @star_rc_release"), "Set::remove must release the borrowed query element: {}", ir);
}

/// `Set::insert(v)` when `v` is already present is a no-op that never
/// stores the newly-passed `v` -- same reasoning as `Map::insert`'s
/// overwrite branch above.
#[test]
fn codegen_set_insert_already_present_releases_borrowed_str_element() {
    let src = "fn t(mut s: Set<str>, k: str):\n    s.insert(k)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    // Same reasoning as `codegen_map_insert_overwrite_releases_borrowed_str_key`'s
    // comment above: skip past the `br` instruction's own operand mention of
    // this label so `already_start` lands on the real block header.
    let after_br = ir.find("set_insert_already_present_").expect("expected a set_insert_already_present block") + "set_insert_already_present_".len();
    let already_start = after_br + ir[after_br..].find("set_insert_already_present_").expect("expected the set_insert_already_present block header");
    let already_end = ir[already_start..].find("set_insert_do_").map(|i| already_start + i).unwrap_or(ir.len());
    let already_block = &ir[already_start..already_end];
    assert!(
        already_block.contains("call void @star_rc_release"),
        "Set::insert's already-present branch must release the discarded borrowed element: {}",
        already_block
    );
}

/// Functional companion to the codegen-shape tests above: repeatedly
/// querying/no-op-inserting a `Map<str,i32>`/`Set<str>` with a freshly
/// constructed (retained-on-read) `str` key must still report correct
/// results -- guards against a fix that silently breaks correctness (e.g.
/// releasing the wrong value, or double-releasing the actually-stored key)
/// while chasing the leak.
#[test]
fn runtime_map_set_query_methods_still_correct_after_leak_fix_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let mut m: Map<str, i32> = Map<str, i32>()\n",
        "    let k = concat(\"a\", \"b\")\n",
        "    m.insert(k, 1)\n",
        "    match m.get(k):\n",
        "        Option::Some(v) -> println(f\"contains={m.contains(k)} get={v}\")\n",
        "        Option::None -> println(f\"contains={m.contains(k)} get=none\")\n",
        "    m.insert(k, 2)\n",
        "    match m.get(k):\n",
        "        Option::Some(v) -> println(f\"after_overwrite={v}\")\n",
        "        Option::None -> println(\"after_overwrite=none\")\n",
        "    match m.remove(k):\n",
        "        Option::Some(v) -> println(f\"removed={v}\")\n",
        "        Option::None -> println(\"removed=none\")\n",
        "    println(f\"contains_after_remove={m.contains(k)}\")\n",
        "    let mut s: Set<str> = Set<str>()\n",
        "    let first_insert = s.insert(k)\n",
        "    let second_insert = s.insert(k)\n",
        "    println(f\"first_insert={first_insert} second_insert={second_insert} set_contains={s.contains(k)} set_len={s.len()}\")\n",
        "    let removed = s.remove(k)\n",
        "    println(f\"removed={removed} set_contains_after={s.contains(k)}\")\n",
    );
    let output = compile_and_run("map_set_query_methods_still_correct", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(
        lines,
        vec![
            "contains=true get=1",
            "after_overwrite=2",
            "removed=2",
            "contains_after_remove=false",
            "first_insert=true second_insert=false set_contains=true set_len=1",
            "removed=true set_contains_after=false",
        ],
        "{}",
        stdout
    );
}

// ===== Bug-fix round: struct/enum constructor argument validation ==========

/// A plain (non-generic) struct literal's argument *types* were never
/// checked against the struct's declared field types at all -- only the
/// four builtin vec/mat forms (`Vec2`/`Vec3`/`Vec4`/`Mat4`) were validated
/// (`check_builtin_ctor_arity`'s own doc comment explicitly no-op'd for
/// everything else). A swapped/wrong-typed constructor argument previously
/// type-checked cleanly and either silently miscompiled (same-width fields
/// swapped) or produced invalid LLVM IR the `clang` step alone rejected.
#[test]
fn rejects_struct_ctor_argument_of_wrong_type() {
    let src = "struct Player:\n    health: i32\n    name: str\nfn t():\n    let p = Player(\"oops\", 100)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("a struct ctor arg of the wrong type should be a type error") };
    assert!(errs.iter().any(|d| d.message.contains("Player") && d.message.contains("health")), "{:?}", errs);
}

/// The same struct's fields, swapped (two structurally different but
/// codegen-adjacent types, `str` vs `i32`) in the other position, still
/// caught.
#[test]
fn rejects_struct_ctor_with_swapped_field_types() {
    let src = concat!(
        "struct Item:\n    kind: str\n    count: i32\n",
        "fn t():\n    let it = Item(1, \"two\")\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("swapped struct ctor arg types should be a type error") };
    assert!(errs.iter().any(|d| d.message.contains("Item")), "{:?}", errs);
}

/// A plain struct literal's argument *count* was likewise never checked --
/// `Player(100, "hi", 999, 888)` (two extra arguments for a 2-field struct)
/// previously type-checked cleanly and produced out-of-bounds struct-index
/// GEPs in codegen.
#[test]
fn rejects_struct_ctor_with_too_many_arguments() {
    let src = "struct Player:\n    health: i32\n    name: str\nfn t():\n    let p = Player(100, \"hi\", 999, 888)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("a struct ctor with too many args should be a type error") };
    assert!(errs.iter().any(|d| d.message.contains("expects 2 argument")), "{:?}", errs);
}

/// The correctly-typed, correct-arity case must still type-check cleanly --
/// guards against the fix above rejecting sound code.
#[test]
fn accepts_struct_ctor_with_correct_field_types() {
    let src = "struct Player:\n    health: i32\n    name: str\nfn t():\n    let p = Player(100, \"hi\")\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "a correctly-typed struct ctor call should type-check");
}

/// A `sequence`'s desugared struct carries extra fields (hoisted locals,
/// `state`) beyond its declared parameters (see `crate::sequence`) -- its
/// constructor call is only ever expected to supply the leading parameter
/// count, not the struct's full desugared field list. Guards
/// `check_struct_ctor_args`'s `sequence_param_counts` special-case against
/// wrongly rejecting every ordinary sequence constructor call once
/// struct-ctor type-checking landed.
#[test]
fn accepts_sequence_ctor_with_only_its_declared_params() {
    let src = concat!(
        "sequence Counter(start: i32):\n",
        "    let mut n: i32 = start\n",
        "    yield\n",
        "    n = n + 1\n",
        "fn t():\n",
        "    let mut c = Counter(5)\n",
        "    c.resume()\n",
    );
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "a sequence ctor call supplying only its declared params should type-check");
}

/// A payload-carrying enum variant's argument types were likewise never
/// checked -- same gap, same fix (`check_enum_variant_ctor_args`), for
/// `EnumVariant` construction instead of `StructLit`.
#[test]
fn rejects_enum_variant_ctor_argument_of_wrong_type() {
    let src = concat!(
        "enum Shape:\n    Circle(radius: i32)\n    Label(name: str)\n",
        "fn t():\n    let s = Shape::Circle(\"nope\")\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("an enum variant ctor arg of the wrong type should be a type error") };
    assert!(errs.iter().any(|d| d.message.contains("Shape") && d.message.contains("Circle")), "{:?}", errs);
}

/// The correctly-typed case must still type-check cleanly.
#[test]
fn accepts_enum_variant_ctor_with_correct_field_types() {
    let src = "enum Shape:\n    Circle(radius: i32)\nfn t():\n    let s = Shape::Circle(5)\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "a correctly-typed enum variant ctor call should type-check");
}

// ===== Bug-fix round: `while`/`else` CFG wiring =============================

/// `while cond: ... else: ...`'s `else` clause runs once after the loop
/// exits *normally* (the condition becomes false) -- previously the
/// condition's false branch jumped straight to the loop's `end_label`,
/// entirely bypassing `else_label` (an unreachable orphan block), so the
/// `else` clause silently never ran under any circumstances.
#[test]
fn runtime_while_else_runs_after_normal_loop_exit_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let mut x = 0\n",
        "    while x < 3:\n",
        "        println(\"loop\")\n",
        "        x = x + 1\n",
        "    else:\n",
        "        println(\"else ran\")\n",
        "    println(\"after\")\n",
    );
    let output = compile_and_run("while_else_normal_exit", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["loop", "loop", "loop", "else ran", "after"], "{}", stdout);
}

/// `break`ing out of the loop must still skip the `else` clause (Python's
/// own `while`/`else` semantics, and `docs/language_reference.md`'s
/// documented behavior) -- a regression guard alongside the test above so
/// the CFG fix doesn't overcorrect into always running `else`.
#[test]
fn runtime_while_else_skipped_after_break_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let mut x = 0\n",
        "    while x < 10:\n",
        "        if x == 2:\n",
        "            break\n",
        "        println(f\"x={x}\")\n",
        "        x = x + 1\n",
        "    else:\n",
        "        println(\"else ran\")\n",
        "    println(\"after\")\n",
    );
    let output = compile_and_run("while_else_skipped_on_break", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["x=0", "x=1", "after"], "{}", stdout);
}

/// A `while`/`else` whose `else` clause itself ends in `return` must not
/// emit a trailing, unreachable `br` after that `ret` (invalid LLVM IR) --
/// the same "an already-terminated block must not get a second terminator"
/// guard `if`/`else` and the loop body already had, which the `else` clause
/// itself was missing until this fix.
#[test]
fn codegen_while_else_ending_in_return_does_not_double_terminate() {
    let src = concat!(
        "fn t(n: i32) -> i32:\n",
        "    let mut x = 0\n",
        "    while x < n:\n",
        "        x = x + 1\n",
        "    else:\n",
        "        return -1\n",
        "    return x\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i32 @t(");
    assert!(!fn_ir.contains("ret i32 -1\n  br"), "an else clause ending in `return` must not be followed by a further `br`: {}", fn_ir);
}

// ===== Bug-fix round: f-string interpolation refcount leaks =================

/// Interpolating a non-primitive RC-bearing value (`List`/`Map`/`Set`/
/// `Closure`/a struct with RC fields/a payload enum) into an f-string used
/// as an ordinary `str` value falls into a `%p` fallback that -- unlike the
/// `str`/`bool` arms right next to it -- never released the borrow
/// `emit_expr` retained on the interpolated identifier's behalf, leaking one
/// reference per interpolation.
#[test]
fn codegen_fstring_value_interpolating_list_releases_borrowed_reference() {
    let src = "fn t(lst: List<i32>) -> str:\n    f\"list is {lst}\"\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i8* @t(");
    assert!(fn_ir.contains("call void @star_rc_release"), "an f-string value interpolating a List must release the borrowed reference: {}", fn_ir);
}

/// Superseded by the format-specifier-table audit
/// (`Ty::is_fstring_unprintable`): a struct value has no defined
/// print/f-string format at all now (it used to silently fall through to
/// the `%p` catch-all, tagging an aggregate-by-value LLVM register as a
/// vararg pointer -- a C-ABI mismatch, not just a leak), so this is now a
/// clean checker diagnostic rather than IR this test used to assert
/// released the struct's borrowed `str` field correctly.
#[test]
fn checks_fstring_interpolating_struct_is_rejected() {
    let src = "struct Holder:\n    s: str\nfn t(h: Holder):\n    println(f\"holder is {h}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("f-string interpolation of a struct value should be a checker error") };
    assert!(
        diags.iter().any(|d| d.message.contains("cannot interpolate") && d.message.contains("Holder")),
        "expected a clean 'cannot interpolate' diagnostic naming the struct type, got: {:?}", diags
    );
}

// ===== Bug-fix round: f-string literal-brace escaping =======================

/// `\{`/`\}` inside an f-string's literal text previously fell through
/// `scan_escape`'s `other` arm as a bogus "unknown escape sequence" --
/// there was no way at all to spell a literal brace next to an
/// interpolation hole. Recognized now alongside `\n`/`\t`/`\"`/etc.
#[test]
fn runtime_fstring_escaped_braces_end_to_end() {
    let src = "fn main():\n    let x = 5\n    println(f\"\\{value={x}\\}\")\n";
    let output = compile_and_run("fstring_escaped_braces", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "{value=5}", "{}", stdout);
}

// ===== Bug-fix round: `par`/`swarm` closure-invocation hazard ===============

/// A closure *defined outside* a `par`/`swarm` body, itself performing a
/// `spawn` (a hazard that would be rejected if written directly inside the
/// body), then *invoked* from inside the body -- previously type-checked
/// cleanly, since `compute_unsafe_par_fns` only walks named top-level
/// `fn`/`impl` bodies (never a lambda literal's), so `unsafe_par_fns` could
/// never recognize the closure's own hazard by name, and the pre-existing
/// `rejects_closure_inside_par_body` test only ever banned *defining* a
/// closure literal inside the body, not invoking one captured from outside.
/// At runtime this would race all four worker threads on the arena's
/// `count`/`gen`/`free`/`free_top` globals -- exactly the class of bug
/// `spawn`/`despawn` are directly banned inside a par/swarm body to prevent.
#[test]
fn rejects_closure_invocation_inside_par_body() {
    let src = concat!(
        "struct P:\n    n: i32\n\n",
        "arena Arena: P\n\n",
        "fn t():\n",
        "    let f = fn():\n",
        "        spawn Arena(P(1))\n",
        "    par p in Arena:\n",
        "        f()\n",
    );
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "calling a captured closure value inside a par/swarm body should be rejected");
}

/// Calling the loop variable's own (non-closure) method must still be
/// allowed -- a regression guard alongside the test above so the fix
/// doesn't overcorrect into rejecting the ordinary, safe case
/// `rejects_closure_inside_par_body`'s sibling positive tests already cover.
#[test]
fn accepts_plain_method_call_on_loop_variable_inside_par_body() {
    let src = concat!(
        "struct P:\n    mut n: i32\n\n",
        "arena Arena: P\n\n",
        "impl P:\n    fn bump(mut self):\n        self.n += 1\n\n",
        "fn t():\n",
        "    par p in Arena:\n",
        "        p.bump()\n",
    );
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "calling the loop variable's own method inside a par/swarm body should still be allowed");
}

// ===== Bug-fix round: frame-escape check through tuple/array projections ===

/// The exact `local_structs`/`local_struct_receiver` gap: an ordinary
/// (non-`frame:`) local *tuple* whose `Ty::Named` element is used as a
/// method-call receiver that returns a closure capturing `self` by pointer,
/// then returned out of the enclosing function. `local_struct_receiver`
/// previously only chained back through `Ident`/`Field`, never
/// `TupleIndex`/`ArrayIndex`, and the tuple-typed local itself was never
/// even registered in `local_structs` (only a directly `Ty::Named`-typed
/// `let` was) -- so this exact shape sailed straight past the escape check
/// and would print/read a garbage value at runtime instead of failing to
/// compile, the same bug class `rejects_closure_capturing_plain_local_self_escaping_via_return`
/// already closed for a bare local.
#[test]
fn rejects_closure_capturing_plain_local_self_escaping_through_tuple_projection() {
    let src = r#"struct Holder:
    val: i32

impl Holder:
    fn get_closure(self) -> Fn() -> i32:
        fn(): self.val

fn make() -> Fn() -> i32:
    let h = Holder(777)
    let other = Holder(1)
    let pair = (h, other)
    return pair.0.get_closure()
"#;
    let module = Driver::parse(src).expect("should parse");
    let errs = Driver::check(&module).expect_err("a closure escaping with a tuple-projected local's self pointer should be a type error");
    assert!(errs.iter().any(|d| d.message.contains("pair")), "{:?}", errs);
}

/// The same closure, called and used entirely *within* the enclosing
/// function (never escaping via `return`), is safe -- guards against the
/// fix above overcorrecting into rejecting sound code.
#[test]
fn accepts_closure_capturing_plain_local_self_through_tuple_projection_used_locally() {
    let src = r#"struct Holder:
    val: i32

impl Holder:
    fn get_closure(self) -> Fn() -> i32:
        fn(): self.val

fn t() -> i32:
    let h = Holder(777)
    let other = Holder(1)
    let pair = (h, other)
    let c = pair.0.get_closure()
    return c()
"#;
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "using the closure entirely within the enclosing function should be allowed");
}

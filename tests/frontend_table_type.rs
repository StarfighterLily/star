//! `Table<T>` struct-of-arrays table, plus adjacent regressions (turbofish backtracking, place-projection writes, disjointness)
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Table<T> (`docs/design.md`'s Type System plan, §10's final
// ===== indie-tier gap) -- a struct-of-arrays table, lowered to a
// ===== reference-counted, copy-on-write `i8*` object pointer like
// ===== `List<T>`/`Map<K,V>`/`Set<T>`, pointing past a `star_rc_alloc` header
// ===== at a `{ i64 len, i64 cap, F0*, F1*, ... }` payload -- one parallel
// ===== growable column per field of `T`, all growing/shrinking in lockstep,
// ===== instead of `List<T>`'s single `{ T*, i64, i64 }` buffer. `T` must be a
// ===== plain declared `struct` (enforced by `Checker::resolve_type`'s own
// ===== `"Table"` branch); `Table<T>()`/method calls piggyback on the same
// ===== ordinary generic-turbofish + `StructLit` machinery `List<T>`/`Map<K,V>`/
// ===== `Set<T>` already use (unlike `Ring<T,N>`, no dedicated parser/AST node
// ===== was needed). `push`/`pop`/`len`/indexing mirror `List<T>`'s method
// ===== surface and fails-safe OOB conventions. ===============================

#[test]
fn parses_table_type_annotation() {
    let src = "struct Enemy:\n    hp: i32\n\nfn main():\n    let t: Table<Enemy> = Table<Enemy>()\n    println(f\"{t.len()}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected a fn item") };
    let Stmt::Let { ty, .. } = &f.body.stmts[0] else { panic!("expected a let stmt") };
    assert_eq!(ty.as_ref(), Some(&Type::Generic("Table".into(), vec![Type::Named("Enemy".into())])), "{:?}", ty);
}

/// `Table<T>()` is a plain `StructLit` with an empty `args` list, exactly
/// like `List<T>()`/`Map<K,V>()`/`Set<T>()` -- no dedicated AST node needed,
/// unlike `Ring<T, N>()` (whose second argument is a bare integer literal,
/// not a `Type`, so it can't piggyback on the ordinary turbofish machinery).
#[test]
fn parses_table_new_construction() {
    let src = "struct Enemy:\n    hp: i32\n\nfn main():\n    let t = Table<Enemy>()\n    println(f\"{t.len()}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[1] else { panic!("expected a fn item") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected a let stmt") };
    assert!(matches!(value, Expr::StructLit { name, args, .. } if name == "Table" && args.is_empty()), "{:?}", value);
}

/// `Table()` with no `<T>` turbofish has nothing to infer an element type
/// from and is rejected, mirroring `rejects_list_new_without_type_arg`.
#[test]
fn rejects_table_new_without_type_arg() {
    let module = Driver::parse("struct Enemy:\n    hp: i32\n\nfn t():\n    let x = Table()\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "`Table()` with no type argument should be a type error");
}

/// `Table<T>()` takes no arguments (an empty table always starts empty --
/// there's no literal form to populate it up front), mirroring
/// `List<T>()`/`Map<K,V>()`/`Set<T>()`.
#[test]
fn rejects_table_new_with_arguments() {
    let module = Driver::parse("struct Enemy:\n    hp: i32\n\nfn t():\n    let x = Table<Enemy>(1)\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "`Table<T>(1)` should be a type error -- it takes no arguments");
}

/// `T` must be a plain declared struct -- there are no fields to reflect a
/// column layout out of a primitive, so `Table<i32>` is rejected.
#[test]
fn rejects_table_of_non_struct_element() {
    let module = Driver::parse("fn t():\n    let x = Table<i32>()\n").expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("`Table<i32>()` should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("Table<T>") && d.message.contains("struct")), "{:?}", diags);
}

#[test]
fn rejects_table_push_on_non_mut_receiver() {
    let module = Driver::parse("struct Enemy:\n    hp: i32\n\nfn t(e: Table<Enemy>):\n    e.push(Enemy(hp = 1))\n").expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("push on a non-mut Table should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("not declared `mut`")), "{:?}", diags);
}

#[test]
fn rejects_table_pop_on_non_mut_receiver() {
    let module = Driver::parse("struct Enemy:\n    hp: i32\n\nfn t(e: Table<Enemy>):\n    e.pop()\n").expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("pop on a non-mut Table should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("not declared `mut`")), "{:?}", diags);
}

#[test]
fn accepts_table_push_pop_on_mut_receiver() {
    let module = Driver::parse("struct Enemy:\n    hp: i32\n\nfn t(mut e: Table<Enemy>):\n    e.push(Enemy(hp = 1))\n    e.pop()\n").expect("should parse");
    assert!(Driver::check(&module).is_ok(), "push/pop on a `mut` Table should type-check cleanly");
}

#[test]
fn rejects_assignment_to_table_index_without_mut() {
    let src = "struct Enemy:\n    hp: i32\n\nfn main():\n    let e = Table<Enemy>()\n    e[0] = Enemy(hp = 1)\n    println(f\"{e[0].hp}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("assigning into a table element through a non-`mut` binding must be rejected") };
    assert!(errs.iter().any(|d| d.message.contains("not declared `mut`")), "{:?}", errs);
}

/// `Table<T>` has no hashing/equality story (like `List<T>`/`Ring<T,N>`), so
/// it's rejected as a `Map`/`Set` key/element type -- mirrors
/// `rejects_ring_as_map_key`.
#[test]
fn rejects_table_as_map_key() {
    let module = Driver::parse("struct Enemy:\n    hp: i32\n\nfn t():\n    let m = Map<Table<Enemy>, i32>()\n").expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("Table<T> as a Map key should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("cannot be used as a")), "{:?}", diags);
}

/// `Codegen::llvm_ty` lowers `Ty::Table` to a bare `i8*` object pointer, the
/// same reference-counted, copy-on-write scheme `List<T>`/`Map<K,V>`/
/// `Set<T>` share -- mirrors `codegen_ring_lowers_to_inline_llvm_struct_type`,
/// just asserting the opposite (heap-indirected, not inline) representation.
#[test]
fn codegen_table_lowers_to_rc_object_pointer() {
    let src = "struct Enemy:\n    hp: i32\n\nfn main():\n    let t = Table<Enemy>()\n    println(f\"{t.len()}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("i8* null"), "an empty Table<T>, like List<T>, should start as `null`: {}", ir);
}

/// Full runtime round trip via `examples/table.exe`: construction, `push`
/// (growing across two capacity doublings), indexed read/write (reassembling/
/// decomposing the whole struct element across every column), `pop`
/// (removes and returns the last element), the safe zero-value fallback for
/// an out-of-bounds read and for `pop` on an empty table, and copy-on-write
/// (mutating a clone via `push` must not affect the original -- exercising
/// the per-column clone path, including its `str` field's retain).
#[test]
fn runtime_table_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/table.exe").output().expect("failed to execute table.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("empty len = 0"), "{}", stdout);
    assert!(stdout.contains("after 3 pushes len = 3"), "{}", stdout);
    assert!(stdout.contains("enemies[0] = Goblin hp=10"), "{}", stdout);
    assert!(stdout.contains("enemies[2] = Troll hp=30"), "{}", stdout);
    assert!(stdout.contains("enemies[1] after set = Orc Chief hp=99"), "indexed write: {}", stdout);
    assert!(stdout.contains("popped = Troll hp=30"), "pop must return the last element: {}", stdout);
    assert!(stdout.contains("len after pop = 2"), "{}", stdout);
    assert!(stdout.contains("enemies[99] hp = 0"), "OOB read yields the zero value: {}", stdout);
    assert!(stdout.contains("pop from empty hp = 0"), "pop on an empty table yields the zero value: {}", stdout);
    assert!(stdout.contains("original len = 1 clone len = 2"), "copy-on-write: mutating a clone must not affect the original: {}", stdout);
    assert!(stdout.contains("original[0] hp = 1 clone[0] hp = 1"), "{}", stdout);
}

// ===== Regression: `Ring` isn't a reserved keyword, so a plain value named
// ===== `Ring` must still parse as an ordinary identifier/comparison, not be
// ===== force-fed into `Parser::parse_ring_new`'s turbofish grammar. Mirrors
// ===== `try_parse_type_args`'s own documented backtracking rule (see its
// ===== doc comment) for every *other* capitalized generic-looking name
// ===== (`Box`, `Option`, a user struct); `Ring<T, N>()`'s dedicated parser
// ===== special case (needed since `N` is a bare integer literal, not a
// ===== `Type` the ordinary turbofish loop can parse) previously hard-committed
// ===== the instant it saw `Ring` followed by `<`, with no speculative
// ===== backtrack -- so `if Ring < 3:` (comparing a local literally named
// ===== `Ring`) produced a cascading parse failure ("expected an identifier,
// ===== found an integer literal") that ate the rest of the enclosing block
// ===== instead of parsing as an ordinary comparison. =========================

/// A local named `Ring` compared with `<` must parse as an ordinary
/// comparison expression, not misfire into `Ring<T, N>()` turbofish parsing.
#[test]
fn parses_shadowed_ring_identifier_as_comparison_not_turbofish() {
    let src = "fn main():\n    let Ring = 5\n    if Ring < 3:\n        println(\"less\")\n    else:\n        println(\"not less\")\n";
    let module = Driver::parse(src).expect("`Ring < 3` on a shadowed local should parse as a comparison, not a Ring<T,N> turbofish");
    assert!(Driver::check(&module).is_ok(), "shadowed `Ring` comparison should type-check cleanly");
}

/// The real `Ring<T, N>()` construction must still parse correctly once the
/// speculative turbofish is confirmed by an immediately-following `(` --
/// the backtracking fix must not regress the ordinary case.
#[test]
fn parses_real_ring_new_construction_alongside_shadow_fix() {
    let src = "fn main():\n    let r = Ring<i32, 3>()\n    println(f\"{r.len()}\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Item::Fn(f) = &module.items[0] else { panic!("expected a fn item") };
    let Stmt::Let { value, .. } = &f.body.stmts[0] else { panic!("expected a let stmt") };
    assert!(matches!(value, Expr::RingNew { count: 3, .. }), "{:?}", value);
}

/// A genuinely malformed `Ring<T, N>` construction (a non-positive capacity)
/// immediately followed by `(` is unambiguously a construction attempt, not
/// a comparison -- it must still be rejected with a real diagnostic, not
/// silently backtracked into a nonsensical comparison parse.
#[test]
fn rejects_ring_new_zero_capacity_even_with_backtracking_fix() {
    let src = "fn main():\n    let r: Ring<i32, 0> = Ring<i32, 0>()\n    println(f\"{r.len()}\")\n";
    let Err(diags) = Driver::parse(src) else { panic!("`Ring<T, 0>()` should be a parse error") };
    assert!(diags.iter().any(|d| d.message.contains("positive")), "{:?}", diags);
}

// ===== Regression: `root_ident` (the shared helper `walk_par_stmt`'s
// ===== `TypedStmt::Assign` arm uses to decide whether a mutation target is a
// ===== provably-disjoint body-local) was missing a `TableIndex` arm, even
// ===== though `ArrayIndex`/`RingIndex` both have one and `crate::types::
// ===== par_analysis`'s own doc comments explicitly say a `Table<T>` element
// ===== write "goes through a plain `Stmt::Assign` target, checked generically
// ===== via `root_ident`". Without that arm, `root_ident` fell through to its
// ===== `_ => None` catch-all for *every* `table[i] = v` inside a par/swarm
// ===== body, which `walk_par_stmt` treats as an unconditionally-rejected
// ===== "unsupported mutation target" -- even for a table declared and only
// ===== ever touched inside that same loop body, which is exactly as safe as
// ===== the identical `ring[i] = v` case one line above it in the source. ====

/// `table[i] = v` on a body-local `Table<T>` (declared inside the loop body
/// itself) must type-check inside a `par`/`swarm` body -- it can't be shared
/// across threads, so it's exactly as safe as mutating the loop variable's
/// own fields.
#[test]
fn accepts_table_index_write_on_body_local_table_inside_par_body() {
    let src = r#"struct Enemy:
    mut hp: i32

struct Item:
    mut hp: i32
    name: str

arena Enemies: Enemy

fn main():
    par e in Enemies:
        let mut t: Table<Item> = Table<Item>()
        t.push(Item(hp = 1, name = "a"))
        t[0] = Item(hp = 2, name = "b")
        e.hp = t[0].hp
"#;
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "writing into a body-local Table<T>'s index inside par/swarm should type-check cleanly");
}

/// `table[i] = v` on a *captured* (outer-scope) `Table<T>` must still be
/// rejected inside a `par`/`swarm` body -- the fix for the body-local case
/// above must not weaken this into an unconditionally-accepted write.
#[test]
fn rejects_table_index_write_on_captured_table_inside_par_body() {
    let src = r#"struct Enemy:
    mut hp: i32

struct Item:
    mut hp: i32
    name: str

arena Enemies: Enemy

fn main():
    let mut t: Table<Item> = Table<Item>()
    t.push(Item(hp = 1, name = "a"))
    par e in Enemies:
        t[0] = Item(hp = 2, name = "b")
        e.hp = t[0].hp
"#;
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("writing into a captured Table<T>'s index inside par/swarm should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("cannot be proven disjoint across threads")), "{:?}", diags);
}

/// `table[i].field = v` (a field projected *through* a table index, todo.md
/// P2 #10) on a body-local `Table<T>` must type-check inside a `par`/
/// `swarm` body exactly like the whole-element write above --
/// `root_ident`'s `Field`/`TableIndex` recursion (mirrored by
/// `walk_par_assign_target`) already finds the same root binding regardless
/// of how many `Field` hops sit between the assignment target and the
/// `TableIndex`, so this needed no separate `par_analysis.rs` wiring once
/// the write itself became supported.
#[test]
fn accepts_table_field_write_through_index_on_body_local_table_inside_par_body() {
    let src = r#"struct Enemy:
    mut hp: i32

struct Item:
    mut hp: i32

arena Enemies: Enemy

fn main():
    par e in Enemies:
        let mut t: Table<Item> = Table<Item>()
        t.push(Item(hp = 1))
        t[0].hp = 2
        e.hp = t[0].hp
"#;
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "writing a field through a body-local Table<T>'s index inside par/swarm should type-check cleanly: {:?}", Driver::check(&module).err());
}

/// Same fix, the captured-table control: `table[i].field = v` on a
/// *captured* (outer-scope) `Table<T>` must still be rejected inside a
/// `par`/`swarm` body, exactly like the whole-element write's own control
/// above -- the field-projection fix must not weaken this into an
/// unconditionally-accepted write.
#[test]
fn rejects_table_field_write_through_index_on_captured_table_inside_par_body() {
    let src = r#"struct Enemy:
    mut hp: i32

struct Item:
    mut hp: i32

arena Enemies: Enemy

fn main():
    let mut t: Table<Item> = Table<Item>()
    t.push(Item(hp = 1))
    par e in Enemies:
        t[0].hp = 2
        e.hp = t[0].hp
"#;
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("writing a field through a captured Table<T>'s index inside par/swarm should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("cannot be proven disjoint across threads")), "{:?}", diags);
}

/// Same `root_ident` gap as `Table<T>` above, but for `List<T>`: `root_ident`
/// had `ArrayIndex`/`RingIndex`/`TableIndex` arms but no `ListIndex` one, so
/// `xs[0] = v` on a `List<T>` declared and only ever touched inside the loop
/// body itself was wrongly rejected as an "unsupported mutation target" --
/// even though it's exactly as safe as the identical `Table`/`Ring`/`Array`
/// cases right next to it.
#[test]
fn accepts_list_index_write_on_body_local_list_inside_par_body() {
    let src = r#"struct Enemy:
    mut hp: i32

arena Enemies: Enemy

fn main():
    par e in Enemies:
        let mut xs: List<i32> = List<i32>()
        xs.push(1)
        xs[0] = 2
        e.hp = xs[0]
"#;
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "writing into a body-local List<T>'s index inside par/swarm should type-check cleanly");
}

// ===== Regression: `compute_unsafe_par_fns`'s syntactic pre-pass (over the
// ===== raw AST, before any type-checking) treated `spawn`/`despawn`/`frame:`
// ===== as hazards that make a called function unsafe to invoke inside a
// ===== `par`/`swarm` body, but never treated an assignment written through a
// ===== `[..]` index (`Expr::GenRefIndex` -- the one AST node backing every
// ===== bracketed index syntax, `GenRef` included, until the checker later
// ===== disambiguates it by type) as a hazard at all. So a helper method that
// ===== mutates a field reached through a `GenRef` dereference (e.g.
// ===== `self.target[0].hp -= dmg`, where `self.target: GenRef<Player>` looks
// ===== into a shared arena, not the receiver's own disjoint-per-iteration
// ===== storage) type-checked cleanly when called from inside a `par` body,
// ===== racing every worker thread on that shared `Player` slot with zero
// ===== diagnostic. =========================================================

/// A method that writes through a `GenRef` field dereference (`self.target[0]
/// .hp -= dmg`) must be rejected when called inside a `par`/`swarm` body --
/// two different loop items' `target` fields can alias the same arena slot,
/// so this can't be proven disjoint across worker threads.
#[test]
fn rejects_genref_index_write_hidden_behind_helper_function_call_inside_par() {
    let src = r#"struct Player:
    mut hp: i32

struct Enemy:
    target: GenRef<Player>

impl Enemy:
    fn damage_target(mut self, dmg: i32):
        self.target[0].hp -= dmg

arena Players: Player
arena Enemies: Enemy

fn main():
    spawn Players(Player(100))
    let p = GenRef<Player>(0)
    spawn Enemies(Enemy(p))
    spawn Enemies(Enemy(p))
    par e in Enemies:
        e.damage_target(1)
"#;
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else {
        panic!("a GenRef-index write hidden behind a helper function call inside par/swarm should be a type error")
    };
    assert!(diags.iter().any(|d| d.message.contains("damage_target")), "{:?}", diags);
}

// ===== Additional wide-coverage runtime tests: edge cases not exercised by
// ===== `examples/ring.star`/`examples/table.star` (capacity-1 rings,
// ===== negative-index reads, RC content nested a level deep through a
// ===== struct field rather than a direct `str` field, an all-`i32`
// ===== no-RC-column `Table<T>`), plus higher-iteration stress passes for
// ===== both types' RC-sensitive paths (eviction, column growth, CoW clone
// ===== under growth pressure). ================================================

/// `examples/ring_table_edge_cases.exe`: a capacity-1 ring (every push
/// evicts immediately), negative-index reads on both `Ring<T,N>` and
/// `Table<T>` (must read as out-of-bounds, not wrap via unsigned modulo),
/// an element type whose RC content is nested through a struct field (a
/// `List<i32>`, not a direct `str`), and an all-`i32` `Table<T>` (no RC
/// columns at all) -- exercised end to end through a real clang-compiled
/// executable.
#[test]
fn runtime_ring_table_edge_cases_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/ring_table_edge_cases.exe").output().expect("failed to execute ring_table_edge_cases.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("r1 len=1 r1[0]=30"), "capacity-1 ring: every push must evict immediately: {}", stdout);
    assert!(stdout.contains("r2[-1]=0"), "negative ring index must read as out-of-bounds: {}", stdout);
    assert!(stdout.contains("r3[0].label=second r3[0].items.len()=2"), "nested-RC element type after eviction: {}", stdout);
    assert!(stdout.contains("r3[1].label=third r3[1].items.len()=1"), "{}", stdout);
    assert!(stdout.contains("pts len=2 clone len=3"), "all-i32 Table<T> copy-on-write: {}", stdout);
    assert!(stdout.contains("pts[1] = (3, 4)"), "{}", stdout);
    assert!(stdout.contains("pts[-1] = (0, 0)"), "negative table index must read as out-of-bounds: {}", stdout);
    assert!(stdout.contains("bags[0].label=alpha bags[0].items.len()=3"), "Table<T> with nested-RC (List<i32>) field: {}", stdout);
    assert!(stdout.contains("bags[1].label=beta bags[1].items.len()=0"), "{}", stdout);
}

/// `examples/ring_stress.exe`: 200,000 pushes of a fresh `str` into a
/// capacity-4 ring (199,996 evictions, each exercising `RingMethod::Push`'s
/// RC-safe "release-before-overwrite" full-ring branch), followed by a
/// smaller `let`-bound push/pop cycling pass -- a release/retain imbalance
/// on either path would leak unboundedly, double-free, or corrupt content
/// well before either loop finishes.
#[test]
fn runtime_ring_stress_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/ring_stress.exe").output().expect("failed to execute ring_stress.exe");
    assert!(output.status.success(), "ring_stress.exe should exit cleanly: stdout={} stderr={}", String::from_utf8_lossy(&output.stdout), String::from_utf8_lossy(&output.stderr));
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("len = 4"), "{}", stdout);
    assert!(stdout.contains("r[0] = item-199996"), "the ring must hold exactly the most recent 4 pushes after 200,000: {}", stdout);
    assert!(stdout.contains("r[1] = item-199997"), "{}", stdout);
    assert!(stdout.contains("r[2] = item-199998"), "{}", stdout);
    assert!(stdout.contains("r[3] = item-199999"), "{}", stdout);
    assert!(stdout.contains("cycler len = 3"), "{}", stdout);
}

/// `examples/table_stress.exe`: thousands of pushes forcing many capacity
/// doublings of a struct-with-`str`-field `Table<T>` (each exercising
/// `TableMethod::Push`'s `malloc`/`memcpy`/`free` grow branch across every
/// column), a late copy-on-write clone kept diverging under continued
/// growth pressure in both the original and the clone, and a separate
/// `let`-bound push/pop cycling pass -- a corrupted column pointer or
/// release-thunk bug on any of these paths would leak, crash, or read back
/// garbled text well before the run finishes.
#[test]
fn runtime_table_stress_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/table_stress.exe").output().expect("failed to execute table_stress.exe");
    assert!(output.status.success(), "table_stress.exe should exit cleanly: stdout={} stderr={}", String::from_utf8_lossy(&output.stdout), String::from_utf8_lossy(&output.stderr));
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("len = 5000"), "{}", stdout);
    assert!(stdout.contains("t[0] = tag-0 hp=0"), "{}", stdout);
    assert!(stdout.contains("t[4999] = tag-4999 hp=4999"), "{}", stdout);
    assert!(stdout.contains("original len = 5000 clone len = 10000"), "copy-on-write under growth pressure: {}", stdout);
    assert!(stdout.contains("original[0] = tag-0 clone[0] = tag-0"), "{}", stdout);
    assert!(stdout.contains("original[4999] = tag-4999 clone[4999] = tag-4999"), "{}", stdout);
    assert!(stdout.contains("cycler len = 2000"), "{}", stdout);
    assert!(!stdout.contains("unexpected empty pop"), "a pop paired with a preceding push should never see the zero value: {}", stdout);
}

// ===== `table[i].field = v` (and any mutating collection-method call
// ===== reached the same way, e.g. `table[i].tags.push(x)`) -- todo.md P2
// ===== #10, "General place-projection into `Table<T>`". Previously
// ===== rejected outright at type-check time (`Checker::
// ===== writes_through_table_index`): `Codegen::emit_place` had no arm for
// ===== `TypedExpr::TableIndex`, so a `Field`/`TupleIndex`/`ListIndex`/
// ===== `ArrayIndex`/`RingIndex` chain rooted there fell into the generic
// ===== rvalue fallback (materialize a disconnected copy, GEP/mutate *that*
// ===== instead of the real column). Now `emit_place`'s `Field` arm
// ===== special-cases a `TableIndex` base directly
// ===== (`Codegen::emit_table_field_place`, `crate::codegen::table`),
// ===== addressing the real column slot without ever materializing the
// ===== whole element -- so every one of these shapes both type-checks
// ===== *and* actually mutates the table now, verified end to end below
// ===== rather than just asserting a rejection diagnostic. `table[i] = v`
// ===== (the whole element) and `table[i].field` (a *read*) were already
// ===== supported and remain unaffected. =====================================

/// `table[i].field = v`: a single field written through a table index must
/// actually mutate the table's own storage, not a disconnected temporary.
#[test]
fn runtime_table_field_assignment_through_index_end_to_end() {
    let src = r#"struct Enemy:
    mut hp: i32

fn main():
    let mut e = Table<Enemy>()
    e.push(Enemy(hp = 1))
    e[0].hp = 99
    println(f"{e[0].hp}")
"#;
    let output = compile_and_run("table_field_assignment_through_index", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "99");
}

/// Same fix, one level deeper: `table[i].nested.field = v` must also reach
/// the real column, not just the immediate `table[i].field = v` shape --
/// `emit_place`'s `Field` arm recurses through the nested struct's own
/// offset once the outer `Field` hands back a real pointer into the
/// `nested` column.
#[test]
fn runtime_table_nested_field_assignment_through_index_end_to_end() {
    let src = r#"struct Pos:
    mut x: i32

struct Enemy:
    mut pos: Pos

fn main():
    let mut e = Table<Enemy>()
    e.push(Enemy(pos = Pos(x = 1)))
    e[0].pos.x = 99
    println(f"{e[0].pos.x}")
"#;
    let output = compile_and_run("table_nested_field_assignment_through_index", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "99");
}

/// A mutating collection-method call on a field reached through a table
/// index (`table[i].tags.push(x)`) composes for free through the same fix:
/// `List::push`'s own `list_fields_mut` resolves the receiver's storage via
/// `emit_place`, which now hands back the real column slot instead of a
/// disconnected copy.
#[test]
fn runtime_table_list_field_push_through_index_end_to_end() {
    let src = r#"struct Enemy:
    mut tags: List<str>

fn main():
    let mut e = Table<Enemy>()
    e.push(Enemy(tags = List<str>()))
    e[0].tags.push("x")
    println(f"{e[0].tags.len()}")
    println(f"{e[0].tags[0]}")
"#;
    let output = compile_and_run("table_list_field_push_through_index", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["1", "x"], "{}", stdout);
}

/// Copy-on-write correctness: `table[i].field = v` must trigger the same
/// CoW clone every other mutating table operation does (`table_fields_mut`
/// -> `emit_table_ensure_unique`) -- a field write reached through a table
/// index is a genuinely new call site into that machinery (previously only
/// exercised by `push`/`pop`/whole-element write), so a shared table must
/// not observe another binding's field-level mutation.
#[test]
fn runtime_table_field_write_triggers_cow_does_not_affect_aliased_binding_end_to_end() {
    let src = r#"struct Enemy:
    mut hp: i32

fn main():
    let mut a = Table<Enemy>()
    a.push(Enemy(hp = 1))
    let mut b = a
    b[0].hp = 99
    println(f"{a[0].hp}")
    println(f"{b[0].hp}")
"#;
    let output = compile_and_run("table_field_write_cow_aliasing", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["1", "99"], "b's field write must not leak into a's own copy: {}", stdout);
}

/// Column independence: writing `table[i].field = v` for one row must not
/// disturb any other row's own columns -- each row's slot is addressed by
/// its own index into the shared column buffer, so this guards against an
/// off-by-one in `emit_table_field_place`/`store_table_field`'s index
/// arithmetic bleeding into a neighboring row.
#[test]
fn runtime_table_field_write_does_not_disturb_other_rows_end_to_end() {
    let src = r#"struct Enemy:
    mut hp: i32
    mut name: str

fn main():
    let mut e = Table<Enemy>()
    e.push(Enemy(hp = 1, name = "a"))
    e.push(Enemy(hp = 2, name = "b"))
    e.push(Enemy(hp = 3, name = "c"))
    e[1].hp = 200
    e[1].name = "z"
    println(f"{e[0].hp} {e[0].name}")
    println(f"{e[1].hp} {e[1].name}")
    println(f"{e[2].hp} {e[2].name}")
"#;
    let output = compile_and_run("table_field_write_row_independence", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["1 a", "200 z", "3 c"], "{}", stdout);
}

/// `mut` is still required on the table binding itself: `table[i].field = v`
/// must be rejected on a non-`mut` variable exactly like every other write
/// path (`Checker::assign_root_name`'s `TableIndex` arm recurses to find
/// the root binding regardless of how deep the `Field` projection goes) --
/// removing the old blanket `writes_through_table_index` rejection must not
/// have accidentally bypassed this separate, still-active gate.
#[test]
fn rejects_table_field_assignment_through_index_without_mut() {
    let src = r#"struct Enemy:
    mut hp: i32

fn main():
    let e = Table<Enemy>()
    e[0].hp = 99
"#;
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("table[i].field = v on a non-mut table binding should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("was not declared `mut`")), "{:?}", diags);
}

/// A struct field can independently be non-`mut` even when the table
/// binding itself is `mut` -- `table[i].field = v` must still respect
/// `Checker::field_is_mut`'s per-field gate, matching `Stmt::Assign`'s
/// existing `s.field = v` behavior for an ordinary (non-table) struct.
#[test]
fn rejects_table_field_assignment_through_index_on_non_mut_field() {
    let src = r#"struct Enemy:
    hp: i32

fn main():
    let mut e = Table<Enemy>()
    e.push(Enemy(hp = 1))
    e[0].hp = 99
"#;
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("assigning a non-mut field through a table index should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("is not mutable")), "{:?}", diags);
}

/// The fix must not overreach: `table[i] = v` (the whole element, the one
/// genuinely supported write path) must still type-check cleanly.
#[test]
fn accepts_whole_element_assignment_to_table_index() {
    let src = r#"struct Enemy:
    hp: i32

fn main():
    let mut e = Table<Enemy>()
    e.push(Enemy(hp = 1))
    e[0] = Enemy(hp = 99)
    println(f"{e[0].hp}")
"#;
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "table[i] = v (the whole element) must still type-check cleanly");
}

/// The fix must not overreach: `table[i].field` (a *read*) must still
/// type-check cleanly -- only a write through the projection is unsound.
#[test]
fn accepts_field_read_through_table_index() {
    let src = r#"struct Enemy:
    hp: i32

fn main():
    let mut e = Table<Enemy>()
    e.push(Enemy(hp = 1))
    println(f"{e[0].hp}")
"#;
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "table[i].field (a read) must still type-check cleanly");
}

/// The fix must not overreach in the other direction either: a `Table<T>`
/// reached *through* another collection's index (`list[i].some_table[j] =
/// v`) is a bare `TableIndex` target, not a `Field`/`TupleIndex` projection
/// through one -- it must still type-check, since `table[j] = v` is always
/// the supported whole-element write regardless of how `table` itself was
/// reached.
#[test]
fn accepts_whole_element_assignment_to_table_reached_through_list_index() {
    let src = r#"struct Enemy:
    hp: i32

struct Holder:
    mut inner: Table<Enemy>

fn main():
    let mut holders = List<Holder>()
    holders.push(Holder(inner = Table<Enemy>()))
    holders[0].inner.push(Enemy(hp = 1))
    holders[0].inner[0] = Enemy(hp = 42)
    println(f"{holders[0].inner[0].hp}")
"#;
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "table[j] = v must still type-check even when the table itself is reached through a list index: {:?}", Driver::check(&module).err());
}

/// The fix isn't limited to plain `=`: a compound assignment
/// (`table[i].field += v`) reaches `Stmt::Assign` exactly the same way (the
/// target/op/value are inferred once for every assignment operator, and
/// `load_target`/`store_target` both resolve through the same real column
/// pointer), so it must actually mutate the table too, not just the
/// plain-`=` shape exercised above.
#[test]
fn runtime_table_compound_assignment_to_field_through_index_end_to_end() {
    let src = r#"struct Enemy:
    mut hp: i32

fn main():
    let mut e = Table<Enemy>()
    e.push(Enemy(hp = 1))
    e[0].hp += 41
    println(f"{e[0].hp}")
"#;
    let output = compile_and_run("table_compound_assignment_to_field_through_index", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "42");
}

// ===== `RingMethod`/`RingIndex` par/swarm-disjointness coverage: mirrors the
// ===== `Table<T>` coverage above (`accepts_table_index_write_on_body_local_table_inside_par_body`/
// ===== `rejects_table_index_write_on_captured_table_inside_par_body`), which
// ===== `src/types/par_analysis.rs` added identical logic for at the same
// ===== time (`TypedExpr::RingMethod`/`RingIndex` arms in `walk_par_expr`,
// ===== `RingIndex` in `root_ident`) but the prior test round only ever
// ===== exercised the `Table<T>` half. ========================================

/// `ring.push(v)`/`ring[i] = v` on a body-local `Ring<T,N>` (declared inside
/// the loop body itself) must type-check inside a `par`/`swarm` body -- it
/// can't be shared across threads, so it's exactly as safe as mutating the
/// loop variable's own fields.
#[test]
fn accepts_ring_mutation_on_body_local_ring_inside_par_body() {
    let src = r#"struct Enemy:
    mut hp: i32

arena Enemies: Enemy

fn main():
    par e in Enemies:
        let mut r: Ring<i32, 3> = Ring<i32, 3>()
        r.push(1)
        r.push(2)
        r[0] = 5
        e.hp = r[0]
"#;
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "mutating a body-local Ring<T,N> inside par/swarm should type-check cleanly: {:?}", Driver::check(&module).err());
}

/// `ring.push(v)` on a *captured* (outer-scope) `Ring<T,N>` must still be
/// rejected inside a `par`/`swarm` body -- the fix for the body-local case
/// above must not weaken this into an unconditionally-accepted mutation.
#[test]
fn rejects_ring_push_on_captured_ring_inside_par_body() {
    let src = r#"struct Enemy:
    mut hp: i32

arena Enemies: Enemy

fn main():
    let mut r: Ring<i32, 3> = Ring<i32, 3>()
    par e in Enemies:
        r.push(1)
        e.hp = r[0]
"#;
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("mutating a captured Ring<T,N> inside par/swarm should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("cannot mutate a captured ring")), "{:?}", diags);
}

// ===== Additional wide-coverage runtime test: `Ring<T,N>`/`Table<T>` nested
// ===== a level deeper than `examples/ring.star`/`examples/table.star`/
// ===== `examples/ring_table_edge_cases.star` exercise -- a `Ring<T,N>`
// ===== stored as a *struct field* (exercising `Codegen::type_size`/
// ===== `type_align`'s `Ty::Ring` arm for real struct-layout offsets, plus
// ===== plain struct-value-copy independence, since a `Ring<T,N>` has no
// ===== copy-on-write of its own -- unlike every other collection type here,
// ===== copying the struct that holds it must deep-copy the ring inline), a
// ===== `Table<T>` whose element struct has a `Ring<str,N>` field (RC
// ===== content nested a level deeper than the existing `List<i32>`-field
// ===== coverage), and a `Ring<Table<T>, N>` (a `Table<T>` -- itself RC'd --
// ===== as a ring element type, exercising eviction releasing a whole table).

/// `examples/ring_table_nesting.exe`: a `Ring<T,N>` struct field (including
/// a `Ring<Player,2>` alongside a `Ring<i32,3>` in the same struct) with
/// struct-copy independence, a `Table<Bag>` whose element has a
/// `Ring<str,2>` field (copy-on-write, pop), and a `Ring<Table<Item>, 2>`
/// (eviction of a whole table).
#[test]
fn runtime_ring_table_nesting_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/ring_table_nesting.exe").output().expect("failed to execute ring_table_nesting.exe");
    assert!(output.status.success(), "ring_table_nesting.exe should exit cleanly: stdout={} stderr={}", String::from_utf8_lossy(&output.stdout), String::from_utf8_lossy(&output.stderr));
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("snapshot tag=42 hist_len=2 hist=[1, 2]"), "Ring<T,N> struct field: {}", stdout);
    assert!(stdout.contains("snapshot who_len=1 who0=Hero hp=100"), "Ring<Player,2> struct field: {}", stdout);
    assert!(stdout.contains("a hist len=3 a=[2, 3]"), "mutating a struct copy's ring field: {}", stdout);
    assert!(stdout.contains("s hist len=2 s=[1, 2]"), "the original struct's ring field must be unaffected (Ring<T,N> has no CoW, so a plain struct copy must deep-copy it): {}", stdout);
    assert!(stdout.contains("bags len=2"), "{}", stdout);
    assert!(stdout.contains("bags[0] tag=1 hist_len=2 h=[a, b]"), "Table<T> with a Ring<str,N> field: {}", stdout);
    assert!(stdout.contains("bags[1] tag=2 hist_len=1 h0=c"), "{}", stdout);
    assert!(stdout.contains("bags orig len=3 clone len=2"), "Table<T> copy-on-write with a Ring<str,N>-bearing element: {}", stdout);
    assert!(stdout.contains("popped tag=3 hist_len=0"), "{}", stdout);
    assert!(stdout.contains("r len=2 r0 len=1 r0[0].tag=1"), "Ring<Table<Item>, 2>: {}", stdout);
    assert!(stdout.contains("r1 len=2 r1[0].tag=2 r1[1].tag=3"), "{}", stdout);
    assert!(stdout.contains("after evict r len=2 r0 len=2 r0[0].tag=2"), "evicting a Ring<Table<T>,N> element must release the whole evicted table: {}", stdout);
}

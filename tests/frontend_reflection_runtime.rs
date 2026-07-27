//! Reflection runtime
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Reflection runtime (todo.md #7, "wire up reflection into an actual
// runtime feature") ==========================================================
//
// `@export`/`@tweakable` previously only emitted descriptive `name:offset:
// type:decorators` metadata strings (`Codegen::emit_reflect_metadata`) with
// no in-process consumer at all -- `todo.md` explicitly called this out as
// "metadata-only". `reflect_get_i32`/`_f32`/`_bool`, `reflect_set_i32`/`_f32`/
// `_bool`, and `reflect_has_field` close that gap: a lazily-generated,
// per-struct `strcmp`-chain accessor function (`crate::codegen::reflect`)
// reads/writes a decorated field by a genuine *runtime* `str` name -- unlike
// ordinary `s.field` access, the field being touched no longer has to be
// known at compile time. Scoped to `i32`/`float`/`bool` fields only (none
// carry RC-managed content, so a `reflect_set_*` write never needs to
// release an outgoing value or retain an incoming one); a name that doesn't
// match any decorated field of the right type is a safe fallback (`0`/
// `0.0`/`false` on read, a no-op on write) rather than a crash, mirroring
// this codebase's established convention for every other runtime-keyed
// lookup (an out-of-bounds `List<T>` index, a stale `GenRef`, ...).
//
// `reflect_set_*` additionally only ever matches a field that's *also*
// declared `mut` (`reflect_get_*` doesn't require this -- reading a plain,
// non-`mut` `@export` field is always safe), and rejects a `Table<T>` index
// as argument 1 outright -- both real correctness gaps this round found and
// closed itself before they ever shipped, not pre-existing bugs: without
// the `mut` gate, `reflect_set_i32` could silently mutate a field the rest
// of the language treats as immutable after construction; without the
// `Table<T>` guard, `emit_place`'s generic disconnected-copy fallback for a
// *bare* `TableIndex` base (still the only unaddressable shape --
// `table[i].field = v` itself is genuinely supported since todo.md P2 #10,
// see the `runtime_table_field_assignment_through_index_end_to_end` family
// above) would make the write silently vanish -- `reflect_set_i32(t[i],
// ...)` mutates its *whole* argument-1 struct by runtime field-name lookup,
// which still has no single contiguous address to target through a
// `Table<T>` index, unlike a single compile-time-known field.

/// `reflect_get_i32`/`_f32`/`_bool` resolve to their respective scalar type
/// through the checker, with no `fn` declaration of their own to consult
/// (mirroring every other builtin, e.g. `checks_builtin_return_types`).
#[test]
fn checks_reflect_get_return_types() {
    let src = "struct Stats:\n    @export mut score: i32 = 0\n    @tweakable mut speed: float = 1.0\n    @export mut alive: bool = true\n\nfn t():\n    let s = Stats(score = 0, speed = 1.0, alive = true)\n    let a: i32 = reflect_get_i32(s, \"score\")\n    let b: float = reflect_get_f32(s, \"speed\")\n    let c: bool = reflect_get_bool(s, \"alive\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("reflect_get_* should type-check to their respective scalar types");
}

/// `reflect_has_field` resolves to `bool`.
#[test]
fn checks_reflect_has_field_return_type() {
    let src = "struct Stats:\n    @export mut score: i32 = 0\n\nfn t():\n    let s = Stats(score = 0)\n    let ok: bool = reflect_has_field(s, \"score\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("reflect_has_field should type-check to bool");
}

/// `reflect_get_i32` (and by extension every `reflect_*` builtin) requires
/// exactly the arity its `crate::codegen::reflect` lowering assumes -- same
/// class of check `check_builtin_call_args`'s doc comment describes for
/// `file_open`/`clamp`/....
#[test]
fn rejects_reflect_get_i32_wrong_arity() {
    let src = "struct Stats:\n    @export mut score: i32 = 0\n\nfn t():\n    let s = Stats(score = 0)\n    let x = reflect_get_i32(s)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("reflect_get_i32 with one argument should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("expects 2 argument")), "{:?}", diags);
}

/// Argument 1 must be a real struct value -- a bare scalar is rejected with
/// a clean diagnostic rather than a confusing downstream codegen failure.
#[test]
fn rejects_reflect_get_on_non_struct_arg() {
    let src = "fn t():\n    let x = reflect_get_i32(5, \"score\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("reflect_get_i32 on a non-struct value should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("must be a struct value")), "{:?}", diags);
}

/// Argument 2 (the field name) must be `str`.
#[test]
fn rejects_reflect_get_with_non_str_name_arg() {
    let src = "struct Stats:\n    @export mut score: i32 = 0\n\nfn t():\n    let s = Stats(score = 0)\n    let x = reflect_get_i32(s, 5)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("a non-str field name should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("argument 2 expected `str`")), "{:?}", diags);
}

/// A struct with no decorated `i32` field at all can never possibly satisfy
/// a `reflect_get_i32` call -- rejected statically, the one half of "does
/// this call make sense" this checker *can* verify without knowing the
/// runtime field-name value.
#[test]
fn rejects_reflect_get_i32_when_struct_has_no_matching_decorated_field() {
    let src = "struct Stats:\n    @tweakable mut speed: float = 1.0\n\nfn t():\n    let s = Stats(speed = 1.0)\n    let x = reflect_get_i32(s, \"speed\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("reflect_get_i32 on a struct with no decorated i32 field should be a type error") };
    assert!(
        diags.iter().any(|d| d.message.contains("declares no `@export`/`@tweakable` field of type `Int`")),
        "{:?}", diags
    );
}

/// An undecorated field of the right type still doesn't count -- only
/// `@export`/`@tweakable` fields are reflectable, matching
/// `emit_reflect_metadata`'s own gate.
#[test]
fn rejects_reflect_get_i32_ignores_undecorated_field_of_matching_type() {
    let src = "struct Stats:\n    score: i32 = 0\n    @tweakable mut speed: float = 1.0\n\nfn t():\n    let s = Stats(score = 0, speed = 1.0)\n    let x = reflect_get_i32(s, \"score\")\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "an undecorated i32 field must not satisfy reflect_get_i32's static check");
}

/// `reflect_get_i32` doesn't require the matching field to be `mut` --
/// reading is always safe regardless of mutability, unlike `reflect_set_i32`
/// (see `rejects_reflect_set_i32_when_only_matching_field_is_not_mut` below).
#[test]
fn checks_reflect_get_i32_allows_non_mut_decorated_field() {
    let src = "struct Stats:\n    @export score: i32 = 0\n\nfn t():\n    let s = Stats(score = 0)\n    let x = reflect_get_i32(s, \"score\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("reflect_get_i32 should not require the target field to be mut");
}

/// `reflect_set_i32`'s value argument (argument 3) must match the getter/
/// setter pair's own scalar type.
#[test]
fn rejects_reflect_set_i32_wrong_value_type() {
    let src = "struct Stats:\n    @export mut score: i32 = 0\n\nfn t():\n    let mut s = Stats(score = 0)\n    reflect_set_i32(s, \"score\", \"nope\")\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("reflect_set_i32 with a str value should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("argument 3 expected `Int`")), "{:?}", diags);
}

/// `reflect_set_i32` mutates its first argument in place, exactly like a
/// mutating method call's receiver -- the same `mut`-binding gate
/// `List::push`/`Map::insert`/... already get via `Checker::
/// check_mut_receiver` applies here too.
#[test]
fn rejects_reflect_set_on_non_mut_variable() {
    let src = "struct Stats:\n    @export mut score: i32 = 0\n\nfn t():\n    let s = Stats(score = 0)\n    reflect_set_i32(s, \"score\", 1)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("reflect_set_i32 on a non-mut binding should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("was not declared `mut`")), "{:?}", diags);
}

/// A field carrying a decorator but *not* declared `mut` (legitimate for
/// `@export`, which only promises hot-reload visibility, not writability)
/// must not satisfy `reflect_set_i32`'s static check even though it *does*
/// satisfy `reflect_get_i32`'s (`checks_reflect_get_i32_allows_non_mut_decorated_field`).
#[test]
fn rejects_reflect_set_i32_when_only_matching_field_is_not_mut() {
    let src = "struct Stats:\n    @export score: i32 = 0\n\nfn t():\n    let mut s = Stats(score = 0)\n    reflect_set_i32(s, \"score\", 1)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("reflect_set_i32 targeting a non-mut decorated field should be a type error") };
    assert!(
        diags.iter().any(|d| d.message.contains("declares no `@export`/`@tweakable` field of type `Int` (also `mut`)")),
        "{:?}", diags
    );
}

/// `reflect_set_i32` through a bare `Table<T>` index is rejected the same
/// way any other write through one already is (`Checker::
/// writes_through_table_index`) -- a table element's fields live in
/// independent column buffers with no single addressable storage
/// `emit_place` could hand out a real pointer into, so the write would
/// otherwise silently target a disconnected copy instead of erroring or
/// taking effect. `check_mut_receiver`'s own hazard check alone doesn't
/// catch this shape (it was written for a *chain* bottoming out at a
/// `TableIndex`, e.g. `t[i].field`, not a bare `t[i]` itself) -- this needed
/// its own explicit, unconditional check.
#[test]
fn rejects_reflect_set_through_bare_table_index() {
    let src = "struct Stats:\n    @export mut score: i32 = 0\n\nfn t():\n    let mut xs: Table<Stats> = Table<Stats>()\n    xs.push(Stats(score = 0))\n    reflect_set_i32(xs[0], \"score\", 1)\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("reflect_set_i32 through a bare Table<T> index should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("Table<T>")), "{:?}", diags);
}

/// Reading through a bare `Table<T>` index is fine -- only a *write*
/// through one is unsupported (mirroring `table[i].field`'s own read-vs-
/// write asymmetry).
#[test]
fn checks_reflect_get_i32_through_bare_table_index_is_allowed() {
    let src = "struct Stats:\n    @export mut score: i32 = 0\n\nfn t():\n    let mut xs: Table<Stats> = Table<Stats>()\n    xs.push(Stats(score = 0))\n    let v = reflect_get_i32(xs[0], \"score\")\n";
    let module = Driver::parse(src).expect("should parse");
    Driver::check(&module).expect("reading via reflect_get_i32 through a Table<T> index should type-check");
}

/// `extern "C" fn reflect_get_i32` collides with the builtin of the same
/// name -- `is_builtin_name` is derived directly from `builtin_return_ty`,
/// so this needed no dedicated wiring of its own, and reaches
/// `Checker::check_extern_fn`'s ordinary builtin-name-collision diagnostic
/// (distinct from the "reserved runtime symbol" wording `puts`/`getenv`/
/// `main` get, since `reflect_get_i32` isn't a real C-runtime symbol this
/// compiler unconditionally `declare`s -- it's a Star-level builtin that
/// simply always wins name resolution at the call site).
#[test]
fn extern_fn_rejects_reflect_get_i32_as_reserved_name() {
    let src = "extern \"C\" fn reflect_get_i32(s: ptr, name: str) -> int\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("extern fn named `reflect_get_i32` should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("collides with a built-in name")), "{:?}", diags);
}

/// One `@__star_reflect_get_i32_<Struct>` accessor function is generated and
/// cached, then reused, across multiple `reflect_get_i32` call sites against
/// the same struct -- mirroring `Codegen::eq_fn_name`'s own lazy-generate-
/// and-cache shape (`crate::codegen::eq`), not a fresh `define` per call.
#[test]
fn codegen_reflect_get_i32_accessor_is_generated_once_and_reused() {
    let src = "struct Stats:\n    @export mut score: i32 = 0\n\nfn t():\n    let s = Stats(score = 0)\n    let a = reflect_get_i32(s, \"score\")\n    let b = reflect_get_i32(s, \"score\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert_eq!(ir.matches("define i32 @__star_reflect_get_i32_Stats(").count(), 1, "the accessor should be generated exactly once: {}", ir);
    assert_eq!(ir.matches("call i32 @__star_reflect_get_i32_Stats(").count(), 2, "both call sites should reuse it: {}", ir);
}

/// The generated `reflect_set_i32` accessor's `strcmp` chain only covers
/// fields that are both decorated *and* `mut` -- a decorated-but-not-`mut`
/// field of the same type must not add a comparison branch to the setter,
/// even though it does add one to the getter (`reflect_decorated_fields_of_ty`'s
/// `require_mut` parameter).
#[test]
fn codegen_reflect_set_i32_accessor_excludes_non_mut_field() {
    let src = "struct Stats:\n    @export health: i32 = 100\n    @tweakable mut speed: i32 = 5\n\nfn t():\n    let mut s = Stats(health = 100, speed = 5)\n    let v = reflect_get_i32(s, \"health\")\n    reflect_set_i32(s, \"speed\", 9)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let getter = extract_fn_body(&ir, "define i32 @__star_reflect_get_i32_Stats(");
    let setter = extract_fn_body(&ir, "define void @__star_reflect_set_i32_Stats(");
    assert_eq!(getter.matches("call i32 @strcmp(").count(), 2, "the getter should compare both health and speed: {}", getter);
    assert_eq!(setter.matches("call i32 @strcmp(").count(), 1, "the setter should only compare the mut field speed: {}", setter);
}

/// Basic `i32` get/set round trip through a runtime field name, plus a safe
/// fallback (`0`, not a crash) when the name doesn't match anything
/// decorated on the struct at all.
#[test]
fn runtime_reflect_get_set_i32_round_trip_end_to_end() {
    let src = concat!(
        "struct Stats:\n",
        "    @export mut score: i32 = 0\n",
        "    @tweakable mut move_interval_ms: i32 = 120\n",
        "\n",
        "fn main():\n",
        "    let mut s = Stats(score = 10, move_interval_ms = 120)\n",
        "    let a = reflect_get_i32(s, \"score\")\n",
        "    let b = reflect_get_i32(s, \"move_interval_ms\")\n",
        "    let c = reflect_get_i32(s, \"nonexistent\")\n",
        "    println(f\"{a}\")\n",
        "    println(f\"{b}\")\n",
        "    println(f\"{c}\")\n",
        "    reflect_set_i32(s, \"score\", 42)\n",
        "    println(f\"{s.score}\")\n",
        "    reflect_set_i32(s, \"nonexistent\", 999)\n",
        "    println(f\"{s.score}\")\n",
    );
    let output = compile_and_run("reflect_i32_round_trip", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["10", "120", "0", "42", "42"], "{}", stdout);
}

/// Same round trip, `float` field.
#[test]
fn runtime_reflect_get_set_f32_round_trip_end_to_end() {
    let src = concat!(
        "struct Tuning:\n",
        "    @tweakable mut gravity: float = 0.12\n",
        "\n",
        "fn main():\n",
        "    let mut t = Tuning(gravity = 0.12)\n",
        "    let a = reflect_get_f32(t, \"gravity\")\n",
        "    println(f\"{a}\")\n",
        "    reflect_set_f32(t, \"gravity\", 0.5)\n",
        "    println(f\"{t.gravity}\")\n",
        "    let b = reflect_get_f32(t, \"nonexistent\")\n",
        "    println(f\"{b}\")\n",
    );
    let output = compile_and_run("reflect_f32_round_trip", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["0.120000", "0.500000", "0.000000"], "{}", stdout);
}

/// Same round trip, `bool` field.
#[test]
fn runtime_reflect_get_set_bool_round_trip_end_to_end() {
    let src = concat!(
        "struct Tuning:\n",
        "    @tweakable mut particles_enabled: bool = true\n",
        "\n",
        "fn main():\n",
        "    let mut t = Tuning(particles_enabled = true)\n",
        "    let a = reflect_get_bool(t, \"particles_enabled\")\n",
        "    println(f\"{a}\")\n",
        "    reflect_set_bool(t, \"particles_enabled\", false)\n",
        "    println(f\"{t.particles_enabled}\")\n",
    );
    let output = compile_and_run("reflect_bool_round_trip", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "false"], "{}", stdout);
}

/// `reflect_has_field` is `true` for a decorated field, `false` for an
/// undecorated field of the same struct, and `false` for a name that
/// doesn't exist on the struct at all.
#[test]
fn runtime_reflect_has_field_end_to_end() {
    let src = concat!(
        "struct Stats:\n",
        "    @export mut score: i32 = 0\n",
        "    name: str = \"Hero\"\n",
        "\n",
        "fn main():\n",
        "    let s = Stats(score = 0, name = \"x\")\n",
        "    let a = reflect_has_field(s, \"score\")\n",
        "    let b = reflect_has_field(s, \"name\")\n",
        "    let c = reflect_has_field(s, \"nonexistent\")\n",
        "    println(f\"{a}\")\n",
        "    println(f\"{b}\")\n",
        "    println(f\"{c}\")\n",
    );
    let output = compile_and_run("reflect_has_field", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "false", "false"], "{}", stdout);
}

/// A decorated-but-not-`mut` field is excluded from `reflect_set_i32`'s
/// generated accessor entirely (`codegen_reflect_set_i32_accessor_excludes_non_mut_field`'s
/// runtime counterpart): writing to its name is a safe no-op, exactly as if
/// the name didn't match anything at all, while a genuinely `mut` decorated
/// field of the same struct still writes correctly.
#[test]
fn runtime_reflect_set_skips_non_mut_decorated_field_end_to_end() {
    let src = concat!(
        "struct Stats:\n",
        "    @export health: i32 = 100\n",
        "    @tweakable mut speed: i32 = 5\n",
        "\n",
        "fn main():\n",
        "    let mut s = Stats(health = 100, speed = 5)\n",
        "    reflect_set_i32(s, \"health\", 999)\n",
        "    reflect_set_i32(s, \"speed\", 42)\n",
        "    println(f\"{s.health}\")\n",
        "    println(f\"{s.speed}\")\n",
    );
    let output = compile_and_run("reflect_skips_non_mut", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["100", "42"], "{}", stdout);
}

/// `reflect_set_i32(self, ..)` works from inside an `impl` method exactly
/// like it does on an ordinary local -- `emit_place`'s `SelfExpr` arm
/// resolves `self` to a real pointer the same way plain `self.field`
/// codegen already does.
#[test]
fn runtime_reflect_via_self_in_method_end_to_end() {
    let src = concat!(
        "struct Stats:\n",
        "    @export mut score: i32 = 0\n",
        "\n",
        "impl Stats:\n",
        "    fn apply_tweak(mut self, name: str, value: i32):\n",
        "        reflect_set_i32(self, name, value)\n",
        "\n",
        "fn main():\n",
        "    let mut s = Stats(score = 5)\n",
        "    s.apply_tweak(\"score\", 77)\n",
        "    println(f\"{s.score}\")\n",
    );
    let output = compile_and_run("reflect_via_self", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["77"], "{}", stdout);
}

/// `reflect_set_i32` through a `Field` chain (`container.stats`, where
/// `stats` is itself a `mut` field of `Container`) resolves through
/// `emit_place`'s recursive `Field` arm to the real nested storage, and
/// `check_mut_receiver`'s field-level `mut` gate (`Checker::field_is_mut`)
/// correctly allows it since `stats` is declared `mut`.
#[test]
fn runtime_reflect_set_through_mut_field_chain_end_to_end() {
    let src = concat!(
        "struct Stats:\n",
        "    @export mut score: i32 = 0\n",
        "struct Container:\n",
        "    mut stats: Stats = Stats(score = 0)\n",
        "\n",
        "fn main():\n",
        "    let mut c = Container(stats = Stats(score = 1))\n",
        "    reflect_set_i32(c.stats, \"score\", 99)\n",
        "    println(f\"{c.stats.score}\")\n",
    );
    let output = compile_and_run("reflect_field_chain", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["99"], "{}", stdout);
}

/// Two unrelated structs decorating a field with the *same* name (`score`)
/// must not cross-contaminate -- each struct gets its own generated
/// accessor function (keyed by struct name), even though the underlying
/// `"score"` field-name string constant those two accessors' `strcmp`
/// chains compare against is deduplicated and shared between them
/// (`Codegen::reflect_name_ptr`).
#[test]
fn runtime_reflect_two_structs_with_same_field_name_do_not_collide_end_to_end() {
    let src = concat!(
        "struct A:\n",
        "    @export mut score: i32 = 0\n",
        "struct B:\n",
        "    @export mut score: i32 = 0\n",
        "\n",
        "fn main():\n",
        "    let mut a = A(score = 1)\n",
        "    let mut b = B(score = 2)\n",
        "    reflect_set_i32(a, \"score\", 111)\n",
        "    reflect_set_i32(b, \"score\", 222)\n",
        "    let av = reflect_get_i32(a, \"score\")\n",
        "    let bv = reflect_get_i32(b, \"score\")\n",
        "    println(f\"{av}\")\n",
        "    println(f\"{bv}\")\n",
    );
    let output = compile_and_run("reflect_two_structs_same_name", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["111", "222"], "{}", stdout);
}

/// A struct with several decorated `i32` fields resolves each runtime name
/// to the *correct* field, not just "the first one" or "the last one" --
/// exercising the generated `strcmp` chain past a single comparison.
#[test]
fn runtime_reflect_multiple_decorated_fields_picks_correct_one_end_to_end() {
    let src = concat!(
        "struct Stats:\n",
        "    @export mut a: i32 = 1\n",
        "    @export mut b: i32 = 2\n",
        "    @export mut c: i32 = 3\n",
        "    @export mut d: i32 = 4\n",
        "\n",
        "fn main():\n",
        "    let mut s = Stats(a = 1, b = 2, c = 3, d = 4)\n",
        "    let va = reflect_get_i32(s, \"a\")\n",
        "    let vb = reflect_get_i32(s, \"b\")\n",
        "    let vc = reflect_get_i32(s, \"c\")\n",
        "    let vd = reflect_get_i32(s, \"d\")\n",
        "    println(f\"{va}\")\n",
        "    println(f\"{vb}\")\n",
        "    println(f\"{vc}\")\n",
        "    println(f\"{vd}\")\n",
        "    reflect_set_i32(s, \"c\", 300)\n",
        "    println(f\"{s.a}\")\n",
        "    println(f\"{s.b}\")\n",
        "    println(f\"{s.c}\")\n",
        "    println(f\"{s.d}\")\n",
    );
    let output = compile_and_run("reflect_multi_field", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["1", "2", "3", "4", "1", "2", "300", "4"], "{}", stdout);
}

/// `@export` and `@tweakable` are interchangeable as far as
/// `reflect_get_*`/`reflect_set_*` are concerned -- either decorator alone
/// (or both stacked) makes a field reflectable, matching
/// `emit_reflect_metadata`'s own "any decorator at all" gate.
#[test]
fn runtime_reflect_export_and_tweakable_both_reflectable_end_to_end() {
    let src = concat!(
        "struct Stats:\n",
        "    @export mut exported_only: i32 = 1\n",
        "    @tweakable mut tweakable_only: i32 = 2\n",
        "    @export @tweakable mut both: i32 = 3\n",
        "\n",
        "fn main():\n",
        "    let mut s = Stats(exported_only = 1, tweakable_only = 2, both = 3)\n",
        "    reflect_set_i32(s, \"exported_only\", 10)\n",
        "    reflect_set_i32(s, \"tweakable_only\", 20)\n",
        "    reflect_set_i32(s, \"both\", 30)\n",
        "    println(f\"{s.exported_only}\")\n",
        "    println(f\"{s.tweakable_only}\")\n",
        "    println(f\"{s.both}\")\n",
    );
    let output = compile_and_run("reflect_export_tweakable", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["10", "20", "30"], "{}", stdout);
}

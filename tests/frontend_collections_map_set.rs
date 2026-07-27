//! `Map<K,V>` / `Set<T>` plus hash-table backing
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Map<K,V> / Set<T> ====================================================

/// `Map<K,V>()`/`Set<T>()` need an explicit turbofish -- there's nothing to
/// infer a type from otherwise (mirrors `rejects_list_new_without_type_arg`).
#[test]
fn rejects_map_new_without_type_args() {
    let module = Driver::parse("fn t():\n    let m = Map()\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "`Map()` with no type arguments should be a type error");
}

#[test]
fn rejects_set_new_without_type_arg() {
    let module = Driver::parse("fn t():\n    let s = Set()\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "`Set()` with no type argument should be a type error");
}

/// A `Map`/`Set` key/element type must be structurally hashable
/// (`Checker::check_hashable_ty`); `List<T>`/`GenRef<T>` have no
/// hashing/equality story and are rejected with a clear diagnostic instead
/// of an opaque later failure.
#[test]
fn rejects_non_hashable_map_key() {
    let module = Driver::parse("fn t():\n    let m = Map<List<i32>, i32>()\n").expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("List<T> as a Map key should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("cannot be used as a")), "{:?}", diags);
}

#[test]
fn rejects_non_hashable_set_element() {
    let module = Driver::parse("arena Entities: i32\nfn t():\n    let s = Set<GenRef<i32>>()\n").expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("GenRef<T> as a Set element should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("cannot be used as a")), "{:?}", diags);
}

/// A payload-carrying enum is not yet a supported `Map`/`Set` key type (see
/// `Checker::check_hashable_ty`'s doc comment on the current scope cut); a
/// fieldless enum is fine (exercised end-to-end by `Set<Point>` below, which
/// covers the struct-key path -- a fieldless-enum key is the same
/// `icmp eq i32` shape as a plain `i32` key, so no separate runtime test).
#[test]
fn rejects_payload_enum_as_map_key() {
    let src = "enum Shape:\n    Circle(radius: i32)\nfn t():\n    let m = Map<Shape, i32>()\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("a payload enum as a Map key should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("payload-carrying enums")), "{:?}", diags);
}

/// A struct is a hashable key only if every one of its fields, recursively,
/// is itself hashable.
#[test]
fn rejects_struct_with_non_hashable_field_as_map_key() {
    let src = "struct Bag:\n    items: List<i32>\nfn t():\n    let m = Map<Bag, i32>()\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "a struct with a non-hashable field should be a type error as a Map key");
}

// --- NOTES.md 2.4: fieldless-enum/struct `==`/`!=` -----------------------
//
// `Checker::infer_binop_ty` used to reject `Direction == Direction`/
// `Cell == Cell` outright for *every* user `enum`/`struct`, even though the
// exact same shapes were already legal `Map`/`Set` keys via a generated
// structural-equality function (`Checker::check_hashable_ty` /
// `crate::codegen::eq`). The fix reuses that existing hashability rule (via
// a new silent probe, `Checker::is_structurally_comparable_ty`, factored out
// of `check_hashable_ty`'s reporting version) to legalize `==`/`!=` for
// exactly the same fieldless-enum/comparable-struct shapes, and reuses
// `Codegen::eq_fn_name`/`emit_eq_body` at codegen time to actually implement
// it, instead of inventing a second comparison story.

/// A fieldless enum supports `==`/`!=` directly now -- `grid.star`'s
/// `dir_name`-adjacent `cell_eq`/direction-reversal workarounds existed
/// specifically because this didn't type-check before.
#[test]
fn accepts_fieldless_enum_equality() {
    let src = "enum Direction:\n    Up\n    Down\nfn same(a: Direction, b: Direction) -> bool:\n    return a == b\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "fieldless enum `==` should type-check: {:?}", Driver::check(&module).err());
}

/// `!=` is accepted the same way `==` is.
#[test]
fn accepts_fieldless_enum_inequality() {
    let src = "enum Direction:\n    Up\n    Down\nfn differ(a: Direction, b: Direction) -> bool:\n    return a != b\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "fieldless enum `!=` should type-check: {:?}", Driver::check(&module).err());
}

/// A struct composed entirely of structurally-comparable fields (here two
/// plain `i32`s, `grid.star`'s own `Cell` shape) supports `==` directly.
#[test]
fn accepts_struct_equality_when_fields_comparable() {
    let src = "struct Cell:\n    x: i32\n    y: i32\nfn same(a: Cell, b: Cell) -> bool:\n    return a == b\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "struct `==` over comparable fields should type-check: {:?}", Driver::check(&module).err());
}

/// The comparability rule recurses: a struct containing a nested struct
/// (itself composed of comparable fields) is still comparable.
#[test]
fn accepts_nested_struct_equality() {
    let src = concat!(
        "struct Cell:\n    x: i32\n    y: i32\n",
        "struct Segment:\n    head: Cell\n    tail: Cell\n",
        "fn same(a: Segment, b: Segment) -> bool:\n    return a == b\n",
    );
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "nested-struct `==` should type-check: {:?}", Driver::check(&module).err());
}

/// A struct containing a `str` field is still comparable (`str` itself
/// supports structural `==`), matching `check_hashable_ty`'s own rule.
#[test]
fn accepts_struct_with_str_field_equality() {
    let src = "struct Named:\n    label: str\n    id: i32\nfn same(a: Named, b: Named) -> bool:\n    return a == b\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "struct with a `str` field `==` should type-check: {:?}", Driver::check(&module).err());
}

/// A payload-carrying enum is still rejected -- `check_hashable_ty`'s
/// existing scope cut (no `Map`/`Set` key support for one either) applies
/// identically to `==`/`!=`, with a message naming the actual reason instead
/// of a generic "not supported between" fallback.
#[test]
fn rejects_payload_enum_equality() {
    let src = "enum Shape:\n    Circle(radius: i32)\n    Point\nfn same(a: Shape, b: Shape) -> bool:\n    return a == b\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("payload enum `==` should still be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("payload-carrying")), "{:?}", diags);
}

/// A struct containing a non-comparable field (`List<i32>`, no hashing/
/// equality story) is rejected for `==`, mirroring
/// `rejects_struct_with_non_hashable_field_as_map_key`.
#[test]
fn rejects_struct_equality_with_non_comparable_field() {
    let src = "struct Bag:\n    items: List<i32>\nfn same(a: Bag, b: Bag) -> bool:\n    return a == b\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("struct with a List field `==` should still be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("==")), "{:?}", diags);
}

/// A struct containing a `GenRef<T>` field is rejected the same way.
#[test]
fn rejects_struct_equality_with_genref_field() {
    let src = "struct Enemy:\n    hp: i32\narena Enemies: Enemy\nstruct Ref:\n    r: GenRef<Enemy>\nfn same(a: Ref, b: Ref) -> bool:\n    return a == b\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "struct with a GenRef field `==` should be a type error");
}

/// Ordering operators are still rejected for a fieldless enum -- only
/// `==`/`!=` get the new support, same "no meaningful less-than" reasoning
/// `Ty::BitField`/`Ty::Symbol` already carry.
#[test]
fn rejects_ordering_between_fieldless_enums() {
    let src = "enum Direction:\n    Up\n    Down\nfn cmp(a: Direction, b: Direction) -> bool:\n    return a < b\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("`<` between enums should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("only") && d.message.contains("==")), "{:?}", diags);
}

/// Ordering operators are still rejected for a comparable struct.
#[test]
fn rejects_ordering_between_structs() {
    let src = "struct Cell:\n    x: i32\n    y: i32\nfn cmp(a: Cell, b: Cell) -> bool:\n    return a > b\n";
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("`>` between structs should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("only") && d.message.contains("==")), "{:?}", diags);
}

/// Two distinct enum types can never be compared -- `lhs_ty == rhs_ty` is a
/// precondition of the new arm, so a mismatched pair falls through to the
/// pre-existing generic "not supported between" diagnostic rather than
/// silently type-checking.
#[test]
fn rejects_equality_between_mismatched_enum_types() {
    let src = "enum A:\n    X\nenum B:\n    Y\nfn same(a: A, b: B) -> bool:\n    return a == b\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "`==` between two different enum types should be a type error");
}

/// Two distinct struct types can never be compared either.
#[test]
fn rejects_equality_between_mismatched_struct_types() {
    let src = "struct Cell:\n    x: i32\nstruct Point:\n    x: i32\nfn same(a: Cell, b: Point) -> bool:\n    return a == b\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_err(), "`==` between two different struct types should be a type error");
}

/// A tuple gets exactly the same comparability rule as a struct (it's
/// already a legal `Map`/`Set` key/element under the identical rule -- see
/// `accepts_tuple_as_set_element_when_all_elements_hashable`), so `==`
/// should work on one too.
#[test]
fn accepts_tuple_equality() {
    let src = "fn same(a: (i32, i32), b: (i32, i32)) -> bool:\n    return a == b\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "tuple `==` should type-check: {:?}", Driver::check(&module).err());
}

/// A fixed-size array gets the same comparability rule too.
#[test]
fn accepts_array_equality() {
    let src = "fn same(a: [i32; 3], b: [i32; 3]) -> bool:\n    return a == b\n";
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "array `==` should type-check: {:?}", Driver::check(&module).err());
}

/// Runtime test: tuple/array equality is structural, element-by-element.
#[test]
fn runtime_tuple_and_array_equality_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let ta = (1, 2)\n",
        "    let tb = (1, 2)\n",
        "    let tc = (1, 3)\n",
        "    let aa = [1; 3]\n",
        "    let ab = [1; 3]\n",
        "    let mut ac = [1; 3]\n",
        "    ac[2] = 2\n",
        "    println(f\"{ta == tb} {ta == tc} {aa == ab} {aa == ac}\")\n",
    );
    let output = compile_and_run("tuple_array_equality", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.replace("\r\n", "\n").trim_end(), "true false true false", "{}", stdout);
}

/// Codegen test: `Direction == Direction` should lower to a call into a
/// generated `eq_<mangled>` function (the same machinery `Map`/`Set` key
/// lookup already uses -- see `crate::codegen::eq`), not an ad-hoc inline
/// comparison, so any future fix to `emit_eq_body` automatically covers this
/// operator too.
#[test]
fn codegen_enum_equality_calls_generated_eq_fn() {
    let src = "enum Direction:\n    Up\n    Down\nfn same(a: Direction, b: Direction) -> bool:\n    return a == b\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("call i1 @eq_"), "enum `==` should call a generated eq_ function: {}", ir);
}

/// Same codegen shape for a struct.
#[test]
fn codegen_struct_equality_calls_generated_eq_fn() {
    let src = "struct Cell:\n    x: i32\n    y: i32\nfn same(a: Cell, b: Cell) -> bool:\n    return a == b\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("call i1 @eq_"), "struct `==` should call a generated eq_ function: {}", ir);
}

/// `!=` should negate the generated `eq_` call's result rather than
/// generating a wholly separate not-equal comparison function.
#[test]
fn codegen_struct_inequality_negates_generated_eq_fn() {
    let src = "struct Cell:\n    x: i32\n    y: i32\nfn differ(a: Cell, b: Cell) -> bool:\n    return a != b\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("call i1 @eq_"), "struct `!=` should still call the generated eq_ function: {}", ir);
    assert!(ir.contains("xor i1"), "struct `!=` should negate the eq_ call's result via xor: {}", ir);
}

/// Runtime test: a fieldless enum's `==`/`!=` actually compares by
/// discriminant, matching same-variant values as equal and different
/// variants as unequal in both directions.
#[test]
fn runtime_fieldless_enum_equality_end_to_end() {
    let src = concat!(
        "enum Direction:\n    Up\n    Down\n    Left\n    Right\n",
        "fn main():\n",
        "    let a = Direction::Up\n",
        "    let b = Direction::Up\n",
        "    let c = Direction::Down\n",
        "    println(f\"{a == b} {a == c} {a != b} {a != c}\")\n",
    );
    let output = compile_and_run("fieldless_enum_equality", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.replace("\r\n", "\n").trim_end(), "true false false true", "{}", stdout);
}

/// Runtime test: struct equality is structural (field-by-field), not
/// pointer/identity-based -- two independently constructed `Cell` values
/// with the same field contents must compare equal.
#[test]
fn runtime_struct_equality_end_to_end() {
    let src = concat!(
        "struct Cell:\n    x: i32\n    y: i32\n",
        "fn main():\n",
        "    let a = Cell(3, 4)\n",
        "    let b = Cell(3, 4)\n",
        "    let c = Cell(3, 5)\n",
        "    println(f\"{a == b} {a == c} {a != c}\")\n",
    );
    let output = compile_and_run("struct_equality", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.replace("\r\n", "\n").trim_end(), "true false true", "{}", stdout);
}

/// Runtime test: nested-struct equality recurses field-by-field into the
/// inner struct too, not just a shallow top-level comparison.
#[test]
fn runtime_nested_struct_equality_end_to_end() {
    let src = concat!(
        "struct Cell:\n    x: i32\n    y: i32\n",
        "struct Segment:\n    head: Cell\n    tail: Cell\n",
        "fn main():\n",
        "    let a = Segment(Cell(0, 0), Cell(1, 1))\n",
        "    let b = Segment(Cell(0, 0), Cell(1, 1))\n",
        "    let c = Segment(Cell(0, 0), Cell(1, 2))\n",
        "    println(f\"{a == b} {a == c}\")\n",
    );
    let output = compile_and_run("nested_struct_equality", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.replace("\r\n", "\n").trim_end(), "true false", "{}", stdout);
}

/// Runtime test: a struct with a `str` field compares by string *content*
/// (`strcmp`-backed structural equality, see `crate::codegen::eq`'s `Str`
/// arm), not by pointer identity -- two independently-built strings with
/// the same characters must compare equal.
#[test]
fn runtime_struct_with_str_field_equality_end_to_end() {
    let src = concat!(
        "struct Named:\n    label: str\n    id: i32\n",
        "fn main():\n",
        "    let a = Named(\"snake\", 1)\n",
        "    let b = Named(concat(\"sna\", \"ke\"), 1)\n",
        "    let c = Named(\"snake\", 2)\n",
        "    println(f\"{a == b} {a == c}\")\n",
    );
    let output = compile_and_run("struct_str_field_equality", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.replace("\r\n", "\n").trim_end(), "true false", "{}", stdout);
}

/// Runtime test: comparing structs with `str` fields inside a loop must not
/// crash or corrupt the heap -- exercises `emit_release_bare`'s transient
/// release of each side's `str` field after the `eq_fn` call, repeated
/// enough times that a double-free or a leaked/under-released refcount would
/// reliably crash or (at minimum) be caught by a future allocator-sanity
/// check, rather than being a one-shot fluke.
#[test]
fn runtime_repeated_struct_str_equality_does_not_corrupt_heap_end_to_end() {
    let src = concat!(
        "struct Named:\n    label: str\n    id: i32\n",
        "fn main():\n",
        "    let mut matches = 0\n",
        "    let mut i = 0\n",
        "    while i < 2000:\n",
        "        let a = Named(concat(\"snake-\", \"x\"), i)\n",
        "        let b = Named(concat(\"snake-\", \"x\"), i)\n",
        "        if a == b:\n",
        "            matches = matches + 1\n",
        "        i = i + 1\n",
        "    println(f\"{matches}\")\n",
    );
    let output = compile_and_run("struct_str_equality_loop", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.replace("\r\n", "\n").trim_end(), "2000", "{}", stdout);
}

/// Runtime test: struct/enum equality composes correctly with `Set<T>` --
/// the new `==` operator and the pre-existing `Map`/`Set` structural
/// equality must agree (both are backed by the exact same `eq_fn_name`), so
/// a value considered `==` to another must also be indistinguishable as a
/// `Set` element (inserting both only grows the set by one).
#[test]
fn runtime_struct_equality_agrees_with_set_dedup_end_to_end() {
    let src = concat!(
        "struct Cell:\n    x: i32\n    y: i32\n",
        "fn main():\n",
        "    let a = Cell(2, 2)\n",
        "    let b = Cell(2, 2)\n",
        "    let mut s = Set<Cell>()\n",
        "    s.insert(a)\n",
        "    s.insert(b)\n",
        "    println(f\"{a == b} {s.len()}\")\n",
    );
    let output = compile_and_run("struct_equality_agrees_with_set", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.replace("\r\n", "\n").trim_end(), "true 1", "{}", stdout);
}

/// `.get(k)` on a `Map<K,V>` returns a real `Option<V>` -- the same builtin
/// generic enum `?`/`match` already work with, not a bespoke type.
#[test]
fn checks_map_get_returns_option_of_value_type() {
    let module = Driver::parse("fn t(m: Map<str, i32>) -> i32:\n    match m.get(\"k\"):\n        Option::Some(v) -> v\n        Option::None -> -1\n").expect("should parse");
    assert!(Driver::check(&module).is_ok(), "Map::get's Option<V> should match against Option::Some/None: {:?}", Driver::check(&module).err());
}

/// Passing the wrong key type to `.insert`/`.get`/`.contains`/`.remove` is a
/// type error (mirrors `rejects_list_push_wrong_type`).
#[test]
fn rejects_map_insert_wrong_key_type() {
    let module = Driver::parse("fn t(mut m: Map<str, i32>):\n    m.insert(5, 1)\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "inserting a mismatched key type should be a type error");
}

/// An unrecognized method name on a `Map<K,V>`/`Set<T>` receiver is a type
/// error (mirrors `rejects_unknown_list_method`).
#[test]
fn rejects_unknown_map_method() {
    let module = Driver::parse("fn t(m: Map<str, i32>):\n    m.keys()\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "an unknown Map<K,V> method should be a type error");
}

#[test]
fn rejects_unknown_set_method() {
    let module = Driver::parse("fn t(s: Set<i32>):\n    s.sort()\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "an unknown Set<T> method should be a type error");
}

/// Codegen-shape: a `Map<str,i32>`'s `.get`/`.insert` generate the
/// structural-equality function for `str` keys (`@eq_str`, calling
/// `@strcmp`) and the release thunk, rather than any hashing/bucketing
/// machinery -- confirming the documented linear-scan implementation
/// strategy (`crate::codegen::eq`/`crate::codegen::map`'s doc comments).
#[test]
fn codegen_map_generates_str_eq_fn_using_strcmp() {
    let src = "fn t(mut m: Map<str, i32>):\n    m.insert(\"k\", 1)\n    m.get(\"k\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("define i1 @eq_str("), "{}", ir);
    assert!(ir.contains("call i32 @strcmp("), "{}", ir);
    assert!(ir.contains("define void @map_release_"), "{}", ir);
}

/// Runtime test: `examples/map_set.exe` exercises `Map<str,i32>` (insert,
/// overwrite-on-duplicate-key, get-hit/get-miss via `Option<V>`, contains,
/// remove) and `Set<T>` for both a primitive element type (`i32`,
/// insert/dup-insert/contains/remove) and a struct element type (`Point`,
/// exercising the recursive structural-equality codegen path) end to end
/// through a real clang-compiled executable.
#[test]
fn runtime_map_set_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/map_set.exe").output().expect("failed to execute map_set.exe");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("len after 2 inserts: 2"), "{}", stdout);
    assert!(stdout.contains("alice: 30"), "Map::get hit: {}", stdout);
    assert!(stdout.contains("carol: missing"), "Map::get miss: {}", stdout);
    assert!(stdout.contains("len after overwrite: 2"), "insert on an existing key overwrites rather than growing: {}", stdout);
    assert!(stdout.contains("alice after overwrite: 31"), "{}", stdout);
    assert!(stdout.contains("contains bob: true"), "{}", stdout);
    assert!(stdout.contains("removed bob: 25"), "Map::remove returns the removed value: {}", stdout);
    assert!(stdout.contains("contains bob after remove: false"), "{}", stdout);
    assert!(stdout.contains("len after remove: 1"), "{}", stdout);
    assert!(stdout.contains("insert 1 (new): true"), "Set::insert reports true for a new element: {}", stdout);
    assert!(stdout.contains("insert 2 (new): true"), "{}", stdout);
    assert!(stdout.contains("insert 1 (dup): false"), "Set::insert reports false for a duplicate: {}", stdout);
    assert!(stdout.contains("set len: 2"), "duplicate insert does not grow the set: {}", stdout);
    assert!(stdout.contains("contains 2: true"), "{}", stdout);
    assert!(stdout.contains("remove 2: true"), "{}", stdout);
    assert!(stdout.contains("contains 2 after remove: false"), "{}", stdout);
    assert!(stdout.contains("remove 2 again: false"), "Set::remove reports false when the element is absent: {}", stdout);
    assert!(stdout.contains("set len after removes: 1"), "{}", stdout);
    assert!(stdout.contains("struct set len: 2"), "Set<Point> deduplicates a structurally-equal struct inserted twice: {}", stdout);
    assert!(stdout.contains("contains (1,2): true"), "struct structural-equality match: {}", stdout);
    assert!(stdout.contains("contains (9,9): false"), "struct structural-equality non-match: {}", stdout);
}

// ===== Map<K,V>/Set<T> bug-hunting round (this pass) =======================

/// A read-only `Map` method (`.get`/`.contains`/`.len`) called on a receiver
/// reached through a list index (`maps[0].get(k)`) must not trigger the
/// copy-on-write uniqueness gate on the *outer* list -- same bug class as
/// the already-fixed `codegen_nested_list_index_read_does_not_trigger_cow_clone`
/// (`list_fields`'s `ListIndex`-base fast path), just never applied to
/// `map_fields` when this feature was added: it resolved `base` through
/// `Codegen::emit_place` directly, whose `ListIndex` arm is a write path
/// that unconditionally clones/un-aliases the *outer list* via
/// `emit_list_ensure_unique` (identifiable by the `list_cow_clone` block it
/// emits -- the receiver here is `List<Map<str,i32>>`, so it's the outer
/// list's own clone marker, not the inner map's `map_cow_clone`). Fixed by
/// routing `map_fields` through `Codegen::emit_read_place`.
#[test]
fn codegen_map_method_on_list_index_receiver_does_not_trigger_cow_clone() {
    let src = "fn t(maps: List<Map<str, i32>>) -> i32:\n    let found = maps[0].contains(\"k\")\n    maps[0].len()\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i32 @t(");
    assert!(!fn_ir.contains("list_cow_clone"), "a pure Map read through a list index must not clone/unshare the outer list: {}", fn_ir);
}

/// Same nested shape, but a *write* (`maps[0].insert(k, v)`) still must run
/// the copy-on-write gate on the outer list -- a regression guard alongside
/// the read test above so the fix doesn't overcorrect into skipping a
/// uniqueness check a real mutation still needs (mirrors
/// `codegen_nested_list_index_write_still_triggers_cow_clone`).
#[test]
fn codegen_map_method_on_list_index_receiver_write_still_triggers_cow_clone() {
    let module = Driver::parse("fn t(mut maps: List<Map<str, i32>>):\n    maps[0].insert(\"k\", 1)\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("list_cow_clone"), "a Map mutation through a list index must still uniquify the outer list: {}", ir);
}

/// The same bug, one level deeper: a `Map` reached through a *struct field*
/// behind a list index (`points[0].scores.get(k)`) must also not clone the
/// outer list -- `map_fields` only special-cased `base` itself being a
/// `ListIndex` directly, not a `Field` wrapping one, so this shape still hit
/// `emit_place`'s write path even after the direct-`ListIndex` case is
/// fixed. `Codegen::emit_read_place` recurses through `Field` to close this.
#[test]
fn codegen_map_method_on_field_behind_list_index_does_not_trigger_cow_clone() {
    let src = "struct Player:\n    scores: Map<str, i32>\nfn t(players: List<Player>) -> i32:\n    players[0].scores.len()\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i32 @t(");
    assert!(!fn_ir.contains("list_cow_clone"), "a Map field read behind a list index must not clone/unshare the outer list: {}", fn_ir);
}

/// `Set<T>`'s equivalent of the two tests above: a read-only method
/// (`.contains`/`.len`) on a `Set` reached through a list index
/// (`sets[0].contains(x)`) must not trigger the outer *list's*
/// copy-on-write gate (`list_cow_clone`), but a mutation (`.insert`/
/// `.remove`) still must.
#[test]
fn codegen_set_method_on_list_index_receiver_does_not_trigger_cow_clone() {
    let module = Driver::parse("fn t(sets: List<Set<i32>>) -> i32:\n    sets[0].len()\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define i32 @t(");
    assert!(!fn_ir.contains("list_cow_clone"), "a pure Set read through a list index must not clone/unshare the outer list: {}", fn_ir);
}

#[test]
fn codegen_set_method_on_list_index_receiver_write_still_triggers_cow_clone() {
    let module = Driver::parse("fn t(mut sets: List<Set<i32>>):\n    sets[0].insert(5)\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("list_cow_clone"), "a Set mutation through a list index must still uniquify the outer list: {}", ir);
}

/// Functional companion to the codegen-shape tests above (mirrors
/// `runtime_nested_list_read_then_mutate_preserves_cow_isolation_end_to_end`'s
/// own reasoning): a pure `Map` read through a list index must not un-alias
/// two variables sharing the same outer list's buffer, so a subsequent
/// mutation through one is still invisible through the other, exactly as
/// plain copy-on-write semantics predict. Can't distinguish "never cloned"
/// from "cloned-then-still-correctly-isolated" by final values alone --
/// the `codegen_map_method_on_list_index_receiver_does_not_trigger_cow_clone`
/// test above is what actually pins the fix; this guards against a botched
/// fix breaking ordinary COW isolation.
#[test]
fn runtime_map_method_on_list_index_receiver_preserves_cow_isolation_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let mut m: List<Map<str, i32>> = [Map<str, i32>()]\n",
        "    m[0].insert(\"k\", 1)\n",
        "    let n = m\n",
        "    let found = n[0].contains(\"k\")\n",
        "    m[0].insert(\"k2\", 2)\n",
        "    println(f\"found={found} m0len={m[0].len()} n0len={n[0].len()}\")\n",
    );
    let output = compile_and_run("map_list_index_read_then_mutate", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim_end(), "found=true m0len=2 n0len=1", "{}", stdout);
}

/// `Map::remove`'s swap-remove (`crate::codegen::map`'s `MapMethod::Remove`)
/// must not retain the *swapped-in last value* -- it previously called
/// `emit_retain_at(&val_ptr, val_ty)` *after* storing the last element into
/// `val_ptr`, so the retain landed on the relocated last value (which needs
/// none -- same object, same owner, just moved to a new array slot, exactly
/// like `ListMethod::Pop`'s zero-retain convention) instead of the actually-
/// removed value (which needs none either -- its map-owned reference
/// transfers straight into the returned `Some(v)`, a net-zero move). The
/// bug was a permanent, unbalanced +1 refcount leak on the swapped element
/// every time a non-last key was removed from an RC-valued `Map`.
#[test]
fn codegen_map_remove_swap_does_not_retain_swapped_in_value() {
    let src = "fn t(mut m: Map<i32, str>):\n    m.remove(1)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let fn_ir = extract_fn_body(&ir, "define void @t(");
    // Scoped to the `map_remove_some` block specifically (not the whole
    // function): `emit_map_ensure_unique`'s own CoW-clone path legitimately
    // retains every copied element while cloning the map's buffer (a
    // separate, correct retain loop, unconditionally present in the IR
    // regardless of whether it's ever taken at runtime) -- that's not the
    // bug this test pins, so checking the whole function would false-positive
    // on it.
    let some_block_start = fn_ir.find("map_remove_some_").expect("expected a map_remove_some block");
    let some_block_end = fn_ir[some_block_start..].find("map_remove_end_").map(|i| some_block_start + i).unwrap_or(fn_ir.len());
    let some_block = &fn_ir[some_block_start..some_block_end];
    assert!(
        !some_block.contains("star_rc_retain"),
        "Map::remove's swap-remove must not retain the swapped-in last value: {}",
        some_block
    );
}

/// Runtime companion to the codegen-shape retain test above: removing a
/// non-last key from a `Map<i32, str>` must still return the *correct*
/// removed value (not the swapped-in one) and leave the map's remaining
/// entries intact -- guards against a fix that silently breaks correctness
/// while chasing the leak (e.g. dropping the removed value's own content
/// instead of just the erroneous retain).
#[test]
fn runtime_map_remove_swap_returns_correct_value_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let mut m: Map<i32, str> = Map<i32, str>()\n",
        "    m.insert(1, \"one\")\n",
        "    m.insert(2, \"two\")\n",
        "    m.insert(3, \"three\")\n",
        "    match m.remove(1):\n",
        "        Option::Some(v) -> println(f\"removed={v}\")\n",
        "        Option::None -> println(\"removed=none\")\n",
        "    println(f\"len={m.len()} contains3={m.contains(3)} contains2={m.contains(2)}\")\n",
    );
    let output = compile_and_run("map_remove_swap_value", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["removed=one", "len=2 contains3=true contains2=true"], "{}", stdout);
}

/// `Codegen::mangle_ty`'s `Ty::Map` arm previously joined the key/value
/// mangled segments with a bare `_`, ambiguous whenever a struct name
/// itself contains `_` (`Ty::Named` mangles as `s_<name>`): e.g.
/// `Map<a_s_b, c>` and `Map<a, b_s_c>` both mangled to the identical string
/// `map_s_a_s_b_s_c`, so the second Map's release-thunk cache lookup would
/// silently reuse the first's already-generated thunk -- a function whose
/// body is baked with the *wrong* struct's field layout/GEP indices/sizes.
/// Fixed by length-prefixing the key segment so the K/V boundary is
/// unambiguous. That exact adversarial pair can't be spelled in real Star
/// source (a struct name must start uppercase to be usable as a constructor
/// call), so it's pinned directly against `Codegen::mangle_ty` in
/// `src/codegen/mod.rs`'s own `#[cfg(test)]` module instead
/// (`mangle_ty_map_key_value_boundary_is_unambiguous_across_underscore_names`);
/// this is the parseable end-to-end companion, confirming two structurally
/// distinct `Map<K,V>` instantiations that share a `_`-containing key/value
/// name each still get their own, distinct release thunk through the real
/// pipeline.
#[test]
fn codegen_map_release_thunk_names_dont_collide_across_underscore_ambiguous_structs() {
    let src = concat!(
        "struct A_s_b:\n    v: i32\n",
        "struct C:\n    v: i32\n",
        "struct A:\n    v: i32\n",
        "struct B_s_c:\n    v: i32\n",
        "fn t():\n",
        "    let mut m1 = Map<A_s_b, C>()\n",
        "    let mut m2 = Map<A, B_s_c>()\n",
        "    m1.insert(A_s_b(1), C(2))\n",
        "    m2.insert(A(1), B_s_c(2))\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let thunk_count = ir.matches("define void @map_release_").count();
    assert_eq!(
        thunk_count, 2,
        "Map<A_s_b,C> and Map<A,B_s_c> must each get their own release thunk: {}",
        ir
    );
}

/// `mut` enforcement (todo.md's "mut is required to change state" work) was
/// never wired up for any mutating *method* call -- only plain `x = value`
/// assignment was checked, so `List::push`/`pop`, `Map::insert`/`remove`,
/// and `Set::insert`/`remove` all silently allowed mutating a non-`mut`
/// binding/parameter/field through a method call. The following tests pin
/// the fix for every one of those six methods, plus confirm the `mut` case
/// still type-checks cleanly (no false positives).
#[test]
fn rejects_list_push_on_non_mut_receiver() {
    let module = Driver::parse("fn t(nums: List<i32>):\n    nums.push(1)\n").expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("push on a non-mut List should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("not declared `mut`")), "{:?}", diags);
}

#[test]
fn rejects_list_pop_on_non_mut_receiver() {
    let module = Driver::parse("fn t(nums: List<i32>):\n    nums.pop()\n").expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("pop on a non-mut List should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("not declared `mut`")), "{:?}", diags);
}

#[test]
fn rejects_map_insert_on_non_mut_receiver() {
    let module = Driver::parse("fn t(m: Map<str, i32>):\n    m.insert(\"k\", 1)\n").expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("insert on a non-mut Map should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("not declared `mut`")), "{:?}", diags);
}

#[test]
fn rejects_map_remove_on_non_mut_receiver() {
    let module = Driver::parse("fn t(m: Map<str, i32>):\n    m.remove(\"k\")\n").expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("remove on a non-mut Map should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("not declared `mut`")), "{:?}", diags);
}

#[test]
fn rejects_set_insert_on_non_mut_receiver() {
    let module = Driver::parse("fn t(s: Set<i32>):\n    s.insert(1)\n").expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("insert on a non-mut Set should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("not declared `mut`")), "{:?}", diags);
}

#[test]
fn rejects_set_remove_on_non_mut_receiver() {
    let module = Driver::parse("fn t(s: Set<i32>):\n    s.remove(1)\n").expect("should parse");
    let Err(diags) = Driver::check(&module) else { panic!("remove on a non-mut Set should be a type error") };
    assert!(diags.iter().any(|d| d.message.contains("not declared `mut`")), "{:?}", diags);
}

/// The positive case for all six methods above: a `mut`-declared receiver
/// must still type-check cleanly, whether it's a `mut` parameter, a plain
/// `let mut` local, or `self` on a `mut self` method -- no false positives
/// from the new check.
#[test]
fn accepts_mutating_collection_methods_on_mut_receivers() {
    let src = concat!(
        "struct Bag:\n",
        "    mut items: List<i32>\n",
        "    mut tags: Set<i32>\n",
        "impl Bag:\n",
        "    fn add(mut self, x: i32):\n",
        "        self.items.push(x)\n",
        "        self.tags.insert(x)\n",
        "fn t(mut nums: List<i32>, mut m: Map<str, i32>, mut s: Set<i32>):\n",
        "    nums.push(1)\n",
        "    nums.pop()\n",
        "    m.insert(\"k\", 1)\n",
        "    m.remove(\"k\")\n",
        "    s.insert(1)\n",
        "    s.remove(1)\n",
    );
    let module = Driver::parse(src).expect("should parse");
    assert!(Driver::check(&module).is_ok(), "mut receivers should type-check cleanly: {:?}", Driver::check(&module).err());
}

/// `check_mut_receiver` checked only the *root* binding (`self`/a variable)
/// against `mut_vars`, exactly like `Stmt::Assign` -- but `Stmt::Assign` also
/// separately re-checks the immediate field's own `mut` declaration via
/// `field_is_mut` (a field can be declared without `mut` even on a `mut`-bound
/// struct). `check_mut_receiver` never made that second check, so
/// `self.items.push(x)` on a non-`mut` `items: List<i32>` field silently
/// type-checked through a `mut self` method -- the exact same field-level
/// bypass `rejects_assignment_to_struct_field_not_declared_mut` already pins
/// for plain assignment, just reached through a mutating method call instead.
#[test]
fn rejects_list_push_on_non_mut_field_even_through_mut_self() {
    let src = concat!(
        "struct Player:\n",
        "    items: List<i32>\n",
        "impl Player:\n",
        "    fn add_item(mut self, x: i32):\n",
        "        self.items.push(x)\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("push on a non-`mut` field must be rejected even through a `mut self` receiver") };
    assert!(errs.iter().any(|d| d.message.contains("field `items` is not mutable")), "{:?}", errs);
}

/// Same gap, `Map<K,V>::insert` variant.
#[test]
fn rejects_map_insert_on_non_mut_field_even_through_mut_self() {
    let src = concat!(
        "struct Cache:\n",
        "    entries: Map<str, i32>\n",
        "impl Cache:\n",
        "    fn add(mut self, k: str, v: i32):\n",
        "        self.entries.insert(k, v)\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("insert on a non-`mut` field must be rejected even through a `mut self` receiver") };
    assert!(errs.iter().any(|d| d.message.contains("field `entries` is not mutable")), "{:?}", errs);
}

/// Same gap, `Set<T>::remove` variant.
#[test]
fn rejects_set_remove_on_non_mut_field_even_through_mut_self() {
    let src = concat!(
        "struct Tags:\n",
        "    values: Set<i32>\n",
        "impl Tags:\n",
        "    fn drop_tag(mut self, x: i32):\n",
        "        self.values.remove(x)\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let Err(errs) = Driver::check(&module) else { panic!("remove on a non-`mut` field must be rejected even through a `mut self` receiver") };
    assert!(errs.iter().any(|d| d.message.contains("field `values` is not mutable")), "{:?}", errs);
}

// ===== Map<K,V>/Set<T> hash-table backing (todo.md P0 #3) ==================
//
// `Map`/`Set` used to be a plain linear scan (`crate::codegen::eq`'s
// structural-equality function, `O(n)` per operation); they're now a real
// open-addressing hash table (`crate::codegen::hash`/`hashtable`) with
// growth and tombstone-based removal. These tests target exactly the
// behavior that scan-based implementation couldn't get wrong but a hash
// table can: growth/rehashing correctness at scale, tombstone-slot reuse
// after `remove`, structural-hash agreement with structural equality for
// aggregate key types, and the `cap == 0` (never-grown) edge case.

/// Codegen-shape companion to `codegen_map_generates_str_eq_fn_using_strcmp`:
/// a `Map<str,i32>` now also generates a structural-hash function for its
/// key type, not just the structural-equality one.
#[test]
fn codegen_map_generates_hash_str_fn_for_str_key() {
    let src = "fn t(mut m: Map<str, i32>):\n    m.insert(\"k\", 1)\n    m.get(\"k\")\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("define i64 @hash_str("), "{}", ir);
}

/// `Set<T>`'s equivalent of the test above.
#[test]
fn codegen_set_generates_hash_fn_for_element_type() {
    let module = Driver::parse("fn t(mut s: Set<i32>):\n    s.insert(1)\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("define i64 @hash_i32("), "{}", ir);
}

/// `Map<i32,i32>` through 300 keys' worth of churn: 200 inserts (forcing
/// several grows past the initial `cap = 8`), a full correctness pass over
/// every inserted key via `get`, two definite misses, removing every even
/// key (creating 100 tombstones), re-checking both the removed and
/// remaining halves, then inserting 100 *new* keys -- which must reuse the
/// tombstoned slots (and/or trigger another grow/rehash) rather than losing
/// or duplicating anything -- followed by one final full-range correctness
/// pass. A linear-scan implementation could never observe a growth or
/// tombstone bug; this is squarely the coverage a hash table needs that the
/// old implementation didn't.
#[test]
fn runtime_map_hash_table_growth_tombstone_reuse_and_correctness_end_to_end() {
    let src = concat!(
        "fn extract(o: Option<i32>) -> i32:\n",
        "    match o:\n",
        "        Option::Some(v) -> v\n",
        "        Option::None -> -999999\n",
        "\n",
        "fn main():\n",
        "    let mut m: Map<i32, i32> = Map<i32, i32>()\n",
        "    for i in 0..200:\n",
        "        m.insert(i, i * 7)\n",
        "    println(f\"len_after_insert={m.len()}\")\n",
        "\n",
        "    let mut all_correct = true\n",
        "    for i in 0..200:\n",
        "        if extract(m.get(i)) != i * 7:\n",
        "            all_correct = false\n",
        "    println(f\"all_correct={all_correct}\")\n",
        "\n",
        "    println(f\"contains_300={m.contains(300)}\")\n",
        "    println(f\"contains_neg1={m.contains(-1)}\")\n",
        "\n",
        "    let mut removed_correct = true\n",
        "    for i in 0..200:\n",
        "        if i % 2 == 0:\n",
        "            if extract(m.remove(i)) != i * 7:\n",
        "                removed_correct = false\n",
        "    println(f\"removed_correct={removed_correct}\")\n",
        "    println(f\"len_after_remove={m.len()}\")\n",
        "\n",
        "    let mut post_remove_correct = true\n",
        "    for i in 0..200:\n",
        "        if i % 2 == 0:\n",
        "            if m.contains(i):\n",
        "                post_remove_correct = false\n",
        "        else:\n",
        "            if extract(m.get(i)) != i * 7:\n",
        "                post_remove_correct = false\n",
        "    println(f\"post_remove_correct={post_remove_correct}\")\n",
        "\n",
        "    for i in 200..300:\n",
        "        m.insert(i, i * 7)\n",
        "    println(f\"len_after_refill={m.len()}\")\n",
        "\n",
        "    let mut final_correct = true\n",
        "    for i in 0..300:\n",
        "        if i < 200 and i % 2 == 0:\n",
        "            if m.contains(i):\n",
        "                final_correct = false\n",
        "        else:\n",
        "            if extract(m.get(i)) != i * 7:\n",
        "                final_correct = false\n",
        "    println(f\"final_correct={final_correct}\")\n",
    );
    let output = compile_and_run("map_hash_growth_tombstone", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(
        lines,
        vec![
            "len_after_insert=200",
            "all_correct=true",
            "contains_300=false",
            "contains_neg1=false",
            "removed_correct=true",
            "len_after_remove=100",
            "post_remove_correct=true",
            "len_after_refill=200",
            "final_correct=true",
        ],
        "{}",
        stdout
    );
}

/// `Set<i32>`'s equivalent of the `Map` growth/tombstone-reuse stress test
/// above: 150 inserts, a duplicate-insert pass (must report `false`/not grow
/// `len`), removing every multiple of 3, re-checking both halves, refilling
/// with 70 new elements, and a final full-range check.
#[test]
fn runtime_set_hash_table_growth_and_tombstone_reuse_correctness_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let mut s: Set<i32> = Set<i32>()\n",
        "    for i in 0..150:\n",
        "        s.insert(i)\n",
        "    println(f\"len_after_insert={s.len()}\")\n",
        "\n",
        "    let mut all_present = true\n",
        "    for i in 0..150:\n",
        "        if !s.contains(i):\n",
        "            all_present = false\n",
        "    println(f\"all_present={all_present}\")\n",
        "\n",
        "    let mut dup_rejected = true\n",
        "    for i in 0..150:\n",
        "        if s.insert(i):\n",
        "            dup_rejected = false\n",
        "    println(f\"dup_rejected={dup_rejected}\")\n",
        "    println(f\"len_after_dup_inserts={s.len()}\")\n",
        "\n",
        "    let mut removed_ok = true\n",
        "    for i in 0..150:\n",
        "        if i % 3 == 0:\n",
        "            if !s.remove(i):\n",
        "                removed_ok = false\n",
        "    println(f\"removed_ok={removed_ok}\")\n",
        "    println(f\"len_after_remove={s.len()}\")\n",
        "\n",
        "    let mut post_remove_ok = true\n",
        "    for i in 0..150:\n",
        "        if i % 3 == 0:\n",
        "            if s.contains(i):\n",
        "                post_remove_ok = false\n",
        "        else:\n",
        "            if !s.contains(i):\n",
        "                post_remove_ok = false\n",
        "    println(f\"post_remove_ok={post_remove_ok}\")\n",
        "\n",
        "    for i in 150..220:\n",
        "        s.insert(i)\n",
        "    println(f\"len_after_refill={s.len()}\")\n",
        "\n",
        "    let mut final_ok = true\n",
        "    for i in 0..220:\n",
        "        if i < 150 and i % 3 == 0:\n",
        "            if s.contains(i):\n",
        "                final_ok = false\n",
        "        else:\n",
        "            if !s.contains(i):\n",
        "                final_ok = false\n",
        "    println(f\"final_ok={final_ok}\")\n",
    );
    let output = compile_and_run("set_hash_growth_tombstone", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(
        lines,
        vec![
            "len_after_insert=150",
            "all_present=true",
            "dup_rejected=true",
            "len_after_dup_inserts=150",
            "removed_ok=true",
            "len_after_remove=100",
            "post_remove_ok=true",
            "len_after_refill=170",
            "final_ok=true",
        ],
        "{}",
        stdout
    );
}

/// A `Set<Point>` (a two-field struct key, `crate::codegen::hash`'s
/// `Ty::Named` recursion) inserted with 100 distinct values must end up with
/// `len == 100` -- if the structural hash function disagreed with the
/// structural equality function on any pair (e.g. an unmixed/truncated field
/// hash colliding two genuinely different points into the same probe chain
/// *and* the equality check being buggy enough to still treat them as equal
/// -- a real class of hash/eq-disagreement bug this test would catch even
/// though it wouldn't reliably catch a mere hash collision alone, since
/// open addressing already handles same-bucket-different-key correctly by
/// design). Also checks duplicate-insert dedup and both a near-miss and a
/// far-miss `contains` query.
#[test]
fn runtime_set_struct_key_distinct_values_do_not_collide_end_to_end() {
    let src = concat!(
        "struct Point:\n",
        "    x: i32\n",
        "    y: i32\n",
        "\n",
        "fn main():\n",
        "    let mut s: Set<Point> = Set<Point>()\n",
        "    for i in 0..100:\n",
        "        s.insert(Point(x = i, y = i * 2))\n",
        "    println(f\"len={s.len()}\")\n",
        "\n",
        "    s.insert(Point(x = 0, y = 0))\n",
        "    s.insert(Point(x = 50, y = 100))\n",
        "    println(f\"len_after_dup_inserts={s.len()}\")\n",
        "\n",
        "    let mut all_present = true\n",
        "    for i in 0..100:\n",
        "        if !s.contains(Point(x = i, y = i * 2)):\n",
        "            all_present = false\n",
        "    println(f\"all_present={all_present}\")\n",
        "\n",
        "    println(f\"contains_near_miss={s.contains(Point(x = 50, y = 99))}\")\n",
        "    println(f\"contains_far_miss={s.contains(Point(x = 500, y = 1000))}\")\n",
    );
    let output = compile_and_run("set_struct_key_no_collide", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(
        lines,
        vec![
            "len=100",
            "len_after_dup_inserts=100",
            "all_present=true",
            "contains_near_miss=false",
            "contains_far_miss=false",
        ],
        "{}",
        stdout
    );
}

/// `Map<str,str>` growth/removal/refill correctness -- the RC-bearing-key-
/// and-value variant of the `i32` stress test above, exercising the
/// generated release thunk's/CoW-clone's/grow-rehash's walk over the
/// `states` array for a type where a missed or double release would be a
/// real leak or use-after-free rather than just a wrong integer.
#[test]
fn runtime_map_str_key_and_value_growth_correctness_end_to_end() {
    let src = concat!(
        "fn extract(o: Option<str>) -> str:\n",
        "    match o:\n",
        "        Option::Some(v) -> v\n",
        "        Option::None -> \"MISSING\"\n",
        "\n",
        "fn main():\n",
        "    let mut m: Map<str, str> = Map<str, str>()\n",
        "    for i in 0..150:\n",
        "        m.insert(f\"k{i}\", f\"v{i}\")\n",
        "    println(f\"len_after_insert={m.len()}\")\n",
        "\n",
        "    let mut all_correct = true\n",
        "    for i in 0..150:\n",
        "        if extract(m.get(f\"k{i}\")) != f\"v{i}\":\n",
        "            all_correct = false\n",
        "    println(f\"all_correct={all_correct}\")\n",
        "\n",
        "    let mut removed_correct = true\n",
        "    for i in 0..150:\n",
        "        if i % 3 == 0:\n",
        "            if extract(m.remove(f\"k{i}\")) != f\"v{i}\":\n",
        "                removed_correct = false\n",
        "    println(f\"removed_correct={removed_correct}\")\n",
        "    println(f\"len_after_remove={m.len()}\")\n",
        "\n",
        "    for i in 150..220:\n",
        "        m.insert(f\"k{i}\", f\"v{i}\")\n",
        "    println(f\"len_after_refill={m.len()}\")\n",
        "\n",
        "    let mut final_correct = true\n",
        "    for i in 0..220:\n",
        "        if i < 150 and i % 3 == 0:\n",
        "            if m.contains(f\"k{i}\"):\n",
        "                final_correct = false\n",
        "        else:\n",
        "            if extract(m.get(f\"k{i}\")) != f\"v{i}\":\n",
        "                final_correct = false\n",
        "    println(f\"final_correct={final_correct}\")\n",
    );
    let output = compile_and_run("map_str_growth_correctness", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(
        lines,
        vec![
            "len_after_insert=150",
            "all_correct=true",
            "removed_correct=true",
            "len_after_remove=100",
            "len_after_refill=170",
            "final_correct=true",
        ],
        "{}",
        stdout
    );
}

/// `contains`/`remove` on a `Map`/`Set` that has *never* had anything
/// inserted (`cap == 0`, the `null`-object empty representation -- see
/// `crate::codegen::map`/`set`'s module doc comments) must not crash: probe
/// helpers compute `mask = cap - 1` unconditionally, and with `cap == 0`
/// that's `-1` (all bits set) -- safe only because the probe loop's own
/// `i < cap` bound (`cap == 0`) skips every body iteration that would
/// otherwise dereference the (null) `states`/`keys` pointers.
#[test]
fn runtime_map_and_set_remove_and_contains_on_never_inserted_do_not_crash_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let mut m: Map<i32, i32> = Map<i32, i32>()\n",
        "    println(f\"map_contains={m.contains(5)}\")\n",
        "    match m.remove(5):\n",
        "        Option::Some(v) -> println(f\"map_removed_some={v}\")\n",
        "        Option::None -> println(\"map_removed_none\")\n",
        "    println(f\"map_len={m.len()}\")\n",
        "\n",
        "    let mut s: Set<i32> = Set<i32>()\n",
        "    println(f\"set_contains={s.contains(5)}\")\n",
        "    println(f\"set_removed={s.remove(5)}\")\n",
        "    println(f\"set_len={s.len()}\")\n",
    );
    let output = compile_and_run("map_set_empty_no_crash", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(
        lines,
        vec!["map_contains=false", "map_removed_none", "map_len=0", "set_contains=false", "set_removed=false", "set_len=0",],
        "{}",
        stdout
    );
}

/// `Symbol`'s intern hash index (`@sym.tbl.ids`, `crate::codegen::symbol`)
/// through enough distinct strings (300) to force several grows/rebuilds:
/// every id must come out sequential (`0..300`, matching insertion order,
/// since every string here is unique -- no dedup ever kicks in) *and*
/// re-interning the exact same 300 strings afterward -- once the index has
/// been rebuilt from scratch multiple times -- must still recover the exact
/// same ids rather than minting duplicates. Also spot-checks `symbol_name`'s
/// reverse lookup still agrees after the index (but not the append-only
/// `@sym.data` log it's built from) has been through several grow/rebuild
/// cycles.
#[test]
fn runtime_symbol_intern_hash_index_growth_still_dedups_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let mut ids: List<i64> = List<i64>()\n",
        "    let mut i = 0\n",
        "    while i < 300:\n",
        "        let sym = Symbol(f\"sym{i}\")\n",
        "        ids.push(sym as i64)\n",
        "        i += 1\n",
        "\n",
        "    let mut sequential_ok = true\n",
        "    let mut j = 0\n",
        "    while j < 300:\n",
        "        if ids[j] != j as i64:\n",
        "            sequential_ok = false\n",
        "        j += 1\n",
        "    println(f\"sequential_ok={sequential_ok}\")\n",
        "\n",
        "    let mut redup_ok = true\n",
        "    let mut k = 0\n",
        "    while k < 300:\n",
        "        let sym2 = Symbol(f\"sym{k}\")\n",
        "        if (sym2 as i64) != ids[k]:\n",
        "            redup_ok = false\n",
        "        k += 1\n",
        "    println(f\"redup_ok={redup_ok}\")\n",
        "\n",
        "    let last_id = 299 as i64\n",
        "    println(f\"name_last={symbol_name(last_id as Symbol)}\")\n",
    );
    let output = compile_and_run("symbol_hash_index_growth", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["sequential_ok=true", "redup_ok=true", "name_last=sym299",], "{}", stdout);
}

//! `BitField<N>` / `Flags<E>`
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== `BitField<N>` / `Flags<E>` (docs/design.md §8, "Bit-level types") ===

/// Construction from an int-shaped value, widened/narrowed to `i{N}` --
/// mirrors `Ty::Tick`'s own construction rule, see `examples/bitfield.star`.
#[test]
fn runtime_bitfield_construction_and_print_end_to_end() {
    let src = "fn main():\n    let a: BitField<8> = BitField<8>(200 as u8)\n    println(f\"{a}\")\n";
    let output = compile_and_run("bitfield_construct", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "200");
}

/// A literal wider than `i32`'s range (so `Checker::infer_expr`'s literal-
/// magnitude fast path is what makes this legal at all -- an ordinary bare
/// literal token defaults to `i32`) still constructs a `BitField<64>`
/// correctly, tagged with the matching-width type rather than truncated back
/// down to `i32` by the fast path itself.
#[test]
fn runtime_bitfield_construction_from_wide_literal_end_to_end() {
    let src = "fn main():\n    let a: BitField<64> = BitField<64>(5000000000)\n    println(f\"{a}\")\n";
    let output = compile_and_run("bitfield_wide_literal", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "5000000000");
}

/// Construction from a value *wider* than `N` truncates (matching `as`'s own
/// infallible truncating semantics -- there's no fallible-construction path
/// in this compiler), same as a non-literal source would have to.
#[test]
fn runtime_bitfield_construction_truncates_wider_source_end_to_end() {
    let src = "fn main():\n    let a: BitField<8> = BitField<8>(300)\n    println(f\"{a}\")\n";
    let output = compile_and_run("bitfield_truncate", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "44");
}

/// `bit_set`/`bit_get`/`bit_clear`/`bit_toggle` -- the index-based free-
/// function surface (`&`/`|`/`^`/`~` don't exist as operators in this
/// language yet, see `Ty::BitField`'s doc comment).
#[test]
fn runtime_bitfield_set_get_clear_toggle_end_to_end() {
    let src = "fn main():\n    let mut a: BitField<8> = BitField<8>(0)\n    a = bit_set(a, 0)\n    a = bit_set(a, 3)\n    \
               println(f\"{a}\")\n    println(f\"{bit_get(a, 0)}\")\n    println(f\"{bit_get(a, 1)}\")\n    \
               a = bit_clear(a, 3)\n    println(f\"{a}\")\n    a = bit_toggle(a, 1)\n    println(f\"{a}\")\n";
    let output = compile_and_run("bitfield_set_get_clear_toggle", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["9", "true", "false", "1", "3"], "{}", stdout);
}

/// An out-of-range bit index (`>= N`) shifts by a truncated/wrapped amount
/// rather than trapping -- matching this compiler's existing "safe, not
/// panicking" convention for other builtin edge cases (e.g. an out-of-bounds
/// `List<T>` index). `9` truncated to 3 bits (mod 8) is `1`, so `bit_get(a,
/// 9)` reads the same bit as `bit_get(a, 1)`.
#[test]
fn runtime_bitfield_out_of_range_index_wraps_rather_than_traps_end_to_end() {
    let src = "fn main():\n    println(\"before\")\n    let a: BitField<8> = BitField<8>(2 as u8)\n    \
               println(f\"{bit_get(a, 1)}\")\n    println(f\"{bit_get(a, 9)}\")\n    println(\"after\")\n";
    let output = compile_and_run("bitfield_oob_index", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["before", "true", "true", "after"], "{}", stdout);
}

/// `bit_and`/`bit_or`/`bit_xor`/`bit_not` combine whole registers.
#[test]
fn runtime_bitfield_and_or_xor_not_end_to_end() {
    let src = "fn main():\n    let a: BitField<8> = BitField<8>(12 as u8)\n    let b: BitField<8> = BitField<8>(10 as u8)\n    \
               println(f\"{bit_and(a, b)}\")\n    println(f\"{bit_or(a, b)}\")\n    println(f\"{bit_xor(a, b)}\")\n    println(f\"{bit_not(a)}\")\n";
    let output = compile_and_run("bitfield_and_or_xor_not", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["8", "14", "6", "243"], "{}", stdout);
}

/// `==`/`!=` -- a single bit-pattern comparison, see `Ty::BitField`'s doc
/// comment.
#[test]
fn runtime_bitfield_equality_end_to_end() {
    let src = "fn main():\n    let a: BitField<8> = BitField<8>(5 as u8)\n    let b: BitField<8> = BitField<8>(5 as u8)\n    \
               let c: BitField<8> = BitField<8>(6 as u8)\n    println(f\"{a == b}\")\n    println(f\"{a != c}\")\n    println(f\"{a == c}\")\n";
    let output = compile_and_run("bitfield_equality", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "true", "false"], "{}", stdout);
}

/// `BitField<N> <-> u{N}` is a free bit-preserving relabel via `as`.
#[test]
fn runtime_bitfield_cast_round_trip_end_to_end() {
    let src = "fn main():\n    let a: BitField<16> = BitField<16>(1000)\n    let raw: u16 = a as u16\n    println(f\"{raw}\")\n    \
               let back: BitField<16> = raw as BitField<16>\n    println(f\"{a == back}\")\n";
    let output = compile_and_run("bitfield_cast_roundtrip", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["1000", "true"], "{}", stdout);
}

/// `BitField<N>` also allows casting to/from the *signed* type at the
/// matching width (`i16`, not just `u16`) -- it has no declared signedness
/// of its own (a bit count, not a stored `Ty`), unlike `Wrapping<T>`'s
/// exact-`Ty`-match cast rule.
#[test]
fn runtime_bitfield_cast_to_signed_type_at_same_width_end_to_end() {
    let src = "fn main():\n    let a: BitField<8> = BitField<8>(200 as u8)\n    let signed: i8 = a as i8\n    println(f\"{signed}\")\n";
    let output = compile_and_run("bitfield_cast_signed", src);
    assert!(output.status.success(), "{:?}", output.status);
    // 200 as an 8-bit two's-complement pattern reinterpreted signed is -56.
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "-56");
}

/// Every supported width (`8`/`16`/`32`/`64`) lowers correctly, not just the
/// smallest -- `bit_set` on the top bit of a wide register.
#[test]
fn runtime_bitfield_widths_32_and_64_end_to_end() {
    let src = "fn main():\n    let mut a: BitField<32> = BitField<32>(0)\n    a = bit_set(a, 31)\n    println(f\"{a}\")\n    \
               let mut b: BitField<64> = BitField<64>(0)\n    b = bit_set(b, 63)\n    println(f\"{b}\")\n";
    let output = compile_and_run("bitfield_wide_widths", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["2147483648", "9223372036854775808"], "{}", stdout);
}

/// The `bit_*` free functions aren't restricted to `BitField<N>` itself --
/// they also work on a plain integer type and on `Wrapping<T>` (`Ty::
/// bit_shape`'s full set), the retro-register-emulation use case `docs/
/// design.md`'s "Bit-level types" section motivates this section with.
#[test]
fn runtime_bit_ops_on_plain_int_and_wrapping_end_to_end() {
    let src = "fn main():\n    let reg: i32 = 0\n    let reg2 = bit_set(reg, 4)\n    println(f\"{reg2}\")\n    \
               let w: Wrapping<u8> = Wrapping<u8>(0 as u8)\n    let w2 = bit_set(w, 7)\n    println(f\"{w2}\")\n";
    let output = compile_and_run("bit_ops_plain_int_wrapping", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["16", "128"], "{}", stdout);
}

/// `BitField<N>` is structurally hashable (a bare `i{N}` comparison, like
/// `Symbol`) -- legal as a `Set<T>` element. Mirrors `runtime_symbol_as_
/// set_key_dedups_end_to_end`'s regression-test shape: `crate::codegen::eq`'s
/// generated per-key-type equality function relies on every legal `Map`/
/// `Set` key type having its own explicit arm, silently falling back to
/// "always equal" otherwise (the exact bug class `Ty::Symbol` once shipped
/// with, see `docs/design.md`) -- if `Ty::BitField` were missing its own
/// `emit_eq_body` arm, every distinct value would collapse into one slot and
/// this would report `1`, not `3`.
#[test]
fn runtime_bitfield_as_set_key_dedups_correctly_end_to_end() {
    let src = "fn main():\n    let mut s: Set<BitField<8>> = Set<BitField<8>>()\n    \
               s.insert(BitField<8>(1 as u8))\n    s.insert(BitField<8>(2 as u8))\n    s.insert(BitField<8>(1 as u8))\n    \
               s.insert(BitField<8>(3 as u8))\n    println(f\"{s.len()}\")\n";
    let output = compile_and_run("bitfield_set_key_dedup", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "3");
}

#[test]
fn rejects_bitfield_with_an_unsupported_bit_width() {
    let src = "fn main():\n    let a: BitField<7> = BitField<7>(1)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("bit width must be one of 8, 16, 32, 64")), "{:?}", diags);
}

#[test]
fn rejects_bitfield_construction_with_non_integer_value() {
    let src = "fn main():\n    let a = BitField<8>(\"nope\")\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("expects an integer value")), "{:?}", diags);
}

#[test]
fn rejects_bit_get_with_non_integer_index() {
    let src = "fn main():\n    let a: BitField<8> = BitField<8>(1 as u8)\n    let b = bit_get(a, \"x\")\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("bit index) expected `int`")), "{:?}", diags);
}

#[test]
fn rejects_bit_and_between_mismatched_bitfield_widths() {
    let src = "fn main():\n    let a: BitField<8> = BitField<8>(1 as u8)\n    let b: BitField<16> = BitField<16>(1)\n    let c = bit_and(a, b)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("must be the same type")), "{:?}", diags);
}

#[test]
fn rejects_binop_between_mismatched_bitfield_widths() {
    let src = "fn main():\n    let a: BitField<8> = BitField<8>(1 as u8)\n    let b: BitField<16> = BitField<16>(1)\n    let c = a == b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("is not supported between")), "{:?}", diags);
}

#[test]
fn rejects_bit_not_on_a_flags_value() {
    let src = "enum Dir:\n    Up\n    Down\n\nfn main():\n    let f: Flags<Dir> = Flags<Dir>()\n    let g = bit_not(f)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("expects an integer/`Wrapping<T>`/`BitField<N>` value")), "{:?}", diags);
}

/// `Flags<E>()` starts empty; `flags_with`/`flags_without`/`flags_has`/
/// `flags_is_empty` build it up and query it -- see `examples/flags.star`.
#[test]
fn runtime_flags_construction_with_without_has_is_empty_end_to_end() {
    let src = "enum Direction:\n    Up\n    Down\n    Left\n    Right\n\n\
               fn main():\n    let mut m: Flags<Direction> = Flags<Direction>()\n    println(f\"{flags_is_empty(m)}\")\n    \
               m = flags_with(m, Direction::Up)\n    println(f\"{flags_has(m, Direction::Up)}\")\n    \
               println(f\"{flags_has(m, Direction::Down)}\")\n    println(f\"{flags_is_empty(m)}\")\n    \
               m = flags_without(m, Direction::Up)\n    println(f\"{flags_has(m, Direction::Up)}\")\n    \
               println(f\"{flags_is_empty(m)}\")\n";
    let output = compile_and_run("flags_construct_with_without", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "true", "false", "false", "false", "true"], "{}", stdout);
}

/// `Flags<E>(a, b, ...)` -- variadic direct construction from multiple
/// variants at once, OR'd together.
#[test]
fn runtime_flags_variadic_construction_end_to_end() {
    let src = "enum Direction:\n    Up\n    Down\n    Left\n    Right\n\n\
               fn main():\n    let diagonal: Flags<Direction> = Flags<Direction>(Direction::Up, Direction::Right)\n    \
               println(f\"{flags_has(diagonal, Direction::Up)}\")\n    println(f\"{flags_has(diagonal, Direction::Down)}\")\n    \
               println(f\"{flags_has(diagonal, Direction::Left)}\")\n    println(f\"{flags_has(diagonal, Direction::Right)}\")\n";
    let output = compile_and_run("flags_variadic_construct", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "false", "false", "true"], "{}", stdout);
}

/// A *runtime* (non-literal) enum-typed expression works as a `Flags<E>`
/// construction argument too, not just a literal `EnumName::Variant` --
/// `Codegen::emit_flags_variant_bit` computes `1i64 << discriminant` from
/// the already-evaluated value, with no compile-time variant-name lookup.
#[test]
fn runtime_flags_construction_from_runtime_enum_value_end_to_end() {
    let src = "enum Direction:\n    Up\n    Down\n    Left\n    Right\n\n\
               fn main():\n    let dir: Direction = Direction::Left\n    let f: Flags<Direction> = Flags<Direction>(dir)\n    \
               println(f\"{flags_has(f, Direction::Left)}\")\n    println(f\"{flags_has(f, Direction::Up)}\")\n";
    let output = compile_and_run("flags_from_runtime_enum", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "false"], "{}", stdout);
}

/// `bit_or`/`bit_and`/`bit_xor` on `Flags<E>` implement union/intersect/
/// symmetric-difference -- safe to share with `Ty::BitField`'s free
/// functions since both operands only ever have bits set for real declared
/// variants (see `Ty::Flags`'s doc comment).
#[test]
fn runtime_flags_union_intersect_symmetric_difference_end_to_end() {
    let src = "enum Direction:\n    Up\n    Down\n    Left\n    Right\n\n\
               fn main():\n    let all_four: Flags<Direction> = Flags<Direction>(Direction::Up, Direction::Down, Direction::Left, Direction::Right)\n    \
               let vertical: Flags<Direction> = Flags<Direction>(Direction::Up, Direction::Down)\n    \
               let horizontal: Flags<Direction> = Flags<Direction>(Direction::Left, Direction::Right)\n    \
               let empty: Flags<Direction> = Flags<Direction>()\n    \
               println(f\"{bit_or(vertical, horizontal) == all_four}\")\n    \
               println(f\"{bit_and(vertical, horizontal) == empty}\")\n    \
               println(f\"{bit_xor(all_four, vertical) == horizontal}\")\n";
    let output = compile_and_run("flags_union_intersect_symdiff", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "true", "true"], "{}", stdout);
}

/// `==`/`!=` and `Flags<E> as i64` (a free bit-preserving relabel, for
/// debugging -- printing the raw mask).
#[test]
fn runtime_flags_equality_and_cast_to_i64_end_to_end() {
    let src = "enum Direction:\n    Up\n    Down\n    Left\n    Right\n\n\
               fn main():\n    let a: Flags<Direction> = Flags<Direction>(Direction::Up, Direction::Down)\n    \
               let b: Flags<Direction> = Flags<Direction>(Direction::Up, Direction::Down)\n    \
               let c: Flags<Direction> = Flags<Direction>(Direction::Left)\n    \
               println(f\"{a == b}\")\n    println(f\"{a != c}\")\n    \
               let raw: i64 = a as i64\n    println(f\"{raw}\")\n";
    let output = compile_and_run("flags_equality_cast", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "true", "3"], "{}", stdout);
}

/// `Flags<E>` is structurally hashable -- legal as a `Map<K,V>` key. Same
/// "needs its own explicit `emit_eq_body` arm" regression-test reasoning as
/// `runtime_bitfield_as_set_key_dedups_correctly_end_to_end` above.
#[test]
fn runtime_flags_as_map_key_end_to_end() {
    let src = "enum Direction:\n    Up\n    Down\n\n\
               fn main():\n    let mut m: Map<Flags<Direction>, i32> = Map<Flags<Direction>, i32>()\n    \
               m.insert(Flags<Direction>(Direction::Up), 1)\n    m.insert(Flags<Direction>(Direction::Down), 2)\n    \
               m.insert(Flags<Direction>(Direction::Up), 3)\n    println(f\"{m.len()}\")\n    \
               let v = m.get(Flags<Direction>(Direction::Up))\n    \
               match v:\n        Option::Some(x) -> println(f\"{x}\")\n        Option::None -> println(\"missing\")\n";
    let output = compile_and_run("flags_as_map_key", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["2", "3"], "{}", stdout);
}

#[test]
fn rejects_flags_of_non_enum_type() {
    let src = "fn main():\n    let a: Flags<i32> = Flags<i32>()\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("requires `E` to be an enum type")), "{:?}", diags);
}

#[test]
fn rejects_flags_of_payload_carrying_enum() {
    let src = "enum Shape:\n    Circle(radius: f32)\n    Point\n\nfn main():\n    let a: Flags<Shape> = Flags<Shape>()\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("requires a fieldless enum")), "{:?}", diags);
}

#[test]
fn rejects_flags_variadic_construction_argument_of_wrong_enum_type() {
    let src = "enum Direction:\n    Up\n    Down\n\nenum Color:\n    Red\n    Blue\n\n\
               fn main():\n    let a: Flags<Direction> = Flags<Direction>(Color::Red)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("argument 1 expected")), "{:?}", diags);
}

#[test]
fn rejects_flags_has_argument_of_wrong_enum_type() {
    let src = "enum Direction:\n    Up\n    Down\n\nenum Color:\n    Red\n    Blue\n\n\
               fn main():\n    let f: Flags<Direction> = Flags<Direction>()\n    let b = flags_has(f, Color::Red)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("argument 2 expected")), "{:?}", diags);
}

#[test]
fn rejects_flags_with_more_than_64_variants() {
    let variants: String = (0..65).map(|i| format!("V{}\n", i)).collect::<Vec<_>>().join("    ");
    let src = format!("enum Big:\n    {}\nfn main():\n    let a: Flags<Big> = Flags<Big>()\n", variants);
    let module = Driver::parse(&src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("requires 64 or fewer variants")), "{:?}", diags);
}

#[test]
fn parses_bitfield_and_flags_type_positions() {
    let src = "enum Dir:\n    Up\n    Down\n\nfn main():\n    let a: BitField<16> = BitField<16>(0)\n    let b: Flags<Dir> = Flags<Dir>()\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module);
    assert!(diags.is_ok(), "{:?}", diags.err());
}

// === docs/design.md's "Math and geometry" section ===========================
//
// `Quat`/`Mat2`/`Mat3`/`Color`/`Color32`/`PaletteIndex`/`Palette` (see
// `Ty`'s own doc comments in `src/types/mod.rs`), plus the builtin
// `Rect`/`Aabb2`/`Aabb3`/`Ray`/`Plane`/`Frustum`/`Transform` structs
// (`crate::types::builtin_structs`) and their free-function surface
// (`crate::codegen::geometry`).

// --- `Quat` -------------------------------------------------------------

/// The identity rotation leaves a point unchanged; a real rotation moves it.
#[test]
fn runtime_quat_identity_and_rotate_end_to_end() {
    let src = "fn main():\n    \
               let id = quat_identity()\n    \
               let p = quat_rotate(id, Vec3(1.0, 0.0, 0.0))\n    \
               println(f\"{p.x}, {p.y}, {p.z}\")\n    \
               let q = Quat(0.0, 0.0, 0.70710678, 0.70710678)\n    \
               let r = quat_rotate(q, Vec3(1.0, 0.0, 0.0))\n    \
               println(f\"{r.x}, {r.y}, {r.z}\")\n";
    let output = compile_and_run("quat_identity_and_rotate", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines[0], "1.000000, 0.000000, 0.000000");
    // A 90-degree rotation about +Z sends (1,0,0) to (0,1,0).
    assert_eq!(lines[1], "0.000000, 1.000000, 0.000000");
}

/// `Quat * Quat` composes rotations (the Hamilton product) -- two 45-degree
/// rotations about the same axis compose into one 90-degree rotation.
#[test]
fn runtime_quat_multiply_composes_rotations_end_to_end() {
    let src = "fn main():\n    \
               let half = Quat(0.0, 0.0, 0.38268343, 0.92387953)\n    \
               let composed = half * half\n    \
               let r = quat_rotate(composed, Vec3(1.0, 0.0, 0.0))\n    \
               println(f\"{r.x}, {r.y}, {r.z}\")\n";
    let output = compile_and_run("quat_multiply_composes", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim(), "0.000000, 1.000000, 0.000000");
}

/// `quat_conjugate` inverts a unit rotation: rotating and then rotating back
/// by the conjugate returns the original point.
#[test]
fn runtime_quat_conjugate_inverts_rotation_end_to_end() {
    let src = "fn main():\n    \
               let q = Quat(0.0, 0.0, 0.70710678, 0.70710678)\n    \
               let rotated = quat_rotate(q, Vec3(1.0, 0.0, 0.0))\n    \
               let undone = quat_rotate(quat_conjugate(q), rotated)\n    \
               println(f\"{undone.x}, {undone.y}, {undone.z}\")\n";
    let output = compile_and_run("quat_conjugate_inverts", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim(), "1.000000, 0.000000, 0.000000");
}

/// `quat_normalize` rescales an unnormalized quaternion back to unit length.
#[test]
fn runtime_quat_normalize_end_to_end() {
    let src = "fn main():\n    \
               let n = quat_normalize(Quat(0.0, 0.0, 0.0, 2.0))\n    \
               println(f\"{n.w}\")\n";
    let output = compile_and_run("quat_normalize", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim(), "1.000000");
}

/// `Quat` reuses `Vec4`'s exact layout, so field access (`.x`/`.y`/`.z`/`.w`)
/// and componentwise `+`/scalar `*` fall out for free, distinct from the
/// quaternion-product `*` between two `Quat`s.
#[test]
fn runtime_quat_field_access_and_componentwise_arithmetic_end_to_end() {
    let src = "fn main():\n    \
               let a = Quat(1.0, 2.0, 3.0, 4.0)\n    \
               let b = Quat(0.0, 0.0, 0.0, 1.0)\n    \
               let sum = a + b\n    \
               println(f\"{sum.x}, {sum.y}, {sum.z}, {sum.w}\")\n    \
               let scaled = a * 2.0\n    \
               println(f\"{scaled.w}\")\n";
    let output = compile_and_run("quat_field_access_componentwise", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["1.000000, 2.000000, 3.000000, 5.000000", "8.000000"]);
}

#[test]
fn rejects_quat_constructor_wrong_arity() {
    let src = "fn main():\n    let q = Quat(1.0, 2.0)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("Quat(..) with 2 args should be rejected");
    assert!(diags.iter().any(|d| d.message.contains("expects 4 float arguments")), "{:?}", diags);
}

#[test]
fn rejects_quat_rotate_wrong_argument_types() {
    let src = "fn main():\n    let v = Vec3(1.0, 0.0, 0.0)\n    let r = quat_rotate(v, v)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("quat_rotate(Vec3, Vec3) should be rejected");
    assert!(diags.iter().any(|d| d.message.contains("argument 1 expected `Quat`")), "{:?}", diags);
}

#[test]
fn rejects_quat_quat_equality_comparison() {
    let src = "fn main():\n    let a = Quat(0.0, 0.0, 0.0, 1.0)\n    let b = Quat(0.0, 0.0, 0.0, 1.0)\n    let c = a == b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("`==` between two Quats directly should be rejected");
    assert!(!diags.is_empty(), "{:?}", diags);
}

// --- `Mat2`/`Mat3` --------------------------------------------------------

/// `Mat2 * Vec2` and `Mat2 * Mat2` -- extends `Mat4`'s existing matrix
/// codegen to a smaller fixed dimension.
#[test]
fn runtime_mat2_scale_and_matrix_multiply_end_to_end() {
    let src = "fn main():\n    \
               let scale2 = Mat2(Vec2(2.0, 0.0), Vec2(0.0, 3.0))\n    \
               let scaled = scale2 * Vec2(1.0, 1.0)\n    \
               println(f\"{scaled.x}, {scaled.y}\")\n    \
               let identity2 = Mat2(Vec2(1.0, 0.0), Vec2(0.0, 1.0))\n    \
               let product = scale2 * identity2\n    \
               let via_product = product * Vec2(1.0, 1.0)\n    \
               println(f\"{via_product.x}, {via_product.y}\")\n    \
               let sum2 = scale2 + identity2\n    \
               let via_sum = sum2 * Vec2(1.0, 0.0)\n    \
               println(f\"{via_sum.x}\")\n";
    let output = compile_and_run("mat2_scale_and_matrix_multiply", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["2.000000, 3.000000", "2.000000, 3.000000", "3.000000"]);
}

/// `Mat3 * Vec3` -- a non-identity 3x3 matrix (swapping the x/y rows)
/// correctly permutes the multiplied vector's components.
#[test]
fn runtime_mat3_matrix_multiply_end_to_end() {
    let src = "fn main():\n    \
               let identity3 = Mat3(Vec3(1.0, 0.0, 0.0), Vec3(0.0, 1.0, 0.0), Vec3(0.0, 0.0, 1.0))\n    \
               let v = identity3 * Vec3(5.0, 6.0, 7.0)\n    \
               println(f\"{v.x}, {v.y}, {v.z}\")\n    \
               let swap_xy = Mat3(Vec3(0.0, 1.0, 0.0), Vec3(1.0, 0.0, 0.0), Vec3(0.0, 0.0, 1.0))\n    \
               let swapped = swap_xy * Vec3(1.0, 2.0, 3.0)\n    \
               println(f\"{swapped.x}, {swapped.y}, {swapped.z}\")\n";
    let output = compile_and_run("mat3_matrix_multiply", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["5.000000, 6.000000, 7.000000", "2.000000, 1.000000, 3.000000"]);
}

#[test]
fn rejects_mat2_constructor_with_vec3_row() {
    let src = "fn main():\n    let m = Mat2(Vec3(1.0, 2.0, 3.0), Vec2(0.0, 1.0))\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("Mat2(Vec3, Vec2) should be rejected");
    assert!(diags.iter().any(|d| d.message.contains("expects 2 Vec2 row arguments")), "{:?}", diags);
}

#[test]
fn rejects_mat2_times_vec3() {
    let src = "fn main():\n    let m = Mat2(Vec2(1.0, 0.0), Vec2(0.0, 1.0))\n    let v = m * Vec3(1.0, 2.0, 3.0)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("Mat2 * Vec3 should be rejected");
    assert!(!diags.is_empty(), "{:?}", diags);
}

#[test]
fn rejects_mat2_plus_mat3() {
    let src = "fn main():\n    \
               let m2 = Mat2(Vec2(1.0, 0.0), Vec2(0.0, 1.0))\n    \
               let m3 = Mat3(Vec3(1.0, 0.0, 0.0), Vec3(0.0, 1.0, 0.0), Vec3(0.0, 0.0, 1.0))\n    \
               let bad = m2 + m3\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("Mat2 + Mat3 should be rejected");
    assert!(!diags.is_empty(), "{:?}", diags);
}

// --- `Color`/`Color32` ----------------------------------------------------

/// `Color` reuses `Vec4`'s exact layout: `.r/.g/.b/.a` field access and
/// componentwise `+`/scalar `*` (blending) work for free.
#[test]
fn runtime_color_field_access_and_blending_end_to_end() {
    let src = "fn main():\n    \
               let orange = Color(1.0, 0.5, 0.0, 1.0)\n    \
               println(f\"{orange.r}, {orange.g}, {orange.b}, {orange.a}\")\n    \
               let dimmed = orange * 0.5\n    \
               println(f\"{dimmed.r}\")\n    \
               let blended = orange + Color(0.0, 0.0, 1.0, 0.0)\n    \
               println(f\"{blended.b}\")\n";
    let output = compile_and_run("color_field_access_blending", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["1.000000, 0.500000, 0.000000, 1.000000", "0.500000", "1.000000"]);
}

/// `color_to_color32`/`color32_to_color`: a lossy but bounded round trip
/// through the packed 8-bit-per-channel representation.
#[test]
fn runtime_color_color32_round_trip_end_to_end() {
    let src = "fn main():\n    \
               let orange = Color(1.0, 0.5, 0.0, 1.0)\n    \
               let packed = color_to_color32(orange)\n    \
               println(f\"{color32_r(packed)}\")\n    \
               println(f\"{color32_g(packed)}\")\n    \
               println(f\"{color32_b(packed)}\")\n    \
               println(f\"{color32_a(packed)}\")\n    \
               let restored = color32_to_color(packed)\n    \
               println(f\"{restored.r}\")\n";
    let output = compile_and_run("color_color32_round_trip", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["255", "127", "0", "255", "1.000000"]);
}

/// `color_to_color32` clamps an out-of-`[0,1]`-range HDR channel instead of
/// producing undefined behavior via a raw `fptoui`.
#[test]
fn runtime_color_to_color32_clamps_hdr_out_of_range_channels_end_to_end() {
    let src = "fn main():\n    \
               let hot = Color(2.0, -1.0, 0.5, 1.0)\n    \
               let packed = color_to_color32(hot)\n    \
               println(f\"{color32_r(packed)}\")\n    \
               println(f\"{color32_g(packed)}\")\n";
    let output = compile_and_run("color_to_color32_clamps_hdr", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["255", "0"]);
}

/// `Color32(r, g, b, a)` packs four raw 0-255 channel values, unpacked by
/// `color32_r`/`color32_g`/`color32_b`/`color32_a`.
#[test]
fn runtime_color32_construction_and_channels_end_to_end() {
    let src = "fn main():\n    \
               let raw = Color32(255, 128, 64, 10)\n    \
               println(f\"{color32_r(raw)}\")\n    \
               println(f\"{color32_g(raw)}\")\n    \
               println(f\"{color32_b(raw)}\")\n    \
               println(f\"{color32_a(raw)}\")\n";
    let output = compile_and_run("color32_construction_channels", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["255", "128", "64", "10"]);
}

/// `==`/`!=` -- a single `i32` pack comparison, see `Ty::Color32`'s doc
/// comment.
#[test]
fn runtime_color32_equality_end_to_end() {
    let src = "fn main():\n    \
               let a = Color32(1, 2, 3, 4)\n    \
               let b = Color32(1, 2, 3, 4)\n    \
               let c = Color32(1, 2, 3, 5)\n    \
               println(f\"{a == b}\")\n    \
               println(f\"{a != c}\")\n    \
               println(f\"{a == c}\")\n";
    let output = compile_and_run("color32_equality", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "true", "false"]);
}

/// `Color32` is structurally hashable -- legal as a `Map`/`Set` key, and two
/// distinct `Color32` values must land in distinct slots (the same
/// "`check_hashable_ty` needs a matching `emit_eq_body` arm or every key
/// collapses into one slot" bug class `Ty::Symbol` once shipped with --
/// see `docs/design.md`'s "Text and bytes" section history).
#[test]
fn runtime_color32_as_set_key_dedups_correctly_end_to_end() {
    let src = "fn main():\n    \
               let mut set: Set<Color32> = Set<Color32>()\n    \
               set.insert(Color32(255, 0, 0, 255))\n    \
               set.insert(Color32(255, 0, 0, 255))\n    \
               set.insert(Color32(0, 255, 0, 255))\n    \
               println(f\"{set.len()}\")\n    \
               println(f\"{set.contains(Color32(255, 0, 0, 255))}\")\n    \
               println(f\"{set.contains(Color32(0, 0, 255, 255))}\")\n";
    let output = compile_and_run("color32_as_set_key_dedups", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["2", "true", "false"]);
}

/// `Color32 <-> i32`/`u32` is a free bit-preserving relabel via `as`.
#[test]
fn runtime_color32_cast_round_trip_end_to_end() {
    let src = "fn main():\n    \
               let c = Color32(1, 2, 3, 4)\n    \
               let raw: i32 = c as i32\n    \
               println(f\"{raw}\")\n    \
               let back: Color32 = raw as Color32\n    \
               println(f\"{c == back}\")\n";
    let output = compile_and_run("color32_cast_roundtrip", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    // 1 | 2<<8 | 3<<16 | 4<<24
    assert_eq!(lines, vec!["67305985", "true"]);
}

#[test]
fn rejects_color32_ordering_comparison() {
    let src = "fn main():\n    let a = Color32(1, 2, 3, 4)\n    let b = Color32(1, 2, 3, 4)\n    let c = a < b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("`<` between Color32 values should be rejected");
    assert!(diags.iter().any(|d| d.message.contains("only `==`/`!=` are supported between `Color32` values")), "{:?}", diags);
}

#[test]
fn rejects_color32_constructor_wrong_arity() {
    let src = "fn main():\n    let c = Color32(1, 2, 3)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("Color32(..) with 3 args should be rejected");
    assert!(diags.iter().any(|d| d.message.contains("expects 4 integer")), "{:?}", diags);
}

// --- `PaletteIndex`/`Palette` ---------------------------------------------

/// `Palette` reuses `List<Color32>`'s method surface wholesale
/// (`push`/`len`/`[i]`) -- see `Ty::Palette`'s doc comment.
#[test]
fn runtime_palette_push_len_and_index_end_to_end() {
    let src = "fn main():\n    \
               let mut pal: Palette = Palette()\n    \
               pal.push(Color32(255, 0, 0, 255))\n    \
               pal.push(Color32(0, 255, 0, 255))\n    \
               pal.push(Color32(0, 0, 255, 255))\n    \
               println(f\"{pal.len()}\")\n    \
               println(f\"{color32_g(pal[1])}\")\n    \
               println(f\"{color32_b(pal[2])}\")\n";
    let output = compile_and_run("palette_push_len_index", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["3", "255", "255"]);
}

/// `PaletteIndex(value)` constructs from any int-shaped value; `<-> u8` is a
/// free bit-preserving relabel via `as`.
#[test]
fn runtime_palette_index_construction_and_cast_round_trip_end_to_end() {
    let src = "fn main():\n    \
               let idx: PaletteIndex = PaletteIndex(200)\n    \
               let raw: u8 = idx as u8\n    \
               println(f\"{raw}\")\n    \
               let back: PaletteIndex = raw as PaletteIndex\n    \
               println(f\"{idx == back}\")\n";
    let output = compile_and_run("palette_index_construction_cast", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["200", "true"]);
}

/// `==`/`!=` between `PaletteIndex` values.
#[test]
fn runtime_palette_index_equality_end_to_end() {
    let src = "fn main():\n    \
               let a: PaletteIndex = PaletteIndex(3)\n    \
               let b: PaletteIndex = PaletteIndex(3)\n    \
               let c: PaletteIndex = PaletteIndex(4)\n    \
               println(f\"{a == b}\")\n    \
               println(f\"{a != c}\")\n";
    let output = compile_and_run("palette_index_equality", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "true"]);
}

#[test]
fn rejects_palette_index_direct_cast_to_i32() {
    let src = "fn main():\n    let idx: PaletteIndex = PaletteIndex(1)\n    let raw: i32 = idx as i32\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("PaletteIndex only casts to/from u8 directly");
    assert!(diags.iter().any(|d| d.message.contains("cannot cast")), "{:?}", diags);
}

// --- Bug-hunting round 6: wide-coverage additions for Color/Color32/
// PaletteIndex/Mat2/Mat3/Quat, the least-audited types per todo.md's round 5/
// follow-up writeups. Every hand-computed expected value below was derived
// independently of this codegen (plain arithmetic, not a re-derivation of
// `emit_quat_mul`/`emit_mat_mul`'s own formulas) and cross-checked before
// being written into an assertion.

/// `Quat * Quat` / `quat_rotate` against a rotation about a genuinely
/// non-axis-aligned axis (the existing `runtime_quat_multiply_composes_
/// rotations_end_to_end`/`examples/quat.star` coverage only ever rotates
/// about +Z) -- a 120-degree rotation about the `(1,1,1)` diagonal, i.e.
/// `Quat(0.5, 0.5, 0.5, 0.5)` (`sin(60deg) * (1,1,1)/sqrt(3) = (0.5,0.5,0.5)`,
/// `cos(60deg) = 0.5`), which cyclically permutes the three axes: hand-derived
/// via the same Hamilton-product formula `emit_quat_mul` implements, computed
/// independently on paper, not by running this compiler.
#[test]
fn runtime_quat_rotate_about_diagonal_axis_end_to_end() {
    let src = "fn main():\n    \
               let q = Quat(0.5, 0.5, 0.5, 0.5)\n    \
               let x_axis = quat_rotate(q, Vec3(1.0, 0.0, 0.0))\n    \
               println(f\"{x_axis.x}, {x_axis.y}, {x_axis.z}\")\n    \
               let y_axis = quat_rotate(q, Vec3(0.0, 1.0, 0.0))\n    \
               println(f\"{y_axis.x}, {y_axis.y}, {y_axis.z}\")\n";
    let output = compile_and_run("quat_rotate_diagonal_axis", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    // A 120-degree rotation about (1,1,1) cyclically permutes the axes:
    // +X -> +Y -> +Z -> +X.
    assert_eq!(lines, vec!["0.000000, 1.000000, 0.000000", "0.000000, 0.000000, 1.000000"]);
}

/// `Mat2 * Mat2` / `Mat2 * Vec2` against a genuinely non-diagonal,
/// non-permutation 2x2 matrix (the existing `runtime_mat2_scale_and_matrix_
/// multiply_end_to_end` only ever uses diagonal scale/identity matrices) --
/// the textbook `[[1,2],[3,4]] * [[5,6],[7,8]] = [[19,22],[43,50]]` example.
#[test]
fn runtime_mat2_nontrivial_matrix_multiply_end_to_end() {
    let src = "fn main():\n    \
               let a = Mat2(Vec2(1.0, 2.0), Vec2(3.0, 4.0))\n    \
               let b = Mat2(Vec2(5.0, 6.0), Vec2(7.0, 8.0))\n    \
               let product = a * b\n    \
               let col0 = product * Vec2(1.0, 0.0)\n    \
               let col1 = product * Vec2(0.0, 1.0)\n    \
               println(f\"{col0.x}, {col1.x}, {col0.y}, {col1.y}\")\n    \
               let v = a * Vec2(1.0, 2.0)\n    \
               println(f\"{v.x}, {v.y}\")\n";
    let output = compile_and_run("mat2_nontrivial_multiply", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["19.000000, 22.000000, 43.000000, 50.000000", "5.000000, 11.000000"]);
}

/// `Mat3 * Vec3` and self-composition (`(M*M) * v` must equal `M * (M * v)`)
/// against a genuinely non-trivial (non-identity, non-permutation, no zero
/// row/column) 3x3 matrix -- the existing `runtime_mat3_matrix_multiply_
/// end_to_end` only ever uses the identity and a row-swap permutation, both
/// of which would pass even with a transposed-read or wrong-multiply-order
/// bug (a permutation matrix's transpose is its own inverse, and its product
/// with itself in either order is idempotent on many inputs). Expected
/// values hand-computed independently: `A = [[1,2,3],[0,1,4],[5,6,0]]`,
/// `A * (1,1,1) = (6,5,11)`, `(A*A) * (1,1,1) = (49,49,60)`.
#[test]
fn runtime_mat3_nontrivial_multiply_and_self_composition_end_to_end() {
    let src = "fn main():\n    \
               let a = Mat3(Vec3(1.0, 2.0, 3.0), Vec3(0.0, 1.0, 4.0), Vec3(5.0, 6.0, 0.0))\n    \
               let v = Vec3(1.0, 1.0, 1.0)\n    \
               let av = a * v\n    \
               println(f\"{av.x}, {av.y}, {av.z}\")\n    \
               let a_squared = a * a\n    \
               let via_squared = a_squared * v\n    \
               println(f\"{via_squared.x}, {via_squared.y}, {via_squared.z}\")\n    \
               let via_twice = a * av\n    \
               println(f\"{via_twice.x}, {via_twice.y}, {via_twice.z}\")\n";
    let output = compile_and_run("mat3_nontrivial_self_composition", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(
        lines,
        vec!["6.000000, 5.000000, 11.000000", "49.000000, 49.000000, 60.000000", "49.000000, 49.000000, 60.000000"]
    );
}

/// A struct mixing a scalar field before and after a `Mat3` field gets
/// `@export` reflection byte offsets matching `Mat3`'s real LLVM layout
/// (align 16, size 48 -- `[3 x <3 x float>]`, each `<3 x float>` row padded
/// to a 4-wide vector's 16-byte footprint on this target) -- cross-checked
/// against a standalone `.ll` `getelementptr`+`ptrtoint` probe of
/// `{ i8, [3 x <3 x float>], i32 }` compiled and run for real (`sizeof=80`,
/// `mat_offset=16`, `row1_offset=32`, `tail_offset=64`), not just this
/// compiler's own `Codegen::type_align`/`type_size` model of itself.
#[test]
fn codegen_reflect_metadata_offsets_correct_around_mat3_field() {
    let src = "struct Mixed:\n    @export flag: bool = true\n    @export basis: Mat3 = Mat3(Vec3(1.0, 0.0, 0.0), Vec3(0.0, 1.0, 0.0), Vec3(0.0, 0.0, 1.0))\n    @export tail: i32 = 0\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("flag:0:bool:export"), "{}", ir);
    assert!(ir.contains("basis:16:Mat3:export"), "Mat3 needs 16-byte alignment after a 1-byte bool: {}", ir);
    assert!(ir.contains("tail:64:i32:export"), "tail should follow Mat3's 48-byte, 16-aligned footprint (16+48=64): {}", ir);
}

/// Writing through a multi-component swizzle with its destination components
/// listed *out of source order* (`v.zx = ...`, as opposed to the existing
/// `runtime_vecmath_end_to_end`'s in-order `.xy = Vec2(..)` coverage) must
/// route each source component to its own named lane independently, leaving
/// the unnamed lane (`y`) untouched.
#[test]
fn runtime_vec3_swizzle_write_out_of_order_end_to_end() {
    let src = "fn main():\n    \
               let mut v = Vec3(1.0, 2.0, 3.0)\n    \
               v.zx = Vec2(9.0, 7.0)\n    \
               println(f\"{v.x}, {v.y}, {v.z}\")\n";
    let output = compile_and_run("vec3_swizzle_write_out_of_order", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    // `.zx = Vec2(9.0, 7.0)`: z <- 9.0 (1st source component), x <- 7.0 (2nd
    // source component); y is untouched.
    assert_eq!(stdout.trim(), "7.000000, 2.000000, 9.000000");
}

/// A swizzle read on the result of an expression (not a plain variable) --
/// `(a + b).yx` -- must evaluate the base expression once and swizzle its
/// result, not require an addressable place.
#[test]
fn runtime_swizzle_read_on_expression_result_end_to_end() {
    let src = "fn main():\n    \
               let a = Vec2(1.0, 2.0)\n    \
               let b = Vec2(3.0, 4.0)\n    \
               let swapped = (a + b).yx\n    \
               println(f\"{swapped.x}, {swapped.y}\")\n";
    let output = compile_and_run("swizzle_read_on_expr_result", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim(), "6.000000, 4.000000");
}

/// `Color32(r, g, b, a)` masks each channel to its low byte rather than
/// rejecting/corrupting neighboring channels on an out-of-`[0,255]` argument
/// -- confirmed against every boundary/wraparound shape: `300 & 0xFF = 44`,
/// a negative `-1 & 0xFF = 255`, an exact `256 & 0xFF = 0`, and `1000 & 0xFF
/// = 232`.
#[test]
fn runtime_color32_out_of_range_channel_arguments_mask_to_low_byte_end_to_end() {
    let src = "fn main():\n    \
               let c = Color32(300, -1, 256, 1000)\n    \
               println(f\"{color32_r(c)}, {color32_g(c)}, {color32_b(c)}, {color32_a(c)}\")\n";
    let output = compile_and_run("color32_out_of_range_channels", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim(), "44, 255, 0, 232");
}

/// `PaletteIndex(value)` narrows any int-shaped value to `u8` by plain
/// truncation (mirrors `Ty::Tick`'s widen/narrow rule) -- confirmed at both
/// wraparound boundaries: `300 -> 44` (`300 mod 256`), `-1 -> 255` (two's
/// complement truncation).
#[test]
fn runtime_palette_index_out_of_range_construction_truncates_end_to_end() {
    let src = "fn main():\n    \
               let a: PaletteIndex = PaletteIndex(300)\n    \
               let b: PaletteIndex = PaletteIndex(-1)\n    \
               println(f\"{a}, {b}\")\n";
    let output = compile_and_run("palette_index_out_of_range_construction", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim(), "44, 255");
}

/// `List<Mat3>`/`Map<str, Quat>` -- both odd-shaped aggregate builtin types
/// (`Mat3`'s 3x3=9-float non-power-of-2 shape, `Quat`'s 4-float layout with a
/// non-vector-arithmetic `*`) instantiate cleanly as a generic type argument,
/// round-tripping every component through the heap-backed, RC'd, copy-on-write
/// storage `List<T>`/`Map<K,V>` share with every other element type.
#[test]
fn runtime_list_of_mat3_and_map_of_quat_generic_instantiation_end_to_end() {
    let src = "fn main():\n    \
               let mut mats: List<Mat3> = List<Mat3>()\n    \
               mats.push(Mat3(Vec3(1.0, 2.0, 3.0), Vec3(4.0, 5.0, 6.0), Vec3(7.0, 8.0, 9.0)))\n    \
               mats.push(Mat3(Vec3(1.0, 0.0, 0.0), Vec3(0.0, 1.0, 0.0), Vec3(0.0, 0.0, 1.0)))\n    \
               let m0 = mats[0]\n    \
               let diag0 = m0 * Vec3(1.0, 0.0, 0.0)\n    \
               let diag1 = m0 * Vec3(0.0, 1.0, 0.0)\n    \
               let diag2 = m0 * Vec3(0.0, 0.0, 1.0)\n    \
               println(f\"{diag0.x}, {diag1.y}, {diag2.z}\")\n    \
               let mut rotations: Map<str, Quat> = Map<str, Quat>()\n    \
               rotations.insert(\"spin\", Quat(0.0, 0.0, 0.70710678, 0.70710678))\n    \
               let looked_up = rotations.get(\"spin\")\n    \
               match looked_up:\n        \
                   Option::Some(q) ->\n            \
                       println(f\"{q.z}, {q.w}\")\n        \
                   Option::None ->\n            \
                       println(\"missing\")\n";
    let output = compile_and_run("list_mat3_map_quat_generics", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["1.000000, 5.000000, 9.000000", "0.707107, 0.707107"]);
}

/// A payload enum carrying a wide-aligned aggregate field (`Vec3`/`Vec4`/
/// `Mat2`/`Mat3`/`Mat4`/`Quat`/`Color`, all 16-byte-aligned native vectors on
/// this target -- see `Codegen::type_align`) previously segfaulted at
/// runtime (`STATUS_ACCESS_VIOLATION`) as soon as it was actually
/// constructed and read back, confirmed via a real `clang -O0`-compiled run
/// of exactly this shape *before* the fix: `%Option__Quat` lowered to
/// `{ i32, [2 x i64] }`, an LLVM struct whose own ABI alignment is only 8
/// (built entirely out of `i32`/`i64`), so every `alloca %Option__Quat` this
/// compiler emits (with no explicit `align` override anywhere) defaulted to
/// 8-byte alignment -- but storing the `Quat` payload is a `store <4 x
/// float> .., <4 x float>* <bitcast into that buffer>`, which implicitly
/// assumes `<4 x float>`'s own natural 16-byte alignment whenever no
/// explicit `align N` is given. An unaligned SSE store into 8-aligned memory
/// is undefined behavior that happened to fault immediately at `-O0` (this
/// harness's own compile path) but not at `-O2`/`star build`'s default
/// optimization level, making it an easy miss for any check that only
/// builds through the default-optimized CLI. Fixed by widening the payload
/// buffer's element type from `i64` to `<2 x i64>` (still 8 bytes per lane,
/// but itself 16-byte-aligned on this target, like the aggregate types that
/// need it) whenever any variant needs it (`Codegen::enum_payload_elem_ty`,
/// `src/codegen/mod.rs`) -- letting LLVM's own struct-layout algorithm
/// compute the correct alignment/padding everywhere this type is used
/// (`alloca`, heap allocation, array-of-this-enum element stride) with no
/// per-call-site `align N` overrides needed. Deliberately as minimal a
/// repro as possible (no `List`/`Map` involved) to isolate the payload-enum
/// codegen itself as the root cause, distinct from the wider `Map<str,
/// Quat>::get(..)` repro this was originally found through (`runtime_list_
/// of_mat3_and_map_of_quat_generic_instantiation_end_to_end`, whose own
/// `Map::get` construct-an-`Option<Quat>` call reuses this exact codegen
/// path in `src/codegen/map.rs`'s `emit_construct_enum_variant`).
#[test]
fn runtime_payload_enum_holding_quat_does_not_segfault_at_o0_end_to_end() {
    let src = "enum MaybeRotation:\n    \
               None\n    \
               Some(q: Quat)\n\n\
               fn main():\n    \
               let a = MaybeRotation::Some(Quat(1.0, 2.0, 3.0, 4.0))\n    \
               match a:\n        \
                   MaybeRotation::Some(q) ->\n            \
                       println(f\"{q.x}, {q.y}, {q.z}, {q.w}\")\n        \
                   MaybeRotation::None ->\n            \
                       println(\"none\")\n";
    let output = compile_and_run("payload_enum_holding_quat_o0", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim(), "1.000000, 2.000000, 3.000000, 4.000000");
}

/// `Codegen::type_align`/`Codegen::type_size`'s `Ty::Enum` arm must report
/// the *real* payload alignment (16, not the pre-fix flat 8) once a payload
/// enum embeds a wide-aligned field -- otherwise a struct field or `@export`
/// reflection offset computed from the old flat-8 assumption would disagree
/// with the real, now-`<2 x i64>`-backed LLVM layout `enum_payload_elem_ty`
/// produces (`emit_reflect_metadata`, `src/codegen/reflect.rs`, walks fields
/// via exactly this model). Mirrors `codegen_reflect_metadata_offsets_
/// correct_around_mat3_field`'s own "cross-check the Rust-side layout model
/// against a real struct" shape, just for a payload-enum field instead of a
/// bare `Mat3` field.
#[test]
fn codegen_reflect_metadata_offsets_correct_around_wide_aligned_payload_enum_field() {
    let src = "enum MaybeRotation:\n    None\n    Some(q: Quat)\n\nstruct Holder:\n    @export flag: bool = true\n    @export rot: MaybeRotation = MaybeRotation::None\n    @export tail: i32 = 0\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("flag:0:bool:export"), "{}", ir);
    assert!(ir.contains("rot:16:MaybeRotation:export"), "a payload enum holding a Quat needs 16-byte alignment after a 1-byte bool: {}", ir);
    // `{ i32 tag, [1 x <2 x i64>] }`: tag padded to 16, plus one 16-byte
    // word for the `Quat` payload = 32 bytes total, so `tail` follows at
    // `16 + 32 = 48`.
    assert!(ir.contains("tail:48:i32:export"), "{}", ir);
}

/// f-string interpolation of an aggregate carrying negative/large-magnitude
/// float lanes, and of two distinct aggregate/bare-scalar builtin types
/// mixed with a plain `i32` in one format string -- beyond the already-fixed
/// general aggregate case (`todo.md`'s follow-up round), specifically
/// exercising negative numbers (a literal `-` byte inside the
/// constructor-call-syntax rendering), a large magnitude that needs more
/// than one digit of exponent-free `%f` output, and `Color32` (a bare `%u`
/// hole, not the aggregate path -- see round 5's fix) alongside `Quat` (the
/// aggregate path) in the same format string.
#[test]
fn runtime_fstring_aggregate_with_negative_and_large_values_and_mixed_types_end_to_end() {
    let src = "fn main():\n    \
               let v = Vec2(-1.5, 123456.0)\n    \
               println(f\"v={v}\")\n    \
               let c = Color32(10, 20, 30, 40)\n    \
               let q = Quat(0.0, 0.0, 0.0, 1.0)\n    \
               let n = 7\n    \
               println(f\"n={n} c={c} q={q}\")\n";
    let output = compile_and_run("fstring_aggregate_negative_large_mixed", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines[0], "v=Vec2(-1.500000, 123456.000000)");
    // `Color32(10, 20, 30, 40)` packs to `10 | 20<<8 | 30<<16 | 40<<24 =
    // 673059850`, printed as its raw packed `%u` value (not constructor
    // syntax -- `Color32` is a bare scalar, not an aggregate).
    assert_eq!(lines[1], "n=7 c=673059850 q=Quat(0.000000, 0.000000, 0.000000, 1.000000)");
}

// --- `Rect`/`Aabb2`/`Aabb3`/`Ray`/`Plane`/`Frustum`/`Transform` -----------

/// `Rect`/`Aabb2`/`Aabb3`/`Ray`/`Plane`/`Frustum`/`Transform` are ordinary
/// nominal structs (`crate::types::builtin_structs`): named-argument
/// construction and field access already work like any user-declared
/// struct, with no dedicated codegen of their own.
#[test]
fn runtime_geometry_struct_named_construction_and_field_access_end_to_end() {
    let src = "fn main():\n    \
               let r = Rect(x = 1.0, y = 2.0, width = 3.0, height = 4.0)\n    \
               println(f\"{r.x}, {r.y}, {r.width}, {r.height}\")\n    \
               let a = Aabb2(min = Vec2(0.0, 0.0), max = Vec2(1.0, 1.0))\n    \
               println(f\"{a.min.x}, {a.max.y}\")\n";
    let output = compile_and_run("geometry_struct_named_construction", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["1.000000, 2.000000, 3.000000, 4.000000", "0.000000, 1.000000"]);
}

#[test]
fn runtime_rect_contains_and_intersects_end_to_end() {
    let src = "fn main():\n    \
               let r = Rect(x = 0.0, y = 0.0, width = 10.0, height = 10.0)\n    \
               println(f\"{rect_contains(r, Vec2(5.0, 5.0))}\")\n    \
               println(f\"{rect_contains(r, Vec2(50.0, 5.0))}\")\n    \
               let overlapping = Rect(x = 5.0, y = 5.0, width = 10.0, height = 10.0)\n    \
               let far_away = Rect(x = 100.0, y = 100.0, width = 10.0, height = 10.0)\n    \
               println(f\"{rect_intersects(r, overlapping)}\")\n    \
               println(f\"{rect_intersects(r, far_away)}\")\n";
    let output = compile_and_run("rect_contains_intersects", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "false", "true", "false"]);
}

#[test]
fn runtime_aabb2_contains_and_intersects_end_to_end() {
    let src = "fn main():\n    \
               let a = Aabb2(min = Vec2(0.0, 0.0), max = Vec2(10.0, 10.0))\n    \
               println(f\"{aabb2_contains(a, Vec2(1.0, 1.0))}\")\n    \
               println(f\"{aabb2_contains(a, Vec2(50.0, 1.0))}\")\n    \
               let overlapping = Aabb2(min = Vec2(5.0, 5.0), max = Vec2(15.0, 15.0))\n    \
               let far_away = Aabb2(min = Vec2(100.0, 100.0), max = Vec2(110.0, 110.0))\n    \
               println(f\"{aabb2_intersects(a, overlapping)}\")\n    \
               println(f\"{aabb2_intersects(a, far_away)}\")\n";
    let output = compile_and_run("aabb2_contains_intersects", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "false", "true", "false"]);
}

#[test]
fn runtime_aabb3_contains_and_intersects_end_to_end() {
    let src = "fn main():\n    \
               let a = Aabb3(min = Vec3(0.0, 0.0, 0.0), max = Vec3(10.0, 10.0, 10.0))\n    \
               println(f\"{aabb3_contains(a, Vec3(1.0, 1.0, 1.0))}\")\n    \
               println(f\"{aabb3_contains(a, Vec3(50.0, 1.0, 1.0))}\")\n    \
               let overlapping = Aabb3(min = Vec3(5.0, 5.0, 5.0), max = Vec3(15.0, 15.0, 15.0))\n    \
               let far_away = Aabb3(min = Vec3(100.0, 100.0, 100.0), max = Vec3(110.0, 110.0, 110.0))\n    \
               println(f\"{aabb3_intersects(a, overlapping)}\")\n    \
               println(f\"{aabb3_intersects(a, far_away)}\")\n";
    let output = compile_and_run("aabb3_contains_intersects", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "false", "true", "false"]);
}

#[test]
fn runtime_ray_at_end_to_end() {
    let src = "fn main():\n    \
               let ray = Ray(origin = Vec3(1.0, 2.0, 3.0), direction = Vec3(1.0, 0.0, 0.0))\n    \
               let p = ray_at(ray, 5.0)\n    \
               println(f\"{p.x}, {p.y}, {p.z}\")\n";
    let output = compile_and_run("ray_at", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim(), "6.000000, 2.000000, 3.000000");
}

#[test]
fn runtime_plane_distance_to_point_end_to_end() {
    let src = "fn main():\n    \
               let ground = Plane(normal = Vec3(0.0, 1.0, 0.0), distance = 0.0)\n    \
               println(f\"{plane_distance_to_point(ground, Vec3(0.0, 3.0, 0.0))}\")\n    \
               println(f\"{plane_distance_to_point(ground, Vec3(0.0, -2.0, 0.0))}\")\n";
    let output = compile_and_run("plane_distance_to_point", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["3.000000", "-2.000000"]);
}

#[test]
fn runtime_frustum_contains_point_end_to_end() {
    let src = "fn main():\n    \
               let ground = Plane(normal = Vec3(0.0, 1.0, 0.0), distance = 0.0)\n    \
               let planes: [Plane; 6] = [ground; 6]\n    \
               let frustum = Frustum(planes)\n    \
               println(f\"{frustum_contains_point(frustum, Vec3(0.0, 1.0, 0.0))}\")\n    \
               println(f\"{frustum_contains_point(frustum, Vec3(0.0, -1.0, 0.0))}\")\n";
    let output = compile_and_run("frustum_contains_point", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "false"]);
}

#[test]
fn runtime_transform_apply_point_end_to_end() {
    let src = "fn main():\n    \
               let t = Transform(position = Vec3(1.0, 0.0, 0.0), rotation = quat_identity(), scale = Vec3(2.0, 2.0, 2.0))\n    \
               let p = transform_apply_point(t, Vec3(1.0, 0.0, 0.0))\n    \
               println(f\"{p.x}, {p.y}, {p.z}\")\n";
    let output = compile_and_run("transform_apply_point", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim(), "3.000000, 0.000000, 0.000000");
}

/// `transform_apply_point` also applies a non-identity rotation, exercising
/// `quat_rotate` and the scale/rotate/translate composition together.
#[test]
fn runtime_transform_apply_point_with_rotation_end_to_end() {
    let src = "fn main():\n    \
               let rot90 = Quat(0.0, 0.0, 0.70710678, 0.70710678)\n    \
               let t = Transform(position = Vec3(0.0, 0.0, 0.0), rotation = rot90, scale = Vec3(1.0, 1.0, 1.0))\n    \
               let p = transform_apply_point(t, Vec3(1.0, 0.0, 0.0))\n    \
               println(f\"{p.x}, {p.y}, {p.z}\")\n";
    let output = compile_and_run("transform_apply_point_rotation", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim(), "0.000000, 1.000000, 0.000000");
}

#[test]
fn rejects_rect_contains_wrong_argument_type() {
    let src = "fn main():\n    let r = Rect(x = 0.0, y = 0.0, width = 1.0, height = 1.0)\n    let b = rect_contains(r, Vec3(0.0, 0.0, 0.0))\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("rect_contains(Rect, Vec3) should be rejected");
    assert!(diags.iter().any(|d| d.message.contains("argument 2 expected `Vec2`")), "{:?}", diags);
}

#[test]
fn rejects_aabb2_intersects_wrong_argument_type() {
    let src = "fn main():\n    \
               let a = Aabb2(min = Vec2(0.0, 0.0), max = Vec2(1.0, 1.0))\n    \
               let b = Aabb3(min = Vec3(0.0, 0.0, 0.0), max = Vec3(1.0, 1.0, 1.0))\n    \
               let ok = aabb2_intersects(a, b)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("aabb2_intersects(Aabb2, Aabb3) should be rejected");
    assert!(diags.iter().any(|d| d.message.contains("argument 2 expected `Aabb2`")), "{:?}", diags);
}

#[test]
fn rejects_redeclaring_builtin_geometry_struct_name() {
    let src = "struct Rect:\n    thing: i32\n\nfn main():\n    let r = Rect(thing = 1)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("re-declaring the builtin `Rect` struct should be rejected");
    assert!(diags.iter().any(|d| d.message.contains("declared more than once")), "{:?}", diags);
}

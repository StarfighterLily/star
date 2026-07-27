//! `BitField<N>` broadened interop coverage; shared `Ty::eq_only_scalar_shape` binop-dispatch unification
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== `BitField<N>` broadened interop coverage (bug-hunting audit round
// focused on this type -- everything below was verified against a real
// compile+run, not just read from source; see each test's own doc comment
// for what was specifically being checked and why) =====================

/// A `BitField<N>` struct field must land at the byte offset real LLVM struct
/// layout actually places it at, not a naive field-size sum -- same "every
/// field needs alignment padding" class of bug `codegen_reflect_metadata_
/// offsets_account_for_field_alignment` already covers for `bool`/`i32`/
/// `str`/`float`, exercised here end to end (not just IR-string offsets) for
/// a struct that mixes a 1-byte-aligned `BitField<8>` with an 8-byte-aligned
/// `BitField<64>` followed by a 4-byte-aligned `i32`: `a` must not corrupt
/// `b`'s bits (or vice versa) once `c` is packed in behind them.
#[test]
fn runtime_bitfield_as_struct_field_mixed_alignment_end_to_end() {
    let src = "struct Reg:\n    a: BitField<8>\n    b: BitField<64>\n    c: i32\n\nfn main():\n    let r = Reg(a = BitField<8>(1 as u8), b = BitField<64>(2), c = 3)\n    println(f\"{r.a}\")\n    println(f\"{r.b}\")\n    println(f\"{r.c}\")\n";
    let output = compile_and_run("bitfield_struct_field_mixed_alignment", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["1", "2", "3"], "{}", stdout);
}

/// `List<BitField<N>>`: push/index/len work the same as any other element
/// type -- `BitField<N>` carries no RC header (see `Ty::BitField`'s doc
/// comment), so this exercises `List<T>`'s plain-value (non-RC) element path.
#[test]
fn runtime_bitfield_as_list_element_end_to_end() {
    let src = "fn main():\n    let mut xs: List<BitField<8>> = List<BitField<8>>()\n    xs.push(BitField<8>(1 as u8))\n    xs.push(BitField<8>(2 as u8))\n    println(f\"{xs[0]}\")\n    println(f\"{xs[1]}\")\n    println(f\"{xs.len()}\")\n";
    let output = compile_and_run("bitfield_list_element", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["1", "2", "2"], "{}", stdout);
}

/// `Map<K, BitField<N>>` as the *value* type (companion to the existing
/// `runtime_bitfield_as_set_key_dedups_correctly_end_to_end`, which only
/// exercises `BitField<N>` as a *key*) -- insert/get round-trips the value
/// unchanged.
#[test]
fn runtime_bitfield_as_map_value_end_to_end() {
    let src = "fn main():\n    let mut m: Map<i32, BitField<16>> = Map<i32, BitField<16>>()\n    m.insert(1, BitField<16>(100))\n    match m.get(1):\n        Option::Some(x) -> println(f\"{x}\")\n        Option::None -> println(\"missing\")\n";
    let output = compile_and_run("bitfield_map_value", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "100");
}

/// `Ring<BitField<N>, M>`: indexed push/read, plus `pop()` on an *empty*
/// ring yielding `BitField<N>`'s zero value (`Codegen`'s `Ty::BitField(..) =>
/// "0"` zero-value table) rather than garbage/a crash -- mirrors `Ring<T,N>`'s
/// documented fails-safe convention (see `examples/ring.star`).
#[test]
fn runtime_bitfield_as_ring_element_end_to_end() {
    let src = "fn main():\n    let mut r: Ring<BitField<8>, 3> = Ring<BitField<8>, 3>()\n    r.push(BitField<8>(1 as u8))\n    r.push(BitField<8>(2 as u8))\n    println(f\"{r[0]}\")\n    println(f\"{r[1]}\")\n    let mut empty: Ring<BitField<8>, 2> = Ring<BitField<8>, 2>()\n    println(f\"{empty.pop()}\")\n";
    let output = compile_and_run("bitfield_ring_element", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["1", "2", "0"], "{}", stdout);
}

/// `Table<T>` (struct-of-arrays) with a `BitField<8>` column, alongside an
/// ordinary `i32` column -- each column grows independently, so this checks
/// the `BitField<8>` column isn't corrupted by the `i32` column's own growth/
/// reassembly on `push`/indexed read.
#[test]
fn runtime_bitfield_as_table_column_end_to_end() {
    let src = "struct Reg:\n    flags: BitField<8>\n    id: i32\n\nfn main():\n    let mut t: Table<Reg> = Table<Reg>()\n    t.push(Reg(flags = BitField<8>(9 as u8), id = 1))\n    t.push(Reg(flags = BitField<8>(200 as u8), id = 2))\n    println(f\"{t[0].flags}\")\n    println(f\"{t[1].flags}\")\n";
    let output = compile_and_run("bitfield_table_column", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["9", "200"], "{}", stdout);
}

/// `[BitField<N>; M]` fixed-size array: the `[value; N]` repeat literal
/// (the only array-literal form this compiler has) plus an indexed write
/// mutating one slot without disturbing its neighbors.
#[test]
fn runtime_bitfield_as_array_element_end_to_end() {
    let src = "fn main():\n    let mut arr: [BitField<8>; 3] = [BitField<8>(9 as u8); 3]\n    arr[1] = BitField<8>(200 as u8)\n    println(f\"{arr[0]}\")\n    println(f\"{arr[1]}\")\n    println(f\"{arr[2]}\")\n";
    let output = compile_and_run("bitfield_array_element", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["9", "200", "9"], "{}", stdout);
}

/// `BitField<N>` flows through a generic `fn identity<T>(x: T) -> T` type
/// parameter unchanged, same as any other monomorphized-per-call-site type.
#[test]
fn runtime_bitfield_as_generic_fn_param_end_to_end() {
    let src = "fn identity<T>(x: T) -> T:\n    return x\n\nfn main():\n    let a: BitField<8> = BitField<8>(5 as u8)\n    let b = identity(a)\n    println(f\"{b}\")\n";
    let output = compile_and_run("bitfield_generic_fn_param", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "5");
}

/// A closure capturing a `BitField<N>` local reads the captured value
/// correctly -- `BitField<N>` has no RC header, so this exercises the
/// plain-scalar-capture path (not the RC-retain-on-capture path `str`/
/// `List<T>` captures need).
#[test]
fn runtime_bitfield_closure_capture_end_to_end() {
    let src = "fn main():\n    let a: BitField<8> = BitField<8>(5 as u8)\n    let f = fn(): println(f\"{a}\")\n    f()\n";
    let output = compile_and_run("bitfield_closure_capture", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "5");
}

/// A `BitField<8>` arena-struct field mutated inside a `par` statement (real
/// worker threads, see `crate::codegen::par`) via `bit_set` -- every worker
/// must see its own entity's mutation land, not race/lose an update. Two
/// entities so a single-worker fallback couldn't accidentally hide a
/// cross-thread bug.
#[test]
fn runtime_bitfield_par_mutation_end_to_end() {
    let src = "struct Reg:\n    mut flags: BitField<8>\n\narena Regs: Reg\n\nfn main():\n    spawn Regs(BitField<8>(0))\n    spawn Regs(BitField<8>(0))\n    par r in Regs:\n        r.flags = bit_set(r.flags, 3)\n    swarm r in Regs:\n        println(f\"{r.flags}\")\n";
    let output = compile_and_run("bitfield_par_mutation", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["8", "8"], "{}", stdout);
}

/// `Option<BitField<N>>` -- a `BitField<N>` payload flows through the builtin
/// tagged-union `Option` enum (`{ i32 tag, [W x i64] payload }`) and back out
/// via `match` unchanged.
#[test]
fn runtime_bitfield_as_option_payload_end_to_end() {
    let src = "fn main():\n    let a: Option<BitField<8>> = Option::Some(BitField<8>(42 as u8))\n    match a:\n        Option::Some(x) -> println(f\"{x}\")\n        Option::None -> println(\"none\")\n";
    let output = compile_and_run("bitfield_option_payload", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "42");
}

/// Every `BitField<N>` width (`8`/`16`/`32`/`64`) printed through the
/// *general* f-string value path (an f-string first bound to a `let`, then
/// passed to `println` as a plain `str` -- `Codegen::emit_expr`'s
/// `TypedExpr::FStr` arm in `expr.rs`) rather than `println`'s own direct
/// sole-argument fast path (`emit_print_like` in `builtins.rs`, already
/// covered by `runtime_bitfield_widths_32_and_64_end_to_end`/
/// `runtime_bitfield_construction_and_print_end_to_end`) -- a separate
/// format-specifier table with its own C-varargs-promotion rules per width,
/// the exact spot round 5 found `Color32`/`PaletteIndex` missing an explicit
/// arm in one of the two tables but not the other.
#[test]
fn runtime_bitfield_fstr_general_value_path_all_widths_end_to_end() {
    let src = "fn main():\n    let a: BitField<8> = BitField<8>(200 as u8)\n    let b: BitField<16> = BitField<16>(50000)\n    let c: BitField<32> = BitField<32>(4000000000)\n    let d: BitField<64> = BitField<64>(10000000000)\n    let sa = f\"{a}\"\n    let sb = f\"{b}\"\n    let sc = f\"{c}\"\n    let sd = f\"{d}\"\n    println(sa)\n    println(sb)\n    println(sc)\n    println(sd)\n";
    let output = compile_and_run("bitfield_fstr_general_value_path", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["200", "50000", "4000000000", "10000000000"], "{}", stdout);
}

/// `expr as BitField<N>` at a matching width is a bit-preserving relabel
/// (see `Ty::BitField`'s doc comment), not a value-preserving numeric
/// conversion -- casting a *negative* signed value reinterprets its two's-
/// complement bit pattern as the unsigned register value (`-1i8`'s bit
/// pattern `0xFF` prints as `255`, `-1i32`'s `0xFFFFFFFF` prints as
/// `4294967295`), matching `as`'s existing infallible-truncating convention
/// rather than e.g. saturating at 0.
#[test]
fn runtime_bitfield_cast_from_negative_signed_value_end_to_end() {
    let src = "fn main():\n    let s: i8 = -1 as i8\n    let bf: BitField<8> = s as BitField<8>\n    println(f\"{bf}\")\n    let s2: i32 = -1\n    let bf2: BitField<32> = s2 as BitField<32>\n    println(f\"{bf2}\")\n";
    let output = compile_and_run("bitfield_cast_from_negative_signed", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["255", "4294967295"], "{}", stdout);
}

/// A *negative* bit index behaves the same as an out-of-range positive one
/// (`runtime_bitfield_out_of_range_index_wraps_rather_than_traps_end_to_end`
/// above only covers `>= N`): `idx & (width - 1)` is plain two's-complement
/// bitwise AND, so `-1` (all bits set) masks down to `width - 1` -- the top
/// bit -- rather than trapping or reading/writing an unrelated bit. Verified
/// against a real `2u8` register (`00000010`): its bit 7 is `0`, matching
/// `bit_get(a, 7)` exactly; `bit_set(a, -1)` then sets that same top bit,
/// yielding `130` (`2 | 128`).
#[test]
fn runtime_bitfield_negative_bit_index_masks_like_out_of_range_end_to_end() {
    let src = "fn main():\n    let a: BitField<8> = BitField<8>(2 as u8)\n    println(f\"{bit_get(a, -1)}\")\n    println(f\"{bit_get(a, 7)}\")\n    let b = bit_set(a, -1)\n    println(f\"{b}\")\n";
    let output = compile_and_run("bitfield_negative_bit_index", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["false", "false", "130"], "{}", stdout);
}

/// A packed register has no meaningful "less than" -- `<`/`>`/`<=`/`>=` must
/// be rejected between two `BitField<N>` values with a located diagnostic
/// (same "only `==`/`!=`" restriction `Ty::Symbol`/`Ty::Str`/`Ty::Ptr` already
/// have), not silently accepted or a late codegen crash.
#[test]
fn rejects_bitfield_ordering_comparison() {
    let src = "fn main():\n    let a: BitField<8> = BitField<8>(1 as u8)\n    let b: BitField<8> = BitField<8>(2 as u8)\n    let c = a < b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("only `==`/`!=` are supported between `BitField<N>` values")), "{:?}", diags);
}

/// `BitField<N>` isn't `is_numeric()` (see `Ty::BitField`'s doc comment: "a
/// packed register isn't a number to do arithmetic on") -- `+`/`-`/`*` must
/// be rejected between two `BitField<N>` values with a located diagnostic,
/// not silently accepted or a late codegen crash.
#[test]
fn rejects_bitfield_arithmetic() {
    let src = "fn main():\n    let a: BitField<8> = BitField<8>(1 as u8)\n    let b: BitField<8> = BitField<8>(2 as u8)\n    let c = a + b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("not supported")), "{:?}", diags);
}

// ===== todo.md P3 #12: shared `Ty::eq_only_scalar_shape` binop-dispatch =====
//
// `Symbol`/`BitField<N>`/`Flags<E>`/`Color32`/`PaletteIndex` all share one
// underlying shape -- `==`/`!=` only, no ordering, no arithmetic, backed by a
// single opaque-width `icmp` -- and used to each get their own hand-copied
// `if` block in both `Checker::infer_binop_ty` and `Codegen::emit_binop`.
// They're now driven by one shared `Ty::eq_only_scalar_shape` table instead.
// `Symbol`/`Color32`/`BitField<N>` ordering/arithmetic rejection already had
// coverage above; the tests below close the matching gap for `Flags<E>`/
// `PaletteIndex` (previously untested), then add regression coverage aimed
// specifically at the new shared table: a wrong-width mismatch between two
// otherwise-eligible types must still fall through to the generic mismatch
// diagnostic rather than being silently accepted or misreporting the wrong
// type's name, and each type's `icmp` must use its own distinct bit width
// rather than accidentally sharing another table entry's.

/// A `Flags<E>` bitmask has no meaningful "less than" -- `<` must be
/// rejected with the same located diagnostic `BitField<N>`/`Color32` already
/// get, not silently accepted or a late codegen crash.
#[test]
fn rejects_flags_ordering_comparison() {
    let src = "enum Dir:\n    Up\n    Down\n\n\
               fn main():\n    let a: Flags<Dir> = Flags<Dir>()\n    let b: Flags<Dir> = Flags<Dir>()\n    let c = a < b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("`<` between Flags<E> values should be rejected");
    assert!(diags.iter().any(|d| d.message.contains("only `==`/`!=` are supported between `Flags<E>` values")), "{:?}", diags);
}

/// `Flags<E>` isn't `is_numeric()` -- `+` must be rejected between two
/// `Flags<E>` values with a located diagnostic (union/intersect/symmetric-
/// difference go through `bit_or`/`bit_and`/`bit_xor` instead, never a raw
/// operator).
#[test]
fn rejects_flags_arithmetic() {
    let src = "enum Dir:\n    Up\n    Down\n\n\
               fn main():\n    let a: Flags<Dir> = Flags<Dir>()\n    let b: Flags<Dir> = Flags<Dir>()\n    let c = a + b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("not supported")), "{:?}", diags);
}

/// A palette slot has no meaningful "less than" -- `<` must be rejected with
/// the same located diagnostic `BitField<N>`/`Color32`/`Flags<E>` already
/// get, not silently accepted or a late codegen crash.
#[test]
fn rejects_palette_index_ordering_comparison() {
    let src = "fn main():\n    let a: PaletteIndex = PaletteIndex(1)\n    let b: PaletteIndex = PaletteIndex(2)\n    let c = a < b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("`<` between PaletteIndex values should be rejected");
    assert!(diags.iter().any(|d| d.message.contains("only `==`/`!=` are supported between `PaletteIndex` values")), "{:?}", diags);
}

/// `PaletteIndex` isn't `is_numeric()` -- `+` must be rejected between two
/// `PaletteIndex` values with a located diagnostic, not silently accepted or
/// a late codegen crash.
#[test]
fn rejects_palette_index_arithmetic() {
    let src = "fn main():\n    let a: PaletteIndex = PaletteIndex(1)\n    let b: PaletteIndex = PaletteIndex(2)\n    let c = a + b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("not supported")), "{:?}", diags);
}

/// Two `BitField<N>` values of *different* `N` must still be rejected as a
/// plain type mismatch (`eq_only_scalar_shape`'s shared block gates on exact
/// `lhs_ty == rhs_ty`, not merely "both sides are some `BitField`") -- must
/// not silently compare across widths, and must not misreport the generic
/// mismatch as the type-specific "only `==`/`!=` are supported between
/// `BitField<N>` values" message (that message asserts both sides already
/// share one width; a cross-width pair never reaches it).
#[test]
fn rejects_bitfield_equality_between_mismatched_widths() {
    let src = "fn main():\n    let a: BitField<8> = BitField<8>(1 as u8)\n    let b: BitField<16> = BitField<16>(1 as u16)\n    let c = a == b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("BitField<8> == BitField<16> should be rejected");
    assert!(diags.iter().any(|d| d.message.contains("not supported") && d.message.contains("BitField")), "{:?}", diags);
    assert!(
        !diags.iter().any(|d| d.message.contains("only `==`/`!=` are supported between `BitField<N>` values")),
        "a cross-width pair must hit the generic mismatch diagnostic, not the same-width-specific one: {:?}",
        diags
    );
}

/// Two *different* `eq_only_scalar_shape` types (`Symbol` vs `Color32`) must
/// be rejected as a mismatch, not silently accepted -- the shared table's
/// gate must key off both sides sharing the exact same `Ty`, not merely off
/// either side individually being some eq-only-scalar type.
#[test]
fn rejects_equality_between_different_eq_only_scalar_types() {
    let src = "fn main():\n    let a = Symbol(\"x\")\n    let b = Color32(1, 2, 3, 4)\n    let c = a == b\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("Symbol == Color32 should be rejected");
    assert!(diags.iter().any(|d| d.message.contains("not supported")), "{:?}", diags);
}

/// Codegen regression for the shared table itself: each `eq_only_scalar_shape`
/// type must emit `icmp eq/ne` at *its own* bit width (`Symbol`/`Flags<E>` ->
/// `i64`, a `BitField<16>` -> `i16` specifically (not `BitField`'s most
/// common `i8`/`i32` test cases elsewhere, so a table entry that dropped the
/// `N` and hardcoded a width would still be caught), `Color32` -> `i32`,
/// `PaletteIndex` -> `i8`) -- a mis-keyed shared table (e.g. two entries'
/// widths transposed) would still type-check cleanly and only show up here,
/// at the IR shape level.
#[test]
fn codegen_eq_only_scalar_types_emit_correct_icmp_width_per_type() {
    let src = "enum Dir:\n    Up\n    Down\n\n\
               fn sym_eq(a: Symbol, b: Symbol) -> bool:\n    a == b\n\n\
               fn bits_eq(a: BitField<16>, b: BitField<16>) -> bool:\n    a == b\n\n\
               fn flags_eq(a: Flags<Dir>, b: Flags<Dir>) -> bool:\n    a == b\n\n\
               fn color_eq(a: Color32, b: Color32) -> bool:\n    a == b\n\n\
               fn pal_eq(a: PaletteIndex, b: PaletteIndex) -> bool:\n    a == b\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");

    let sym_ir = extract_fn_body(&ir, "define i1 @sym_eq(");
    assert!(sym_ir.contains("icmp eq i64"), "Symbol should compare as i64: {}", sym_ir);

    let bits_ir = extract_fn_body(&ir, "define i1 @bits_eq(");
    assert!(bits_ir.contains("icmp eq i16"), "BitField<16> should compare as i16, not a hardcoded width: {}", bits_ir);

    let flags_ir = extract_fn_body(&ir, "define i1 @flags_eq(");
    assert!(flags_ir.contains("icmp eq i64"), "Flags<E> should compare as i64: {}", flags_ir);

    let color_ir = extract_fn_body(&ir, "define i1 @color_eq(");
    assert!(color_ir.contains("icmp eq i32"), "Color32 should compare as i32: {}", color_ir);

    let pal_ir = extract_fn_body(&ir, "define i1 @pal_eq(");
    assert!(pal_ir.contains("icmp eq i8"), "PaletteIndex should compare as i8: {}", pal_ir);
}

/// Runtime companion to the codegen-shape test above: `BitField<64>` (no
/// dedicated equality coverage elsewhere in this file, whose 64-bit width
/// otherwise-eligible `Symbol`/`Flags<E>` also happen to share) must still
/// compare correctly end to end through the shared table, not just type-
/// check and emit plausible-looking IR.
#[test]
fn runtime_bitfield_64_width_equality_end_to_end() {
    let src = "fn main():\n    \
               let a: BitField<64> = BitField<64>(5000000000)\n    \
               let b: BitField<64> = BitField<64>(5000000000)\n    \
               let c: BitField<64> = BitField<64>(2)\n    \
               println(f\"{a == b}\")\n    println(f\"{a != c}\")\n";
    let output = compile_and_run("bitfield_64_width_equality", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["true", "true"], "{}", stdout);
}

/// `BitField<N>(value)` only accepts an `int_shape()`-having source (see
/// `Ty::BitField`'s doc comment) -- `Wrapping<T>` is deliberately excluded
/// from `int_shape()` too (same "not a number" reasoning), so constructing a
/// `BitField<N>` directly from a `Wrapping<u8>` must be a clean type error,
/// not an implicit double-unwrap.
#[test]
fn rejects_bitfield_construction_from_wrapping_value() {
    let src = "fn main():\n    let w: Wrapping<u8> = Wrapping<u8>(5 as u8)\n    let a: BitField<8> = BitField<8>(w)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("`BitField<N>(..)` expects an integer value")), "{:?}", diags);
}

/// Same reasoning as `rejects_bitfield_construction_from_wrapping_value`,
/// for a `BitField<M>` source: `BitField<N>(value)`'s construction rule only
/// accepts `int_shape()`-having values, and `BitField` itself is deliberately
/// excluded from `int_shape()` -- so `BitField<16>(some_BitField<8>_value)`
/// must be rejected too (`as`, not a constructor call, is the sanctioned way
/// to relabel between two `BitField` widths at all, and even that requires
/// the widths to match exactly).
#[test]
fn rejects_bitfield_construction_from_another_bitfield_value() {
    let src = "fn main():\n    let x: BitField<8> = BitField<8>(5 as u8)\n    let a: BitField<16> = BitField<16>(x)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("`BitField<N>(..)` expects an integer value")), "{:?}", diags);
}

/// `bit_get`/`bit_set`/`bit_clear`/`bit_toggle`'s bit-index argument must be
/// exactly `int` (`i32`) -- a `u8` index (a plausible thing to reach for,
/// since it's a small unsigned count) is rejected with a located diagnostic
/// rather than silently accepted or truncated, same strictness
/// `rejects_bit_get_with_non_integer_index` already covers for a `str` index.
#[test]
fn rejects_bit_get_index_of_non_int_type() {
    let src = "fn main():\n    let a: BitField<8> = BitField<8>(1 as u8)\n    let idx: u8 = 3 as u8\n    let b = bit_get(a, idx)\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("argument 2 (bit index) expected `int`")), "{:?}", diags);
}

/// Reflect metadata offsets for `BitField<N>` fields must account for real
/// alignment/padding across *mixed* widths -- `a: BitField<8>` (1-byte
/// aligned) followed by `b: BitField<64>` (8-byte aligned) needs 7 bytes of
/// padding before `b`, same "every field needs its own arm in the alignment
/// table" class `codegen_reflect_metadata_offsets_account_for_field_
/// alignment` already covers for `bool`/`i32`/`str`/`float`, exercised here
/// specifically for `Ty::BitField`'s own `type_align`/`type_size` arms
/// (`n / 8`).
#[test]
fn codegen_reflect_metadata_bitfield_mixed_width_offsets() {
    let src = "struct Reg:\n    @export a: BitField<8> = BitField<8>(0)\n    @export b: BitField<64> = BitField<64>(0)\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("a:0:BitField<8>:export"), "{}", ir);
    assert!(ir.contains("b:8:BitField<64>:export"), "BitField<64> needs 8-byte alignment after a 1-byte BitField<8>: {}", ir);
}

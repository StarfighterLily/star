//! Bug-hunting round 6: cross-cutting audit of BitField/Color/Color32/PaletteIndex/Mat2/Mat3/Quat combined with generics/memory/par/reflection
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Bug-hunting round 6: cross-cutting audit -- `BitField<N>`/`Color`/=====
// ===== `Color32`/`PaletteIndex`/`Mat2`/`Mat3`/`Quat` combined with the ======
// ===== existing generic/memory machinery (`List`/`Map`/`Set`/`Ring`/`Table`,=
// ===== generics, `arena`/`GenRef`/`Handle`, closures, `par`/`swarm`, =======
// ===== reflection). Not a full audit of any one type in isolation (two =====
// ===== other rounds covered `BitField<N>` and `Color`/geometry each on their
// ===== own) -- scope here is specifically the combinations neither of those
// ===== would think to try. Every one of these reproduced clean (no bug
// ===== found) against a real `star build`+run before being added as a
// ===== permanent regression test; see this round's own `todo.md` writeup for
// ===== the areas that were also audited but didn't get a dedicated test.====

/// A struct mixing an RC field (`str`), a 48-byte `Mat3`, a 2-byte
/// `BitField<16>`, a plain `i32`, and a 4-byte `Color32` -- exactly the
/// "old scalar next to a new odd-sized aggregate" shape that has broken
/// `type_size`/`type_align`/GEP-offset math in this codebase before (see
/// `runtime_arena_of_padded_struct_spawns_past_naive_size_boundary_end_to_end`'s
/// own doc comment for the historical bug class). Spawns 300 into an `arena`
/// (past any small initial-capacity boundary) and separately pushes 300 into
/// a `List<T>` (past its own growth boundary), then reads back the first,
/// middle, and last element of each by `GenRef`/index and confirms every
/// field -- including the `Mat3` (read back via a matrix-vector multiply,
/// since `Mat3` exposes no field accessor) and the `BitField<16>` -- round-
/// trips uncorrupted.
#[test]
fn runtime_arena_and_list_of_struct_mixing_str_mat3_bitfield_color32_end_to_end() {
    let src = "struct Entity:\n    \
                   name: str\n    \
                   xf: Mat3\n    \
                   flags: BitField<16>\n    \
                   id: i32\n    \
                   tint: Color32\n    \
                   hp: i32\n\n\
               arena Entities: Entity\n\n\
               fn main():\n    \
                   for i in 0..300:\n        \
                       let m = Mat3(Vec3(1.0, 0.0, 0.0), Vec3(0.0, 1.0, 0.0), Vec3(0.0, 0.0, (i as float)))\n        \
                       spawn Entities(f\"e{i}\", m, BitField<16>(i as u16), i, Color32(1, 2, 3, 4), i * 2)\n    \
                   let r1 = GenRef<Entity>(0)\n    \
                   let r2 = GenRef<Entity>(150)\n    \
                   let r3 = GenRef<Entity>(299)\n    \
                   println(r1[0].name)\n    \
                   println(f\"{(r1[0].xf * Vec3(0.0, 0.0, 1.0)).z}\")\n    \
                   println(f\"{r1[0].flags}\")\n    \
                   println(f\"{r1[0].hp}\")\n    \
                   println(r2[0].name)\n    \
                   println(f\"{(r2[0].xf * Vec3(0.0, 0.0, 1.0)).z}\")\n    \
                   println(f\"{r2[0].flags}\")\n    \
                   println(f\"{r2[0].hp}\")\n    \
                   println(r3[0].name)\n    \
                   println(f\"{(r3[0].xf * Vec3(0.0, 0.0, 1.0)).z}\")\n    \
                   println(f\"{r3[0].flags}\")\n    \
                   println(f\"{r3[0].hp}\")\n    \
                   let mut xs: List<Entity> = List<Entity>()\n    \
                   for i in 0..300:\n        \
                       let m = Mat3(Vec3(1.0, 0.0, 0.0), Vec3(0.0, 1.0, 0.0), Vec3(0.0, 0.0, (i as float)))\n        \
                       xs.push(Entity(f\"l{i}\", m, BitField<16>(i as u16), i, Color32(9, 8, 7, 6), i * 3))\n    \
                   println(xs[0].name)\n    \
                   println(f\"{(xs[0].xf * Vec3(0.0, 0.0, 1.0)).z}\")\n    \
                   println(f\"{(xs[150].xf * Vec3(0.0, 0.0, 1.0)).z}\")\n    \
                   println(f\"{(xs[299].xf * Vec3(0.0, 0.0, 1.0)).z}\")\n    \
                   println(f\"{xs[299].flags}\")\n    \
                   println(f\"{xs[299].hp}\")\n";
    let output = compile_and_run("arena_list_mixed_mat3_bitfield_color32", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(
        lines,
        vec![
            "e0", "0.000000", "0", "0", "e150", "150.000000", "150", "300", "e299", "299.000000", "299", "598", "l0", "0.000000",
            "150.000000", "299.000000", "299", "897",
        ],
        "{}",
        stdout
    );
}

/// `Map<str, Color32>` insert/get, `Ring<Quat, N>` push past its fixed
/// capacity (eviction of the oldest element), and `Table<T>` (struct-of-
/// arrays) with a `PaletteIndex` field and a `Mat2` field pushed past its own
/// growth boundary -- three different generic collections, three different
/// new-type element/field shapes, in one pass. All three round-trip their
/// stored values correctly.
#[test]
fn runtime_map_color32_ring_quat_table_mat2_paletteindex_end_to_end() {
    let src = "struct Row:\n    \
                   idx: PaletteIndex\n    \
                   xf: Mat2\n    \
                   tag: str\n\n\
               fn get_color(m: Map<str, Color32>, key: str) -> Color32:\n    \
                   match m.get(key):\n        \
                       Option::Some(v) -> v\n        \
                       Option::None -> Color32(0, 0, 0, 0)\n\n\
               fn main():\n    \
                   let mut m: Map<str, Color32> = Map<str, Color32>()\n    \
                   for i in 0..40:\n        \
                       m.insert(f\"k{i}\", Color32(i, i + 1, i + 2, 255))\n    \
                   println(f\"{m.len()}\")\n    \
                   let c0 = get_color(m, \"k0\")\n    \
                   let c39 = get_color(m, \"k39\")\n    \
                   println(f\"{color32_r(c0)},{color32_g(c0)},{color32_b(c0)}\")\n    \
                   println(f\"{color32_r(c39)},{color32_g(c39)},{color32_b(c39)}\")\n    \
                   let mut ring: Ring<Quat, 4> = Ring<Quat, 4>()\n    \
                   ring.push(Quat(0.0, 0.0, 0.0, 1.0))\n    \
                   ring.push(Quat(0.0, 0.0, 0.70710678, 0.70710678))\n    \
                   ring.push(Quat(1.0, 0.0, 0.0, 0.0))\n    \
                   ring.push(Quat(0.0, 1.0, 0.0, 0.0))\n    \
                   ring.push(Quat(0.0, 0.0, 1.0, 0.0))\n    \
                   println(f\"{ring.len()}\")\n    \
                   println(f\"{ring[0].w}\")\n    \
                   println(f\"{ring[3].y}\")\n    \
                   let mut t: Table<Row> = Table<Row>()\n    \
                   for i in 0..150:\n        \
                       let m2 = Mat2(Vec2((i as float), 0.0), Vec2(0.0, 1.0))\n        \
                       t.push(Row((i as u8) as PaletteIndex, m2, f\"row{i}\"))\n    \
                   println(f\"{t.len()}\")\n    \
                   println(f\"{(t[0].xf * Vec2(1.0, 0.0)).x}\")\n    \
                   println(f\"{(t[100].xf * Vec2(1.0, 0.0)).x}\")\n    \
                   println(t[100].tag)\n    \
                   let raw0: u8 = t[0].idx as u8\n    \
                   let raw100: u8 = t[100].idx as u8\n    \
                   println(f\"{raw0},{raw100}\")\n    \
                   t.pop()\n    \
                   println(f\"{t.len()}\")\n";
    let output = compile_and_run("map_ring_table_mixed_new_types", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(
        lines,
        vec![
            "40",
            "0,1,2",
            "39,40,41",
            "4",
            "0.707107",
            "0.000000",
            "150",
            "0.000000",
            "100.000000",
            "row100",
            "0,100",
            "149",
        ],
        "{}",
        stdout
    );
}

/// Odd-element-sized top-level (not struct-nested) generic collections:
/// `List<BitField<8>>`/`List<Mat3>` growing past their initial capacity, and
/// `Ring<BitField<8>, N>`/`Ring<Mat2, N>` pushed past their fixed capacity --
/// a 1-byte `BitField<8>` and a 48-byte `Mat3` are exactly the two ends of
/// the size spectrum this codegen's element-size/growth math could get wrong
/// in opposite ways (undersizing a wide element vs. misaligning a narrow
/// one).
#[test]
fn runtime_list_and_ring_of_odd_sized_new_types_end_to_end() {
    let src = "fn main():\n    \
                   let mut bs: List<BitField<8>> = List<BitField<8>>()\n    \
                   for i in 0..400:\n        \
                       bs.push(BitField<8>((i % 256) as u8))\n    \
                   println(f\"{bs.len()}\")\n    \
                   let x0: u8 = bs[0] as u8\n    \
                   let x200: u8 = bs[200] as u8\n    \
                   let x399: u8 = bs[399] as u8\n    \
                   println(f\"{x0},{x200},{x399}\")\n    \
                   let mut ms: List<Mat3> = List<Mat3>()\n    \
                   for i in 0..200:\n        \
                       ms.push(Mat3(Vec3(1.0, 0.0, 0.0), Vec3(0.0, 1.0, 0.0), Vec3(0.0, 0.0, (i as float))))\n    \
                   println(f\"{ms.len()}\")\n    \
                   let v0 = ms[0] * Vec3(0.0, 0.0, 1.0)\n    \
                   let v199 = ms[199] * Vec3(0.0, 0.0, 1.0)\n    \
                   println(f\"{v0.z},{v199.z}\")\n    \
                   let mut rb: Ring<BitField<8>, 6> = Ring<BitField<8>, 6>()\n    \
                   for i in 0..10:\n        \
                       rb.push(BitField<8>(i as u8))\n    \
                   println(f\"{rb.len()}\")\n    \
                   let r0: u8 = rb[0] as u8\n    \
                   let r5: u8 = rb[5] as u8\n    \
                   println(f\"{r0},{r5}\")\n    \
                   let mut rm: Ring<Mat2, 3> = Ring<Mat2, 3>()\n    \
                   rm.push(Mat2(Vec2(1.0, 0.0), Vec2(0.0, 1.0)))\n    \
                   rm.push(Mat2(Vec2(2.0, 0.0), Vec2(0.0, 2.0)))\n    \
                   rm.push(Mat2(Vec2(3.0, 0.0), Vec2(0.0, 3.0)))\n    \
                   rm.push(Mat2(Vec2(4.0, 0.0), Vec2(0.0, 4.0)))\n    \
                   let p = rm[0] * Vec2(1.0, 1.0)\n    \
                   let q = rm[2] * Vec2(1.0, 1.0)\n    \
                   println(f\"{p.x},{q.x}\")\n";
    let output = compile_and_run("list_ring_odd_sized_new_types", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(
        lines,
        vec!["400", "0,200,143", "200", "0.000000,199.000000", "6", "4,9", "2.000000,4.000000"],
        "{}",
        stdout
    );
}

/// Generic functions/structs instantiated with a new type as the type
/// parameter (`identity<T>(x: T) -> T` called with a `Quat`; user-defined
/// `struct Box<T>: value: T` instantiated as `Box<BitField<16>>`/
/// `Box<Color32>`/`Box<Mat3>`) round-trip their value correctly through
/// monomorphized generic codegen.
#[test]
fn runtime_generic_fn_and_struct_instantiated_with_new_types_end_to_end() {
    let src = "struct Box<T>:\n    \
                   value: T\n\n\
               fn identity<T>(x: T) -> T:\n    \
                   return x\n\n\
               fn main():\n    \
                   let q = Quat(0.1, 0.2, 0.3, 0.9)\n    \
                   let q2 = identity(q)\n    \
                   println(f\"{q2.x},{q2.y},{q2.z},{q2.w}\")\n    \
                   let bf = BitField<16>(4242 as u16)\n    \
                   let boxed = Box<BitField<16>>(bf)\n    \
                   println(f\"{boxed.value}\")\n    \
                   let c = Color32(10, 20, 30, 40)\n    \
                   let boxed_c = Box(c)\n    \
                   println(f\"{color32_r(boxed_c.value)},{color32_g(boxed_c.value)}\")\n    \
                   let m3 = Mat3(Vec3(1.0, 0.0, 0.0), Vec3(0.0, 2.0, 0.0), Vec3(0.0, 0.0, 3.0))\n    \
                   let boxed_m = Box(m3)\n    \
                   let pv = boxed_m.value * Vec3(1.0, 1.0, 1.0)\n    \
                   println(f\"{pv.x},{pv.y},{pv.z}\")\n";
    let output = compile_and_run("generic_fn_struct_new_types", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(
        lines,
        vec!["0.100000,0.200000,0.300000,0.900000", "4242", "10,20", "1.000000,2.000000,3.000000"],
        "{}",
        stdout
    );
}

/// Closures capturing a `Color32`/`Quat`/`BitField<32>` local by value: these
/// are plain-value, no-RC types (`Codegen::contains_rc` returns `false` for
/// all three), so the capture should be a straightforward by-value snapshot
/// with no retain/release codegen emitted at all -- confirmed indirectly
/// here by the captured values reading back correctly after the originals
/// are no longer touched (a type-confused RC walk over a non-pointer
/// register would be a miscompile/crash, not just a wrong value). Also
/// covers two independent closures each capturing a distinct `Color32`
/// local, to rule out one capture's storage aliasing another's.
#[test]
fn runtime_closure_captures_color32_quat_bitfield_by_value_end_to_end() {
    let src = "fn main():\n    \
                   let color_local = Color32(77, 88, 99, 111)\n    \
                   let quat_local = Quat(0.0, 0.0, 0.0, 1.0)\n    \
                   let bits_local = BitField<32>(999 as u32)\n    \
                   let make_reader = fn() -> i32:\n        \
                       color32_r(color_local) + (bits_local as u32 as i32)\n    \
                   println(f\"{make_reader()}\")\n    \
                   println(f\"{quat_local.w}\")\n    \
                   let a = Color32(1, 1, 1, 1)\n    \
                   let b = Color32(2, 2, 2, 2)\n    \
                   let fa = fn() -> i32: color32_r(a)\n    \
                   let fb = fn() -> i32: color32_r(b)\n    \
                   println(f\"{fa()},{fb()}\")\n";
    let output = compile_and_run("closure_captures_color_quat_bitfield", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["1076", "1.000000", "1,2"], "{}", stdout);
}

/// `par`/`swarm` over an `arena` of a struct with `Mat3`/`Quat`/`Color32`/
/// `BitField<16>` fields, all `mut`: reads the `Mat3` field, writes all four
/// fields inside the `par` body, then reads every field back in a `swarm`
/// (printing one line per entity -- `par`/`swarm` don't guarantee iteration
/// order across the 4-worker pool, so correctness is checked per-line below
/// rather than against a fixed expected order, the same "verify the
/// invariant, not the interleaving" shape `par_nested.star` already
/// established). Confirms both that the disjointness analysis doesn't
/// spuriously reject mutating these fields (`par_analysis` has no type-
/// specific logic at all, but this is the first real end-to-end proof for
/// this exact field-type mix) and that the values computed under real
/// parallelism are correct (`hp` is `original_index + 1`, matching the
/// per-iteration `Mat3`-derived `z` component), not just crash-free.
#[test]
fn runtime_par_swarm_over_arena_with_mat3_quat_color32_bitfield_fields_end_to_end() {
    let src = "struct Unit:\n    \
                   mut xf: Mat3\n    \
                   mut rot: Quat\n    \
                   mut tint: Color32\n    \
                   mut flags: BitField<16>\n    \
                   mut hp: i32\n\n\
               arena Units: Unit\n\n\
               fn main():\n    \
                   for i in 0..40:\n        \
                       let m = Mat3(Vec3(1.0, 0.0, 0.0), Vec3(0.0, 1.0, 0.0), Vec3(0.0, 0.0, (i as float)))\n        \
                       spawn Units(m, quat_identity(), Color32(0, 0, 0, 0), BitField<16>(0 as u16), i)\n    \
                   par u in Units:\n        \
                       u.hp = u.hp + 1\n        \
                       u.rot = quat_normalize(Quat(0.0, 0.0, 0.0, 2.0))\n        \
                       u.tint = Color32(1, 2, 3, 4)\n        \
                       u.flags = bit_set(u.flags, 0)\n    \
                   swarm u in Units:\n        \
                       let z = (u.xf * Vec3(0.0, 0.0, 1.0)).z\n        \
                       println(f\"{u.hp},{z},{u.rot.w},{color32_r(u.tint)},{u.flags}\")\n";
    let output = compile_and_run("par_swarm_arena_mat3_quat_color32_bitfield", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines.len(), 40, "expected one line per entity: {}", stdout);
    for line in &lines {
        let parts: Vec<&str> = line.split(',').collect();
        assert_eq!(parts.len(), 5, "{}", line);
        let hp: f64 = parts[0].parse().unwrap();
        let z: f64 = parts[1].parse().unwrap();
        assert_eq!(hp, z + 1.0, "hp should be original index + 1, matching the Mat3-derived z: {}", line);
        assert_eq!(parts[2], "1.000000", "quat_normalize should yield a unit w: {}", line);
        assert_eq!(parts[3], "1", "Color32 r channel should be 1: {}", line);
        assert_eq!(parts[4], "1", "BitField<16> bit 0 should be set: {}", line);
    }
}

/// `@export`/`@tweakable` reflection on a struct mixing `str`, `BitField<16>`,
/// `Color32`, `PaletteIndex`, `Mat2`, `i32`, `Quat`, and `Mat3` fields:
/// confirms the emitted byte offset (hand-computed against real LLVM struct
/// layout: each field padded to its own alignment) and reported type-name
/// string are correct for every one of the new types at once, in a single
/// struct, rather than one at a time -- the shape a single-type audit
/// wouldn't think to combine.
#[test]
fn codegen_reflect_metadata_offsets_correct_for_mixed_new_type_struct() {
    let src = "struct Everything:\n    \
                   tag: str\n    \
                   @export flags: BitField<16> = BitField<16>(0 as u16)\n    \
                   @export tint: Color32 = Color32(0, 0, 0, 0)\n    \
                   @tweakable idx: PaletteIndex = PaletteIndex(0)\n    \
                   @export basis: Mat2 = Mat2(Vec2(1.0, 0.0), Vec2(0.0, 1.0))\n    \
                   n: i32\n    \
                   @tweakable rot: Quat = quat_identity()\n    \
                   @export basis3: Mat3 = Mat3(Vec3(1.0, 0.0, 0.0), Vec3(0.0, 1.0, 0.0), Vec3(0.0, 0.0, 1.0))\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    // str(8,align8)@0; BitField<16>(2,align2)@8; Color32(4,align4)@12 (10->12);
    // PaletteIndex(1,align1)@16; Mat2(16,align8)@24 (17->24); i32@40 (skipped,
    // no decorator); Quat(16,align16)@48 (44->48); Mat3(48,align16)@64 (64->64).
    assert!(
        ir.contains(
            "c\"flags:8:BitField<16>:export;tint:12:Color32:export;idx:16:PaletteIndex:tweakable;\
             basis:24:Mat2:export;rot:48:Quat:tweakable;basis3:64:Mat3:export;\\00\""
        ),
        "reflect metadata offsets/type-names should be correct for every mixed field: {}",
        ir
    );
}

/// A struct composed entirely of `BitField<8>`/`Color32`/`PaletteIndex`
/// fields is structurally hashable (`Checker::check_hashable_ty` recurses
/// into `Ty::Named` fields), legal as a `Set<T>` element -- confirms
/// `crate::codegen::eq`'s per-field recursion produces correct field-wise
/// (not padding-byte-including, not pointer-identity) structural equality
/// when every field is one of this round's new scalar types.
#[test]
fn runtime_struct_of_bitfield_color32_paletteindex_as_set_key_dedups_correctly_end_to_end() {
    let src = "struct Tag:\n    \
                   bits: BitField<8>\n    \
                   tint: Color32\n    \
                   idx: PaletteIndex\n\n\
               fn main():\n    \
                   let mut s: Set<Tag> = Set<Tag>()\n    \
                   s.insert(Tag(BitField<8>(1 as u8), Color32(1, 2, 3, 4), PaletteIndex(9)))\n    \
                   s.insert(Tag(BitField<8>(1 as u8), Color32(1, 2, 3, 4), PaletteIndex(9)))\n    \
                   s.insert(Tag(BitField<8>(2 as u8), Color32(1, 2, 3, 4), PaletteIndex(9)))\n    \
                   s.insert(Tag(BitField<8>(1 as u8), Color32(9, 2, 3, 4), PaletteIndex(9)))\n    \
                   println(f\"{s.len()}\")\n";
    let output = compile_and_run("struct_of_new_types_as_set_key", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.trim(), "3", "{}", stdout);
}

/// `Handle<T>`/`GenRef<T>` mutation and the despawn/respawn free-list cycle
/// (round-tripping a stale handle to the element type's zero value, same as
/// `runtime_arena_despawn_respawn_cycle_...`'s existing coverage) for a
/// struct whose fields are `str` plus `Mat3`/`BitField<16>`/`Color32` --
/// confirmed correct across a real free-list reuse cycle (despawn+respawn
/// the same slot 30 times), not just a single spawn.
#[test]
fn runtime_handle_and_genref_despawn_respawn_cycle_with_mat3_bitfield_color32_end_to_end() {
    let src = "struct Widget:\n    \
                   name: str\n    \
                   mut xf: Mat3\n    \
                   mut flags: BitField<16>\n    \
                   mut tint: Color32\n\n\
               arena Widgets: Widget\n\n\
               fn main():\n    \
                   for i in 0..20:\n        \
                       let m = Mat3(Vec3(1.0, 0.0, 0.0), Vec3(0.0, 1.0, 0.0), Vec3(0.0, 0.0, (i as float)))\n        \
                       spawn Widgets(f\"w{i}\", m, BitField<16>(i as u16), Color32(i, 0, 0, 255))\n    \
                   let handle = Handle<Widget>(5)\n    \
                   let before = handle[0]\n    \
                   println(f\"{before.name},{before.flags}\")\n    \
                   despawn Widgets[5]\n    \
                   let after = handle[0]\n    \
                   println(f\"{after.name},{after.flags}\")\n    \
                   let gr = GenRef<Widget>(19)\n    \
                   gr[0].flags = bit_set(gr[0].flags, 3)\n    \
                   println(f\"{gr[0].name},{gr[0].flags}\")\n    \
                   for cycle in 0..30:\n        \
                       despawn Widgets[10]\n        \
                       spawn Widgets(f\"cyc{cycle}\", Mat3(Vec3(1.0, 0.0, 0.0), Vec3(0.0, 1.0, 0.0), Vec3(0.0, 0.0, (cycle as float))), \
                       BitField<16>(cycle as u16), Color32(1, 1, 1, 1))\n    \
                   let last = GenRef<Widget>(10)\n    \
                   println(f\"{last[0].name},{last[0].flags}\")\n";
    let output = compile_and_run("handle_genref_despawn_respawn_mat3_bitfield_color32", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(lines, vec!["w5,5", "(null),0", "w19,27", "cyc29,29"], "{}", stdout);
}

//! M6 SIMD vector/matrix math types
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== M6 SIMD Math Type Tests ============================================

#[test]
fn checks_vec_add_same_type() {
    let ty = typed_fn_result_ty("fn t(a: Vec3, b: Vec3) -> Vec3:\n    a + b\n");
    assert_eq!(ty, Ty::Vec3);
}

#[test]
fn checks_vec_scalar_mul_both_orders() {
    assert_eq!(typed_fn_result_ty("fn t(a: Vec3) -> Vec3:\n    a * 2.0\n"), Ty::Vec3);
    assert_eq!(typed_fn_result_ty("fn t(a: Vec3) -> Vec3:\n    2.0 * a\n"), Ty::Vec3);
}

#[test]
fn checks_mat4_vec4_mul() {
    let ty = typed_fn_result_ty("fn t(m: Mat4, v: Vec4) -> Vec4:\n    m * v\n");
    assert_eq!(ty, Ty::Vec4);
}

#[test]
fn checks_mat4_mat4_mul() {
    let ty = typed_fn_result_ty("fn t(a: Mat4, b: Mat4) -> Mat4:\n    a * b\n");
    assert_eq!(ty, Ty::Mat4);
}

#[test]
fn checks_swizzle_read_types() {
    assert_eq!(typed_fn_result_ty("fn t(v: Vec3) -> Vec3:\n    v.xyz\n"), Ty::Vec3);
    assert_eq!(typed_fn_result_ty("fn t(v: Vec3) -> Vec2:\n    v.xy\n"), Ty::Vec2);
    assert_eq!(typed_fn_result_ty("fn t(v: Vec3) -> f32:\n    v.x\n"), Ty::Float);
    assert_eq!(typed_fn_result_ty("fn t(v: Vec3) -> Vec3:\n    v.zyx\n"), Ty::Vec3);
    assert_eq!(typed_fn_result_ty("fn t(v: Vec3) -> Vec2:\n    v.xx\n"), Ty::Vec2);
}

#[test]
fn rejects_mismatched_vec_arity() {
    let module = Driver::parse("fn t(a: Vec2, b: Vec3):\n    a + b\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "mismatched vector arity should be a type error");
}

#[test]
fn rejects_invalid_swizzle_component() {
    let module = Driver::parse("fn t(v: Vec3):\n    v.q\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "invalid swizzle component should be a type error");
}

#[test]
fn rejects_swizzle_out_of_range() {
    let module = Driver::parse("fn t(v: Vec2):\n    v.z\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "swizzle component out of range should be a type error");
}

#[test]
fn rejects_vec_comparison() {
    let module = Driver::parse("fn t(a: Vec3, b: Vec3):\n    a == b\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "comparing vectors should be a type error");
}

#[test]
fn rejects_duplicate_swizzle_write_target() {
    let module = Driver::parse("fn t(mut v: Vec3):\n    v.xx = v.xy\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "duplicate swizzle write target should be a type error");
}

#[test]
fn rejects_wrong_ctor_arity() {
    let module = Driver::parse("fn t():\n    Vec3(1.0, 2.0)\n").expect("should parse");
    assert!(Driver::check(&module).is_err(), "wrong constructor arity should be a type error");
}

#[test]
fn codegen_float_binop_uses_fadd() {
    let module = Driver::parse("fn t(a: f32, b: f32) -> f32:\n    a + b\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("fadd float"), "float addition should emit fadd, not add i32: {}", ir);
}

#[test]
fn codegen_vec2_add_uses_vector_fadd() {
    let module = Driver::parse("fn t(a: Vec2, b: Vec2) -> Vec2:\n    a + b\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("fadd <2 x float>"), "{}", ir);
}

#[test]
fn codegen_vec3_add_uses_vector_fadd() {
    let module = Driver::parse("fn t(a: Vec3, b: Vec3) -> Vec3:\n    a + b\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("fadd <3 x float>"), "{}", ir);
}

#[test]
fn codegen_vec4_add_uses_vector_fadd() {
    let module = Driver::parse("fn t(a: Vec4, b: Vec4) -> Vec4:\n    a + b\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("fadd <4 x float>"), "{}", ir);
}

#[test]
fn codegen_vec2_scalar_mul_uses_vector_fmul() {
    let module = Driver::parse("fn t(a: Vec2) -> Vec2:\n    a * 2.0\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("fmul <2 x float>"), "{}", ir);
}

#[test]
fn codegen_vec3_scalar_mul_uses_vector_fmul() {
    let module = Driver::parse("fn t(a: Vec3) -> Vec3:\n    2.0 * a\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("fmul <3 x float>"), "{}", ir);
}

#[test]
fn codegen_vec2_multi_swizzle_read_uses_shufflevector() {
    let module = Driver::parse("fn t(v: Vec2) -> Vec2:\n    v.yx\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("shufflevector <2 x float>"), "{}", ir);
}

#[test]
fn codegen_vec3_multi_swizzle_read_uses_shufflevector() {
    let module = Driver::parse("fn t(v: Vec3) -> Vec3:\n    v.zyx\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("shufflevector <3 x float>"), "{}", ir);
}

#[test]
fn codegen_vec4_multi_swizzle_read_uses_shufflevector() {
    let module = Driver::parse("fn t(v: Vec4) -> Vec3:\n    v.xyz\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("shufflevector <4 x float>"), "{}", ir);
}

#[test]
fn codegen_vec2_single_swizzle_uses_extractelement() {
    let module = Driver::parse("fn t(v: Vec2) -> f32:\n    v.x\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("extractelement <2 x float>"), "{}", ir);
}

#[test]
fn codegen_vec4_single_swizzle_uses_extractelement() {
    let module = Driver::parse("fn t(v: Vec4) -> f32:\n    v.x\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("extractelement <4 x float>"), "{}", ir);
}

#[test]
fn codegen_vec2_swizzle_write_uses_insertelement_store() {
    let module = Driver::parse("fn t(mut v: Vec2):\n    v.x = 1.0\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("insertelement <2 x float>"), "{}", ir);
    assert!(ir.contains("store <2 x float>"), "{}", ir);
}

#[test]
fn codegen_vec3_swizzle_write_uses_insertelement_store() {
    let module = Driver::parse("fn t(mut v: Vec3):\n    v.y = 1.0\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("insertelement <3 x float>"), "{}", ir);
    assert!(ir.contains("store <3 x float>"), "{}", ir);
}

#[test]
fn codegen_vec4_swizzle_write_uses_insertelement_store() {
    let module = Driver::parse("fn t(mut v: Vec4):\n    v.x = 1.0\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("insertelement <4 x float>"), "{}", ir);
    assert!(ir.contains("store <4 x float>"), "{}", ir);
}

#[test]
fn codegen_mat4_vec4_mul_uses_dot_pattern() {
    let module = Driver::parse("fn t(m: Mat4, v: Vec4) -> Vec4:\n    m * v\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("fmul <4 x float>"), "{}", ir);
    assert!(ir.contains("extractelement"), "{}", ir);
    let row_extracts = ir.matches("extractvalue [4 x <4 x float>]").count();
    assert_eq!(row_extracts, 4, "should extract exactly the 4 matrix rows: {}", ir);
}

#[test]
fn codegen_vec2_ctor_uses_insertelement_no_alloca() {
    let module = Driver::parse("fn t() -> Vec2:\n    Vec2(1.0, 2.0)\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("insertelement <2 x float> undef"), "{}", ir);
    assert!(!ir.contains("alloca <2 x float>"), "{}", ir);
}

#[test]
fn codegen_vec3_ctor_uses_insertelement_no_alloca() {
    let module = Driver::parse("fn t() -> Vec3:\n    Vec3(1.0, 2.0, 3.0)\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("insertelement <3 x float> undef"), "{}", ir);
    assert!(!ir.contains("alloca <3 x float>"), "{}", ir);
}

#[test]
fn codegen_vec4_ctor_uses_insertelement_no_alloca() {
    let module = Driver::parse("fn t() -> Vec4:\n    Vec4(1.0, 2.0, 3.0, 4.0)\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("insertelement <4 x float> undef"), "{}", ir);
    assert!(!ir.contains("alloca <4 x float>"), "{}", ir);
}

#[test]
fn codegen_compound_assign_vec2_uses_vector_fadd() {
    let module = Driver::parse("fn t(mut v: Vec2, o: Vec2):\n    v += o\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("fadd <2 x float>"), "{}", ir);
}

#[test]
fn codegen_compound_assign_vec3_uses_vector_fadd() {
    let module = Driver::parse("fn t(mut v: Vec3, o: Vec3):\n    v += o\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("fadd <3 x float>"), "{}", ir);
}

#[test]
fn codegen_vec2_dot_uses_vector_fmul_and_extractelement() {
    let module = Driver::parse("fn t(a: Vec2, b: Vec2) -> f32:\n    dot(a, b)\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("fmul <2 x float>"), "{}", ir);
    assert!(ir.contains("extractelement <2 x float>"), "{}", ir);
}

#[test]
fn codegen_vec2_length_uses_sqrt() {
    let module = Driver::parse("fn t(a: Vec2) -> f32:\n    length(a)\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("call float @llvm.sqrt.f32"), "{}", ir);
    assert!(ir.contains("fmul <2 x float>"), "{}", ir);
}

#[test]
fn codegen_vec2_lerp_uses_extractelement_insertelement() {
    let module = Driver::parse("fn t(a: Vec2, b: Vec2, t: f32) -> Vec2:\n    lerp(a, b, t)\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("extractelement <2 x float>"), "{}", ir);
    assert!(ir.contains("insertelement <2 x float>"), "{}", ir);
    assert!(!ir.contains("extractvalue"), "{}", ir);
}

#[test]
fn codegen_struct_field_of_vec2_type_uses_native_vector() {
    let src = "struct Marker:\n    pos: Vec2\n    id: i32\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("%Marker = type"), "{}", ir);
    assert!(ir.contains("<2 x float>"), "{}", ir);
    assert!(!ir.contains("{ float, float }"), "{}", ir);
}

#[test]
fn codegen_list_of_vec2_uses_native_vector_element() {
    // `List<Vec2>()` alone is just `null` -- no allocation, so no
    // element-typed payload struct is ever spelled out. A literal forces
    // the payload/release-thunk machinery to actually mention the element
    // type.
    let module = Driver::parse("fn t() -> List<Vec2>:\n    [Vec2(1.0, 2.0)]\n").expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("<2 x float>"), "{}", ir);
}

#[test]
fn codegen_arena_of_vec3_uses_native_vector() {
    let src = "arena Particles: Vec3\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("<3 x float>"), "{}", ir);
}

#[test]
fn codegen_closure_capturing_vec2_local_uses_native_vector() {
    let module = Driver::parse(
        "fn t() -> f32:\n    let p = Vec2(1.0, 2.0)\n    let f = fn() -> f32: p.x + p.y\n    f()\n"
    ).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(ir.contains("<2 x float>"), "{}", ir);
}

/// Runtime test: compiled `vecmath.exe` exercises vec3/vec4 arithmetic,
/// scalar multiply, swizzle reads (including reordering), Mat4*Vec4, and
/// both single- and multi-component swizzle writes, end to end through a
/// real clang-compiled executable.
#[test]
fn runtime_vecmath_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/vecmath.exe")
        .output()
        .expect("failed to execute vecmath.exe");

    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("sum: 11.000000 22.000000 33.000000"), "vec3 add result: {}", stdout);
    assert!(stdout.contains("scaled: 2.000000 4.000000 6.000000"), "vec3 scalar mul result: {}", stdout);
    assert!(stdout.contains("vec4 sum: 1.000000 1.000000 0.000000 0.000000"), "vec4 add result: {}", stdout);
    assert!(stdout.contains("swizzled: 33.000000 22.000000 11.000000"), "swizzle reorder result: {}", stdout);
    assert!(stdout.contains("mat4*vec4 identity: 1.000000 0.000000 0.000000 0.000000"), "identity matrix result: {}", stdout);
    assert!(stdout.contains("vec4 single write: 99.000000 1.000000"), "vec4 lane write result: {}", stdout);
    assert!(stdout.contains("vec2 multi write: 5.000000 6.000000"), "vec2 multi-swizzle write result: {}", stdout);
}

/// Runtime test: `examples/mat4_transform.exe` exercises non-identity Mat4
/// math (`runtime_vecmath_end_to_end`'s `Mat4*Vec4` case only ever multiplies
/// by the identity, which can't distinguish a correct row-major
/// matrix-vector multiply from several plausible-looking bugs -- a
/// transposed row/column read, swapped dot-product operand order, off-by-one
/// row indexing -- since every one of those still hands the identity's own
/// input right back unchanged). Uses a real scale+translate matrix instead,
/// checks `Mat4*Mat4` self-composition against applying the transform twice
/// by hand, and covers a zero vector's `length`/`dot` (`length(v) ==
/// sqrt(dot(v,v))`, so a zero vector must produce `0.0`, not a NaN from
/// dividing by a zero length -- there is no `normalize` builtin in this
/// compiler to trip that specific division, but `length`/`dot` themselves
/// must still be well-defined at the origin).
#[test]
fn runtime_mat4_nontrivial_transform_end_to_end() {
    use std::process::Command;

    let output = Command::new("examples/mat4_transform.exe")
        .output()
        .expect("failed to execute mat4_transform.exe");

    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("zero length: 0.000000"), "zero-vector length: {}", stdout);
    assert!(stdout.contains("zero dot: 0.000000"), "zero-vector dot: {}", stdout);
    assert!(stdout.contains("m*v = 12.000000 23.000000 34.000000 1.000000"), "scale+translate mat4*vec4: {}", stdout);
    assert!(stdout.contains("m2*v = 34.000000 89.000000 166.000000 1.000000"), "mat4*mat4 self-composition: {}", stdout);
    assert!(stdout.contains("dot(a,b) = 32.000000"), "vec3 dot product: {}", stdout);
    assert!(stdout.contains("length(3,4) = 5.000000"), "3-4-5 triangle length: {}", stdout);
    assert!(output.status.success(), "{:?}", output.status);
}

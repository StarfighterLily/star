# M6 SIMD math types demonstration: vec2/vec3/vec4/mat4 arithmetic and
# GLSL-style swizzling. Uses a fresh file (not player.star) to avoid the
# unrelated naming collision between player.star's own `struct Vec3` and the
# builtin Vec3 type.

fn main():
    let a = Vec3(1.0, 2.0, 3.0)
    let b = Vec3(10.0, 20.0, 30.0)
    let c = a + b
    print(f"sum: {c.x} {c.y} {c.z}")

    let scaled = a * 2.0
    print(f"scaled: {scaled.x} {scaled.y} {scaled.z}")

    let v4a = Vec4(1.0, 0.0, 0.0, 0.0)
    let v4b = Vec4(0.0, 1.0, 0.0, 0.0)
    let v4c = v4a + v4b
    print(f"vec4 sum: {v4c.x} {v4c.y} {v4c.z} {v4c.w}")

    let swizzled = c.zyx
    print(f"swizzled: {swizzled.x} {swizzled.y} {swizzled.z}")

    let identity = Mat4(
        Vec4(1.0, 0.0, 0.0, 0.0),
        Vec4(0.0, 1.0, 0.0, 0.0),
        Vec4(0.0, 0.0, 1.0, 0.0),
        Vec4(0.0, 0.0, 0.0, 1.0),
    )
    let transformed = identity * v4a
    print(f"mat4*vec4 identity: {transformed.x} {transformed.y} {transformed.z} {transformed.w}")

    let mut w = Vec4(1.0, 1.0, 1.0, 1.0)
    w.x = 99.0
    print(f"vec4 single write: {w.x} {w.y}")

    let mut m = Vec2(1.0, 1.0)
    m.xy = Vec2(5.0, 6.0)
    print(f"vec2 multi write: {m.x} {m.y}")

# Regression coverage for non-identity Mat4 math: `examples/vecmath.star`
# only ever multiplies by the identity matrix, which can't distinguish a
# correct row-major matrix-vector multiply from several plausible-looking
# bugs (transposed row/column reads, wrong dot-product operand order,
# off-by-one row indexing) since every one of those still produces the
# identity's own input right back. This file uses a real scale+translate
# matrix instead, with every expected value hand-computed in the comments,
# plus a zero-vector `length`/`dot` (no divide-by-zero from an unwritten
# `normalize`) and a `dot` of two arbitrary Vec3s.

fn main():
    # Zero vector: length == sqrt(dot(v,v)) == sqrt(0) == 0, no NaN/inf.
    let z = Vec3(0.0, 0.0, 0.0)
    println(f"zero length: {length(z)}")
    println(f"zero dot: {dot(z, z)}")

    # Row-major Mat4 scaling by (2,3,4) then translating by (10,20,30).
    let m = Mat4(
        Vec4(2.0, 0.0, 0.0, 10.0),
        Vec4(0.0, 3.0, 0.0, 20.0),
        Vec4(0.0, 0.0, 4.0, 30.0),
        Vec4(0.0, 0.0, 0.0, 1.0),
    )
    let v = Vec4(1.0, 1.0, 1.0, 1.0)
    let r = m * v
    # expected: (2*1+10, 3*1+20, 4*1+30, 1) = (12, 23, 34, 1)
    println(f"m*v = {r.x} {r.y} {r.z} {r.w}")

    # Mat4 * Mat4 self-composition, then applied to v -- equivalent to
    # applying m twice: m*(m*v) = m*(12,23,34,1) = (2*12+10, 3*23+20,
    # 4*34+30, 1) = (34, 89, 166, 1).
    let m2 = m * m
    let r2 = m2 * v
    println(f"m2*v = {r2.x} {r2.y} {r2.z} {r2.w}")

    # dot(a,b) of two arbitrary Vec3s: 1*4 + 2*5 + 3*6 = 32.
    let a = Vec3(1.0, 2.0, 3.0)
    let b = Vec3(4.0, 5.0, 6.0)
    println(f"dot(a,b) = {dot(a, b)}")

    # A 3-4-5 right triangle: length == 5 exactly.
    println(f"length(3,4) = {length(Vec2(3.0, 4.0))}")

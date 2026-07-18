# Demonstrates docs/design.md's "Math and geometry" section's `Quat`: a
# quaternion rotation, avoiding the gimbal lock a `Vec3` Euler angle would
# suffer.

fn main():
    # The identity rotation leaves a point unchanged.
    let identity = quat_identity()
    let p = quat_rotate(identity, Vec3(1.0, 0.0, 0.0))
    println(f"identity rotate: {p.x}, {p.y}, {p.z}")

    # A 90-degree rotation about +Z: axis (0,0,1), half-angle 45 degrees.
    let q = Quat(0.0, 0.0, 0.70710678, 0.70710678)
    let rotated = quat_rotate(q, Vec3(1.0, 0.0, 0.0))
    println(f"(1,0,0) rotated 90 degrees about Z: {rotated.x}, {rotated.y}, {rotated.z}")

    # Composing two 45-degree rotations (via `*`, the quaternion/Hamilton
    # product) is equivalent to one 90-degree rotation.
    let half = Quat(0.0, 0.0, 0.38268343, 0.92387953)
    let composed = half * half
    let rotated_composed = quat_rotate(composed, Vec3(1.0, 0.0, 0.0))
    println(f"composed rotate: {rotated_composed.x}, {rotated_composed.y}, {rotated_composed.z}")

    # `quat_conjugate` inverts a unit rotation.
    let undone = quat_rotate(quat_conjugate(q), rotated)
    println(f"undone rotate: {undone.x}, {undone.y}, {undone.z}")

    # `quat_normalize` rescales an unnormalized quaternion back to unit length.
    let n = quat_normalize(Quat(0.0, 0.0, 0.0, 2.0))
    println(f"normalized w: {n.w}")

    # `Quat` reuses `Vec4`'s field access/`+`/`-`/scalar `*`/`/` for free --
    # only `*` between two `Quat`s is special-cased to the true quaternion
    # product rather than a componentwise multiply.
    let sum = q + identity
    println(f"componentwise sum w: {sum.w}")

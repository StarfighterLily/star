# Demonstrates docs/design.md's "Math and geometry" section's `Mat2`/`Mat3`:
# small fixed matrices extending `Vec2`/`Vec3`'s existing `Mat4` sibling to
# the two other common dimensions (2D transforms, 3D rotation/basis
# matrices).

fn main():
    let scale2 = Mat2(Vec2(2.0, 0.0), Vec2(0.0, 3.0))
    let scaled = scale2 * Vec2(1.0, 1.0)
    println(f"Mat2 scale: {scaled.x}, {scaled.y}")

    let identity2 = Mat2(Vec2(1.0, 0.0), Vec2(0.0, 1.0))
    let product2 = scale2 * identity2
    let via_product = product2 * Vec2(1.0, 1.0)
    println(f"Mat2 * identity: {via_product.x}, {via_product.y}")

    let sum2 = scale2 + identity2
    let via_sum = sum2 * Vec2(1.0, 0.0)
    println(f"Mat2 sum row0.x: {via_sum.x}")

    let identity3 = Mat3(Vec3(1.0, 0.0, 0.0), Vec3(0.0, 1.0, 0.0), Vec3(0.0, 0.0, 1.0))
    let v3 = identity3 * Vec3(5.0, 6.0, 7.0)
    println(f"Mat3 identity: {v3.x}, {v3.y}, {v3.z}")

    let swap_xy = Mat3(Vec3(0.0, 1.0, 0.0), Vec3(1.0, 0.0, 0.0), Vec3(0.0, 0.0, 1.0))
    let swapped = swap_xy * Vec3(1.0, 2.0, 3.0)
    println(f"Mat3 swap xy: {swapped.x}, {swapped.y}, {swapped.z}")

# Demonstrates docs/design.md's "Math and geometry" section's builtin
# geometry structs: `Rect`/`Aabb2`/`Aabb3`/`Ray`/`Plane`/`Frustum`/
# `Transform`. Each is an ordinary nominal struct (named-argument
# construction, field access, all pre-registered by the compiler -- see
# `crate::types::builtin_structs`), so only their characteristic operations
# need a dedicated free function.

fn main():
    let r = Rect(x = 0.0, y = 0.0, width = 10.0, height = 10.0)
    println(f"rect contains inside point: {rect_contains(r, Vec2(5.0, 5.0))}")
    println(f"rect contains outside point: {rect_contains(r, Vec2(50.0, 5.0))}")

    let overlapping = Rect(x = 5.0, y = 5.0, width = 10.0, height = 10.0)
    let far_away = Rect(x = 100.0, y = 100.0, width = 10.0, height = 10.0)
    println(f"rect intersects overlapping: {rect_intersects(r, overlapping)}")
    println(f"rect intersects far away: {rect_intersects(r, far_away)}")

    let box2 = Aabb2(min = Vec2(0.0, 0.0), max = Vec2(10.0, 10.0))
    println(f"aabb2 contains: {aabb2_contains(box2, Vec2(1.0, 1.0))}")
    let box2b = Aabb2(min = Vec2(5.0, 5.0), max = Vec2(15.0, 15.0))
    println(f"aabb2 intersects: {aabb2_intersects(box2, box2b)}")

    let box3 = Aabb3(min = Vec3(0.0, 0.0, 0.0), max = Vec3(10.0, 10.0, 10.0))
    println(f"aabb3 contains: {aabb3_contains(box3, Vec3(1.0, 1.0, 1.0))}")
    let box3b = Aabb3(min = Vec3(20.0, 20.0, 20.0), max = Vec3(30.0, 30.0, 30.0))
    println(f"aabb3 intersects far away: {aabb3_intersects(box3, box3b)}")

    let ray = Ray(origin = Vec3(0.0, 0.0, 0.0), direction = Vec3(1.0, 0.0, 0.0))
    let along_ray = ray_at(ray, 5.0)
    println(f"ray at t=5: {along_ray.x}, {along_ray.y}, {along_ray.z}")

    let ground = Plane(normal = Vec3(0.0, 1.0, 0.0), distance = 0.0)
    println(f"height above ground: {plane_distance_to_point(ground, Vec3(0.0, 3.0, 0.0))}")

    # A degenerate "frustum" of six copies of the same ground plane, purely
    # to exercise `frustum_contains_point` end to end.
    let planes: [Plane; 6] = [ground; 6]
    let frustum = Frustum(planes)
    println(f"frustum contains above ground: {frustum_contains_point(frustum, Vec3(0.0, 1.0, 0.0))}")
    println(f"frustum excludes below ground: {frustum_contains_point(frustum, Vec3(0.0, -1.0, 0.0))}")

    let t = Transform(position = Vec3(1.0, 0.0, 0.0), rotation = quat_identity(), scale = Vec3(2.0, 2.0, 2.0))
    let world_point = transform_apply_point(t, Vec3(1.0, 0.0, 0.0))
    println(f"transformed point: {world_point.x}, {world_point.y}, {world_point.z}")

# Regression check for GenRef liveness (LANGUAGE_ANALYSIS.md §3.3):
# dereferencing a GenRef against a slot that was *never* spawned into must
# fall back to the element type's zero value -- never a segfault or
# uninitialized garbage -- matching the documented "safe null equivalent"
# guarantee for every dead/never-live slot, not just despawned-after-spawn.
struct Point:
    x: i32
    y: i32

arena Entities: Point

fn main():
    let never_touched_arena = GenRef<Point>(0)
    let a = never_touched_arena[0]
    print(f"before any spawn: x={a.x} y={a.y}")

    spawn Entities(999, 999)
    let other_slot_never_spawned = GenRef<Point>(5)
    let b = other_slot_never_spawned[0]
    print(f"other slot live, this slot never spawned: x={b.x} y={b.y}")

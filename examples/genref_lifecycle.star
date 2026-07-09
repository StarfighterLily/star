# Demonstrates the generational-reference safety guarantee end to end:
# a GenRef dereferenced after its slot is despawned falls back to the
# element type's zero value instead of returning stale data or crashing.

struct Entity:
    hp: i32

arena Entities: Entity

fn main():
    spawn Entities(100)
    let r = GenRef<Entity>(0)
    let before = r[0]
    print(f"before: {before.hp}")
    despawn Entities[0]
    let after = r[0]
    print(f"after: {after.hp}")

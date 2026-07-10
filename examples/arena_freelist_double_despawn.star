# Regression check: despawning an already-dead slot must be a no-op, not a
# second push onto the free-list. If it pushed twice, two later spawns would
# both pop the same slot and alias each other's memory instead of one
# spawn reusing the freed slot and the next growing the arena.

struct Entity:
    hp: i32

arena Entities: Entity

fn main():
    spawn Entities(100)
    despawn Entities[0]
    despawn Entities[0]
    spawn Entities(200)
    spawn Entities(300)
    let r0 = GenRef<Entity>(0)
    let r1 = GenRef<Entity>(1)
    print(f"slot0: {r0[0].hp}")
    print(f"slot1: {r1[0].hp}")

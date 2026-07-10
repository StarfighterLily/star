# Demonstrates the arena free-list: `despawn` reclaims a slot so the next
# `spawn` reuses its memory instead of growing the arena's backing array
# forever, while the generation counter still keeps old references honest
# (no ABA aliasing between the old and new occupant of the slot).

struct Entity:
    hp: i32

arena Entities: Entity

fn main():
    spawn Entities(100)
    let old_ref = GenRef<Entity>(0)
    despawn Entities[0]
    spawn Entities(200)
    let new_ref = GenRef<Entity>(0)
    let via_old = old_ref[0]
    let via_new = new_ref[0]
    print(f"via_old: {via_old.hp}")
    print(f"via_new: {via_new.hp}")

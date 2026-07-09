# Arena population demonstration: `spawn ArenaName(args...)` constructs a
# new element of the arena's declared struct type and appends it to the
# arena's backing array (see `Codegen::emit_spawn_stmt`), so `par`/`swarm`
# (see `examples/swarm.star`) actually have live elements to iterate over.

struct Enemy:
    mut hp: i32

arena Enemies: Enemy

fn main():
    spawn Enemies(10)
    spawn Enemies(20)
    spawn Enemies(30)
    par e in Enemies:
        e.hp -= 1
    swarm e in Enemies:
        print(f"hp: {e.hp}")

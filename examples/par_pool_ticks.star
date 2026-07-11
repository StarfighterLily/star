# Persistent-pool regression demonstration: the *same* 4-worker thread pool
# must correctly serve several sequential `par` dispatch/join cycles, not
# just a single one (see `Codegen::par_pool` / `runtime_par_pool_ticks_
# persists_across_cycles`). A correct single-shot `par` would also pass
# under the old per-call-`CreateThread` design; running 5 ticks and checking
# the cumulative result is what actually proves the pool survives repeated
# dispatch/join cycles without corrupting shared state or hanging.

struct Enemy:
    mut hp: i32

arena Enemies: Enemy

fn main():
    spawn Enemies(100)
    spawn Enemies(100)
    spawn Enemies(100)
    for tick in 0..5:
        par e in Enemies:
            e.hp -= 1
    swarm e in Enemies:
        print(f"hp: {e.hp}")

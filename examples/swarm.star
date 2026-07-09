# M7 parallel-iteration demonstration: `par`/`swarm` dispatches loop
# iterations across a fixed pool of OS worker threads (see
# `Codegen::emit_par_stmt`), after the checker proves the body only mutates
# the loop variable's own fields (so the iterations are provably disjoint
# and safe to run concurrently).
#
# `Enemies` below is empty at runtime (nothing `spawn`s into it), so this
# example only exercises the threading machinery itself: genuine
# `CreateThread`/`WaitForSingleObject`/`CloseHandle` calls compiled and
# linked into a native binary that runs to completion over zero elements.
# See `examples/spawn.star` for `spawn`-populated `par`/`swarm` iteration
# over real live elements.

struct Enemy:
    mut hp: i32

arena Enemies: Enemy

fn main():
    par e in Enemies:
        e.hp -= 1
    swarm e in Enemies:
        e.hp = 0
    print(f"swarm done")

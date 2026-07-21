# Demonstrates conditionally reclaiming arena slots during a scan -- the gap
# `projects/snake/NOTES.md` section 2.1 flagged as impossible: `despawn` is
# (still, necessarily) banned inside `par`/`swarm` since concurrent
# generation bumps aren't disjoint across worker threads, and those were
# previously the *only* way to iterate an arena's contents at all. `each
# item, idx in ArenaName:` closes it: `despawn` was never actually banned
# inside `each` (it runs sequentially, on the calling thread, same as any
# other statement in the loop body) -- there was just no bound name for the
# slot to reclaim. `idx` gives the body exactly that.
struct Particle:
    mut hp: i32
    mut dead: bool

arena Particles: Particle

fn main():
    spawn Particles(1, false)
    spawn Particles(2, false)
    spawn Particles(3, false)
    spawn Particles(4, false)

    # Mark two entities dead (an expired timer, an enemy that hit zero HP --
    # any per-entity runtime condition).
    each p, i in Particles:
        if p.hp == 2 or p.hp == 4:
            p.dead = true

    # The pattern 2.1 said couldn't be written: scan every live entity,
    # despawn the ones matching a runtime condition.
    each p, i in Particles:
        if p.dead:
            despawn Particles[i]

    print("after reclaiming dead slots:")
    each p, i in Particles:
        print(f"  slot {i}: hp={p.hp}")

    # A later spawn reuses a freed slot off the arena's free-list, exactly
    # like arena_freelist.star's explicit `despawn`/`spawn` pair.
    spawn Particles(99, false)
    print("after respawn:")
    each p, i in Particles:
        print(f"  slot {i}: hp={p.hp}")

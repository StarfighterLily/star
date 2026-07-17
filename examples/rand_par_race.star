# Regression test for an RNG-state thread-safety bug: `rand`/`rand_range`
# (`crate::codegen::vector_math::emit_rand_next`) advance a single
# process-wide xorshift32 generator (`@rng.state`) via a plain
# load-xorshift-store sequence -- and, unlike `spawn`/`despawn`/`frame:`,
# calling `rand_range(..)` inside a `par`/`swarm` body is *not* rejected by
# the checker's disjointness proof (`types::par_analysis`), since nothing
# about the analysis knows `@rng.state` is shared global state. Every
# `par`/`swarm` dispatch genuinely runs the body on 4 concurrent OS worker
# threads (`crate::codegen::par_pool`), so two threads both loading
# `@rng.state` before either stores back compute and store the *identical*
# next value -- a lost-update race. A plain aligned `i32` load/store can't
# itself tear the way `Symbol`'s table's `malloc`/`memcpy`/`free` grow path
# can, so this doesn't crash the heap -- instead it silently produces
# statistically impossible duplicate "random" draws within the same tick
# (with a 32-bit generator and only 64 draws per tick, a natural collision by
# chance alone is a ~0.0000149 probability; this reproduced dozens of
# collisions per affected tick, in roughly 5-15% of ticks, 5/5 runs, before
# the fix). Fixed by adding `@rng.lock` (a binary semaphore created once in
# `main`'s prologue, before any `par`/`swarm` dispatch can possibly spin up
# the worker pool) guarding every `rand`/`rand_range`/`rand_seed` access to
# `@rng.state`, mirroring `@sym.lock`'s exact shape and rationale.
#
# Each tick draws a fresh `rand_range(..)` value for all 64 entities at
# once, then prints every entity's value (space-suffixed) followed by a
# blank line -- 65 output lines per tick. If the race were still present,
# some tick's block of 64 values would contain duplicates despite each
# entity drawing an independent value from a 32-bit-state generator.

struct Entity:
    mut id: i64

arena Entities: Entity

fn main():
    for i in 0..64:
        spawn Entities(0 as i64)
    for tick in 0..200:
        par e in Entities:
            e.id = rand_range(0, 2000000000) as i64
        swarm e in Entities:
            print(f"{e.id} ")
        println("")

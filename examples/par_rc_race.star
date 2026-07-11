# Regression test for the RC retain/release atomicity fix: `star_rc_retain`/
# `star_rc_release` used to do a plain (non-atomic) load-add/sub-store on the
# shared 16-byte allocation header, but `par`/`swarm` genuinely dispatches
# the same generated worker body across 4 concurrent OS threads (see
# `crate::codegen::par_pool`), and the disjointness proof only restricts
# *writes* to captured state, not reads -- so a captured `Str` merely *read*
# inside a `par` body retains/releases the same header from multiple threads
# at once with no synchronization, a classic lost-update race that can free
# a still-referenced block early (use-after-free) or leak it.
#
# This can't deterministically prove the race is gone (a lost-update race is
# inherently timing-dependent), but running many ticks across several arena
# entries multiplies the number of chances to hit the lost-update window per
# run, the same stress-testing approach `rc_stress.star` uses for leaks. If
# the captured `tag` were freed early, the final `println(tag)` after the
# loop would read freed memory -- typically a crash or garbled output, not a
# quiet pass.

struct Enemy:
    mut hp: i32

arena Enemies: Enemy

fn main():
    let tag = concat("swarm-", "tag")
    for i in 0..16:
        spawn Enemies(100)
    for tick in 0..400:
        par e in Enemies:
            e.hp -= 1
            print(tag)
    println(f"final: {tag}")

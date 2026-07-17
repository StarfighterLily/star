# Regression test for a `Symbol` intern-table thread-safety fix: `Symbol(s)`
# (`crate::codegen::symbol::emit_symbol_intern`) mutates the process-wide
# intern table (`@sym.data`/`@sym.len`/`@sym.cap`) via a plain, unsynchronized
# scan-then-insert-with-doubling sequence -- and unlike `spawn`/`despawn`/
# `frame:`, calling `Symbol(..)` inside a `par`/`swarm` body is *not* banned
# by the checker's disjointness proof (`types::par_analysis`), since nothing
# about the analysis knows the intern table is shared global state. Every
# `par`/`swarm` dispatch genuinely runs the body on 4 concurrent OS worker
# threads (`crate::codegen::par_pool`), so every worker interning the same
# growing set of strings each tick raced for real on the table's grow path
# (`malloc`/`memcpy`/`free` against `@sym.data`) and its length counter --
# confirmed via a real, reliably reproducing `STATUS_HEAP_CORRUPTION`
# (`0xC0000374`) crash, 5/5 runs, before the fix added `@sym.lock` (a binary
# semaphore created once in `main`'s prologue, before any `par`/`swarm`
# dispatch can possibly spin up the worker pool) guarding every
# `Symbol(..)`/`symbol_name(..)` table access.
#
# Each tick interns a tick-unique string identically from all 64 entities at
# once (forcing real concurrent contention on both the linear scan and the
# grow path every single tick, not just once), then stores the resulting id
# on the entity itself (the only per-iteration mutation allowed). If the race
# were still present this would either crash outright or let some entities
# in the same tick land on a different id than their tick-mates despite
# interning the exact same string.

struct Entity:
    mut id: i64

arena Entities: Entity

fn main():
    for i in 0..64:
        spawn Entities(0 as i64)
    for tick in 0..200:
        let tag = f"tag{tick}"
        par e in Entities:
            e.id = Symbol(tag) as i64
    swarm e in Entities:
        print(f"{e.id}")
    # Re-intern the very last tick's tag from the single (now non-`par`)
    # main thread -- if the table were corrupted this call could itself
    # crash, or return an id inconsistent with what every entity already
    # observed for that same string.
    let check = Symbol(f"tag{199}") as i64
    print(f"check = {check}")

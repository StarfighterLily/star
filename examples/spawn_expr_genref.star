# Demonstrates `spawn` as an expression -- the gap `projects/snake/NOTES.md`
# section 2.2 flagged: the old `spawn ArenaName(...)` statement form has no
# return value, so there was no way to get a handle to the entity a call
# *just* created -- only to a slot whose index you already knew
# independently (in practice, always slot 0, right after an arena's
# first-ever spawn, as arena_freelist.star's own example does).
#
# `let name = spawn ArenaName(args...)` closes that: it evaluates to the raw
# `i32` index the spawn actually landed in, ready to feed straight into
# `GenRef<T>(idx)` for a live handle -- no more only-ever-knowing-slot-0.
struct Enemy:
    mut hp: i32

# A small, explicit capacity (see `arena Name: Type = N`) so the overflow
# case below is reachable without padding this example with filler spawns.
arena Enemies: Enemy = 3

fn main():
    spawn Enemies(1)
    # The entity this whole example cares about isn't the first or the
    # last spawned -- exactly the case the old fire-and-forget `spawn`
    # couldn't name at all.
    let target = spawn Enemies(50)
    spawn Enemies(3)

    let handle = GenRef<Enemy>(target)
    handle[0].hp -= 5

    # An independently-built second `GenRef` to the same reported index
    # reads the mutation back -- proving `target` really does name the
    # live slot those constructor arguments landed in.
    let check = GenRef<Enemy>(target)
    print(f"spawned at slot {target}, hp={check[0].hp}")

    # Past-capacity spawns still can't be trusted with a real handle -- the
    # expression form reports `-1` instead (the same safe-sentinel
    # convention as GenRef's own stale/out-of-bounds reads), never a
    # garbage index. The arena above is already full (capacity 3, 3 live
    # elements), so this next spawn is the one that gets dropped.
    let dropped = spawn Enemies(999)
    print(f"spawn into a full arena reports: {dropped}")

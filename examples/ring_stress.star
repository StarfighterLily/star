# Stress test for `Ring<T,N>`'s RC-safe eviction path (see
# `crate::codegen::ring`'s module doc comment): 200,000 pushes of a fresh
# `str` into a capacity-4 ring, forcing 199,996 evictions -- each one
# exercises `RingMethod::Push`'s "full" branch (`emit_release_at` on the
# slot about to be overwritten, right before the new value is written in).
# A release/retain imbalance on that path would either leak unboundedly or
# double-free and crash well before the loop finishes; see
# `runtime_ring_stress_end_to_end` in tests/frontend.rs.
fn main():
    let mut r: Ring<str, 4> = Ring<str, 4>()
    let mut i = 0
    while i < 200000:
        r.push(f"item-{i}")
        i += 1
    println(f"len = {r.len()}")
    println(f"r[0] = {r[0]}")
    println(f"r[1] = {r[1]}")
    println(f"r[2] = {r[2]}")
    println(f"r[3] = {r[3]}")

    # A separate, smaller pop-heavy pass -- `let`-bound (so each popped
    # value's own scope-exit release balances its `push`-time retain,
    # mirroring `examples/ring.star`'s existing pop usage rather than
    # discarding a fresh RC value as a bare statement, which this codegen
    # doesn't release -- see this file's `tests/frontend.rs` doc comment for
    # why that's a deliberately separate, pre-existing gap this test doesn't
    # exercise).
    let mut cycler: Ring<str, 3> = Ring<str, 3>()
    let mut j = 0
    while j < 50000:
        cycler.push(f"cycle-{j}")
        if j % 3 == 0:
            let popped = cycler.pop()
            if len(popped) == 0:
                println("unexpected empty pop")
        j += 1
    println(f"cycler len = {cycler.len()}")

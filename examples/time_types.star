# Demonstrates docs/design.md's "Time" section: `Tick` (a simulation-step
# counter), `Duration` (a wall-clock span), and `Instant` (a monotonic
# timestamp). All three lower to a bare i64, but are nominally distinct types
# from `i64` and from each other -- mixing a raw tick count with a raw
# nanosecond count at a call site is exactly the class of bug this section
# exists to catch at compile time instead of at replay/rollback time.

fn main():
    # Tick: advances by a plain i64 step count; the difference between two
    # ticks is itself a plain i64 (how many steps elapsed).
    let start_tick: Tick = Tick(0)
    let mut tick = start_tick
    for i in 0..60:
        tick = tick + (1 as i64)
    println(f"tick after 60 steps = {tick}")
    let elapsed_ticks: i64 = tick - start_tick
    println(f"elapsed ticks = {elapsed_ticks}")

    # Duration: a span of nanoseconds, addable/subtractable with itself.
    let frame_budget: Duration = Duration(16666667 as i64)
    let mut total: Duration = Duration(0 as i64)
    for f in 0..3:
        total = total + frame_budget
    println(f"total duration after 3 frames = {total} ns")
    let remaining: Duration = total - frame_budget
    println(f"remaining after refunding one frame = {remaining} ns")
    println(f"frame_budget < total is {frame_budget < total}")

    # Instant: a monotonic timestamp. Subtracting two instants yields the
    # Duration between them; adding/subtracting a Duration shifts an Instant.
    let t0: Instant = Instant(1000 as i64)
    let t1: Instant = Instant(2500 as i64)
    let gap: Duration = t1 - t0
    println(f"gap between instants = {gap} ns")
    let shifted: Instant = t0 + gap
    println(f"t0 shifted by gap == t1 is {shifted == t1}")
    let rewound: Instant = t1 - gap
    println(f"t1 rewound by gap == t0 is {rewound == t0}")

# M7 coroutine demonstration: `sequence` desugars into a state-holding
# struct plus a `resume(mut self) -> bool` method (see src/sequence.rs). Each
# `yield` suspends until the next tick; params and top-level `let`s are
# hoisted into fields so they survive across `resume()` calls.

sequence Countdown(start: i32):
    let mut n: i32 = start
    print(f"tick: {n}")
    n -= 1
    yield
    print(f"tick: {n}")
    n -= 1
    yield
    print(f"tick: {n}")
    n -= 1
    print(f"liftoff")

fn main():
    let mut c = Countdown(3)
    let mut running = true
    while running:
        running = c.resume()
    print(f"sequence done")

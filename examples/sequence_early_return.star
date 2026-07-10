# Regression check for early `return` inside a `sequence` body
# (LANGUAGE_ANALYSIS.md §3.7): a bare `return` before the sequence's next
# `yield` previously desugared to a `ret void` inside the synthesized
# `resume(mut self) -> bool` method -- invalid LLVM IR caught only by the
# backend with no Star diagnostic. It must now compile and behave as "the
# sequence is complete" (`resume()` returns `false`).
sequence Countdown(start: i32):
    let mut n: i32 = start
    if n < 0:
        return
    yield
    n -= 1
    yield
    n -= 1

fn main():
    let mut c = Countdown(1)
    let mut going = true
    let mut ticks: i32 = 0
    while going:
        going = c.resume()
        ticks += 1
    print(f"ticks: {ticks}")

    let mut aborted = Countdown(-1)
    let done = aborted.resume()
    print(f"early return reports done: {done}")

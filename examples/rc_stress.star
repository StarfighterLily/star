# Stress test proving the todo.md §3.6 leaks are actually bounded, not just
# that the right opcodes appear in the IR: 10,000,000 iterations, each
# creating a fresh `concat` result and a closure capturing it, immediately
# going out of scope. Before the reference-counting fix, every iteration
# permanently leaked both allocations -- run long enough, this would grow
# the process's memory without bound. See `runtime_rc_stress_memory_stays_bounded`
# in tests/frontend.rs, which samples this process's Working Set while it
# runs and asserts it stays flat rather than growing with iteration count.
#
# The per-iteration work is deliberately in its own function, called from
# the loop, rather than inlined directly in the loop body: an unrelated,
# pre-existing codegen characteristic (every local's `alloca` is emitted at
# its statement's position, not hoisted to the function's entry block) means
# a `let` directly inside a large loop can grow the *native* stack per
# iteration in some cases -- a real bug, but a stack-management one, not a
# heap leak, and out of scope here. Routing through a call sidesteps it: a
# called function's own stack frame is fully reclaimed on return regardless.
fn make_stuff(n: i32) -> i32:
    let s = concat("hello-", "world")
    let total = len(s) + n
    let f = fn() -> i32: len(s)
    total + f()

fn main():
    let mut i = 0
    let mut total = 0
    while i < 10000000:
        total += make_stuff(i)
        i += 1
    println(f"done, total = {total}")

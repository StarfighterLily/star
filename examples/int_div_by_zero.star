# Regression check for the integer division/modulo-by-zero runtime guard:
# `sdiv`/`srem i32` are undefined behavior in LLVM on a zero divisor (and on
# the lone overflowing case `i32::MIN / -1`), which traps the whole process
# with SIGFPE and no diagnostic on x86 if left unchecked. The divisor here is
# read back from an `Enemy`'s field rather than written as a literal `0` so
# the checker's (nonexistent) constant-folding can't be accused of catching
# this at compile time -- it's a genuine runtime value.

struct Enemy:
    mut hp: i32

fn main():
    let e = Enemy(0)
    print("before")
    let x = 10 / e.hp
    print(f"should not reach here: 10 / 0 = {x}")

fn apply_twice(f: Fn(i32) -> i32, x: i32) -> i32:
    f(f(x))

# A plain top-level function, never wrapped in a lambda literal -- used
# below both called directly and passed as a first-class `Fn(i32) -> i32`
# value, to exercise the `add_one`-as-value (function-pointer) codegen
# path alongside the ordinary direct-call path.
fn add_one(x: i32) -> i32:
    x + 1

fn make_adder(n: i32) -> Fn(i32) -> i32:
    fn(x: i32) -> i32: x + n

fn main():
    let add1 = fn(x: i32) -> i32: x + 1
    println(f"add1(5) = {add1(5)}")

    let base = 10
    let add_base = fn(x: i32) -> i32: x + base
    println(f"add_base(7) = {add_base(7)}")

    println(f"apply_twice(add1, 5) = {apply_twice(add1, 5)}")

    println(f"add_one(5) = {add_one(5)}")
    println(f"apply_twice(add_one, 5) = {apply_twice(add_one, 5)}")

    let adder = make_adder(100)
    println(f"adder(5) = {adder(5)}")

    let mut counter = 0
    let bump = fn() -> i32: counter + 1
    counter = 50
    println(f"bump() = {bump()}")

    let say_hi = fn(): println("hi from a void closure")
    say_hi()

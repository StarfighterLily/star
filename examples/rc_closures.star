# Exercises reference-counted closure environments from todo.md §3.6:
# a closure capturing a `str` by value, escaping its defining function,
# stored in a struct field and in a list, called long after the local
# binding that created it went out of scope -- plus a closure capturing
# another closure. The regression risk this guards against is a captured
# value's reference being released too early (the closure would read
# corrupted/freed memory when finally called) or never released at all
# (the leak todo.md flags).

struct Handler:
    action: Fn() -> str

fn make_greeter(name: str) -> Fn() -> str:
    fn() -> str: name

fn make_adder(base: i32) -> Fn(i32) -> i32:
    fn(x: i32) -> i32: x + base

fn main():
    let greet = make_greeter("Alice")
    println(f"{greet()}")

    let h = Handler(action = make_greeter("Bob"))
    println(f"{h.action()}")

    let mut greeters: List<Fn() -> str> = [make_greeter("Carol"), make_greeter("Dave")]
    println(f"{greeters[0]()}")
    println(f"{greeters[1]()}")

    let add5 = make_adder(5)
    let apply_add5 = fn(x: i32) -> i32: add5(x)
    println(f"apply_add5(10) = {apply_add5(10)}")

    let mut i = 0
    while i < 3:
        println(f"tick {i}: {greet()}")
        i += 1

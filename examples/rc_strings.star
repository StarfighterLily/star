# Exercises the reference-counted `str` heap values from todo.md §3.6:
# concat results, reassignment, struct fields, list elements, and passing a
# `str` into a function, all composed together -- the regression risk this
# guards against isn't the leak itself (see `rc_stress.star` for that), it's
# a release firing too early and corrupting/truncating a string still in use.
#
# A function *returning* a freshly constructed `str` (e.g. `fn f() -> str:
# concat(a, b)`) used to trip an unrelated, pre-existing dangling-pointer bug
# here -- see `str_fixes.star`, which now exercises exactly that case (fixed
# by removing the `Str` "box" indirection entirely).

struct Greeting:
    text: str

fn shout_len(s: str) -> i32:
    let shouted = concat(s, "!!!")
    len(shouted)

fn main():
    let mut s = concat("foo", "bar")
    println(s)
    s = concat(s, "baz")
    println(s)

    let g = Greeting(text = concat("hello", " world"))
    println(g.text)
    let g2 = g
    println(g2.text)

    let mut words: List<str> = [concat("alpha", "-1"), concat("beta", "-2")]
    words.push(concat("gamma", "-3"))
    println(f"{words[0]}")
    println(f"{words[1]}")
    println(f"{words[2]}")
    println(f"words len = {words.len()}")

    let go = concat("g", "o")
    println(f"shout_len(go) = {shout_len(go)}")

    let mut i = 0
    let mut acc = "start"
    while i < 5:
        acc = concat(acc, "-x")
        i += 1
    println(acc)

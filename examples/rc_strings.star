# Exercises the reference-counted `str` heap values from todo.md §3.6:
# concat results, reassignment, struct fields, list elements, and passing a
# `str` into a function, all composed together -- the regression risk this
# guards against isn't the leak itself (see `rc_stress.star` for that), it's
# a release firing too early and corrupting/truncating a string still in use.
#
# Deliberately not exercised here: a function *returning* a freshly
# constructed `str` (e.g. `fn f() -> str: concat(a, b)`). That trips an
# unrelated, pre-existing bug -- `Codegen::box_str_ptr`'s "box" wrapper is
# always a stack `alloca`, which dangles the moment the function returns it,
# independent of reference counting. Confirmed present in the last commit
# before this session's changes; out of scope for the leak fix here.

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

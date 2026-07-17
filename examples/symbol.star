# Demonstrates `Symbol` (docs/design.md's "Text and bytes" section): an
# interned string with O(1) equality comparison, for entity tags/event names
# where a byte-for-byte `str` compare every frame would be a real cost.
# Lowers to a bare i64 id into a process-wide intern table; equal strings
# always intern to the same id, so `==` between two `Symbol`s is a single
# integer compare.

fn main():
    let a = Symbol("player")
    let b = Symbol("player")
    let c = Symbol("enemy")

    print(f"Symbol(\"player\") == Symbol(\"player\") is {a == b}")
    print(f"Symbol(\"player\") == Symbol(\"enemy\") is {a == c}")
    print(f"Symbol(\"player\") != Symbol(\"enemy\") is {a != c}")

    # `as i64` is a free bit-preserving relabel -- interning order is
    # deterministic (first-seen order), so ids are stable within one run.
    let a_id = a as i64
    let c_id = c as i64
    print(f"a_id == 0 is {a_id == (0 as i64)}")
    print(f"c_id == 1 is {c_id == (1 as i64)}")
    let back = c_id as Symbol
    print(f"(c_id as Symbol) == c is {back == c}")

    # `symbol_name` reverses the lookup.
    print(f"symbol_name(a) = {symbol_name(a)}")
    print(f"symbol_name(c) = {symbol_name(c)}")

    # A legal `Map`/`Set` key.
    let mut hp: Map<Symbol, i32> = Map<Symbol, i32>()
    hp.insert(a, 100)
    hp.insert(c, 40)
    hp.insert(Symbol("player"), 80)
    print(f"hp.len() = {hp.len()}")
    match hp.get(a):
        Option::Some(v) -> print(f"player hp = {v}")
        Option::None -> print("player hp missing")

    let mut tags: Set<Symbol> = Set<Symbol>()
    tags.insert(Symbol("flying"))
    tags.insert(Symbol("flying"))
    tags.insert(Symbol("armored"))
    print(f"tags.len() = {tags.len()}")
    let has_flying = tags.contains(Symbol("flying"))
    print(f"tags.contains(flying) is {has_flying}")

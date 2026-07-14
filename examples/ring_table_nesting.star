# Nesting coverage for `Ring<T,N>`/`Table<T>` not exercised by
# `examples/ring.star`/`examples/table.star`/`examples/ring_table_edge_cases.star`:
# a `Ring<T,N>` stored as a *struct field* (exercising `Codegen::type_size`/
# `type_align`'s `Ty::Ring` arm for real struct-layout offsets, and plain
# struct-value-copy independence, since a `Ring<T,N>` has no copy-on-write of
# its own -- unlike every other collection type here, copying the struct that
# holds it must deep-copy the ring inline), a `Table<T>` whose element struct
# has a `Ring<str,N>` field (RC content nested a level deeper than the
# existing `List<i32>`-field coverage), and a `Ring<Table<T>, N>` (a `Table<T>`
# -- itself RC'd -- as a ring element type, exercising eviction releasing a
# whole table).

struct Player:
    name: str
    hp: i32

struct Snapshot:
    tag: i32
    mut history: Ring<i32, 3>
    mut who: Ring<Player, 2>

fn make_snapshot() -> Snapshot:
    let mut h: Ring<i32, 3> = Ring<i32, 3>()
    h.push(1)
    h.push(2)
    let mut w: Ring<Player, 2> = Ring<Player, 2>()
    w.push(Player(name = "Hero", hp = 100))
    return Snapshot(tag = 42, history = h, who = w)

struct Bag:
    mut hist: Ring<str, 2>
    tag: i32

struct Item:
    tag: i32

fn main():
    # A `Ring<T,N>` stored as a struct field, including a `Ring<Player,2>`
    # (a struct element type) alongside a `Ring<i32,3>` in the same struct
    # (exercising `padded_struct_size`'s general offset algorithm for two
    # differently-shaped inline-ring fields back to back).
    let s = make_snapshot()
    println(f"snapshot tag={s.tag} hist_len={s.history.len()} hist=[{s.history[0]}, {s.history[1]}]")
    println(f"snapshot who_len={s.who.len()} who0={s.who[0].name} hp={s.who[0].hp}")

    # Plain struct-value copy must deep-copy the inline ring field -- a
    # `Ring<T,N>` has no copy-on-write/RC of its own (see
    # `crate::codegen::ring`'s module doc comment), unlike `List<T>`/
    # `Table<T>`, so mutating the copy's ring must never be visible through
    # the original's.
    let mut a = s
    a.history.push(3)
    a.history.push(4)
    println(f"a hist len={a.history.len()} a=[{a.history[0]}, {a.history[1]}]")
    println(f"s hist len={s.history.len()} s=[{s.history[0]}, {s.history[1]}]")

    # `Table<T>` whose element struct has a `Ring<str,N>` field: RC content
    # nested through the table's column layout one level deeper than a
    # direct `str`/`List<i32>` field -- exercises `table_release_thunk`'s
    # `contains_rc` walk correctly recursing into `Ty::Ring`.
    let mut bags = Table<Bag>()
    let mut h1: Ring<str, 2> = Ring<str, 2>()
    h1.push("a")
    h1.push("b")
    bags.push(Bag(hist = h1, tag = 1))
    let mut h2: Ring<str, 2> = Ring<str, 2>()
    h2.push("c")
    bags.push(Bag(hist = h2, tag = 2))
    println(f"bags len={bags.len()}")
    println(f"bags[0] tag={bags[0].tag} hist_len={bags[0].hist.len()} h=[{bags[0].hist[0]}, {bags[0].hist[1]}]")
    println(f"bags[1] tag={bags[1].tag} hist_len={bags[1].hist.len()} h0={bags[1].hist[0]}")

    let bags_clone = bags
    bags.push(Bag(hist = Ring<str, 2>(), tag = 3))
    println(f"bags orig len={bags.len()} clone len={bags_clone.len()}")
    let popped_bag = bags.pop()
    println(f"popped tag={popped_bag.tag} hist_len={popped_bag.hist.len()}")

    # `Ring<Table<T>, N>`: a `Table<T>` (RC'd, heap-backed) as a ring
    # element type -- exercises the ring eviction path releasing a whole
    # table, not just a scalar/str.
    let mut r: Ring<Table<Item>, 2> = Ring<Table<Item>, 2>()
    let mut t1 = Table<Item>()
    t1.push(Item(tag = 1))
    r.push(t1)
    let mut t2 = Table<Item>()
    t2.push(Item(tag = 2))
    t2.push(Item(tag = 3))
    r.push(t2)
    println(f"r len={r.len()} r0 len={r[0].len()} r0[0].tag={r[0][0].tag}")
    println(f"r1 len={r[1].len()} r1[0].tag={r[1][0].tag} r1[1].tag={r[1][1].tag}")

    let mut t3 = Table<Item>()
    t3.push(Item(tag = 9))
    r.push(t3)
    println(f"after evict r len={r.len()} r0 len={r[0].len()} r0[0].tag={r[0][0].tag}")

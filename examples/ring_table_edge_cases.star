# Targeted edge-case coverage for `Ring<T,N>`/`Table<T>` not exercised by
# `examples/ring.star`/`examples/table.star`: capacity-1 rings (every push
# immediately evicts), negative-index reads (must be treated as
# out-of-bounds, not wrap via unsigned modulo), a `Ring<T,N>`/`Table<T>`
# element type whose RC content is nested a level deep through a struct
# field (a `List<i32>`, not a direct `str` field -- exercises
# `Codegen::contains_rc`'s `Ty::Named` recursion), and a struct with no RC
# columns at all (an all-`i32` `Table<T>`, exercising the release-thunk/CoW
# code paths that must correctly do *nothing* extra for a non-RC column).

struct Bag:
    items: List<i32>
    label: str

struct Point:
    x: i32
    y: i32

fn main():
    # Capacity-1 ring: every push evicts immediately, so len never exceeds 1.
    let mut r1: Ring<i32, 1> = Ring<i32, 1>()
    r1.push(10)
    r1.push(20)
    r1.push(30)
    println(f"r1 len={r1.len()} r1[0]={r1[0]}")

    # Negative index reads: sign-extends to a huge unsigned value, must be
    # treated as out-of-bounds (zero value), not wrap to a valid slot.
    let mut r2: Ring<i32, 3> = Ring<i32, 3>()
    r2.push(1)
    r2.push(2)
    println(f"r2[-1]={r2[-1]}")

    # Nested RC element type: Ring<Bag,2> where Bag has a List<i32> field --
    # exercises `contains_rc`'s recursion through `Ty::Named` -> struct field
    # -> `List`, not just a direct `str` field.
    let mut r3: Ring<Bag, 2> = Ring<Bag, 2>()
    r3.push(Bag(items = [1, 2, 3], label = "first"))
    r3.push(Bag(items = [4, 5], label = "second"))
    r3.push(Bag(items = [6], label = "third"))
    println(f"r3[0].label={r3[0].label} r3[0].items.len()={r3[0].items.len()}")
    println(f"r3[1].label={r3[1].label} r3[1].items.len()={r3[1].items.len()}")

    # Table<T> with an all-i32 (no-RC-column) struct: the release thunk and
    # CoW-clone path must still work correctly with zero RC-bearing columns.
    let mut pts: Table<Point> = Table<Point>()
    pts.push(Point(x = 1, y = 2))
    pts.push(Point(x = 3, y = 4))
    let mut pts_clone = pts
    pts_clone.push(Point(x = 5, y = 6))
    println(f"pts len={pts.len()} clone len={pts_clone.len()}")
    println(f"pts[1] = ({pts[1].x}, {pts[1].y})")

    # Negative index reads on a Table<T> -- same OOB convention as Ring.
    println(f"pts[-1] = ({pts[-1].x}, {pts[-1].y})")

    # Table<T> with nested RC content (List<i32> field, not just str).
    let mut bags: Table<Bag> = Table<Bag>()
    bags.push(Bag(items = [7, 8, 9], label = "alpha"))
    bags.push(Bag(items = List<i32>(), label = "beta"))
    println(f"bags[0].label={bags[0].label} bags[0].items.len()={bags[0].items.len()}")
    println(f"bags[1].label={bags[1].label} bags[1].items.len()={bags[1].items.len()}")

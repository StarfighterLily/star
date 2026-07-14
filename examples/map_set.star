struct Point:
    x: i32
    y: i32

fn main():
    let mut ages = Map<str, i32>()
    ages.insert("alice", 30)
    ages.insert("bob", 25)
    println(f"len after 2 inserts: {ages.len()}")

    match ages.get("alice"):
        Option::Some(v) -> println(f"alice: {v}")
        Option::None -> println("alice: missing")

    match ages.get("carol"):
        Option::Some(v) -> println(f"carol: {v}")
        Option::None -> println("carol: missing")

    ages.insert("alice", 31)
    println(f"len after overwrite: {ages.len()}")
    match ages.get("alice"):
        Option::Some(v) -> println(f"alice after overwrite: {v}")
        Option::None -> println("alice: missing")

    let bob_key = "bob"
    println(f"contains bob: {ages.contains(bob_key)}")
    match ages.remove("bob"):
        Option::Some(v) -> println(f"removed bob: {v}")
        Option::None -> println("bob: missing")
    println(f"contains bob after remove: {ages.contains(bob_key)}")
    println(f"len after remove: {ages.len()}")

    let mut tags = Set<i32>()
    println(f"insert 1 (new): {tags.insert(1)}")
    println(f"insert 2 (new): {tags.insert(2)}")
    println(f"insert 1 (dup): {tags.insert(1)}")
    println(f"set len: {tags.len()}")
    println(f"contains 2: {tags.contains(2)}")
    println(f"remove 2: {tags.remove(2)}")
    println(f"contains 2 after remove: {tags.contains(2)}")
    println(f"remove 2 again: {tags.remove(2)}")
    println(f"set len after removes: {tags.len()}")

    let mut points = Set<Point>()
    points.insert(Point(x = 1, y = 2))
    points.insert(Point(x = 1, y = 2))
    points.insert(Point(x = 3, y = 4))
    println(f"struct set len: {points.len()}")
    println(f"contains (1,2): {points.contains(Point(x = 1, y = 2))}")
    println(f"contains (9,9): {points.contains(Point(x = 9, y = 9))}")

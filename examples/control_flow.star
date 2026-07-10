enum Direction:
    North
    South
    East
    West

fn print_dir(d: Direction):
    match d:
        Direction::North -> println("dir: north")
        Direction::South -> println("dir: south")
        Direction::East -> println("dir: east")
        Direction::West -> println("dir: west")

fn sum_with_skip_and_stop() -> i32:
    let mut total: i32 = 0
    for i in 0..10:
        if i == 5:
            continue
        if i == 8:
            break
        total += i
    total

fn count_with_nested_break() -> i32:
    let mut count: i32 = 0
    for i in 0..3:
        for j in 0..3:
            if j == 1:
                break
            count += 1
    count

fn while_break_at_four() -> i32:
    let mut n: i32 = 0
    while true:
        n += 1
        if n == 4:
            break
    n

fn main():
    println(f"sum: {sum_with_skip_and_stop()}")
    println(f"nested: {count_with_nested_break()}")
    println(f"while: {while_break_at_four()}")
    print_dir(Direction::North)
    print_dir(Direction::West)

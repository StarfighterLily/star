struct Point:
    x: i32 = 0
    y: i32 = 0

fn sum_list(nums: List<i32>) -> i32:
    let mut total: i32 = 0
    let mut i: i32 = 0
    while i < nums.len():
        total += nums[i]
        i += 1
    total

fn main():
    let mut nums: List<i32> = [1, 2, 3]
    println(f"initial len = {nums.len()}")
    nums.push(4)
    nums.push(5)
    println(f"after push len = {nums.len()}")

    for i in 0..nums.len():
        println(f"nums[{i}] = {nums[i]}")

    nums[0] = 100
    println(f"nums[0] after set = {nums[0]}")

    let popped = nums.pop()
    println(f"popped = {popped}")
    println(f"len after pop = {nums.len()}")

    println(f"sum via function = {sum_list(nums)}")

    let mut empty: List<i32> = List<i32>()
    println(f"empty len = {empty.len()}")
    let oob_pop = empty.pop()
    println(f"pop from empty = {oob_pop}")
    let oob_read = empty[0]
    println(f"index oob = {oob_read}")

    let mut grown: List<i32> = List<i32>()
    let mut j: i32 = 0
    while j < 20:
        grown.push(j)
        j += 1
    println(f"grown len = {grown.len()}")
    println(f"grown[19] = {grown[19]}")
    println(f"grown[0] = {grown[0]}")

    let mut words: List<String> = ["alpha", "beta", "gamma"]
    println(f"words len = {words.len()}")
    println(f"words[1] = {words[1]}")

    let mut points: List<Point> = [Point(x = 1, y = 2), Point(x = 3, y = 4)]
    let p = points[1]
    println(f"points[1] = ({p.x}, {p.y})")

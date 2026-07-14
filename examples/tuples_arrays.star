struct Player:
    mut health: i32
    name: str

fn min_max(a: i32, b: i32) -> (i32, i32):
    match a <= b:
        true -> (a, b)
        false -> (b, a)

fn main():
    # Tuples: lightweight multi-return without declaring a one-off struct.
    let mut point = (3, 4)
    println(f"point = ({point.0}, {point.1})")
    point.0 = 10
    println(f"point after mutation = ({point.0}, {point.1})")

    # No destructuring `let` pattern yet -- read a returned tuple positionally.
    let result = min_max(7, 2)
    println(f"min_max(7, 2) = ({result.0}, {result.1})")

    # A tuple can nest a struct; mutating through the tuple mutates the
    # struct value the tuple itself owns (not a shared alias).
    let mut carrying_player = (Player(health = 100, name = "Hero"), "extra lives: 2")
    carrying_player.0.health -= 25
    println(f"{carrying_player.0.name} hp={carrying_player.0.health} ({carrying_player.1})")

    # A single parenthesized value with no comma is still just grouping.
    let grouped = (5)
    println(f"grouped = {grouped}")
    # A trailing comma makes a genuine 1-element tuple.
    let one = (9,)
    println(f"one.0 = {one.0}")

    # Fixed-size arrays: a compile-time-constant element count, unlike
    # List<T>'s runtime-growable length. The only literal form is the
    # `[value; N]` repeat (evaluated once, copied into every slot).
    let mut scores: [i32; 5] = [0; 5]
    println(f"scores.len() = {scores.len()}")
    scores[2] = 42
    println(f"scores = [{scores[0]}, {scores[1]}, {scores[2]}, {scores[3]}, {scores[4]}]")

    # Out of bounds is safe, not a crash: a zero-value read, a silent no-op
    # write -- matching List<T>'s own fails-safe convention.
    println(f"scores[99] = {scores[99]}")
    scores[99] = 7
    println(f"scores[2] unaffected by the out-of-bounds write = {scores[2]}")

    # A repeat literal makes N independent copies, not N aliases of one
    # shared value -- mutating one slot never affects the others.
    let mut party = [Player(health = 50, name = "Grunt"); 3]
    party[0].health -= 10
    println(f"party[0].health={party[0].health} party[1].health={party[1].health}")

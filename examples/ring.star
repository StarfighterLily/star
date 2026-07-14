struct Player:
    mut health: i32
    name: str

fn main():
    # Ring<T, N>: a fixed-capacity ring buffer -- a sliding window over the
    # most recent N pushes. Unlike List<T>, push() never grows past N: once
    # full, it evicts the oldest (front) element instead of no-op'ing.
    let mut history: Ring<i32, 3> = Ring<i32, 3>()
    println(f"empty len = {history.len()}")
    history.push(1)
    history.push(2)
    history.push(3)
    println(f"after 3 pushes len = {history.len()}")
    println(f"history = [{history[0]}, {history[1]}, {history[2]}]")

    # Pushing past capacity evicts the oldest element -- len stays at N, and
    # index 0 always reads the current oldest live element.
    history.push(4)
    println(f"after push past capacity len = {history.len()}")
    println(f"history = [{history[0]}, {history[1]}, {history[2]}]")

    # pop() removes and returns the oldest (front) element -- FIFO order.
    let oldest = history.pop()
    println(f"popped = {oldest}")
    println(f"len after pop = {history.len()}")

    # Out of bounds is safe: a zero-value read, bounds-checked against the
    # current len (not the static capacity N) -- matching List<T>'s own
    # fails-safe convention.
    println(f"history[99] = {history[99]}")

    # pop() on an empty ring yields the zero value too.
    let mut tiny: Ring<i32, 2> = Ring<i32, 2>()
    println(f"pop from empty = {tiny.pop()}")

    # Indexed write overwrites a live slot in place, without touching head/len.
    history[0] = 100
    println(f"history[0] after set = {history[0]}")

    # A ring of a heap-backed element type (str) exercises the RC-safe
    # eviction/pop path (release-before-overwrite on evict, zero-after-pop).
    let mut names: Ring<str, 2> = Ring<str, 2>()
    names.push("alpha")
    names.push("beta")
    names.push("gamma")
    println(f"names = [{names[0]}, {names[1]}]")

    # A struct element type works too -- each push copies the struct value in.
    let mut party: Ring<Player, 2> = Ring<Player, 2>()
    party.push(Player(health = 100, name = "Hero"))
    party.push(Player(health = 80, name = "Sidekick"))
    println(f"party[0] = {party[0].name} hp={party[0].health}")

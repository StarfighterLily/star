struct Enemy:
    mut hp: i32
    name: str

fn main():
    # Table<T>: a struct-of-arrays table -- complements an arena's
    # array-of-structs layout. T must be a plain struct; each field gets its
    # own parallel growable column instead of one array-of-Enemy buffer.
    let mut enemies: Table<Enemy> = Table<Enemy>()
    println(f"empty len = {enemies.len()}")
    enemies.push(Enemy(hp = 10, name = "Goblin"))
    enemies.push(Enemy(hp = 20, name = "Orc"))
    enemies.push(Enemy(hp = 30, name = "Troll"))
    println(f"after 3 pushes len = {enemies.len()}")
    println(f"enemies[0] = {enemies[0].name} hp={enemies[0].hp}")
    println(f"enemies[2] = {enemies[2].name} hp={enemies[2].hp}")

    # Indexed write replaces the whole element, reassembled back into every
    # column.
    enemies[1] = Enemy(hp = 99, name = "Orc Chief")
    println(f"enemies[1] after set = {enemies[1].name} hp={enemies[1].hp}")

    # pop() removes and returns the last element (reassembled from every
    # column), shrinking len -- mirrors List<T>'s pop convention.
    let last = enemies.pop()
    println(f"popped = {last.name} hp={last.hp}")
    println(f"len after pop = {enemies.len()}")

    # Out of bounds is a safe zero-value read, bounds-checked against the
    # current len -- matching List<T>/Ring<T,N>'s own convention.
    println(f"enemies[99] hp = {enemies[99].hp}")

    # pop() on an empty table yields the zero value too.
    let mut nobody: Table<Enemy> = Table<Enemy>()
    let popped_empty = nobody.pop()
    println(f"pop from empty hp = {popped_empty.hp}")

    # Copy-on-write: `let clone = original` is an O(1) refcount bump: every
    # column is still shared until a mutation forces a per-column clone, so
    # mutating one must never affect the other.
    let mut original: Table<Enemy> = Table<Enemy>()
    original.push(Enemy(hp = 1, name = "A"))
    let mut clone = original
    clone.push(Enemy(hp = 2, name = "B"))
    println(f"original len = {original.len()} clone len = {clone.len()}")
    println(f"original[0] hp = {original[0].hp} clone[0] hp = {clone[0].hp}")

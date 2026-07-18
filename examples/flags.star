# Demonstrates docs/design.md's "Bit-level types" section's `Flags<E>`: a
# typed bitflag set for input state, physics collision layers, and render
# state -- anywhere a fieldless enum's variants each need to be
# independently on/off rather than mutually exclusive.

enum Direction:
    Up
    Down
    Left
    Right

fn main():
    # An empty flag set, then building it up one variant at a time.
    let mut moving: Flags<Direction> = Flags<Direction>()
    println(f"empty moving is empty? {flags_is_empty(moving)}")

    moving = flags_with(moving, Direction::Up)
    println(f"moving has Up? {flags_has(moving, Direction::Up)}")
    println(f"moving has Down? {flags_has(moving, Direction::Down)}")
    println(f"moving is empty? {flags_is_empty(moving)}")

    moving = flags_with(moving, Direction::Right)
    println(f"moving has Right after adding it? {flags_has(moving, Direction::Right)}")

    # Constructing directly from multiple variants at once.
    let diagonal: Flags<Direction> = Flags<Direction>(Direction::Up, Direction::Right)
    println(f"diagonal == moving is {diagonal == moving}")

    # Removing a variant.
    moving = flags_without(moving, Direction::Up)
    println(f"moving has Up after removing it? {flags_has(moving, Direction::Up)}")
    println(f"moving has Right still? {flags_has(moving, Direction::Right)}")

    # `bit_or`/`bit_and`/`bit_xor` combine whole flag sets (union/intersect/
    # symmetric difference).
    let all_four: Flags<Direction> = Flags<Direction>(Direction::Up, Direction::Down, Direction::Left, Direction::Right)
    let vertical: Flags<Direction> = Flags<Direction>(Direction::Up, Direction::Down)
    let horizontal: Flags<Direction> = Flags<Direction>(Direction::Left, Direction::Right)
    let union = bit_or(vertical, horizontal)
    println(f"vertical | horizontal == all_four is {union == all_four}")
    let empty: Flags<Direction> = Flags<Direction>()
    let intersection = bit_and(vertical, horizontal)
    println(f"vertical & horizontal is empty? {intersection == empty}")
    let sym_diff = bit_xor(all_four, vertical)
    println(f"all_four ^ vertical == horizontal is {sym_diff == horizontal}")

    # A runtime (non-literal) enum value works too, not just a literal
    # `EnumName::Variant`.
    let dir: Direction = Direction::Left
    let from_var: Flags<Direction> = Flags<Direction>(dir)
    println(f"from_var has Left? {flags_has(from_var, Direction::Left)}")

    # `!=` and `as i64` (a free bit-preserving relabel, for debugging).
    println(f"vertical != horizontal is {vertical != horizontal}")
    let raw: i64 = all_four as i64
    println(f"all_four as i64 = {raw}")

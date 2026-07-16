# Demonstrates docs/design.md's "Numeric widths and modes" section's
# `Wrapping<T>`: silent-overflow arithmetic, the explicit opt-in for a width
# that would otherwise trap on overflow like every other explicit-width
# integer type -- for emulating an actual 8/16-bit register or audio-chip
# counter faithfully.

fn main():
    # A u8 register that silently wraps 255 -> 0, matching real hardware --
    # unlike a plain `u8`, which would trap on this overflow.
    let mut frame_counter: Wrapping<u8> = Wrapping<u8>(250 as u8)
    let step: Wrapping<u8> = Wrapping<u8>(1 as u8)
    let mut i = 0
    while i < 10:
        frame_counter = frame_counter + step
        i += 1
    # 250 + 10 wraps around mod 256, landing on 4.
    println(f"frame_counter after wraparound = {frame_counter}")

    # Signed wraparound too: i8::MAX + 1 wraps to i8::MIN.
    let near_max: Wrapping<i8> = Wrapping<i8>(127 as i8)
    let one: Wrapping<i8> = Wrapping<i8>(1 as i8)
    println(f"i8::MAX + 1 wraps to {near_max + one}")

    # `Wrapping<i32>` closes the one gap `i32` itself still has: MIN / -1
    # wraps to MIN instead of trapping (the lone i32 overflow case).
    let min_val: Wrapping<i32> = Wrapping<i32>(-2147483648)
    let neg_one: Wrapping<i32> = Wrapping<i32>(-1)
    println(f"i32::MIN / -1 wraps to {min_val / neg_one}")

    # Comparisons work exactly like the underlying integer type.
    let a: Wrapping<u16> = Wrapping<u16>(100 as u16)
    let b: Wrapping<u16> = Wrapping<u16>(200 as u16)
    println(f"a < b is {a < b}")

    # `as` is a free bit-preserving relabel back to the plain integer type.
    let plain: u8 = frame_counter as u8
    println(f"unwrapped = {plain}")

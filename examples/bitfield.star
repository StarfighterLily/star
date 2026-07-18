# Demonstrates docs/design.md's "Bit-level types" section's `BitField<N>`:
# a packed bit register for accurate retro CPU flag-register emulation (e.g.
# Z80/6502 status flags) and other hand-rolled bitmasks.

fn main():
    # A fresh 8-bit status register, all bits clear.
    let mut status: BitField<8> = BitField<8>(0)
    println(f"initial status = {status}")

    # Setting the zero flag (bit 1) and the carry flag (bit 0).
    status = bit_set(status, 0)
    status = bit_set(status, 1)
    println(f"after setting bits 0 and 1 = {status}")
    println(f"bit 0 (carry) set? {bit_get(status, 0)}")
    println(f"bit 2 (unset) set? {bit_get(status, 2)}")

    # Clearing the carry flag on overflow recovery.
    status = bit_clear(status, 0)
    println(f"after clearing bit 0 = {status}")
    println(f"bit 0 set? {bit_get(status, 0)}")

    # Toggling the interrupt-disable flag (bit 2) twice returns to the start.
    status = bit_toggle(status, 2)
    println(f"after toggling bit 2 once = {status}")
    status = bit_toggle(status, 2)
    println(f"after toggling bit 2 twice = {status}")

    # `bit_and`/`bit_or`/`bit_xor`/`bit_not` combine whole registers.
    let mask: BitField<8> = BitField<8>(15 as u8)
    let combined = bit_or(status, mask)
    println(f"status | 0x0F = {combined}")
    let intersected = bit_and(combined, mask)
    println(f"(status | 0x0F) & 0x0F = {intersected}")
    let inverted = bit_not(mask)
    println(f"~0x0F = {inverted}")
    let xored = bit_xor(mask, mask)
    println(f"0x0F ^ 0x0F = {xored}")

    # `==`/`!=` compare whole registers.
    println(f"mask == mask is {mask == mask}")
    println(f"mask != combined is {mask != combined}")

    # `as` is a free bit-preserving relabel back to a plain integer type.
    let raw: u8 = mask as u8
    println(f"mask as u8 = {raw}")
    let roundtrip: BitField<8> = raw as BitField<8>
    println(f"roundtrip == mask is {roundtrip == mask}")

    # Every supported width works the same way -- 16/32/64-bit registers too.
    let mut wide: BitField<32> = BitField<32>(0)
    wide = bit_set(wide, 31)
    println(f"bit 31 of a 32-bit register set = {wide}")
    println(f"bit 31 set? {bit_get(wide, 31)}")

    let mut huge: BitField<64> = BitField<64>(0)
    huge = bit_set(huge, 63)
    println(f"bit 63 of a 64-bit register set = {huge}")

    # `Wrapping<T>` and plain integer types also support the free-function
    # bit-manipulation surface -- not just `BitField<N>` itself.
    let reg: i32 = 0
    let reg2 = bit_set(reg, 4)
    println(f"bit_set on a plain i32 = {reg2}")
    let w: Wrapping<u8> = Wrapping<u8>(0 as u8)
    let w2 = bit_set(w, 7)
    println(f"bit_set on a Wrapping<u8> = {w2}")

# Demonstrates docs/design.md's "Numeric widths and modes" section's
# `Fixed<Bits, Frac>`: deterministic fixed-point arithmetic, for lockstep
# simulation and rollback netcode where float non-determinism across
# machines is a correctness bug, not a rounding nit.

fn main():
    # Fixed<32, 16>: a 32-bit Q16.16 value -- 16 integer bits, 16 fractional
    # bits. Constructed directly from a float literal (the one well-defined
    # float boundary this type allows -- every operation after this is pure
    # deterministic integer math).
    let a: Fixed<32, 16> = Fixed<32, 16>(3.5)
    let b: Fixed<32, 16> = Fixed<32, 16>(2.0)
    println(f"a + b = {a + b}")
    println(f"a - b = {a - b}")
    println(f"a * b = {a * b}")
    println(f"a / b = {a / b}")

    # Constructing directly from an integer is exact (a plain `shl` by the
    # fractional-bit count) -- no float involved at all.
    let whole: Fixed<32, 16> = Fixed<32, 16>(10)
    println(f"whole = {whole}")

    # Comparisons work like any other numeric type.
    println(f"a < whole is {a < whole}")

    # `as` converts back to a float for display/config, a true scaled
    # conversion (not a bit reinterpret).
    let back: f32 = a as f32
    println(f"a as f32 = {back}")

    # A narrower Fixed<8, 4> (Q3.4, mostly for retro-scale fixed-point) --
    # exercises the same i128-widening multiply/divide path at a much
    # smaller width.
    let small_a: Fixed<8, 4> = Fixed<8, 4>(3.5)
    let small_b: Fixed<8, 4> = Fixed<8, 4>(1.5)
    println(f"small_a * small_b = {small_a * small_b}")

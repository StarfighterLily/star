# Demonstrates docs/design.md's "Numeric widths and modes" section: every
# explicit-width integer/float alongside the original i32/f32, plus `char`
# (a Unicode scalar) and `expr as Type` explicit casts. There is no implicit
# widening between distinct numeric types (the original int/float mixed-pair
# promotion is the one preserved exception) -- an `as` cast is always
# required to move a value from one width to another.

struct Registers:
    a: u8
    x: i16
    pc: u32

fn main():
    # Retro-tier: exact-width integers for emulating hardware registers.
    let regs = Registers(200 as u8, -1000 as i16, 65536 as u32)
    print(f"a={regs.a} x={regs.x} pc={regs.pc}")

    # `+`/`-`/`*` trap on overflow for every explicit-width integer type
    # (unlike i32, which keeps its original silent wraparound) -- 250 + 10
    # would overflow a u8, so this stays safely under the limit instead.
    let hp: u8 = 250 as u8
    let heal: u8 = 5 as u8
    print(f"healed hp={hp + heal}")

    # AAA-tier: i64/f64 for large-world coordinates and precise math.
    let world_x: i64 = 1000000000 as i64
    let scale: i64 = 8 as i64
    print(f"world_x={world_x * scale}")

    let precise: f64 = 22 as f64
    let divisor: f64 = 7 as f64
    print(f"pi_approx={precise / divisor}")

    # `char`: a Unicode scalar, distinct from a raw `str` byte -- supports
    # equality/ordering but not arithmetic; convert to/from an integer type
    # via `as` to do codepoint arithmetic.
    let grade = 'A' as i32 + 1
    let next_grade = grade as char
    print(f"next_grade={next_grade}")
    print(f"'a' < 'b' is {'a' < 'b'}")

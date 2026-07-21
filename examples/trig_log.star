# Demonstrates `todo.md` #6 "Fill out math builtins as needed": trig
# (`sin`/`cos`/`tan`/`asin`/`acos`/`atan`/`atan2`) and exponential/logarithm
# (`exp`/`exp2`/`log`/`log2`/`log10`) builtins alongside the pre-existing
# `sqrt`/`pow`/`floor`/`ceil` (see `examples/math_builtins.star` for those).
fn main():
    let pi = 4.0 * atan(1.0)
    print(f"pi (from atan): {pi}")
    print(f"sin(pi/2): {sin(pi / 2.0)}")
    print(f"cos(pi): {cos(pi)}")
    print(f"tan(pi/4): {tan(pi / 4.0)}")

    print(f"asin(0.5): {asin(0.5)}")
    print(f"acos(0.5): {acos(0.5)}")

    # atan2(y, x) uses the sign of both arguments to pick the right quadrant,
    # unlike plain atan(y / x) which can't tell (1, 1) from (-1, -1).
    print(f"atan2(1, 1): {atan2(1.0, 1.0)}")
    print(f"atan2(-1, -1): {atan2(-1.0, -1.0)}")

    print(f"exp(1): {exp(1.0)}")
    print(f"exp2(10): {exp2(10.0)}")
    print(f"log(exp(1)): {log(exp(1.0))}")
    print(f"log2(1024): {log2(1024.0)}")
    print(f"log10(1000): {log10(1000.0)}")

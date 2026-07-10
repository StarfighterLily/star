# Regression check for the `dot`/`length`/`lerp`/`clamp`/`rand`/`rand_range`/
# `rand_seed` builtins (LANGUAGE_ANALYSIS.md §4.6, §5).
fn main():
    let a = Vec3(1.0, 0.0, 0.0)
    let b = Vec3(0.0, 1.0, 0.0)
    print(f"dot: {dot(a, b)}")

    let c = Vec3(3.0, 4.0, 0.0)
    print(f"length: {length(c)}")

    print(f"lerp float: {lerp(0.0, 10.0, 0.5)}")
    let lv = lerp(a, c, 0.5)
    print(f"lerp vec: {lv.x} {lv.y} {lv.z}")

    print(f"clamp int: {clamp(15, 0, 10)}")
    print(f"clamp float: {clamp(-2.5, 0.0, 10.0)}")

    rand_seed(42)
    let r1 = rand()
    let r2 = rand()
    print(f"rand in [0,1): {r1 >= 0.0 and r1 < 1.0} {r2 >= 0.0 and r2 < 1.0}")

    let ri = rand_range(10, 20)
    print(f"rand_range in bounds: {ri >= 10 and ri < 20}")

    rand_seed(42)
    let r1_again = rand()
    print(f"reseeding reproduces the same sequence: {r1 == r1_again}")

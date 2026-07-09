# M8 standard library demonstration: `println` (guaranteed trailing
# newline), basic math builtins (`sqrt`/`pow`/`abs`/`floor`/`ceil`/`min`/
# `max`), string builtins (`len`/`concat`), and a free function that isn't
# `main` (calling another free function, exercising the non-method call path
# in codegen end to end via a real compiled binary).

struct Player:
    @export mut health: i32 = 100
    @tweakable speed: float = 5.0
    name: str = "Hero"

fn add(a: i32, b: i32) -> i32:
    a + b

fn clamp_health(h: i32) -> i32:
    max(0, min(h, 100))

fn main():
    println(f"sum: {add(2, 3)}")
    println(f"sqrt: {sqrt(16.0)}")
    println(f"pow: {pow(2.0, 10.0)}")
    println(f"abs int: {abs(-5)}")
    println(f"abs float: {abs(-5.5)}")
    println(f"floor: {floor(3.75)}")
    println(f"ceil: {ceil(3.25)}")
    println(f"clamped: {clamp_health(150)}")

    let name = "Hero"
    println(f"name len: {len(name)}")
    let greeting = concat("hello, ", name)
    println(f"greeting: {greeting}")

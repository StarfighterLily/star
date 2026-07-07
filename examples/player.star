# The canonical Star example from docs/design.md.
# Exercises structs with defaults, traits, impls, match, and f-strings.

struct Vec3:
    x: f32 = 0.0
    y: f32 = 0.0
    z: f32 = 0.0

struct Player:
    mut health: i32 = 100
    position: Vec3 = Vec3(0, 0, 0)
    name: String

trait Damageable:
    fn take_damage(mut self, amount: i32)

impl Damageable for Player:
    fn take_damage(mut self, amount: i32):
        self.health -= amount
        match self.health:
            <= 0 -> print(f"{self.name} has perished.")
            _    -> print(f"Health critical: {self.health}")

fn main():
    let p = Player(health = 100, position = Vec3(0, 0, 0), name = "Hero")
    p.take_damage(150)

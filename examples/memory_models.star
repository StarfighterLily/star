# Memory Models Demonstration in Star
# This file demonstrates the three memory models: Frame, Arena, and GenRef

# ===== FRAME MEMORY MODEL =====
# Temporal allocations that reset at end of tick
# Used for ephemeral data like pathfinding nodes, intermediate calculations

struct Point:
    x: i32
    y: i32

struct Projectile:
    x: i32
    y: i32

fn calculate_path(start_x: i32, start_y: i32) -> i32:
    frame:
        let node1 = Point(0, 0)
        let node2 = Point(start_x, start_y)
        node1.x + node2.y

# ===== ARENA MEMORY MODEL =====
# Spatial arenas for long-lived state
# Used for macro-level state like level entities, game objects

arena EnemyArena: Point
arena ProjectileArena: Projectile

fn spawn_enemy(x: i32, y: i32) -> i32:
    x

fn spawn_projectile(x: i32, y: i32) -> i32:
    y

# ===== GENREF MEMORY MODEL =====
# Generational references with slot-map pattern: a GenRef<T> is a handle
# {index, generation} into the arena backing T, validated against that
# slot's live generation on every dereference.

fn create_entity_reference(idx: i32) -> GenRef<Point>:
    GenRef<Point>(idx)

fn follow_reference(gen_ref: GenRef<Point>) -> i32:
    gen_ref[0].x

fn game_tick():
    frame:
        spawn EnemyArena(42, 0)
        let temp_counter = 0
        let state_ref = create_entity_reference(0)
        temp_counter + follow_reference(state_ref)

fn main():
    let result = calculate_path(5, 10)
    print(f"Path calculation result: {result}")
    game_tick()
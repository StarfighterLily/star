# Memory Models Demonstration in Star
# This file demonstrates the three memory models: Frame, Arena, and GenRef

# ===== FRAME MEMORY MODEL =====
# Temporal allocations that reset at end of tick
# Used for ephemeral data like pathfinding nodes, intermediate calculations

struct Point:
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
arena ProjectileArena: Point

fn spawn_enemy(x: i32, y: i32) -> i32:
    x

fn spawn_projectile(x: i32, y: i32) -> i32:
    y

# ===== GENREF MEMORY MODEL =====
# Generational references with slot-map pattern

fn create_entity_reference(id: i32) -> GenRef<i32>:
    GenRef<i32>(id)

fn follow_reference(gen_ref: GenRef<i32>) -> i32:
    gen_ref[0]

fn game_tick():
    frame:
        let temp_counter = 0
        let state_ref = create_entity_reference(42)
        temp_counter + follow_reference(state_ref)

fn main():
    let result = calculate_path(5, 10)
    print(f"Path calculation result: {result}")
    game_tick()
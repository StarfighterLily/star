# Cross-system compile-time locks: `system`/`parallel` run named,
# arena-scoped procedures concurrently on the same persistent worker pool
# `par`/`swarm` uses, after the checker proves their declared arena accesses
# don't conflict -- the literal "compile-time lock" `docs/features.md`
# pitches (`Checker::check_parallel_stmt`,
# `src/types/system_analysis.rs`). See `docs/language_reference.md`'s
# "Cross-System Scheduling" section.

struct Enemy:
    mut hp: i32

struct Particle:
    mut life: i32

arena Enemies: Enemy
arena Particles: Particle

# Declares mutable access to `Enemies` only -- may freely `par`/`spawn`/
# `despawn` it, but touching any other arena (`Particles` included) would be
# a compile error.
system UpdateEnemies(mut Enemies):
    par e in Enemies:
        e.hp -= 1

# Declares mutable access to `Particles` only -- disjoint from
# `UpdateEnemies`'s `mut Enemies`, so the compiler proves these two systems
# can safely run concurrently in the `parallel:` block below.
system UpdateParticles(mut Particles):
    par p in Particles:
        p.life -= 1

fn main():
    spawn Enemies(10)
    spawn Enemies(20)
    spawn Enemies(30)
    spawn Particles(5)
    spawn Particles(8)

    # Dispatches both systems to the worker pool at the same time; had they
    # declared a conflicting (>= 1 mutable) lock on the same arena, this
    # would be a compile-time error instead.
    parallel:
        UpdateEnemies()
        UpdateParticles()

    swarm e in Enemies:
        print(f"enemy hp: {e.hp}")
    swarm p in Particles:
        print(f"particle life: {p.life}")
    print(f"parallel done")

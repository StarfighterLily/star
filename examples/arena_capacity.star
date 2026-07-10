# Regression check for arena-capacity overflow (LANGUAGE_ANALYSIS.md §3.2):
# spawning past `ARENA_CAPACITY` (1024) live elements is still silently
# dropped rather than writing out of bounds (a deliberate, defensible choice
# given `par`/`swarm` workers may be concurrently reading the backing
# array), but the caller must now get a loud runtime warning identifying the
# offending arena instead of no signal at all.
struct Enemy:
    hp: i32

arena Enemies: Enemy

fn main():
    for i in 0..1030:
        spawn Enemies(i)
    print("done spawning")

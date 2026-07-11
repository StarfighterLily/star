# Nested `par`/`swarm` demonstration: a `par` statement inside another
# `par` body can't dispatch to the same fixed 4-worker pool it's already
# running on (each outer worker is itself busy), so it falls back to a
# serial, lock-protected pass instead (see `par_pool`'s module doc comment
# and `Codegen::emit_par_dispatch`). This is the runtime regression test for
# that fallback: without the manually-reentrant `serial_lock`, multiple
# outer workers reaching the nested statement concurrently would each run
# an overlapping full pass over `Bullets`, losing updates -- with it, every
# `Bullet` deterministically ends up incremented exactly once per live
# `Enemy`, every run.

struct Enemy:
    mut hp: i32

struct Bullet:
    mut dmg: i32

arena Enemies: Enemy
arena Bullets: Bullet

fn main():
    spawn Enemies(10)
    spawn Enemies(10)
    spawn Enemies(10)
    spawn Bullets(0)
    spawn Bullets(0)
    spawn Bullets(0)
    spawn Bullets(0)
    par e in Enemies:
        par b in Bullets:
            b.dmg = b.dmg + 1
    swarm b in Bullets:
        print(f"dmg: {b.dmg}")

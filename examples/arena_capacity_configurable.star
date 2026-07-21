# `arena Name: Type = N` overrides the default 1024-element capacity
# (`gamedev_gaps.md` #4: "Arena capacity is a hardcoded, silent constant --
# not something you can size for your game"). Every arena still gets its
# own independent backing/generation/free-list array sized for whatever it
# declares -- `examples/arena_capacity.star` is the same overflow-warning
# regression check, but against the un-overridden 1024-element default.
struct Bullet:
    x: i32

arena Bullets: Bullet = 8

fn main():
    for i in 0..12:
        spawn Bullets(i)
    print("done spawning")

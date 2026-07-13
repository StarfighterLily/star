The Star programming language architecture is expressly built to resolve the tension between developer velocity and high-performance game execution. The syntax strips away the noise of semicolons and curly braces in favor of clean, Python-inspired indentation, while retaining the robust type inference, pattern matching, and immutability-by-default of Rust. Furthermore, it avoids rigid OOP inheritance in favor of a hybrid approach combining data objects with behavior implementations.

# Memory
1. Temporal Allocations (frame Context)
Objective: Managing ephemeral data, transient calculations (like A* pathfinding nodes), and intermediate states.

The Mechanism: The frame keyword introduces an implicit bump allocator that resets its pointer to zero at the end of each tick.

Performance Benefits: This grants massive cache locality and ensures allocations and deallocations are highly performant $O(1)$ operations with zero fragmentation.

Compiler Requirements & Safety: The primary danger of frame allocation is pointer escape, where a long-lived object attempts to read overwritten frame memory, causing non-deterministic bugs. To guarantee safety without a GC, the compiler enforces a strict escape analysis (akin to a specialized borrow checker). This guarantees that frame pointers can never be assigned to lifetimes exceeding the current tick.

2. First-Class Spatial Arenas
Objective: Managing macro-level state, large domain groupings, and level-loading lifecycles.

The Mechanism: Spatial arenas are first-class language citizens and serve as the default allocation space for long-lived objects.

Performance Benefits: Entire arenas (e.g., a "Forest Level") can be dropped in a single CPU instruction for $O(1)$ mass deallocation, perfectly aligning with how game states are loaded and unloaded.

Architectural Refinements: While arenas solve traditional memory leaks (forgetting to free a specific object), developers must still manage "logical leaks". For example, infinitely spawning entities into a persistent arena will eventually trigger an Out-of-Memory (OOM) crash. To support dynamic creation and destruction during a level's lifespan, the spatial arenas implement an internal free-list to manage fragmentation.

3. Generational References
Objective: Managing the heavily interconnected "Game Graph" and cross-arena communications where strict borrow checking fails due to unpredictable object mutations and lifetimes.

The Mechanism: Objects are referenced using a Generational ID (a slot-map pattern) rather than direct memory pointers. This ID pairs an index with a generation counter.

Safety and Efficacy: If an entity is destroyed and its memory reused, the generation increments. This cleanly solves the ABA problem (where reassigned memory is mistaken for the original object) and bypasses the overhead of Atomic Reference Counting (ARC).

Validation Check: When dereferencing an ID, the software automatically validates that the array's generation matches the ID's generation. While this requires a minor CPU branch-check overhead, it safely prevents segfaults and returns a safe null/None equivalent if the target is gone. Hardware-level validation is only utilized if compiled for specific architectures supporting memory tagging (like ARM MTE).

Architectural Synergy
By intersecting these three paradigms, it provides a highly cohesive, deeply hacking-friendly philosophy for engine development:
Arenas handle the macro (The World).
Frame handles the micro (The Math).
Generational IDs handle the relationships (The Logic).

This triad completely circumvents the need for a standard Garbage Collector, offering engine developers fine-grained, deterministic control over their memory without exposing them to the catastrophic dangers of manual malloc and free.


# Syntax
1. The Syntax: Pythonic Rust
To eliminate syntactic noise, we strip away the semicolons and curly braces, relying on clean indentation. However, we keep Rust's powerful type inference and immutability-by-default to ensure the code remains robust.

Instead of heavy OOP inheritance (which often leads to rigid, fragile base-class problems in game design), we can use a hybrid approach: Data objects + Behavior implementations, similar to Rust, but with less boilerplate.

```Python
# 'mut' is required to change state. Types are inferred but can be explicit.
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

```
Notice the match statement—Rust's pattern matching is too good to leave behind, but we can make it visually lighter.


# Type System
Star's pitch is a single language spanning small indie titles, retro remakes/throwbacks and emulated retrocomputer systems, and AAA-quality games. Today's type system (`src/types/mod.rs`'s `Ty` enum) covers only `i32`, `f32`, `str`, `bool`, `Vec2`/`Vec3`/`Vec4`, `Mat4`, `List<T>`, `GenRef<T>`, closures, and nominal structs/enums — everything else (`Option`, `Result`, maps, sets) is user-space library code, and there is exactly one integer width and one float width. That is enough for toy programs but not for the three stated tiers, each of which pulls the type system in a different direction. This section lays out the gap and the additions needed to close it. Nothing below is implemented yet — this is the plan to circle back to.

1. Why one type system has to stretch three ways
Retro/emulation demands *exact-width, wrapping* arithmetic: an 8-bit CPU register or a PSG audio channel must overflow silently at 255 -> 0, which is the opposite of Star's current philosophy of trapping overflow as a bug. It also needs indexed/palette color and packed pixel formats, since that's how the hardware being emulated actually stores a frame.

AAA pulls the other way: `f64` for large-world coordinates without precision loss, quaternions to avoid gimbal lock, HDR linear color, and resource handles for GPU/audio assets that fail safely the way `GenRef` already does for despawned entities, plus string interning so per-frame tag/event comparisons across a huge entity count aren't `strcmp`.

Indie mostly needs the connective tissue both extremes assume already exists: `Option`/`Result` as real primitives (not a hand-rolled generic enum copied into every project), `Map`/`Set`, tuples, fixed-size arrays. Unglamorous, but currently entirely absent.

2. Numeric widths and modes
Add `i8`/`u8`/`i16`/`u16`/`u32`/`i64`/`u64`/`f64` alongside today's `i32`/`f32`, plus `char` (a Unicode scalar, distinct from a raw `str` byte). Keep trap-on-overflow as the *default* for signed/unsigned ints — that's a genuine safety property worth keeping — and add two explicit opt-ins rather than a silent global mode change:
- `Wrapping<T>`: silent-overflow arithmetic, for emulating an actual 8/16-bit register or audio-chip counter faithfully.
- `Fixed<Bits, Frac>`: deterministic fixed-point (e.g. `Fixed<32,16>`), for lockstep simulation and rollback netcode where float non-determinism across machines is a correctness bug, not a rounding nit.

3. Compound and collection types
```Python
[T; N]          # fixed-size inline array: tile grids, palettes, register files, vertex layouts
(T, U, ...)     # tuple: lightweight multi-return without declaring a one-off struct
Map<K, V>       # hash map: asset lookup tables, save data, tag indices
Set<T>          # hash set
Table<T>        # struct-of-arrays, complementing arena's array-of-structs for cache-batch AAA systems
Ring<T, N>      # fixed-capacity ring buffer: input replay, frame-time history, netcode rollback buffers
```
`Map`/`Set` are already flagged as a known gap in `todo.md`'s roadmap; fixed-size arrays and tuples are new asks that fall out of the retro/AAA tiers respectively.

4. Text and bytes
`Bytes`, an owned growable byte buffer distinct from `Str`, for asset formats, binary save data, and network payloads that aren't text. `Symbol`, an interned string with O(1) comparison, for entity tags and event names — at AAA entity counts, comparing tags with a byte-for-byte `str` compare every frame is a real cost.

5. Math and geometry
Extending today's `Vec2`/`Vec3`/`Vec4`/`Mat4`:
```Python
Quat                     # quaternion rotation, no gimbal lock
Mat2, Mat3
Rect, Aabb2, Aabb3
Transform                # position + rotation + scale — the de facto universal ECS component
Ray, Plane, Frustum      # physics and culling
Color                    # f32 linear HDR, for AAA lighting pipelines
Color32                  # packed RGBA8, for indie-scale 2D/3D
Palette, PaletteIndex(u8)  # indexed color, for faithful retro console emulation
```

6. Time
`Tick` (integer simulation-step counter, matching `sequence`'s existing tick model), `Duration` (wall-clock, e.g. `i64` nanoseconds), `Instant` (monotonic timestamp). Keeping these distinct from a bare `f32` delta-time avoids the drift and non-determinism bugs that break replay recording and rollback netcode.

7. Resource handles
Generalize the `GenRef<T>` pattern — already generation-checked, already proven safe for arena entities — to engine resources: `Handle<Texture>`, `Handle<Mesh>`, `Handle<Shader>`, `Handle<Sound>`. A freed texture handle used after unload fails the same safe generation-check path `GenRef` already gives despawned entities, instead of segfaulting the renderer. This is a reuse of existing machinery, not a new safety mechanism.

8. Bit-level types
`Flags<E: Enum>`, a typed bitflag set for input state, physics collision layers, and render state. `BitField<N>`, a packed bit register for accurate retro CPU flag-register emulation (e.g. Z80/6502 status flags).

9. `Option`/`Result` as compiler primitives
Promote these from a user-space generic enum (as in the current docs example) to true builtins with `?`-propagation sugar. This matters more as the standard library grows past bare `bool` return codes for file/network I/O.

10. Sequencing
The lowest-effort, highest-value slice is `Option`/`Result` as builtins + `Map`/`Set` + fixed-size arrays — all indie-tier gaps that unblock ordinary programs immediately and require no new codegen primitives beyond what generics/`List<T>` already establish. The numeric-width and `Wrapping`/`Fixed` work is the larger lift, since it touches the lexer, parser, checker, and every arithmetic codegen path, and only pays off once a real retro-emulation or netcode example exists to validate it against.
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
Star's pitch is a single language spanning small indie titles, retro remakes/throwbacks and emulated retrocomputer systems, and AAA-quality games. Today's type system (`src/types/mod.rs`'s `Ty` enum) covers `i32`/`i8`/`u8`/`i16`/`u16`/`u32`/`i64`/`u64`, `f32`/`f64`, `char`, `str`, `bool`, `Vec2`/`Vec3`/`Vec4`, `Mat4`, `List<T>`, `Map<K,V>`/`Set<T>`, `Tuple`/`Array`/`Ring<T,N>`/`Table<T>` (`(T, U, ...)`/`[T; N]`/`Ring<T, N>`/`Table<T>`), `GenRef<T>`/`Handle<T>`, closures, and nominal structs/enums, plus `Option`/`Result` as true compiler-builtin generic enums with `?`-propagation sugar. That covers every item in this section's "indie connective tissue" tier (§3's collection/compound types, §9's `Option`/`Result`) in full, plus §7's resource handles and (as of this round) most of §2's numeric-width gap, and is enough for toy programs plus a good slice of the retro/AAA tiers -- `Wrapping<T>`/`Fixed<Bits,Frac>` (§2's two explicit opt-in modes) and the rest of this section's items still pull the type system in directions today's `Ty` doesn't reach yet. This section lays out the remaining gap and the additions needed to close it; items marked **done** below are implemented and tested (`tests/frontend.rs`), everything else is still the plan to circle back to.

1. Why one type system has to stretch three ways
Retro/emulation demands *exact-width, wrapping* arithmetic: an 8-bit CPU register or a PSG audio channel must overflow silently at 255 -> 0, which is the opposite of Star's current philosophy of trapping overflow as a bug. It also needs indexed/palette color and packed pixel formats, since that's how the hardware being emulated actually stores a frame.

AAA pulls the other way: `f64` for large-world coordinates without precision loss, quaternions to avoid gimbal lock, HDR linear color, and resource handles for GPU/audio assets that fail safely the way `GenRef` already does for despawned entities, plus string interning so per-frame tag/event comparisons across a huge entity count aren't `strcmp`.

Indie mostly needed the connective tissue both extremes assume already exists: `Option`/`Result` as real primitives (not a hand-rolled generic enum copied into every project), `Map`/`Set`, tuples, fixed-size arrays, a ring buffer, a struct-of-arrays table. Unglamorous, but until recently entirely absent — all seven are **done** now (see §3/§9's status below), closing out this tier entirely.

2. Numeric widths and modes -- **the width/`char`/cast part is done; `Wrapping<T>`/`Fixed<Bits,Frac>` are not**
`i8`/`u8`/`i16`/`u16`/`u32`/`i64`/`u64`/`f64` now exist alongside the original `i32`/`f32` as nine new `Ty` variants (`Ty::I8`/`U8`/`I16`/`U16`/`U32`/`I64`/`U64`/`F64`/`Char`), plus `char` (a Unicode scalar, distinct from a raw `str` byte -- lowered to a bare `i32` codepoint, see `Ty::Char`'s doc comment). `i64`/`f64` used to be accepted spellings that silently *aliased* `Ty::Int`/`Ty::Float` (the doc comment on `Checker::resolve_type`'s old code called this out as exactly this section's gap) -- they're genuinely distinct types now. Trap-on-overflow is the default for `+`/`-`/`*` on every one of these explicit-width integer types (via LLVM's `llvm.{s,u}{add,sub,mul}.with.overflow.iN` intrinsics, `Codegen::emit_checked_sized_int_arith`) and `/`/`%` trap on a zero divisor (plus, for a signed width, the lone `MIN / -1` overflow case) exactly like the pre-existing `i32` division guard, generalized to every width/signedness (`Codegen::emit_checked_sized_int_div`) -- **except** `Ty::Int` (`i32`) itself, which deliberately keeps its original silent two's-complement wraparound rather than retroactively changing behavior for a type every existing program already depends on; that gap (an intentional, documented scope cut, not an oversight -- see `Ty::I8`'s doc comment) is exactly where `Wrapping<T>` is still needed. There is no implicit widening between any two distinct numeric types (the original `Int`/`Float` mixed-pair promotion -- `1 + 1.5 == 2.5` -- is the one preserved backward-compatible exception; every other pairing, e.g. `i8 + i64`, is a hard type-mismatch error). Moving a value between widths (or between a numeric type and `char`) requires a new explicit `expr as Type` cast expression (`Expr::Cast`/`TypedExpr::Cast`, a genuinely new, general-purpose grammar production -- `as` previously only appeared in `import "path.star" as alias`), lowered to the appropriate `trunc`/`sext`/`zext`/`sitofp`/`uitofp`/`fptosi`/`fptoui`/`fpext`/`fptrunc` per `Codegen::emit_cast`, mirroring Rust's own infallible truncating `as` (no runtime validation that a cast integer is a valid `char` codepoint, no `Result`-returning fallible-cast path). See `examples/numeric_widths.star`. Still not implemented, and now the two remaining items in this whole section: the two explicit opt-in modes below (`Wrapping<T>`, `Fixed<Bits,Frac>`), and indexed/palette color and packed pixel formats (this section's other retro-tier ask).
- `Wrapping<T>`: silent-overflow arithmetic, for emulating an actual 8/16-bit register or audio-chip counter faithfully.
- `Fixed<Bits, Frac>`: deterministic fixed-point (e.g. `Fixed<32,16>`), for lockstep simulation and rollback netcode where float non-determinism across machines is a correctness bug, not a rounding nit.

3. Compound and collection types
```Python
[T; N]          # fixed-size inline array: tile grids, palettes, register files, vertex layouts -- done
(T, U, ...)     # tuple: lightweight multi-return without declaring a one-off struct -- done
Map<K, V>       # hash map: asset lookup tables, save data, tag indices -- done
Set<T>          # hash set -- done
Table<T>        # struct-of-arrays, complementing arena's array-of-structs for cache-batch AAA systems -- done
Ring<T, N>      # fixed-capacity ring buffer: input replay, frame-time history, netcode rollback buffers -- done
```
`Map<K,V>`/`Set<T>` (linear-scan lookup plus a generated structural-equality function per key/element type, not a hash table yet) landed first — see `examples/map_set.star`. `Tuple`/`Array` landed in the same round as each other: `(T, U, ...)` lowers to an anonymous LLVM literal struct (no `%name` declaration, unlike a nominal `struct`), positional elements read via a dedicated `.0`/`.1`/... `TupleIndex` node (not `Field`, which looks a name up in a *declared* struct); `[T; N]` lowers to a plain inline LLVM array, with the *only* literal form being the `[value; N]` repeat (a new `;` token/`TokenKind::Semi` — the only place the grammar uses one) since a distinct-elements form (`[e1, e2, e3]`) would collide with `List<T>`'s existing bracket literal and this checker has no expected-type propagation to disambiguate the two by context. Both are stored inline (no RC header, no heap allocation of their own) and are structurally hashable — usable as a `Map`/`Set` key/element type — exactly when composed entirely of hashable element types, mirroring a struct. See `examples/tuples_arrays.star`. `Ring<T,N>` landed next: also stored inline (an `{ [N x T], i64, i64 }` of data/head/len — no RC header, no heap allocation, no copy-on-write), like `Array` rather than `List`, but *mutable* through dedicated `push`/`pop` methods instead of being fully populated up front. `N` is written `Ring<T, N>` (angle brackets, alongside the element type argument, unlike `Array`'s `[T; N]`) since this compiler has no general const-generic parameter machinery to reuse — both the type position (`let h: Ring<i32, 3>`) and the `Ring<T, N>()` constructor needed a dedicated parser special case (`Parser::parse_type_inner`/`parse_ring_new`) rather than the ordinary comma-separated-`Type`-list turbofish, since `N` is a bare integer literal, not a `Type`. `push` grows while `len < N`, then evicts the oldest (front) element once full instead of growing (nowhere to grow to) or silently no-op'ing (`List`'s out-of-bounds-write convention) — a full ring always holds a sliding window of the most recent `N` pushes, matching the history-buffer/rollback use case; `pop` removes and returns the oldest element, FIFO-style. Not structurally hashable (no `Map`/`Set` key/element use, matching `List`). See `examples/ring.star`; `crate::codegen::ring`'s module doc comment has the full RC-safety invariant (every slot outside the live `[head, head+len)` window is always the element type's zero value) that lets the ordinary blanket retain/release walk stay correct with no length-aware special-casing. `Table<T>` landed last, closing out this section's "indie connective tissue" list: unlike every type above, `T` is a plain declared `struct` reflected over at codegen time (`Codegen::struct_field_types`) to lay out one parallel growable column per field instead of reusing a single-buffer storage shape wholesale — the payload is `{ i64 len, i64 cap, F0*, F1*, ... }`, one pointer per field of `T` in declaration order, all growing/shrinking in lockstep behind one shared `len`/`cap` pair. Lowered to the same reference-counted, copy-on-write `i8*` object pointer scheme as `List<T>`/`Map<K,V>`/`Set<T>` (unlike `Array`/`Ring`'s inline storage) — `Table<T>()`/method calls piggyback on the exact same generic-turbofish-plus-`StructLit` machinery those three already established (`Type::Generic("Table", [T])`, no dedicated AST node), since `Table<T>` (unlike `Ring<T,N>`) has only one type argument, a plain `Type`. `push`/`pop`/`len`/`table[i]`/`table[i] = v` mirror `List<T>`'s method surface and fails-safe OOB conventions exactly, just decomposing the whole element into (or reassembling it from) every column instead of touching one buffer slot. One accepted gap: there is no dedicated place-projection support for a single field through a table index, since a `Table<T>` element's fields live in independent column buffers with no single contiguous address to GEP a field offset out of — rather than let `table[i].field = v` silently target a disconnected temporary (the naive fallback's behavior, and still what happens for any other rvalue struct base with no addressable storage of its own, e.g. a function's returned-by-value struct), the checker rejects it outright (`Checker::writes_through_table_index`, checked at both `Stmt::Assign` and any mutating collection-method receiver, e.g. `table[i].tags.push(x)`) with a diagnostic pointing at `table[i] = v` instead; `table[i] = v` (the whole element) and `table[i].field` (a *read*) both work correctly. See `examples/table.star`; `crate::codegen::table`'s module doc comment has the full column-layout rationale.

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

7. Resource handles -- **done**
Generalize the `GenRef<T>` pattern — already generation-checked, already proven safe for arena entities — to engine resources: `Handle<Texture>`, `Handle<Mesh>`, `Handle<Shader>`, `Handle<Sound>`. A freed texture handle used after unload fails the same safe generation-check path `GenRef` already gives despawned entities, instead of segfaulting the renderer. This is a reuse of existing machinery, not a new safety mechanism: `Ty::Handle(Box<Ty>)` lowers to the exact same `%GenRef = type { i32, i32 }` layout and the exact same arena-backed construction/dereference codegen (`Codegen::emit_genref_create`/`emit_genref_index`/`emit_genref_index_place`) as `Ty::GenRef` -- same `arena Name: T` backing declaration, same `spawn`/`despawn` lifecycle, same stale/OOB "safe zero value" fallback. The only new work is at the front end: `Handle<T>(value)` parses through the identical special-cased grammar `GenRef<T>(value)` already needed (`Expr::GenRefCreate` gained an `is_handle` flag rather than a second AST node, since every downstream pass that doesn't care about the distinction already matched on `{ .. }`), and `Ty::Handle` is a genuinely distinct nominal type from `Ty::GenRef` -- a function declared to take `Handle<Texture>` rejects a `GenRef<Texture>` argument and vice versa, even though they're byte-identical at runtime, so a resource handle can never be silently swapped for an unrelated entity reference. See `examples/handle_resource.star`.

8. Bit-level types
`Flags<E: Enum>`, a typed bitflag set for input state, physics collision layers, and render state. `BitField<N>`, a packed bit register for accurate retro CPU flag-register emulation (e.g. Z80/6502 status flags).

9. `Option`/`Result` as compiler primitives -- done
Promoted from a user-space generic enum (as the docs example used to show) to true builtins: `Checker::check` synthesizes and registers the `Option<T>`/`Result<T,E>` generic-enum templates as if they'd been parsed from source (`src/types/mod.rs`'s `builtin_generic_enums`) before any user code is scanned, and `expr?` desugars to a `match` over their `Some`/`None`/`Ok`/`Err` variants with early `return` (`Expr::Try`) — there is no dedicated codegen path for `?` at all, just the ordinary generated `match`/enum machinery.

10. Sequencing
The lowest-effort, highest-value slice — `Option`/`Result` as builtins + `Map`/`Set` + tuples + fixed-size arrays, all indie-tier gaps that unblock ordinary programs immediately and required no new codegen primitives beyond what generics/`List<T>`/nominal structs already established — is now **done**. `Ring<T,N>` (fixed-capacity ring buffer) is now **done** too, a straightforward extension of patterns this compiler already has (`Array`'s inline no-RC-header storage, `List`'s `push`/`pop` method shape). `Table<T>` (struct-of-arrays) is now **done** as well, closing out this section's indie-tier list entirely: a bigger lift than `Ring<T,N>` was, since `T` is generically a *struct* type whose fields needed to be reflected over at codegen time (`Codegen::struct_field_types`) to lay out one parallel growable column per field, rather than reusing an existing single-buffer storage shape wholesale — but it reuses `List<T>`'s reference-counted, copy-on-write `i8*` object-pointer scheme wholesale (unlike `Ring<T,N>`'s inline storage), and — unlike `Ring<T,N>`, which needed a dedicated parser/AST node since its `N` is a bare integer literal — `Table<T>` has only one type argument, a plain `Type`, so `Table<T>()`/method calls piggyback on the exact same generic-turbofish-plus-`StructLit` machinery `List<T>`/`Map<K,V>`/`Set<T>` already established, with zero parser or AST changes. Resource handles (`Handle<T>`, §7) are now **done** too: the smallest of the remaining items, since it's a pure front-end generalization of machinery §1's `GenRef<T>`/arena work already built and proved safe -- no new codegen, no new runtime representation, just a second nominal wrapper type sharing the same generation-check path. §2's numeric-width/`char`/cast work turned out to be the largest single lift this section has seen -- it touched the lexer (a new `'c'` char-literal token), the parser (a new `as`-cast grammar production, the first new binary-operator-precedence-tier addition since the original grammar), the checker (nine new `Ty` variants, a generalized "any numeric type" predicate replacing the old `Int`/`Float`-only one, and a new cast-legality check), and every arithmetic codegen path (`Codegen::emit_scalar_binop` now dispatches to a width/signedness-generic sized-integer path with real overflow-trap intrinsics, not just the original `i32`-only opcodes) -- and is now **done**, per §2's own entry above; `Wrapping<T>`/`Fixed<Bits,Frac>` (the two explicit opt-in modes trap-on-overflow needs *not* to be the only option) are the two items that lift left unaddressed, and are now the largest remaining lift in this whole section, since each needs its own new generic wrapper type with codegen that deliberately does *not* go through the trap-on-overflow path this round just built.
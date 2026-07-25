1. Native Data-Oriented Concurrency (swarm)
Modern game engines thrive on Entity Component System (ECS) architectures to maximize CPU cache utilization. Since Star's spatial arenas naturally manage macro-level state, we introduce the swarm (or par) keyword to make parallel iterations over these arenas safe and syntactically clean.

The Abstraction: Replaces manual thread pools and mutexes with explicit, ECS-mapped component array threading.

Safety & Pragmatism: Proving disjoint memory access statically essentially brushes up against the halting problem. Therefore, safety is guaranteed through strict, compiler-enforced read/write declarations.

Compile-Time Locks: The compiler simply forbids a swarm loop if another system has requested a mutable lock on the same component array in the current tick. (Implemented -- see `docs/language_reference.md`'s "Cross-System Scheduling (`system`/`parallel`)" section: named `system`s declare which arenas they read/write, a `parallel:` block runs a set of them concurrently on the `par`/`swarm` worker pool, and the compiler rejects the block if two listed systems declare a conflicting, >= 1 mutable, lock on the same arena.)

2. Tick-Aware Coroutines (sequence)
Standard OS-level async/await is designed for I/O network operations and is highly detrimental to a deterministic, tick-based game loop. Star introduces the sequence keyword, tailored specifically for multi-frame gameplay logic.

The Abstraction: Automates manual state machines, switch statements, and timer variables directly into a clean coroutine syntax.

Frame-Bound Yields: Yielding is directly bound to frame counts (e.g., waiting 30 frames to spawn a hitbox), providing brilliant domain-specific utility.

Technical Implementation: The compiler strips the sequence function and hoists its local variables into a struct.

Memory Integration: This struct is automatically allocated into a lightweight spatial arena to persist across yields.

Execution: Resumption of the coroutine is handled by generating a fast switch statement based on an internal state variable.

3. First-Class SIMD and Math Types
Game math must execute at hardware speeds. Star incorporates native GLSL-style vectors and matrices into a general-purpose systems language, vastly improving readability for graphics and physics math.

The Abstraction: Provides native vec2, vec3, vec4, and mat4 types complete with GLSL-style swizzling (e.g., vector.xyz).

Operator Overloading: Hides manual SIMD intrinsics (like _mm_add_ps) behind standard overloaded operators like + and *. (User-defined structs can overload the same operators too, via `Add`/`Sub`/`Mul`/`Div`/`Rem`/`Eq`/`Ord`/`Neg` traits -- see `docs/language_reference.md`'s "Operator Overloading" section; the vector/matrix types below get theirs from dedicated compiler-internal lowering rather than that trait mechanism, since they need to compile straight to native SIMD instructions.)

Technical Viability: Relies on Clang's ext_vector_type or GCC's native vector extensions in the backend.

Hardware Mapping: The compiler strictly handles ABI alignment rules (ensuring vec4 is 16-byte aligned) and automatically emits optimal SSE/AVX or ARM NEON instructions.

4. Compile-Time Reflection for Hot-Reloading
Iterative velocity is the lifeblood of game design, and standard serialization is too slow. Star uses memory-poking as a low-overhead solution to hot-reloading data.

The Abstraction: Developers use an @export or @tweakable decorator above variables, entirely bypassing the boilerplate of custom JSON parsers.

Build-Step Generation: During the build step, the compiler emits a metadata dictionary or C-struct containing offsetof(Struct, field) alongside type identifiers.

Editor Integration: An external editor reads this metadata to establish an IPC connection or shared memory mapping with the running game.

Safety: This allows external tools to instantly and safely overwrite raw bytes of targeted variables in real-time without risking a segfault.
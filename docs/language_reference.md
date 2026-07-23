# Star Language Reference Guide

## Overview

Star is a game programming language with Pythonic-Rust syntax, featuring unique memory management models tailored for high-performance game development. It targets native executables via LLVM IR compilation.

**Key Design Principles:**
- **Syntax**: Python-style indentation, Rust-style type inference, pattern matching, and immutability-by-default
- **Memory**: Three-tier model — `frame` bump allocators for ephemeral data, spatial `arena`s for level-scoped state, and generational references for cross-arena communication
- **Concurrency**: `swarm`/`par` for safe parallel ECS iteration; `sequence` for tick-aware coroutines
- **Math**: Native `vec2`/`vec3`/`vec4`/`mat4` types with GLSL-style swizzling

---

## Basic Syntax

### Program Structure

Star programs use Python-style indentation to define blocks. A program consists of top-level declarations:

```star
# Comments start with #

fn main():
    # Entry point - must exist
    print("Hello, Star!")

struct Point:
    x: f32 = 0.0
    y: f32 = 0.0
```

### Comments

Comments begin with `#` and continue to the end of the line:
```star
# This is a comment
x = 5  # Inline comments are also supported
```

---

## Data Types

### Primitive Types

| Type | Description |
|------|-------------|
| `i32` | 32-bit signed integer |
| `f32` | 32-bit floating point number |
| `bool` | Boolean (`true` or `false`) |
| `str` | String type |

### Vector Types

Star provides native SIMD vector types with GLSL-style swizzling:

| Type | Description |
|------|-------------|
| `Vec2` | 2D vector with `.x`, `.y` components |
| `Vec3` | 3D vector with `.x`, `.y`, `.z` components |
| `Vec4` | 4D vector with `.x`, `.y`, `.z`, `.w` components |
| `Mat4` | 4x4 matrix for transformations |

**Swizzling:**
```star
let v = Vec3(1.0, 2.0, 3.0)
let swizzled = v.zyx  # Creates Vec3(3.0, 2.0, 1.0)
```

---

## Variables and Mutability

### Variable Declaration

Variables are declared with `let`. Types are inferred when not specified:

```star
let x = 42           # Inferred as i32
let y: f32 = 3.14    # Explicit type
let mut z = 10       # Mutable variable
```

### Assignment

```star
let mut health = 100
health = 80          # Simple assignment
health -= 20         # Compound assignment
```

### Top-Level Constants

`const NAME: Type = <expr>` declares a named constant at module scope --
unlike `let`, it's legal outside a function body (alongside `struct`/`fn`/
`arena`/etc.) and its type annotation is required. `<expr>` must be a
constant expression: a literal, a unary/binary operator over other constant
expressions, a numeric cast, or a reference to another `const` -- in any
declaration order, including forward references and references across an
`import`. It's evaluated once at compile time and inlined at every use site;
there is no runtime global behind it.

```star
const COLS: i32 = 32
const ROWS: i32 = 24
const CELL_SIZE: i32 = 20
const BOARD_CELLS: i32 = COLS * ROWS   # forward/cross references are fine

fn board_width() -> i32:
    COLS * CELL_SIZE
```

Anything that isn't reducible to a compile-time literal (a function call, a
field access, a collection literal, ...) is rejected with a diagnostic at
the point it fails to fold, not silently accepted. See
`examples/top_level_const.star`.

---

## Control Flow

### If/Else Statements

```star
if x > 0:
    print("positive")
else:
    print("non-positive")
```

If can be used as an expression:
```star
let result = if x > 0: "pos" else: "neg"
```

### While Loops

```star
let mut n = 0
while n < 10:
    print(f"n = {n}")
    n += 1
```

While loops support optional else blocks:
```star
while condition:
    # loop body
else:
    # executes when loop exits normally (not via break)
```

### For Loops

```star
for i in 0..10:
    print(f"i = {i}")
```

Range is exclusive on the upper bound.

### Break and Continue

```star
for i in 0..100:
    if i == 50:
        break       # Exit the loop
    if i % 2 == 0:
        continue  # Skip to next iteration
```

### Match Expressions

Match provides pattern matching similar to Rust:

```star
match value:
    <= 0 -> print("non-positive")
    _    -> print("positive")

match shape:
    Shape::Circle(r) -> return 3 * r * r
    Shape::Rect(w, h) -> return w * h

match option:
    Option::Some(v) -> v
    Option::None -> -1
```

---

## Functions

### Function Definition

```star
fn add(a: i32, b: i32) -> i32:
    return a + b

fn greet(name: str):
    print(f"Hello, {name}!")
```

Functions with no return value implicitly return `()`. The `main` function must return `i32` and implicitly returns 0.

### Return Values

```star
fn multiply(a: i32, b: i32) -> i32:
    a * b  # Implicit return (trailing expression)

fn early_exit(n: i32) -> i32:
    if n < 0:
        return 0
    n * 2
```

---

## Structs

### Struct Definition

```star
struct Vec3:
    x: f32 = 0.0
    y: f32 = 0.0
    z: f32 = 0.0

struct Player:
    mut health: i32 = 100
    position: Vec3 = Vec3(0, 0, 0)
    name: str
```

### Struct Literal

```star
let p = Player(health = 100, position = Vec3(0, 0, 0), name = "Hero")
let v = Vec3(1.0, 2.0, 3.0)
```

Arguments may be positional (filling fields in declaration order), named
(`field = value`, in any order), or a positional prefix followed by named
arguments — a positional argument after a named one is an error, as are
unknown and duplicate field names. Any field omitted entirely falls back to
its declared default; omitting a field with no default is a compile error:

```star
let d = Player(name = "NPC")          # health/position from their defaults
let q = Player(50, name = "Grunt")    # positional prefix fills health
```

The same rules apply to enum-variant payload fields and to `spawn Arena(...)`
(which constructs the arena's element struct). Ordinary function and method
calls do not accept named arguments — their parameters match positionally.

### Field Access

```star
print(f"Health: {p.health}")
p.health = 80  # Mutating mutable field
```

---

## Enums

### Enum Definition

```star
enum Direction:
    North
    South
    East
    West

enum Shape:
    Circle(radius: i32)
    Rect(width: i32, height: i32)
```

`Option<T>` and `Result<T, E>` are compiler builtins (see [Generics](#generics)
below) -- they're always available and never need to be declared.

### Enum Variants

```star
let d = Direction::North
let some_int = Option<i32>::Some(5)
let none = Option<i32>::None
```

---

## Generics

### Generic Structs

```star
struct Box<T>:
    value: T
```

### `Option<T>` and `Result<T, E>`

`Option<T>` and `Result<T, E>` are pre-registered generic enums built into the
compiler -- functionally identical to a hand-declared generic `enum`, but
always available without declaring them yourself (and a module that tries to
declare its own `enum Option<T>`/`enum Result<T, E>` gets a "declared more
than once" error, the same as redeclaring any other name):

```star
enum Option<T>:
    None
    Some(value: T)

enum Result<T, E>:
    Ok(value: T)
    Err(error: E)
```

### Generic Functions

```star
fn identity<T>(x: T) -> T:
    x

fn unwrap_or<T>(o: Option<T>, default: T) -> T:
    match o:
        Option::Some(v) -> return v
        Option::None -> return default
```

### `?`-propagation

A postfix `?` on an `Option<T>`/`Result<T, E>` expression unwraps the
"success" variant (`Some(v)`/`Ok(v)`) to `v`, or immediately `return`s the
"empty" variant (`None`/`Err(e)`) unchanged out of the enclosing function --
no explicit `match` needed at the call site. The enclosing function's
declared return type must be the exact same `Option`/`Result` instantiation
(Star has no `From`/`Into` conversions to reconcile, say, a `Result<i32, i32>`
being propagated out of a function returning `Result<i32, str>`):

```star
fn safe_div(a: i32, b: i32) -> Result<i32, i32>:
    if b == 0:
        return Result<i32, i32>::Err(1)
    Result<i32, i32>::Ok(a / b)

fn checked_double(a: i32, b: i32) -> Result<i32, i32>:
    let h = safe_div(a, b)?
    Result<i32, i32>::Ok(h * 2)
```

---

## Traits and Implementations

### Trait Definition

```star
trait Damageable:
    fn take_damage(mut self, amount: i32)
```

### Implementing Traits

```star
impl Damageable for Player:
    fn take_damage(mut self, amount: i32):
        self.health -= amount
        match self.health:
            <= 0 -> print(f"{self.name} has perished.")
            _    -> print(f"Health critical: {self.health}")
```

### Inherent Methods

```star
impl Player:
    fn remaining_health(self) -> i32:
        self.health
```

---

## Closures

### Closure Syntax

```star
let add_one = fn(x: i32) -> i32: x + 1

fn apply_twice(f: Fn(i32) -> i32, x: i32) -> i32:
    f(f(x))

# Capturing variables by value
let base = 10
let add_base = fn(x: i32) -> i32: x + base
```

### Void Closures

```star
let say_hi = fn(): print("hi from a closure")
say_hi()
```

---

## Lists

### List Creation and Operations

```star
let mut nums: List<i32> = [1, 2, 3]
let empty: List<i32> = List<i32>()

# Operations
nums.len()        # Get length
nums.push(4)      # Append element
let v = nums[0]   # Access element
nums[0] = 100     # Modify element
let popped = nums.pop()  # Remove and return last element
```

---

## Maps and Sets

### `Map<K, V>`

```star
let mut ages: Map<str, i32> = Map<str, i32>()
ages.insert("alice", 30)   # insert or overwrite
ages.insert("bob", 25)

match ages.get("alice"):   # -> Option<V>
    Option::Some(v) -> println(f"alice: {v}")
    Option::None -> println("alice: missing")

ages.contains("bob")       # -> bool
ages.remove("bob")         # -> Option<V>, the removed value if present
ages.len()                 # -> i32
```

### `Set<T>`

```star
let mut tags: Set<i32> = Set<i32>()
tags.insert(1)     # -> bool, true if newly inserted
tags.insert(1)     # -> false, already present
tags.contains(1)   # -> bool
tags.remove(1)     # -> bool, true if it was present
tags.len()         # -> i32
```

### Key/element type restrictions

A `Map`/`Set` key or element type must be *structurally hashable*: `i32`,
`f32`, `bool`, `str`, a fieldless `enum`, `Vec2`/`Vec3`/`Vec4`, or a `struct`
composed entirely of such fields (recursively). Payload-carrying enums,
`GenRef<T>`, `List<T>`, `Map<K,V>`, `Set<T>`, closures, and `ptr` are not
supported as key/element types today, and are rejected at compile time.

There is no hashing/bucketing yet: `insert`/`get`/`remove`/`contains` are all
`O(n)` in the current size, comparing against each stored key/element with a
generated structural-equality function rather than a hash table. This is a
deliberate first-cut scope decision (see `docs/design.md`) that fully
supports arbitrary hashable key/element types today, including nested
structs, without needing a hash function at all -- a real hash table is a
purely internal follow-up optimization that would not change any of the
syntax or semantics documented above.

---

## F-Strings

F-strings provide formatted string interpolation:

```star
let name = "Hero"
let health = 100
print(f"Name: {name}, Health: {health}")

# Nested expressions
print(f"Remaining: {p.remaining_health()}")
```

---

## Modules

### Importing Modules

```star
import "geometry_lib.star" as geo

# Use qualified names
let p = geo::Point(3, 4)
let area = geo::area(geo::Shape::Circle(2))
```

---

## Game-Specific Features

### Memory Models

Star provides three memory management paradigms for game development:

#### 1. Frame Memory (Temporal Allocations)

The `frame` keyword introduces an implicit bump allocator that resets at the end of each tick:

```star
fn calculate_path(start_x: i32) -> i32:
    frame:
        let node1 = Point(0, 0)
        let node2 = Point(start_x, start_y)
        # These values are ephemeral - automatically cleaned up
        node1.x + node2.y
```

**Use Cases:** Path-finding nodes, intermediate calculations, transient states.

**Safety:** The compiler enforces escape analysis to prevent frame pointers from escaping to longer-lived storage.

#### 2. Spatial Arenas

Arenas are first-class citizens for long-lived state:

```star
arena Enemies: Enemy
arena Projectiles: Projectile
arena Bullets: Bullet = 4096  # override the default 1024-element capacity

fn spawn_enemy(hp: i32):
    spawn Enemies(hp)  # Create new entity in arena

# Iterate over arena elements
par e in Enemies:
    e.hp -= 1
```

**Features:**
- O(1) mass deallocation when unloading levels
- Internal free-list for dynamic creation/destruction during gameplay
- Capacity of 1024 elements by default, overridable per arena with
  `arena Name: Type = N` (runtime warning, printed once per arena, on
  overflow — see "Arena Limitations" below)

#### 3. Generational References (GenRef)

GenRef provides safe cross-arena references using a slot-map pattern:

```star
fn create_reference(idx: i32) -> GenRef<Point>:
    GenRef<Point>(idx)

fn follow_reference(gen_ref: GenRef<Point>) -> i32:
    gen_ref[0].x  # Safe dereference with validation
```

**Safety:** 
- Combines an index with a generation counter
- Validates generation on each dereference to prevent stale references
- Never-spawned slots return zero values instead of segfaulting

---

### Parallel Iteration (`par`/`swarm`)

Star provides safe parallel ECS-style iteration:

```star
struct Enemy:
    mut hp: i32

arena Enemies: Enemy

fn main():
    spawn Enemies(10)
    spawn Enemies(20)
    spawn Enemies(30)
    
    # Parallel iteration - safe concurrent access
    par e in Enemies:
        e.hp -= 1
    
    # swarm is an alias for par
    swarm e in Enemies:
        print(f"hp: {e.hp}")
```

**Safety Guarantees:**
- Compiler proves iterations are disjoint
- Workers only mutate their loop variable's fields
- Uses a persistent 4-worker thread pool for efficiency

Because a `par`/`swarm` body genuinely runs across worker threads, it may
never call anything that touches SDL's shared window/renderer state or its
global input-event queue (`window_create`, `clear_screen`, `draw_pixel`,
`draw_rect`, `draw_line`, `present`, `key_down`, `mouse_x`, `mouse_y`,
`mouse_button_down`, ...) — concurrent calls into those crash SDL itself, not
just Star-level state. Use `each` (below) for a loop that needs to draw.

### Sequential Arena Iteration (`each`)

`each` iterates an arena's live elements one at a time on the calling
thread — no worker-pool dispatch, so none of `par`/`swarm`'s restrictions
apply:

```star
arena Enemies: Enemy

fn main():
    spawn Enemies(10)
    spawn Enemies(20)

    # Sequential, single-threaded - free to call SDL drawing builtins and
    # to read/mutate anything else already in scope.
    each e in Enemies:
        draw_rect(window, e.x as i32, e.y as i32, 16, 16, Color32(255, 255, 255, 255))
```

**Characteristics:**
- Runs in loop-variable order, once per live element, on the current thread
- No disjointness restrictions: may call any function (SDL builtins
  included) and freely mutate captured outer state
- Supports `break`/`continue` like any other loop
- Cannot be nested inside a `par`/`swarm` body (it would then run its whole
  sequential scan concurrently on every worker thread)

#### Conditional reclamation during a scan

`each item, idx in ArenaName:` optionally binds a second name to the
current element's raw slot index (`i32`), so the body can `despawn
ArenaName[idx]` — the standard "scan every entity, despawn the ones
matching a runtime condition" pattern (expired particles, dead enemies,
finished timers). `despawn` is banned inside `par`/`swarm` (concurrent
generation bumps aren't disjoint across worker threads), but `each` runs
sequentially on the calling thread, so there's nothing unsafe about it:

```star
arena Particles: Particle

fn reclaim_dead_particles():
    each p, i in Particles:
        if p.life <= 0.0:
            despawn Particles[i]
```

---

### Tick-Aware Coroutines (`sequence`)

Sequences provide coroutines bound to frame ticks:

```star
sequence Countdown(start: i32):
    let mut n: i32 = start
    print(f"tick: {n}")
    n -= 1
    yield
    print(f"tick: {n}")
    n -= 1
    yield
    print(f"tick: {n}")
    n -= 1
    print(f"liftoff!")

fn main():
    let mut c = Countdown(3)
    let mut running = true
    while running:
        running = c.resume()  # Returns false when done
    print("sequence done")
```

**Characteristics:**
- Automatically transforms into state-holding struct
- `yield` suspends until next tick
- Top-level locals must have explicit type annotations

---

### Spawn and Despawn

Create and destroy arena entities:

```star
arena Enemies: Enemy

fn main():
    spawn Enemies(100)           # Create entity with 100 HP
    spawn Enemies(200)
    
    despawn Enemies[0]           # Remove entity at index 0
    
    spawn Enemies(50)            # Reuses freed slot (free-list)
```

---

### Built-in Math Functions

```star
# Vector operations
let a = Vec3(1.0, 0.0, 0.0)
let b = Vec3(0.0, 1.0, 0.0)
print(f"dot: {dot(a, b)}")

let v = Vec3(3.0, 4.0, 0.0)
print(f"length: {length(v)}")

# Interpolation
print(f"lerp: {lerp(0.0, 10.0, 0.5)}")
print(f"lerp vec: {lerp(a, b, 0.5)}")

# Clamping
print(f"clamp: {clamp(15, 0, 10)}")

# Random numbers
rand_seed(42)
let r = rand()         # Random float in [0, 1)
let ri = rand_range(10, 20)  # Random int in [min, max)
```

| Function | Description |
|----------|-------------|
| `dot(a, b)` | Dot product of two vectors |
| `length(v)` | Length/magnitude of a vector |
| `lerp(a, b, t)` | Linear interpolation |
| `clamp(v, min, max)` | Clamp value to range |
| `rand_seed(seed)` | Seed the RNG |
| `rand()` | Random f32 in [0, 1) |
| `rand_range(min, max)` | Random i32 in [min, max) |

---

## Standard Library Functions

### I/O

```star
print("message")      # No trailing newline
println("message")    # With trailing newline
print(f"x: {x}")     # F-string interpolation

let name = read_line()  # Read one line from stdin (trailing newline
                         # stripped); an empty str at EOF
```

### String Operations

```star
len("hello")                    # String length
len(my_string)                   # Also works on variables
concat("hello", ", world")       # String concatenation
"abc" == other                   # Structural equality (and !=);
                                 # ordering (<, >, ...) is not defined for str

str_contains("hello world", "wor")      # true -- substring search
str_starts_with("hello", "he")          # true
str_ends_with("hello", "lo")            # true
str_index_of("hello world", "wor")      # 6 -- byte offset, or -1 if not found

str_trim("  padded  ")                  # "padded" -- strips leading/trailing
                                         # space/tab/newline/CR
str_replace("a-b-c", "-", "/")          # "a/b/c" -- every non-overlapping
                                         # occurrence, left to right

let parts = str_split("a,b,,c", ",")    # List<str>: ["a", "b", "", "c"]
str_join(parts, "|")                    # "a|b||c" -- str_split's inverse
```

An empty `needle`/`prefix`/`suffix` always matches (mirroring C's `strstr`);
an empty `old` in `str_replace` and an empty separator in `str_split` are
each a documented no-op (returning `s` unchanged, and a single-element list
holding all of `s`, respectively) rather than looping forever with nothing to
advance past.

### Math Operations

```star
sqrt(16.0)    # Square root
pow(2.0, 10.0) # Power
abs(-5)        # Absolute value
abs(-5.5)      # Works on floats too
floor(3.75)    # Floor
ceil(3.25)     # Ceiling
min(a, b)      # Minimum
max(a, b)      # Maximum

# Trig, exponential, logarithm -- all take/return `float` (an `int`
# argument is promoted), lowered to LLVM's target-independent float
# intrinsics (no extra linker flags needed, same as the functions above)
sin(angle)     # Sine
cos(angle)     # Cosine
tan(angle)     # Tangent
asin(x)        # Arcsine
acos(x)        # Arccosine
atan(x)        # Arctangent
atan2(y, x)    # Arctangent of y/x, using the sign of both to pick the quadrant
exp(x)         # e^x
exp2(x)        # 2^x
log(x)         # Natural logarithm
log2(x)        # Base-2 logarithm
log10(x)       # Base-10 logarithm
```

---

## Reflection Decorators

Star supports compile-time reflection for hot-reloading:

```star
struct Player:
    @export mut health: i32 = 100
    @tweakable speed: f32 = 5.0
    name: str = "Hero"
```

- `@export`: Marks field for hot-reloading
- `@tweakable`: Marks field as runtime-tweakable

---

## Operators

### Arithmetic

| Operator | Description |
|----------|-------------|
| `+` | Addition |
| `-` | Subtraction |
| `*` | Multiplication |
| `/` | Division |
| `%` | Modulo |

Compound assignment operators: `+=`, `-=`, `*=`, `/=`

### Comparison

| Operator | Description |
|----------|-------------|
| `==` | Equal |
| `!=` | Not equal |
| `<` | Less than |
| `>` | Greater than |
| `<=` | Less than or equal |
| `>=` | Greater than or equal |

### Logical

| Operator | Alternative | Description |
|----------|-------------|-------------|
| `&&` | `and` | Short-circuiting AND |
| `\|\|` | `or` | Short-circuiting OR |
| `!` | `not` | Logical NOT |

---

## Compilation Toolchain

### Commands

```bash
star check <file>       # Lex, parse, type-check, report diagnostics
star build <file>       # Full pipeline → native executable
star emit tokens <file> # Dump the token stream
star emit ast <file>    # Dump the parsed AST
star emit llvm <file>   # Dump the generated LLVM IR
```

### Requirements

- Rust toolchain (edition 2024)
- Clang/LLVM on PATH or at `E:\LLVM\bin\clang.exe`

---

## Common Patterns

### Entity Component System

```star
arena Entities: Entity

struct Entity:
    mut x: f32
    mut y: f32
    mut health: i32

# Update system - parallel iteration
par e in Entities:
    e.x += 1.0
    e.y += 1.0

# Render system - sequential, since it draws to the shared window (`par`/
# `swarm` ban SDL calls outright; see "Sequential Arena Iteration" above)
each e in Entities:
    draw_rect(window, e.x as i32, e.y as i32, 16, 16, Color32(255, 255, 255, 255))
```

### Windowing / Graphics / Input

SDL2-backed: `window_create`/`window_destroy`/`window_should_close` for the
window lifecycle, `clear_screen`/`draw_pixel`/`draw_rect`/`draw_line`/
`present` for a 2D immediate-mode framebuffer, `key_down`/`mouse_x`/
`mouse_y`/`mouse_button_down` for input polling, `delay`/`ticks` for frame
timing. See `examples/graphics.star` for a complete bouncing-square program.
Building a program that calls any of these needs SDL2 linked explicitly
(SDL2 is vendored under `sdl/` at the repo root, not installed system-wide):

```bash
star build examples/graphics.star -L sdl/lib/x64 -l SDL2
```

`sdl/lib/x64/SDL2.dll` must also be next to the built `.exe` (or on `PATH`)
to run it.

```star
fn main():
    let w = window_create("My Game", 640, 480)
    if is_null(w):
        return
    while true:
        if window_should_close(w):
            break
        if key_down(41):  # SDL_SCANCODE_ESCAPE
            break
        clear_screen(w, Color32(20, 20, 30, 255))
        draw_rect(w, 100, 100, 40, 40, Color32(80, 180, 255, 255))
        present(w)
        delay(16)
    window_destroy(w)
```

Audio playback and gamepad input are still open (`todo.md` #4).

### Sequential Animations

```star
sequence FlashDamage(w: ptr):
    clear_screen(w, Color32(200, 30, 30, 255))
    present(w)
    delay(100)
    yield
    clear_screen(w, Color32(20, 20, 30, 255))
    present(w)

fn main():
    let w = window_create("flash", 320, 240)
    let mut anim = FlashDamage(w)
    let mut running = true
    while running:
        running = anim.resume()
    window_destroy(w)
```

### Frame-Temporary Calculations

```star
fn astar(start: Point, goal: Point) -> List<Point>:
    frame:
        let mut open_set: List<Point> = [start]
        let mut closed_set: List<Point> = List<Point>()
        # Large temporary allocations here are automatically cleaned up
        # after each tick when the frame block exits
        # ... pathfinding logic ...
```

---

## Language Limitations

### Sequence Restrictions

- `yield` is only supported at the top level of a sequence body
- Nested `yield` inside `if`, `while`, or `frame` is not allowed
- Top-level `let` declarations in sequences require explicit type annotations

### Arena Limitations

- Default capacity of 1024 elements per arena, overridable per arena with
  `arena Name: Type = N` (an integer literal), up to a hard ceiling of
  1,000,000 elements
- Spawning beyond capacity still drops the entity, but now warns at
  runtime only once per arena (naming that arena's actual configured
  capacity) rather than repeating the warning on every further overflow

---

## Examples Directory

The `examples/` directory contains working demonstrations:

| File | Description |
|------|-------------|
| `player.star` | Basic structs, traits, match, f-strings |
| `spawn.star` | Arena population and iteration |
| `swarm.star` | Parallel iteration |
| `each_index_despawn.star` | Conditionally reclaiming arena slots during a scan (`each item, idx in ...`) |
| `arena_capacity_configurable.star` | Overriding an arena's default capacity (`arena Name: Type = N`) |
| `sequence.star` | Coroutines |
| `vecmath.star` | Vector math and swizzling |
| `math_builtins.star` | Built-in math functions |
| `control_flow.star` | If/for/while/break/continue |
| `generics.star` | Generic types and functions |
| `option_result.star` | Builtin `Option`/`Result`, `?`-propagation, payload enums |
| `map_set.star` | `Map<K,V>`/`Set<T>`, including a struct element type |
| `closures.star` | Lambda expressions |
| `memory_models.star` | Frame/Arena/GenRef demonstration |
| `modules_main.star` | Module imports |
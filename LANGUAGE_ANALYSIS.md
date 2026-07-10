# Star Language & Compiler Analysis

*A technical audit of the Star front-end/codegen (commit `03390dc`), covering
correctness bugs, general-purpose-programming gaps, the frame/arena/GenRef
memory model, codegen quality, and game/graphics ergonomics. Every finding
below was either read directly from `src/` or reproduced with a minimal
`.star` program compiled and executed with the current `target/release/star.exe`.*

## Executive summary

Star's front-end (lexer/parser/diagnostics) is genuinely well built — good
spans, typo suggestions, 225 passing tests, clean architecture across
`src/types`/`src/codegen`. The gap is between that polish and what actually
gets *checked* and *guaranteed*. Four findings are memory-safety violations
of guarantees the language explicitly advertises as its core sell (§3.1,
§3.3, §3.5): a closure can smuggle a dangling frame pointer past escape
analysis with zero diagnostics, the frame bump buffer has no capacity
check at all, `GenRef` dereference of a never-spawned slot segfaults
despite a documented "never segfaults" guarantee, and the `par`/`swarm`
`spawn`/`despawn` safety ban is bypassed by moving one line into a helper
function, producing a real unsynchronized data race. Separately, the type
checker doesn't validate `let` annotations, assignments, return types, or
call arguments against declared types (§1), which combines with a
`void @main()` codegen bug (§0) to mean *every single example shipped in
`examples/`* exits with a non-deterministic garbage status code despite
printing correct output. None of this shows up in `cargo test` because the
test suite checks parsing/lexing and a handful of golden runtime outputs,
not exit codes or the type-checker's negative-case coverage. Sections 1–2
cover general-purpose-language gaps, §3 the memory model in depth, §4
codegen quality, §5 game/graphics ergonomics, §6 tooling, and §7 is a
priority-ordered fix list.

---

## 0. Flagship bug: every compiled program exits with a garbage status code

**Severity: critical. Reproducible on every single example in `examples/`.**

`fn main():` with no `->` return type compiles to `define void @main()`
(`src/codegen/stmt.rs:87`, `ret_ty = "void"` when `f.sig.ret` is `None`).
Clang links this straight in as the process's C entry point. A hosted `main`
is contractually `int main(void)`/`int main(int, char**)` — the OS/CRT
startup thunk always reads a return value out of the ABI return register
(`eax`/`al` on x86-64) after calling it. A `void`-typed `main` never writes
that register, so the process exit code is **whatever happened to be left
in `eax`** by the last instruction executed before `ret void` — typically
the return value of the last `printf`/`puts` call.

Reproduced against the shipped example binaries:

| Example | stdout | exit code |
|---|---|---|
| `player.exe` | `Hero has perished.` (19 chars incl. `\n`) | **19** |
| `arena_freelist.exe` | correct | **13** |
| `arena_freelist_double_despawn.exe` | correct | **11** |
| `swarm.exe` | correct | **11** |
| `genref_lifecycle.exe` | correct | **9** |
| `spawn.exe` | correct | **1** |

Confirmed root cause by minimal repro: declaring `fn main() -> i32: ... return 0`
fixes the exit code to `0` every time; omitting the return type reproduces
the garbage code on the identical program. Every canonical example in the
repo — the ones the README and `todo.md` point to as proof the compiler
works — silently "fails" from the perspective of any shell, CI pipeline, or
`Process::status()` caller (`cmd1 && cmd2`, `make`, test harnesses, etc.),
despite printing perfectly correct output.

**Fix:** special-case `main`'s signature to always lower to `i32 @main(...)`
and append an implicit `ret i32 0` when the user's `main` body doesn't
already return a value (mirroring what `rustc`/`clang` do for a bare `fn
main()`/`void main()`).

---

## 1. Type-checker soundness holes

The type checker's diagnostics *look* trustworthy — good spans, "did you
mean" suggestions (`src/diagnostics.rs`) — but several of the most basic
checks a "Rust-typed" language promises simply don't exist. All four holes
below were independently reproduced.

### 1.1 `let` type annotations are parsed and then ignored

`src/types/stmt.rs:13-19`:

```rust
Stmt::Let { is_mut, name, ty, value, span } => {
    let value_typed = self.infer_expr(value, vars)...;
    let actual_ty: Ty = ty.as_ref().and_then(|t| self.resolve_type(t))
        .unwrap_or_else(|| value_typed.clone().into_ty());
    ...
}
```

The annotation, if present, is resolved and used as the variable's tracked
type **with no comparison against `value_typed`'s actual type at all**.
Reproduced:

```star
struct Foo:
    x: i32

fn main():
    let a: Foo = 42
    let b: str = 3.14
    print(f"{a} {b}")
```

`star check` reports `ok: ... parsed and type-checked successfully`.
`star build` reports `ok: built ...`. Running the executable **segfaults**
(exit code 139 / SIGSEGV under the WSL-ish shell used to test). The emitted
IR is self-evidently broken — `%t2 = load %Foo, %Foo* %t0` where `%t0` was
actually `alloca i32` two lines earlier — because the checker told codegen
the variable's type was `Foo` while its value was really an `i32`.

### 1.2 Assignments are never type-checked

`src/types/stmt.rs:20-35` (`Stmt::Assign`) infers both the target and value
expressions but only checks for duplicate swizzle components on vector
writes — there is no general "is `value`'s type assignable to `target`'s
type" check anywhere in that arm.

### 1.3 `return` is never checked against the function's declared return type

`src/types/stmt.rs:36-39` and `Checker::check_fn_with_self_ty`
(`src/types/mod.rs:384-393`) never compare a `return expr`'s inferred type
against `f.sig.ret`. Worse, this isn't just a missed diagnostic: codegen's
`TypedStmt::Return` (`src/codegen/stmt.rs:182-193`) emits `ret <ty-of-the-
returned-expression>`, not `ret <declared-return-type>`. Reproduced:

```star
fn get_val() -> i32:
    "not an int"

fn main():
    print(f"{get_val()}")
```

`star check` passes cleanly. This produces a `define i32 @get_val()` whose
body does `ret i8* %something` — a function whose declared LLVM signature
and actual terminator disagree, which is only caught (if at all) by clang's
backend, surfacing as an opaque non-Star error rather than a diagnostic
pointing at the offending line.

### 1.4 Ordinary function calls never check argument count or argument types

`src/types/expr.rs`'s general `Expr::Call` arm (~lines 99-153) type-checks
generic calls, struct literals, enum-variant construction, `List` methods,
and `spawn` — but a plain call to a plain function skips argument
count/type validation entirely. Reproduced:

```star
fn add(a: i32, b: i32) -> i32:
    a + b

fn main():
    let x = add("foo", "bar")   # passes i32 params two `str`s
    print(f"{x}")
```

`star check` passes. (`star build` also "succeeds"; the resulting binary's
behavior is whatever falls out of treating two string pointers as if they
were `i32`s inside `add`'s body — undefined in the useful sense, since the
checker never even considered it an error.)

### 1.5 Struct binary operators silently type as `Int`, caught only at codegen with no location

`infer_binop_ty`'s fallback path (`src/types/expr.rs:557-566`) treats two
struct-typed operands to `+` as producing `Ty::Int` rather than rejecting
them. The actual rejection happens much later, in `emit_binop`'s catch-all
(`src/codegen/vector_math.rs:245-248`), using `Span::dummy()` — so the
resulting "codegen error: unsupported operand types for binary operator"
points at line 0, column 0 of the file, not the offending expression.
Reproduced directly: `star check` reports success for `let x = "foo" + 5`;
`star build` fails with a span-free error only at the codegen stage. Any
checker hole that only surfaces at codegen inherits this same
"unlocatable error" problem — see also §1.1–1.4, all of which either build
successfully into broken binaries or (in 1.5's case) fail late with no
useful location.

### 1.6 Traits are decorative, not checked

`Checker::check_impl` (`src/types/mod.rs:343-378`) verifies the trait name
and the target struct name both exist — it never compares the `impl`
block's methods against the trait's declared `FnSig` list. An `impl Trait
for Type:` block can implement zero of the trait's methods, or methods with
totally different signatures/arity, and it still compiles without
complaint. There are also no default trait method bodies (`TraitDef` only
stores bare `FnSig`s, `src/ast.rs:120-126`) and no trait bounds/where-
clauses on generic parameters (`parse_opt_type_params`,
`src/parser/items.rs:112-125`, parses bare `<T, U>` with no `T: Trait`
syntax at all) — so `fn add_them<T>(a: T, b: T) -> T: a + b` cannot express
"T must support `+`" even in principle.

### 1.7 Global flat function/method namespace — a real miscompilation risk

`Checker.functions: HashMap<String, (Vec<Ty>, Option<Ty>)>`
(`src/types/mod.rs:125`) is keyed by method/function name **only**; `impl`
block methods are inserted into the exact same table as free functions
(`src/types/mod.rs:223-231`). Two unrelated structs each defining `fn
update(mut self) -> i32` and `fn update(mut self) -> String` collide:
whichever is declared later in the file wins in the checker's table, and
every call site's inferred return type follows that shared entry — while
codegen's own dispatch table is correctly struct-scoped (keyed
`"Struct#method"`, `src/codegen/expr.rs:100-101`). The checker and codegen
can therefore disagree about a call's type: the checker infers one type,
codegen emits code for a different method. This also isn't module-isolated:
`src/modules.rs`'s import-inlining never mangles impl-block method names
(`collect_names`, `src/modules.rs:138-153` explicitly skips `Item::Impl`),
so importing two modules that each define a same-named method on different
structs reproduces the exact same collision across file boundaries.

### 1.8 Inference is one-shot substitution, not real unification

The module doc-comment claims "Hindley-Milner-style inference"
(`src/types/mod.rs:1-5`), but `unify_ty` (`src/types/mod.rs:653-691`) does
first-binding-wins substitution with no cross-argument consistency check
(the code's own comment at `src/types/mod.rs:650-652` admits "later,
conflicting bindings are silently ignored"). `fn pair<T>(a: T, b: T)`
called as `pair(1, "x")` binds `T = Int` from `a` and silently drops the
mismatch from `b` rather than erroring.

### 1.9 `frame:` blocks don't lexically scope their bindings — and the failure mode is a useless error

Per `docs/design.md`, `frame` memory is supposed to be reclaimed "at the end
of each tick," but the actual codegen resets `@frame.off` back to its
saved value **the instant the `frame:` block itself exits**
(`src/codegen/stmt.rs:45-51`, save-before/restore-after around
`emit_frame_body`), i.e. at block-scope, not tick-scope. That's a stricter
and arguably more useful guarantee than the docs describe — but the checker
doesn't enforce it as a scope boundary at all:

```star
struct Holder:
    mut val: i32

fn main():
    frame:
        let h = Holder(777)
        print(f"in frame: {h.val}")
    print(f"after frame: {h.val}")
```

`star check` reports success — `h` is still visible to the checker's `vars`
map after the `frame:` block closes, because `frame:` isn't treated as
introducing a new lexical scope the way `if`/`while` blocks are (consistent
with Star's Python-style indentation, where those *don't* scope either —
an entirely reasonable thing for a user to assume `frame:` also does,
since nothing in the syntax marks it as special). `star build`, however,
**does** reject it, but with a useless error: `codegen error: unknown
struct \`unknown\`` — no span, no mention of `h`, no mention of `frame`.
Codegen's own `self.symbols` table *is* properly popped at the end of the
frame block (unlike the checker's `vars`), so the mismatch between "checker
still knows about `h`" and "codegen has forgotten `h`" is what produces
this specific garbage message. Net effect: `star check` — the fast
iteration/"developer velocity" tool the whole design is pitched around —
gives a false "successfully type-checked" verdict for a program that
cannot be built at all, and when the user does run `build`, the error
message actively misdirects them away from the real problem (a stale
`frame:`-scoped reference).

---

## 2. General-purpose programming gaps

### 2.1 No boolean logical operators at all

`TokenKind` (`src/lexer.rs:18-102`) has no `&&`, `||`, `&`, `|`, `^`, `<<`,
`>>`, and no `and`/`or`/`not` keywords either — confirmed by grep, zero
matches anywhere in `src/`. `peek_binop` (`src/parser/expr.rs:38-54`) only
recognizes arithmetic and comparison operators. **It is currently
impossible to write `if a > 0 and b > 0:`** — every compound boolean
condition must be manually nested into separate `if`s, or reimplemented by
hand as a chain of `match` arms. For a language pitching itself as a
general-purpose-capable "Pythonic-Rust", this is probably the single
highest-impact missing feature: it affects nearly every nontrivial
conditional in real code.

### 2.2 No error-propagation sugar (`?`, `try`, `panic`)

There is no `?` operator, no exception mechanism, and no `panic`/`abort`
builtin anywhere in `ast.rs`'s `Expr`/`Stmt`. `Result`/`Option` exist only
as ordinary user-defined enums (see `examples/option_result.star`) that
must be `match`ed out by hand at every call site — there is no shorthand
for "propagate the error variant upward." The convention chosen for
built-in fallible operations (`List` index/pop out of bounds, `GenRef`
dereference of a dead slot) is instead "return the type's zero value"
(`src/types/hir.rs:220-241`'s doc comments), the same silent-fallback
philosophy as `GenRef`. That's a reasonable default for hot game-loop
code, but it means there is currently no way to *opt into* loud failure
for user-defined fallible logic without hand-rolling it.

### 2.3 Minimal standard library

The entire builtin surface (`src/codegen/builtins.rs` +
`builtin_return_ty` in `src/types/mod.rs:93-107`) is: `print`/`println`,
`sqrt`/`pow`/`floor`/`ceil`/`abs`/`min`/`max`, and exactly two string
operations, `len` and `concat`. Missing, and commonly needed in *any*
general-purpose program: string `split`/`trim`/`replace`/`index_of`/case
conversion, numeric parsing (`str` ↔ `int`/`float`), a `to_string`
facility independent of f-string interpolation, `HashMap`/`Set` (there is
no `Ty::Map` variant at all, confirmed absent from `src/types/mod.rs:28-52`),
sorting, and any file/stdin I/O (no `read_line`, no file open/read/write).

### 2.4 Collections are thin and can't be iterated with `for`

`src/codegen/list.rs` implements a genuinely solid growable array —
`{T* data, i64 len, i64 cap}`, doubling growth, sound bounds checking with
an unsigned-compare trick that also rejects negative indices
(`emit_list_index`/`store_list_index`, `src/codegen/list.rs:101-163`) — but
the only methods are `push`/`pop`/`len`. No `insert`, `remove`, `contains`,
`clear`, `sort`, `map`/`filter`/`reduce`. Worse: `Stmt::For` only supports
integer ranges (`src/ast.rs:243-251`, `src/parser/stmt.rs:203-215`) — there
is no `for x in some_list:` at all. Iterating a list requires manually
writing `for i in 0..list.len(): list[i]`, which also means there's no
`for e in Arena:` — ECS iteration is confined to `par`/`swarm`.

### 2.5 Modules: no re-exports, no visibility, no stdlib namespace

`src/modules.rs` inlines each imported file wholesale and mangles every
top-level name (`mangle_name`, line 39). The module's own doc comments
admit: no re-exports/transitive imports (`a` importing `b` importing `c`
cannot reach `c`'s items through `b`, lines 17-24); no `pub`/private
distinction exists anywhere in `ast.rs`, so every item is globally visible;
and there's no `import "std"` surface, since builtins are compiler
intrinsics rather than a real module — meaning the stdlib gaps in §2.3
can't even be worked around with a community-maintained module today.

### 2.6 Lexer gaps

- **Number literals**: `scan_number` (`src/lexer.rs:345-368`) accepts only
  plain decimal digits with one optional `.fraction` — no `0x`/`0o`/`0b`,
  no scientific notation (`1e10`), no digit-group separators (`1_000`).
- **Strings**: no multi-line/triple-quoted or raw-string literals —
  `scan_string`/`scan_fstring` (`src/lexer.rs:381-466`) both error out on a
  bare newline inside the literal.
- **Escapes are silently lossy**: `scan_escape`'s catch-all
  (`src/lexer.rs:469-484`) turns any unrecognized `\x` into bare `x` (the
  backslash just vanishes) instead of erroring — `"\q"` silently becomes
  `"q"`, a real footgun for typos. No `\u{...}` Unicode escapes either.
- **Comments**: line comments (`#`) only, no block comments.

None of this is a crash risk — no `unimplemented!()`/`todo!()` exist
anywhere in `src/`, and the four `unreachable!()` call sites
(`src/codegen/vector_math.rs:101,132,258`, `src/types/expr.rs:629`,
`src/sequence.rs:90`) are all genuinely guarded by their enclosing matches.
The real robustness risk, as §1 shows, is the opposite of panicking: silent
acceptance of malformed programs that later crash or misbehave at runtime.

### 2.7 `star check` is not a reliable signal

Because of §1.1–1.5 and §1.9, "parsed and type-checked successfully" from
`star check` does **not** mean the program will build, and does not mean
the program is correct if it does build. Given `todo.md`'s workflow
explicitly treats `check` as the fast iteration loop ("Confirm code with
cargo" / fast feedback), this materially undercuts the stated "developer
velocity" goal — users will learn not to trust green `check` output.

---

## 3. Memory model (frame / arena / GenRef / par / sequence)

This is Star's headline differentiator, and the *safety-critical* claims
around it are the ones that matter most — a memory model that markets
itself as "circumvent[ing] the need for a standard Garbage Collector...
without exposing [developers] to the catastrophic dangers of manual malloc
and free" (`docs/design.md:37`) is making a much stronger promise than an
ordinary feature gap. Several of the findings below are reproduced,
memory-unsafe violations of that exact promise, not just missing
convenience.

### 3.1 Frame escape analysis: false-negatives via closures, and no capacity check at all

`src/types/frame_analysis.rs` correctly catches the three cases its own
doc comment enumerates: returning a frame-local struct, assigning it to a
non-frame-local target, and `spawn`-ing it into an arena — all reproduced
successfully above (a direct `frame: let h = Holder(999); h` returned from
a function is rejected with a good, spanned error). It also correctly
reasons that `List<T>` is a safe sink for frame-local structs, since
pushing copies by value into independently-owned storage. What it gets
**wrong**, reproduced end-to-end:

- **A closure capturing `self` by pointer smuggles a frame pointer straight
  past the check.** Every `TypedExpr::Call` is unconditionally treated as
  non-escaping (`frame_analysis.rs:170-187`, "a call only borrows its
  arguments... none of these can carry frame identity onward"). That
  reasoning is false for methods: `src/codegen/closure.rs:30-40` documents
  that closures capture a `self` receiver *by pointer*, not by value. So a
  method called on a frame-local struct that returns a closure capturing
  `self` carries a raw pointer into the frame buffer straight out through
  the return, and the escape check never looks inside the call. Reproduced
  with a getter closure returned from a frame-local receiver: `star check`
  passes cleanly, and the closure's return value silently changes from
  `777` to `42` once a second `frame:` block reuses the same bump-buffer
  bytes — exactly the "non-deterministic bug from reading overwritten
  frame memory" the design doc's escape analysis exists to prevent
  (`docs/design.md:11`), occurring with zero compiler diagnostics.
  **This is the analysis's core promise failing silently, not loudly.**
- **The frame buffer itself has no capacity check.** `@frame.buf` is a
  fixed `[4096 x i8]` global (`src/codegen/mod.rs:215`); the frame-`Let`
  codegen path (`src/codegen/stmt.rs:141-168`) advances `@frame.off` and
  does an `inbounds` GEP with **no comparison against the 4096-byte
  limit** anywhere. A single `frame:` block that allocates more than 4KB —
  trivial with a handful of structs, a few `Mat4`s, or any loop — segfaults
  or silently corrupts whatever global data happens to sit after the
  buffer. Reproduced directly: a `frame:` block constructing ~121 `Mat4`s
  (64 bytes each, ~7.7KB, one block) segfaults on execution. The escape
  analysis reasons entirely about *identity/lifetime*; nothing in the
  compiler reasons about *capacity* at all.
- Frame nesting (save/restore of `@frame.off` around each block,
  `src/codegen/stmt.rs:41-54`) and recursive re-entry are otherwise
  correctly handled as ordinary runtime state. But there is **no actual
  "tick" concept anywhere in the compiler** — a repo-wide search for `tick`
  turns up only doc comments. "Resets at end of tick" (`docs/design.md:7`)
  is, in the actual implementation, "resets at the end of the lexically-
  scoped `frame:` block" (see also §1.9); nothing ties frame lifetime to an
  actual game-loop iteration.
- It also doesn't treat a `frame:` block as a scope boundary for ordinary
  same-function, non-escaping reads after the block closes — see §1.9's
  repro (`star check` passes; `star build` fails with an unhelpful,
  span-free "unknown struct `unknown`" error instead of a clear diagnostic
  about the stale reference).

### 3.2 Arenas silently drop spawns past capacity instead of erroring, growing, or crashing

`Codegen::ARENA_CAPACITY` (`src/codegen/mod.rs:100`) is a hardcoded
`1024` for **every** arena regardless of element type or declared use —
there is no way to size an arena per-declaration. `emit_spawn_stmt`'s own
doc comment (`src/codegen/arena.rs:234-237`) confirms: "a spawn past
`ARENA_CAPACITY` live elements is silently dropped rather than writing out
of bounds." This is a deliberate, defensible safety choice given `par`/
`swarm` workers may be concurrently reading the backing array — but it
directly contradicts `docs/design.md`'s claim that unbounded spawning
"will eventually trigger an Out-of-Memory (OOM) crash": the actual failure
mode is **silent data loss** (an entity the game logic believes it spawned
simply never exists), which is strictly harder to debug than a crash. There
is currently no error, warning, or return value that tells the caller a
`spawn` was dropped.

### 3.3 GenRef dereference of a never-spawned slot segfaults or returns garbage — directly contradicts the documented safety guarantee

`docs/design.md:29` is explicit: dereferencing a stale/dead `GenRef`
"safely prevents segfaults and returns a safe null/None equivalent if the
target is gone." That guarantee holds for the *despawned-after-spawn* case
(reproduced correctly via `examples/genref_lifecycle.star`), but not for a
`GenRef` created against a slot that was **never spawned into in the first
place**. `emit_genref_index` (`src/codegen/arena.rs:460-523`) only compares
the `GenRef`'s captured generation against the slot's *current* generation
(lines 492-495) — it never checks whether the slot is actually live
(odd-vs-even generation parity), and its "match" path unconditionally loads
`@arena.{name}.data` and dereferences it (497-506) with **no null check**.
A never-spawned slot's generation is `0`, which is indistinguishable from a
freshly-constructed `GenRef`'s own captured generation for that same slot
(acknowledged as a known limitation in the code's own comment at
`src/codegen/arena.rs:394-401`) — and since the arena's backing storage is
allocated via a plain, unzeroed `@malloc` (`src/codegen/arena.rs:253`) that
only happens lazily on the *first* `spawn`, dereferencing a `GenRef` before
any `spawn` into that arena either **segfaults** (if `data` is still
`null`, i.e. nothing has ever been spawned into this arena) or **returns
uninitialized garbage heap bytes** (if `data` was already allocated because
some other slot in the same arena was spawned into). Reproduced directly:
`GenRef<Entity>(0)` immediately dereferenced with zero prior `spawn`s into
`Entities` segfaults. This is not an edge case — creating a `GenRef` before
anything has been spawned is an entirely ordinary sequencing mistake, and
the resulting crash is exactly the failure mode generational references
exist to make impossible. **Severity: critical — a documented safety
guarantee is falsified by a straightforward, easily-reached repro.**

### 3.4 Generation counters are unchecked 32-bit and can theoretically wrap

Each arena slot's generation is a plain `i32`, bumped with `add i32 ...,
1` on every despawn/respawn (`src/codegen/arena.rs:316-330`) with no
overflow check. After ~2^31 despawn/respawn cycles on the same slot the
counter wraps back through a value a long-lived stale `GenRef` might still
be holding, reintroducing exactly the ABA problem generational references
exist to prevent. This is a very low-probability event in practice (2
billion+ despawns of one slot) but is worth a saturating-add or an explicit
"generation exhausted" fallback given the whole feature's purpose is
eliminating this exact class of bug.

### 3.5 `par`/`swarm`: the `spawn`/`despawn`/`frame` ban is not transitive through function calls — a real, reproduced data race

The checker's disjointness analysis (`src/types/par_analysis.rs`) textually
bans `spawn`/`despawn`, closures, and method calls on captured values
directly inside a `par`/`swarm` body (lines 42-212) — but `walk_par_expr`'s
`Call` arm (lines 115-130) only restricts *method* calls (a `Field`-based
callee); a **bare function call is completely unchecked**. Reproduced: a
helper function whose body contains `spawn Enemies(1)` compiles cleanly
when called from inside a `par e in Enemies:` loop body (`star check`
reports success). At runtime this is `NUM_THREADS = 4`
(`src/codegen/arena.rs:65`) separate OS threads concurrently mutating the
same unsynchronized `@arena.*.count`/`@arena.*.free_top`/`@arena.*.data`
globals with no atomics or locking anywhere in their codegen — precisely
the race the textual `spawn`/`despawn` ban exists to prevent, reachable by
simply moving one line into a helper function. The same hole applies to
`frame:`: calling a function that contains its own `frame:` block from
inside a `par` body also compiles cleanly, and since `in_frame` is a
codegen-time flag scoped only to the *inlined* body (`src/codegen/arena.rs:
92`), the callee's `frame:` block still targets the same shared
`@frame.off`/`@frame.buf` globals from all 4 threads simultaneously — an
unsynchronized data race on ordinary (non-atomic) memory. **Severity:
critical** — this isn't a theoretical gap, it's a one-line workaround
around a safety check the language advertises as load-bearing ("safety is
guaranteed through strict, compiler-enforced read/write declarations",
`docs/features.md:7`).

Separately, and lower severity: `docs/features.md:4` promises "a fixed pool
of OS worker threads," but `emit_par_stmt` issues fresh `CreateThread` /
`WaitForSingleObject` / `CloseHandle` calls (`src/codegen/arena.rs:
198,217,219`) on **every** `par`/`swarm` statement execution — there is no
persistent thread-pool structure anywhere in the codebase. Since `par`/
`swarm` is pitched for per-tick ECS iteration, a game at 60 FPS with four
parallel systems pays 240+ OS thread creation/teardown cycles *per second*,
each costing tens of microseconds on Windows — a severe, avoidable
performance regression against the feature's own stated purpose. (Sequential
`par` loops are at least not racy against *each other*, since each fully
joins via `WaitForSingleObject` before returning.) `swarm` is also
lexer/parser/codegen-identical to `par` — no distinct read-only fast path
exists despite the separate naming implying one. And the cross-system lock
arbitration `docs/features.md:8` describes ("the compiler simply forbids a
swarm loop if another system has requested a mutable lock on the same
component array in the current tick") does not exist anywhere in the
checker or codegen — what's implemented is single-loop-body
field-disjointness only, not cross-system arbitration; that framing is
aspirational, not built.

### 3.6 Two silent, permanent memory leaks entirely outside the three-tier model

Star's whole pitch is "no GC, no manual malloc/free, fully deterministic
memory" via frame/arena/GenRef. Two features quietly opt out of that
story by calling raw `malloc` with no corresponding `free`, ever:

- **String concatenation** (`emit_str_concat`, `src/codegen/builtins.rs:
  219-241`): every `concat(a, b)` call `malloc`s a fresh buffer that is
  never freed by anything — not by the frame allocator, not by an arena,
  not manually. Any string-heavy loop (e.g. building a UI label every
  frame) leaks unboundedly.
- **Closure environments** (`src/codegen/closure.rs:158`, and explicitly
  documented in the file's own header comment at lines 6-9: "heap-allocated
  (`malloc`'d, never freed) environment"): every closure literal leaks its
  captured-variable snapshot for the lifetime of the process. Creating
  closures inside a loop (a very natural thing to do, e.g. per-entity
  event handlers) leaks unboundedly.

Both are real, user-triggerable, unbounded leaks in a language whose
flagship claim is deterministic, leak-proof memory management. Neither is
mentioned anywhere in the design docs as a known limitation.

### 3.7 `sequence` coroutines: early `return` compiles to invalid LLVM IR

`src/sequence.rs` hoists a `sequence`'s parameters and top-level `let`s
into a generated state struct and compiles to a `resume(mut self) -> bool`
method with a `switch`-based dispatch on an internal state index, matching
the design doc's description. `yield` is correctly restricted to top-level
statements only — nesting one inside a loop or conditional is explicitly
detected and rejected (`scan_for_nested_yield`, `src/sequence.rs:200-243`),
which is an honest, well-enforced "flat script" limitation rather than a
silent gap.

What isn't handled: `rewrite_stmt` passes a bare `Stmt::Return` through
completely unchanged (`src/sequence.rs:255`), with no accounting for the
fact that the surrounding function has been rewritten to return `bool` (the
synthesized `resume`'s signature). Reproduced: a `sequence` containing `if
n < 0: return` before any `yield` passes `star check` silently, then fails
`star build` with a raw backend error (`error: value doesn't match function
result type 'i1'` / `ret void`) rather than a Star diagnostic. "Early exit
from a sequence" is an entirely natural pattern (e.g. aborting a multi-tick
attack sequence when the target dies) and is currently an undocumented
landmine — either early `return` should be rewritten to `return false`/
`return true` the same way the implicit fallthrough is, or the checker
should reject it explicitly with a clear message.

---

## 4. Codegen quality / missed optimizations

### 4.1 Every build ships at `-O0`, with no way to opt out

`cmd_build` (`src/main.rs:121-140`) invokes clang with exactly `-o
<exe>`, `<ll-path>`, and `-Wno-override-module` — no `-O1/-O2/-O3`, no
`-flto`, and the `build` subcommand exposes no flag to request
optimization at all. Combined with the fact the emitter itself never runs
LLVM's `opt` pipeline or does any of its own simplification, this means
**every single Star binary, including the ones in `examples/`, is built
fully unoptimized.** For a language whose entire pitch is "hardware
speed," this is the highest-leverage, lowest-effort fix available — simply
passing `-O2` would likely produce a large, free performance win across
every program, since mem2reg/SROA alone would eliminate the alloca-per-
variable pattern noted below.

### 4.2 Alloca-per-variable, relying entirely on an optimizer pass that never runs

Every `Ident`, `let`, function parameter, and `self` is spilled to an
`alloca` + `store` and read back via `load` (e.g. `src/codegen/expr.rs:
178-192`, `emit_fn`'s parameter handling at `src/codegen/stmt.rs:101-109`).
This is a completely reasonable strategy *if* `mem2reg` always runs
afterward — but per §4.1, it never does in the shipped `build` pipeline, so
this stack traffic survives into the final binary as-is.

### 4.3 `Vec2`/`Vec3` don't use real SIMD types; only `Vec4`/`Mat4` do

`docs/features.md:30-32` claims Star "relies on Clang's `ext_vector_type`"
and "automatically emits optimal SSE/AVX ... instructions" for all vector
math. In reality, `llvm_ty` (`src/codegen/mod.rs:255-284`) lowers `Vec2`
to the plain aggregate `{ float, float }` and `Vec3` to `{ float, float,
float }` — ordinary structs, not `<2 x float>`/`<3 x float>` vector types
— and `emit_vec_struct_binop` (`src/codegen/vector_math.rs:59-72`)
performs their arithmetic component-by-component via `fadd float`/`fsub
float`/etc. in a loop, round-tripping through an `alloca` to reassemble the
result. Only `Vec4` (`<4 x float>`) and `Mat4` (`[4 x <4 x float>]`) get
genuine vector instructions (`emit_vec4_binop`,
`src/codegen/vector_math.rs:75-88`, and the matrix ops at 121-220, which
are legitimately well-built — real `extractvalue`/dot-product sequences
over native vector registers). Since `Vec2`/`Vec3` are extremely common in
2D game code, this is a meaningful gap between the documented behavior and
the actual implementation for the *majority* of typical game-math traffic.

### 4.4 No explicit alignment, no `target datalayout`

A repo-wide search of `src/codegen/**` for `align` turns up zero explicit
alignment attributes on any vector/matrix `alloca`/`load`/`store`. The
"strict 16-byte alignment for `vec4`" guarantee `docs/features.md:32`
claims is not enforced by the emitter — it's implicit, unverified behavior
of whatever clang infers by default, further weakened by `emit()`
(`src/codegen/mod.rs:127`) only setting `target triple` and never a
matching `target datalayout` string, so the assumed ABI layout isn't
actually pinned down anywhere in the IR itself.

### 4.5 No constant folding, no debug info

`1.0 + 2.0` on two literals still emits a real `fadd` instruction sequence
— nothing in `Codegen` special-cases constant operands. Separately, no
`!dbg`/`DICompileUnit` metadata is ever emitted and `cmd_build` never
passes `-g` to clang, so there is currently no way to source-level-debug a
compiled Star program.

### 4.6 Missing vector-math builtins the codegen already has the pieces for

A repo-wide search for `dot`, `cross`, `normalize`, `length`, `lerp`,
`clamp`, `reflect` turns up no user-callable builtin of any of these names.
Notably, `emit_dot4` already exists internally (`src/codegen/vector_math.rs:
143-161`) to implement `Mat4 * Vec4`, but it's private and unreachable from
user code — exposing `dot(a, b)`/`length(v)` as builtins would be close to
free given the primitive is already written and correct.

---

## 5. Game/graphics ergonomics — gaps that fit Star's existing philosophy

Given what already exists — arenas + `GenRef` handles, `par`/`swarm`
per-tick parallel iteration, `sequence` frame-yield coroutines, and
first-class `Vec2`–`Vec4`/`Mat4` — the following are conspicuously absent,
and each would fit as low-overhead sugar over the *existing* mechanisms
rather than as a new subsystem:

- **Input polling with edge detection** (`key_down(K)` / `just_pressed(K)`
  / `just_released(K)`). No `input`/`keyboard`/`gamepad` symbol exists
  anywhere in `src/`. This is the most obviously-missing convenience for a
  game language and the cheapest to add: two bitsets (current/previous
  frame) diffed once per tick, exposed as pure-looking builtin calls —
  exactly the "hide a stateful poll behind a call" pattern Star already
  uses for `print`.
- **Delta-time plumbing / fixed-timestep loop scaffolding.** `sequence`'s
  whole pitch is "frame-bound yields" (`docs/features.md:15`), but nothing
  owns "run N systems at a fixed dt per tick," and there's no builtin
  `dt`/`Time` value — every per-frame movement calculation has to invent
  its own time source, undercutting `sequence`'s own value proposition.
- **Basic physics primitives** (AABB/circle overlap, raycast-vs-AABB).
  Since arenas already hold cache-friendly component arrays and `par`/
  `swarm` already has the machinery to iterate them safely, a
  `overlap(a: Arena, b: Arena) -> List<(GenRef, GenRef)>`-shaped builtin
  built on the same disjointness analysis backing `swarm` would avoid every
  game hand-rolling an O(n²) loop from scratch.
- **Transform hierarchy / scene graph.** `Vec3`/`Mat4` are already
  first-class; a lightweight parent-index + cached local/world `Mat4`
  built on `GenRef` parent links (the same "safe null on dead reference"
  semantics arenas already guarantee) would be a natural, cheap extension
  rather than a heavyweight bolt-on ECS.
- **Asset-handle types.** `GenRef<T>`'s `{ i32 index, i32 generation }`
  representation (`src/codegen/mod.rs:213`) already solves "stable,
  use-after-free-safe handle into a fixed array" — exactly what a
  texture/mesh/sound handle needs. Nothing currently specializes it for
  asset loading, but the runtime shape is already proven and in place.
- **Event/signal dispatch.** `List<T>` and closures both already exist; a
  `Signal<T>` sugar (`List<Fn(T)>` plus an `emit` that calls each
  subscriber) would be nearly free to add given both primitives are
  already implemented, and would avoid every game hand-rolling observer
  patterns via raw lists of function pointers.
- **Seeded RNG.** No `rand`/`Random` builtin exists anywhere. A
  deterministic per-run-seeded PRNG (xorshift/PCG) fits the same
  intrinsic-style lowering `sqrt`/`abs` already use
  (`src/codegen/builtins.rs:92-105`) and matters specifically for a
  tick-based engine where determinism/replay is often a design goal.
- **Easing/interpolation helpers** (`lerp`, `smoothstep`, `clamp`). Same
  observation as §4.6 — `emit_math_binary_f32`'s existing pattern already
  covers exactly this shape of builtin; the marginal cost of adding these
  is small relative to their ubiquity in game code.

### 5.1 Reflection/hot-reload has a real payload but no external contract

`emit_reflect_metadata` (`src/codegen/reflect.rs:70-97`) is a genuine,
working mechanism — it walks a struct's `@export`/`@tweakable` fields in
declaration order, computes real byte offsets against the struct's actual
LLVM layout, and emits a `name:offset:type:decorators;`-joined global
string per struct (`@__star_reflect_StructName`). It is not a stub. But
it has **no documented, versioned, or stable external surface**: the
format only exists as a doc comment in the source
(`src/codegen/reflect.rs:62-69`), not in `docs/features.md` or any schema
file; there's no accompanying JSON manifest or symbol table emitted at
build time; and the ad hoc `;`/`:`-delimited grammar has no escaping, so a
field or struct name containing `:` or `;` would corrupt it. An external
hot-reload editor tool would today need to reverse-engineer the naming
convention and hand-parse this format directly out of the compiled
binary's data section — a real gap between "the mechanism exists" and
"the mechanism is usable by the external tooling the whole feature exists
to support."

---

## 6. Tooling and CLI

- **Commands**: `star check`, `star build [-o out]`, `star emit
  {tokens|ast|llvm}` (`src/main.rs:22-45`). No `--release`/`-O` flag on
  `build` (tie-in to §4.1), no watch mode (notable given the project's own
  hot-reload ambitions — nothing drives an actual reload cycle from source
  changes today), no incremental build/caching (every `build` re-lexes/
  re-parses/re-typechecks/re-codegens the whole flattened module from
  scratch), no package manager (`src/modules.rs` only resolves local-file
  imports), no formatter, no language server.
- **`find_clang`** (`src/main.rs:153-171`) falls back to a hardcoded
  `E:\LLVM\bin\clang.exe` if nothing is found on `PATH`. That's a
  reasonable single-developer convenience but is a portability bug for
  anyone else building this compiler on a different machine or in CI
  without `clang` on `PATH` — silently pointing at a path that won't exist
  on their system rather than failing with an actionable "clang not
  found" message up front.

---

## 7. Priority recommendations

Roughly in order of severity/impact-to-effort ratio. The first four are
memory-safety guarantees the language explicitly advertises as its core
value proposition, falsified by direct, easily-reached repros — these are
the highest priority regardless of effort:

1. **Bounds-check the frame bump buffer (§3.1).** `@frame.buf` is a fixed
   4096-byte global with *no* capacity check anywhere in the codegen — any
   `frame:` block allocating more than 4KB segfaults or corrupts adjacent
   global state today. This is the most basic safety property a bump
   allocator needs and it's currently entirely absent.
2. **Close the closure/`self`-pointer escape hole in frame analysis
   (§3.1).** A method returning a closure that captures `self` by pointer
   carries a frame pointer past the escape check undetected, and silently
   returns stale/overwritten data on the next `frame:` reuse — with zero
   diagnostics. This is the exact bug class the escape analysis exists to
   prevent, reproduced with no compiler warning at all.
3. **Null/liveness-check `GenRef` dereference against a never-spawned slot
   (§3.3).** Currently segfaults or reads uninitialized heap memory,
   directly falsifying the documented "safe null equivalent, never a
   segfault" guarantee — and "dereference a `GenRef` before spawning
   anything" is an ordinary sequencing mistake, not an edge case.
4. **Make the `par`/`swarm` `spawn`/`despawn`/`frame` ban transitive
   through function calls (§3.5).** Moving a `spawn` call one level into a
   helper function currently bypasses the entire disjointness check and
   produces a real, unsynchronized 4-thread data race on arena globals —
   a one-line workaround around a safety property the language markets as
   compiler-enforced.
5. **Fix `main`'s exit code (§0).** One or two lines; currently breaks
   every single compiled program's integration with any exit-code-aware
   caller (shells, CI, process-status checks).
6. **Close the `let`/`return`/`Assign`/call-argument type-checking holes
   (§1.1–1.4).** The difference between "Rust-style type safety" as
   advertised and a checker that only validates a subset of programs;
   mistyped code currently reaches codegen or a segfaulting runtime
   instead of being rejected with a clear diagnostic.
7. **Pass `-O2` by default in `cmd_build`, add a `--release`/`-O0` toggle
   (§4.1).** Free performance win, near-zero implementation cost.
8. **Give `par`/`swarm` a real persistent thread pool (§3.5).** Currently
   the single biggest gap between the feature's stated purpose and its
   actual per-tick runtime cost.
9. **Add `&&`/`||`/`and`/`or`/`not` (§2.1).** Small parser/lexer/codegen
   change, unblocks a huge fraction of realistic control flow.
10. **Fix the two unbounded leaks in string `concat` and closure
    environments (§3.6).** Directly contradicts the "no GC needed, fully
    deterministic memory" pitch that's the language's core sell.
11. **Make arena-capacity overflow loud (§3.2)** — even just a debug-mode
    assertion — rather than silently dropping spawned entities.
12. **Route `Vec2`/`Vec3` through the same SSA/vector-register path `Vec4`
    already uses (§4.3)**, closing the gap between the documented and
    actual SIMD story for the two most common vector types in 2D games.
13. Expose `dot`/`length`/`lerp`/`clamp`/RNG as builtins (§4.6, §5) — cheap
    given the underlying primitives already exist in the codegen.
14. **Rewrite or reject early `return` inside `sequence` bodies (§3.7)** —
    currently produces invalid LLVM IR caught only by the backend.

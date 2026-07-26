# Star Language: A Technical Assessment

*Reviewed at commit `ca0d66b` (2026-07-26). Based on a full read of
`docs/design.md`, `docs/features.md`, `docs/language_reference.md`, the prior
`ASSESSMENT.md`/`todo.md` (now archived at `changelog/060_...`/`061_...`), the
`src/` compiler (~42k lines of Rust across 99 commits), `tests/frontend.rs`
(1,514 tests, all green under both `cargo build` (MSVC) and
`cargo +stable-x86_64-pc-windows-gnu test --release`, with zero compiler
warnings on either toolchain), and targeted reads of `par_pool.rs`,
`system_font.rs`, `audio.rs`, `gamepad.rs`, `hashtable.rs`, and the
operator-overloading/trait-bound machinery in `types/expr.rs`.

## The pitch, updated

Star still wants to be one language spanning indie, retro-emulation, and AAA
game-dev tiers: Python layout, Rust-style inference and immutability-by-default,
a three-tier memory model (`frame`/`arena`/`GenRef`) that avoids both a GC and a
borrow checker, a narrow statically-checked `par`/`swarm` concurrency model, and
a hand-rolled textual-LLVM-IR backend shelled out to `clang`. What's changed
since the last review is that several things which used to be *aspirational
prose* are now real, checked, tested code: `system`/`parallel` cross-system
scheduling exists and rejects conflicting arena locks at compile time; `Map`/
`Set`/`Symbol` are real hash tables, not linear scans; structs can overload
operators and satisfy trait bounds; audio and gamepad are implemented, not
"deferred." The design thesis hasn't changed — the gap between the thesis and
the implementation has visibly narrowed.

---

## The Good

**1. Follow-through at a rate this project's own history didn't predict.**
The previous review (`changelog/060_2026_07_26_ASSESSMENT.md`) produced a
13-item prioritized punch list spanning structural-risk P0s to process P3s.
Every single item is now done — not stubbed, not partially done: each has a
committed implementation, new `docs/` sections, new examples, and (per
`changelog/061_...`'s own running total) the test suite grew from 1,331 to
1,514 tests along the way, entirely in the two days between `db1454b` and
`ca0d66b`. That's a rare thing to see land in full rather than cherry-picked,
and it's worth naming as a real engineering strength before the "Bad" section
below moves on to what's next.

**2. The hand-rolled-IR structural risk has a real answer now.**
`src/ir_check.rs` runs after codegen and before `clang` ever sees the output:
terminator/phi/reference/duplicate-definition checks derived directly from the
two historically-documented bug classes (a `store` after a block's own `ret`;
an untagged register reaching a `phi`), plus a 2,000-case fuzz test and a
permanent regression asserting zero errors across every shipped `.ll` fixture.
This closes the exact "`star check` says clean, `clang` still rejects it"
failure mode that was this project's single biggest structural risk.

**3. The silent-wrong-output bug class was fixed at the root, not patched.**
The fieldless-enum-prints-as-pointer bug (and its worse sibling — structs/
tuples/closures also silently misprinting as garbage addresses) is now closed
by making both format-specifier tables in `builtins.rs`/`expr.rs` *exhaustive*
(`unreachable!()` on every aggregate-by-value type instead of a `_ => %p`
wildcard) and rejecting unprintable types at check time
(`Ty::is_fstring_unprintable`). A future `Ty` variant that isn't sorted into a
bucket now fails to *compile the compiler*, not just fails a test — a
materially stronger guarantee than "we added a test for the case we already
found."

**4. `Map`/`Set`/`Symbol` are real hash tables.** Open addressing with
tombstones, structural hashing that agrees with structural equality
(`codegen/hash.rs` mirrors `eq.rs`'s exact type coverage, including `-0.0`/
`+0.0` canonicalization), grow-at-75%-load. This directly closes last
review's top-billed complaint (`Map<Symbol, _>` being O(n) undercut the "AAA
entity counts" framing) with no syntax/semantics change to the surface API.

**5. Operator overloading reused the existing method-call path instead of
adding a new one.** `a + b` on a type implementing `Add` desugars at
type-check time into the same `TypedExpr::Call`/`TypedExpr::Field` shape an
ordinary `a.add(b)` call already produces — meaning **zero codegen changes**
were needed to support it. That's a genuinely elegant piece of design: new
surface-level feature, no new backend surface, so no new place for the
hand-rolled-IR risk (point 2, historically) to reappear. The `Self`-in-trait-
signature handling that made it possible is scoped narrowly (a checker-only
flag, not a general resolvable type) specifically to avoid `Self` leaking
into a context with nothing to substitute it with.

**6. The build story now has a real default path.** `cargo build` (MSVC)
works with zero configuration for any contributor; the GNU/mingw path (this
machine's own build path) is now clearly labeled as the exception requiring
one-time user-level setup, with the actual reason
(mingw's GCC-style runtime vs. MSVC's ambient CRT) documented instead of
assumed. This closes what was a real "one person has memorized the
incantation" risk.

**7. The memory model, diagnostics, and dogfooding discipline carry over
unchanged and still hold up.** `frame`/`arena`/`GenRef`'s "new type, old
layout" consistency, trap-by-default overflow semantics, rustc-grade
diagnostics with cross-file span tracking, and `projects/snake` as a running
integration exercise are all still exactly as strong as the last review found
them — none of that needed revisiting.

---

## The Bad

**1. The compiler is Windows-only at the concurrency-primitive level, not
just at the graphics/font level.** `codegen/par_pool.rs` — the shared worker
pool backing *every* `par`/`swarm` loop — emits raw `CreateThread`/semaphore
calls directly into the generated LLVM IR. `system_font.rs` binds GDI
(`CreateFontA`, `TextOutA`). `net.rs` almost certainly binds Winsock. None of
this is hidden — the toolchain docs are upfront that the only build target is
`x86_64-w64-windows-gnu` — but it means "port to Linux/macOS" is not a
backend swap; it's a rewrite of parallelism, audio, windowing, and text
rendering simultaneously, because there is no platform-abstraction seam
anywhere in the codegen layer today. Every feature landed since the last
review (audio, gamepad, system fonts) has independently deepened this same
coupling rather than routing through one.

**2. The `par`/`swarm` worker pool is a hardcoded 4 threads, not scaled to
hardware.** `NUM_WORKERS: u32 = 4` (`codegen/par_pool.rs:43`) is a compile-time
constant baked into the generated program, not queried from the OS at
runtime. On an 8+ core machine this leaves real parallel throughput on the
table for exactly the workload (`swarm` ECS iteration) the language's
concurrency story is built to sell; on a weaker or busier machine it can
oversubscribe. This is a gap between the "swarm" pitch (parallel ECS
performance) and what actually runs.

**3. Traits are structural sugar over monomorphization, with no dynamic
dispatch — and only structs can use them.** There is no vtable, no `dyn
Trait`, no heterogeneous `List<SomeTrait>` holding mixed concrete types; a
"trait bound" only ever resolves to one concrete type per call site, checked
nominally but dispatched statically. Combined with `check_impl`'s struct-only
restriction (an enum can't implement a trait at all), this means the design
doc's own flagship `Player`/`Damageable` pitch — which reads like it wants
runtime polymorphism over a mixed collection of damageable things — can't
actually be expressed as stated. This was already implicitly true before
trait-bounded generics/operator overloading existed; it's more conspicuous
now that traits are a load-bearing, working feature rather than a stub.

**4. The test suite is a single 1,514-test, ~1.45 MB file.** `tests/
frontend.rs` is by a wide margin the largest file in the repository (the next
largest source file, `types/mod.rs`, is ~4,700 lines vs. this file's sheer
byte size). It has no internal module decomposition mirroring `src/codegen/`'s
own 35-file breakdown. This hasn't caused a visible problem yet, but it's a
trend line: every new feature adds tests to the same file, and "find the
existing coverage for X before adding more" is already a real cost at this
size.

**5. Front-end robustness against malformed/adversarial input is unverified
one layer earlier than it should be.** `ir_check.rs` got a real fuzz test
(2,000 garbled inputs, asserted no panic) precisely because hand-rolled IR
generation was identified as a risk. The lexer/parser/checker — which see
*raw user text* first, before any of that — never got the same treatment,
despite 181 `.expect()` call sites across `src/` that are plausible panic
surfaces if a malformed `.star` file trips an internal invariant the checker
assumed always held. Nothing currently proves `star check` on garbage input
degrades to a clean diagnostic rather than a compiler panic.

**6. No tooling ecosystem exists yet.** No syntax-highlighting grammar, no
LSP, no formatter, no package registry beyond local search paths + a minimal
manifest. Not urgent for a solo project mid-design-churn, but worth flagging
now rather than after the syntax has fully settled, since "nobody else can
comfortably read `.star` in an editor" is a real adoption barrier the moment
this is shown to anyone else.

**7. Versioning is still informal, though the process gap that motivated it
is fixed.** `Cargo.toml` stays `0.1.0`; there's no stated stability tier or
SemVer policy for the language surface itself. `changelog/` (added this
round, per last review's P3 #11) now gives a durable, append-only record of
*why* each change happened, which was the real complaint — this item is
substantially de-risked, just not formally closed.

---

## The Ugly

**1. Every new feature is currently making the eventual cross-platform port
more expensive, with no counter-force in sight.** This isn't a single ugly
fact so much as a trend: `par_pool.rs` (`CreateThread`), `audio.rs` (a
Windows-only mixer thread model per its own doc comments), `gamepad.rs`
(SDL's `Joystick`, fine — cross-platform in principle — but every sibling
module isn't), and `system_font.rs` (raw GDI) all landed in the same round,
each independently Win32-coupled, with zero shared abstraction boundary
between "what the language needs" and "how Windows happens to provide it."
If cross-platform is ever a real goal, the cost of that migration is
compounding weekly, right now, without anyone deciding that's an acceptable
trade — it may well be the *correct* trade for a solo Windows-dev project,
but it should be a decision, not a default.

**2. The review cadence itself is now a risk the project doesn't have a
process for.** The entire prior punch list — 13 items, several of them
genuinely structural — was fully closed in about two days. That's a strength,
but it also means new special cases, new Windows API surface, and new
untested code paths can accumulate *faster* than periodic manual review
catches them. Nothing in `.clinerules/workflows/` currently triggers a
review like this one on any cadence tied to feature velocity rather than to
being asked for.

**3. "One type system" is still, after this round's own unification pass, a
list of special guests — just a shorter list.** `Ty::eq_only_scalar_shape`
(`todo.md` P3 #12, done) unified the five equality-only types' dispatch
branches, which is real progress. But it explicitly *didn't* touch
`Wrapping`/`Fixed` (real arithmetic) or the `Tick`/`Duration`/`Instant` family
(asymmetric legal pairings) — each keeps its own dedicated branch by design —
and `i32`'s silent-wraparound exception to the trap-by-default rule remains a
hand-documented asymmetry with no structural guard against a future
contributor forgetting it's the odd one out. The abstraction pass proved the
pattern is tractable; it didn't eliminate the pattern.

---

## Bottom line

The center of gravity of risk in this project has genuinely moved. A review
two days ago would have opened with "can I trust the IR this compiler
generates" and "is the concurrency model actually sound" — both now have
real, tested answers (yes, via `ir_check.rs`; yes, but narrower than the docs
used to claim, and the docs now match). The risk today is less about
*correctness* and more about *scope and durability*: how far this can travel
off of one Windows machine, whether the front end survives a user's typo as
gracefully as it now survives a hand-rolled-IR bug, and whether a test suite
and a Win32-coupled codegen layer that both grew this fast this cleanly can
keep doing so without deliberately-placed seams (a platform-abstraction
boundary, a decomposed test tree, a fuzzed parser) rather than continued raw
velocity. None of this is urgent in the way last round's IR-verification gap
was — nothing here is silently producing wrong output — but it's exactly the
kind of gap that's cheap to address now and expensive to retrofit later,
which is the same argument that made last round's P0 list worth acting on
before this one was written.

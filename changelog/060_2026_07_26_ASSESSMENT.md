# Star Language: A Technical Assessment

*Reviewed at commit `db1454b` (2026-07-24). Based on a full read of `docs/design.md`,
`docs/features.md`, `docs/language_reference.md`, `projects/snake/NOTES.md`, the
`src/` compiler (~34k lines of Rust), `tests/frontend.rs` (1,331 tests, all green
under `cargo +stable-x86_64-pc-windows-gnu test --release`), and targeted reads of
`par_analysis.rs`, `frame_analysis.rs`, `modules.rs`, `diagnostics.rs`, and
`codegen/stmt.rs`.*

## The pitch

Star wants to be one language spanning three normally-incompatible game-dev
tiers: small indie titles, faithfully-emulated retro hardware, and AAA engine
work. Its syntax is Python's layout with Rust's type inference and
immutability-by-default; its memory model is a three-tier scheme (`frame` bump
allocators, spatial `arena`s, generational `GenRef` handles) that explicitly
avoids a garbage collector and (mostly) avoids a borrow checker; concurrency is
a narrow, statically-checked `par`/`swarm` construct plus tick-bound `sequence`
coroutines; it compiles to native code by emitting textual LLVM IR and shelling
out to `clang`.

That is a genuinely coherent design thesis, not a grab-bag of features. The
rest of this document is about how well the implementation lives up to it.

---

## The Good

**1. The memory model is real, not marketing.** `frame`, `arena`, and `GenRef`
aren't three separate ideas bolted together — they compose cleanly ("arenas
handle the macro, frame handles the micro, generational IDs handle the
relationships"), and each one reuses the others' machinery where it can:
`Handle<T>` is a second nominal wrapper around `GenRef`'s exact layout;
`Bytes`/`Palette` reuse `List<T>`'s RC/copy-on-write layout; `Wrapping<T>`/
`Fixed<Bits,Frac>`/`Tick`/`Symbol`/`Color32` all reuse a bare integer with zero
overhead beyond a nominal-type tag. This "new type, old layout" discipline
repeats so consistently across the codebase that it reads as an actual
architectural principle, not an accident.

**2. Overflow safety is opt-out, not opt-in.** Every explicit-width integer
type traps on overflow by default via LLVM's `llvm.{s,u}{add,sub,mul}.with.overflow.iN`
intrinsics; `Wrapping<T>` and `Fixed<Bits,Frac>` are the deliberate, explicit
escape hatches for retro register emulation and deterministic fixed-point sim,
respectively. That's the right default for a language claiming to span indie
and AAA use — most languages in this space (C, C++, and every big engine's
own scripting layer) get this backwards.

**3. The `par`/`swarm` safety check is small, conservative, and sound by
construction.** `types/par_analysis.rs` doesn't attempt real alias analysis
(rightly — the design doc itself calls that a brush with the halting
problem). Instead it enforces one simple rule: a `par` body may only mutate
its loop variable's own fields or locals it declares itself; any write to a
captured name is rejected outright, as is any method call on anything but the
loop variable or a local. It's a narrow guarantee, but it's a *real* one, and
it's cheap enough to explain in one paragraph — a good trade for a systems
language that wants to be readable by people who aren't concurrency experts.

**4. Diagnostics are genuinely rustc-grade.** `src/diagnostics.rs` tracks a
`file_id` per span (so multi-module errors render against the *correct*
source file, not the importing file's), renders a caret-underlined snippet,
and powers "did you mean `x`?" suggestions via edit distance. This is a level
of polish a lot of hobby/research languages skip entirely, and it materially
changes how painful the language is to actually debug.

**5. The test suite is unusually honest.** 1,331 tests, and a large fraction
are `runtime_*_end_to_end` tests that actually invoke `clang` and *run* the
resulting executable rather than just asserting on IR shape or AST structure.
That's a meaningfully stronger guarantee than most compiler test suites offer,
and it's why the bug list below is so detailed — this project catches its own
mistakes and writes them down.

**6. Real dogfooding, not just unit tests.** `projects/snake/NOTES.md` is the
single most valuable artifact in this repo: a genuine multi-module game that
exercises modules, generics, closures, all three memory tiers, `par`/`swarm`/
`each`, `sequence`, most of the collection types, file I/O, and SDL graphics —
and documents, with root causes and confirmations, every bug and design gap
it actually hit. Every one of the six confirmed compiler bugs found this way
has since been fixed, and the write-up is refreshingly free of spin: it
records what *didn't* work as prominently as what did (section 3, "what
worked well," is proportionally the shortest section).

**7. The toolchain choice is pragmatic.** Emitting textual LLVM IR and
shelling out to an installed `clang.exe` instead of linking against `inkwell`/
`llvm-sys` sidesteps LLVM version-matching hell and lets "any Clang that
accepts modern LLVM IR" work as the backend. For a solo/small-team project,
that's the correct call — it trades a class of correctness risk (see "The
Ugly," below) for a large reduction in build/toolchain fragility.

---

## The Bad

**1. `Map<K,V>`/`Set<T>` are linear-scan, not hash tables — today, `O(n)` on
every `insert`/`get`/`remove`/`contains`.** This is disclosed honestly in the
docs, and it's a defensible bootstrapping choice (it supports arbitrary
structurally-hashable keys, including nested structs, with no hash function
needed at all). But it directly undercuts the "AAA entity counts" language
used elsewhere in the design docs (the same section that motivates `Symbol`
interning for O(1) tag comparison). A `Map` keyed by `Symbol` is exactly the
kind of per-frame lookup a real ECS needs to be fast, and today it's O(n).
`Symbol` construction itself is also a linear `strcmp` scan of the whole
intern table.

**2. The concurrency story is narrower than it's pitched.** The design doc
describes "compile-time locks" that "forbid a swarm loop if another system
has requested a mutable lock on the same component array in the current
tick" — language that implies an ECS scheduler resolving cross-system data
dependencies. What's actually implemented is much smaller: a single `par`
loop is checked in isolation against its own captures; there is no
cross-system lock/schedule concept at all. That's not a bad design (it's
arguably the right scope for where this project is), but the docs describe
an ambition the implementation doesn't yet have, and a reader evaluating
"can I safely parallelize multiple systems that touch overlapping arenas in
one tick" will get a more restrictive answer in practice (write it
sequentially) than the prose implies.

**3. `par`/`swarm` can't draw anything, at all — full stop.** Every SDL
drawing/input builtin is banned inside `par`/`swarm` (for good, confirmed
reasons: concurrent calls crash SDL itself). But until `each` was added,
there was *no other way to iterate an arena's contents* — no `.len()`, no
indexed read, no plain `for`. `each` (sequential, single-threaded) now fixes
this, but it means the actual idiomatic ECS render-loop pattern this language
is pitched around — the reference doc's own flagship example — never runs in
parallel, by construction. Fine for a 2D indie game; a real constraint for
the AAA tier of the pitch.

**4. `frame:` blocks are a leaky abstraction with a hardcoded, tiny budget.**
The bump-allocator cap is 4096 bytes, hardcoded in `codegen/stmt.rs`, with no
per-block override (unlike `arena`, which got a per-arena capacity override
specifically because 1024 elements was too rigid). 4096 bytes is easy to blow
with unremarkable code — the doc's own flagship A*-pathfinding example
(`docs/language_reference.md`) doesn't actually fit in it once you loop over
a nontrivial grid, as `projects/snake/NOTES.md` §1.2 confirms firsthand. The
per-iteration reclaim fix (also in that write-up) helps a lot, but the fixed
ceiling itself remains a footgun with no compiler-facing way to size it to
the workload.

**5. No trait-bounded generics.** `fn identity<T>(x: T) -> T` works; there is
no `<T: SomeTrait>` constraint syntax anywhere in the parser. A generic
function can move, store, and return a `T`, but can't call a trait method on
it or use an operator that isn't defined for literally every possible type.
This limits generics to container-shaped code (`Box<T>`, `Stack<T>`) — which
is most of what the design doc actually wants generics for, but it's worth
being explicit that "generics" here means "monomorphized templates," not
Rust-style bounded polymorphism.

**6. The module system still can't resolve a search path.** `import
"foo.star"` is always a literal path relative to the importing file; there's
no project root, no search path, no manifest. `projects/snake/NOTES.md`
calls this "the most significant gap from this exercise still open" — even
after the diamond-import unification bug (below) was fixed, real multi-file
projects still hand-thread relative paths with no notion of a package.

**7. Build friction on the reference platform is real.** Per this project's
own build config, a plain `cargo build` doesn't work on the primary
development machine at all (no MSVC linker) — building requires
`cargo +stable-x86_64-pc-windows-gnu` plus a hand-maintained `vendor-libs`
stub directory to satisfy `-lgcc_eh`/`-lgcc` against LLVM-mingw's
compiler-rt. That's an unusually fragile toolchain story for a project that
wants outside contributors or users; today it works because one person has
memorized the incantation.

**8. Audio and gamepad are still entirely unimplemented.** Explicitly
deferred, and honestly labeled as such, but it's a real hole in "game
programming language" — no game ships without audio, and controller input
matters a lot for the genres this language's memory model (arenas, `par`
ECS iteration) is obviously aimed at.

**9. The bitmap font renderer is debug-HUD-grade, not UI-grade.** 5x7,
uppercase-only (lowercase folds up), a fixed ASCII-ish subset, no
kerning/proportional spacing. Fine for a score counter; not something you'd
ship a real UI with.

---

## The Ugly

**1. Hand-rolled textual LLVM IR generation is a structural risk, not a
one-off bug source.** Several of the "confirmed compiler bugs" in
`projects/snake/NOTES.md` are exactly the failure mode you'd predict from
string-templating IR by hand with no builder verifying well-formedness before
`clang` sees it: a `frame:` block ending in `return` emitted a `store` *after*
the block's own terminator (`ret`), which LLVM correctly rejects; a trailing
`if/else` returning a bare identifier produced an untagged register that a
later `phi`-merge step couldn't split a type off of, again only caught at the
`clang` step, not by `star check`. Both are now fixed, but they're evidence of
a systemic weak point, not two independent one-off mistakes: `star check` can
report a program clean and it can still fail to *compile* at the `clang`
step, on IR the front end itself generated. Every new codegen path added to
this compiler carries the same latent risk class until (if ever) it grows an
internal IR-validity check ahead of the `clang` boundary.

**2. The scariest bug so far wasn't a crash — it was silent wrong output.**
Interpolating a fieldless `enum` into an f-string used to compile clean and
*run* clean, printing something that looked like a real value (a 16-hex-digit
string that reads as a plausible pointer/ID) instead of the enum's name —
because the enum's `i32` discriminant fell through to the f-string
formatter's `%p` catch-all. No crash, no diagnostic, no test failure until a
human eyeballed the actual output and noticed it was wrong. For a language
whose entire safety pitch rests on the type system catching mistakes at
compile time, "the type system silently accepted a category error and
printed a confident-looking lie" is the worst class of bug this project could
have — worse than a crash, because a crash tells you something is wrong.
It's fixed now, but it was found by a human reading console output, not by
`star check`, not by the type checker, and not by any of the 1,331 existing
tests (a new one had to be written *after* the fact).

**3. The module-diamond-import bug reveals the mangling strategy was
identity-blind from the start, not just incomplete.** Two independently
imported paths reaching the same physical file used to produce two different,
mutually-incompatible mangled types for what is, by any reasonable
definition, the same struct — because `modules::resolve` mangled names by
concatenating the *alias chain used to reach* a type, rather than by the
type's actual source-file identity. This isn't a missing feature; it's a
design that worked by coincidence for strictly linear import graphs and broke
the moment a genuinely ordinary project structure (two feature modules
sharing one foundation module) was attempted. It's fixed now (via an
`ItemProvenance`/`dedupe_by_origin` pass keyed on canonical source identity),
but it's worth naming plainly: the original design implicitly assumed no
real program would ever import the same file two ways, which is not a safe
assumption for *any* module system past a toy example.

**4. The "one type system, three tiers" thesis is already visibly straining
at the seams.** `i32` is the one integer type that keeps silent
two's-complement wraparound "because every existing program already depends
on it," while every other explicit width traps by default — a deliberate,
documented exception, but also exactly the kind of asymmetry that will
surprise newcomers coming from either direction (a systems programmer
expects `i32` to behave like every other int; a retro/wrapping-arithmetic
user has to remember `i32` is the odd one out). More broadly, nearly every
new type added to close a tier-specific gap (`Wrapping`, `Fixed`, `Symbol`,
`Color32`, `Tick`/`Duration`/`Instant`, `BitField`, `Flags`) is explicitly
*not* folded into the checker's general `is_numeric()`/`int_shape()`
predicates and instead gets its own dedicated dispatch branch in both the
type checker's binop inference and the codegen's binop emission. Each
addition is individually well-reasoned and well-tested, but the pattern is
cumulative: the checker and codegen's binop-dispatch surfaces grow one
special case per type, indefinitely, with no unifying abstraction in sight.
That's a maintainability trajectory worth naming now, while the list is still
short enough to fix.

**5. There is no versioning, changelog, or stability guarantee of any kind
pre-1.0 — and the project's own historical record is actively discarded.**
`todo.md` and `current_status.md` are both, by explicit process
(`.clinerules/workflows/todo`), rewritten/cleared after each work session
rather than accumulated; the only durable record of *why* a decision was made
is buried in prose inside `docs/design.md`'s "done" annotations and
`projects/snake/NOTES.md`. That's a real process risk if this project ever
wants outside contributors: there's no single place to see "what changed
between last week and today" outside of reading `git log -p`.

---

## Bottom line

This is a more rigorously engineered language than its "solo project" scale
would suggest — the trap-by-default numeric model, the sound-but-narrow
`par` safety check, the rustc-grade diagnostics, and above all the
end-to-end `clang`-executed test suite are all signs of real engineering
discipline, and the `projects/snake` dogfooding exercise is exactly the kind
of self-critical practice that catches the bugs a language most needs caught
before someone else finds them. The risk isn't a lack of rigor; it's that
the rigor is currently applied *after* the fact (bugs found by dogfooding,
then fixed) rather than by construction (an IR validity check, a hash-backed
`Map`, a package/module identity model) — and the "one language, three
tiers" ambition means the type system's surface area, and therefore the
list of places a hand-written LLVM-IR string can be wrong, keeps growing
faster than the up-front safety net does.

# Star Compiler — Next Steps

Prioritized from [current_status.md](current_status.md)'s technical review.
Ordered by how much each item protects the investment already made (the last
review's 13-item punch list, now fully closed) versus adds new surface area
— biggest lever first within each tier.

## P0 — Protects existing investment / structural

1. **Fuzz the lexer/parser/checker directly, not just `ir_check.rs`.**
   `ir_check.rs`'s 2,000-case fuzz test (asserting no panic) exists precisely
   because hand-rolled IR generation was identified as a risk — but raw user
   text hits the lexer/parser/checker *first*, and none of that pipeline has
   the same guarantee despite 181 `.expect()` call sites across `src/` that
   are plausible panic surfaces on malformed input. Apply the exact same
   methodology one layer earlier: feed random bytes and mutated real `.star`
   files through `star check`'s full pipeline and assert it always ends in
   either success or a clean diagnostic, never a panic. -- Done
2. **Scale the `par`/`swarm` worker pool to actual hardware.** `NUM_WORKERS:
   u32 = 4` (`src/codegen/par_pool.rs:43`) is a hardcoded compile-time
   constant baked into every generated program, not queried at runtime. Query
   the real core count (`GetSystemInfo`'s `dwNumberOfProcessors`, with an
   optional explicit override) so the "swarm" pitch's actual performance
   matches the hardware it runs on instead of always assuming 4 cores. -- Done
3. **Make the Windows-only scope an explicit decision, not a default, before
   more Win32-specific machinery lands.** `par_pool.rs` (`CreateThread`),
   `audio.rs`, `gamepad.rs`, and `system_font.rs` (GDI) each independently
   deepened the same Win32 coupling this round, with no platform-abstraction
   seam anywhere in codegen. Either update `readme.md`/`docs/design.md` to
   scope Star explicitly as a Windows-only game language (so nobody is
   surprised later), or identify the seam a future OS-primitives
   abstraction would need now, while the surface is still small enough to
   retrofit cheaply. -- Done

## P1 — Real design gaps

4. **Decide and document the dynamic-dispatch story.** Traits today are
   structural sugar over monomorphization — no vtable, no `dyn Trait`, no
   heterogeneous collection of mixed concrete types satisfying one trait —
   and only structs may implement a trait at all (`check_impl`'s struct-only
   restriction). The design doc's own `Player`/`Damageable` flagship example
   reads like it wants runtime polymorphism over a mixed collection; either
   commit explicitly to "generics/traits are compile-time-only, full stop"
   and adjust that example/prose to stop implying otherwise, or scope what a
   `dyn Trait`/tagged-enum-of-variants alternative would need for the one
   real motivating use case (heterogeneous ECS component lists). -- Done
5. **Allow enums to implement traits, or document why not.** The struct-only
   restriction on `impl Trait for ...:` was a reasonable bootstrapping choice
   when traits were new; now that trait-bounded generics and operator
   overloading are both real, load-bearing features, the asymmetry (a
   fieldless enum can't satisfy even a trivial trait bound) is worth either
   closing or naming as an intentional limitation in
   `docs/language_reference.md`'s "Traits and Implementations" section. -- Done

## P2 — Maintainability

6. **Split `tests/frontend.rs`** (1,514 tests, ~1.45 MB — by far the largest
   file in the repo) **into topic-scoped files**, mirroring `src/codegen/`'s
   own 35-file decomposition (e.g. one test file per codegen module, or at
   minimum separating checker-diagnostic tests / codegen-shape tests /
   runtime end-to-end tests into their own files). No functional change
   needed — this is purely about keeping "find existing coverage before
   adding more" cheap as the suite keeps growing every session. -- Done: split
   into 59 topic-scoped `tests/frontend_*.rs` files (e.g.
   `frontend_collections_map_set.rs`, `frontend_bitfield_flags.rs`,
   `frontend_sdl_graphics_input_and_geometry_audit.rs`), each a separate
   `cargo test` binary named for the feature/section it covers, plus a shared
   `tests/frontend/common.rs` (pulled in via `#[path]`) for the dozen
   cross-cutting helpers (`compile_and_run`, `assert_no_leak`,
   `typed_fn_result_ty`, the `PAR_SRC_PREFIX`/`FRAME_ESCAPE_SRC_PREFIX`
   fixtures, ...) used across more than one file. All 1,530 tests still pass
   (`cargo +stable-x86_64-pc-windows-gnu test --tests`), same pass/fail
   behavior as before -- purely a file-layout change.
7. **Finish (or explicitly bound) the binop-dispatch unification.** The P3
   #12 abstraction pass (`Ty::eq_only_scalar_shape`) only unified the
   equality-only types (`Symbol`/`BitField<N>`/`Flags<E>`/`Color32`/
   `PaletteIndex`); `Wrapping`/`Fixed` and the `Tick`/`Duration`/`Instant`
   family still get bespoke per-type branches by design. Either fold the
   arithmetic-bearing types into a similar shared table where their
   semantics genuinely overlap, or write down explicitly (in a doc comment
   next to `infer_binop_ty`) that these are irreducibly special so the next
   contributor doesn't re-litigate the question. -- Done

## P3 — Process

8. **Treat a review like this one as recurring, not one-off.** The prior
   punch list — 13 items, several structural — was fully closed in about two
   days. At that velocity, new special cases and new untested code paths can
   accumulate faster than periodic manual review catches them. Consider a
   `.clinerules/workflows/` trigger tied to feature-batch size (e.g., "every
   N changelog entries" or "before any session that touches a new codegen
   module") rather than only running a full assessment when asked.
9. **Start scoping minimal editor tooling** — at minimum a TextMate/
   Tree-sitter grammar for syntax highlighting. No LSP urgency yet while the
   syntax is still moving, but even highlighting would materially help
   anyone other than the primary author read `.star` code, and it's cheap
   relative to everything else on this list.


# Previous Work
Implemented todo.md P1 #4: decided and documented the dynamic-dispatch story, plus scoped (but did not build) what real `dyn Trait` support would require.

Decision (docs, no code changes): traits remain compile-time-only, permanently -- `impl Trait for Type:`/`T: Trait` bounds resolve to exactly one concrete type per call site (monomorphized, per `check_impl`), with no vtable and no `dyn Trait` anywhere in the compiler. This is now stated explicitly rather than left implicit, in two places: `docs/design.md` gets a new "Trait Dispatch: Decision and Scope" section right after the `Player`/`Damageable` flagship example (`docs/design.md`), and `docs/language_reference.md`'s "Traits and Implementations" section gets a new "Dispatch Model" subsection cross-referencing it.

The motivating use case the review flagged -- a trait named `Damageable` reading like it wants a mixed collection of damageable things -- already has a real answer that needs zero new compiler machinery: a tagged enum of variants, since enum variants can already carry different payload types (`Shape::Circle(radius: i32)`/`Rect(width, height)` already existed). Both docs now show the same worked example (`enum DamageableKind: PlayerK(player: Player), EnemyK(enemy: Enemy)`, dispatched via an index-based `for`/`match` loop over `List<DamageableKind>`) in a new "Heterogeneous Collections" subsection of `docs/language_reference.md`. Verified by hand with `star check`/`star build` against a scratch `.star` file exercising this exact shape (two concrete `impl Damageable for ...` types, a `List<DamageableKind>`, and the `for`/`match` dispatch loop) -- both parsed/type-checked and compiled cleanly; this also caught two real syntax facts worth recording since they contradicted an initial draft: enum variant payloads must be named fields (`PlayerK(player: Player)`, not a bare `PlayerK(Player)`), and match-arm bindings can never carry a `mut` modifier (`PlayerK(p)`, not `PlayerK(mut p)`) -- calling a `mut self` method on a plain pattern-bound name still type-checks fine.

`docs/design.md`'s new section also scopes what real `dyn Trait`/vtable support would need if ever revisited: a fat-pointer/vtable value representation, a decision on where a boxed `dyn Trait` value lives (arenas/`frame`/`GenRef` have no boxed/unsized storage class today), a second per-trait vtable-construction codegen path alongside the existing monomorphize-per-call-site path, and an answer for how `par`/`swarm`'s per-system parallel iteration would type a system over a `dyn Trait` list. Recorded as scoped-not-planned, matching the user's explicit choice to write this down for a future revisit rather than build it now.

todo.md P0 #1:
Code (tests/frontend.rs): extended the existing lexer/parser fuzz test into a full-pipeline fuzzer (fuzz_lexer_parser_checker_do_not_panic) that now also runs the type checker, scaled from 300 → 2,000 cases to match ir_check.rs's methodology. Added a second test, fuzz_full_pipeline_random_bytes_do_not_panic, that feeds truly uniform random bytes (not just the plausible-source-alphabet mutations) through the same lex→parse→check pipeline, also 2,000 cases. Both assert no panic and no hang (bounded worker thread), matching ir_check.rs's fuzz_never_panics guarantee one layer earlier in the front end. Full suite (1,515 tests) still passes; the two new fuzz tests run in ~0.3s combined.

Implemented todo.md P0 #2: the par/swarm worker pool now sizes itself to real hardware instead of a hardcoded 4.

src/codegen/par_pool.rs (near-complete rewrite): NUM_WORKERS: u32 = 4 became MAX_WORKERS: u32 = 64 (array-sizing ceiling) and MIN_WORKERS: u32 = 4 (runtime floor). ensure_init now determines the live worker count via GetSystemInfo's dwNumberOfProcessors, with a STAR_WORKERS environment-variable override (parsed via atoi), clamped to [MIN_WORKERS, MAX_WORKERS]. Thread creation, dispatch fan-out, and the join wait all became genuine LLVM runtime loops instead of Rust-compile-time-unrolled sequences — including switching per-worker argument-struct storage from N separate allocas to one array alloca indexed at runtime (a single alloca inside the loop would have aliased every concurrent worker onto the same memory).

src/codegen/mod.rs: added GetSystemInfo/atoi externs, plus a prelude_declared name-tracking fix — an unconditional atoi prelude declare collided with existing tests that extern "C" fn atoi(...) themselves (LLVM rejects duplicate declares), so emit_extern_fn_decl now skips re-declaring anything the fixed prelude already provided.

src/codegen/system.rs / src/types/system_analysis.rs: updated to the new constant names/semantics; MAX_PARALLEL_SYSTEMS (4) is now documented as a floor the pool guarantees, not a ceiling it's fixed to.

Tests (tests/frontend.rs, +11 net): fixed two existing IR-shape tests that asserted CreateThread appears 4 times (now 1, since it's a single runtime-loop call site); added coverage for the new mailbox array sizing, hardware/env-var detection in the IR, the runtime-loop shape itself, and — most importantly — end-to-end runtime correctness across STAR_WORKERS overrides (1, 2, 3, 4, 5, 8, 37, 64, 100), the zero/below-floor clamp, and a 4-system parallel: block still dispatching correctly when STAR_WORKERS=1. Full suite: 1522 passed.

Implemented todo.md P0 #3: picked the "identify/build the seam" branch over "document Windows-only" — the worker-thread pool's OS primitives (thread create, semaphores, core-count detection) now have a real second implementation, selectable with a new `--target` flag, rather than just a design note.

src/codegen/platform.rs (new): a `Target` enum (`WindowsGnu` default / `LinuxGnu`) plus every thread/semaphore/core-count primitive codegen needs, each with a Win32 arm (unchanged IR, byte-for-byte) and a POSIX arm (pthread_create/pthread_self/sem_init/sem_wait/sem_post/sysconf). A semaphore is always handed back as an opaque i8* "handle" regardless of backend (a malloc'd+sem_init'd sem_t buffer on Linux, a real kernel HANDLE on Windows) so every existing call site and global array of handles stays unchanged in shape. GDI text rendering (system_font.rs) deliberately got no seam — no POSIX syscall rasterizes a TrueType glyph, so that's a real new-backend feature, not a retrofit; its module doc comment now says so explicitly, alongside font.rs's bitmap font as the already-portable fallback.

src/codegen/par_pool.rs, mod.rs, symbol.rs, vector_math.rs, system.rs: every raw CreateThread/WaitForSingleObject/CreateSemaphoreA/ReleaseSemaphore/GetCurrentThreadId/GetSystemInfo call site — not just par_pool.rs's, also @sym.lock/@rng.lock's init and the parallel: dispatcher's own wait/release — now routes through platform.rs instead of hand-writing Win32 IR inline. @par.pool.tid widened i32→i64 so a Windows thread id (zext'd) and a Linux pthread_t can share one array shape.

src/driver.rs / src/main.rs: Codegen::new_for_target/Driver::codegen_verified_for_target added alongside (not replacing) the existing default-target new()/codegen_verified(), so none of the ~1500 pre-existing tests calling those needed to change. `star build`/`star emit llvm --target=windows|linux` (clap ValueEnum) threads the choice through; clang only gets an explicit -target flag for the non-default case, leaving the well-tested Windows clang invocation byte-for-byte untouched.

src/types/mod.rs: pthread_create/pthread_self/sem_init/sem_wait/sem_post/sysconf added to RESERVED_RUNTIME_SYMBOLS (checked at type-check time, before --target is known, so this can't be conditional on it).

Tests (+21: 4 in platform.rs, 2 in main.rs, 15 in tests/frontend.rs): Target::default()/triple()/parse() round-trip coverage; Linux-target IR-shape assertions mirroring every existing Windows par-pool shape test (pthread_create/sem_init/sem_wait/sem_post call counts match CreateThread/CreateSemaphoreA/WaitForSingleObject/ReleaseSemaphore's exactly — 1/3/3/3 — and never mention a Win32 symbol); a Windows-target regression test pinning the new i64 tid array and confirming zero POSIX symbols leak into the default build; extern fn rejection tests for the two new reserved POSIX names; clang_target_flag unit tests. Verified by hand (not linkable on this Windows dev box, no Linux sysroot) that `star emit llvm --target=linux` on a par/swarm program produces clean IR with no internal-verifier errors. Full suite: 1530 passed (77→81 lib, 15→17 main, 1522→1530 frontend).

Implemented todo.md P2 #7: closed the binop-dispatch unification question by picking "bound explicitly, don't force-fold further" -- documented as the permanent decision, plus new high-coverage tests confirming the resulting dispatch actually behaves correctly.

The code already had `Wrapping<T>`/`Fixed<Bits,Frac>` folded into one shared exact-type-match branch in `Checker::infer_binop_ty` (`src/types/expr.rs`) -- both families need identical treatment (every arithmetic/comparison operator, exact `lhs_ty == rhs_ty`, no implicit widening, `Fixed` additionally rejecting `%`) -- but that reasoning was only scattered across inline `//` comments next to each branch, not stated as a decision anywhere a future contributor would see it before reaching for `infer_binop_ty` itself. `Tick`/`Duration`/`Instant` were, and remain, a separate dedicated `infer_time_binop_ty` table: their legal pairings are asymmetric per operator and per type (`Tick + i64 -> Tick` but `Tick + Tick` illegal; `Instant - Instant -> Duration` but `Instant + Instant` illegal), which doesn't fit the shared branch's "operands match, result mirrors operand type" rule at all -- folding them in would mean replacing that rule with a per-`(lhs, op, rhs)` table, i.e. becoming the dedicated table it already is, not a simplification.

src/types/expr.rs: added a doc comment directly on `infer_binop_ty` itself (not just the scattered inline comments at each branch) stating this split as the permanent decision -- a future `Wrapping`/`Fixed`-shaped type gets one new match arm in the shared branch, a future asymmetric time-like type gets its own `infer_*_binop_ty` sibling, and nobody should re-litigate merging the two approaches.

Tests (tests/frontend_wrapping_fixed_time.rs, +13): closed real coverage gaps the shared-branch/dedicated-table split specifically hinges on -- `Wrapping<T>` comparisons end to end (previously only `Fixed` had a comparison test), a signed-vs-unsigned ordering test (`Wrapping<i8>(-1) < Wrapping<i8>(1)` is `true` under `slt`, but the same bits as `Wrapping<u8>(255) < Wrapping<u8>(1)` is `false` under `ult` -- would only surface here if the signedness flag were ever dropped/hardcoded), `Wrapping`-vs-`Fixed` and `Fixed`-vs-bare-`int` mismatch rejection (the two families sit right next to each other in the same source branch), a mismatch test for comparisons specifically (not just arithmetic), and — for `Tick`/`Duration`/`Instant` — `Tick` ordering end to end, `Tick < i64` rejection (proving comparisons don't inherit `Add`/`Sub`'s bare-`i64` allowance), `Instant + Instant`/`Tick - Duration` rejection (asymmetric-table gaps), and `Tick`/`Instant` division/modulo rejection (previously only `Duration` had a multiply-rejection test). Full suite: 1543 passed (unchanged elsewhere; +13 in the wrapping/fixed/time file specifically). One pre-existing, unrelated failure confirmed via `git stash` to reproduce identically on unmodified `main`: `runtime_gamepad_count_zero_and_open_null_with_no_device_end_to_end` fails on this dev box because a real gamepad is attached, not because of anything in this change.
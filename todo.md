# Star Compiler — Next Steps

Prioritized from [current_status.md](current_status.md)'s technical review.
Ordered by how much each item protects the investment already made (the last
review's 13-item punch list, now fully closed) versus adds new surface area
— biggest lever first within each tier.

## P0 — Protects existing investment / structural

1. **Scale the `par`/`swarm` worker pool to actual hardware.** `NUM_WORKERS:
   u32 = 4` (`src/codegen/par_pool.rs:43`) is a hardcoded compile-time
   constant baked into every generated program, not queried at runtime. Query
   the real core count (`GetSystemInfo`'s `dwNumberOfProcessors`, with an
   optional explicit override) so the "swarm" pitch's actual performance
   matches the hardware it runs on instead of always assuming 4 cores.
2. **Make the Windows-only scope an explicit decision, not a default, before
   more Win32-specific machinery lands.** `par_pool.rs` (`CreateThread`),
   `audio.rs`, `gamepad.rs`, and `system_font.rs` (GDI) each independently
   deepened the same Win32 coupling this round, with no platform-abstraction
   seam anywhere in codegen. Either update `readme.md`/`docs/design.md` to
   scope Star explicitly as a Windows-only game language (so nobody is
   surprised later), or identify the seam a future OS-primitives
   abstraction would need now, while the surface is still small enough to
   retrofit cheaply.

## P1 — Real design gaps

3. **Decide and document the dynamic-dispatch story.** Traits today are
   structural sugar over monomorphization — no vtable, no `dyn Trait`, no
   heterogeneous collection of mixed concrete types satisfying one trait —
   and only structs may implement a trait at all (`check_impl`'s struct-only
   restriction). The design doc's own `Player`/`Damageable` flagship example
   reads like it wants runtime polymorphism over a mixed collection; either
   commit explicitly to "generics/traits are compile-time-only, full stop"
   and adjust that example/prose to stop implying otherwise, or scope what a
   `dyn Trait`/tagged-enum-of-variants alternative would need for the one
   real motivating use case (heterogeneous ECS component lists).
4. **Allow enums to implement traits, or document why not.** The struct-only
   restriction on `impl Trait for ...:` was a reasonable bootstrapping choice
   when traits were new; now that trait-bounded generics and operator
   overloading are both real, load-bearing features, the asymmetry (a
   fieldless enum can't satisfy even a trivial trait bound) is worth either
   closing or naming as an intentional limitation in
   `docs/language_reference.md`'s "Traits and Implementations" section.

## P2 — Maintainability

5. **Split `tests/frontend.rs`** (1,514 tests, ~1.45 MB — by far the largest
   file in the repo) **into topic-scoped files**, mirroring `src/codegen/`'s
   own 35-file decomposition (e.g. one test file per codegen module, or at
   minimum separating checker-diagnostic tests / codegen-shape tests /
   runtime end-to-end tests into their own files). No functional change
   needed — this is purely about keeping "find existing coverage before
   adding more" cheap as the suite keeps growing every session.
6. **Finish (or explicitly bound) the binop-dispatch unification.** The P3
   #12 abstraction pass (`Ty::eq_only_scalar_shape`) only unified the
   equality-only types (`Symbol`/`BitField<N>`/`Flags<E>`/`Color32`/
   `PaletteIndex`); `Wrapping`/`Fixed` and the `Tick`/`Duration`/`Instant`
   family still get bespoke per-type branches by design. Either fold the
   arithmetic-bearing types into a similar shared table where their
   semantics genuinely overlap, or write down explicitly (in a doc comment
   next to `infer_binop_ty`) that these are irreducibly special so the next
   contributor doesn't re-litigate the question.

## P3 — Process

7. **Treat a review like this one as recurring, not one-off.** The prior
   punch list — 13 items, several structural — was fully closed in about two
   days. At that velocity, new special cases and new untested code paths can
   accumulate faster than periodic manual review catches them. Consider a
   `.clinerules/workflows/` trigger tied to feature-batch size (e.g., "every
   N changelog entries" or "before any session that touches a new codegen
   module") rather than only running a full assessment when asked.
8. **Start scoping minimal editor tooling** — at minimum a TextMate/
   Tree-sitter grammar for syntax highlighting. No LSP urgency yet while the
   syntax is still moving, but even highlighting would materially help
   anyone other than the primary author read `.star` code, and it's cheap
   relative to everything else on this list.

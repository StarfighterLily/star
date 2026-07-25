# Star Compiler — Next Steps

Prioritized from [ASSESSMENT.md](ASSESSMENT.md)'s technical review. Ordered by
risk-to-the-language's-own-thesis and how much each item unblocks real
programs, biggest lever first within each tier.

## P0 — Structural risk (affects every future feature, not just one gap)

1. **Add an IR-validity check ahead of the `clang` boundary.** Several
   confirmed bugs (`frame:` block ending in `return`, trailing `if/else` with
   a bare-ident arm) were `star check`-clean but produced invalid LLVM IR
   that only `clang` caught. At minimum: assert every emitted basic block
   ends in exactly one terminator before handing `.ll` to `clang`, and assert
   every `emit_expr` return value carries its type tag (`reg_of`'s own
   documented convention) before it reaches a `phi`/merge site. This is the
   single highest-leverage fix — it closes an entire *class* of bug the
   hand-rolled textual-IR approach will otherwise keep re-discovering one
   feature at a time. -- Done: See previous work below for details.
2. **Audit every f-string/`print`-family format-specifier table for missing
   type arms.** The fieldless-enum-prints-as-garbage-hex bug (silent wrong
   output, no crash, no diagnostic) is the worst bug class this project has
   shipped, and it was only caught by a human reading console output. Write
   an exhaustive test that round-trips every `Ty` variant through `print`/
   f-string interpolation and fails loudly on any silent fallthrough to a
   catch-all specifier, so the next new type can't ship this bug again. --
   Done: See previous work below for details.
3. **Give `Map`/`Set`/`Symbol` real hash-table backing.** Currently O(n) on
   every operation, which directly contradicts the "AAA entity counts"
   framing used to justify `Symbol` in the first place. This is a purely
   internal change (docs already say so) — no syntax/semantics shift needed,
   just replacing the linear scan with a real hash table behind the existing
   API. -- Done: See previous work below for details.

## P1 — Gaps that block realistic multi-file / at-scale programs

4. **Module search-path resolution + minimal manifest.** `projects/snake`'s
   own dogfooding notes call this "the most significant gap ... still open."
   Every import is a hand-written relative path with no project root, no
   search path, no package identity. Needed before any project bigger than a
   handful of files is comfortable to maintain. -- Done: See previous work
   below for details.
5. **Make `frame:`'s bump-allocator budget configurable per block**, mirroring
   the fix already done for arena capacity (`arena Name: Type = N`). The
   hardcoded 4096-byte cap is easy to blow with unremarkable code (confirmed
   by the doc's own A*-pathfinding example) and there's currently no way to
   size it to the actual workload. -- Done: See previous work below for
   details.
6. **Reconcile the `par`/`swarm` concurrency docs with what's implemented.**
   `docs/design.md`/`docs/features.md` describe cross-system "compile-time
   locks" resolving overlapping component-array access across a tick; the
   actual `par_analysis.rs` check is a single-loop-only capture-mutation
   rule. Either document the real (narrower, still-sound) guarantee
   accurately, or extend the analysis to actually match the pitch — but stop
   letting the docs promise a scheduler that doesn't exist. -- Done: added
   `system`/`parallel` (`src/types/system_analysis.rs`,
   `src/codegen/system.rs`) — named systems declare an explicit per-arena
   read/write access list, and a `parallel:` block runs a set of them
   concurrently on the existing `par`/`swarm` worker pool after the checker
   proves no two listed systems hold a conflicting (>= 1 mutable) lock on
   the same arena, rejecting the block at compile time otherwise. See
   `docs/language_reference.md`'s "Cross-System Scheduling" section and
   `examples/parallel_systems.star`.

## P2 — Real but lower-blast-radius feature gaps

7. **Trait-bounded generics** (`fn f<T: SomeTrait>(x: T)`). Today a generic
   function can only move/store/return a `T` — it can't call a trait method
   or use an operator on it. Fine for container-shaped generics (`Box<T>`,
   `Stack<T>`), a real ceiling for anything else.
8. **Audio playback and gamepad input.** Long-deferred, explicitly and
   honestly labeled as such — but "game programming language" without audio
   is a real, user-visible hole, not a nice-to-have.
9. **A proportional/lowercase-aware text renderer**, or a documented,
   supported path to bind `SDL_ttf` for anything beyond a debug HUD. The
   current 5x7 uppercase-only bitmap font is fine for a score counter, not
   for shippable UI text.
10. **General place-projection into `Table<T>`** (`table[i].field = v`),
    closing the one documented gap in that type's method surface.

## P3 — Process / maintainability (won't block a single feature, but compounds)

11. **Stop discarding `todo.md`/`current_status.md` history wholesale.**
    Current workflow rewrites/clears both after every session
    (`.clinerules/workflows/todo`), so the only durable record of *why* a
    decision was made lives in scattered doc prose and `git log -p`. Keep a
    real `CHANGELOG.md` (append-only) even if `todo.md` itself stays a
    living scratchpad. -- Done: `.\changelog` now acts as the long-term storage for implementation documentation.
12. **Give the checker/codegen binop-dispatch pattern a real abstraction
    before it grows further.** Every new scalar-ish type (`Wrapping`,
    `Fixed`, `Symbol`, `Color32`, `Tick`/`Duration`/`Instant`, `BitField`,
    `Flags`) adds its own dedicated dispatch branch rather than folding into
    a general predicate, by design (each has different legal-operator
    semantics). That's the right call per-type, but the growing list of
    one-off branches is a maintainability trend worth addressing with a
    shared table/trait rather than continuing to hand-add arms.
13. **Document and/or fix the Windows build story.** Building this compiler
    today requires `cargo +stable-x86_64-pc-windows-gnu` plus a hand-
    maintained `vendor-libs` stub directory — a plain `cargo build` fails
    outright on the reference machine. Fine for a solo project; a real
    barrier if outside contribution is ever a goal.

# Previous work:

Made `frame:`'s bump-allocator budget configurable per block (todo.md P1 #5), mirroring the fix already done for arena capacity (`arena Name: Type = N`): the previously hardcoded 4096-byte cap on every `frame:` block's shared bump allocator is now overridable per block, closing the exact gap ASSESSMENT.md #4 named ("4096 bytes is easy to blow with unremarkable code ... the fixed ceiling itself remains a footgun with no compiler-facing way to size it to the workload").

- New grammar: `frame(N):` (an optional parenthesized byte-count literal directly after the `frame` keyword, mirroring `arena Name: Type = N`'s "= N" override rather than reusing that exact token sequence, since `frame:` has no name/type slot to attach `= N` after). A bare `frame:` keeps working unchanged and still gets the default budget.
- `src/ast.rs`: `Stmt::Frame` gained `budget: Option<u64>` (parallel to `ArenaDecl::capacity`). `src/parser/stmt.rs`'s `parse_frame_stmt` parses the optional `(N)`, rejecting a non-positive or non-integer-literal budget at parse time -- the exact same rule `parse_arena` already enforces for `= N`, for the same reason (a codegen-time bounds check has to know the value without evaluating anything).
- `src/types/mod.rs`: new `DEFAULT_FRAME_BUDGET: u64 = 4096` (the old fixed value, now just the default) and `MAX_FRAME_BUDGET: u64 = 16 * 1024 * 1024` (16 MiB -- unlike `MAX_ARENA_CAPACITY`, this isn't protecting a narrower-width field, just guarding against a typo'd budget reserving unreasonable address space). `src/types/stmt.rs`'s `Stmt::Frame` checker arm resolves `None` to the default and clamps-with-error anything over the max, producing `TypedStmt::Frame { budget: u64, .. }` (`src/types/hir.rs`) -- same clamp-not-abandon shape as `Item::Arena`'s own check, so one bad literal doesn't cascade into unrelated diagnostics.
- `src/codegen/mod.rs`/`src/codegen/stmt.rs`: unlike `arena` (a named top-level item that naturally gets a per-name `HashMap<String, u64>`), `frame:` is a bare, unnamed statement that can appear (and nest) anywhere, and every `frame:` block in a program shares one physical backing buffer (`@frame.buf`) rather than getting its own. Rather than trying to right-size that single buffer to the tightest bound actually used anywhere in the module (which would need an exhaustive scan of every `frame:` statement reachable from anywhere, including arbitrarily deep inside closure literals stored in lists/struct fields/call arguments, to stay sound), `@frame.buf` is now always allocated at the fixed `MAX_FRAME_BUDGET` size regardless of what any block requests -- cheap in practice since it's a `.bss`-resident zero-initialized global that costs nothing until a page inside it is actually touched. A new `Codegen::frame_budget: u64` field (saved/restored around `emit_frame_body` exactly like the existing `in_frame: bool` field, so nested `frame:` blocks with different budgets each enforce their own bound and the outer block's own budget is correctly restored once an inner one exits) is what `emit_frame_alloc`'s bounds check actually compares the running offset against, not the physical buffer's fixed capacity. The runtime abort message now names the block's own configured budget (baked in at compile time via Rust's own `format!`, exactly like `emit_arena_decl`'s dynamic-capacity overflow-warning message) instead of a hardcoded "4096-byte" string.
- Updated `docs/language_reference.md`'s "Frame Memory" section and added a new "Frame Limitations" section (mirroring "Arena Limitations") documenting the default/max/override grammar. Added `examples/frame_budget_configurable.star`, showing the exact 4480-byte allocation `examples/frame_overflow.star` proves aborts under the un-overridden default succeeding cleanly once its enclosing block raises its own budget with `frame(8192):`.
- Added 15 new tests to `tests/frontend.rs`: parse-shape tests (`frame(N):` sets `budget: Some(N)`, bare `frame:` sets `None`, non-positive/non-integer-literal budgets rejected at parse time), checker tests (over-max rejected, within-max accepted), codegen-shape tests (the physical buffer is always sized to the 16 MiB maximum; a `frame(64):` block's own bounds check and abort message use 64, not the buffer size or the old default), and five end-to-end runtime tests (an override allowing an allocation that aborts under the un-overridden default; the same allocation still aborting under the default to prove that contrast is real; the abort message naming the configured override; and nested `frame:` blocks with different budgets each enforcing their own bound independently, with the outer block's budget correctly restored after the inner one exits). Fixed one pre-existing test (`codegen_frame_alloc_uses_bump_allocator`) that had hardcoded the old fixed buffer size. Full suite (1371 tests) passes.

Implemented module search-path resolution and a minimal project manifest (todo.md P1 #4), closing `projects/snake/NOTES.md`'s own "most significant gap ... still open" finding: every `import` was a hand-written path relative only to the importing file, with no project root, no search path, no package identity.

- New `src/manifest.rs`: a hand-rolled parser (deliberately not a `toml`+`serde` dependency, consistent with this compiler's existing lexer/parser/codegen-everything-by-hand approach and its own documented aversion to a fragile build story, P3 #13) for a genuine subset of TOML -- `[section]` headers, `key = "string"`/`key = ["a", "b"]` values, `#` comments (honored inside neither kind of string literal), multi-line arrays. Two sections: `[package]` (`name`/`version`/`entry`, all optional) and `[paths]` (`search`, a list of extra import search directories relative to the manifest's own directory). Every field optional -- an empty `star.toml` is legal, useful purely to mark a directory as a project root. `find`/`load_from_dir`/`discover` cover both "look for a manifest directly in this exact directory" (an explicit directory CLI argument) and "walk up from here looking for the nearest one" (auto-augmenting an explicit file argument's search paths) -- deliberately different lookup shapes, since an explicit directory argument is a claim about exactly which project root is meant, while a file argument's manifest discovery is a purely additive convenience that must never silently change which file gets built.
- `src/modules.rs`: `resolve` (the existing 2-argument entry point, ~10 call sites across `driver.rs`/`main.rs`/`tests/frontend.rs`, all left untouched) is now a thin wrapper over a new `resolve_with_search_paths(module, root_path, search_paths)`, threaded through `resolve_inner`'s recursion so search paths reach arbitrarily-nested imports, not just the root file's own. An import resolves relative-to-the-importing-file first (unchanged, so it can never be shadowed by a same-named file reachable some other way -- mirrors a C compiler's `#include "foo.h"` checking the including file's own directory before any `-I` path), then each search-path directory in order, first match wins. A completely unresolvable import now lists every location actually tried in its diagnostic, instead of a bare single-path IO error.
- `src/driver.rs`: `Driver` gained `with_search_paths` (alongside the existing `new`, unchanged) and a new `resolve_input(file, extra_search_paths) -> Result<ResolvedInput, String>` that turns a CLI `file` argument plus explicit `-I`/`STAR_PATH` paths into a concrete entry file and the full ordered search-path list to compile with -- a directory argument must directly contain a `star.toml` (no ancestor walk: an explicit directory argument is an explicit claim about the project root) and resolves to the manifest's own `entry` (default `main.star`); a file argument is used verbatim (bit-for-bit identical behavior to every pre-existing single-file caller when no manifest is involved) with `star.toml` auto-discovered by walking up from its directory purely to augment the search-path list.
- `src/main.rs`: every subcommand that resolves imports (`check`/`build`/`emit`) gained `-I`/`--search-path <dir>` (repeatable, via a shared `#[command(flatten)] SearchPathArgs`) and now also honors a `STAR_PATH` environment variable (a `PATH`-style list), both routed through `resolve_input` before compiling -- `file` may now be a directory containing a `star.toml`.
- `projects/snake/star.toml` added (name/version/entry only, no extra search paths needed since that project's imports already sit flat in one directory) -- verified end to end with a real `star build projects/snake -L sdl/lib/x64 -l SDL2 -o ...` through the actual CLI binary, producing a working executable via the new directory-plus-manifest path.
- `docs/language_reference.md`'s "Modules" section and `readme.md`'s usage section documented the two-step resolution order and the manifest format/CLI flags.
- Added 16 new tests to `tests/frontend.rs` (search-path-directory resolution, relative-wins-over-search-path precedence, first-matching-directory-wins ordering, missing-import diagnostics listing every location tried, search-path propagation into nested/transitive imports, `resolve_input`'s file-vs-directory/manifest-vs-no-manifest/malformed-manifest matrix, and two full parse-check-codegen-clang-run end-to-end runtime tests proving the feature works for a real multi-file, manifest-rooted project, not just at the AST level), 44 new inline unit tests in `src/manifest.rs` (parser happy paths, string escapes, single/multi-line/trailing-comma array literals, a `]` inside a quoted path string not being mistaken for an array terminator, every parse-error diagnostic shape with correct line numbers, and `find`/`load_from_dir`/`discover`'s filesystem-walking behavior including the exact-directory-vs-walk-up distinction), and 4 new unit tests in `src/main.rs` for the `-I`/`STAR_PATH` merge-and-order logic. Full suite (1359 tests) passes.

Added an IR verification phase (src/ir_check.rs) that runs after LLVM IR codegen and before the IR is ever handed to clang, directly addressing the "Ugly #1" gap identified in ASSESSMENT.md: a hand-rolled textual IR emitter with no builder verifying well-formedness ahead of the clang boundary.

What it checks, grounded in reading the actual .ll dialect this emitter produces (not general LLVM IR):

Every basic block ends with exactly one terminator (ret/br/unreachable) and nothing follows it — this is the exact shape of the documented frame:-block-ending-in-return bug (store emitted after ret).
phi nodes are grouped at the top of their block, their incoming-label list matches the block's actual predecessors, and (best-effort) incoming value types agree with the phi's declared type — targets the documented "untagged register" bug.
No duplicate SSA register or function/global definitions (defense against the diamond-import mangling bug class).
Every branch target is a real label; every %register/@global reference resolves to something actually defined (skipping llvm.* intrinsics, which clang auto-declares from the call site).
ret types match the function's declared signature.
Wired into Driver::codegen (src/driver.rs) so every caller — star build, star emit llvm, and the test suite — gets it automatically rather than opt-in.

Validated it: scanned all 73 shipped .ll files plus the 7,900-line projects/snake/main.ll (zero false positives), ran it against all 1,331 existing tests (initially caught 3 real false positives from my own checker — a phi-type-parsing bug when the phi's type itself starts with [ — which I fixed and turned into regression tests), and added 16 targeted unit tests including direct reproductions of both historically-documented bug classes. Full end-to-end star build → clang → run still works correctly.

Robustness expansion (src/ir_check.rs):

Added Severity::{Error, Warning} to IrError — findings that clang genuinely rejects stay build-blocking Errors; findings that are legal-but-suspicious IR (e.g. an unreachable block) are non-blocking Warnings.
New checks: duplicate basic-block labels, unreachable/orphaned blocks (warning-only — validated against a real fixture, struct_destructure.ll's intentional unreachable catch-all block, confirming the severity split was necessary), and call-argument-count mismatches against in-module declare/define signatures (including correct handling of the call i32 (i8*, ...) @printf(...) explicit-signature syntax variadic calls actually use — caught and fixed a real bug in my first draft of that check).
Added a permanent regression test that runs verify() against all 74 shipped .ll fixtures and asserts zero Error-severity findings, plus a fuzz test (2000 random garbled inputs) and hand-written adversarial cases (unbalanced brackets, unterminated strings, huge integer literals) asserting the checker never panics.
Graceful failure (src/driver.rs, src/main.rs):

Driver::codegen_verified now wraps the call to ir_check::verify in catch_unwind: a bug in this best-effort heuristic checker degrades to a warning instead of crashing the whole compiler.
The generated IR is no longer discarded when verification fails — IrVerification { ir, errors, warnings } always carries the IR text. star build now writes the .ll file even on a verifier rejection (so a false positive isn't a dead end), and star emit llvm — the actual debugging tool — always prints the IR regardless of verifier findings.
Added star build --skip-ir-verify as an explicit escape hatch to let clang have the final word when the verifier is wrong.
Driver::codegen's signature (used by ~200 existing tests) is untouched — it's now a thin wrapper over codegen_verified.

Audited every f-string/print-family format-specifier table (todo.md P0 #2), directly targeting the fieldless-enum-prints-as-garbage-hex bug class. Found there are actually two independently-implemented specifier tables — println(f"...")'s direct-argument path (Codegen::emit_print_like, builtins.rs) and the general f-string-as-str-value path (TypedExpr::FStr, expr.rs) — each with its own `_ => %p` catch-all and its own history of missing arms.

Reproduced a new, worse instance of the bug class live: interpolating a struct/tuple/array/GenRef/Handle/closure/Ring value into an f-string compiled clean and ran clean, silently printing a garbage address (`println(f"point={p}")` for a two-i32-field struct printed `0000000000000001`) instead of erroring — worse than the enum case because these seven types lower to an LLVM aggregate passed *by value* (`%Name`/`{..}`/`[N x T]`/`%GenRef`/`{i8*,i8*}`), so tagging one as a vararg `%p` pointer is a real C-ABI mismatch, not just an unhelpful address.

Fixed two ways:
- Added `Ty::is_fstring_unprintable` (types/mod.rs) classifying `Named`/`GenRef`/`Handle`/`Tuple`/`Array`/`Ring`/`Closure` as having no defined print format; `Checker::infer_expr`'s `Expr::FStr` arm (types/expr.rs) now rejects interpolating one with a clean "cannot interpolate a `Ty` value into an f-string" diagnostic instead of letting it reach codegen.
- Made both codegen specifier matches exhaustive — removed the `_ => %p` wildcard entirely from both `emit_print_like` (builtins.rs) and `TypedExpr::FStr` (expr.rs), replacing it with explicit arms: the seven pointer-backed types (`List`/`Map`/`Set`/`Table`/`Palette`/`Bytes`/`Ptr`, all a bare `i8*`) keep `%p` as a deliberate, ABI-safe "print the address" arm; the seven aggregate-by-value types get `unreachable!()` (defense-in-depth — the checker should already have rejected them); the vector/matrix/`Fixed` types get `unreachable!()` too (they're filtered/substituted earlier in the same function). With no wildcard arm left, a future `Ty` variant that isn't sorted into one of these buckets now fails to *compile*, not just fails a test — the strongest form of "the next new type can't ship this bug again."

Added 4 new tests (tests/frontend.rs): two exhaustive round-trip tests (one per format-specifier table) covering all 32 printable `Ty` variants' exact expected output in one pass each, one smoke test confirming the 7 pointer-backed types still compile/run/print without crashing, and one confirming all 7 previously-silently-broken aggregate types now produce a clean diagnostic instead of miscompiled IR. Repurposed one obsolete pre-existing test (`codegen_println_fstring_interpolating_struct_releases_borrowed_reference`, which asserted RC-release behavior for a now-rejected pattern) into a checker-diagnostic test. Full suite (1335 tests) passes.

Gave `Map<K,V>`/`Set<T>`/`Symbol` real hash-table backing (todo.md P0 #3), replacing the linear-scan implementation with open addressing. Purely an internal codegen change — no syntax/semantics shift, `docs/language_reference.md`'s "no hashing/bucketing yet" note updated to describe the new O(1)-average behavior instead.

- New `src/codegen/hash.rs`: a structural-hash function generator (`hash_<mangled>(T) -> i64`, FNV-1a) mirroring `eq.rs`'s exact per-`Ty` coverage (same set `Checker::check_hashable_ty` accepts), so two structurally-equal keys always hash equal — including canonicalizing `-0.0`/`+0.0` for `Float`/`F64` before hashing, since `eq_fn_name`'s `fcmp oeq` already treats them equal but their raw bits differ. Threads a single `alloca`'d accumulator through recursive field/lane traversal rather than returning SSA values, sidestepping the `phi`-merging a `str` field's byte loop would otherwise need at arbitrary recursion depth.
- New `src/codegen/hashtable.rs`: shared open-addressing primitives — `emit_ht_probe` (linear-probe a `states`(`i8`: 0=empty/1=occupied/2=tombstone)+`keys` pair for a match or the first free-or-tombstone slot, `alloca`-based rather than `phi`-based across its several exit branches, mirroring `symbol.rs`'s pre-existing linear-scan shape), `emit_ht_first_empty` (rehash-only variant, no equality check), `emit_ht_grown_cap` (double-or-8 policy), and `emit_fill_i8`/`emit_fill_i64` (hand-rolled fill loops — this codegen never declares `@llvm.memset`).
- `Map<K,V>` (`src/codegen/map.rs`) and `Set<T>` (`src/codegen/set.rs`) payloads gained a `states: i8*` array (and `Map` a `tomb: i64` alongside `Set`'s) alongside the existing RC/CoW `i8*` object-pointer scheme; `insert`/`get`/`remove`/`contains` hash the key/element and probe instead of scanning. Growth (double capacity, starting at 8) trips at 75% load *including* tombstones, and always rehashes into a fresh all-empty table (clearing tombstones) rather than just copying, since capacity changes every element's bucket. `remove` now tombstones in place instead of swap-removing — element/key order was never a documented guarantee (the old swap-remove already said so), so this is a pure internal simplification, not a behavior change. CoW-clone (`emit_map/set_ensure_unique`) stays a flat same-capacity structural copy (states+keys+vals memcpy'd, then occupied slots retained), never a rehash, since cloning doesn't change `cap`.
- `Symbol` (`src/codegen/symbol.rs`) kept its append-only `@sym.data`/`@sym.len`/`@sym.cap` log (id = index, so `symbol_name`'s reverse lookup was already O(1) and untouched) and added a separate hash index (`@sym.tbl.ids`, `-1`-sentinel, no tombstones needed since interning never removes) accelerating the `string -> id` direction from a linear `strcmp` scan to an average-O(1) probe. Grows by rebuilding from `@sym.data` directly rather than migrating the old index's slots.
- Every `star_rc_alloc` byte-size argument and payload field-index literal (GEPs are positional) was updated for the new struct shapes; the generated release thunks now walk the full `cap`-length `states` array checking `== OCCUPIED` per slot instead of a contiguous `0..len` run, since live slots are no longer contiguous.
- Rebuilt and re-verified the two committed example binaries that exercise this path end to end (`examples/map_set.exe`, `examples/symbol_par_race.exe`) against the new codegen.
- Added 8 new tests (tests/frontend.rs): two codegen-shape tests confirming a `hash_<mangled>` function is now generated alongside the existing `eq_<mangled>`; a 300-key `Map<i32,i32>` stress test driving multiple grows, a full remove-half/tombstone/refill/re-verify cycle, and exact `len`/`contains`/`get` correctness at every stage; the `Set<i32>` equivalent (150 elements, dup-insert rejection, remove-a-third, refill); a `Set<Point>` test (100 distinct two-field-struct keys) pinning that the structural hash agrees with structural equality closely enough that no two distinct points collapse into one slot; a `Map<str,str>` growth/removal/refill test exercising RC-bearing key/value rehashing and release-thunk correctness; a `cap == 0` (never-inserted) `contains`/`remove` smoke test for both `Map` and `Set`, pinning the "probe loop's own bound skips the body, so an unguarded `mask = cap - 1 = -1` is never actually dereferenced" invariant; and a 300-string `Symbol` intern-index growth test confirming ids stay sequential and re-interning after several index rebuilds still dedups correctly. Full suite (1343 tests) passes.
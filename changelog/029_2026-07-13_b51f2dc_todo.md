# Star Compiler — Next Steps
1. Complete Priority Roadmap

## Priority Roadmap (derived from current_status.md suitability analysis)

Ordered biggest win → smallest, where "win" = how much it unblocks writing useful
programs relative to implementation effort.

### 4. Graphics / audio / input bindings
Core to the "game language" pitch but currently 100% aspirational
(`draw_sprite`, `flash_screen`, `wait` are documented but not implemented).
Highest effort of the "unlock capability" items — best sequenced after FFI (#1)
so it's a binding to SDL/similar rather than a from-scratch renderer.
- Window creation + framebuffer/pixel-blit as the minimal viable slice.
- Input polling (keyboard/mouse/gamepad).
- Audio playback (defer to last — least blocking for "useful program" broadly).

### 5. Module system: re-exports, search paths, manifest
Needed once any program grows past a few files. Current system only inlines one
relative-path file at a time with no transitive symbol visibility.
- Transitive re-export so `a` importing `b` importing `c` can reach `c`'s symbols.
- Search-path resolution instead of hand-written relative paths everywhere.
- Minimal package manifest (name, version, entry point) — defer a full package
  manager/registry until there's more than one real multi-file project to learn from.

### 6. Expand core standard library
The current 28 builtins cover almost no string/collection manipulation beyond
`List<T>`. Grow incrementally as real programs (see #8) expose actual gaps
rather than speculatively.
- String ops: split/join/trim/replace/contains/format beyond f-strings
- ~~A `Map`/`Dict` and `Set` type to complement `List<T>`~~ -- done:
  `Map<K,V>`/`Set<T>` landed (linear-scan lookup plus a generated
  structural-equality function per key/element type, not a hash table yet --
  see `docs/design.md`'s Type System plan and `examples/map_set.star`).
- Fill out math builtins as needed (trig, log/exp, etc.).

### 7. Wire up reflection into an actual runtime feature
`@export`/`@tweakable` currently only emit descriptive metadata strings — there
is no hot-reload runtime or file watcher consuming them yet. Lower priority
since it's a productivity/tooling win, not a capability unlock: nothing is
*impossible* without it, just slower to iterate on.

### 8. Build one real, non-toy program in Star
Everything in `examples/` and `tests/` tops out around ~40 lines of
single-feature demos. FFI and file I/O are now done, which is enough to write
a small file-backed tool; dogfood the language on one program larger than a
toy — this will surface real gaps faster than speculative stdlib growth, and
is the best validation that the "useful programs today" bar has actually
been cleared.

## Last actions:
Thorough bug-hunting round across the whole compiler, using four parallel research
agents (lexer/parser/modules/sequence, type checker, codegen data structures,
codegen io/net/par_pool/driver) plus manual verification of every finding against
the real compiler before fixing. Found and fixed thirteen real bugs -- several of
them independently confirmed by reverting the fix and watching the new regression
test fail with the exact predicted symptom -- all with new tests in
tests/frontend.rs (504 -> 539 tests, all green; all 39 examples still `star check`
cleanly):
1. **Critical, memory corruption**: `enum_payload_words` (src/codegen/mod.rs) sized
   a payload enum's shared `[W x i64]` buffer by naively summing each field's size
   with *no* inter-field alignment padding, while construction/destructuring
   bitcasts that same buffer to the variant's real, padding-correct LLVM struct
   type. Any variant mixing a sub-8-byte field with an 8-or-16-byte-aligned one
   (`bool`+`str`, or a `Vec3`) under-allocated the buffer and silently overwrote
   whatever followed it in memory. Fixed by extracting the same padding algorithm
   `type_size`'s `Ty::Named` case already used into a shared `padded_struct_size`
   helper, used by both.
2. `type_align` hardcoded alignment 8 for *every* `Ty::Enum`, but a fieldless enum
   is a bare `i32` (align 4) -- only a payload enum is the real 8-byte-aligned
   tagged union. Wrong alignment corrupted `@export`/`@tweakable` reflect-metadata
   byte offsets for any field following a fieldless enum.
3. `emit_logical_binop`'s (`&&`/`||`) `phi` merge hardcoded the `rhs` operand's
   *entry* label as its incoming block -- the exact same class of bug as the
   already-fixed `if`/`match`-as-value phi merges (todo.md's own item 9 from the
   previous round), just never applied to this call site. A list/`GenRef` index,
   nested logical op, or `if`/`match`-value on the right of `&&`/`||` opens its own
   blocks, producing invalid LLVM IR ("PHI node entries do not match
   predecessors"). Fixed by capturing `current_label` after evaluating `rhs`,
   mirroring the existing fix.
4. A field read off a `List<T>`-of-structs element (`points[0].x`) routed through
   `Codegen::emit_place`'s `ListIndex` arm -- a write-only path that unconditionally
   clones/un-aliases the list via `emit_list_ensure_unique`. Same bug class as the
   already-fixed `list_fields`/`list_index_read_obj` split (previous round's item
   6), just for a struct-element field projection instead of a scalar/nested-list
   read. Fixed with a new retain-free `emit_list_index_read_place`.
5. `Lexer::handle_line_start`'s blank-line detection checked for `\n`/`#` only --
   a CRLF blank line (`\r\n`, no leading spaces) lands on `\r` first, so it fell
   through to the indentation branch and (measuring width 0) popped every open
   indent level, corrupting the token stream for the rest of the block with no
   diagnostic, on any Windows-authored source file with a blank line inside an
   indented block.
6. `sequence`'s hoisted-name rewrite (`rewrite_expr`'s `Expr::Ident` arm) had no
   lexical hygiene: a `for` loop's induction variable, a lambda's parameter, or a
   match arm's bound name sharing a name with a hoisted field got silently
   rewritten to `self.<name>` throughout that inner scope instead of referring to
   the local binding -- the loop variable became dead and the block ran using the
   stale outer field value instead, no diagnostic. Fixed by threading a
   scope-aware "shadowed" hoist set (`without`) into each of the three binding
   sites.
7. `sequence.rs`'s `check_no_nested_yield` only recognized statement-form control
   flow (`Stmt::If`/`While`/`Frame`/`For`); a `match` used as a statement is
   `Stmt::Expr(Expr::Match{..})`, and an expression-form `if`/lambda literal
   reaches the checker the same way -- so a `yield` nested inside any of these
   slipped past this dedicated check and was only caught later by the generic
   type-checker fallback, with a strictly worse diagnostic. Added
   `scan_expr_for_nested_yield` to recurse into these expression-carried blocks.
8. `tcp_connect`'s `inet_addr` result was never checked against its `INADDR_NONE`
   (`0xFFFFFFFF`) failure sentinel before being used to `connect()` -- a malformed
   host string now fails cleanly (closesocket + null) instead of attempting a
   connect with garbage address bytes.
9. **`mut` was parsed and threaded everywhere but never once read by any check** --
   `docs/design.md`'s very first stated rule ("`mut` is required to change state")
   was a complete no-op: every `let`, parameter, `self`, and struct field was
   silently mutable regardless of the keyword. Implemented real enforcement: a new
   `Checker::mut_vars` set (scoped per-function, per-nested-block, and per-lambda
   exactly like `vars` itself, including shadowing correctness verified by a
   dedicated test) checked at every `Stmt::Assign`, plus a per-field `is_mut` check
   for the specific field being written. Two deliberate carve-outs, both matching
   how the language already uses these constructs: a `GenRef<T>` handle needs no
   `mut` on the local binding holding it (mirrors a Rust `&mut T` reference --
   mutability is a property of what it points to, not the handle), and a
   `par`/`swarm` loop variable is implicitly mutable (there's no `mut` keyword
   available in that syntax at all, and safety is already proven by
   `check_par_disjoint`).
10. A method declaring no `self` at all (an "associated function" still called via
    `obj.method(...)` syntax) had its call-site argument count silently
    mis-checked -- `check_call_args` was always told to skip the first declared
    parameter believing it was `self`, regardless of whether the matched method
    actually declared one. A wrong argument count went undetected by the checker,
    and codegen's call site unconditionally passed a receiver pointer as arg0
    regardless, corrupting the real argument shape at the LLVM level. Fixed by
    threading a real `has_self` bool (from the method's own declared signature)
    through both the checker's `self.methods` table and codegen's parallel table,
    replacing the syntax-shape guess.
11. `Pattern::Int`/`Pattern::Bool`/`Pattern::Compare` match-arm patterns were never
    checked against the scrutinee's type at all -- only their *coverage* was
    validated. Codegen's match-arm lowering hardcodes `icmp eq i32`/`icmp sle i32`
    for these regardless of the scrutinee's real LLVM type, so e.g. `match a_str:
    5 -> ...` type-checked cleanly and only failed at the opaque `clang` IR
    verifier step ("defined with type 'ptr' but expected 'i32'").
12. `resolve_type`'s `Type::Named` catch-all accepted *any* identifier as a valid
    type with no lookup against `self.structs` at all -- a typo'd/undeclared type
    name in a parameter, field, or return position silently "resolved" to a bogus
    `Ty::Named`, which `resolve_field_type` then treats as "already reported
    elsewhere" and quietly widens to the `unknown` placeholder, masking what should
    be a clean "undefined type" diagnostic (with a "did you mean" suggestion,
    matching `check_impl`'s existing style) right at the declaration.
13. `codegen_arena_includes_malloc` (a pre-existing test) relied on the bug in
    #12: its `arena EnemyArena: Point` referenced a `Point` struct that was never
    declared anywhere in the test's source. Fixed the test fixture rather than the
    (now-correct) checker behavior.

**Found but deliberately deferred** (a real, confirmed gap, but a missing-feature/
doc-mismatch rather than a silent-corruption bug, and a larger, riskier change than
this round's scope): a struct field's declared `= value` default expression
(`docs/design.md`'s own flagship example: `mut health: i32 = 100`) is parsed and
type-checked but never consulted by codegen -- `TypedExpr::StructLit`'s
constructor always zero-fills any field the call site didn't supply, by explicit
design (this is what lets a `sequence`'s desugared struct trail hoisted-local
fields the constructor never supplies). Making construction honor a field's own
declared default instead of zero, only when one exists, is a reasonable follow-up
but needs its own dedicated round with its own tests.


Thorough bug-hunting round across the whole compiler (parser/lexer, type checker,
codegen), using three parallel research agents (lexer/parser, type checker,
codegen list/closure/par_pool) plus manual review of file I/O, networking, RC,
arena, and the driver. Found and fixed nine real bugs, all with new regression
tests in tests/frontend.rs (478 -> 499 tests, all green):
1. `match` nesting had no depth guard of its own (unlike `parse_unary`/`parse_type`/
   `parse_block`) -- `parse_match` is reachable both as a bare statement and inline
   in another arm's body, and costs far more real stack per level than a plain
   paren/unary chain, so ~55-60 levels of nested `match` overflowed the stack well
   under `MAX_EXPR_DEPTH`'s 80-level threshold. Added a dedicated `match_depth`/
   `MAX_MATCH_DEPTH = 30` counter (src/parser/mod.rs, src/parser/expr.rs).
2. `expect_line_end()`'s failure was silently discarded (no `?`) in
   `parse_enum_variant`/`parse_trait` (src/parser/items.rs) -- garbage after an
   otherwise-valid enum variant or trait method signature produced two cascading
   diagnostics instead of one clean recovery.
3. **Critical, par/swarm data race**: `frame:` written directly inside a `par`/
   `swarm` body was never rejected (src/types/par_analysis.rs) -- `@frame.off`/
   `@frame.buf` are shared globals, so every worker thread would race on them
   unsynchronized. The *indirect* case (frame hidden behind a helper call) was
   already caught; the direct, more obvious case wasn't.
4. **Critical, par/swarm safety bypass**: the transitive spawn/despawn/`frame:`
   ban is keyed by each hazardous function's declared (template) name, but a
   generic function's call site names its *mangled* monomorphized form instead
   (`sneaky__i32`) -- never in the hazard set, so any generic function/method
   silently bypassed the ban just by being generic. Fixed with a new
   `mono_fn_of` map (mirroring `mono_struct_of`/`mono_enum_of`) resolving a
   mangled name back to its template before the hazard check.
5. `Pattern::Binding` (`match x: v -> v + 1`, binding the whole scrutinee to a
   name) was completely unusable: the type checker never inserted `v` into the
   arm's scope (any use failed "undefined name"), and codegen had no arm for it
   at all (would have hit "unsupported match pattern in codegen" once the first
   bug was fixed). Fixed both; also fixed the same pattern being incorrectly
   rejected as an unsafe mutation inside a `par`/`swarm` body.
6. A nested list-index *read* (`m[0][1]`, `m[0].len()`) silently triggered the
   copy-on-write uniqueness gate on `m` itself (src/codegen/list.rs) -- `list_fields`
   (the read path) resolved its base through `Codegen::emit_place`, whose
   `ListIndex` arm exists for writes and unconditionally clones/un-aliases the
   list before returning a pointer. A pure read now resolves through a new,
   retain-free `list_index_read_obj` instead.
7. `file_read`'s buffer sizing (`sext(ftell(end) - ftell(start))`) didn't clamp a
   negative result (e.g. `ftell` returning -1 on a non-seekable handle) before
   treating it as an unsigned byte count -- would have requested a ~u64::MAX
   `star_rc_alloc`/`fread` instead of failing cleanly. Clamped to 0.
8. A negative literal in a match compare-pattern (`<= -5`) parses as
   `Unary{Neg, Int}`, not `Expr::Int` directly (no negative-literal token) --
   codegen's `Pattern::Compare` arm only recognized a bare `Expr::Int` rhs, so
   this ordinary syntax hit "unsupported match rhs expression" instead of
   compiling. Folded the unary-negation case in.
9. **The most impactful bug found**: `TypedExpr::If`/`TypedExpr::Match`'s `phi`
   merges hardcoded each branch/arm's *entry* label as the incoming-block
   operand -- correct only if the trailing value is computed with zero further
   control flow. Any branch value with its own basic blocks (`&&`/`||`,
   `list[i]`/`gen_ref[i]` bounds checks, `frame:`, nested `if`/`match`) produced
   invalid LLVM IR ("PHI node entries do not match predecessors"), rejected by
   `clang` -- meaning `if`/`match` used as a *value* was broken for almost any
   non-trivial branch expression. Fixed generally: added `Codegen::current_label`
   (tracked by a new `open_block` helper, now the sole place any block label is
   emitted -- ~120 call sites across every codegen file migrated to it) and threaded
   it through both `phi` sites instead of the stale entry labels. Discovered while
   fixing a narrower, related gap: `Checker::trailing_value_ty` already existed and
   correctly handled a trailing `frame:` block, but `Expr::If`'s own type inference,
   `check_match_arm`'s arm-type inference, and closure return-type inference each
   independently hand-rolled a narrower "bare trailing expression only" check
   instead of reusing it -- now consolidated onto the one correct helper.

---

Bug-hunting round on the parser's recursion-depth guards, prompted by discovering
`rejects_deeply_nested_parens_does_not_overflow_stack` was actually crashing
(`STATUS_STACK_OVERFLOW`) rather than hitting its own depth guard. Found and fixed four
real bugs, all with new regression tests in tests/frontend.rs (471 -> 478 tests, all green):
1. `MAX_EXPR_DEPTH` (src/parser/expr.rs) was 200 but the real stack-overflow cliff on a
   debug build's default thread stack is ~100-150 levels -- the guard never actually
   triggered before the crash it exists to prevent. Lowered to 80.
2. `parse_type` (src/parser/mod.rs) had no depth guard at all -- `Type::Generic`/`Type::Fn`
   recursion on a deeply nested type annotation (`List<List<...>>>`) crashed the same way.
   Now shares `expr_depth`/`MAX_EXPR_DEPTH` with `parse_unary`.
3. `parse_block` (src/parser/stmt.rs) had no depth guard either -- deeply nested
   `if`/`while`/`for`/`match` blocks crashed the same way. Added a separate
   `block_depth`/`MAX_BLOCK_DEPTH = 60` counter (block nesting costs more stack per level
   than expression nesting, so a lower cap).
4. `lower_fstring`'s per-interpolation sub-`Parser` reset `expr_depth`/`block_depth` to 0
   at every nesting level, defeating the guard for nested f-strings -- now carries the
   outer parser's counters in. Investigating that surfaced a separate, more serious bug in
   the same function: it `?`-returned out of `sub.parse_expr()` on failure *before* merging
   `sub.errors` into the outer parser's error list, so a syntax error inside `f"{...}"`
   (e.g. `f"{1+}"`) silently dropped the whole enclosing statement from the AST with zero
   diagnostics instead of failing the parse. Fixed by merging errors before handling `None`.

Networking basics (#3): raw TCP socket builtins -- tcp_connect(host, port) -> ptr,
tcp_send(handle, data) -> bool, tcp_recv(handle) -> str, tcp_close(handle) -- new
src/codegen/net.rs wrapping Winsock2 (socket/connect/send/recv/closesocket), reusing
the ptr/is_null FFI machinery as the socket handle same as file_open. tcp_connect only
accepts a dotted-decimal IPv4 address (inet_addr, no DNS) -- HTTP/hostname resolution
stays deferred to a future FFI-bound library per this item's own note. Needs `-l ws2_32`
linked explicitly (not linked by default on this target, same as any other extern lib).
11 new tests in tests/frontend.rs (type-check, codegen-shape, and runtime end-to-end
including a real round trip against a std::net::TcpListener spun up in the test itself);
examples/tcp_socket.star added alongside.
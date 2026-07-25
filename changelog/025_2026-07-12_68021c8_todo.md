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
- String ops: split/join/trim/replace/contains/format beyond f-strings.
- A `Map`/`Dict` and `Set` type to complement `List<T>`.
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
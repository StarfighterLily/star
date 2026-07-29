# Cross-platform scope

Status: **intended, not yet scheduled.** A second (Linux) target is a real
goal of this project, not a hypothetical — but nothing below gets built
until there's an actual Linux devbox to build, link, and run the result on.
Every existing cross-platform claim in this repo (`codegen/platform.rs`,
`--target linux`) is IR-shape-verified only: inspected by eye, never linked
by a real Linux `clang`/`ld` or executed. That's a meaningfully weaker claim
than "ported," and this document exists so the gap between the two is a
tracked plan, not a silent asterisk. **Once a new devbox is running, this
file's priority order is the intended work order** — cheapest, most-isolated
surfaces first, so a first real Linux binary happens as early as possible
rather than being gated on the hardest item (fonts) finishing first.

This inventories every Windows-only surface in `src/codegen/`, not just
`system_font.rs` — `platform.rs`'s own doc comment only ever flagged the
font gap because it's the one with no cheap fix; the other gaps below are
smaller precisely because nobody had written them down next to each other
before.

## Already seamed

`codegen/platform.rs` — thread creation, semaphore alloc/wait/post, current
thread id, core-count detection. Real second implementation
(`pthread_create`/`sem_init`/`sysconf`) behind `Target::LinuxGnu`, exercised
by `par`/`swarm`. Nothing to do here beyond eventual devbox verification.

## Cheap: networking (`codegen/net.rs`)

`tcp_connect`/`tcp_send`/`tcp_recv`/`tcp_close` are thin wrappers over
Winsock2 (`WSAStartup`/`socket`/`connect`/`send`/`recv`/`closesocket`,
declared in `codegen/mod.rs`'s `emit_builtins`). This is the smallest gap in
the list — BSD sockets are Winsock's own ancestor API, and glibc's
`socket`/`connect`/`send`/`recv` already share Winsock's names and
signatures almost exactly. The differences a `Target::LinuxGnu` arm would
need to paper over, mirroring `platform.rs`'s existing
`emit_alloc_semaphore` pattern of presenting one uniform shape over two real
representations:

- **No `WSAStartup`/`WSACleanup` call at all** — POSIX sockets need no
  per-process init; the Linux arm simply skips emitting the call.
- **Close is `close`, not `closesocket`** — same signature (`i32 -> i32`),
  different symbol name.
- **Handle representation differs.** A Windows `SOCKET` is `UINT_PTR`
  (pointer-sized, opaque, reused here as `Ty::Ptr` since it's shape-
  compatible with a `FILE*`); a POSIX socket is a plain `int` file
  descriptor, and `-1` (not a null pointer) is the failure sentinel. This is
  the one real representation change — `emit_tcp_connect`'s null-check and
  `abort_if_null_socket`'s null-check would both need a `Target`-gated
  sentinel comparison (`icmp eq i8* ptr, null` vs. `icmp eq i32 fd, -1`), the
  same shape `platform.rs` already solves for `CreateSemaphoreA`'s handle
  vs. a `malloc`'d `sem_t*`.
- **`htons`/`inet_addr`** are POSIX standard (`<arpa/inet.h>`) with identical
  signatures — declare unconditionally, no `Target` branch needed, same as
  `platform.rs`'s reasoning for declaring GDI/Winsock symbols regardless of
  target.
- **Linking**: `ws2_32.dll` becomes `-lc` (already linked) — no `-l`
  flag needed on Linux for sockets at all, one fewer build-time requirement
  than Windows.

Net effect: a `Target::LinuxGnu` arm in `net.rs`'s handful of `emit_*`
methods, no new `Ty`, no new builtin surface. Realistically a few hours of
work once there's a Linux `clang` on hand to confirm the sentinel/linking
details against.

## Cheapest: environment variables (`codegen/os.rs`)

`env_set` calls `_putenv_s`, a Microsoft CRT extension (`<stdlib.h>`, MSVC/
MinGW only) — not POSIX. The direct equivalent is `setenv(name, value,
1) -> i32`, present in glibc `<stdlib.h>`. Same argument count, similar
"0 on success" convention (`setenv` returns `-1` on failure, not an
arbitrary nonzero `errno_t`, so `emit_env_set`'s success check would need
`icmp eq i32 result, 0` either way — no behavioral difference to callers).
`env_get`'s `getenv` is already POSIX-standard and needs no change at all.
This is a single `Target` match arm in `emit_env_set`, smaller than the
networking change — realistically under an hour once verified against a
real Linux libc.

## Hard, deliberately unstarted: text rendering (`codegen/system_font.rs`)

Unchanged from this module's own doc comment: GDI's font engine
(`CreateFontA`/`TextOutA`/`GetTextMetricsA`/...) has no POSIX syscall
equivalent — there is no "ask the OS to rasterize a TrueType glyph" call on
Linux the way `sysconf`/`pthread_create` cover the threading seam. The two
realistic options, in the order this project would pursue them:

1. **`stb_truetype.h`** (single-header, public-domain, ~5,000 lines of C) —
   vendor it as a small compiled C shim analogous to how `sdl/` is already
   vendored, expose a flat C ABI (`stbtt_InitFont`/`stbtt_GetCodepointBitmap`
   or a purpose-built wrapper) for `system_font.rs`'s `emit_*` methods to
   `declare`/`call` exactly like GDI's own flat ABI today. This is the
   "cheapest realistic vendor option" `todo.md` already named: no external
   DLL dependency at runtime (statically linked), no font-shaping ambitions
   beyond what GDI already provides (no complex-script shaping either way).
2. **`SDL_ttf` + `libfreetype`** — heavier (a real font-shaping library plus
   its own transitive dependency), but reuses the SDL_* binding pattern
   `codegen/sdl.rs` already established, and gets kerning/hinting from a
   library instead of hand-driving `stb_truetype`'s rasterizer.

Either path is a genuinely new rendering backend, not a retrofit — unlike
the two gaps above, this is real, scoped-but-unscheduled feature work, not
"add a `Target` match arm." `codegen/font`'s hand-rolled 5x7 bitmap font
remains the already-portable fallback for a program that needs *some* text
under both targets today.

## Not a code gap: SDL2 itself (`codegen/sdl.rs`, `audio.rs`, `gamepad.rs`)

`window_create`/audio/gamepad all bind SDL2's own C ABI, which already ships
real Linux builds — nothing in `sdl.rs`/`audio.rs`/`gamepad.rs` is Win32-
specific code needing a `Target` branch. The gap here is packaging, not
codegen: `sdl/` (this repo's vendored copy) currently only vendors Windows
headers/import libs/DLL, so `star build --target=linux` has no
`-L`/`-l`/runtime-`.so` story to hand `clang`/`ld` yet. Vendoring a Linux
SDL2 build (or documenting a `apt install libsdl2-dev`-style system-package
expectation instead of vendoring) is a packaging task for whoever sets up
the devbox, not a `src/codegen/` change.

## What "devbox" unblocks specifically

Every item above is currently unverifiable past "the emitted IR looks
right" — this repo has no Linux `clang`, `ld`, or libc to actually link
against, so `--target=linux` output has never been build-tested end to end
(see `readme.md`'s "Platform Support" section and `Target::LinuxGnu`'s own
doc comment). A devbox changes that from "plausible" to "proven": each item
above becomes a small, independently landable, real-clang-verified change
instead of IR that's only ever been eyeballed.

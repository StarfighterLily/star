# Cross-platform scope

Status: **priority order complete except fonts.** A second (Linux) target
is a real goal of this project, not a hypothetical, and as of 2026-07-30
every item in this file's priority order except the deliberately-unstarted
fonts gap has been linked and *run* for real against a devbox: a WSL2
Debian instance (`clang` 19.1.7, GNU `ld` 2.44, `libsdl2-dev` 2.32.4),
reachable non-interactively over SSH (`localhost:2222`, key-based auth via
a dedicated `~/.ssh/id_star_devbox` keypair). Everything in this file
before 2026-07-30 (`codegen/platform.rs`, `--target linux`) was IR-shape-
verified only: inspected by eye, never linked by a real Linux `clang`/`ld`
or executed — that gap is now closed for networking, env vars, the
`par`/`swarm` thread pool, and SDL2/gamepad. Items are moved out of their
"unstarted" section and into "Already seamed" only once actually linked and
*run* against the devbox, not just emitted.

This inventories every Windows-only surface in `src/codegen/`, not just
`system_font.rs` — `platform.rs`'s own doc comment only ever flagged the
font gap because it's the one with no cheap fix; the other gaps below are
smaller precisely because nobody had written them down next to each other
before.

## Already seamed

`codegen/platform.rs` — thread creation, semaphore alloc/wait/post, current
thread id, core-count detection. Real second implementation
(`pthread_create`/`sem_init`/`sysconf`) behind `Target::LinuxGnu`, exercised
by `par`/`swarm` (and, via the same shared lock, `Symbol`/`rand`).
**Devbox-link-verified** 2026-07-30, the oldest claim in this file and the
last one still resting on IR-shape inspection alone until now: a `par`
program spawning 200 entities and decrementing each once under `par e in
Enemies` (real concurrent dispatch, not serial fallback) produced the
correct total every time across default/`STAR_WORKERS=1`/`8`/`64` and 8
repeated runs at `STAR_WORKERS=64` — no races, no wrong totals, real
`pthread_create`/`sem_init`/`sem_wait`/`sem_post`/`pthread_self`/`sysconf`
all exercised concurrently against genuine Linux glibc, not just emitted.
`Symbol`/`rand`'s shared `@sym.lock`/`@rng.lock` (the same primitives, used
serially rather than under real contention here) also produced correct
output in the same run. Linked with no extra `-l` flag at all — this
devbox's glibc (Debian, recent enough to have merged `libpthread` into
`libc`) needed no separate `-lpthread`, unlike older glibc.

`codegen/net.rs` — `tcp_connect`/`tcp_send`/`tcp_recv`/`tcp_close`. Real
second implementation behind `Target::LinuxGnu`, **devbox-link-verified**
2026-07-30: `star emit llvm --target=linux` on a small `tcp_*` test program,
`clang -target x86_64-unknown-linux-gnu` linked *on the devbox itself* (no
cross-linking from this Windows-hosted toolchain), then actually run against
a live `python3` echo listener on the same box — real connect/send/recv
round trip (`sent:true` / `reply:pong`) and a real refused-connection null
handle (`refused_is_null:true`), exit code 0. What the port turned out to
need, mirroring `platform.rs`'s `emit_alloc_semaphore` pattern of presenting
one uniform shape over two real representations:

- **No `WSAStartup`/`WSACleanup` call at all** — `emit_tcp_connect`'s
  `Target::LinuxGnu` arm skips that whole block; POSIX sockets need no
  per-process init.
- **Close is `close`, not `closesocket`** — same signature (`i32 -> i32`),
  different symbol name, both routed through a new shared
  `emit_close_socket` helper (used by `tcp_close` and `emit_tcp_connect`'s
  own cleanup paths alike).
- **Handle representation**: a Windows `SOCKET` is pointer-sized and reused
  directly as `Ty::Ptr`; a POSIX socket is a plain `i32` fd. Rather than
  giving socket handles a second `Ty` per target, the `i32` fd is packed
  into the same `i8*`-shaped handle with `sext`/`inttoptr` right where
  `socket()`/`connect()` produce it, and unpacked with `ptrtoint`/`trunc`
  (a new `socket_handle_to_fd` helper) immediately before each real POSIX
  call. That packing is why the existing `INVALID_SOCKET` check
  (`icmp eq i8* sock, inttoptr (i64 -1 to i8*)`) and `abort_if_null_socket`
  needed **no** `Target` branch at all, contrary to this doc's original
  guess: `sext`ing a `-1` fd to `i64` and `inttoptr`-ing it produces the
  exact same bit pattern Windows' `INVALID_SOCKET` check already compares
  against, and `tcp_connect`'s phi node collapses every failure path to a
  literal `i8* null` on both targets.
- **`send`/`recv` width**: glibc's `send`/`recv` take a 64-bit `size_t`
  length and return a 64-bit `ssize_t` on x86-64, unlike Winsock's
  `int`/`int` — `sext`/`trunc` around the existing `i32` length/result this
  module's callers already expect. Not anticipated by this doc's original
  draft (written before there was a real glibc header to check against).
- **`htons`/`inet_addr`** are POSIX standard (`<arpa/inet.h>`) with identical
  signatures — declared unconditionally, no `Target` branch needed.
- **Linking**: `ws2_32.dll` becomes nothing — glibc's already linked, no
  `-l` flag needed on Linux for sockets at all.

Net effect matched the original estimate: a `Target::LinuxGnu` arm (plus two
small shared helpers) in `net.rs`, no new `Ty`, no new builtin surface. See
`codegen/net.rs`'s own module doc comment for the implementation, and
`tests/frontend_networking.rs`'s `Target::LinuxGnu` section for the IR-shape
regression coverage (this crate's test suite has no Linux clang/ld to link
against, so those tests pin down IR shape the same way
`tests/frontend_par_swarm.rs` already does for `platform.rs` — the actual
link/run proof above was done by hand against the devbox, not from `cargo
test`).

`codegen/os.rs` — `env_set`. Real second implementation behind
`Target::LinuxGnu`, **devbox-link-verified** 2026-07-30: `emit_env_set`
now calls glibc's `setenv(name, value, 1) -> i32` instead of `_putenv_s`
(a Microsoft CRT extension, not POSIX) via a new `declare_os_externs`
(mirrors `net.rs`'s `declare_net_externs`). Same argument count (`setenv`
takes one extra fixed `overwrite = 1` argument), same "0 on success"
convention (`setenv` returns `-1` on failure, not an arbitrary nonzero
`errno_t`, so `emit_env_set`'s existing `icmp eq i32 result, 0` check needed
no change at all) — matched this doc's original estimate exactly, the
smallest of the three code gaps. `env_get`'s `getenv` was already
POSIX-standard and needed no change.

Verified the same two ways as `net.rs`: `Target::LinuxGnu` IR-shape tests in
`tests/frontend_method_calls_and_builtin_validation.rs`, and a real
`star emit llvm --target=linux` → `scp` → devbox-native `clang` link → run,
exercising an unset var (`before:[]`), a fresh `env_set`/`env_get` round
trip, and an overwrite — all correct, exit code 0.

`codegen/sdl.rs`/`audio.rs`/`gamepad.rs` — `window_create`/`clear_screen`/
`draw_rect`/`present`/`get_pixel`/gamepad queries. This was never a codegen
gap (`window_create`/audio/gamepad all bind SDL2's own C ABI directly,
nothing Win32-specific needing a `Target` branch), only a packaging one:
`sdl/` (this repo's vendored copy) only ever vendored Windows headers/
import libs/DLL, so `star build --target=linux` had no `-L`/`-l`/runtime-
`.so` story to hand `clang`/`ld`. `libsdl2-dev` 2.32.4+dfsg-1 installed
system-wide on the devbox closed that gap from the Linux side — **devbox-
link-verified** 2026-07-30: a `star emit llvm --target=linux` program was
linked on the devbox with a bare `-lSDL2` (**no `-L` flag needed at all**,
unlike Windows' vendored `-L sdl/lib/x64` — a real, if minor, packaging
story difference between the two targets), then run headless under
`SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy`: a real window create /
`clear_screen`(navy) / `draw_rect`(orange) / `present` / `get_pixel` round
trip read back exactly the colors drawn (both inside and outside the
rect), and `gamepad_count`/`key_down`/`mouse_x`/`mouse_y` all returned safe
defaults with no gamepad/display actually attached. Also ran successfully
with neither dummy driver set (SDL fell back on its own without one, no
`window_create` failure) — the dummy drivers were used deliberately for a
clean, deterministic headless run, not because the alternative broke.
`tests/frontend_sdl_graphics_input_and_geometry_audit.rs`'s
`codegen_sdl_and_gamepad_ir_is_target_invariant` pins the underlying claim
down as a checked regression: the `@main` call-site IR for this exact
sequence is byte-identical under `Target::LinuxGnu` and the default
`Target::WindowsGnu` (once the unrelated `@sym.lock`/`@rng.lock` init
lines — see `platform.rs` above — are filtered out), not just assumed
identical because nothing in `sdl.rs` mentions `Target`.

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

## What the devbox unblocked

No longer hypothetical: the WSL2 Debian devbox described at the top of this
file is online and reachable (`ssh localhost -p 2222`, key-based). Every
item in "Already seamed" above went through the same real proof —
`star emit llvm --target=linux`, `scp` to the devbox, `clang` linked
*there* (never cross-linked from this Windows-hosted toolchain, which has
no Linux sysroot), then actually executed and its output checked — not
just "the emitted IR looks right." The only surface left unstarted is text
rendering (see "Hard, deliberately unstarted" above), and deliberately so:
a devbox doesn't help there the way it did for everything else in this
file, since there's no POSIX syscall to link against in the first place,
only a from-scratch rendering backend to build.

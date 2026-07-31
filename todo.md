# Star Compiler — Next Steps

Seeded from `current_status.md`'s "Next steps, prioritized" section
(reviewed at commit `82be6e2`, 2026-07-30). This cycle's headline finding:
`readme.md`'s versioning-gate conditions are, independently re-checked
condition by condition, satisfied — but whether and to what version the
project actually moves is a call for the user, not this document, per
`CLAUDE.md`'s own "Things not to do" and three prior reviews' precedent.
See `current_status.md`'s "Goals vs. reality, honestly" for the full
checklist and "The Bad" #1 for why that decision isn't executed here.

**P0: Nothing to fix — no false "Done." markers last cycle, and the one
genuine bug found mid-stage (the `clang` large-aggregate-reassignment
pathology) was root-caused and fixed within the same stage that found
it, with new regression coverage.**

**P1: The one decision this whole cycle has been building toward.**
1. **Done.** The version has been bumped to `0.2.0`. See below for details.
2. **Done.** See `P1 #1 & #2` for details.

**P2: Real, still-open gaps — none block the version question above,
since the gate never named them.**
3. **Done.** `sound.star`'s leaked WAV handles. See below for details.
4. **Done.** `SMIX`/`SECHO`/`SREVERB`/`SFILTER` and `debugger.star`
   source-line breakpoints. See below for details.
5. The permanent structural caveats ("special guest" types unified in docs
   not mechanism, non-dynamic monomorphized-only traits, warning-only
   stack-budget check) — not gaps to close, but worth keeping as a standing
   line item so a future version decision doesn't have to rediscover them
   from scratch. (Windows-only-by-construction scope moved off this list
   2026-07-30 — a real Linux devbox is now online and the plan in
   `docs/cross_platform_scope.md` is active work, not a permanent caveat;
   see P2 #6.)
6. **Done.** A real WSL2 Debian devbox is now reachable for
   `docs/cross_platform_scope.md`'s Linux-port plan. Every item in that
   doc's priority order except the deliberately-unstarted fonts gap is now
   devbox-link-verified: `codegen/net.rs` (`tcp_connect`/`tcp_send`/
   `tcp_recv`/`tcp_close`), `codegen/os.rs` (`env_set`), `codegen/
   platform.rs` (the `par`/`swarm`/`Symbol`/`rand` thread-pool backend, the
   oldest cross-platform claim in this repo, re-verified rather than newly
   built), and SDL2/gamepad packaging (`crate::codegen::sdl`/`audio`/
   `gamepad` needed no codegen change at all, only a real Linux link
   against system `libsdl2-dev`). See below for details. Text rendering
   (`codegen/system_font.rs`, GDI-bound with no POSIX equivalent) is the
   one remaining genuinely-unstarted item, tracked in `docs/
   cross_platform_scope.md`, not carried here as an active work item.

**P3: Keep the cadence honest.**
6. This cycle was triggered two ways at once — `todo.md`'s own full
   completion, and the user asking for it directly — both converging on
   the same underlying question. Worth naming as a healthy sign, not a
   coincidence.
7. Continue starting the full `cargo test` run before drafting
   `current_status.md` rather than concurrently with it — two reviews
   running have now made this adjustment; keep doing it.

# Previous work
P2 #4: Closed out both halves of the item this cycle explicitly carried
forward for visibility rather than as an active work item, at the user's
direct request ("close out these issues and implementations once and for
all"). Neither half had a reference to port from, so both required real
design decisions rather than transcription:

`SMIX`/`SECHO`/`SREVERB`/`SFILTER` have no upstream implementation at all
(the Python reference's own `opcodes.py` marks all four `# unimplemented`
too), which is exactly why every prior cycle left them alone rather than
inventing bug-for-bug-unmatchable behavior. Asked the user which shape to
build before writing any code, since the options genuinely diverged in
effort and architecture, not just detail: real DSP built entirely in Star
against a new per-channel cached dry buffer (no native codegen changes), a
version requiring new native `crate::codegen::audio` "read back the live
mixer" builtins, or a minimal accept-but-inert wiring that stops short of
real audio. User picked the first. Design: `Cpu::sound_channel_last_wav`
(`cpu.star`, a `List<Bytes>` sized 8 for hardware channels 0-7 only —
`STRIG`'s 8-15 one-shot pool isn't cached, nothing stable there to apply an
effect to) caches the raw WAV buffer `op_splay` (`cpu_sound.star`) most
recently synthesized per channel; `play_tone`/`play_memory_sample`
(`sound.star`) now return `(handle, wav)` instead of just `handle` so that
cache has something to populate itself with. `SECHO`/`SREVERB`/`SFILTER
channel, param` (new `op_secho`/`op_sreverb`/`op_sfilter`) read that cache,
run it through new `sound.star` DSP (`apply_echo`: two decaying taps at a
20-500ms delay mapped from the operand; `apply_reverb`: a fixed 4-tap comb
scaled by the operand; `apply_filter`: a one-pole low/high/band-pass IIR,
reusing the same "one-pole running filter" shape `waveform_sample`'s
existing pink-noise case already established rather than introducing a new
technique), and re-trigger playback of the processed buffer on the same
channel via the existing `play_pcm_wav_on_channel` — an immediate "applies"
semantics matching `docs/nova16_instruction_reference.md`'s own present-tense
wording. `SMIX output` (new `op_smix`) averages all 8 cached buffers
sample-by-sample (`sound.star::mix_wavs`) onto `output`, which becomes that
channel's new cached buffer too, so a `SMIX` result is itself chainable into
a further effect. New `wav_sample_at`/`push_frame_amp` in `sound.star`
invert/mirror the existing `push_frame` encoding to read/write already-
amplitude-scaled samples (the cached buffer is already volume-scaled at
synthesis time). `assembler.star`'s `build_unimplemented()` no longer lists
these four (previously rejected at assembly time, mirroring the Python
assembler's own `UNIMPLEMENTED_INSTRUCTIONS` check); `cpu.star::execute`
gained real dispatch arms for `0x7F`-`0x82`; `disasm.star`/`debugger.star`'s
opcode tables flip their `verified` flag from `false` to `true` for all
four, since there's now a real handler to have cross-checked their operand
counts against. Every `Cpu`-constructing site (`main.star`, `debugger.star`,
`tests/run_bin.star`, `uart_bridge.star`) updated for the new field, backed
by a new `cpu::new_channel_wav_cache()` shared by construction and by
`free_all_sound_handles` (now also clearing this cache on `SSTOP`/`Reset`,
same as it already did for `sound_channel_handles`).

`debugger.star`'s source-line breakpoints needed a real line->address map
that didn't exist anywhere in this project — `assembler.star` gained a
fourth sidecar, `.lines` (`write_lines`), one `<source_line> <address>` row
per line that actually emits an instruction. A new `AsmLine::source_line`
field is threaded through `parse_line`/`finish_directive_line`/
`finish_instruction_line` from `main`'s own `raw_lines` loop index, and
`second_pass` records each `has_instruction` line's address (computed the
same way segment addresses already were, before that line's own bytes are
emitted) into two new parallel lists. `debugger.star`'s `break`/`b`/
`clear`/`c` now accept `:<line>` alongside the existing raw-address form
(`parse_break_location`, resolved through a new `load_line_table` — loaded
automatically next to `.sym`, both at startup and on `load`), and
`breakpoints`/`bp` plus a breakpoint hit during `run`/`continue` label their
address with `[line N]` (`line_suffix`, mirroring the existing
`symbol_suffix`) whenever the table has one. No upstream `nova_debugger.py`
behavior to match here — its own breakpoints are address-only too — so this
is a genuine addition, not a port.

Verified without any Rust-level changes (this was entirely Nova `.star`
source work) by rebuilding every Nova build target (`assembler.exe`,
`disasm.exe`, `debugger.exe`, `nova16.exe`, `tests/run_bin.exe`,
`uart_bridge.exe`) clean, then: (1) reassembling every checked-in
`tests/asm/*.asm`/`asm/*.asm` with the updated assembler and diffing the
resulting `.bin`/`.org`/`.sym` byte-for-byte against their pre-change
versions — all identical, confirming the new `source_line` tracking changes
nothing about actual code generation; (2) re-running the full existing
`tests/asm/*.bin` suite through `tests/run_bin.exe` — same `halted`/
`cycles_run`/`pc` as before on every file, no regression from the new
`Cpu` field or opcode dispatch entries; (3) a new checked-in smoke test,
`asm/sound_fx_test.asm` (same spirit as `sound_channel_test.asm`/
`sound_leak_test.asm` — no reference expected values exist for these four
opcodes, so this checks "runs clean to `HLT`, exercises every operand,
doesn't crash on an empty cache" rather than exact register values),
run via both `tests/run_bin.exe` (`halted=true`, exit 0) and `debugger.exe`
stepping all 29 instructions headlessly, plus confirming the underlying
temp WAV file's size actually reflects real DSP processing (117KB with the
echo/reverb tail padding vs. ~62KB for the dry buffer alone) rather than a
silent no-op; (4) `tests/debugger_test_commands.txt`/
`tests/debugger_test_expected.txt` extended with `break :1` (no code on
that comment line — confirms the error path), `break :67`/`breakpoints`/
`clear :67`/`breakpoints` (line 67 of `write_width_test.asm` is its `HLT`,
`0x006C` — the same address the pre-existing address-only breakpoint
commands already use, cross-checking both syntaxes against one known-good
address), regenerated via the script's own documented procedure, and
`run_debugger_test.ps1` re-run clean. `NOTES.md`'s "What's implemented"/
"What's not implemented"/"Assembler"/"Debugger"/"Ideas for future work"
sections and `sound.star`/`cpu_sound.star`/`assembler.star`/`debugger.star`'s
own header comments all updated to describe the real implementation rather
than the former "genuinely out of scope" framing.

P2 #6: A Linux devbox came online (user-set-up WSL2 Debian, reachable via
SSH at `localhost:2222`) and `docs/cross_platform_scope.md`'s
previously-unscheduled Linux-port plan became active work. Bootstrapping
non-interactive access took its own detour: the box's existing SSH key
(`~/.ssh/id_ed25519`) turned out to be passphrase-protected, which blocks
any non-interactive `ssh` call from this tool even after installing its
public half on the box, so a dedicated passphrase-less keypair
(`~/.ssh/id_star_devbox`) was generated instead, installed via one
`plink -pw` password login (PuTTY's CLI was already on `PATH`; plain `ssh`
has no way to feed a password non-interactively without `sshpass`, which
wasn't installed), and wired into `~/.ssh/config` with `IdentitiesOnly yes`
so the original personal key stays untouched. Confirmed the box has `clang`
19.1.7, GNU `ld` 2.44, and (once the user installed it) `libsdl2-dev`
2.32.4+dfsg-1 — everything `cross_platform_scope.md`'s priority order
(networking → env vars → SDL2 packaging → fonts) needs to start on.

Per that priority order, `codegen/net.rs`'s `tcp_connect`/`tcp_send`/
`tcp_recv`/`tcp_close` got a real `Target::LinuxGnu` arm: `declare_net_externs`
(new, mirrors `platform.rs`'s `declare_platform_threading_externs`) declares
POSIX `socket`/`connect`/`send`/`recv`/`close` instead of Winsock's
`socket`/`connect`/`send`/`recv`/`closesocket`, and skips `WSAStartup`
entirely (POSIX needs no per-process init). The one real representation
change — a POSIX socket is a plain `i32` fd, not a pointer — is handled
without giving socket handles a second `Ty` per target: the fd is packed
into the same `i8*`-shaped handle every other target uses for Star's `ptr`
type via `sext`/`inttoptr` right where `socket()`/`connect()` produce it,
and unpacked with `ptrtoint`/`trunc` (new `socket_handle_to_fd` helper)
immediately before each real POSIX call. That packing turned out to make
the existing `INVALID_SOCKET`/null-handle checks fully `Target`-agnostic
with no branching needed at all (sign-extending `-1` and `inttoptr`-ing it
produces the same bit pattern Windows' own check already compared against)
— a better outcome than `cross_platform_scope.md`'s original guess of a
`Target`-gated sentinel comparison. One thing that doc's original draft
didn't anticipate (written before there was a real glibc header to check
against): glibc's `send`/`recv` take a 64-bit `size_t` length and return a
64-bit `ssize_t` on x86-64, unlike Winsock's `int`/`int`, needing
`sext`/`trunc` around the existing `i32` length/result callers expect.
`closesocket`/`close` calls were unified behind a new shared
`emit_close_socket` helper used by both `tcp_close` and `emit_tcp_connect`'s
own cleanup paths.

Verified two ways, matching this doc's own reassessment-honesty standard of
not just eyeballing IR: (1) new `Target::LinuxGnu` IR-shape tests in
`tests/frontend_networking.rs` (declares/call-shape assertions, the
fd-packing `sext`/`inttoptr`/`ptrtoint` sequence, the internal IR verifier,
and a regression guard that the default Windows target is untouched),
mirroring `tests/frontend_par_swarm.rs`'s existing `Target::LinuxGnu`
coverage of `platform.rs` — full suite re-run clean (`cargo
+stable-x86_64-pc-windows-gnu test`, every file `0 failed`). (2) The thing
this whole devbox exists for: `star emit llvm --target=linux` on a small
`tcp_*` test program, the `.ll` shipped to the devbox over `scp`, and
`clang -target x86_64-unknown-linux-gnu` invoked *on the devbox itself* (no
cross-linking from this Windows-hosted toolchain, which has no Linux
sysroot) to produce a real ELF binary. Run against a live `python3` echo
listener also on the devbox: real connect/send/recv round trip
(`sent:true`/`reply:pong`) and a real refused-connection null handle
(`refused_is_null:true`), exit code 0 — the first Star-compiled Linux binary
this project has ever actually executed, not just emitted. `codegen/net.rs`
and `codegen/platform.rs`'s module doc comments and
`docs/cross_platform_scope.md` all updated to record the devbox coming
online and net.rs's now-verified status (platform.rs itself is still only
IR-shape-tested — re-verifying it against the devbox is follow-up work, not
folded into this entry).

Same pass, next item in the priority order: `codegen/os.rs`'s `env_set`
(`_putenv_s`, a Microsoft CRT extension, was the only non-POSIX call left in
that module -- `env_get`'s `getenv` was already POSIX-standard). Got the
`Target::LinuxGnu` arm this doc's own original estimate predicted almost
exactly: a new `declare_os_externs` (mirroring `net.rs`'s
`declare_net_externs`) declares glibc's `setenv(i8*, i8*, i32)` instead of
`_putenv_s(i8*, i8*)`, and `emit_env_set` calls it with a fixed
`overwrite = 1` last argument (matching `_putenv_s`'s own always-overwrite
behavior) -- same "0 on success" convention, so the existing
`icmp eq i32 result, 0` check needed no change at all. Verified the same two
ways as `net.rs`: new `Target::LinuxGnu` IR-shape tests in
`tests/frontend_method_calls_and_builtin_validation.rs` (full suite re-run
clean), and a real `star emit llvm --target=linux` -> `scp` -> devbox-native
`clang` link -> run, exercising an unset var, a fresh `env_set`/`env_get`
round trip, and an overwrite -- all correct, exit code 0.
`docs/cross_platform_scope.md` updated to reflect both `net.rs` and `os.rs`
now being devbox-verified, leaving only `platform.rs`'s re-verification and
SDL2 Linux packaging in the priority order before the fonts gap.

Closed out the rest of the priority order in the same pass. `codegen/
platform.rs` (the `par`/`swarm` thread pool, plus `Symbol`/`rand`'s shared
lock) needed no code change at all -- it already had a `Target::LinuxGnu`
arm, just never linked/run against a real Linux target before. Re-
verification: a `par` program spawning 200 entities and decrementing each
once under `par e in Enemies` (real concurrent dispatch, not the serial
fallback) produced the correct total (800) every time across
default/`STAR_WORKERS=1`/`8`/`64`, plus 8 repeated runs at `STAR_WORKERS=64`
specifically to catch any nondeterministic race a single run could miss --
none found. `Symbol`/`rand`'s shared `@sym.lock`/`@rng.lock` also produced
correct output in the same run. Linked with no extra `-lpthread` flag --
this devbox's glibc has `pthread_create`/`sem_*` folded into `libc` itself
(a recent-enough glibc), unlike older systems that need it split out.

SDL2/gamepad packaging (`crate::codegen::sdl`/`audio`/`gamepad`) also
needed no codegen change -- confirmed for real, not just asserted, by a new
regression test (`codegen_sdl_and_gamepad_ir_is_target_invariant` in
`tests/frontend_sdl_graphics_input_and_geometry_audit.rs`) that diffs the
`@main` call-site IR between `Target::WindowsGnu` and `Target::LinuxGnu`
for a `window_create`/`clear_screen`/`draw_rect`/`present`/`get_pixel`/
`gamepad_count` sequence and asserts it's byte-identical (aside from the
unrelated `@sym.lock`/`@rng.lock` init lines `platform.rs` owns). The real
gap was purely packaging: this repo's vendored `sdl/` only ever shipped a
Windows build, so `--target=linux` had no `-L`/`-l` story. With
`libsdl2-dev` installed as a system package on the devbox, linking needed
only a bare `-lSDL2` -- **no `-L` flag at all**, unlike Windows' vendored
`-L sdl/lib/x64`. Link/run-verified with a real window create /
`clear_screen` / `draw_rect` / `present` / `get_pixel` round trip, executed
headless via `SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy`: the read-back
pixel colors matched exactly what was drawn (both inside and outside the
rect), and `gamepad_count`/`key_down`/`mouse_x`/`mouse_y` all returned safe
defaults with nothing attached. Also confirmed it runs fine without the
dummy driver set at all (SDL falls back on its own in this WSL2 environment
with no display), so the dummy driver was a deliberate choice for a clean
deterministic run, not a requirement.

`docs/cross_platform_scope.md` restructured around this: `platform.rs` and
SDL2/gamepad both moved into "Already seamed" with their own verified-claim
paragraphs, the now-redundant standalone "Not a code gap: SDL2" section
folded into that same "Already seamed" entry, and the closing section
rewritten from "what a devbox would unblock" (hypothetical) to "what the
devbox unblocked" (done). `platform.rs`'s and `sdl.rs`'s own module doc
comments updated to match, plus `audio.rs`/`gamepad.rs`'s brief linking
notes (each pointed at `sdl.rs`'s own note already, so only needed the
"no `-L` under Linux" fact added). `readme.md`'s "Platform Support" section
-- previously written entirely in "gated on getting a devbox" future tense
-- rewritten to state plainly what's now real: only text rendering remains
Windows-only by construction, everything else (threading, networking, env
vars, graphics/audio/input) has a devbox-verified `Target::LinuxGnu` path,
and `--target linux` is still not a supported one-command cross-compile
(no vendored/detected Linux sysroot), just a real, tested cross-*emission*
path today. Full `cargo test` suite re-run clean throughout (0 failures in
any file) after every change in this round.

P2 #3: Fixed `sound.star`'s leaked WAV handles, the one remaining named
audio simplification. Every `SPLAY`/`STRIG` trigger built a fresh WAV
buffer, `sound_load`d it, and played it, but the returned handle was
discarded — `crate::codegen::audio`'s `sound_load` `malloc`s a fresh copy
of the whole file per call, so this leaked real heap memory on every
retrigger with no bound, growing without limit under sustained play (e.g.
a looping `SPLAY` retriggered every frame, or a `STRIG` sound effect fired
repeatedly). Fix: `sound.star`'s `play_pcm_wav_on_channel`/`play_tone`/
`play_memory_sample`/`trigger_effect` now return the new `ptr` handle
(`null_ptr()` on failure) instead of a bare `bool`; a new `Cpu` field,
`sound_channel_handles: [ptr; 16]` (`cpu.star`), tracks the one handle
currently occupying each of the 16 mixer channels this port addresses (0-7
`SPLAY`'s hardware voices, 8-15 `STRIG`'s round-robin pool); and
`cpu_sound.star`'s new `replace_channel_handle`/`free_all_sound_handles`
free a channel's previous occupant the instant a new one replaces it
there (safe with no per-channel "finished playing" callback, since
`sound_play_channel` has already overwritten that channel's `chan_base` to
the new buffer by the time the old one is freed — `sound_free`'s own
"stop any channel still using this buffer" scan finds no match for the
outgoing handle) or `SSTOP`/`Cpu::reinit` (`Reset`) free every tracked
handle outright. Every `Cpu`-constructing site (`main.star`,
`tests/run_bin.star`, `debugger.star`, `uart_bridge.star`) updated for the
new field. Verified with a new checked-in regression test,
`projects/nova/asm/sound_leak_test.asm`/`.bin` (retriggers the same
`SPLAY` hardware channel 20 times in a row with no wait for real playback
to finish, then saturates `STRIG`'s 8-slot round-robin pool twice over,
then `SSTOP`), run via `tests/run_bin.exe` — confirmed running clean to
`HLT` (exit code 0). Confirmed the test actually has teeth by temporarily
removing the null-handle guard in `replace_channel_handle`: the same test
then aborted immediately with `sound_free`'s own "null/freed sound handle"
runtime error, as expected, before the guard was restored. The existing
`sound_channel_test.bin` (todo.md P2 #5's own retrigger-a-looping-channel
scenario) and the full `tests/asm/*.bin` suite were re-run and still halt
clean. `main.star`/`debugger.star`/`uart_bridge.star` all rebuilt
successfully with the new field (`main.star`'s build needed `-l comdlg32`
in addition to `-l SDL2`, a pre-existing requirement for its native
"Open File" dialog, not a regression). `NOTES.md`'s "What's implemented"/
"What's not implemented"/"Known simplifications" sections and
`sound.star`/`cpu_sound.star`'s own header comments updated to describe
the fix rather than the former "intentionally leaked" framing.

Also surveyed the rest of the Nova project for any other undocumented
simplifications per this cycle's direct ask, cross-referencing `NOTES.md`'s
curated "What's not implemented"/"Known simplifications" sections (and a
fresh grep of every `.star` file under `projects/nova` for `leak`/`race`/
`stub`/`TODO`/`silently drop`/etc.) against what's already tracked here.
Nothing new surfaced: every remaining item is either already carried
forward as P2 #4/#5 above, or is explicitly documented as a deliberate,
justified design choice rather than a shortcut — e.g. `SBLEND` being a
stub is a confirmed bug-for-bug match with the Python reference (it never
calls its own blend-aware pixel write either), the timer ticking once per
instruction rather than per host clock cycle is inherent to writing an
interpreter rather than a cycle-accurate simulator, and the math library's
`f32`-vs-reference's-`f64` precision gap (reachable only in `POWR`/`EXP`'s
overflow thresholds) is already fully traced and accepted in `NOTES.md`'s
"Math library / Q8.8 fixed-point" section. No new P2 item warranted from
this pass.

P1 #1 & #2: Bumped version to an honest `0.2.0` across `cargo.toml` and `readme.md`, 
modified both `CLAUDE.md` and `.clinerules/general.md` to reflect the unbounded
version bump while raising the point to keep the version in sync across load-bearing
files and documentation alike to avoid stale version numbers anywhere, and 
updated `docs/conventions.md` to reflect the bump and further define incremental
policy (also reflected in Claude and Cline files).

See `changelog/069_2026-07-30_82be6e2_todo.md` and
`changelog/069_2026-07-30_82be6e2_current_status.md` for the full history
up to and including this cycle: a checked-in `debugger.star` regression
test (with a genuine live-pipe-vs-real-file stdin dead end recorded along
the way), F5-F8 hotkey verification closed for real (including a false
alarm from a demo binary's own deliberate `JMP $` idle loop), a concrete
"what does 'Nova complete' mean" checklist built and checked against
`NOTES.md`, a genuine new Star compiler bug (`clang` large-aggregate-
reassignment) root-caused and fixed, a true per-8-channel sound voice
model and real pink-noise filter for Nova's `SPLAY`, and `cpu.star`'s
opcode handlers split across 11 files by group — archived per the
reassessment protocol before this file was reseeded from the fresh
`current_status.md`'s "Next steps" section above.

See `changelog/068_2026-07-30_cacd569_todo.md` and
`changelog/068_2026-07-30_cacd569_current_status.md` for the cycle before
that (the repeated-f-string-call corruption bug root-caused and fixed, a
real assembler for `projects/nova`, and a real debugger plus GUI+controls
parity, a genuine Cpu SP/FP reset-value port bug found via the debugger's
first real use, and the `clang` build-time pathology first surfaced and
worked around) — also archived under the same reassessment protocol.

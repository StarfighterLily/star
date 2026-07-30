# Nova-16 in Star — implementation notes

**Read this framing note first if you're new to this file — it corrects a
stale impression the rest of this document used to leave.** Every round
before the disassembler round below described this project primarily as a
*language exercise*: something to "stress-test Star on a big, demanding
program" and "write down everything that broke." That framing was accurate
for a while, but it has quietly stopped being the point. Enough of this
project is now correctness-verified against the live Python reference,
byte-for-byte, with checked-in regression tests, that "Status: this port
now supersedes the Python reference" below is a real, evidenced claim, not
a boast — and enough Python-toolchain-equivalent tooling now exists (a real
binary loader, a real disassembler, real sound synthesis, a real UART host
bridge) that treating this as "a demo that happens to run Nova-16 programs"
undersells it. **The goal from here forward is to make this the de facto
Nova-16 emulator** — not "can Star do this," but "this is where you go to
run, inspect, and trust a Nova-16 program" — with the Python original
increasingly the *legacy* implementation instead of the ground truth. The
language-exercise angle doesn't disappear (every genuine Star compiler bug
found along the way is still recorded below, and still matters to that
other project), but it is no longer why this project exists. Concretely,
this means: don't reach for "acceptable simplification because this is
just a stress test" as a reason to skip real verification, real tooling, or
a real fix — hold this project to the same bar a standalone Nova-16
emulator project would set for itself, because that's what it now is.

A native reimplementation of the Nova-16 fantasy computer (originally a
Python emulator at a sibling project, `c:\Code\projects\Nova`) written in
Star, the language this repository's compiler implements: a 64KB unified
memory space, a ~190-entry instruction set, a register-code addressing
scheme, a 256x256 indexed framebuffer, and a keyboard/timer/interrupt
model.

There is a real binary program loader (see "Binary program loading" below),
a real disassembler (see "Disassembler" below), a real assembler (see
"Assembler" below), a real debugger (see "Debugger" below), and now
GUI+controls parity with the Python reference's own graphical tooling (see
"GUI+controls parity" below) — every concrete, named piece of `readme.md`'s
versioning gate's "tooling to match Python reference" condition is now
built. Test/demo programs no longer have to originate from the upstream
Python `nova_assembler.py` at all — this project can produce, inspect, run,
and interactively debug its own `.bin` files end to end. A real file-open
dialog now exists too (see "Load button and `open_file_dialog`" below) --
see "Ideas for future work" below for what's left unported by deliberate
scope cut (a UART-configuration dialog equivalent, mainly) rather than
genuinely missing.

**Expansion round** (this pass): the binary program loader itself, full
9-layer compositing (`LSWAP`/`LMOVE`/`LCOPY`, every drawing opcode now
`VL`-aware), memory-mapped sprites (`SPBLIT`/`SPBLITALL`), the UART
(`SERIN`/`SEROUT`/`SERSTAT`/`SERCTRL`), real host mouse plumbing
(`MOUSECTRL`/`MX`/`MY`/`MB` + the mouse interrupt), and register-model
stubs for the three sound opcodes the reference itself actually implements
(`SPLAY`/`SSTOP`/`STRIG`) — see each section below. Also found and fixed: a
genuine pre-existing port bug (not a Star compiler bug) in how a memory
destination's write width was resolved for `MOV`/`MOVZ`/`MOVNZ` — see "A
genuine port bug: MOV [mem], narrow-source write-width" below.

**Follow-up round**: a real user report ("programs loaded from the command
line close almost immediately") led to a genuine **Star compiler** bug —
`star build`-produced executables never had their stack size raised, so a
large struct like this project's own `Cpu` (grown considerably by the
9-layer compositing above) combined with just one more sizable local
elsewhere in the same call chain (`Screen::roll_x`'s pre-existing temp
buffer) could overflow the OS default 1MiB stack — see "Seven Star compiler
bugs found and fixed" #5 below for the full bisection and fix.

**Correctness round** (todo.md P0 #1): generalized the `MOV`-only
write-width fix to every opcode handler in `cpu.star` sharing the same
memory-write codepath, and — auditing every other memory-touching path for
the same class of bug while doing it — found and fixed two more genuine
port bugs (PUSH/POP's stack-slot width, and a BCD carry/borrow
masking-order bug this file had previously *mis-documented* as intentional
reference behavior) plus a genuine read-width bug in the BCD group. See
"Generalizing the write-width fix", "PUSH/POP always used a fixed 16-bit
stack slot", and "BCD operations" below. **This version now supersedes the
Python implementation** as the correctness reference for anyone working on
Nova-16 going forward — see "Status: this port now supersedes the Python
reference" below for what that means and what should be carried back.

**Disassembler round** (the first round explicitly framed around "de facto
emulator," not "language exercise" — see the framing note at the very top
of this file): a real disassembler, `disasm.star` — see "Disassembler"
below. Building it required knowing every opcode's exact operand count, so
every opcode in `docs/nova16_instruction_reference.md` was cross-checked
against `cpu.star`'s own `decode_operands(N)` call sites rather than the
doc being trusted at face value (this project's own established
precedent — see "Status: this port now supersedes the Python reference"
below) — that check found **ten real operand-count errors in the doc
itself**, now fixed there directly (see "Disassembler" below for the full
list). Writing the disassembler's hex/string formatting helpers also
surfaced **two genuine, previously-unknown Star compiler bugs**, both found,
fixed, and verified against the full `cargo test` suite with zero
regressions — see "Seven Star compiler bugs found and fixed" #6 and #7
below.

**Assembler round** (todo.md P1 #2): a real assembler, `assembler.star` —
see "Assembler" below. Unlike every prior round, this one found **zero**
new Star compiler bugs — the language handled everything the assembler
needed (a 180-entry `Map<str, i32>` opcode table, string-index-byte-by-byte
substring building, `Bytes`/`List<T>` threaded through by return value
across a two-pass design) on the first real attempt, both `star check` and
`star build` succeeding without a single fix needed at the compiler level.
Verified byte-for-byte identical to a fresh run of the live upstream
`nova_assembler.py` on every one of this project's existing checked-in
`tests/asm/*.asm` sources, plus two new ones covering directives/labels/
`EQU`/char-literals/negative-immediates (also byte-for-byte Python-matched)
and direct-indexed addressing (which the Python assembler cannot itself
produce — verified instead via `disasm.star` round-trip and live execution
on both the Python reference CPU over MCP and this port's own `cpu.star`).

**Debugger and GUI+controls round** (todo.md P2 #3, the reassessment's
headline finding for this cycle): a real debugger, `debugger.star` — see
"Debugger" below — and GUI+controls parity in `main.star` — see
"GUI+controls parity" below — the two remaining named-tooling gaps in
`readme.md`'s versioning gate. Building the debugger's `stack` command
surfaced a genuine, previously-unknown **port bug** (not a Star compiler
bug): every build target's `Cpu` construction initialized SP/FP (P8/P9) to
`0x0000` instead of the reference's real `0xFFFF` reset value (confirmed
against `core/regfile.py::RegisterFile.__init__`'s explicit `self.P[8] =
self.P[9] = 0xFFFF`, and against a fresh `debugger_init`/`get_cpu_state`
probe over MCP) — every existing checked-in `.asm` test happens to set SP
explicitly before touching the stack, which is exactly why this went
unnoticed until a debugger exposed the raw post-reset state. Fixed in all
four build targets that construct a `Cpu` (`main.star`, `debugger.star`,
`tests/run_bin.star`, `uart_bridge.star`); re-verified the full
`tests/asm/*.bin` suite against `tests/run_bin.exe` afterward (all 11
programs, including the two that exercise the stack —
`push_pop_width_test.bin`, which sets its own SP and was unaffected, and
`assembler_directives_test.bin`, whose `CALL`/`RET` round-trip doesn't set
SP at all and still matched its documented expected register values exactly
post-fix, since a push/pop pair returns the stack pointer to wherever it
started regardless of that starting value). A second, unrelated finding
while wiring up `main.star`'s `Reset` button: an early draft called a
`build_cpu`-style function (returning a fresh `Cpu` by value) a second and
third time for `Reset`, and that build took several minutes and multiple
gigabytes of `clang` memory just to link — three call sites to a function
returning a megabyte-plus struct, in one function, is a meaningfully
different shape from the single call site every other build target in this
project uses, and empirically triggers something close to the `clang`
optimizer pathology NOTES.md's own "Large fixed-array/struct construction
crashed or hung clang" bug writeup already describes for a different
(also since-fixed) shape. Not chased down to a compiler-level fix this
round (no reproducible minimal case isolated yet, and a working per-project
mitigation existed) — `main.star`'s `Cpu::reinit` does the equivalent reset
via ordinary loop-driven field/array writes into the existing `Cpu` instead
of a second/third full struct-literal-returning call, which builds and
links normally. Worth investigating for real if this shape ever recurs
elsewhere.

## Contents

- `star.toml` — project manifest.
- `docs/` — reference documentation copied from the upstream Python
  project (CPU spec, instruction reference, VRAM/sprite/sound/keyboard/UART
  specs, font format). `reimplantation_analysis.md`, the various profiler/
  monitor-tool READMEs, and anything assembler/debugger-specific were
  deliberately not copied — they document tooling and Python-side
  refactors, not the machine. Some of this doc set (`SPRITE_SYSTEM.md`'s own
  "Instructions"/opcode section, in particular) turned out to be stale
  against the actually-running reference — see "Layer compositing and
  sprites" below for what was cross-checked against source instead.
- `bits.star` — shift/rotate/parity/popcount/clz/ctz helpers for the CPU's
  *dynamic*-shift-amount instructions. Originally existed solely because
  Star had no bitwise/shift operators at all; now that it does (see
  "Language gotchas" #1 below), every *fixed*-amount shift/combine elsewhere
  in this project uses the real operators directly, and this file only
  covers the runtime-operand-amount case, whose clamping semantics
  deliberately differ from the operators' mod-width masking.
- `flags.star` — the 12-bit status register (`Flags`) and the
  arithmetic/logic/rotate flag-setting rules, ported
  from `core/flags.py::set_from_operation` directly (read from source, not
  guessed from the higher-level docs, which don't spell out the CMP-vs-SUB
  carry distinction).
- `palette.star` — the 256-color indexed palette (16 hue ramps x 16
  shades), same float formula per ramp as `nova/graphics/gfx.py`.
- `memory.star` — the 64KB unified address space plus the bank-switched
  0x8000-0xBFFF expansion window.
- `font_data.star` — the 8x8 1bpp font glyph table, mechanically generated
  from the upstream `font.py`, now as a real fixed-size array literal (see
  "Language gotchas" #5 below).
- `screen.star` — 9 compositing layers (base + 4 background + 4 sprite),
  each a 256x256 8bpp buffer, plus the VRAM staging buffer and drawing
  primitives (line/rect/circle/char/text/roll/shift/flip/rotate/fill/invert),
  all `VL`-layer-aware, and on-demand (uncached) compositing. See "Layer
  compositing and sprites" below.
- `uart.star` — the UART's data/status/control register model, RX/TX
  loopback semantics, and (`host_push_rx`) the real host-bridge RX path —
  see "UART" below.
- `sound.star` — real waveform synthesis (square/sine/sawtooth/triangle/
  white-noise/pink-noise-approximation/memory-sample) for `SPLAY`/`SSTOP`/
  `STRIG`, round-tripped through the host audio mixer via a generated WAV
  buffer. See "Sound" (in "What's not implemented"'s history) and its own
  header comment for the full approach and documented simplifications.
- `keyboard.star` — the 64-slot keyboard FIFO and its status/control
  register model.
- `loader.star` — the binary program loader: reads a compiled `.bin` (plus
  its `.org` sidecar, if present) via `file_read_bytes` into a `Cpu`'s
  memory. See "Binary program loading" below.
- `disasm.star` — the disassembler: decodes a compiled `.bin` back into
  readable Nova-16 assembly text. Deliberately independent of `Cpu`/
  `cpu.star` (a pure byte-stream decode, no machine state involved) and,
  unlike every other Nova build target here, links with no SDL2 dependency
  at all. See "Disassembler" below.
- `assembler.star` — the assembler: turns a `.asm` source file into a
  compiled `.bin` plus `.org`/`.sym` sidecars. Like `disasm.star`, a pure
  text-in/bytes-out tool independent of `Cpu`/`cpu.star`, with no SDL2
  dependency. See "Assembler" below.
- `cpu.star` — the CPU itself: registers, the register-code address space,
  operand decoding, the fetch-decode-execute cycle, every implemented
  instruction, interrupts, and the timer. Still the one large file in the
  project (register codes and opcodes spelled in hex — see "Language
  gotchas" #6 and #2 below); splitting it by opcode group is now *possible*
  since `impl` can cross a module boundary, just not done yet.
- `main.star` — SDL2 window, a small built-in demo program (used when no
  `.bin` path is given on the command line — see "Binary program loading"
  below), the main loop, keyboard/mouse-event plumbing, and (see
  "GUI+controls parity" below) a toolbar (Start/Pause, Stop, Reset, Step)
  and status bar plus F5-F8 hotkeys.
- `debugger.star` — the debugger: a headless CLI REPL (step/breakpoints/
  register-and-memory inspection/disassembly), independent of `main.star`'s
  graphical loop the same way `uart_bridge.star` is. See "Debugger" below.
- `uart_bridge.star` — a headless stdin/stdout UART host bridge entry
  point, separate from `main.star`'s graphical loop. See "UART" below.
- `tests/` — checked-in headless regression tests: `run_bin.star` (a
  generic `.bin` runner/register-dumper, built as its own small executable,
  no SDL needed), a handful of direct-field-poke Star harnesses for things
  no opcode can drive on its own (`mouse_interrupt_test.star`), and
  `asm/` (the actual `.asm` sources plus their `nova_assembler.py`-produced
  `.bin`/`.org`/`.sym` output). See "Testing" below.

## Building and running

```
star build projects/nova/main.star -L sdl/lib/x64 -l SDL2 -o projects/nova/nova16.exe
```

`sdl/lib/x64/SDL2.dll` must sit next to the built `.exe` (or be on `PATH`).
The demo draws a diagonal rainbow gradient (color = (x+y) mod 256 through
the palette) using nested loops, register arithmetic, and `SWRITE`, then
jumps back to address 0 and redraws forever. Press Escape or close the
window to quit.

The disassembler needs no SDL linking at all (see "Disassembler" below for
why):

```
star build projects/nova/disasm.star -o projects/nova/disasm.exe
projects/nova/disasm.exe projects/nova/tests/asm/write_width_test.bin
```

Neither does the assembler:

```
star build projects/nova/assembler.star -o projects/nova/assembler.exe
projects/nova/assembler.exe projects/nova/tests/asm/write_width_test.asm
```

## Architecture / design decisions

### Register storage: `Wrapping<uN>`, not plain `uN`

Every register that participates in arithmetic (`R0`-`R9`, `P0`-`P9`/`SP`/
`FP`, `VX`/`VY`/`VC`, timer/sound/mouse/RTC registers) is stored as
`Wrapping<u8>`/`Wrapping<u16>`, never a plain `u8`/`u16`. Star's
explicit-width integer types (`u8`, `u16`, ...) **trap** (process abort) on
overflow — the opposite of what a CPU register needs, since wraparound on
overflow is exactly what the Carry/Overflow flags exist to observe.
`Wrapping<T>` is the language's opt-in for silent wraparound arithmetic at
a fixed width. `PC` is `Wrapping<u16>` for the same reason (a program
executing right up to the top of the address space must wrap, not crash
the host process).

### One flat register-code address space

Every register — general-purpose, graphics, timer, sound, mouse, RTC, and
the `P0:`/`:P0`-style byte-halves — is reached through the same 8-bit
register-code byte (0x00-0xFF) the operand decoder uses, mirroring
`core/regfile.py::_build_register_code_map` exactly. `Cpu::get_reg_value`/
`set_reg_value` (a ~250-arm `match`) are the single source of truth; every
other register-touching opcode goes through them rather than special-casing
register kinds. This made addressing modes trivial: register-indirect
`[reg]` just calls `get_reg_value(code)` and uses the result as an address,
whether the register is 8-bit (R, a zero-page pointer) or 16-bit (P, a full
address) — no special-casing needed there either.

### Operand width is inferred from the destination register's kind

The instruction set has no explicit 8-bit/16-bit opcode variants — `ADD`
(say) covers both, and the operand width (8 vs. 16) is determined per
execution by inspecting the *destination* operand: an `R`-register
destination means 8-bit, anything else (`P` register, memory, or any other
external register) means 16-bit. This matches the upstream reference's own
`_resolve_single_operand`, **except** for one deliberate deviation: the
reference only special-cases `reg_type == 'R'` and falls back to 16-bit
memory reads even when the *actual* destination register is another 8-bit
register (`VX`, `SF`, `BANK`, ...) — plausibly a latent bug that never
manifests because real programs don't `MOV VX, [addr]`. This port uses each
register's *real* declared width (`Cpu::reg_width`) uniformly instead, which
is more defensible as "genuine machine architecture" than replicating a
reference-implementation quirk. Documented here in case it ever causes an
observable difference against real Nova-16 programs.

### 4-operand instructions are out of scope

The mode byte only encodes 3 operand addressing modes (bits 0-5); a fourth
operand's mode would have to reuse bits 6-7, which already mean
indexed/direct for every memory-mode operand in the instruction. The only
4-operand opcodes are `MEMCMP` and the string-library `STREXT`/`STREXTI` —
all skipped (string library is deferred anyway; `MEMCMP` alone wasn't worth
a special-cased decode path for this pass).

## Language gotchas hit along the way (and their fixes, applied here)

These weren't bugs — they were real constraints of the Star language/
compiler at the time this project was first written, and they shaped how it
was structured. All eleven were subsequently fixed at the compiler level
(tracked in [`todo.md`](../../todo.md), prioritized directly off this list)
and this project has now been updated to use every fix that has a genuine
call site here — see "Fixes applied to this project" below for the concrete
diff-level summary. Left in place (not just deleted) so a future session can
see both what the constraint used to be *and* what replaced it.

1. **No bitwise operators or shift functions at all.** No `& | ^ ~ << >>`.
   The free-function surface (`bit_get`/`bit_set`/`bit_clear`/`bit_toggle`/
   `bit_and`/`bit_or`/`bit_xor`/`bit_not`) covers single-bit ops and whole-
   register AND/OR/XOR/NOT, but there was no general "shift by N" primitive.
   `bits.star` built every shift/rotate (SHL/SHR/SAR/SAL/ROL/ROR/RCL/RCR)
   bit-by-bit from `bit_get`/`bit_set` instead of `<<`/`>>`. Multiply/divide
   by a power of two was considered and rejected for the arithmetic-
   right-shift case specifically: dividing a negative value truncates
   toward zero, not toward -infinity, so it doesn't reproduce sign-extending
   shift semantics. **Fixed:** real `&`/`|`/`^`/`~`/`<<`/`>>` operators now
   exist. Every *fixed*-amount shift/combine in this project (`bit_and`/
   `bit_or`/`bit_xor`/`bit_not` call sites, and `bits::shl16`/`shr16`/`shl8`
   calls whose amount was a compile-time-in-range literal — byte-half
   register packing, `SWAP`'s nibble swap, `read_word`/`write_word`) now
   uses the operators directly. `bits.star` itself is deliberately
   unchanged: its *runtime*-shift-amount functions (used by the actual
   `SHL`/`SHR`/`SAR`/`ROL`/`ROR`/`RCL`/`RCR` opcodes, whose amount is a
   CPU-supplied operand that can be any 0-255 value) have out-of-range
   clamping semantics ported from `core/exec.py` that deliberately differ
   from the new operators' mod-width masking — see `bits.star`'s own header
   comment for the full reasoning. Verified against a small headless check
   program exercising the P0 byte-half write/read, `vxy()`'s packed address
   calc, `AND`/`OR`/`XOR`/`NOT`/`SWAP` opcodes, and `SINV`, all matching
   hand-computed expected values.

2. **No hex integer literals.** `0x1F`-style literals didn't exist in the
   lexer at all — every register code, opcode number, and address constant
   in this project was written in decimal. **Fixed:** `0x`-prefixed literals
   now exist. `cpu.star`'s `get_reg_value`/`set_reg_value`/`reg_width`
   register-code matches and `execute`'s opcode dispatch (293 match-arm keys
   total) are now spelled in hex, matching
   `docs/nova16_instruction_reference.md`'s own opcode table directly
   instead of needing a decimal-to-hex lookup by hand. `main.star`'s
   hand-encoded demo program's opcode/register/mode bytes are hex too (the
   byte-offset address comments alongside them stay decimal — they're
   counting bytes, not encoding a register/opcode).

3. **`elif` doesn't exist.** Only `if`/`else`, so a multi-way branch was
   either a `match` with comparison-guard arms (`<= 15 ->`, works for
   ranges) or explicit `else:` + nested `if`. `match` with bare integer
   literal arms (`0x43 -> ...`) works fine and is what `Cpu::execute`'s
   ~100-entry opcode dispatch and the register-code `match` blocks are
   built from — confirmed against the existing `examples/brainfuck.star`
   before relying on it for this project's own dispatch table. **Fixed:**
   `elif` now exists. Every genuine same-subject `else:` + nested-`if`
   cascade in this project was flattened: `Cpu::decode_operand`'s
   4-way addressing-mode fallback, `Cpu::draw_text`'s control-code dispatch
   (NUL/tab/newline/CR/printable), `Cpu::check_interrupts`'s
   timer-then-keyboard priority check, and `screen::clamp_i32`. Nested
   `if`/`else` pairs that branch on *different* subjects (e.g.
   `Cpu::to_signed`'s width-then-sign check, `bits::sar8`'s
   range-then-sign check) were deliberately left alone — `elif` is for a
   cascade of alternatives on one decision, not unrelated nested ones.

4. **No destructuring `let`.** `let (a, b) = expr` did not parse — every
   tuple-returning call in this project (`decode_operands`, `vxy`,
   `pop_key`, ...) was bound to a temporary and then read back positionally:
   `let ops = self.decode_operands(2)` / `let op1 = ops.0` / `let op2 =
   ops.1`. Cost 93 call sites a mechanical regex fixup after discovering it
   partway through writing `cpu.star` — see the compiler-bug section below
   for the *other*, more subtle tuple-related issue this project also hit.
   **Fixed:** `let (a, b, ...) = expr` now exists. All 90 of those call
   sites (81 `decode_operands` sites, 6 `vxy()` sites, 2 `xy0`/`cxy`
   variants, and `pop_key()`) were converted to destructuring `let`,
   including binding an intentionally-unused trailing element as
   `_op2`/`_op3` where a 1- or 2-operand instruction only needs the first
   name or two (`decode_operands` always returns a 3-tuple regardless of
   how many operands the instruction actually decodes). `op_rcl`/`op_rcr`
   went a step further, replacing a `let mut raw = 0; let mut carry_out =
   ...; if width == 8: raw = ...; carry_out = ... else: ...` reassignment
   pattern with `let (raw, carry_out) = if width == 8: ... else: ...` — a
   multi-statement `if`/`else` `let` initializer returning a tuple, exactly
   the shape gotcha #10 below covers, now confirmed working.

5. **No array-literal-of-differing-values.** `[a, b, c]` was a `List<T>`
   literal (heap/RC-backed, fine to return by value); the *only* fixed-size
   `[T; N]` array literal form was the `[value; N]` repeat. This mattered
   for the font glyph table (256 glyphs x 8 bytes, virtually all distinct
   values): there was no way to spell that as an array literal at all.
   `font_data.star` was mechanically generated from the upstream Python
   `font.py` as ~1500 individual `f.glyphs[i] = v as u8` assignments on a
   zero-initialized array (skipping the ~500 already-zero bytes) — slower
   to type than a literal would have been, and there was no other option
   short of runtime file I/O (see #9 below for why that wasn't viable for
   binary data either). **Fixed:** a `[a, b, c]` literal now coerces to a
   fixed `[T; N]` array when an expected `[T; N]` type is reachable from
   context (a struct field's declared type, here). `font_data.star` was
   regenerated as a single `glyphs = [0, 0, ..., 255, ...]` literal — 273
   lines instead of 1527, one row of 8 bytes per glyph, each row commented
   with its character code — with the `mut` dropped from the `glyphs` field
   since it's never written after construction. Round-tripped against the
   original mechanical version (`FontData(...).glyphs[65*8 .. 65*8+8]` for
   `'A'`, code 65) to confirm the regenerated data is byte-identical.

6. **`impl` can't reach into another module.** `impl SomeImportedType:` was
   a parse error (`impl` only took a bare identifier, confirmed empirically
   — `impl cpu::Cpu:` failed with "expected ':', found '::'"). Every method
   on a struct had to live in the same file as that struct's own
   definition; there was no way to split `Cpu`'s ~90 opcode handler methods
   across multiple files the way, say, C splits a big `struct` across
   translation units. This is why `cpu.star` was (and, pending an actual
   split, still is) one large file rather than several smaller ones. What
   already worked, and is used throughout this project: composition —
   `Cpu` holds `mem: memory::Memory`, `screen: screen::Screen`,
   `kbd: keyboard::Keyboard`, `flags: flags::Flags` as plain fields, each
   with their own methods defined in their own file, called through
   `self.mem.read_byte(...)` etc. Method resolution across the module
   boundary always worked fine for *calling* a type's existing methods —
   it was only *defining new methods* on an imported type that didn't.
   **Fixed:** `impl mod::Type:` (and `impl mod::Trait: for Type`/etc., any
   combination) now resolves the qualified name correctly. This directly
   unblocks splitting `cpu.star`'s opcode handlers across files by group —
   genuinely useful for this project specifically, since `cpu.star` is
   still its one ~1800-line file — but that split hasn't been done in this
   pass; it's scoped as its own follow-up (see "Ideas for future work").

7. **`Flags` is a reserved builtin generic name.** `struct Flags:` collided
   with the builtin `Flags<E>` (a typed bitset over a fieldless enum) and
   failed with a confusing "needs an explicit type argument" error at the
   *construction* site, not the declaration. Renamed to `StatusFlags` to
   work around it. **Fixed:** a declared struct now shadows the builtin
   generic of the same name (matching how `Vec2`/`Tick`/etc. already
   shadowed builtin scalars), so `struct Flags:` works standalone. Renamed
   back from `StatusFlags` to `Flags` in `flags.star` and its two call
   sites (`cpu.star`'s `Cpu.flags` field type, `main.star`'s construction).

8. **Single-line `fn foo(): body` doesn't parse.** A function/method body
   had to be on its own indented line(s) below the `fn ... :` header, even
   for a one-expression body — `fn t(self) -> bool: self.get(T_BIT)` was a
   parse error; it had to be
   ```
   fn t(self) -> bool:
       self.get(T_BIT)
   ```
   Hit repeatedly while writing `flags.star`'s named bit accessors.
   **Fixed:** the compact single-line form now parses. `flags.star`'s 22
   one-line bit accessors/setters (`t`/`s`/`o`/.../`set_t`/`set_s`/...) were
   collapsed onto their `fn` line, cutting that block from 48 lines to 22.

9. **`file_read`'s `str` result silently truncates at the first embedded
   NUL byte.** Confirmed empirically: a 6-byte binary file with a 0x00 in
   the middle comes back with `len() == 1`. This made `file_read` unusable
   for loading an arbitrary compiled Nova-16 program — `HLT` alone is
   opcode 0, so *any* real program is virtually guaranteed to contain
   embedded zero bytes. This is why `main.star` has a hand-encoded demo
   program baked in rather than a "load a .bin" option. **Fixed** at the
   compiler level: `file_read_bytes(handle) -> Bytes`/`file_write_bytes`
   now exist as genuinely binary-safe siblings of `file_read`/`file_write`,
   built on the pre-existing length-prefixed `Bytes` type rather than a
   NUL-terminated `str`. **Not wired up in this project** at the time this
   gotcha was first written up, though: there was still no assembler in
   this port (out of scope per the brief) to produce a real compiled
   `.bin` to load, so there was nothing to feed a byte-loader that the
   baked-in demo program didn't already cover. **Now wired up for real**
   (a later round, see "Binary program loading" below): the upstream
   Python `nova_assembler.py` can produce a real `.bin` this port never
   needed to write itself, which was the actual remaining blocker, not the
   language gap this gotcha describes.

10. **A bare multi-statement `if`/`else` doesn't work as a `let`
    initializer.** `let x = if cond: <expr> else: <expr>` worked fine when
    each arm was a *single* expression (used successfully in `flags.star`'s
    `sign_idx`/`overflow` calculations). The moment either arm became
    multiple statements (its own `let`s before a trailing value), binding
    the whole thing to a `let` broke — suspected at the time to be the same
    underlying issue as the function-trailing-`if`/`else` `phi` bug this
    project had already found and reported fixed (see "Two Star compiler
    bugs found and fixed" #2 below). **That assumption turned out to be
    wrong**, and chasing it down (todo.md P3 #11, prompted directly by this
    gotcha) found a real, different, previously-unknown bug — see "Two
    Star compiler bugs found and fixed" #3 below. Now fixed and exercised
    for real in this project: `Cpu::op_rcl`/`op_rcr` (see #4 above) bind a
    2-tuple from a multi-statement `if`/`else`, one `let` inside each arm
    before the trailing tuple value.

11. **No scientific-notation float literal syntax.** `3.0e38` lexed as the
    two tokens `Float(3.0)` and the bare identifier `e38`, not one float
    token (confirmed the hard way: first draft of `op_exp`/`op_tan`'s
    overflow-guard threshold hit a parse error, not a lexer one). Worked
    around with a `const MATH_OVERFLOW_GUARD: f32 =
    300000000000000000000000000000000000000.0` (the full 39-zero expansion
    of `3e38`) rather than reaching for a `f32::INFINITY`/`is_infinite`
    builtin, neither of which exist either. **Fixed:** `Lexer::scan_number`
    now recognizes an `[eE][+-]?[0-9]+` exponent suffix (`todo.md` P3 #12).
    `cpu.star`'s `MATH_OVERFLOW_GUARD` is now spelled `3.0e38` directly.

## Seven Star compiler bugs found and fixed

Building this project's very first smoke test (a struct holding a
`[u8; 65536]` array — the whole reason a Nova-16 port needs 64KB of
addressable memory) immediately hung `clang`. All three fixes below are in
`src/codegen/`, not in this project, and each was verified against the full
`cargo test` suite (no regressions) before continuing.

### 1. Large fixed-array/struct construction crashed or hung `clang`

`let mut mem: [u8; 65536] = [0 as u8; 65536]` alone (no struct involved)
reproduced two distinct failures depending on optimization level:
- At the default `-O2`, `clang` hung indefinitely starting around
  `N=16384` elements (timed out at 20s+ and climbing).
- At `-O0`, it didn't hang but crashed outright — a genuine LLVM
  `SelectionDAGISel`/`DAGCombine` segfault, reproducible exactly at
  `N=65536` (65535 compiled fine; 65536 crashed every time).

Root cause: `Codegen::emit_array_repeat` (the `[value; N]` literal's
codegen) builds the repeated array into a temporary `alloca` via a genuine
runtime loop (cheap, already fixed in an earlier round per its own doc
comment) — but then **loads the entire array as one `[N x T]`-typed SSA
value** to hand back to its caller, which **stores that whole value again**
into the real destination. Two copies of a giant aggregate *value*
(as opposed to two pointers and a `memcpy`) is exactly the shape that
breaks both `clang`'s optimizer (trying to scalar-replace tens of thousands
of elements) and, at `-O0`, its instruction selector outright.

Fix: added `Codegen::emit_array_repeat_into` (writes the repeat loop
directly into a caller-supplied destination pointer, no temp alloca, no
load, no second store) and `Codegen::emit_struct_lit_fields_into` (the
struct-literal-field-filling logic factored out of the existing generic
struct-literal codegen, now recursing into nested struct-literal fields and
routing array-typed fields through `emit_array_repeat_into`). `TypedStmt
::Let` now special-cases a directly-assigned `ArrayRepeat` or `StructLit`
initializer to build straight into the binding's own `alloca` instead of a
temp-then-copy. This was **not** a general fix — it only covered `let x =
<array-repeat-or-struct-literal>` (recursively through nested struct-
literal fields). Two shapes were left unfixed, deliberately avoided
everywhere in this project instead of chased further at the time:
- **A struct/array returned *by value* from an ordinary function** crashed/
  hung identically (confirmed: a function returning a
  `struct { data: [u8; 65536] }` hung `clang` the same way). This is why
  `memory.star`/`screen.star` originally had no `fn new_memory() -> Memory`-
  style constructors — `Memory`/`Screen`/`Cpu` had to be built as one big
  literal directly at their `let mut cpu = Cpu(mem = Memory(...), screen =
  Screen(...), ...)` call site in `main.star`, relying on the recursive
  struct-literal fix. `FontData` (2048 bytes) was small enough to return by
  value safely and had its own constructor function even then.
- **A plain (non-`self`) function parameter of a large struct type** was
  passed *by value* and hit the same wall — confirmed the hard way:
  `Screen::draw_text(mut self, m: mem::Memory, ...)` taking `Memory`
  (~300KB) as an ordinary parameter hung `clang` even though every
  individual piece involved (two 64KB arrays plus a small nested struct)
  compiled fine in isolation. Bisected by literally deleting half the
  methods in `screen.star` at a time until the hang disappeared. Fixed by
  moving `draw_text` onto `Cpu` itself (`cpu.star`), which already holds
  both `mem` and `screen` as fields reachable through `self` — `self` is
  the one parameter kind that's pointer-passed, never copied, in this
  compiler (confirmed in `codegen/stmt.rs::emit_fn`).

  General takeaway adopted for the rest of this project at the time: **any
  struct embedding a "large" fixed array only ever gets constructed once,
  directly into a `let` binding via a literal, and is only ever passed
  around afterward as an implicit `self` on a method call — never as an
  ordinary parameter, and never returned by value.**

**Both remaining shapes are now fixed** (todo.md P0 #2): a large struct/
array return now uses a hidden `sret` out-pointer instead of a by-value
`ret`, and a large ordinary parameter arrives as a pointer and is
`memcpy`'d into a private local — both gated on a 512-byte size threshold,
so every existing small struct keeps its old by-value convention unchanged.
`memory.star` and `screen.star` now have real `new_memory()`/`new_screen()`
constructors, used from `main.star`'s `let mut cpu = Cpu(mem = mem::
new_memory(), screen = screen::new_screen(), ...)`, confirmed with a real
`star build` + a headless run (and the SDL window staying up, not crashing,
for a live smoke test). `draw_text` stays on `Cpu` rather than moving back
to taking `Memory` as an ordinary parameter — pointer-passing `self` is
still strictly cheaper than pointer-passing-plus-`memcpy`'ing an ordinary
large parameter, so there's no reason to revert it now that both work.
One caveat found while verifying this: the fix places a large by-value
return in the *caller's own stack frame* (that's what `sret` means), so
several such structs alive as separate locals in one function can still
overflow the stack even though a single one is fine — not a regression in
this project (only one `Cpu` is ever live at a time here), but worth
knowing before leaning on this pattern more heavily.

### 2. Malformed `phi` for a trailing `if`/`else` returning a tuple or struct

Once the array crash was fixed, the very next build hit an internal IR
verifier rejection: `malformed phi ... no incoming-value list found`, from
`Keyboard::pop_key` (returns `(u8, bool)`) and `Cpu::decode_operands`
(returns a 3-tuple of `Operand`) — both have a trailing `if`/`else` as
their last statement, each arm itself multiple statements.

Root cause: `Codegen::emit_trailing_if_value` (`src/codegen/stmt.rs`)
derives the merged `phi`'s LLVM type by taking the "value" string one arm
produced (e.g. `"{ i8, i1 } %t9"`) and splitting it at the **first** space
(`split_once(' ')`) to separate type from value. That's correct for every
scalar type (`"i32 %t5"` splits cleanly), but any aggregate type's own
textual form contains internal spaces (`"{ i8, i1 }"`, `"[65536 x i8]"`),
so splitting at the first space instead truncated the type down to just
`"{"`/`"["`, corrupting the `phi` line into something clang's parser
rejected outright.

Fix: `rsplit_once(' ')` (split at the *last* space) instead — matches how
`Codegen::reg_of` already extracts the value half
(`split_whitespace().next_back()`), since the value token (an SSA register
name) never itself contains whitespace regardless of how many words the
type needs.

Both fixes are narrowly scoped and were re-verified against the full test
suite twice (once per fix) with zero regressions.

### 3. RC-owning locals leaked/segfaulted from an untaken `let x = if/else` arm

Gotcha #10 above assumed a `let x = if cond: <multi-statement> else:
<multi-statement>` `let`-initializer failure was the same bug as #2 above
(both are "a trailing `if`/`else` with a non-trivial arm produces bad
codegen"). Confirming that assumption (todo.md P3 #11) found it was
actually wrong: a `let`-initializer `if`/`else` parses as a full `Expr::If`
and codegens through an entirely separate `TypedExpr::If` arm in
`src/codegen/expr.rs`, which reads its merged `phi` type directly off the
checker's own `ty` field rather than splitting a tagged value string — so
it was never susceptible to fix #2's particular bug at all.

But auditing that arm while checking turned up a real, different bug in
the same neighborhood: unlike every other `if` codegen path in the
compiler, `TypedExpr::If` never wrapped either arm in its own
`push_scope`/`pop_scope`. An RC-owning local declared inside an arm (a
`str`, `List<T>`, ...) — whether or not it was the arm's own trailing
value — got tracked in whatever scope was already open *outside* the whole
`if`. That outer scope's eventual release fired unconditionally for
*both* arms' locals, including the untaken arm's, whose `alloca` was never
stored to and held uninitialized stack garbage — releasing that garbage as
a supposed RC pointer segfaulted, confirmed with a real `star build` + run
repro before the fix.

Fix: give each arm its own scope in `Codegen::emit_expr`'s `TypedExpr::If`
case, exactly matching `emit_trailing_if_value`/`TypedStmt::If`'s existing
pattern. Not a shape this project's own multi-statement `let x = if/else`
usage (`Cpu::op_rcl`/`op_rcr`, see gotcha #4/#10 above) actually triggers —
neither arm there declares an RC-owning local — but confirmed safe by the
same headless check used for gotcha #1's operator conversions, and by the
compiler's own dedicated regression tests (`tests/frontend_closures_higher_order.rs`,
including a sustained 400,000-iteration leak check alternating branches).

### 4. A diamond import silently deleted a cross-module `impl` block

Found while writing a standalone headless test harness for the string-
library opcodes below (not this project's own source, but the harness
still needed a real multi-file Star build to exercise `Cpu`). The harness
put its test-only helper methods in a second file via `impl cpu::Cpu:`
(gotcha #6's cross-module-`impl` fix — `cpu.star` itself keeps its own
bare `impl Cpu:`), the same shape `todo.md` P1 #6 cites as *this project's
own* motivating future use case for splitting `cpu.star`'s opcode handlers
across files. Every method the harness added this way silently failed to
resolve (`no field 't_write_str' on 'cpu__Cpu'`) — but only once the
harness's `main` file imported `cpu.star` *and* one of `cpu.star`'s own
leaf dependencies a second time under a different alias (needed to
construct a `Cpu` literal's fields directly). Bisected down to a genuinely
minimal, project-independent repro: a struct `Top` with two fields from
two *sibling* modules that both import one common leaf module (an
ordinary, entirely unrelated diamond dependency — no relation to `Top`
itself) is enough to make a *separate file's* `impl Top:` block vanish
entirely, even though `Top` is declared only once and isn't part of the
diamond at all.

Root cause, in `src/modules.rs`: `dedupe_by_origin`'s main mechanism
(tracking each top-level item's `(source file, name, import-call-id)`
provenance to tell a genuine diamond re-visit of the same declaration apart
from two independently-authored items that happen to share a name) already
handles diamonds correctly for named items — this is the exact machinery
`projects/snake/NOTES.md` section 1.1 describes fixing. But `impl` blocks
declare no name of their own (`item_top_level_name` returns `None` for
`Item::Impl`, by design — `collect_names` relies on that to skip mangling
them), so they were never entered into that provenance-tracked mechanism
at all. Instead, a separate, later, unconditional sweep collapsed *any* two
`impl` blocks sharing a `(trait_name, type_name)` pair down to one — with
no check that they were actually the same source declaration re-visited
via two import paths, rather than two genuinely different `impl` blocks
for the same type. That sweep only ran when `dedupe_by_origin`'s main
mechanism had already found *some* diamond to collapse elsewhere in the
module (an early return skipped it entirely otherwise) — which is exactly
why an unrelated diamond (through `flags.star`/`memory.star` both
importing `bits.star`, in this project's real `cpu.star`) was enough to
trigger it against a completely unrelated `impl cpu::Cpu:` block.

Fix: give `impl` blocks a synthetic identity in the same provenance
mechanism named items already use, built from `(trait_name, type_name,
span.start..span.end)` instead of a real name. A genuine diamond re-visit
re-parses the identical source text and produces the identical byte-offset
span every time (even though `span.file_id` itself differs per visit, since
each import edge allocates a fresh file id), while two independently-
authored `impl` blocks for the same type necessarily have different spans
and so are never grouped together. This subsumes the old blanket sweep
entirely, so it was deleted rather than left as a redundant (and, as this
bug showed, actively harmful) second pass. Verified against the minimal
repro above (now fixed) and the full `cargo test` suite (no regressions —
including the pre-existing diamond-import tests this mechanism was
originally built for).

### 5. The default linked executable's stack was too small for this language's own large-aggregate support

Found via a real user report against the binary program loader (see
"Binary program loading" above): a real, independently-authored Nova-16
program (`gfxtest.asm`, from the upstream Python repo's own `asm/`
directory) loaded and ran fine for a few thousand steps, then the whole
process died silently — no crash message, no diagnostic, window just gone.
Bisected (via `tests/run_bin.star`'s cycle-count argument, halving the
range each time) to the *exact* step where a timer interrupt first fires
(`gfxtest.asm` enables `TC`/`TM`/`TS` and its handler is one instruction,
`SROL 0, -1`) — reproducible at the precise cycle, every run. `$?`/
`$LASTEXITCODE` after the "crash" was 0xC00000FD, Windows'
`STATUS_STACK_OVERFLOW` — not a Star-level trap (those print a diagnostic
first; this printed nothing at all, consistent with a hard OS-level kill
that never runs the C runtime's normal `atexit`/stdio-flush path).

Root cause was **not** a Star compiler bug in the usual sense (bad codegen,
a wrong type rule, a parser gap) — it's that `star build`'s `clang`
invocation (`cmd_build`, `src/main.rs`) never passed a stack-size linker
flag at all, so every produced Windows executable got whatever tiny default
`ld`/`lld` picks for a PE binary's main-thread stack reserve (1MiB,
confirmed empirically). That's an entirely reasonable default for a
program with only small, ordinary locals — but this language *deliberately*
makes large aggregates (multi-hundred-KB structs/arrays) ordinary values a
program can freely `let`-bind, pass, and return (the whole point of
`Codegen::LARGE_AGGREGATE_THRESHOLD`'s pointer-passing convention, todo.md
P0 #2) — and every one of those values still has to live in *some*
function's native stack frame. `projects/nova`'s own `Cpu` (a ~300KB
`Memory` plus, after this round grew `Screen` to 9 compositing layers, a
~650KB `Screen` — see "Layer compositing and sprites" above) is held as a
single `let mut c = Cpu(...)` local in `main`, comfortably under 1MiB on
its own — but stacked on top of even one additional, unrelated 64KB local
array deeper in the same call chain (`Screen::roll_x`'s pre-existing temp
buffer, called from `SROL`'s opcode handler when the timer interrupt
fires), the combined depth exceeded the linker's 1MiB reserve. Confirmed
with a minimal, project-independent repro: a `Cpu`-sized struct held in
`main`, plus one ordinary (non-recursive) call to a function with its own
64KB local array — nothing pathological, just two large, unrelated locals
coexisting on the same native stack the way any real program using this
language's large-aggregate support legitimately might.

Fix: `cmd_build` now always links with an explicit, generous stack-size
reserve (16MiB — 16x the current largest known combined usage) via a new
`stack_size_flag(target)` (`src/main.rs`), added to the `clang` invocation
right alongside the existing `-target`/`-l`/`-L` flags. Target-specific,
since the two backends' linkers spell "reserve more stack" differently:
`--stack,<bytes>` for `Target::WindowsGnu` (GNU `ld`/mingw-flavored
`lld`, a PE-header field — no ELF equivalent) vs. `-z stack-size=<bytes>`
for `Target::LinuxGnu` (a modern GNU `ld`/`lld` ELF option); passing the
wrong one under the wrong target is a hard "unrecognized option" link
error, not a silent no-op, so the two needed separate handling from the
start, mirroring how `clang_target_flag` already splits target-specific
flag logic out of `cmd_build` for testability. Reserved address space costs
nothing until touched (only committed pages count against real memory), so
this has no effect on a typical small program's actual footprint — it only
raises the ceiling for programs that need it. Verified against the exact
repro above (now fixed, confirmed via `$LASTEXITCODE` back to `0`) and the
full `cargo test` suite (no regressions). Two new tests in `src/main.rs`'s
own `tests` module (`stack_size_flag_uses_windows_ld_stack_spelling`/
`_uses_linux_ld_stack_spelling`), matching the existing `clang_target_flag`
test pattern.

This is deliberately **not** the same fix as `MAIN_STACK_SIZE`
(`src/main.rs`, near `fn main`) — that constant already existed, but covers
a completely different stack: it's the 32MiB the `star` *compiler's own
process* runs its parser/checker/codegen passes on (for genuinely deep
input, e.g. long operator chains), not anything about the stack size of the
*executables* `star build` produces. The two are easy to conflate (same
file, same general topic) but fix unrelated problems; the doc comment on
the new `DEFAULT_STACK_SIZE_BYTES` constant cross-references this
distinction directly for whoever finds this section next.

### 6. `FStr` (f-string) codegen returned an untagged value, breaking trailing-`if`/`else` type recovery

Found writing `disasm.star`'s `format_offset` helper: `fn format_offset(off:
i32) -> str: if off < 0: f"-{0 - off}" else: f"+{off}"` — a function whose
entire body is a trailing `if`/`else`, each arm a single f-string
expression — failed to compile with a generic `codegen error: function must
end in a value-producing expression or explicit return`, despite type-
checking cleanly and despite an f-string working fine as a function's *only*
statement, or with an explicit `return f"..."` inside each arm. Only the
"bare trailing-value" `if`/`else` shape failed.

Root cause, in `Codegen::emit_expr`'s `TypedExpr::FStr` arm
(`src/codegen/expr.rs`): every other arm in that same match returns a
*tagged* `"<llvm-type> <value>"` string (e.g. `TupleLit`'s
`format!("{} {}", struct_ty, loaded)`) — the convention
`Codegen::untag`/`Codegen::reg_of` and (critically here)
`Codegen::emit_trailing_if_value` (`src/codegen/stmt.rs`, the fix site for
bug #2 above) all rely on. `FStr`'s arm was the one exception: it built its
`snprintf`-backed buffer correctly but returned the bare register name
`buf`, no type tag at all. `untag`'s own defensive `strip_prefix(..).
unwrap_or(s)` tolerates a missing tag fine (that's exactly why this went
unnoticed for as long as it did — most callers already route through
`untag`), but `emit_trailing_if_value`'s `then_val.rsplit_once(' ')` — used
to *recover* the merged `phi`'s LLVM type from the value string itself,
since a bare `TypedStmt::If` carries no separate `ty` field the way
`TypedExpr::If` does — has no fallback: no space in the string means
`rsplit_once` returns `None`, the `?` operator propagates it, and the whole
function silently reports "no trailing value" even though one obviously
exists.

Fix: tag the `FStr` arm's return the same way every sibling arm already
does — `format!("i8* {}", buf)` instead of bare `buf`. One line. Verified
against a minimal repro (`fn f1(off: i32) -> str: if off < 0: f"-{off}"
else: f"+{off}"`, previously failing the same way, now compiles and runs
correctly) and the full `cargo +stable-x86_64-pc-windows-gnu test` suite
(zero regressions, all ~72 binaries).

### 7. `concat()` had the identical untagged-return bug, found five minutes later by the same investigation

Working around bug #6 (before it was diagnosed as fixable) by rewriting
`disasm.star`'s hex-formatting helpers to build strings with `concat(a, b)`
instead of nesting f-strings hit the *exact same* `codegen error:` message
again, on `fn format_offset(off: i32) -> str: if off < 0: concat("-",
dec_str(0 - off)) else: concat("+", dec_str(off))` — same shape, different
builtin. `Codegen::emit_str_concat` (`src/codegen/builtins.rs`) turned out
to have the identical bug: it also returns a bare `buf`, unlike its own
sibling `Codegen::emit_str_join` (`src/codegen/list.rs`), which already
returns `format!("i8* {}", buf)` correctly — `str_join` was never affected.

Fix: identical one-line change, `buf` → `format!("i8* {}", buf)`. Also
verified against a minimal repro and the full test suite (zero
regressions). Given two independent builtins had the same exact class of
bug, a third might too — nothing else was found by inspection of the
remaining `str_*`/list builtins during this pass, but this is worth keeping
in mind (and worth checking with a repro like the two above, not just by
reading) the next time a function-valued builtin's return is used as a bare
trailing `if`/`else` value and produces this same generic error.

### A related runtime bug, since fixed: calling an f-string-producing function repeatedly could corrupt its own output

While bisecting bug #6/#7 above, an *earlier* draft of `disasm.star`'s
`hex_word`/`hex_byte` — implemented via nested f-strings
(`f"{hex_byte(..)}{hex_byte(..)}"`) rather than `concat` — exhibited a
second, different symptom once bug #6 was already fixed at the compiler
level: the program *compiled and ran*, but produced wrong values.
`hex_word(0x1234)` returned `"444"` instead of `"1234"`; a small wrapper
function (`fn wrap(v: i32) -> str: f"0x{hex_word(v)}"`, itself materialized
via f-string) returned the *correct* value on its first call in a program
run and a *corrupted* one on the second/third call to the same call site —
`wrap(0x1234)` → `"0x1234"` (right), then `wrap(0)` → `"0x0x00"` (wrong,
with a literal duplicated `"0x"` fragment), even though each call is
independent and passes a fresh argument. This is **not** the same bug as
#6/#7 above (no compile error at all — the program builds and links fine)
and reproduces regardless of whether the *inner* function
(`hex_byte`/`hex_word`) is itself f-string- or `concat`-based; the common
factor across every failing case is an f-string appearing *somewhere* in
the call chain, more than once, in the same running program.

At the time this was written, `disasm.star` routed around it entirely
instead (every helper function it defines builds its result with
`concat`/`str_join` only, and calls no function from *inside* an f-string's
`{...}` interpolation that itself contains an f-string anywhere in its own
body; see `disasm.star`'s own header comment), which was sufficient to get
correct, verified output from every test `.bin` disassembled during that
round. The hypothesis recorded here at the time (a `star_rc_alloc`-backed
buffer from a first call not being retained/protected before a later call
reuses its address) turned out to be right in spirit and precise about the
symptom, but not about the mechanism.

**Since root-caused and fixed** (`todo.md` P1 #1): three separate codegen
call sites -- `Codegen::emit_expr`'s general `TypedExpr::FStr` arm and both
branches of `Codegen::emit_print_like` (`src/codegen/expr.rs` /
`src/codegen/builtins.rs`) -- released a `str`-typed f-string
interpolation hole's owned pointer via `star_rc_release` *before* the
`snprintf`/`printf` call that actually reads through it, freeing its
backing `malloc` block immediately. Nothing then stopped a *later*
allocation in the same expression (typically a second interpolation
hole's own call, or the enclosing f-string's own result buffer) from
reusing that exact address before the pending `snprintf`/`printf` read it
-- exactly the duplicated-fragment corruption recorded above, not random
garbage, because the read and a subsequent write ended up aliasing the
same memory. This is the identical bug class `Codegen::emit_str_concat`'s
own doc comment (`builtins.rs`) already documented and fixed for
`concat`'s two arguments in an earlier round; it had simply never been
ported to these three other call sites. Fixed by deferring each hole's
release until after the read(s) that actually consume it. Verified against
a direct transcription of this section's own `wrap(v) -> f"0x{hex_word(v)}"`
repro (reproduced the exact `"0x0x0N"` corruption pre-fix once looped over
enough calls, clean post-fix) plus several other shapes, and the full
`cargo +stable-x86_64-pc-windows-gnu test` suite (no regressions) -- see
`tests/frontend_fstring_str_hole_use_after_free.rs` and `todo.md`'s
"Previous work" entry for the fix. `disasm.star`'s own `concat`-only
helpers are left as they are (routing around the bug cost nothing and
reverting them isn't this fix's job), but any *new* Star code is no longer
required to avoid nested f-strings the way this file's header comment
still describes.

## Fixes applied to this project

Once all ten gotchas above were fixed at the compiler level (tracked in
[`todo.md`](../../todo.md)), this project was swept for real call sites and
updated in place. Summary, file by file:

- **`font_data.star`** — regenerated from ~1500 individual
  `f.glyphs[i] = v as u8` assignments into one `glyphs = [...]` fixed-size
  array literal (gotcha #5); 1527 lines → 273. `mut` dropped from the
  `glyphs` field (never written after construction).
- **`flags.star`** — struct renamed `StatusFlags` → `Flags` (gotcha #7); 22
  one-line bit accessors/setters collapsed onto their `fn` line (gotcha #8);
  `bit_xor(a, b)` → `a ^ b` in `apply_arith` (gotcha #1).
- **`bits.star`** — header comment updated to explain why its bit-by-bit
  shift/rotate functions are *kept* rather than replaced by the new
  operators (gotcha #1): they serve the CPU's runtime-shift-amount opcodes,
  whose clamping semantics deliberately differ from the operators' mod-width
  masking.
- **`memory.star`** — `read_word`/`write_word` use `<<`/`>>`/`|` directly
  instead of `bits::shl16`/`bits::shr16`/`bit_or` (gotcha #1, fixed shift
  amount); gained a real `new_memory()` constructor (large-aggregate
  by-value return fix, "Three Star compiler bugs" #1).
- **`screen.star`** — `sinv()`'s `bit_not` → `~`; `clamp_i32` flattened to
  `if`/`elif`/`else` (gotcha #3); gained a real `new_screen()` constructor
  (same fix as `memory.star`).
- **`cpu.star`** — the big one:
  - `get_reg_value`/`set_reg_value`/`reg_width`'s register-code `match`
    arms and `execute`'s opcode dispatch: 293 match-arm keys converted
    decimal → hex (gotcha #2), now matching
    `docs/nova16_instruction_reference.md`'s own numbering.
  - `decode_operand`'s 4-way addressing-mode fallback, `draw_text`'s
    control-code dispatch, and `check_interrupts`'s interrupt-priority
    check flattened to `elif` (gotcha #3).
  - 90 tuple-returning call sites (`decode_operands`, `vxy`, `pop_key`)
    converted from positional `let ops = ...; let op1 = ops.0; ...` to
    destructuring `let (op1, op2, op3) = ...` (gotcha #4); `op_rcl`/`op_rcr`
    additionally restructured around a multi-statement `if`/`else` `let`
    initializer returning a tuple (gotcha #10).
  - `Cpu.flags`'s field type updated for the `Flags` rename (gotcha #7).
  - `bit_or`/`bit_and`/`bit_xor`/`bit_not` calls and fixed-amount
    `bits::shl16`/`shr16`/`shl8` calls (byte-half register packing, `SWAP`'s
    nibble swap, `vxy()`'s packed-address calc) converted to `<<`/`>>`/`&`/
    `|`/`^`/`~` (gotcha #1).
  - File header comment updated: no longer claims decimal-only register
    codes or a hard "`impl` can't cross modules" constraint, since both are
    fixed; notes the opcode-group file split is now *possible* but not done.
  - `MATH_OVERFLOW_GUARD`'s 39-zero decimal expansion replaced with `3.0e38`
    directly (gotcha #11).
- **`main.star`** — `demo_program()`'s hand-encoded opcode/register/mode
  bytes converted decimal → hex (gotcha #2; the byte-offset address
  comments alongside them stay decimal, since those count bytes rather than
  encode a register/opcode); `Cpu(...)` construction switched to
  `mem::new_memory()`/`screen::new_screen()`; unused `font_data.star` import
  removed (folded into `new_screen()`); header comment updated to mention
  `file_read_bytes` as the now-available (if not yet wired up) binary-safe
  loader path.

Not changed, on purpose:
- **No opcode-group file split for `cpu.star`** (gotcha #6 unblocks this,
  but it's a substantial restructuring on its own — scoped as future work,
  not bundled into this sweep).
- **No binary `.bin` program loader** (gotcha #9 unblocks the *language*
  side of this, but there's still no assembler in this port to produce a
  `.bin` to load — the actual blocker is unrelated to the language gap).
- **`bits.star`'s runtime-shift-amount functions** stay bit-by-bit rather
  than switching to the new operators — see gotcha #1 and `bits.star`'s own
  header comment for why that's a deliberate semantics-preserving choice,
  not an oversight.

Verification: a full `star build projects/nova/main.star -L sdl/lib/x64 -l
SDL2 -o projects/nova/nova16.exe` succeeds; the built binary runs without
crashing (confirmed headlessly with a timed run, no error output, exits
only when killed); a standalone headless check program (not checked in)
exercised the P0 byte-half register write/read, `vxy()`'s packed address
calc, the `AND`/`OR`/`XOR`/`NOT`/`SWAP` opcodes end to end via `Cpu::step()`,
and `SINV`, all matching hand-computed expected values — covering every
`bit_*`-to-operator conversion in `cpu.star`/`screen.star`. The regenerated
`font_data.star`'s glyph 65 (`'A'`) bytes were diffed against the original
mechanical version's and are identical.

## What's implemented

The full CPU/memory/register-file/flags architecture, the fetch-decode-
execute cycle, all four addressing modes, and 167 opcodes (of the 180
`docs/nova16_instruction_reference.md` documents as real instructions —
the 13 gap is exactly "What's not implemented" below: 6 hardware-debugging
opcodes, `STREXT`/`STREXTI`/`MEMCMP`, and `SMIX`/`SECHO`/`SREVERB`/
`SFILTER`. This count, and every opcode's exact operand count below, was
mechanically cross-checked against `cpu.star`'s own `decode_operands(N)`
call sites while building the disassembler — see "Disassembler" below,
which is also where this replaces this section's own former "roughly 140"
estimate):

- No-operand: `HLT NOP RET IRET CLI STI`
- Data movement: `MOV MOVZ MOVNZ XCHNG SWAP LEA`
- Arithmetic: `ADD SUB MUL DIV MOD INC DEC NEG ABS ADC SBC MULH DIVH MIN MAX
  CLZ CTZ POPCNT`
- Math library: `POWR SQRT LOG EXP SIN COS TAN ATAN ASIN ACOS DEG RAD FLOOR
  CEIL ROUND TRUNC FRAC INTGR`
- Fixed-point Q8.8: `FMUL FDIV FTOI ITOF`
- BCD: `SED CLD CLA BCDA BCDS BCDCMP BCD2BIN BIN2BCD BCDADD BCDSUB`
- Bitwise: `AND OR XOR NOT SHL SHR ROL ROR SAR SAL RCL RCR BTST BSET BCLR
  BFLIP`
- String library: `STRCPY STRCAT STRCMP STRLEN STRUPR STRLWR STRREV STRFIND
  STRFINDI`
- Integer/string conversion: `ITOB BTOI ITOS STOI`
- Stack: `PUSH POP PUSHF POPF PUSHA POPA ENTER LEAVE`
- Control flow: `JMP` + all 12 conditional jumps, `BR BRZ BRNZ CMP CALL
  CALLZ CALLNZ RETN LOOP LOOPZ WHILE INT`
- Memory bulk: `MEMCPY MEMSET MEMMOVE MEMSWAP MEMTEST`
- Random: `RND RNDR`
- Graphics: `SBLEND(stub, see below) SREAD SWRITE VREAD VWRITE SBLIT VBLIT
  SFILL SINV SLINE SRECT SCIRC SROL SROT SSHFT SFLIP CHAR TEXT` — every one
  of these except `SREAD`/`VREAD`/`VWRITE` now targets whichever of the 9
  layers `VL` selects, not just layer 0 (see "Layer compositing and
  sprites" below).
- Layers: `LSWAP LMOVE LCOPY` (see "Layer compositing and sprites" below).
- Sprites: `SPBLIT SPBLITALL` (see "Layer compositing and sprites" below).
- UART: `SERIN SEROUT SERSTAT SERCTRL`, plus a real host bridge
  (`uart_bridge.star`) — see "UART" below.
- Sound: `SPLAY SSTOP STRIG` — real waveform synthesis and playback (not a
  stub; see `sound.star` and "Known simplifications" below for the
  documented simplifications this *does* still carry). `SMIX SECHO SREVERB
  SFILTER` are unimplemented in the reference itself, see "What's not
  implemented" below.
- Keyboard: `KEYIN KEYSTAT KEYCOUNT KEYCLEAR KEYCTRL`
- `MOUSECTRL` (real host mouse plumbing — see "Mouse plumbing" below).
- Every register-code target (`R0-R9, P0-P9, SP, FP, VX, VY, VM, VL, VC,
  BANK, C0, C1, MX, MY, MB, SA, SF, SV, SW, TT, TM, TC, TS`, and the
  `P0:`/`:P0`-style byte-halves) via `MOV`/arithmetic/etc., not just as
  dedicated opcodes.
- Interrupts (timer, serial/UART, keyboard, and mouse as real hardware
  sources, in that priority order; software `INT` reaching every vector
  0-7) and the timer (`TC`/`TM`/`TS`/`TT`, ticked once per instruction).
- A real binary program loader (see "Binary program loading" below) --
  loads a compiled `.bin` (as produced by the upstream Python
  `nova_assembler.py`) instead of only the built-in demo program.
- A real disassembler (see "Disassembler" below) -- decodes a compiled
  `.bin` back into readable Nova-16 assembly text.
- A real assembler (see "Assembler" below) -- turns a `.asm` source file
  into a compiled `.bin`, matching the upstream `nova_assembler.py`'s own
  output byte-for-byte on every source it can also assemble.
- A real debugger (see "Debugger" below) -- a CLI REPL with breakpoints,
  single-stepping, register/memory/stack inspection, and symbol-labeled
  disassembly.
- GUI+controls parity (see "GUI+controls parity" below) -- `main.star`'s
  SDL window has a Start/Pause/Stop/Reset/Step/Load toolbar, a status bar,
  and F5-F9 hotkeys, matching the upstream `nova_gui.py`'s own toolbar --
  including, now, a real `Load` button (see "Load button and
  `open_file_dialog`" below), backed by a new native-file-dialog compiler
  builtin.

## What's not implemented (and why)

Deliberately deferred, each documented at the point it would have plugged
in:

- **`STREXT`/`STREXTI`** specifically (unlike the rest of the string
  library, now implemented — see "String library and integer/string
  conversion" below) and **`MEMCMP`** — both 4-operand opcodes; see
  "4-operand instructions are out of scope" above.
- **`SMIX SECHO SREVERB SFILTER`** specifically — still genuinely
  unimplemented, unlike `SPLAY`/`SSTOP`/`STRIG` (see `sound.star` below):
  the reference's own `opcodes.py` marks these four `# unimplemented` too
  (no handler exists there either), so leaving them unimplemented here
  stays a bug-for-bug match, not a gap. **`SPLAY`/`SSTOP`/`STRIG` waveform
  synthesis itself is now implemented** (todo.md P0 #1, reversing this
  section's own earlier "a host-audio concern, not implemented" entry) —
  see `sound.star`'s header comment for the WAV-file-roundtrip approach
  through the existing `crate::codegen::audio` mixer, and its documented
  simplifications (one loop channel + one one-shot pool rather than 8
  independent voices, leaked WAV handles, a 3-tap noise approximation
  standing in for a true pink/1-over-f filter).
- **UART framed-mode protocol parsing** (start byte + length + payload +
  checksum) — still out of scope, no opcode drives it either way. **The
  host bridge itself is now implemented** (todo.md P0 #1, reversing this
  section's own earlier "left out, no opcode can drive it" entry):
  `uart.star::host_push_rx` feeds a real host byte into the RX path, and
  `projects/nova/uart_bridge.star` is a headless stdin/stdout driver for
  it — see "UART" below and `uart_bridge.star`'s own header comment for why
  stdin/stdout (blocking, `read_line()`-driven) was chosen over TCP (no
  non-blocking/timeout mode exists at the language level, which would
  freeze a bridge loop waiting on an idle peer).
- **Hardware debugging opcodes** (`SETBP CLRBP ENABRK DISBRK ENATRAP
  DISATRAP`) — still unimplemented; matching the reference (see
  `disasm.star`'s own opcode table, where these are marked doc-only/
  unverified). **This is no longer a debugger-tooling gap** now that
  `debugger.star` exists (see "Debugger" below): its breakpoints are
  implemented entirely host-side (a `[bool; 65536]` membership check the
  debugger's own `step`/`run` loop consults), the same way
  `nova_debugger.py`'s own `self.breakpoints` set works, with no dependency
  on these CPU-level opcodes at all. Wiring these six up would only matter
  for a Nova-16 *program* that wants to set its own breakpoints against a
  debugger attached over some hardware protocol this emulator doesn't
  implement — a materially different feature from "have a debugger," which
  is done.
- ~~An assembler/debugger~~ — both done, see "Assembler" and "Debugger"
  below. Programs no longer have to be real compiled `.bin`s assembled by
  the upstream Python `nova_assembler.py` — `assembler.star` produces them
  from source directly — and there's a real way to set a breakpoint,
  single-step interactively, and inspect state live (`debugger.star`),
  beyond `disasm.star`'s static decode and `tests/run_bin.star`'s post-hoc
  register dump.

## Known simplifications

- **The timer ticks once per emulated instruction**, not once per host
  clock cycle. This is an interpreter, not a cycle-accurate simulator —
  documented as a deliberate simplification, not an oversight.
- **Timer catch-up is capped at +1 per tick** rather than "advance by
  however many divisor-periods elapsed," which only differs from the
  reference under a `TS` so small relative to instruction throughput that
  multiple periods elapse between ticks — an edge case, not the common
  path.
- **`SBLEND` (blend mode) is a stub, and confirmed to be a bug-for-bug
  match rather than a simplification**: reading `nova/graphics/blitter.py`
  directly shows `Blitter.blend_pixel`/`_set_pixel_to_layer` (the only
  blend-aware pixel write) is never called from anywhere in the reference
  — `SWRITE`'s real path and every drawing primitive write raw, unblended
  values. See `screen.star`'s header comment for the full trace. This was
  reconfirmed during this round specifically because it looked like an
  obvious gap to close — it isn't one.
- **`SPLAY`/`SSTOP`/`STRIG` now update real audio state (todo.md P0 #1)** —
  previously this bullet read "update no actual audio state"; see
  `sound.star` and the "What's not implemented" entry above for what
  changed and its documented simplifications (one loop channel + one
  one-shot pool, leaked WAV handles, approximated pink noise).
- **DIV/MOD/DIVH by zero print a diagnostic and leave the destination
  unchanged**, rather than raising a hardware fault/trap — a defensive
  choice so a buggy test program halts with a readable message instead of
  the whole emulator process aborting.
- **An unknown/unimplemented opcode halts the CPU with a diagnostic**
  (`pc`, opcode byte) rather than either crashing or silently
  misinterpreting the following bytes as something else — the safest
  choice given the fetch stream would otherwise desync unrecoverably.
- **The math library's transcendental opcodes compute in `f32`, not
  `f64`** like the Python reference — see "Math library / Q8.8
  fixed-point" below for the full reasoning and the two opcodes (`POWR`,
  `EXP`) where the gap is actually reachable rather than academic.
- **No layer-visibility toggle, no mouse-cursor compositor overlay** —
  the reference's `Compositor.set_layer_visibility`/mouse-cursor-bitmap
  overlay are pure Python-API conveniences with no opcode that reaches
  them (confirmed by grep — no `exec_handlers.py` handler calls either),
  so there's nothing ISA-visible to port here.
- **`Screen`'s composite is always recomputed on demand, never cached** —
  see `screen.star`'s header comment for why the reference's own dirty-
  flag/pixel-count cache is a pure performance optimization with no
  observable effect on any opcode's result, and is therefore skipped
  entirely (same "don't chase the reference's own performance hacks, only
  its observable behavior" precedent as the timer/opcode-fetch-cache
  simplifications above).

## Testing

**Updated this round**: there is now a real, checked-in `tests/` directory,
unblocked entirely by the binary program loader (see "Binary program
loading" below) — assembling a real `.asm` test program with the upstream
Python `nova_assembler.py` and loading the resulting `.bin` is now strictly
easier than hand-encoding bytes, so every prior round's "no test suite, no
assembler" rationale is gone for anything the assembler can express. This
round also added a second, independent way to eyeball what a checked-in
`.bin` actually contains without executing it at all — `disasm.star` (see
"Disassembler" above), whose own "Verification" subsection covers what it
was checked against; not repeated here. What's checked in:

- `tests/run_bin.star` — a generic headless runner: loads a `.bin` (via
  `loader.star`, same as `main.star`), steps it to completion or a cycle
  cap, and prints every register plus `halted`/`pc` (and, given a third/
  fourth CLI argument, a raw memory range) for shell-level comparison. Built
  standalone (`star build projects/nova/tests/run_bin.star -L sdl/lib/x64
  -l SDL2 -o projects/nova/tests/run_bin.exe`) once per session and reused
  against every `.bin` below. **Correction**: this used to say "no SDL
  needed" — true when this file was first written, no longer true since
  `cpu.star` transitively pulls in `sound.star`'s audio builtins for
  `SPLAY`/`SSTOP`/`STRIG` (todo.md P0 #1) even though this harness never
  opens a window; `-l SDL2` is required at link time regardless (undefined
  `SDL_Init`/`SDL_OpenAudioDevice`/etc. otherwise). `run_bin.star`'s own
  header comment already carries this correction; this file didn't, until
  now. `disasm.star` (see "Disassembler" above) is the one Nova build
  target in this project that genuinely doesn't need `-l SDL2` — it never
  imports `cpu.star` at all.
- `tests/asm/*.asm` (+ their assembled `.bin`/`.org`/`.sym`) — the actual
  test programs:
  - `uart_integration_test.asm` — copied verbatim from the upstream
    Python repo's own `asm/uart_integration_test.asm` (not authored for
    this port), proving the loader can run an *existing*, independently-
    authored Nova-16 program unmodified. See "Binary program loading"/
    "UART" below.
  - `layers_test.asm`, `sprites_test.asm`, `mov_write_width_test.asm` —
    written for this round, each with its expected-register-values
    checklist spelled out in its own header comment. See "Layer
    compositing and sprites" and "A genuine port bug: MOV [mem],
    narrow-source write-width" below.
  - `write_width_test.asm`, `push_pop_width_test.asm`, `bcd_width_test.asm`,
    `bcda_carry_order_test.asm`, `bcds_borrow_order_test.asm` — written in
    the pass that generalized the write-width fix and swept the rest of
    this file for the same class of bug; each checked against the live
    Python reference before being checked in (not just hand-derived). See
    "Generalizing the write-width fix", "PUSH/POP always used a fixed
    16-bit stack slot", and "BCD operations"'s corrected read-width/
    masking-order bullets below.
  - `assembler_directives_test.asm`, `assembler_direct_indexed_test.asm` —
    written for the assembler round (todo.md P1 #2) to exercise directives/
    labels/`EQU`/char-literals/negative-immediates and direct-indexed
    addressing respectively, neither touched by any file above. Their
    `.bin`/`.org`/`.sym` are the first in this directory produced by this
    project's own `assembler.star` rather than the upstream Python
    `nova_assembler.py` — see "Assembler" above for the full verification
    record (byte-for-byte Python parity where Python can assemble the
    input, live-CPU/disassembler round-trip where it can't).
- `tests/mouse_interrupt_test.star` — a direct-field-poke harness (not a
  `.bin`) for the one piece of this round with no opcode-reachable way to
  drive it end to end (nothing a Nova-16 program can execute sets
  `mouse_pending_irq` — only the host mouse does, see "Mouse plumbing"
  below) — same spirit as the BCD/string rounds' own "standalone headless
  harness", just checked in this time.

Every one of these was **also** run against the live Python reference
(`python -c "..."` scripts importing `nova_memory`/`nova_gfx`/`nova_cpu`
directly, `Memory.load(path)` for the `.org`-aware loader) for a
checkpoint-by-checkpoint diff, not just hand-derived expected values —
continuing the standard the math/string/BCD rounds established. Every
comparison below matched exactly (cycle count, final `pc`, and every
register), including the mouse-interrupt-gating case, which was cross-
checked by reading `NovaMouse`/`nova_cpu.py`'s dispatch logic directly
rather than executing it (there's no way to drive it from a `.bin` on
either side).

What was verified before this round (headlessly, before wiring anything
into the SDL window, back when there was no assembler-driven `.bin` to
load):

- Register-code round trips (`get_reg_value`/`set_reg_value` for `R0`,
  `P0`, and `P0:`/`:P0` byte-halves) against known bit patterns.
- Flag computation (`Flags::apply_arith`) against hand-checked
  expected Z/C/S/O for unsigned wraparound, signed overflow, `CMP`
  equal/borrow, and plain `SUB`'s wider carry rule vs. `CMP`'s narrower one.
- Palette output for `BLACK`/`WHITE`/`RED`/`GREEN` against the documented
  "common color values" table.
- Font glyph bytes for `'A'` (code 65) against the upstream `font.py`
  directly.
- A real hand-assembled program (`MOV`/`ADD`/`MOV VX,VY`/`SWRITE`/`HLT`)
  executed via repeated `Cpu::step()` calls, checking the resulting
  register value, screen pixel, and Z flag.
- A second hand-assembled program exercising an `INC`/`DEC`/`JNZ` loop
  (5 iterations), checking both counters' final values.
- The full nested-loop demo program now baked into `main.star` (256x256
  diagonal gradient via `SWRITE`, `INC`+`JNZ` wraparound loops, `JMP`) —
  first run headlessly for exact pixel-value checks at several
  coordinates, *then* wired into the real SDL window and confirmed
  visually (a screenshot during development showed the expected diagonal
  rainbow stripes through the palette). The first draft of this program
  had two real hand-encoding bugs (a wrong mode byte on a `CMP`, and a
  loop condition — `R0 <= 255` — that can never be false for an 8-bit
  register) caught by exactly this headless-first-then-visual process;
  worth keeping for anything hand-encoded in the future.
- The math library / Q8.8 fixed-point opcodes (0x5B-0x6C, 0xAC-0xAF),
  checked against the actual **running** Python reference (via the
  Nova-16 MCP server) rather than hand-computed expectations — see "Math
  library / Q8.8 fixed-point"'s own "Verification" section below for the
  full process.
- The string library and integer/string conversion opcodes (0x71-0x7B,
  0x83-0x86), checked two ways: a standalone headless Star harness (19
  hand-computed checks) and, separately, the same live-Python-reference
  process as the math library round — see "String library and
  integer/string conversion"'s own "Verification" section below.
- The BCD opcodes (0x4B-0x54), checked by replaying the *exact same
  machine-code bytes* through both the live Python reference (over MCP)
  and this port's own `Cpu::step()`, checkpoint by checkpoint, rather than
  hand-computing expected BCD values independently for each side — see
  "BCD operations"'s own "Verification" section below for why (the
  reference's own BCD algorithm turned out to have a real, non-obvious
  quirk that hand-derivation from idealized decimal-adjust math got wrong
  on the first pass here too).

## Math library / Q8.8 fixed-point (0x5B-0x6C, 0xAC-0xAF)

Added in this round: the full math library (`POWR SQRT LOG EXP SIN COS TAN
ATAN ASIN ACOS DEG RAD FLOOR CEIL ROUND TRUNC FRAC INTGR`) and Q8.8
fixed-point conversion (`FMUL FDIV FTOI ITOF`), ported from
`core/exec_handlers.py`'s `_powr`/`_sqrt`/.../`_itof`. Implementation lives
in `cpu.star`'s "Math library"/"Fixed-point Q8.8 conversion" sections
(right after `op_popcnt`), dispatched from `execute` the same way as every
other opcode.

Notable decisions and quirks found while porting, each also called out at
its point of use in `cpu.star`:

- **Every one of these opcodes treats its operand as 16-bit signed
  regardless of the destination's resolved width**, via `to_signed(a, 16)`
  called unconditionally — matching the reference's own hardcoded
  `_to_signed_16`, and a deliberate *exception* to this port's usual
  "infer width from the destination register's real kind" rule (see
  "Operand width is inferred..." above). Justified because Q8.8 is
  inherently a 16-bit format and real programs always target a `P`
  register or memory with these; the one case where the distinction could
  matter (an 8-bit `R`/`VX`/`SF`/... destination) already reads only 8
  bits before the signed reinterpretation runs, making it a no-op in both
  this port and the reference alike.
- **`TAN` (0x61) is a genuine upstream quirk, not a transcription slip**:
  unlike every other trig opcode here, it uses its operand directly as
  radians (not `/ 256.0`) and scales its result by 1000 (not 256) —
  confirmed intentional by `core/exec_handlers.py::_tan`'s own docstring
  ("tangent (scaled by 1000)"). Ported bug-for-bug.
- **`DEG`/`RAD` convert between a plain-integer degree count and Q8.8
  radians**, not between two Q8.8 values — easy to misread from the opcode
  names alone; `core/exec_handlers.py::_deg`/`_rad` confirm the asymmetry.
- **`FLOOR`/`CEIL`/`ROUND`/`FDIV` needed Python's floor-toward-negative-
  infinity division semantics**, which Star's own `/`/`%` don't have (they
  truncate toward zero — gotcha #1). Added a small `floor_div16` free
  function (trunc-to-floor adjustment: subtract 1 from the truncating
  quotient exactly when the remainder is nonzero and the operands' signs
  differ) rather than reaching for float math, which sidesteps the
  precision question below entirely for this family.
- **`ROUND` reproduces Python's round-half-to-even** with pure integer
  arithmetic, no float involved: since `v / 256.0` is always *exact* for a
  16-bit `v` (256 is a power of 2), the "exactly .5" tie case is a genuine
  tie, not a float-rounding artifact, and occurs exactly when the
  floor-remainder (`v` mod 256, always in `[0, 256)`) equals 128 — checked
  directly, then broken by the floor quotient's own parity.
- **`SIN`/`COS`/`TAN`/`ATAN`/`ASIN`/`ACOS`/`LOG`/`EXP`/`SQRT`/`POWR` route
  through Star's builtin math functions, which are `f32` (single)
  precision — the Python reference is `f64` throughout.** Deliberately
  accepted for the Q8.8-scaled ones: 8 bits of fractional precision is far
  inside `f32`'s ~23-bit mantissa, so it can only matter at an exact-tie
  rounding boundary. `POWR` and `EXP` are the two placed where this gap is
  actually reachable and worth flagging specifically:
  - `POWR`'s "overflow → 0" fallback (matching `_powr`'s caught
    `OverflowError`) triggers far more often here, since `f32` overflows to
    +inf around `3.4e38` where `f64` doesn't until `~1.8e308`. Beyond
    `f32`'s exact-integer ceiling (`2**24`, ~16.8M) a finite `POWR` result
    is also only an approximation of the reference's exact
    (arbitrary-precision-then-truncated) low 16 bits, not a bit-exact
    match — there's no way to reproduce that through float math without
    implementing bignum exponentiation, so this is flagged rather than
    silently wrong.
  - `EXP` substitutes `0xFFFF` (not `0`) on overflow, matching `_exp`'s own
    except-clause. `f32` overflows around `exp(88.7)`, `f64` not until
    `exp(709.8)` — and the input range here (`v/256` up to ~128) actually
    reaches past the `f32` threshold, unlike the other trig ops whose
    output magnitude is bounded regardless of precision.
- **`FDIV` by zero prints a diagnostic and skips the write** rather than
  raising (Python's `_fdiv` raises `RuntimeError`), matching the existing
  `DIV`/`MOD`/`DIVH`-by-zero precedent elsewhere in this port (see "Known
  simplifications" below) instead of introducing a second by-zero policy.
- **Star's float lexer had no scientific-notation literal syntax**
  (`3.0e38` lexed as the two tokens `3.0` and the bare identifier `e38`,
  not one float token — confirmed the hard way, first draft of `op_exp`/
  `op_tan`'s overflow-guard threshold). Originally worked around with a
  `const MATH_OVERFLOW_GUARD: f32 =
  300000000000000000000000000000000000000.0` (the full expansion of
  `3e38`) rather than reaching for a `f32::INFINITY`/`is_infinite` builtin,
  neither of which exist either. **Fixed** at the compiler level (gotcha
  #11 above, `todo.md` P3 #12): `MATH_OVERFLOW_GUARD` is now spelled
  `3.0e38` directly in `cpu.star`. There's still no `f32::INFINITY`/
  `is_infinite` builtin — unneeded here since the guard-threshold
  comparison already achieves the same effect, but a future project could
  still hit that gap on its own.

### Verification

Unlike everything ported before it in this project (verified only against
hand-computed expected values or the Python *source* read directly), this
round was checked against the actual **running** Python reference via the
Nova-16 MCP server — assembling a real `.asm` test program
(`asm`-syntax `MOV`/`FTOI`/`ITOF`/`FMUL`/`FDIV`/`TRUNC`/`FRAC`/`FLOOR`/
`CEIL`/`ROUND`/`SQRT`/`POWR`/`LOG`/`EXP`/`SIN`/`COS`/`TAN`/`ATAN`/`ASIN`/
`ACOS`/`DEG`/`RAD` covering every new opcode, including deliberately
negative/edge-case operands and two overflow-triggering `POWR`/`EXP`
inputs), running it on the live reference CPU, and recording `P0`-`P3` at
15 checkpoints. The exact same assembled `.bin` was then loaded into this
port via `file_read_bytes` (a genuine, if temporary, real-world use of the
binary-safe loader gotcha #9 unblocked but never wired up — see "Ideas for
future work" below) into a standalone headless harness stepping through the
same 15 checkpoints and diffing `P0`-`P3` against the reference's recorded
values. All 15 checkpoints matched exactly, including every transcendental
op — `f32`-vs-`f64` turned out not to bite anywhere in this test's input
range (only `POWR`/`EXP`'s already-documented overflow-threshold gap is
known to differ, and this test's overflow cases were chosen large enough
that *both* implementations already fall back to their guard value, so
even that gap didn't surface as a visible mismatch here).

One MCP-server-specific discovery along the way, unrelated to Star or Nova
itself: **the reference emulator's `halted` flag is sticky through the MCP
tool surface** — once `HLT` sets it, neither `set_register("PC", ...)` nor
`cpu_step` clears it, so a test program with an intermediate `HLT`
"checkpoint" can never be resumed past it in the same session (confirmed
directly: `cpu_step` after manually setting `PC` past a `HLT` still reports
`"halted": true` and performs no work). Worked around by dropping every
`HLT` from the middle of the test program (blocks fall through into each
other with no gap — an `ORG` gap pads with `0x00`, which *is* `HLT`, an
earlier version of this test program hit that too) and driving the whole
thing with `cpu_step(count=N)` where `N` is each block's own known
instruction count, checking state between calls instead of relying on
`HLT`+resume.

## String library and integer/string conversion (0x71-0x7B, 0x83-0x86)

Added in this round: the string library (`STRCPY STRCAT STRCMP STRLEN
STRUPR STRLWR STRREV STRFIND STRFINDI`) and integer/string conversion
(`ITOB BTOI ITOS STOI`), ported from `core/exec_handlers.py`'s `_strcpy`/
`_strcat`/.../`_stoi`. Implementation lives in `cpu.star`'s "String
operations"/"Integer/string conversion" sections (right before the
dispatch table), dispatched from `execute` the same way as every other
opcode. `STREXT`/`STREXTI` (0x75/0x76) stay unimplemented — 4-operand
opcodes, see "4-operand instructions are out of scope" above.

Notable decisions and quirks found while porting, each also called out at
its point of use in `cpu.star`:

- **Every string/address operand resolves through the exact same
  `operand_read(op, 16)` convention `MEMCPY`/`MEMSET`/etc. already use**:
  a register or immediate operand's own value *is* the address; a
  memory-mode operand's contents are dereferenced once more as a 16-bit
  pointer. Matches `core/exec.py::_resolve_single_operand`'s `is_memory`
  case exactly — nothing string-specific needed inventing here.
- **`STRCMP`/`STRLEN`/`STRFIND`/`STRFINDI` write their result straight to
  `R0`, bypassing the destination-operand mechanism entirely** — matches
  `_strcmp`/`_strlen`/`_strfind`/`_strfindi`'s own `cpu.regfile.set('R', 0,
  ...)` calls, which the `Instruction.execute` wrapper's usual
  `_write_result(cpu, 0, ...)` writeback path never touches for these four
  opcodes (no `flags_fn`/writeback is registered for them in
  `core/exec.py`'s dispatch table). Easy to misread from the operand list
  alone: none of `STRCMP`'s three operands (`str1`, `str2`, `length`) is a
  "destination" in the usual sense.
- **`STRCPY`/`STRCAT`/`STRUPR`/`STRLWR`/`STRREV` set no flags at all** —
  confirmed by their handlers never calling `_set_arith_flags`, unlike
  every arithmetic/comparison opcode ported so far in this project.
- **`ITOS` always writes its decimal string to the fixed static buffer
  `0xA000`**, never wherever its own destination operand points —
  `_itos` hardcodes `buffer_addr = 0xA000` rather than deriving it from an
  operand; the destination operand only ever receives that fixed address
  back as a pointer. Easy to misread as "write the string at the
  destination address" from the opcode name alone.
- **`STOI`'s decimal parser is a deliberate simplification of Python's
  `int(str)`**: an optional leading `+`/`-` then one or more ASCII digits,
  requiring the *entire* string to match (any other character anywhere, or
  an empty string, yields 0) — covers every string `ITOS` itself can
  produce and anything a real assembler would encode, without reproducing
  `int()`'s whitespace-stripping (`" 5 "` parses to `5` in Python; this
  port's `STOI` treats it as invalid and yields 0). Not reachable from any
  test vector exercised here, but worth knowing before relying on it
  against a hand-crafted string with leading/trailing whitespace.
- **`ITOB`'s bit string is built most-significant-bit first**, matching
  `_itob`'s own "prepend each new bit" construction — easy to get backwards
  if translated as "append each bit as it's produced" instead (which would
  emit least-significant-bit first).

### Verification

Checked two ways, matching (and extending) the math library round's own
"don't just trust a hand read of the Python source" standard:

1. **A standalone headless Star harness** (not checked in — see "Testing"
   above for why this project keeps none of these), 19 checks covering
   every opcode in this group against hand-computed expected values
   (`"Hello"` + `" World"` → `STRCPY`/`STRCAT` → `"Hello World"`; `STRCMP`
   at two different lengths to exercise both the equal-prefix and the
   mismatch-after-shared-prefix path; `STRFIND`/`STRFINDI` found and
   not-found; `ITOB(13)`/`ITOB(0)` round-tripped through `BTOI`; `ITOS`
   of a negative value round-tripped through `STOI`; `STOI` on an invalid
   and an empty string). All 19 passed.

   One real Star-specific pitfall hit while writing this harness, worth
   recording since it'll bite the next one too: the harness's first draft
   used ordinary free functions taking `mut c: cpu::Cpu` to write test
   strings into memory and hand-encode instructions. Every single check
   silently failed — not because the opcodes were wrong, but because a
   `Cpu`-by-value parameter is a *real copy* even now that large-aggregate
   by-value parameters compile without hanging `clang` (todo.md P0 #2):
   the free functions were mutating a throwaway copy's memory, never the
   caller's actual `Cpu`. Fixed by making every mutating helper a method
   on `Cpu` (`impl cpu::Cpu:` in the harness file) instead, so `self` — the
   one parameter kind this compiler pointer-passes — carries the mutation
   back correctly. See "Four Star compiler bugs found and fixed" #4 above
   for a second, subtler bug this same harness turned up while doing this
   (a diamond import silently deleting a cross-module `impl` block
   entirely) — now fixed at the compiler level, verified with the full
   `cargo test` suite (0 regressions across all suites).

2. **The actual running Python reference** (via the Nova-16 MCP server),
   the same process the math library round established: a real `.asm`
   test program (`STRCPY`/`STRCAT`/`STRLEN`/`STRCMP`/`STRUPR`/`STRLWR`/
   `STRREV`/`STRFIND`/`STRFINDI`/`ITOB`/`BTOI`/`ITOS`/`STOI`, independent
   test vectors from the headless harness above) assembled and run on the
   live reference CPU with no intermediate `HLT` (avoiding the sticky-
   `halted` MCP quirk the math library round already found), then every
   `R`/`P` register and every string buffer's memory contents checked
   against the reference's actual post-run state. All checks matched
   exactly on the first attempt — no corrections needed to `cpu.star`
   itself from this pass, giving real confidence the source-reading-only
   port above was accurate.

## BCD operations (0x4B-0x54)

Added in this round: `SED CLD CLA BCDA BCDS BCDCMP BCD2BIN BIN2BCD BCDADD
BCDSUB`, ported from `core/exec_handlers.py`'s `_sed`/`_cld`/`_cla`/
`_bcda`/.../`_bcdsub` and `core/flags.py::set_from_bcd`. Implementation
lives in `cpu.star` right after `op_popcnt` (the BCD group sits between
the bitwise/arithmetic block and the math library in the reference's own
opcode numbering too), dispatched from `execute` the same way as every
other opcode; `SED`/`CLD`/`CLA` (no operand at all) are handled inline in
`execute`, same as `CLI`/`STI`, rather than as their own `op_*` methods.
`flags.star` gained a new `Flags::apply_bcd(result, bcd_carry)`, mirroring
`set_from_bcd` — the one flag helper in this file that's always 8-bit
regardless of the destination's real width, since a BCD byte packs
exactly two decimal digits no matter which register holds it.

Notable decisions and quirks found while porting, each also called out at
its point of use in `cpu.star`:

- **BCDA/BCDS/BCDADD/BCDSUB's *written-back value* is always masked to a
  fixed 8-bit width** (`result & 0xFF`, matching `_write_result`'s own
  masking in the reference), regardless of whether `op1` is a 16-bit
  destination (a `P` register or memory). This does **not** mean the
  *read* is 8-bit too — see the correction below, found in a later pass
  over this section, for a real bug that conflated the two. `BCD2BIN`/
  `BIN2BCD` are a separate case: they use this port's usual destination-
  driven width for both read and write (see the "Operand width is
  inferred..." deviation above), which the reference doesn't do (it always
  treats the value as 16-bit, 4 nibbles) — but since a valid packed-BCD
  result never exceeds 9999, well under either width's sign threshold, an
  8-bit destination's flags never actually differ from what the
  reference's always-16-bit computation would produce; confirmed with a
  dedicated 8-bit-vs-16-bit equivalence check in the verification harness
  below.
- **BCDA/BCDS's "add/subtract 1 when the A flag is set" step is gated on
  D (decimal mode) being *un*set** (`if not D and A: ...`) — backwards
  from what "carry-in" would suggest (you'd expect it gated on D being
  set, or applying unconditionally), but that's what `_bcda`/`_bcds`
  actually do, confirmed against the live reference (checkpoints 4-5 in
  the verification section below specifically isolate this gate in both
  directions). `BCDADD`/`BCDSUB` don't have this step at all — they're the
  plain, non-chaining add/subtract.
- **Corrected in a later pass (prompted by generalizing the write-width fix
  above, which is what put fresh eyes on this whole section): two real bugs
  in this port's `op_bcda`/`op_bcds`/`op_bcdadd`/`op_bcdsub`, neither
  actually present in the reference, despite this section previously
  documenting both as "confirmed reference behavior."**
  1. **The read width was hardcoded to 8 bits for both operands**, on the
     theory that "BCD always operates at a fixed 8-bit width" (see the
     first bullet above) extended to the *read* as well as the write. It
     doesn't: `core/exec_handlers.py`'s `_resolve_single_operand` applies
     the ordinary "8 if the overall destination is an `R` register, else
     16" rule to BCD operand reads exactly like every other instruction —
     only the final written-back value gets an unconditional `& 0xFF`.
     Confirmed against the live reference over MCP: `BCDA P0, P1` with
     `P0=0x1234`, `P1=0x0006` reads the *full* 16-bit values (raw sum
     `0x123A`), not `0x34 + 0x06 = 0x3A` — which changes whether the
     carry flag comes out set (see next bullet for why this particular
     example also exercises bug 2). Fixed by reading at
     `operand_width(op1)` like every other two-operand arithmetic op in
     this file, exactly as the already-generalized `write_width_for`
     pattern above does for the *write* side.
  2. **The BCD-carry/borrow check ran against the *masked* result instead
     of the raw pre-mask value** — the exact opposite of what
     `core/exec_handlers.py` actually does. `_bcda`'s statement order is
     `carry = result > 0x99` *directly followed by* `result &= 0xFF` — the
     carry check reads `result` one line *before* it gets masked, not
     after. (`_bcds`/`_bcdadd`/`_bcdsub` all follow the identical pattern.)
     A previous pass over this file got the order backwards and then
     documented the mistake as if it were confirmed reference behavior,
     down to a specific (and, on inspection, unconvincing) example: "`BCDS
     0x42, 0x15` still reports C=0" — but `0x42 > 0x15`, so that's not a
     borrow case at all; whoever wrote that check picked an example that
     couldn't have demonstrated the claim either way. Re-verified for real
     this time, against the **running** reference over MCP, with inputs
     specifically chosen so the pre-mask and post-mask checks disagree:
     `BCDA R0, R1` with `R0=R1=0x89` (raw sum `0x112`/274, masked `0x12`)
     comes back from the live reference with **C set** — only possible if
     the carry check runs against the unmasked 274, not the masked 18.
     `BCDS R0, R1` with `R0=0x15`, `R1=0x42` (a genuine borrow, raw diff
     `-45`) likewise comes back with **C set**, contradicting the old
     "BCDS's borrow flag is always cleared" claim outright. Both fixed by
     computing `carry`/`borrow` from `raw` *before* the `& 0xFF` mask,
     matching the reference's actual statement order.

  Both bugs trace back to the same root cause: an earlier pass read
  `_write_result`'s `result & 0xFF` masking (which genuinely does apply
  unconditionally to the *written value*) and over-generalized it to "BCD
  operates at 8 bits, full stop" — read width and carry-check timing
  included — without separately re-verifying those two specific claims
  against the live reference the way this project's own stated standard
  (see "Testing" below) requires. Left as a cautionary note rather than
  silently corrected: a plausible-sounding, specifically-worded claim
  ("confirmed against the live reference," a named example) is not the
  same thing as an actually-run verification, and this file is not immune
  to stating one while having done the other.
- **BCDCMP compares its two operands as plain numbers**, with no
  decimal-digit adjustment at all, and its S flag is not "sign of the
  subtraction" the way `apply_arith`'s CMP path computes it elsewhere in
  this file — it's simply "1 iff op1 < op2", 0 in both the equal and
  greater-than cases. Ported directly from `_bcdcmp`'s explicit three-way
  if/elif/else rather than reused through `apply_arith`.
- **`BCD2BIN` on an invalid packed-BCD value (any nibble > 9) leaves the
  operand unchanged** rather than producing a garbage numeric result —
  matches `_bcd2bin`'s own `valid` flag falling back to `bcd` itself.

### Verification

Following the same "don't just trust a hand read of the Python source"
standard the math library and string library rounds established, but
with a twist this round specifically needed: rather than hand-deriving
expected BCD values independently and comparing both implementations
against that derivation (the approach every earlier round used), this
round assembled one `.asm` test program (16 checkpoints covering every
new opcode, including the two aux-carry-gate checkpoints above and both a
valid and an invalid packed-BCD `BCD2BIN` input), ran it on the live
reference CPU via the Nova-16 MCP server (single-stepped, `R`/`P`
registers and flags read directly from `get_cpu_state` — no memory writes
or `HLT` needed, sidestepping the sticky-`halted` MCP quirk entirely),
recorded the reference's own register/flag values at each checkpoint, and
then **replayed the exact same assembled machine-code bytes** (copied
byte-for-byte from the assembler's own output, not re-encoded by hand)
through this port's `Cpu::step()` in a standalone headless harness,
diffing against the recorded reference values. All 16 checkpoints matched
— after the masking-order bug above was found and fixed by exactly this
process (the harness's first draft, using the "obviously correct"
pre-mask carry check, disagreed with the live reference at checkpoint 3;
the reference was right, the harness's assumption was wrong).

The byte-for-byte replay (rather than two independent hand-derivations)
was deliberate: idealized BCD/DAA math is a well-known algorithm, and
hand-deriving "the correct answer" for a tricky case risks silently
reproducing the *idealized* algorithm instead of the reference's actual
(buggy) one — exactly the trap a purely hand-computed test would fall
into. Using the reference's own assembler output as the input to both
sides removes that risk entirely: any mismatch can only mean this port's
opcode handler itself is wrong, not that the expected value was
mis-derived.

**This "16 checkpoints, all matched" claim above turned out to describe a
harness that was never checked in** (see "Testing" below — this project's
own stated policy is to check in exactly this kind of regression test, but
this round's own harness wasn't), and re-deriving the read-width and
masking-order fixes above from scratch found the actual code disagreed
with the live reference in exactly the two ways described — meaning
whatever the original harness checked, it didn't catch either bug, or the
"16/16 matched" report predates the bugs being introduced and was never
rerun after. Not resolvable in hindsight which; recorded here so it isn't
repeated. This time both fixes are backed by **checked-in** regression
tests: `tests/asm/bcd_width_test.asm` (`BCDA P0, P1` with `P0=0x1234`,
`P1=0x0006`, capturing the carry flag into a register via `JC`/`JMP` since
`tests/run_bin.star` doesn't print flags directly — `P0`=0x003A, carry=1,
matching the live reference exactly and disagreeing with what the
pre-fix code produced) and two smaller, sharper probes isolating each half
of the masking-order fix on their own — `tests/asm/bcda_carry_order_test.
asm` (`BCDA R0, R1` with `R0=R1=0x89`, pure `R`-register operands so the
read-width fix can't be masking the result, raw sum 274 vs. masked 18) and
`tests/asm/bcds_borrow_order_test.asm` (`BCDS R0, R1` with `R0=0x15`,
`R1=0x42`, a genuine borrow) — both confirming carry/borrow tracks the
pre-mask `raw` value, not the post-mask `result`.

One footgun hit again while writing the headless harness, already
documented in the string-library round's own verification section above
but easy to trip on independently: the harness's first draft used plain
free functions taking `mut c: cpu::Cpu` for its `run_steps`/`checkpoint`
helpers, and every single checkpoint silently reported the CPU as never
having advanced (`R0`/`P0` stuck at 0 forever) — not because `step()`
itself was broken, but because the free functions were mutating a
throwaway *copy* of `c`. Fixed the same way as before: made both helpers
`impl cpu::Cpu:` methods in the harness file so `self` carries the
mutation back correctly.

## Binary program loading

Added in this round: `loader.star`'s `Cpu::load_program(bin_path) ->
(entry_point, ok)`, wired into `main.star` (`nova16.exe path/to/prog.bin`
loads and runs a real compiled program; no argument keeps the old built-in
demo) and into every test harness in `tests/`. This is the thing gotcha #9
(`file_read`'s NUL-truncation) unblocked at the language level
(`file_read_bytes`) but never had anywhere to plug in — this round's actual
blocker was never the language, it was that this port had no assembler
*and no test asm to load*; both are now moot since the upstream Python
`nova_assembler.py` can assemble a real `.asm` into a `.bin` this loader can
read directly.

Segment format: mirrors `nova/memory/memory.py::Memory.load`/
`load_with_org_info` exactly, since that's the actual producer/consumer
pair this needs to interoperate with, not something invented independently.
`nova_assembler.py` always writes a `.org` sidecar next to its `.bin`
output — one line per contiguous `ORG` segment, `<start_addr_hex>
<length_decimal> <bin_offset_decimal>`, comments starting with `#`. The
*first* segment's address becomes the entry point (`PC`'s initial value),
matching the reference's own "first segment sets entry_point" rule.
`.bin`s with no matching `.org` (any other binary blob) load at address 0,
matching the reference's own "legacy" fallback.

Parsing needed real integer parsing this project had never needed before —
Star has no `parse_int`/`atoi` builtin, but does support declaring one
directly against the C runtime already linked in: `extern "C" fn atoi(s:
str) -> i32` and `extern "C" fn strtol(s: str, endptr: ptr, base: i32) ->
i32` (`strtol(s, null_ptr(), 0)` auto-detects the `.org` file's `0x`-prefixed
hex addresses, matching `int(parts[0], 16)`'s explicit base-16 the
reference uses, while still accepting plain decimal for free). Both are
ordinary, already-linked C runtime symbols on this target (confirmed
working, no extra `-l` flag needed) — no new language feature, just the
first real use of `extern "C" fn` for something other than a toy example in
this project. One real gotcha hit while writing this: `str` has no `.len()`
*method* (`len(s)` is a free function instead, unlike `Bytes`/`List<T>`'s
own `.len()` methods) — a `no field len on type Str` compiler error caught
this immediately rather than silently doing the wrong thing.

`Cpu::load_program` lives as a method on `cpu::Cpu` (a cross-module `impl`,
gotcha #6) rather than a free function taking `Cpu` by value, for the same
by-value-large-struct reason `draw_text`/the sprite-blit methods below do —
see NOTES.md's established rule. This is also the same shape ("a second
file's `impl cpu::Cpu:` alongside `cpu.star`'s own `impl Cpu:`") gotcha #6's
bug #4 (a diamond import silently deleting a cross-module `impl` block) was
originally found through; re-confirmed fixed here too (`main.star` imports
both `cpu.star` directly and `loader.star`, which itself imports
`cpu.star` — a genuine diamond — and `load_program` resolved correctly).

### Verification

`tests/asm/uart_integration_test.bin`/`.org` were copied *verbatim* from
the upstream Python repo's own `asm/uart_integration_test.bin`/`.org` (not
reassembled, not authored for this port) and loaded through this exact
mechanism — proving the loader can run an existing, independently-produced
Nova-16 program unmodified, not just a program this port's own author
happened to assemble. Confirmed byte-accurate: `PC` starts at the `.org`
file's recorded entry point (`0x1000`), and the very first instruction
(`MOV P0, 0xDEAD`) executes correctly (`P0 == 0xDEAD` after one step). The
same run also became this round's first real regression signal for the
still-unimplemented UART opcodes at the time (see "UART" below) — the CPU
halted cleanly with `unimplemented opcode 165 (0xA5, SERCTRL) at pc=4102`,
exactly the diagnostic "Known simplifications" promises, rather than
crashing or desyncing.

## Disassembler

Added in this round: `disasm.star`, a real disassembler — decodes a
compiled `.bin` back into readable Nova-16 assembly text (`ADD [0x3000],
R0` rather than a raw hex dump). Named in "Ideas for future work" since the
binary loader round, picked up for real this round as the first piece of
work explicitly framed around this file's new "de facto emulator" goal (see
the framing note at the top of this file) rather than "language exercise."

Deliberately independent of `Cpu`/`cpu.star`: disassembly is a pure, static
byte-stream decode (opcode byte -> mnemonic/operand-count from a lookup
table, mode byte -> addressing mode, no register *values* or machine state
involved anywhere), so `disasm.star` imports only `bits.star` (for
`sign_extend8`) — no `Memory`/`Screen`/`Uart`/`sound.star`, and, unlike
every other Nova build target in this project, it links with **no SDL2
dependency at all** (`sound.star`'s audio builtins are the only reason
`tests/run_bin.star`/`main.star`/`uart_bridge.star` all need `-l SDL2`;
this tool never touches that import chain).

### The opcode table: code as ground truth, not the doc

The hard part of a disassembler isn't decoding one instruction — it's
knowing exactly how many operand bytes each opcode consumes, since getting
one wrong desyncs every instruction after it in the stream. The obvious
source is `docs/nova16_instruction_reference.md`'s own opcode table
(mnemonic, hex opcode, operand count, one line per instruction) — but this
project's own repeated experience (`SPRITE_SYSTEM.md`'s stale "Instructions"
section, the base instruction reference's own stale `PUSH`/`POP` stack-slot
width, both documented elsewhere in this file) is that a doc can silently
drift from the code it describes, and "Status: this port now supersedes the
Python reference" below already establishes the standing rule for exactly
this situation: re-derive from source, don't trust the doc by default.

So every opcode's operand count in `disasm.star`'s `opcode_info` table was
mechanically cross-checked against `cpu.star`'s own `decode_operands(N)`
call sites (or, for the handful of opcodes handled inline in `execute`
rather than through a dedicated `op_*` method — `HLT`/`NOP`/`RET`/`IRET`/
`CLI`/`STI`/`SED`/`CLD`/`CLA`/the twelve conditional jumps via the shared
`jump_if` helper — read directly from `execute`'s dispatch) rather than
taken from the doc at face value. **That cross-check found ten real
operand-count errors in the doc itself**, each confirmed against the
actual, already-live-reference-verified `cpu.star` handler and now fixed
directly in `docs/nova16_instruction_reference.md`:

- **`SFLIP` (0x37)**: doc said 2 operands, `op_sflip` actually decodes 1
  (just an axis; there's no separate amount operand the way `SROL`/`SROT`/
  `SSHFT` have).
- **`KEYCLEAR` (0x46)**: doc said 1 operand (with its own description
  hedging "operand ignored?", a doc that already didn't fully believe
  itself) — `op_keyclear` decodes 0. Same story for **`SED`/`CLD`/`CLA`
  (0x4B/0x4C/0x4D)**: each doc entry said 1 operand, but all three are
  handled inline in `execute` with no `decode_operands` call at all (0
  operands) — matching this file's own "BCD operations" section, which
  already correctly described `SED`/`CLD`/`CLA` as "no operand at all,"
  just never made it back into the instruction reference doc itself.
- **`BCDA`/`BCDS`/`BCDCMP`/`BCDADD`/`BCDSUB` (0x4E/0x4F/0x50/0x53/0x54)**:
  doc said 1 operand each; `op_bcda`/`op_bcds`/`op_bcdcmp`/`op_bcdadd`/
  `op_bcdsub` all call `decode_operands(2)`. This one is the most
  consequential of the ten — a real two-operand instruction decoded as
  one-operand would desync every following byte in the stream — and this
  file's own "BCD operations" section already shows a `BCDA P0, P1`
  two-operand worked example, so the doc's "1 operand" was already
  contradicted by this file before the disassembler forced a real
  cross-check to notice.

`BCD2BIN`/`BIN2BCD` were the control case: the doc's "1 operand" for those
two is correct (`decode_operands(1)`, confirmed), which is why they aren't
in the list above — the disassembler cross-check corrects, it doesn't
uniformly distrust.

Two same-byte aliases were also confirmed *not* to be bugs, by reading the
Python reference's own handlers directly rather than assuming from the
shared dispatch target alone: `execute`'s `0x91` (`SAL`) dispatches to the
same `op_shl` as `0x14` (`SHL`), and `0x6C` (`INTGR`) dispatches to the same
`op_trunc` as `0x6A` (`TRUNC`). `core/exec_handlers.py::_sal`'s own body is
`return _shl(cpu, values)`, and `_intgr`'s own docstring says "alias of
TRUNC" with a body identical to `_trunc`'s — both opcodes are *supposed* to
share a handler, matching the reference exactly. `disasm.star`'s opcode
table still gives each its own correct mnemonic (disassembly reflects the
byte encoding, not which handler happens to implement it), so this had no
effect on the table itself; noted in the file's own header comment so a
future reader who spots the shared handler in `cpu.star` doesn't mistake it
for a missing-opcode bug.

Opcodes with no `cpu.star` handler at all (hardware debugging, `STREXT`/
`STREXTI`/`MEMCMP`, `SMIX`/`SECHO`/`SREVERB`/`SFILTER` — see "What's not
implemented" above) have no running code to cross-check against, so their
operand counts are still doc-sourced and flagged `unverified` in
`disasm.star`'s own table.

One earlier suspected doc gap that turned out **not** to be real, corrected
before it was written down anywhere permanent: a first pass over
`docs/nova16_instruction_reference.md`'s "Special Registers" section
suspected it was missing the `P0:`-`P9:`/`:P0`-`:P9` byte-half register
codes (0xC9-0xDC) entirely. That was wrong — a `grep` pattern that happened
to exclude `:`-containing mnemonics was the actual cause, not a real
omission; the doc covers the full 0xC2-0xFE range correctly. `disasm.star`
still sources its own register-name table from `cpu.star::get_reg_value`
directly rather than the doc, consistent with its general "the code is the
source of truth" stance for everything else in this file, but that's a
choice of convention, not a doc-gap workaround.

### Genuine Star compiler bugs found while writing this file

Two, both found, fixed, and verified with zero regressions against the
full `cargo test` suite — see "Seven Star compiler bugs found and fixed"
below, entries #6 and #7. A third, related issue (calling an f-string-
materializing function more than once in the same program run can corrupt
its own output) was found but not root-caused or fixed — `disasm.star`
routes around it by never using an f-string anywhere in its own source
(every dynamic string is built with `concat`/`str_join` instead); see that
same section's write-up for the full repro and status.

### Verification

Run against four independently-produced `.bin`s already checked in under
`tests/asm/` (not new files written to flatter the disassembler): `write_
width_test.bin` and `bcd_width_test.bin` (round-tripped byte-for-byte back
to a text form matching their own `.asm` source exactly, including the
corrected `BCDA P0, P1` two-operand decode above), `push_pop_width_test.
bin` (confirming `PUSH R0`/`PUSH P0`/`PUSH [mem]`'s differing operand
widths decode as single operands regardless of the underlying stack-slot
width difference — a CPU-execution concern, not a disassembly one), and
`uart_integration_test.bin` (the file copied verbatim from the upstream
Python repo, not authored for this port — decodes cleanly starting at its
`.org` file's recorded entry point `0x1000` with `MOV P0, 0xDEAD` as the
first instruction, matching "Binary program loading"'s own verification of
the same file above). Every decoded mnemonic, operand, and byte-length
matched the source `.asm` exactly across all four files.

## Assembler

Added this round: `assembler.star`, a real assembler — turns a `.asm`
source file into a compiled `.bin` plus `.org`/`.sym` sidecars, matching
the upstream Python `nova_assembler.py`'s own accepted syntax and output
conventions closely enough that either assembler can consume the other's
inputs. Named as the single biggest remaining named-tooling gap since the
disassembler round (todo.md P1 #2, "Ideas for future work"): the binary
loader and disassembler gave an assembler's output somewhere to go and a
way to check it immediately, which wasn't true before either existed.

### Design: reuse the disassembler's own verified tables, don't re-derive

`assembler.star`'s opcode table (mnemonic -> opcode byte, operand count)
and register table (name -> register code) are transcribed directly from
`disasm.star`'s own `opcode_info`/`reg_name` — not re-derived independently
from `docs/nova16_instruction_reference.md` or from Python's `opcodes.py`.
Cross-checked against `opcodes.py` directly while writing this (every
mnemonic/opcode/arity triple matches exactly, register table too — 180
instruction entries, 61 register entries, both counts confirmed by
`grep`ping each file's own match-arm/insert-call count), so this isn't
blind trust in an unverified transcription; it's confirmation that
`disasm.star`'s already-cross-checked-against-`cpu.star` table and the
Python reference's own opcode table agree, and building the assembler from
the same source of truth as the disassembler means an assemble-then-
disassemble round trip is a genuine end-to-end check of both tools against
each other, not two independently-guessed tables happening to agree by
coincidence.

Two-pass design, same shape as `nova_assembler.py::Assembler.first_pass`/
`second_pass`: pass one walks every parsed line building a `Map<str, i32>`
symbol table (label -> address, `EQU` name -> resolved value) while
computing each line's byte size without needing that table to be complete
yet (a bare non-literal operand token always sizes as a 2-byte immediate
regardless of whether it's already a resolved symbol — matching
`nova_assembler.py::OperandClassifier.classify_operand`'s own fallback
behavior exactly, confirmed by reading it directly rather than assumed);
pass two re-walks the same lines with the complete symbol table to emit
real bytes. A `validate_lines` pass runs between the two (unknown
mnemonics, unimplemented instructions, unresolvable register/symbol
operands) so a malformed source is reported through a real nonzero exit
code from `main` before any file is written — see "No process-abort
builtin, so validate before emitting" below for why errors are collected
this way rather than aborting mid-emit.

### No process-abort builtin, so validate before emitting

Star has no `panic`/`abort`/`std::process::exit`-equivalent builtin
reachable from ordinary code, and `extern "C" fn exit` cannot be declared
either — confirmed empirically, the checker rejects it outright
(`"extern "C" fn `exit` collides with a symbol this compiler always
declares internally"`, since the compiler's own runtime trap machinery
already links `@exit` for its own use, `src/codegen/mod.rs`). With no way
to unwind or terminate early from deep inside a nested call (encoding a
single operand can be several calls deep), a Python-style "collect errors
as `raise`s and report them all at the end" design isn't available. Instead
`main` runs `validate_lines` once the symbol table is complete and before
any bytes are emitted, collecting every error up front and returning a real
nonzero exit code (`fn main() -> i32:` + `return 1`, confirmed available
and exit-code-carrying via `tests/frontend_enums_pattern_matching.rs`'s own
`fn main() -> i32: ... return N` pattern) if any were found. The deep
`fatal()` helper inside code generation itself only prints — a defense-in-
depth fallback for a code path `validate_lines` didn't anticipate, not the
primary error-reporting mechanism; see its own doc comment.

### Deliberate deviations from the Python assembler

Documented in full in `assembler.star`'s own header comment; summarized
here:

- No `MACRO`/`INCLUDE`/`IF`-`IFDEF`-`IFNDEF`-`ELSE`-`ENDIF` preprocessing --
  none of this project's own checked-in `tests/asm/*.asm` sources (the ones
  the Python assembler actually produced the checked-in `.bin`/`.org` files
  from) use any of these (confirmed by `grep`), so there's nothing in this
  project's real corpus that needs them yet.
- The 12 "dual-purpose" register/instruction mnemonics (`SA`/`SF`/`SV`/
  `SW`/`TT`/`TM`/`TC`/`TS`/`VM`/`VL`/`VX`/`VY`) are accepted here only as
  register operands, not as standalone one-operand instructions the way
  Python's assembler accepts them (e.g. a bare `TT 5` line) -- because
  `cpu.star`'s own `execute` dispatch has no opcode-table entry for any of
  these bytes as standalone opcodes at all (confirmed by grepping every
  register-code match in `cpu.star` -- `get_reg_value`/`set_reg_value`/
  `reg_width` all have arms for these codes, `execute` does not), matching
  this file's own "What's implemented" note that this port reaches these
  registers "via MOV/arithmetic/etc, not just as dedicated opcodes." This is
  an already-documented capability gap in this port's CPU, not something
  newly discovered here; encoding them anyway would silently produce a
  `.bin` this port's own `cpu.star` cannot run.
- `BR`/`BRZ`/`BRNZ` encode an absolute resolved address, exactly like `JMP`
  -- **not** a PC-relative delta, despite the mnemonics' names. This matches
  the Python assembler's *actual* behavior, not its own comment:
  `CodeGenerator._parse_immediate_value`'s "for branch instructions,
  calculate relative offset" branch is genuinely dead code (`val = val - 0
  # Would need location_counter passed in`), confirmed by reading
  `nova_assembler.py` directly -- the Python reference has never actually
  computed a relative offset here. Filed below under "What to carry back to
  the Python emulator" as a naming/behavior mismatch worth flagging
  upstream, alongside the PUSH/POP and BCD findings from earlier rounds.
- `[0xADDR + off]` / `[0xADDR - off]` (direct-indexed addressing) is
  supported here even though the Python assembler cannot produce it at all
  -- confirmed empirically, `[0x2000+4]` raises `"Unknown base register:
  0x2000"` in the live Python assembler, since its own `direct`/`indexed`
  regexes don't compose (the general indexed-operand path falls through and
  tries to look up `"0x2000"` as a register name). `cpu.star`'s
  `decode_operand` and `disasm.star`'s own `format_operand` both handle this
  addressing mode correctly (it's a real CPU capability, not a wrong guess),
  so this is a deliberate superset that can never show up in a byte-for-byte
  comparison against real Python-assembled output (Python can't generate an
  input that would exercise it) -- verified separately, see "Verification"
  below.
- Register/mnemonic matching is case-insensitive here (tokens are
  upper-cased before lookup); the Python assembler is case-sensitive for
  registers specifically, an accident of `OperandClassifier.classify_
  operand` comparing the raw token against an all-uppercase set without
  upper-casing it first. Every real `.asm` source already writes registers
  upper-case, so this is strictly more lenient and never changes output for
  any source Python could already assemble.
- A genuine Python-side gap found and worked around, not carried into this
  port: `nova_assembler.py`'s `DataGenerator._parse_numeric_value` (backing
  `DB`'s non-string arguments) never checks `OperandClassifier`'s own
  char-literal pattern, so `DB 'A'` fails in the live Python assembler with
  `"Unknown value: 'A'"` even though the identical `'A'` token works fine as
  an ordinary instruction operand (`MOV R0, 'A'`) in the same file. This
  port's `assembler.star` has no such gap (`DB` and instruction operands
  share the same `resolve_imm`/`classify_operand` logic), but
  `tests/asm/assembler_directives_test.asm` deliberately avoids the
  char-literal-in-`DB` form specifically so its own output stays fully
  byte-for-byte comparable against a live Python assembler run -- see that
  file's own header comment.

### Verification

Every one of this project's pre-existing checked-in `tests/asm/*.asm`
sources (`bcd_width_test`, `bcda_carry_order_test`, `bcds_borrow_order_
test`, `layers_test`, `mov_write_width_test`, `push_pop_width_test`,
`sprites_test`, `uart_integration_test`, `write_width_test` -- nine files,
originally assembled by the Python reference) reassembled through
`assembler.star` byte-for-byte identical, both `.bin` and `.org`, against a
*fresh* live run of `nova_assembler.py` (not just the possibly-stale
checked-in files) -- none of these needed a single byte adjusted.

Two new files added this round specifically to exercise what those nine
never touch:

- `tests/asm/assembler_directives_test.asm` -- every directive (`EQU`/`DB`/
  `DW`/`DEFSTR`/`DS`), char literals in instruction operands, a negative
  decimal immediate, a string literal containing a comma (the string-aware
  comma splitter), and label references in every direction (forward,
  backward via a genuine loop, and a data-section reference back up into
  the code section). Byte-for-byte identical to a fresh Python assembler
  run (`.bin` and `.org` both). Also run to completion on both CPUs: the
  live Python reference over MCP (`cpu_run`/`get_cpu_state`) and this
  port's own `cpu.star` (via `tests/run_bin.exe`) -- registers matched each
  other and the file's own documented expected values exactly on both
  (`R0`-`R5`, `cycles_run=17`, final `pc=0x0030` on both CPUs), and the
  assembled `.bin` also loads and runs without crashing under `nova16.exe`
  itself (the SDL GUI build).
- `tests/asm/assembler_direct_indexed_test.asm` -- `[0xADDR + off]` /
  `[0xADDR - off]`, the one addressing mode the Python assembler can't
  produce (see "Deliberate deviations" above), so there's no Python output
  to diff against. Verified three other ways instead: (1) `disasm.star`
  round-trips the assembled `.bin` back to text matching the source exactly
  (`MOV [0x3000+4], 0xAB` / `MOV [0x3010-12], 0xCD`, both landing on the
  same address `0x3004` from opposite signs); (2) run on the live Python
  reference CPU over MCP, confirming `R0=0xAB`, `R1=0xCD`, and
  `mem[0x3004]=0xCD` (the second write correctly overwriting the first at
  the same resolved address); (3) run on this port's own `cpu.star` via
  `tests/run_bin.exe`, matching the Python reference's registers, memory,
  and even cycle count (5) and final `pc` (`0x0017`) exactly, and loading
  cleanly under `nova16.exe`.

Notably, this is the first tooling round for this project that found **zero**
new Star compiler bugs -- both `star check` and `star build` succeeded on
`assembler.star` on the first real attempt, with only ordinary logic bugs
(one: `check_directive_arg`'s validation missing the char-literal case,
caught immediately by the directives test failing to assemble, one-line
fix) along the way.

## Debugger

`debugger.star` (new, todo.md P2 #3): a headless CLI REPL, matching a piece
of the upstream Python toolchain's own tooling (`nova_debugger.py`) that
`readme.md`'s "Versioning" section names as part of "tooling to match
Python reference" for the language-wide `0.1.0` gate. Command set is a
close, deliberate port of `nova_debugger.py::NovaDebugger::handle_command`:
`step`/`s` (single or `s N`), `run`/`continue`/`cont`, `regs`/`r`, `mem
<addr>`, `stack`, `disasm`/`d [addr] [n]`, `break`/`b <addr>`,
`breakpoints`/`bp`, `clear`/`c <addr>`, `load <file>`, `help`/`h`/`?`,
`quit`/`q`/`exit`. A `.sym` sidecar next to a loaded `.bin` (produced by
`assembler.star`, see "Assembler" above) is read automatically to label
addresses by symbol name in disassembly/breakpoint output, matching
`nova_debugger.py::load_symbol_table`'s identical behavior. Not ported:
the Python CLI's `--steps N` startup flag (the REPL's own `step N` command
already covers it interactively).

Deliberately duplicates a handful of small helpers from `disasm.star`
(the full opcode/operand-formatting tables) and `assembler.star`
(`is_ws_byte`/`ltrim`/`split_first_token`) rather than importing either
file directly: both are themselves standalone build targets with their own
`fn main()`, and this compiler's codegen lowers every top-level `fn main()`
to the single real `@main` LLVM symbol regardless of which source file
declares it (`is_main` in `src/codegen/stmt.rs` checks only the function's
own name) -- importing either file into `debugger.star` would collide two
`@main` definitions in one linked program. `disasm.star`'s own header
comment already established the same "keep this tool's own link/dependency
footprint independent" precedent for a smaller case; this is the same call
for a bigger table, for a genuine structural reason (the double-`main`
hazard) rather than just footprint hygiene.

One deliberate, documented improvement over the Python reference:
`nova_debugger.py::run_until_breakpoint` checks its own just-hit breakpoint
*before* stepping on every call to `run`/`continue`, so resuming from a
breakpoint re-hits the same address immediately without executing anything,
unless the user manually steps off it first. This port's `run`/`continue`
steps at least once before the first breakpoint check (matching what a
real debugger's "continue" does) -- see "What to carry back to the Python
emulator" below, where this is filed as an upstream issue.

Verified against `tests/asm/write_width_test.bin`: `disasm`/`step`/`regs`/
`stack`/`mem`/`break`/`breakpoints`/`run`/`clear` all exercised via a
scripted stdin session, symbol labeling confirmed (`0x0000: (START) ...`),
memory-dump output matching the test's own documented expected values
(`mem[0x3000]=0xD7`, `mem[0x3001]=0xCD`) exactly, and a `break 0x30` +
`run` landing precisely on the expected instruction with `R0=0x0C`, cross-
checked against a fresh `debugger_init`/`cpu_step(10)`/`get_cpu_state`
sequence against the live Python reference over MCP (identical `pc=0x0030`,
`R0=0x0C` after 10 steps). That same cross-check is what surfaced the
SP/FP reset bug described above (Python's fresh CPU has `sp=0xFFFF`; this
port's did not, until fixed) -- the debugger's very first real use already
paid for itself the same way the disassembler/assembler's own first real
uses each found genuine bugs in earlier rounds.

Build (needs SDL2 linked even though this tool never opens a window --
`cpu.star` transitively pulls in `sound.star`'s audio builtins for
`SPLAY`/`SSTOP`/`STRIG`, the same reason `tests/run_bin.star`/
`uart_bridge.star` both need it too):
```
star build projects/nova/debugger.star -L sdl/lib/x64 -l SDL2 -o projects/nova/debugger.exe
```

## GUI+controls parity

`main.star` (extended, todo.md P2 #3): a toolbar (Start/Pause, Stop, Reset,
Step) and a status bar (PC, run state, hotkey legend), matching the
concrete, useful-without-a-file-dialog slice of `nova_gui.py::main`'s own
toolbar -- the other named-tooling gap in `readme.md`'s versioning gate,
alongside the debugger above. F5/F6/F7/F8 hotkeys match `nova_gui.py`'s own
Start/Pause/Stop/Reset/Step bindings exactly (its F9=Load has no equivalent
here). Both the toolbar buttons and the hotkeys are edge-triggered (a
"just pressed this frame" transition, tracked the same way the existing
A-Z keyboard debounce already was in this file) so holding a key or mouse
button down doesn't toggle Start/Pause or re-fire Reset every frame at
60fps.

**Deliberately not ported, at the time this section was written**:
`nova_gui.py`'s own "Load" and "UART" toolbar buttons, each backed by a
`tkinter` file-open dialog / configuration dialog. There was no file-dialog
or Tk-dialog builtin anywhere in this language's surface (confirmed by
inspecting `src/codegen/` -- `sdl.rs` covers window/input, `font.rs` covers
text, neither exposed a native "open file" picker), and building a whole
file browser from `draw_rect`/`draw_text`/mouse polling primitives to back
one Reset button was out of scope for that pass. Loading stayed
command-line-argument-only; UART configuration stayed `uart_bridge.star`'s
own separate headless tool. **This has since changed for `Load`** -- see
"Load button and `open_file_dialog`" below, added specifically because a
real, user-visible `Load` button (not just command-line loading) was
requested. UART configuration is still the one piece left un-ported;
`uart_bridge.star` remains its own separate tool.

**Reset's own behavior is a deliberate adaptation, not a straight port**:
`nova_gui.py::CPUController.reset()` clears CPU/memory/graphics state and
stops, requiring the user to click "Load" again afterward to get a running
program back. At the time this paragraph was written, this port had no
"Load" button to click afterward, so `Reset` immediately reloaded whichever
program the process originally started with (the CLI-provided `.bin`, or a
built-in demo program) and resumed running -- otherwise `Reset` would have
been a dead end. Both halves of that reasoning are now out of date -- see
"Load button and `open_file_dialog`" below: there's a real `Load` button
now, the built-in demo has been removed entirely (a no-argument launch now
waits idle for `Load` instead), and `Reset` reloads whichever binary is
*currently* active (the original CLI argument, or the most recent `Load`),
falling back to the same idle wait if nothing has ever been loaded. See
`Cpu::reinit`/`Cpu::load_program_or_wait` in `main.star`.

**A real build-time finding along the way**: an early draft implemented
`Reset` by calling a `build_cpu`-style function (constructing and
returning a fresh, ~megabyte `Cpu` by value) a second and third time -- once
for the F7 hotkey, once for the toolbar button, in addition to the one call
already needed at startup. That build took several minutes and multiple
gigabytes of `clang` memory just to reach the link step. Three call sites
to a function returning an aggregate this large, all within one function
(`main`'s own per-frame loop), is a meaningfully different shape from the
single call site every other build target in this project uses (`new_cpu`
in `debugger.star`/`tests/run_bin.star`/`uart_bridge.star`, all called
exactly once), and empirically triggers something close to the `clang`
optimizer pathology NOTES.md's "Seven Star compiler bugs found and fixed"
#1 ("Large fixed-array/struct construction crashed or hung clang")
describes for a different (also since-fixed) shape. Not chased down to a
minimal repro or a compiler-level fix this round -- a working, and arguably
more correct, per-project alternative existed: `Cpu::reinit` resets every
field via ordinary loop-driven writes into the *existing* `Cpu` (matching
`nova_gui.py::CPUController.reset()`'s own "mutate in place" shape more
closely than "construct a new object" would have anyway), which builds and
links in the same normal time as everything else in this project. Worth a
real compiler-level investigation if this shape (a large-aggregate-
returning function called repeatedly from one function) ever recurs
elsewhere.

Verified interactively: built `nova16.exe`, launched it, and drove the
toolbar with real synthesized mouse input (`SetCursorPos` + `mouse_event`,
indistinguishable from a hardware click) while screenshotting the live
window. Confirmed, in order: clicking Start/Pause toggles the button label
(START/green <-> PAUSE/yellow) and the status bar's run-state text
(RUNNING/STOPPED); clicking Step twice while stopped advances `PC` by
exactly two instructions (`0x0010` -> `0x0018`, matching the built-in
demo's own 8-byte `MOV VX, R0` / `ADD` instruction pair at those addresses
exactly); clicking Reset reloads the demo and resumes running. Direct
`SendMessage`-posted window messages (bypassing real input entirely) did
*not* register with SDL's own mouse-state tracking, which is why the
verification above uses genuine synthesized hardware input instead -- worth
knowing if a future session tries to script-test this again. The F5-F8
hotkeys share the exact same edge-triggered state-toggling code the
verified mouse clicks already exercise (`running`/`single_step` locals),
so they're verified by the same logic rather than repeated separately;
synthetic `keybd_event` key presses sent from an external, non-foreground
script process were inconclusive in this environment (Windows' foreground-
lock restrictions can silently drop a background process's simulated
keystrokes), which is an environment limitation of this verification
attempt, not evidence of a bug in the hotkey code itself.

## Load button and `open_file_dialog`

The "GUI+controls parity" section above recorded a deliberate scope cut:
no `Load` button, because there was no file-dialog builtin anywhere in the
language. That's no longer true. `open_file_dialog(filter_pattern: str) ->
str` is a new compiler builtin (`src/codegen/dialog.rs`) wrapping Windows'
`GetOpenFileNameA` (`comdlg32.dll`) -- a native "Open File" common dialog,
added specifically because a real, user-visible `Load` button (as opposed
to command-line-argument-only loading) was requested directly, not
something this project's own backlog had queued up.

**Why `GetOpenFileNameA` and not the modern `IFileOpenDialog`**: the
Vista-era replacement is a COM interface (`CoCreateInstance` against a
vtable, manual `AddRef`/`Release`), machinery this codegen has never
needed before. `GetOpenFileNameA` is one flat C ABI call taking a single
struct pointer -- the same "hand-emit a call to an existing C API" shape
`net.rs`'s `connect`/`system_font.rs`'s `CreateFontA` already use, no COM
plumbing to add.

**The struct**: this codegen has no external-struct-type declarations --
every field of `OPENFILENAMEA` (152 bytes on x64) is written by hand via
`getelementptr`/`bitcast`/`store` at its known byte offset into a flat
`alloca`, the same technique `net.rs::emit_tcp_connect` already established
for `sockaddr_in`. See `dialog.rs`'s own module doc comment for the full
offset table (verified against `commdlg.h`'s real field order and x64's
natural alignment) and for how the `"Files (PATTERN)\0PATTERN\0\0"` filter
buffer is built by hand into a zeroed scratch buffer, letting the
separator/terminating NULs fall out for free instead of needing explicit
writes.

**Signature choice**: `open_file_dialog` takes one `filter_pattern` `str`
(e.g. `"*.bin"`; `""` means "all files") rather than a caller-supplied
double-NUL-packed Windows filter string directly -- an ordinary Star `str`
is implicitly NUL-terminated at its first `\0` (this codegen's C-string
representation), so it can't carry a packed multi-entry filter as a single
argument anyway. Returns the chosen path as a fresh, owned `str`, or `""`
if the user canceled -- the same "empty string means nothing here"
convention `file_read`/`read_line`/`tcp_recv` already use, rather than a
new `Option`-shaped sentinel this language doesn't have. No owner window is
passed (`hwndOwner = null`): `GetOpenFileNameA` blocks the calling thread
either way, which is exactly the "pause here and wait for a binary"
behavior the `Load` button wants; a real parent window would need
`SDL_GetWindowWMInfo` wired up as its own new builtin just to resolve one
`HWND`, out of scope for this floor. Needs `-l comdlg32` linked explicitly,
same pattern as `net.rs`'s `-l ws2_32`/`system_font.rs`'s `-l gdi32`.

**Testing**: unlike `window_create`/`clear_screen`/etc (runtime-tested
under `SDL_VIDEODRIVER=dummy`), there's no headless mode for a real Win32
common dialog -- calling it for real shows a genuine modal window and
blocks until a human dismisses it. `tests/frontend_open_file_dialog.rs`
covers type-checking (arity/argument type/return type) and a real
clang-compile-and-*link* against `-lcomdlg32` (catching any malformed
`bitcast`/`getelementptr` in the generated IR) without ever actually
invoking `GetOpenFileNameA`. That gap was covered manually instead, once,
outside the automated suite (see below).

**`main.star` changes**: `demo_program()` -- the old hand-encoded
diagonal-gradient fill loaded whenever no CLI argument was given -- is
gone entirely, along with `load_program_or_demo` (now
`load_program_or_wait`, with no demo-fallback branch). A no-argument
launch needs no special "idle" state to construct for this: `new_cpu`/
`Cpu::reinit` already leave `self.mem` entirely zeroed, and opcode `0x00`
is `HLT` (`cpu.star::execute`), so a never-loaded (or freshly `Reset`)
`Cpu` just halts on its very first `step()`, at `PC=0`, against a blank
screen, for free -- exactly the "wait for a binary" behavior wanted, with
no new state machine. A `LOAD` toolbar button (teal, rightmost, after
`STEP`) and an F9 hotkey (matching `nova_gui.py`'s own F9=Load exactly now)
both run the same sequence: `open_file_dialog("*.bin")`, and if non-empty,
`c.reinit()` + `load_program_or_wait(picked, true)` + resume running. A
canceled dialog (`""`) leaves everything untouched. `bin_path`/`use_file`
became `mut` so `Load` can update them and `Reset` (F7/toolbar) picks up
whichever binary is now current.

**Verified interactively, for real, end to end** (not just "should work
from the codegen"): built `nova16.exe`, launched it with no argument, and
confirmed via screenshot a blank black screen with the toolbar/status bar
reading `PC:0X0001 HALTED` -- no demo gradient, exactly the intended idle
wait. F9 was tried first and, consistent with this file's own prior
finding just above (`keybd_event` from a background/non-foreground script
being unreliable against this SDL window), didn't register. Switched to
the same genuinely-synthesized hardware mouse click (`SetCursorPos` +
`mouse_event`) this project's mouse-toolbar verification already trusts,
clicking the `LOAD` button's real screen coordinates: the native "Open"
dialog appeared for real, its filter dropdown correctly reading
`Files (*.bin)` (confirming the hand-built filter buffer), defaulting into
the last-used directory. Double-clicking `gfxtest.bin` in that dialog
closed it and the emulator immediately began running the loaded program --
status bar flipped to `PC:0X106F RUNNING`, and the screen filled with the
program's own diagonal rainbow-stripe pattern and rendered text ("De Nova
Stella"), matching what that specific test program is known to draw. This
is real proof the whole path works: dialog construction, filter-string
correctness, file selection, `Cpu::reinit`, `load_program`'s `.org`-sidecar
segment loading, and resumed execution, all in one live run.

## Layer compositing and sprites

Added in this round: the remaining 8 compositing layers (backgrounds 1-4,
sprites 5-8 — layer 0 already existed), `LSWAP`/`LMOVE`/`LCOPY`, and
memory-mapped sprites (`SPBLIT`/`SPBLITALL`). Implementation lives in
`screen.star` (layer storage/compositing/transforms) and `cpu.star` (opcode
dispatch, and the sprite-blit methods specifically, which need `self.mem`
too). Ported from `nova/graphics/{compositor,blitter,sprites}.py` — read
directly, since `docs/SPRITE_SYSTEM.md`'s own "Instructions" section turned
out to be stale (its `STOR`/`LOAD` example opcodes don't exist anywhere in
the actual ISA or assembler; the real setup uses `MOV [addr], reg`) and its
sprite-layer-assignment description (sprites use layer 5 *or* 6, selected by
one flag bit) doesn't match its own dirty-tracking code's 4-sprite-layer
grouping — the actual `blit_sprite`/`blit_all_sprites` behavior (which only
ever writes layer 5 or 6) is what this port follows.

Design decisions, each also explained at its point of use in `screen.star`:

- **9 separate `[u8; 65536]` fields, not a `[[u8; 65536]; 9]` nested
  array.** This project's own "Four Star compiler bugs found and fixed"
  history is a long list of exactly this shape (a large fixed aggregate
  built/returned/passed as one value) hitting genuine, previously-unknown
  `clang` crashes/hangs; a *nested* array repeat/struct-literal-field-of-
  arrays specifically was never exercised against the existing fixes.
  Explicit named fields (`bg1`-`bg4`, `sp1`-`sp4`) plus a `vl`-to-field
  `match`-style dispatch (`layer_get_idx`/`layer_set_idx`) gets the same
  behavior without depending on an untested codegen path — a deliberately
  conservative choice given this project's specific history with this
  compiler.
- **Compositing is always recomputed on demand, never cached.** The
  reference's own dirty-flag/pixel-count-tracking `Compositor` cache is a
  pure performance optimization confirmed (by reading `composite()`/
  `mark_dirty`/`_pixel_counts` directly) to have zero effect on any
  opcode's observable result — every mutating path already marks its layer
  dirty, and the cache is always rebuilt in full before being read. Skipped
  entirely, same "don't chase the reference's own performance hacks, only
  its observable behavior" precedent as the pre-existing timer/opcode-
  fetch-cache simplifications. One concrete, easy-to-miss consequence: the
  reference's `VBLIT` (`Blitter.blit_vram`) copies the composite into VRAM
  and then `_screen.fill(0)`s the *cache*, but immediately follows that
  with `mark_all_dirty()` — so the very next composite-read rebuilds it
  from the (untouched) individual layers, making the `fill(0)` completely
  unobservable. This port's `vblit` therefore clears nothing at all.
- **`SREAD` reads the *composited* screen; every other graphics opcode is
  `VL`-aware and touches only its own layer.** Easy to get backwards from
  the opcode names alone — confirmed from `GFX.get_screen_val`, which
  reads `self.screen` (the compositor's own composited property), while
  `GFX.set_screen_val`/`_set_pixel_fast` and every drawing primitive
  (`draw_line`/`draw_rectangle`/`draw_circle`/`draw_char`/fill/invert) all
  route through `get_layer_buffer_by_num(self.VL)`.
- **`SBLEND`/blend modes are still a stub, and this round specifically
  confirmed that's correct, not a gap** — see "Known simplifications"
  above and `screen.star`'s header comment: `blend_pixel` is genuinely dead
  code in the reference itself.
- **An out-of-range `LSWAP`/`LMOVE`/`LCOPY` target layer is a silent
  no-op** rather than the reference's `raise ValueError` — matching this
  project's established "memory/graphics ops always bounds-check, never
  trap" convention (there's no exception mechanism to reproduce the
  reference's behavior with anyway).
- **Sprite control blocks are read straight out of `Cpu.mem`** at
  `0xF000 + sprite_id * 16` (16 bytes: big-endian `data_addr`, `x`, `y`,
  `width`, `height`, `flags`, `transparency_color`, 8 reserved bytes) —
  no separate sprite-specific memory model, matching the reference's own
  "hybrid memory-based" design. `SPBLITALL` clears sprite layers 5-8 (all
  four, matching `blit_all_sprites`'s own behavior, even though a single
  sprite can only ever target layer 5 or 6) before re-blitting sprites
  0-15 in order.

### Verification

Two independently-verified `.asm` test programs (`tests/asm/
layers_test.asm`, `tests/asm/sprites_test.asm`), each assembled with the
upstream `nova_assembler.py`, run through this port via `tests/run_bin.
star`, and cross-checked against the actual **running** Python reference
(a short script importing `nova_memory`/`nova_gfx`/`nova_cpu` directly,
loading the same `.bin` via `Memory.load`, stepping to completion, and
diffing every `R` register) — not just hand-derived expected values.

- `layers_test.asm`: writes distinct pixel values on layers 0/1 at
  overlapping and non-overlapping coordinates (proving composite-overwrite-
  where-nonzero ordering), then `LCOPY`s a pixel to a third layer and wipes
  the source (proving copy-without-clearing-source), `LMOVE`s a pixel to a
  fourth layer and wipes the *destination* afterward (proving move
  *does* clear its source — the only way to observationally tell "moved"
  apart from "copied", since composite alone can't distinguish which layer
  a value lives on once only one is nonzero), and `LSWAP`s two nonzero
  pixels between two layers, again wiping one side afterward to prove the
  swap actually exchanged values rather than no-op'ing. All 6 checkpoints
  (`R0`-`R5`) matched the live reference exactly (`cycles_run=45`,
  `pc=158` on both sides).
- `sprites_test.asm`: a 4x4 sprite with one transparent pixel blitted via
  `SPBLIT` (checking top-left, the transparent pixel showing background
  through, and bottom-right), a second sprite targeting layer 6 (flag bit
  7) blitted via `SPBLITALL` alongside an *inactive* third sprite (flag
  bit 0 clear) that must never appear anywhere. All 5 checkpoints (`R1`-
  `R5`) matched exactly (`cycles_run=100`, `pc=439`) — but only *after*
  fixing a real bug this test surfaced; see the next section.

## A genuine port bug: MOV [mem], narrow-source write-width

**Not a Star compiler bug** — a pre-existing logic bug in this port's own
Nova-16 CPU model, found while writing `sprites_test.asm` above (which
needed to poke 16 individual sprite-control-block bytes via `MOV [addr],
R0`, the first real exercise this project gave a memory-destination `MOV`
with a narrower source — every earlier round's test/demo programs only
ever wrote memory via `SWRITE`/`MEMSET`/etc., never plain `MOV`). The
symptom: every single byte written this way came back as `0`, as if
nothing had ever been written at all.

Root cause: `Cpu::operand_width(op)` (this port's "operand width is
inferred from the destination's kind" rule, see the "Operand width..."
section above) returns 16 for *any* non-register destination, including
memory — and `op_mov` used that same `width` for both the read *and* the
write. But `core/exec_handlers.py::_write_result`'s own docstring says the
opposite for a memory destination specifically: *"For memory destinations,
the write size is determined by the source operand when available (legacy
behavior: MOV [mem], imm8 writes a byte, MOV [mem], imm16 writes a
word)"* — an 8-bit register source also forces a 1-byte write, by the same
logic. So `MOV [addr], R0` (an 8-bit `R` register source) should write
exactly 1 byte, but this port's `width=16` made it write 2 bytes (a 0x00
high byte plus the low byte) at every address — each subsequent sequential
byte-write then clobbered the *previous* write's low byte with its own
0x00 high byte, leaving every byte 0 except the very last one written.
Confirmed against the live Python reference first (which produced the
correct non-zero values for the identical assembled `.bin`), proving the
test program itself was right and this port's execution was wrong.

Fix (originally scoped narrow, now generalized — see "Generalizing the
write-width fix" below): a new `Cpu::write_width_for(dest, src) -> i32`
implementing `_write_result`'s exact rule (immediate source uses its own
encoded width — `Operand` gained an `imm_width: u8` field to remember
whether an immediate was decoded via the 8-bit or 16-bit addressing mode,
previously discarded; an 8-bit register source forces 8; anything else
forces 16), wired into `MOV`/`MOVZ`/`MOVNZ`'s write (not their read, which
still correctly uses the existing destination-based `operand_width`).

### Verification

A dedicated regression test, `tests/asm/mov_write_width_test.asm`, covering
all four `_write_result` cases (imm8, an 8-bit `R` register, a 16-bit `P`
register, imm16) with an untouched sentinel byte immediately after each
narrow write (proving the write really was narrower, not just "happened to
end in the right value") — 8 checkpoints, all matching the live Python
reference exactly (`R2`=0xAB, `R3`=0xCD sentinel intact, `R4`=0x11, `R5`=
0x22 sentinel intact, `R6:R7`=0x12:0x34 big-endian, `R8:R9`=0xBE:0xEF).

## Generalizing the write-width fix (todo.md P0 #1)

The `MOV`/`MOVZ`/`MOVNZ`-only fix above was originally left deliberately
scoped narrow, with the rest of the ~90 handlers that share the same
`_write_result` codepath in the reference flagged as a known, accepted gap
in `todo.md`. Revisited directly per that todo item: `write_width_for` was
already fully generic (takes an arbitrary `dest`/`src` operand pair, no
`MOV`-specific assumption anywhere in it), so generalizing it was
mechanical — every handler in `cpu.star` that calls `self.operand_write`
to write a computed result back to its first decoded operand (`op1`) now
routes the *write* (not the read, which stays on the existing
destination-based `operand_width`) through `write_width_for(op1, op2)`
instead of the plain destination-only `width`. This matches
`core/exec_handlers.py::_write_result`'s own behavior exactly: every one of
its ~50 call sites (`grep`-confirmed) passes no explicit `source_size`
override, so the same generic source-operand inference this port already
proved correct for `MOV` applies identically everywhere else in the
reference too — there was no per-opcode special case to rediscover.

Sites updated (all two-or-more-operand handlers that write back to `op1`):
`LEA`, `XCHNG` (both directions, see below), `ADD`, `ADC`, `SUB`, `SBC`,
`MUL`, `MULH`, `DIV`, `DIVH`, `MOD`, `MIN`, `MAX`, `BCDA`, `BCDS`, `BCDADD`,
`BCDSUB` (see "BCD operations" below for a second, distinct bug this same
pass found in these four), `POWR`, `FMUL`, `FDIV`, `AND`, `OR`, `XOR`,
`SHL`, `SHR`, `SAR`, `ROL`, `ROR`, `RCL`, `RCR`, `BSET`, `BCLR`, `BFLIP`,
`LOOP`, `LOOPZ`, `RNDR`, `BTOI`, `ITOS`, `STOI`. Left alone, correctly: every
*single*-operand handler (`INC`/`NEG`/`NOT`/`CLZ`/the whole math library/
etc.) — `_write_result`'s own inference falls back to `cpu.operands[0]`
(the destination itself) when there's no second operand, and a memory
operand is never `is_register`/`is_immediate` with respect to itself, so
the reference's own single-operand write width is unconditionally 16,
identical to what `operand_width` already produced here; verified this by
reading `_write_result`'s inference logic directly rather than assuming,
since it would have been easy to over-apply the fix everywhere. `STRFIND`/
`STRFINDI`/`STRCMP`/`STRLEN`/etc. write straight to `R0` bypassing the
destination-operand mechanism entirely (see "String library..." below) and
`MEMCPY`/`MEMSET`/etc. write raw byte ranges directly, neither going
through `_write_result` at all — also correctly untouched.

`XCHNG` gets one write per operand (`_write_result(cpu, 0, values[1])` then
`_write_result(cpu, 1, values[0])`), and the reference's generic inference
happens to compute the *second* write's size from `cpu.operands[1]`'s own
kind regardless of write direction — worth naming explicitly because it
looks like it should be `write_width_for(op2, op1)`'s mirror-image evil
twin, but tracing through every case (a memory `op2` is never
`is_register`/`is_immediate` with respect to itself, so always resolves to
16 either way; a register `op2`'s write always uses its own natural width
regardless of `source_size` per `_write_result`'s register branch) shows
both formulations produce identical results in every observable case. Used
the semantically-intuitive `write_width_for(op2, op1)` for the second write
rather than the literal (but observably-equivalent) self-referential
version, since it reads correctly and there's no case where the distinction
matters.

One genuinely surprising consequence, confirmed intentional (not a
transcription slip) by checking `_write_result`'s inference logic directly:
**the write width for a handler that writes back to `op1` is always keyed
off `op2`'s own encoding, even when `op2` isn't conceptually a "value
source" at all.** `SHL [addr], 3` narrows its write to 1 byte because `3`
(the shift *amount*, not the value being shifted) happens to be encoded as
an 8-bit immediate — `write_width_for` doesn't know or care that `op2`
means something different for `SHL` than it does for `ADD`. Same story for
`LOOP [addr], target`: the counter at `[addr]` gets a write width derived
from the *jump target* operand, not the counter's own encoding. Ported
bug-for-bug, per this project's existing precedent for `TAN`'s scaling
quirk and the (now-corrected, see below) BCD masking-order finding — this
is exactly the kind of consequence that's easy to "fix" into something more
sensible while porting and therefore easy to silently diverge from the
reference, so it's called out here explicitly rather than smoothed over.

### Verification

`tests/asm/write_width_test.asm` — `ADD`, `AND`, `SHL`, `BSET`, each
targeting a memory destination from a narrow (8-bit register or imm8)
source/amount operand, with a sentinel byte immediately after each memory
destination proving the resulting write only touched 1 byte. Every existing
handler's *read* of a memory destination is still the ordinary 16-bit word
read regardless of source width (that part was never broken — a memory
operand always reads 16-bit unless the overall destination is an `R`
register), so each checkpoint's expected value already reflects that: e.g.
`ADD [0x3000], R0` with `mem[0x3000]=0x05`/`mem[0x3001]=0xCD` reads the
*word* `0x05CD`, adds `R0=0x0A` to get `0x05D7`, and writes back only the
low byte `0xD7` — leaving the sentinel at `mem[0x3001]` untouched. Expected
values were captured from the live Python reference over MCP
(`get_cpu_state` after `cpu_step`) rather than hand-derived, per this
project's standing precedent for exactly this kind of multi-step
memory-arithmetic case (see "BCD operations" below for where hand-deriving
instead of replaying the reference previously produced a wrong test). All 8
checkpoints (`R1`=0xD7, `R2`=0xCD, `R3`=0x0C, `R4`=0xCD, `R5`=0x34, `R6`=
0xCD, `R7`=0xCD, `R8`=0xCD) match the live reference exactly, and this
port's own `Cpu::step()` (via `tests/run_bin.star`) reproduces every one of
them byte-for-byte.

## PUSH/POP always used a fixed 16-bit stack slot

**Not a Star compiler bug** — a second genuine port bug, found while
auditing every other memory-write path in this file for the same
"narrower-than-16-bit write" shape the `MOV` bug above turned up. `op_push`/
`op_pop` always called `push16`/`pop16` regardless of the pushed/popped
operand's own kind, so `PUSH R0` (an 8-bit register) advanced `SP` by 2 and
wrote a 2-byte word, when the reference actually pushes only 1 byte (`SP`
by 1) for an `R` register or `imm8` operand.

This is a case where the doc and the actually-running reference disagree,
and this port had matched the (wrong) doc:
`docs/nova16_instruction_reference.md`'s own `PUSH`/`POP` entries both say
a fixed `SP -= 2`/`SP += 2`, with no operand-kind caveat. But
`core/exec_handlers.py::_push_pop_width` (the function `_push`/`_pop`
actually call) is explicit that an `R` register or `imm8` operand is
1-byte, and everything else (a `P` register, `imm16`, or memory) is 2-byte
— confirmed against the **running** reference over MCP, not just read from
source, precisely because this contradicts the doc and a source-only read
could plausibly have been a doc-vs-stale-code mismatch in the *other*
direction: `PUSH R0` from `SP=0x9000` left the reference's `SP` at
`0x8FFF` (a 1-byte push), while `PUSH P0` from the same starting `SP` left
it at `0x8FFE` (a 2-byte push) — unambiguous. Same "the live reference is
the ground truth, not the doc" precedent `SPRITE_SYSTEM.md`'s own stale
opcode section already established (see "Layer compositing and sprites"
below) — this is just the first time it was the *base* instruction
reference doc rather than a subsystem doc that turned out stale.

Fix: new `Cpu::push_pop_width(op) -> i32` (mirrors `_push_pop_width`
exactly — register operand uses its own natural width, immediate uses its
encoded `imm_width`, memory defaults to 16) plus new `Cpu::push8`/`pop8`
methods (1-byte-`SP`-delta siblings of the existing `push16`/`pop16`).
`op_push`/`op_pop` now branch on `push_pop_width(op1)` to pick the 8- or
16-bit stack primitive. Every other stack-touching opcode in this file
(`PUSHF`/`POPF`/`PUSHA`/`POPA`/`ENTER`/`LEAVE`/`CALL`/`RET`/`INT`/`IRET`)
is always word-based in the reference too (confirmed by reading
`_pushf`/`_popf`/`_pusha`/`_popa`/`_enter`/`_leave` directly — none of them
call `_push_pop_width`), so none of those needed any change.

### Verification

`tests/asm/push_pop_width_test.asm` — `PUSH R0`/`PUSH P0`/`PUSH [mem]` from
a known `SP`, and `POP R0`/`POP P0` into a known stack layout, checking the
resulting `SP` delta and popped value for each. All 7 checkpoints match the
live Python reference exactly (`PUSH R0`: `SP` 0x9000→0x8FFF; `PUSH P0`:
0x9000→0x8FFE; `PUSH [mem]`: 0x9000→0x8FFE, confirming the memory-operand
default; `POP R0`: `SP` 0x8FFF→0x9000, value 0xAB; `POP P0`: `SP`
0x8FFD→0x8FFF, value 0x1234).

## UART (0xA2-0xA5)

Added in this round: `SERIN SEROUT SERSTAT SERCTRL`, ported from
`nova_uart.py::NovaUART`'s raw-mode data path. Lives in its own file,
`uart.star` (a `Uart` struct + methods, composed into `Cpu` the same way
`Keyboard`/`Flags` already are), plumbed into `Cpu::check_interrupts` at
vector 1 (Serial), between Timer (0, highest) and Keyboard (2) per
`docs/CPU Specification.md`'s own priority table.

Originally deliberately not ported (this section used to end here): the
host bridge (`LocalTerminalBridge`/`TCPSocketBridge`/`TCPServerBridge`) and
framed-mode parsing, on the reasoning that there was no opcode that let a
Nova-16 program push a byte into its own RX FIFO, so without a host bridge
feeding it, `SERIN` always ended up reading back `data_register`, i.e.
whatever `SEROUT` last wrote. **The host bridge itself is now implemented**
(todo.md P0 #1): `host_push_rx` (this file) writes a real host byte into
`data_register`/`rx_available`/`pending_interrupt` directly, and
`projects/nova/uart_bridge.star` is a headless stdin/stdout driver that
calls it, blocking on `read_line()` between bursts of CPU execution the
same way a real interactive terminal blocks for the next line of input.
TCP transport and framed-mode parsing are still out of scope — see
`uart_bridge.star`'s own header comment for why TCP specifically was
rejected (`net.rs`'s `tcp_recv` has no non-blocking/timeout mode, so it
would freeze the bridge loop waiting on an idle peer) and no opcode drives
framing either way. Same reasoning as `MOUSECTRL`'s register model being
fully in place and testable long before real host mouse events existed
(see "Mouse plumbing" below) applied here too, for exactly as long as it
took to actually build the bridge.

### Verification

`tests/asm/uart_integration_test.asm`/`.bin`/`.org` are copied *verbatim*
from the upstream Python repo (not authored for this port, not
reassembled) — this is deliberately the strongest kind of test available:
an independently-produced program neither side's author wrote to match
the other. Loaded through this port's own binary loader (see "Binary
program loading" above) and run to completion: `P0 == 0xBEEF` (the
program's own PASS marker; `0xDEAD` would mean failure), matching what the
program expects the *real* Python reference to produce, with zero changes
needed on either side. Still passes unchanged after the host-bridge work
above (`op_serout` now also prints the transmitted `'A'` to stdout as a
visible side effect, since TX is real now too).

`host_push_rx`'s own new state transitions (status flags before/after a
host push, the pushed byte round-tripping through `SERIN`'s `read_data`,
the flag clearing again on read) were checked with a throwaway
direct-field-poke headless harness (not checked in, same convention as the
mouse-interrupt harness below) alongside a live `op_splay`/`op_strig`
trigger for the new sound synthesis — see todo.md P0 #1's write-up for the
full list of what that harness covered.

## Mouse plumbing (MOUSECTRL, MX/MY/MB, interrupt vector 3)

Added in this round: `MOUSECTRL` now really gates host mouse input instead
of no-op'ing, `main.star`'s per-frame loop updates `MX`/`MY`/`MB` from the
real host mouse (`mouse_x()`/`mouse_y()`/`mouse_button_down()`, already
existing Star builtins — this needed no new language feature at all), and
a mouse-changed-while-enabled event raises interrupt vector 3, mirroring
`NovaMouse.move_to`/`set_buttons`'s own `if from_host and not self.
enabled: return` guard and `_check_pending_interrupts`'s consume-on-
dispatch (`Cpu::check_interrupts` clears `mouse_pending_irq` the same way
it already does for the UART's `pending_interrupt`).

`MX`/`MY`/`MB` were already ordinary readable/writable registers before
this round (reachable via `MOV` like any other register) — what was
missing was purely the host-input side: nothing fed them from the real
mouse, and `MOUSECTRL`'s enable bit did nothing. Host window coordinates
are halved before being clamped into Nova-16's 256x256 range, since
`main.star`'s window renders at 2x the emulated resolution (`SCREEN_SIZE *
2`); `MB`'s bit 0/1 map to SDL's left/right buttons (`mouse_button_down(1)`/
`(3)`), matching `NovaMouse.LEFT_BUTTON_MASK`/`RIGHT_BUTTON_MASK` (there's
no middle-button mask in the reference either).

### Verification

There's no way to drive a real host mouse event through a `.bin` (same
"no opcode can inject this" situation as UART's RX FIFO), so this is
verified two ways instead:

1. **`tests/mouse_interrupt_test.star`**, a direct-field-poke headless
   harness exercising `Cpu::check_interrupts`'s new mouse branch directly
   (not through `step()`/a hand-encoded handler, since the thing under
   test is purely the dispatch-gating logic): a pending mouse IRQ with
   `mouse_enabled=false` must leave `PC`/the pending flag untouched; the
   same pending IRQ with `mouse_enabled=true` must jump to the IVT vector-3
   handler address and clear the pending flag; and a pending IRQ with the
   CPU's own interrupt-disable flag (`I`) clear must not fire regardless of
   `mouse_enabled`. All 5 checks pass.
2. **Reading `NovaMouse`/`nova_cpu.py`'s dispatch logic directly** (not
   executing it, since there's nothing to execute it *with* on either
   side) to confirm the enable-gate-at-both-set-time-and-dispatch-time
   behavior and the vector-3/priority assignment match.

## Ideas for future work

- ~~Sound synthesis~~ and ~~a UART host bridge~~ — both done, see
  `sound.star`/`uart_bridge.star` and todo.md P0 #1's write-up. Real
  remaining gaps in that area: `SMIX`/`SECHO`/`SREVERB`/`SFILTER` (still
  genuinely unimplemented, matching the reference), UART framed-mode
  parsing, a true per-8-channel voice model instead of the current
  one-loop-channel-plus-one-shot-pool collapse, and a real 1/f pink-noise
  filter instead of the 3-tap white-noise approximation.
- Splitting `cpu.star`'s ~100 opcode-handler methods across files by group
  (arithmetic/bitwise/stack/control-flow/graphics/...) — unblocked now that
  `impl` can cross a module boundary (gotcha #6), not yet done.
- ~~An actual assembler~~ — done, see "Assembler" above (todo.md P1 #2). Its
  `.sym` output is exactly what `debugger.star`'s address-labeling now reads
  (see "Debugger" above), which is what this bullet named as the natural
  next step.
- ~~A disassembler~~ — done, see "Disassembler" below.
- ~~A debugger~~ and ~~GUI+controls parity~~ — both done, see "Debugger" and
  "GUI+controls parity" above (todo.md P2 #3). These were the last two
  named-tooling gaps in `readme.md`'s versioning gate's "tooling to match
  Python reference" condition; every concrete piece that gate names is now
  built (see the file's own framing note at the top). Real remaining gaps,
  by deliberate scope cut rather than oversight: `debugger.star` has no
  source-line breakpoints (only numeric-address ones — nothing in this
  project maps a `.asm` source line back to an address at debug time, only
  symbol *names*, which it does support).
- ~~A file-dialog-backed "Load" button~~ — done, see "Load button and
  `open_file_dialog`" above: a new `open_file_dialog` compiler builtin
  (Windows `GetOpenFileNameA`) backs a real `Load` toolbar button/F9
  hotkey, and the old built-in demo program is gone (a no-argument launch
  now waits idle instead). The one piece still un-ported is a "UART
  config" dialog — `uart_bridge.star` remains its own separate headless
  tool, unchanged.
- ~~The f-string-repeated-call corruption bug~~ — root-caused and fixed at
  the compiler level (see "A related runtime bug, since fixed" right after
  "Seven Star compiler bugs found and fixed" above, and `todo.md` P1 #1).
  `disasm.star` still routes around it via `concat`-only helpers, which is
  no longer required but costs nothing to leave as-is.

## Status: this port now supersedes the Python reference

Every round of this project up to and including this one treated the
Python emulator (`core/exec_handlers.py`/`exec.py`/`regfile.py`/... in the
sibling `Nova` repo, reached over the Nova-16 MCP server) as the ground
truth: this port's job was to match it, byte for byte, checkpoint by
checkpoint, and every genuine mismatch found along the way was assumed to
be a bug in *this* port until proven otherwise by reading or running the
Python side directly.

That relationship flips as of this round. Three of the bugs fixed here
(PUSH/POP's stack-slot width, BCD's read width, and BCD's carry/borrow
masking order) are cases where this port's own prior documentation had
already claimed to have checked against the live reference and gotten it
right — and hadn't, in ways only surfaced by actually re-running fresh
probes against the MCP server rather than trusting the existing write-up.
Combined with the two still-open, upstream-confirmed **Python** bugs this
project has found and deliberately ported bug-for-bug rather than
"fixed away" (`TAN`'s scaling quirk and the general "port bug-for-bug"
precedent both trace back to matching Python behavior that is itself
questionable), the accumulated evidence is that this Star port has now had
more scrutiny applied to more of its opcode surface, more recently, and
with more of that scrutiny backed by checked-in regression tests, than the
Python original has.

Concretely, this means: for any future discrepancy between this port and
the Python reference, **do not assume the Python side is correct by
default**. Re-derive the expected behavior from `docs/`, from first
principles, or from a fresh live-MCP probe designed to distinguish the two
readings — the same standard this round applied to PUSH/POP and BCD — before
changing this port to match Python. This does not retroactively invalidate
the extensive checkpoint-by-checkpoint verification the math library,
string library, and BCD rounds did against the live reference (that
process is sound and remains this project's standard); it means the
Python reference's *output* is no longer to be trusted uncritically just
because it's the older, "real" implementation — it has its own bugs, same
as this port did, and some of them are still sitting in Python unfixed
(see "What to carry back to the Python emulator" below).

## What to carry back to the Python emulator

Everything below is a bug in the **Python** reference (`c:\Code\projects\
Nova` at the time of this round), confirmed by direct MCP interaction with
the running CPU, not merely inferred from this port's own fixes. None of
these have been changed on the Python side as part of this round — this
project's brief is the Star port, and the Python repo is a separate
project — but each is a concrete, reproducible, worth-filing issue for
whoever maintains it next:

1. **`docs/nova16_instruction_reference.md`'s `PUSH`/`POP` entries are
   stale against the actually-running `core/exec_handlers.py`.** The doc
   says a fixed `SP -= 2`/`SP += 2` for both opcodes, with no operand-kind
   caveat; the actual code (`_push_pop_width`, called from `_push`/`_pop`)
   pushes/pops only 1 byte (`SP +-= 1`) for an `R` register or `imm8`
   operand. Either the doc needs an operand-kind caveat added, or (if a
   fixed 2-byte stack slot was the *intended* design and `_push_pop_width`
   is the actual bug) the code needs to change — this round can't tell
   which was intended, only that the two disagree today. Reproduction:
   `PUSH R0` from a known `SP` advances it by 1, not 2 — see
   `tests/asm/push_pop_width_test.asm` (in this Star project) for a
   ready-made repro program, independently confirmed against the live
   reference.
2. **`_bcda`/`_bcds`/`_bcdadd`/`_bcdsub`'s carry/borrow flag is computed
   from the pre-mask `raw` value, one statement before `result &= 0xFF`**
   — worth flagging not because it's wrong (it isn't; this is the correct,
   intended-looking behavior, and this port's own bug was getting this
   backwards) but because the *statement order* that makes it work is
   easy to misread as the opposite at a glance (`carry = result > 0x99`
   reads as if `result` is already the masked byte, when at that point in
   the function it's still the raw, possibly-three-digit sum) — exactly
   the misreading this port's own prior documentation fell into. A comment
   at that call site in `core/exec_handlers.py` noting "must run before
   the mask below, not after" would have prevented this port from getting
   it backwards, and would prevent the same misreading in any future
   change to that function.
3. **No corresponding bug found in the Python side for the write-width
   generalization or the BCD read-width fix** — both of those were bugs
   in this Star port only (an incomplete port of `_write_result`'s already-
   correct, already-general inference rule, and a read-width
   over-generalization from a real but narrower masking rule,
   respectively). Nothing to carry back for either.
4. **`nova_assembler.py::CodeGenerator._parse_immediate_value`'s "for branch
   instructions, calculate relative offset" comment describes code that was
   never finished.** The branch it sits in is `val = val - 0  # Would need
   location_counter passed in` — a literal no-op, confirmed by reading the
   function directly. So `BR`/`BRZ`/`BRNZ` (the three mnemonics whose names
   imply relative/branch semantics, as opposed to `JMP`'s explicitly
   absolute one) have only ever encoded a resolved absolute address in the
   actual, running Python assembler, identical to `JMP`. Found while
   building this port's own `assembler.star` (todo.md P1 #2) and matched
   deliberately rather than "fixed", since byte-for-byte parity with the
   Python assembler's real output is this port's own stated verification
   standard (see "Status: this port now supersedes the Python reference"
   above) — see `assembler.star`'s own header comment, "Deliberate
   deviations from the Python assembler," for where this is recorded on
   this port's side. Worth flagging upstream either way: either finish the
   relative-offset calculation (`location_counter` is already threaded
   through `CodeGenerator.generate_instruction`'s call sites, so the fix is
   probably small), or drop the misleading comment and any implication that
   these three mnemonics currently do anything `JMP` doesn't.
5. **`nova_debugger.py::run_until_breakpoint` re-hits an already-current
   breakpoint instead of stepping past it.** The method checks `if
   self.cpu.pc in self.breakpoints` *before* ever calling `self.cpu.step()`,
   every time it's called -- so calling `run`/`continue` again right after a
   breakpoint hit (the single most common next action in a debugger) prints
   "Breakpoint hit" again immediately, without executing anything, until the
   user manually steps off the address first. Found building this port's
   own `debugger.star` (todo.md P2 #3) and deliberately *not* matched --
   this port's `run`/`continue` steps at least once before its first
   breakpoint check on every call, matching what a real debugger's
   "continue" does, and it's hard to construct a reading of the *intended*
   behavior where re-hitting instantly is preferable. See `debugger.star`'s
   own `run`/`continue` handler for where this is recorded on this port's
   side.

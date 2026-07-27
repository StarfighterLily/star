# Nova-16 in Star — implementation notes

A native reimplementation of the Nova-16 fantasy computer (originally a
Python emulator at a sibling project) written in Star, the language this
repository's compiler implements. Like `projects/snake`, this exists to
exercise the language on something larger and more demanding than a toy —
in this case a CPU emulator: a 64KB unified memory space, a ~190-entry
instruction set, a register-code addressing scheme, a 256x256 indexed
framebuffer, and a keyboard/timer/interrupt model — and to write down
everything that broke, surprised, or shaped a design choice along the way.

This is a **base emulator only**, per the brief: no assembler, no
disassembler, no debugger. Test programs in this directory are hand-encoded
raw opcode bytes (see "Testing" below).

## Contents

- `star.toml` — project manifest.
- `docs/` — reference documentation copied from the upstream Python
  project (CPU spec, instruction reference, VRAM/sprite/sound/keyboard/UART
  specs, font format). `reimplantation_analysis.md`, the various profiler/
  monitor-tool READMEs, and anything assembler/debugger-specific were
  deliberately not copied — they document tooling and Python-side
  refactors, not the machine.
- `bits.star` — shift/rotate/parity/popcount/clz/ctz helpers. Exists solely
  because Star has no bitwise shift operator or function (see below).
- `flags.star` — the 12-bit status register (`StatusFlags` — not `Flags`,
  see "Gotchas") and the arithmetic/logic/rotate flag-setting rules, ported
  from `core/flags.py::set_from_operation` directly (read from source, not
  guessed from the higher-level docs, which don't spell out the CMP-vs-SUB
  carry distinction).
- `palette.star` — the 256-color indexed palette (16 hue ramps x 16
  shades), same float formula per ramp as `nova/graphics/gfx.py`.
- `memory.star` — the 64KB unified address space plus the bank-switched
  0x8000-0xBFFF expansion window.
- `font_data.star` — the 8x8 1bpp font glyph table, mechanically generated
  from the upstream `font.py` (see "No literal array-of-values" below).
- `screen.star` — the 256x256 8bpp screen + VRAM buffers, drawing
  primitives (line/rect/circle/char/text/roll/shift/flip/rotate), and the
  font.
- `keyboard.star` — the 64-slot keyboard FIFO and its status/control
  register model.
- `cpu.star` — the CPU itself: registers, the register-code address space,
  operand decoding, the fetch-decode-execute cycle, every implemented
  instruction, interrupts, and the timer. This is the one large file in the
  project (~1500 lines) — see "impl blocks can't cross files" below for why
  it isn't split further.
- `main.star` — SDL2 window, a small built-in demo program (there's no
  assembler to produce anything else — see "Loading programs" below), the
  main loop, and keyboard-event plumbing.

## Building and running

```
star build projects/nova/main.star -L sdl/lib/x64 -l SDL2 -o projects/nova/nova16.exe
```

`sdl/lib/x64/SDL2.dll` must sit next to the built `.exe` (or be on `PATH`).
The demo draws a diagonal rainbow gradient (color = (x+y) mod 256 through
the palette) using nested loops, register arithmetic, and `SWRITE`, then
jumps back to address 0 and redraws forever. Press Escape or close the
window to quit.

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

## Language gotchas hit along the way

These aren't bugs — they're real constraints of the current Star language/
compiler that shaped how this project is structured. Written down so a
future session doesn't have to rediscover them.

1. **No bitwise operators or shift functions at all.** No `& | ^ ~ << >>`.
   The free-function surface (`bit_get`/`bit_set`/`bit_clear`/`bit_toggle`/
   `bit_and`/`bit_or`/`bit_xor`/`bit_not`) covers single-bit ops and whole-
   register AND/OR/XOR/NOT, but there's no general "shift by N" primitive.
   `bits.star` builds every shift/rotate (SHL/SHR/SAR/SAL/ROL/ROR/RCL/RCR)
   bit-by-bit from `bit_get`/`bit_set` instead of `<<`/`>>`. Multiply/divide
   by a power of two was considered and rejected for the arithmetic-
   right-shift case specifically: dividing a negative value truncates
   toward zero, not toward -infinity, so it doesn't reproduce sign-extending
   shift semantics.

2. **No hex integer literals.** `0x1F`-style literals don't exist in the
   lexer at all — every register code, opcode number, and address constant
   in this project is written in decimal (with a `# 0x..` comment for
   readability where it helps).

3. **`elif` doesn't exist.** Only `if`/`else`, so a multi-way branch is
   either a `match` with comparison-guard arms (`<= 15 ->`, works for
   ranges) or explicit `else:` + nested `if`. `match` with bare integer
   literal arms (`43 -> ...`) works fine and is what `Cpu::execute`'s ~100-
   entry opcode dispatch and the register-code `match` blocks are built
   from — confirmed against the existing `examples/brainfuck.star` before
   relying on it for this project's own dispatch table.

4. **No destructuring `let`.** `let (a, b) = expr` does not parse — every
   tuple-returning call in this project (`decode_operands`, `vxy`,
   `pop_key`, ...) is bound to a temporary and then read back positionally:
   `let ops = self.decode_operands(2)` / `let op1 = ops.0` / `let op2 =
   ops.1`. Cost 93 call sites a mechanical regex fixup after discovering it
   partway through writing `cpu.star` — see the compiler-bug section below
   for the *other*, more subtle tuple-related issue this project also hit.

5. **No array-literal-of-differing-values.** `[a, b, c]` is a `List<T>`
   literal (heap/RC-backed, fine to return by value); the *only* fixed-size
   `[T; N]` array literal form is the `[value; N]` repeat. This mattered
   for the font glyph table (256 glyphs x 8 bytes, virtually all distinct
   values): there is no way to spell that as an array literal at all.
   `font_data.star` is mechanically generated from the upstream Python
   `font.py` as ~1500 individual `f.glyphs[i] = v as u8` assignments on a
   zero-initialized array (skipping the ~500 already-zero bytes) — slower
   to type than a literal would have been, but there's no other option
   short of runtime file I/O (see below for why that's also not viable for
   binary data yet).

6. **`impl` can't reach into another module.** `impl SomeImportedType:` is
   a parse error (`impl` only takes a bare identifier, confirmed empirically
   — `impl cpu::Cpu:` fails with "expected ':', found '::'"). Every method
   on a struct must live in the same file as that struct's own definition;
   there's no way to split `Cpu`'s ~90 opcode handler methods across
   multiple files the way, say, C splits a big `struct` across translation
   units. This is why `cpu.star` is one ~1500-line file rather than several
   smaller ones. What *does* work, and is used throughout this project:
   composition — `Cpu` holds `mem: memory::Memory`, `screen: screen::Screen`,
   `kbd: keyboard::Keyboard`, `flags: flags::StatusFlags` as plain fields,
   each with their own methods defined in their own file, called through
   `self.mem.read_byte(...)` etc. Method resolution across the module
   boundary works fine for *calling* a type's existing methods — it's only
   *defining new methods* on an imported type that's unsupported.

7. **`Flags` is a reserved builtin generic name.** `struct Flags:` collides
   with the builtin `Flags<E>` (a typed bitset over a fieldless enum) and
   fails with a confusing "needs an explicit type argument" error at the
   *construction* site, not the declaration. Renamed to `StatusFlags`.

8. **Single-line `fn foo(): body` doesn't parse.** A function/method body
   must be on its own indented line(s) below the `fn ... :` header, even
   for a one-expression body — `fn t(self) -> bool: self.get(T_BIT)` is a
   parse error; it has to be
   ```
   fn t(self) -> bool:
       self.get(T_BIT)
   ```
   Hit repeatedly while writing `flags.star`'s named bit accessors.

9. **`file_read`'s `str` result silently truncates at the first embedded
   NUL byte.** Confirmed empirically: a 6-byte binary file with a 0x00 in
   the middle comes back with `len() == 1`. This makes `file_read` unusable
   for loading an arbitrary compiled Nova-16 program — `HLT` alone is
   opcode 0, so *any* real program is virtually guaranteed to contain
   embedded zero bytes. This is why `main.star` has a hand-encoded demo
   program baked in rather than a "load a .bin" option; a byte-accurate
   binary file reader (an `extern "C" fn`-based `fread` into a `Bytes`,
   or a compiler-level fix to `file_read`) is future work, not attempted
   here.

10. **A bare multi-statement `if`/`else` doesn't work as a `let`
    initializer.** `let x = if cond: <expr> else: <expr>` works fine when
    each arm is a *single* expression (used successfully in `flags.star`'s
    `sign_idx`/`overflow` calculations). The moment either arm becomes
    multiple statements (its own `let`s before a trailing value), binding
    the whole thing to a `let` breaks — this turned out to be the exact
    shape of a real compiler bug, not just a style limitation; see below.

## Two Star compiler bugs found and fixed

Building this project's very first smoke test (a struct holding a
`[u8; 65536]` array — the whole reason a Nova-16 port needs 64KB of
addressable memory) immediately hung `clang`. Both fixes below are in
`src/codegen/`, not in this project, and both were verified against the
full `cargo test` suite (no regressions) before continuing.

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
temp-then-copy. This is **not** a general fix — it only covers `let x =
<array-repeat-or-struct-literal>` (recursively through nested struct-
literal fields). Two shapes remain unfixed, deliberately avoided everywhere
in this project instead of chased further:
- **A struct/array returned *by value* from an ordinary function** still
  crashes/hangs identically (confirmed: a function returning a
  `struct { data: [u8; 65536] }` hangs `clang` the same way). This is why
  `memory.star`/`screen.star` have no `fn new_memory() -> Memory`-style
  constructors — `Memory`/`Screen`/`Cpu` are only ever built as one big
  literal directly at their `let mut cpu = Cpu(mem = Memory(...), screen =
  Screen(...), ...)` call site in `main.star`, relying on the recursive
  struct-literal fix. `FontData` (2048 bytes) is small enough to return by
  value safely and does have its own constructor function.
- **A plain (non-`self`) function parameter of a large struct type** is
  passed *by value* and hits the same wall — confirmed the hard way:
  `Screen::draw_text(mut self, m: mem::Memory, ...)` taking `Memory`
  (~300KB) as an ordinary parameter hung `clang` even though every
  individual piece involved (two 64KB arrays plus a small nested struct)
  compiled fine in isolation. Bisected by literally deleting half the
  methods in `screen.star` at a time until the hang disappeared. Fixed by
  moving `draw_text` onto `Cpu` itself (`cpu.star`), which already holds
  both `mem` and `screen` as fields reachable through `self` — `self` is
  the one parameter kind that's pointer-passed, never copied, in this
  compiler (confirmed in `codegen/stmt.rs::emit_fn`).

  General takeaway adopted for the rest of this project: **any struct
  embedding a "large" fixed array only ever gets constructed once, directly
  into a `let` binding via a literal, and is only ever passed around
  afterward as an implicit `self` on a method call — never as an ordinary
  parameter, and never returned by value.**

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

## What's implemented

The full CPU/memory/register-file/flags architecture, the fetch-decode-
execute cycle, all four addressing modes, and roughly 100 opcodes:

- No-operand: `HLT NOP RET IRET CLI STI`
- Data movement: `MOV MOVZ MOVNZ XCHNG SWAP LEA`
- Arithmetic: `ADD SUB MUL DIV MOD INC DEC NEG ABS ADC SBC MULH DIVH MIN MAX
  CLZ CTZ POPCNT`
- Bitwise: `AND OR XOR NOT SHL SHR ROL ROR SAR SAL RCL RCR BTST BSET BCLR
  BFLIP`
- Stack: `PUSH POP PUSHF POPF PUSHA POPA ENTER LEAVE`
- Control flow: `JMP` + all 12 conditional jumps, `BR BRZ BRNZ CMP CALL
  CALLZ CALLNZ RETN LOOP LOOPZ WHILE INT`
- Memory bulk: `MEMCPY MEMSET MEMMOVE MEMSWAP MEMTEST`
- Random: `RND RNDR`
- Graphics: `SBLEND(stub) SREAD SWRITE VREAD VWRITE SBLIT VBLIT SFILL SINV
  SLINE SRECT SCIRC SROL SROT SSHFT SFLIP CHAR TEXT`
- Keyboard: `KEYIN KEYSTAT KEYCOUNT KEYCLEAR KEYCTRL`
- `MOUSECTRL` (stub, consumes its operand and no-ops)
- Every register-code target (`R0-R9, P0-P9, SP, FP, VX, VY, VM, VL, VC,
  BANK, C0, C1, MX, MY, MB, SA, SF, SV, SW, TT, TM, TC, TS`, and the
  `P0:`/`:P0`-style byte-halves) via `MOV`/arithmetic/etc., not just as
  dedicated opcodes.
- Interrupts (timer and keyboard as real hardware sources; software `INT`
  reaching every vector 0-7) and the timer (`TC`/`TM`/`TS`/`TT`, ticked once
  per instruction).

## What's not implemented (and why)

Deliberately deferred, each documented at the point it would have plugged
in:

- **BCD arithmetic** (`SED CLD CLA BCDA BCDS BCDCMP BCD2BIN BIN2BCD BCDADD
  BCDSUB`) — a self-contained subsystem, no interaction with anything
  above; skipped for time.
- **Math library** (`POWR SQRT LOG EXP SIN COS TAN ATAN ASIN ACOS DEG RAD
  FLOOR CEIL ROUND TRUNC FRAC INTGR`) and **fixed-point Q8.8** (`FMUL FDIV
  FTOI ITOF`) — straightforward given Star's own math builtins exist
  (`sin`/`cos`/`sqrt`/... are already used elsewhere in this repo), just not
  reached yet.
- **String library** (`STRCPY STRCAT STRCMP STRLEN STREXT STREXTI STRUPR
  STRLWR STRREV STRFIND STRFINDI`) and **type conversion** (`ITOB BTOI ITOS
  STOI`) — operate on raw memory bytes, moderate complexity, not reached.
- **`MEMCMP`** specifically (unlike its 3-operand siblings above) — a
  4-operand opcode; see "4-operand instructions are out of scope" above.
- **Sprites** (`SPBLIT SPBLITALL`) and **layers** (`LSWAP LMOVE LCOPY`,
  and `VL`/layer-switching generally) — the real machine composites 9
  layers (1 base + 4 background + 4 sprite); this port only implements
  layer-0 semantics (every draw goes straight to `screen`/`vram`,
  matching what the upstream reference itself does when `VL==0`). A full
  compositor is a substantial separate subsystem.
- **Sound** (`SPLAY SSTOP STRIG SMIX SECHO SREVERB SFILTER`) — the
  register model (`SA SF SV SW`) is fully in place and settable via `MOV`
  like any other register, but no audio synthesis/mixing is implemented.
  The actual waveform generation is a host-audio concern more than CPU-
  instruction semantics even in the reference implementation.
- **UART/serial** (`SERIN SEROUT SERSTAT SERCTRL`) — a self-contained
  peripheral, not reached.
- **Hardware debugging opcodes** (`SETBP CLRBP ENABRK DISBRK ENATRAP
  DISATRAP`) — explicitly out of scope per the brief (no debugger).
- **Real mouse events** — `MOUSECTRL` is stubbed and `MX`/`MY`/`MB` are
  ordinary readable/writable registers, but nothing feeds them from the
  host's actual mouse.
- **An assembler/disassembler/debugger** — explicitly out of scope per the
  brief. Test/demo programs are hand-encoded raw opcode bytes; see
  "Testing" below.

## Known simplifications

- **The timer ticks once per emulated instruction**, not once per host
  clock cycle. This is an interpreter, not a cycle-accurate simulator —
  documented as a deliberate simplification, not an oversight.
- **Timer catch-up is capped at +1 per tick** rather than "advance by
  however many divisor-periods elapsed," which only differs from the
  reference under a `TS` so small relative to instruction throughput that
  multiple periods elapse between ticks — an edge case, not the common
  path.
- **`SBLEND` (blend mode) is a stub**: the opcode is recognized and its
  operand consumed, but every draw is a plain overwrite — no additive/
  subtractive/multiply/screen blending is wired into `Screen::set_screen`/
  `set_vram` yet.
- **DIV/MOD/DIVH by zero print a diagnostic and leave the destination
  unchanged**, rather than raising a hardware fault/trap — a defensive
  choice so a buggy test program halts with a readable message instead of
  the whole emulator process aborting.
- **An unknown/unimplemented opcode halts the CPU with a diagnostic**
  (`pc`, opcode byte) rather than either crashing or silently
  misinterpreting the following bytes as something else — the safest
  choice given the fetch stream would otherwise desync unrecoverably.

## Testing

No test suite (no assembler to generate real programs from source, and
unit-testing individual opcodes would mean hand-encoding bytes for each
one anyway — the same cost as the smoke tests below, without the
end-to-end confidence). What was actually verified, headlessly, before
wiring anything into the SDL window:

- Register-code round trips (`get_reg_value`/`set_reg_value` for `R0`,
  `P0`, and `P0:`/`:P0` byte-halves) against known bit patterns.
- Flag computation (`StatusFlags::apply_arith`) against hand-checked
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

## Ideas for future work

- Layer compositing (backgrounds 1-4, sprites 5-8) and `SPBLIT`/
  `SPBLITALL`/`LSWAP`/`LMOVE`/`LCOPY`.
- Sound synthesis (waveform generation + mixing) behind the already-in-
  place `SA`/`SF`/`SV`/`SW` register model.
- The math/string/BCD/type-conversion/UART opcode groups listed above.
- A byte-accurate binary file loader (so a compiled `.bin` could be loaded
  instead of a baked-in demo), which needs either a `Bytes`/raw-`fread`-
  based reader or a compiler-level fix to `file_read`'s NUL-truncation.
- Blend modes (`SBLEND`) actually affecting `SWRITE`/`VWRITE`.
- Real mouse-event plumbing behind `MOUSECTRL`/`MX`/`MY`/`MB`.

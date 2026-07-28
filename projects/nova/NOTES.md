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
- `screen.star` — the 256x256 8bpp screen + VRAM buffers, drawing
  primitives (line/rect/circle/char/text/roll/shift/flip/rotate), and the
  font.
- `keyboard.star` — the 64-slot keyboard FIFO and its status/control
  register model.
- `cpu.star` — the CPU itself: registers, the register-code address space,
  operand decoding, the fetch-decode-execute cycle, every implemented
  instruction, interrupts, and the timer. Still the one large file in the
  project (~2570 lines, register codes and opcodes now spelled in hex —
  see "Language gotchas" #6 and #2 below); splitting it by opcode group is
  now *possible* since `impl` can cross a module boundary, just not done yet.
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
   NUL-terminated `str`. **Not wired up in this project**, though: there's
   still no assembler in this port (out of scope per the brief) to produce
   a real compiled `.bin` to load, so there's nothing to feed a byte-loader
   that the baked-in demo program doesn't already cover. `main.star`'s
   header comment now points at `file_read_bytes` for whenever that
   changes.

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

## Four Star compiler bugs found and fixed

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
execute cycle, all four addressing modes, and roughly 115 opcodes:

- No-operand: `HLT NOP RET IRET CLI STI`
- Data movement: `MOV MOVZ MOVNZ XCHNG SWAP LEA`
- Arithmetic: `ADD SUB MUL DIV MOD INC DEC NEG ABS ADC SBC MULH DIVH MIN MAX
  CLZ CTZ POPCNT`
- Math library: `POWR SQRT LOG EXP SIN COS TAN ATAN ASIN ACOS DEG RAD FLOOR
  CEIL ROUND TRUNC FRAC INTGR`
- Fixed-point Q8.8: `FMUL FDIV FTOI ITOF`
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
- **`STREXT`/`STREXTI`** specifically (unlike the rest of the string
  library, now implemented — see "String library and integer/string
  conversion" below) and **`MEMCMP`** — both 4-operand opcodes; see
  "4-operand instructions are out of scope" above.
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
- **The math library's transcendental opcodes compute in `f32`, not
  `f64`** like the Python reference — see "Math library / Q8.8
  fixed-point" below for the full reasoning and the two opcodes (`POWR`,
  `EXP`) where the gap is actually reachable rather than academic.

## Testing

No test suite (no assembler to generate real programs from source, and
unit-testing individual opcodes would mean hand-encoding bytes for each
one anyway — the same cost as the smoke tests below, without the
end-to-end confidence). What was actually verified, headlessly, before
wiring anything into the SDL window:

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

## Ideas for future work

- Layer compositing (backgrounds 1-4, sprites 5-8) and `SPBLIT`/
  `SPBLITALL`/`LSWAP`/`LMOVE`/`LCOPY`.
- Sound synthesis (waveform generation + mixing) behind the already-in-
  place `SA`/`SF`/`SV`/`SW` register model.
- The BCD/UART opcode groups listed above (the math library, Q8.8
  fixed-point conversion, string library, and integer/string conversion
  are now done — see above).
- A byte-accurate binary file loader (so a compiled `.bin` could be loaded
  instead of a baked-in demo) — the language-level blocker is gone
  (`file_read_bytes`/`file_write_bytes` now exist, see "Fixes applied to
  this project"), and this round's own verification harness proved the
  mechanics work end to end (loading a real assembled `.bin` via
  `file_read_bytes` into `Cpu`'s memory) — but there's still no assembler
  in this port to produce a `.bin` from source in the first place, which is
  the actual remaining blocker for wiring this into `main.star` for real.
- Blend modes (`SBLEND`) actually affecting `SWRITE`/`VWRITE`.
- Real mouse-event plumbing behind `MOUSECTRL`/`MX`/`MY`/`MB`.
- Splitting `cpu.star`'s ~90 opcode-handler methods across files by group
  (arithmetic/bitwise/stack/control-flow/graphics/...) — unblocked now that
  `impl` can cross a module boundary (gotcha #6), not yet done.

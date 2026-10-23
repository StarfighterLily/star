# HavokOS in Star — implementation notes

A native Star port of HavokOS, the LPMUD driver at `E:\dsdev\havokos`
(Pike). See `havokos.md` for the project charter. Minimum viable product:
boot the stock Dead Souls 3.9 mudlib at `E:\ds3.9\lib` (config
`E:\ds3.9\bin\mudos.cfg`) and let a player log in over telnet.

## Ground rules

- **Clean room.** The Pike driver is the only implementation reference.
  FluffOS source must never be opened. Note that `E:\ds3.9\fluffos-2.23-ds03\`
  *is* a FluffOS source tree that ships alongside the mudlib. Never read,
  grep or glob into it. Every survey of the mudlib targets `E:\ds3.9\lib`
  specifically, never `E:\ds3.9` as a whole. The HavokOS `docs/*-spec.md` and
  `docs/*-clean-room.md` files are fair game: they are HavokOS's own
  black-box specifications.
- **The live Pike driver is the oracle.** Pike is installed
  (`C:\Program Files (x86)\Pike\bin\pike.exe`). Each phase is verified by
  diffing against the reference's own output on the real DS3.9 mudlib, the
  same "byte-for-byte against the live reference" bar
  `projects/nova/NoBASIC` set. A plausible-looking port without that check
  doesn't count as done.

## Architecture: why this is not a line-by-line port

The Pike driver *transpiles*: `lpc/emitter.pike` turns each LPC program
into Pike source, and Pike's runtime compiler (`compile_string`) turns that
into a Pike program the driver instantiates. Star compiles ahead of time to
native code through LLVM, and a running Star program cannot compile new
code. So the Star driver has to be a real **LPC compiler plus a bytecode
virtual machine**:

| Pike HavokOS | Star HavokOS |
|---|---|
| Pike `cpp()` + `lpc/preprocess.pike` workarounds | `preprocess.star`: a from-scratch token-level C preprocessor with the LPC extensions (`@MARK` text blocks, raw newlines in strings, `efun_defined()`) built in |
| `lpc/lexer.pike` | `lexer.star` (works on `Bytes`, see below) |
| `lpc/parser.pike` | `parser.star` → AST |
| `lpc/emitter.pike` → Pike source → Pike compiler | `compiler.star`: AST → bytecode (`program.star` format) |
| Pike runtime executing the generated program | `vm.star`: bytecode interpreter |
| `havok/driver.pike` object table, call stack, call_outs, heart beats | `vm.star` for now: programs, objects, loading, call_other and the object stack (M3). Call_outs and heart beats join it in M5 |
| `havok/efuns.pike` | `efuns.star` (the M3 subset); M4 adds more files, split by area |
| `havok/net.pike` (telnet), `sockets.pike`, `http.pike`, `tls.pike` | later phases (see roadmap) |

Up to and including the parser, the port can follow the Pike code closely.
From the compiler on, the Pike files still define the *semantics* (what each
efun does, the order of master applies, how objects load, clone and
destruct), but the *mechanism* is new code.

## Star constraints that shape the design

Each of these was probed with a throwaway program on 2026-10-22, not
assumed:

1. **`List<T>` has value semantics** (copy-on-write, refcounted).
   `let b = a; b.push(x)` leaves `a` unchanged. LPC arrays and mappings
   are *shared by reference*, so they can't simply be a `List<Value>`
   inside a `Value`. They live in VM-owned heap tables, and a `Value`
   holds an integer handle into the table.
2. **A free function's `mut` parameter is a copy.** Changes made through
   it don't reach the caller. **`mut self` methods do mutate in place**,
   and nested in-place mutation through `self` stays cheap: 400k
   `self.heap.arrs[i].items.push(..)` calls take about 2 ms. So all
   driver and VM state hangs off structs and is mutated through
   `mut self` methods, never passed to free functions.
3. **`str` indexing is O(n).** `s[i]` runs `strlen` for its bounds check,
   so a char-by-char scan of 1 MB took about 70 s. Building strings with
   `chr()` + `push` + `str_join` is slow too: about 15 s for 200k
   characters. **`Bytes` is O(1)**: a 1 MB scan takes about 1 ms, and
   20k `str_from_bytes` substrings take about 10 ms. The front end reads
   files with `file_read_bytes` and only creates `str` values for
   finished token text. String-heavy efuns (`sprintf`, `explode`,
   `replace_string`, ...) will work on `bytes_from_str` copies and build
   results in `Bytes` buffers.
4. **`List<T>` supports only `push`/`pop`/`len`/indexing**, and
   `Map<K,V>` has no iteration. Where code needs an ordered key list, it
   keeps one beside the map. LPC mappings get their own hash table
   implementation, since their keys are `Value`s, and a payload-carrying
   enum can't be a `Map` key.
5. **Recursive enums through `List` work** (`enum Value: ... Arr(items:
   List<Value>)` builds and runs), but because of #1 they aren't used for
   LPC containers.
6. **`i64` needs explicit casts everywhere.** Literals infer as `i32`, so
   it's `(5 as i64)`, and there's no `i64` literal above 2^31 without
   arithmetic. LPC `int` is 64-bit, so the VM uses `i64` throughout.
7. **`extern "C"` names can't start with a capital letter.** `extern "C"
   fn Sleep(..)` and `GetTickCount()` resolve as *type* names (`undefined
   type 'Sleep'`). Lowercase CRT names work: `_sleep`, `clock`,
   `_time64`. Some lowercase names (`time`) are reserved by the runtime.
   Filed in `todo.md` as a Star compiler bug.
8. **No server sockets.** `net.rs` has only `tcp_connect`/`send`/`recv`/
   `close`/`set_nonblocking`, so there's no `listen`/`accept`, and
   `extern "C"` can't easily build the `sockaddr_in` that `bind` needs.
   The networking phase will add `tcp_listen`/`tcp_accept` builtins to
   `src/codegen/net.rs`, following that file's existing Winsock/POSIX
   seam pattern.

## Value representation (M3, `value.star`)

```
enum Value:
    Undef            # FluffOS "undefined" zero: undefinedp() true, otherwise int 0
    Int(v: i64)
    Real(v: f64)
    Str(s: str)
    Arr(h: i32)      # handle into Vm.arrs
    Map(h: i32)      # handle into Vm.maps
    Obj(h: i32, gen: i32)   # object slot + generation (slot reuse after destruct, M5)
    Fn(h: i32)       # Vm.fns: efun/simul_efun/prototype pointers, local function refs, closures
    Cls(h: i32)      # Vm.clss: positional class instance
```

- A mapping is insertion-ordered key/value columns plus a `Map<MKey, i32>`
  index, `MKey` being a hashable flattening of the key `Value`.
- Every empty array is one shared object (handle 0), because it is in
  Pike: `({}) == ({})` and `({}) == allocate(0)` are true in the reference,
  but two non-empty arrays never compare equal. Nothing may grow handle 0
  in place.
- A local captured by a closure is "boxed" into a cell (`Vm.cells`), and
  both the function and its closures go through the cell, since Pike
  lambdas capture by reference. `$(expr)` values become cells too.
- No buffers yet. DS3.9 doesn't need them for the MVP.

Garbage: the heap tables only grow in M3. The plan stands: a mark-and-sweep
that runs only *between* top-level evaluations, when the VM stack is empty.
The roots are then object variables, pending call_outs and a few
driver-held values, so no stack maps are needed. It arrives with the
object model (M5), which is when long-running evaluation starts.

## Roadmap

Tracked as `todo.md` items. Each milestone is verified against the live
Pike driver before it's marked done.

- **M1: front end.** Lexer + preprocessor. Exit criterion: the
  post-preprocessing token stream is identical to the Pike reference's
  `preprocess()` → `tokenize()` for every `.c` file in DS3.9: the same
  2376 succeed and the same 2 fail (`/obj/area_room.c` on its missing
  `/customdefs.h`, and `/obj/stargate.c`'s deliberate load blocker).
  Reference sweep baseline, measured 2026-10-22: `pike
  lpc/tools/parse_sweep.pike E:/ds3.9/lib` → 2378 files, 2376 ok, 51 s.
- **M2: parser.** AST for the full LPC/FluffOS grammar the reference
  accepts. Exit criterion: a canonical AST dump of every DS3.9 file
  identical to the reference parser's, plus an edge-case file for the
  grammar DS3.9 never uses. Done 2026-10-23, see the log.
- **M3: compiler + VM core.** Bytecode for expressions, statements,
  functions, inherits, `::` calls, closures/function pointers,
  `catch`/`throw`, and the call_other dispatch. Exit criterion: the
  language-semantics part of `pike/tests/run_tests.pike`'s case table
  (114+ `({ name, body, expected })` cases) runs under the Star VM. Done
  2026-10-23, see the log.
- **M4: efuns.** Strings (`sprintf`/`sscanf`/`explode`/`implode`/...),
  arrays, mappings, math, files, time, save/restore format.
- **M5: object model.** Master and simul_efun loading, load/clone/
  destruct, environment/move, add_action and command dispatch,
  call_outs, heart beats, reset and clean_up.
- **M6: network + boot (MVP).** Star compiler `tcp_listen`/`tcp_accept`
  builtins, the telnet layer, login. DS3.9 boots and a player can log in.
- **M7+: the rest.** Verb parser efuns, `ed`, socket efuns, HTTP/TLS,
  everything else HavokOS implements.

## Files

| File | Role |
|---|---|
| `token.star` | `Token`/`Tk` |
| `lexer.star` | raw file `Bytes` → tokens, including directive lines, text blocks and the reference's lexical fix-ups |
| `preprocess.star` | `Pp`: directives, includes, macro expansion, `#if` evaluation → final token stream |
| `paths.star` | `combine_path`/`dirname` for mudlib virtual paths |
| `ast.star` | `Node`/`NodeKind` arena (one variant per reference node kind) and the canonical AST dump |
| `parser.star` | `Parser`: token stream → `ast.star` nodes, method for method with `parser.pike` |
| `tools/tokdump.star` | Star side of the golden token comparison |
| `tools/ref_tokdump.pike` | reference side: drives HavokOS's own `preprocess.pike` + `lexer.pike` |
| `tests/run_tokdump_test.ps1` | M1 regression: all 2378 DS3.9 files against a frozen reference fixture |
| `tests/run_pp_cases_test.ps1` | macro and `#if` edge cases (`tests/fixtures/pplib/`) against a frozen reference dump |
| `tools/astdump.star` | Star side of the golden AST comparison |
| `tools/ref_astdump.pike` | reference side: `preprocess.pike` → `lexer.pike` → `parser.pike`, every mapping printed with sorted keys |
| `tests/run_astdump_test.ps1` | M2 regression: all 2378 DS3.9 files' ASTs against a frozen reference fixture |
| `tests/run_ast_cases_test.ps1` | grammar DS3.9 never uses (`tests/fixtures/astlib/ast_cases.c`) plus 12 one-mistake files, against frozen reference output |
| `value.star` | `Value` and the heap slot types (arrays, mappings, function pointers, classes) |
| `program.star` | bytecode opcodes, `Program`/`FnDef`/`DispEntry` |
| `compiler.star` | `Compiler`: one program's AST → `Program`, using the emitter's resolution rules |
| `vm.star` | `Vm`: heap, operators, interpreter loop, calls, call_other, loading/cloning, the object stack |
| `efuns.star` | the M3 efun subset |
| `efun_table.star` | the efun dispatch codes the VM implements |
| `efun_names.star` | generated: the reference's implemented efuns and every FluffOS efun name |
| `tools/ref_efun_names.pike` | generates `efun_names.star` from the live reference |
| `tools/run_cases.star` | Star side of the M3 case comparison |
| `tools/ref_cases.pike` | reference side: runs run_tests.pike cases (and `-extra` edge cases) through the live driver |
| `tests/run_cases_test.ps1` | M3 regression: `fixtures/cases/m3.expected.txt` (76 table cases) and `m3_extra.expected.txt` (92 edge cases) |
| `tools/compile_sweep.star`, `tools/ref_compile_sweep.pike` | M3 compile sweep over DS3.9, both sides: which files compile, and their inheritance tables |
| `tests/run_compile_sweep_test.ps1` | M3 regression: all 2378 DS3.9 files' compile results and table hashes against `fixtures/ds39_compile.expected.txt` (frozen reference output), about 21 s |

Build the tools with the **release** compiler (`target/release/star.exe
build ...`). The `star` on `PATH` on this machine was a stale Sep 8
`target/debug` build during M2, without the `println` fix or the spill-slot
fix below.

## Deliberate deviations from the reference

Each is also documented at the point in the code where it happens.

1. **Line numbers after `@MARK` text blocks** (`lexer.star`). The
   reference rewrites a block with Pike's `%O`, which spells a multi-line
   string as one literal per line. That adds newlines, so every token
   after a single-`@` block reports a line too high for the rest of the
   file. This port reports the real lines. The 9 DS3.9 files with text
   blocks are compared with line numbers left out.
2. **A stray apostrophe inside a skipped `#if 0` block is tolerated.**
   Pike `cpp()` fails the whole file ("Newline in char"). Here the lexer
   reports a `Bad` token, and the preprocessor only treats it as an error
   if it survives into live output. No DS3.9 file depends on this either
   way.

3. **Floats are doubles** (`value.star`). The reference's Pike on this
   machine is a 32-bit-float build (`float_size` 32). That's an accident of
   the build rather than LPC semantics: FluffOS uses doubles. Both print 6
   significant digits (`%g`), so results only differ past the 7th digit.
   Float *printing* does match the reference, MSVC's 3-digit exponents
   included (`1e+010`).
4. **A `switch` on a negative constant compiles** (`switch (-2) { case -2:
   ... }`). The reference rejects it: Pike narrows the type of a constant
   switch value, and the emitter's `__D->sw()` workaround for that only
   covers a bare or parenthesised literal, not `-2`. That's a transpile
   artifact, so the edge-case fixture tests negative labels through a
   variable.
5. **Closure variables are made per declaration** (`compiler.star`). A
   fresh cell is made each time a captured local's declaration runs, so
   closures made in different iterations of a loop see different copies of
   a variable declared inside the loop body. Pike shares one variable
   between every closure made in the same call. No DS3.9 code is known to
   depend on either behavior.
6. **Integer overflow wraps** at 64 bits, as in FluffOS. Pike promotes to
   bignums.

## Star compiler bugs found

1. **`print`/`println` of a non-f-string `str` used it as the `printf`
   format** (fixed). `println(s)` where `s` held `%` dropped characters
   (`"%^RED%^"` printed as `"^RED^"`), and `%s` in the data segfaulted.
   For a MUD, where `%^COLOUR%^` codes and arbitrary player input get
   printed, that's a crash bug. It surfaced as a token-dump mismatch on
   DS3.9's `bank.c`/`imc2.c`. Fixed in `src/codegen/builtins.rs`
   (`emit_print_like` now always formats through a constant `"%s"`), with
   regression test `tests/frontend_print_percent.rs`.
2. **Capitalized `extern "C"` names** (constraint #7): filed, not fixed.
3. **`str` indexing is O(n)** (constraint #3): filed as a performance
   issue, worked around with `Bytes`.
4. **Releasing an uninitialized spill slot** (fixed, M2). A field read off
   a struct-returning call, `f().field`, spills the struct into a fresh
   alloca that's released when the enclosing *scope* ends. When the read
   sat on the right of `and`/`or` and the short-circuit skipped it, that
   release still ran, on uninitialized stack, and segfaulted or not
   depending on what the caller had left there. In the parser it was
   `self.peek(1).kind` in `parse_toplevel`'s class check: the parser
   worked when called from `main` and crashed when called from
   `parse_program`'s loop. Fixed in `src/codegen/mod.rs` (`emit_place`'s
   fallback arm zeroes such slots in the entry block) and `rc.rs`
   (`emit_scope_release` re-zeroes after each release, so a loop iteration
   that skips the spill can't re-release the previous one's value).
   Regression test `tests/frontend_spill_slot_conditional_release.rs`;
   each half of the fix has a test that fails without it.
5. **`extern "C"` declarations duplicated by a diamond import** (fixed,
   M3). `crate::modules::dedupe_by_origin` collapses items a diamond import
   resolves twice (a file reached through two import edges), keyed on the
   item's name. An `extern "C" fn` has no mangled name, so it got no
   identity, both copies survived, and the checker rejected the second as
   "declared more than once". It surfaced as soon as `tools/run_cases.star`
   imported both `vm.star` and `efuns.star`: `efuns.star` imports
   `vm.star`, whose own imports declare `atof` and `clock`. Fixed in
   `src/modules.rs` by giving an extern the same span-keyed synthetic
   identity an `impl` block gets. Regression test
   `tests/frontend_extern_diamond_import.rs`: its two positive tests fail
   without the fix, and two more check that a real duplicate is still
   reported.

Not a bug, but visible: building the VM prints "internal compiler notice:
suspicious LLVM IR ... block `match_end_N` ... is unreachable" for a few
functions whose every `match` arm returns. It's the compiler's own IR
self-check noticing a dead join block, and the generated code is correct.

## Log

### 2026-10-22: project kickoff, M1 front end
Surveyed both codebases, probed Star's capabilities (constraints #1–#8
above), and recorded the reference sweep baseline.

**M1 done.** `lexer.star` + `preprocess.star` reproduce the reference
front end's token stream exactly on all 2378 DS3.9 `.c` files:
- 2376 preprocess and lex cleanly. The same 2 fail on both sides, for the
  same reasons.
- 2369 match the reference token for token *and* line for line.
- The 9 files with `@` text blocks match token for token (deviation #1).

The Star front end preprocesses and lexes the whole mudlib in about 20 s,
including the dump and hashing. That's not directly comparable to the
reference's 51 s `parse_sweep`, which also parses. The macro rules were pinned down against Pike `cpp()` with a
dedicated edge-case file rather than taken from the C standard, and two
of them really do differ from ISO C (see `preprocess.star`'s header):
- An expansion is rescanned in isolation, so a function-like name
  produced by an expansion can't take its arguments from the following
  text.
- There's no permanent "blue paint" on a self-referencing name.

Getting there found:
- One Star compiler bug, now fixed (the `println` format bug above).
- Two reference behaviors this port deliberately doesn't reproduce
  (deviations #1–#2).
- One line-numbering rule: a multi-line function-like macro call's
  expansion reports the line of its closing paren.

**Next: M2, the parser** (`pike/lpc/parser.pike`, 779 lines). Its exit
criterion should mirror M1's: run HavokOS's own parser on every DS3.9 file,
dump a canonical AST form from both sides, and compare.

### 2026-10-23: M2 parser

**M2 done.** `ast.star` + `parser.star` reproduce the reference parser's AST
exactly:
- All 2378 DS3.9 files: the same 2376 parse and the same 2 fail, and every
  AST dump is identical (`tests/run_astdump_test.ps1`, about 21 s; the
  reference takes about 1 min 50 s for the same dump). The 9 text-block
  files are compared without line numbers, as in M1. Full `-v` dumps of
  large files (`/lib/std/room.c`, `/secure/lib/connect.c`, 220+ KB of dump
  each) were also compared byte for byte.
- DS3.9 never uses case ranges, scoped function pointers (`(: ::f :)`,
  `(: efun::write, x :)`), `parse_command`, default arguments,
  `ob->(expr)` or labelled inherits, so
  `tests/fixtures/astlib/ast_cases.c` does, and its dump matches too
  (`tests/run_ast_cases_test.ps1`). The same script checks 12 one-mistake
  files succeed or fail as the reference does. The error messages also
  match the reference's word for word, though only success/failure is
  pinned.

The dump format (`ast.star`, "Canonical dump") is the reference mapping
printed generically, keys sorted. The reference side sorts with Pike's
`sort()`. Star has no ordering on `str`, so the Star side writes each kind's
keys in a hand-sorted order, and the sweep catches any slip. It also
distinguishes a key the reference leaves unset from one it sets to 0
(`func` "body" vs `case` "lo"), since M3's compiler will read those.

One reference behavior that comes from Pike rather than the parser's own
code is reproduced: a node built without an explicit token takes its line
from the token current when the mapping is built, *after* its children
were parsed. So a `for` loop's init-expression node reports the line of
the `;`, not of the expression.

Getting there found one Star compiler bug, now fixed (#4 above): until
it was, the parser segfaulted on the very first file, a one-line
`int x;`.

**Next: M3, bytecode compiler + VM core.**

### 2026-10-23: M3 compiler + VM core

**M3 done.** `compiler.star` compiles each program's AST to stack-machine
bytecode (`program.star`), and `vm.star` runs it. It's checked three ways,
all against the live Pike driver:
- **The reference's own case table.** The 76 language-semantics cases of
  `pike/tests/run_tests.pike` all give the reference's results
  (`tests/run_cases_test.ps1`). The selection is
  `tests/fixtures/cases/m3_selection.txt`: syntax quirks, values, the
  int/float assignment rules, classes, function pointers, catch/throw,
  foreach, simul_efuns, inherits, `::`, call_other, plus the table's two
  check_error cases. The fixture records what the live driver actually
  returned, not the table's expected column, and `tools/ref_cases.pike`
  reports any case where the two disagree. None do. The efun-library cases
  (sscanf, explode/implode edge cases, save/restore, ...) belong to M4, and
  the object-model ones (destruct, environments, call_outs, ...) to M5.
- **92 edge cases of this port's own** (`m3_extra_cases.txt`), whose
  expected values are whatever the reference returns. They cover closures
  sharing locals by reference, nested lvalue chains, string index
  assignment through an array, varargs and spreads, switch fallthrough and
  ranges, catch inside loops, Pike's operator semantics, private/static
  dispatch, prototypes and float printing. Writing them turned up two
  semantics the table never shows: in Pike `3 == 3.0` is false, and the
  empty array is a single shared object (`({}) == ({})` is true).
- **A compile sweep of all 2378 DS3.9 files** (`tools/compile_sweep.star`
  against `tools/ref_compile_sweep.pike`, which drives the reference's own
  `transpile()`). All 2378 lines match: the same 2373 files compile, with
  identical inheritance tables (hashes of the `all_funcs` and `all_vars`
  meta), and the same 5 fail on files missing from the mudlib
  (`tests/run_compile_sweep_test.ps1`, about 21 s; the reference takes
  about 6 min). Both sides compile the simul_efun program first and
  resolve against its names, as a boot would. Without that, the
  reference's own Pike compile rejects 3 player files (a DS simul_efun
  shadows the `query_charmode` efun, whose arity Pike checks). The sweep also showed that the reference driver adds
  config-derived predefined macros (`MUD_NAME`, `__HAVOKOS__`, ...) that
  M1's front-end comparison never saw, because that comparison drove
  `preprocess.pike` directly. `Vm.configure()` adds them now.

The design decisions, each explained at its point in the code:
- **Frames on one loop.** LPC-to-LPC calls (local, virtual, `::`,
  call_other, simul_efun, function pointers) push a frame on the
  interpreter loop rather than recursing in Star. Only an efun calling back
  into LPC runs a nested loop, so LPC recursion depth isn't bounded by the
  native stack.
- **Errors without exceptions.** An error sets a flag and unwinds to the
  innermost `catch` handler of the current loop. Failing that, it unwinds
  out of the loop, so the efun that started a nested loop sees the flag
  and returns.
- **Dispatch tables per program.** `vt` (call_other and virtual calls) and
  `anyt` (the reference's `__lpc_fn`, for prototype calls and self
  call_other) are built at compile time from the inherits' tables.
  Inherited code addresses variables relative to its own block, so it runs
  unchanged in any inheriting object.
- **Lvalue chains.** `a[i][j] op= v` evaluates each container and key
  once. The innermost store is done in place, and only a changed string is
  written back outwards.
- **Functions with captures compile twice.** The first pass finds the
  captured declarations, and the second boxes them.

Speed is already comparable with the reference's compiled Pike: `fib(25)`
plus a million-iteration loop take 0.48 s including boot, against the
reference's 1.28 s (about 1 s of which is its boot).

Not in M3, by plan: line numbers in runtime error messages, the
evaluation cost limit, garbage collection, destruct and the rest of the
object model (M5), and the efun library beyond `efuns.star`'s subset (M4).
`sscanf`/`parse_command` compile today as plain efun calls with rvalue
arguments, which raise the reference's "not implemented" error. M4
compiles their lvalue arguments properly.

Getting there found one Star compiler bug, now fixed (#5 above).

**Next: M4, efuns.**

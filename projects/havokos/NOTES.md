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
| `havok/driver.pike` object table, call stack, call_outs, heart beats | `vm.star` (programs, objects, loading, call_other, the object stack; M3) and `objects.star` (applies, top-level evaluations, destruct, environments, commands, call_outs, heart beats, resets; M5) |
| Pike's garbage collector | `gc.star`: a mark-and-sweep of the VM's value tables between top-level evaluations (M5), and of the slots one interpreter loop allocated, at its safe points (P1 #9) |
| `havok/efuns.pike` | `efuns.star` (dispatch + the M3 subset) and one file per area since M4: `efuns_str.star`, `efuns_arr.star`, `efuns_file.star`, `sprintf.star`, `sscanf.star`, `regex.star`, `md5.star`, `tcolour.star`, `numfmt.star`, and `efuns_obj.star` (the object model, M5) |
| `havok/saveformat.pike` | `saveformat.star` (plus the emitter's `__lpc_save`/`__lpc_restore` variable walk) |
| `havok/net.pike` (telnet, connections, sessions) | `net.star` (on `conn.star`'s Conn), its efuns `efuns_net.star`; the sockets themselves are compiler builtins (`src/codegen/net_server.rs`, M6) |
| `havok/parser.pike` (the verb parser) | `verbparse.star` (registry) + `verbmatch.star` (parse_sentence()), data in `vpdata.star` (M6) |
| `havok/boot.pike` and the Pike backend's event loop | `boot.star` + `config.star`: boot, then an explicit wait/read/timers/write loop (M6) |
| `havok/ed.pike` (the line editor) and its efun glue | `ed.star` (the engine and efuns, on the Vm), session state in `eddata.star` (M7) |
| `havok/sockets.pike` (LPC sockets) and `efuns.pike` resolve() | `sockets.star` (on `sockdata.star`'s LSock), polled by `net.star` net_poll(); the OS side is the compiler's (`src/codegen/net_sock.rs`, M7) |
| `havok/efuns.pike`'s HavokOS-only extensions (JSON, astar_path, find_files, watching, quotas, dependencies, profiling, status reports) and their `driver.pike`/`compiler.pike` machinery | `json.star`, and `ext.star` with its rows in `extdata.star` (M7) |
| `havok/sqldb.pike` (the SQLite efuns) | `sqldb.star`, over the real SQLite library: `extern "C"` plus the compiler's `sqlite_open()`/`sqlite_prepare()` (`src/codegen/sqlite.rs`, P1 #7) |
| `havok/http.pike` (the HTTP port, WebSockets) over Pike's Protocols.HTTP.Server and Protocols.WebSocket | `http.star` (with `sha1.star`, `mimetypes.star`), the upgraded connections in `net.star` (P1 #8) |
| `havok/tls.pike` and Pike's SSL.File/SSL.Port | `tls.star`, over OpenSSL 3 through `extern "C"` (`openssl/`, P1 #8) |
| Pike's Gz (MCCP's zlib stream) | `zlib.star`, a deflate compressor of this port's own (P1 #8) |
| (none: the reference has no LPC buffers) | `buffers.star`, FluffOS's buffer type as Dead Souls' docs describe it (P1 #8) |

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
7. **`extern "C"` names couldn't start with a capital letter** (fixed in
   P1 #8, HavokOS P2 #1). `extern "C" fn Sleep(..)` and `GetTickCount()`
   resolved as *type* names (`undefined type 'Sleep'`), and since M7 the
   checker rejected them outright; lowercase CRT names worked (`_sleep`,
   `clock`, `_time64`). Now a struct literal naming an extern is checked as
   its call, which is what let `tls.star` bind OpenSSL (`SSL_new`, ...).
   Some lowercase names (`time`) are still reserved by the runtime.
8. **No server sockets.** `net.rs` has only `tcp_connect`/`send`/`recv`/
   `close`/`set_nonblocking`, so there's no `listen`/`accept`, and
   `extern "C"` can't easily build the `sockaddr_in` that `bind` needs.
   The networking phase will add `tcp_listen`/`tcp_accept` builtins to
   `src/codegen/net.rs`, following that file's existing Winsock/POSIX
   seam pattern.

Found during M4 (2026-10-23), each probed with a throwaway program:

9. **Star's FFI couldn't read a C struct.** A `ptr` can be passed to C, but
   nothing in the language loaded a field back out of one, so every C call
   that answers through an out-parameter (`_findfirst64`, `_stat64`,
   `_localtime64_s`) was out of reach. M4 added filesystem and calendar
   builtins to the compiler instead (`dir_list`, `path_kind`, `file_size`,
   `file_mtime`, `dir_create`, `dir_remove`, `file_remove`, `file_rename`,
   `local_time`; `src/codegen/fs.rs`). Since P1 #8 there is a general
   answer for data in C memory: `ptr_to_bytes(p, n)` copies n bytes out
   (a struct's fields then decode from the `Bytes`) and
   `ptr_write_bytes(dst, b, off, n)` copies in (`src/codegen/ffi_bytes.rs`);
   only a `T**` out-parameter still needs a builtin, there being no way to
   make a pointer to a Star local.
10. **`x = f(x)` on a `Bytes`/`List` is quadratic.** The caller still holds
    its reference during the call, so the first push inside `f` copies the
    whole buffer, on every call: 20k ten-byte appends take 188 ms that way
    against 1 ms through a `mut self` method. Every string-building efun
    appends through `buf.star`'s `Buf`, and the recursive formatters (%O,
    the save encoder) write into a VM-owned `Buf` (`Vm.dsc`, `Vm.enc`).
11. **`i64` arithmetic traps on overflow** and aborts the process ("signed
    64-bit integer overflow"). LPC ints wrap (deviation #6), so the VM's
    operators go through `vm.star`'s `wadd`/`wsub`/`wmul`/`wdiv`/`wmod`
    (`Wrapping<i64>`) and `wshl`/`wshr` (a shift by 64 or more is poison in
    LLVM). Until M4 the VM used plain `i64` ops, so an LPC `(1 << 62) * 4`
    killed the whole driver.
12. **A float literal is single precision.** `2.718281828459045 as f64` is
    2.7182817...: the literal is an `f32` before the cast widens it. Exact
    constants are computed (`(1.0 as f64) / (3.0 as f64)`) or built from
    integers. Filed in `todo.md`.
13. **Math builtins narrowed `f64` to `f32`** (fixed in M4, Star compiler
    bug #6 below).

Found during M5 (2026-10-25):

14. **No clock that lasts a MUD's uptime.** msvcrt's `clock()` returns
    `(clock_t)-1` for good once its millisecond count passes 2^31, after
    about 24.8 days (and on glibc it's CPU time); `_time64` has whole
    seconds only; `GetTickCount64` can't be declared (#7) and
    `clock_gettime` answers through a struct (#9). M5 added a `clock_ms()`
    builtin to the compiler (`src/codegen/clock.rs`,
    `tests/frontend_clock.rs`) for call_outs, heart beats and the
    evaluation limit.
15. **A densely connected program could hang `star check`** (Star compiler
    bug #7 below), and **a statement `match` whose arms have different
    value types built malformed IR** (bug #8). Both surfaced compiling the
    M5 VM.

Found during M6 (2026-10-25):

16. **Star functions keep their own names in the IR** (`fn bind(..)` is
    `@bind`), so a C symbol the compiler declares unconditionally collides
    with any user function of that name. The server-socket builtins
    therefore declare `bind`/`listen`/`accept`/`poll` only in programs that
    use them (`src/codegen/net_server.rs`); the test suite already has a
    `fn bind`.
17. **An empty `Bytes` (or `List`) is a null pointer**, so `tcp_recv`'s
    "null means would-block" signal can't carry over to a binary-safe
    receive. Readiness comes from `tcp_wait()` instead, which is also the
    driver's idle wait.
18. **stdout is fully buffered when redirected to a file**: a driver's log
    showed nothing until it exited. `log_msg()` flushes (`fflush`).
19. **msvcrt `clock()` advances in 15.6 ms steps** (and dies after 24.8
    days, #14), which M5's `time_expression` used: a short block timed 0 or
    15625 µs, so Dead Souls' boot-time performance rating swung at random.
    M6 added `clock_us()` (`src/codegen/clock.rs`).
20. **The machine's host name** (`query_host_name()`) needs `gethostname`
    after `WSAStartup`, or `GetComputerNameExA`, which can't be declared
    (#7); `COMPUTERNAME` is upper-cased. M6 added `host_name()`.
21. **A list literal inside an `if`/`match` arm could break the build**
    (Star compiler bug #9 below), found as soon as `tcp_wait`'s codegen
    built its result the same way.

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
- Buffers (P1 #8): `Value::Buf(h)`, a handle into `Vm.bufs` holding the
  bytes, shared by reference like an array (`buffers.star`).
- Strings are NUL-terminated (Star `str`), so an LPC string can't hold a
  `\0` byte (deviation #7).
- `a += ({ x })` copies the whole left array each time, as LPC semantics
  require, but the copy costs more than Pike's: 20k appends in a loop take
  3.3 s against the reference's ~0.3 s. In-place appending when nothing else
  holds the array needs reference tracking the VM doesn't have yet (P1 #9
  went another way, see below). DS3.9's `+=` loops are over small arrays.
  Since P1 #9 the copies are at least garbage that gets collected while
  the loop runs: 40,000 appends peak at 63 MB, where 30,000 used to hold
  7 GB.

Garbage (M5, `gc.star`): a mark-and-sweep that runs only *between*
top-level evaluations, when the VM stack is empty, so the roots are object
variables, pending call_outs, add_action sentences and a few driver-held
values, and no stack maps are needed. Freed handles go on per-table free
lists the allocators take from first; a destructed object's slot is reused
one generation on, so stale object values still read as destructed. The
driver's timer step (`objects.star` driver_tick()) collects when the heap
has doubled since the last collection, or when reclaim_objects() asked.
Every case fixture runs with a collection after each case, and `boot_ds.exe
-run 60 -gcevery` collects on every tick of a booted Dead Souls (about 3700
collections a minute) and ends in the same state as without.

Garbage inside an evaluation (P1 #9, `gc.star` collect_young()): until
then one evaluation's garbage lived until it ended, so a loop of 40,000
`a += ({ x })` (quadratic garbage) killed the driver. A collection can't
simply run mid-evaluation, because native Star frames below the running
LPC (an efun calling back into it, the loader running create(), the verb
parser between applies) hold handles in locals no root reaches. Instead
every run of the interpreter loop (`vm.star` execute()) gets a serial, every
array/mapping/function/class/buffer slot records the serial it was
allocated under, and at the loop's safe points (the top of `run_frames()`
between calls and returns, and loop back edges) a collection frees only
unreachable slots at least as young as the running loop. A native frame
below it was suspended before the loop began, so it can only hold older
handles, and older slots are never freed there; their contents are scanned
as roots instead (shallowly, every time, so no write barrier is needed for
a young value stored into an old array). Cells are all roots and objects
aren't freed, as before. Collections come when as many values have been
allocated since the last one as were live after it, with a floor of 1M
values (about 16 MB); the evaluation's time limit is extended by the time
they take. `run_cases -gcstress` (and `run_cases_test.ps1 -GcStress`,
`boot_ds -gcstress`) collects at every safe point after any allocation.

Considered and not taken: reference counts (every Value copy touches a
count, and cycles still need a collector; they'd also allow in-place
appends, the one thing this doesn't give); collecting at safe points with
everything native code holds pinned on a VM-visible list (correct only if
every native path into LPC pins exactly right: about 100 call sites of the
apply/call_value/load family, the verb parser among them, and a miss is a
silent use-after-free); collecting only in
loops entered from audited top-level paths (the verb parser runs most
commands' applies from native code, so it would have needed the same
audit).

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
  arrays, mappings, math, files, time, save/restore format. Done
  2026-10-23, see the log.
- **M5: object model.** Master and simul_efun loading, load/clone/
  destruct, environment/move, add_action and command dispatch,
  call_outs, heart beats, reset and clean_up. Done 2026-10-25, see the
  log.
- **M6: network + boot (MVP).** Star compiler server-socket builtins, the
  telnet layer, connections and sessions, the driver's main loop, login.
  It turned out to need the verb parser too (every Dead Souls object calls
  parse_init(), and entering the game runs verbs), so the parser moved
  here from M7. Done 2026-10-25, see the log.
- **M7: the rest.** `ed` and the LPC socket efuns (both done 2026-10-25),
  the HavokOS-only extensions that need no outside library (done
  2026-10-26; see the log), SQLite (`db_*`, done 2026-10-26), then MCCP,
  the HTTP port and WebSockets (`http_respond`, the last stub), TLS, and
  LPC buffers (all done 2026-10-26, P1 #8): the Star VM now runs every efun
  the reference implements, and the boot test's stub list is empty.

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
| `efuns.star` | efun dispatch, the M3 subset, `get_config()` |
| `efuns_str.star` | string efuns (strsrch, replace_string, pluralize, query_num, crc32, regexp/reg_assoc/crypt glue, ...) |
| `efuns_arr.star` | array/mapping/math efuns, the VM's random generator |
| `efuns_file.star` | time, file and save_object/restore_object efuns, master valid_read/valid_write |
| `sprintf.star`, `sscanf.star` | Pike's sprintf (with %O) and array_sscanf, as the reference uses them |
| `numfmt.star` | exact double -> decimal formatting (%f/%e/%g, the save format) |
| `regex.star` | the PCRE subset behind regexp()/reg_assoc(), and with capturing groups (`rx_exec()`) and `\<`/`\>` the line editor's (M7) |
| `md5.star` | MD5 and MD5-crypt for crypt() |
| `tcolour.star` | terminal_colour() |
| `saveformat.star` | save_variable/restore_variable and the .o format |
| `buf.star` | `Buf`, the in-place byte buffer every string-building efun appends through (constraint #10) |
| `efun_table.star` | the efun dispatch codes the VM implements, in ranges per file |
| `efun_names.star` | generated: the reference's implemented efuns and every FluffOS efun name |
| `tools/ref_efun_names.pike` | generates `efun_names.star` from the live reference |
| `tools/run_cases.star` | Star side of the M3 case comparison |
| `tools/ref_cases.pike` | reference side: runs run_tests.pike cases (and `-extra` edge cases) through the live driver |
| `tests/run_cases_test.ps1` | M3-M7 regression: every `fixtures/cases/*.expected.txt` (see the M4-M7 logs for what each holds) |
| `tools/gen_contrib_cases.py` | generates `m4_contrib_cases.txt` from the reference's `tests/contrib_golden.txt` |
| `tools/compile_sweep.star`, `tools/ref_compile_sweep.pike` | M3 compile sweep over DS3.9, both sides: which files compile, and their inheritance tables |
| `tests/run_compile_sweep_test.ps1` | M3 regression: all 2378 DS3.9 files' compile results and table hashes against `fixtures/ds39_compile.expected.txt` (frozen reference output), about 21 s |
| `objects.star` | the object model's machinery: applies, top-level evaluations and the evaluation limit, error_handler() reports, destruct, environments and init(), livings, shadows, add_action dispatch, messages, call_outs, heart beats, reset/clean_up, replace_program(), get_garbage(), the driver's timer step |
| `efuns_obj.star` | the object-model efuns (codes 200-299) and the case runner's test_* driver hooks (900-999) |
| `gc.star` | the garbage collector (between evaluations, and inside them since P1 #9), and the marking get_garbage() uses |
| `tools/gen_gc_cases.py` | generates `gc_cases.txt` (P1 #9: collections inside evaluations; what each case covers is in its header) |
| `tools/boot_ds.star`, `tools/ref_boot.pike` | M5 boot comparison, both sides: boot a mudlib from its mudos.cfg through every preload and print the live objects (privs, environment, heart beat, living) and counts; `boot_ds.exe -unimplemented` lists the efuns the reference side stubs, `-run N` soaks the booted driver, `-wait N -eval f.lpc` runs a script on it (M6) |
| `tests/run_boot_test.ps1` | M5 regression: DS3.9's boot on a scratch copy of the mudlib against `fixtures/ds39_boot.expected.txt` (frozen reference output, made with `fixtures/ds39_boot_stubs.txt`), about 3 s |
| `conn.star` | `Conn`: one connection's state (telnet options, buffers, pending input_to) |
| `net.star` | the network layer: telnet negotiation and subnegotiations (TTYPE/MTTS, NAWS, NEW-ENVIRON, MSSP, GMCP, MSDP, MSP, ZMP, MXP, EOR, CHARSET), lines, input_to/get_char, commands and prompts, sessions through the master's connect(), exec, snoop, the main loop's net_poll() |
| `efuns_net.star` | the efuns of connections (codes 300-349) and the case runner's test_tel_* hooks |
| `telcodec.star` | the `~xx` printable form telnet bytes cross LPC strings and transcripts in |
| `vpdata.star`, `verbparse.star`, `verbmatch.star` | the verb parser: its data, the registry efuns (codes 350-355), parse_sentence()/parse_my_rules() |
| `config.star` | mudos.cfg reading and VM setup, shared by the driver and boot_ds |
| `boot.star` | **the driver**: `tools/havokos.exe <mudos.cfg> [port]` boots the mudlib and serves telnet |
| `tools/gen_m6_cases.py` | generates `m6_cases.txt` (telnet, sessions, input_to, exec, snoop, parser registry) |
| `tools/gen_m6_parser_cases.py` | generates `m6_parser_cases.txt` from the reference's own `pike/tests/parser_cases.txt` |
| `tools/ref_eval.pike` | reference side of `boot_ds.exe -eval` (havok/eval.pike with the boot test's stubs) |
| `tests/run_parser_transcript_test.ps1` | M6 regression: the reference's Dead Souls parser script (50 commands) on both drivers, against `fixtures/ds39_parser_transcript.expected.txt` |
| `tools/telnet_script.star`, `tools/ref_serve.pike` | M6 login comparison: a scripted telnet client whose transcript is anchored by content (and, since P1 #8, shows an MCCP stream inflated), and the reference serving telnet with the boot test's stubs and `havok mccp : 0` (or MCCP on, for the MCCP login) |
| `tests/run_login_test.ps1` | M6 regression: a new character and a returning one, over real sockets, against `fixtures/ds39_login_{new,again}.expected.txt`; since M7 also a session in Dead Souls' editor (`ds39_login_edit`), since P1 #8 a login over MCCP on a second driver with MCCP on (`ds39_login_mccp`) |
| `eddata.star` | `EdSession`: one line editor session's state (`Vm.eds`, addressed from `ObjSlot.ed`) |
| `ed.star` | the line editor (M7): `ed.pike`'s engine method for method, EdIO's file access through the master, ed_start()/ed_cmd()/query_ed_mode()/in_edit() (codes 370-379), the buffer rescue on destruct |
| `tools/gen_m7_cases.py` | generates `m7_cases.txt` (the reference's `ed_tests()` verbatim, and this port's editor edge cases) |
| `sockdata.star` | `LSock`: one LPC socket's state (`Vm.socks`, one row per socket number ever handed out), and `PendingResolve` |
| `sockets.star` | the LPC socket efuns (codes 380-399): `sockets.pike` method for method, resolve(), dump_file_descriptors(), the events net_poll() hands over (sock_ready()), closing on destruct, the test_sock_pump()/test_config() hooks |
| `tools/gen_m7_sock_cases.py` | generates `m7_sock_cases.txt` (streams, MUD mode, datagrams, release/acquire, failing connects, resolve(), over loopback) |
| `json.star` | json_encode()/json_decode() (codes 400-401): Pike's Standards.JSON as the reference uses it, its layout, leniencies and error positions |
| `extdata.star` | the extensions' rows: `PendingFind`, `WatchDir`/`Watcher`, `QuotaUse`/`QuotaLimits`, `DepEntry`, `ProfRec`/`SampleRec` |
| `ext.star` | the other HavokOS-only extensions (codes 402-416): astar_path(), find_files() (answered from net_poll()), file watching (driver_tick()), resource quotas (hooked into cloning, call_outs and heart beats), stale_programs()/dependents() (stamps and stats recorded by vm.star compile_tokens()), function_profile() and the sampling profiler (frame entry/return and the evaluation-limit tick), cache_stats()/malloc_status()/memory_summary(), and the hooks their cases need (920-927) |
| `tools/gen_m7_ext_cases.py` | generates `m7_ext_cases.txt` (the reference's own extension tests ported through the hooks, JSON edge cases, larger A* mazes) |
| `sqldb.star` | the SQLite efuns (codes 420-423, P1 #7): `sqldb.pike` method for method, the handles in `Vm.dbs` (rows: `extdata.star` SqlDb), closing on destruct |
| `tools/gen_m7_db_cases.py` | generates `m7_db_cases.txt` (the reference's own sqlite_tests() ported, ownership through a helper object, this port's edge cases) |
| `zlib.star` | MCCP's zlib stream (P1 #8): a deflate compressor (LZ77 with hash chains and lazy matching; each block dynamic, fixed or stored, whichever is smallest; every write sync-flushed), and an inflater for the tests |
| `tools/zlib_check.star`, `tools/ref_zlib.pike` | the zlib check, both sides: compress with zlib.star / inflate with Pike's Gz, and the reverse |
| `tests/run_zlib_test.ps1` | 69 round trips over a varied corpus (DS source, a binary, random bytes, long runs, an empty and a one-line file) in chunk sizes from 1 byte to whole, both directions |
| `netdata.star` | P1 #8's rows: `TlsLink`, `HttpConn`/`HttpPending`, `TlsAccept`, the case runner's `TestCli`/`TestSrv` |
| `tls.star` | TLS (P1 #8): tls.pike's contexts (configured files, or a self-signed certificate made once in `runtime/tls/selfsigned.pem`), sessions over OpenSSL memory BIOs that the driver's one poll feeds |
| `http.star` | the HTTP port (P1 #8): http.pike and the Pike Request/WebSocket behavior beneath it, request parsing, the reply's exact bytes, keep-alive, timeouts, http_respond() (code 430), the WebSocket upgrade |
| `sha1.star` | SHA-1 and Pike-lenient base64 for the WebSocket handshake |
| `mimetypes.star` | generated by `tools/ref_mime_types.pike`: Pike's extension -> media type table (1224 extensions) |
| `buffers.star` | LPC buffers (P1 #8): allocate_buffer(), read_buffer(), write_buffer() (codes 440-442); the type itself is in value.star/vm.star |
| `tools/gen_m7_net_cases.py` | generates `m7_net_cases.txt` (MCCP, the HTTP port, WebSockets, TLS) |
| `tools/ref_net_hooks.pike` | the reference's side of the network hooks (raw clients, listeners), which `ref_cases.pike` delegates to |
| `tests/fixtures/netlib/` | laid over a scratch copy of the minilib for the network cases: a `/test/web.c` that is a superset of the reference's |
| `tools/gen_m7_buf_cases.py` | writes `m7_buf.expected.txt` directly: the buffer cases, their expected column hand-written from Dead Souls' docs (no oracle) |
| `tests/run_dsweb_test.ps1` | Dead Souls' own web server on the Star driver: six pages (three of them images) must come back byte for byte |

Build the tools with the **release** compiler (`target/release/star.exe
build ...`), and since M6 every tool that imports the efuns or the network
layer (run_cases, boot_ds, compile_sweep, the driver, telnet_script) with
`-l ws2_32`. Since P1 #7 the ones that import the efuns (all but
telnet_script) also link SQLite, `-L sqlite/lib/x64 -l sqlite3` from the
repository root, and need `sqlite3.dll` beside them at run time
(`tools/sqlite3.dll`; see `sqlite/README.md`); since P1 #8 OpenSSL too,
`-L openssl/lib/x64 -l ssl -l crypto`, with `libssl-3-x64.dll` and
`libcrypto-3-x64.dll` beside them (see `openssl/README.md`). The `star` on `PATH` on this machine was a stale Sep 8
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
   included (`1e+010`). Where a format shows more digits the difference is
   visible: the reference's `sprintf("%.10f", 0.1)` is "0.1000000015" and its
   `save_variable(123456.789)` is "123457.000000" (Pike limits a 32-bit
   float to 6 significant digits there); here they are "0.1000000000" and
   "123456.789000". `numfmt.star` formats the exact double, with MSVC's tie
   rule (half away from zero), so values exact in both widths print
   identically, and the M4 fixtures use only those.
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
   bignums. That covers parsing too: `to_int()`/`sscanf("%d")` of a 20-digit
   number wrap, where the reference returns a bignum.
7. **Strings can't contain a NUL byte** (`str` is NUL-terminated, as
   FluffOS strings are too). `sprintf("%c", 0)` is "" rather than a
   one-character string, and `%Nc` padding bytes of 0 truncate the result.
   The fixtures avoid NUL bytes.
8. **map()/filter() over a string work**, as in FluffOS. The reference's
   string branch fails with "Bad argument 1." for any function, apparently a
   bug in it, so the fixtures leave strings out.
9. **Mappings iterate in insertion order** (`keys()`, `values()`, foreach,
   `save_variable()`). The reference iterates in Pike's hash order, and
   FluffOS in its own; LPC promises no order. It shows where mudlib code
   builds a sentence from a mapping: DS3.9's `item_list(({ "a sword", "a
   shield" }))` is "a sword and a shield" here and "a shield and a sword" in
   the reference. %O output sorts its keys, so that one matches.

10. **replace_program() really switches the program** (`objects.star`).
    FluffOS swaps the object's program for the inherited one when the
    evaluation ends. The reference can't change a Pike object's program, so
    it looks functions up through a view of the inherited program, and code
    inside that program still reaches functions the replaced program
    overrode. Here the object switches, keeping the inherited program's
    variables. Dead Souls only replaces programs that define nothing but
    create(), where the two can't differ.
11. **functionp() reports FP_OWNER_DESTED** (0x20) for an efun, simul_efun
    or bound function pointer whose owner was destructed, as FluffOS does.
    The reference never sets it: its check is `owner && ...`, and a
    destructed Pike object reads as false. Dead Souls tests the flag before
    calling stored function pointers (guard.c, seasons.c, access.c, the
    master), so the FluffOS answer is what it expects. A plain local
    function or closure of a destructed object reads as 0 on both, as in
    Pike.
12. **Inheritance queries follow the object's own program** (inherits(),
    inherit_list(), deep_inherit_list(), function_exists()). The reference
    reads the *latest* compile of each inherited path, so an old clone
    whose parent was since recompiled reports the new parent's inherits;
    here it reports the program it actually runs, as FluffOS does. The
    table's own cases, which only query fresh objects, agree.

13. **MCCP's compressed bytes are this port's own** (`net.star`,
    `zlib.star`; until P1 #8 there was no MCCP at all). COMPRESS2 is offered
    and accepted as in the reference (unless `havok mccp : 0`), but the
    stream comes from `zlib.star`'s compressor, not zlib, and a pass's writes
    share one sync flush where the reference flushes each write, so the
    bytes on the wire differ while what the client inflates is the same
    (the MCCP cases and the MCCP login compare inflated text; the zlib test
    checks the compressor against Pike's real zlib). On a WebSocket carrying
    telnet each frame is compressed and flushed on its own, as there.
14. **A UTF-8 connection passes text through unchanged** (`net.star`). LPC
    strings are byte strings here (`value.star`), not Pike's wide strings,
    so after CHARSET UTF-8 is accepted a client's UTF-8 arrives as its bytes
    and the mudlib's text goes out as it is; the reference decodes input to
    wide strings and re-encodes Latin-1 output as UTF-8. The negotiation
    itself, and `client_info()["utf8"]`, are the reference's.

15. **The line editor's patterns are regex.star's PCRE subset** (`ed.star`).
    The reference compiles them with full PCRE; here they go through the
    same engine as regexp() (M4), extended with capturing groups for `\1`
    and ed's `\<`/`\>` word anchors, so a backreference, lookaround or
    inline option is "Bad regular expression" where the reference accepts
    it. The ed help page only promises `. * + ? [a-z] ^ $ ( ) |`, all of
    which match. Also: a pattern holding a backslash followed by a raw
    byte 1 or 2 reads as a word anchor (that is how `\<`/`\>` reach the
    engine), and numbers in commands are capped rather than bignums, which
    changes no answer short of a line number past 10^12.

Reproduced on purpose, though it reads like a slip: the reference sends a
`\r\n` in text as a bare `\n` (and a lone `\n` as `\r\n`), because its
`replace(s, ({ "\r\n", "\n" }), ({ "\n", "\r\n" }))` swaps the two where
its comment says it leaves `\r\n` alone. `net.star` conn_send() does the
same, and an M6 case pins it.

Not in M4: `sprintf`'s table mode (`#`) and its `$ ~ @ / ^` modifiers
(errors, so the format comes back; DS3.9 uses none), the reference's
asynchronous save writer and SQLite save store (save_object() writes
synchronously through a renamed temp file), and its HavokOS-only
extensions (`json_encode`/`json_decode`, `find_files`, `watch_path`,
`astar_path`, quotas), which DS3.9 doesn't call.

16. **TLS is OpenSSL's** (`tls.star`; until P1 #8 the TLS socket modes
    couldn't be used at all). Telnet over TLS, HTTPS and the STREAM_TLS
    modes behave as the reference's, but the handshake is OpenSSL 3.2's:
    the protocol versions and cipher suites on offer are its defaults (TLS
    1.3 and 1.2), not Pike 8.0's, and the self-signed certificate made when
    none is configured is OpenSSL's (RSA 2048, SHA-256, ten years, the
    mud's name as common name, the reference's PEM layout), kept in this
    port's own `runtime/tls/` beside its tools.
17. **Names resolve through the system resolver, to IPv4** (`sockets.star`).
    resolve() calls the compiler's blocking `host_lookup()` (the reference
    uses Pike's asynchronous DNS client), and answers a numeric address
    with itself as the name instead of making a reverse lookup, which on
    Windows blocks for about five seconds when it fails (the reference
    answers 127.0.0.1 with the local network's reverse name). Connecting by
    name is IPv4 only: the reference tries `localhost` as ::1 first, so its
    connect to an IPv4 listener there is refused. Dead Souls resolves and
    connects only to its intermud routers' and web hosts' names; a name that
    doesn't resolve fails as on the reference (EECONNECT, left CONNECTING).
    Also, from #7: a stream read or datagram holding a NUL byte reaches LPC
    cut short at it.

18. **json_decode() stays in bytes** (`json.star`). The reference decodes
    UTF-8 text to a Pike wide string before parsing, and its strings come
    out wide. Here text that is valid UTF-8 with nothing above U+00FF is
    decoded to its Latin-1 bytes, which is exactly the reference's answer;
    text holding anything above U+00FF is parsed as the bytes it is (its
    strings stay UTF-8, error positions count bytes), and a `\u` escape above
    U+00FF becomes UTF-8. This is deviation #14 again, for JSON; `\u0000`
    cuts a string short (#7), and integers past 64 bits wrap (#6).
19. **The status reports carry this driver's own numbers** (`ext.star`).
    cache_stats() keeps the reference's heading and line order, but there is
    no function lookup cache to count (calls resolve through per-program
    dispatch tables built at compile time) and no disk cache of programs;
    malloc_status() heads its table with the process's resident memory
    (`process_memory()`; the reference reports its Pike heap) and estimates
    each value table's size from what it holds, since Star has no allocator
    to ask; memory_info() is that resident memory too. Dead Souls only
    prints these.
20. **find_files() crawls at the call** (`ext.star`). The reference crawls
    in a thread and answers by call_out; Star has no threads the VM could
    share, so the directory walk runs inside the efun and only the answer
    waits for the driver's next pass, which keeps the callback out of the
    caller's evaluation as the reference does. A crawl of the whole mudlib
    holds up the driver for as long as it takes. There is no save store
    (`havok save store`, off by default in the reference), so stored saves
    are never merged in.
21. **Profiling needs no recompile, and counts every efun call**
    (`ext.star`). With `havok profiling` the reference instruments the code
    it emits, so only programs compiled after it was turned on are profiled
    and only their efun calls are counted for opcprof(); here the
    interpreter's frame entry and return do it, so every named function
    called while it is on is profiled and every efun call counted.

22. **SQLite is 3.54.1, and values come back typed** (`sqldb.star`). The
    reference's Pike 8.0 bundles SQLite 3.6.0 (2008), and its module hands
    every value over as text, so the reference wraps a SELECT's columns in
    quote() and parses the literals back; here the same wrapper selects the
    columns themselves and reads each value's type through the C API. So:
    SQL 3.6.0 lacks works here (multi-row VALUES, VALUES and WITH as
    statements, RETURNING, window functions, ...); errors raised while a
    statement runs carry SQLite's real message ("UNIQUE constraint failed:
    t.a", "integer overflow") where 3.6.0 says "SQL logic error or missing
    database", and a statement cut off inside a comment is "incomplete
    input" rather than "near ...: syntax error"; DELETE without WHERE counts
    its changes (3.6.0's truncation reported 0); PRAGMA answers are
    today's (table_info upper-cases declared types and reports notnull as
    1, not 99; index_list has five columns); an unaliased `'x' || 'y'` is
    named that, not "x"; an infinity stays one (the reference's quote() of
    it is "Inf", which it parses as 0.0); and integers past 2^31 bind (the
    reference's 32-bit Pike makes them bignums it can't bind). Text is bound
    and read as its bytes (#14): UTF-8 text is stored as in the reference,
    which encodes its wide strings, but Latin-1 bytes are stored as
    themselves rather than as UTF-8, and a blob holding a NUL byte reaches
    LPC cut short at it (#7). The reference's quirks that don't depend on
    the library are kept: the placeholder renumbering (`select ?, ?3, ?`
    leaves ?2 unbound), "Trailing query data" refusals, the SELECT wrapper's
    column names ("a", "a:1") and error positions, and the columns after
    each kind of statement and error. Dead Souls doesn't call these efuns.

23. **The HTTP port's few differences** (`http.star`). Everything a client
    or http_request() can see follows the reference and Pike's server
    beneath it byte for byte, quirks included, except: the Server header
    names this driver (`HavokOS/0.2 (Star)`, where the reference's names
    Pike's HTTP module); a malformed %-escape in the query or an urlencoded
    body, which makes Pike's parser throw inside its event loop and leaves
    the client unanswered for good, closes the connection; a `%uXXXX`
    escape above U+00FF becomes UTF-8 bytes (#14); an answer's extra headers
    go out in the mapping's order, where the reference's follow Pike's hash
    order (which changes from run to run: the cases sort them); and a body
    over the 1 MB request limit arrives empty rather than as whatever Pike's
    buffer read gives.
24. **A STREAM_TLS connect that gets no TLS back is closed** (`sockets.star`),
    with the close callback. The reference reports nothing to LPC and
    leaves the socket open for good (probed: no event and still open after
    two seconds), so its case is left out of the fixture.
25. **There are LPC buffers, and the binary socket modes deliver them**
    (`buffers.star`, `sockets.star`). The reference has no buffer type
    (bufferp() is always 0; read_buffer() and write_buffer() don't exist),
    and its STREAM_BINARY/DATAGRAM_BINARY sockets deliver strings. Dead
    Souls is written for FluffOS's: its HTTP service is a STREAM_BINARY
    socket that reads requests with read_buffer(), and its file object
    serves pages as buffers -- so on the reference every page request fails.
    Here buffers follow Dead Souls' own documentation of FluffOS's
    (doc/efun/buffers, doc/lpc/types/buffer), the binary modes deliver
    buffers and socket_write() takes them, and Dead Souls' web server works
    (`tests/run_dsweb_test.ps1`). The socket cases compare what binary
    sockets deliver as the bytes it holds. With no oracle, the buffer cases'
    expected results are hand-written from the documentation, and the
    choices it leaves open are buffers.star's (fixed size, out-of-range
    index errors, `%O` as `<buffer of N bytes>`, a read from a file limited
    by `maximum byte transfer`).

## Star compiler bugs found

1. **`print`/`println` of a non-f-string `str` used it as the `printf`
   format** (fixed). `println(s)` where `s` held `%` dropped characters
   (`"%^RED%^"` printed as `"^RED^"`), and `%s` in the data segfaulted.
   For a MUD, where `%^COLOUR%^` codes and arbitrary player input get
   printed, that's a crash bug. It surfaced as a token-dump mismatch on
   DS3.9's `bank.c`/`imc2.c`. Fixed in `src/codegen/builtins.rs`
   (`emit_print_like` now always formats through a constant `"%s"`), with
   regression test `tests/frontend_print_percent.rs`.
2. **Capitalized `extern "C"` names** (constraint #7): filed in M1, fixed in
   P1 #8 (HavokOS P2 #1). The parser reads `Name(args)` with an uppercase
   name as a struct literal, so `GetTickCount()` became the construction of
   a struct that doesn't exist, and since M7 `Checker::check_extern_fn`
   rejected any uppercase extern. The checker now records every extern name
   in pass 1 (`Checker::extern_fn_decls`) and checks a struct literal naming
   one (no struct of that name, no turbofish) as the call; an extern named
   like a struct is the error left, since that struct's literal always
   wins. The parser can't decide it: an extern may be declared after its
   first call, or in another module. Fix in `src/types/expr.rs` and
   `src/types/mod.rs`; tests in `tests/frontend_ffi_extern_uppercase.rs`
   (Win32's `GetTickCount`/`Sleep`, C helpers, an imported module, the
   struct collision), and `tests/frontend_ffi_extern_c.rs`'s rejection test
   became an acceptance test.
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

6. **Math builtins narrowed `f64` to `f32`** (fixed, M4). `sqrt`, `pow`,
   `floor`, `ceil`, `sin` ... `log10` were typed `Float` and lowered through
   the `.f32` LLVM intrinsics whatever their argument, so an `f64` came back
   good to about 7 digits, and assigning it to an `f64` was a type error,
   which is how it surfaced in `efuns_arr.star`. Fixed in `src/types/mod.rs`
   (`math_result_ty`: an `f64` argument makes the result `F64`) and
   `src/codegen/builtins.rs` (the `.f64` intrinsics for it). Regression
   test `tests/frontend_math_f64.rs`; its four positive tests fail without
   the fix.

7. **`star check` could run forever on a densely connected program**
   (fixed, M5). The stack-budget warning (`src/types/stack_budget.rs`)
   measured each function's heaviest static call chain with a DFS that
   tracked only the current path, so a function called from two places was
   explored again down each one: a walk over every simple path of the call
   graph, exponential in it. The M5 VM's interpreter loop, efun dispatch and
   driver applies all reach one another, and checking it never finished
   (gdb showed a stack of nothing but `cumulative_footprint`). Fixed by
   computing the chains on the graph's strongly connected components
   (Tarjan, iteratively), in linear time: on an acyclic graph the same
   totals as before; a recursive group counts all its members' locals, an
   upper bound on the old answer. Regression tests in
   `tests/frontend_stack_budget_warning.rs`: a 30-layer graph of diamonds
   (2^30 paths, with the exact expected total), a 20-function recursive
   clique, and a recursive pair whose summed locals cross the budget.
8. **A statement `match` with arms of different value types built
   malformed IR** (fixed, M5). The checker typed every match after its
   first value-producing arm, so `match v: Str(f) -> self.safe_master_apply(..)
   _ -> 0` (in `Vm.boot`) became a match producing a `Value` whose join
   `phi` had an `int` flowing in, which the IR verifier refused. Now such a
   match produces no value (`void`): fine as a statement, its arms'
   discarded values released like any statement expression's, and a type
   error when used as a value or returned. Integer-shaped arms still share
   the first arm's type (an integer literal is valid in any integer `phi`,
   and code relies on `-> x as i64` beside `_ -> 0`). Fix in
   `src/types/expr.rs` (the `Expr::Match` arm), `src/types/stmt.rs` and
   `src/codegen/expr.rs`; regression tests in
   `tests/frontend_match_arm_types.rs`.

9. **Out-of-line helpers clobbered `current_label`** (fixed, M6). Every
   codegen helper that emits a whole function in the middle of an
   expression -- a list/map/set release thunk, an eq/hash helper, a
   closure body, reflect/table helpers, the par/audio pools, 16 sites in 11
   files -- opened that function's `entry:` block through `open_block` and
   never restored `Codegen::current_label`. So the first `[1, 2]` of an
   element type, or a closure literal, inside a value-producing `if`/`match`
   arm left the arm's `phi` naming `entry` as its predecessor, and the IR
   verifier refused the build: `let x = if c: [1, 2] else: [3]` didn't
   compile. It surfaced in `tcp_wait`'s codegen, which builds its `Bytes`
   result the same way. Each site now saves and restores the label beside
   `ir`; regression tests in `tests/frontend_out_of_line_current_label.rs`
   (the list and closure cases fail on the old compiler).

10. **Float `!=` was ordered** (fixed, P1 #6). `!=` on `f32`/`f64` lowered
    to LLVM's `fcmp one`, false when either side is NaN, so `nan != nan`
    was false and the `x != x` NaN test never fired. `fmt_float()` tests
    `v != v` for NaN and `x - x != 0.0` for infinity, so printing an infinite
    float looped forever: `json_decode("1e400")`, or any LPC float overflow
    that got printed, hung the whole driver. Fixed in
    `src/codegen/vector_math.rs` (`fcmp une`); regression tests
    `tests/frontend_float_ne_nan.rs`, all five failing on the old compiler.
11. **A parameter spelled like a temporary broke the build** (fixed, P1
    #6). Parameters reached the IR under their own names (`i64 %t0`), and
    temporaries are `%t<N>`, so `fn sample_compile(mut self, t0: i64)`
    defined `%t0` twice and clang rejected the module. Parameters are now
    `%arg.<name>` (`src/codegen/stmt.rs`); regression tests
    `tests/frontend_param_temp_names.rs`, and six existing IR-shape tests
    updated to the new spelling.

12. **A null `str` reached C as a null pointer** (fixed, P1 #7). A `str`
    holding its zero value (a field never assigned) is a null pointer, and
    both `extern "C"` call paths (`Codegen::emit_extern_call`, and the
    `fnval_` thunk for a call through a function value) forwarded it as is,
    so C saw "no string" where Star reads "": a `strlen`-style callee
    crashed, and `sqlite3_bind_text` would have bound NULL. Every `str`
    builtin already normalized such a value to the shared empty string
    (`emit_str_or_empty`); both extern paths now do too. Regression tests
    `tests/frontend_ffi_extern_empty_str.rs` (all three fail on the old
    compiler; a literal "" and `str_from_bytes` of an empty `Bytes` were
    never null, so only a zero-valued field shows it).
13. **`file_read_line` called an undeclared `@fgetc`** (fixed, P1 #7
    round). Not found here, but it failed five tests in every full-suite
    run since M1 (`todo.md`'s P0): the `declare` had gone missing from
    `Codegen::emit_builtins` while `RESERVED_RUNTIME_SYMBOLS` still listed
    `fgetc` as always declared. The five existing tests are its regression
    tests.

New compiler surface in P1 #8 (the rest of M7), not bugs:
`ptr_to_bytes(p, n)` and `ptr_write_bytes(dst, b, off, n)` in
`src/codegen/ffi_bytes.rs`: binary data between C memory and `Bytes`, the
binary twin of `ptr_to_str` -- what OpenSSL's `SSL_read`/`SSL_write`/
`BIO_read`/`BIO_write` over memory BIOs need, and the general answer to
constraint #9. Neither hands out a pointer into a `Bytes`' own storage
(copy-on-write would make that unsafe). Tested by
`tests/frontend_ffi_bytes.rs` (NUL bytes both ways, the clamping, both null
aborts, an in-memory TLS 1.3 handshake through the OpenSSL DLLs); the
Linux IR is verified and compiled to an object.

New compiler surface in P1 #7 (the SQLite efuns), not bugs:
`sqlite_open(path)` and `sqlite_prepare(db, sql)` in `src/codegen/sqlite.rs`,
the two SQLite calls that answer through an out-parameter (constraint #9);
the rest of the API is `extern "C"` in `sqldb.star`. Declared on first use,
so only programs that call them link SQLite. Tested by
`tests/frontend_sqlite.rs` against the DLL in `sqlite/lib/x64`; the Linux
IR is verified and compiled to an object, not linked and run
(`docs/cross_platform_scope.md`).

New compiler surface in P1 #6 (the HavokOS-only extensions), not bugs:
`file_set_mtime(path, t)` in `src/codegen/fs.rs` (the dependency cases age
files as the reference's tests do with `System.utime`; `_utime64`/`utime`
take a struct) and `process_memory()` in `src/codegen/procmem.rs` (resident
bytes, for memory_info() and malloc_status(); Windows answers through a
struct out-parameter). Tested by `tests/frontend_fs.rs` and
`tests/frontend_process_memory.rs`; Linux arms IR/object-verified only
(`docs/cross_platform_scope.md`).

New compiler surface in M7 (the LPC sockets), not bugs:
`src/codegen/net_sock.rs` -- `tcp_listen_at` (a chosen address),
`tcp_connect_start` and `tcp_sock_error` (a connect that doesn't block the
driver, its outcome from write readiness and `SO_ERROR`), `tcp_wait_io`
(`tcp_wait` with per-handle read/write interest, the same poll body),
`tcp_local_ip`/`tcp_peer_port` (both ends' addresses), `udp_open`/
`udp_send_to`/`udp_recv_from` (datagrams, each received one behind a 6-byte
sender header since a builtin can't return a pair) and `host_lookup`
(`gethostbyname`). Tested by `tests/frontend_net_sock.rs`; Linux arm
IR/object-verified only (`docs/cross_platform_scope.md`).

New compiler surface in M6, not bugs: the server-socket builtins
(`tcp_listen`, `tcp_accept`, `tcp_wait`, `tcp_recv_bytes`,
`tcp_send_bytes`, `tcp_peer_ip`, `tcp_local_port`) and `host_name()` in
`src/codegen/net_server.rs` (`tests/frontend_net_server.rs`), and
`clock_us()` in `src/codegen/clock.rs` (constraints #16-#20).

New compiler surface, not a bug: the `clock_ms()` builtin of constraint
#14 (`src/codegen/clock.rs`, `tests/frontend_clock.rs`; its Linux arm is
IR/object-verified only, like the filesystem builtins). Also the filesystem
and calendar builtins of
constraint #9 (`src/codegen/fs.rs`, tested by `tests/frontend_fs.rs`).
Their Linux arm emits IR that compiles to an object for
`x86_64-unknown-linux-gnu`, but hasn't been linked and run on the devbox,
which wasn't reachable this round.

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

### 2026-10-23: M4 efuns

**M4 done.** The efun library, one file per area (see the file table), is
checked against the live Pike driver four ways, all in
`tests/run_cases_test.ps1`:
- **The reference's own case table:** its 20 efun-library cases
  (`m4_selection.txt`: sscanf, explode/implode, strsrch, replace_string,
  pluralize, crypt, typeof, match_path, save/restore_variable, the
  save_object round trip, file efuns on a denied path). The two "efun
  defaults" cases lean on call_out/query_privs/environment and wait for M5.
- **204 edge cases of this port's own** (`m4_cases.txt`). The reference's
  `sprintf()` and `sscanf()` are Pike's own built-ins, so their rules were
  probed against Pike rather than taken from FluffOS or C (see
  `sprintf.star`/`sscanf.star`'s headers). Pike is strictly typed (`%f` of
  an int fails, so the format comes back), its float precision defaults to
  3, `%:N` sets width *and* precision, `%Nc` writes N bytes, `%s` before a
  `%d` stops at the first digit or `-`. The cases also cover every file
  efun on a scratch directory of the test mudlib, the .o format with
  nosave/static/inherited (and private) variables, and all ~100 of the
  reference's FluffOS-derived `terminal_colour` cases in one run of its
  `/test/tc_runner`.
- **740 golden values** of `query_num()`/`pluralize()` from the reference's
  `tests/contrib_golden.txt` (FluffOS output), 25 to a case.
- **The real mudlib:** 36 cases calling Dead Souls 3.9's own simul_efuns
  (`m4_ds_cases.txt`: center, wrap, convert_string, item_list,
  conjunction, cardinal, comma, ordinal, absolute_path, morse, ...), with
  both drivers booted on DS3.9 as far as its simul_efun object
  (`run_cases.exe -ds`, `ref_cases.pike -ds`). Loading that object needed
  `get_config()`, which M4 added with the reference's table.

Booting now loads the master after the simul_efun object (as the
reference does), so the file efuns run its valid_read/valid_write. Its
other boot duties come with the object model.

Probes and the first runs found:
- Two Star limitations, filed: constraint #9 (the FFI can't read a C
  struct, so M4 added filesystem/calendar builtins to the compiler,
  `src/codegen/fs.rs`, `tests/frontend_fs.rs`) and #12 (float literals are
  single precision, `todo.md` HavokOS P2 #3).
- One Star compiler bug, fixed (#6: math builtins narrowed `f64`).
- One M3 bug in this port, fixed: the VM's int operators trapped on
  overflow and aborted the driver (constraint #11).
- One performance trap, worked around (constraint #10, `buf.star`).
- Four new deliberate deviations (#7-#9, and #3's float-printing note).

Speed, measured end to end against the reference on the same cases (its
times include about 1 s of boot): 20k sprintf calls with `%O` 0.45 s
(1.2 s), replace_string on 90 KB twenty times 0.16 s (1.0 s), 20k sscanf
calls 0.19 s (1.1 s), terminal_colour wrapping 0.10 s (1.0 s). One slow
spot, inherited from M3: `a += ({ x })` 20k times, 3.3 s (see "Value
representation").

**Next: M5, the object model.**

### 2026-10-25: M5 object model

**M5 done.** The object model (`objects.star`, `efuns_obj.star`, `gc.star`,
plus the per-object state, loading and boot in `vm.star`) is checked against
the live Pike driver three ways:
- **The reference's own case table:** the 20 object-model cases the M3 and
  M4 selections left out (`m5_selection.txt`): inherits loaded as objects,
  inherits()/deep_inherit_list() through rebuilt and destructed chains,
  destruct of the master and the simul_efun object (each reloads first),
  code running on after its object destructs itself, call_stack(), origin(),
  move_object(), efun argument defaults, get_garbage() (with virtual
  objects), this_player() destructed mid-command and kept across create().
- **42 cases of this port's own** (`m5_cases.txt`), whose expected values
  are whatever the reference returns. They port run_tests.pike's Pike-level
  driver tests (call_out ownership and find/remove, find_living, lazy
  resets, clean_up and its inherited flag, heart beat intervals and slots,
  the evaluation limit) through `test_*` driver hooks both runners provide
  as efuns (ref_cases.pike installs them in a subclass of the reference's
  efun table), and cover init() order on moves, the three add_action flags,
  catch-all verbs and notify_fail, remove_action/commands(), present()
  (including Pike sscanf's "red sword 2"), inventories, destruct moving
  inventory out through move_or_destruct(), shadows, every message efun,
  call_out order with arguments and errors, origin() in a call_out,
  replace_program(), bind(), privs, children(), fetch_variable() and
  references to destructed objects. Helper objects are written to
  `/test/tmp_m5_*.c` by the first case and removed by the last.
- **The real mudlib:** Dead Souls 3.9 boots all the way on both drivers
  (simul_efun, master, epilog() and all 43 preloads; `tools/boot_ds.star`,
  `tools/ref_boot.pike`, `tests/run_boot_test.ps1`): the same 162 live
  objects with the same privs, environments, heart beats and living flags,
  the same 42 pending call_outs, and the same files written into the
  mudlib, whose contents differ only in mapping order (deviation #9) and
  one boot timestamp. The reference stubs the 80 efuns the Star VM doesn't
  have yet (the verb parser, ed, sockets, the network; `boot_ds.exe
  -unimplemented`) with its own "not implemented" error, so both fail the
  same preloads (`/daemon/soul`, `/lib/player` and a few others call
  parse_init()). The Star boot takes about 2 s, the reference's 8 s.

Every earlier fixture still passes, now with a garbage collection after each
case, and the M1-M3 token, AST and compile sweeps still match. A 60-second
soak of the booted mudlib (`boot_ds.exe -run 60`) runs its call_outs and heart
beats (162 objects grow to 327 as daemons load things) with no runtime
errors but the 6 socket efuns M6/M7 bring; with `-gcevery` it collects on
every tick and ends in the same state.

Design decisions, each explained at its point in the code:
- **Applies run nested interpreter loops**, like an efun calling back into
  LPC, and a top-level evaluation is a wrapper that reports an error to the
  master's error_handler() and restores the stacks. Frames a driver call
  entered are marked, so origin() only calls a call "local" between two LPC
  frames.
- **Destructed objects keep their slot** until a collection, so code still
  running in one goes on; values referring to it read as 0 (Pike's rule,
  `o == 0` but not `intp(o)`), as do plain function values of it, which
  can't run any more. The DESTRUCTED placeholder (slot 0) stands for a
  this_player() destructed mid-command.
- **Driver-side references that outlive an object** (call_out owners,
  add_action owners, bind()'s owner) carry the slot's generation.
- **Runtime errors carry source lines:** the compiler records a (pc, line,
  file) table per function, and an error snapshots the frames when it first
  reaches an interpreter loop. Dead Souls' error_handler() logs the right
  lines.
- **The evaluation limit** ticks on function entry and loop back edges
  (including a loop that jumps to itself, `for (;;);`), against the new
  `clock_ms()`.

Getting there found two Star compiler bugs, both fixed (#7, #8), and needed
one new builtin (constraint #14). Three new deliberate deviations (#10-#12).
Not in M5: connections (M6; users() and interactive() see none,
tell_user() has nowhere to send), and the slow `a += ({ x })` loop from M3,
which needs reference counts the collector doesn't keep.

**Next: M6, network + boot (MVP).**

### 2026-10-25: M6 network, boot and login

**M6 done.** The Star driver (`tools/havokos.exe <mudos.cfg> [port]`,
`boot.star`) boots Dead Souls 3.9 and serves telnet, and a player can
create a character, play and come back. Checked against the live Pike
driver five ways:
- **Telnet, connections and sessions** (`m6_cases.txt`, 30 cases,
  generated by `tools/gen_m6_cases.py`): ports of run_tests.pike's telnet
  table (the offers, TTYPE/MTTS, NAWS with IAC IAC, MSSP from
  get_mud_stats(), GA/EOR prompts, refused options, telnet_suboption(),
  GMCP/ZMP/MXP, NEW-ENVIRON, MSDP both ways, MSP, CHARSET, line endings, a
  noecho input_to), and this port's own: commands split across reads, a
  whole session through the master's connect() and logon() with an
  input_to chain and net_dead(), a refused connection, process_input(),
  notify_fail() (string and function), write_prompt(), exec() and when it's
  refused, snoop() with its loop check, get_char() and charmode,
  remove_interactive(), destructing an interactive object, say/shout/
  message()/tell_room() to interactive non-livings, and the parser
  registry (rules and their errors, synonyms, parse_remove(), forgetting a
  destructed handler, get_garbage() of a parse_init()ed clone). They run
  through `test_tel_*` hooks both case runners provide: socketless
  connections here, the reference's own Connection over loopback sockets
  in `ref_cases.pike`, bytes crossing as `~xx`.
- **The reference's own parser suite** (`pike/tests/parser_cases.txt`, 80
  cases, `m6_parser_cases.txt`): all match.
- **The DS3.9 boot** (`run_boot_test.ps1`), with the efuns this milestone
  added taken off the stub list (80 stubs became 38): the same 235 objects,
  41 clones, 70 call_outs and 25 heart beats as the reference. Before the
  parser was in, both drivers failed a SetInventory() loop on
  parse_sentence() at whichever item their mapping order reached first
  (deviation #9), so the boot could only match once the parser did.
- **The reference's Dead Souls parser script** (`run_parser_transcript_test.ps1`):
  an NPC runs 50 commands (get/drop/put/give/wield/wear/look/smile/light,
  plurals, ordinals, "all", containers, errors); all 200 transcript lines
  match, with the items of two mapping-built sentences sorted (#9).
- **A real login over sockets** (`run_login_test.ps1`): a scripted client
  (`tools/telnet_script.exe`) creates a character -- the whole dialogue,
  the news pagers, then look, inventory, who, get, read, say, score, smile,
  an unknown and a creator-only command, movement, drop/get, quit -- and
  logs back in after a wrong password. Every byte the driver sends,
  telnet negotiation included, matches the reference (`tools/ref_serve.pike`)
  except the random stats in the prompt, the calendar birthday and the
  inventory list order (#9), which are masked. The client places what it
  sends by content (where the previous expect matched), so the reference's
  separate write for each IAC GA can't shift the transcript.

All 630 cases (M3-M6) pass with a collection after each, and the M1-M3
token, AST and compile sweeps still match. A 60 s soak of the booted mudlib
with a collection on every tick (3404) has only the socket efuns' 7 errors.

Design decisions, each explained at its point in the code:
- **The socket layer is the compiler's**, not FFI (#8, #9): server
  builtins in `src/codegen/net_server.rs`, binary-safe (telnet carries NUL
  bytes) and with readiness from one `tcp_wait()` over every socket (#17),
  which is also the main loop's idle wait: the driver sleeps in the kernel
  until input arrives or its next timer is due (`next_timer_ms()`).
- **Connections are a table of `Conn` slots** addressed by index from
  `ObjSlot.conn`, and every operation re-reads the slot after any LPC call,
  since LPC can exec, close or destruct anything meanwhile. Output is
  queued and written at the end of each pass (or at once on close); the
  bytes and their order are the reference's.
- **The verb parser is in M6**, because logging in needs it: every Dead
  Souls object calls parse_init(), and entering the game runs verbs. Its
  per-parse state lives on VM stacks (`vp_ps`, `vp_its`), since an apply it
  makes can parse again; per-object parser state is ObjSlot flags plus a
  slot in `vp_infos`, so destructing (or reusing a slot) can't leave stale
  entries. A parse_init()ed object counts as referenced for get_garbage(),
  as the reference's parser tables hold it (an M6 case pins this).
- **in_edit()/query_ed_mode()** answer "no session" (0, -1): the player
  prompt calls them on every line, and no ed session can exist before M7.

Getting there found one Star compiler bug, fixed (#9), needed three pieces
of new compiler surface (server sockets, `host_name()`, `clock_us()`;
constraints #16-#20), and two new deliberate deviations (#13 no MCCP, #14
UTF-8 passthrough). Not in M6: HTTP and TLS ports, MCCP, `ed`, the socket
efuns (Dead Souls' intermud daemons fail on socket_create(), as on the
stubbed reference).

**Next: M7, the rest** (ed, sockets, HTTP/TLS, the remaining stubs).

### 2026-10-25: M7 part 1, the line editor

**`ed` done.** `ed.star` ports `havok/ed.pike` (the reference's own engine,
written from POSIX ed(1) and the Dead Souls editor primer) method for
method, with its efun glue from `efuns.pike`: EdIO's file access as the
editing object (valid_read/valid_write, make_path_absolute(),
retrieve_ed_setup()/save_ed_setup()), ed_start(), ed_cmd() (0 with no
session, the reference's deliberate difference from FluffOS), query_ed_mode()
and in_edit(), and ed_rescue() on destruct, which writes unsaved changes to
the master's get_save_file_name() with the editor as this_player(). Every
message is the reference's word for word. Checked against the live Pike
driver three ways:
- **The reference's own `ed_tests()`** (7 cases from run_tests.pike, which
  sit outside its case table, so their bodies are copied verbatim into
  `m7_cases.txt`): the recorded results equal the table's expected values.
- **26 cases of this port's own** (`m7_cases.txt`, generated by
  `tools/gen_m7_cases.py`, plus a helper object written by a first case and
  removed by a last): opening messages for every kind of file (empty,
  CRLF, no final newline, new, directory, denied, relative, nameless),
  every address form (marks, `/re/` `?re?` with wrap-round and reuse,
  offsets, `,` `;`, more than two addresses, overflowing numbers), the print
  forms and options, input modes, d/j/k/m/t with marks following the edits,
  s/// (nth and `g`, `&`, groups, `\n` splits, `%`, empty matches, word
  anchors, other delimiters, every error), g/v (commands that change the
  buffer while it runs, the ones refused inside it), undo/redo, z/Z paging,
  e/E/r/f/w/W/wq/x/q/Q, restricted sessions, the help pager, efun argument
  errors, sessions per object, rescue edge cases, and get_garbage() keeping
  an editing clone (the reference's EdIO holds it; `gc.star` counts
  `ObjSlot.ed`).
- **The real mudlib over sockets**: a third login transcript
  (`ds39_login_edit`) edits through Dead Souls' lib/editor.c as a player
  (a restricted session): `praise` in input mode, the "Command: " and
  "Help: " prompts, print, s///, numbering, the pager, a refused `e`, undo,
  `x` and the command's callback ("Praise reported!!!", which needs the
  saved file), then `bug -r`, a `!look` from inside the editor, and `!quit`
  mid-edit through lib/interactive.c's ed_cmd(".")/("x")/("Q"). All 143 lines
  match byte for byte.

The engine's two reference shapes that don't carry over directly:
- **EdError**: the reference abandons a command by throwing; here
  `ed_oops()` writes the message and sets a flag every step checks
  (`ed_stop()`), which also stops on an LPC error from a master apply, as
  the reference lets those through.
- **The session lives in a Vm table** (`Vm.eds`), not an object, because a
  command calls the master midway and only a `mut self` Vm method can
  (constraint #2). A destruct during a command ends the session, but its
  slot isn't reused until the command returns.

`regex.star` gained capturing groups (`rx_exec()`, PCRE's exec() vector,
undone on backtrack through the same stack) and ed's word anchors, reached
only through `rx_compile_ed()`; regexp()/reg_assoc() are unchanged (deviation
#15 for what ed patterns can't do). The boot stubs went from 38 to 36
(`ed_start`, `ed_cmd`); the reference's DS3.9 boot report is identical with
the shorter list, since nothing edits at boot. All 665 cases (M3-M7) pass,
the boot, parser-transcript and compile-sweep tests still match, and a 60 s
soak collecting on every tick has only the socket efuns' 7 errors.

**Next: the rest of M7** (the socket efuns, HTTP/TLS, MCCP, the remaining 36
stubs).

### 2026-10-25: M7 part 2, the LPC sockets

**Socket efuns done.** `sockets.star` ports `havok/sockets.pike` method for
method (FluffOS PACKAGE_SOCKETS: MUD, STREAM, DATAGRAM and the binary modes),
with its efun glue: socket_create/bind/listen/accept/connect/write/close/
release/acquire/error/address/status, resolve(), dump_file_descriptors(),
`valid_socket()` on the master, sockets closing when their owner is
destructed, and the reference's `havok outbound sockets` gate (off unless the
config says 1, so a test boot never dials the real intermud routers). Every
return code, text and callback order is the reference's. Checked against the
live Pike driver three ways:
- **24 cases of this port's own** over loopback (`m7_sock_cases.txt`,
  generated by `tools/gen_m7_sock_cases.py`, through two new hooks both
  runners give: `test_sock_pump(ob, fn)` runs network passes until
  `ob->fn()` is true, run_tests.pike's pump_until(); `test_config()` sets a
  config value). They cover every socket_error() text, every mode's
  socket_status() row, the state machine's errors, ownership and
  EESECURITY, stream connect/echo/close with name and function-pointer
  callbacks, int arrays and empty writes, 16 MB through one write, a
  stalled peer (EECALLBACK, EEALREADY, the write callback once it drains),
  callback errors reported without breaking the socket, destructing either
  end, release/acquire, get_garbage() keeping a socket's owner, MUD-mode
  values both ways and frames split or undecodable from a stream peer,
  datagrams (NUL terminator handling, addressing errors, a bound address,
  an unbound sender), refused, failing and unresolvable connects, and
  resolve(). The reference's own run_tests.pike only tests the TLS modes.
  The cases stay clear of what the two drivers can't agree on: ephemeral
  ports, TLS, connecting by name, reverse lookups, NUL bytes, and objects in
  results (the runners render them differently).
- **The DS3.9 boot** with the 13 socket efuns, resolve() and
  dump_file_descriptors() off the stub list (36 became 22, all HavokOS-only
  extensions plus malloc_status): the reference's boot report changed in
  one line, /secure/daemon/resolv now keeps its heart beat (its create()
  used to fail on the stubbed resolve()), and the Star boot matches it. The
  parser-transcript and login fixtures were re-recorded on the reference
  with the shorter list and are unchanged under their tests' normalization,
  and the Star driver still matches them.
- **Dead Souls' own servers**: its inet daemon listens (HTTP, FTP, HFTP,
  OOB), and a request to its HTTP port reaches `server.c` and `http.c` on
  both drivers, which then fail identically on `read_buffer()`, an LPC
  buffer efun neither driver has (now in todo.md).

A 60 s soak of the booted mudlib collecting on every tick now has no runtime
errors at all (the 7 it had were the socket efuns); Dead Souls' outbound
connects are refused by the gate, as on the reference.

The OS side needed new compiler builtins (`src/codegen/net_sock.rs`, see
"New compiler surface in M7"): Star could listen and accept, but not connect
without blocking the driver, wait for write readiness, use UDP, or read a
socket's own address. Design decisions, each explained at its point in the
code:
- **One poll for everything.** net_poll() hands every open LPC socket to the
  same tcp_wait_io() as the telnet listeners and connections, with the
  interest the reference's callbacks imply (write only while a connect is
  under way or output is queued), so the driver still sleeps in the kernel
  between events. Work left for the next pass (resolve() answers, a connect
  the OS refused at once) makes the wait zero.
- **Socket numbers are never reused**, as in the reference (socket_status()
  lists every one ever handed out), so `Vm.socks` is indexed by them.
- **A stream read drains what has arrived** (up to 1 MB a pass), as a Pike
  read callback does; reading one 16 KB chunk a pass made a stalled peer's
  4 MB take 256 passes, which the stalled-peer case caught.

Two new deliberate deviations (#16 the TLS modes, #17 the system resolver and
IPv4). No Star compiler bugs this round.

**Next: the rest of M7** (HTTP and TLS ports, MCCP, LPC buffers, the
HavokOS-only efuns).

### 2026-10-26: M7 part 3, the HavokOS-only extensions

**17 of the 22 remaining stubs done.** Every HavokOS-only extension efun the
boot still stubbed that needs no outside library: json_encode() and
json_decode() (`json.star`), astar_path(), find_files(), watch_path() and
unwatch_path(), quota_info() and quota_refresh() with the quotas themselves,
stale_programs() and dependents(), function_profile(), profile_start(),
profile_stop() and profile_report(), cache_stats(), malloc_status() and
memory_summary() (`ext.star`). What's left is db_open/db_query/db_info/
db_close (SQLite) and http_respond() (the HTTP ports). Checked against the
live Pike driver three ways:
- **The reference's own tests of them** (`pike/tests/run_tests.pike`):
  its json, astar and status checks are LPC and are copied; its watch,
  find_files, quota, dependency and profiling tests drive the driver from
  Pike, so they're ported one case per `expect` through eight new hooks both
  runners give (`test_watch_poll()`, `test_watch_state()`,
  `test_run_call_out()`, `test_utime()`, `test_forget()`,
  `test_profiling()`, `test_put()`, `test_rmtree()`), and the sampled work
  runs through M5's `test_limited()`, since the sample clock only runs
  inside top-level evaluations and a case body isn't one.
- **99 cases in all** (`m7_ext_cases.txt`, generated by
  `tools/gen_m7_ext_cases.py`), including about 40 JSON edge cases probed
  against Pike's Standards.JSON first (its pretty-printer keeps a
  one-element array on one line; its decoder takes trailing commas and a
  leading point, and reports the first character it can't take, or a
  string's opening quote when the text ends inside it), and A* mazes whose
  whole node tables (parents, g, h, f) and heap high-water marks match.
  Stable over 5 runs on each side.
- **The DS3.9 boot** with the 17 off the stub list (22 -> 5): the
  reference's report is unchanged, and so is the Star boot's. The
  parser-transcript, login and compile-sweep tests still pass.

Design decisions, each explained at its point in the code:
- **Stamps are token hashes.** The reference stamps a program with a hash of
  the Pike source it generated; here it's an FNV hash of the preprocessed
  token stream and the inherits' stamps, so recompiling unchanged code keeps
  the stamp and a comment-only edit doesn't change it. Each compile also
  records its source's and includes' (mtime, size); those stats are
  remembered for up to a second, which took the compile sweep from 35 s
  (unmemoized) back to 23 s, and can only make stale_programs() err towards
  "stale". The memo is dropped whenever the driver touches a file.
- **Quotas count where the reference counts**: the group is asked per base
  name when an object registers, clones are checked before creation and
  counted after, call_outs on creation (a refused one still uses up its
  handle) and released on every removal path, and call_out and heart beat
  wall time is charged per minute.
- **Profiling is the interpreter's**: frame entry opens a record, return or
  unwinding closes it and adds its time to the nearest profiled caller's
  callee time; the sampling profiler samples at the evaluation-limit tick,
  the reference's own place, and pauses between evaluations.

Getting there found two Star compiler bugs, both fixed (#10 float `!=`, #11
parameter names), and needed two new builtins (`file_set_mtime()`,
`process_memory()`). Four new deliberate deviations (#18-#21).

**Next: the rest of M7** (HTTP/TLS, MCCP, SQLite, LPC buffers).

### 2026-10-26: M7 part 4, the SQLite efuns

**db_open(), db_query(), db_info() and db_close() done** (`sqldb.star`,
efun codes 420-423), `havok/sqldb.pike` method for method, over a real
SQLite: the precompiled 3.54.1 DLL now in `sqlite/lib/x64`, with an import
library made by `llvm-dlltool` (`sqlite/README.md`). The boot's stub list
is down to http_respond() alone. Checked against the live Pike driver:
- **Probes first.** About 100 throwaway cases on the reference showed what
  it really does before any code was written, and the big surprise: its
  Pike bundles SQLite **3.6.0**, so a third of the probes answered for that
  library's age rather than the driver's logic (no multi-row VALUES, legacy
  error texts, DELETE without WHERE counting 0, ...). Those became
  deviation #22, and the fixture keeps to SQL both libraries answer alike.
  Run on the Star side, every remaining probe matched.
- **46 cases** (`m7_db_cases.txt`, generated by `tools/gen_m7_db_cases.py`):
  the reference's own `sqlite_tests()` (its two Pike-level checks, a handle
  used by another object and closed by its owner's destruct, through
  clones of a helper object; two others adjusted, a wide string and a
  lower-case declared type, see the generator), then trimming, placeholder
  numbering and its count check, named bindings and every binding error,
  "Trailing query data", the SELECT wrapper's column names, typed values
  and affinity, non-SELECT string rows, transactions, db_info() after each
  kind of statement, handles, paths. Stable over 5 runs on each side.
- **The DS3.9 boot** with the four off the stub list (5 -> 1): the
  reference's report is unchanged, and the Star boot matches it. The
  parser-transcript, login (all three), compile-sweep and token/AST
  sweeps pass, and a 60 s soak collecting every tick has 0 runtime errors.

Design decisions, each explained at its point in the code:
- **The reference's query pipeline, the library's values.** A SELECT runs
  as the reference runs it: `SELECT * FROM (<sql>) LIMIT 0` for the column
  names (and the errors), then a second wrapper over those columns for the
  rows. Only the reference's quote() around each column is gone: the
  values come back through `sqlite3_column_type()`, so nothing goes through
  text. Running the same SQL means the column names, error positions and
  placeholder behavior are the reference's by construction.
- **Two builtins, the rest `extern "C"`.** Only `sqlite3_open_v2` and
  `sqlite3_prepare_v2` answer through an out-parameter; everything else
  takes and returns scalars and pointers. `sqlite3_sql()`'s length gives
  the tail `pzTail` would have (checked: the text runs exactly to it), so
  the builtin needn't return a pair.
- **When the columns change** was probed rather than guessed: a statement
  that fails while running leaves them set to its own (the reference's
  module only steps when rows are fetched, after sqldb.pike has set them),
  one that fails to prepare leaves the previous query's.

Getting there found Star compiler bug #12 (a null `str` reaching
`extern "C"`), fixed, and the round also fixed #13, the five-test `@fgetc`
P0 failure. One new deliberate deviation (#22).

**Next: the rest of M7** (HTTP/TLS with http_respond(), MCCP, LPC buffers).

### 2026-10-26: M7 part 5, MCCP, HTTP, WebSockets, TLS and buffers

**The rest of M7 done**, which leaves the boot test's stub list empty: the
Star VM runs every efun the reference implements.
- **MCCP v2** (`zlib.star`, `net.star`): a deflate compressor written here
  rather than a zlib binding, and on par with zlib -6 in size. Checked
  against the reference by 7 cases (offers, the plain start marker, one
  stream across writes and input, DONT ending it, a second stream, closing)
  that compare inflated text through a `test_inflate()` hook both runners
  give, by an MCCP login over a real socket (`ds39_login_mccp`: the
  telnet client inflates), and by 69 round trips against Pike's own zlib
  (`tests/run_zlib_test.ps1`).
- **The HTTP port and WebSockets** (`http.star`): http.pike, and beneath it
  what Pike's Protocols.HTTP.Server.Request and Protocols.WebSocket really
  do, probed on the live reference first and read in Pike's library where
  a probe couldn't show the rule (the pipelined second request that goes
  unanswered is `parse_variables()` truncating its buffer; the Range
  header's miscounted lengths are `response_and_finish()`'s arithmetic).
  Every reference raw_send() is its own WebSocket frame, so output is
  marked where each ends.
- **TLS** (`tls.star`) over OpenSSL 3.2, the user's choice of library: the
  DLLs from Git for Windows with generated import libraries (`openssl/`).
  Getting there fixed two gaps in Star itself: uppercase extern names
  (HavokOS P2 #1; all of OpenSSL is uppercase) and binary data across the
  FFI (`ptr_to_bytes`/`ptr_write_bytes`). Telnet and HTTPS sessions start
  only once the handshake is done, as the reference's SSL.Port hands over
  only finished ones; STREAM_TLS listeners too, and a connecting STREAM_TLS
  socket's write callback waits for its handshake.
- **LPC buffers** (`buffers.star`), with no oracle: Dead Souls' own
  documentation of FluffOS's, because Dead Souls' web server needs them
  (deviation #25). Its pages now come back byte for byte, images included
  (`tests/run_dsweb_test.ps1`), where the reference fails every request.

Checked: 77 network cases (`m7_net.expected.txt`, through raw client hooks
both runners give, on a scratch minilib whose `/test/web.c` is a superset of
the reference's, stable over three runs), the 25 hand-checked buffer cases,
all earlier fixtures (the socket cases re-recorded with a helper that reads
a buffer's bytes, the reference's results unchanged), the boot (its stub
list now empty, the reference's report unchanged), the four logins, the
parser transcript and the compile sweep.

Found along the way:
- **The VM never frees garbage within one evaluation** (todo.md HavokOS P1
  #9): collections run only between top-level evaluations, so an
  `a += ({ x })` loop keeps every intermediate copy, quadratic in memory --
  0.8 GB at 10,000 appends, 7 GB at 30,000, and at 40,000 an allocation
  fails and the driver dies. Found when a case helper did exactly that over
  a 120 KB reply; the helpers now build with allocate()/implode().
- The reference's extra response headers come out in an order that changes
  between runs (Pike's hash order): the one case with two of them sorts.

Five new deliberate deviations or rewrites (#13 and #16 rewritten, #23-#25).


### 2026-10-26: P1 #9, garbage collection inside one evaluation

**Collections now run inside evaluations** (`gc.star` collect_young(), the
design in "Value representation" above): every slot carries the serial of
the interpreter loop that allocated it, and a collection at one of the
loop's safe points frees only unreachable slots at least as young as that
loop. Measured on `a += ({ i })` loops: 10k, 20k and 30k appends peak at
27 MB (were 0.8, 3.1 and 7 GB), 40k at 42 MB in 7.8 s (the driver used to
die). Against a build of the
previous commit: 10k appends 810 MB -> 27 MB in the same 0.65 s, and
`fib(25)` plus a 1M loop 0.42-0.44 s before, 0.42-0.45 s after, so the
safe-point checks (a compare at each frame switch and back edge) cost
nothing measurable.

The argument for safety is short (collect_young()'s comment), so the
checking went into making a mistake visible:
- **A fixture of the risky shapes** (`gc.expected.txt`, 21 cases,
  `tools/gen_gc_cases.py`, results from the live reference): values only
  a native frame holds while LPC runs beneath it (map() over an array and
  over a mapping, filter(), sort_array(), call_other()'s arguments while
  the target loads and its create() makes garbage, a call_out's argument)
  and every kind of root (outer frames, half-built expressions on the
  stack, closure cells, a destructed object whose code runs on, class
  instances, a thrown value crossing frames, a young mapping growing among
  garbage, recursion with no loop back edge). Each allocates past the
  1M-value floor, so 799 collections run in it without any stress mode.
- **A stress mode** (`-gcstress` on run_cases and boot_ds, `-GcStress` on
  their test scripts): a collection at every safe point after any
  allocation. All 957 cases pass (about 166,000 collections inside
  evaluations), and the DS3.9 boot gives the reference's report after
  12,116.
- **A mutant**: the same collector freeing young slots of *any* loop (the
  rule removed) fails 5 of the gc cases without stress (map()/filter()/
  sort_array() results freed under the efun), and under stress 31 cases of
  m3_extra, m4_extra, m5_extra and m7_ext as well. So both the rule and
  the tests matter.
- Everything else as usual: all cases, the boot, four logins, the parser
  transcript, the compile sweep, the DS web test; 60 s soaks with
  `-gcevery` and with `-gcstress`, 0 runtime errors. A normal soak runs no
  collection inside an evaluation at all: Dead Souls' own evaluations
  never allocate 1M values.

Left as it was: `a += ({ x })` still copies (quadratic time; in-place
appends would need reference counts), garbage an outer loop made while a
nested one runs waits until that loop's next safe point, and cells and
destructed objects' slots are still freed only between evaluations.

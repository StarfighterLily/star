# SQLite for Star programs

A precompiled 64-bit Windows SQLite (**3.54.1**, as `sqlite3_libversion()`
reports; the matching source tree is `sqlite-src-3540100/`), which Star
programs link to use the `sqlite_open()`/`sqlite_prepare()` builtins
(`src/codegen/sqlite.rs`) and the rest of SQLite's C API through
`extern "C"`. The LPMUD driver in `projects/havokos` is the first user (its
SQLite efuns, `projects/havokos/sqldb.star`).

| File | What it is |
|---|---|
| `lib/x64/sqlite3.dll` | the library |
| `lib/x64/sqlite3.def` | its export list |
| `lib/x64/libsqlite3.dll.a` | an import library for linking, made from the `.def` (below) |

`sqlite3.dll` SHA-256:
`4b59d3cded9dc1608544160f3b4b10ac974c6ac0d6ffc23064e5f4c8dbd05aea`

## Linking

From the repository root:

```
star build program.star -o program.exe -L sqlite/lib/x64 -l sqlite3
```

and put a copy of `sqlite3.dll` beside `program.exe` (Windows looks in the
executable's own directory first). `projects/havokos/tools/` holds one for
the tools built there; `tests/frontend_sqlite.rs` stages one per test.

## Regenerating the import library

LLVM-mingw's linker can't link against a DLL directly, so the import
library is generated from the `.def` with the toolchain's own `dlltool`:

```
llvm-dlltool -m i386:x86-64 -d sqlite/lib/x64/sqlite3.def -D sqlite3.dll -l sqlite/lib/x64/libsqlite3.dll.a
```

Building SQLite from source instead (a static `libsqlite3.a`, so no DLL to
ship) was considered: the source tree needs `tclsh` to produce the
amalgamation. The prebuilt DLL is what the HavokOS driver links today.

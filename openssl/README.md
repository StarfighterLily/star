# OpenSSL for Star programs

A precompiled 64-bit Windows OpenSSL (**3.2.4**, 11 Feb 2025, as `openssl
version -a` reports for the build it came with), which Star programs link
to use TLS through `extern "C"`: every OpenSSL call is a plain C function
of pointers and integers, which Star can call by its uppercase name since
the compiler fix for HavokOS P2 #1, and binary data crosses the boundary
through the `ptr_to_bytes`/`ptr_write_bytes` builtins
(`src/codegen/ffi_bytes.rs`). The LPMUD driver in `projects/havokos` is the
first user: telnet over TLS, HTTPS ports and STREAM_TLS sockets
(`projects/havokos/tls.star`).

| File | What it is |
|---|---|
| `lib/x64/libssl-3-x64.dll` | the TLS library |
| `lib/x64/libcrypto-3-x64.dll` | the crypto library it uses |
| `lib/x64/libssl-3-x64.def`, `lib/x64/libcrypto-3-x64.def` | their export lists, made with `gendef` |
| `lib/x64/libssl.dll.a`, `lib/x64/libcrypto.dll.a` | import libraries for linking, made from the `.def`s (below) |

Where they came from: Git for Windows' own copies
(`C:\Program Files\Git\mingw64\bin`), the user's choice of TLS library for
the HavokOS port (over a TLS stack written in Star, or Windows SChannel,
which would have left the Linux side without one). SHA-256:

```
libssl-3-x64.dll     a9169d9b4350c934570c6912614dc76edadfae64469de802d5529b65f73f706c
libcrypto-3-x64.dll  9c069dec902628c5e37f532a06f171c5b82333a3614e57db0d1429d70abc9892
```

They depend only on Windows system DLLs (`KERNEL32`, `ADVAPI32`,
`CRYPT32`, `USER32`, `WS2_32`, `msvcrt`). The build was configured with
shared zlib, which libcrypto only loads if TLS compression is asked for;
nothing here asks.

## Linking

From the repository root:

```
star build program.star -o program.exe -L openssl/lib/x64 -l ssl -l crypto
```

and put copies of both DLLs beside `program.exe` (Windows looks in the
executable's own directory first). `projects/havokos/tools/` holds a pair
for the tools built there; `tests/frontend_ffi_bytes.rs` stages a pair per
test. On Linux the system's `libssl`/`libcrypto` are linked the same way
(not yet built and run there; `docs/cross_platform_scope.md`).

## Regenerating the import libraries

LLVM-mingw's linker can't link against a DLL directly, so the import
libraries are generated from export lists with the toolchain's own tools:

```
cd openssl/lib/x64
gendef libssl-3-x64.dll
gendef libcrypto-3-x64.dll
llvm-dlltool -m i386:x86-64 -d libssl-3-x64.def -D libssl-3-x64.dll -l libssl.dll.a
llvm-dlltool -m i386:x86-64 -d libcrypto-3-x64.def -D libcrypto-3-x64.dll -l libcrypto.dll.a
```

## Things OpenSSL's headers hide

Some documented "functions" are macros and aren't exported --
`EVP_RSA_gen()`, `SSL_set_tlsext_host_name()`, `BIO_pending()` -- so a
binding calls what they expand to (`RSA_generate_key_ex()` with a
`BN_set_word()` exponent, `SSL_ctrl(s, 55, 0, name)`, `BIO_ctrl_pending()`).
A C `long` parameter is declared `i64`: on Windows x64 a long is 32 bits,
but every argument travels in a 64-bit register or stack slot and the
callee reads the low half, while on Linux a long is the full 64 bits.

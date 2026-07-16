//! File I/O builtins (`file_open`/`file_read`/`file_read_line`/`file_write`/
//! `file_close`/`file_exists`): thin wrappers over the C runtime's buffered
//! `FILE*` API, reusing `Ty::Ptr` (see its doc comment in `crate::types`) as
//! the file-handle type -- exactly the same "opaque foreign pointer, no RC
//! header" shape `extern "C"` FFI already established for `getenv`'s
//! returned `char*`.
//!
//! Error model (see `todo.md`'s "decide error model" note): `file_open`
//! returns a null `ptr` on failure, checked with the existing
//! `is_null`/`null_ptr` builtins exactly like `getenv`. Calling any of the
//! other file builtins with a null/closed handle is a programmer error, not
//! a recoverable I/O condition -- it aborts loudly (see `abort_if_null_handle`)
//! rather than handing a null `FILE*` to the C runtime, matching the
//! frame-buffer-overflow/div-by-zero abort philosophy elsewhere in this
//! codegen. `file_read`/`file_read_line` return an empty `str` on EOF,
//! matching `read_line`'s own EOF convention.

use crate::diagnostics::Span;
use crate::types::*;

use super::Codegen;

impl Codegen {
    /// Abort with a message (matches `Codegen::emit_frame_alloc`'s
    /// bounds-check shape: branch -> `puts` -> `exit(1)` -> `unreachable`)
    /// if `handle` is a null `ptr`. Used by every file builtin except
    /// `file_open`/`file_exists`, which have no handle to misuse yet.
    fn abort_if_null_handle(&mut self, handle: &str, builtin_name: &str) {
        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, handle));
        let fail_label = self.block_label("file_null_handle");
        let ok_label = self.block_label("file_handle_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, fail_label, ok_label));

        self.open_block(&fail_label);
        let msg = format!("star runtime error: {}(..) called with a null/closed file handle\n", builtin_name);
        let g = self.global_name();
        let escaped = msg.replace("\\", "\\\\").replace("\"", "\\22").replace("\n", "\\0A");
        self.global_defs.push(format!("{} = private unnamed_addr constant [{} x i8] c\"{}\\00\"", g, msg.len() + 1, escaped));
        let msg_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [{} x i8], [{} x i8]* {}, i64 0, i64 0", msg_ptr, msg.len() + 1, msg.len() + 1, g));
        self.line(&format!("  call i32 @puts(i8* {})", msg_ptr));
        self.line("  call void @exit(i32 1)");
        self.line("  unreachable");

        self.open_block(&ok_label);
    }

    /// `file_open(path: str, mode: str) -> ptr`: `fopen`, passing `mode`
    /// straight through (`"r"`/`"w"`/`"a"`/`"r+"`/...) -- null `ptr` on
    /// failure, checked the same way `extern "C" fn getenv` results are.
    pub(super) fn emit_file_open(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("file_open(..) expects 2 arguments (path, mode)", Span::dummy());
            return "i8* null".into();
        }
        let path = self.emit_raw_str_ptr(&args[0]);
        let mode = self.emit_raw_str_ptr(&args[1]);
        let reg = self.tmp_name();
        self.line(&format!("  {} = call i8* @fopen(i8* {}, i8* {})", reg, path, mode));
        format!("i8* {}", reg)
    }

    /// `file_close(handle: ptr)`: `fclose`, no return value.
    pub(super) fn emit_file_close(&mut self, args: &[TypedExpr]) {
        let Some(arg) = args.first() else {
            self.err("file_close(..) expects 1 argument", Span::dummy());
            return;
        };
        let val = self.emit_expr(arg);
        let handle = self.untag(&val, &Ty::Ptr);
        self.abort_if_null_handle(&handle, "file_close");
        self.line(&format!("  call i32 @fclose(i8* {})", handle));
        // Null out the caller's own variable, if `arg` is a bare one, so
        // calling any other file builtin through *this* binding afterward
        // hits `abort_if_null_handle` above -- matching this module's
        // documented "aborts loudly on a closed handle" contract -- instead
        // of silently handing the C runtime a dangling `FILE*` that a later,
        // unrelated `fopen` may have already reused for a different file
        // (`fclose` doesn't invalidate the pointer *value* itself at the
        // LLVM/C-ABI level; there is no portable way to poison a raw
        // pointer's bit pattern). Restricted to a bare `Ident` specifically
        // because `emit_place` would otherwise *re-evaluate* `arg` a second
        // time -- harmless for a plain variable lookup, but wrong for
        // anything with its own side effects (an index expression, a call).
        // This can't help a handle reached through a *different*
        // variable/copy/struct field still holding the same stale value --
        // a real, but narrower, residual gap of the same class -- but it
        // closes the direct, single-binding case this module's doc comment
        // actually promises.
        if let TypedExpr::Ident { .. } = arg {
            let place = self.emit_place(arg);
            self.line(&format!("  store i8* null, i8** {}", place));
        }
    }

    /// `file_read(handle: ptr) -> str`: reads every remaining byte from the
    /// handle's current position through EOF into one fresh, owned `str`.
    /// Sizes the buffer up front via `ftell`/`fseek` (save position, seek to
    /// `SEEK_END`, `ftell` again, seek back) rather than growing a buffer
    /// incrementally, since the size is cheaply knowable ahead of the single
    /// `fread` -- mirrors `emit_str_concat`'s alloc-then-fill shape rather
    /// than `read_line`'s char-at-a-time loop.
    pub(super) fn emit_file_read(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("file_read(..) expects 1 argument", Span::dummy());
            return "i8* null".into();
        };
        let val = self.emit_expr(arg);
        let handle = self.untag(&val, &Ty::Ptr);
        self.abort_if_null_handle(&handle, "file_read");

        let cur = self.tmp_name();
        self.line(&format!("  {} = call i32 @ftell(i8* {})", cur, handle));
        self.line(&format!("  call i32 @fseek(i8* {}, i32 0, i32 2)", handle));
        let end = self.tmp_name();
        self.line(&format!("  {} = call i32 @ftell(i8* {})", end, handle));
        self.line(&format!("  call i32 @fseek(i8* {}, i32 {}, i32 0)", handle, cur));
        let remaining = self.tmp_name();
        self.line(&format!("  {} = sub i32 {}, {}", remaining, end, cur));
        let remaining64_raw = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", remaining64_raw, remaining));
        // `ftell` returns -1 on a non-seekable stream (a pipe, a console
        // handle, ...); sign-extending that (or any other negative `remaining`
        // it produces) to i64 and treating it as an unsigned byte count would
        // request a near-u64::MAX `star_rc_alloc`/`fread`, corrupting memory
        // instead of failing cleanly. Clamp to 0 (empty read) exactly like an
        // already-at-EOF handle, rather than trusting the C runtime's signed
        // result to always be a valid unsigned size.
        let is_valid = self.tmp_name();
        self.line(&format!("  {} = icmp sge i64 {}, 0", is_valid, remaining64_raw));
        let remaining64 = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i64 {}, i64 0", remaining64, is_valid, remaining64_raw));
        let cap64 = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", cap64, remaining64));
        let buf = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 {}, i8* null)", buf, cap64));
        let n = self.tmp_name();
        self.line(&format!("  {} = call i64 @fread(i8* {}, i64 1, i64 {}, i8* {})", n, buf, remaining64, handle));
        let nul_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", nul_ptr, buf, n));
        self.line(&format!("  store i8 0, i8* {}", nul_ptr));
        buf
    }

    /// `file_read_line(handle: ptr) -> str`: structurally identical to
    /// `Codegen::emit_read_line`'s fixed-1024-byte, char-at-a-time loop,
    /// except reading via `@fgetc(handle)` instead of the stdin-only
    /// `@getchar()`. EOF and an empty line both yield `""`, the same
    /// convention `read_line` already established for stdin.
    pub(super) fn emit_file_read_line(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("file_read_line(..) expects 1 argument", Span::dummy());
            return "i8* null".into();
        };
        let val = self.emit_expr(arg);
        let handle = self.untag(&val, &Ty::Ptr);
        self.abort_if_null_handle(&handle, "file_read_line");

        const CAP: u64 = 1024;
        let buf = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 {}, i8* null)", buf, CAP));
        let i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", i_ptr));
        self.line(&format!("  store i64 0, i64* {}", i_ptr));

        let cond_label = self.block_label("file_read_line_cond");
        let body_label = self.block_label("file_read_line_body");
        let store_label = self.block_label("file_read_line_store");
        let end_label = self.block_label("file_read_line_end");

        self.line(&format!("  br label %{}", cond_label));
        self.open_block(&cond_label);
        let i_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
        let has_room = self.tmp_name();
        self.line(&format!("  {} = icmp ult i64 {}, {}", has_room, i_reg, CAP - 1));
        self.line(&format!("  br i1 {}, label %{}, label %{}", has_room, body_label, end_label));

        self.open_block(&body_label);
        let c = self.tmp_name();
        self.line(&format!("  {} = call i32 @fgetc(i8* {})", c, handle));
        let is_eof = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, -1", is_eof, c));
        let is_nl = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 10", is_nl, c));
        let stop = self.tmp_name();
        self.line(&format!("  {} = or i1 {}, {}", stop, is_eof, is_nl));
        self.line(&format!("  br i1 {}, label %{}, label %{}", stop, end_label, store_label));

        self.open_block(&store_label);
        let dest = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", dest, buf, i_reg));
        let c8 = self.tmp_name();
        self.line(&format!("  {} = trunc i32 {} to i8", c8, c));
        self.line(&format!("  store i8 {}, i8* {}", c8, dest));
        let i_next = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
        self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
        self.line(&format!("  br label %{}", cond_label));

        self.open_block(&end_label);
        let final_i = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", final_i, i_ptr));
        let nul = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", nul, buf, final_i));
        self.line(&format!("  store i8 0, i8* {}", nul));

        buf
    }

    /// `file_write(handle: ptr, data: str) -> bool`: `fwrite`s `data`'s raw
    /// bytes verbatim (no auto-appended newline, matching `print`'s bare-
    /// `str` behavior); returns whether every byte was actually written --
    /// unlike a null handle, a short write (full disk, revoked permission,
    /// ...) is a real runtime condition a program can react to, not a
    /// programmer error, hence a `bool` sentinel rather than an abort.
    pub(super) fn emit_file_write(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("file_write(..) expects 2 arguments (handle, data)", Span::dummy());
            return "i1 false".into();
        }
        let hval = self.emit_expr(&args[0]);
        let handle = self.untag(&hval, &Ty::Ptr);
        self.abort_if_null_handle(&handle, "file_write");
        let data = self.emit_raw_str_ptr(&args[1]);
        let len = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", len, data));
        let len64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", len64, len));
        let n = self.tmp_name();
        self.line(&format!("  {} = call i64 @fwrite(i8* {}, i64 1, i64 {}, i8* {})", n, data, len64, handle));
        let reg = self.tmp_name();
        self.line(&format!("  {} = icmp eq i64 {}, {}", reg, n, len64));
        format!("i1 {}", reg)
    }

    /// `file_exists(path: str) -> bool`: `fopen(path, "r")`, closing it
    /// again immediately if it succeeded -- no handle escapes to the
    /// caller, so no abort path applies here.
    pub(super) fn emit_file_exists(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("file_exists(..) expects 1 argument", Span::dummy());
            return "i1 false".into();
        };
        let path = self.emit_raw_str_ptr(arg);
        let mode_g = self.global_name();
        self.global_defs.push(format!("{} = private unnamed_addr constant [2 x i8] c\"r\\00\"", mode_g));
        let mode_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [2 x i8], [2 x i8]* {}, i64 0, i64 0", mode_ptr, mode_g));
        let handle = self.tmp_name();
        self.line(&format!("  {} = call i8* @fopen(i8* {}, i8* {})", handle, path, mode_ptr));
        let exists = self.tmp_name();
        self.line(&format!("  {} = icmp ne i8* {}, null", exists, handle));
        let close_label = self.block_label("file_exists_close");
        let end_label = self.block_label("file_exists_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", exists, close_label, end_label));
        self.open_block(&close_label);
        self.line(&format!("  call i32 @fclose(i8* {})", handle));
        self.line(&format!("  br label %{}", end_label));
        self.open_block(&end_label);
        format!("i1 {}", exists)
    }
}

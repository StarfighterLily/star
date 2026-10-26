//! Filesystem and calendar builtins: `dir_list`, `path_kind`, `file_size`,
//! `file_mtime`, `file_set_mtime`, `dir_create`, `dir_remove`, `file_remove`,
//! `file_rename` and `local_time` -- thin wrappers over the C runtime, the same shape as
//! `crate::codegen::file_io`/`crate::codegen::os`.
//!
//! Why builtins rather than `extern "C"` in user code: every one of these
//! C calls reports through a struct out-parameter (`_finddata64_t`,
//! `struct stat`, `struct tm`) or a per-OS entry point, and Star's FFI can
//! pass a `ptr` but never read a field back out of one -- there's no pointer
//! arithmetic or load in the language. They surfaced as one gap while
//! porting the LPMUD driver in `projects/havokos` (`todo.md` HavokOS M4:
//! `get_dir`/`file_size`/`stat`/`mkdir`/`rm`/`rename` and
//! `ctime`/`localtime`), which until then could only read and write whole
//! files. The struct layouts used here were measured with `offsetof` on
//! this toolchain (clang targeting `x86_64-w64-windows-gnu`, msvcrt) rather
//! than taken from documentation: `__finddata64_t` is 304 bytes with `name`
//! at 40; `_stat64` is 56 bytes with `st_mode` (u16) at 6, `st_size` at 24
//! and `st_mtime` at 40; `struct tm` is nine `i32`s from offset 0.
//!
//! Conventions, matching the rest of the builtin surface (no Option/Result
//! at the C boundary): a missing path is `path_kind` 0 and `file_size`/
//! `file_mtime` -1, `dir_list` of a non-directory is an empty list, the
//! mutating calls return `false` on failure, and `local_time` returns an
//! empty list if the C runtime rejects the time. `dir_list` leaves out `.`
//! and `..` and returns names in whatever order the OS lists them.
//! `file_rename` replaces an existing target on both targets (POSIX
//! `rename` does; on Windows the CRT's `rename` refuses, so it's
//! `MoveFileExA` with `MOVEFILE_REPLACE_EXISTING | MOVEFILE_COPY_ALLOWED`),
//! because the usual reason to rename is the atomic "write a temp file,
//! move it over the old one" save.
//!
//! `file_set_mtime(path, t)` sets a file's modification (and access) time to
//! `t` seconds since the epoch, through `_utime64`/`utime`, whose argument is
//! the same 16-byte `{ actime, modtime }` pair of `i64`s on both C runtimes.
//! It came later (`todo.md` HavokOS P1 #6): the LPMUD driver's
//! `stale_programs()` treats a file stamped within a second of its compile as
//! changed, so its tests have to age files the way the reference's own tests
//! do with Pike's `System.utime`, and Star's FFI can't build the struct.
//!
//! `local_time(t)` is `[sec, min, hour, mday, mon (0-11), year (e.g. 2001),
//! wday, yday, isdst, gmtoff]`, gmtoff in seconds east of UTC. Windows has
//! no `tm_gmtoff`, so it's `_mkgmtime64` of the local broken-down time
//! minus `t` (the local wall clock read as if it were UTC).
//!
//! ## `Target::LinuxGnu`: seamed, not yet devbox-verified
//! The Linux arm uses `opendir`/`readdir`/`closedir`, `stat`, `mkdir(path,
//! 0777)`, `rmdir`, `rename` and `localtime_r` (whose `tm_gmtoff` is read
//! directly), with glibc x86_64 offsets: `struct stat` 144 bytes, `st_mode`
//! (u32) at 24, `st_size` at 48, `st_mtim.tv_sec` at 88; `dirent.d_name` at
//! 19; `tm_gmtoff` at 40 of a 56-byte `struct tm`. See
//! `docs/cross_platform_scope.md`.

use crate::diagnostics::Span;
use crate::types::*;

use super::{Codegen, Target};

impl Codegen {
    /// `declare` every C symbol this module calls, for the `Target` this
    /// `Codegen` was built for -- called once from `emit_builtins`, like
    /// `crate::codegen::os::declare_os_externs`.
    pub(super) fn declare_fs_externs(&mut self) {
        match self.target {
            Target::WindowsGnu => {
                self.line("declare i64 @_findfirst64(i8*, i8*)");
                self.line("declare i32 @_findnext64(i64, i8*)");
                self.line("declare i32 @_findclose(i64)");
                self.line("declare i32 @_stat64(i8*, i8*)");
                self.line("declare i32 @_mkdir(i8*)");
                self.line("declare i32 @_rmdir(i8*)");
                self.line("declare i32 @MoveFileExA(i8*, i8*, i32)");
                self.line("declare i32 @_localtime64_s(i8*, i64*)");
                self.line("declare i64 @_mkgmtime64(i8*)");
                self.line("declare i32 @_utime64(i8*, i8*)");
            }
            Target::LinuxGnu => {
                self.line("declare i8* @opendir(i8*)");
                self.line("declare i8* @readdir(i8*)");
                self.line("declare i32 @closedir(i8*)");
                self.line("declare i32 @stat(i8*, i8*)");
                self.line("declare i32 @mkdir(i8*, i32)");
                self.line("declare i32 @rmdir(i8*)");
                self.line("declare i32 @rename(i8*, i8*)");
                self.line("declare i8* @localtime_r(i64*, i8*)");
                self.line("declare i32 @utime(i8*, i8*)");
            }
        }
        self.line("declare i32 @remove(i8*)");
    }

    /// A private NUL-terminated string constant; returns an `i8*` to it.
    fn fs_cstr(&mut self, s: &str) -> String {
        let g = self.global_name();
        let n = s.len() + 1;
        self.global_defs.push(format!("{} = private unnamed_addr constant [{} x i8] c\"{}\\00\"", g, n, s));
        let p = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [{} x i8], [{} x i8]* {}, i64 0, i64 0", p, n, n, g));
        p
    }

    /// One `str` argument as an owned raw `i8*` (released by the caller).
    fn fs_path_arg(&mut self, args: &[TypedExpr], name: &str) -> Option<String> {
        let Some(arg) = args.first() else {
            self.err(&format!("{}(..) expects 1 argument", name), Span::dummy());
            return None;
        };
        Some(self.emit_raw_str_ptr(arg))
    }

    /// `stat` the path into a fresh stack buffer: (call succeeded `i1`,
    /// buffer `i8*`). Releases `path`.
    fn fs_stat(&mut self, path: &str) -> (String, String) {
        let (size, func) = match self.target {
            Target::WindowsGnu => (56, "_stat64"),
            Target::LinuxGnu => (144, "stat"),
        };
        let buf = self.tmp_name();
        self.line(&format!("  {} = alloca [{} x i8], align 8", buf, size));
        let bufp = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [{} x i8], [{} x i8]* {}, i64 0, i64 0", bufp, size, size, buf));
        let r = self.tmp_name();
        self.line(&format!("  {} = call i32 @{}(i8* {}, i8* {})", r, func, path, bufp));
        self.line(&format!("  call void @star_rc_release(i8* {})", path));
        let ok = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 0", ok, r));
        (ok, bufp)
    }

    /// Load an `i64` field at byte `offset` of a stat buffer.
    fn fs_load_i64(&mut self, bufp: &str, offset: i64) -> String {
        let p = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", p, bufp, offset));
        let pi = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i64*", pi, p));
        let v = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", v, pi));
        v
    }

    /// `path_kind(path) -> i32`: 0 missing, 1 regular file, 2 directory,
    /// 3 anything else.
    pub(super) fn emit_path_kind(&mut self, args: &[TypedExpr]) -> String {
        let Some(path) = self.fs_path_arg(args, "path_kind") else {
            return "i32 0".into();
        };
        let (ok, bufp) = self.fs_stat(&path);
        let mode = match self.target {
            Target::WindowsGnu => {
                let p = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 6", p, bufp));
                let p16 = self.tmp_name();
                self.line(&format!("  {} = bitcast i8* {} to i16*", p16, p));
                let m16 = self.tmp_name();
                self.line(&format!("  {} = load i16, i16* {}", m16, p16));
                let m = self.tmp_name();
                self.line(&format!("  {} = zext i16 {} to i32", m, m16));
                m
            }
            Target::LinuxGnu => {
                let p = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 24", p, bufp));
                let p32 = self.tmp_name();
                self.line(&format!("  {} = bitcast i8* {} to i32*", p32, p));
                let m = self.tmp_name();
                self.line(&format!("  {} = load i32, i32* {}", m, p32));
                m
            }
        };
        // S_IFMT 0170000, S_IFDIR 0040000, S_IFREG 0100000 (the same octal
        // values on both C runtimes)
        let fmt = self.tmp_name();
        self.line(&format!("  {} = and i32 {}, 61440", fmt, mode));
        let is_dir = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 16384", is_dir, fmt));
        let is_reg = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 32768", is_reg, fmt));
        let k1 = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i32 1, i32 3", k1, is_reg, ));
        let k2 = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i32 2, i32 {}", k2, is_dir, k1));
        let k = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i32 {}, i32 0", k, ok, k2));
        format!("i32 {}", k)
    }

    /// `file_size(path) -> i64` / `file_mtime(path) -> i64` (seconds since
    /// the epoch): -1 when the path doesn't exist.
    pub(super) fn emit_file_stat_field(&mut self, args: &[TypedExpr], mtime: bool) -> String {
        let name = if mtime { "file_mtime" } else { "file_size" };
        let Some(path) = self.fs_path_arg(args, name) else {
            return "i64 -1".into();
        };
        let (ok, bufp) = self.fs_stat(&path);
        let offset = match (self.target, mtime) {
            (Target::WindowsGnu, false) => 24,
            (Target::WindowsGnu, true) => 40,
            (Target::LinuxGnu, false) => 48,
            (Target::LinuxGnu, true) => 88,
        };
        let v = self.fs_load_i64(&bufp, offset);
        let r = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i64 {}, i64 -1", r, ok, v));
        format!("i64 {}", r)
    }

    /// `file_set_mtime(path, t) -> bool`: modification and access time both
    /// set to `t`.
    pub(super) fn emit_file_set_mtime(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("file_set_mtime(..) expects 2 arguments", Span::dummy());
            return "i1 false".into();
        }
        let path = self.emit_raw_str_ptr(&args[0]);
        let tv = self.emit_expr(&args[1]);
        let t = self.untag(&tv, &Ty::I64);
        let buf = self.tmp_name();
        self.line(&format!("  {} = alloca [2 x i64], align 8", buf));
        for i in 0..2 {
            let p = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds [2 x i64], [2 x i64]* {}, i64 0, i64 {}", p, buf, i));
            self.line(&format!("  store i64 {}, i64* {}", t, p));
        }
        let bufp = self.tmp_name();
        self.line(&format!("  {} = bitcast [2 x i64]* {} to i8*", bufp, buf));
        let func = match self.target {
            Target::WindowsGnu => "_utime64",
            Target::LinuxGnu => "utime",
        };
        let r = self.tmp_name();
        self.line(&format!("  {} = call i32 @{}(i8* {}, i8* {})", r, func, path, bufp));
        self.line(&format!("  call void @star_rc_release(i8* {})", path));
        let ok = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 0", ok, r));
        format!("i1 {}", ok)
    }

    /// `dir_create`/`dir_remove`/`file_remove(path) -> bool`.
    pub(super) fn emit_fs_path_op(&mut self, args: &[TypedExpr], name: &str) -> String {
        let Some(path) = self.fs_path_arg(args, name) else {
            return "i1 false".into();
        };
        let r = self.tmp_name();
        match (name, self.target) {
            ("dir_create", Target::WindowsGnu) => self.line(&format!("  {} = call i32 @_mkdir(i8* {})", r, path)),
            ("dir_create", Target::LinuxGnu) => self.line(&format!("  {} = call i32 @mkdir(i8* {}, i32 511)", r, path)),
            ("dir_remove", Target::WindowsGnu) => self.line(&format!("  {} = call i32 @_rmdir(i8* {})", r, path)),
            ("dir_remove", Target::LinuxGnu) => self.line(&format!("  {} = call i32 @rmdir(i8* {})", r, path)),
            _ => self.line(&format!("  {} = call i32 @remove(i8* {})", r, path)),
        }
        self.line(&format!("  call void @star_rc_release(i8* {})", path));
        let ok = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 0", ok, r));
        format!("i1 {}", ok)
    }

    /// `file_rename(from, to) -> bool`, replacing an existing `to`.
    pub(super) fn emit_file_rename(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("file_rename(..) expects 2 arguments", Span::dummy());
            return "i1 false".into();
        }
        let from = self.emit_raw_str_ptr(&args[0]);
        let to = self.emit_raw_str_ptr(&args[1]);
        let r = self.tmp_name();
        let ok = self.tmp_name();
        match self.target {
            Target::WindowsGnu => {
                self.line(&format!("  {} = call i32 @MoveFileExA(i8* {}, i8* {}, i32 3)", r, from, to));
                self.line(&format!("  {} = icmp ne i32 {}, 0", ok, r));
            }
            Target::LinuxGnu => {
                self.line(&format!("  {} = call i32 @rename(i8* {}, i8* {})", r, from, to));
                self.line(&format!("  {} = icmp eq i32 {}, 0", ok, r));
            }
        }
        self.line(&format!("  call void @star_rc_release(i8* {})", from));
        self.line(&format!("  call void @star_rc_release(i8* {})", to));
        format!("i1 {}", ok)
    }

    /// Push a copy of the NUL-terminated `name` onto a dynamic `List<str>`
    /// unless it is `.` or `..`.
    fn fs_push_entry(&mut self, name: &str, data_slot: &str, len_slot: &str, cap_slot: &str) {
        let dot = self.fs_cstr(".");
        let dotdot = self.fs_cstr("..");
        let c1 = self.tmp_name();
        self.line(&format!("  {} = call i32 @strcmp(i8* {}, i8* {})", c1, name, dot));
        let c2 = self.tmp_name();
        self.line(&format!("  {} = call i32 @strcmp(i8* {}, i8* {})", c2, name, dotdot));
        let s1 = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 0", s1, c1));
        let s2 = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 0", s2, c2));
        let skip = self.tmp_name();
        self.line(&format!("  {} = or i1 {}, {}", skip, s1, s2));
        let push_label = self.block_label("dir_list_push");
        let next_label = self.block_label("dir_list_pushed");
        self.line(&format!("  br i1 {}, label %{}, label %{}", skip, next_label, push_label));
        self.open_block(&push_label);
        let n32 = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", n32, name));
        let n64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", n64, n32));
        let total = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", total, n64));
        let owned = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 {}, i8* null)", owned, total));
        self.line(&format!("  call i8* @strcpy(i8* {}, i8* {})", owned, name));
        self.emit_dynamic_str_list_push(data_slot, len_slot, cap_slot, &owned);
        self.line(&format!("  br label %{}", next_label));
        self.open_block(&next_label);
    }

    /// `dir_list(path) -> List<str>`: the entry names of a directory.
    pub(super) fn emit_dir_list(&mut self, args: &[TypedExpr]) -> String {
        let Some(path) = self.fs_path_arg(args, "dir_list") else {
            return "i8* null".into();
        };
        let data_slot = self.tmp_name();
        self.line(&format!("  {} = alloca i8**", data_slot));
        self.line(&format!("  store i8** null, i8*** {}", data_slot));
        let len_slot = self.tmp_name();
        self.line(&format!("  {} = alloca i64", len_slot));
        self.line(&format!("  store i64 0, i64* {}", len_slot));
        let cap_slot = self.tmp_name();
        self.line(&format!("  {} = alloca i64", cap_slot));
        self.line(&format!("  store i64 0, i64* {}", cap_slot));
        let done_label = self.block_label("dir_list_done");
        let loop_label = self.block_label("dir_list_loop");
        match self.target {
            Target::WindowsGnu => {
                // spec = path + "/*" (just "*" after a trailing separator)
                let n32 = self.tmp_name();
                self.line(&format!("  {} = call i32 @strlen(i8* {})", n32, path));
                let n = self.tmp_name();
                self.line(&format!("  {} = sext i32 {} to i64", n, n32));
                let total = self.tmp_name();
                self.line(&format!("  {} = add i64 {}, 3", total, n));
                let spec = self.tmp_name();
                self.line(&format!("  {} = call i8* @malloc(i64 {})", spec, total));
                self.line(&format!("  call i8* @strcpy(i8* {}, i8* {})", spec, path));
                let has = self.tmp_name();
                self.line(&format!("  {} = icmp sgt i64 {}, 0", has, n));
                let lastidx = self.tmp_name();
                self.line(&format!("  {} = select i1 {}, i64 {}, i64 1", lastidx, has, n));
                let li = self.tmp_name();
                self.line(&format!("  {} = sub i64 {}, 1", li, lastidx));
                let lp = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", lp, spec, li));
                let lc = self.tmp_name();
                self.line(&format!("  {} = load i8, i8* {}", lc, lp));
                let is_fs = self.tmp_name();
                self.line(&format!("  {} = icmp eq i8 {}, 47", is_fs, lc));
                let is_bs = self.tmp_name();
                self.line(&format!("  {} = icmp eq i8 {}, 92", is_bs, lc));
                let is_sep0 = self.tmp_name();
                self.line(&format!("  {} = or i1 {}, {}", is_sep0, is_fs, is_bs));
                let is_sep = self.tmp_name();
                self.line(&format!("  {} = and i1 {}, {}", is_sep, is_sep0, has));
                let star_only = self.fs_cstr("*");
                let slash_star = self.fs_cstr("/*");
                let suffix = self.tmp_name();
                self.line(&format!("  {} = select i1 {}, i8* {}, i8* {}", suffix, is_sep, star_only, slash_star));
                self.line(&format!("  call i8* @strcat(i8* {}, i8* {})", spec, suffix));
                self.line(&format!("  call void @star_rc_release(i8* {})", path));
                let buf = self.tmp_name();
                self.line(&format!("  {} = alloca [304 x i8], align 8", buf));
                let bufp = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds [304 x i8], [304 x i8]* {}, i64 0, i64 0", bufp, buf));
                let h = self.tmp_name();
                self.line(&format!("  {} = call i64 @_findfirst64(i8* {}, i8* {})", h, spec, bufp));
                self.line(&format!("  call void @free(i8* {})", spec));
                let bad = self.tmp_name();
                self.line(&format!("  {} = icmp eq i64 {}, -1", bad, h));
                self.line(&format!("  br i1 {}, label %{}, label %{}", bad, done_label, loop_label));
                self.open_block(&loop_label);
                let name = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 40", name, bufp));
                self.fs_push_entry(&name, &data_slot, &len_slot, &cap_slot);
                let r = self.tmp_name();
                self.line(&format!("  {} = call i32 @_findnext64(i64 {}, i8* {})", r, h, bufp));
                let more = self.tmp_name();
                self.line(&format!("  {} = icmp eq i32 {}, 0", more, r));
                let close_label = self.block_label("dir_list_close");
                self.line(&format!("  br i1 {}, label %{}, label %{}", more, loop_label, close_label));
                self.open_block(&close_label);
                self.line(&format!("  call i32 @_findclose(i64 {})", h));
                self.line(&format!("  br label %{}", done_label));
            }
            Target::LinuxGnu => {
                let d = self.tmp_name();
                self.line(&format!("  {} = call i8* @opendir(i8* {})", d, path));
                self.line(&format!("  call void @star_rc_release(i8* {})", path));
                let bad = self.tmp_name();
                self.line(&format!("  {} = icmp eq i8* {}, null", bad, d));
                self.line(&format!("  br i1 {}, label %{}, label %{}", bad, done_label, loop_label));
                self.open_block(&loop_label);
                let ent = self.tmp_name();
                self.line(&format!("  {} = call i8* @readdir(i8* {})", ent, d));
                let end = self.tmp_name();
                self.line(&format!("  {} = icmp eq i8* {}, null", end, ent));
                let body_label = self.block_label("dir_list_entry");
                let close_label = self.block_label("dir_list_close");
                self.line(&format!("  br i1 {}, label %{}, label %{}", end, close_label, body_label));
                self.open_block(&body_label);
                let name = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 19", name, ent));
                self.fs_push_entry(&name, &data_slot, &len_slot, &cap_slot);
                self.line(&format!("  br label %{}", loop_label));
                self.open_block(&close_label);
                self.line(&format!("  call i32 @closedir(i8* {})", d));
                self.line(&format!("  br label %{}", done_label));
            }
        }
        self.open_block(&done_label);
        self.emit_finish_dynamic_str_list(&data_slot, &len_slot, &cap_slot)
    }

    /// `local_time(t: i64) -> List<i64>`; see the module doc comment.
    pub(super) fn emit_local_time(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("local_time(..) expects 1 argument", Span::dummy());
            return "i8* null".into();
        };
        let ty = self.expr_ty(arg);
        let v = self.emit_expr(arg);
        let t = self.untag(&v, &ty);
        let tslot = self.tmp_name();
        self.line(&format!("  {} = alloca i64", tslot));
        self.line(&format!("  store i64 {}, i64* {}", t, tslot));
        let tm = self.tmp_name();
        self.line(&format!("  {} = alloca [64 x i8], align 8", tm));
        let tmp = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [64 x i8], [64 x i8]* {}, i64 0, i64 0", tmp, tm));
        let ok = self.tmp_name();
        match self.target {
            Target::WindowsGnu => {
                let r = self.tmp_name();
                self.line(&format!("  {} = call i32 @_localtime64_s(i8* {}, i64* {})", r, tmp, tslot));
                self.line(&format!("  {} = icmp eq i32 {}, 0", ok, r));
            }
            Target::LinuxGnu => {
                let r = self.tmp_name();
                self.line(&format!("  {} = call i8* @localtime_r(i64* {}, i8* {})", r, tslot, tmp));
                self.line(&format!("  {} = icmp ne i8* {}, null", ok, r));
            }
        }
        let tmi = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", tmi, tmp));
        let mut fields = Vec::new();
        for i in 0..9 {
            let p = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds i32, i32* {}, i64 {}", p, tmi, i));
            let f32v = self.tmp_name();
            self.line(&format!("  {} = load i32, i32* {}", f32v, p));
            let f64v = self.tmp_name();
            self.line(&format!("  {} = sext i32 {} to i64", f64v, f32v));
            fields.push(f64v);
        }
        // tm_year counts from 1900
        let year = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1900", year, fields[5]));
        fields[5] = year;
        let gmtoff = match self.target {
            Target::WindowsGnu => {
                // read every field above before this: _mkgmtime64 may
                // normalise the struct in place
                let g = self.tmp_name();
                self.line(&format!("  {} = call i64 @_mkgmtime64(i8* {})", g, tmp));
                let d = self.tmp_name();
                self.line(&format!("  {} = sub i64 {}, {}", d, g, t));
                d
            }
            Target::LinuxGnu => self.fs_load_i64(&tmp, 40),
        };
        fields.push(gmtoff);
        let raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 80)", raw));
        let data = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i64*", data, raw));
        for (i, f) in fields.iter().enumerate() {
            let p = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds i64, i64* {}, i64 {}", p, data, i));
            self.line(&format!("  store i64 {}, i64* {}", f, p));
        }
        let len = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i64 10, i64 0", len, ok));
        let elem_ty = Ty::I64;
        let payload_ty = self.list_payload_llvm_ty(&elem_ty);
        let release_fn = self.list_release_thunk_operand(&elem_ty);
        let obj = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 24, i8* {})", obj, release_fn));
        let payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", payload, obj, payload_ty));
        let df = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", df, payload_ty, payload_ty, payload));
        self.line(&format!("  store i64* {}, i64** {}", data, df));
        let lf = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", lf, payload_ty, payload_ty, payload));
        self.line(&format!("  store i64 {}, i64* {}", len, lf));
        let cf = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", cf, payload_ty, payload_ty, payload));
        self.line(&format!("  store i64 10, i64* {}", cf));
        format!("i8* {}", obj)
    }
}

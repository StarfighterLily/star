//! `process_memory() -> i64`: the bytes of memory this process has resident
//! (its working set on Windows, its resident set on Linux), or -1 if the OS
//! won't say.
//!
//! Why a builtin: the LPMUD driver in `projects/havokos` (`todo.md` HavokOS
//! P1 #6) answers `memory_info()` and heads `malloc_status()`'s report with
//! the memory the driver uses, which the reference reads from Pike's own
//! allocator. Nothing reachable from Star could ask: Windows answers through
//! `GetProcessMemoryInfo`'s `PROCESS_MEMORY_COUNTERS` out-parameter, which
//! Star's FFI can't read back (the gap `crate::codegen::fs` documents), and
//! a capitalized `extern "C"` name doesn't resolve anyway (`todo.md`
//! HavokOS P2 #1). Until then the driver reported a count of its own heap
//! slots times 64 bytes.
//!
//! `K32GetProcessMemoryInfo` (kernel32's export of the psapi call since
//! Windows 7, so no extra library) on the current-process pseudo-handle
//! (-1), with `cb` set to the 72-byte x64 `PROCESS_MEMORY_COUNTERS`, reading
//! `WorkingSetSize` at offset 16. On Linux, the second field of
//! `/proc/self/statm` (resident pages) times `sysconf(_SC_PAGESIZE)`.
//!
//! ## `Target::LinuxGnu`: seamed, not yet devbox-verified
//! Like `crate::codegen::fs`'s and `crate::codegen::clock`'s Linux arms, it
//! emits IR that compiles to an object for `x86_64-unknown-linux-gnu`, but
//! hasn't been linked and run there. See `docs/cross_platform_scope.md`.

use super::{Codegen, Target};

impl Codegen {
    /// `declare` the C symbols `process_memory` calls, for this `Codegen`'s
    /// `Target` -- called once from `emit_builtins`, like
    /// `crate::codegen::clock::declare_clock_externs`. (`fopen`/`fclose`
    /// and Linux's `sysconf` are declared elsewhere already.)
    pub(super) fn declare_procmem_externs(&mut self) {
        match self.target {
            Target::WindowsGnu => self.line("declare i32 @K32GetProcessMemoryInfo(i8*, i8*, i32)"),
            Target::LinuxGnu => self.line("declare i32 @fscanf(i8*, i8*, ...)"),
        }
    }

    /// A private NUL-terminated string constant; returns an `i8*` to it.
    fn procmem_cstr(&mut self, s: &str) -> String {
        let g = self.global_name();
        let n = s.len() + 1;
        self.global_defs.push(format!("{} = private unnamed_addr constant [{} x i8] c\"{}\\00\"", g, n, s));
        let p = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [{} x i8], [{} x i8]* {}, i64 0, i64 0", p, n, n, g));
        p
    }

    /// `process_memory() -> i64`; see the module doc comment.
    pub(super) fn emit_process_memory(&mut self) -> String {
        let r = self.tmp_name();
        match self.target {
            Target::WindowsGnu => {
                let buf = self.tmp_name();
                self.line(&format!("  {} = alloca [9 x i64], align 8", buf));
                let bufp = self.tmp_name();
                self.line(&format!("  {} = bitcast [9 x i64]* {} to i8*", bufp, buf));
                let cbp = self.tmp_name();
                self.line(&format!("  {} = bitcast i8* {} to i32*", cbp, bufp));
                self.line(&format!("  store i32 72, i32* {}", cbp));
                let ok = self.tmp_name();
                self.line(&format!("  {} = call i32 @K32GetProcessMemoryInfo(i8* inttoptr (i64 -1 to i8*), i8* {}, i32 72)", ok, bufp));
                let wsp = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds [9 x i64], [9 x i64]* {}, i64 0, i64 2", wsp, buf));
                let ws = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", ws, wsp));
                let failed = self.tmp_name();
                self.line(&format!("  {} = icmp eq i32 {}, 0", failed, ok));
                self.line(&format!("  {} = select i1 {}, i64 -1, i64 {}", r, failed, ws));
            }
            Target::LinuxGnu => {
                let path = self.procmem_cstr("/proc/self/statm");
                let mode = self.procmem_cstr("r");
                let fmt = self.procmem_cstr("%*s %ld");
                let slot = self.tmp_name();
                self.line(&format!("  {} = alloca i64, align 8", slot));
                self.line(&format!("  store i64 -1, i64* {}", slot));
                let f = self.tmp_name();
                self.line(&format!("  {} = call i8* @fopen(i8* {}, i8* {})", f, path, mode));
                let open = self.tmp_name();
                self.line(&format!("  {} = icmp ne i8* {}, null", open, f));
                let read_l = self.block_label("procmem_read");
                let done_l = self.block_label("procmem_done");
                self.line(&format!("  br i1 {}, label %{}, label %{}", open, read_l, done_l));
                self.open_block(&read_l);
                self.line(&format!("  call i32 (i8*, i8*, ...) @fscanf(i8* {}, i8* {}, i64* {})", f, fmt, slot));
                self.line(&format!("  call i32 @fclose(i8* {})", f));
                self.line(&format!("  br label %{}", done_l));
                self.open_block(&done_l);
                let pages = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", pages, slot));
                // _SC_PAGESIZE is 30 on glibc
                let psz = self.tmp_name();
                self.line(&format!("  {} = call i64 @sysconf(i32 30)", psz));
                let bytes = self.tmp_name();
                self.line(&format!("  {} = mul i64 {}, {}", bytes, pages, psz));
                let neg = self.tmp_name();
                self.line(&format!("  {} = icmp slt i64 {}, 0", neg, pages));
                self.line(&format!("  {} = select i1 {}, i64 -1, i64 {}", r, neg, bytes));
            }
        }
        format!("i64 {}", r)
    }
}

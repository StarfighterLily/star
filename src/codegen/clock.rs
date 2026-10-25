//! `clock_ms() -> i64`: milliseconds on a monotonic clock, for measuring
//! elapsed time and scheduling (the zero point is arbitrary: boot, on both
//! targets).
//!
//! Why a builtin: the LPMUD driver in `projects/havokos` (`todo.md` HavokOS
//! M5) schedules call_outs and heart beats and enforces the per-evaluation
//! time limit, all against a wall clock that must keep running for the
//! months a MUD stays up. Nothing reachable from Star did that:
//! - C's `clock()` is wall time on msvcrt but returns `(clock_t)-1` for
//!   good once its 32-bit millisecond count passes 2^31, after about 24.8
//!   days, and it's CPU time on glibc;
//! - `_time64` counts whole seconds, too coarse for a 2-second beat split
//!   into slots;
//! - `GetTickCount64` can't be declared from Star at all, since a
//!   capitalized `extern "C"` name resolves as a type (`todo.md` HavokOS
//!   P2 #1), and `clock_gettime` answers through a `struct timespec`
//!   out-parameter Star can't read (the same gap `crate::codegen::fs`
//!   documents).
//!
//! So it's a thin wrapper, the same shape as `crate::codegen::fs`:
//! `GetTickCount64()` on `Target::WindowsGnu` (kernel32, linked by
//! default; milliseconds since boot, 64-bit, no wrap), and
//! `clock_gettime(CLOCK_MONOTONIC, &ts)` on `Target::LinuxGnu` as
//! `tv_sec * 1000 + tv_nsec / 1000000` (glibc x86_64 `struct timespec`: two
//! `i64`s, `CLOCK_MONOTONIC` = 1). Resolution is whatever the OS gives:
//! 10-16 ms on Windows by default, which is fine for scheduling and for a
//! multi-second evaluation limit, not for benchmarking short spans.
//!
//! ## `Target::LinuxGnu`: seamed, not yet devbox-verified
//! Like `crate::codegen::fs`'s Linux arm, it emits IR that compiles to an
//! object for `x86_64-unknown-linux-gnu`, but hasn't been linked and run
//! there. See `docs/cross_platform_scope.md`.

use super::{Codegen, Target};

impl Codegen {
    /// `declare` the C symbol `clock_ms` calls, for this `Codegen`'s
    /// `Target` -- called once from `emit_builtins`, like
    /// `crate::codegen::fs::declare_fs_externs`.
    pub(super) fn declare_clock_externs(&mut self) {
        match self.target {
            Target::WindowsGnu => self.line("declare i64 @GetTickCount64()"),
            Target::LinuxGnu => self.line("declare i32 @clock_gettime(i32, i8*)"),
        }
    }

    /// `clock_ms() -> i64`; see the module doc comment.
    pub(super) fn emit_clock_ms(&mut self) -> String {
        let r = self.tmp_name();
        match self.target {
            Target::WindowsGnu => {
                self.line(&format!("  {} = call i64 @GetTickCount64()", r));
            }
            Target::LinuxGnu => {
                let ts = self.tmp_name();
                self.line(&format!("  {} = alloca [2 x i64], align 8", ts));
                let p = self.tmp_name();
                self.line(&format!("  {} = bitcast [2 x i64]* {} to i8*", p, ts));
                let rc = self.tmp_name();
                self.line(&format!("  {} = call i32 @clock_gettime(i32 1, i8* {})", rc, p));
                let sp = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds [2 x i64], [2 x i64]* {}, i64 0, i64 0", sp, ts));
                let sec = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", sec, sp));
                let np = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds [2 x i64], [2 x i64]* {}, i64 0, i64 1", np, ts));
                let nsec = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", nsec, np));
                let ms = self.tmp_name();
                self.line(&format!("  {} = mul i64 {}, 1000", ms, sec));
                let frac = self.tmp_name();
                self.line(&format!("  {} = sdiv i64 {}, 1000000", frac, nsec));
                self.line(&format!("  {} = add i64 {}, {}", r, ms, frac));
            }
        }
        format!("i64 {}", r)
    }
}

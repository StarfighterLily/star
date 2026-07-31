//! OS-primitives seam: every place codegen needs a raw thread, semaphore, or
//! hardware-core-count call goes through one of the `emit_*`/`declare_*`
//! methods below rather than hand-writing a `CreateThread`/`WaitForSingleObject`
//! (or POSIX equivalent) call inline. This is the retrofit point `todo.md`'s
//! "make the Windows-only scope an explicit decision" item asked for: before
//! this module existed, `par_pool.rs`, `symbol.rs`, `vector_math.rs`, and
//! `system.rs` each hand-rolled Win32 IR text directly, so adding a second
//! target meant hunting down every call site by hand. Now they all route
//! through here, so a third backend (say, macOS) is a new `match` arm in
//! this file, not a grep-and-replace across the codegen crate.
//!
//! ## What's *not* here
//! GDI-based text rendering (`crate::codegen::system_font`) has no cheap
//! portable equivalent -- there's no POSIX syscall that rasterizes a
//! TrueType glyph, only a from-scratch rendering backend (FreeType,
//! `stb_truetype`, or a second vendored font library) would do it, which is
//! a real, large feature addition, not a seam retrofit. See that module's
//! own doc comment: it stays an explicit, acknowledged Windows-only
//! dependency, with `crate::codegen::font`'s hand-rolled bitmap font as the
//! already-portable fallback. Text rendering is now the *only* unseamed
//! Windows-only surface left -- `crate::codegen::net`'s Winsock calls and
//! `crate::codegen::os`'s `_putenv_s` call each got their own
//! `Target::LinuxGnu` arm (not centralized here), and this module's own
//! `pthread_create`/`sem_init`/`sysconf` arm -- the oldest cross-platform
//! claim in this crate -- went from IR-shape-inspected to devbox-link-
//! verified 2026-07-30, right alongside them: a real `par` dispatch across
//! 200 entities produced the correct result under real concurrent
//! `pthread_create`/`sem_wait`/`sem_post`, not just serial fallback, at
//! several `STAR_WORKERS` counts and repeated runs with no races observed.
//! Every `declare` this crate emits for a still-Windows-only surface stays
//! unconditional regardless of `Target` (an unreferenced `declare` costs
//! nothing at link time). See `docs/cross_platform_scope.md` for the full
//! inventory and the fonts gap's own concrete (still unscheduled)
//! porting plan.
//!
//! ## Semaphore representation
//! Win32's `CreateSemaphoreA` returns an opaque kernel `HANDLE` (`i8*`);
//! POSIX has no such handle -- a `sem_t` is a plain value type that must live
//! at a stable address the caller owns. `emit_alloc_semaphore` papers over
//! that difference by always handing back an `i8*` "semaphore handle": on
//! Linux it's a freshly `malloc`'d `sem_t`-sized buffer, already
//! `sem_init`'d. That lets every call site (and every existing global array
//! of semaphore handles, e.g. `par_pool`'s `@par.pool.start_sem`) stay
//! `i8*`-shaped and target-agnostic.

use super::Codegen;

/// Which native OS/ABI the emitted LLVM IR -- and the executable `clang`
/// produces from it -- targets. Orthogonal to what OS the `star` compiler
/// binary itself runs on: this compiler cross-emits textual LLVM IR, so a
/// `star` built for Windows can still emit a `LinuxGnu`-target `.ll` file
/// (whether `clang` on hand can actually *link* it into a working ELF binary
/// is a separate, environment-dependent question -- see `crate::main`'s
/// `--target` flag doc comment).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum Target {
    /// `x86_64-w64-windows-gnu` -- this compiler's original, and still
    /// default, target. Every Win32-specific builtin (`crate::codegen::sdl`'s
    /// window/audio/gamepad bindings ride on cross-platform SDL2, but
    /// `crate::codegen::system_font`'s GDI text rendering is Windows-only by
    /// construction) is only ever *called* under this target -- nothing
    /// about `Target::LinuxGnu` makes those builtins portable, it only
    /// affects the primitives this module owns.
    #[default]
    WindowsGnu,
    /// `x86_64-unknown-linux-gnu`. Only the primitives this module emits
    /// (threads, semaphores, core-count detection) have a real second
    /// implementation under this target; a Star program calling
    /// `font_load_system`/`gamepad_*`-via-Winsock-style Windows-only
    /// builtins still won't link under it -- see this module's own doc
    /// comment.
    LinuxGnu,
}

impl Target {
    /// The LLVM `target triple` string this target's emitted IR declares.
    pub fn triple(self) -> &'static str {
        match self {
            Target::WindowsGnu => "x86_64-w64-windows-gnu",
            Target::LinuxGnu => "x86_64-unknown-linux-gnu",
        }
    }

    /// Short, stable name for this target, as accepted by `star build
    /// --target=<name>` and printed in diagnostics -- kept separate from
    /// `triple()` (clang/LLVM's own spelling) so the CLI surface doesn't
    /// have to change if a future target's real triple does (e.g. gaining
    /// an explicit vendor field).
    pub fn name(self) -> &'static str {
        match self {
            Target::WindowsGnu => "windows",
            Target::LinuxGnu => "linux",
        }
    }

    /// Parse a `--target` CLI value; `None` for anything unrecognized (the
    /// caller turns that into a clean CLI error rather than a panic).
    pub fn parse(s: &str) -> Option<Target> {
        match s {
            "windows" => Some(Target::WindowsGnu),
            "linux" => Some(Target::LinuxGnu),
            _ => None,
        }
    }
}

/// `sizeof(sem_t)` on glibc/x86-64: a 32-byte opaque byte array
/// (`__SIZEOF_SEM_T` in `bits/semaphore.h`). Only `Target::LinuxGnu`'s
/// `emit_alloc_semaphore` allocates one; declared here (rather than duplicated
/// at each call site) since it's the one POSIX-specific size this module's
/// callers never need to know about directly.
const LINUX_SEM_T_SIZE: u32 = 32;

/// `_SC_NPROCESSORS_ONLN` (`bits/confname.h`, glibc/x86-64): the `sysconf`
/// query this module's `emit_detect_core_count` uses as `GetSystemInfo`'s
/// POSIX counterpart -- the number of processors currently online, matching
/// `GetSystemInfo`'s own `dwNumberOfProcessors` semantics (not
/// `_SC_NPROCESSORS_CONF`, which counts configured-but-possibly-offline
/// processors instead).
const SC_NPROCESSORS_ONLN: i32 = 84;

impl Codegen {
    /// `declare` every C symbol this module's other `emit_*` methods call,
    /// for whichever `Target` this `Codegen` was constructed with. Called
    /// once from `emit_builtins`, unconditionally (mirroring every other
    /// fixed-prelude `declare` there) -- a program that never uses `par`/
    /// `swarm`/`Symbol`/`rand` still pays nothing for an unreferenced
    /// `declare`, so there's no reason to gate this on whether the module
    /// actually needs it.
    pub(super) fn declare_platform_threading_externs(&mut self) {
        match self.target {
            Target::WindowsGnu => {
                self.line("declare i8* @CreateThread(i8*, i64, i8*, i8*, i32, i32*)");
                self.line("declare i32 @WaitForSingleObject(i8*, i32)");
                // Synchronization primitives backing the persistent
                // `par`/`swarm` worker-thread pool -- see `par_pool.rs`.
                self.line("declare i8* @CreateSemaphoreA(i8*, i32, i32, i8*)");
                self.line("declare i32 @ReleaseSemaphore(i8*, i32, i32*)");
                self.line("declare i32 @GetCurrentThreadId()");
                // Runtime worker-count detection (`par_pool.rs`'s
                // `ensure_init`): `GetSystemInfo` for the real core count,
                // `atoi` (declared unconditionally elsewhere -- shared with
                // `env_get`) to parse an optional `STAR_WORKERS` override.
                self.line("declare void @GetSystemInfo(i8*)");
            }
            Target::LinuxGnu => {
                // `pthread_t` is `unsigned long` (8 bytes) on x86-64 glibc,
                // hence the `i64*` out-param and `i64` return type below.
                self.line("declare i32 @pthread_create(i64*, i8*, i8* (i8*)*, i8*)");
                self.line("declare i64 @pthread_self()");
                self.line("declare i32 @sem_init(i8*, i32, i32)");
                self.line("declare i32 @sem_wait(i8*)");
                self.line("declare i32 @sem_post(i8*)");
                self.line("declare i64 @sysconf(i32)");
            }
        }
    }

    /// Create a persistent OS thread running `entry` (an already-`define`d
    /// `i32 (i8*)`-shaped function, e.g. `@par.pool.worker_main`) with `arg`
    /// (an `i8*` register or literal) as its sole parameter. The thread's
    /// own handle/id is never captured -- every caller of this method
    /// creates threads that live for the process's lifetime and are never
    /// joined or closed (see `par_pool.rs`'s own doc comment on why), so
    /// there is nothing useful to do with it.
    pub(super) fn emit_create_persistent_thread(&mut self, entry_fn: &str, arg: &str) {
        match self.target {
            Target::WindowsGnu => {
                self.line(&format!(
                    "  call i8* @CreateThread(i8* null, i64 0, i8* bitcast (i32 (i8*)* @{} to i8*), i8* {}, i32 0, i32* null)",
                    entry_fn, arg
                ));
            }
            Target::LinuxGnu => {
                // `@platform.pthread_out`'s value is never read back (see
                // its own doc comment at the declaration site in
                // `par_pool.rs`) -- it exists only because `pthread_create`
                // requires a non-null `pthread_t*` out-param.
                self.line(&format!(
                    "  call i32 @pthread_create(i64* @platform.pthread_out, i8* null, i8* (i8*)* bitcast (i32 (i8*)* @{} to i8* (i8*)*), i8* {})",
                    entry_fn, arg
                ));
            }
        }
    }

    /// Allocate a new binary/counting semaphore initialized to `initial`
    /// (`0` = locked/empty, `1` = unlocked/one-permit), returning an `i8*`
    /// "handle" usable by `emit_semaphore_wait`/`emit_semaphore_post` --
    /// either a real Win32 kernel handle or a `malloc`'d, `sem_init`'d
    /// `sem_t` buffer. See this module's own doc comment for why both
    /// backends present the same `i8*` shape.
    pub(super) fn emit_alloc_semaphore(&mut self, initial: u32) -> String {
        match self.target {
            Target::WindowsGnu => {
                let h = self.tmp_name();
                self.line(&format!("  {} = call i8* @CreateSemaphoreA(i8* null, i32 {}, i32 1, i8* null)", h, initial));
                h
            }
            Target::LinuxGnu => {
                let buf = self.tmp_name();
                self.line(&format!("  {} = call i8* @malloc(i64 {})", buf, LINUX_SEM_T_SIZE));
                self.line(&format!("  call i32 @sem_init(i8* {}, i32 0, i32 {})", buf, initial));
                buf
            }
        }
    }

    /// Block until `handle` (an `emit_alloc_semaphore`-produced `i8*`) has a
    /// permit available, consuming one -- `WaitForSingleObject(h, INFINITE)`
    /// or `sem_wait`.
    pub(super) fn emit_semaphore_wait(&mut self, handle: &str) {
        match self.target {
            Target::WindowsGnu => {
                let r = self.tmp_name();
                self.line(&format!("  {} = call i32 @WaitForSingleObject(i8* {}, i32 -1)", r, handle));
            }
            Target::LinuxGnu => {
                self.line(&format!("  call i32 @sem_wait(i8* {})", handle));
            }
        }
    }

    /// Release one permit on `handle` -- `ReleaseSemaphore(h, 1, null)` or
    /// `sem_post`.
    pub(super) fn emit_semaphore_post(&mut self, handle: &str) {
        match self.target {
            Target::WindowsGnu => {
                let r = self.tmp_name();
                self.line(&format!("  {} = call i32 @ReleaseSemaphore(i8* {}, i32 1, i32* null)", r, handle));
            }
            Target::LinuxGnu => {
                self.line(&format!("  call i32 @sem_post(i8* {})", handle));
            }
        }
    }

    /// The calling thread's own id/handle, widened to a uniform `i64` so
    /// every caller (`par_pool.rs`'s worker-registration and reentrancy
    /// check) can compare ids without caring which backend produced them --
    /// `GetCurrentThreadId` (a 32-bit `DWORD`, `zext`'d) or `pthread_self`
    /// (already 64-bit on this target). Returns the register name holding
    /// the `i64` value.
    pub(super) fn emit_current_thread_id64(&mut self) -> String {
        match self.target {
            Target::WindowsGnu => {
                let r = self.tmp_name();
                self.line(&format!("  {} = call i32 @GetCurrentThreadId()", r));
                let r64 = self.tmp_name();
                self.line(&format!("  {} = zext i32 {} to i64", r64, r));
                r64
            }
            Target::LinuxGnu => {
                let r = self.tmp_name();
                self.line(&format!("  {} = call i64 @pthread_self()", r));
                r
            }
        }
    }

    /// The number of processors currently online, as a bare `i32` register
    /// -- `GetSystemInfo`'s `dwNumberOfProcessors` field or
    /// `sysconf(_SC_NPROCESSORS_ONLN)`, truncated to `i32` (the pool's
    /// worker count is bounded by `par_pool::MAX_WORKERS`, nowhere near
    /// `i64`'s range). Unclamped -- `par_pool.rs`'s `ensure_init` applies the
    /// same `[MIN_WORKERS, MAX_WORKERS]` clamp to this result regardless of
    /// which backend produced it.
    pub(super) fn emit_detect_core_count(&mut self) -> String {
        match self.target {
            Target::WindowsGnu => {
                // `SYSTEM_INFO.dwNumberOfProcessors` sits at byte offset
                // `SYSTEM_INFO_NUM_PROCESSORS_OFFSET` on x86-64 -- see
                // `par_pool.rs`'s `SYSTEM_INFO_SIZE`/
                // `SYSTEM_INFO_NUM_PROCESSORS_OFFSET` doc comments for the
                // field layout this falls out of. `@par.pool.sysinfo_buf` is
                // declared once by `ensure_par_pool_emitted`, sized to the
                // whole struct since `GetSystemInfo` writes it in full.
                let sysinfo_ptr = self.tmp_name();
                self.line(&format!(
                    "  {} = getelementptr inbounds [{} x i8], [{} x i8]* @par.pool.sysinfo_buf, i64 0, i64 0",
                    sysinfo_ptr,
                    super::par_pool::SYSTEM_INFO_SIZE,
                    super::par_pool::SYSTEM_INFO_SIZE
                ));
                self.line(&format!("  call void @GetSystemInfo(i8* {})", sysinfo_ptr));
                let nproc_ptr8 = self.tmp_name();
                self.line(&format!(
                    "  {} = getelementptr inbounds [{} x i8], [{} x i8]* @par.pool.sysinfo_buf, i64 0, i64 {}",
                    nproc_ptr8,
                    super::par_pool::SYSTEM_INFO_SIZE,
                    super::par_pool::SYSTEM_INFO_SIZE,
                    super::par_pool::SYSTEM_INFO_NUM_PROCESSORS_OFFSET
                ));
                let nproc_ptr = self.tmp_name();
                self.line(&format!("  {} = bitcast i8* {} to i32*", nproc_ptr, nproc_ptr8));
                let detected_raw = self.tmp_name();
                self.line(&format!("  {} = load i32, i32* {}", detected_raw, nproc_ptr));
                detected_raw
            }
            Target::LinuxGnu => {
                let r = self.tmp_name();
                self.line(&format!("  {} = call i64 @sysconf(i32 {})", r, SC_NPROCESSORS_ONLN));
                let r32 = self.tmp_name();
                self.line(&format!("  {} = trunc i64 {} to i32", r32, r));
                r32
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::Target;

    /// `Target::default()` -- what `Codegen::new()` uses with no target
    /// argument at all -- is `WindowsGnu`, not `LinuxGnu`: this compiler's
    /// original, well-tested, end-to-end-built-and-run target must stay the
    /// implicit choice for every caller that predates `Target` existing
    /// (every one of this crate's ~1500 other codegen tests, plus `star
    /// build` with no `--target` flag).
    #[test]
    fn default_target_is_windows() {
        assert_eq!(Target::default(), Target::WindowsGnu);
    }

    #[test]
    fn triples_match_expected_llvm_spellings() {
        assert_eq!(Target::WindowsGnu.triple(), "x86_64-w64-windows-gnu");
        assert_eq!(Target::LinuxGnu.triple(), "x86_64-unknown-linux-gnu");
    }

    /// `Target::parse` round-trips `Target::name`'s own spelling -- the
    /// contract `--target=<name>` (`crate::main`'s `TargetArg`) depends on.
    #[test]
    fn parse_round_trips_name() {
        for t in [Target::WindowsGnu, Target::LinuxGnu] {
            assert_eq!(Target::parse(t.name()), Some(t));
        }
    }

    #[test]
    fn parse_rejects_unknown_name() {
        assert_eq!(Target::parse("macos"), None);
        assert_eq!(Target::parse(""), None);
        assert_eq!(Target::parse("Windows"), None, "should be case-sensitive, matching every other `ValueEnum` in this CLI");
    }
}

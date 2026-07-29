//! Minimal OS surface (todo.md #2): `env_get`/`env_set` builtins, thin
//! wrappers over the C runtime's `getenv`/`_putenv_s`. `args()` builds a
//! `List<str>` and lives alongside the rest of `List<T>`'s construction
//! logic instead -- see `crate::codegen::list::emit_args`.
//!
//! ## Windows-only today, but the cheapest gap in the codebase
//! `getenv` (`emit_env_get`) is already POSIX-standard and needs no
//! `Target` branch at all. `_putenv_s` (`emit_env_set`) is a Microsoft CRT
//! extension, not POSIX -- the direct equivalent is glibc's
//! `setenv(name, value, 1) -> i32`, same argument shape, "0 on success"
//! convention preserved. A single `Target::LinuxGnu` match arm in
//! `emit_env_set` closes this; see `docs/cross_platform_scope.md`.

use crate::diagnostics::Span;
use crate::types::*;

use super::Codegen;

impl Codegen {
    /// `env_get(name: str) -> str`: `getenv`, copied into a fresh, owned
    /// `str` the same way `emit_ptr_to_str` bridges any other foreign
    /// `char*` -- a missing variable yields `""` rather than a null `ptr`,
    /// matching `file_read`/`read_line`'s established EOF convention rather
    /// than introducing an Option/Result type Star doesn't have.
    pub(super) fn emit_env_get(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("env_get(..) expects 1 argument", Span::dummy());
            return "i8* null".into();
        };
        let name = self.emit_raw_str_ptr(arg);
        let raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @getenv(i8* {})", raw, name));
        // `name` is done being read -- release whatever `emit_raw_str_ptr`
        // left us owning (see its own doc comment).
        self.line(&format!("  call void @star_rc_release(i8* {})", name));
        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, raw));
        let null_label = self.block_label("env_get_null");
        let real_label = self.block_label("env_get_real");
        let end_label = self.block_label("env_get_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, null_label, real_label));

        self.open_block(&null_label);
        let empty = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 1, i8* null)", empty));
        self.line(&format!("  store i8 0, i8* {}", empty));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&real_label);
        let len = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", len, raw));
        let total = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", total, len));
        let total64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", total64, total));
        let buf = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 {}, i8* null)", buf, total64));
        self.line(&format!("  call i8* @strcpy(i8* {}, i8* {})", buf, raw));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let result = self.tmp_name();
        self.line(&format!("  {} = phi i8* [ {}, %{} ], [ {}, %{} ]", result, empty, null_label, buf, real_label));
        format!("i8* {}", result)
    }

    /// `env_set(name: str, value: str) -> bool`: hands both strings straight
    /// to `_putenv_s`. Unlike `_putenv` (which stores the pointer it's given
    /// directly in the process's environment block, making it a use-after-
    /// free hazard the moment the caller frees or reuses that memory),
    /// `_putenv_s` copies `name`/`value` internally, so there's no scratch
    /// buffer here for this function to own or free. Returns whether the
    /// underlying call reported success (`_putenv_s` returns `0` on
    /// success, nonzero `errno_t` on failure).
    pub(super) fn emit_env_set(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("env_set(..) expects 2 arguments (name, value)", Span::dummy());
            return "i1 false".into();
        }
        let name = self.emit_raw_str_ptr(&args[0]);
        let value = self.emit_raw_str_ptr(&args[1]);

        let result = self.tmp_name();
        self.line(&format!("  {} = call i32 @_putenv_s(i8* {}, i8* {})", result, name, value));
        // `name`/`value` are done being read -- release whatever
        // `emit_raw_str_ptr` left us owning for each (see its own doc
        // comment).
        self.line(&format!("  call void @star_rc_release(i8* {})", name));
        self.line(&format!("  call void @star_rc_release(i8* {})", value));
        let ok = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 0", ok, result));
        format!("i1 {}", ok)
    }
}

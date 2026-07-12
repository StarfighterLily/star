//! Minimal OS surface (todo.md #2): `env_get`/`env_set` builtins, thin
//! wrappers over the C runtime's `getenv`/`_putenv`. `args()` builds a
//! `List<str>` and lives alongside the rest of `List<T>`'s construction
//! logic instead -- see `crate::codegen::list::emit_args`.

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
        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, raw));
        let null_label = self.block_label("env_get_null");
        let real_label = self.block_label("env_get_real");
        let end_label = self.block_label("env_get_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, null_label, real_label));

        self.line(&format!("{}:", null_label));
        let empty = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 1, i8* null)", empty));
        self.line(&format!("  store i8 0, i8* {}", empty));
        self.line(&format!("  br label %{}", end_label));

        self.line(&format!("{}:", real_label));
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

        self.line(&format!("{}:", end_label));
        let result = self.tmp_name();
        self.line(&format!("  {} = phi i8* [ {}, %{} ], [ {}, %{} ]", result, empty, null_label, buf, real_label));
        format!("i8* {}", result)
    }

    /// `env_set(name: str, value: str) -> bool`: builds a `"NAME=VALUE"`
    /// buffer and hands it to `_putenv`, which -- per its documented
    /// behavior on this target -- copies the string into the process's own
    /// environment block rather than retaining the pointer, so the buffer
    /// is `malloc`/`free`d as a plain transient scratch allocation (not
    /// `star_rc_alloc`'d -- nothing keeps a reference to it once this call
    /// returns). Returns whether the underlying call reported success
    /// (`_putenv` returns `0` on success, nonzero on failure).
    pub(super) fn emit_env_set(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("env_set(..) expects 2 arguments (name, value)", Span::dummy());
            return "i1 false".into();
        }
        let name = self.emit_raw_str_ptr(&args[0]);
        let value = self.emit_raw_str_ptr(&args[1]);

        let name_len = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", name_len, name));
        let value_len = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", value_len, value));
        let sum = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, {}", sum, name_len, value_len));
        // `+2`: one byte for the `=` separator, one for the NUL terminator.
        let total = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 2", total, sum));
        let total64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", total64, total));
        let buf = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", buf, total64));

        self.line(&format!("  call i8* @strcpy(i8* {}, i8* {})", buf, name));
        let eq_g = self.global_name();
        self.global_defs.push(format!("{} = private unnamed_addr constant [2 x i8] c\"=\\00\"", eq_g));
        let eq_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [2 x i8], [2 x i8]* {}, i64 0, i64 0", eq_ptr, eq_g));
        self.line(&format!("  call i8* @strcat(i8* {}, i8* {})", buf, eq_ptr));
        self.line(&format!("  call i8* @strcat(i8* {}, i8* {})", buf, value));

        let result = self.tmp_name();
        self.line(&format!("  {} = call i32 @_putenv(i8* {})", result, buf));
        self.line(&format!("  call void @free(i8* {})", buf));
        let ok = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 0", ok, result));
        format!("i1 {}", ok)
    }
}

//! SQLite's two out-parameter calls: `sqlite_open(path) -> ptr` and
//! `sqlite_prepare(db, sql) -> ptr`.
//!
//! Why: the LPMUD driver in `projects/havokos` (`todo.md` HavokOS P1 #7)
//! implements the reference's SQLite efuns (db_open()/db_query()/db_info()/
//! db_close(), `havok/sqldb.pike`) over the real SQLite library. Almost all
//! of SQLite's C API is plain scalars and pointers that an `extern "C"`
//! binding reaches directly (`sqlite3_step`, `sqlite3_column_int64`,
//! `sqlite3_bind_text`, ...; a returned `const char*` goes through
//! `ptr_to_str`). Exactly two calls answer through an out-parameter, a
//! `sqlite3**` or `sqlite3_stmt**`, which Star's FFI can't read back
//! (`projects/havokos/NOTES.md` constraint #9, the gap
//! `crate::codegen::fs` and `crate::codegen::procmem` fill the same way).
//! So these two are compiler builtins and the rest stays in Star code.
//! Wrapping the whole API as builtins, the way `crate::codegen::sdl` wraps
//! SDL, was considered and rejected: it would add a dozen builtins whose
//! only job is to forward scalars `extern "C"` already forwards.
//!
//! - `sqlite_open(path)`: `sqlite3_open_v2(path, &db, SQLITE_OPEN_READWRITE
//!   | SQLITE_OPEN_CREATE, NULL)`, which is what `sqlite3_open()` does.
//!   SQLite hands back a connection even when the open fails (a missing
//!   directory, say), carrying the error, so the result is null only when
//!   SQLite couldn't allocate one. The caller checks `sqlite3_errcode(db)`,
//!   reads `sqlite3_errmsg(db)` and closes it, exactly as in C.
//! - `sqlite_prepare(db, sql)`: `sqlite3_prepare_v2(db, sql, -1, &stmt,
//!   NULL)`, the first statement of `sql`. Null on an error *and* when the
//!   text holds no statement at all (only whitespace or comments), which C
//!   tells apart by `sqlite3_errcode(db)` (0, "not an error", for the
//!   latter). The tail the dropped `pzTail` would give is
//!   `sql[len(ptr_to_str(sqlite3_sql(stmt)))..]`: `sqlite3_sql()` keeps the
//!   text the statement was prepared from, which runs exactly to the tail
//!   (checked against SQLite 3.54.1 in `tests/frontend_sqlite.rs`).
//!   A null `db` aborts with a message rather than reaching SQLite, which
//!   would crash, the same treatment `ptr_to_str` gives a null pointer.
//!
//! `str`'s zero value is a null pointer, so both pass the path or SQL
//! through `emit_str_or_empty`, like every `str` builtin:
//! `sqlite3_prepare_v2` on a null text is a misuse, where "" is just a
//! statement-less string.
//!
//! ## Linking, and declared on first use
//! A program that calls either builtin links SQLite itself: `-L
//! sqlite/lib/x64 -l sqlite3` on Windows (`sqlite/` holds the
//! x64 DLL and an import library made from its `.def`; see
//! `sqlite/README.md`), with `sqlite3.dll` beside the executable at run
//! time, or the system's `libsqlite3` on Linux. Like
//! `crate::codegen::net_server`'s, the two C symbols are `declare`d only by
//! programs that use the builtins (`declare_lazy`), so every other program
//! keeps building without the library. A program that also declares
//! `sqlite3_open_v2`/`sqlite3_prepare_v2` through `extern "C"` collides with
//! that `declare`; the builtin is the way to reach those two.
//!
//! ## No `Target` seam
//! SQLite's C API, and both calls' argument shapes, are the same on every
//! platform SQLite builds for, so unlike the OS-facing builtins there is
//! nothing to split on `Target`: the Linux object references the same two
//! symbols, which `libsqlite3.so` exports. Like the other Linux arms it has
//! been checked by the IR verifier but not linked and run on the devbox
//! (`docs/cross_platform_scope.md`).

use crate::diagnostics::Span;
use crate::types::*;

use super::Codegen;

/// `SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE`, `sqlite3_open()`'s flags.
const SQLITE_OPEN_READWRITE_CREATE: i32 = 0x2 | 0x4;

impl Codegen {
    /// `sqlite_open(path: str) -> ptr`; see the module doc comment.
    pub(super) fn emit_sqlite_open(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("sqlite_open(..) expects 1 argument", Span::dummy());
            return "i8* null".into();
        };
        self.declare_lazy("declare i32 @sqlite3_open_v2(i8*, i8**, i32, i8*)");
        let raw = self.emit_raw_str_ptr(arg);
        let path = self.emit_str_or_empty(&raw);
        let slot = self.tmp_name();
        self.line(&format!("  {} = alloca i8*, align 8", slot));
        self.line(&format!("  store i8* null, i8** {}", slot));
        self.line(&format!(
            "  call i32 @sqlite3_open_v2(i8* {}, i8** {}, i32 {}, i8* null)",
            path, slot, SQLITE_OPEN_READWRITE_CREATE
        ));
        self.line(&format!("  call void @star_rc_release(i8* {})", raw));
        let db = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", db, slot));
        format!("i8* {}", db)
    }

    /// `sqlite_prepare(db: ptr, sql: str) -> ptr`; see the module doc
    /// comment.
    pub(super) fn emit_sqlite_prepare(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("sqlite_prepare(..) expects 2 arguments", Span::dummy());
            return "i8* null".into();
        }
        self.declare_lazy("declare i32 @sqlite3_prepare_v2(i8*, i8*, i32, i8**, i8**)");
        let dv = self.emit_expr(&args[0]);
        let db = self.untag(&dv, &Ty::Ptr);
        let raw = self.emit_raw_str_ptr(&args[1]);
        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, db));
        let fail_label = self.block_label("sqlite_prepare_null");
        let ok_label = self.block_label("sqlite_prepare_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, fail_label, ok_label));
        self.open_block(&fail_label);
        self.emit_abort_with_message("star runtime error: sqlite_prepare(..) called with a null connection\n");

        self.open_block(&ok_label);
        let sql = self.emit_str_or_empty(&raw);
        let slot = self.tmp_name();
        self.line(&format!("  {} = alloca i8*, align 8", slot));
        self.line(&format!("  store i8* null, i8** {}", slot));
        self.line(&format!(
            "  call i32 @sqlite3_prepare_v2(i8* {}, i8* {}, i32 -1, i8** {}, i8** null)",
            db, sql, slot
        ));
        self.line(&format!("  call void @star_rc_release(i8* {})", raw));
        let st = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", st, slot));
        format!("i8* {}", st)
    }
}

//! `sqlite_open()`/`sqlite_prepare()` (`crate::codegen::sqlite`): the two
//! SQLite calls that answer through an out-parameter, so Star's FFI can't
//! make them itself. Added for the `projects/havokos` LPMUD driver's
//! db_open()/db_query() (`todo.md` HavokOS P1 #7); the rest of the API is
//! plain `extern "C"`, which these runtime tests use the way the driver
//! does. Runtime tests link `sqlite/lib/x64` (`compile_and_run_sqlite`).

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

/// The `extern "C"` half of the API the runtime tests call.
const EXTERNS: &str = "extern \"C\" fn sqlite3_errcode(db: ptr) -> i32
extern \"C\" fn sqlite3_errmsg(db: ptr) -> ptr
extern \"C\" fn sqlite3_step(st: ptr) -> i32
extern \"C\" fn sqlite3_finalize(st: ptr) -> i32
extern \"C\" fn sqlite3_close_v2(db: ptr) -> i32
extern \"C\" fn sqlite3_column_int64(st: ptr, i: i32) -> i64
extern \"C\" fn sqlite3_column_text(st: ptr, i: i32) -> ptr
extern \"C\" fn sqlite3_sql(st: ptr) -> ptr
extern \"C\" fn sqlite3_bind_text(st: ptr, i: i32, s: str, n: i32, d: i64) -> i32

fn exec(db: ptr, sql: str):
    let st = sqlite_prepare(db, sql)
    let rc = sqlite3_step(st)
    let f = sqlite3_finalize(st)
";

fn run(name: &str, body: &str) -> String {
    let out = compile_and_run_sqlite(name, &format!("{}\n{}", EXTERNS, body), None);
    assert!(out.status.success(), "exit {:?}, stderr: {}", out.status, String::from_utf8_lossy(&out.stderr));
    String::from_utf8_lossy(&out.stdout).replace("\r\n", "\n")
}

/// Both builtins return a `ptr`.
#[test]
fn typecheck_sqlite_builtins_return_ptr() {
    assert_eq!(typed_fn_result_ty("fn f() -> ptr:\n    sqlite_open(\":memory:\")\n"), Ty::Ptr);
    assert_eq!(typed_fn_result_ty("fn f(db: ptr) -> ptr:\n    sqlite_prepare(db, \"select 1\")\n"), Ty::Ptr);
}

/// `sqlite_open` takes one `str`; `sqlite_prepare` a `ptr` then a `str`.
#[test]
fn typecheck_sqlite_builtins_reject_wrong_arguments() {
    for src in [
        "fn main():\n    let d = sqlite_open(5)\n",
        "fn main():\n    let d = sqlite_open()\n",
        "fn main():\n    let s = sqlite_prepare(\"x\", \"select 1\")\n",
        "fn main():\n    let s = sqlite_prepare(null_ptr(), 1)\n",
        "fn main():\n    let s = sqlite_prepare(null_ptr())\n",
    ] {
        let module = Driver::parse(src).expect("should parse");
        assert!(Driver::check(&module).is_err(), "should be a type error: {}", src);
    }
}

/// The two C symbols are declared only by programs that use the builtins,
/// so nothing else needs SQLite to link.
#[test]
fn codegen_sqlite_symbols_declared_only_on_use() {
    let plain = Driver::codegen(&Driver::check(&Driver::parse("fn main():\n    println(\"x\")\n").unwrap()).unwrap()).unwrap();
    assert!(!plain.contains("sqlite3_"), "{}", plain);
    let src = "fn main():\n    let d = sqlite_open(\":memory:\")\n    let s = sqlite_prepare(d, \"select 1\")\n";
    let ir = Driver::codegen(&Driver::check(&Driver::parse(src).unwrap()).unwrap()).unwrap();
    assert!(ir.contains("declare i32 @sqlite3_open_v2(i8*, i8**, i32, i8*)"), "{}", ir);
    assert!(ir.contains("declare i32 @sqlite3_prepare_v2(i8*, i8*, i32, i8**, i8**)"), "{}", ir);
    // sqlite3_open()'s flags, READWRITE | CREATE, and the whole SQL text
    assert!(ir.contains("i32 6, i8* null)"), "{}", ir);
    assert!(ir.contains("i32 -1, i8** %"), "{}", ir);
}

/// The IR is target-independent; the Linux build verifies and compiles to
/// an object referencing the same two symbols.
#[test]
fn codegen_sqlite_linux_target_compiles() {
    let src = "fn main():\n    let d = sqlite_open(\"x.db\")\n    let s = sqlite_prepare(d, \"select 1\")\n";
    let typed = Driver::check(&Driver::parse(src).unwrap()).unwrap();
    let v = Driver::codegen_verified_for_target(&typed, star::codegen::Target::LinuxGnu).expect("should codegen");
    assert!(v.errors.is_empty(), "{:?}", v.errors.iter().map(|d| &d.message).collect::<Vec<_>>());
    assert!(v.ir.contains("@sqlite3_open_v2(") && v.ir.contains("@sqlite3_prepare_v2("), "{}", v.ir);
    let dir = std::env::temp_dir();
    let ll = dir.join("star_test_sqlite_linux.ll");
    let obj = dir.join("star_test_sqlite_linux.o");
    std::fs::write(&ll, &v.ir).unwrap();
    let status = std::process::Command::new("clang")
        .args(["-c", "--target=x86_64-unknown-linux-gnu", ll.to_str().unwrap(), "-o", obj.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&obj);
    assert!(status.success(), "the Linux IR should compile to an object");
}

/// An in-memory database round trip: create, insert, then step a select
/// through its row (100, SQLITE_ROW) to the end (101, SQLITE_DONE).
#[test]
fn runtime_sqlite_round_trip_in_memory() {
    let out = run("round_trip", "fn main():
    let db = sqlite_open(\":memory:\")
    println(f\"{is_null(db)} {sqlite3_errcode(db)}\")
    exec(db, \"create table t (n integer, s text)\")
    exec(db, \"insert into t values (42, 'hello')\")
    let st = sqlite_prepare(db, \"select n, s from t\")
    println(f\"{sqlite3_step(st)}\")
    println(f\"{sqlite3_column_int64(st, 0)}\")
    println(ptr_to_str(sqlite3_column_text(st, 1)))
    println(f\"{sqlite3_step(st)}\")
    let f = sqlite3_finalize(st)
    println(f\"{sqlite3_close_v2(db)}\")
");
    assert_eq!(out, "false 0\n100\n42\nhello\n101\n0\n");
}

/// Only the first statement is prepared, and `sqlite3_sql()` runs exactly
/// to the tail, so its length is the offset `pzTail` would have given.
#[test]
fn runtime_sqlite_prepare_takes_the_first_statement() {
    let out = run("tail", "fn main():
    let db = sqlite_open(\":memory:\")
    let sql = \"create table a (x); create table b (y)\"
    let st = sqlite_prepare(db, sql)
    let first = ptr_to_str(sqlite3_sql(st))
    println(first)
    println(f\"{len(first)}\")
    let rc = sqlite3_step(st)
    let f = sqlite3_finalize(st)
    let q = sqlite_prepare(db, \"select count(*) from sqlite_master\")
    let r = sqlite3_step(q)
    println(f\"{sqlite3_column_int64(q, 0)}\")
    let g = sqlite3_finalize(q)
");
    assert_eq!(out, "create table a (x);\n19\n1\n");
}

/// A syntax error is a null statement with the message on the connection;
/// text holding no statement is a null statement with error code 0, and
/// so is "".
#[test]
fn runtime_sqlite_prepare_errors_and_empty_text() {
    let out = run("prepare_errors", "fn main():
    let db = sqlite_open(\":memory:\")
    let bad = sqlite_prepare(db, \"selec 1\")
    println(f\"{is_null(bad)} {sqlite3_errcode(db)}\")
    println(ptr_to_str(sqlite3_errmsg(db)))
    let none = sqlite_prepare(db, \"  -- just a comment\")
    println(f\"{is_null(none)} {sqlite3_errcode(db)}\")
    let empty = sqlite_prepare(db, \"\")
    println(f\"{is_null(empty)} {sqlite3_errcode(db)}\")
    println(ptr_to_str(sqlite3_errmsg(db)))
");
    assert_eq!(out, "true 1\nnear \"selec\": syntax error\ntrue 0\ntrue 0\nnot an error\n");
}

/// A failed open still hands back a connection, carrying the error
/// (SQLITE_CANTOPEN, 14), which the caller reads and then closes.
#[test]
fn runtime_sqlite_open_failure_carries_the_error() {
    let path = scratch_file_path("star_sqlite_no_such_dir/x.db");
    let _ = std::fs::remove_dir_all(std::env::temp_dir().join("star_sqlite_no_such_dir"));
    let out = run("open_failure", &format!("fn main():
    let db = sqlite_open(\"{}\")
    println(f\"{{is_null(db)}} {{sqlite3_errcode(db)}}\")
    println(ptr_to_str(sqlite3_errmsg(db)))
    println(f\"{{sqlite3_close_v2(db)}}\")
", path));
    assert_eq!(out, "false 14\nunable to open database file\n0\n");
}

/// A file database keeps its rows across a close and a fresh open.
#[test]
fn runtime_sqlite_file_database_persists() {
    let path = scratch_file_path("star_sqlite_persist.db");
    let _ = std::fs::remove_file(&path);
    let out = run("persist", &format!("fn main():
    let a = sqlite_open(\"{p}\")
    exec(a, \"create table t (v text)\")
    exec(a, \"insert into t values ('kept')\")
    let c = sqlite3_close_v2(a)
    let b = sqlite_open(\"{p}\")
    let st = sqlite_prepare(b, \"select v from t\")
    let r = sqlite3_step(st)
    println(ptr_to_str(sqlite3_column_text(st, 0)))
    let f = sqlite3_finalize(st)
    let d = sqlite3_close_v2(b)
", p = path));
    let _ = std::fs::remove_file(&path);
    assert_eq!(out, "kept\n");
}

/// Binding "" through `extern "C"` binds empty text, not SQL NULL (what
/// the driver's db_query() relies on for an empty LPC string; a zero-valued
/// `str` gets the same since the fix `tests/frontend_ffi_extern_empty_str.rs`
/// covers).
#[test]
fn runtime_sqlite_bind_empty_text_is_not_null() {
    let out = run("bind_empty", "fn main():
    let db = sqlite_open(\":memory:\")
    let st = sqlite_prepare(db, \"select typeof(?1), length(?1)\")
    let b = sqlite3_bind_text(st, 1, \"\", 0 - 1, (0 - 1) as i64)
    let r = sqlite3_step(st)
    println(ptr_to_str(sqlite3_column_text(st, 0)))
    println(f\"{sqlite3_column_int64(st, 1)}\")
    let f = sqlite3_finalize(st)
");
    assert_eq!(out, "text\n0\n");
}

/// `sqlite_prepare` on a null connection stops with a message instead of
/// handing SQLite a null pointer.
#[test]
fn runtime_sqlite_prepare_null_connection_aborts() {
    let out = compile_and_run_sqlite("null_db", "fn main():\n    let s = sqlite_prepare(null_ptr(), \"select 1\")\n    println(\"not reached\")\n", None);
    let stdout = String::from_utf8_lossy(&out.stdout);
    assert_eq!(out.status.code(), Some(1), "{}", stdout);
    assert!(stdout.contains("sqlite_prepare(..) called with a null connection"), "{}", stdout);
    assert!(!stdout.contains("not reached"), "{}", stdout);
}

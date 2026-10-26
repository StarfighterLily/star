//! Filesystem and calendar builtins (`crate::codegen::fs`): `dir_list`,
//! `path_kind`, `file_size`, `file_mtime`, `file_set_mtime`, `dir_create`,
//! `dir_remove`, `file_remove`, `file_rename` and `local_time`.
//!
//! Added for the `projects/havokos` LPMUD driver's file and time efuns
//! (`todo.md` HavokOS M4), which Star's FFI couldn't reach: every one of
//! these reports through a C struct out-parameter, and Star has no way to
//! read a field out of a `ptr`. Each runtime test works in its own scratch
//! directory under the OS temp dir, created and cleaned up by the Star
//! program itself, so the builtins exercise one another.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

fn run_ok(name: &str, src: &str) -> String {
    let out = compile_and_run(name, src);
    assert!(out.status.success(), "should run: {:?}", out);
    String::from_utf8_lossy(&out.stdout).replace("\r\n", "\n")
}

fn fresh_dir(name: &str) -> String {
    let d = scratch_file_path(&format!("star_fs_{}", name));
    let _ = std::fs::remove_dir_all(&d);
    d
}

/// The builtins' result types: `List<str>`, `i32`, `i64`, `bool`, `List<i64>`.
#[test]
fn typecheck_fs_builtin_result_types() {
    assert_eq!(typed_fn_result_ty("fn f() -> List<str>:\n    dir_list(\".\")\n"), Ty::List(Box::new(Ty::Str)));
    assert_eq!(typed_fn_result_ty("fn f() -> i32:\n    path_kind(\".\")\n"), Ty::Int);
    assert_eq!(typed_fn_result_ty("fn f() -> i64:\n    file_size(\"x\")\n"), Ty::I64);
    assert_eq!(typed_fn_result_ty("fn f() -> i64:\n    file_mtime(\"x\")\n"), Ty::I64);
    assert_eq!(typed_fn_result_ty("fn f() -> bool:\n    file_rename(\"a\", \"b\")\n"), Ty::Bool);
    assert_eq!(typed_fn_result_ty("fn f() -> bool:\n    file_set_mtime(\"a\", 0 as i64)\n"), Ty::Bool);
    assert_eq!(typed_fn_result_ty("fn f() -> List<i64>:\n    local_time(0 as i64)\n"), Ty::List(Box::new(Ty::I64)));
}

/// A wrongly typed argument is a checker error, not a codegen crash.
#[test]
fn rejects_non_str_path_and_non_i64_time() {
    for src in [
        "fn main():\n    let k = path_kind(5)\n",
        "fn main():\n    let ok = file_rename(\"a\", 3)\n",
        "fn main():\n    let t = local_time(5)\n",
        "fn main():\n    let ok = file_set_mtime(\"a\", 5)\n",
        "fn main():\n    let ok = file_set_mtime(5, 0 as i64)\n",
    ] {
        let module = Driver::parse(src).expect("should parse");
        let diags = Driver::check(&module).expect_err("should fail to type-check");
        assert!(diags.iter().any(|d| d.message.contains("expect")), "{:?}", diags);
    }
}

/// An extern redeclaring one of the C symbols the fs builtins declare gets a real diagnostic.
#[test]
fn rejects_extern_redeclaring_fs_runtime_symbol() {
    let src = "extern \"C\" fn _mkdir(p: str) -> i32\nfn main():\n    let r = _mkdir(\"x\")\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("declares internally")), "{:?}", diags);
}

/// `dir_create`, `path_kind`, `dir_list` (no `.`/`..`), `file_size`, `file_remove` and `dir_remove` round-trip.
#[test]
fn runtime_dir_create_list_kind_size_remove_end_to_end() {
    let d = fresh_dir("basic");
    let src = format!(
        concat!(
            "fn main() -> i32:\n",
            "    let d = \"{d}\"\n",
            "    println(f\"missing:{{path_kind(d)}}\")\n",
            "    println(f\"mk:{{dir_create(d)}} again:{{dir_create(d)}} kind:{{path_kind(d)}}\")\n",
            "    let f = file_open(concat(d, \"/a.txt\"), \"wb\")\n",
            "    file_write(f, \"hello\")\n",
            "    file_close(f)\n",
            "    let g = file_open(concat(d, \"/b.txt\"), \"wb\")\n",
            "    file_close(g)\n",
            "    dir_create(concat(d, \"/sub\"))\n",
            "    let names = dir_list(d)\n",
            "    let mut seen = 0\n",
            "    for i in 0..names.len():\n",
            "        if names[i] == \"a.txt\" or names[i] == \"b.txt\" or names[i] == \"sub\":\n",
            "            seen += 1\n",
            "        if names[i] == \".\" or names[i] == \"..\":\n",
            "            seen += 100\n",
            "    println(f\"count:{{names.len()}} seen:{{seen}}\")\n",
            "    println(f\"slash:{{dir_list(concat(d, \"/\")).len()}}\")\n",
            "    println(f\"file:{{path_kind(concat(d, \"/a.txt\"))}} size:{{file_size(concat(d, \"/a.txt\"))}} empty:{{file_size(concat(d, \"/b.txt\"))}} nosuch:{{file_size(concat(d, \"/zz\"))}}\")\n",
            "    println(f\"notdir:{{dir_list(concat(d, \"/a.txt\")).len()}} nodir:{{dir_list(concat(d, \"/zz\")).len()}}\")\n",
            "    println(f\"rmdir_full:{{dir_remove(d)}} rm_dir_as_file:{{file_remove(concat(d, \"/sub\"))}}\")\n",
            "    println(f\"rm:{{file_remove(concat(d, \"/a.txt\"))}} {{file_remove(concat(d, \"/b.txt\"))}} again:{{file_remove(concat(d, \"/a.txt\"))}}\")\n",
            "    println(f\"rmsub:{{dir_remove(concat(d, \"/sub\"))}} rmdir:{{dir_remove(d)}} gone:{{path_kind(d)}}\")\n",
            "    0\n",
        ),
        d = d
    );
    let out = run_ok("fs_basic", &src);
    assert_eq!(
        out,
        concat!(
            "missing:0\n",
            "mk:true again:false kind:2\n",
            "count:3 seen:3\n",
            "slash:3\n",
            "file:1 size:5 empty:0 nosuch:-1\n",
            "notdir:0 nodir:0\n",
            "rmdir_full:false rm_dir_as_file:false\n",
            "rm:true true again:false\n",
            "rmsub:true rmdir:true gone:0\n",
        )
    );
}

/// `file_rename` moves a file and replaces an existing target (the atomic-save pattern).
#[test]
fn runtime_file_rename_replaces_target_end_to_end() {
    let d = fresh_dir("rename");
    let src = format!(
        concat!(
            "fn put(p: str, s: str):\n",
            "    let f = file_open(p, \"wb\")\n",
            "    file_write(f, s)\n",
            "    file_close(f)\n",
            "fn main() -> i32:\n",
            "    let d = \"{d}\"\n",
            "    dir_create(d)\n",
            "    put(concat(d, \"/old\"), \"OLD\")\n",
            "    put(concat(d, \"/new.tmp\"), \"NEWER\")\n",
            "    println(f\"mv:{{file_rename(concat(d, \"/new.tmp\"), concat(d, \"/old\"))}}\")\n",
            "    let f = file_open(concat(d, \"/old\"), \"rb\")\n",
            "    println(file_read(f))\n",
            "    file_close(f)\n",
            "    println(f\"tmp:{{path_kind(concat(d, \"/new.tmp\"))}} missing:{{file_rename(concat(d, \"/nope\"), concat(d, \"/x\"))}}\")\n",
            "    file_remove(concat(d, \"/old\"))\n",
            "    dir_remove(d)\n",
            "    0\n",
        ),
        d = d
    );
    assert_eq!(run_ok("fs_rename", &src), "mv:true\nNEWER\ntmp:0 missing:false\n");
}

/// `file_mtime` is a plausible epoch time for a fresh file and -1 for a missing one.
#[test]
fn runtime_file_mtime_end_to_end() {
    let p = scratch_file_path("star_fs_mtime.txt");
    let _ = std::fs::remove_file(&p);
    let src = format!(
        concat!(
            "fn main() -> i32:\n",
            "    let p = \"{p}\"\n",
            "    let f = file_open(p, \"wb\")\n",
            "    file_close(f)\n",
            "    let t = file_mtime(p)\n",
            "    let floor = (1700000000 as i64)\n",
            "    println(f\"{{t > floor}} {{file_mtime(concat(p, \".none\"))}}\")\n",
            "    file_remove(p)\n",
            "    0\n",
        ),
        p = p
    );
    assert_eq!(run_ok("fs_mtime", &src), "true -1\n");
}

/// `file_set_mtime` moves a file's modification time back (read back by
/// `file_mtime` and by Rust), and fails on a missing path.
#[test]
fn runtime_file_set_mtime_end_to_end() {
    let p = scratch_file_path("star_fs_set_mtime.txt");
    let _ = std::fs::remove_file(&p);
    let src = format!(
        concat!(
            "fn main() -> i32:\n",
            "    let p = \"{p}\"\n",
            "    let f = file_open(p, \"wb\")\n",
            "    file_close(f)\n",
            "    let t = (1600000000 as i64)\n",
            "    let ok = file_set_mtime(p, t)\n",
            "    let missing = file_set_mtime(concat(p, \".none\"), t)\n",
            "    println(f\"{{ok}} {{file_mtime(p)}} {{missing}}\")\n",
            "    0\n",
        ),
        p = p
    );
    assert_eq!(run_ok("fs_set_mtime", &src), "true 1600000000 false\n");
    let m = std::fs::metadata(&p).expect("file should exist").modified().expect("mtime");
    let secs = m.duration_since(std::time::UNIX_EPOCH).expect("after epoch").as_secs();
    assert_eq!(secs, 1600000000);
    let _ = std::fs::remove_file(&p);
}

/// An extern redeclaring `_utime64` (what `file_set_mtime` calls on Windows) gets the internal-symbol diagnostic.
#[test]
fn rejects_extern_redeclaring_utime_symbol() {
    let src = "extern \"C\" fn _utime64(p: str, b: ptr) -> i32\nfn main():\n    let r = 0\n";
    let module = Driver::parse(src).expect("should parse");
    let diags = Driver::check(&module).expect_err("should fail to type-check");
    assert!(diags.iter().any(|d| d.message.contains("declares internally")), "{:?}", diags);
}

/// `local_time` agrees with Rust's own view of this machine's UTC offset and gives the right calendar fields.
#[test]
fn runtime_local_time_end_to_end() {
    let src = concat!(
        "fn main() -> i32:\n",
        "    let t = local_time(1000000000 as i64)\n",
        "    println(f\"{t.len()}\")\n",
        "    let gm = t[9]\n",
        "    # undo the zone offset: the UTC wall clock of 2001-09-09 01:46:40Z\n",
        "    let secs = t[2] * (3600 as i64) + t[1] * (60 as i64) + t[0] - gm\n",
        "    let day = (86400 as i64)\n",
        "    let wrapped = ((secs % day) + day) % day\n",
        "    println(f\"{wrapped}\")\n",
        "    println(f\"{t[8] >= (0 as i64)} {t[4] == (8 as i64)} {t[5] == (2001 as i64)}\")\n",
        "    let z = local_time(0 as i64)\n",
        "    println(f\"{z.len()} {z[5] == (1970 as i64) or z[5] == (1969 as i64)}\")\n",
        "    0\n",
    );
    // 01:46:40 UTC is 6400 seconds into the day; September, 2001 in any zone
    assert_eq!(run_ok("fs_local_time", src), "10\n6400\ntrue true true\n10 true\n");
}

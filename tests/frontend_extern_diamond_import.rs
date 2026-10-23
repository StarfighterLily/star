//! `extern "C" fn` declarations reached through a diamond import.
//!
//! `crate::modules::dedupe_by_origin` collapses every item a diamond import
//! re-resolves (a file reached through two import edges) back to one copy,
//! keyed on the item's name -- but an `extern "C" fn` has no mangled name
//! (`item_top_level_name` returns `None` so the real C symbol is never
//! renamed), so it got no identity at all and both copies survived. The
//! checker then rejected the second as "`extern "C" fn` ... is declared more
//! than once". Found by the `projects/havokos` port (todo.md HavokOS M3):
//! its case runner imports both `vm.star` and `efuns.star`, and `efuns.star`
//! imports `vm.star`, whose own imports declare `atof`/`clock`. Fixed by
//! giving an extern the same span-keyed synthetic identity an `impl` block
//! already gets.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

fn compile_dir(dir: &std::path::Path, main_src: &str) -> star::driver::Compilation {
    let main_path = write_test_file(dir, "main.star", main_src);
    Driver::new(&main_path).compile().expect("file read should succeed")
}

/// A shared file declaring an extern, imported by `main` both directly and through another module, type-checks.
#[test]
fn diamond_import_of_extern_declaration_type_checks() {
    let dir = test_scratch_dir("diamond_import_of_extern_declaration_type_checks");
    write_test_file(&dir, "shared.star", "extern \"C\" fn atoi(s: str) -> i32\nfn parse(s: str) -> i32:\n    atoi(s)\n");
    write_test_file(&dir, "mid.star", "import \"shared.star\" as shared\nfn twice(s: str) -> i32:\n    shared::parse(s) * 2\n");
    let c = compile_dir(
        &dir,
        "import \"shared.star\" as shared\nimport \"mid.star\" as mid\nfn main() -> i32:\n    println(f\"{shared::parse(\"20\") + mid::twice(\"11\")}\")\n    0\n",
    );
    assert!(c.is_ok(), "{}", c.render_diagnostics());
    let _ = std::fs::remove_dir_all(&dir);
}

/// The collapsed extern still links and calls the real C symbol once the program runs.
#[test]
fn runtime_diamond_import_of_extern_declaration_end_to_end() {
    let dir = test_scratch_dir("runtime_diamond_import_of_extern_declaration_end_to_end");
    write_test_file(&dir, "shared.star", "extern \"C\" fn atoi(s: str) -> i32\nfn parse(s: str) -> i32:\n    atoi(s)\n");
    write_test_file(&dir, "mid.star", "import \"shared.star\" as shared\nfn twice(s: str) -> i32:\n    shared::parse(s) * 2\n");
    let c = compile_dir(
        &dir,
        "import \"shared.star\" as shared\nimport \"mid.star\" as mid\nfn main() -> i32:\n    println(f\"{shared::parse(\"20\") + mid::twice(\"11\")}\")\n    0\n",
    );
    assert!(c.is_ok(), "{}", c.render_diagnostics());
    let ir = Driver::codegen(c.typed.as_ref().unwrap()).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_extern_diamond_import.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");
    let output = std::process::Command::new(&exe).output().expect("failed to execute compiled test binary");
    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim_end(), "42");
    let _ = std::fs::remove_dir_all(&dir);
}

/// One file genuinely declaring the same extern twice is still an error: only diamond re-visits collapse.
#[test]
fn same_file_duplicate_extern_still_rejected() {
    let dir = test_scratch_dir("same_file_duplicate_extern_still_rejected");
    let c = compile_dir(
        &dir,
        "extern \"C\" fn atoi(s: str) -> i32\nextern \"C\" fn atoi(s: str) -> i32\nfn main() -> i32:\n    atoi(\"1\")\n",
    );
    assert!(!c.is_ok(), "a real duplicate must still be diagnosed");
    assert!(c.render_diagnostics().contains("declared more than once"), "{}", c.render_diagnostics());
    let _ = std::fs::remove_dir_all(&dir);
}

/// Two different files each declaring the same extern (no diamond) are still reported, since their spans differ.
#[test]
fn separate_files_declaring_same_extern_still_rejected() {
    let dir = test_scratch_dir("separate_files_declaring_same_extern_still_rejected");
    write_test_file(&dir, "a.star", "extern \"C\" fn atoi(s: str) -> i32\nfn pa(s: str) -> i32:\n    atoi(s)\n");
    write_test_file(&dir, "b.star", "fn pad() -> i32:\n    1\nextern \"C\" fn atoi(s: str) -> i32\nfn pb(s: str) -> i32:\n    atoi(s)\n");
    let c = compile_dir(
        &dir,
        "import \"a.star\" as a\nimport \"b.star\" as b\nfn main() -> i32:\n    a::pa(\"1\") + b::pb(\"2\")\n",
    );
    assert!(!c.is_ok(), "two independent declarations of one symbol must still be diagnosed");
    let _ = std::fs::remove_dir_all(&dir);
}

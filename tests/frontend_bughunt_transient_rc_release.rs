//! Bug-hunting round: transient RC-value release gating
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Bug-hunting round: transient RC-value release was gated on ==========
// ===== "was this a borrowed read", skipping it entirely for a fresh =======
// ===== construction =========================================================
//
// `Codegen::is_rc_borrowing_read` used to gate every "release a transiently-
// consumed value" call site (`println`/f-string holes, `Map`/`Set` lookup
// keys, an invoked closure literal, `emit_raw_str_ptr`'s callers) on whether
// the value came from a borrowing read (`Ident`/`Field`/`ListIndex`/...).
// That's correct for undoing a borrow's extra retain, but backwards for a
// *fresh* construction (`concat(..)`, a fresh closure literal, ...): those
// start at refcount 1 with a single owner and were never being retained in
// the first place, so skipping the release left that sole reference with
// nothing to ever free it -- a real, confirmed leak on every evaluation.
// Fixed by making every one of those releases unconditional (safe: a
// non-RC-bearing type's release is a no-op via `contains_rc`, and
// `star_rc_release` itself no-ops on a null pointer or a string literal's
// immortal `-1`-sentinel refcount).
//
// A first version of this fix moved the release *into*
// `Codegen::emit_raw_str_ptr` itself, which broke every caller that reads
// the extracted raw pointer more than once after getting it back (`concat`'s
// `strcpy`/`strcat`, an extern-C call, `file_open`'s `fopen`, ...): a fresh
// (non-borrowed) argument's buffer was freed the instant its first use
// (e.g. `strlen`) executed, corrupting or reusing that memory before its
// second use ever ran -- confirmed via a real wrong runtime result
// (`concat(f"a{1}", f"b{2})` produced `"b2b2"` instead of `"a1b2"`, caught
// by the pre-existing `runtime_fstring_value_nested_and_concat_end_to_end`).
// Fixed by releasing at each *caller's* own last use of the pointer instead.

/// Chaining `concat` calls (each argument itself a fresh `concat` result,
/// never bound to a `let`) must still produce the correct concatenation --
/// guards `Codegen::emit_str_concat` specifically, since its two arguments'
/// raw pointers are each read twice (`strlen`, then `strcpy`/`strcat`)
/// before being released.
#[test]
fn runtime_concat_of_two_fresh_concat_results_end_to_end() {
    let src = "fn main():\n    let s = concat(concat(\"a\", \"b\"), concat(\"c\", \"d\"))\n    println(s)\n";
    let output = compile_and_run("concat_of_fresh_concats", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "abcd");
}

/// `len`/`ord` of a fresh (never `let`-bound) `concat` result must read the
/// correct bytes, not a use-after-free of a buffer released before it was
/// ever read -- guards `Codegen::emit_str_len`/`emit_ord`, which route
/// through `emit_raw_str_ptr` the same way `emit_str_concat` does.
#[test]
fn runtime_len_and_ord_of_a_fresh_concat_result_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let n = len(concat(\"xy\", \"zw\"))\n",
        "    println(f\"{n}\")\n",
        "    let o = ord(concat(\"Q\", \"\"))\n",
        "    println(f\"{o}\")\n",
    );
    let output = compile_and_run("len_ord_of_fresh_concat", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.lines().collect::<Vec<_>>(), vec!["4", "81"], "{}", stdout);
}

/// An `extern "C" fn` call passed a *fresh* `str` argument (not a borrowed
/// `Ident`) must still read the correct bytes -- guards
/// `Codegen::emit_extern_call`'s deferred per-argument release (added
/// alongside `emit_raw_str_ptr`'s own fix), which has to release *after*
/// the actual `call @name(...)` instruction, not while still building up
/// `call_args`.
#[test]
fn runtime_extern_call_with_a_fresh_str_argument_end_to_end() {
    let src = "extern \"C\" fn atoi(s: str) -> int\nfn main():\n    println(f\"{atoi(concat(\"4\", \"2\"))}\")\n";
    let output = compile_and_run("extern_call_fresh_str_arg", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "42");
}

/// `file_open`/`file_write`/`env_get`/`env_set` each passed a fresh
/// (`concat`-built) `str` argument rather than a borrowed `Ident` -- guards
/// every remaining `emit_raw_str_ptr` caller in `file_io.rs`/`os.rs` at
/// once, end-to-end through real OS calls rather than just inspecting IR.
#[test]
fn runtime_file_and_env_builtins_with_fresh_str_arguments_end_to_end() {
    let dir = test_scratch_dir("runtime_file_and_env_builtins_with_fresh_str_arguments_end_to_end");
    let file_path = dir.join("fresh_write_test.txt");
    std::fs::create_dir_all(&dir).expect("create test dir");
    let file_path_star = file_path.to_str().unwrap().replace('\\', "/");
    let src = format!(
        "fn main():\n    \
         env_set(concat(\"STAR_TEST_\", \"FRESHVAR\"), concat(\"hello_\", \"world\"))\n    \
         println(env_get(concat(\"STAR_TEST_\", \"FRESHVAR\")))\n    \
         let h = file_open(concat(\"{path}\", \"\"), \"w\")\n    \
         file_write(h, concat(\"payload_\", \"data\"))\n    \
         file_close(h)\n    \
         let h2 = file_open(concat(\"{path}\", \"\"), \"r\")\n    \
         println(file_read_line(h2))\n    \
         file_close(h2)\n",
        path = file_path_star
    );
    let output = compile_and_run("file_env_fresh_str_args", &src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert_eq!(stdout.lines().collect::<Vec<_>>(), vec!["hello_world", "payload_data"], "{}", stdout);

    let _ = std::fs::remove_dir_all(&dir);
}

/// Regression test for the leak fixed across `emit_print_like`/the f-string-
/// value codegen path: `println`ing a fresh, never-`let`-bound `concat`
/// result in a tight loop must not grow memory -- previously every call
/// left that fresh string's sole reference permanently unreleased. Mirrors
/// `runtime_discarded_list_pop_statement_does_not_leak_end_to_end`'s
/// technique (throwaway executable + a single PowerShell Working-Set
/// polling loop).
#[test]
fn runtime_printing_a_fresh_concat_result_does_not_leak_end_to_end() {
    use std::process::Command;

    let src = "fn main():\n    let mut i: i32 = 0\n    while i < 20000000:\n        println(concat(\"a\", \"b\"))\n        i += 1\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_println_fresh_concat_leak.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");

    let stdout_file = std::env::temp_dir().join("println_fresh_concat_leak_stdout.txt");
    let script = format!(
        "$p = Start-Process -FilePath '{}' -PassThru -RedirectStandardOutput '{}'; \
         $samples = New-Object System.Collections.ArrayList; \
         while (-not $p.HasExited) {{ try {{ $p.Refresh(); [void]$samples.Add($p.WorkingSet64) }} catch {{}}; Start-Sleep -Milliseconds 100 }}; \
         $samples -join ','",
        exe.display(),
        stdout_file.display()
    );
    let output = Command::new("powershell")
        .args(["-NoProfile", "-NonInteractive", "-Command", &script])
        .output()
        .expect("failed to run the PowerShell memory-sampling script");
    assert!(output.status.success(), "sampling script failed: {}", String::from_utf8_lossy(&output.stderr));

    let samples_raw = String::from_utf8_lossy(&output.stdout);
    let samples: Vec<i64> = samples_raw.trim().split(',').filter_map(|s| s.trim().parse().ok()).collect();

    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
    let _ = std::fs::remove_file(&stdout_file);

    if samples.len() < 3 {
        return;
    }
    let settled = &samples[1..];
    let min = *settled.iter().min().unwrap();
    let max = *settled.iter().max().unwrap();
    assert!(
        (max - min) < 20 * 1024 * 1024,
        "Working Set grew by {}MB across the run (samples: {:?}) -- println of a fresh, unbound `concat` result is leaking",
        (max - min) / (1024 * 1024),
        samples
    );
}

/// Regression test for the same leak, through `Map::contains` passed a
/// fresh `concat`-built key argument (rather than the collection-return-
/// value leak `runtime_method_call_on_a_fresh_map_returning_call_does_not_leak_end_to_end`
/// covers) -- this is the call site that originally caught the bug: a
/// `-O2`-optimized manual check looked flat (the optimizer had likely
/// elided the unused result), but this suite always builds at `-O0`
/// (matching `compile_and_run`'s convention) and immediately showed real,
/// unbounded growth before the fix.
#[test]
fn runtime_map_contains_with_a_fresh_concat_key_does_not_leak_end_to_end() {
    use std::process::Command;

    let src = concat!(
        "fn main():\n",
        "    let mut m: Map<str, str> = Map<str, str>()\n",
        "    m.insert(\"k1\", \"v1\")\n",
        "    let mut i: i32 = 0\n",
        "    while i < 20000000:\n",
        "        let found = m.contains(concat(\"k\", \"1\"))\n",
        "        i += 1\n",
        "    println(\"done\")\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let exe = std::env::temp_dir().join("star_test_map_contains_fresh_key_leak.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");

    let stdout_file = std::env::temp_dir().join("map_contains_fresh_key_leak_stdout.txt");
    let script = format!(
        "$p = Start-Process -FilePath '{}' -PassThru -RedirectStandardOutput '{}'; \
         $samples = New-Object System.Collections.ArrayList; \
         while (-not $p.HasExited) {{ try {{ $p.Refresh(); [void]$samples.Add($p.WorkingSet64) }} catch {{}}; Start-Sleep -Milliseconds 100 }}; \
         $samples -join ','",
        exe.display(),
        stdout_file.display()
    );
    let output = Command::new("powershell")
        .args(["-NoProfile", "-NonInteractive", "-Command", &script])
        .output()
        .expect("failed to run the PowerShell memory-sampling script");
    assert!(output.status.success(), "sampling script failed: {}", String::from_utf8_lossy(&output.stderr));

    let program_stdout = std::fs::read_to_string(&stdout_file).unwrap_or_default();
    assert!(program_stdout.contains("done"), "program should finish normally: {}", program_stdout);

    let samples_raw = String::from_utf8_lossy(&output.stdout);
    let samples: Vec<i64> = samples_raw.trim().split(',').filter_map(|s| s.trim().parse().ok()).collect();

    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
    let _ = std::fs::remove_file(&stdout_file);

    if samples.len() < 3 {
        return;
    }
    let settled = &samples[1..];
    let min = *settled.iter().min().unwrap();
    let max = *settled.iter().max().unwrap();
    assert!(
        (max - min) < 20 * 1024 * 1024,
        "Working Set grew by {}MB across the run (samples: {:?}) -- `Map::contains` with a fresh `concat` key argument is leaking",
        (max - min) / (1024 * 1024),
        samples
    );
}

/// An immediately-invoked closure *literal* (never bound to a `let`,
/// so its environment is a fresh construction, not a borrowed read) must
/// still call through correctly and release its environment -- guards
/// `Codegen::emit_closure_call`'s release, which used to be skipped
/// entirely for exactly this case.
#[test]
fn runtime_immediately_invoked_fresh_closure_literal_end_to_end() {
    let src = "fn main():\n    let x = 10\n    let r = (fn(y: i32) -> i32: x + y)(5)\n    println(f\"{r}\")\n";
    let output = compile_and_run("iife_fresh_closure", src);
    assert!(output.status.success(), "{:?}", output.status);
    assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "15");
}

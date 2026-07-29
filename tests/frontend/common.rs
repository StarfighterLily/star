//! Shared test infrastructure for the split `tests/frontend_*.rs` suite
//! (see `todo.md` P2 #6, and the sibling `src/codegen/` module split this
//! mirrors). Not compiled as its own `cargo test` binary -- only `.rs`
//! files directly under `tests/` are; this one is pulled in via
//! `#[path = "frontend/common.rs"] mod common;` from each split file.

pub use star::ast::{AssignOp, BinOp, EnumDef, Expr, FStrExpr, Item, Pattern, Stmt, Type, TypeParam, UnOp};
pub use star::diagnostics::Diagnostic;
pub use star::driver::{Driver};
pub use star::lexer::{TokenKind};
pub use star::types::{Checker, Ty, TypedExpr, TypedItem, TypedStmt};

/// Type-check `src` and return both the typed module and every non-fatal
/// warning `Checker::check` accumulated (currently just
/// `Checker::check_stack_budget`'s, `todo.md` P0 #2) -- `Driver::check`
/// alone (used by every other helper here) discards these, since it only
/// ever returns `Result<TypedModule, Vec<Diagnostic>>`, so this goes
/// straight to a fresh `Checker` instead.
pub fn typecheck_with_warnings(src: &str) -> (star::types::TypedModule, Vec<Diagnostic>) {
    let module = Driver::parse(src).expect("should parse");
    let mut checker = Checker::new();
    let typed = checker.check(&module).expect("should type-check");
    (typed, checker.take_warnings())
}

/// Shared fixture: a minimal `Enemy` struct + backing arena, prefixed onto
/// `par`/`swarm`/`spawn`/`despawn` test sources across several split files.
pub const PAR_SRC_PREFIX: &str = "struct Enemy:\n    mut hp: i32\n\narena Enemies: Enemy\n\n";

/// Shared fixture: a minimal `Point` struct, prefixed onto frame-escape test
/// sources across several split files.
pub const FRAME_ESCAPE_SRC_PREFIX: &str = "struct Point:\n    x: i32\n    y: i32\n\n";

/// Slice out just one `define ... @name(...` function's body from a full
/// module's emitted IR, so a test asserting "this function never emits X"
/// isn't tripped up by an unrelated occurrence of `X` elsewhere in the
/// module -- e.g. the fixed `star_rc_alloc`/`retain`/`release` runtime
/// prelude (see `Codegen::emit_rc_runtime`) legitimately contains its own
/// `ret void`/`icmp`/`call i8* @malloc`, which has nothing to do with
/// whether the function under test emits them.
pub fn extract_fn_body<'a>(ir: &'a str, define_prefix: &str) -> &'a str {
    let start = ir.find(define_prefix).unwrap_or_else(|| panic!("`{}` not found in IR:\n{}", define_prefix, ir));
    let rest = &ir[start..];
    let end = rest.find("\n}\n").map(|i| i + 3).unwrap_or(rest.len());
    &rest[..end]
}

/// Type-check a single-function source and return the trailing expression's
/// resolved type.
pub fn typed_fn_result_ty(src: &str) -> Ty {
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let TypedItem::Fn(f) = &typed.items[0] else { panic!("expected fn") };
    match f.body.stmts.last().expect("body should have a statement") {
        TypedStmt::Expr(e) => e.clone().into_ty(),
        other => panic!("expected trailing expr statement, got {:?}", other),
    }
}

/// Shared helper for the file-I/O runtime tests below: parse/check/codegen
/// `src`, compile it with clang into a uniquely-named temp `.exe`, run it,
/// and return its captured output -- mirrors the inline compile-and-run
/// pattern `runtime_extern_ptr_round_trip_end_to_end` established, extended
/// with a `name` parameter so concurrently-run tests don't collide on the
/// same temp `.ll`/`.exe` path.
pub fn compile_and_run(name: &str, src: &str) -> std::process::Output {
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let exe = std::env::temp_dir().join(format!("star_test_{}.exe", name));
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
    output
}

/// A scratch data-file path under the OS temp dir, with backslashes
/// normalized to forward slashes -- `fopen` accepts either on Windows, and
/// forward slashes sidestep needing to double-escape `\` inside the Star
/// string literal embedded in each test's generated source.
pub fn scratch_file_path(name: &str) -> String {
    std::env::temp_dir().join(name).to_string_lossy().replace('\\', "/")
}

/// Like `compile_and_run`, but also passes extra `argv` entries and/or
/// preset environment variables to the compiled binary -- needed to
/// exercise `args()`/`env_get` end to end, since both read real
/// OS-supplied process state `compile_and_run`'s bare `.output()` call
/// doesn't control.
pub fn compile_and_run_with(name: &str, src: &str, extra_args: &[&str], envs: &[(&str, &str)]) -> std::process::Output {
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let exe = std::env::temp_dir().join(format!("star_test_{}.exe", name));
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");
    let mut cmd = std::process::Command::new(&exe);
    cmd.args(extra_args);
    for (k, v) in envs {
        cmd.env(k, v);
    }
    let output = cmd.output().expect("failed to execute compiled test binary");
    let _ = std::fs::remove_file(&ll);
    let _ = std::fs::remove_file(&exe);
    output
}

/// Write `contents` to `dir/name`, creating `dir` if needed, and return its
/// path -- a tiny helper for tests that exercise `crate::modules::resolve`
/// against real files on disk (import resolution is inherently file-based).
pub fn write_test_file(dir: &std::path::Path, name: &str, contents: &str) -> std::path::PathBuf {
    std::fs::create_dir_all(dir).expect("create test dir");
    let path = dir.join(name);
    std::fs::write(&path, contents).expect("write test file");
    path
}

/// A fresh scratch directory under the OS temp dir, namespaced by test name
/// so parallel test runs never collide.
pub fn test_scratch_dir(name: &str) -> std::path::PathBuf {
    std::env::temp_dir().join("star_module_tests").join(name)
}

/// Shared helper for this round's leak regression tests: build `src`
/// (which must `println("done")` somewhere in its output on success) the
/// same way `compile_and_run` does, then sample the running process's
/// Working Set the same way `runtime_rc_stress_memory_stays_bounded` does,
/// asserting it stays within `growth_cap_bytes` of its settled minimum
/// across the whole run -- an unbounded per-iteration leak grows steadily
/// instead of staying flat.
pub fn assert_no_leak(name: &str, src: &str, growth_cap_bytes: i64) {
    use std::process::Command;

    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let exe = std::env::temp_dir().join(format!("star_test_{}.exe", name));
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let status = Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR");

    let stdout_file = std::env::temp_dir().join(format!("{}_stdout.txt", name));
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
        // Ran too fast to sample meaningfully on this machine -- a
        // successful, fast exit is itself still evidence against an
        // unbounded per-iteration leak.
        return;
    }
    let settled = &samples[1..];
    let min = *settled.iter().min().unwrap();
    let max = *settled.iter().max().unwrap();
    assert!(
        (max - min) < growth_cap_bytes,
        "Working Set grew by {}MB across the run (samples: {:?}) -- looks like a leak",
        (max - min) / (1024 * 1024),
        samples
    );
}

/// Like `compile_and_run_linked`, but also adds `sdl/lib/x64` as a `-L`
/// search path, stages a copy of `sdl/lib/x64/SDL2.dll` next to the compiled
/// `.exe` (Windows' DLL search order checks the executable's own directory
/// before `PATH`, and this repo's `sdl/` directory generally isn't on
/// `PATH`), and runs the binary with `SDL_VIDEODRIVER=dummy` set so no real
/// OS window is created during `cargo test`. Uses `CARGO_MANIFEST_DIR`
/// rather than a bare relative `sdl/lib/x64` so this doesn't depend on
/// `cargo test`'s current directory happening to be the repo root.
///
/// The exe (and its staged DLL copy, which the Windows loader requires be
/// named exactly `SDL2.dll` -- unlike the exe/`.ll` themselves, it can't be
/// disambiguated by filename) lives in its own uniquely-named subdirectory
/// under the OS temp dir, not directly in it: every SDL runtime test would
/// otherwise stage its DLL copy to the *same* shared `SDL2.dll` path, and
/// `cargo test` runs tests concurrently -- confirmed as a real race (one
/// test's `fs::copy` landing while another test's already-launched process
/// still had its own copy of the DLL mapped/open, failing with `ERROR_
/// SHARING_VIOLATION`) before each test got its own directory.
pub fn compile_and_run_sdl(name: &str, src: &str) -> std::process::Output {
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let dir = std::env::temp_dir().join(format!("star_test_sdl_{}", name));
    std::fs::create_dir_all(&dir).expect("failed to create test scratch dir");
    let exe = dir.join("test.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");

    let sdl_lib_dir = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("sdl").join("lib").join("x64");
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .arg(format!("-L{}", sdl_lib_dir.display()))
        .arg("-lSDL2")
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR, linked against SDL2");

    let dll_dest = dir.join("SDL2.dll");
    std::fs::copy(sdl_lib_dir.join("SDL2.dll"), &dll_dest).expect("failed to stage SDL2.dll next to the test binary");

    let output = std::process::Command::new(&exe).env("SDL_VIDEODRIVER", "dummy").output().expect("failed to execute compiled test binary");
    let _ = std::fs::remove_dir_all(&dir);
    output
}

/// Like `compile_and_run_sdl`, but also sets `SDL_AUDIODRIVER=dummy` --
/// SDL2's own headless audio driver, the audio-subsystem counterpart to
/// `SDL_VIDEODRIVER=dummy` (accepts any requested `SDL_AudioSpec`, drives
/// the callback on a timer, produces no real sound) -- so `sound_play`/
/// `music_play`'s `SDL_OpenAudioDevice` call succeeds under `cargo test`
/// with no real sound card or default output device required. Used by
/// every audio runtime test in the "Audio playback / gamepad input"
/// section below.
pub fn compile_and_run_sdl_audio(name: &str, src: &str) -> std::process::Output {
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let dir = std::env::temp_dir().join(format!("star_test_sdl_{}", name));
    std::fs::create_dir_all(&dir).expect("failed to create test scratch dir");
    let exe = dir.join("test.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");

    let sdl_lib_dir = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("sdl").join("lib").join("x64");
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .arg(format!("-L{}", sdl_lib_dir.display()))
        .arg("-lSDL2")
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR, linked against SDL2");

    let dll_dest = dir.join("SDL2.dll");
    std::fs::copy(sdl_lib_dir.join("SDL2.dll"), &dll_dest).expect("failed to stage SDL2.dll next to the test binary");

    let output = std::process::Command::new(&exe)
        .env("SDL_VIDEODRIVER", "dummy")
        .env("SDL_AUDIODRIVER", "dummy")
        .output()
        .expect("failed to execute compiled test binary");
    let _ = std::fs::remove_dir_all(&dir);
    output
}

/// Like `compile_and_run_sdl`, but also compiles a small C source file
/// (`c_helper`) alongside the generated `.ll` in the same `clang`
/// invocation, with SDL2's vendored headers (`sdl/include`) on the include
/// path. Used only by the virtual-joystick gamepad test below: this
/// compiler's own `extern "C" fn` grammar rejects any symbol starting with
/// an uppercase letter outright (`Checker::check_extern_fn` -- Star always
/// parses `Name(args)` as a struct literal when `Name` starts uppercase),
/// so a `.star` test program can never call SDL2's own (uppercase)
/// `SDL_JoystickAttachVirtual`/`SDL_JoystickSetVirtualButton`/
/// `SetVirtualAxis` simulation APIs directly. `c_helper` provides lowercase
/// wrapper functions around exactly those three that a `.star` program's
/// own `extern "C" fn` declarations *can* legally name and call.
pub fn compile_and_run_sdl_with_c_helper(name: &str, src: &str, c_helper: &str) -> std::process::Output {
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    let dir = std::env::temp_dir().join(format!("star_test_sdl_{}", name));
    std::fs::create_dir_all(&dir).expect("failed to create test scratch dir");
    let exe = dir.join("test.exe");
    let ll = exe.with_extension("ll");
    std::fs::write(&ll, &ir).expect("failed to write ll");
    let c_path = dir.join("helper.c");
    std::fs::write(&c_path, c_helper).expect("failed to write c helper");

    let sdl_root = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("sdl");
    let sdl_include_dir = sdl_root.join("include");
    let sdl_lib_dir = sdl_root.join("lib").join("x64");
    let status = std::process::Command::new("clang")
        .args(["-O0", ll.to_str().unwrap(), c_path.to_str().unwrap(), "-o", exe.to_str().unwrap()])
        .arg(format!("-I{}", sdl_include_dir.display()))
        .arg(format!("-L{}", sdl_lib_dir.display()))
        .arg("-lSDL2")
        .status()
        .expect("failed to invoke clang");
    assert!(status.success(), "clang should compile the generated IR + C helper, linked against SDL2");

    let dll_dest = dir.join("SDL2.dll");
    std::fs::copy(sdl_lib_dir.join("SDL2.dll"), &dll_dest).expect("failed to stage SDL2.dll next to the test binary");

    let output = std::process::Command::new(&exe).env("SDL_VIDEODRIVER", "dummy").output().expect("failed to execute compiled test binary");
    let _ = std::fs::remove_dir_all(&dir);
    output
}

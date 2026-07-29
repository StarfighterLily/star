//! `star` command-line entry point.
//!
//! Thin CLI over [`star::driver`]. Subcommands drive the pipeline stages:
//!
//! - `star check <file>`  — lex + parse + type-check, report diagnostics.
//! - `star build <file>`  — full pipeline to native executable via LLVM IR.
//! - `star emit <file>`   — dump tokens or the AST for debugging.

use std::ffi::OsStr;
use std::path::{Path, PathBuf};
use std::process::ExitCode;

use clap::{Parser, Subcommand, ValueEnum};
use star::driver::{Driver, ResolvedInput};

#[derive(Parser)]
#[command(name = "star", version, about = "The Star game programming language compiler")]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

/// Extra `import` search directories shared by every subcommand that
/// resolves imports (`check`/`build`/`emit llvm`) -- factored out with
/// `#[command(flatten)]` so `-I`/`--search-path`'s help text and behavior
/// can't drift between them.
#[derive(clap::Args)]
struct SearchPathArgs {
    /// Add a directory `import "path"` should search when it isn't found
    /// relative to the importing file itself (like a C compiler's `-I` for
    /// `#include "..."`). Repeatable; searched in the order given, after the
    /// importing file's own directory and before anything a discovered
    /// `star.toml`'s `[paths] search` contributes. The `STAR_PATH`
    /// environment variable (a `;`/`:`-separated list, like `PATH`) is
    /// consulted the same way, after every `-I` given here.
    #[arg(short = 'I', long = "search-path")]
    search_paths: Vec<String>,
}

#[derive(Subcommand)]
enum Command {
    /// Lex, parse, and type-check a source file.
    Check {
        /// Path to a `.star` source file, or a directory containing a
        /// `star.toml` manifest (see `crate::manifest`).
        file: String,
        #[command(flatten)]
        search: SearchPathArgs,
    },
    /// Compile a source file to a native executable.
    Build {
        /// Path to a `.star` source file, or a directory containing a
        /// `star.toml` manifest (see `crate::manifest`).
        file: String,
        #[command(flatten)]
        search: SearchPathArgs,
        /// Output executable path (default: <file>.exe).
        #[arg(short, long)]
        output: Option<String>,
        /// Optimization level passed to clang (0-3). Defaults to 2: Star's
        /// own emitter never runs LLVM's `opt` pipeline or does any
        /// simplification of its own (every local is spilled to an
        /// `alloca`+`load`/`store`), so building at the previous default of
        /// `-O0` shipped every binary, including every example, fully
        /// unoptimized -- `-O2` alone lets `mem2reg`/SROA clean that up for
        /// free.
        #[arg(short = 'O', long = "opt-level", default_value_t = 2)]
        opt_level: u8,
        /// Shorthand for `-O 3` (maximum optimization); overrides `-O`/
        /// `--opt-level` if both are given.
        #[arg(long)]
        release: bool,
        /// Link against an additional library (passed through to clang as
        /// `-l<name>`), e.g. `-l SDL2`. Repeatable. Needed for `extern "C"
        /// fn` declarations that bind a symbol from a library beyond the
        /// ones already linked by default (libc/kernel32 on this target).
        #[arg(short = 'l', long = "lib")]
        libs: Vec<String>,
        /// Add a library search directory (passed through to clang as
        /// `-L<path>`), e.g. `-L C:\SDL2\lib`. Repeatable.
        #[arg(short = 'L', long = "lib-path")]
        lib_paths: Vec<String>,
        /// Hand the generated `.ll` to clang even if this compiler's own IR
        /// verifier (`star::ir_check`) flagged it as malformed. The
        /// verifier is a best-effort heuristic checker over this emitter's
        /// own dialect, not a reimplementation of `clang`'s -- if it's
        /// wrong about a specific program (a false positive on a codegen
        /// shape it hasn't seen before), this is the escape hatch: `clang`
        /// remains the actual authority on well-formedness either way, and
        /// this flag just lets it have the final word instead of the build
        /// stopping short of ever asking it.
        #[arg(long = "skip-ir-verify")]
        skip_ir_verify: bool,
        /// Which native target to emit code (and, ultimately, a linked
        /// executable) for. See `TargetArg`'s own doc comment -- `linux` is
        /// best-effort cross-emission, not a verified cross-compile story.
        #[arg(long = "target", value_enum, default_value_t = TargetArg::Windows)]
        target: TargetArg,
    },
    /// Emit an intermediate representation for debugging.
    Emit {
        /// What to emit.
        #[arg(value_enum)]
        what: EmitKind,
        /// Path to a `.star` source file, or a directory containing a
        /// `star.toml` manifest (see `crate::manifest`).
        file: String,
        #[command(flatten)]
        search: SearchPathArgs,
        /// Which native target to emit code for -- see `Build`'s own
        /// `--target` doc comment. Only meaningful for `star emit llvm`;
        /// ignored (accepted but unused) for `tokens`/`ast`.
        #[arg(long = "target", value_enum, default_value_t = TargetArg::Windows)]
        target: TargetArg,
    },
}

/// `--target`'s CLI spelling of `star::codegen::Target` -- kept as its own
/// `clap`-derivable enum rather than deriving `ValueEnum` on `Target` itself
/// so the codegen crate doesn't need a `clap` dependency just for its CLI
/// surface (`star::codegen` is also used as a library, e.g. by this crate's
/// own tests, with no CLI involved).
#[derive(Copy, Clone, Default, ValueEnum)]
enum TargetArg {
    /// `x86_64-w64-windows-gnu` -- this compiler's original target, and the
    /// only one built/linked end-to-end in this project's own test suite.
    #[default]
    Windows,
    /// `x86_64-unknown-linux-gnu`. Codegen emits real pthread/`sem_t`-based
    /// synchronization for `par`/`swarm` (see `star::codegen::platform`)
    /// instead of Win32 primitives, and this flag passes `-target
    /// x86_64-unknown-linux-gnu` through to clang -- but actually *linking*
    /// a working Linux ELF binary needs a matching sysroot/libc/linker this
    /// compiler doesn't vendor, detect, or verify are present. Treat this as
    /// best-effort cross-emission (inspect the `.ll` with `star emit llvm
    /// --target=linux`, or hand it to a real Linux toolchain) rather than a
    /// supported one-command cross-compile.
    Linux,
}

impl TargetArg {
    fn to_target(self) -> star::codegen::Target {
        match self {
            TargetArg::Windows => star::codegen::Target::WindowsGnu,
            TargetArg::Linux => star::codegen::Target::LinuxGnu,
        }
    }
}

#[derive(Copy, Clone, ValueEnum)]
enum EmitKind {
    /// The raw token stream.
    Tokens,
    /// The parsed abstract syntax tree.
    Ast,
    /// The LLVM IR text.
    Llvm,
}

/// The OS default main-thread stack (on this compiler's Windows/MinGW
/// target, whatever the linker's default `/STACK` reserve happens to be --
/// smaller than the 8MiB a typical Linux/macOS main thread gets, and not
/// something this project's `.cargo/config.toml` currently overrides) is too
/// small for this front end's own recursive-descent parser/checker/codegen
/// passes on legitimately deep (but explicitly bounded -- see
/// `Parser::MAX_EXPR_DEPTH`/`MAX_BINARY_CHAIN`/`Checker::MAX_MONO_DEPTH`)
/// input: a real, reproducible "thread 'main' has overflowed its stack"
/// crash on e.g. 150 chained `+` operators (well under `MAX_BINARY_CHAIN`'s
/// 200-operator promise) predates this specific change but was made worse by
/// it -- every new `Ty`/`Expr`/`TypedExpr` variant added over this
/// compiler's life adds one more match arm's worth of locals to these same
/// hot recursive functions' stack frames in an unoptimized build, eroding
/// whatever margin the *last* round's stack-safety fix established. Rather
/// than keep shrinking the depth constants (a real, user-visible regression
/// in how much legitimately-nested/long input compiles) every time a future
/// feature adds one more match arm, `main`'s actual work runs on a purpose-
/// spawned thread with a generous, explicit stack size instead -- the same
/// fix real compilers with deep AST recursion (e.g. `rustc` itself) use, and
/// one that scales with future growth instead of fighting it test by test.
const MAIN_STACK_SIZE: usize = 32 * 1024 * 1024;

fn main() -> ExitCode {
    // `Cli::parse()` itself never recurses deeply (a flat `clap` argument
    // scan), so it's fine to run on the OS-provided main thread; only the
    // actual compile work is spawned onto the larger stack.
    let cli = Cli::parse();
    std::thread::Builder::new()
        .stack_size(MAIN_STACK_SIZE)
        .spawn(move || run(cli))
        .expect("failed to spawn main worker thread")
        .join()
        .expect("main worker thread panicked")
}

fn run(cli: Cli) -> ExitCode {
    match cli.command {
        Command::Check { file, search } => cmd_check(&file, &search),
        Command::Build { file, search, output, opt_level, release, libs, lib_paths, skip_ir_verify, target } => {
            cmd_build(&file, &search, output.as_deref(), opt_level, release, &libs, &lib_paths, skip_ir_verify, target.to_target())
        }
        Command::Emit { what, file, search, target } => cmd_emit(what, &file, &search, target.to_target()),
    }
}

/// The full ordered search-path list `-I`/`--search-path` and `STAR_PATH`
/// contribute for one compile (before `star::driver::resolve_input` folds
/// in whatever a discovered `star.toml` adds -- see `SearchPathArgs`'s doc
/// comment for the complete ordering story).
fn collect_search_paths(search: &SearchPathArgs) -> Vec<PathBuf> {
    collect_search_paths_from(&search.search_paths, std::env::var_os("STAR_PATH").as_deref())
}

/// `collect_search_paths`'s logic, parameterized over the `STAR_PATH` value
/// so it can be exercised on a synthetic value without touching the
/// process's real environment -- mirrors `find_clang_on`'s own reason for
/// taking `path_var` as a parameter (see the `tests` module below).
fn collect_search_paths_from(cli_paths: &[String], star_path_var: Option<&OsStr>) -> Vec<PathBuf> {
    let mut paths: Vec<PathBuf> = cli_paths.iter().map(PathBuf::from).collect();
    if let Some(var) = star_path_var {
        paths.extend(std::env::split_paths(var));
    }
    paths
}

/// Resolve a CLI `file` argument (plus its `-I`/`STAR_PATH` search paths)
/// via `star::driver::resolve_input`, printing a clean error and returning
/// `None` on failure (an unrecognized directory argument, or a malformed
/// `star.toml`) rather than making every `cmd_*` function duplicate that
/// error-formatting.
fn resolve_entry(file: &str, search: &SearchPathArgs) -> Option<ResolvedInput> {
    let extra = collect_search_paths(search);
    match star::driver::resolve_input(Path::new(file), &extra) {
        Ok(resolved) => Some(resolved),
        Err(e) => {
            eprintln!("error: {}", e);
            None
        }
    }
}

/// Run the front-end and print diagnostics.
fn cmd_check(file: &str, search: &SearchPathArgs) -> ExitCode {
    let Some(resolved) = resolve_entry(file, search) else { return ExitCode::FAILURE };
    let driver = Driver::with_search_paths(&resolved.entry, resolved.search_paths);
    match driver.compile() {
        Ok(compilation) => {
            if compilation.is_ok() {
                eprint!("{}", compilation.render_warnings());
                println!("ok: {} parsed and type-checked successfully", resolved.entry.display());
                ExitCode::SUCCESS
            } else {
                eprint!("{}", compilation.render_diagnostics());
                ExitCode::FAILURE
            }
        }
        Err(e) => {
            eprintln!("error: could not read {}: {}", resolved.entry.display(), e);
            ExitCode::FAILURE
        }
    }
}

/// The `-O<N>` flag clang should be invoked with, given the `--opt-level`/
/// `-O` value and whether `--release` was passed (which always wins, since
/// it's an explicit, unambiguous request for maximum optimization). Split
/// out from `cmd_build` so the clamping/precedence logic can be exercised
/// directly without shelling out to clang -- see the `tests` module below.
fn opt_flag(opt_level: u8, release: bool) -> String {
    let level = if release { 3 } else { opt_level.min(3) };
    format!("-O{}", level)
}

/// The `-l<name>`/`-L<path>` flags clang should be invoked with for `-l`/
/// `--lib` and `-L`/`--lib-path`, in `-L`-before-`-l` order (matching how a
/// linker resolves `-l` against whatever search paths precede it on the
/// command line). Split out from `cmd_build` so it can be exercised directly
/// without shelling out to clang -- see the `tests` module below.
fn link_args(libs: &[String], lib_paths: &[String]) -> Vec<String> {
    lib_paths.iter().map(|p| format!("-L{}", p)).chain(libs.iter().map(|l| format!("-l{}", l))).collect()
}

/// The `-target <triple>` flag clang should be invoked with for a given
/// `--target`, or nothing for the default `Target::WindowsGnu` -- the build
/// invocation this replaces never passed `-target` at all and relied
/// entirely on clang inferring the right one from the emitted `.ll`'s own
/// `target triple` line (see `Codegen::emit`) plus the installed clang's own
/// default (this project's toolchain is an LLVM-mingw clang whose default
/// already matches). Leaving the well-tested default path's clang
/// invocation byte-for-byte unchanged avoids any risk of that inference
/// behaving differently once a flag is added; only a non-default `--target`
/// needs (and gets) an explicit override. Split out from `cmd_build` so it
/// can be exercised directly without shelling out to clang -- see the
/// `tests` module below.
fn clang_target_flag(target: star::codegen::Target) -> Vec<String> {
    if target == star::codegen::Target::default() {
        Vec::new()
    } else {
        vec!["-target".to_string(), target.triple().to_string()]
    }
}

/// The default reserved main-thread stack size for a `star build`-produced
/// executable, in bytes. Windows' own PE linker default (1MiB, inherited
/// unchanged from `ld`/`lld-link` when nothing overrides it -- confirmed via
/// a real reproduction, not just documentation) is far too small for what
/// this language explicitly, deliberately supports: the large-aggregate
/// pointer-passing convention (`Codegen::LARGE_AGGREGATE_THRESHOLD`,
/// `src/codegen/mod.rs`) exists specifically so a struct/array holding
/// megabytes of data can be a perfectly ordinary `let` binding, function
/// parameter, or return value -- but every one of those still ultimately
/// lives in *some* function's stack frame (its own, or -- for a large local
/// in `main` specifically -- `main`'s own frame, for the lifetime of the
/// program). A real Nova-16 port under `projects/nova` hit exactly this:
/// its `Cpu` struct (composed of a ~300KB `Memory` and, after this port
/// grew to 9 compositing layers, a ~650KB `Screen`) is held as one `let mut
/// c = Cpu(...)` local in `main` -- comfortably under 1MiB on its own, but
/// *combined* with even a single additional 64KB local array somewhere
/// deeper in the same call chain (`Screen::roll_x`'s temp buffer, called
/// from a real loaded program's `SROL` opcode handler), the total native
/// stack depth at that point exceeded the linker's 1MiB reserve --
/// producing a genuine `STATUS_STACK_OVERFLOW` (confirmed via a minimal,
/// language-level reproduction: a `Cpu`-sized struct held in `main` plus one
/// call to a function with its own 64KB local array, nothing recursive or
/// otherwise pathological). This isn't unbounded recursion (this compiler's
/// own front end already has a dedicated, documented fix for that class of
/// bug -- see `MAIN_STACK_SIZE` above -- covering *this* compiler's own
/// process, not executables it produces) -- it's an entirely finite,
/// correct program simply needing more stack than Windows' linker default
/// budgets for by default. 16MiB (16x the current largest known combined
/// large-aggregate-plus-locals usage, ~1MiB) gives a generous, cheap-to-grant
/// margin: reserved address space costs nothing until touched, only the
/// actually-used pages are committed, so this has no effect on a typical
/// small program's real memory footprint.
const DEFAULT_STACK_SIZE_BYTES: u64 = 16 * 1024 * 1024;

/// The linker flag(s) that raise the produced executable's reserved
/// main-thread stack to `DEFAULT_STACK_SIZE_BYTES` -- see that constant's own
/// doc comment for why this exists at all. Split out (like
/// `clang_target_flag`) so it's exercised directly in `tests` below without
/// shelling out to clang; target-specific because the two backends' linkers
/// spell "reserve more stack" differently: GNU `ld`/mingw-flavored `lld`
/// (`Target::WindowsGnu`) takes `--stack <reserve>` (a PE-header field, no
/// ELF equivalent), while a modern GNU `ld`/`lld` targeting ELF
/// (`Target::LinuxGnu`) takes `-z stack-size=<bytes>` instead -- passing
/// Windows' `--stack` under an ELF target (or vice versa) is simply an
/// unrecognized-option link error, not a silent no-op, so this can't be one
/// flag pair shared unconditionally across both.
fn stack_size_flag(target: star::codegen::Target) -> Vec<String> {
    match target {
        star::codegen::Target::WindowsGnu => {
            vec![format!("-Wl,--stack,{}", DEFAULT_STACK_SIZE_BYTES)]
        }
        star::codegen::Target::LinuxGnu => {
            vec![format!("-Wl,-z,stack-size={}", DEFAULT_STACK_SIZE_BYTES)]
        }
    }
}

/// Full pipeline: parse, type-check, emit LLVM IR, compile with clang.
#[allow(clippy::too_many_arguments)]
fn cmd_build(
    file: &str,
    search: &SearchPathArgs,
    output: Option<&str>,
    opt_level: u8,
    release: bool,
    libs: &[String],
    lib_paths: &[String],
    skip_ir_verify: bool,
    target: star::codegen::Target,
) -> ExitCode {
    let Some(resolved) = resolve_entry(file, search) else { return ExitCode::FAILURE };
    let driver = Driver::with_search_paths(&resolved.entry, resolved.search_paths);
    let compilation = match driver.compile() {
        Ok(c) => c,
        Err(e) => {
            eprintln!("error: could not read {}: {}", resolved.entry.display(), e);
            return ExitCode::FAILURE;
        }
    };

    if !compilation.is_ok() {
        eprint!("{}", compilation.render_diagnostics());
        return ExitCode::FAILURE;
    }
    eprint!("{}", compilation.render_warnings());

    let typed = compilation.typed.as_ref().expect("typed module after successful compile");
    let verification = match Driver::codegen_verified_for_target(typed, target) {
        Ok(v) => v,
        Err(diags) => {
            // `Codegen::emit` itself failed -- a genuine codegen-stage
            // semantic error (e.g. an unsupported type). There is no IR at
            // all to fall back on here, unlike a verifier finding below.
            for d in &diags {
                eprintln!("codegen error: {}", d.message);
            }
            return ExitCode::FAILURE;
        }
    };
    for w in &verification.warnings {
        eprintln!("warning: {}", w.message);
    }

    // Written before the verification-error check below (not after) so the
    // false-positive case -- a bug in this compiler's own best-effort IR
    // verifier flagging real, working IR -- isn't a dead end: the offending
    // `.ll` is on disk either way, for a manual `clang` run or a bug report,
    // whether or not this function goes on to refuse the build over it.
    let src_path = resolved.entry.as_path();
    let ll_path = src_path.with_extension("ll");
    if let Err(e) = std::fs::write(&ll_path, &verification.ir) {
        eprintln!("error: could not write {}: {}", ll_path.display(), e);
        return ExitCode::FAILURE;
    }

    if !verification.is_ok() {
        for e in &verification.errors {
            eprintln!("{}", e.message);
        }
        if !skip_ir_verify {
            eprintln!(
                "error: internal IR verifier rejected the generated IR (see above) -- refusing to hand it to clang.\n\
                 The offending IR was still written to {} for inspection; pass --skip-ir-verify to build it anyway.",
                ll_path.display()
            );
            return ExitCode::FAILURE;
        }
        eprintln!("warning: --skip-ir-verify set -- building despite the internal IR verifier's findings above.");
    }

    // Compile with clang.
    let exe_path = output
        .map(Path::new)
        .map(|p| p.to_path_buf())
        .unwrap_or_else(|| src_path.with_extension("exe"));

    let clang = find_clang();
    let status = match std::process::Command::new(&clang)
        .arg("-o")
        .arg(&exe_path)
        .arg(&ll_path)
        .arg(opt_flag(opt_level, release))
        .arg("-Wno-override-module")
        .args(clang_target_flag(target))
        .args(stack_size_flag(target))
        .args(link_args(libs, lib_paths))
        .status()
    {
        Ok(s) => s,
        Err(e) => {
            eprintln!("error: could not invoke clang: {}", e);
            return ExitCode::FAILURE;
        }
    };

    if status.success() {
        println!("ok: built {}", exe_path.display());
        ExitCode::SUCCESS
    } else {
        eprintln!("error: clang compilation failed");
        ExitCode::FAILURE
    }
}

/// Locate a `clang` executable: prefer one on `PATH`, falling back to
/// `STAR_CLANG_PATH` (see the README's "Requirements" section).
fn find_clang() -> std::path::PathBuf {
    find_clang_on(std::env::var_os("PATH").as_deref(), std::env::var_os("STAR_CLANG_PATH"))
}

/// `find_clang`'s search logic, parameterized over `PATH` and
/// `STAR_CLANG_PATH` so it can be exercised on synthetic values without
/// touching the process's real environment (see the `tests` module below).
///
/// Preference order: a `clang`/`clang.exe` found on `PATH`, then
/// `STAR_CLANG_PATH` (for a non-`PATH`-installed clang, e.g. LLVM-mingw's),
/// then a bare executable name -- letting `Command::new` fall back to the
/// OS's own `PATH` search and produce a normal "program not found" error,
/// rather than baking a personal absolute path into the compiled binary.
fn find_clang_on(
    path_var: Option<&std::ffi::OsStr>,
    star_clang_path: Option<std::ffi::OsString>,
) -> std::path::PathBuf {
    let exe_name = if cfg!(windows) { "clang.exe" } else { "clang" };
    if let Some(paths) = path_var {
        for dir in std::env::split_paths(paths) {
            let candidate = dir.join(exe_name);
            if candidate.is_file() {
                return candidate;
            }
        }
    }
    if let Some(path) = star_clang_path {
        return std::path::PathBuf::from(path);
    }
    std::path::PathBuf::from(exe_name)
}

#[cfg(test)]
mod tests {
    use super::{clang_target_flag, collect_search_paths_from, emit_llvm_ir_verified, find_clang_on, link_args, opt_flag, stack_size_flag, DEFAULT_STACK_SIZE_BYTES};

    /// `star emit llvm` on a file with an `import` must resolve it exactly
    /// like `star check`/`star build` do (both go through `Driver::compile`,
    /// which calls `star::modules::resolve`) -- previously `cmd_emit`'s
    /// `EmitKind::Llvm` branch inlined its own parse-then-check pipeline that
    /// skipped `star::modules::resolve` entirely, so every `alias::name`
    /// reference (already mangled to `alias__name` by the parser) failed as
    /// "undefined" even though the identical program built fine with `star
    /// build`. Exercises `emit_llvm_ir_verified` (the extracted, testable
    /// pipeline) directly against real files on disk, since import
    /// resolution is inherently file-based.
    #[test]
    fn emit_llvm_resolves_imports_like_check_and_build_do() {
        let dir = std::env::temp_dir().join("star_main_tests").join("emit_llvm_resolves_imports");
        std::fs::create_dir_all(&dir).expect("create test dir");
        std::fs::write(dir.join("lib.star"), "fn helper() -> i32:\n    return 42\n").expect("write lib.star");
        let main_path = dir.join("main.star");
        std::fs::write(&main_path, "import \"lib.star\" as lib\nfn main() -> i32:\n    return lib::helper()\n").expect("write main.star");

        let source = std::fs::read_to_string(&main_path).unwrap();
        let v = emit_llvm_ir_verified(&main_path, &[], &source, star::codegen::Target::default())
            .expect("should resolve the import and codegen cleanly");
        assert!(v.errors.is_empty(), "expected no IR-verifier errors, got: {:?}", v.errors.iter().map(|d| &d.message).collect::<Vec<_>>());
        let ir = v.ir;
        assert!(ir.contains("define i32 @lib__helper("), "expected the imported fn to be mangled and defined: {}", ir);
        assert!(ir.contains("call i32 @lib__helper()"), "expected main to call the mangled imported fn: {}", ir);

        std::fs::remove_dir_all(&dir).ok();
    }

    /// With no `-I` flags and no `STAR_PATH` set, the search-path list is
    /// empty -- the common case (no manifest, no explicit search paths at
    /// all) must not grow the list.
    #[test]
    fn collect_search_paths_from_empty_when_nothing_given() {
        assert!(collect_search_paths_from(&[], None).is_empty());
    }

    /// Every `-I`/`--search-path` flag becomes one `PathBuf`, in the order
    /// given.
    #[test]
    fn collect_search_paths_from_includes_every_cli_flag_in_order() {
        let cli = vec!["a".to_string(), "b".to_string()];
        assert_eq!(collect_search_paths_from(&cli, None), vec![std::path::PathBuf::from("a"), std::path::PathBuf::from("b")]);
    }

    /// `STAR_PATH` is parsed as a `PATH`-style list (semicolon-separated on
    /// Windows) and appended *after* every `-I` flag.
    #[test]
    fn collect_search_paths_from_appends_star_path_entries_after_cli_flags() {
        let cli = vec!["cli_dir".to_string()];
        let joined = std::env::join_paths(["env_dir_1", "env_dir_2"]).unwrap();
        assert_eq!(
            collect_search_paths_from(&cli, Some(joined.as_os_str())),
            vec![std::path::PathBuf::from("cli_dir"), std::path::PathBuf::from("env_dir_1"), std::path::PathBuf::from("env_dir_2")]
        );
    }

    /// `STAR_PATH` alone (no `-I` flags at all) still contributes its
    /// entries -- the two sources are independent, neither gates the other.
    #[test]
    fn collect_search_paths_from_honors_star_path_with_no_cli_flags() {
        let joined = std::env::join_paths(["only_env_dir"]).unwrap();
        assert_eq!(collect_search_paths_from(&[], Some(joined.as_os_str())), vec![std::path::PathBuf::from("only_env_dir")]);
    }

    /// `star build` with no flags at all defaults to `-O2` -- previously
    /// every build (including every shipped example) was fully unoptimized.
    #[test]
    fn opt_flag_defaults_to_o2() {
        assert_eq!(opt_flag(2, false), "-O2");
    }

    /// An explicit `-O0`/`--opt-level 0` is honored (e.g. for faster
    /// iterative debug builds), not silently overridden.
    #[test]
    fn opt_flag_honors_explicit_o0() {
        assert_eq!(opt_flag(0, false), "-O0");
    }

    /// `--release` always wins over `--opt-level`, even if a lower level was
    /// also (redundantly) specified.
    #[test]
    fn opt_flag_release_overrides_opt_level() {
        assert_eq!(opt_flag(0, true), "-O3");
        assert_eq!(opt_flag(2, true), "-O3");
    }

    /// An out-of-range `--opt-level` clamps to clang's max (`-O3`) rather
    /// than passing a flag clang would reject outright.
    #[test]
    fn opt_flag_clamps_out_of_range_level() {
        assert_eq!(opt_flag(9, false), "-O3");
    }

    /// No `-l`/`-L` flags at all produces no extra arguments -- the common
    /// case (a program using only what's already linked by default) must
    /// not grow the clang invocation.
    #[test]
    fn link_args_empty_when_no_libs_or_paths() {
        assert!(link_args(&[], &[]).is_empty());
    }

    /// Each `-l NAME` becomes a bare `-lNAME` (clang's expected spelling,
    /// no space) -- one per repeated flag, in the order given.
    #[test]
    fn link_args_formats_libs() {
        assert_eq!(link_args(&["SDL2".to_string(), "m".to_string()], &[]), vec!["-lSDL2", "-lm"]);
    }

    /// `-L` search paths are emitted *before* `-l` libraries, matching how a
    /// linker resolves `-l` only against search paths already seen on the
    /// command line.
    #[test]
    fn link_args_orders_lib_paths_before_libs() {
        let libs = vec!["SDL2".to_string()];
        let lib_paths = vec![r"C:\SDL2\lib".to_string()];
        assert_eq!(link_args(&libs, &lib_paths), vec![r"-LC:\SDL2\lib", "-lSDL2"]);
    }

    /// The default target (`Target::WindowsGnu`, `--target` never passed)
    /// adds no `-target` flag at all -- the well-tested existing build
    /// invocation stays byte-for-byte unchanged, relying (as it always has)
    /// on the emitted `.ll`'s own `target triple` line plus this project's
    /// LLVM-mingw clang's own matching default.
    #[test]
    fn clang_target_flag_empty_for_default_windows_target() {
        assert!(clang_target_flag(star::codegen::Target::WindowsGnu).is_empty());
        assert!(clang_target_flag(star::codegen::Target::default()).is_empty());
    }

    /// A non-default `--target` (currently only `linux`) becomes an explicit
    /// `-target <triple>` clang argument -- needed because clang's own
    /// default target (this project's LLVM-mingw clang defaults to
    /// `x86_64-w64-windows-gnu`) would otherwise silently override whatever
    /// the `.ll` file's own `target triple` line says.
    #[test]
    fn clang_target_flag_passes_explicit_triple_for_linux() {
        assert_eq!(
            clang_target_flag(star::codegen::Target::LinuxGnu),
            vec!["-target".to_string(), "x86_64-unknown-linux-gnu".to_string()]
        );
    }

    /// `Target::WindowsGnu` gets GNU `ld`/mingw-`lld`'s `--stack <reserve>`
    /// spelling, as one comma-joined `-Wl,` argument (not two separate
    /// arguments -- clang would otherwise treat a bare `16777216` as a stray
    /// positional/input-file argument rather than `--stack`'s value).
    #[test]
    fn stack_size_flag_uses_windows_ld_stack_spelling() {
        assert_eq!(stack_size_flag(star::codegen::Target::WindowsGnu), vec![format!("-Wl,--stack,{}", DEFAULT_STACK_SIZE_BYTES)]);
    }

    /// `Target::LinuxGnu` gets the ELF-linker spelling instead (`-z
    /// stack-size=N`) -- passing Windows' `--stack` spelling under this
    /// target would be an unrecognized-option link error, not a silent
    /// no-op, so the two targets cannot share one flag.
    #[test]
    fn stack_size_flag_uses_linux_ld_stack_spelling() {
        assert_eq!(stack_size_flag(star::codegen::Target::LinuxGnu), vec![format!("-Wl,-z,stack-size={}", DEFAULT_STACK_SIZE_BYTES)]);
    }

    /// A `clang`/`clang.exe` on `PATH` is preferred over a `STAR_CLANG_PATH`
    /// override -- the bug this guards against: `cmd_build` ignoring `PATH`
    /// entirely in favor of a fallback, contradicting `STAR_CLANG_PATH`
    /// being meant only as a fallback, not a hardcoded override.
    #[test]
    fn prefers_clang_on_path_over_hardcoded_fallback() {
        let dir = std::env::temp_dir().join("star_test_find_clang_on_path");
        std::fs::create_dir_all(&dir).unwrap();
        let exe_name = if cfg!(windows) { "clang.exe" } else { "clang" };
        let clang_path = dir.join(exe_name);
        std::fs::write(&clang_path, b"").unwrap();

        let path_var = std::env::join_paths([&dir]).unwrap();
        let found = find_clang_on(Some(&path_var), None);
        assert_eq!(found, clang_path);

        std::fs::remove_dir_all(&dir).ok();
    }

    /// With no `clang` on `PATH`, `STAR_CLANG_PATH` wins over the bare-name
    /// fallback -- this is how a non-`PATH`-installed LLVM-mingw clang gets
    /// picked up.
    #[test]
    fn falls_back_to_star_clang_path_env_var_when_not_on_path() {
        let dir = std::env::temp_dir().join("star_test_find_clang_env_var");
        std::fs::create_dir_all(&dir).unwrap();
        let path_var = std::env::join_paths([&dir]).unwrap();
        let clang_path = std::ffi::OsString::from(r"C:\llvm-mingw\bin\clang.exe");

        assert_eq!(
            find_clang_on(Some(&path_var), Some(clang_path.clone())),
            std::path::PathBuf::from(&clang_path)
        );

        std::fs::remove_dir_all(&dir).ok();
    }

    /// With no `clang` anywhere on `PATH` (or no `PATH` at all) and no
    /// `STAR_CLANG_PATH` override, the search falls back to a bare
    /// executable name rather than a personal hardcoded install path --
    /// `Command::new` then relies on the OS's own `PATH` search, giving a
    /// normal "program not found" error if nothing is installed.
    #[test]
    fn falls_back_to_bare_exe_name_when_no_path_and_no_env_override() {
        let dir = std::env::temp_dir().join("star_test_find_clang_empty");
        std::fs::create_dir_all(&dir).unwrap();
        let path_var = std::env::join_paths([&dir]).unwrap();
        let exe_name = if cfg!(windows) { "clang.exe" } else { "clang" };

        assert_eq!(find_clang_on(Some(&path_var), None), std::path::PathBuf::from(exe_name));
        assert_eq!(find_clang_on(None, None), std::path::PathBuf::from(exe_name));

        std::fs::remove_dir_all(&dir).ok();
    }
}

/// Emit tokens, AST, or LLVM IR for debugging.
fn cmd_emit(what: EmitKind, file: &str, search: &SearchPathArgs, target: star::codegen::Target) -> ExitCode {
    let Some(resolved) = resolve_entry(file, search) else { return ExitCode::FAILURE };
    let source = match std::fs::read_to_string(&resolved.entry) {
        Ok(s) => s,
        Err(e) => {
            eprintln!("error: could not read {}: {}", resolved.entry.display(), e);
            return ExitCode::FAILURE;
        }
    };
    match what {
        EmitKind::Tokens => match Driver::lex(&source) {
            Ok(tokens) => {
                for tok in tokens {
                    println!("{:?}", tok);
                }
                ExitCode::SUCCESS
            }
            Err(diags) => {
                for d in diags {
                    eprintln!("{}", d.message);
                }
                ExitCode::FAILURE
            }
        },
        EmitKind::Ast => match Driver::parse(&source) {
            Ok(module) => {
                println!("{:#?}", module);
                ExitCode::SUCCESS
            }
            Err(diags) => {
                for d in diags {
                    eprintln!("{}", d.message);
                }
                ExitCode::FAILURE
            }
        },
        // Unlike `Build`, this is explicitly a debugging tool -- so unlike
        // `cmd_build`, a verifier finding never withholds the IR text: if
        // `Codegen::emit` produced *something*, that's exactly what a
        // developer chasing a codegen bug (or a false positive in the
        // verifier itself) needs to see, printed regardless of whether
        // `crate::ir_check` was happy with it. Verifier findings still
        // print (to stderr, so they don't get piped along with the IR
        // itself) and still fail the exit code on an `Error`-severity one.
        EmitKind::Llvm => match emit_llvm_ir_verified(&resolved.entry, &resolved.search_paths, &source, target) {
            Ok(v) => {
                for w in &v.warnings {
                    eprintln!("warning: {}", w.message);
                }
                println!("{}", v.ir);
                if v.errors.is_empty() {
                    ExitCode::SUCCESS
                } else {
                    for e in &v.errors {
                        eprintln!("{}", e.message);
                    }
                    ExitCode::FAILURE
                }
            }
            Err(diags) => {
                for d in diags {
                    eprintln!("{}", d.message);
                }
                ExitCode::FAILURE
            }
        },
    }
}

/// Parse, resolve imports, type-check, and generate LLVM IR for `source`
/// (read from `file`, used only to anchor relative import paths) -- the same
/// pipeline `Driver::compile` runs for `check`/`build`, split out so `star
/// emit llvm` shares it exactly rather than drifting out of sync (previously
/// this inlined a copy that skipped `star::modules::resolve` entirely, so a
/// multi-file program's `alias::name` references -- already mangled to
/// `alias__name` by the parser -- failed as "undefined" instead of resolving,
/// even though `star check`/`star build` on the same file worked fine).
///
/// Returns the full [`star::driver::IrVerification`] (IR text plus
/// severity-split verifier findings) rather than collapsing it down to "the
/// IR, or an error", since `cmd_emit`'s `EmitKind::Llvm` branch -- an
/// explicitly debugging-oriented command -- wants to print the IR text
/// regardless of whether the verifier was happy with it.
fn emit_llvm_ir_verified(
    entry: &Path,
    search_paths: &[PathBuf],
    source: &str,
    target: star::codegen::Target,
) -> Result<star::driver::IrVerification, Vec<star::diagnostics::Diagnostic>> {
    let module = Driver::parse(source)?;
    let (module, _imported_files) = star::modules::resolve_with_search_paths(module, entry, search_paths)?;
    let mut checker = star::types::Checker::new();
    let typed = checker.check(&module)?;
    Driver::codegen_verified_for_target(&typed, target)
}
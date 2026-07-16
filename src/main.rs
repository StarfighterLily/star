//! `star` command-line entry point.
//!
//! Thin CLI over [`star::driver`]. Subcommands drive the pipeline stages:
//!
//! - `star check <file>`  — lex + parse + type-check, report diagnostics.
//! - `star build <file>`  — full pipeline to native executable via LLVM IR.
//! - `star emit <file>`   — dump tokens or the AST for debugging.

use std::path::Path;
use std::process::ExitCode;

use clap::{Parser, Subcommand, ValueEnum};
use star::driver::Driver;

#[derive(Parser)]
#[command(name = "star", version, about = "The Star game programming language compiler")]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

#[derive(Subcommand)]
enum Command {
    /// Lex, parse, and type-check a source file.
    Check {
        /// Path to a `.star` source file.
        file: String,
    },
    /// Compile a source file to a native executable.
    Build {
        /// Path to a `.star` source file.
        file: String,
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
    },
    /// Emit an intermediate representation for debugging.
    Emit {
        /// What to emit.
        #[arg(value_enum)]
        what: EmitKind,
        /// Path to a `.star` source file.
        file: String,
    },
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

fn main() -> ExitCode {
    let cli = Cli::parse();
    match cli.command {
        Command::Check { file } => cmd_check(&file),
        Command::Build { file, output, opt_level, release, libs, lib_paths } => {
            cmd_build(&file, output.as_deref(), opt_level, release, &libs, &lib_paths)
        }
        Command::Emit { what, file } => cmd_emit(what, &file),
    }
}

/// Run the front-end and print diagnostics.
fn cmd_check(file: &str) -> ExitCode {
    let driver = Driver::new(file);
    match driver.compile() {
        Ok(compilation) => {
            if compilation.is_ok() {
                println!("ok: {} parsed and type-checked successfully", file);
                ExitCode::SUCCESS
            } else {
                eprint!("{}", compilation.render_diagnostics());
                ExitCode::FAILURE
            }
        }
        Err(e) => {
            eprintln!("error: could not read {}: {}", file, e);
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

/// Full pipeline: parse, type-check, emit LLVM IR, compile with clang.
fn cmd_build(file: &str, output: Option<&str>, opt_level: u8, release: bool, libs: &[String], lib_paths: &[String]) -> ExitCode {
    let driver = Driver::new(file);
    let compilation = match driver.compile() {
        Ok(c) => c,
        Err(e) => {
            eprintln!("error: could not read {}: {}", file, e);
            return ExitCode::FAILURE;
        }
    };

    if !compilation.is_ok() {
        eprint!("{}", compilation.render_diagnostics());
        return ExitCode::FAILURE;
    }

    let typed = compilation.typed.as_ref().expect("typed module after successful compile");
    let llvm_ir = match Driver::codegen(typed) {
        Ok(ir) => ir,
        Err(diags) => {
            for d in &diags {
                eprintln!("codegen error: {}", d.message);
            }
            return ExitCode::FAILURE;
        }
    };

    // Write .ll file next to the source.
    let src_path = Path::new(file);
    let ll_path = src_path.with_extension("ll");
    if let Err(e) = std::fs::write(&ll_path, &llvm_ir) {
        eprintln!("error: could not write {}: {}", ll_path.display(), e);
        return ExitCode::FAILURE;
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

/// Locate a `clang` executable: prefer one on `PATH`, falling back to the
/// well-known LLVM install location the README documents.
fn find_clang() -> std::path::PathBuf {
    find_clang_on(std::env::var_os("PATH").as_deref())
}

/// `find_clang`'s search logic, parameterized over the `PATH` value so it
/// can be exercised on a synthetic directory list without touching the
/// process's real environment (see the `tests` module below).
fn find_clang_on(path_var: Option<&std::ffi::OsStr>) -> std::path::PathBuf {
    let exe_name = if cfg!(windows) { "clang.exe" } else { "clang" };
    if let Some(paths) = path_var {
        for dir in std::env::split_paths(paths) {
            let candidate = dir.join(exe_name);
            if candidate.is_file() {
                return candidate;
            }
        }
    }
    std::path::PathBuf::from(r"E:\LLVM\bin\clang.exe")
}

#[cfg(test)]
mod tests {
    use super::{emit_llvm_ir, find_clang_on, link_args, opt_flag};

    /// `star emit llvm` on a file with an `import` must resolve it exactly
    /// like `star check`/`star build` do (both go through `Driver::compile`,
    /// which calls `star::modules::resolve`) -- previously `cmd_emit`'s
    /// `EmitKind::Llvm` branch inlined its own parse-then-check pipeline that
    /// skipped `star::modules::resolve` entirely, so every `alias::name`
    /// reference (already mangled to `alias__name` by the parser) failed as
    /// "undefined" even though the identical program built fine with `star
    /// build`. Exercises `emit_llvm_ir` (the extracted, testable pipeline)
    /// directly against real files on disk, since import resolution is
    /// inherently file-based.
    #[test]
    fn emit_llvm_resolves_imports_like_check_and_build_do() {
        let dir = std::env::temp_dir().join("star_main_tests").join("emit_llvm_resolves_imports");
        std::fs::create_dir_all(&dir).expect("create test dir");
        std::fs::write(dir.join("lib.star"), "fn helper() -> i32:\n    return 42\n").expect("write lib.star");
        let main_path = dir.join("main.star");
        std::fs::write(&main_path, "import \"lib.star\" as lib\nfn main() -> i32:\n    return lib::helper()\n").expect("write main.star");

        let source = std::fs::read_to_string(&main_path).unwrap();
        let ir = emit_llvm_ir(main_path.to_str().unwrap(), &source).expect("should resolve the import and codegen cleanly");
        assert!(ir.contains("define i32 @lib__helper("), "expected the imported fn to be mangled and defined: {}", ir);
        assert!(ir.contains("call i32 @lib__helper()"), "expected main to call the mangled imported fn: {}", ir);

        std::fs::remove_dir_all(&dir).ok();
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

    /// A `clang`/`clang.exe` on `PATH` is preferred over the hardcoded
    /// `E:\LLVM\bin\clang.exe` fallback -- the bug this guards against: the
    /// old `cmd_build` hardcoded that path unconditionally, ignoring `PATH`
    /// entirely (contradicting the README's "Clang on PATH (or at
    /// `E:\LLVM\bin\clang.exe`)").
    #[test]
    fn prefers_clang_on_path_over_hardcoded_fallback() {
        let dir = std::env::temp_dir().join("star_test_find_clang_on_path");
        std::fs::create_dir_all(&dir).unwrap();
        let exe_name = if cfg!(windows) { "clang.exe" } else { "clang" };
        let clang_path = dir.join(exe_name);
        std::fs::write(&clang_path, b"").unwrap();

        let path_var = std::env::join_paths([&dir]).unwrap();
        let found = find_clang_on(Some(&path_var));
        assert_eq!(found, clang_path);

        std::fs::remove_dir_all(&dir).ok();
    }

    /// With no `clang` anywhere on `PATH` (or no `PATH` at all), the search
    /// falls back to the well-known LLVM install location rather than
    /// failing outright.
    #[test]
    fn falls_back_to_hardcoded_path_when_not_on_path() {
        let dir = std::env::temp_dir().join("star_test_find_clang_empty");
        std::fs::create_dir_all(&dir).unwrap();
        let path_var = std::env::join_paths([&dir]).unwrap();

        assert_eq!(find_clang_on(Some(&path_var)), std::path::PathBuf::from(r"E:\LLVM\bin\clang.exe"));
        assert_eq!(find_clang_on(None), std::path::PathBuf::from(r"E:\LLVM\bin\clang.exe"));

        std::fs::remove_dir_all(&dir).ok();
    }
}

/// Emit tokens, AST, or LLVM IR for debugging.
fn cmd_emit(what: EmitKind, file: &str) -> ExitCode {
    let source = match std::fs::read_to_string(file) {
        Ok(s) => s,
        Err(e) => {
            eprintln!("error: could not read {}: {}", file, e);
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
        EmitKind::Llvm => match emit_llvm_ir(file, &source) {
            Ok(ir) => {
                println!("{}", ir);
                ExitCode::SUCCESS
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
fn emit_llvm_ir(file: &str, source: &str) -> Result<String, Vec<star::diagnostics::Diagnostic>> {
    let module = Driver::parse(source)?;
    let (module, _imported_files) = star::modules::resolve(module, Path::new(file))?;
    let mut checker = star::types::Checker::new();
    let typed = checker.check(&module)?;
    Driver::codegen(&typed).map_err(|diags| {
        diags
            .into_iter()
            .map(|d| star::diagnostics::Diagnostic::error(format!("codegen error: {}", d.message), d.span))
            .collect()
    })
}
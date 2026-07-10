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
        Command::Build { file, output } => cmd_build(&file, output.as_deref()),
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

/// Full pipeline: parse, type-check, emit LLVM IR, compile with clang.
fn cmd_build(file: &str, output: Option<&str>) -> ExitCode {
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
        .arg("-Wno-override-module")
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
    use super::find_clang_on;

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
        EmitKind::Llvm => {
            let module = match Driver::parse(&source) {
                Ok(m) => m,
                Err(diags) => {
                    for d in diags {
                        eprintln!("{}", d.message);
                    }
                    return ExitCode::FAILURE;
                }
            };
            let mut checker = star::types::Checker::new();
            let typed = match checker.check(&module) {
                Ok(t) => t,
                Err(diags) => {
                    for d in diags {
                        eprintln!("{}", d.message);
                    }
                    return ExitCode::FAILURE;
                }
            };
            let ir = match Driver::codegen(&typed) {
                Ok(ir) => ir,
                Err(diags) => {
                    for d in diags {
                        eprintln!("codegen error: {}", d.message);
                    }
                    return ExitCode::FAILURE;
                }
            };
            println!("{}", ir);
            ExitCode::SUCCESS
        }
    }
}
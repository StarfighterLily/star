//! Compilation driver: ties the stages together and renders diagnostics.
//!
//! The driver is intentionally thin — it owns file I/O and error reporting so
//! the individual stages ([`crate::lexer`], [`crate::parser`], ...) stay pure
//! and testable. Later milestones extend [`Driver::compile`] with resolution,
//! type checking, and LLVM IR emission.

use std::fs;
use std::path::{Path, PathBuf};

use crate::ast::Module;
use crate::codegen::Codegen;
use crate::diagnostics::{self, Diagnostic, Span};
use crate::lexer::{Lexer, Token};
use crate::parser::Parser;
use crate::types::{Checker, TypedModule};

/// Outcome of running the front-end over a single source file.
pub struct Compilation {
    pub file: String,
    pub source: String,
    /// Every file pulled in transitively via `import`, in first-encountered
    /// order -- index `i` here holds the file `crate::diagnostics::Span`s
    /// with `file_id == i as u32 + 1` were produced from (`file_id == 0`
    /// always means `file`/`source` above, the root file being compiled).
    /// Populated by `crate::modules::resolve`. See `Span::file_id`'s doc
    /// comment for why this exists: without it, every diagnostic whose span
    /// originated in an imported file rendered against the *root* file's
    /// source text instead, landing on a wrong/garbled location.
    pub imported_files: Vec<(String, String)>,
    pub module: Option<Module>,
    pub typed: Option<TypedModule>,
    pub diagnostics: Vec<Diagnostic>,
}

/// Result of [`Driver::codegen_verified`]: the generated LLVM IR text,
/// always present, plus whatever `crate::ir_check::verify` found about it,
/// split by severity so a caller can act on `errors` (build-blocking)
/// without losing access to `ir` (needed even when `errors` isn't empty --
/// see that method's doc comment).
pub struct IrVerification {
    pub ir: String,
    pub errors: Vec<Diagnostic>,
    pub warnings: Vec<Diagnostic>,
}

impl IrVerification {
    pub fn is_ok(&self) -> bool {
        self.errors.is_empty()
    }
}

/// Render one `crate::ir_check::IrError` as a `Diagnostic` pointing at the
/// *generated IR's* line, not any position in the `.star` source -- there's
/// no meaningful source span for a structural defect in the emitter's own
/// output, so this always carries [`Span::dummy`] and relies on the message
/// text itself citing the IR line number.
fn ir_finding_to_diagnostic(e: crate::ir_check::IrError) -> Diagnostic {
    let prefix = match e.severity {
        crate::ir_check::Severity::Error => "internal compiler error: malformed LLVM IR emitted",
        crate::ir_check::Severity::Warning => "internal compiler notice: suspicious LLVM IR emitted",
    };
    let message = format!("{} (generated IR line {}): {}", prefix, e.line, e.message);
    match e.severity {
        crate::ir_check::Severity::Error => Diagnostic::error(message, Span::dummy()),
        crate::ir_check::Severity::Warning => Diagnostic::warning(message, Span::dummy()),
    }
}

impl Compilation {
    /// True when no error-severity diagnostics were produced.
    pub fn is_ok(&self) -> bool {
        self.module.is_some() && self.diagnostics.is_empty()
    }

    /// The `(file label, source text)` a given `Span::file_id` refers to.
    /// Falls back to the root file for an out-of-range id -- defensive only,
    /// since every real `file_id` a `Span` can carry is one this
    /// `Compilation` itself assigned while parsing (see `imported_files`'s
    /// doc comment).
    fn file_and_source(&self, file_id: u32) -> (&str, &str) {
        if file_id == 0 {
            return (&self.file, &self.source);
        }
        match self.imported_files.get(file_id as usize - 1) {
            Some((file, source)) => (file.as_str(), source.as_str()),
            None => (&self.file, &self.source),
        }
    }

    /// Render every diagnostic against the source file its own span
    /// actually came from (the root file, or whichever imported file --
    /// see `file_and_source`), not unconditionally against the root file's
    /// source text.
    pub fn render_diagnostics(&self) -> String {
        self.diagnostics
            .iter()
            .map(|d| {
                let (file, source) = self.file_and_source(d.span.file_id);
                diagnostics::render(source, file, d)
            })
            .collect()
    }
}

/// Drives the compiler pipeline for one file.
pub struct Driver {
    path: PathBuf,
    /// Extra directories `import` resolution should search beyond the
    /// importing file's own directory -- see [`resolve_input`] and
    /// `crate::modules::resolve_with_search_paths`. Empty for every caller
    /// that just wants the original relative-path-only behavior (the vast
    /// majority of this crate's own tests, via [`Driver::new`]).
    search_paths: Vec<PathBuf>,
}

impl Driver {
    pub fn new(path: impl Into<PathBuf>) -> Self {
        Self { path: path.into(), search_paths: Vec::new() }
    }

    /// Like [`Driver::new`], but `import` resolution also searches
    /// `search_paths` (in order) for any import that isn't found relative
    /// to its importing file -- see [`resolve_input`], which builds this
    /// list from CLI `-I`/`STAR_PATH` and a discovered `star.toml`.
    pub fn with_search_paths(path: impl Into<PathBuf>, search_paths: Vec<PathBuf>) -> Self {
        Self { path: path.into(), search_paths }
    }

    /// Read the source file from disk.
    fn read_source(&self) -> std::io::Result<String> {
        fs::read_to_string(&self.path)
    }

    /// Tokenize only; used by tests and the `--emit tokens` debug mode.
    pub fn lex(source: &str) -> Result<Vec<Token>, Vec<Diagnostic>> {
        Lexer::new(source).tokenize()
    }

    /// Parse only; used by tests and the `--emit ast` debug mode.
    pub fn parse(source: &str) -> Result<Module, Vec<Diagnostic>> {
        Parser::parse_source(source)
    }

    /// Type-check only; used by tests.
    pub fn check(module: &Module) -> Result<TypedModule, Vec<Diagnostic>> {
        let mut checker = Checker::new();
        checker.check(module)
    }

    /// Run the full pipeline: lex, parse, type-check, and codegen.
    pub fn compile(&self) -> std::io::Result<Compilation> {
        let source = self.read_source()?;
        let file = self.file_label();
        let (module, mut diagnostics) = match Parser::parse_source(&source) {
            Ok(module) => (Some(module), Vec::new()),
            Err(diags) => (None, diags),
        };

        // Inline any `import`ed files into a single flat module before the
        // checker ever has to think about more than one file.
        let mut imported_files = Vec::new();
        let module = match module {
            Some(m) => match crate::modules::resolve_with_search_paths(m, &self.path, &self.search_paths) {
                Ok((resolved, files)) => {
                    imported_files = files;
                    Some(resolved)
                }
                Err(diags) => {
                    diagnostics = diags;
                    None
                }
            },
            None => None,
        };

        // Run type checker if parsing succeeded.
        let typed = if let Some(ref module) = module {
            let mut checker = Checker::new();
            match checker.check(module) {
                Ok(tm) => {
                    diagnostics = Vec::new();
                    Some(tm)
                }
                Err(type_errs) => {
                    diagnostics = type_errs;
                    None
                }
            }
        } else {
            None
        };

        Ok(Compilation { file, source, imported_files, module, typed, diagnostics })
    }

    /// Generate LLVM IR from a checked module, then verify its structural
    /// well-formedness (`crate::ir_check`) before handing it back to a
    /// caller that's ultimately going to feed it to `clang`. A thin wrapper
    /// around [`Driver::codegen_verified`] for the common case (this
    /// crate's own tests, and any caller that just wants the IR or a reason
    /// it couldn't get one) -- see that method's doc comment for callers
    /// that need the generated IR text even when verification finds a
    /// problem with it (`star emit llvm`'s whole purpose).
    ///
    /// This is the fix for the systemic weak point `ASSESSMENT.md` ("The
    /// Ugly" #1) names explicitly: previously a codegen bug could produce
    /// IR that `Codegen::emit` itself considered successful (its own
    /// `errors` vec only catches semantic problems it happens to check for
    /// explicitly, e.g. an unsupported type) and that only failed once
    /// `clang` parsed the `.ll` file -- with no diagnostic pointing back
    /// into the compiler. Running the verifier here, inside `codegen`
    /// itself rather than as an opt-in step callers might forget, means
    /// every caller (`star build`, `star emit llvm`, and this crate's own
    /// tests) gets it automatically.
    pub fn codegen(typed: &TypedModule) -> Result<String, Vec<Diagnostic>> {
        let v = Self::codegen_verified(typed)?;
        if v.errors.is_empty() { Ok(v.ir) } else { Err(v.errors) }
    }

    /// [`Driver::codegen`], but never discarding the generated IR text on a
    /// verification failure -- only `Codegen::emit` itself failing (a
    /// genuine codegen-stage semantic error, e.g. an unsupported type;
    /// there is truly no IR to show in that case) is a hard `Err` here.
    /// Every [`IrError`](crate::ir_check::IrError) `crate::ir_check::verify`
    /// finds comes back split by [`Severity`](crate::ir_check::Severity)
    /// into [`IrVerification::errors`] (what `codegen`'s `Err` case is built
    /// from) and [`IrVerification::warnings`] (surfaced for a caller to
    /// print, but never on their own a reason to withhold the IR) -- so a
    /// caller that wants to inspect/emit the malformed IR a real bug
    /// produced (`star emit llvm`'s whole purpose as a debugging tool, and
    /// exactly the situation a verifier false positive would otherwise make
    /// impossible to work around) still can, by reading `.ir` regardless of
    /// whether `.errors` is empty.
    ///
    /// `crate::ir_check` is explicitly a best-effort heuristic checker over
    /// a dialect it infers from reading this compiler's own example output,
    /// not a reimplementation of LLVM's verifier (see that module's own doc
    /// comment) -- so a panic inside it is treated as "verification
    /// inconclusive," not "build failed": it's caught here and downgraded
    /// to a warning rather than taking `star build`/`star check` down over
    /// what, at worst, should cost a missed diagnostic. `clang` remains the
    /// actual authority on well-formedness either way.
    pub fn codegen_verified(typed: &TypedModule) -> Result<IrVerification, Vec<Diagnostic>> {
        Self::codegen_verified_for_target(typed, crate::codegen::Target::default())
    }

    /// [`Driver::codegen_verified`], but for a `Target` other than the
    /// default `Target::WindowsGnu` -- the `--target` flag's entry point
    /// (see `crate::main`'s `cmd_build`) and what this crate's own
    /// `Target::LinuxGnu` IR-shape tests call directly. See
    /// `crate::codegen::platform::Target`'s own doc comment.
    pub fn codegen_verified_for_target(typed: &TypedModule, target: crate::codegen::Target) -> Result<IrVerification, Vec<Diagnostic>> {
        let mut cg = Codegen::new_for_target(target);
        let ir = cg.emit(typed)?;
        let findings = match std::panic::catch_unwind(|| crate::ir_check::verify(&ir)) {
            Ok(findings) => findings,
            Err(_) => {
                let warning = Diagnostic::warning(
                    "internal IR verifier panicked and was skipped for this build (please report a bug) -- \
                     the generated IR was not double-checked before being handed to clang"
                        .to_string(),
                    Span::dummy(),
                );
                return Ok(IrVerification { ir, errors: Vec::new(), warnings: vec![warning] });
            }
        };
        let (errors, warnings): (Vec<_>, Vec<_>) = findings.into_iter().partition(|e| e.severity == crate::ir_check::Severity::Error);
        Ok(IrVerification {
            ir,
            errors: errors.into_iter().map(ir_finding_to_diagnostic).collect(),
            warnings: warnings.into_iter().map(ir_finding_to_diagnostic).collect(),
        })
    }

    /// A short label for diagnostics (the file name, not the full path).
    fn file_label(&self) -> String {
        self.path
            .file_name()
            .map(|s| s.to_string_lossy().into_owned())
            .unwrap_or_else(|| self.path.display().to_string())
    }

    pub fn path(&self) -> &Path {
        &self.path
    }
}

/// What a CLI `file` argument (`star build <file>`, `star check <file>`,
/// ...) actually resolves to once a directory-plus-manifest argument and
/// explicit `-I`/`STAR_PATH` search paths are folded in -- see
/// [`resolve_input`].
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ResolvedInput {
    /// The concrete `.star` file to feed to [`Driver::new`]/
    /// [`Driver::with_search_paths`].
    pub entry: PathBuf,
    /// The full ordered search-path list to pass to
    /// [`Driver::with_search_paths`].
    pub search_paths: Vec<PathBuf>,
    /// The project root a `star.toml` was found at, if any (whether given
    /// directly as `file` or discovered by walking up from it) -- exposed
    /// mainly so a caller can print it in a diagnostic; resolution itself
    /// only needs `entry`/`search_paths`.
    pub manifest_root: Option<PathBuf>,
}

/// Turn a CLI-supplied `file` argument plus explicit search paths (`-I`/
/// `STAR_PATH`, already parsed into `PathBuf`s by the caller) into a
/// concrete entry file and the full ordered search-path list
/// `crate::modules::resolve_with_search_paths` should consult.
///
/// Two shapes of `file` are supported:
/// - A **directory**: it must directly contain `crate::manifest::
///   MANIFEST_FILE_NAME` (`star.toml`) -- an explicit directory argument is
///   an explicit claim that it's a project root, so this deliberately does
///   *not* fall back to walking further up looking for one (unlike the file
///   case below), which would silently build a different project than the
///   one named on the command line. The manifest's own `entry` (default
///   `crate::manifest::DEFAULT_ENTRY`) becomes [`ResolvedInput::entry`], and
///   its declared search dirs plus its own directory are appended after
///   `extra_search_paths`.
/// - A **file** (including one that doesn't exist yet -- the read failure
///   surfaces later, exactly like every existing single-file caller before
///   this function existed): used verbatim as `entry`, so every pre-
///   existing caller's behavior is unchanged bit-for-bit when no manifest is
///   involved. `star.toml` is then looked up by walking up from the file's
///   own directory (`crate::manifest::discover`) purely to *augment* the
///   search path list -- if none is found, `search_paths` is just
///   `extra_search_paths` unchanged.
///
/// Either way, `extra_search_paths` always comes first in the returned
/// list, ahead of anything the manifest contributes -- an explicit `-I`/
/// `STAR_PATH` entry should win over a same-named file the project's own
/// manifest would otherwise have resolved to.
pub fn resolve_input(file: &Path, extra_search_paths: &[PathBuf]) -> Result<ResolvedInput, String> {
    if file.is_dir() {
        let loaded = crate::manifest::load_from_dir(file)?.ok_or_else(|| {
            format!("`{}` is a directory but contains no `{}`", file.display(), crate::manifest::MANIFEST_FILE_NAME)
        })?;
        let mut search_paths = extra_search_paths.to_vec();
        search_paths.extend(loaded.search_paths());
        return Ok(ResolvedInput { entry: loaded.entry_path(), search_paths, manifest_root: Some(loaded.root) });
    }

    let start_dir = file.parent().filter(|p| !p.as_os_str().is_empty()).unwrap_or_else(|| Path::new("."));
    let mut search_paths = extra_search_paths.to_vec();
    let manifest_root = match crate::manifest::discover(start_dir)? {
        Some(loaded) => {
            search_paths.extend(loaded.search_paths());
            Some(loaded.root)
        }
        None => None,
    };
    Ok(ResolvedInput { entry: file.to_path_buf(), search_paths, manifest_root })
}
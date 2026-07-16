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
use crate::diagnostics::{self, Diagnostic};
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
}

impl Driver {
    pub fn new(path: impl Into<PathBuf>) -> Self {
        Self { path: path.into() }
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
            Some(m) => match crate::modules::resolve(m, &self.path) {
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

    /// Generate LLVM IR from a checked module.
    pub fn codegen(typed: &TypedModule) -> Result<String, Vec<Diagnostic>> {
        let mut cg = Codegen::new();
        cg.emit(typed)
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
//! Source positions and compiler diagnostics.
//!
//! Every token, AST node, and error carries a [`Span`] so later stages can
//! point back at the exact byte range in the original source. Diagnostics are
//! rendered with a caret underline for readability.

use std::fmt;

/// A half-open byte range `[start, end)` into a single source file.
#[derive(Clone, Copy, PartialEq, Eq)]
pub struct Span {
    pub start: usize,
    pub end: usize,
}

impl Span {
    pub const fn new(start: usize, end: usize) -> Self {
        Self { start, end }
    }

    /// A zero-width span, useful for synthesized nodes.
    pub const fn dummy() -> Self {
        Self { start: 0, end: 0 }
    }

    /// Merge two spans into the smallest span covering both.
    pub fn to(self, other: Span) -> Span {
        Span::new(self.start.min(other.start), self.end.max(other.end))
    }
}

impl fmt::Debug for Span {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}..{}", self.start, self.end)
    }
}

/// Severity of a [`Diagnostic`].
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Severity {
    Error,
    Warning,
}

impl fmt::Display for Severity {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Severity::Error => write!(f, "error"),
            Severity::Warning => write!(f, "warning"),
        }
    }
}

/// A single compiler message tied to a source span.
#[derive(Clone, Debug)]
pub struct Diagnostic {
    pub severity: Severity,
    pub message: String,
    pub span: Span,
}

impl Diagnostic {
    pub fn error(message: impl Into<String>, span: Span) -> Self {
        Self { severity: Severity::Error, message: message.into(), span }
    }

    pub fn warning(message: impl Into<String>, span: Span) -> Self {
        Self { severity: Severity::Warning, message: message.into(), span }
    }
}

/// Translates a byte offset into a 1-based `(line, column)` pair.
fn line_col(source: &str, offset: usize) -> (usize, usize) {
    let mut line = 1;
    let mut col = 1;
    for (i, ch) in source.char_indices() {
        if i >= offset {
            break;
        }
        if ch == '\n' {
            line += 1;
            col = 1;
        } else {
            col += 1;
        }
    }
    (line, col)
}

/// Extracts the full source line containing `offset`.
fn line_text(source: &str, offset: usize) -> &str {
    let start = source[..offset.min(source.len())]
        .rfind('\n')
        .map(|i| i + 1)
        .unwrap_or(0);
    let end = source[start..]
        .find('\n')
        .map(|i| start + i)
        .unwrap_or(source.len());
    &source[start..end]
}

/// Renders a diagnostic with a file name, line/column, and caret underline.
pub fn render(source: &str, file: &str, diag: &Diagnostic) -> String {
    let (line, col) = line_col(source, diag.span.start);
    let snippet = line_text(source, diag.span.start);
    let width = diag.span.end.saturating_sub(diag.span.start).max(1);
    let caret = format!("{}{}", " ".repeat(col.saturating_sub(1)), "^".repeat(width));
    format!(
        "{sev}: {msg}\n  --> {file}:{line}:{col}\n   |\n   | {snippet}\n   | {caret}\n",
        sev = diag.severity,
        msg = diag.message,
        file = file,
        line = line,
        col = col,
        snippet = snippet,
        caret = caret,
    )
}
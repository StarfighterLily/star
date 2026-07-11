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
    /// An optional secondary hint (e.g. a "did you mean `x`?" suggestion),
    /// rendered as a trailing `= note: ...` line.
    pub note: Option<String>,
}

impl Diagnostic {
    pub fn error(message: impl Into<String>, span: Span) -> Self {
        Self { severity: Severity::Error, message: message.into(), span, note: None }
    }

    pub fn warning(message: impl Into<String>, span: Span) -> Self {
        Self { severity: Severity::Warning, message: message.into(), span, note: None }
    }

    pub fn error_with_note(message: impl Into<String>, span: Span, note: impl Into<String>) -> Self {
        Self { severity: Severity::Error, message: message.into(), span, note: Some(note.into()) }
    }
}

/// Edit distance between two strings, used to power "did you mean" suggestions.
fn edit_distance(a: &str, b: &str) -> usize {
    let a: Vec<char> = a.chars().collect();
    let b: Vec<char> = b.chars().collect();
    let mut dp = vec![vec![0usize; b.len() + 1]; a.len() + 1];
    for (i, row) in dp.iter_mut().enumerate() {
        row[0] = i;
    }
    for j in 0..=b.len() {
        dp[0][j] = j;
    }
    for i in 1..=a.len() {
        for j in 1..=b.len() {
            let cost = if a[i - 1] == b[j - 1] { 0 } else { 1 };
            dp[i][j] = (dp[i - 1][j] + 1).min(dp[i][j - 1] + 1).min(dp[i - 1][j - 1] + cost);
        }
    }
    dp[a.len()][b.len()]
}

/// Find the closest candidate to `target` by edit distance, for "did you
/// mean `X`?" notes. Returns `None` when nothing is close enough to plausibly
/// be a typo of `target`, so unrelated names aren't suggested.
pub fn suggest<'a>(target: &str, candidates: impl IntoIterator<Item = &'a str>) -> Option<&'a str> {
    let max_dist = (target.len() / 2).max(1);
    candidates
        .into_iter()
        .map(|c| (c, edit_distance(target, c)))
        .filter(|(_, d)| *d <= max_dist)
        .min_by_key(|(_, d)| *d)
        .map(|(c, _)| c)
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
    // Defensive: a `Span` should always land on a char boundary, but this is
    // the last line of defense against a rendering panic if some future
    // span-producing bug slips one through -- clamp down to the nearest
    // boundary rather than trusting the incoming offset.
    let mut offset = offset.min(source.len());
    while offset > 0 && !source.is_char_boundary(offset) {
        offset -= 1;
    }
    let start = source[..offset].rfind('\n').map(|i| i + 1).unwrap_or(0);
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
    let note = diag.note.as_ref().map(|n| format!("   = note: {}\n", n)).unwrap_or_default();
    format!(
        "{sev}: {msg}\n  --> {file}:{line}:{col}\n   |\n   | {snippet}\n   | {caret}\n{note}",
        sev = diag.severity,
        msg = diag.message,
        file = file,
        line = line,
        col = col,
        snippet = snippet,
        caret = caret,
        note = note,
    )
}
//! `star lsp` -- a minimal Language Server Protocol server over stdio.
//!
//! Deliberately small (todo.md P2 #5): no completions, no hover -- just
//! `textDocument/publishDiagnostics` driven by the exact same
//! `Driver::compile` pipeline `star check` already uses, re-run whenever a
//! document is opened or saved, plus `textDocument/definition` (see
//! `find_definition`'s doc comment for its own, separately-scoped
//! limitations). That alone turns "run `star check` by hand, then map the
//! line number back to your editor" into diagnostics appearing in-place,
//! which is the cheap, high-leverage half of "can someone actually use this
//! language" (the TextMate grammar in `editors/vscode` already covers the
//! other half -- being able to *read* `.star` source). Every other LSP
//! feature is a strict, additive extension of the same `handle_message`
//! dispatch below, not a redesign.
//!
//! Deliberately re-reads the file from disk on every check rather than
//! tracking the client's in-memory buffer via `textDocument/didChange`: the
//! LSP spec's `didSave` fires after the editor has already flushed the
//! buffer to disk, so at that moment "the file on disk" and "what's open in
//! the editor" are the same bytes -- and skipping buffer-tracking entirely
//! avoids an entire class of bugs (encoding mismatches, out-of-order
//! change events) for a "minimal" first version. `didChange` is accepted
//! (so a client isn't surprised by an "unknown notification") but
//! intentionally a no-op. `textDocument/definition` inherits this same
//! disk-truth tradeoff: it re-runs the full pipeline against the file on
//! disk, so a jump computed against unsaved edits can be stale until the
//! next save -- exactly the diagnostics-freshness tradeoff already made
//! above, not a new one.

use std::io::{self, BufRead, Write};
use std::path::{Path, PathBuf};

use serde_json::{json, Value};

use crate::ast::{Block, Expr, FStrExpr, Item, Module, Pattern, Stmt};
use crate::diagnostics::{Diagnostic, Severity, Span};
use crate::driver::Compilation;

/// Read one JSON-RPC message framed the way LSP requires: a `Content-Length:
/// N` header (plus optional other headers, ignored), a blank line, then
/// exactly `N` bytes of UTF-8 JSON. Returns `Ok(None)` on a clean EOF before
/// any header is read (the normal way a client shuts down its side of the
/// pipe), so callers can tell that apart from a genuine framing error.
fn read_message(reader: &mut impl BufRead) -> io::Result<Option<Value>> {
    let mut content_length: Option<usize> = None;
    loop {
        let mut line = String::new();
        if reader.read_line(&mut line)? == 0 {
            return if content_length.is_none() {
                Ok(None)
            } else {
                Err(io::Error::new(io::ErrorKind::UnexpectedEof, "stream ended mid-header"))
            };
        }
        let line = line.trim_end_matches(['\r', '\n']);
        if line.is_empty() {
            break;
        }
        if let Some(value) = line.strip_prefix("Content-Length:").or_else(|| line.strip_prefix("Content-Length ")) {
            content_length = value.trim().parse::<usize>().ok();
        }
    }
    let len = content_length
        .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidData, "message header missing Content-Length"))?;
    let mut buf = vec![0u8; len];
    reader.read_exact(&mut buf)?;
    serde_json::from_slice(&buf)
        .map(Some)
        .map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))
}

/// Write one JSON-RPC message with the same `Content-Length` framing
/// [`read_message`] expects on the other end.
fn write_message(writer: &mut impl Write, value: &Value) -> io::Result<()> {
    let body = serde_json::to_string(value).map_err(|e| io::Error::new(io::ErrorKind::InvalidData, e))?;
    write!(writer, "Content-Length: {}\r\n\r\n{}", body.len(), body)?;
    writer.flush()
}

/// Percent-decode a `file://` URI's path component (`%20` -> space, etc.).
/// Only decodes well-formed `%XX` escapes with valid hex digits; anything
/// else is passed through byte-for-byte rather than treated as an error --
/// URIs a real editor sends are always well-formed, so this only needs to
/// not panic on the rest.
fn percent_decode(s: &str) -> String {
    let bytes = s.as_bytes();
    let mut out = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'%' && i + 2 < bytes.len() {
            if let Ok(byte) = u8::from_str_radix(&s[i + 1..i + 3], 16) {
                out.push(byte);
                i += 3;
                continue;
            }
        }
        out.push(bytes[i]);
        i += 1;
    }
    String::from_utf8_lossy(&out).into_owned()
}

/// Turn a `file://` URI (the only scheme every editor sends for a real
/// on-disk `.star` file) into a filesystem path. Returns `None` for any
/// other scheme (e.g. `untitled:` for an unsaved buffer) -- there is no file
/// on disk to run `star check` against, so callers simply skip those rather
/// than erroring.
fn uri_to_path(uri: &str) -> Option<PathBuf> {
    let rest = uri.strip_prefix("file://")?;
    let decoded = percent_decode(rest);
    // `file:///C:/Users/...` decodes to `/C:/Users/...` -- strip the leading
    // slash in front of a drive letter so `PathBuf` sees `C:/Users/...`
    // rather than a bogus rooted-without-a-drive path.
    let bytes = decoded.as_bytes();
    let decoded = if bytes.len() > 2 && bytes[0] == b'/' && bytes[2] == b':' {
        decoded[1..].to_string()
    } else {
        decoded
    };
    Some(PathBuf::from(decoded))
}

/// Turn a filesystem path into a `file://` URI -- [`uri_to_path`]'s inverse,
/// needed by `find_definition` to point a jump target at an imported file
/// other than the one currently open (the client identifies documents by
/// URI, not by path). Always emits a triple-slash `file:///` form (`/` in
/// front of a Windows drive letter, `file:///C:/...`, mirroring
/// `uri_to_path`'s own stripping of exactly that slash) since that's the
/// form every editor sends and this server's own tests already construct by
/// hand.
fn path_to_file_uri(path: &Path) -> String {
    let raw = path.display().to_string();
    // `Path::canonicalize()` on Windows (what `crate::modules::resolve_inner`
    // computes `find_definition`'s cross-file jump targets from) prefixes its
    // result with the "extended-length"/verbatim `\\?\` marker -- harmless
    // for ordinary filesystem APIs, but not something any editor expects
    // inside a `file://` URI (confirmed via a real cross-file
    // `textDocument/definition` request producing a garbled
    // `file:////?/C:/...` URI before this strip). Stripped here, at the LSP
    // protocol boundary, rather than wherever the canonical path is first
    // computed, which should stay the precise, `canonicalize`-standard
    // representation for every other use.
    let stripped = raw.strip_prefix(r"\\?\").unwrap_or(&raw);
    let s = stripped.replace('\\', "/");
    if s.as_bytes().first() == Some(&b'/') {
        format!("file://{}", s)
    } else {
        format!("file:///{}", s)
    }
}

/// Convert a byte offset into `source` to an LSP `Position` (0-based line,
/// UTF-16-code-unit character) -- the LSP spec fixes UTF-16 as the column
/// unit regardless of the server's own internal encoding, so a non-ASCII
/// character before `offset` on its line must count for however many UTF-16
/// units it actually takes (1 for anything in the BMP, 2 for an astral
/// character), not 1 byte or 1 `char`.
fn offset_to_position(source: &str, offset: usize) -> (u32, u32) {
    let mut offset = offset.min(source.len());
    while offset > 0 && !source.is_char_boundary(offset) {
        offset -= 1;
    }
    let mut line: u32 = 0;
    let mut line_start = 0usize;
    for (i, ch) in source.char_indices() {
        if i >= offset {
            break;
        }
        if ch == '\n' {
            line += 1;
            line_start = i + 1;
        }
    }
    let character: u32 = source[line_start..offset].chars().map(|c| c.len_utf16() as u32).sum();
    (line, character)
}

/// Convert an LSP `Position` (0-based line, UTF-16-code-unit character) to a
/// byte offset into `source` -- [`offset_to_position`]'s inverse, needed to
/// turn `textDocument/definition`'s incoming cursor position into something
/// comparable against a [`Span`]'s byte offsets. A line/character past the
/// end of `source` (a stale position from a client whose in-memory buffer
/// has drifted from what's on disk -- see this module's doc comment on why
/// disk truth can lag) clamps to the nearest valid offset (end of file, or
/// end of the requested line) rather than panicking.
fn position_to_offset(source: &str, line: u32, character: u32) -> usize {
    let mut current_line: u32 = 0;
    let mut line_start = 0usize;
    if line > 0 {
        for (i, ch) in source.char_indices() {
            if ch == '\n' {
                current_line += 1;
                if current_line == line {
                    line_start = i + 1;
                    break;
                }
            }
        }
        if current_line < line {
            return source.len();
        }
    }
    let mut units: u32 = 0;
    for (i, ch) in source[line_start..].char_indices() {
        if ch == '\n' || units >= character {
            return line_start + i;
        }
        units += ch.len_utf16() as u32;
    }
    source.len()
}

/// A single-line, zero-context LSP `Diagnostic` for something that isn't
/// itself a [`Diagnostic`] with a real [`crate::diagnostics::Span`] -- an
/// import-resolution or file-read failure from before/around the compiler
/// pipeline proper (see `crate::driver::resolve_input`/`Driver::compile`'s
/// own `Err` cases). Anchored at the top of the file rather than left
/// without a location, since every LSP client requires *some* range.
fn plain_diagnostic(message: &str) -> Value {
    json!({
        "range": {"start": {"line": 0, "character": 0}, "end": {"line": 0, "character": 1}},
        "severity": 1,
        "source": "star",
        "message": message,
    })
}

/// Convert one compiler [`Diagnostic`] to an LSP `Diagnostic` JSON object.
///
/// A span whose `file_id` isn't `0` originated inside an `import`ed file
/// (see `Span::file_id`'s doc comment) -- `Compilation::imported_files` only
/// stores that file's *import-string label* and source text, not a
/// canonical path this server could turn into its own `file://` URI. Rather
/// than invent a false-precision mapping back into the currently-open
/// document, this deliberately anchors those at the top of the file with the
/// origin file named in the message text; publishing real per-file
/// diagnostics for imported files is a natural, additive follow-up (it needs
/// `crate::modules::resolve` to retain each imported file's canonical path,
/// which it doesn't today) once this minimal version proves out.
fn diagnostic_to_lsp(compilation: &Compilation, d: &Diagnostic) -> Value {
    let severity = match d.severity {
        Severity::Error => 1,
        Severity::Warning => 2,
    };
    if d.span.file_id != 0 {
        let label = compilation
            .imported_files
            .get(d.span.file_id as usize - 1)
            .map(|(label, _, _)| label.as_str())
            .unwrap_or("<imported file>");
        return json!({
            "range": {"start": {"line": 0, "character": 0}, "end": {"line": 0, "character": 1}},
            "severity": severity,
            "source": "star",
            "message": format!("[in imported file \"{}\"] {}", label, d.message),
        });
    }
    let (start_line, start_char) = offset_to_position(&compilation.source, d.span.start);
    let (end_line, mut end_char) = offset_to_position(&compilation.source, d.span.end.max(d.span.start));
    if end_line == start_line && end_char == start_char {
        end_char += 1;
    }
    json!({
        "range": {
            "start": {"line": start_line, "character": start_char},
            "end": {"line": end_line, "character": end_char},
        },
        "severity": severity,
        "source": "star",
        "message": d.message,
        "code": null,
    })
}

/// The `STAR_PATH`-derived search-path list `star check`'s CLI entry point
/// also honors (see `crate::main`'s `collect_search_paths`) -- there's no
/// CLI `-I` flag equivalent here (an LSP session has no per-file command
/// line), so `STAR_PATH` is the only source.
fn star_path_search_dirs() -> Vec<PathBuf> {
    std::env::var_os("STAR_PATH").map(|v| std::env::split_paths(&v).collect()).unwrap_or_default()
}

/// Re-run the exact `star check` pipeline against `uri`'s on-disk contents
/// and publish the result as one `textDocument/publishDiagnostics`
/// notification (always sent, even when empty -- an empty array is how a
/// client clears diagnostics from a document that's now clean).
fn check_and_publish(uri: &str, out: &mut impl Write) -> io::Result<()> {
    let Some(path) = uri_to_path(uri) else { return Ok(()) };
    let resolved = match crate::driver::resolve_input(&path, &star_path_search_dirs()) {
        Ok(r) => r,
        Err(e) => return publish_diagnostics(uri, vec![plain_diagnostic(&e)], out),
    };
    let driver = crate::driver::Driver::with_search_paths(&resolved.entry, resolved.search_paths);
    let compilation = match driver.compile() {
        Ok(c) => c,
        Err(e) => {
            let msg = format!("could not read {}: {}", resolved.entry.display(), e);
            return publish_diagnostics(uri, vec![plain_diagnostic(&msg)], out);
        }
    };
    let diagnostics: Vec<Value> = compilation
        .diagnostics
        .iter()
        .chain(compilation.warnings.iter())
        .map(|d| diagnostic_to_lsp(&compilation, d))
        .collect();
    publish_diagnostics(uri, diagnostics, out)
}

// --- textDocument/definition ------------------------------------------

/// True when `span` both belongs to `file_id` and contains `offset` --
/// every hit-test below needs the `file_id` check, not just byte-range
/// containment: a flattened multi-file [`Module`]'s spans are byte offsets
/// into their own *originating* file (see [`Span::file_id`]'s doc comment),
/// so two different files' offset ranges can and do numerically overlap.
/// `offset == span.end` counts as contained (not just `< span.end`) so a
/// cursor sitting immediately after the last character of a token -- a very
/// common place for an editor to actually report a click -- still hits it.
fn span_contains(span: Span, file_id: u32, offset: usize) -> bool {
    span.file_id == file_id && span.start <= offset && offset <= span.end
}

/// Find the resolved name of the innermost identifier-like reference whose
/// span contains `offset` in file `file_id` -- a plain [`Expr::Ident`], or
/// the leading type name of a [`Expr::StructLit`]/[`Expr::EnumVariant`], or
/// a [`Stmt::Parallel`] entry's system name. Recurses into children first so
/// a more specific nested match (e.g. an argument expression inside a
/// struct literal) wins over an enclosing one.
///
/// Deliberately does **not** track local-variable shadowing the way
/// `crate::modules::rename_module`'s own `shadowed` machinery does: a
/// parameter or `let` binding that happens to share a name with a top-level
/// declaration resolves to that top-level declaration here even where it
/// actually refers to the local. `crate::modules`'s own doc comment already
/// establishes this exact collision is real (if narrow), not hypothetical --
/// duplicating that shadow-tracking machinery here too is a natural,
/// additive follow-up once this minimal version proves out (see
/// `editors/vscode/README.md`), not required for a first, honest version.
///
/// Also does not resolve field access (`obj.field`/`obj.method()`) or type
/// annotations: `Expr::Field`'s `field` name carries no span of its own to
/// hit-test against, and `crate::ast::Type` carries no span at all -- both
/// would need resolved-type information (which struct/trait a field/method
/// actually belongs to) this minimal server doesn't have access to anyway
/// (see this module's own doc comment on hover being similarly out of
/// scope).
fn ident_ref_at(module: &Module, file_id: u32, offset: usize) -> Option<String> {
    module.items.iter().find_map(|item| ident_in_item(item, file_id, offset))
}

fn ident_in_item(item: &Item, file_id: u32, offset: usize) -> Option<String> {
    match item {
        Item::Struct(s) => s.fields.iter().find_map(|f| f.default.as_ref().and_then(|d| ident_in_expr(d, file_id, offset))),
        Item::Trait(_) | Item::Arena(_) | Item::Enum(_) | Item::Import(_) | Item::ExternFn(_) => None,
        Item::Impl(blk) => blk.methods.iter().find_map(|f| ident_in_fn(f, file_id, offset)),
        Item::Fn(f) => ident_in_fn(f, file_id, offset),
        Item::Sequence(s) => s
            .params
            .iter()
            .find_map(|p| p.default.as_ref().and_then(|d| ident_in_expr(d, file_id, offset)))
            .or_else(|| ident_in_block(&s.body, file_id, offset)),
        Item::Const(c) => ident_in_expr(&c.value, file_id, offset),
        Item::System(s) => s
            .accesses
            .iter()
            .find_map(|acc| span_contains(acc.span, file_id, offset).then(|| acc.arena.clone()))
            .or_else(|| ident_in_block(&s.body, file_id, offset)),
    }
}

fn ident_in_fn(f: &crate::ast::FnDef, file_id: u32, offset: usize) -> Option<String> {
    f.sig
        .params
        .iter()
        .find_map(|p| p.default.as_ref().and_then(|d| ident_in_expr(d, file_id, offset)))
        .or_else(|| ident_in_block(&f.body, file_id, offset))
}

fn ident_in_block(block: &Block, file_id: u32, offset: usize) -> Option<String> {
    block.stmts.iter().find_map(|s| ident_in_stmt(s, file_id, offset))
}

fn ident_in_stmt(stmt: &Stmt, file_id: u32, offset: usize) -> Option<String> {
    match stmt {
        Stmt::Let { value, .. } => ident_in_expr(value, file_id, offset),
        Stmt::Assign { target, value, .. } => ident_in_expr(target, file_id, offset).or_else(|| ident_in_expr(value, file_id, offset)),
        Stmt::Return { value, .. } => value.as_ref().and_then(|v| ident_in_expr(v, file_id, offset)),
        Stmt::Expr(e) => ident_in_expr(e, file_id, offset),
        Stmt::If { cond, then_block, else_block, .. } => ident_in_expr(cond, file_id, offset)
            .or_else(|| ident_in_block(then_block, file_id, offset))
            .or_else(|| else_block.as_ref().and_then(|b| ident_in_block(b, file_id, offset))),
        Stmt::While { cond, body, else_block, .. } => ident_in_expr(cond, file_id, offset)
            .or_else(|| ident_in_block(body, file_id, offset))
            .or_else(|| else_block.as_ref().and_then(|b| ident_in_block(b, file_id, offset))),
        Stmt::For { start, end, body, .. } => ident_in_expr(start, file_id, offset)
            .or_else(|| ident_in_expr(end, file_id, offset))
            .or_else(|| ident_in_block(body, file_id, offset)),
        Stmt::Break { .. } | Stmt::Continue { .. } | Stmt::Yield { .. } => None,
        Stmt::Frame { body, .. } | Stmt::Par { body, .. } | Stmt::Each { body, .. } => ident_in_block(body, file_id, offset),
        Stmt::Spawn { args, .. } => args.iter().find_map(|a| ident_in_expr(a, file_id, offset)),
        Stmt::Despawn { index, .. } => ident_in_expr(index, file_id, offset),
        Stmt::Parallel { systems, .. } => systems.iter().find_map(|(name, span)| span_contains(*span, file_id, offset).then(|| name.clone())),
    }
}

fn ident_in_pattern(pattern: &Pattern, file_id: u32, offset: usize) -> Option<String> {
    match pattern {
        Pattern::Compare(_, e) => ident_in_expr(e, file_id, offset),
        Pattern::Wildcard | Pattern::Int(_) | Pattern::Bool(_) | Pattern::Binding(_) | Pattern::EnumVariant(..) | Pattern::Struct(..) => None,
    }
}

fn ident_in_expr(expr: &Expr, file_id: u32, offset: usize) -> Option<String> {
    match expr {
        Expr::Ident(name, span) => span_contains(*span, file_id, offset).then(|| name.clone()),
        Expr::Int(..) | Expr::Float(..) | Expr::Str(..) | Expr::Bool(..) | Expr::Char(..) | Expr::SelfExpr(..) | Expr::RingNew { .. } => None,
        Expr::FStr(parts, _) => parts.iter().find_map(|p| match p {
            FStrExpr::Literal(_) => None,
            FStrExpr::Expr(e) => ident_in_expr(e, file_id, offset),
        }),
        Expr::Field { base, .. } => ident_in_expr(base, file_id, offset),
        Expr::Call { callee, args, .. } => {
            ident_in_expr(callee, file_id, offset).or_else(|| args.iter().find_map(|a| ident_in_expr(a, file_id, offset)))
        }
        Expr::Binary { lhs, rhs, .. } => ident_in_expr(lhs, file_id, offset).or_else(|| ident_in_expr(rhs, file_id, offset)),
        Expr::Unary { operand, .. } => ident_in_expr(operand, file_id, offset),
        Expr::Match { scrutinee, arms, .. } => ident_in_expr(scrutinee, file_id, offset).or_else(|| {
            arms.iter()
                .find_map(|a| ident_in_pattern(&a.pattern, file_id, offset).or_else(|| ident_in_block(&a.body, file_id, offset)))
        }),
        Expr::StructLit { name, span, args, .. } => args
            .iter()
            .find_map(|a| ident_in_expr(a, file_id, offset))
            .or_else(|| span_contains(*span, file_id, offset).then(|| name.clone())),
        Expr::If { cond, then_block, else_block, .. } => ident_in_expr(cond, file_id, offset)
            .or_else(|| ident_in_block(then_block, file_id, offset))
            .or_else(|| else_block.as_ref().and_then(|b| ident_in_block(b, file_id, offset))),
        Expr::GenRefCreate { value, .. } => ident_in_expr(value, file_id, offset),
        Expr::GenRefIndex { base, index, .. } => ident_in_expr(base, file_id, offset).or_else(|| ident_in_expr(index, file_id, offset)),
        Expr::EnumVariant { enum_name, span, args, .. } => args
            .iter()
            .find_map(|a| ident_in_expr(a, file_id, offset))
            .or_else(|| span_contains(*span, file_id, offset).then(|| enum_name.clone())),
        Expr::Lambda { body, .. } => ident_in_block(body, file_id, offset),
        Expr::ListLit(elems, _) | Expr::TupleLit(elems, _) => elems.iter().find_map(|e| ident_in_expr(e, file_id, offset)),
        Expr::Try { inner, .. } => ident_in_expr(inner, file_id, offset),
        Expr::TupleIndex { base, .. } => ident_in_expr(base, file_id, offset),
        Expr::ArrayRepeat { value, .. } => ident_in_expr(value, file_id, offset),
        Expr::Cast { expr, .. } => ident_in_expr(expr, file_id, offset),
        Expr::WrappingNew { value, .. } | Expr::FixedNew { value, .. } | Expr::BitFieldNew { value, .. } => ident_in_expr(value, file_id, offset),
        Expr::Spawn { args, .. } => args.iter().find_map(|a| ident_in_expr(a, file_id, offset)),
    }
}

/// The whole-declaration [`Span`] of the top-level [`Item`] in `module` that
/// declares `name` (already mangled, if it came from an import -- see
/// `crate::modules::mangle_name`), if any.
fn item_span(item: &Item) -> Span {
    match item {
        Item::Struct(s) => s.span,
        Item::Trait(t) => t.span,
        Item::Impl(b) => b.span,
        Item::Fn(f) => f.span,
        Item::Arena(a) => a.span,
        Item::Sequence(s) => s.span,
        Item::Enum(e) => e.span,
        Item::Import(i) => i.span,
        Item::ExternFn(e) => e.span,
        Item::Const(c) => c.span,
        Item::System(s) => s.span,
    }
}

fn find_declaration(module: &Module, name: &str) -> Option<Span> {
    module.items.iter().find_map(|item| (crate::modules::item_top_level_name(item) == Some(name)).then(|| item_span(item)))
}

/// Narrow a declaration's whole-item [`Span`] (covering `fn foo(...):
/// <body>` in its entirety) down to just the `foo` name token, by re-lexing
/// `source` (the *declaring* file's own text -- not necessarily the file the
/// original click happened in) and taking the first `TokenKind::Ident` token
/// at or after `item_span.start`. Exact, not a heuristic guess: every
/// declaration this server offers a jump target for
/// (`Struct`/`Trait`/`Fn`/`Arena`/`Sequence`/`Enum`/`Const`/`System`) writes
/// its own name as the very first identifier token following its declaring
/// keyword, before any type-parameter/parameter/field list. This can't just
/// search `source` for the literal text of `name`: for an item pulled in
/// through an `import`, `name` is already `alias__`-mangled
/// (`crate::modules::mangle_name`) while the declaring file's own source
/// text still says the plain, unmangled name -- a substring search for the
/// mangled form would never match. Falls back to the whole-item span if
/// lexing fails or no such token is found (defensive only: shouldn't happen
/// for source that already parsed successfully once to produce `item_span`).
fn declaration_name_span(source: &str, item_span: Span) -> Span {
    let Ok(tokens) = crate::lexer::Lexer::new(source).tokenize() else { return item_span };
    tokens
        .iter()
        .find(|t| t.span.start >= item_span.start && matches!(t.kind, crate::lexer::TokenKind::Ident(_)))
        .map(|t| t.span)
        .unwrap_or(item_span)
}

/// Handle one `textDocument/definition` request: re-run the full compile
/// pipeline against `uri`'s on-disk contents (see this module's doc comment
/// on why disk, not the client's in-memory buffer), find the identifier
/// reference at `position` (see [`ident_ref_at`] for exactly what counts),
/// and resolve it to the declaration's location. Returns `None` (which the
/// caller turns into a `null` LSP result, meaning "no definition found") for
/// every reason that can fail: an `untitled:`/non-`file:` URI, a file that
/// doesn't parse/import-resolve at all (`compilation.module` is `None`),
/// a position that isn't on any recognized identifier reference, or a
/// reference [`ident_ref_at`] resolved to a name with no matching top-level
/// declaration (a local variable/parameter reference, or a call to a
/// builtin/extern function -- see `ident_ref_at`'s own doc comment for what
/// this deliberately doesn't attempt).
fn find_definition(msg: &Value) -> Option<Value> {
    let uri = text_document_uri(msg)?;
    let path = uri_to_path(uri)?;
    let line = msg.pointer("/params/position/line")?.as_u64()? as u32;
    let character = msg.pointer("/params/position/character")?.as_u64()? as u32;

    let resolved = crate::driver::resolve_input(&path, &star_path_search_dirs()).ok()?;
    let driver = crate::driver::Driver::with_search_paths(&resolved.entry, resolved.search_paths);
    let compilation = driver.compile().ok()?;
    let module = compilation.module.as_ref()?;

    let offset = position_to_offset(&compilation.source, line, character);
    let name = ident_ref_at(module, 0, offset)?;
    let decl_span = find_declaration(module, &name)?;

    let (target_uri, source) = if decl_span.file_id == 0 {
        (uri.to_string(), compilation.source.as_str())
    } else {
        let (_, source, canonical) = compilation.imported_files.get(decl_span.file_id as usize - 1)?;
        (path_to_file_uri(canonical), source.as_str())
    };
    let name_span = declaration_name_span(source, decl_span);
    let (start_line, start_char) = offset_to_position(source, name_span.start);
    let (end_line, end_char) = offset_to_position(source, name_span.end);
    Some(json!({
        "uri": target_uri,
        "range": {
            "start": {"line": start_line, "character": start_char},
            "end": {"line": end_line, "character": end_char},
        },
    }))
}

fn publish_diagnostics(uri: &str, diagnostics: Vec<Value>, out: &mut impl Write) -> io::Result<()> {
    write_message(
        out,
        &json!({
            "jsonrpc": "2.0",
            "method": "textDocument/publishDiagnostics",
            "params": {"uri": uri, "diagnostics": diagnostics},
        }),
    )
}

fn text_document_uri(msg: &Value) -> Option<&str> {
    msg.pointer("/params/textDocument/uri").and_then(Value::as_str)
}

/// What [`LspServer::handle_message`] tells its caller's read loop to do
/// next.
enum Action {
    Continue,
    Exit,
}

/// All the state one `star lsp` session needs -- currently just whether
/// `shutdown` has been received, which decides `exit`'s process exit code
/// per the LSP spec (0 if the client shut down cleanly first, 1 if `exit`
/// arrives without a preceding `shutdown`, signaling a client-side protocol
/// error). Everything else this server does is a pure function of the
/// message just received plus the filesystem, so there's nothing else to
/// hold onto yet.
#[derive(Default)]
struct LspServer {
    shutdown_received: bool,
}

impl LspServer {
    fn respond(&self, id: Option<Value>, result: Value, out: &mut impl Write) -> io::Result<()> {
        let Some(id) = id else { return Ok(()) };
        write_message(out, &json!({"jsonrpc": "2.0", "id": id, "result": result}))
    }

    fn respond_error(&self, id: Value, code: i64, message: &str, out: &mut impl Write) -> io::Result<()> {
        write_message(out, &json!({"jsonrpc": "2.0", "id": id, "error": {"code": code, "message": message}}))
    }

    fn handle_initialize(&self, id: Option<Value>, out: &mut impl Write) -> io::Result<()> {
        let result = json!({
            "capabilities": {
                // `openClose` + `save` are all this server acts on; `change`
                // is accepted (clients otherwise assume the server wants
                // full-document sync by default) but never inspected -- see
                // this module's doc comment for why.
                "textDocumentSync": {"openClose": true, "change": 1, "save": {"includeText": false}},
                "definitionProvider": true,
            },
            "serverInfo": {"name": "star-lsp", "version": env!("CARGO_PKG_VERSION")},
        });
        self.respond(id, result, out)
    }

    /// Dispatch one already-parsed JSON-RPC message. Returns
    /// [`Action::Exit`] only for the `exit` notification -- every other
    /// message, including an error response to an unrecognized request,
    /// keeps the session running (a client sending one message this server
    /// doesn't understand yet is exactly the "expand on this later" case
    /// this module's doc comment calls out, not a reason to tear down the
    /// whole connection).
    fn handle_message(&mut self, msg: Value, out: &mut impl Write) -> io::Result<Action> {
        let method = msg.get("method").and_then(Value::as_str).map(str::to_string);
        let id = msg.get("id").cloned();
        match method.as_deref() {
            Some("initialize") => self.handle_initialize(id, out)?,
            Some("initialized") => {}
            Some("shutdown") => {
                self.shutdown_received = true;
                self.respond(id, Value::Null, out)?;
            }
            Some("exit") => return Ok(Action::Exit),
            Some("textDocument/didOpen") | Some("textDocument/didSave") => {
                if let Some(uri) = text_document_uri(&msg) {
                    check_and_publish(uri, out)?;
                }
            }
            Some("textDocument/didClose") => {
                if let Some(uri) = text_document_uri(&msg) {
                    publish_diagnostics(uri, Vec::new(), out)?;
                }
            }
            Some("textDocument/didChange") => {}
            Some("textDocument/definition") => {
                self.respond(id, find_definition(&msg).unwrap_or(Value::Null), out)?;
            }
            Some(other) => {
                if let Some(id) = id {
                    self.respond_error(id, -32601, &format!("method not found: {other}"), out)?;
                }
            }
            None => {}
        }
        Ok(Action::Continue)
    }
}

/// Entry point for `star lsp`: read JSON-RPC messages from stdin, dispatch
/// them, write responses/notifications to stdout, until `exit` or a clean
/// EOF. Exit code follows the LSP spec's `exit` handling: success if
/// `shutdown` was received first, failure if a client sends `exit` without
/// it (or the pipe simply errors out).
pub fn run() -> std::process::ExitCode {
    let stdin = io::stdin();
    let mut reader = stdin.lock();
    let stdout = io::stdout();
    let mut writer = stdout.lock();
    let mut server = LspServer::default();
    loop {
        match read_message(&mut reader) {
            Ok(Some(msg)) => match server.handle_message(msg, &mut writer) {
                Ok(Action::Continue) => {}
                Ok(Action::Exit) => {
                    return if server.shutdown_received {
                        std::process::ExitCode::SUCCESS
                    } else {
                        std::process::ExitCode::FAILURE
                    };
                }
                Err(e) => {
                    eprintln!("star lsp: error handling message: {e}");
                    return std::process::ExitCode::FAILURE;
                }
            },
            Ok(None) => return std::process::ExitCode::SUCCESS,
            Err(e) => {
                eprintln!("star lsp: error reading message: {e}");
                return std::process::ExitCode::FAILURE;
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Cursor;

    fn temp_star_file(name: &str, contents: &str) -> PathBuf {
        let dir = std::env::temp_dir().join("star_lsp_tests");
        std::fs::create_dir_all(&dir).unwrap();
        let path = dir.join(name);
        std::fs::write(&path, contents).unwrap();
        path
    }

    /// `%20`/`%3A`-style escapes decode to the literal bytes they represent;
    /// anything not a well-formed `%XX` escape (a bare `%`, or one followed
    /// by non-hex) passes through unchanged rather than panicking.
    #[test]
    fn percent_decode_handles_escapes_and_leaves_the_rest_alone() {
        assert_eq!(percent_decode("hello%20world"), "hello world");
        assert_eq!(percent_decode("C%3A/foo"), "C:/foo");
        assert_eq!(percent_decode("100%-done"), "100%-done");
        assert_eq!(percent_decode("no escapes here"), "no escapes here");
    }

    /// A Windows-style `file:///C:/Users/...` URI must lose exactly the
    /// slash in front of the drive letter, not become `/C:/Users/...`
    /// (which `PathBuf` would treat as rooted with no drive) or `C/Users/...`
    /// (which would eat the colon).
    #[test]
    fn uri_to_path_strips_leading_slash_before_a_windows_drive_letter() {
        let path = uri_to_path("file:///C:/Users/test/file.star").unwrap();
        assert_eq!(path, PathBuf::from("C:/Users/test/file.star"));
    }

    /// A non-`file` scheme (e.g. `untitled:` for a never-saved buffer) has
    /// no on-disk path to check against, so this must return `None` rather
    /// than fabricate a nonsense path.
    #[test]
    fn uri_to_path_rejects_non_file_schemes() {
        assert!(uri_to_path("untitled:Untitled-1").is_none());
    }

    /// A plain single-line ASCII offset lands on the expected 0-based
    /// line/character.
    #[test]
    fn offset_to_position_ascii_single_line() {
        assert_eq!(offset_to_position("fn main():", 3), (0, 3));
    }

    /// An offset on a later line resets the character count to be relative
    /// to that line's own start, not the whole file.
    #[test]
    fn offset_to_position_counts_lines() {
        let src = "let a = 1\nlet b = 2\n";
        // "let b" starts at byte 10 (right after the first "\n").
        assert_eq!(offset_to_position(src, 10), (1, 0));
        assert_eq!(offset_to_position(src, 14), (1, 4));
    }

    /// A non-BMP character (e.g. an astral emoji, 4 UTF-8 bytes) must count
    /// as *2* UTF-16 code units for everything after it on the same line --
    /// the LSP spec fixes UTF-16 as the column unit regardless of this
    /// server's own UTF-8 internals.
    #[test]
    fn offset_to_position_counts_utf16_units_not_bytes_or_chars() {
        let src = "a\u{1F600}b"; // 'a', grinning-face emoji (4 UTF-8 bytes, 2 UTF-16 units), 'b'
        let b_offset = "a\u{1F600}".len();
        assert_eq!(offset_to_position(src, b_offset), (0, 3)); // 1 ('a') + 2 (emoji)
    }

    /// A message written by `write_message` round-trips through
    /// `read_message` byte-for-byte as the same JSON value.
    #[test]
    fn write_then_read_message_round_trips() {
        let mut buf = Cursor::new(Vec::new());
        let msg = json!({"jsonrpc": "2.0", "method": "initialized", "params": {}});
        write_message(&mut buf, &msg).unwrap();
        buf.set_position(0);
        let read_back = read_message(&mut buf).unwrap().unwrap();
        assert_eq!(read_back, msg);
    }

    /// A clean EOF before any bytes at all is a normal end-of-session, not
    /// an error -- this is how a client disconnecting without an explicit
    /// `exit` notification should be handled.
    #[test]
    fn read_message_returns_none_on_clean_eof() {
        let mut buf = Cursor::new(Vec::new());
        assert!(read_message(&mut buf).unwrap().is_none());
    }

    /// `initialize` must answer with the same `id` the client sent, and
    /// advertise `openClose`+`save` sync so a client knows to send
    /// `didOpen`/`didSave`.
    #[test]
    fn initialize_responds_with_matching_id_and_sync_capabilities() {
        let mut server = LspServer::default();
        let mut out = Cursor::new(Vec::new());
        let request = json!({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {}});
        server.handle_message(request, &mut out).unwrap();

        out.set_position(0);
        let response = read_message(&mut out).unwrap().unwrap();
        assert_eq!(response["id"], json!(1));
        assert_eq!(response["result"]["capabilities"]["textDocumentSync"]["openClose"], json!(true));
    }

    /// An unrecognized method that expects a reply (carries an `id`) gets a
    /// JSON-RPC "method not found" error, not silence -- an LSP client
    /// blocks on a response for every request it sends by `id`, so silently
    /// dropping one would hang it.
    #[test]
    fn unknown_request_gets_method_not_found_error() {
        let mut server = LspServer::default();
        let mut out = Cursor::new(Vec::new());
        let request = json!({"jsonrpc": "2.0", "id": 42, "method": "textDocument/hover", "params": {}});
        server.handle_message(request, &mut out).unwrap();

        out.set_position(0);
        let response = read_message(&mut out).unwrap().unwrap();
        assert_eq!(response["id"], json!(42));
        assert_eq!(response["error"]["code"], json!(-32601));
    }

    /// An unrecognized *notification* (no `id`) is simply ignored -- there's
    /// no `id` to answer, and a notification's sender never waits for one.
    #[test]
    fn unknown_notification_is_silently_ignored() {
        let mut server = LspServer::default();
        let mut out = Cursor::new(Vec::new());
        let notification = json!({"jsonrpc": "2.0", "method": "$/somethingUnknown", "params": {}});
        server.handle_message(notification, &mut out).unwrap();
        assert!(out.get_ref().is_empty());
    }

    /// `shutdown` then `exit` is the clean-shutdown sequence: `exit` must
    /// report [`Action::Exit`], and the caller (`run`) uses
    /// `shutdown_received` to pick exit code 0 for this sequence specifically.
    #[test]
    fn shutdown_then_exit_is_a_clean_exit() {
        let mut server = LspServer::default();
        let mut out = Cursor::new(Vec::new());
        server.handle_message(json!({"jsonrpc": "2.0", "id": 1, "method": "shutdown"}), &mut out).unwrap();
        assert!(server.shutdown_received);
        let action = server.handle_message(json!({"jsonrpc": "2.0", "method": "exit"}), &mut out).unwrap();
        assert!(matches!(action, Action::Exit));
    }

    /// `exit` with no preceding `shutdown` is still `Action::Exit`, but
    /// `shutdown_received` stays `false` -- `run` maps this combination to a
    /// non-zero exit code per the LSP spec.
    #[test]
    fn exit_without_shutdown_still_exits_but_flag_stays_false() {
        let mut server = LspServer::default();
        let mut out = Cursor::new(Vec::new());
        let action = server.handle_message(json!({"jsonrpc": "2.0", "method": "exit"}), &mut out).unwrap();
        assert!(matches!(action, Action::Exit));
        assert!(!server.shutdown_received);
    }

    /// `didOpen` on a file with a real type error publishes exactly one
    /// diagnostic, at the error's real location, with `severity: 1` (Error).
    #[test]
    fn did_open_on_erroring_file_publishes_error_diagnostic() {
        let path = temp_star_file(
            "did_open_error.star",
            "fn main() -> i32:\n    let x: i32 = \"not an int\"\n    return x\n",
        );
        let uri = path_to_file_uri(&path);
        let mut server = LspServer::default();
        let mut out = Cursor::new(Vec::new());
        let msg = json!({
            "jsonrpc": "2.0",
            "method": "textDocument/didOpen",
            "params": {"textDocument": {"uri": uri, "text": ""}},
        });
        server.handle_message(msg, &mut out).unwrap();

        out.set_position(0);
        let notification = read_message(&mut out).unwrap().unwrap();
        assert_eq!(notification["method"], json!("textDocument/publishDiagnostics"));
        assert_eq!(notification["params"]["uri"], json!(uri));
        let diags = notification["params"]["diagnostics"].as_array().unwrap();
        assert_eq!(diags.len(), 1, "expected exactly one diagnostic, got: {:?}", diags);
        assert_eq!(diags[0]["severity"], json!(1));
        // The bad `let` is on the second (0-based line 1) source line.
        assert_eq!(diags[0]["range"]["start"]["line"], json!(1));
    }

    /// `didSave` on a clean file publishes an empty diagnostics array (not
    /// no message at all) -- a client relies on receiving *some*
    /// `publishDiagnostics` to know a previously-erroring document is now
    /// clean.
    #[test]
    fn did_save_on_clean_file_publishes_empty_diagnostics() {
        let path = temp_star_file("did_save_clean.star", "fn main() -> i32:\n    return 0\n");
        let uri = path_to_file_uri(&path);
        let mut server = LspServer::default();
        let mut out = Cursor::new(Vec::new());
        let msg = json!({
            "jsonrpc": "2.0",
            "method": "textDocument/didSave",
            "params": {"textDocument": {"uri": uri}},
        });
        server.handle_message(msg, &mut out).unwrap();

        out.set_position(0);
        let notification = read_message(&mut out).unwrap().unwrap();
        assert_eq!(notification["params"]["diagnostics"].as_array().unwrap().len(), 0);
    }

    /// `didClose` always publishes an empty diagnostics array, clearing
    /// whatever was previously shown for that document -- an editor removes
    /// a closed document's problems from its UI, and relies on the server
    /// to say so explicitly rather than inferring it.
    #[test]
    fn did_close_clears_diagnostics() {
        let mut server = LspServer::default();
        let mut out = Cursor::new(Vec::new());
        let msg = json!({
            "jsonrpc": "2.0",
            "method": "textDocument/didClose",
            "params": {"textDocument": {"uri": "file:///C:/some/file.star"}},
        });
        server.handle_message(msg, &mut out).unwrap();

        out.set_position(0);
        let notification = read_message(&mut out).unwrap().unwrap();
        assert_eq!(notification["method"], json!("textDocument/publishDiagnostics"));
        assert_eq!(notification["params"]["diagnostics"].as_array().unwrap().len(), 0);
    }

    /// A `didOpen` referencing a file that doesn't exist on disk publishes a
    /// single diagnostic describing the read failure, rather than silently
    /// doing nothing (which would look, from the editor's side, identical
    /// to "everything's fine").
    #[test]
    fn did_open_on_missing_file_publishes_a_diagnostic() {
        let path = std::env::temp_dir().join("star_lsp_tests").join("does_not_exist_at_all.star");
        let _ = std::fs::remove_file(&path);
        let uri = path_to_file_uri(&path);
        let mut server = LspServer::default();
        let mut out = Cursor::new(Vec::new());
        let msg = json!({
            "jsonrpc": "2.0",
            "method": "textDocument/didOpen",
            "params": {"textDocument": {"uri": uri, "text": ""}},
        });
        server.handle_message(msg, &mut out).unwrap();

        out.set_position(0);
        let notification = read_message(&mut out).unwrap().unwrap();
        let diags = notification["params"]["diagnostics"].as_array().unwrap();
        assert_eq!(diags.len(), 1);
        assert_eq!(diags[0]["severity"], json!(1));
    }

    /// `initialize` also advertises `definitionProvider: true` -- without
    /// this, `vscode-languageclient` (and most other LSP clients) never
    /// sends `textDocument/definition` requests at all, so "go to
    /// definition" would silently do nothing regardless of whether
    /// `find_definition` itself worked.
    #[test]
    fn initialize_advertises_definition_provider() {
        let mut server = LspServer::default();
        let mut out = Cursor::new(Vec::new());
        server
            .handle_message(json!({"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {}}), &mut out)
            .unwrap();

        out.set_position(0);
        let response = read_message(&mut out).unwrap().unwrap();
        assert_eq!(response["result"]["capabilities"]["definitionProvider"], json!(true));
    }

    /// Send a `textDocument/definition` request for `uri` at `line`/
    /// `character` and return the raw JSON `result` (a `Location` object, or
    /// `Value::Null` for "no definition found").
    fn request_definition(uri: &str, line: u32, character: u32) -> Value {
        let mut server = LspServer::default();
        let mut out = Cursor::new(Vec::new());
        let msg = json!({
            "jsonrpc": "2.0",
            "id": 1,
            "method": "textDocument/definition",
            "params": {"textDocument": {"uri": uri}, "position": {"line": line, "character": character}},
        });
        server.handle_message(msg, &mut out).unwrap();
        out.set_position(0);
        let response = read_message(&mut out).unwrap().unwrap();
        response["result"].clone()
    }

    /// Clicking on a function-call callee (`helper` in `return helper()`)
    /// jumps to that function's own declaration, at just the name token
    /// (not the whole `fn helper() -> i32:` signature).
    #[test]
    fn definition_jumps_from_call_to_function_declaration() {
        let path = temp_star_file(
            "definition_call.star",
            "fn helper() -> i32:\n    return 42\n\nfn main() -> i32:\n    return helper()\n",
        );
        let uri = path_to_file_uri(&path);
        // Line 4: "    return helper()" -- 'h' of "helper" is at column 11.
        let result = request_definition(&uri, 4, 12);

        assert_eq!(result["uri"], json!(uri));
        assert_eq!(result["range"]["start"]["line"], json!(0));
        // Line 0: "fn helper() -> i32:" -- 'h' of "helper" is at column 3.
        assert_eq!(result["range"]["start"]["character"], json!(3));
        assert_eq!(result["range"]["end"]["character"], json!(3 + "helper".len() as u32));
    }

    /// Clicking on a struct literal's leading type name (`Point` in `Point(x
    /// = 1, y = 2)`) jumps to that struct's own declaration -- the click
    /// site's span covers the whole literal (name plus every argument), not
    /// just the name token, so this also confirms clicking `Point`
    /// specifically (rather than, say, inside `x = 1`) is what resolves,
    /// not merely "anywhere in the literal."
    #[test]
    fn definition_jumps_from_struct_literal_to_struct_declaration() {
        let path = temp_star_file(
            "definition_struct_lit.star",
            "struct Point:\n    x: i32\n    y: i32\n\nfn main() -> i32:\n    let p = Point(x = 1, y = 2)\n    return p.x\n",
        );
        let uri = path_to_file_uri(&path);
        // Line 5: "    let p = Point(x = 1, y = 2)" -- 'P' of "Point" is at column 12.
        let result = request_definition(&uri, 5, 13);

        assert_eq!(result["uri"], json!(uri));
        assert_eq!(result["range"]["start"]["line"], json!(0));
        // Line 0: "struct Point:" -- 'P' of "Point" is at column 7.
        assert_eq!(result["range"]["start"]["character"], json!(7));
    }

    /// A qualified `alias::name` cross-file reference jumps into the
    /// *imported* file, not the one currently open -- exercising the
    /// canonical-path plumbing `crate::modules::resolve` now retains
    /// specifically for this (previously discarded after cycle detection;
    /// see `crate::modules::resolve`'s doc comment).
    #[test]
    fn definition_jumps_across_files_for_qualified_import_reference() {
        let dir = std::env::temp_dir().join("star_lsp_tests").join("definition_cross_file");
        std::fs::create_dir_all(&dir).unwrap();
        let lib_path = dir.join("lib.star");
        std::fs::write(&lib_path, "fn helper() -> i32:\n    return 42\n").unwrap();
        let main_path = dir.join("main.star");
        std::fs::write(&main_path, "import \"lib.star\" as lib\nfn main() -> i32:\n    return lib::helper()\n").unwrap();

        let main_uri = path_to_file_uri(&main_path);
        // Line 2: "    return lib::helper()" -- 'h' of "helper" is at column 16.
        let result = request_definition(&main_uri, 2, 17);

        assert_eq!(result["uri"], json!(path_to_file_uri(&lib_path)));
        assert_eq!(result["range"]["start"]["line"], json!(0));
        // lib.star's own line 0: "fn helper() -> i32:" -- 'h' at column 3.
        assert_eq!(result["range"]["start"]["character"], json!(3));
    }

    /// Clicking a plain parameter reference (no matching top-level
    /// declaration exists at all) finds no definition -- `null`, not an
    /// error, matching the LSP spec's "no definition" convention.
    #[test]
    fn definition_is_null_for_a_local_parameter_reference() {
        let path = temp_star_file("definition_local.star", "fn add(a: i32, b: i32) -> i32:\n    return a + b\n");
        let uri = path_to_file_uri(&path);
        // Line 1: "    return a + b" -- 'a' is at column 11.
        let result = request_definition(&uri, 1, 11);
        assert!(result.is_null());
    }

    /// Clicking on whitespace/punctuation (not on any identifier reference
    /// at all) finds no definition.
    #[test]
    fn definition_is_null_when_not_on_an_identifier() {
        let path = temp_star_file("definition_whitespace.star", "fn main() -> i32:\n    return 0\n");
        let uri = path_to_file_uri(&path);
        let result = request_definition(&uri, 0, 0); // column 0 of "fn main..." -- on "fn", not an Ident.
        assert!(result.is_null());
    }

    /// Pins `ident_ref_at`'s documented shadowing limitation: a parameter
    /// that shares a name with a top-level function currently resolves to
    /// the top-level declaration, not the (actually-referenced) parameter,
    /// since this minimal version doesn't track local shadowing (see
    /// `ident_ref_at`'s own doc comment). This test exists so a future
    /// shadow-tracking fix has a clear, honest "this changed" signal instead
    /// of silently flipping an untested case.
    #[test]
    fn definition_known_limitation_ignores_local_shadowing_of_a_top_level_name() {
        let path = temp_star_file(
            "definition_shadow.star",
            "fn helper() -> i32:\n    return 1\n\nfn main(helper: i32) -> i32:\n    return helper\n",
        );
        let uri = path_to_file_uri(&path);
        // Line 4: "    return helper" -- 'h' of the *parameter* reference is at column 11.
        let result = request_definition(&uri, 4, 12);

        // Wrongly (but knowingly) jumps to the top-level `fn helper`'s own
        // declaration instead of `main`'s `helper` parameter.
        assert_eq!(result["range"]["start"]["line"], json!(0));
        assert_eq!(result["range"]["start"]["character"], json!(3));
    }

    /// `position_to_offset` round-trips with `offset_to_position` for a
    /// plain multi-line ASCII source.
    #[test]
    fn position_to_offset_round_trips_with_offset_to_position() {
        let src = "let a = 1\nlet b = 2\n";
        let offset = 14; // 'b's line, 5th column (0-based) -- see offset_to_position's own test.
        let (line, character) = offset_to_position(src, offset);
        assert_eq!(position_to_offset(src, line, character), offset);
    }

    /// A non-BMP character before the target column must be counted as *2*
    /// UTF-16 units, matching `offset_to_position`'s own astral-character
    /// test -- `position_to_offset` is its inverse and must agree.
    #[test]
    fn position_to_offset_counts_utf16_units_not_bytes_or_chars() {
        let src = "a\u{1F600}b"; // 'a', grinning-face emoji (4 UTF-8 bytes, 2 UTF-16 units), 'b'
        // Byte offset of 'b' is len("a\u{1F600}") = 5; its UTF-16 character is 1 (for 'a') + 2 (emoji) = 3.
        assert_eq!(position_to_offset(src, 0, 3), "a\u{1F600}".len());
    }

    /// A line/character past the end of the source clamps to `source.len()`
    /// rather than panicking -- guards against a stale position from a
    /// client whose in-memory buffer has drifted from what's on disk.
    #[test]
    fn position_to_offset_clamps_past_end_of_source() {
        let src = "fn main() -> i32:\n    return 0\n";
        assert_eq!(position_to_offset(src, 50, 0), src.len());
        assert_eq!(position_to_offset(src, 0, 500), "fn main() -> i32:".len());
    }
}

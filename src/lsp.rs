//! `star lsp` -- a minimal Language Server Protocol server over stdio.
//!
//! Deliberately small (todo.md P2 #5): no completions, no hover, no
//! go-to-definition -- just `textDocument/publishDiagnostics` driven by the
//! exact same `Driver::compile` pipeline `star check` already uses, re-run
//! whenever a document is opened or saved. That alone turns "run `star
//! check` by hand, then map the line number back to your editor" into
//! diagnostics appearing in-place, which is the cheap, high-leverage half of
//! "can someone actually use this language" (the TextMate grammar in
//! `editors/vscode` already covers the other half -- being able to *read*
//! `.star` source). Every other LSP feature is a strict, additive extension
//! of the same `handle_message` dispatch below, not a redesign.
//!
//! Deliberately re-reads the file from disk on every check rather than
//! tracking the client's in-memory buffer via `textDocument/didChange`: the
//! LSP spec's `didSave` fires after the editor has already flushed the
//! buffer to disk, so at that moment "the file on disk" and "what's open in
//! the editor" are the same bytes -- and skipping buffer-tracking entirely
//! avoids an entire class of bugs (encoding mismatches, out-of-order
//! change events) for a "minimal" first version. `didChange` is accepted
//! (so a client isn't surprised by an "unknown notification") but
//! intentionally a no-op.

use std::io::{self, BufRead, Write};
use std::path::PathBuf;

use serde_json::{json, Value};

use crate::diagnostics::{Diagnostic, Severity};
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
            .map(|(label, _)| label.as_str())
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

    fn path_to_file_uri(path: &std::path::Path) -> String {
        let s = path.display().to_string().replace('\\', "/");
        if s.as_bytes().first() == Some(&b'/') {
            format!("file://{}", s)
        } else {
            format!("file:///{}", s)
        }
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
}

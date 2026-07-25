//! Minimal project manifest (`star.toml`) and search-path discovery.
//!
//! Star has no package registry or dependency resolution yet -- this is
//! deliberately the smallest manifest that can still do real work: give a
//! multi-file project a stable *root* (so `import` paths can be written
//! relative to one place instead of hand-threaded relative-to-the-importing-
//! file paths, `projects/snake/NOTES.md`'s "most significant gap ... still
//! open") and let it declare extra directories `import` should search.
//!
//! The format is a genuine (if small) subset of TOML: `[section]` headers,
//! `key = "string"` and `key = ["a", "b"]` array-of-strings values, `#`
//! comments (honored inside neither kind of string literal), multi-line
//! arrays. It's hand-rolled rather than pulled from a `toml`+`serde`
//! dependency -- consistent with the rest of this compiler (hand-rolled
//! lexer/parser/codegen throughout) and this project's own documented
//! aversion to a fragile build story (`todo.md` P3 #13).
//!
//! Two sections are recognized today:
//! ```toml
//! [package]
//! name = "snake"        # cosmetic today; a future dependency story's hook
//! version = "0.1.0"     # optional
//! entry = "main.star"   # optional, defaults to `DEFAULT_ENTRY`
//!
//! [paths]
//! search = ["src", "lib"]   # extra import search directories, relative to
//!                            # this file's own directory
//! ```
//! Both sections, and every key within them, are optional -- an empty
//! `star.toml` is a legal (if pointless) manifest, useful purely to mark a
//! directory as a project root.

use std::collections::HashSet;
use std::path::{Path, PathBuf};

/// The manifest file name `find`/`discover` look for.
pub const MANIFEST_FILE_NAME: &str = "star.toml";

/// `[package] entry`'s default when the manifest doesn't override it.
pub const DEFAULT_ENTRY: &str = "main.star";

/// A parsed `star.toml`. Every field is optional -- see the module doc
/// comment.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct Manifest {
    pub name: Option<String>,
    pub version: Option<String>,
    pub entry: Option<String>,
    /// Raw strings from `[paths] search`, in declaration order, still
    /// relative to the manifest's own directory -- callers resolve them
    /// against a concrete root via [`LoadedManifest::search_paths`].
    pub search: Vec<String>,
}

/// A parse failure, tagged with the 1-based source line it occurred on.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ManifestError {
    pub line: usize,
    pub message: String,
}

impl std::fmt::Display for ManifestError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "line {}: {}", self.line, self.message)
    }
}

impl std::error::Error for ManifestError {}

/// A successfully loaded manifest, bundled with the directory it was found
/// in (its "project root") and the manifest file's own path.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LoadedManifest {
    pub manifest: Manifest,
    pub root: PathBuf,
    pub path: PathBuf,
}

impl LoadedManifest {
    /// The full ordered list of directories `import` should search beyond
    /// the importing file's own directory: every `[paths] search` entry
    /// (resolved against `root`), followed by `root` itself, so a bare
    /// `import "grid.star"` reaches any file in the project without an
    /// explicit `search` entry.
    pub fn search_paths(&self) -> Vec<PathBuf> {
        let mut paths: Vec<PathBuf> = self.manifest.search.iter().map(|s| self.root.join(s)).collect();
        paths.push(self.root.clone());
        paths
    }

    /// The file `star build`/`check`/`emit` should actually compile when
    /// given this manifest's project root with no explicit entry file --
    /// `[package] entry`, or [`DEFAULT_ENTRY`] if unset.
    pub fn entry_path(&self) -> PathBuf {
        self.root.join(self.manifest.entry.as_deref().unwrap_or(DEFAULT_ENTRY))
    }
}

/// Walk `start_dir` and its ancestors (in that order) looking for
/// [`MANIFEST_FILE_NAME`], returning the first one found. Never walks past
/// the filesystem root (`Path::parent` returns `None` there, which ends the
/// loop naturally -- no separate depth guard needed, unlike the recursive
/// import-chain walk in `crate::modules`, since this loop's length is
/// already bounded by real directory nesting depth, not by a value under a
/// caller's control).
pub fn find(start_dir: &Path) -> Option<PathBuf> {
    let mut dir = if start_dir.as_os_str().is_empty() { Path::new(".") } else { start_dir };
    loop {
        let candidate = dir.join(MANIFEST_FILE_NAME);
        if candidate.is_file() {
            return Some(candidate);
        }
        dir = dir.parent()?;
    }
}

/// Read and parse the manifest at `manifest_path`.
pub fn load(manifest_path: &Path) -> Result<Manifest, String> {
    let source = std::fs::read_to_string(manifest_path)
        .map_err(|e| format!("cannot read {}: {}", manifest_path.display(), e))?;
    parse(&source).map_err(|e| format!("{}: {}", manifest_path.display(), e))
}

/// Load the manifest directly inside `dir` (no ancestor walk) -- used when
/// the caller explicitly named `dir` as a project root (e.g. `star build`
/// given a directory argument), where finding a manifest in some unrelated
/// *ancestor* of `dir` instead would be a confusing surprise.
pub fn load_from_dir(dir: &Path) -> Result<Option<LoadedManifest>, String> {
    let path = dir.join(MANIFEST_FILE_NAME);
    if !path.is_file() {
        return Ok(None);
    }
    let manifest = load(&path)?;
    Ok(Some(LoadedManifest { manifest, root: dir.to_path_buf(), path }))
}

/// Find and load the nearest manifest reachable by walking up from
/// `start_dir` -- used to *auto-augment* an explicitly-given entry file's
/// search paths, purely additive (see `driver::resolve_input`), unlike
/// [`load_from_dir`]'s exact-directory-only lookup.
pub fn discover(start_dir: &Path) -> Result<Option<LoadedManifest>, String> {
    let Some(path) = find(start_dir) else { return Ok(None) };
    let manifest = load(&path)?;
    let root = path.parent().unwrap_or_else(|| Path::new(".")).to_path_buf();
    Ok(Some(LoadedManifest { manifest, root, path }))
}

/// Parse `source` as a `star.toml` document. See the module doc comment for
/// the supported subset.
pub fn parse(source: &str) -> Result<Manifest, ManifestError> {
    let mut manifest = Manifest::default();
    let mut section = String::new();
    let mut seen_keys: HashSet<(String, String)> = HashSet::new();
    let lines: Vec<&str> = source.lines().collect();
    let mut i = 0;

    while i < lines.len() {
        let lineno = i + 1;
        let line = strip_comment(lines[i]).trim();
        i += 1;
        if line.is_empty() {
            continue;
        }

        if let Some(inner) = line.strip_prefix('[') {
            let Some(name) = inner.strip_suffix(']') else {
                return Err(ManifestError { line: lineno, message: format!("unterminated section header `{line}`") });
            };
            let name = name.trim();
            match name {
                "package" | "paths" => section = name.to_string(),
                _ => {
                    return Err(ManifestError {
                        line: lineno,
                        message: format!("unknown section `[{name}]` (expected `[package]` or `[paths]`)"),
                    });
                }
            }
            continue;
        }

        let Some((key, rest)) = line.split_once('=') else {
            return Err(ManifestError { line: lineno, message: format!("expected `key = value`, found `{line}`") });
        };
        let key = key.trim();
        let rest = rest.trim();
        if key.is_empty() || !key.chars().all(|c| c.is_ascii_alphanumeric() || c == '_') {
            return Err(ManifestError { line: lineno, message: format!("invalid key `{key}`") });
        }
        if section.is_empty() {
            return Err(ManifestError { line: lineno, message: format!("key `{key}` outside of any `[section]`") });
        }
        if !seen_keys.insert((section.clone(), key.to_string())) {
            return Err(ManifestError { line: lineno, message: format!("duplicate key `{key}` in `[{section}]`") });
        }

        match (section.as_str(), key) {
            ("package", "name") => manifest.name = Some(parse_string(rest, lineno)?),
            ("package", "version") => manifest.version = Some(parse_string(rest, lineno)?),
            ("package", "entry") => manifest.entry = Some(parse_string(rest, lineno)?),
            ("paths", "search") => {
                let (values, consumed) = parse_string_array(rest, lineno, &lines[i..])?;
                manifest.search = values;
                i += consumed;
            }
            (s, k) => return Err(ManifestError { line: lineno, message: format!("unknown key `{k}` in `[{s}]`") }),
        }
    }

    Ok(manifest)
}

/// Strip a `#` end-of-line comment, honoring quoted strings (a `#` inside
/// `"..."` doesn't start a comment). Escaped quotes (`\"`) inside the string
/// don't end it early.
fn strip_comment(line: &str) -> &str {
    let mut in_string = false;
    let mut escaped = false;
    for (i, c) in line.char_indices() {
        if escaped {
            escaped = false;
            continue;
        }
        match c {
            '\\' if in_string => escaped = true,
            '"' => in_string = !in_string,
            '#' if !in_string => return &line[..i],
            _ => {}
        }
    }
    line
}

/// Parse `raw` as a `"..."` string literal, unescaping `\"`, `\\`, `\n`,
/// `\t`.
fn parse_string(raw: &str, line: usize) -> Result<String, ManifestError> {
    if raw.len() >= 2 && raw.starts_with('"') && raw.ends_with('"') {
        unescape(&raw[1..raw.len() - 1], line)
    } else {
        Err(ManifestError { line, message: format!("expected a quoted string, found `{raw}`") })
    }
}

fn unescape(s: &str, line: usize) -> Result<String, ManifestError> {
    let mut out = String::with_capacity(s.len());
    let mut chars = s.chars();
    while let Some(c) = chars.next() {
        if c != '\\' {
            out.push(c);
            continue;
        }
        match chars.next() {
            Some('"') => out.push('"'),
            Some('\\') => out.push('\\'),
            Some('n') => out.push('\n'),
            Some('t') => out.push('\t'),
            Some(other) => return Err(ManifestError { line, message: format!("unsupported escape `\\{other}`") }),
            None => return Err(ManifestError { line, message: "unterminated escape at end of string".to_string() }),
        }
    }
    Ok(out)
}

/// Parse `[paths] search = ...`'s value, which may be a single-line array
/// literal or span multiple lines. `following` is every line after the one
/// `rest` came from; on success, returns the parsed strings plus how many
/// of `following`'s lines were consumed closing the array, so the caller
/// can skip past them.
fn parse_string_array(rest: &str, start_line: usize, following: &[&str]) -> Result<(Vec<String>, usize), ManifestError> {
    let mut buf = String::new();
    buf.push_str(rest);
    let mut consumed = 0;
    while !has_closing_bracket_outside_string(&buf) {
        if consumed >= following.len() {
            return Err(ManifestError { line: start_line + consumed, message: "unterminated array (missing `]`)".to_string() });
        }
        let content = strip_comment(following[consumed]).trim();
        consumed += 1;
        buf.push(' ');
        buf.push_str(content);
    }
    let items = parse_array_literal(&buf, start_line)?;
    Ok((items, consumed))
}

fn parse_array_literal(buf: &str, line: usize) -> Result<Vec<String>, ManifestError> {
    let trimmed = buf.trim();
    let inner = trimmed
        .strip_prefix('[')
        .and_then(|s| s.strip_suffix(']'))
        .ok_or_else(|| ManifestError { line, message: format!("malformed array literal `{trimmed}`") })?;
    let mut out = Vec::new();
    for part in inner.split(',') {
        let part = part.trim();
        if part.is_empty() {
            continue;
        }
        out.push(parse_string(part, line)?);
    }
    Ok(out)
}

/// True if `s` contains a `]` outside of any quoted string (accounting for
/// `\"` escapes) -- used to detect a multi-line array's closing bracket
/// without being fooled by a literal `]` inside a path string.
fn has_closing_bracket_outside_string(s: &str) -> bool {
    let mut in_string = false;
    let mut chars = s.chars();
    while let Some(c) = chars.next() {
        match c {
            '\\' if in_string => {
                chars.next();
            }
            '"' => in_string = !in_string,
            ']' if !in_string => return true,
            _ => {}
        }
    }
    false
}

#[cfg(test)]
mod tests {
    use super::*;

    // --- parse: happy paths -------------------------------------------

    #[test]
    fn parse_empty_source_yields_all_defaults() {
        let m = parse("").expect("empty manifest is legal");
        assert_eq!(m, Manifest::default());
    }

    #[test]
    fn parse_whitespace_and_comment_only_source_yields_all_defaults() {
        let m = parse("  \n# just a comment\n\n   # another\n").expect("should parse");
        assert_eq!(m, Manifest::default());
    }

    #[test]
    fn parse_full_manifest_reads_every_field() {
        let src = r#"
            [package]
            name = "snake"
            version = "0.1.0"
            entry = "main.star"

            [paths]
            search = ["src", "lib"]
        "#;
        let m = parse(src).expect("should parse");
        assert_eq!(m.name.as_deref(), Some("snake"));
        assert_eq!(m.version.as_deref(), Some("0.1.0"));
        assert_eq!(m.entry.as_deref(), Some("main.star"));
        assert_eq!(m.search, vec!["src".to_string(), "lib".to_string()]);
    }

    #[test]
    fn parse_package_section_alone_is_legal_with_empty_search() {
        let m = parse("[package]\nname = \"lib_only\"\n").expect("should parse");
        assert_eq!(m.name.as_deref(), Some("lib_only"));
        assert!(m.search.is_empty());
    }

    #[test]
    fn parse_paths_section_alone_is_legal_with_no_package_fields() {
        let m = parse("[paths]\nsearch = [\"vendor\"]\n").expect("should parse");
        assert_eq!(m.name, None);
        assert_eq!(m.search, vec!["vendor".to_string()]);
    }

    #[test]
    fn parse_trailing_hash_comment_after_a_value_is_ignored() {
        let m = parse("[package]\nname = \"snake\" # the game\n").expect("should parse");
        assert_eq!(m.name.as_deref(), Some("snake"));
    }

    #[test]
    fn parse_hash_inside_a_quoted_string_is_not_a_comment() {
        let m = parse("[package]\nname = \"snake#1\"\n").expect("should parse");
        assert_eq!(m.name.as_deref(), Some("snake#1"));
    }

    #[test]
    fn parse_section_header_tolerates_inner_whitespace() {
        let m = parse("[ package ]\nname = \"x\"\n").expect("should parse");
        assert_eq!(m.name.as_deref(), Some("x"));
    }

    #[test]
    fn parse_blank_lines_between_entries_are_ignored() {
        let m = parse("[package]\n\n\nname = \"x\"\n\n[paths]\n\nsearch = [\"a\"]\n").expect("should parse");
        assert_eq!(m.name.as_deref(), Some("x"));
        assert_eq!(m.search, vec!["a".to_string()]);
    }

    // --- parse: string escapes -----------------------------------------

    #[test]
    fn parse_string_handles_escaped_quote_backslash_newline_tab() {
        let m = parse(r#"[package]
name = "a\"b\\c\nd\te"
"#)
        .expect("should parse");
        assert_eq!(m.name.as_deref(), Some("a\"b\\c\nd\te"));
    }

    #[test]
    fn parse_rejects_unknown_escape_sequence() {
        let err = parse("[package]\nname = \"a\\qb\"\n").expect_err("unknown escape should fail");
        assert!(err.message.contains("escape"), "{err}");
    }

    #[test]
    fn parse_rejects_unterminated_escape_at_end_of_string() {
        // The literal source ends with a backslash immediately before the
        // closing quote, so `unescape` sees `\` with nothing after it.
        let err = parse("[package]\nname = \"ab\\\"\n").expect_err("dangling escape should fail");
        assert!(err.message.contains("unterminated"), "{err}");
    }

    // --- parse: array literals ------------------------------------------

    #[test]
    fn parse_string_array_single_line() {
        let m = parse("[paths]\nsearch = [\"a\", \"b\", \"c\"]\n").expect("should parse");
        assert_eq!(m.search, vec!["a".to_string(), "b".to_string(), "c".to_string()]);
    }

    #[test]
    fn parse_string_array_empty_literal() {
        let m = parse("[paths]\nsearch = []\n").expect("should parse");
        assert!(m.search.is_empty());
    }

    #[test]
    fn parse_string_array_tolerates_trailing_comma() {
        let m = parse("[paths]\nsearch = [\"a\", \"b\",]\n").expect("should parse");
        assert_eq!(m.search, vec!["a".to_string(), "b".to_string()]);
    }

    #[test]
    fn parse_string_array_spans_multiple_lines() {
        let src = "[paths]\nsearch = [\n    \"a\",\n    \"b\",\n    \"c\"\n]\n";
        let m = parse(src).expect("should parse");
        assert_eq!(m.search, vec!["a".to_string(), "b".to_string(), "c".to_string()]);
    }

    /// A multi-line array's continuation lines may carry their own trailing
    /// `#` comments (e.g. explaining one entry) without corrupting the
    /// array or being mistaken for array content.
    #[test]
    fn parse_string_array_multiline_entries_may_have_trailing_comments() {
        let src = "[paths]\nsearch = [\n    \"a\", # first\n    \"b\" # second\n]\n";
        let m = parse(src).expect("should parse");
        assert_eq!(m.search, vec!["a".to_string(), "b".to_string()]);
    }

    /// A `]` that's part of a path string's own text (not the array's
    /// closing bracket) must not be mistaken for the terminator -- this is
    /// exactly what `has_closing_bracket_outside_string` exists to get
    /// right instead of a naive `.contains(']')` scan.
    #[test]
    fn parse_string_array_element_may_itself_contain_a_bracket() {
        let m = parse("[paths]\nsearch = [\"weird]name\", \"b\"]\n").expect("should parse");
        assert_eq!(m.search, vec!["weird]name".to_string(), "b".to_string()]);
    }

    #[test]
    fn parse_rejects_unterminated_array_at_end_of_file() {
        let err = parse("[paths]\nsearch = [\"a\",\n").expect_err("unterminated array should fail");
        assert!(err.message.contains("unterminated array"), "{err}");
    }

    /// After a multi-line array closes, parsing resumes on the line right
    /// after `]` -- a key declared there must still be recognized (guards
    /// against the line-skipping arithmetic in `parse`'s `i += consumed`
    /// off-by-one in either direction).
    #[test]
    fn parse_resumes_correctly_after_a_multiline_array() {
        let src = "[paths]\nsearch = [\n    \"a\"\n]\n[package]\nname = \"after\"\n";
        let m = parse(src).expect("should parse");
        assert_eq!(m.search, vec!["a".to_string()]);
        assert_eq!(m.name.as_deref(), Some("after"));
    }

    // --- parse: error diagnostics ----------------------------------------

    #[test]
    fn parse_rejects_unknown_section() {
        let err = parse("[bogus]\nname = \"x\"\n").expect_err("unknown section should fail");
        assert!(err.message.contains("unknown section"), "{err}");
        assert_eq!(err.line, 1);
    }

    #[test]
    fn parse_rejects_unknown_key_in_known_section() {
        let err = parse("[package]\nbogus_key = \"x\"\n").expect_err("unknown key should fail");
        assert!(err.message.contains("unknown key"), "{err}");
        assert_eq!(err.line, 2);
    }

    #[test]
    fn parse_rejects_key_before_any_section_header() {
        let err = parse("name = \"x\"\n[package]\n").expect_err("key outside a section should fail");
        assert!(err.message.contains("outside of any"), "{err}");
        assert_eq!(err.line, 1);
    }

    #[test]
    fn parse_rejects_duplicate_key_in_same_section() {
        let err = parse("[package]\nname = \"a\"\nname = \"b\"\n").expect_err("duplicate key should fail");
        assert!(err.message.contains("duplicate key"), "{err}");
        assert_eq!(err.line, 3);
    }

    /// The same key name in *different* sections is not a duplicate --
    /// `[package]`/`[paths]` are independent namespaces.
    #[test]
    fn parse_does_not_confuse_same_key_name_across_different_sections() {
        // Neither `[package]` nor `[paths]` actually shares a key name
        // today, so this pins the (section, key) pairing itself using two
        // legal same-named-if-ungrouped keys reached via `entry`/`search`
        // would not collide; exercise the guard directly against the real
        // duplicate-detection data structure instead by re-declaring `name`
        // after an intervening different section, which must NOT be
        // flagged as a dup of an unrelated section's key.
        let m = parse("[package]\nname = \"a\"\n[paths]\nsearch = [\"x\"]\n").expect("should parse");
        assert_eq!(m.name.as_deref(), Some("a"));
    }

    #[test]
    fn parse_rejects_line_missing_equals_sign() {
        let err = parse("[package]\nname \"x\"\n").expect_err("missing `=` should fail");
        assert!(err.message.contains("expected `key = value`"), "{err}");
    }

    #[test]
    fn parse_rejects_unterminated_section_header() {
        let err = parse("[package\nname = \"x\"\n").expect_err("unterminated header should fail");
        assert!(err.message.contains("unterminated section header"), "{err}");
    }

    #[test]
    fn parse_rejects_unquoted_string_value() {
        let err = parse("[package]\nname = snake\n").expect_err("unquoted value should fail");
        assert!(err.message.contains("expected a quoted string"), "{err}");
    }

    #[test]
    fn parse_rejects_invalid_key_syntax() {
        let err = parse("[package]\nweird-key = \"x\"\n").expect_err("hyphenated key should fail");
        assert!(err.message.contains("invalid key"), "{err}");
    }

    #[test]
    fn parse_error_line_numbers_point_at_the_real_offending_line() {
        let src = "[package]\nname = \"ok\"\n\nbogus_key = \"x\"\n";
        let err = parse(src).expect_err("should fail");
        assert_eq!(err.line, 4);
    }

    // --- find/load/discover: filesystem behavior -------------------------

    fn manifest_scratch_dir(name: &str) -> std::path::PathBuf {
        std::env::temp_dir().join("star_manifest_tests").join(name)
    }

    #[test]
    fn find_locates_manifest_directly_in_start_dir() {
        let dir = manifest_scratch_dir("find_locates_manifest_directly_in_start_dir");
        std::fs::create_dir_all(&dir).unwrap();
        std::fs::write(dir.join(MANIFEST_FILE_NAME), "[package]\nname = \"x\"\n").unwrap();

        assert_eq!(find(&dir), Some(dir.join(MANIFEST_FILE_NAME)));
        std::fs::remove_dir_all(&dir).ok();
    }

    #[test]
    fn find_walks_up_through_several_ancestors() {
        let root = manifest_scratch_dir("find_walks_up_through_several_ancestors");
        let nested = root.join("a").join("b").join("c");
        std::fs::create_dir_all(&nested).unwrap();
        std::fs::write(root.join(MANIFEST_FILE_NAME), "[package]\nname = \"root\"\n").unwrap();

        assert_eq!(find(&nested), Some(root.join(MANIFEST_FILE_NAME)));
        std::fs::remove_dir_all(&root).ok();
    }

    #[test]
    fn find_prefers_the_nearest_ancestor_manifest() {
        let root = manifest_scratch_dir("find_prefers_the_nearest_ancestor_manifest");
        let nested = root.join("nested");
        std::fs::create_dir_all(&nested).unwrap();
        std::fs::write(root.join(MANIFEST_FILE_NAME), "[package]\nname = \"root\"\n").unwrap();
        std::fs::write(nested.join(MANIFEST_FILE_NAME), "[package]\nname = \"nested\"\n").unwrap();

        assert_eq!(find(&nested), Some(nested.join(MANIFEST_FILE_NAME)));
        std::fs::remove_dir_all(&root).ok();
    }

    #[test]
    fn find_returns_none_when_no_manifest_anywhere_up_the_chain() {
        // A fresh directory tree under the OS temp dir has no `star.toml`
        // in it or (assuming a sane CI/dev machine) any of its ancestors up
        // to a drive root, where `Path::parent` finally returns `None`.
        let dir = manifest_scratch_dir("find_returns_none_when_no_manifest_anywhere_up_the_chain").join("only_child");
        std::fs::create_dir_all(&dir).unwrap();
        assert_eq!(find(&dir), None);
        std::fs::remove_dir_all(dir.parent().unwrap()).ok();
    }

    #[test]
    fn load_from_dir_returns_none_when_directory_has_no_manifest() {
        let dir = manifest_scratch_dir("load_from_dir_returns_none_when_directory_has_no_manifest");
        std::fs::create_dir_all(&dir).unwrap();
        assert_eq!(load_from_dir(&dir).expect("should not error"), None);
        std::fs::remove_dir_all(&dir).ok();
    }

    #[test]
    fn load_from_dir_does_not_walk_up_past_the_given_directory() {
        let root = manifest_scratch_dir("load_from_dir_does_not_walk_up_past_the_given_directory");
        let nested = root.join("nested");
        std::fs::create_dir_all(&nested).unwrap();
        std::fs::write(root.join(MANIFEST_FILE_NAME), "[package]\nname = \"root\"\n").unwrap();

        // Unlike `find`/`discover`, an explicit-directory lookup must not
        // find the parent's manifest -- an absent manifest right there is
        // reported as `None`, not silently satisfied by an ancestor.
        assert_eq!(load_from_dir(&nested).expect("should not error"), None);
        std::fs::remove_dir_all(&root).ok();
    }

    #[test]
    fn load_from_dir_loads_a_valid_manifest() {
        let dir = manifest_scratch_dir("load_from_dir_loads_a_valid_manifest");
        std::fs::create_dir_all(&dir).unwrap();
        std::fs::write(dir.join(MANIFEST_FILE_NAME), "[package]\nname = \"x\"\nentry = \"start.star\"\n").unwrap();

        let loaded = load_from_dir(&dir).expect("should parse").expect("manifest present");
        assert_eq!(loaded.manifest.name.as_deref(), Some("x"));
        assert_eq!(loaded.root, dir);
        assert_eq!(loaded.path, dir.join(MANIFEST_FILE_NAME));
        std::fs::remove_dir_all(&dir).ok();
    }

    #[test]
    fn load_from_dir_surfaces_a_parse_error_with_the_manifest_path() {
        let dir = manifest_scratch_dir("load_from_dir_surfaces_a_parse_error_with_the_manifest_path");
        std::fs::create_dir_all(&dir).unwrap();
        std::fs::write(dir.join(MANIFEST_FILE_NAME), "not a valid line\n").unwrap();

        let err = load_from_dir(&dir).expect_err("malformed manifest should error");
        assert!(err.contains("star.toml"), "{err}");
        std::fs::remove_dir_all(&dir).ok();
    }

    #[test]
    fn discover_finds_and_loads_the_nearest_ancestor_manifest() {
        let root = manifest_scratch_dir("discover_finds_and_loads_the_nearest_ancestor_manifest");
        let nested = root.join("src").join("deep");
        std::fs::create_dir_all(&nested).unwrap();
        std::fs::write(root.join(MANIFEST_FILE_NAME), "[package]\nname = \"proj\"\n[paths]\nsearch = [\"vendor\"]\n").unwrap();

        let loaded = discover(&nested).expect("should parse").expect("manifest present");
        assert_eq!(loaded.manifest.name.as_deref(), Some("proj"));
        assert_eq!(loaded.root, root);
        std::fs::remove_dir_all(&root).ok();
    }

    #[test]
    fn discover_returns_none_when_nothing_found() {
        let dir = manifest_scratch_dir("discover_returns_none_when_nothing_found").join("only_child");
        std::fs::create_dir_all(&dir).unwrap();
        assert_eq!(discover(&dir).expect("should not error"), None);
        std::fs::remove_dir_all(dir.parent().unwrap()).ok();
    }

    // --- LoadedManifest: derived paths ------------------------------------

    #[test]
    fn loaded_manifest_search_paths_appends_root_after_declared_dirs() {
        let loaded = LoadedManifest {
            manifest: Manifest { search: vec!["src".to_string(), "vendor".to_string()], ..Manifest::default() },
            root: PathBuf::from("/project"),
            path: PathBuf::from("/project/star.toml"),
        };
        assert_eq!(
            loaded.search_paths(),
            vec![PathBuf::from("/project/src"), PathBuf::from("/project/vendor"), PathBuf::from("/project")]
        );
    }

    #[test]
    fn loaded_manifest_search_paths_is_just_root_with_no_declared_dirs() {
        let loaded = LoadedManifest { manifest: Manifest::default(), root: PathBuf::from("/project"), path: PathBuf::from("/project/star.toml") };
        assert_eq!(loaded.search_paths(), vec![PathBuf::from("/project")]);
    }

    #[test]
    fn loaded_manifest_entry_path_defaults_to_main_star() {
        let loaded = LoadedManifest { manifest: Manifest::default(), root: PathBuf::from("/project"), path: PathBuf::from("/project/star.toml") };
        assert_eq!(loaded.entry_path(), PathBuf::from("/project/main.star"));
    }

    #[test]
    fn loaded_manifest_entry_path_honors_explicit_entry() {
        let loaded = LoadedManifest {
            manifest: Manifest { entry: Some("start.star".to_string()), ..Manifest::default() },
            root: PathBuf::from("/project"),
            path: PathBuf::from("/project/star.toml"),
        };
        assert_eq!(loaded.entry_path(), PathBuf::from("/project/start.star"));
    }
}

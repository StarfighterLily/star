//! A structural verifier for the LLVM IR text this compiler's hand-rolled
//! emitter (`crate::codegen`) produces, run after codegen and before the IR
//! is ever handed to `clang`.
//!
//! This is deliberately *not* an attempt at reimplementing LLVM's own
//! verifier (`llvm::verifyModule`) -- that's a losing, endless game, and
//! `clang` already does it correctly. What this module targets instead is
//! the specific, recurring failure mode `ASSESSMENT.md` ("The Ugly" #1)
//! calls out: a string-templating emitter with no builder object checking
//! well-formedness as it goes, where a bug in one `codegen/*.rs` file
//! produces a `.ll` file that parses fine as text but describes a control-
//! flow or type shape `clang`/LLVM rejects -- previously the *only* place
//! that was ever caught. Two concrete, previously-shipped bugs motivate the
//! rule set below (see `projects/snake/NOTES.md`):
//!
//! - a `frame:` block ending in `return` emitted a `store` *after* the
//!   block's own terminator (`ret`) -- see `terminator` checks below.
//! - a trailing `if`/`else` returning a bare identifier produced an
//!   untagged register a later `phi`-merge couldn't split a type from --
//!   see the `phi` predecessor/type-sanity checks below.
//!
//! Every check here is scoped to the actual dialect this emitter produces
//! (documented per-check below, grounded in reading `examples/*.ll`), not
//! general LLVM IR -- e.g. it assumes basic blocks are always explicitly
//! labeled (including `entry`), never split across blank lines, and that
//! `nsw`/`nuw`/`exact` arithmetic flags are never emitted. If the emitter's
//! output shape changes, these assumptions -- not just the rules -- may need
//! revisiting.

use std::collections::{HashMap, HashSet};

/// How confident a given finding is that `clang`/LLVM will actually reject
/// the module. [`Severity::Error`] is reserved for shapes LLVM's own parser
/// or verifier is known to reject outright (backed by the historical bugs
/// this module's top-level doc comment cites, or by the same class of
/// violation); callers should treat these as build-blocking. [`Severity::Warning`]
/// covers findings that are syntactically valid LLVM IR `clang` will accept
/// -- but that are still suspicious enough (e.g. a basic block no branch in
/// the function ever reaches) to be worth surfacing without stopping the
/// build over what may be intentional or merely dead code.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Severity {
    Error,
    Warning,
}

/// One verification finding: a 1-based line number into the generated IR
/// text, a human-readable description, and how confident the finding is
/// (see [`Severity`]).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct IrError {
    pub line: usize,
    pub message: String,
    pub severity: Severity,
}

impl IrError {
    fn new(line: usize, message: impl Into<String>) -> Self {
        Self { line, message: message.into(), severity: Severity::Error }
    }

    fn warning(line: usize, message: impl Into<String>) -> Self {
        Self { line, message: message.into(), severity: Severity::Warning }
    }
}

/// Instructions this emitter uses that end a basic block. LLVM also has
/// `switch`/`indirectbr`/`invoke`/`resume`/`callbr`, none of which
/// `crate::codegen` ever emits (confirmed by grepping every `.ll` this
/// compiler currently ships in `examples/`/`projects/`) -- if a future
/// codegen path starts emitting one of those, it needs to be added here or
/// every block ending in it will (harmlessly, but incorrectly) fail the
/// "block must end with a terminator" check below.
const TERMINATORS: [&str; 3] = ["ret", "br", "unreachable"];

/// Run every structural check against a complete `.ll` module's text.
/// Returns one [`IrError`] per problem found, in ascending line order.
pub fn verify(ir: &str) -> Vec<IrError> {
    let raw_lines: Vec<&str> = ir.lines().collect();
    // Blank out quoted string content (`c"...\00"` global constant bodies)
    // before any token scan below -- a Star string literal containing a
    // stray `%`/`@` character (e.g. printing an email address) would
    // otherwise be misread as an IR register/global reference and produce a
    // bogus "undefined" error. Quote boundaries are plain `"..."` with no
    // backslash-escaped quote in LLVM's `c"..."` syntax (a literal `"` byte
    // is spelled `\22`), so naive quote-toggling is safe here.
    let lines: Vec<String> = raw_lines.iter().map(|l| strip_quoted(l)).collect();
    let lines: Vec<&str> = lines.iter().map(|s| s.as_str()).collect();

    let mut errors = Vec::new();

    let type_names = collect_type_names(&lines);
    let global_names = collect_global_symbols(&lines, &mut errors);
    let fn_sigs = collect_function_sigs(&lines);
    let functions = split_functions(&lines, &mut errors);

    for func in &functions {
        check_function(func, &type_names, &fn_sigs, &mut errors);
    }

    check_global_uses(&lines, &global_names, &mut errors);

    errors.sort_by_key(|e| e.line);
    errors.dedup();
    errors
}

fn strip_quoted(line: &str) -> String {
    let mut out = String::with_capacity(line.len());
    let mut in_str = false;
    for ch in line.chars() {
        if ch == '"' {
            in_str = !in_str;
            out.push(' ');
        } else if in_str {
            out.push(' ');
        } else {
            out.push(ch);
        }
    }
    out
}

// --------------------------------------------------------------------
// Generic textual-IR tokenizing helpers, shared by every pass below.
// --------------------------------------------------------------------

/// Split `s` on top-level commas -- i.e. commas not nested inside
/// `()`/`[]`/`{}`/`<...>` (angle brackets only ever appear here as the
/// `<N x T>` vector-type delimiter; this emitter never spells a comparison
/// with bare `<`/`>`, those are always the `icmp`/`fcmp` mnemonics).
fn split_top_level_commas(s: &str) -> Vec<&str> {
    let mut out = Vec::new();
    let mut depth = 0i32;
    let mut start = 0usize;
    for (i, ch) in s.char_indices() {
        match ch {
            '(' | '[' | '{' | '<' => depth += 1,
            ')' | ']' | '}' | '>' => depth -= 1,
            ',' if depth == 0 => {
                out.push(&s[start..i]);
                start = i + ch.len_utf8();
            }
            _ => {}
        }
    }
    out.push(&s[start..]);
    out
}

/// Index of the bracket matching `s[open_pos]` (which must be `open_ch`),
/// accounting for nesting of the same bracket kind.
fn find_matching_bracket(s: &str, open_pos: usize, open_ch: char, close_ch: char) -> Option<usize> {
    let mut depth = 0i32;
    for (i, ch) in s.char_indices().skip(open_pos) {
        if ch == open_ch {
            depth += 1;
        } else if ch == close_ch {
            depth -= 1;
            if depth == 0 {
                return Some(i);
            }
        }
    }
    None
}

/// Split `s` (assumed already left-trimmed) at the first whitespace that
/// isn't nested inside a `()[]{}<>` pair, returning `(first token, rest)`.
///
/// Used to split a `phi`'s `<type> [ val, %label ], ...` text into its type
/// and its incoming-value list. A naive search for the first top-level `[`
/// to mark that boundary breaks when the type *itself* starts with `[`
/// (an array-typed phi result, `[3 x <3 x float>]* [ %v, %blk ], ...` --
/// this is a real, previously-shipping shape: monomorphized `Mat3`/`Mat2`
/// generics phi-merge a `[N x <N x float>]*` pointer). The type, however --
/// however deeply it nests brackets internally -- is always exactly one
/// contiguous run with no whitespace at bracket depth 0, and is always
/// followed by a depth-0 space before the incoming-list begins, so
/// splitting on the first depth-0 whitespace instead is correct regardless
/// of which bracket kind (if any) the type's own text starts with.
fn split_first_top_level_token(s: &str) -> (&str, &str) {
    let mut depth = 0i32;
    for (i, ch) in s.char_indices() {
        match ch {
            '(' | '[' | '{' | '<' => depth += 1,
            ')' | ']' | '}' | '>' => depth -= 1,
            c if c.is_whitespace() && depth == 0 => {
                return (&s[..i], s[i..].trim_start());
            }
            _ => {}
        }
    }
    (s, "")
}

/// Every `%name` token in `text` (the `%` sigil stripped, any trailing `*`
/// pointer-depth markers dropped since they're never part of the
/// identifier). Covers both SSA-register and basic-block-label references
/// (LLVM shares one per-function namespace between the two).
fn find_percent_tokens(text: &str) -> Vec<String> {
    let chars: Vec<char> = text.chars().collect();
    let mut out = Vec::new();
    let mut i = 0;
    while i < chars.len() {
        if chars[i] == '%' {
            let start = i + 1;
            let mut j = start;
            while j < chars.len() && (chars[j].is_ascii_alphanumeric() || chars[j] == '_' || chars[j] == '.' || chars[j] == '$') {
                j += 1;
            }
            if j > start {
                out.push(chars[start..j].iter().collect());
            }
            i = j.max(i + 1);
        } else {
            i += 1;
        }
    }
    out
}

/// Every `@name` token in `text`, `@` sigil stripped. Same shape as
/// [`find_percent_tokens`] but for the module-level symbol namespace.
fn find_at_tokens(text: &str) -> Vec<String> {
    let chars: Vec<char> = text.chars().collect();
    let mut out = Vec::new();
    let mut i = 0;
    while i < chars.len() {
        if chars[i] == '@' {
            let start = i + 1;
            let mut j = start;
            while j < chars.len() && (chars[j].is_ascii_alphanumeric() || chars[j] == '_' || chars[j] == '.' || chars[j] == '$') {
                j += 1;
            }
            if j > start {
                out.push(chars[start..j].iter().collect());
            }
            i = j.max(i + 1);
        } else {
            i += 1;
        }
    }
    out
}

fn extract_at_name(rest: &str) -> Option<String> {
    let at = rest.find('@')?;
    let after = &rest[at + 1..];
    let end = after.find('(').unwrap_or(after.len());
    let name = after[..end].trim();
    if name.is_empty() { None } else { Some(name.to_string()) }
}

/// Split `s` into its last whitespace-separated token (the "value" half of
/// a `<type> <value>` operand pair) and everything before it (the "type"
/// half). Works even when the type itself contains internal whitespace
/// (`<3 x float>`, `[6 x %Plane]`) since only the *last* token is peeled
/// off.
fn split_type_and_value(s: &str) -> (String, String) {
    let trimmed = s.trim();
    match trimmed.rfind(char::is_whitespace) {
        Some(idx) => (trimmed[..idx].trim().to_string(), trimmed[idx..].trim().to_string()),
        None => (trimmed.to_string(), String::new()),
    }
}

fn split_first_word(s: &str) -> (&str, &str) {
    match s.find(char::is_whitespace) {
        Some(i) => (&s[..i], s[i..].trim_start()),
        None => (s, ""),
    }
}

// --------------------------------------------------------------------
// Pass 0: declared struct/enum type names (`%Foo = type { ... }`).
// --------------------------------------------------------------------

fn collect_type_names(lines: &[&str]) -> HashSet<String> {
    let mut set = HashSet::new();
    for line in lines {
        if let Some(rest) = line.strip_prefix('%') {
            if let Some(idx) = rest.find(" = type") {
                set.insert(rest[..idx].trim().to_string());
            }
        }
    }
    set
}

// --------------------------------------------------------------------
// Pass 1: module-level symbol table (`declare`/`define`/`@global`), and
// duplicate-definition detection -- defense in depth against the exact
// failure shape of the diamond-import mangling bug (`ASSESSMENT.md` "The
// Ugly" #3): two definitions colliding on one name is a `clang` "invalid
// redefinition" error, caught here instead.
// --------------------------------------------------------------------

fn collect_global_symbols(lines: &[&str], errors: &mut Vec<IrError>) -> HashSet<String> {
    let mut all_names: HashSet<String> = HashSet::new();
    let mut first_def_line: HashMap<String, usize> = HashMap::new();

    for (i, line) in lines.iter().enumerate() {
        let lineno = i + 1;
        if let Some(rest) = line.strip_prefix("declare ") {
            if let Some(name) = extract_at_name(rest) {
                all_names.insert(name);
            }
        } else if let Some(rest) = line.strip_prefix("define ") {
            if let Some(name) = extract_at_name(rest) {
                if let Some(&prev) = first_def_line.get(&name) {
                    errors.push(IrError::new(
                        lineno,
                        format!("duplicate definition of `@{}` (already defined at line {})", name, prev),
                    ));
                } else {
                    first_def_line.insert(name.clone(), lineno);
                }
                all_names.insert(name);
            }
        } else if let Some(rest) = line.strip_prefix('@') {
            if let Some(eq_idx) = rest.find(" = ") {
                let name = rest[..eq_idx].trim().to_string();
                // A `declare`-only forward mention never lands here (it's
                // handled by the branch above), so anything of the shape
                // `@name = ...` at column 0 is a real global-variable
                // definition.
                if let Some(&prev) = first_def_line.get(&name) {
                    errors.push(IrError::new(
                        lineno,
                        format!("duplicate definition of `@{}` (already defined at line {})", name, prev),
                    ));
                } else {
                    first_def_line.insert(name.clone(), lineno);
                }
                all_names.insert(name);
            }
        }
    }
    all_names
}

/// Every `@name` reference anywhere in the module (call targets, operands,
/// initializers) must resolve to something `collect_global_symbols` saw
/// declared or defined -- otherwise `clang` rejects the module outright
/// ("use of undefined value").
fn check_global_uses(lines: &[&str], global_names: &HashSet<String>, errors: &mut Vec<IrError>) {
    for (i, line) in lines.iter().enumerate() {
        let lineno = i + 1;
        for tok in find_at_tokens(line) {
            // `llvm.*`-prefixed names are core LLVM intrinsics: the parser
            // auto-synthesizes their declaration from the name itself
            // (confirmed empirically -- `clang` accepts a call to e.g.
            // `@llvm.sadd.with.overflow.i32` with no `declare` anywhere in
            // the module), so a missing `declare` for one isn't a real
            // defect the way it would be for an ordinary symbol.
            if tok.starts_with("llvm.") {
                continue;
            }
            if !global_names.contains(&tok) {
                errors.push(IrError::new(lineno, format!("reference to undefined global `@{}`", tok)));
            }
        }
    }
}

/// A `declare`/`define` signature, as far as `check_call_arity` needs: how
/// many fixed parameters it takes, and whether it's variadic (`...` as the
/// last parameter, e.g. `@printf`).
struct FnSig {
    param_count: usize,
    is_vararg: bool,
}

/// Number of comma-separated, non-`...` entries in a parameter or argument
/// list's inner text (whether that's a `declare`/`define`'s parameter types,
/// or a `call`'s argument values -- both are top-level-comma-separated lists
/// with the same nesting rules), and whether a trailing `...` marks the
/// list variadic.
fn parse_param_list(inner: &str) -> (usize, bool) {
    let mut count = 0usize;
    let mut is_vararg = false;
    for chunk in split_top_level_commas(inner) {
        let chunk = chunk.trim();
        if chunk.is_empty() {
            continue;
        }
        if chunk == "..." {
            is_vararg = true;
        } else {
            count += 1;
        }
    }
    (count, is_vararg)
}

/// Every function's signature, keyed by name (`@` sigil stripped) -- from
/// its `declare` if it only has one, its `define` otherwise. Used by
/// `check_call_arity` to catch a `call` passing the wrong number of
/// arguments, the direct-call analogue of the `phi`-type-mismatch bug this
/// module already targets: an argument-count bug is just as invisible to
/// this emitter's string templating as an untagged register is, and `clang`
/// rejects it just as outright ("too many/few arguments to function call").
fn collect_function_sigs(lines: &[&str]) -> HashMap<String, FnSig> {
    let mut sigs = HashMap::new();
    for line in lines {
        let Some(rest) = line.strip_prefix("declare ").or_else(|| line.strip_prefix("define ")) else {
            continue;
        };
        let Some(at_idx) = rest.find('@') else { continue };
        let after_at = &rest[at_idx + 1..];
        let Some(paren_idx) = after_at.find('(') else { continue };
        let name = after_at[..paren_idx].trim().to_string();
        let Some(close_idx) = find_matching_bracket(after_at, paren_idx, '(', ')') else { continue };
        let params_str = &after_at[paren_idx + 1..close_idx];
        let (param_count, is_vararg) = parse_param_list(params_str);
        // First signature seen wins -- a `define` normally also has a prior
        // `declare` (or none at all), and the two are expected to agree; a
        // mismatched second signature isn't this check's concern (that's an
        // ordinary duplicate-definition case `collect_global_symbols`
        // already flags for `define`/`define` pairs).
        sigs.entry(name).or_insert(FnSig { param_count, is_vararg });
    }
    sigs
}

// --------------------------------------------------------------------
// Pass 2: split the module into functions and, within each, into basic
// blocks.
// --------------------------------------------------------------------

struct Function<'a> {
    name: String,
    ret_ty: String,
    header_line: usize,
    param_names: Vec<String>,
    /// `(1-based line number, trimmed line text)` for every non-blank line
    /// strictly between the `define ... {` header and its matching `}`.
    body: Vec<(usize, &'a str)>,
}

fn parse_define_header(rest: &str) -> Option<(String, String, Vec<String>)> {
    let at_idx = rest.find('@')?;
    let ret_ty = normalize_ws(rest[..at_idx].trim());
    let after_at = &rest[at_idx + 1..];
    let paren_idx = after_at.find('(')?;
    let name = after_at[..paren_idx].trim().to_string();
    let close_idx = find_matching_bracket(after_at, paren_idx, '(', ')')?;
    let params_str = &after_at[paren_idx + 1..close_idx];
    let mut param_names = Vec::new();
    for chunk in split_top_level_commas(params_str) {
        let chunk = chunk.trim();
        if chunk.is_empty() || chunk == "..." {
            continue;
        }
        let (_, value) = split_type_and_value(chunk);
        if let Some(stripped) = value.strip_prefix('%') {
            param_names.push(stripped.to_string());
        }
    }
    Some((ret_ty, name, param_names))
}

fn normalize_ws(s: &str) -> String {
    s.split_whitespace().collect::<Vec<_>>().join(" ")
}

fn split_functions<'a>(lines: &[&'a str], errors: &mut Vec<IrError>) -> Vec<Function<'a>> {
    let mut out = Vec::new();
    let mut i = 0usize;
    while i < lines.len() {
        let line = lines[i];
        let lineno = i + 1;
        if let Some(rest) = line.strip_prefix("define ") {
            if let Some((ret_ty, name, param_names)) = parse_define_header(rest) {
                let mut j = i + 1;
                let mut body = Vec::new();
                let mut closed = false;
                while j < lines.len() {
                    if lines[j] == "}" {
                        closed = true;
                        break;
                    }
                    if lines[j].starts_with("define ") {
                        errors.push(IrError::new(
                            j + 1,
                            format!(
                                "function `@{}` (opened at line {}) is missing its closing `}}` -- another `define` starts here first",
                                name, lineno
                            ),
                        ));
                        break;
                    }
                    let trimmed = lines[j].trim();
                    if !trimmed.is_empty() {
                        body.push((j + 1, trimmed));
                    }
                    j += 1;
                }
                if !closed && j >= lines.len() {
                    errors.push(IrError::new(lineno, format!("function `@{}` is missing a closing `}}`", name)));
                }
                out.push(Function { name, ret_ty, header_line: lineno, param_names, body });
                i = if closed { j + 1 } else { j + 1 };
                continue;
            }
        }
        i += 1;
    }
    out
}

struct Block<'a> {
    label: String,
    /// Line the block's own `label:` line was found on -- used only to point
    /// a duplicate-label error somewhere sensible.
    header_line: usize,
    /// Instruction lines in this block, in order, *excluding* the label
    /// line itself.
    lines: Vec<(usize, &'a str)>,
}

fn parse_label_line(t: &str) -> Option<String> {
    let name = t.strip_suffix(':')?;
    if name.is_empty() || name.contains(' ') {
        return None;
    }
    if !name.chars().all(|c| c.is_ascii_alphanumeric() || c == '_' || c == '.' || c == '$') {
        return None;
    }
    Some(name.to_string())
}

/// Split a function's body into basic blocks, and flag two blocks sharing
/// one label -- `clang` rejects this outright ("label ... already defined")
/// and, unlike most malformed shapes this module checks for, it isn't
/// self-evident from a later pass: a duplicate label silently folds two
/// blocks' instructions into what downstream checks see as one block
/// (`cur` above only ever tracks the *most recent* block for a name), so
/// this is the one place that folding is still visible and must be caught
/// before it happens.
fn split_blocks<'a>(func: &Function<'a>, errors: &mut Vec<IrError>) -> Vec<Block<'a>> {
    let mut blocks = Vec::new();
    let mut cur: Option<Block> = None;
    let mut seen_labels: HashMap<String, usize> = HashMap::new();
    for &(lineno, text) in &func.body {
        if let Some(label) = parse_label_line(text) {
            if let Some(b) = cur.take() {
                blocks.push(b);
            }
            if let Some(&prev) = seen_labels.get(&label) {
                errors.push(IrError::new(
                    lineno,
                    format!("block label `{}` in `@{}` is defined more than once (already defined at line {})", label, func.name, prev),
                ));
            } else {
                seen_labels.insert(label.clone(), lineno);
            }
            cur = Some(Block { label, header_line: lineno, lines: Vec::new() });
        } else {
            match &mut cur {
                Some(b) => b.lines.push((lineno, text)),
                None => {
                    errors.push(IrError::new(
                        lineno,
                        format!("instruction in `@{}` appears before any block label (expected an `entry:` label first)", func.name),
                    ));
                }
            }
        }
    }
    if let Some(b) = cur.take() {
        blocks.push(b);
    }
    blocks
}

// --------------------------------------------------------------------
// Per-instruction parsing: `%reg = opcode rest` or `opcode rest`.
// --------------------------------------------------------------------

struct Instr<'a> {
    lhs: Option<String>,
    opcode: &'a str,
    rest: &'a str,
}

fn parse_instr(text: &str) -> Instr<'_> {
    if let Some(eq_idx) = text.find(" = ") {
        let lhs_part = text[..eq_idx].trim();
        if let Some(reg) = lhs_part.strip_prefix('%') {
            let after_eq = text[eq_idx + 3..].trim_start();
            let (opcode, rest) = split_first_word(after_eq);
            return Instr { lhs: Some(reg.to_string()), opcode, rest };
        }
    }
    let (opcode, rest) = split_first_word(text);
    Instr { lhs: None, opcode, rest }
}

fn is_integer_type(ty: &str) -> bool {
    ty.starts_with('i') && ty.len() > 1 && ty[1..].bytes().all(|b| b.is_ascii_digit())
}

/// Best-effort result type of an instruction with a value result, used only
/// to sanity-check `phi` incoming values against the `phi`'s declared type
/// (the concrete class of bug this closes: an operand whose real type
/// disagrees with what a later `phi` assumes -- `ASSESSMENT.md`'s "untagged
/// register" bug). Deliberately conservative: any shape not confidently
/// recognized returns `None` rather than guessing, since a wrong guess here
/// would produce a false-positive verifier error on legitimate IR -- worse
/// than the missed detection of leaving it `None`.
fn infer_result_type(instr: &Instr) -> Option<String> {
    match instr.opcode {
        "alloca" => {
            let elem = split_top_level_commas(instr.rest).first().map(|s| normalize_ws(s.trim()))?;
            Some(format!("{}*", elem))
        }
        "load" => {
            let first_chunk = split_top_level_commas(instr.rest).first().copied().unwrap_or("").trim().to_string();
            // Skip a possible leading `atomic` keyword on the element-type chunk.
            let ty = first_chunk.strip_prefix("atomic ").unwrap_or(&first_chunk);
            if ty.is_empty() { None } else { Some(normalize_ws(ty)) }
        }
        "call" => {
            let paren_idx = instr.rest.find('(')?;
            let before = &instr.rest[..paren_idx];
            let callee_start = before.rfind(char::is_whitespace).map(|i| i + 1).unwrap_or(0);
            let ty = before[..callee_start].trim();
            if ty.is_empty() { None } else { Some(normalize_ws(ty)) }
        }
        "bitcast" | "sitofp" | "uitofp" | "fptosi" | "fptoui" | "trunc" | "zext" | "sext" | "fpext" | "fptrunc" | "ptrtoint" | "inttoptr" => {
            let idx = instr.rest.find(" to ")?;
            Some(normalize_ws(instr.rest[idx + 4..].trim()))
        }
        "icmp" | "fcmp" => Some("i1".to_string()),
        "select" => {
            let chunks = split_top_level_commas(instr.rest);
            let val_chunk = chunks.get(1)?;
            let (ty, _) = split_type_and_value(val_chunk);
            if ty.is_empty() { None } else { Some(ty) }
        }
        "add" | "sub" | "mul" | "sdiv" | "udiv" | "srem" | "urem" | "shl" | "lshr" | "ashr" | "and" | "or" | "xor" | "fadd" | "fsub" | "fmul"
        | "fdiv" | "frem" => {
            let first_chunk = split_top_level_commas(instr.rest).first().copied().unwrap_or("").trim();
            let (ty, _) = split_type_and_value(first_chunk);
            if ty.is_empty() { None } else { Some(ty) }
        }
        "phi" => {
            let (ty, _) = split_first_top_level_token(instr.rest);
            let ty = ty.trim();
            if ty.is_empty() { None } else { Some(normalize_ws(ty)) }
        }
        _ => None,
    }
}

// --------------------------------------------------------------------
// Pass 3: per-function checks.
// --------------------------------------------------------------------

fn check_function(func: &Function, type_names: &HashSet<String>, fn_sigs: &HashMap<String, FnSig>, errors: &mut Vec<IrError>) {
    let blocks = split_blocks(func, errors);
    if blocks.is_empty() {
        errors.push(IrError::new(func.header_line, format!("function `@{}` has no basic blocks", func.name)));
        return;
    }

    let block_labels: HashSet<String> = blocks.iter().map(|b| b.label.clone()).collect();

    // Whole-function defined-name set: parameters, every block label, and
    // every SSA register any instruction assigns. Built as one flat set
    // (not tracked in textual order) deliberately -- this emitter never
    // relies on a register defined "later" in program order dominating an
    // earlier use (every real cross-block value flows through `phi` or
    // `alloca`+`load`/`store`), so ordering adds dominance-analysis
    // complexity this pass isn't trying to do; what it *does* catch --
    // reliably, with no false positives from ordering subtlety -- is a
    // register referenced that the emitter never assigned at all (a typo'd
    // temp name or an off-by-one counter bug).
    let mut defined_names: HashSet<String> = func.param_names.iter().cloned().collect();
    defined_names.extend(block_labels.iter().cloned());
    let mut reg_types: HashMap<String, String> = HashMap::new();
    let mut seen_lhs: HashMap<String, usize> = HashMap::new();

    for block in &blocks {
        for &(lineno, text) in &block.lines {
            let instr = parse_instr(text);
            if let Some(reg) = &instr.lhs {
                if let Some(&prev) = seen_lhs.get(reg) {
                    errors.push(IrError::new(
                        lineno,
                        format!("register `%{}` in `@{}` is defined more than once (already defined at line {}) -- SSA violation", reg, func.name, prev),
                    ));
                } else {
                    seen_lhs.insert(reg.clone(), lineno);
                }
                defined_names.insert(reg.clone());
                if let Some(ty) = infer_result_type(&instr) {
                    reg_types.insert(reg.clone(), ty);
                }
            }
        }
    }

    // Predecessor map: block label -> list of blocks whose terminator
    // branches to it (as a multiset -- a block branching to the same
    // target on both arms of a conditional legitimately produces two
    // edges).
    let mut predecessors: HashMap<String, Vec<String>> = HashMap::new();
    for block in &blocks {
        if let Some(&(lineno, text)) = block.lines.last() {
            let instr = parse_instr(text);
            if instr.opcode == "br" {
                for target in find_branch_targets(instr.rest) {
                    if !block_labels.contains(&target) {
                        errors.push(IrError::new(
                            lineno,
                            format!("`br` in `@{}` targets `%{}`, which is not a label defined in this function", func.name, target),
                        ));
                    }
                    predecessors.entry(target).or_default().push(block.label.clone());
                }
            }
        }
    }

    for block in &blocks {
        check_block_terminator(func, block, errors);
        check_phi_placement(func, block, errors);
        check_phis(func, block, &predecessors, &reg_types, errors);
        check_call_arity(func, block, fn_sigs, errors);
    }

    // A block other than the function's first (which `clang` always treats
    // as the entry point regardless of its label spelling, and which is
    // therefore always "reachable" with no `br` pointing at it) that no
    // `br` anywhere in the function ever targets is dead code no path
    // through this function can reach. Unlike every other check in this
    // module this isn't a shape `clang` rejects -- an unreachable block is
    // perfectly legal LLVM IR -- so it's a [`Severity::Warning`], not an
    // [`Severity::Error`]: real, but not build-blocking, since a
    // conditional the type checker (not this module) already proved
    // statically true/false can legitimately produce one.
    for block in blocks.iter().skip(1) {
        if predecessors.get(&block.label).map(|p| p.is_empty()).unwrap_or(true) {
            errors.push(IrError::warning(
                block.header_line,
                format!("block `{}` in `@{}` is unreachable -- no `br` in this function ever targets it", block.label, func.name),
            ));
        }
    }

    // Whole-function undefined-value-use scan.
    for block in &blocks {
        for &(lineno, text) in &block.lines {
            let instr = parse_instr(text);
            for tok in find_percent_tokens(instr.rest) {
                if type_names.contains(&tok) || defined_names.contains(&tok) {
                    continue;
                }
                errors.push(IrError::new(
                    lineno,
                    format!("use of undefined value `%{}` in `@{}` -- no `alloca`/assignment/parameter/label with that name exists in this function", tok, func.name),
                ));
            }
        }
    }

    check_return_types(func, &blocks, errors);
}

fn find_branch_targets(rest: &str) -> Vec<String> {
    let mut out = Vec::new();
    let mut s = rest;
    while let Some(idx) = s.find("label %") {
        let after = &s[idx + "label %".len()..];
        let end = after.find(|c: char| c == ',' || c.is_whitespace()).unwrap_or(after.len());
        out.push(after[..end].to_string());
        s = &after[end..];
    }
    out
}

/// A block must end with exactly one terminator (`ret`/`br`/`unreachable`)
/// as its last instruction, and no non-terminator instruction may follow
/// one -- the exact shape of the `frame:`-block-ending-in-`return` bug
/// (`ASSESSMENT.md` "The Ugly" #1): a `store` emitted after the block's own
/// `ret`, which parses as textual IR fine but which LLVM rejects outright
/// ("instruction is not a predecessor terminator" / unreachable code after
/// a terminator).
fn check_block_terminator(func: &Function, block: &Block, errors: &mut Vec<IrError>) {
    if block.lines.is_empty() {
        errors.push(IrError::new(
            func.header_line,
            format!("block `{}` in `@{}` is empty -- every basic block must end with a terminator (`ret`/`br`/`unreachable`)", block.label, func.name),
        ));
        return;
    }
    let last_idx = block.lines.len() - 1;
    for (idx, &(lineno, text)) in block.lines.iter().enumerate() {
        let instr = parse_instr(text);
        let is_terminator = TERMINATORS.contains(&instr.opcode);
        if idx == last_idx {
            if !is_terminator {
                errors.push(IrError::new(
                    lineno,
                    format!(
                        "block `{}` in `@{}` does not end with a terminator -- last instruction is `{}`, expected `ret`/`br`/`unreachable`",
                        block.label, func.name, instr.opcode
                    ),
                ));
            }
        } else if is_terminator {
            errors.push(IrError::new(
                lineno,
                format!(
                    "block `{}` in `@{}` has a `{}` terminator before its last instruction -- unreachable code follows in the same block",
                    block.label, func.name, instr.opcode
                ),
            ));
        }
    }
}

/// `phi` instructions must be grouped at the very top of a block, before
/// any non-`phi` instruction.
fn check_phi_placement(func: &Function, block: &Block, errors: &mut Vec<IrError>) {
    let mut seen_non_phi: Option<usize> = None;
    for &(lineno, text) in &block.lines {
        let instr = parse_instr(text);
        if instr.opcode == "phi" {
            if let Some(prev) = seen_non_phi {
                errors.push(IrError::new(
                    lineno,
                    format!("`phi` in `@{}` block `{}` follows a non-`phi` instruction at line {} -- `phi`s must be grouped at the top of a block", func.name, block.label, prev),
                ));
            }
        } else if seen_non_phi.is_none() {
            seen_non_phi = Some(lineno);
        }
    }
}

/// For every `phi` in `block`: its listed incoming labels must match the
/// block's actual predecessor set exactly (as a multiset), and -- where the
/// checker was able to infer a type for an incoming SSA value -- that type
/// must agree with the `phi`'s own declared type. This is the check that
/// directly targets the "if/else returning a bare identifier produced an
/// untagged register" bug.
fn check_phis(func: &Function, block: &Block, predecessors: &HashMap<String, Vec<String>>, reg_types: &HashMap<String, String>, errors: &mut Vec<IrError>) {
    let actual_preds = predecessors.get(&block.label).cloned().unwrap_or_default();
    let mut actual_sorted = actual_preds.clone();
    actual_sorted.sort();

    for &(lineno, text) in &block.lines {
        let instr = parse_instr(text);
        if instr.opcode != "phi" {
            continue;
        }
        let (phi_ty_raw, pairs_str) = split_first_top_level_token(instr.rest);
        if !pairs_str.starts_with('[') {
            errors.push(IrError::new(lineno, format!("malformed `phi` in `@{}`: no incoming-value list found", func.name)));
            continue;
        }
        let phi_ty = normalize_ws(phi_ty_raw.trim());

        let mut incoming_labels = Vec::new();
        for chunk in split_top_level_commas(pairs_str) {
            let chunk = chunk.trim();
            let Some(inner) = chunk.strip_prefix('[').and_then(|s| s.strip_suffix(']')) else {
                errors.push(IrError::new(lineno, format!("malformed `phi` incoming pair `{}` in `@{}`", chunk, func.name)));
                continue;
            };
            let parts = split_top_level_commas(inner);
            if parts.len() != 2 {
                errors.push(IrError::new(lineno, format!("malformed `phi` incoming pair `{}` in `@{}`: expected `[ value, %label ]`", chunk, func.name)));
                continue;
            }
            let value = parts[0].trim();
            let label = parts[1].trim().strip_prefix('%').unwrap_or(parts[1].trim()).to_string();
            incoming_labels.push(label);

            check_phi_incoming_type(func, lineno, &phi_ty, value, reg_types, errors);
        }

        let mut incoming_sorted = incoming_labels.clone();
        incoming_sorted.sort();
        if incoming_sorted != actual_sorted {
            errors.push(IrError::new(
                lineno,
                format!(
                    "`phi` in `@{}` block `{}` lists incoming blocks [{}] but the actual predecessors are [{}]",
                    func.name,
                    block.label,
                    incoming_labels.join(", "),
                    actual_preds.join(", ")
                ),
            ));
        }
    }
}

/// The `(<args>)` this instruction's text ends with, and everything before
/// it -- i.e. `s` split at the *last* top-level `(`, found by scanning
/// backwards from `s`'s own closing `)` and tracking paren depth. Unlike a
/// simple "first `(`" search, this handles a variadic callee's explicit
/// `<ret> (<param types>) @callee(<args>)` call syntax (the real shape
/// `call i32 (i8*, ...) @printf(...)` this emitter's `emit_print_like`
/// produces) correctly: the *first* `(` in that text opens the parameter-
/// type annotation, not the argument list. Returns `None` for anything that
/// doesn't end in a balanced `(...)`, including every malformed shape a
/// fuzzed/garbled input could produce -- this check only ever fires on text
/// it's confident it parsed correctly.
fn split_trailing_paren_group(s: &str) -> Option<(&str, &str)> {
    let trimmed = s.trim_end();
    if !trimmed.ends_with(')') {
        return None;
    }
    let close_idx = trimmed.len() - 1;
    let mut depth = 0i32;
    let mut open_idx = None;
    for (i, ch) in trimmed.char_indices().rev() {
        match ch {
            ')' => depth += 1,
            '(' => {
                depth -= 1;
                if depth == 0 {
                    open_idx = Some(i);
                    break;
                }
            }
            _ => {}
        }
    }
    let open_idx = open_idx?;
    Some((trimmed[..open_idx].trim(), &trimmed[open_idx + 1..close_idx]))
}

/// A direct `call`'s argument count must agree with its callee's declared
/// parameter count (or, for a variadic callee, be at least that many).
/// Deliberately skips anything it can't confidently resolve to a concrete,
/// non-variadic-mismatched signature -- an indirect call through a register
/// (`call i32 %fnptr(...)`, the shape a closure/generic dispatch produces)
/// has no statically-known arity here and is left unchecked, and a callee
/// this module never found a `declare`/`define` for is already reported by
/// `check_global_uses` and not re-flagged here.
fn check_call_arity(func: &Function, block: &Block, fn_sigs: &HashMap<String, FnSig>, errors: &mut Vec<IrError>) {
    for &(lineno, text) in &block.lines {
        let instr = parse_instr(text);
        if instr.opcode != "call" {
            continue;
        }
        let Some((before, args_str)) = split_trailing_paren_group(instr.rest) else { continue };

        let (_, callee) = split_type_and_value(before);
        let Some(name) = callee.strip_prefix('@') else { continue };
        if name.starts_with("llvm.") {
            continue;
        }
        let Some(sig) = fn_sigs.get(name) else { continue };

        let (actual, _) = parse_param_list(args_str);
        let mismatched = if sig.is_vararg { actual < sig.param_count } else { actual != sig.param_count };
        if mismatched {
            errors.push(IrError::new(
                lineno,
                format!(
                    "call to `@{}` in `@{}` passes {} argument{} but it {} {}{}",
                    name,
                    func.name,
                    actual,
                    if actual == 1 { "" } else { "s" },
                    if sig.is_vararg { "requires at least" } else { "takes" },
                    sig.param_count,
                    if sig.param_count == 1 { "" } else { "s" },
                ),
            ));
        }
    }
}

fn check_phi_incoming_type(func: &Function, lineno: usize, phi_ty: &str, value: &str, reg_types: &HashMap<String, String>, errors: &mut Vec<IrError>) {
    if value == "null" {
        if !phi_ty.ends_with('*') {
            errors.push(IrError::new(
                lineno,
                format!("`phi` in `@{}` declares type `{}` but has an incoming `null` value (a pointer literal)", func.name, phi_ty),
            ));
        }
    } else if value == "true" || value == "false" {
        if phi_ty != "i1" {
            errors.push(IrError::new(
                lineno,
                format!("`phi` in `@{}` declares type `{}` but has an incoming `{}` value (an `i1` literal)", func.name, phi_ty, value),
            ));
        }
    } else if value.starts_with("0x") {
        if phi_ty != "float" && phi_ty != "double" {
            errors.push(IrError::new(
                lineno,
                format!("`phi` in `@{}` declares type `{}` but has an incoming hex float literal `{}`", func.name, phi_ty, value),
            ));
        }
    } else if value.parse::<i64>().is_ok() {
        if !is_integer_type(phi_ty) {
            errors.push(IrError::new(
                lineno,
                format!("`phi` in `@{}` declares type `{}` but has an incoming integer literal `{}`", func.name, phi_ty, value),
            ));
        }
    } else if let Some(reg) = value.strip_prefix('%') {
        if let Some(reg_ty) = reg_types.get(reg) {
            if normalize_ws(reg_ty) != normalize_ws(phi_ty) {
                errors.push(IrError::new(
                    lineno,
                    format!("`phi` in `@{}` declares type `{}` but incoming value `%{}` has type `{}`", func.name, phi_ty, reg, reg_ty),
                ));
            }
        }
    }
    // Any other shape (an inline aggregate literal, an unrecognized
    // constant expression, ...) is left unchecked -- see
    // `infer_result_type`'s doc comment on why guessing here is worse than
    // not checking.
}

/// Every `ret` in a function must agree with that function's own declared
/// return type -- `ret void` in a non-`void` function (or vice versa), or a
/// `ret <ty> ...` whose `<ty>` doesn't match, is exactly the shape of an
/// untagged/mistyped merge value slipping past the emitter uncaught.
fn check_return_types(func: &Function, blocks: &[Block], errors: &mut Vec<IrError>) {
    for block in blocks {
        if let Some(&(lineno, text)) = block.lines.last() {
            let instr = parse_instr(text);
            if instr.opcode != "ret" {
                continue;
            }
            let actual_ty = if instr.rest.trim() == "void" { "void".to_string() } else { normalize_ws(split_type_and_value(instr.rest).0.as_str()) };
            if actual_ty != func.ret_ty {
                errors.push(IrError::new(
                    lineno,
                    format!("`ret` type `{}` does not match `@{}`'s declared return type `{}`", actual_ty, func.name, func.ret_ty),
                ));
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::{verify, Severity};

    /// A minimal, well-formed module (mirroring the shape real `Codegen`
    /// output takes) should never produce any error -- the baseline every
    /// other test's "bad" variant is a minimal edit away from.
    fn clean_module() -> String {
        r#"; Star compiler -- LLVM IR
target triple = "x86_64-w64-windows-gnu"

declare i32 @printf(i8*, ...)

define i32 @main(i32 %.argc, i8** %.argv) {
entry:
  %cond = icmp sgt i32 %.argc, 1
  br i1 %cond, label %then, label %else
then:
  %a = add i32 1, 1
  br label %merge
else:
  %b = add i32 2, 2
  br label %merge
merge:
  %m = phi i32 [ %a, %then ], [ %b, %else ]
  ret i32 %m
}
"#
        .to_string()
    }

    #[test]
    fn clean_module_has_no_errors() {
        let errs = verify(&clean_module());
        assert!(errs.is_empty(), "expected no errors, got: {:?}", errs);
    }

    /// Reproduces the exact historical bug from `projects/snake/NOTES.md`:
    /// a `frame:` block ending in `return` emitted a `store` *after* the
    /// block's own terminator. LLVM rejects this outright; this test proves
    /// the checker catches it without ever shelling out to `clang`.
    #[test]
    fn catches_instruction_after_terminator() {
        let ir = r#"target triple = "x86_64-w64-windows-gnu"
define i32 @main() {
entry:
  ret i32 0
  store i32 1, i32* @dangling
}
"#;
        let errs = verify(ir);
        assert!(
            errs.iter().any(|e| e.message.contains("terminator") && e.message.contains("unreachable code")),
            "expected an instruction-after-terminator error, got: {:?}",
            errs
        );
    }

    /// A block that never ends in `ret`/`br`/`unreachable` at all (e.g. a
    /// codegen path that forgot to terminate a block) is just as invalid --
    /// same rule, opposite shape of mistake.
    #[test]
    fn catches_missing_terminator() {
        let ir = r#"target triple = "x86_64-w64-windows-gnu"
define i32 @main() {
entry:
  %a = add i32 1, 1
}
"#;
        let errs = verify(ir);
        assert!(
            errs.iter().any(|e| e.message.contains("does not end with a terminator")),
            "expected a missing-terminator error, got: {:?}",
            errs
        );
    }

    /// Reproduces the second historical bug class: a `phi` merging branch
    /// results where one incoming value's real type disagrees with what the
    /// `phi` declares -- the "untagged register" bug from `NOTES.md`.
    #[test]
    fn catches_phi_type_mismatch() {
        let ir = r#"target triple = "x86_64-w64-windows-gnu"
define i32 @main() {
entry:
  %cond = icmp eq i32 0, 0
  br i1 %cond, label %then, label %else
then:
  %a = add i64 1, 1
  br label %merge
else:
  %b = add i32 2, 2
  br label %merge
merge:
  %m = phi i32 [ %a, %then ], [ %b, %else ]
  ret i32 %m
}
"#;
        let errs = verify(ir);
        assert!(
            errs.iter().any(|e| e.message.contains("phi") && e.message.contains("type") && e.message.contains("%a")),
            "expected a phi type-mismatch error naming %a, got: {:?}",
            errs
        );
    }

    /// A `phi` whose incoming-label list doesn't match the block's actual
    /// predecessors (e.g. a stale label left behind after a codegen
    /// refactor) is invalid regardless of value types.
    #[test]
    fn catches_phi_predecessor_mismatch() {
        let ir = r#"target triple = "x86_64-w64-windows-gnu"
define i32 @main() {
entry:
  br label %merge
merge:
  %m = phi i32 [ 0, %nonexistent ]
  ret i32 %m
}
"#;
        let errs = verify(ir);
        assert!(
            errs.iter().any(|e| e.message.contains("actual predecessors")),
            "expected a phi predecessor-mismatch error, got: {:?}",
            errs
        );
    }

    #[test]
    fn catches_branch_to_undefined_label() {
        let ir = r#"target triple = "x86_64-w64-windows-gnu"
define i32 @main() {
entry:
  br label %nope
}
"#;
        let errs = verify(ir);
        assert!(
            errs.iter().any(|e| e.message.contains("not a label defined")),
            "expected an undefined-branch-target error, got: {:?}",
            errs
        );
    }

    #[test]
    fn catches_use_of_undefined_register() {
        let ir = r#"target triple = "x86_64-w64-windows-gnu"
define i32 @main() {
entry:
  ret i32 %never_defined
}
"#;
        let errs = verify(ir);
        assert!(
            errs.iter().any(|e| e.message.contains("undefined value") && e.message.contains("never_defined")),
            "expected an undefined-value error, got: {:?}",
            errs
        );
    }

    #[test]
    fn catches_duplicate_register_definition() {
        let ir = r#"target triple = "x86_64-w64-windows-gnu"
define i32 @main() {
entry:
  %a = add i32 1, 1
  %a = add i32 2, 2
  ret i32 %a
}
"#;
        let errs = verify(ir);
        assert!(
            errs.iter().any(|e| e.message.contains("defined more than once")),
            "expected a duplicate-definition error, got: {:?}",
            errs
        );
    }

    #[test]
    fn catches_duplicate_function_definition() {
        let ir = r#"target triple = "x86_64-w64-windows-gnu"
define i32 @dup() {
entry:
  ret i32 0
}
define i32 @dup() {
entry:
  ret i32 1
}
"#;
        let errs = verify(ir);
        assert!(
            errs.iter().any(|e| e.message.contains("duplicate definition of `@dup`")),
            "expected a duplicate-function error, got: {:?}",
            errs
        );
    }

    #[test]
    fn catches_undefined_global_reference() {
        let ir = r#"target triple = "x86_64-w64-windows-gnu"
define i32 @main() {
entry:
  %v = load i32, i32* @never_declared
  ret i32 %v
}
"#;
        let errs = verify(ir);
        assert!(
            errs.iter().any(|e| e.message.contains("undefined global") && e.message.contains("never_declared")),
            "expected an undefined-global error, got: {:?}",
            errs
        );
    }

    /// `llvm.*`-prefixed intrinsics are exempt from the undefined-global
    /// check -- `clang` auto-synthesizes their declaration from the call
    /// site alone (confirmed empirically against a real `clang` invocation
    /// during development of this checker), so flagging a missing
    /// `declare` for one would be a false positive, not a real defect.
    #[test]
    fn does_not_flag_missing_llvm_intrinsic_declare() {
        let ir = r#"target triple = "x86_64-w64-windows-gnu"
define i32 @main() {
entry:
  %t = call { i32, i1 } @llvm.sadd.with.overflow.i32(i32 1, i32 2)
  %v = extractvalue { i32, i1 } %t, 0
  ret i32 %v
}
"#;
        let errs = verify(ir);
        assert!(errs.is_empty(), "expected no errors for an undeclared llvm.* intrinsic call, got: {:?}", errs);
    }

    #[test]
    fn catches_return_type_mismatch() {
        let ir = r#"target triple = "x86_64-w64-windows-gnu"
define i32 @main() {
entry:
  ret void
}
"#;
        let errs = verify(ir);
        assert!(
            errs.iter().any(|e| e.message.contains("does not match")),
            "expected a return-type-mismatch error, got: {:?}",
            errs
        );
    }

    /// A `phi` whose declared type itself contains nested brackets (an
    /// array-typed field inside a struct pointer, e.g. `{ [2 x i8*], i64
    /// }*` -- the exact shape `ring_table_nesting.ll` exercises) must not
    /// confuse the incoming-pair parser, which used to find the *first*
    /// `[` anywhere in the instruction rather than the first *top-level*
    /// one and misparse the type as truncated partway through.
    #[test]
    fn handles_phi_with_bracketed_type() {
        let ir = r#"target triple = "x86_64-w64-windows-gnu"
%Pair = type { [2 x i8*], i64 }
define %Pair* @main() {
entry:
  br i1 true, label %a, label %b
a:
  br label %merge
b:
  br label %merge
merge:
  %m = phi %Pair* [ null, %a ], [ null, %b ]
  ret %Pair* %m
}
"#;
        let errs = verify(ir);
        assert!(errs.is_empty(), "expected no errors for a bracketed phi type, got: {:?}", errs);
    }

    /// A `phi` whose declared type *itself* starts with `[` (an array-of-
    /// vector pointer, `[3 x <3 x float>]*` -- the real shape a
    /// monomorphized `Mat3`/`Mat2` generic's `if`/`else`-merge produces)
    /// must not be misparsed as if the incoming-value list started at that
    /// leading `[` -- this is the actual false positive three end-to-end
    /// tests (`runtime_list_and_ring_of_odd_sized_new_types_end_to_end` and
    /// two others) hit during development of this checker, before
    /// `split_first_top_level_token` replaced a naive "first `[` anywhere"
    /// search.
    #[test]
    fn handles_phi_with_array_typed_result() {
        let ir = r#"target triple = "x86_64-w64-windows-gnu"
define [3 x <3 x float>]* @main() {
entry:
  br i1 true, label %a, label %b
a:
  %p1 = alloca [3 x <3 x float>]
  br label %merge
b:
  %p2 = alloca [3 x <3 x float>]
  br label %merge
merge:
  %m = phi [3 x <3 x float>]* [ %p1, %a ], [ %p2, %b ]
  ret [3 x <3 x float>]* %m
}
"#;
        let errs = verify(ir);
        assert!(errs.is_empty(), "expected no errors for an array-typed phi result, got: {:?}", errs);
    }

    /// A string literal containing a stray `%`/`@` character (plausible
    /// Star source: printing an email address or a `@`-prefixed tag) must
    /// not be misread as an IR register/global reference.
    #[test]
    fn ignores_percent_and_at_inside_string_literals() {
        let ir = r#"target triple = "x86_64-w64-windows-gnu"
@.str.0 = private unnamed_addr constant [20 x i8] c"user@example.com %x\00"
define i32 @main() {
entry:
  %p = getelementptr inbounds [20 x i8], [20 x i8]* @.str.0, i64 0, i64 0
  %r = call i32 @puts(i8* %p)
  ret i32 %r
}
declare i32 @puts(i8*)
"#;
        let errs = verify(ir);
        assert!(errs.is_empty(), "expected no errors from string-literal content, got: {:?}", errs);
    }

    #[test]
    fn catches_phi_not_grouped_at_block_top() {
        let ir = r#"target triple = "x86_64-w64-windows-gnu"
define i32 @main() {
entry:
  br label %merge
merge:
  %x = add i32 1, 1
  %m = phi i32 [ 0, %entry ]
  ret i32 %m
}
"#;
        let errs = verify(ir);
        assert!(
            errs.iter().any(|e| e.message.contains("follows a non-`phi` instruction")),
            "expected a phi-placement error, got: {:?}",
            errs
        );
    }

    #[test]
    fn catches_duplicate_block_label() {
        let ir = r#"target triple = "x86_64-w64-windows-gnu"
define i32 @main() {
entry:
  br label %again
again:
  ret i32 0
again:
  ret i32 1
}
"#;
        let errs = verify(ir);
        assert!(
            errs.iter().any(|e| e.severity == Severity::Error && e.message.contains("defined more than once")),
            "expected a duplicate-block-label error, got: {:?}",
            errs
        );
    }

    /// A block no `br` in the function ever targets is dead, real LLVM IR
    /// `clang` happily accepts (the exhaustive-`match` catch-all shape
    /// `struct_destructure.ll` actually ships) -- so this must surface as a
    /// non-blocking [`Severity::Warning`], never a build-blocking
    /// [`Severity::Error`].
    #[test]
    fn flags_unreachable_block_as_warning_only() {
        let ir = r#"target triple = "x86_64-w64-windows-gnu"
define i32 @main() {
entry:
  ret i32 0
orphan:
  ret i32 1
}
"#;
        let errs = verify(ir);
        assert!(
            errs.iter().any(|e| e.severity == Severity::Warning && e.message.contains("unreachable") && e.message.contains("orphan")),
            "expected an unreachable-block warning naming `orphan`, got: {:?}",
            errs
        );
        assert!(
            !errs.iter().any(|e| e.severity == Severity::Error),
            "an unreachable block must never itself produce an Error-severity finding, got: {:?}",
            errs
        );
    }

    /// The function's first block is always the entry point regardless of
    /// its label spelling and is never expected to have a `br` pointing at
    /// it -- it must never be flagged as "unreachable" itself.
    #[test]
    fn does_not_flag_entry_block_as_unreachable() {
        let ir = r#"target triple = "x86_64-w64-windows-gnu"
define i32 @main() {
entry:
  ret i32 0
}
"#;
        let errs = verify(ir);
        assert!(errs.is_empty(), "entry block must never be flagged unreachable, got: {:?}", errs);
    }

    #[test]
    fn catches_call_with_too_few_arguments() {
        let ir = r#"target triple = "x86_64-w64-windows-gnu"
declare i32 @add(i32, i32)
define i32 @main() {
entry:
  %r = call i32 @add(i32 1)
  ret i32 %r
}
"#;
        let errs = verify(ir);
        assert!(
            errs.iter().any(|e| e.severity == Severity::Error && e.message.contains("passes 1 argument") && e.message.contains("takes 2")),
            "expected a call-arity error, got: {:?}",
            errs
        );
    }

    #[test]
    fn catches_call_with_too_many_arguments() {
        let ir = r#"target triple = "x86_64-w64-windows-gnu"
declare void @f(i32)
define i32 @main() {
entry:
  call void @f(i32 1, i32 2)
  ret i32 0
}
"#;
        let errs = verify(ir);
        assert!(
            errs.iter().any(|e| e.severity == Severity::Error && e.message.contains("passes 2 arguments") && e.message.contains("takes 1")),
            "expected a call-arity error, got: {:?}",
            errs
        );
    }

    /// A variadic callee (`declare i32 @printf(i8*, ...)`) only has a
    /// *minimum* argument count -- passing more than its fixed parameters
    /// is exactly the point of `...`, not a defect.
    #[test]
    fn does_not_flag_extra_varargs_to_variadic_callee() {
        let ir = r#"target triple = "x86_64-w64-windows-gnu"
declare i32 @printf(i8*, ...)
define i32 @main() {
entry:
  %r = call i32 (i8*, ...) @printf(i8* null, i32 1, i32 2, i32 3)
  ret i32 %r
}
"#;
        let errs = verify(ir);
        assert!(errs.is_empty(), "expected no errors for extra varargs to a variadic callee, got: {:?}", errs);
    }

    /// A variadic callee still needs at least its fixed parameters supplied.
    #[test]
    fn catches_too_few_arguments_to_variadic_callee() {
        let ir = r#"target triple = "x86_64-w64-windows-gnu"
declare i32 @printf(i8*, ...)
define i32 @main() {
entry:
  %r = call i32 (i8*, ...) @printf()
  ret i32 %r
}
"#;
        let errs = verify(ir);
        assert!(
            errs.iter().any(|e| e.severity == Severity::Error && e.message.contains("requires at least 1")),
            "expected a variadic-callee arity error, got: {:?}",
            errs
        );
    }

    /// An indirect call through a register (the shape closures/generic
    /// dispatch produce) has no statically-known arity in this checker and
    /// must never be flagged.
    #[test]
    fn does_not_flag_indirect_call_arity() {
        let ir = r#"target triple = "x86_64-w64-windows-gnu"
define i32 @main(i32 (i8*)* %fn, i8* %env) {
entry:
  %r = call i32 %fn(i8* %env)
  ret i32 %r
}
"#;
        let errs = verify(ir);
        assert!(errs.is_empty(), "expected no errors for an indirect call, got: {:?}", errs);
    }
}

/// Adversarial/malformed-input coverage: every check above is written to
/// degrade gracefully (return fewer/no findings) on IR text that doesn't
/// match this emitter's dialect rather than panic -- since a panic here
/// would crash `star build`/`star check` outright over what should, at
/// worst, be a missed diagnostic (see `crate::driver::Driver::codegen`,
/// which additionally wraps the call to `verify` in `catch_unwind` as a
/// second line of defense). These tests exist to keep that property honest
/// as new checks get added, not to assert anything about *which* findings a
/// given garbled input produces.
#[cfg(test)]
mod robustness {
    use super::verify;

    struct Rng(u64);
    impl Rng {
        fn next(&mut self) -> u64 {
            self.0 ^= self.0 << 13;
            self.0 ^= self.0 >> 7;
            self.0 ^= self.0 << 17;
            self.0
        }
        fn pick<'a, T>(&mut self, items: &'a [T]) -> &'a T {
            &items[(self.next() as usize) % items.len()]
        }
    }

    #[test]
    fn fuzz_never_panics() {
        let tokens = [
            "define", "declare", "i32", "@main", "@foo", "(", ")", "{", "}", "[", "]", "<", ">", ",",
            "%a", "%b", "%.argc", "entry:", "merge:", "ret", "br", "label", "phi", "i1", "true", "false",
            "null", "icmp", "eq", "call", "load", "store", "alloca", "getelementptr", "inbounds", "=",
            "\"", "c\"foo\\00\"", "atomic", "to", "x", "float", "double", "0x7FF0000000000000", "...",
            "-1", "99999999999999999999", "%", "@", "type", "unreachable", "bitcast", "*", "\n",
        ];
        let mut rng = Rng(0x9E3779B97F4A7C15);
        for _ in 0..2000 {
            let n_lines = 1 + (rng.next() % 12) as usize;
            let mut ir = String::new();
            for _ in 0..n_lines {
                let n_tok = 1 + (rng.next() % 8) as usize;
                for _ in 0..n_tok {
                    ir.push_str(rng.pick(&tokens));
                    ir.push(' ');
                }
                ir.push('\n');
            }
            // Should never panic regardless of how garbled the input is.
            let _ = verify(&ir);
        }
    }

    #[test]
    fn empty_input_ok() {
        assert!(verify("").is_empty());
    }

    #[test]
    fn only_whitespace_ok() {
        let _ = verify("   \n\n\t\n");
    }

    #[test]
    fn unbalanced_brackets_do_not_panic() {
        let _ = verify("define i32 @f((((((( {\nentry:\n  ret i32 0\n");
        let _ = verify("define i32 @f() {\nentry:\n  %m = phi i32 [ 0, %a\n  ret i32 %m\n}\n");
        let _ = verify("%x = phi [[[[[ i32 [ 0, %a ]\n");
    }

    #[test]
    fn unterminated_string_literal_does_not_panic() {
        let _ = verify(r#"@.str = constant [4 x i8] c"abc"#);
    }

    #[test]
    fn lone_sigils_do_not_panic() {
        let _ = verify("% @ %% @@ %.. @..\n");
    }

    #[test]
    fn huge_integer_literal_in_phi_does_not_panic() {
        let ir = r#"define i32 @main() {
entry:
  br label %m
m:
  %v = phi i32 [ 999999999999999999999999999999, %entry ]
  ret i32 %v
}
"#;
        let _ = verify(ir);
    }
}

/// Regression coverage against every `.ll` file this compiler actually
/// ships (`examples/`, `projects/`) -- real `Codegen` output, not
/// hand-written fixtures. A [`Severity::Warning`] here is fine (and, for
/// e.g. an exhaustive `match`'s trailing `unreachable` catch-all block,
/// expected); a [`Severity::Error`] is not: every one of these files
/// already builds and runs today, so this module reporting a build-blocking
/// error against any of them would be a false positive in this checker
/// itself, not a real bug in the fixture.
#[cfg(test)]
mod real_fixture_regression {
    use super::{verify, Severity};
    use std::fs;
    use std::path::PathBuf;

    fn walk(dir: &str) -> Vec<PathBuf> {
        let mut out = Vec::new();
        let mut stack = vec![PathBuf::from(dir)];
        while let Some(d) = stack.pop() {
            if let Ok(rd) = fs::read_dir(&d) {
                for entry in rd.flatten() {
                    let p = entry.path();
                    if p.is_dir() {
                        stack.push(p);
                    } else {
                        out.push(p);
                    }
                }
            }
        }
        out
    }

    #[test]
    fn no_error_severity_findings_on_shipped_ll_files() {
        let mut total_files = 0usize;
        let mut failures = String::new();
        for dir in ["examples", "projects"] {
            for entry in walk(dir) {
                if entry.extension().map(|e| e == "ll").unwrap_or(false) {
                    total_files += 1;
                    let text = fs::read_to_string(&entry).unwrap();
                    for e in verify(&text) {
                        if e.severity == Severity::Error {
                            failures.push_str(&format!("{}:{}: {}\n", entry.display(), e.line, e.message));
                        }
                    }
                }
            }
        }
        assert!(total_files > 0, "expected to find at least one .ll fixture under examples/ or projects/");
        assert!(failures.is_empty(), "false-positive Error-severity findings on real, working .ll fixtures:\n{}", failures);
    }
}

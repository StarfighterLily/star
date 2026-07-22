//! Resolves `import "path.star" as alias` declarations into a single flat
//! [`Module`] before type checking ever has to think about more than one
//! file.
//!
//! Star has no notion of separately-compiled units: `resolve` inlines each
//! imported file's items directly into the importing module, after renaming
//! every one of that file's top-level declarations (structs, enums, traits,
//! functions, arenas, sequences) to a globally-unique `alias__name` mangled
//! form and rewriting every reference to them (calls, types, struct/enum
//! literals, match patterns, arena statements) to match. The parser
//! reproduces the exact same `alias__name` scheme (see [`mangle_name`]) when
//! it sees a qualified `alias::name` path in the importing file's own source,
//! so by the time the checker and codegen run, `alias::name` and the
//! definition it refers to are simply the same plain identifier -- neither
//! stage needs to know modules exist.
//!
//! Imports are resolved recursively (an imported file may itself import
//! other files), with a cycle guard over canonicalized paths. Nested imports
//! are transitively reachable: if module `a` imports `b`, which imports `c`,
//! `b`'s own `c::foo` references are mangled to `c__foo` while resolving `b`
//! in isolation, and that identifier is then a genuine top-level item of
//! `b`'s own (already-flattened) module -- so it gets swept up in `b`'s own
//! `alias__` prefixing when `a` imports `b`, landing on `b__c__foo`, which is
//! exactly the name the parser produces for `a`'s own `b::c::foo` (see
//! `parser::expr::parse_primary`'s qualified-path loop): chained
//! `mangle_name` calls are pure string concatenation, so `a` can address it
//! directly with no re-export syntax needed and no risk of the two sides'
//! mangling disagreeing.

use std::collections::{HashMap, HashSet};
use std::path::{Path, PathBuf};

use crate::ast::*;
use crate::diagnostics::Diagnostic;
use crate::parser::Parser;

/// The mangled name a qualified `alias::name` reference resolves to. The
/// parser (see `parser::expr::parse_primary`/`parse_pattern` and
/// `parser::parse_type`) and this module's rename pass must agree on this
/// exact scheme, since the parser produces it from source text while parsing
/// the importing file, and this module produces it independently while
/// renaming the imported file's own declarations.
pub fn mangle_name(alias: &str, name: &str) -> String {
    format!("{alias}__{name}")
}

/// A bound on how many levels deep `resolve_inner` may recurse through a
/// chain of `import`s (`a` imports `b` imports `c` imports ...) before
/// failing with a clean diagnostic instead of exhausting the real Rust call
/// stack.
///
/// The cycle guard (`loading`, a `HashSet<PathBuf>` shared across every
/// recursive call) already stops a *circular* import chain from recursing
/// forever -- but it does nothing for a long, genuinely acyclic chain of
/// distinct files, since each new file is a fresh, never-before-seen
/// canonical path that `loading.insert` happily accepts. `resolve_inner`
/// recurses once per import level with no depth counter of its own,
/// confirmed via a real, unguarded stack overflow ("thread 'main' has
/// overflowed its stack") from a genuinely acyclic chain of a few hundred
/// files (`a` imports `b` imports `c` imports ... some 700+ levels deep,
/// each file distinct, no cycle anywhere) -- a somewhat exotic shape for a
/// hand-written program, but entirely plausible from a code generator that
/// emits one file per module/scene/level and chains them together. 200
/// matches this codebase's other depth guards' (`MAX_EXPR_DEPTH`,
/// `MAX_BLOCK_DEPTH`, `Checker::MAX_MONO_DEPTH`) same "comfortable margin
/// below an empirically observed cliff" calibration.
const MAX_IMPORT_DEPTH: u32 = 200;

/// A top-level item's provenance: which canonical source file, and which
/// original (unmangled) name, it was actually declared under. Tracked
/// *positionally*, one entry per item in the module currently being built --
/// never keyed by the item's current (possibly mangled, possibly colliding)
/// name string. Keying by name was tried first and is wrong: two genuinely
/// different declarations (different files, different meanings) can and do
/// collide onto the identical mangled name today (see
/// `rejects_duplicate_top_level_name_from_two_imports_sharing_one_alias`,
/// which imports two different files' `helper` under the same alias) --
/// name-keyed provenance would clobber one entry with the other and cause
/// [`dedupe_by_origin`] to treat a real collision as a diamond-dependency
/// re-export and silently drop one of the two, hiding a genuine "declared
/// more than once" diagnostic. Positional tracking never conflates the two.
type ItemProvenance = Vec<Option<(PathBuf, String)>>;

/// Resolve every `import` in `module` (whose own source lives at
/// `root_path`), recursively inlining each imported file's items under a
/// mangled name. Returns the flattened module (no `Item::Import` entries
/// left) plus a file table: index `i` holds the `(label, source text)` of
/// the file `crate::diagnostics::Span::file_id == i as u32 + 1` refers to,
/// in first-encountered order. `crate::driver::Compilation` stores this
/// (as `imported_files`) so a diagnostic whose span originated inside an
/// imported file's inlined AST renders against *that* file's real source
/// text instead of unconditionally against the root file's -- previously
/// every span an imported file's declarations carried was preserved
/// verbatim (correct *byte offsets*, but only meaningful against that
/// file's own buffer) with nothing tracking which buffer it belonged to,
/// so any checker/codegen diagnostic raised against successfully-inlined
/// imported code rendered at a wrong/garbled line, column, and caret span
/// in the *importing* file instead (confirmed via a real `star check` on a
/// type error inside an imported file rendering mid-way through the
/// importing file's own `import` statement). Import-resolution-level
/// failures (a missing file, a parse error, a cycle) are unaffected -- they
/// already re-anchor on the *importing* file's own `decl.span`, a real,
/// meaningful location in a file this function's caller definitely has the
/// source text for. Also runs a final deduplication pass ([`dedupe_by_origin`])
/// so the same file reached via more than one alias chain (a diamond
/// dependency) collapses to one set of top-level declarations instead of
/// producing mutually-incompatible duplicates.
pub fn resolve(module: Module, root_path: &Path) -> Result<(Module, Vec<(String, String)>), Vec<Diagnostic>> {
    let mut loading = HashSet::new();
    // Best-effort: if the root file exists on disk, seed the cycle guard
    // with its own canonical path so an import chain that loops back to the
    // root is caught too, not just cycles among nested imports. Root
    // modules parsed from an in-memory string with no backing file (as in
    // most unit tests) simply skip this -- they can still import real files,
    // they just can't be re-imported by them.
    let root_canonical = root_path.canonicalize().ok();
    if let Some(canon) = &root_canonical {
        loading.insert(canon.clone());
    }
    let base_dir = root_path.parent().unwrap_or_else(|| Path::new(".")).to_path_buf();
    let mut files = Vec::new();
    let (resolved, provenance) =
        resolve_inner(module, &base_dir, root_canonical.as_deref(), &mut loading, &mut files, 0)?;
    Ok((dedupe_by_origin(resolved, &provenance), files))
}

/// Resolve every `import` in `module`, returning the flattened module
/// alongside its [`ItemProvenance`] (aligned 1:1, by position, with the
/// returned module's `items`). A name introduced by an `import` inherits
/// its child item's provenance unchanged (renaming never changes what file
/// something came from -- `rename_module` preserves item count and order);
/// an item declared directly in this module is tagged with `own_path` (this
/// file's own canonical path, if known -- always known for a real imported
/// file, only possibly unknown for an in-memory root module with no backing
/// path, in which case it's tagged `None`, meaning "never deduplicate this
/// item").
fn resolve_inner(
    module: Module,
    base_dir: &Path,
    own_path: Option<&Path>,
    loading: &mut HashSet<PathBuf>,
    files: &mut Vec<(String, String)>,
    depth: u32,
) -> Result<(Module, ItemProvenance), Vec<Diagnostic>> {
    let mut items = Vec::new();
    let mut provenance: ItemProvenance = Vec::new();
    for item in module.items {
        match item {
            Item::Import(decl) => {
                if depth >= MAX_IMPORT_DEPTH {
                    return Err(vec![Diagnostic::error(
                        format!(
                            "import chain nests too deeply while importing `{}` (over {} levels) -- likely a runaway generated chain of imports",
                            decl.path, MAX_IMPORT_DEPTH
                        ),
                        decl.span,
                    )]);
                }
                let resolved_path = base_dir.join(&decl.path);
                let canonical = match resolved_path.canonicalize() {
                    Ok(p) => p,
                    Err(e) => {
                        return Err(vec![Diagnostic::error(
                            format!("cannot import `{}`: {}", decl.path, e),
                            decl.span,
                        )]);
                    }
                };
                if !loading.insert(canonical.clone()) {
                    return Err(vec![Diagnostic::error(
                        format!("import cycle detected while importing `{}`", decl.path),
                        decl.span,
                    )]);
                }
                let source = match std::fs::read_to_string(&resolved_path) {
                    Ok(s) => s,
                    Err(e) => {
                        return Err(vec![Diagnostic::error(
                            format!("cannot read import `{}`: {}", decl.path, e),
                            decl.span,
                        )]);
                    }
                };
                // Allocate this file's id *before* parsing it, so every span
                // its own AST carries (and, recursively, any span from a
                // file *it* imports) is stamped with the right id from the
                // moment it's lexed -- see `Span::file_id`'s doc comment.
                // `files.len() as u32 + 1` since `file_id == 0` is reserved
                // for the root file (never itself entered into `files`).
                let file_id = files.len() as u32 + 1;
                files.push((decl.path.clone(), source.clone()));
                let imported = match Parser::parse_source_with_file(&source, file_id) {
                    Ok(m) => m,
                    Err(diags) => {
                        let msg = diags.first().map(|d| d.message.clone()).unwrap_or_else(|| "parse error".into());
                        return Err(vec![Diagnostic::error(
                            format!("failed to parse import `{}`: {}", decl.path, msg),
                            decl.span,
                        )]);
                    }
                };
                // Resolve the imported file's own imports (if any) before
                // renaming, so a transitive import chain flattens correctly
                // (see the module-level doc comment on the reach limit this
                // implies).
                let child_base = canonical.parent().unwrap_or_else(|| Path::new(".")).to_path_buf();
                let (resolved_child, child_provenance) =
                    match resolve_inner(imported, &child_base, Some(&canonical), loading, files, depth + 1) {
                        Ok(m) => m,
                        Err(diags) => {
                            // Re-anchor on this level's own (meaningful) span
                            // rather than propagating a span from the nested
                            // file's own source, which would be nonsensical
                            // rendered against this file's text.
                            let msg = diags.first().map(|d| d.message.clone()).unwrap_or_else(|| "error".into());
                            return Err(vec![Diagnostic::error(
                                format!("error in import `{}`: {}", decl.path, msg),
                                decl.span,
                            )]);
                        }
                    };
                loading.remove(&canonical);
                let names = collect_names(&resolved_child, &decl.alias);
                let renamed = rename_module(&resolved_child, &names);
                // `rename_module`/`rename_item` map each input item to
                // exactly one output item, in order -- so `child_provenance`
                // (aligned with `resolved_child.items`) is still aligned
                // with `renamed.items` and can be carried through unchanged.
                debug_assert_eq!(renamed.items.len(), child_provenance.len());
                items.extend(renamed.items);
                provenance.extend(child_provenance);
            }
            other => {
                let prov = match (item_top_level_name(&other), own_path) {
                    (Some(name), Some(path)) => Some((path.to_path_buf(), name.to_string())),
                    _ => None,
                };
                provenance.push(prov);
                items.push(other);
            }
        }
    }
    Ok((Module { items }, provenance))
}

/// The name a top-level [`Item`] declares (if any) -- mirrors
/// [`collect_names`]'s match arms; kept as a standalone helper since both
/// `collect_names` and the provenance/dedup machinery need exactly this set.
fn item_top_level_name(item: &Item) -> Option<&str> {
    match item {
        Item::Struct(s) => Some(&s.name),
        Item::Trait(t) => Some(&t.name),
        Item::Fn(f) => Some(&f.sig.name),
        Item::Arena(a) => Some(&a.name),
        Item::Sequence(s) => Some(&s.name),
        Item::Enum(e) => Some(&e.name),
        Item::Impl(_) | Item::Import(_) | Item::ExternFn(_) => None,
    }
}

/// Collapse top-level items that ultimately originated from the very same
/// declaration in the very same source file, but were independently
/// resolved (and thus differently mangled) because more than one alias
/// chain reached that file -- the diamond-dependency case
/// `projects/snake/NOTES.md` section 1.1 documents: `main` importing both
/// `A` and `B`, each of which independently imports `grid.star`, previously
/// produced two distinct, mutually-incompatible mangled `Cell` types
/// (`a__grid__Cell`, `b__grid__Cell`) for grid.star's one and only `Cell`.
///
/// For every group of items sharing the same `(canonical path, original
/// name)` provenance (see [`ItemProvenance`] for why this is tracked
/// positionally, not by name), the first-declared item (in the flattened
/// module's own item order, which mirrors first-encountered import order)
/// is kept as canonical; every other item in the group is dropped and every
/// remaining reference to its name rewritten to the canonical item's name --
/// reusing the exact same substitution machinery (`rename_item` et al.)
/// that alias-mangling itself uses, just with a name->name substitution
/// instead of a name->`alias__name` one. `impl` blocks (which declare no
/// name of their own -- see [`item_top_level_name`]) are deduplicated too:
/// once two `impl` blocks' `type_name`s substitute to the same canonical
/// type, they are, by construction, independent re-resolutions of the very
/// same source `impl` block, so only the first is kept (the checker/LLVM
/// would otherwise see the same method defined twice for one type).
fn dedupe_by_origin(module: Module, provenance: &ItemProvenance) -> Module {
    debug_assert_eq!(module.items.len(), provenance.len());
    let mut groups: HashMap<&(PathBuf, String), Vec<usize>> = HashMap::new();
    for (idx, prov) in provenance.iter().enumerate() {
        if let Some(key) = prov {
            groups.entry(key).or_default().push(idx);
        }
    }

    let mut subst: HashMap<String, String> = HashMap::new();
    let mut drop: HashSet<usize> = HashSet::new();
    for indices in groups.values() {
        if indices.len() > 1 {
            let canonical_name = item_top_level_name(&module.items[indices[0]]).map(|s| s.to_string());
            for &dup_idx in &indices[1..] {
                if let (Some(canonical_name), Some(dup_name)) = (&canonical_name, item_top_level_name(&module.items[dup_idx])) {
                    subst.insert(dup_name.to_string(), canonical_name.clone());
                }
                drop.insert(dup_idx);
            }
        }
    }

    if drop.is_empty() {
        return module;
    }

    let mut seen_impls: HashSet<(Option<String>, String)> = HashSet::new();
    let items = module
        .items
        .into_iter()
        .enumerate()
        .filter(|(idx, _)| !drop.contains(idx))
        .map(|(_, item)| rename_item(&item, &subst))
        .filter(|item| match item {
            Item::Impl(blk) => seen_impls.insert((blk.trait_name.clone(), blk.type_name.clone())),
            _ => true,
        })
        .collect();
    Module { items }
}

// --- renaming: prefix every top-level declaration with `alias__` ----------

/// Collect the mangled name for every top-level declaration in `module`
/// (structs, enums, traits, functions, arenas, sequences -- everything that
/// can be the target of an `alias::name` reference). Impl blocks don't
/// declare a new name of their own, and method names live in a separate
/// namespace reached only through `.method(...)` field syntax, so neither
/// contributes an entry here.
fn collect_names(module: &Module, alias: &str) -> HashMap<String, String> {
    let mut names = HashMap::new();
    for item in &module.items {
        // An `extern "C" fn` names a real, global C symbol -- it must never
        // be mangled the way ordinary top-level declarations are, or the
        // emitted `declare`/`call` would no longer match the actual foreign
        // symbol. `Item::Impl`/`Item::Import` are excluded for a different
        // reason (see `item_top_level_name`: an impl introduces no fresh
        // top-level name, and imports are already stripped by this point).
        let Some(name) = item_top_level_name(item) else { continue };
        names.insert(name.to_string(), mangle_name(alias, name));
    }
    names
}

fn mangled(name: &str, names: &HashMap<String, String>) -> String {
    names.get(name).cloned().unwrap_or_else(|| name.to_string())
}

/// Rename every top-level declaration in `module` (and every reference to
/// one within it) according to `names` (a map from each declaration's
/// current name to its new one, e.g. from [`collect_names`]'s `alias__name`
/// mangling, or from [`dedupe_by_origin`]'s duplicate->canonical
/// substitution).
///
/// Known limitation shared with `crate::sequence`'s hoisting rewrite: this
/// matches purely on identifier text, so a local variable that happens to
/// share a name with one of the module's own top-level declarations would
/// also get rewritten. Not a concern in practice since Star's naming
/// convention already separates PascalCase types from snake_case values/fns,
/// but a real name-resolution pass would need to track scopes properly.
fn rename_module(module: &Module, names: &HashMap<String, String>) -> Module {
    let items = module.items.iter().map(|item| rename_item(item, names)).collect();
    Module { items }
}

fn rename_item(item: &Item, names: &HashMap<String, String>) -> Item {
    match item {
        Item::Struct(s) => Item::Struct(StructDef {
            name: mangled(&s.name, names),
            type_params: s.type_params.clone(),
            fields: s.fields.iter().map(|f| rename_field(f, names)).collect(),
            span: s.span,
        }),
        Item::Trait(t) => Item::Trait(TraitDef {
            name: mangled(&t.name, names),
            methods: t.methods.iter().map(|sig| rename_fn_sig(sig, names)).collect(),
            span: t.span,
        }),
        Item::Impl(blk) => Item::Impl(ImplBlock {
            trait_name: blk.trait_name.as_ref().map(|n| mangled(n, names)),
            type_name: mangled(&blk.type_name, names),
            // Method names are reached via `.method(...)` field syntax, not
            // as bare identifiers, so they're never mangled -- only their
            // bodies/signatures need renaming for references to *other*
            // top-level declarations.
            methods: blk.methods.iter().map(|f| rename_fn(f, names, false)).collect(),
            span: blk.span,
        }),
        Item::Fn(f) => Item::Fn(rename_fn(f, names, true)),
        Item::Arena(a) => Item::Arena(ArenaDecl {
            name: mangled(&a.name, names),
            ty: rename_type(&a.ty, names),
            capacity: a.capacity,
            span: a.span,
        }),
        Item::Sequence(s) => Item::Sequence(SequenceDef {
            name: mangled(&s.name, names),
            params: s.params.iter().map(|p| rename_param(p, names)).collect(),
            body: rename_block(&s.body, names),
            span: s.span,
        }),
        Item::Enum(e) => Item::Enum(EnumDef {
            name: mangled(&e.name, names),
            type_params: e.type_params.clone(),
            variants: e
                .variants
                .iter()
                .map(|v| EnumVariantDef {
                    name: v.name.clone(),
                    fields: v
                        .fields
                        .iter()
                        .map(|f| EnumFieldDef { name: f.name.clone(), ty: rename_type(&f.ty, names) })
                        .collect(),
                    span: v.span,
                })
                .collect(),
            span: e.span,
        }),
        // Never present: `resolve_inner` only ever passes already-import-free
        // modules to `rename_module`.
        Item::Import(imp) => Item::Import(imp.clone()),
        // Passed through unchanged -- see `collect_names`'s `Item::ExternFn`
        // exclusion for why the C symbol name is never mangled.
        Item::ExternFn(e) => Item::ExternFn(e.clone()),
    }
}

fn rename_field(f: &FieldDef, names: &HashMap<String, String>) -> FieldDef {
    FieldDef {
        is_mut: f.is_mut,
        name: f.name.clone(),
        ty: rename_type(&f.ty, names),
        default: f.default.as_ref().map(|e| rename_expr(e, names)),
        decorators: f.decorators.clone(),
        span: f.span,
    }
}

fn rename_type(ty: &Type, names: &HashMap<String, String>) -> Type {
    match ty {
        Type::Named(n) => Type::Named(mangled(n, names)),
        Type::Generic(n, args) => {
            Type::Generic(mangled(n, names), args.iter().map(|a| rename_type(a, names)).collect())
        }
        Type::Fn(params, ret) => {
            Type::Fn(params.iter().map(|p| rename_type(p, names)).collect(), Box::new(rename_type(ret, names)))
        }
        Type::Tuple(elems) => Type::Tuple(elems.iter().map(|e| rename_type(e, names)).collect()),
        Type::Array(elem, count) => Type::Array(Box::new(rename_type(elem, names)), *count),
        Type::Ring(elem, count) => Type::Ring(Box::new(rename_type(elem, names)), *count),
        // `Bits`/`Frac` are bare integer literals, no name to rename.
        Type::Fixed(bits, frac) => Type::Fixed(*bits, *frac),
        // `N` is a bare integer literal, no name to rename.
        Type::BitField(bits) => Type::BitField(*bits),
    }
}

fn rename_param(p: &Param, names: &HashMap<String, String>) -> Param {
    Param { is_self: p.is_self, is_mut: p.is_mut, name: p.name.clone(), ty: p.ty.as_ref().map(|t| rename_type(t, names)), span: p.span }
}

fn rename_fn_sig(sig: &FnSig, names: &HashMap<String, String>) -> FnSig {
    FnSig {
        // Trait method signatures declare a method name, not a top-level
        // symbol; never mangled (mirrors `rename_fn`'s `mangle_name: false`).
        name: sig.name.clone(),
        type_params: sig.type_params.clone(),
        params: sig.params.iter().map(|p| rename_param(p, names)).collect(),
        ret: sig.ret.as_ref().map(|t| rename_type(t, names)),
        span: sig.span,
    }
}

fn rename_fn(f: &FnDef, names: &HashMap<String, String>, mangle_own_name: bool) -> FnDef {
    FnDef {
        sig: FnSig {
            name: if mangle_own_name { mangled(&f.sig.name, names) } else { f.sig.name.clone() },
            type_params: f.sig.type_params.clone(),
            params: f.sig.params.iter().map(|p| rename_param(p, names)).collect(),
            ret: f.sig.ret.as_ref().map(|t| rename_type(t, names)),
            span: f.sig.span,
        },
        body: rename_block(&f.body, names),
        span: f.span,
    }
}

fn rename_block(block: &Block, names: &HashMap<String, String>) -> Block {
    Block { stmts: block.stmts.iter().map(|s| rename_stmt(s, names)).collect(), span: block.span }
}

fn rename_stmt(stmt: &Stmt, names: &HashMap<String, String>) -> Stmt {
    match stmt {
        Stmt::Let { is_mut, name, ty, value, span } => Stmt::Let {
            is_mut: *is_mut,
            name: name.clone(),
            ty: ty.as_ref().map(|t| rename_type(t, names)),
            value: rename_expr(value, names),
            span: *span,
        },
        Stmt::Assign { target, op, value, span } => {
            Stmt::Assign { target: rename_expr(target, names), op: *op, value: rename_expr(value, names), span: *span }
        }
        Stmt::Return { value, span } => Stmt::Return { value: value.as_ref().map(|v| rename_expr(v, names)), span: *span },
        Stmt::Expr(e) => Stmt::Expr(rename_expr(e, names)),
        Stmt::If { cond, then_block, else_block, span } => Stmt::If {
            cond: rename_expr(cond, names),
            then_block: rename_block(then_block, names),
            else_block: else_block.as_ref().map(|b| rename_block(b, names)),
            span: *span,
        },
        Stmt::While { cond, body, else_block, span } => Stmt::While {
            cond: rename_expr(cond, names),
            body: rename_block(body, names),
            else_block: else_block.as_ref().map(|b| rename_block(b, names)),
            span: *span,
        },
        Stmt::For { var, start, end, body, span } => Stmt::For {
            var: var.clone(),
            start: rename_expr(start, names),
            end: rename_expr(end, names),
            body: rename_block(body, names),
            span: *span,
        },
        Stmt::Break { span } => Stmt::Break { span: *span },
        Stmt::Continue { span } => Stmt::Continue { span: *span },
        Stmt::Frame { body, span } => Stmt::Frame { body: rename_block(body, names), span: *span },
        Stmt::Par { var, arena, body, span } => {
            Stmt::Par { var: var.clone(), arena: mangled(arena, names), body: rename_block(body, names), span: *span }
        }
        Stmt::Each { var, index_var, arena, body, span } => Stmt::Each {
            var: var.clone(),
            index_var: index_var.clone(),
            arena: mangled(arena, names),
            body: rename_block(body, names),
            span: *span,
        },
        Stmt::Yield { span } => Stmt::Yield { span: *span },
        Stmt::Spawn { arena, args, arg_names, span } => Stmt::Spawn {
            arena: mangled(arena, names),
            args: args.iter().map(|a| rename_expr(a, names)).collect(),
            arg_names: arg_names.clone(),
            span: *span,
        },
        Stmt::Despawn { arena, index, span } => {
            Stmt::Despawn { arena: mangled(arena, names), index: rename_expr(index, names), span: *span }
        }
    }
}

fn rename_pattern(pattern: &Pattern, names: &HashMap<String, String>) -> Pattern {
    match pattern {
        Pattern::Wildcard => Pattern::Wildcard,
        Pattern::Int(v) => Pattern::Int(*v),
        Pattern::Bool(v) => Pattern::Bool(*v),
        Pattern::Compare(op, e) => Pattern::Compare(*op, Box::new(rename_expr(e, names))),
        Pattern::Binding(n) => Pattern::Binding(n.clone()),
        Pattern::EnumVariant(enum_name, variant, bindings) => {
            Pattern::EnumVariant(mangled(enum_name, names), variant.clone(), bindings.clone())
        }
        Pattern::Struct(name, bindings) => Pattern::Struct(mangled(name, names), bindings.clone()),
    }
}

fn rename_expr(expr: &Expr, names: &HashMap<String, String>) -> Expr {
    match expr {
        Expr::Int(v, s) => Expr::Int(*v, *s),
        Expr::Float(v, s) => Expr::Float(*v, *s),
        Expr::Str(v, s) => Expr::Str(v.clone(), *s),
        Expr::Bool(v, s) => Expr::Bool(*v, *s),
        Expr::Char(v, s) => Expr::Char(*v, *s),
        Expr::FStr(parts, s) => Expr::FStr(
            parts
                .iter()
                .map(|p| match p {
                    FStrExpr::Literal(l) => FStrExpr::Literal(l.clone()),
                    FStrExpr::Expr(e) => FStrExpr::Expr(Box::new(rename_expr(e, names))),
                })
                .collect(),
            *s,
        ),
        Expr::Ident(name, s) => Expr::Ident(mangled(name, names), *s),
        Expr::SelfExpr(s) => Expr::SelfExpr(*s),
        Expr::Field { base, field, span } => {
            Expr::Field { base: Box::new(rename_expr(base, names)), field: field.clone(), span: *span }
        }
        Expr::Call { callee, args, arg_names, span } => Expr::Call {
            callee: Box::new(rename_expr(callee, names)),
            args: args.iter().map(|a| rename_expr(a, names)).collect(),
            arg_names: arg_names.clone(),
            span: *span,
        },
        Expr::Binary { op, lhs, rhs, span } => Expr::Binary {
            op: *op,
            lhs: Box::new(rename_expr(lhs, names)),
            rhs: Box::new(rename_expr(rhs, names)),
            span: *span,
        },
        Expr::Unary { op, operand, span } => Expr::Unary { op: *op, operand: Box::new(rename_expr(operand, names)), span: *span },
        Expr::Match { scrutinee, arms, span } => Expr::Match {
            scrutinee: Box::new(rename_expr(scrutinee, names)),
            arms: arms
                .iter()
                .map(|a| MatchArm { pattern: rename_pattern(&a.pattern, names), body: rename_block(&a.body, names), span: a.span })
                .collect(),
            span: *span,
        },
        Expr::StructLit { name, type_args, args, arg_names, span } => Expr::StructLit {
            name: mangled(name, names),
            type_args: type_args.iter().map(|t| rename_type(t, names)).collect(),
            args: args.iter().map(|a| rename_expr(a, names)).collect(),
            arg_names: arg_names.clone(),
            span: *span,
        },
        Expr::If { cond, then_block, else_block, span } => Expr::If {
            cond: Box::new(rename_expr(cond, names)),
            then_block: rename_block(then_block, names),
            else_block: else_block.as_ref().map(|b| rename_block(b, names)),
            span: *span,
        },
        Expr::GenRefCreate { inner_ty, value, is_handle, span } => Expr::GenRefCreate {
            inner_ty: rename_type(inner_ty, names),
            value: Box::new(rename_expr(value, names)),
            is_handle: *is_handle,
            span: *span,
        },
        Expr::GenRefIndex { base, index, span } => {
            Expr::GenRefIndex { base: Box::new(rename_expr(base, names)), index: Box::new(rename_expr(index, names)), span: *span }
        }
        Expr::EnumVariant { enum_name, type_args, variant, args, arg_names, span } => Expr::EnumVariant {
            enum_name: mangled(enum_name, names),
            type_args: type_args.iter().map(|t| rename_type(t, names)).collect(),
            variant: variant.clone(),
            args: args.iter().map(|a| rename_expr(a, names)).collect(),
            arg_names: arg_names.clone(),
            span: *span,
        },
        Expr::Lambda { params, ret, body, span } => Expr::Lambda {
            params: params.iter().map(|p| rename_param(p, names)).collect(),
            ret: ret.as_ref().map(|t| rename_type(t, names)),
            body: rename_block(body, names),
            span: *span,
        },
        Expr::ListLit(elems, span) => Expr::ListLit(elems.iter().map(|e| rename_expr(e, names)).collect(), *span),
        Expr::Try { inner, span } => Expr::Try { inner: Box::new(rename_expr(inner, names)), span: *span },
        Expr::TupleLit(elems, span) => Expr::TupleLit(elems.iter().map(|e| rename_expr(e, names)).collect(), *span),
        Expr::TupleIndex { base, index, span } => {
            Expr::TupleIndex { base: Box::new(rename_expr(base, names)), index: *index, span: *span }
        }
        Expr::ArrayRepeat { value, count, span } => {
            Expr::ArrayRepeat { value: Box::new(rename_expr(value, names)), count: *count, span: *span }
        }
        Expr::RingNew { elem_ty, count, span } => {
            Expr::RingNew { elem_ty: rename_type(elem_ty, names), count: *count, span: *span }
        }
        Expr::Cast { expr, ty, span } => {
            Expr::Cast { expr: Box::new(rename_expr(expr, names)), ty: rename_type(ty, names), span: *span }
        }
        Expr::WrappingNew { inner_ty, value, span } => Expr::WrappingNew {
            inner_ty: rename_type(inner_ty, names),
            value: Box::new(rename_expr(value, names)),
            span: *span,
        },
        Expr::FixedNew { bits, frac, value, span } => {
            Expr::FixedNew { bits: *bits, frac: *frac, value: Box::new(rename_expr(value, names)), span: *span }
        }
        Expr::BitFieldNew { bits, value, span } => {
            Expr::BitFieldNew { bits: *bits, value: Box::new(rename_expr(value, names)), span: *span }
        }
        Expr::Spawn { arena, args, arg_names, span } => Expr::Spawn {
            arena: mangled(arena, names),
            args: args.iter().map(|a| rename_expr(a, names)).collect(),
            arg_names: arg_names.clone(),
            span: *span,
        },
    }
}

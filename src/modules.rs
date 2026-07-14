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
//! other files), with a cycle guard over canonicalized paths. Note this only
//! supports *direct* imports: if module `a` imports `b`, which imports `c`,
//! `a` cannot reach `c`'s items through `b` (there is no re-export syntax) --
//! `b`'s own `c::foo` references are mangled to `c__foo` as part of
//! resolving `b` in isolation, and then *that* identifier gets swept up in
//! `b`'s own `alias__` prefixing when `a` imports `b`, landing on
//! `b__c__foo` rather than anything `a` could address directly.

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

/// Resolve every `import` in `module` (whose own source lives at
/// `root_path`), recursively inlining each imported file's items under a
/// mangled name. Returns a module with no `Item::Import` entries left.
pub fn resolve(module: Module, root_path: &Path) -> Result<Module, Vec<Diagnostic>> {
    let mut loading = HashSet::new();
    // Best-effort: if the root file exists on disk, seed the cycle guard
    // with its own canonical path so an import chain that loops back to the
    // root is caught too, not just cycles among nested imports. Root
    // modules parsed from an in-memory string with no backing file (as in
    // most unit tests) simply skip this -- they can still import real files,
    // they just can't be re-imported by them.
    if let Ok(canon) = root_path.canonicalize() {
        loading.insert(canon);
    }
    let base_dir = root_path.parent().unwrap_or_else(|| Path::new(".")).to_path_buf();
    resolve_inner(module, &base_dir, &mut loading)
}

fn resolve_inner(module: Module, base_dir: &Path, loading: &mut HashSet<PathBuf>) -> Result<Module, Vec<Diagnostic>> {
    let mut items = Vec::new();
    for item in module.items {
        match item {
            Item::Import(decl) => {
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
                let imported = match Parser::parse_source(&source) {
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
                let resolved_child = match resolve_inner(imported, &child_base, loading) {
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
                let renamed = rename_module(&resolved_child, &decl.alias);
                items.extend(renamed.items);
            }
            other => items.push(other),
        }
    }
    Ok(Module { items })
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
        let name = match item {
            Item::Struct(s) => &s.name,
            Item::Trait(t) => &t.name,
            Item::Fn(f) => &f.sig.name,
            Item::Arena(a) => &a.name,
            Item::Sequence(s) => &s.name,
            Item::Enum(e) => &e.name,
            // An `extern "C" fn` names a real, global C symbol -- it must
            // never be mangled the way ordinary top-level declarations are,
            // or the emitted `declare`/`call` would no longer match the
            // actual foreign symbol. `Item::Impl`/`Item::Import` are
            // excluded for a different reason (see their own comments
            // elsewhere in this file: an impl introduces no fresh top-level
            // name, and imports are already stripped by this point).
            Item::Impl(_) | Item::Import(_) | Item::ExternFn(_) => continue,
        };
        names.insert(name.clone(), mangle_name(alias, name));
    }
    names
}

fn mangled(name: &str, names: &HashMap<String, String>) -> String {
    names.get(name).cloned().unwrap_or_else(|| name.to_string())
}

/// Rename every top-level declaration in `module` (and every reference to
/// one within it) to its `alias__name` mangled form.
///
/// Known limitation shared with `crate::sequence`'s hoisting rewrite: this
/// matches purely on identifier text, so a local variable that happens to
/// share a name with one of the module's own top-level declarations would
/// also get rewritten. Not a concern in practice since Star's naming
/// convention already separates PascalCase types from snake_case values/fns,
/// but a real name-resolution pass would need to track scopes properly.
fn rename_module(module: &Module, alias: &str) -> Module {
    let names = collect_names(module, alias);
    let items = module.items.iter().map(|item| rename_item(item, &names)).collect();
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
        Item::Arena(a) => {
            Item::Arena(ArenaDecl { name: mangled(&a.name, names), ty: rename_type(&a.ty, names), span: a.span })
        }
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
        Stmt::Yield { span } => Stmt::Yield { span: *span },
        Stmt::Spawn { arena, args, span } => Stmt::Spawn {
            arena: mangled(arena, names),
            args: args.iter().map(|a| rename_expr(a, names)).collect(),
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
        Expr::Call { callee, args, span } => Expr::Call {
            callee: Box::new(rename_expr(callee, names)),
            args: args.iter().map(|a| rename_expr(a, names)).collect(),
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
        Expr::StructLit { name, type_args, args, span } => Expr::StructLit {
            name: mangled(name, names),
            type_args: type_args.iter().map(|t| rename_type(t, names)).collect(),
            args: args.iter().map(|a| rename_expr(a, names)).collect(),
            span: *span,
        },
        Expr::If { cond, then_block, else_block, span } => Expr::If {
            cond: Box::new(rename_expr(cond, names)),
            then_block: rename_block(then_block, names),
            else_block: else_block.as_ref().map(|b| rename_block(b, names)),
            span: *span,
        },
        Expr::GenRefCreate { inner_ty, value, span } => {
            Expr::GenRefCreate { inner_ty: rename_type(inner_ty, names), value: Box::new(rename_expr(value, names)), span: *span }
        }
        Expr::GenRefIndex { base, index, span } => {
            Expr::GenRefIndex { base: Box::new(rename_expr(base, names)), index: Box::new(rename_expr(index, names)), span: *span }
        }
        Expr::EnumVariant { enum_name, type_args, variant, args, span } => Expr::EnumVariant {
            enum_name: mangled(enum_name, names),
            type_args: type_args.iter().map(|t| rename_type(t, names)).collect(),
            variant: variant.clone(),
            args: args.iter().map(|a| rename_expr(a, names)).collect(),
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
    }
}

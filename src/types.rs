//! Name and type resolution for Star.
//!
//! The checker performs Hindley-Milner-style inference with explicit type
//! annotations where required (struct fields, parameters, return types). Every
//! expression is given an inferred [`Ty`] after resolution.

use crate::ast::*;
use crate::diagnostics::{suggest, Diagnostic, Span};
use std::collections::{HashMap, HashSet};

/// A resolved type.
#[derive(Clone, Debug, PartialEq)]
pub enum Ty {
    Int,
    Float,
    Str,
    Bool,
    Vec2,
    Vec3,
    Vec4,
    Mat4,
    Named(String),
    /// A generational reference backed by a slot-map: GenRef<T>.
    GenRef(Box<Ty>),
}

impl Ty {
    /// True for the builtin SIMD vector types (Vec2/Vec3/Vec4).
    pub fn is_vec(&self) -> bool {
        matches!(self, Ty::Vec2 | Ty::Vec3 | Ty::Vec4)
    }

    /// True for the builtin SIMD matrix type (Mat4).
    pub fn is_mat(&self) -> bool {
        matches!(self, Ty::Mat4)
    }

    /// The component count of a builtin vector type, or `None` for anything else.
    pub fn vec_arity(&self) -> Option<u8> {
        match self {
            Ty::Vec2 => Some(2),
            Ty::Vec3 => Some(3),
            Ty::Vec4 => Some(4),
            _ => None,
        }
    }

    /// The vector type with the given component count (1 -> scalar Float).
    pub fn vec_of_arity(n: u8) -> Option<Ty> {
        match n {
            1 => Some(Ty::Float),
            2 => Some(Ty::Vec2),
            3 => Some(Ty::Vec3),
            4 => Some(Ty::Vec4),
            _ => None,
        }
    }
}

/// Names and return-type rules for the compiler's built-in standard library
/// (see `crate::codegen` for their lowering). These aren't declared by any
/// `fn` item, so the checker special-cases them instead of consulting the
/// user-defined function table. Returns `None` for anything that isn't a
/// recognized builtin name, so ordinary user functions/methods fall through
/// to the normal lookup unaffected.
fn builtin_return_ty(name: &str, args: &[TypedExpr]) -> Option<Ty> {
    match name {
        // No return value; `Ty::Named("unknown")` is the established
        // convention codegen already treats as a `void` call (see
        // `crate::codegen::Codegen::emit_expr`'s `TypedExpr::Call` arm).
        "print" | "println" => Some(Ty::Named("unknown".into())),
        "sqrt" | "pow" | "floor" | "ceil" => Some(Ty::Float),
        // `abs`/`min`/`max` preserve the numeric type (Int or Float) of
        // their first argument rather than always widening to Float.
        "abs" | "min" | "max" => Some(args.first().map(|a| a.clone().into_ty()).unwrap_or(Ty::Float)),
        "len" => Some(Ty::Int),
        "concat" => Some(Ty::Str),
        _ => None,
    }
}

/// The error type for type checking.
#[derive(Clone, Debug)]
pub struct TypeError {
    pub message: String,
    pub span: Span,
    /// An optional "did you mean `x`?" style hint.
    pub note: Option<String>,
}

/// The checker holds symbol tables and the current error list.
pub struct Checker {
    structs: HashMap<String, StructDef>,
    traits: HashMap<String, TraitDef>,
    arenas: HashMap<String, Ty>,
    /// Function signatures: maps function name -> (param_tys, ret_ty)
    functions: HashMap<String, (Vec<Ty>, Option<Ty>)>,
    errors: Vec<TypeError>,
}

impl Checker {
    pub fn new() -> Self {
        Self {
            structs: HashMap::new(),
            traits: HashMap::new(),
            arenas: HashMap::new(),
            functions: HashMap::new(),
            errors: Vec::new(),
        }
    }

    pub fn check(&mut self, module: &Module) -> Result<TypedModule, Vec<Diagnostic>> {
        // `sequence` items are pure syntax sugar over struct+impl (see
        // `crate::sequence`); desugar them before any of the checks below
        // ever see an `Item::Sequence`.
        let (module, desugar_errors) = crate::sequence::desugar_module(module);
        if !desugar_errors.is_empty() {
            return Err(desugar_errors);
        }

        // First pass: collect all declarations
        for item in &module.items {
            match item {
                Item::Struct(s) => { self.structs.insert(s.name.clone(), s.clone()); }
                Item::Trait(t) => { self.traits.insert(t.name.clone(), t.clone()); }
                Item::Arena(a) => {
                    let ty = self.resolve_type(&a.ty).unwrap_or(Ty::Named("unknown".into()));
                    self.arenas.insert(a.name.clone(), ty);
                }
                Item::Fn(f) => {
                    let param_tys: Vec<Ty> = f.sig.params.iter().map(|p| {
                        p.ty.as_ref().and_then(|t| self.resolve_type(t)).unwrap_or(Ty::Named("infer".into()))
                    }).collect();
                    let ret_ty = f.sig.ret.as_ref().and_then(|t| self.resolve_type(t));
                    self.functions.insert(f.sig.name.clone(), (param_tys, ret_ty));
                }
                Item::Impl(blk) => {
                    for m in &blk.methods {
                        let param_tys: Vec<Ty> = m.sig.params.iter().map(|p| {
                            p.ty.as_ref().and_then(|t| self.resolve_type(t)).unwrap_or(Ty::Named("infer".into()))
                        }).collect();
                        let ret_ty = m.sig.ret.as_ref().and_then(|t| self.resolve_type(t));
                        self.functions.insert(m.sig.name.clone(), (param_tys, ret_ty));
                    }
                }
                // Desugared away above; never present past this point.
                Item::Sequence(_) => {}
            }
        }

        let mut typed_items = Vec::new();
        for item in &module.items {
            match self.check_item(item) {
                Some(item) => typed_items.push(item),
                None => {}
            }
        }

        if self.errors.is_empty() {
            Ok(TypedModule { items: typed_items })
        } else {
            Err(self.errors_to_diagnostics())
        }
    }

    fn check_item(&mut self, item: &Item) -> Option<TypedItem> {
        match item {
            Item::Struct(s) => Some(TypedItem::Struct(self.check_struct(s))),
            Item::Trait(t) => Some(TypedItem::Trait(TypedTraitDef {
                name: t.name.clone(),
                methods: t.methods.iter().filter_map(|sig| self.check_fn_sig(sig)).collect(),
                span: t.span,
            })),
            Item::Impl(impl_blk) => {
                let checked = self.check_impl(impl_blk)?;
                Some(TypedItem::Impl(checked))
            }
            Item::Fn(f) => {
                let checked = self.check_fn(f)?;
                Some(TypedItem::Fn(checked))
            }
            Item::Arena(a) => {
                let ty = self.resolve_type(&a.ty).unwrap_or(Ty::Named("unknown".into()));
                // If arena contains GenRef<T>, extract the inner type
                let element_ty = match &a.ty {
                    Type::Generic(name, args) if name == "GenRef" && !args.is_empty() => {
                        self.resolve_type(&args[0]).unwrap_or(Ty::Int)
                    }
                    _ => ty.clone(),
                };
                Some(TypedItem::Arena(TypedArenaDecl {
                    name: a.name.clone(),
                    ty: element_ty,
                    span: a.span,
                }))
            }
            // Desugared away in `check` before this point is ever reached.
            Item::Sequence(_) => None,
        }
    }

    fn check_struct(&mut self, s: &StructDef) -> TypedStructDef {
        TypedStructDef {
            name: s.name.clone(),
            fields: s.fields.iter().map(|f| {
                let resolved = self.resolve_type(&f.ty).unwrap_or(Ty::Named("unknown".into()));
                TypedFieldDef {
                    is_mut: f.is_mut,
                    name: f.name.clone(),
                    ty: resolved,
                    default: f.default.as_ref().map(|e| self.check_expr_infer(e)),
                    decorators: f.decorators.clone(),
                    span: f.span,
                }
            }).collect(),
            span: s.span,
        }
    }

    fn check_impl(&mut self, impl_blk: &ImplBlock) -> Option<TypedImplBlock> {
        if let Some(trait_name) = &impl_blk.trait_name {
            if !self.traits.contains_key(trait_name) {
                let candidates: Vec<&str> = self.traits.keys().map(String::as_str).collect();
                match suggest(trait_name, candidates) {
                    Some(close) => self.error_note(
                        format!("undefined trait `{}`", trait_name),
                        impl_blk.span,
                        format!("did you mean `{}`?", close),
                    ),
                    None => self.error(format!("undefined trait `{}`", trait_name), impl_blk.span),
                }
                return None;
            }
        }
        if !self.structs.contains_key(&impl_blk.type_name) {
            let candidates: Vec<&str> = self.structs.keys().map(String::as_str).collect();
            match suggest(&impl_blk.type_name, candidates) {
                Some(close) => self.error_note(
                    format!("undefined type `{}`", impl_blk.type_name),
                    impl_blk.span,
                    format!("did you mean `{}`?", close),
                ),
                None => self.error(format!("undefined type `{}`", impl_blk.type_name), impl_blk.span),
            }
            return None;
        }
        let struct_ty = Ty::Named(impl_blk.type_name.clone());
        let methods: Vec<TypedFnDef> = impl_blk.methods.iter().filter_map(|m| self.check_fn_with_self_ty(m, &struct_ty)).collect();
        Some(TypedImplBlock {
            trait_name: impl_blk.trait_name.clone(),
            type_name: impl_blk.type_name.clone(),
            methods,
            span: impl_blk.span,
        })
    }

    fn check_fn(&mut self, f: &FnDef) -> Option<TypedFnDef> {
        self.check_fn_with_self_ty(f, &Ty::Named("infer".into()))
    }

    fn check_fn_with_self_ty(&mut self, f: &FnDef, self_ty: &Ty) -> Option<TypedFnDef> {
        let sig = self.check_fn_sig_with_self_ty(&f.sig, self_ty)?;
        let body = self.check_block(&f.body, &sig)?;
        Some(TypedFnDef { sig, body, span: f.span })
    }

    fn check_fn_sig(&self, sig: &FnSig) -> Option<TypedFnSig> {
        self.check_fn_sig_with_self_ty(sig, &Ty::Named("infer".into()))
    }

    fn check_fn_sig_with_self_ty(&self, sig: &FnSig, self_ty: &Ty) -> Option<TypedFnSig> {
        Some(TypedFnSig {
            name: sig.name.clone(),
            params: sig.params.iter().map(|p| self.check_param_with_self_ty(p, self_ty)).collect(),
            ret: sig.ret.as_ref().and_then(|t| self.resolve_type(t)),
            span: sig.span,
        })
    }

    fn check_param_with_self_ty(&self, p: &Param, self_ty: &Ty) -> TypedParam {
        let ty = if p.is_self {
            self_ty.clone()
        } else {
            p.ty.as_ref().and_then(|t| self.resolve_type(t)).unwrap_or(Ty::Named("infer".into()))
        };
        TypedParam {
            is_self: p.is_self,
            is_mut: p.is_mut,
            name: p.name.clone(),
            ty,
            span: p.span,
        }
    }

    fn check_block(&mut self, block: &Block, fn_sig: &TypedFnSig) -> Option<TypedBlock> {
        let mut vars: HashMap<String, Ty> = HashMap::new();
        for p in &fn_sig.params {
            vars.insert(p.name.clone(), p.ty.clone());
        }
        Some(self.check_block_inner(block, &mut vars))
    }

    /// Type-check a block reusing an inherited variable table. Used for nested
    /// `if`/`while` bodies and `else` branches so bindings from the enclosing
    /// scope remain visible.
    fn check_block_inner(&mut self, block: &Block, vars: &mut HashMap<String, Ty>) -> TypedBlock {
        let mut stmts = Vec::new();
        for stmt in &block.stmts {
            if let Some(typed) = self.check_stmt(stmt, vars) {
                stmts.push(typed);
            }
        }
        TypedBlock { stmts, span: block.span }
    }

    fn check_stmt(&mut self, stmt: &Stmt, vars: &mut HashMap<String, Ty>) -> Option<TypedStmt> {
        Some(match stmt {
            Stmt::Let { is_mut, name, ty, value, span } => {
                let value_typed = self.infer_expr(value, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
                let actual_ty: Ty = ty.as_ref().and_then(|t| self.resolve_type(t))
                    .unwrap_or_else(|| value_typed.clone().into_ty());
                vars.insert(name.clone(), actual_ty.clone());
                TypedStmt::Let { is_mut: *is_mut, name: name.clone(), ty: actual_ty, value: value_typed, span: *span }
            }
            Stmt::Assign { target, op, value, span } => {
                let target_typed = self.infer_expr(target, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
                let value_typed = self.infer_expr(value, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
                if let TypedExpr::Field { base, field, .. } = &target_typed {
                    if base.clone().into_ty().is_vec() {
                        let mut seen = HashSet::new();
                        for c in field.chars() {
                            if !seen.insert(c) {
                                self.error(format!("duplicate swizzle component `{}` in write target `.{}`", c, field), *span);
                                break;
                            }
                        }
                    }
                }
                TypedStmt::Assign { target: target_typed, op: *op, value: value_typed, span: *span }
            }
            Stmt::Return { value, span } => {
                let value_typed = value.as_ref().map(|v| self.infer_expr(v, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into()))));
                TypedStmt::Return { value: value_typed, span: *span }
            }
            Stmt::Expr(expr) => TypedStmt::Expr(self.infer_expr(expr, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))),
            Stmt::If { cond, then_block, else_block, span } => {
                let cond_typed = self.infer_expr(cond, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
                if !matches!(cond_typed.clone().into_ty(), Ty::Bool) {
                    self.error("if condition must be of type bool", cond.span());
                }
                let then_typed = self.check_block_inner(then_block, &mut vars.clone());
                let else_typed = else_block.as_ref().map(|b| self.check_block_inner(b, &mut vars.clone()));
                TypedStmt::If { cond: cond_typed, then_block: then_typed, else_block: else_typed, span: *span }
            }
            Stmt::While { cond, body, else_block, span } => {
                let cond_typed = self.infer_expr(cond, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
                if !matches!(cond_typed.clone().into_ty(), Ty::Bool) {
                    self.error("while condition must be of type bool", cond.span());
                }
                let then_typed = self.check_block_inner(body, &mut vars.clone());
                let else_typed = else_block.as_ref().map(|b| self.check_block_inner(b, &mut vars.clone()));
                TypedStmt::While { cond: cond_typed, then_block: then_typed, else_block: else_typed, span: *span }
            }
            Stmt::Frame { body, span } => {
                let body_typed = self.check_block_inner(body, &mut vars.clone());
                TypedStmt::Frame { body: body_typed, span: *span }
            }
            Stmt::Par { var, arena, body, span } => {
                let elem_ty = match self.arenas.get(arena) {
                    Some(t) => t.clone(),
                    None => {
                        self.error(format!("undefined arena `{}`", arena), *span);
                        Ty::Named("unknown".into())
                    }
                };
                let mut inner_vars = vars.clone();
                inner_vars.insert(var.clone(), elem_ty.clone());
                let body_typed = self.check_block_inner(body, &mut inner_vars);
                self.check_par_disjoint(var, &body_typed);
                TypedStmt::Par { var: var.clone(), elem_ty, arena: arena.clone(), body: body_typed, span: *span }
            }
            // Every `yield` inside a `sequence` body is consumed by the
            // desugaring pass in `check()` before this point; one reaching
            // here means it was written outside a `sequence`.
            Stmt::Yield { span } => {
                self.error("`yield` is only valid at the top level of a `sequence` body", *span);
                TypedStmt::Expr(TypedExpr::Error(Ty::Named("void".into())))
            }
            Stmt::Spawn { arena, args, span } => self.check_spawn_stmt(arena, args, vars, *span),
            Stmt::Despawn { arena, index, span } => self.check_despawn_stmt(arena, index, vars, *span),
        })
    }

    /// Type-check `spawn ArenaName(args...)`: resolves the arena's declared
    /// element type, checks it's a struct (the only kind of value an arena
    /// can hold), validates the argument count against the struct's field
    /// list, and packages the constructed element as a `StructLit` so
    /// codegen only has to append it to the arena's backing array.
    fn check_spawn_stmt(&mut self, arena: &str, args: &[Expr], vars: &mut HashMap<String, Ty>, span: Span) -> TypedStmt {
        let elem_ty = match self.arenas.get(arena) {
            Some(t) => t.clone(),
            None => {
                self.error(format!("undefined arena `{}`", arena), span);
                Ty::Named("unknown".into())
            }
        };
        let elem_name = match &elem_ty {
            Ty::Named(n) => n.clone(),
            other => {
                self.error(format!("`spawn` requires an arena of a struct type, but `{}` holds `{:?}`", arena, other), span);
                "unknown".into()
            }
        };
        let arg_exprs: Vec<TypedExpr> = args
            .iter()
            .map(|a| self.infer_expr(a, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into()))))
            .collect();
        if let Some(sdef) = self.structs.get(&elem_name).cloned() {
            if arg_exprs.len() != sdef.fields.len() {
                self.error(
                    format!(
                        "`spawn {}(..)` expects {} argument(s) for `{}`, found {}",
                        arena, sdef.fields.len(), elem_name, arg_exprs.len()
                    ),
                    span,
                );
            }
        } else if elem_name != "unknown" {
            self.error(format!("arena `{}` element type `{}` is not a struct", arena, elem_name), span);
        }
        let elem = TypedExpr::StructLit { name: elem_name, args: arg_exprs, ty: elem_ty, span };
        TypedStmt::Spawn { arena: arena.to_string(), elem, span }
    }

    /// Type-check `despawn ArenaName[index]`: resolves the arena (an error if
    /// undefined) and requires `index` to be an `i32`. No arity/struct
    /// checking needed -- unlike `spawn`, `despawn` doesn't construct a
    /// value, it just bumps a generation counter.
    fn check_despawn_stmt(&mut self, arena: &str, index: &Expr, vars: &mut HashMap<String, Ty>, span: Span) -> TypedStmt {
        if !self.arenas.contains_key(arena) {
            self.error(format!("undefined arena `{}`", arena), span);
        }
        let index_typed = self.infer_expr(index, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
        if !matches!(index_typed.clone().into_ty(), Ty::Int) {
            self.error("`despawn` index must be `i32`", span);
        }
        TypedStmt::Despawn { arena: arena.to_string(), index: index_typed, span }
    }

    /// Arenas whose declared element type is `ty`. Zero means "no backing
    /// arena", more than one means "ambiguous" -- both are errors at any
    /// `GenRef<T>` creation/dereference site (see `require_backing_arena`).
    fn arenas_of_elem_ty(&self, ty: &Ty) -> Vec<&String> {
        self.arenas.iter().filter(|(_, t)| *t == ty).map(|(n, _)| n).collect()
    }

    /// Validate that exactly one arena backs `GenRef<inner_ty>`, emitting a
    /// diagnostic otherwise. Codegen independently re-resolves the arena
    /// name from `inner_ty` (see `Codegen::arena_for_elem_ty`); this check
    /// only exists to turn a missing/ambiguous backing arena into a friendly
    /// type error instead of a defensive codegen-time failure.
    fn require_backing_arena(&mut self, inner_ty: &Ty, span: Span) {
        match self.arenas_of_elem_ty(inner_ty).len() {
            1 => {}
            0 => self.error(
                format!("`GenRef<{:?}>` has no backing arena -- declare `arena Name: {:?}`", inner_ty, inner_ty),
                span,
            ),
            _ => self.error(
                format!("`GenRef<{:?}>` is ambiguous: multiple arenas hold `{:?}`", inner_ty, inner_ty),
                span,
            ),
        }
    }

    // ===== `par`/`swarm` disjoint-access analysis ========================
    //
    // Proves (conservatively) that a `par` body's iterations don't race: the
    // only things a body may *mutate* are the loop variable's own fields and
    // locals it declares itself (both are per-iteration/per-thread, so safe
    // by construction). Any write to a name captured from the enclosing
    // scope — including `self` — is rejected, since concurrent writes to
    // shared state from multiple worker threads would race. Method calls are
    // held to the same standard, since a call `x.foo()` might mutate `x`
    // internally: only calls on the loop variable (or a body-local) are
    // allowed.

    fn check_par_disjoint(&mut self, var: &str, block: &TypedBlock) {
        let mut locals: HashSet<String> = HashSet::new();
        locals.insert(var.to_string());
        self.walk_par_stmts(&block.stmts, &mut locals);
    }

    fn walk_par_stmts(&mut self, stmts: &[TypedStmt], locals: &mut HashSet<String>) {
        for stmt in stmts {
            self.walk_par_stmt(stmt, locals);
        }
    }

    fn walk_par_stmt(&mut self, stmt: &TypedStmt, locals: &mut HashSet<String>) {
        match stmt {
            TypedStmt::Let { name, value, .. } => {
                self.walk_par_expr(value, locals);
                locals.insert(name.clone());
            }
            TypedStmt::Assign { target, value, span, .. } => {
                self.walk_par_expr(value, locals);
                match root_ident(target) {
                    Some(root) if locals.contains(&root) => {}
                    Some(root) => self.error(
                        format!(
                            "par/swarm body may only mutate the loop variable or locals it declares; \
                             write to `{}` cannot be proven disjoint across threads",
                            root
                        ),
                        *span,
                    ),
                    None => self.error("unsupported mutation target in par/swarm body", *span),
                }
            }
            TypedStmt::Return { value, .. } => {
                if let Some(v) = value {
                    self.walk_par_expr(v, locals);
                }
            }
            TypedStmt::Expr(e) => self.walk_par_expr(e, locals),
            TypedStmt::If { cond, then_block, else_block, .. } => {
                self.walk_par_expr(cond, locals);
                let mut l = locals.clone();
                self.walk_par_stmts(&then_block.stmts, &mut l);
                if let Some(e) = else_block {
                    let mut l = locals.clone();
                    self.walk_par_stmts(&e.stmts, &mut l);
                }
            }
            TypedStmt::While { cond, then_block, else_block, .. } => {
                self.walk_par_expr(cond, locals);
                let mut l = locals.clone();
                self.walk_par_stmts(&then_block.stmts, &mut l);
                if let Some(e) = else_block {
                    let mut l = locals.clone();
                    self.walk_par_stmts(&e.stmts, &mut l);
                }
            }
            TypedStmt::Frame { body, .. } => {
                let mut l = locals.clone();
                self.walk_par_stmts(&body.stmts, &mut l);
            }
            TypedStmt::Par { body, .. } => {
                // A nested par loop gets its own fresh disjointness proof;
                // just recurse for any captures it makes of the outer scope.
                let mut l = locals.clone();
                self.walk_par_stmts(&body.stmts, &mut l);
            }
            TypedStmt::Spawn { span, .. } => {
                // Every worker thread would race on the same arena's
                // `count`/`data` globals, so population can't happen from
                // inside a body whose iterations are supposed to be disjoint.
                self.error(
                    "`spawn` cannot be used inside a par/swarm body (arena population is not disjoint across threads)",
                    *span,
                );
            }
            TypedStmt::Despawn { span, .. } => {
                // Same race as `spawn`: every worker thread would contend on
                // the same arena's `gen` global.
                self.error(
                    "`despawn` cannot be used inside a par/swarm body (concurrent generation bumps are not disjoint across threads)",
                    *span,
                );
            }
        }
    }

    fn walk_par_expr(&mut self, expr: &TypedExpr, locals: &HashSet<String>) {
        match expr {
            TypedExpr::Call { callee, args, span, .. } => {
                if let TypedExpr::Field { base, .. } = callee.as_ref() {
                    match root_ident(base) {
                        Some(root) if locals.contains(&root) => {}
                        _ => self.error(
                            "cannot call a method on a captured value inside a par/swarm body \
                             (only the loop variable's own methods may be called)",
                            *span,
                        ),
                    }
                }
                self.walk_par_expr(callee, locals);
                for a in args {
                    self.walk_par_expr(a, locals);
                }
            }
            TypedExpr::Field { base, .. } => self.walk_par_expr(base, locals),
            TypedExpr::Binary { lhs, rhs, .. } => {
                self.walk_par_expr(lhs, locals);
                self.walk_par_expr(rhs, locals);
            }
            TypedExpr::Unary { operand, .. } => self.walk_par_expr(operand, locals),
            TypedExpr::Match { scrutinee, arms, .. } => {
                self.walk_par_expr(scrutinee, locals);
                for arm in arms {
                    let mut l = locals.clone();
                    self.walk_par_stmts(&arm.body.stmts, &mut l);
                }
            }
            TypedExpr::StructLit { args, .. } => {
                for a in args {
                    self.walk_par_expr(a, locals);
                }
            }
            TypedExpr::FStr(parts, ..) => {
                for p in parts {
                    if let TypedFStrExpr::Expr(e) = p {
                        self.walk_par_expr(e, locals);
                    }
                }
            }
            TypedExpr::If { cond, then_block, else_block, .. } => {
                self.walk_par_expr(cond, locals);
                let mut l = locals.clone();
                self.walk_par_stmts(&then_block.stmts, &mut l);
                if let Some(e) = else_block {
                    let mut l = locals.clone();
                    self.walk_par_stmts(&e.stmts, &mut l);
                }
            }
            TypedExpr::GenRefCreate { value, .. } => self.walk_par_expr(value, locals),
            TypedExpr::GenRefIndex { base, index, .. } => {
                self.walk_par_expr(base, locals);
                self.walk_par_expr(index, locals);
            }
            TypedExpr::Int(..)
            | TypedExpr::Float(..)
            | TypedExpr::Str(..)
            | TypedExpr::Bool(..)
            | TypedExpr::Ident { .. }
            | TypedExpr::SelfExpr(..)
            | TypedExpr::Error(_) => {}
        }
    }

    fn check_expr_infer(&mut self, expr: &Expr) -> TypedExpr {
        let mut dummy_vars = HashMap::new();
        self.infer_expr(expr, &mut dummy_vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))
    }

    fn infer_expr(&mut self, expr: &Expr, vars: &mut HashMap<String, Ty>) -> Result<TypedExpr, ()> {
        match expr {
            Expr::Int(v, s) => Ok(TypedExpr::Int(*v, Ty::Int, *s)),
            Expr::Float(v, s) => Ok(TypedExpr::Float(*v, Ty::Float, *s)),
            Expr::Str(s, sp) => Ok(TypedExpr::Str(s.clone(), Ty::Str, *sp)),
            Expr::Bool(v, s) => Ok(TypedExpr::Bool(*v, Ty::Bool, *s)),
            Expr::FStr(parts, s) => {
                let mut typed_parts = Vec::new();
                for part in parts {
                    match part {
                        FStrExpr::Literal(lit) => typed_parts.push(TypedFStrExpr::Literal(lit.clone())),
                        FStrExpr::Expr(e) => {
                            let typed = self.infer_expr(e, vars)?;
                            typed_parts.push(TypedFStrExpr::Expr(Box::new(typed)));
                        }
                    }
                }
                Ok(TypedExpr::FStr(typed_parts, Ty::Str, *s))
            }
            Expr::Ident(name, s) => {
                let ty = vars.get(name).cloned().unwrap_or(Ty::Named("unknown".into()));
                Ok(TypedExpr::Ident { name: name.clone(), ty, span: *s })
            }
            Expr::SelfExpr(s) => {
                let ty = vars.get("self").cloned().unwrap_or(Ty::Named("Self".into()));
                Ok(TypedExpr::SelfExpr(ty, *s))
            }
            Expr::Field { base, field, span } => {
                let base_expr = self.infer_expr(base, vars)?;
                let field_ty = self.resolve_field_type(&base_expr, field, *span);
                Ok(TypedExpr::Field { base: Box::new(base_expr), field: field.clone(), ty: field_ty, span: *span })
            }
            Expr::Call { callee, args, span } => {
                let callee_expr = self.infer_expr(callee, vars)?;
                let arg_exprs: Vec<TypedExpr> = args.iter().map(|a| self.infer_expr(a, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))).collect();
                // Standard-library builtins (`print`/`println`, math, string
                // ops) aren't declared by any `fn` item, so they never show
                // up in `self.functions`; special-case their return types
                // here before falling back to the function table.
                if let TypedExpr::Ident { name, .. } = &callee_expr {
                    if let Some(ty) = builtin_return_ty(name, &arg_exprs) {
                        return Ok(TypedExpr::Call { callee: Box::new(callee_expr), args: arg_exprs, ty, span: *span });
                    }
                }
                // Look up the return type from the function table. Impl
                // methods share the same flat table as free functions
                // (keyed by name only), so a method call `obj.method()`
                // resolves exactly like a free-function call: through the
                // callee's name, whether that name came from an `Ident` or
                // (for methods) the field of a `Field` access.
                let ret_ty = match &callee_expr {
                    TypedExpr::Ident { name, .. } => {
                        self.functions.get(name)
                            .and_then(|(_, ret)| ret.clone())
                            .unwrap_or(Ty::Named("unknown".into()))
                    }
                    TypedExpr::Field { field, .. } => {
                        self.functions.get(field)
                            .and_then(|(_, ret)| ret.clone())
                            .unwrap_or(Ty::Named("unknown".into()))
                    }
                    _ => Ty::Named("unknown".into()),
                };
                Ok(TypedExpr::Call { callee: Box::new(callee_expr), args: arg_exprs, ty: ret_ty, span: *span })
            }
            Expr::Binary { op, lhs, rhs, span } => {
                let lhs_expr = self.infer_expr(lhs, vars)?;
                let rhs_expr = self.infer_expr(rhs, vars)?;
                let lhs_ty = lhs_expr.clone().into_ty();
                let rhs_ty = rhs_expr.clone().into_ty();
                let ty = self.infer_binop_ty(op, &lhs_ty, &rhs_ty, *span);
                Ok(TypedExpr::Binary { op: *op, lhs: Box::new(lhs_expr), rhs: Box::new(rhs_expr), ty, span: *span })
            }
            Expr::Unary { op, operand, span } => {
                let operand_expr = self.infer_expr(operand, vars)?;
                // `-x` preserves the operand's own numeric type (Int stays
                // Int, Float stays Float) rather than always widening to Int.
                let ty = match op {
                    UnOp::Neg => operand_expr.clone().into_ty(),
                    UnOp::Not => Ty::Bool,
                };
                Ok(TypedExpr::Unary { op: *op, operand: Box::new(operand_expr), ty, span: *span })
            }
            Expr::Match { scrutinee, arms, span } => {
                let scrutinee_expr = self.infer_expr(scrutinee, vars)?;
                let arm_tys: Vec<TypedMatchArm> = arms.iter().map(|a| self.check_match_arm(a, &scrutinee_expr, vars)).collect();
                let ty = arm_tys.first().map(|a| a.ty.clone()).unwrap_or(Ty::Named("unknown".into()));
                Ok(TypedExpr::Match { scrutinee: Box::new(scrutinee_expr), arms: arm_tys, ty, span: *span })
            }
            Expr::StructLit { name, args, span } => {
                let arg_exprs: Vec<TypedExpr> = args.iter().map(|a| self.infer_expr(a, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())))).collect();
                let resolved_ty = self.resolve_type(&Type::Named(name.clone())).unwrap_or_else(|| Ty::Named(name.clone()));
                self.check_builtin_ctor_arity(&resolved_ty, name, &arg_exprs, *span);
                Ok(TypedExpr::StructLit { name: name.clone(), args: arg_exprs, ty: resolved_ty, span: *span })
            }
            Expr::If { cond, then_block, else_block, span } => {
                let cond_typed = self.infer_expr(cond, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
                if !matches!(cond_typed.clone().into_ty(), Ty::Bool) {
                    self.error("if condition must be of type bool", cond.span());
                }
                let then_typed = self.check_block_inner(then_block, &mut vars.clone());
                let else_typed = else_block.as_ref().map(|b| self.check_block_inner(b, &mut vars.clone()));
                let ty = then_typed.stmts.last()
                    .and_then(|s| if let TypedStmt::Expr(e) = s { Some(e.clone().into_ty()) } else { None })
                    .unwrap_or_else(|| Ty::Named("void".into()));
                Ok(TypedExpr::If {
                    cond: Box::new(cond_typed),
                    then_block: then_typed,
                    else_block: else_typed,
                    ty,
                    span: *span,
                })
            }
            Expr::GenRefCreate { inner_ty, value, span } => {
                let resolved_inner = self.resolve_type(inner_ty).unwrap_or(Ty::Named("unknown".into()));
                self.require_backing_arena(&resolved_inner, *span);
                let value_typed = self.infer_expr(value, vars).unwrap_or_else(|_| TypedExpr::Error(Ty::Named("infer_error".into())));
                if !matches!(value_typed.clone().into_ty(), Ty::Int) {
                    self.error("`GenRef<T>(..)` index must be `i32`", *span);
                }
                Ok(TypedExpr::GenRefCreate { inner_ty: resolved_inner, value: Box::new(value_typed), span: *span })
            }
            Expr::GenRefIndex { base, index, span } => {
                let base_expr = self.infer_expr(base, vars)?;
                let index_expr = self.infer_expr(index, vars)?;
                let inner_ty = match base_expr.clone().into_ty() {
                    Ty::GenRef(inner) => {
                        self.require_backing_arena(&inner, *span);
                        *inner
                    }
                    other => {
                        self.error(format!("`[..]` dereference requires a `GenRef<T>`, found `{:?}`", other), *span);
                        Ty::Named("unknown".into())
                    }
                };
                Ok(TypedExpr::GenRefIndex { base: Box::new(base_expr), index: Box::new(index_expr), ty: inner_ty, span: *span })
            }
        }
    }

    /// Validate constructor arity/argument types for the builtin vec/mat
    /// literal forms (`Vec2(x,y)`, `Vec3(x,y,z)`, `Vec4(x,y,z,w)`,
    /// `Mat4(row0,row1,row2,row3)`). No-op for user-defined structs (`Ty::Named`),
    /// which are not validated today either.
    fn check_builtin_ctor_arity(&mut self, ty: &Ty, name: &str, args: &[TypedExpr], span: Span) {
        let is_numeric = |t: &Ty| matches!(t, Ty::Int | Ty::Float);
        match ty {
            Ty::Vec2 | Ty::Vec3 | Ty::Vec4 => {
                let expected = ty.vec_arity().unwrap() as usize;
                if args.len() != expected
                    || !args.iter().all(|a| is_numeric(&a.clone().into_ty()))
                {
                    self.error(format!("{}(..) expects {} float arguments", name, expected), span);
                }
            }
            Ty::Mat4 => {
                if args.len() != 4 || !args.iter().all(|a| matches!(a.clone().into_ty(), Ty::Vec4)) {
                    self.error(format!("{}(..) expects 4 Vec4 row arguments", name), span);
                }
            }
            _ => {}
        }
    }

    /// Infer the result type of a binary operator, dispatching on whether
    /// either operand is a builtin vector/matrix type. Falls through to the
    /// original Int/Float/Bool behavior when both operands are scalar.
    fn infer_binop_ty(&mut self, op: &BinOp, lhs_ty: &Ty, rhs_ty: &Ty, span: Span) -> Ty {
        let is_cmp = matches!(op, BinOp::Eq | BinOp::Ne | BinOp::Lt | BinOp::Gt | BinOp::Le | BinOp::Ge);
        if !lhs_ty.is_vec() && !lhs_ty.is_mat() && !rhs_ty.is_vec() && !rhs_ty.is_mat() {
            // Original scalar behavior, preserved exactly.
            return if is_cmp {
                Ty::Bool
            } else {
                match (lhs_ty, rhs_ty) {
                    (Ty::Float, _) | (_, Ty::Float) => Ty::Float,
                    _ => Ty::Int,
                }
            };
        }

        if is_cmp {
            self.error("comparison operators are not supported on vector/matrix types", span);
            return Ty::Bool;
        }
        if matches!(op, BinOp::Rem) {
            self.error("`%` is not supported on vector/matrix types", span);
            return lhs_ty.clone();
        }

        let is_scalar = |t: &Ty| matches!(t, Ty::Int | Ty::Float);

        match op {
            BinOp::Add | BinOp::Sub => {
                if lhs_ty.is_mat() && rhs_ty.is_mat() {
                    if lhs_ty == rhs_ty { Ty::Mat4 } else {
                        self.error("mismatched matrix arity in `+`/`-`", span);
                        lhs_ty.clone()
                    }
                } else if lhs_ty.is_vec() && rhs_ty.is_vec() {
                    if lhs_ty == rhs_ty {
                        lhs_ty.clone()
                    } else {
                        self.error("mismatched vector arity in `+`/`-`", span);
                        lhs_ty.clone()
                    }
                } else {
                    self.error("`+`/`-` between a vector/matrix and a scalar is not supported", span);
                    if lhs_ty.is_vec() || lhs_ty.is_mat() { lhs_ty.clone() } else { rhs_ty.clone() }
                }
            }
            BinOp::Mul | BinOp::Div => {
                if lhs_ty.is_mat() && rhs_ty.is_mat() {
                    if *op == BinOp::Div {
                        self.error("matrix division is not supported", span);
                    }
                    Ty::Mat4
                } else if lhs_ty.is_mat() && *rhs_ty == Ty::Vec4 {
                    if *op == BinOp::Div {
                        self.error("matrix division is not supported", span);
                    }
                    Ty::Vec4
                } else if *lhs_ty == Ty::Vec4 && rhs_ty.is_mat() {
                    self.error("vector * matrix is not supported (use matrix * vector)", span);
                    Ty::Vec4
                } else if lhs_ty.is_vec() && rhs_ty.is_vec() {
                    if lhs_ty == rhs_ty {
                        lhs_ty.clone()
                    } else {
                        self.error("mismatched vector arity in `*`/`/`", span);
                        lhs_ty.clone()
                    }
                } else if lhs_ty.is_vec() && is_scalar(rhs_ty) {
                    lhs_ty.clone()
                } else if is_scalar(lhs_ty) && rhs_ty.is_vec() {
                    rhs_ty.clone()
                } else {
                    self.error("unsupported operand types for `*`/`/`", span);
                    if lhs_ty.is_vec() || lhs_ty.is_mat() { lhs_ty.clone() } else { rhs_ty.clone() }
                }
            }
            _ => unreachable!("Rem and comparisons handled above"),
        }
    }

    fn resolve_field_type(&mut self, base: &TypedExpr, field: &str, span: Span) -> Ty {
        let base_ty = base.clone().into_ty();
        if let Some(arity) = base_ty.vec_arity() {
            return self.resolve_swizzle(arity, field, span);
        }
        let name = match &base_ty {
            Ty::Named(n) => n,
            _ => return Ty::Named("unknown".into()),
        };
        let Some(sdef) = self.structs.get(name).cloned() else {
            // Unknown struct name: already reported elsewhere (or is a
            // synthesized/inferred placeholder type), so stay silent here.
            return Ty::Named("unknown".into());
        };
        match sdef.fields.iter().find(|f| f.name == field) {
            Some(f) => self.resolve_type(&f.ty).unwrap_or(Ty::Named("unknown".into())),
            None => {
                let candidates: Vec<&str> = sdef.fields.iter().map(|f| f.name.as_str()).collect();
                match suggest(field, candidates) {
                    Some(close) => self.error_note(
                        format!("no field `{}` on `{}`", field, name),
                        span,
                        format!("did you mean `{}`?", close),
                    ),
                    None => self.error(format!("no field `{}` on `{}`", field, name), span),
                }
                Ty::Named("unknown".into())
            }
        }
    }

    /// Validate and resolve a GLSL-style swizzle string (`.x`, `.xyz`, `.zyx`,
    /// ...) against a vector base of the given component count.
    fn resolve_swizzle(&mut self, arity: u8, field: &str, span: Span) -> Ty {
        if field.is_empty() || field.len() > 4 {
            self.error("invalid swizzle: expected 1-4 components", span);
            return Ty::Named("unknown".into());
        }
        for c in field.chars() {
            let idx = match c {
                'x' => 0,
                'y' => 1,
                'z' => 2,
                'w' => 3,
                _ => {
                    self.error(format!("invalid swizzle component `{}`", c), span);
                    return Ty::Named("unknown".into());
                }
            };
            if idx >= arity {
                self.error(format!("swizzle component `{}` out of range for Vec{}", c, arity), span);
                return Ty::Named("unknown".into());
            }
        }
        Ty::vec_of_arity(field.len() as u8).unwrap_or(Ty::Named("unknown".into()))
    }

    fn check_match_arm(&mut self, arm: &MatchArm, _scrutinee_expr: &TypedExpr, vars: &mut HashMap<String, Ty>) -> TypedMatchArm {
        let mut stmts = Vec::new();
        for stmt in &arm.body.stmts {
            if let Some(typed) = self.check_stmt(stmt, vars) {
                stmts.push(typed);
            }
        }
        TypedMatchArm { pattern: arm.pattern.clone(), body: TypedBlock { stmts, span: arm.span }, ty: Ty::Named("unknown".into()), span: arm.span }
    }

    fn resolve_type(&self, ty: &Type) -> Option<Ty> {
        match ty {
            Type::Named(name) => Some(match name.as_str() {
                "i32" | "i64" | "int" => Ty::Int,
                "f32" | "f64" | "float" => Ty::Float,
                "String" | "str" => Ty::Str,
                "bool" => Ty::Bool,
                "Vec2" => Ty::Vec2,
                "Vec3" => Ty::Vec3,
                "Vec4" => Ty::Vec4,
                "Mat4" => Ty::Mat4,
                _ => Ty::Named(name.clone()),
            }),
            Type::Generic(name, args) => {
                // Handle GenRef<T>
                if name == "GenRef" {
                    let inner = args.first().and_then(|a| self.resolve_type(a)).unwrap_or(Ty::Int);
                    return Some(Ty::GenRef(Box::new(inner)));
                }
                None
            }
        }
    }

    fn error(&mut self, msg: impl Into<String>, span: Span) {
        self.errors.push(TypeError { message: msg.into(), span, note: None });
    }

    /// Like [`Checker::error`], but attaches a secondary "did you mean `x`?"
    /// style hint rendered as a trailing note.
    fn error_note(&mut self, msg: impl Into<String>, span: Span, note: impl Into<String>) {
        self.errors.push(TypeError { message: msg.into(), span, note: Some(note.into()) });
    }

    fn errors_to_diagnostics(&self) -> Vec<Diagnostic> {
        self.errors
            .iter()
            .map(|e| match &e.note {
                Some(note) => Diagnostic::error_with_note(&e.message, e.span, note.clone()),
                None => Diagnostic::error(&e.message, e.span),
            })
            .collect()
    }
}

// ===== HIR types =========================================================

/// A typed arena declaration.
#[derive(Clone, Debug)]
pub struct TypedArenaDecl {
    pub name: String,
    pub ty: Ty,
    pub span: Span,
}

#[derive(Clone, Debug)]
pub struct TypedModule {
    pub items: Vec<TypedItem>,
}

#[derive(Clone, Debug)]
pub enum TypedItem {
    Struct(TypedStructDef),
    Trait(TypedTraitDef),
    Impl(TypedImplBlock),
    Fn(TypedFnDef),
    Arena(TypedArenaDecl),
}

#[derive(Clone, Debug)]
pub struct TypedStructDef {
    pub name: String,
    pub fields: Vec<TypedFieldDef>,
    pub span: Span,
}

#[derive(Clone, Debug)]
pub struct TypedFieldDef {
    pub is_mut: bool,
    pub name: String,
    pub ty: Ty,
    pub default: Option<TypedExpr>,
    pub decorators: Vec<String>,
    pub span: Span,
}

#[derive(Clone, Debug)]
pub struct TypedTraitDef {
    pub name: String,
    pub methods: Vec<TypedFnSig>,
    pub span: Span,
}

#[derive(Clone, Debug)]
pub struct TypedImplBlock {
    pub trait_name: Option<String>,
    pub type_name: String,
    pub methods: Vec<TypedFnDef>,
    pub span: Span,
}

#[derive(Clone, Debug)]
pub struct TypedFnSig {
    pub name: String,
    pub params: Vec<TypedParam>,
    pub ret: Option<Ty>,
    pub span: Span,
}

#[derive(Clone, Debug)]
pub struct TypedFnDef {
    pub sig: TypedFnSig,
    pub body: TypedBlock,
    pub span: Span,
}

#[derive(Clone, Debug)]
pub struct TypedParam {
    pub is_self: bool,
    pub is_mut: bool,
    pub name: String,
    pub ty: Ty,
    pub span: Span,
}

#[derive(Clone, Debug)]
pub struct TypedBlock {
    pub stmts: Vec<TypedStmt>,
    pub span: Span,
}

#[derive(Clone, Debug)]
pub enum TypedStmt {
    Let { is_mut: bool, name: String, ty: Ty, value: TypedExpr, span: Span },
    Assign { target: TypedExpr, op: AssignOp, value: TypedExpr, span: Span },
    Return { value: Option<TypedExpr>, span: Span },
    Expr(TypedExpr),
    If {
        cond: TypedExpr,
        then_block: TypedBlock,
        else_block: Option<TypedBlock>,
        span: Span,
    },
    While {
        cond: TypedExpr,
        then_block: TypedBlock,
        else_block: Option<TypedBlock>,
        span: Span,
    },
    Frame {
        body: TypedBlock,
        span: Span,
    },
    /// `par`/`swarm item in ArenaName: <body>` - see [`crate::ast::Stmt::Par`].
    Par {
        var: String,
        elem_ty: Ty,
        arena: String,
        body: TypedBlock,
        span: Span,
    },
    /// `spawn ArenaName(args...)` - see [`crate::ast::Stmt::Spawn`]. `elem`
    /// is the constructed element (a `StructLit`); codegen only has to
    /// append it to the arena's backing array and bump `count`.
    Spawn {
        arena: String,
        elem: TypedExpr,
        span: Span,
    },
    /// `despawn ArenaName[index]` - see [`crate::ast::Stmt::Despawn`].
    Despawn {
        arena: String,
        index: TypedExpr,
        span: Span,
    },
}

/// A type-checked f-string component.
#[derive(Clone, Debug)]
pub enum TypedFStrExpr {
    Literal(String),
    Expr(Box<TypedExpr>),
}

/// A type-checked expression with its resolved type attached.
/// Literal variants carry their original value for codegen.
#[derive(Clone, Debug)]
pub enum TypedExpr {
    Int(i64, Ty, Span),
    Float(f64, Ty, Span),
    Str(String, Ty, Span),
    Bool(bool, Ty, Span),
    Ident { name: String, ty: Ty, span: Span },
    SelfExpr(Ty, Span),
    Field { base: Box<TypedExpr>, field: String, ty: Ty, span: Span },
    Call { callee: Box<TypedExpr>, args: Vec<TypedExpr>, ty: Ty, span: Span },
    Binary { op: BinOp, lhs: Box<TypedExpr>, rhs: Box<TypedExpr>, ty: Ty, span: Span },
    Unary { op: UnOp, operand: Box<TypedExpr>, ty: Ty, span: Span },
    Match { scrutinee: Box<TypedExpr>, arms: Vec<TypedMatchArm>, ty: Ty, span: Span },
    StructLit { name: String, args: Vec<TypedExpr>, ty: Ty, span: Span },
    FStr(Vec<TypedFStrExpr>, Ty, Span),
    If {
        cond: Box<TypedExpr>,
        then_block: TypedBlock,
        else_block: Option<TypedBlock>,
        ty: Ty,
        span: Span,
    },
    GenRefCreate { inner_ty: Ty, value: Box<TypedExpr>, span: Span },
    GenRefIndex { base: Box<TypedExpr>, index: Box<TypedExpr>, ty: Ty, span: Span },
    Error(Ty),
}

impl TypedExpr {
    pub fn into_ty(self) -> Ty {
        match self {
            TypedExpr::Int(_, ty, _) | TypedExpr::Float(_, ty, _) | TypedExpr::Str(_, ty, _) | TypedExpr::Bool(_, ty, _)
            | TypedExpr::Field { ty, .. } | TypedExpr::Call { ty, .. } | TypedExpr::Binary { ty, .. }
            | TypedExpr::Unary { ty, .. } | TypedExpr::Match { ty, .. } | TypedExpr::StructLit { ty, .. }
            | TypedExpr::FStr(_, ty, _) | TypedExpr::GenRefIndex { ty, .. } | TypedExpr::Error(ty) => ty,
            TypedExpr::Ident { ty, .. } => ty,
            TypedExpr::SelfExpr(ty, _) => ty,
            TypedExpr::If { ty, .. } => ty.clone(),
            TypedExpr::GenRefCreate { inner_ty, .. } => Ty::GenRef(Box::new(inner_ty)),
        }
    }
}

/// The root identifier a place expression (`x`, `x.a.b`, `self.a`) writes
/// through, or `None` if it isn't a simple identifier/field chain.
fn root_ident(expr: &TypedExpr) -> Option<String> {
    match expr {
        TypedExpr::Ident { name, .. } => Some(name.clone()),
        TypedExpr::SelfExpr(..) => Some("self".to_string()),
        TypedExpr::Field { base, .. } => root_ident(base),
        _ => None,
    }
}

#[derive(Clone, Debug)]
pub struct TypedMatchArm {
    pub pattern: Pattern,
    pub body: TypedBlock,
    pub ty: Ty,
    pub span: Span,
}
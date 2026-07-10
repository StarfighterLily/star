//! `par`/`swarm` disjoint-access analysis.
//!
//! Proves (conservatively) that a `par` body's iterations don't race: the
//! only things a body may *mutate* are the loop variable's own fields and
//! locals it declares itself (both are per-iteration/per-thread, so safe
//! by construction). Any write to a name captured from the enclosing
//! scope — including `self` — is rejected, since concurrent writes to
//! shared state from multiple worker threads would race. Method calls are
//! held to the same standard, since a call `x.foo()` might mutate `x`
//! internally: only calls on the loop variable (or a body-local) are
//! allowed.

use std::collections::HashSet;

use super::*;

impl Checker {
    pub(super) fn check_par_disjoint(&mut self, var: &str, block: &TypedBlock) {
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
            TypedStmt::For { var, start, end, body, .. } => {
                self.walk_par_expr(start, locals);
                self.walk_par_expr(end, locals);
                let mut l = locals.clone();
                l.insert(var.clone());
                self.walk_par_stmts(&body.stmts, &mut l);
            }
            TypedStmt::Break { .. } | TypedStmt::Continue { .. } => {}
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
                    // A payload pattern's bindings are fresh per-match
                    // locals (destructured out of the scrutinee), safe to
                    // treat the same as any other body-local.
                    if let Pattern::EnumVariant(_, _, bindings) | Pattern::Struct(_, bindings) = &arm.pattern {
                        for b in bindings {
                            l.insert(b.clone());
                        }
                    }
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
            TypedExpr::EnumVariant { args, .. } => {
                for a in args {
                    self.walk_par_expr(a, locals);
                }
            }
            // A closure literal's body isn't walked by this per-statement
            // disjointness proof (it only runs when/if the closure is later
            // called, possibly from entirely outside this par/swarm body),
            // so any mutation it makes can't be soundly proven disjoint here.
            // Simplest safe answer: reject closures inside a par/swarm body
            // outright, mirroring `spawn`/`despawn` above.
            TypedExpr::Closure { span, .. } => {
                self.error("closures are not supported inside a par/swarm body", *span);
            }
            TypedExpr::ListNew { .. } => {}
            TypedExpr::ListLit { elems, .. } => {
                for e in elems {
                    self.walk_par_expr(e, locals);
                }
            }
            TypedExpr::ListIndex { base, index, .. } => {
                self.walk_par_expr(base, locals);
                self.walk_par_expr(index, locals);
            }
            // `push`/`pop` mutate the receiver in place (growing/shrinking
            // its backing buffer), so they're held to the same standard as
            // a struct method call above: only the loop variable's own
            // list (or a body-local one) can be proven disjoint across
            // threads. `len` only reads, so it's exempt.
            TypedExpr::ListMethod { base, method, args, span, .. } => {
                if matches!(method, ListMethod::Push | ListMethod::Pop) {
                    match root_ident(base) {
                        Some(root) if locals.contains(&root) => {}
                        _ => self.error(
                            "cannot mutate a captured list inside a par/swarm body \
                             (only the loop variable's own locals may be mutated)",
                            *span,
                        ),
                    }
                }
                self.walk_par_expr(base, locals);
                for a in args {
                    self.walk_par_expr(a, locals);
                }
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
}

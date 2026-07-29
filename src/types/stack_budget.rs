//! `star check`-time heuristic warning for a function whose own `let`-bound
//! aggregate locals, combined with what its deepest statically-resolvable
//! call chain adds on top of them, risk exceeding the native call stack --
//! `todo.md`'s P0 #2.
//!
//! This is the exact incident class `crate::main`'s `DEFAULT_STACK_SIZE_BYTES`
//! doc comment documents fixing *after the fact* for `star build`'s own
//! linked executables: a real Nova-16 port held its ~950KB `Cpu` struct as
//! one `let` in `main`, and `main` transitively called a function with its
//! own unrelated 64KB local array (`Screen::roll_x`'s temp buffer) -- neither
//! function looked dangerous in isolation, but their *combined* native stack
//! depth overflowed Windows' 1MiB linker default. `star build` now always
//! reserves a generous 16MiB, so that specific crash is fixed -- but nothing
//! previously gave a *diagnosable compile-time signal* that a program was
//! heading toward this shape at all; the only feedback was a runtime
//! `STATUS_STACK_OVERFLOW` (or, on a target/config that reserves less, still
//! could be). This pass turns that into a `star check`-time warning instead.
//!
//! Deliberately a heuristic, not a soundness proof (mirroring
//! `crate::ir_check`'s own "best-effort... not a reimplementation" framing):
//! - Byte sizes (`approx_stack_size`) are computed here rather than via
//!   `crate::codegen::Codegen::type_size`, since that method needs codegen's
//!   own `struct_field_types` table (only ever populated during `Codegen::emit`,
//!   which `star check` never runs) -- this recomputes the same shapes from
//!   the already-typed struct/enum field lists instead, without chasing
//!   `Codegen`'s exact LLVM alignment/padding math, since only the order of
//!   magnitude matters for a warning.
//! - The call graph only records a callee this pass can resolve *statically*
//!   to a named `fn`/method by its typed callee expression shape (a bare
//!   `Ident` naming a free function, or a `Field` access whose base's type is
//!   a concrete `Ty::Named`) -- a call through a closure/function value is
//!   skipped entirely, an accepted false-negative gap (this can only
//!   under-warn, never over-warn, from that gap).
//! - A `Closure` literal's body is not walked at all here (neither for its
//!   own `let`s nor for calls inside it): it compiles to its own separate
//!   function (see `crate::codegen::closure`), with its own independent
//!   stack frame, not this function's.
//! - Recursion (direct or mutual) is capped by tracking the current DFS
//!   path: revisiting a function already on it contributes no further
//!   footprint through that edge, rather than looping forever. This means a
//!   deeply recursive function's *own* per-call frame cost is not what this
//!   pass measures (a different, well-known problem); it only measures one
//!   static traversal of the call graph.

use std::collections::{HashMap, HashSet};

use super::*;

/// Cumulative call-chain footprint, in bytes, at or above which
/// `Checker::check_stack_budget` warns. Deliberately far below
/// `crate::main`'s `DEFAULT_STACK_SIZE_BYTES` (16MiB, `star build`'s own
/// linked-executable stack reserve) rather than matched to it: the point of
/// a `star check`-time warning is to flag a design worth a second look while
/// the program is still small and easy to restructure, not to wait until a
/// specific build target's specific linker flag would actually be exceeded.
/// 1MiB matches the concrete incident this guards against -- Windows' PE
/// linker default main-thread stack reserve, which is what actually
/// overflowed before `DEFAULT_STACK_SIZE_BYTES` existed.
const STACK_BUDGET_WARN_BYTES: u64 = 1024 * 1024;

/// One function or method body, reduced to just what this analysis needs --
/// gathered once from the final typed item list before the warning pass
/// walks the call graph. Keyed the same way call-graph edges are (see
/// `callee_key`): a free function by its bare name, a method by
/// `"{struct}#{method}"`.
struct FnInfo {
    /// Sum of `approx_stack_size` over every `let` this function's body
    /// binds directly, including ones nested inside `if`/`while`/`for`/
    /// `frame`/`par`/`each` bodies (all still this same compiled function's
    /// own stack frame) but not inside a nested `Closure` literal's body
    /// (its own, separate function -- see this module's doc comment).
    own_footprint: u64,
    /// Every other function/method this body calls that `callee_key` can
    /// resolve statically, by that same key.
    callees: Vec<String>,
    /// Where to point the warning if this function ends up over budget.
    span: Span,
}

impl Checker {
    /// Entry point, called once from `check` after every item has been
    /// type-checked successfully (see that method's own call site for why
    /// it's gated on `self.errors.is_empty()`).
    pub(super) fn check_stack_budget(&mut self, items: &[TypedItem]) {
        let mut structs: HashMap<String, Vec<Ty>> = HashMap::new();
        let mut enums: HashMap<String, Vec<Vec<Ty>>> = HashMap::new();
        for item in items {
            match item {
                TypedItem::Struct(s) => {
                    structs.insert(s.name.clone(), s.fields.iter().map(|f| f.ty.clone()).collect());
                }
                TypedItem::Enum(e) => {
                    enums.insert(
                        e.name.clone(),
                        e.variants.iter().map(|v| v.fields.iter().map(|f| f.ty.clone()).collect()).collect(),
                    );
                }
                _ => {}
            }
        }

        let mut fn_infos: HashMap<String, FnInfo> = HashMap::new();
        for item in items {
            match item {
                TypedItem::Fn(f) => {
                    fn_infos.insert(f.sig.name.clone(), fn_info_of(&f.body, f.span, &structs, &enums));
                }
                TypedItem::Impl(impl_blk) => {
                    for m in &impl_blk.methods {
                        let key = format!("{}#{}", impl_blk.type_name, m.sig.name);
                        fn_infos.insert(key, fn_info_of(&m.body, m.span, &structs, &enums));
                    }
                }
                _ => {}
            }
        }

        // Sorted purely so warnings come out in a stable, reproducible
        // order across runs -- `fn_infos` is a `HashMap`, whose iteration
        // order isn't otherwise guaranteed.
        let mut names: Vec<&String> = fn_infos.keys().collect();
        names.sort();
        for name in names {
            let info = &fn_infos[name];
            // Only report at a function that itself owns some of the
            // footprint -- a pure pass-through function with no large
            // locals of its own that merely calls into a deep chain isn't
            // where a reader should look to fix this; the function actually
            // holding the data is. This also naturally selects the true
            // *combination* point in the Nova incident this module's doc
            // comment describes: `main` (owns the large struct) over
            // `Screen::roll_x` (owns a modest local, under budget alone).
            if info.own_footprint == 0 {
                continue;
            }
            let mut path = HashSet::new();
            let cumulative = cumulative_footprint(name, &fn_infos, &mut path);
            if cumulative >= STACK_BUDGET_WARN_BYTES {
                self.warning(
                    format!(
                        "`{}`'s own local aggregate footprint ({} bytes) combined with its deepest static call chain totals approximately {} bytes of native stack -- consider not holding this much aggregate data in a `let` across nested calls",
                        name, info.own_footprint, cumulative
                    ),
                    info.span,
                );
            }
        }
    }
}

/// Gather one function/method body's own-`let`-footprint and its
/// statically-resolvable direct callees.
fn fn_info_of(body: &TypedBlock, span: Span, structs: &HashMap<String, Vec<Ty>>, enums: &HashMap<String, Vec<Vec<Ty>>>) -> FnInfo {
    let own_footprint = block_let_footprint(body, structs, enums);
    let mut callees = Vec::new();
    collect_calls_in_block(body, &mut callees);
    FnInfo { own_footprint, callees, span }
}

/// The static call-graph traversal `Checker::check_stack_budget` runs after
/// `fn_infos` is built: `own_footprint` plus whichever direct callee's own
/// `cumulative_footprint` is largest, recursively -- i.e. the heaviest single
/// static call path reachable from `name`. `path` tracks the current DFS
/// path (not a global visited set) so a function called from two unrelated
/// branches is still measured independently down each one; a function
/// already on the current path (direct or mutual recursion) contributes no
/// further footprint through that edge -- see this module's doc comment.
fn cumulative_footprint(name: &str, fn_infos: &HashMap<String, FnInfo>, path: &mut HashSet<String>) -> u64 {
    let Some(info) = fn_infos.get(name) else { return 0 };
    if !path.insert(name.to_string()) {
        return 0;
    }
    let deepest_callee = info.callees.iter().map(|c| cumulative_footprint(c, fn_infos, path)).max().unwrap_or(0);
    path.remove(name);
    info.own_footprint + deepest_callee
}

/// Sum of `approx_stack_size` over every `let` directly inside `block`,
/// recursing into every nested-block-bearing statement shape (see
/// `FnInfo::own_footprint`'s doc comment for which ones still count).
fn block_let_footprint(block: &TypedBlock, structs: &HashMap<String, Vec<Ty>>, enums: &HashMap<String, Vec<Vec<Ty>>>) -> u64 {
    let mut total = 0u64;
    for stmt in &block.stmts {
        stmt_let_footprint(stmt, structs, enums, &mut total);
    }
    total
}

fn stmt_let_footprint(stmt: &TypedStmt, structs: &HashMap<String, Vec<Ty>>, enums: &HashMap<String, Vec<Vec<Ty>>>, total: &mut u64) {
    match stmt {
        TypedStmt::Let { ty, .. } => {
            *total += approx_stack_size(ty, structs, enums, &mut HashSet::new());
        }
        TypedStmt::If { then_block, else_block, .. } | TypedStmt::While { then_block, else_block, .. } => {
            *total += block_let_footprint(then_block, structs, enums);
            if let Some(b) = else_block {
                *total += block_let_footprint(b, structs, enums);
            }
        }
        TypedStmt::For { body, .. } | TypedStmt::Frame { body, .. } | TypedStmt::Par { body, .. } | TypedStmt::Each { body, .. } => {
            *total += block_let_footprint(body, structs, enums);
        }
        TypedStmt::Assign { .. }
        | TypedStmt::Return { .. }
        | TypedStmt::Expr(_)
        | TypedStmt::Break { .. }
        | TypedStmt::Continue { .. }
        | TypedStmt::Spawn { .. }
        | TypedStmt::Despawn { .. }
        | TypedStmt::Parallel { .. } => {}
    }
}

/// Approximate byte footprint of a value of type `ty` if bound as a plain
/// `let` local -- see this module's doc comment for why this doesn't chase
/// `Codegen::type_size`'s exact LLVM alignment/padding instead. `in_progress`
/// guards against a malformed recursive struct/enum (rejected elsewhere by
/// `Checker::check_no_recursive_structs`, but not necessarily *before* this
/// pass runs) sending this into unbounded recursion -- a revisit just falls
/// back to a small constant instead.
fn approx_stack_size(ty: &Ty, structs: &HashMap<String, Vec<Ty>>, enums: &HashMap<String, Vec<Vec<Ty>>>, in_progress: &mut HashSet<String>) -> u64 {
    match ty {
        Ty::Int | Ty::Float | Ty::U32 | Ty::Char | Ty::Color32 => 4,
        Ty::I8 | Ty::U8 | Ty::Bool | Ty::PaletteIndex => 1,
        Ty::I16 | Ty::U16 => 2,
        Ty::I64 | Ty::U64 | Ty::F64 => 8,
        // Heap-backed/pointer-sized types -- their own payload lives off the
        // stack (see each `Ty` variant's own doc comment in `crate::types`),
        // this is just the handle/pointer's size.
        Ty::Str
        | Ty::Ptr
        | Ty::List(_)
        | Ty::Map(..)
        | Ty::Set(_)
        | Ty::Table(_)
        | Ty::Bytes
        | Ty::Palette
        | Ty::Symbol
        | Ty::Tick
        | Ty::Duration
        | Ty::Instant => 8,
        Ty::GenRef(_) | Ty::Handle(_) | Ty::Closure(..) => 16,
        Ty::Vec2 => 8,
        Ty::Vec3 | Ty::Vec4 | Ty::Quat | Ty::Color | Ty::Mat2 => 16,
        Ty::Mat3 => 48,
        Ty::Mat4 => 64,
        Ty::Wrapping(inner) => approx_stack_size(inner, structs, enums, in_progress),
        Ty::Fixed(bits, _) | Ty::BitField(bits) => u64::from(*bits) / 8,
        Ty::Flags(_) => 8,
        Ty::Tuple(elems) => elems.iter().map(|e| approx_stack_size(e, structs, enums, in_progress)).sum(),
        Ty::Array(elem, count) => approx_stack_size(elem, structs, enums, in_progress).saturating_mul(*count),
        Ty::Ring(elem, count) => approx_stack_size(elem, structs, enums, in_progress).saturating_mul(*count).saturating_add(16),
        Ty::Named(name) => match structs.get(name) {
            Some(fields) if in_progress.insert(name.clone()) => {
                let size = fields.iter().map(|f| approx_stack_size(f, structs, enums, in_progress)).sum();
                in_progress.remove(name);
                size
            }
            _ => 8,
        },
        Ty::Enum(name) => match enums.get(name) {
            Some(variants) if in_progress.insert(name.clone()) => {
                let size = 8 + variants
                    .iter()
                    .map(|fields| fields.iter().map(|f| approx_stack_size(f, structs, enums, in_progress)).sum::<u64>())
                    .max()
                    .unwrap_or(0);
                in_progress.remove(name);
                size
            }
            _ => 8,
        },
    }
}

/// The call-graph key a `Call` expression's callee resolves to, if this
/// analysis can determine one statically -- `None` for anything indirect
/// (a closure/function-value call), which this pass simply doesn't trace
/// through (see this module's doc comment).
fn callee_key(callee: &TypedExpr) -> Option<String> {
    match callee {
        TypedExpr::Ident { name, .. } => Some(name.clone()),
        TypedExpr::Field { base, field, .. } => match base.as_ref().clone().into_ty() {
            Ty::Named(struct_name) => Some(format!("{}#{}", struct_name, field)),
            _ => None,
        },
        _ => None,
    }
}

fn collect_calls_in_block(block: &TypedBlock, out: &mut Vec<String>) {
    for stmt in &block.stmts {
        collect_calls_in_stmt(stmt, out);
    }
}

fn collect_calls_in_stmt(stmt: &TypedStmt, out: &mut Vec<String>) {
    match stmt {
        TypedStmt::Let { value, .. } => collect_calls_in_expr(value, out),
        TypedStmt::Assign { target, value, .. } => {
            collect_calls_in_expr(target, out);
            collect_calls_in_expr(value, out);
        }
        TypedStmt::Return { value, .. } => {
            if let Some(v) = value {
                collect_calls_in_expr(v, out);
            }
        }
        TypedStmt::Expr(e) => collect_calls_in_expr(e, out),
        TypedStmt::If { cond, then_block, else_block, .. } | TypedStmt::While { cond, then_block, else_block, .. } => {
            collect_calls_in_expr(cond, out);
            collect_calls_in_block(then_block, out);
            if let Some(b) = else_block {
                collect_calls_in_block(b, out);
            }
        }
        TypedStmt::For { start, end, body, .. } => {
            collect_calls_in_expr(start, out);
            collect_calls_in_expr(end, out);
            collect_calls_in_block(body, out);
        }
        TypedStmt::Frame { body, .. } | TypedStmt::Par { body, .. } | TypedStmt::Each { body, .. } => {
            collect_calls_in_block(body, out);
        }
        TypedStmt::Spawn { elem, .. } => collect_calls_in_expr(elem, out),
        TypedStmt::Despawn { index, .. } => collect_calls_in_expr(index, out),
        TypedStmt::Break { .. } | TypedStmt::Continue { .. } | TypedStmt::Parallel { .. } => {}
    }
}

/// Recursively collect every statically-resolvable call target reachable
/// from `expr` into `out` -- exhaustive over every `TypedExpr` variant (see
/// this module's doc comment for the one deliberate exception, `Closure`).
fn collect_calls_in_expr(expr: &TypedExpr, out: &mut Vec<String>) {
    match expr {
        TypedExpr::Int(..)
        | TypedExpr::Float(..)
        | TypedExpr::Str(..)
        | TypedExpr::Bool(..)
        | TypedExpr::Char(..)
        | TypedExpr::Ident { .. }
        | TypedExpr::SelfExpr(..)
        | TypedExpr::Error(_) => {}
        TypedExpr::Field { base, .. } => collect_calls_in_expr(base, out),
        TypedExpr::Call { callee, args, .. } => {
            if let Some(key) = callee_key(callee) {
                out.push(key);
            }
            collect_calls_in_expr(callee, out);
            for a in args {
                collect_calls_in_expr(a, out);
            }
        }
        TypedExpr::Binary { lhs, rhs, .. } => {
            collect_calls_in_expr(lhs, out);
            collect_calls_in_expr(rhs, out);
        }
        TypedExpr::Unary { operand, .. } => collect_calls_in_expr(operand, out),
        TypedExpr::Match { scrutinee, arms, .. } => {
            collect_calls_in_expr(scrutinee, out);
            for arm in arms {
                collect_calls_in_block(&arm.body, out);
            }
        }
        TypedExpr::StructLit { args, .. } | TypedExpr::EnumVariant { args, .. } | TypedExpr::FlagsNew { args, .. } => {
            for a in args {
                collect_calls_in_expr(a, out);
            }
        }
        TypedExpr::FStr(parts, ..) => {
            for p in parts {
                if let TypedFStrExpr::Expr(e) = p {
                    collect_calls_in_expr(e, out);
                }
            }
        }
        TypedExpr::If { cond, then_block, else_block, .. } => {
            collect_calls_in_expr(cond, out);
            collect_calls_in_block(then_block, out);
            if let Some(b) = else_block {
                collect_calls_in_block(b, out);
            }
        }
        TypedExpr::GenRefCreate { value, .. } => collect_calls_in_expr(value, out),
        TypedExpr::GenRefIndex { base, index, .. }
        | TypedExpr::ListIndex { base, index, .. }
        | TypedExpr::StrIndex { base, index, .. }
        | TypedExpr::ArrayIndex { base, index, .. }
        | TypedExpr::RingIndex { base, index, .. }
        | TypedExpr::TableIndex { base, index, .. } => {
            collect_calls_in_expr(base, out);
            collect_calls_in_expr(index, out);
        }
        // A closure literal's body compiles to its own separate function
        // (see `crate::codegen::closure`) with its own independent stack
        // frame -- not this one's. Any call reachable only through actually
        // *invoking* that closure value is an indirect call this pass
        // already can't resolve (see `callee_key`), so there is nothing this
        // arm could soundly attribute to the enclosing function either way.
        TypedExpr::Closure { .. } => {}
        TypedExpr::ListNew { .. } | TypedExpr::MapNew { .. } | TypedExpr::SetNew { .. } | TypedExpr::RingNew { .. } | TypedExpr::TableNew { .. } => {}
        TypedExpr::ListLit { elems, .. } | TypedExpr::ArrayLit { elems, .. } | TypedExpr::TupleLit { elems, .. } => {
            for e in elems {
                collect_calls_in_expr(e, out);
            }
        }
        TypedExpr::ListMethod { base, args, .. }
        | TypedExpr::MapMethod { base, args, .. }
        | TypedExpr::SetMethod { base, args, .. }
        | TypedExpr::RingMethod { base, args, .. }
        | TypedExpr::TableMethod { base, args, .. } => {
            collect_calls_in_expr(base, out);
            for a in args {
                collect_calls_in_expr(a, out);
            }
        }
        TypedExpr::TupleIndex { base, .. } => collect_calls_in_expr(base, out),
        TypedExpr::ArrayRepeat { value, .. } => collect_calls_in_expr(value, out),
        TypedExpr::ArrayLen { base, .. } => collect_calls_in_expr(base, out),
        TypedExpr::Cast { expr, .. } => collect_calls_in_expr(expr, out),
        TypedExpr::WrappingNew { value, .. } | TypedExpr::FixedNew { value, .. } | TypedExpr::BitFieldNew { value, .. } => {
            collect_calls_in_expr(value, out);
        }
        TypedExpr::Spawn { elem, .. } => collect_calls_in_expr(elem, out),
    }
}

//! Statement and function-body emission: control flow (`if`/`while`),
//! `let`/assignment, and the frame bump-allocator scope.

use crate::ast::*;
use crate::diagnostics::Span;
use crate::types::*;

use super::Codegen;

impl Codegen {
    /// Emit a block of typed statements. If the block ends with an expression
    /// statement (or a `frame` block whose own trailing statement produces a
    /// value), returns the value-register (with type tag) of that trailing
    /// expression; otherwise returns `None` (the block is used for side effects).
    pub(super) fn emit_block_value(&mut self, block: &TypedBlock) -> Option<String> {
        self.emit_stmts_value(&block.stmts)
    }

    /// Shared implementation behind `emit_block_value` and function bodies:
    /// emit every statement but the last normally, then special-case the last
    /// statement so a trailing expression's value (possibly nested inside a
    /// `frame:` scope, or a trailing `if`/`else` whose arms both produce a
    /// matching-typed value -- see `emit_trailing_if_value`) propagates out
    /// instead of being silently discarded. Must recognize exactly the same
    /// statement shapes as `Checker::trailing_value_ty`, kept in sync with it
    /// so a program that type-checks under a given trailing shape actually
    /// gets that value out of codegen too, not `undef`.
    pub(super) fn emit_stmts_value(&mut self, stmts: &[TypedStmt]) -> Option<String> {
        let (init, last) = match stmts.split_last() {
            Some((last, init)) => (init, last),
            None => return None,
        };
        for stmt in init {
            self.emit_stmt(stmt);
        }
        match last {
            TypedStmt::Expr(e) => Some(self.emit_expr(e)),
            TypedStmt::Frame { budget, body, .. } => self.emit_frame_body(*budget, body),
            // Only take the value-producing (phi-join) path when *both*
            // arms actually bottom out in a trailing value -- exactly
            // `Checker::trailing_value_ty`'s own condition for recognizing
            // this shape at all. An `if`/`else` whose arms terminate via
            // `return`/`break`/`continue` instead (by far the more common
            // shape -- see `body_terminates`) also matches this pattern
            // (`else_block: Some(..)`) but must keep going through the
            // plain control-flow `emit_stmt` path below: `then_block`/
            // `else_block`'s own last statement wouldn't be one of
            // `emit_stmts_value`'s value-producing arms either, so
            // `emit_trailing_if_value` would `?`-short-circuit after
            // already emitting a `ret` and opening the `then`/`else`
            // blocks, leaving stray unmatched `push_scope`s and never
            // reaching the `else` branch or the join block at all.
            TypedStmt::If { cond, then_block, else_block: Some(else_block), .. }
                if Self::stmt_has_trailing_value(&then_block.stmts) && Self::stmt_has_trailing_value(&else_block.stmts) =>
            {
                self.emit_trailing_if_value(cond, then_block, else_block)
            }
            other => {
                self.emit_stmt(other);
                None
            }
        }
    }

    /// True if `stmts` bottoms out in a trailing value under the exact same
    /// recursive rule `Checker::trailing_value_ty` uses to compute *what*
    /// that value's type is -- this is the type-independent half of that
    /// same check, used to decide *whether* to take `emit_stmts_value`'s
    /// value-producing `TypedStmt::If` path at all (see its call site's
    /// doc comment for why an unconditional dispatch on shape alone is
    /// wrong).
    ///
    /// A bare trailing expression is excluded when its own type is the
    /// `unknown` placeholder (a void call, e.g. `println(..)` or any
    /// function/method with no declared return type -- see
    /// `builtin_return_ty`'s doc comment): `emit_call_expr` emits such a
    /// call as a bare `"%undef"` string with no LLVM type tag at all, so
    /// treating it as "has a trailing value" would send `emit_trailing_if_value`
    /// looking for a space to split a type off of a string that has none --
    /// exactly `Checker::trailing_value_ty`'s matching `is_unknown` guard,
    /// kept in sync for the same reason every other pair of checks in this
    /// function/that one are.
    fn stmt_has_trailing_value(stmts: &[TypedStmt]) -> bool {
        match stmts.last() {
            Some(TypedStmt::Expr(e)) => !matches!(e.clone().into_ty(), Ty::Named(n) if n == "unknown"),
            Some(TypedStmt::Frame { body, .. }) => Self::stmt_has_trailing_value(&body.stmts),
            Some(TypedStmt::If { then_block, else_block: Some(else_block), .. }) => {
                Self::stmt_has_trailing_value(&then_block.stmts) && Self::stmt_has_trailing_value(&else_block.stmts)
            }
            _ => false,
        }
    }

    /// Emit a trailing `if`/`else` (`TypedStmt::If`, both arms present) as a
    /// value: branch on `cond`, evaluate each arm's own trailing value via
    /// `emit_stmts_value` (so it may itself end in a nested `frame:`/`if`),
    /// then `phi`-merge them at a shared join block -- the same
    /// evaluate-both-arms-then-`phi` shape `emit_expr`'s value-producing
    /// `TypedExpr::If` case already uses (down to tracking each arm's
    /// *actual* final predecessor block via `current_label`, not the block
    /// it started in, for the same "PHI node entries do not match
    /// predecessors" reason documented there), except the merged LLVM type
    /// is read off whichever arm's own tagged value comes back rather than
    /// from a pre-computed `ty` field (`TypedStmt::If`, unlike
    /// `TypedExpr::If`, carries none).
    ///
    /// Only ever reached from `emit_stmts_value` when `stmts.last()` is this
    /// shape, which only ever type-checks (see
    /// `Checker::trailing_value_ty`'s matching `TypedStmt::If` arm) when
    /// *both* arms are independently guaranteed to reach this same
    /// recursive "produces a value" case -- so the two `emit_stmts_value`
    /// calls below are guaranteed to return `Some`, never silently `None`
    /// (`projects/snake/NOTES.md` section 1.4).
    fn emit_trailing_if_value(&mut self, cond: &TypedExpr, then_block: &TypedBlock, else_block: &TypedBlock) -> Option<String> {
        let cond_val = self.emit_expr(cond);
        let cond_reg = self.reg_of(&cond_val);
        let then_label = self.block_label("if_then");
        let else_label = self.block_label("if_else");
        let end_label = self.block_label("if_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", cond_reg, then_label, else_label));

        self.open_block(&then_label);
        self.push_scope();
        let then_val = self.emit_stmts_value(&then_block.stmts)?;
        self.pop_scope(!Self::body_terminates(&then_block.stmts));
        // `rsplit_once` (split at the *last* space), not `split_once`: the
        // value half is always a single token (an SSA register name) with
        // no internal whitespace, but the type half can itself contain
        // spaces for any aggregate type (a tuple's `{ i8, i1 }`, a fixed
        // array's `[65536 x i8]`) -- splitting at the *first* space instead
        // truncated the type down to just `{`/`[` for exactly those cases,
        // corrupting the `phi` this feeds below (confirmed: a trailing
        // `if`/`else` returning a tuple, e.g. Nova-16's `Keyboard::pop_key`
        // returning `(u8, bool)`, emitted a malformed `phi { [ ... ]` that
        // the IR verifier rejected outright). `reg_of` already extracts the
        // value half the matching way (`split_whitespace().next_back()`).
        let ty_str = then_val.rsplit_once(' ').map(|(t, _)| t.to_string())?;
        let then_reg = self.reg_of(&then_val);
        let then_pred = self.current_label.clone();
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&else_label);
        self.push_scope();
        let else_val = self.emit_stmts_value(&else_block.stmts)?;
        self.pop_scope(!Self::body_terminates(&else_block.stmts));
        let else_reg = self.reg_of(&else_val);
        let else_pred = self.current_label.clone();
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let phi = self.tmp_name();
        self.line(&format!("  {} = phi {} [ {}, %{} ], [ {}, %{} ]", phi, ty_str, then_reg, then_pred, else_reg, else_pred));
        Some(format!("{} {}", ty_str, phi))
    }

    /// Bump-allocate `size` bytes from the `frame:` scope's backing buffer
    /// (`@frame.buf`), returning an `i8*` to the claimed region. This is the
    /// bounds check a bump allocator needs and previously had none of: if
    /// the allocation would advance `@frame.off` past the innermost
    /// enclosing `frame:` block's own configured budget (`self.frame_budget`
    /// -- not the physical buffer's fixed capacity, `Self::FRAME_BUF_SIZE`;
    /// see that field's doc comment for how the two differ), the process
    /// aborts with a diagnostic message instead of silently producing an
    /// out-of-bounds `getelementptr` that segfaults or corrupts whatever
    /// global data happens to sit right after the buffer.
    fn emit_frame_alloc(&mut self, size: &str) -> String {
        let budget = self.frame_budget;
        let off = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* @frame.off", off));
        let new_off = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, {}", new_off, off, size));
        let overflow = self.tmp_name();
        self.line(&format!("  {} = icmp ugt i64 {}, {}", overflow, new_off, budget));
        let fail_label = self.block_label("frame_alloc_fail");
        let ok_label = self.block_label("frame_alloc_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", overflow, fail_label, ok_label));

        self.open_block(&fail_label);
        // `budget` is a compile-time constant for this block (resolved by
        // the checker, see `TypedStmt::Frame::budget`'s doc comment), so --
        // exactly like `emit_arena_decl`'s own overflow-warning message --
        // it's baked directly into the message text rather than formatted
        // at runtime.
        let msg = format!("star runtime error: a `frame:` block exceeded its {}-byte capacity\n", budget);
        let g = self.global_name();
        let escaped = msg.replace("\\", "\\\\").replace("\"", "\\22").replace("\n", "\\0A");
        self.global_defs.push(format!("{} = private unnamed_addr constant [{} x i8] c\"{}\\00\"", g, msg.len() + 1, escaped));
        let msg_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [{} x i8], [{} x i8]* {}, i64 0, i64 0", msg_ptr, msg.len() + 1, msg.len() + 1, g));
        self.line(&format!("  call i32 @puts(i8* {})", msg_ptr));
        self.line("  call void @exit(i32 1)");
        self.line("  unreachable");

        self.open_block(&ok_label);
        self.line(&format!("  store i64 {}, i64* @frame.off", new_off));
        let base = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8], [{} x i8]* @frame.buf, i64 0, i64 0",
            base, Self::FRAME_BUF_SIZE, Self::FRAME_BUF_SIZE
        ));
        let byte_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", byte_ptr, base, off));
        byte_ptr
    }

    /// Emit a `frame:` scope: save the bump-allocator offset, emit the body
    /// (allocations inside use the frame buffer instead of the stack), then
    /// restore the saved offset so the scope's allocations are reclaimed in
    /// O(1) when it ends. Returns the body's trailing value, if any.
    ///
    /// If the body's last statement already terminates the block (an
    /// unconditional `return`/`break`/`continue`, or an `if`/`match` whose
    /// every arm does), the offset-restore `store` is skipped entirely --
    /// emitting it unconditionally used to append a `store` *after* the
    /// block's own terminator (e.g. a `ret`), which LLVM rejects outright
    /// ("expected instruction opcode": no instruction, especially not
    /// another terminator, may follow a block's first terminator). A
    /// terminated body never falls through to here anyway, so there is
    /// nothing for the restore to protect -- the frame offset a `return`
    /// leaves behind is irrelevant once control has left the function (and,
    /// for `break`/`continue`, the enclosing loop's own frame scope, if any,
    /// still restores its own offset on its own exit path).
    fn emit_frame_body(&mut self, budget: u64, body: &TypedBlock) -> Option<String> {
        let was_in_frame = self.in_frame;
        let was_budget = self.frame_budget;
        self.in_frame = true;
        self.frame_budget = budget;
        let saved_off = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* @frame.off", saved_off));
        self.push_scope();
        let val = self.emit_stmts_value(&body.stmts);
        let terminates = Self::body_terminates(&body.stmts);
        self.pop_scope(!terminates);
        if !terminates {
            self.line(&format!("  store i64 {}, i64* @frame.off", saved_off));
        }
        self.in_frame = was_in_frame;
        self.frame_budget = was_budget;
        val
    }

    /// True if the last statement of `stmts` unconditionally terminates the
    /// block with an explicit `return`/`break`/`continue` (looking through
    /// trailing `frame` scopes), so callers know not to append a synthetic
    /// terminator of their own (LLVM rejects any instruction, including
    /// another terminator, after a block's first terminator).
    pub(super) fn body_terminates(stmts: &[TypedStmt]) -> bool {
        match stmts.last() {
            Some(TypedStmt::Return { .. } | TypedStmt::Break { .. } | TypedStmt::Continue { .. }) => true,
            Some(TypedStmt::Frame { body, .. }) => Self::body_terminates(&body.stmts),
            // An `if` only terminates the enclosing block if *both* arms do
            // (an `if` with no `else`, or with a non-terminating branch,
            // falls through and still needs the synthetic join point).
            Some(TypedStmt::If { then_block, else_block: Some(else_block), .. }) => {
                Self::body_terminates(&then_block.stmts) && Self::body_terminates(&else_block.stmts)
            }
            // A `match` terminates the enclosing block if every one of its
            // arms does (each ends in its own `return`/`break`/`continue`),
            // matching `emit_expr`'s `TypedExpr::Match` codegen, which closes
            // its own join block with `unreachable` in exactly this case
            // instead of leaving it open for a value to flow through.
            Some(TypedStmt::Expr(TypedExpr::Match { arms, .. })) => {
                !arms.is_empty() && arms.iter().all(|arm| Self::body_terminates(&arm.body.stmts))
            }
            _ => false,
        }
    }

    /// Build `expr` (of type `ty`) directly into already-allocated `dest_ptr`
    /// storage, without ever materializing a whole-aggregate SSA value --
    /// used wherever a struct/fixed-array value crosses a `let` binding,
    /// function return, or call-argument boundary and
    /// `Codegen::is_large_aggregate_ty` says the ordinary by-value
    /// `load`/`store` shape is a real `clang` hang/crash risk (`todo.md` P0
    /// #2; see `crate::codegen::array::emit_array_repeat_into`'s doc comment
    /// for the underlying LLVM/clang bug this all routes around). Four
    /// shapes get a genuinely copy-free lowering:
    /// - a fresh struct/array literal is built field-by-field straight into
    ///   `dest_ptr` (`emit_struct_lit_fields_into`/`emit_array_repeat_into`),
    ///   exactly `TypedStmt::Let`'s pre-existing direct-literal fast path;
    /// - a nested call with the same aggregate return type forwards
    ///   `dest_ptr` straight through as *its own* hidden `sret` argument
    ///   (`emit_call_into`), so a chain of constructor calls never copies at
    ///   all;
    /// - a read of existing storage (a local, `self`, a field, a tuple/
    ///   array/ring element) resolves to that storage's real address via
    ///   `emit_read_place` (not `emit_place` -- see its own doc comment on
    ///   why a `list[idx]`-based read must never go through `emit_place`'s
    ///   write-oriented `ListIndex` arm) and `memcpy`s from it
    ///   (`emit_memcpy_aggregate`, a single intrinsic call regardless of
    ///   size), after retaining it exactly like `emit_expr`'s own `Ident`/
    ///   `Field`/`SelfExpr` read arms do (see `rc.rs`'s module doc comment: a
    ///   read of an existing owned slot hands out a duplicate reference and
    ///   must retain, while a fresh construction starts at refcount 1 and
    ///   must not be retained again).
    ///
    /// Anything else (a `match`/trailing-`if` result, ...) falls back to the
    /// ordinary whole-aggregate `load`+`store` -- rare in practice for a
    /// value large enough to reach this function at all, and no worse than
    /// the behavior this fix replaces.
    pub(super) fn emit_into_ptr(&mut self, dest_ptr: &str, expr: &TypedExpr, ty: &Ty) {
        match expr {
            TypedExpr::StructLit { name, args, ty: Ty::Named(_), .. } => {
                self.emit_struct_lit_fields_into(dest_ptr, name, args);
            }
            TypedExpr::ArrayRepeat { value, count, elem_ty, .. } => {
                self.emit_array_repeat_into(dest_ptr, value, *count, elem_ty);
            }
            TypedExpr::Call { callee, args, .. } => {
                self.emit_call_into(dest_ptr, callee, args, ty);
            }
            TypedExpr::Ident { .. }
            | TypedExpr::SelfExpr(..)
            | TypedExpr::Field { .. }
            | TypedExpr::TupleIndex { .. }
            | TypedExpr::ArrayIndex { .. }
            | TypedExpr::RingIndex { .. } => {
                let src_ptr = self.emit_read_place(expr);
                self.emit_retain_at(&src_ptr, ty);
                self.emit_memcpy_aggregate(dest_ptr, &src_ptr, ty);
            }
            _ => {
                let val = self.emit_expr(expr);
                let bare = self.untag(&val, ty);
                let llvm_ty = self.llvm_ty(ty);
                self.line(&format!("  store {} {}, {}* {}", llvm_ty, bare, llvm_ty, dest_ptr));
            }
        }
    }

    /// `extern "C" fn name(params) -> ret`: a bare LLVM `declare`, no body.
    /// Parameter names aren't needed in a `declare` (LLVM's textual IR only
    /// requires them on `define`), so this is just a type-signature dump --
    /// contrast with `emit_fn` below, which allocas/stores every parameter
    /// and walks a real body. If the fixed builtin prelude already declared
    /// this exact name (e.g. a user writing `extern "C" fn atoi(...)`, the
    /// same real libc function `par_pool.rs` also calls internally), skip
    /// emitting a second `declare` -- see `prelude_declared`'s doc comment.
    pub(super) fn emit_extern_fn_decl(&mut self, sig: &TypedFnSig) {
        if self.prelude_declared.contains(&sig.name) {
            return;
        }
        let ret_ty = match &sig.ret { Some(t) => self.llvm_ty(t), None => "void".into() };
        let params: Vec<String> = sig.params.iter().map(|p| self.llvm_ty(&p.ty)).collect();
        self.line(&format!("declare {} @{}({})", ret_ty, sig.name, params.join(", ")));
    }

    /// `owner`: `Some(struct_name)` for an impl method, `None` for a free
    /// function. A method's emitted LLVM function name is mangled as
    /// `{struct}__{method}` (looked up via `Codegen::methods` at call sites,
    /// see `emit_call_expr`) rather than the bare method name, since two
    /// unrelated structs may declare a same-named method with a different
    /// signature -- emitting both under the bare name would be a duplicate
    /// `define @name` global, rejected by clang as an "invalid redefinition
    /// of function" on otherwise valid source.
    pub(super) fn emit_fn(&mut self, f: &TypedFnDef, owner: Option<&str>) {
        self.symbols.clear();
        self.owned_stack.clear();
        self.push_scope();
        self.tmp = 0;
        // Isolate this function's own IR text so `hoist_allocas_to_entry`
        // (see its doc comment) can move every `alloca` it emits below --
        // wherever in the body it ends up, e.g. inside a loop -- up to the
        // entry block, rather than each one costing real stack space on
        // every pass through the block containing it.
        let fn_start = self.ir.len();

        // `main` is the process's real C entry point once linked by clang: a
        // hosted `int main(void)` is a hard ABI requirement, since the OS/CRT
        // startup thunk always reads a return value out of `eax`/`al` after
        // calling it. Lowering a bare `fn main():` to `define void @main()`
        // (the ordinary no-return-type rule below) leaves that register
        // holding whatever garbage the last instruction before `ret void`
        // happened to write -- typically the last `printf`'s return value --
        // so every compiled program's exit code becomes non-deterministic
        // garbage despite otherwise-correct output. `main` is therefore
        // special-cased to always lower to `i32 @main(...)`, with an
        // implicit `ret i32 0` appended when the user's body doesn't already
        // return a value, mirroring what `rustc`/`clang` do for a bare `fn
        // main()`/`void main()`.
        let is_main = owner.is_none() && f.sig.name == "main";
        // A struct/fixed-array return type large enough that by-value `ret`
        // risks the same `clang` hang/crash `emit_array_repeat_into`'s doc
        // comment describes (`todo.md` P0 #2) lowers to `void` plus a hidden
        // trailing out-pointer argument (`%.sret`) instead of an ordinary
        // by-value `ret` -- see `Codegen::sret_ptr`'s doc comment. `main` is
        // exempt (always forced to `i32` below, and never declares a
        // struct/array return type in practice).
        let ret_is_agg = !is_main && matches!(&f.sig.ret, Some(t) if self.is_large_aggregate_ty(t));
        let ret_ty = if is_main {
            "i32".to_string()
        } else if ret_is_agg {
            "void".to_string()
        } else {
            match &f.sig.ret { Some(t) => self.llvm_ty(t), None => "void".into() }
        };
        let func_name = match owner {
            Some(struct_name) => format!("{}__{}", struct_name, f.sig.name),
            None => f.sig.name.clone(),
        };

        self.write(&format!("define {} @{}(", ret_ty, func_name));
        // `main`'s real, OS-called LLVM signature always accepts `argc`/
        // `argv` regardless of Star `fn main()`'s own (always empty in
        // practice) declared parameter list -- see `args()`'s doc comment
        // above `@star.argc`/`@star.argv` in `crate::codegen::Codegen::emit_builtins`.
        let mut params: Vec<String> = if is_main {
            vec!["i32 %.argc".to_string(), "i8** %.argv".to_string()]
        } else {
            f.sig.params.iter().map(|p| {
                let ty = if p.is_self {
                    match &p.ty { Ty::Named(n) => format!("%{}*", n), t => format!("{}*", self.llvm_ty(t)) }
                } else if self.is_large_aggregate_ty(&p.ty) {
                    // Pointer-passed, like `self` just above -- see this
                    // function's own prologue below, which `memcpy`s the
                    // pointee into a private local instead of loading the
                    // whole by-value aggregate (`todo.md` P0 #2).
                    format!("{}*", self.llvm_ty(&p.ty))
                } else { self.llvm_ty(&p.ty) };
                format!("{} %{}", ty, p.name)
            }).collect()
        };
        if ret_is_agg {
            let rty_llvm = self.llvm_ty(f.sig.ret.as_ref().unwrap());
            params.push(format!("{}* %.sret", rty_llvm));
        }
        self.write(&params.join(", "));
        self.line(") {");
        self.open_block("entry");

        if is_main {
            self.line("  store i32 %.argc, i32* @star.argc");
            self.line("  store i8** %.argv, i8*** @star.argv");
            // Must run before any user code -- see `@sym.lock`'s doc comment
            // in `Codegen::emit_builtins` for why this can't be a lazy
            // first-use init the way the `par`/`swarm` pool's own is.
            self.emit_sym_lock_init();
            // Same reasoning applies to `@rng.lock` -- see its own doc
            // comment in `Codegen::emit_builtins`.
            self.emit_rng_lock_init();
        }

        for p in &f.sig.params {
            if !p.is_self && self.is_large_aggregate_ty(&p.ty) {
                // Arrives as a pointer to the caller's own storage, already
                // correctly retained/uniquely-owned on the caller's side
                // (see `Codegen::emit_call_arg`'s doc comment) -- `memcpy` a
                // private local copy so this function's own mutations, if
                // any, can't alias the caller's storage (ordinary by-value
                // parameter semantics), without ever loading a
                // whole-aggregate SSA value (`todo.md` P0 #2).
                let llvm_ty = self.llvm_ty(&p.ty);
                let alloca = self.tmp_name();
                self.line(&format!("  {} = alloca {}", alloca, llvm_ty));
                self.emit_memcpy_aggregate(&alloca, &format!("%{}", p.name), &p.ty);
                self.track_owned(&alloca, &p.ty);
                self.symbols.push((p.name.clone(), alloca, p.ty.clone()));
                continue;
            }
            let ptr_ty = if p.is_self {
                match &p.ty { Ty::Named(n) => format!("%{}*", n), t => format!("{}*", self.llvm_ty(t)) }
            } else { self.llvm_ty(&p.ty) };
            let alloca = self.tmp_name();
            self.line(&format!("  {} = alloca {}", alloca, ptr_ty));
            self.line(&format!("  store {} %{}, {}* {}", ptr_ty, p.name, ptr_ty, alloca));
            // `self` is passed *by pointer* (a borrow of the caller's own
            // struct, see the `is_self` special-casing above), not an
            // owned copy -- unlike every other parameter, `alloca` here is
            // one indirection level deeper than `track_owned`/`contains_rc`
            // assume for an ordinary local of type `p.ty`, so it must not
            // be tracked (mirrors the same exception in
            // `crate::codegen::closure::emit_closure_lit`'s capture loop).
            if !p.is_self {
                self.track_owned(&alloca, &p.ty);
            }
            self.symbols.push((p.name.clone(), alloca, p.ty.clone()));
        }

        let was_in_main = self.in_main;
        self.in_main = is_main;
        let was_sret = self.sret_ptr.take();
        if ret_is_agg {
            self.sret_ptr = Some("%.sret".to_string());
        }
        let terminated = Self::body_terminates(&f.body.stmts);
        // Aggregate-returning function: build a bare trailing expression
        // (no `return` keyword -- the common constructor-function shape,
        // `fn new() -> Cpu:\n    Cpu(...)`) directly into `%.sret` via
        // `emit_into_ptr` instead of computing a whole-aggregate "value"
        // through the ordinary `emit_stmts_value` path (see
        // `emit_into_ptr`'s doc comment). Anything else in trailing position
        // (a `frame:` scope, a trailing `if`/`else` value, ...) falls back
        // to the pre-existing whole-value path below, `memcpy`'d into
        // `%.sret` after the fact -- rarer in practice, and no worse than
        // the behavior this fix replaces.
        let mut agg_written_directly = false;
        let trailing_val = if ret_is_agg && !terminated {
            match f.body.stmts.split_last() {
                Some((TypedStmt::Expr(e), init)) => {
                    for s in init {
                        self.emit_stmt(s);
                    }
                    let rty = f.sig.ret.clone().unwrap();
                    self.emit_into_ptr("%.sret", e, &rty);
                    agg_written_directly = true;
                    None
                }
                _ => self.emit_stmts_value(&f.body.stmts),
            }
        } else {
            self.emit_stmts_value(&f.body.stmts)
        };
        self.pop_scope(!terminated);
        self.in_main = was_in_main;
        self.sret_ptr = was_sret;

        if !terminated {
            if ret_is_agg {
                let rty = f.sig.ret.as_ref().unwrap();
                if !agg_written_directly {
                    let rty_s = self.llvm_ty(rty);
                    match trailing_val {
                        Some(v) => {
                            let clean = v.strip_prefix(&format!("{} ", rty_s)).unwrap_or(&v).to_string();
                            let tmp = self.tmp_name();
                            self.line(&format!("  {} = alloca {}", tmp, rty_s));
                            self.line(&format!("  store {} {}, {}* {}", rty_s, clean, rty_s, tmp));
                            self.emit_memcpy_aggregate("%.sret", &tmp, rty);
                        }
                        None => {
                            self.err("function must end in a value-producing expression or explicit return", Span::dummy());
                        }
                    }
                }
                self.line("  ret void");
            } else {
                match &f.sig.ret {
                    Some(rty) => {
                        let rty_s = self.llvm_ty(rty);
                        match trailing_val {
                            Some(v) => {
                                let clean = v.strip_prefix(&format!("{} ", rty_s)).unwrap_or(&v).to_string();
                                self.line(&format!("  ret {} {}", rty_s, clean));
                            }
                            None => {
                                self.err("function must end in a value-producing expression or explicit return", Span::dummy());
                                self.line(&format!("  ret {} undef", rty_s));
                            }
                        }
                    }
                    None => {
                        if is_main {
                            self.line("  ret i32 0");
                        } else {
                            self.line("  ret void");
                        }
                    }
                }
            }
        }
        self.line("}");
        self.line("");

        let fn_ir = self.ir.split_off(fn_start);
        self.ir.push_str(&Self::hoist_allocas_to_entry(&fn_ir));
    }

    pub(super) fn emit_stmt(&mut self, stmt: &TypedStmt) {
        match stmt {
            TypedStmt::Let { name, value, .. } => {
                let vty = self.expr_ty(value);
                let ty = self.llvm_ty(&vty);
                if self.in_frame {
                    // Frame allocation: bump-allocate `size` bytes from the
                    // frame buffer (bounds-checked -- see `emit_frame_alloc`),
                    // then bitcast the raw `i8*` slot to the value's actual
                    // pointer type so the subsequent store's operand types
                    // agree with the pointer's declared type. `size` is
                    // LLVM's own real (alignment-padded) size for `ty`, not
                    // a Rust-side estimate -- the `store` below writes a
                    // full `ty`-typed aggregate, so an undersized estimate
                    // for a struct needing internal padding would silently
                    // corrupt whatever the *next* frame-allocated value
                    // occupies, without ever tripping the bounds check above.
                    let size = self.emit_sizeof_llvm_ty(&ty);
                    let byte_ptr = self.emit_frame_alloc(&size);
                    let typed_ptr = self.tmp_name();
                    self.line(&format!("  {} = bitcast i8* {} to {}*", typed_ptr, byte_ptr, ty));
                    let reg = self.emit_expr(value);
                    let clean_val = reg.strip_prefix(&format!("{} ", ty)).unwrap_or(&reg);
                    self.line(&format!("  store {} {}, {}* {}", ty, clean_val, ty, typed_ptr));
                    self.symbols.push((name.clone(), typed_ptr.clone(), vty.clone()));
                    self.track_owned(&typed_ptr, &vty);
                } else if let TypedExpr::ArrayRepeat { value: rep_val, count, elem_ty, .. } = value {
                    // Build straight into this binding's own storage instead
                    // of the generic `emit_expr` path's temp-alloca +
                    // whole-array load + second store -- see
                    // `Codegen::emit_array_repeat_into`'s doc comment (a
                    // `[N x T]`-typed SSA value is a real `clang` crash/hang
                    // risk once `N` gets into the tens of thousands, exactly
                    // what a Nova-16-style 64KB memory array needs).
                    let ptr = self.tmp_name();
                    self.line(&format!("  {} = alloca {}", ptr, ty));
                    self.emit_array_repeat_into(&ptr, rep_val, *count, elem_ty);
                    self.symbols.push((name.clone(), ptr.clone(), vty.clone()));
                    self.track_owned(&ptr, &vty);
                } else if let TypedExpr::StructLit { name: struct_name, args, ty: Ty::Named(_), .. } = value {
                    // Same idea for `let x = StructName(...)`: fill this
                    // binding's own alloca directly via
                    // `emit_struct_lit_fields_into` rather than building the
                    // struct in a private temp and copying the whole
                    // aggregate value over a second time -- the copy is
                    // wasted work in general, and a real correctness hazard
                    // (not just slow) when a field is itself a huge fixed
                    // array (`emit_struct_lit_fields_into` forwards those to
                    // `emit_array_repeat_into` in turn).
                    let ptr = self.tmp_name();
                    self.line(&format!("  {} = alloca {}", ptr, ty));
                    self.emit_struct_lit_fields_into(&ptr, struct_name, args);
                    self.symbols.push((name.clone(), ptr.clone(), vty.clone()));
                    self.track_owned(&ptr, &vty);
                } else if self.is_large_aggregate_ty(&vty) {
                    // Neither a fresh literal (handled directly above) nor a
                    // `frame:` binding -- but still large enough that the
                    // generic `else` branch's whole-aggregate `load`+`store`
                    // below is a real `clang` hang/crash risk (`todo.md` P0
                    // #2). Covers `let x = <existing large struct/array
                    // local>` (a copy) and `let x = <call returning one>` (a
                    // constructor function) via `emit_into_ptr`.
                    let ptr = self.tmp_name();
                    self.line(&format!("  {} = alloca {}", ptr, ty));
                    self.emit_into_ptr(&ptr, value, &vty);
                    self.symbols.push((name.clone(), ptr.clone(), vty.clone()));
                    self.track_owned(&ptr, &vty);
                } else {
                    let ptr = self.tmp_name();
                    self.line(&format!("  {} = alloca {}", ptr, ty));
                    let reg = self.emit_expr(value);
                    let clean_val = reg.strip_prefix(&format!("{} ", ty)).unwrap_or(&reg);
                    self.line(&format!("  store {} {}, {}* {}", ty, clean_val, ty, ptr));
                    self.symbols.push((name.clone(), ptr.clone(), vty.clone()));
                    self.track_owned(&ptr, &vty);
                }
            }
            TypedStmt::Assign { target, op, value, .. } => {
                let val_reg = self.emit_expr(value);
                if *op != AssignOp::Eq {
                    let loaded = self.load_target(target);
                    let tty = self.expr_ty(target);
                    let vty = self.expr_ty(value);
                    let compound = self.emit_assign_binop(&loaded, &tty, &val_reg, &vty, *op);
                    self.store_target(target, &compound);
                } else {
                    self.store_target(target, &val_reg);
                }
            }
            TypedStmt::Return { value, .. } => {
                if let (Some(v), Some(sret)) = (value, self.sret_ptr.clone()) {
                    // Aggregate-returning function (`Codegen::is_large_aggregate_ty`,
                    // see `emit_fn`'s doc comment on `sret_ptr`): build
                    // straight into the caller-supplied out-pointer via
                    // `emit_into_ptr` instead of materializing a
                    // whole-aggregate SSA value and `ret`-ing it -- the exact
                    // `clang` hang/crash risk `todo.md` P0 #2 is about.
                    let ty = self.expr_ty(v);
                    self.emit_into_ptr(&sret, v, &ty);
                    // Same reasoning as the ordinary scalar path below: any
                    // retain `emit_into_ptr` performed for a read of an
                    // existing owned slot must be balanced against releasing
                    // every open scope now, before the `ret`, so the caller
                    // ends up owning exactly one reference.
                    self.emit_releases_for_return();
                    self.line("  ret void");
                } else if let Some(v) = value {
                    let reg = self.emit_expr(v);
                    let ty = self.expr_ty(v);
                    // `emit_expr` returns some values already tagged with
                    // their LLVM type (literals) and others bare (loads,
                    // calls); strip any existing tag so it's never doubled.
                    let clean = self.untag(&reg, &ty);
                    // `emit_expr(v)` above already retained a fresh
                    // reference if `v` reads an existing owned slot (see
                    // `rc.rs`); releasing every currently-open scope *now*,
                    // before the `ret`, nets out to "the caller ends up
                    // owning exactly one reference" whether `v` is a bare
                    // local or a fresh construction.
                    self.emit_releases_for_return();
                    self.line(&format!("  ret {} {}", self.llvm_ty(&ty), clean));
                } else if self.in_main {
                    // `main` is always forced to `i32 @main(...)` (see
                    // `emit_fn`'s `is_main` special case) regardless of its
                    // declared return type, so a bare `return` here must
                    // still produce an `i32`-typed terminator -- `ret void`
                    // would disagree with the function's own declared
                    // signature and be rejected as invalid IR.
                    self.emit_releases_for_return();
                    self.line("  ret i32 0");
                } else {
                    self.emit_releases_for_return();
                    self.line("  ret void");
                }
            }
            TypedStmt::Expr(e) => {
                // A bare-statement expression's result is never bound,
                // returned, or stored anywhere -- but `emit_expr` may still
                // have handed back an owned RC reference (a fresh
                // construction like `list.pop()`/`concat(...)`, or a retain
                // on a read of an existing slot -- see `rc.rs`'s ownership
                // rule). With nothing left to hold that reference, it must
                // be released here or it leaks one heap block per call.
                let val = self.emit_expr(e);
                let ty = self.expr_ty(e);
                if self.contains_rc(&ty) {
                    let clean = self.untag(&val, &ty);
                    self.emit_release_bare(&clean, &ty);
                }
            }
            TypedStmt::If { cond, then_block, else_block, .. } => {
                // Each arm may itself end in an unconditional `return` (e.g.
                // the state-machine chain a `sequence` desugars to); a `ret`
                // is a terminator, so the synthetic `br %end` below must be
                // skipped for any arm that already terminated -- LLVM
                // rejects instructions following a terminator in the same
                // block. The `end` block itself is only emitted if at least
                // one arm can still reach it.
                let then_terminates = Self::body_terminates(&then_block.stmts);
                let else_terminates = else_block.as_ref().map(|b| Self::body_terminates(&b.stmts)).unwrap_or(false);
                let both_terminate = then_terminates && else_terminates;

                let cond_val = self.emit_expr(cond);
                let cond_reg = self.reg_of(&cond_val);
                let then_label = self.block_label("if_then");
                let else_label = self.block_label("if_else");
                let end_label = self.block_label("if_end");
                self.line(&format!("  br i1 {}, label %{}, label %{}", cond_reg, then_label, else_label));
                self.open_block(&then_label);
                self.push_scope();
                for stmt in &then_block.stmts {
                    self.emit_stmt(stmt);
                }
                self.pop_scope(!then_terminates);
                if !then_terminates {
                    self.line(&format!("  br label %{}", end_label));
                }
                self.open_block(&else_label);
                self.push_scope();
                if let Some(else_b) = else_block {
                    for stmt in &else_b.stmts {
                        self.emit_stmt(stmt);
                    }
                }
                self.pop_scope(!else_terminates);
                if !else_terminates {
                    self.line(&format!("  br label %{}", end_label));
                }
                if !both_terminate {
                    self.open_block(&end_label);
                }
            }
            TypedStmt::Frame { budget, body, .. } => { self.emit_frame_body(*budget, body); }
            TypedStmt::While { cond, then_block, else_block, .. } => {
                // If this loop is lexically inside a `frame:` block, snapshot
                // `@frame.off` *before* the loop's first iteration -- every
                // path out of an iteration (normal fallthrough, `continue`,
                // or `break`) restores it back to this exact value, reclaiming
                // that iteration's frame allocations so a many-iteration loop
                // doesn't exhaust the frame buffer just because nothing
                // reclaims space until the whole `frame:` block exits (see
                // `loop_stack`'s doc comment; `NOTES.md` section 1.2).
                let loop_frame_off = if self.in_frame {
                    let saved = self.tmp_name();
                    self.line(&format!("  {} = load i64, i64* @frame.off", saved));
                    Some(saved)
                } else {
                    None
                };
                let cond_label = self.block_label("while_cond");
                let body_label = self.block_label("while_body");
                let else_label = self.block_label("while_else");
                let end_label = self.block_label("while_end");
                // Loop header: evaluate the condition and branch.
                self.line(&format!("  br label %{}", cond_label));
                self.open_block(&cond_label);
                // `cond_label` is every iteration's shared exit choke point
                // (normal fallthrough branches here, and `continue` jumps
                // here directly), so restoring at its very top -- before
                // even evaluating `cond` -- reclaims the just-finished
                // iteration's frame allocations on both paths without
                // needing to touch `TypedStmt::Continue`'s own codegen at
                // all. A no-op store on the very first pass, before any
                // iteration has run yet.
                if let Some(saved) = &loop_frame_off {
                    self.line(&format!("  store i64 {}, i64* @frame.off", saved));
                }
                let cond_val = self.emit_expr(cond);
                let cond_reg = self.reg_of(&cond_val);
                // The condition's false branch must go to `else_label`, not
                // straight to `end_label` -- `else_label` falls through to
                // `end_label` on its own a few lines down, so this is the
                // *only* predecessor that ever reaches it. Previously this
                // branched directly to `end_label`, making the `else` clause
                // a permanently unreachable orphan block: `while cond: ...
                // else: ...` silently never ran its `else` body, even though
                // it's documented to run whenever the loop exits normally
                // (not via `break`).
                self.line(&format!("  br i1 {}, label %{}, label %{}", cond_reg, body_label, else_label));
                // Loop body: runs, then jumps back to the condition. `break`
                // targets `end_label` and `continue` targets `cond_label`
                // directly (re-evaluating the condition has no side effects).
                self.open_block(&body_label);
                let depth_at_entry = self.owned_stack.len();
                self.push_scope();
                self.loop_stack.push((cond_label.clone(), end_label.clone(), depth_at_entry, loop_frame_off.clone()));
                for stmt in &then_block.stmts {
                    self.emit_stmt(stmt);
                }
                self.loop_stack.pop();
                let body_terminates = Self::body_terminates(&then_block.stmts);
                self.pop_scope(!body_terminates);
                if !body_terminates {
                    self.line(&format!("  br label %{}", cond_label));
                }
                // Optional else clause runs once after the loop exits, then joins end.
                self.open_block(&else_label);
                self.push_scope();
                if let Some(else_b) = else_block {
                    for stmt in &else_b.stmts {
                        self.emit_stmt(stmt);
                    }
                }
                // Same reasoning as the `if`-statement's `else` branch above
                // (and the loop body just above it): an else-clause ending in
                // `return`/`break`/`continue` already emitted its own
                // terminator, so falling through to `end_label` unconditionally
                // here would place further instructions after it -- invalid
                // LLVM IR.
                let else_terminates = else_block.as_ref().is_some_and(|b| Self::body_terminates(&b.stmts));
                self.pop_scope(!else_terminates);
                if !else_terminates {
                    self.line(&format!("  br label %{}", end_label));
                }
                self.open_block(&end_label);
            }
            TypedStmt::For { var, start, end, body, .. } => {
                self.emit_for_stmt(var, start, end, body);
            }
            TypedStmt::Break { .. } => {
                let target = self.loop_stack.last().cloned();
                let break_label = target.as_ref().map(|(_, b, _, _)| b.clone()).unwrap_or_else(|| {
                    self.err("`break` outside of a loop", Span::dummy());
                    "undef".into()
                });
                if let Some((_, _, depth, frame_off)) = &target {
                    self.emit_releases_since(*depth);
                    // Unlike normal fallthrough/`continue` (which both
                    // funnel through the loop's own continue-target block,
                    // where the restore already lives -- see
                    // `TypedStmt::While`/`emit_for_stmt`), `break` jumps
                    // straight to `end_label`, bypassing that block
                    // entirely, so it needs its own copy of the same
                    // restore to reclaim the just-abandoned iteration's
                    // frame allocations before leaving the loop for good.
                    if let Some(saved) = frame_off {
                        self.line(&format!("  store i64 {}, i64* @frame.off", saved));
                    }
                }
                self.line(&format!("  br label %{}", break_label));
            }
            TypedStmt::Continue { .. } => {
                let target = self.loop_stack.last().cloned();
                let continue_label = target.as_ref().map(|(c, _, _, _)| c.clone()).unwrap_or_else(|| {
                    self.err("`continue` outside of a loop", Span::dummy());
                    "undef".into()
                });
                if let Some((_, _, depth, _)) = target {
                    self.emit_releases_since(depth);
                }
                self.line(&format!("  br label %{}", continue_label));
            }
            TypedStmt::Par { var, elem_ty, arena, body, .. } => {
                self.emit_par_stmt(var, elem_ty, arena, body);
            }
            TypedStmt::Each { var, index_var, elem_ty, arena, body, .. } => {
                self.emit_each_stmt(var, index_var, elem_ty, arena, body);
            }
            TypedStmt::Spawn { arena, elem, .. } => {
                self.emit_spawn_stmt(arena, elem);
            }
            TypedStmt::Despawn { arena, index, .. } => {
                self.emit_despawn_stmt(arena, index);
            }
            TypedStmt::Parallel { systems, .. } => {
                self.emit_parallel_stmt(systems);
            }
        }
    }

    /// Emit `for var in start..end: <body>`: an `i32` counter alloca,
    /// incremented in a dedicated step block so `continue` can jump straight
    /// to the increment without re-running the loop body.
    fn emit_for_stmt(&mut self, var: &str, start: &TypedExpr, end: &TypedExpr, body: &TypedBlock) {
        let start_val = self.emit_expr(start);
        let start_bare = self.untag(&start_val, &Ty::Int);
        let end_val = self.emit_expr(end);
        let end_bare = self.untag(&end_val, &Ty::Int);

        let i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", i_ptr));
        self.line(&format!("  store i32 {}, i32* {}", start_bare, i_ptr));

        // See `TypedStmt::While`'s identical snapshot -- this is `for`'s
        // equivalent per-iteration frame-reclaim checkpoint (`NOTES.md`
        // section 1.2's own confirmed repro: 768 iterations over a `Cell`
        // struct via exactly this `for`-loop shape).
        let loop_frame_off = if self.in_frame {
            let saved = self.tmp_name();
            self.line(&format!("  {} = load i64, i64* @frame.off", saved));
            Some(saved)
        } else {
            None
        };

        let cond_label = self.block_label("for_cond");
        let body_label = self.block_label("for_body");
        let step_label = self.block_label("for_step");
        let end_label = self.block_label("for_end");

        self.line(&format!("  br label %{}", cond_label));
        self.open_block(&cond_label);
        let i_reg = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", i_reg, i_ptr));
        let cmp = self.tmp_name();
        self.line(&format!("  {} = icmp slt i32 {}, {}", cmp, i_reg, end_bare));
        self.line(&format!("  br i1 {}, label %{}, label %{}", cmp, body_label, end_label));

        self.open_block(&body_label);
        self.symbols.push((var.to_string(), i_ptr.clone(), Ty::Int));
        let depth_at_entry = self.owned_stack.len();
        self.push_scope();
        self.loop_stack.push((step_label.clone(), end_label.clone(), depth_at_entry, loop_frame_off.clone()));
        for stmt in &body.stmts {
            self.emit_stmt(stmt);
        }
        self.loop_stack.pop();
        self.symbols.pop();
        let body_terminates = Self::body_terminates(&body.stmts);
        self.pop_scope(!body_terminates);
        if !body_terminates {
            self.line(&format!("  br label %{}", step_label));
        }

        self.open_block(&step_label);
        // `step_label` is every iteration's shared exit choke point (normal
        // fallthrough branches here, and `continue` jumps here directly --
        // see `emit_for_stmt`'s own doc comment) -- restoring at its very
        // top, before the increment, reclaims the just-finished iteration's
        // frame allocations on both paths. A no-op store on the very first
        // pass, before any iteration has run yet.
        if let Some(saved) = &loop_frame_off {
            self.line(&format!("  store i64 {}, i64* @frame.off", saved));
        }
        let i_reg2 = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", i_reg2, i_ptr));
        let i_next = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", i_next, i_reg2));
        self.line(&format!("  store i32 {}, i32* {}", i_next, i_ptr));
        self.line(&format!("  br label %{}", cond_label));

        self.open_block(&end_label);
    }

    fn load_target(&mut self, target: &TypedExpr) -> String {
        match target {
            TypedExpr::Ident { name, ty, .. } => {
                let ptr = self.sym_ptr(name).unwrap_or_else(|| "%undef".into());
                let reg = self.tmp_name();
                let ts = self.llvm_ty(ty);
                self.line(&format!("  {} = load {}, {}* {}", reg, ts, ts, ptr));
                reg
            }
            TypedExpr::Field { base, field, ty, .. } => {
                if self.expr_ty(base).is_vec() {
                    let val = self.emit_swizzle_read(base, field);
                    return self.reg_of(&val);
                }
                let base_ptr = self.emit_place(base);
                let gep = self.tmp_name();
                let bty = self.llvm_ty(&self.expr_ty(base));
                let idx = self.field_index(&self.expr_ty(base), field);
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", gep, bty, bty, base_ptr, idx));
                let reg = self.tmp_name();
                let ts = self.llvm_ty(ty);
                self.line(&format!("  {} = load {}, {}* {}", reg, ts, ts, gep));
                reg
            }
            TypedExpr::ListIndex { base, index, ty, .. } => {
                let val = self.emit_list_index(base, index, ty);
                self.reg_of(&val)
            }
            TypedExpr::ArrayIndex { base, index, ty, .. } => {
                let Ty::Array(_, count) = self.expr_ty(base) else { unreachable!("ArrayIndex base must be Ty::Array") };
                let val = self.emit_array_index(base, index, ty, count);
                self.reg_of(&val)
            }
            TypedExpr::RingIndex { base, index, ty, .. } => {
                let Ty::Ring(_, count) = self.expr_ty(base) else { unreachable!("RingIndex base must be Ty::Ring") };
                let ptr = self.emit_ring_index_read_place(base, index, ty, count);
                let elem_llvm = self.llvm_ty(ty);
                let reg = self.tmp_name();
                self.line(&format!("  {} = load {}, {}* {}", reg, elem_llvm, elem_llvm, ptr));
                reg
            }
            TypedExpr::TupleIndex { base, index, ty, .. } => {
                let base_ptr = self.emit_place(base);
                let gep = self.tmp_name();
                let bty = self.llvm_ty(&self.expr_ty(base));
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", gep, bty, bty, base_ptr, index));
                let reg = self.tmp_name();
                let ts = self.llvm_ty(ty);
                self.line(&format!("  {} = load {}, {}* {}", reg, ts, ts, gep));
                reg
            }
            TypedExpr::TableIndex { base, index, ty, .. } => {
                let val = self.emit_table_index(base, index, ty);
                self.reg_of(&val)
            }
            _ => { self.err("cannot load from this expression", Span::dummy()); "%undef".into() }
        }
    }

    fn store_target(&mut self, target: &TypedExpr, val: &str) {
        match target {
            TypedExpr::Ident { name, ty, .. } => {
                let ptr = self.sym_ptr(name).unwrap_or_else(|| "%undef".into());
                let ts = self.llvm_ty(ty);
                let clean_val = val.strip_prefix(&format!("{} ", ts)).unwrap_or(val);
                // The new value was already computed (and retained, if it's
                // a copy -- see `rc.rs`) above; releasing the slot's old
                // contents *after* that, right before overwriting it, keeps
                // `x = x` self-assignment safe (the fresh retain balances
                // the matching release instead of releasing first and
                // storing a stale, already-freed pointer).
                self.emit_release_at(&ptr, ty);
                self.line(&format!("  store {} {}, {}* {}", ts, clean_val, ts, ptr));
            }
            TypedExpr::Field { base, field, ty, .. } => {
                if self.expr_ty(base).is_vec() {
                    self.emit_swizzle_write(base, field, ty, val);
                    return;
                }
                // `r[0].field = v`: routed through a dedicated codegen path
                // rather than the generic `emit_place(base)` GEP-and-store
                // below, since that generic path can't release `val` on a
                // stale/OOB `GenRef` (whose place resolution hands back a
                // disconnected dummy) -- see `store_genref_field`'s doc
                // comment for the leak this closes.
                if let TypedExpr::GenRefIndex { base: genref_base, ty: elem_ty, span, .. } = base.as_ref() {
                    self.store_genref_field(genref_base, elem_ty, field, ty, val, *span);
                    return;
                }
                // `table[idx].field = v`: routed through the dedicated,
                // leak-safe `store_table_field` rather than the generic
                // `emit_place(base)` GEP-and-store below -- that generic
                // path can't release `val` on an out-of-bounds row (whose
                // place resolution hands back a disconnected dummy), the
                // exact same leak class `store_genref_field` above closes
                // for `GenRef<T>`. See `store_table_field`'s own doc comment.
                if let TypedExpr::TableIndex { base: table_base, index, ty: elem_ty, .. } = base.as_ref() {
                    self.store_table_field(table_base, index, elem_ty, field, val);
                    return;
                }
                let base_ptr = self.emit_place(base);
                let gep = self.tmp_name();
                let bty = self.llvm_ty(&self.expr_ty(base));
                let idx = self.field_index(&self.expr_ty(base), field);
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", gep, bty, bty, base_ptr, idx));
                let ts = self.llvm_ty(ty);
                let clean_val = val.strip_prefix(&format!("{} ", ts)).unwrap_or(val);
                self.emit_release_at(&gep, ty);
                self.line(&format!("  store {} {}, {}* {}", ts, clean_val, ts, gep));
            }
            TypedExpr::ListIndex { base, index, ty, .. } => {
                self.store_list_index(base, index, ty, val);
            }
            TypedExpr::ArrayIndex { base, index, ty, .. } => {
                let Ty::Array(_, count) = self.expr_ty(base) else { unreachable!("ArrayIndex base must be Ty::Array") };
                self.store_array_index(base, index, ty, count, val);
            }
            TypedExpr::RingIndex { base, index, ty, .. } => {
                let Ty::Ring(_, count) = self.expr_ty(base) else { unreachable!("RingIndex base must be Ty::Ring") };
                self.store_ring_index(base, index, ty, count, val);
            }
            TypedExpr::TableIndex { base, index, ty, .. } => {
                self.store_table_index(base, index, ty, val);
            }
            TypedExpr::TupleIndex { base, index, ty, .. } => {
                if let TypedExpr::GenRefIndex { base: genref_base, ty: elem_ty, span, .. } = base.as_ref() {
                    self.store_genref_tuple_index(genref_base, elem_ty, *index as u32, ty, val, *span);
                    return;
                }
                let base_ptr = self.emit_place(base);
                let gep = self.tmp_name();
                let bty = self.llvm_ty(&self.expr_ty(base));
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 {}", gep, bty, bty, base_ptr, index));
                let ts = self.llvm_ty(ty);
                let clean_val = val.strip_prefix(&format!("{} ", ts)).unwrap_or(val);
                self.emit_release_at(&gep, ty);
                self.line(&format!("  store {} {}, {}* {}", ts, clean_val, ts, gep));
            }
            TypedExpr::GenRefIndex { base, ty, span, .. } => {
                self.store_genref_whole(base, ty, val, *span);
            }
            _ => { self.err("cannot store to this expression", Span::dummy()); }
        }
    }
}

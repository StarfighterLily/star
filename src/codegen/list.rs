//! `List<T>` codegen: a growable, heap-allocated dynamic array lowered to a
//! reference-counted, copy-on-write `i8*` object pointer -- the same
//! allocation scheme `Ty::Str` uses (`Codegen::llvm_ty`'s `Ty::List` arm),
//! pointing past a `star_rc_alloc` header at a `{ T* data, i64 len, i64 cap }`
//! payload.
//!
//! `let b = a` is an O(1) refcount bump (both bindings share the same
//! object), but every *mutating* operation (`push`, `pop`, index-assignment)
//! first calls `Codegen::emit_list_ensure_unique`, which clones the buffer if
//! it isn't the sole owner -- so mutating through one alias is never visible
//! through another, even though non-mutating copies are free. Growth still
//! doubles (`malloc` a bigger buffer, `memcpy` the old contents, `free` the
//! old buffer) whenever `push` finds `len == cap`, same as before, but now
//! safely: copy-on-write has already guaranteed the buffer being grown has
//! exactly one owner. Every out-of-bounds read/removal on an empty list
//! yields the element type's zero value rather than erroring at runtime,
//! mirroring `GenRef`'s "safe null equivalent" convention (see design.md);
//! an out-of-bounds *write* is a silent no-op, mirroring `despawn`'s
//! already-dead-slot handling in `crate::codegen::arena`.

use crate::diagnostics::Span;
use crate::types::*;

use super::Codegen;

impl Codegen {
    /// The anonymous LLVM struct type for `List<elem_ty>`'s heap *payload*
    /// (as opposed to `Codegen::llvm_ty`'s `i8*` object-pointer type) --
    /// what a `List<T>` object pointer points at, past its `star_rc_alloc`
    /// header. Always routed through this helper (rather than formatted
    /// ad-hoc) so every call site agrees byte-for-byte on the type's
    /// textual spelling.
    fn list_payload_llvm_ty(&self, elem_ty: &Ty) -> String {
        format!("{{ {}*, i64, i64 }}", self.llvm_ty(elem_ty))
    }

    /// Lazily generate (and cache, keyed by `Codegen::mangle_ty`) the
    /// `list_release_<mangled_elem>` thunk for `elem_ty`, returning the
    /// bitcast-to-`i8*` operand to pass as `star_rc_alloc`'s `release_fn`
    /// argument. Every `List<elem_ty>` allocation site (a list literal,
    /// `push`'s grow, a copy-on-write clone) shares one thunk instead of
    /// each emitting a duplicate `define` -- mirrors the per-closure
    /// `closure_N_release_env` thunk in `crate::codegen::closure`, except
    /// keyed by element type rather than by call-site id, since many list
    /// allocations of the same element type are expected.
    ///
    /// Unlike a closure's `release_fn` (`null` when no captured field needs
    /// releasing), a list's release thunk is never `null`: it always owns a
    /// separately `malloc`'d `data` buffer that must be `free`d once the
    /// object's last reference goes away, regardless of whether `elem_ty`
    /// itself carries any RC content.
    fn list_release_thunk_operand(&mut self, elem_ty: &Ty) -> String {
        let key = self.mangle_ty(elem_ty);
        if let Some(name) = self.list_release_thunks.get(&key).cloned() {
            let reg = self.tmp_name();
            self.line(&format!("  {} = bitcast void (i8*)* @{} to i8*", reg, name));
            return reg;
        }

        let name = format!("list_release_{}", key);
        self.list_release_thunks.insert(key, name.clone());

        let elem_llvm = self.llvm_ty(elem_ty);
        let payload_ty = self.list_payload_llvm_ty(elem_ty);
        let elem_has_rc = self.contains_rc(elem_ty);

        let saved_ir = std::mem::take(&mut self.ir);
        self.line(&format!("define void @{}(i8* %objp) {{", name));
        self.open_block("entry");
        let payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* %objp to {}*", payload, payload_ty));
        let data_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", data_field, payload_ty, payload_ty, payload));
        let data = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** {}", data, elem_llvm, elem_llvm, data_field));

        if elem_has_rc {
            let len_field = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", len_field, payload_ty, payload_ty, payload));
            let len = self.tmp_name();
            self.line(&format!("  {} = load i64, i64* {}", len, len_field));

            let i_ptr = self.tmp_name();
            self.line(&format!("  {} = alloca i64", i_ptr));
            self.line(&format!("  store i64 0, i64* {}", i_ptr));

            let cond_label = self.block_label("list_release_cond");
            let body_label = self.block_label("list_release_body");
            let end_label = self.block_label("list_release_end");
            self.line(&format!("  br label %{}", cond_label));
            self.open_block(&cond_label);
            let i_reg = self.tmp_name();
            self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
            let cmp = self.tmp_name();
            self.line(&format!("  {} = icmp slt i64 {}, {}", cmp, i_reg, len));
            self.line(&format!("  br i1 {}, label %{}, label %{}", cmp, body_label, end_label));

            self.open_block(&body_label);
            let elem_ptr = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, elem_llvm, elem_llvm, data, i_reg));
            self.emit_release_at(&elem_ptr, elem_ty);
            let i_next = self.tmp_name();
            self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
            self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
            self.line(&format!("  br label %{}", cond_label));

            self.open_block(&end_label);
        }

        let data_i8 = self.tmp_name();
        self.line(&format!("  {} = bitcast {}* {} to i8*", data_i8, elem_llvm, data));
        self.line(&format!("  call void @free(i8* {})", data_i8));
        self.line("  ret void");
        self.line("}");
        self.line("");
        let fn_ir = std::mem::replace(&mut self.ir, saved_ir);
        self.pending_top.push(Self::hoist_allocas_to_entry(&fn_ir));

        let reg = self.tmp_name();
        self.line(&format!("  {} = bitcast void (i8*)* @{} to i8*", reg, name));
        reg
    }

    /// `List<T>()`: the empty list is `null` -- no allocation up front (a
    /// real, uniquely-owned empty object is lazily allocated the first time
    /// `emit_list_ensure_unique` sees it, i.e. on first mutation), mirroring
    /// how a `Str` value's "nothing yet" state is also `null`.
    pub(super) fn emit_list_new(&mut self, _elem_ty: &Ty) -> String {
        "i8* null".into()
    }

    /// A non-empty list literal `[e1, e2, ...]`: `malloc` a tightly-sized
    /// buffer up front (`len == cap`, so the first `push` after this
    /// immediately grows it -- acceptable, this isn't a hot path), then
    /// allocate a fresh, uniquely-owned (refcount 1) RC object around it.
    pub(super) fn emit_list_lit(&mut self, elems: &[TypedExpr], elem_ty: &Ty) -> String {
        let elem_llvm = self.llvm_ty(elem_ty);
        let n = elems.len() as u64;
        // Real, LLVM-computed element size (see `Codegen::emit_sizeof_llvm_ty`'s
        // doc comment) -- this buffer is indexed via `getelementptr` against
        // `elem_llvm` below, so its allocated size must match that stride
        // exactly, not a Rust-side estimate that could undersize it for a
        // struct element type needing internal padding.
        let elem_size = self.emit_sizeof_llvm_ty(&elem_llvm);
        let bytes = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, {}", bytes, elem_size, n));

        let raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", raw, bytes));
        let data = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", data, raw, elem_llvm));
        for (i, e) in elems.iter().enumerate() {
            let val = self.emit_expr(e);
            let clean = self.untag(&val, elem_ty);
            let gep = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", gep, elem_llvm, elem_llvm, data, i));
            self.line(&format!("  store {} {}, {}* {}", elem_llvm, clean, elem_llvm, gep));
        }

        let payload_ty = self.list_payload_llvm_ty(elem_ty);
        let release_fn = self.list_release_thunk_operand(elem_ty);
        let obj_raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 24, i8* {})", obj_raw, release_fn));
        let payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", payload, obj_raw, payload_ty));
        let data_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", data_field, payload_ty, payload_ty, payload));
        self.line(&format!("  store {}* {}, {}** {}", elem_llvm, data, elem_llvm, data_field));
        let len_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", len_field, payload_ty, payload_ty, payload));
        self.line(&format!("  store i64 {}, i64* {}", n, len_field));
        let cap_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", cap_field, payload_ty, payload_ty, payload));
        self.line(&format!("  store i64 {}, i64* {}", n, cap_field));

        format!("i8* {}", obj_raw)
    }

    /// `bytes_from_str(s) -> Bytes`: a fresh, independent copy of `s`'s bytes
    /// (excluding the trailing null terminator `str` always carries but
    /// `Bytes` never does), wrapped in the exact same `{ u8*, i64, i64 }`/
    /// `star_rc_alloc` object `List<u8>` uses -- see `Ty::Bytes`'s doc
    /// comment for why `Bytes` reuses `List<u8>`'s layout wholesale.
    /// Structurally `emit_list_lit`'s tail (malloc a tightly-sized buffer,
    /// wrap it in a fresh RC object), just filling the buffer via one
    /// `memcpy` from `s`'s own bytes instead of a compile-time list of
    /// element expressions.
    pub(super) fn emit_bytes_from_str(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("bytes_from_str(..) expects 1 argument", Span::dummy());
            return "i8* null".into();
        };
        let raw = self.emit_raw_str_ptr(arg);
        let len32 = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", len32, raw));
        let n = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", n, len32));

        let new_raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", new_raw, n));
        self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", new_raw, raw, n));
        // `raw` is done being read -- release whatever `emit_raw_str_ptr`
        // left us owning (see its own doc comment for why this can't happen
        // inside that function itself).
        self.line(&format!("  call void @star_rc_release(i8* {})", raw));

        let payload_ty = self.list_payload_llvm_ty(&Ty::U8);
        let release_fn = self.list_release_thunk_operand(&Ty::U8);
        let obj_raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 24, i8* {})", obj_raw, release_fn));
        let payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", payload, obj_raw, payload_ty));
        let data_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", data_field, payload_ty, payload_ty, payload));
        self.line(&format!("  store i8* {}, i8** {}", new_raw, data_field));
        let len_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", len_field, payload_ty, payload_ty, payload));
        self.line(&format!("  store i64 {}, i64* {}", n, len_field));
        let cap_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", cap_field, payload_ty, payload_ty, payload));
        self.line(&format!("  store i64 {}, i64* {}", n, cap_field));

        format!("i8* {}", obj_raw)
    }

    /// `str_from_bytes(b) -> str`: a fresh, independent, null-terminated
    /// copy of `b`'s bytes -- the reverse of `emit_bytes_from_str`. Reads
    /// `b`'s fields via `list_fields` (retain-free, matching every other
    /// plain-read builtin/method -- `b` itself is untouched).
    pub(super) fn emit_str_from_bytes(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("str_from_bytes(..) expects 1 argument", Span::dummy());
            return "i8* null".into();
        };
        let (data, len) = self.list_fields(arg, &Ty::U8);

        let total = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", total, len));
        let buf = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 {}, i8* null)", buf, total));
        self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", buf, data, len));
        let nul = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", nul, buf, len));
        self.line(&format!("  store i8 0, i8* {}", nul));

        format!("i8* {}", buf)
    }

    /// `args() -> List<str>`: the process's command-line arguments,
    /// including `argv[0]` (the program path) -- the same convention the
    /// underlying OS/CRT argv itself uses. Reads `@star.argc`/`@star.argv`
    /// (populated once, at process start, by `Codegen::emit_fn`'s `is_main`
    /// special case) and copies each `char*` into a fresh, owned `str` via
    /// the same strlen+alloc+strcpy shape `emit_ptr_to_str` uses -- argv's
    /// strings are plain C strings with no RC header (owned by the CRT, not
    /// Star), so they're duplicated rather than referenced directly.
    /// Otherwise structurally identical to `emit_list_lit`'s tail (malloc a
    /// tightly-sized buffer, wrap it in a fresh RC object), just filling the
    /// buffer from a runtime loop over `argv` instead of a compile-time
    /// list of element expressions.
    pub(super) fn emit_args(&mut self) -> String {
        let elem_ty = Ty::Str;
        let elem_llvm = self.llvm_ty(&elem_ty);

        let argc32 = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* @star.argc", argc32));
        let argc64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", argc64, argc32));
        let argv = self.tmp_name();
        self.line(&format!("  {} = load i8**, i8*** @star.argv", argv));

        let bytes = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, 8", bytes, argc64));
        let raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", raw, bytes));
        let data = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", data, raw, elem_llvm));

        let i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", i_ptr));
        self.line(&format!("  store i64 0, i64* {}", i_ptr));

        let cond_label = self.block_label("args_cond");
        let body_label = self.block_label("args_body");
        let end_label = self.block_label("args_end");
        self.line(&format!("  br label %{}", cond_label));
        self.open_block(&cond_label);
        let i_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
        let cmp = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", cmp, i_reg, argc64));
        self.line(&format!("  br i1 {}, label %{}, label %{}", cmp, body_label, end_label));

        self.open_block(&body_label);
        let argv_elem_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8*, i8** {}, i64 {}", argv_elem_ptr, argv, i_reg));
        let c_str = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", c_str, argv_elem_ptr));
        let len = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", len, c_str));
        let total = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", total, len));
        let total64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", total64, total));
        let owned = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 {}, i8* null)", owned, total64));
        self.line(&format!("  call i8* @strcpy(i8* {}, i8* {})", owned, c_str));
        let dest_elem_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", dest_elem_ptr, elem_llvm, elem_llvm, data, i_reg));
        self.line(&format!("  store {} {}, {}* {}", elem_llvm, owned, elem_llvm, dest_elem_ptr));
        let i_next = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
        self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
        self.line(&format!("  br label %{}", cond_label));

        self.open_block(&end_label);

        let payload_ty = self.list_payload_llvm_ty(&elem_ty);
        let release_fn = self.list_release_thunk_operand(&elem_ty);
        let obj_raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 24, i8* {})", obj_raw, release_fn));
        let payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", payload, obj_raw, payload_ty));
        let data_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", data_field, payload_ty, payload_ty, payload));
        self.line(&format!("  store {}* {}, {}** {}", elem_llvm, data, elem_llvm, data_field));
        let len_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", len_field, payload_ty, payload_ty, payload));
        self.line(&format!("  store i64 {}, i64* {}", argc64, len_field));
        let cap_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", cap_field, payload_ty, payload_ty, payload));
        self.line(&format!("  store i64 {}, i64* {}", argc64, cap_field));

        format!("i8* {}", obj_raw)
    }

    /// Copy-on-write gate for every *mutating* list operation (`push`,
    /// `pop`, index-assignment). `slot_ptr` is the address of the
    /// variable's own storage (an `i8**`, from `emit_place`) holding a
    /// `List<elem_ty>` object pointer. After this call, the object pointer
    /// stored at `slot_ptr` (which callers must reload) is guaranteed
    /// uniquely owned -- safe to mutate its `data` buffer or `len`/`cap`
    /// fields in place without that mutation becoming visible through any
    /// other alias.
    fn emit_list_ensure_unique(&mut self, slot_ptr: &str, elem_ty: &Ty) {
        let elem_llvm = self.llvm_ty(elem_ty);
        // Real, LLVM-computed element size (see `Codegen::emit_sizeof_llvm_ty`'s
        // doc comment) -- both the clone buffer's `malloc` and the `memcpy`
        // byte count below index/stride by `elem_llvm` via `getelementptr`,
        // so an undersized Rust-side estimate would both under-allocate the
        // new buffer *and* under-copy the live prefix for a struct element
        // type needing internal padding.
        let elem_size = self.emit_sizeof_llvm_ty(&elem_llvm);
        let payload_ty = self.list_payload_llvm_ty(elem_ty);

        let obj = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", obj, slot_ptr));
        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, obj));
        let alloc_label = self.block_label("list_cow_alloc");
        let check_label = self.block_label("list_cow_check");
        let done_label = self.block_label("list_cow_done");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, alloc_label, check_label));

        // Never-allocated list (the zero value): allocate a fresh, empty,
        // uniquely-owned object rather than treating `null` as a special
        // "shared empty" sentinel.
        self.open_block(&alloc_label);
        let release_fn0 = self.list_release_thunk_operand(elem_ty);
        let raw0 = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 24, i8* {})", raw0, release_fn0));
        let payload0 = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", payload0, raw0, payload_ty));
        let d0 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", d0, payload_ty, payload_ty, payload0));
        self.line(&format!("  store {}* null, {}** {}", elem_llvm, elem_llvm, d0));
        let l0 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", l0, payload_ty, payload_ty, payload0));
        self.line(&format!("  store i64 0, i64* {}", l0));
        let c0 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", c0, payload_ty, payload_ty, payload0));
        self.line(&format!("  store i64 0, i64* {}", c0));
        self.line(&format!("  store i8* {}, i8** {}", raw0, slot_ptr));
        self.line(&format!("  br label %{}", done_label));

        // Already allocated: peek the refcount (same header offset math
        // `star_rc_retain`/`star_rc_release` use, inlined here since it's
        // only needed for this uniqueness check) to decide unique vs.
        // shared.
        self.open_block(&check_label);
        let hdr_i8 = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 -16", hdr_i8, obj));
        let hdr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i64*", hdr, hdr_i8));
        let rc = self.tmp_name();
        self.line(&format!("  {} = load atomic i64, i64* {} seq_cst, align 8", rc, hdr));
        let is_unique = self.tmp_name();
        self.line(&format!("  {} = icmp eq i64 {}, 1", is_unique, rc));
        let clone_label = self.block_label("list_cow_clone");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_unique, done_label, clone_label));

        // Shared: clone into a fresh object before this operation is
        // allowed to mutate anything.
        self.open_block(&clone_label);
        let old_payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", old_payload, obj, payload_ty));
        let od_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", od_field, payload_ty, payload_ty, old_payload));
        let od = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** {}", od, elem_llvm, elem_llvm, od_field));
        let ol_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", ol_field, payload_ty, payload_ty, old_payload));
        let ol = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", ol, ol_field));
        let oc_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", oc_field, payload_ty, payload_ty, old_payload));
        let oc = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", oc, oc_field));

        let release_fn1 = self.list_release_thunk_operand(elem_ty);
        let new_raw = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 24, i8* {})", new_raw, release_fn1));
        let new_payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", new_payload, new_raw, payload_ty));

        let new_bytes = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, {}", new_bytes, oc, elem_size));
        let new_raw_data = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", new_raw_data, new_bytes));
        let new_data = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", new_data, new_raw_data, elem_llvm));

        // Only copy/retain when there's actually a live prefix (`cap` may
        // exceed `len`, and either may be zero on a list that was never
        // pushed onto after a prior pop-to-empty).
        let has_len = self.tmp_name();
        self.line(&format!("  {} = icmp sgt i64 {}, 0", has_len, ol));
        let copy_label = self.block_label("list_cow_copy");
        let after_copy_label = self.block_label("list_cow_after_copy");
        self.line(&format!("  br i1 {}, label %{}, label %{}", has_len, copy_label, after_copy_label));

        self.open_block(&copy_label);
        let old_bytes = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, {}", old_bytes, ol, elem_size));
        let old_raw_data = self.tmp_name();
        self.line(&format!("  {} = bitcast {}* {} to i8*", old_raw_data, elem_llvm, od));
        self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", new_raw_data, old_raw_data, old_bytes));
        if self.contains_rc(elem_ty) {
            // The clone now holds an additional reference to every shared
            // sub-object its elements point at -- retain each one, same
            // shape as the release thunk's element loop above.
            let i_ptr = self.tmp_name();
            self.line(&format!("  {} = alloca i64", i_ptr));
            self.line(&format!("  store i64 0, i64* {}", i_ptr));
            let cond_label = self.block_label("list_cow_retain_cond");
            let body_label = self.block_label("list_cow_retain_body");
            let retain_end_label = self.block_label("list_cow_retain_end");
            self.line(&format!("  br label %{}", cond_label));
            self.open_block(&cond_label);
            let i_reg = self.tmp_name();
            self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
            let cmp = self.tmp_name();
            self.line(&format!("  {} = icmp slt i64 {}, {}", cmp, i_reg, ol));
            self.line(&format!("  br i1 {}, label %{}, label %{}", cmp, body_label, retain_end_label));
            self.open_block(&body_label);
            let elem_ptr = self.tmp_name();
            self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, elem_llvm, elem_llvm, new_data, i_reg));
            self.emit_retain_at(&elem_ptr, elem_ty);
            let i_next = self.tmp_name();
            self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
            self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
            self.line(&format!("  br label %{}", cond_label));
            self.open_block(&retain_end_label);
        }
        self.line(&format!("  br label %{}", after_copy_label));

        self.open_block(&after_copy_label);
        let nd_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", nd_field, payload_ty, payload_ty, new_payload));
        self.line(&format!("  store {}* {}, {}** {}", elem_llvm, new_data, elem_llvm, nd_field));
        let nl_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", nl_field, payload_ty, payload_ty, new_payload));
        self.line(&format!("  store i64 {}, i64* {}", ol, nl_field));
        let nc_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", nc_field, payload_ty, payload_ty, new_payload));
        self.line(&format!("  store i64 {}, i64* {}", oc, nc_field));

        // Drop this binding's reference to the old (still-shared-by-others)
        // object; safe to route through the ordinary release call rather
        // than hand-rolling the decrement, since we already know it won't
        // hit zero here (refcount was > 1).
        self.line(&format!("  call void @star_rc_release(i8* {})", obj));
        self.line(&format!("  store i8* {}, i8** {}", new_raw, slot_ptr));
        self.line(&format!("  br label %{}", done_label));

        self.open_block(&done_label);
    }

    /// Read path: resolve `base`'s `(data, len)`, with no copy-on-write
    /// check (reading never needs to unshare a buffer) and no crash on the
    /// zero value -- `null` (a list that was constructed but never
    /// mutated) reads as `data = null, len = 0` rather than dereferencing
    /// through a null object pointer.
    ///
    /// A nested list-index base (`m[0][1]`, `m[0].len()`) must not resolve
    /// through `Codegen::emit_place`'s `ListIndex` arm: that arm exists for
    /// *writes* (`emit_list_index_place`), which unconditionally runs the
    /// copy-on-write uniqueness gate (`emit_list_ensure_unique`) on `m`
    /// itself before returning a pointer into it -- silently cloning `m`
    /// and un-aliasing it from any other variable sharing its buffer, as a
    /// side effect of a plain read, and doing so regardless of whether `m`'s
    /// own Star-level binding was even declared `mut`. Resolved instead via
    /// `list_index_read_obj`, which peeks at the loaded element without
    /// retaining it -- safe because nothing releases `inner_base`'s own
    /// reference for the remainder of this single, straight-line
    /// expression, so the object it points at is guaranteed to stay alive
    /// long enough to read through here without needing an independent,
    /// owned copy of its own.
    fn list_fields(&mut self, base: &TypedExpr, elem_ty: &Ty) -> (String, String) {
        if let TypedExpr::ListIndex { base: inner_base, index, ty: inner_elem_ty, .. } = base {
            let obj = self.list_index_read_obj(inner_base, index, inner_elem_ty);
            return self.list_fields_from_obj(&obj, elem_ty);
        }
        // `emit_read_place`, not `emit_place`: a `Field` base reached through
        // a list index at any nesting depth (`players[0].scores.len()`) must
        // not fall into `emit_place`'s `ListIndex` arm, which is the write
        // path and unconditionally CoW-clones the *outer* list as a side
        // effect of this plain read (see this function's own doc comment,
        // and `map_fields`/`set_fields`, which already route through
        // `emit_read_place` for exactly this reason).
        let slot_ptr = self.emit_read_place(base);
        let obj = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", obj, slot_ptr));
        self.list_fields_from_obj(&obj, elem_ty)
    }

    /// Shared tail end of `list_fields`, factored out so `list_fields`'s
    /// nested-`ListIndex`-base fast path can hand in an already-loaded
    /// object pointer (from `list_index_read_obj`) instead of loading one
    /// from a slot address.
    fn list_fields_from_obj(&mut self, obj: &str, elem_ty: &Ty) -> (String, String) {
        let elem_llvm = self.llvm_ty(elem_ty);
        let payload_ty = self.list_payload_llvm_ty(elem_ty);

        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, obj));
        let null_label = self.block_label("list_read_null");
        let real_label = self.block_label("list_read_real");
        let end_label = self.block_label("list_read_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, null_label, real_label));

        self.open_block(&null_label);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&real_label);
        let payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", payload, obj, payload_ty));
        let data_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", data_field, payload_ty, payload_ty, payload));
        let data_real = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** {}", data_real, elem_llvm, elem_llvm, data_field));
        let len_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", len_field, payload_ty, payload_ty, payload));
        let len_real = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", len_real, len_field));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let data = self.tmp_name();
        self.line(&format!("  {} = phi {}* [ null, %{} ], [ {}, %{} ]", data, elem_llvm, null_label, data_real, real_label));
        let len = self.tmp_name();
        self.line(&format!("  {} = phi i64 [ 0, %{} ], [ {}, %{} ]", len, null_label, len_real, real_label));

        (data, len)
    }

    /// Bounds-checked, retain-free read of `base[index]`'s raw element
    /// register -- used only by `list_fields`'s nested-base fast path,
    /// where the element is immediately peeked at (never kept as an owned
    /// value), so skipping the retain `emit_list_index` would otherwise do
    /// is intentional, not an oversight. Out of bounds yields `null`,
    /// matching `list_fields_from_obj`'s own "list constructed but never
    /// mutated" null-object handling.
    fn list_index_read_obj(&mut self, base: &TypedExpr, index: &TypedExpr, elem_ty: &Ty) -> String {
        let elem_llvm = self.llvm_ty(elem_ty);
        let (data, len) = self.list_fields(base, elem_ty);

        let idx_val = self.emit_expr(index);
        let idx_bare = self.untag(&idx_val, &Ty::Int);
        let idx64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", idx64, idx_bare));

        let in_bounds = self.tmp_name();
        self.line(&format!("  {} = icmp ult i64 {}, {}", in_bounds, idx64, len));
        let ok_label = self.block_label("list_read_obj_ok");
        let oob_label = self.block_label("list_read_obj_oob");
        let end_label = self.block_label("list_read_obj_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, ok_label, oob_label));

        self.open_block(&ok_label);
        let elem_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, elem_llvm, elem_llvm, data, idx64));
        let obj_ok = self.tmp_name();
        self.line(&format!("  {} = load {}, {}* {}", obj_ok, elem_llvm, elem_llvm, elem_ptr));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&oob_label);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let result = self.tmp_name();
        self.line(&format!("  {} = phi {} [ {}, %{} ], [ null, %{} ]", result, elem_llvm, obj_ok, ok_label, oob_label));
        result
    }

    /// Mutating path: ensure `base`'s object is uniquely owned (allocating
    /// or cloning it as needed) via `emit_list_ensure_unique`, which
    /// guarantees a real, non-null object by the time this returns -- so,
    /// unlike `list_fields`, no null guard is needed here.
    fn list_fields_mut(&mut self, base: &TypedExpr, elem_ty: &Ty) -> (String, String, String, String, String) {
        let elem_llvm = self.llvm_ty(elem_ty);
        let payload_ty = self.list_payload_llvm_ty(elem_ty);
        let slot_ptr = self.emit_place(base);
        self.emit_list_ensure_unique(&slot_ptr, elem_ty);

        let obj = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", obj, slot_ptr));
        let payload = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to {}*", payload, obj, payload_ty));

        let data_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", data_field, payload_ty, payload_ty, payload));
        let data = self.tmp_name();
        self.line(&format!("  {} = load {}*, {}** {}", data, elem_llvm, elem_llvm, data_field));
        let len_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", len_field, payload_ty, payload_ty, payload));
        let len = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", len, len_field));
        let cap_field = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 2", cap_field, payload_ty, payload_ty, payload));

        (data, data_field, len, len_field, cap_field)
    }

    /// `list[idx]`: bounds-checked element read, yielding the element
    /// type's zero value out of bounds instead of reading garbage/OOB
    /// memory (mirrors `emit_genref_index`'s stale/OOB fallback).
    pub(super) fn emit_list_index(&mut self, base: &TypedExpr, index: &TypedExpr, elem_ty: &Ty) -> String {
        let elem_llvm = self.llvm_ty(elem_ty);
        let (data, len) = self.list_fields(base, elem_ty);

        let idx_val = self.emit_expr(index);
        let idx_bare = self.untag(&idx_val, &Ty::Int);
        let idx64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", idx64, idx_bare));

        // Unsigned compare: a negative index sign-extends/wraps to a huge
        // unsigned value, so it safely fails this bounds check too (mirrors
        // `emit_despawn_stmt`'s identical trick).
        let in_bounds = self.tmp_name();
        self.line(&format!("  {} = icmp ult i64 {}, {}", in_bounds, idx64, len));
        let ok_label = self.block_label("list_idx_ok");
        let oob_label = self.block_label("list_idx_oob");
        let end_label = self.block_label("list_idx_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, ok_label, oob_label));

        self.open_block(&ok_label);
        let elem_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, elem_llvm, elem_llvm, data, idx64));
        let elem_val = self.tmp_name();
        self.line(&format!("  {} = load {}, {}* {}", elem_val, elem_llvm, elem_llvm, elem_ptr));
        // Reading an element hands out an independent copy while the list
        // keeps its own reference -- retain (see `rc.rs`; a no-op unless
        // `elem_ty` is RC-bearing). The out-of-bounds branch below produces
        // a zero value with no real backing allocation, so there's nothing
        // to retain there.
        self.emit_retain_at(&elem_ptr, elem_ty);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&oob_label);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let zero = self.zero_value(elem_ty);
        let result = self.tmp_name();
        self.line(&format!("  {} = phi {} [ {}, %{} ], [ {}, %{} ]", result, elem_llvm, elem_val, ok_label, zero, oob_label));
        format!("{} {}", elem_llvm, result)
    }

    /// `list[idx] = v`: bounds-checked element write; an out-of-bounds
    /// index is a silent no-op (mirrors `emit_despawn_stmt`'s dead-slot
    /// handling) rather than writing out of bounds. Mutates, so this goes
    /// through the copy-on-write gate first.
    pub(super) fn store_list_index(&mut self, base: &TypedExpr, index: &TypedExpr, elem_ty: &Ty, val: &str) {
        let elem_llvm = self.llvm_ty(elem_ty);
        let (data, _, len, _, _) = self.list_fields_mut(base, elem_ty);

        let idx_val = self.emit_expr(index);
        let idx_bare = self.untag(&idx_val, &Ty::Int);
        let idx64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", idx64, idx_bare));

        let in_bounds = self.tmp_name();
        self.line(&format!("  {} = icmp ult i64 {}, {}", in_bounds, idx64, len));
        let do_label = self.block_label("list_set_do");
        let oob_label = self.block_label("list_set_oob");
        let end_label = self.block_label("list_set_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, do_label, oob_label));

        self.open_block(&do_label);
        let elem_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, elem_llvm, elem_llvm, data, idx64));
        let clean_val = self.untag(val, elem_ty);
        // `val` was already computed (and retained, if it's a copy) by the
        // caller before calling this; release the old element *after* that,
        // right before overwriting it -- keeps `list[i] = list[i]` safe, same
        // reasoning as `Codegen::store_target`'s `Ident`/`Field` arms.
        self.emit_release_at(&elem_ptr, elem_ty);
        self.line(&format!("  store {} {}, {}* {}", elem_llvm, clean_val, elem_llvm, elem_ptr));
        self.line(&format!("  br label %{}", end_label));

        // An out-of-bounds write is a silent no-op *observably* (nothing in
        // the list changes), but `val` was already computed and retained by
        // the caller on our behalf -- without this, that ownership was
        // never released anywhere, permanently leaking one heap reference
        // per out-of-bounds write instead of the true no-op the doc comment
        // above promises.
        self.open_block(&oob_label);
        // `emit_release_bare` expects a *bare* (untagged) value -- `val` is
        // whatever `emit_expr` handed the caller, which isn't consistently
        // tagged or bare across expression kinds (a literal/struct-literal
        // construction is tagged, e.g. `%Item %t9`; a call/load result is
        // already bare). Reuse the same `clean_val` the `do_label` branch
        // above already computed via `untag`, rather than risking a
        // double-tagged `store` (`store i8* i8* %t5, ...`) clang rejects.
        self.emit_release_bare(&clean_val, elem_ty);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
    }

    /// Place resolution for a `list[idx]` *base* of a further access --
    /// `list[i].field = v`, `list[i].push(v)`, `m[i][j] = v` (a nested
    /// `ListIndex` chained onto another `ListIndex`), `list[i].method()`
    /// with a mutating receiver, etc. Returns a real pointer into the
    /// (copy-on-write-uniqued) buffer at `idx`, so a write through the
    /// returned pointer is actually observable in the list afterwards.
    ///
    /// Before this existed, `Codegen::emit_place` had no `ListIndex` arm, so
    /// any such chained access fell into its generic fallback: evaluate the
    /// expression, spill the *resulting value* into a fresh, disconnected
    /// alloca, and hand out that pointer. Reads through that pointer were
    /// (accidentally) correct, but every write vanished into the throwaway
    /// alloca instead of reaching the list -- `outer[0].push(x)` and
    /// `m[i][j] = v` silently no-op'd on the real data.
    ///
    /// An out-of-bounds index yields a pointer to a fresh, zeroed,
    /// disconnected alloca (mirrors `store_list_index`'s own out-of-bounds
    /// silent-no-op convention: nothing is loaded from or written into the
    /// real buffer, and any read back out of the returned pointer sees a
    /// well-defined zero value rather than uninitialized memory).
    pub(super) fn emit_list_index_place(&mut self, base: &TypedExpr, index: &TypedExpr, elem_ty: &Ty) -> String {
        let elem_llvm = self.llvm_ty(elem_ty);
        let (data, _, len, _, _) = self.list_fields_mut(base, elem_ty);

        let idx_val = self.emit_expr(index);
        let idx_bare = self.untag(&idx_val, &Ty::Int);
        let idx64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", idx64, idx_bare));

        let in_bounds = self.tmp_name();
        self.line(&format!("  {} = icmp ult i64 {}, {}", in_bounds, idx64, len));
        let ok_label = self.block_label("list_place_ok");
        let oob_label = self.block_label("list_place_oob");
        let end_label = self.block_label("list_place_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, ok_label, oob_label));

        self.open_block(&ok_label);
        let elem_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, elem_llvm, elem_llvm, data, idx64));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&oob_label);
        let dummy = self.tmp_name();
        self.line(&format!("  {} = alloca {}", dummy, elem_llvm));
        let zero = self.zero_value(elem_ty);
        self.line(&format!("  store {} {}, {}* {}", elem_llvm, zero, elem_llvm, dummy));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let result = self.tmp_name();
        self.line(&format!("  {} = phi {}* [ {}, %{} ], [ {}, %{} ]", result, elem_llvm, elem_ptr, ok_label, dummy, oob_label));
        result
    }

    /// Retain-free, non-mutating counterpart to `emit_list_index_place`, for
    /// a `list[idx]` base being read through (not written through) by a
    /// further access -- e.g. `list[i].field` (a struct-element field read).
    /// Resolves through `list_fields` (the read path) instead of
    /// `list_fields_mut`, so it never triggers `emit_list_ensure_unique`'s
    /// copy-on-write clone as a side effect of a plain read (the same bug
    /// class `list_index_read_obj`/`list_fields`'s nested-base fast path
    /// exists to avoid for scalar/list elements -- this is the struct-element
    /// sibling of that fix, needed because a read of a *struct* element's
    /// field must produce a pointer to GEP into, not a loaded value).
    /// Safe for the same reason `list_index_read_obj` is: nothing releases
    /// the list's own reference for the remainder of this single,
    /// straight-line expression, so the buffer it points into is guaranteed
    /// to stay alive long enough to read through here.
    pub(super) fn emit_list_index_read_place(&mut self, base: &TypedExpr, index: &TypedExpr, elem_ty: &Ty) -> String {
        let elem_llvm = self.llvm_ty(elem_ty);
        let (data, len) = self.list_fields(base, elem_ty);

        let idx_val = self.emit_expr(index);
        let idx_bare = self.untag(&idx_val, &Ty::Int);
        let idx64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", idx64, idx_bare));

        let in_bounds = self.tmp_name();
        self.line(&format!("  {} = icmp ult i64 {}, {}", in_bounds, idx64, len));
        let ok_label = self.block_label("list_read_place_ok");
        let oob_label = self.block_label("list_read_place_oob");
        let end_label = self.block_label("list_read_place_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_bounds, ok_label, oob_label));

        self.open_block(&ok_label);
        let elem_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, elem_llvm, elem_llvm, data, idx64));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&oob_label);
        let dummy = self.tmp_name();
        self.line(&format!("  {} = alloca {}", dummy, elem_llvm));
        let zero = self.zero_value(elem_ty);
        self.line(&format!("  store {} {}, {}* {}", elem_llvm, zero, elem_llvm, dummy));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let result = self.tmp_name();
        self.line(&format!("  {} = phi {}* [ {}, %{} ], [ {}, %{} ]", result, elem_llvm, elem_ptr, ok_label, dummy, oob_label));
        result
    }

    /// `list.push(v)` / `list.pop()` / `list.len()`.
    pub(super) fn emit_list_method(&mut self, base: &TypedExpr, method: ListMethod, args: &[TypedExpr], elem_ty: &Ty) -> String {
        let elem_llvm = self.llvm_ty(elem_ty);

        match method {
            ListMethod::Len => {
                let (_, len) = self.list_fields(base, elem_ty);
                let len32 = self.tmp_name();
                self.line(&format!("  {} = trunc i64 {} to i32", len32, len));
                format!("i32 {}", len32)
            }
            ListMethod::Push => {
                let (_, data_field, _stale_len, len_field, cap_field) = self.list_fields_mut(base, elem_ty);

                let val = self.emit_expr(&args[0]);
                let clean_val = self.untag(&val, elem_ty);

                let cap = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", cap, cap_field));
                let data = self.tmp_name();
                self.line(&format!("  {} = load {}*, {}** {}", data, elem_llvm, elem_llvm, data_field));
                // `_stale_len` (from `list_fields_mut`, above) was captured
                // *before* evaluating `args[0]` -- if that argument
                // expression mutates this same list (e.g. `xs.push(xs.pop())`),
                // the real `len_field` in memory has already changed by the
                // time we get here, but that captured value hasn't. Reload it
                // fresh, the same way `cap`/`data` already are just above, or
                // every grow-check/copy-count/write-index/new-length
                // computation below would use a stale value.
                let len = self.tmp_name();
                self.line(&format!("  {} = load i64, i64* {}", len, len_field));

                let needs_grow = self.tmp_name();
                self.line(&format!("  {} = icmp sge i64 {}, {}", needs_grow, len, cap));
                let grow_label = self.block_label("list_push_grow");
                let store_label = self.block_label("list_push_store");
                self.line(&format!("  br i1 {}, label %{}, label %{}", needs_grow, grow_label, store_label));

                self.open_block(&grow_label);
                let doubled = self.tmp_name();
                self.line(&format!("  {} = mul i64 {}, 2", doubled, cap));
                let has_cap = self.tmp_name();
                self.line(&format!("  {} = icmp sgt i64 {}, 0", has_cap, doubled));
                let new_cap = self.tmp_name();
                self.line(&format!("  {} = select i1 {}, i64 {}, i64 1", new_cap, has_cap, doubled));
                // Real, LLVM-computed element size -- see
                // `Codegen::emit_sizeof_llvm_ty`'s doc comment. Both the new
                // buffer's `malloc` and the old buffer's `memcpy` byte count
                // below must agree with the `getelementptr`-computed stride
                // `elem_llvm` indexing actually uses; a Rust-side estimate
                // that undersizes a padded struct element type would both
                // under-allocate the grown buffer *and* under-copy (silently
                // truncating) the existing elements being carried over.
                let elem_size = self.emit_sizeof_llvm_ty(&elem_llvm);
                let new_bytes = self.tmp_name();
                self.line(&format!("  {} = mul i64 {}, {}", new_bytes, new_cap, elem_size));
                let new_raw = self.tmp_name();
                self.line(&format!("  {} = call i8* @malloc(i64 {})", new_raw, new_bytes));
                let new_data = self.tmp_name();
                self.line(&format!("  {} = bitcast i8* {} to {}*", new_data, new_raw, elem_llvm));

                // Only copy/free the old buffer when one actually exists
                // (`cap == 0` means `data` is still the initial `null`);
                // `memcpy`/`free` on a null pointer is unnecessary and best
                // avoided even at zero length. Safe to unconditionally
                // `free` the old buffer here (unlike a bit-copied alias
                // scenario) since `list_fields_mut` already guaranteed this
                // object -- and therefore this buffer -- has exactly one
                // owner.
                let had_data = self.tmp_name();
                self.line(&format!("  {} = icmp sgt i64 {}, 0", had_data, cap));
                let copy_label = self.block_label("list_push_copy");
                let after_copy_label = self.block_label("list_push_after_copy");
                self.line(&format!("  br i1 {}, label %{}, label %{}", had_data, copy_label, after_copy_label));

                self.open_block(&copy_label);
                let old_bytes = self.tmp_name();
                self.line(&format!("  {} = mul i64 {}, {}", old_bytes, len, elem_size));
                let old_raw = self.tmp_name();
                self.line(&format!("  {} = bitcast {}* {} to i8*", old_raw, elem_llvm, data));
                self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", new_raw, old_raw, old_bytes));
                self.line(&format!("  call void @free(i8* {})", old_raw));
                self.line(&format!("  br label %{}", after_copy_label));

                self.open_block(&after_copy_label);
                self.line(&format!("  store {}* {}, {}** {}", elem_llvm, new_data, elem_llvm, data_field));
                self.line(&format!("  store i64 {}, i64* {}", new_cap, cap_field));
                self.line(&format!("  br label %{}", store_label));

                self.open_block(&store_label);
                let data_now = self.tmp_name();
                self.line(&format!("  {} = load {}*, {}** {}", data_now, elem_llvm, elem_llvm, data_field));
                let elem_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, elem_llvm, elem_llvm, data_now, len));
                self.line(&format!("  store {} {}, {}* {}", elem_llvm, clean_val, elem_llvm, elem_ptr));
                let new_len = self.tmp_name();
                self.line(&format!("  {} = add i64 {}, 1", new_len, len));
                self.line(&format!("  store i64 {}, i64* {}", new_len, len_field));
                "%undef".into()
            }
            ListMethod::Pop => {
                let (_, data_field, len, len_field, _) = self.list_fields_mut(base, elem_ty);

                let is_empty = self.tmp_name();
                self.line(&format!("  {} = icmp eq i64 {}, 0", is_empty, len));
                let empty_label = self.block_label("list_pop_empty");
                let nonempty_label = self.block_label("list_pop_nonempty");
                let end_label = self.block_label("list_pop_end");
                self.line(&format!("  br i1 {}, label %{}, label %{}", is_empty, empty_label, nonempty_label));

                self.open_block(&nonempty_label);
                let new_len = self.tmp_name();
                self.line(&format!("  {} = sub i64 {}, 1", new_len, len));
                self.line(&format!("  store i64 {}, i64* {}", new_len, len_field));
                let data = self.tmp_name();
                self.line(&format!("  {} = load {}*, {}** {}", data, elem_llvm, elem_llvm, data_field));
                let elem_ptr = self.tmp_name();
                self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i64 {}", elem_ptr, elem_llvm, elem_llvm, data, new_len));
                let popped = self.tmp_name();
                self.line(&format!("  {} = load {}, {}* {}", popped, elem_llvm, elem_llvm, elem_ptr));
                self.line(&format!("  br label %{}", end_label));

                self.open_block(&empty_label);
                self.line(&format!("  br label %{}", end_label));

                self.open_block(&end_label);
                let zero = self.zero_value(elem_ty);
                let result = self.tmp_name();
                self.line(&format!("  {} = phi {} [ {}, %{} ], [ {}, %{} ]", result, elem_llvm, popped, nonempty_label, zero, empty_label));
                format!("{} {}", elem_llvm, result)
            }
        }
    }
}

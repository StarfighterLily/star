//! Structural hash codegen for `Map<K,V>`/`Set<T>` keys and `Symbol`'s
//! string-interning table -- the hashing counterpart to `crate::codegen::eq`
//! (see that module's doc comment for exactly which `Ty`s reach here: only
//! what `Checker::check_hashable_ty` accepts).
//!
//! Every leaf value is folded into a running 64-bit accumulator via FNV-1a
//! (`acc = (acc XOR bits) * FNV_PRIME`, seeded with the standard FNV-1a
//! 64-bit offset basis) -- a small, dependency-free, decent-avalanche mix
//! that needs nothing beyond `xor`/`mul`, easy to hand-emit as textual IR.
//! The accumulator lives in a single `alloca i64` for the whole function
//! (`hash_fn_name`'s `%acc_ptr`), threaded through every recursive call via
//! `emit_hash_into` rather than returned as an SSA value: unlike `eq.rs`'s
//! `emit_eq_body` (which only ever needs one boolean short-circuit chain, a
//! shape `and_acc`'s SSA accumulator handles fine), a `str` field's hash
//! needs an actual loop with its own basic blocks, and threading an SSA
//! accumulator across an arbitrary number of such loops (nested inside
//! struct/array/tuple field recursion) would need a `phi` at every loop exit.
//! Reading/writing through one `alloca` sidesteps that entirely, at the cost
//! of a load+store per leaf -- an irrelevant overhead next to the `malloc`/
//! probe-loop work every hash table operation already does.
//!
//! Two equal keys (`eq_fn_name`'s `i1 @eq_<mangled>`) must always hash equal,
//! or the probe sequence in `crate::codegen::hashtable` can never find an
//! existing entry. The one place that's non-obvious: `Ty::Float`/`Ty::F64`
//! canonicalize `-0.0` to `+0.0` before hashing (`fadd float/double %v,
//! 0.0`, which IEEE 754 defines as exactly `+0.0` for a `-0.0` input, and a
//! no-op bit-for-bit for every other finite value) since `eq_fn_name`'s
//! `fcmp oeq` already treats `-0.0 == 0.0`, but their raw bit patterns
//! differ. `NaN` keys are a known, pre-existing gap shared with the
//! linear-scan implementation this replaces: `fcmp oeq` never returns true
//! for a `NaN` against anything (including itself), so a `NaN` key was
//! already unfindable after insertion before this change; hashing it
//! (whatever bit pattern `fadd`'s NaN-propagation produces) doesn't make
//! that any worse.

use crate::types::*;

use super::Codegen;

impl Codegen {
    /// FNV-1a 64-bit offset basis (`14695981039346656037`), written as its
    /// two's-complement `i64` literal since LLVM textual IR integer constants
    /// are parsed as signed decimals for a signed-looking context.
    const FNV_OFFSET_I64: &'static str = "-3750763034362895579";
    /// FNV-1a 64-bit prime (`1099511628211`) -- fits directly as a positive
    /// `i64` literal.
    const FNV_PRIME_I64: &'static str = "1099511628211";

    /// Lazily generate (and cache, keyed by `Codegen::mangle_ty`) a
    /// structural-hash function `@hash_<mangled>(T %v) -> i64` for `ty`,
    /// returning its bare (no `@`) name. Mirrors `eq_fn_name`'s shape
    /// exactly -- lazy generation, name reservation before the body to guard
    /// a self-referential struct, `hoist_allocas_to_entry` on the finished
    /// body (needed here since a `str` field's byte loop allocas a loop
    /// counter mid-function, on top of `%acc_ptr` itself).
    pub(super) fn hash_fn_name(&mut self, ty: &Ty) -> String {
        let key = self.mangle_ty(ty);
        if let Some(name) = self.hash_fns.get(&key).cloned() {
            return name;
        }
        let name = format!("hash_{}", key);
        self.hash_fns.insert(key, name.clone());

        let llvm = self.llvm_ty(ty);
        let saved_ir = std::mem::take(&mut self.ir);
        self.line(&format!("define i64 @{}({} %v) {{", name, llvm));
        self.open_block("entry");
        let acc_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", acc_ptr));
        self.line(&format!("  store i64 {}, i64* {}", Self::FNV_OFFSET_I64, acc_ptr));
        self.emit_hash_into("%v", ty, &acc_ptr);
        let result = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", result, acc_ptr));
        self.line(&format!("  ret i64 {}", result));
        self.line("}");
        self.line("");
        let fn_ir = std::mem::replace(&mut self.ir, saved_ir);
        self.pending_top.push(Self::hoist_allocas_to_entry(&fn_ir));
        name
    }

    /// `*acc_ptr = (*acc_ptr XOR h64) * FNV_PRIME`, given an already-computed
    /// bare `i64` value `h64`.
    fn mix_into(&mut self, acc_ptr: &str, h64: &str) {
        let acc = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", acc, acc_ptr));
        let x = self.tmp_name();
        self.line(&format!("  {} = xor i64 {}, {}", x, acc, h64));
        let r = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, {}", r, x, Self::FNV_PRIME_I64));
        self.line(&format!("  store i64 {}, i64* {}", r, acc_ptr));
    }

    /// `mix_into`, zero-extending a narrower-than-64-bit bare integer/`i1`
    /// register `v` first. A no-op zext (`width == 64`) just mixes `v`
    /// directly.
    fn mix_zext_into(&mut self, acc_ptr: &str, v: &str, width: u32) {
        if width == 64 {
            self.mix_into(acc_ptr, v);
            return;
        }
        let z = self.tmp_name();
        self.line(&format!("  {} = zext i{} {} to i64", z, width, v));
        self.mix_into(acc_ptr, &z);
    }

    /// Mix a `float` lane into `*acc_ptr`: canonicalize `-0.0` to `+0.0`
    /// (see this module's doc comment) then mix its raw bits.
    fn mix_float_into(&mut self, acc_ptr: &str, v: &str) {
        let canon = self.tmp_name();
        self.line(&format!("  {} = fadd float {}, 0.000000e+00", canon, v));
        let bits = self.tmp_name();
        self.line(&format!("  {} = bitcast float {} to i32", bits, canon));
        self.mix_zext_into(acc_ptr, &bits, 32);
    }

    /// Mix every byte of a `str` (`i8*`, NUL-terminated) into `*acc_ptr`.
    fn mix_str_into(&mut self, acc_ptr: &str, v: &str) {
        let len = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", len, v));
        let len64 = self.tmp_name();
        self.line(&format!("  {} = zext i32 {} to i64", len64, len));

        let i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", i_ptr));
        self.line(&format!("  store i64 0, i64* {}", i_ptr));

        let cond_label = self.block_label("hash_str_cond");
        let body_label = self.block_label("hash_str_body");
        let end_label = self.block_label("hash_str_end");
        self.line(&format!("  br label %{}", cond_label));
        self.open_block(&cond_label);
        let i_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
        let in_range = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", in_range, i_reg, len64));
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_range, body_label, end_label));

        self.open_block(&body_label);
        let byte_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", byte_ptr, v, i_reg));
        let byte = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", byte, byte_ptr));
        self.mix_zext_into(acc_ptr, &byte, 8);
        let i_next = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
        self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
        self.line(&format!("  br label %{}", cond_label));

        self.open_block(&end_label);
    }

    /// Mix an already-loaded value `v` of type `ty` into `*acc_ptr`,
    /// recursing field-by-field/lane-by-lane for aggregates -- structurally
    /// mirrors `eq.rs`'s `emit_eq_body` recursion shape (same `Ty` arms, same
    /// `Named`/`Tuple`/`Array`/vector traversal), just accumulating into a
    /// shared `alloca` instead of building an SSA `and`-chain.
    fn emit_hash_into(&mut self, v: &str, ty: &Ty, acc_ptr: &str) {
        match ty {
            Ty::Int | Ty::Enum(_) => self.mix_zext_into(acc_ptr, v, 32),
            Ty::Bool => self.mix_zext_into(acc_ptr, v, 1),
            Ty::Float => self.mix_float_into(acc_ptr, v),
            Ty::F64 => {
                let canon = self.tmp_name();
                self.line(&format!("  {} = fadd double {}, 0.000000e+00", canon, v));
                let bits = self.tmp_name();
                self.line(&format!("  {} = bitcast double {} to i64", bits, canon));
                self.mix_into(acc_ptr, &bits);
            }
            Ty::I8 | Ty::U8 | Ty::PaletteIndex => self.mix_zext_into(acc_ptr, v, 8),
            Ty::I16 | Ty::U16 => self.mix_zext_into(acc_ptr, v, 16),
            Ty::U32 | Ty::Char | Ty::Color32 => self.mix_zext_into(acc_ptr, v, 32),
            Ty::I64 | Ty::U64 | Ty::Symbol | Ty::Flags(_) => self.mix_into(acc_ptr, v),
            Ty::Str => self.mix_str_into(acc_ptr, v),
            // `Quat`/`Color` reuse `Vec4`'s exact layout -- see
            // `Checker::check_hashable_ty`'s matching arm.
            Ty::Vec2 | Ty::Vec3 | Ty::Vec4 | Ty::Quat | Ty::Color => {
                let n = ty.vec_arity().expect("vector Ty always has an arity");
                for i in 0..n as u32 {
                    let lane = self.extract_component(v, ty, i);
                    self.mix_float_into(acc_ptr, &lane);
                }
            }
            Ty::Named(name) => {
                let field_tys = self.struct_field_types.get(name).cloned().unwrap_or_default();
                let struct_ty = format!("%{}", name);
                for (i, fty) in field_tys.iter().enumerate() {
                    let fv = self.tmp_name();
                    self.line(&format!("  {} = extractvalue {} {}, {}", fv, struct_ty, v, i));
                    self.emit_hash_into(&fv, fty, acc_ptr);
                }
            }
            Ty::Tuple(elems) => {
                let struct_ty = self.llvm_ty(ty);
                for (i, fty) in elems.iter().enumerate() {
                    let fv = self.tmp_name();
                    self.line(&format!("  {} = extractvalue {} {}, {}", fv, struct_ty, v, i));
                    self.emit_hash_into(&fv, fty, acc_ptr);
                }
            }
            Ty::Array(elem, count) => {
                let struct_ty = self.llvm_ty(ty);
                for i in 0..*count {
                    let fv = self.tmp_name();
                    self.line(&format!("  {} = extractvalue {} {}, {}", fv, struct_ty, v, i));
                    self.emit_hash_into(&fv, elem, acc_ptr);
                }
            }
            // Both lower to a plain fixed-size scalar (see their own `Ty`
            // doc comments) -- hashed exactly like any other sized integer,
            // same as the `I8`/.../`Char` arm above.
            Ty::Wrapping(inner) => self.emit_hash_into(v, inner, acc_ptr),
            Ty::Fixed(bits, _) => self.mix_zext_into(acc_ptr, v, *bits),
            Ty::BitField(n) => self.mix_zext_into(acc_ptr, v, *n),
            // Unreachable in practice -- `Checker::check_hashable_ty` rejects
            // every other `Ty` as a Map/Set key/element type before codegen
            // ever sees one here (see `eq.rs`'s matching catch-all).
            _ => {}
        }
    }
}

//! Binary data across `extern "C"`: `ptr_to_bytes(p, n) -> Bytes` and
//! `ptr_write_bytes(dst, b, off, n) -> int`.
//!
//! Why: an `extern "C"` call can pass and return pointers, and `ptr_to_str`
//! reads a NUL-terminated string back, but nothing could move *binary* data
//! between a C buffer and a `Bytes`. That is the whole interface of a TLS
//! library over memory BIOs -- `SSL_read`/`BIO_read` fill a caller's buffer,
//! `SSL_write`/`BIO_write` read one -- which the LPMUD driver in
//! `projects/havokos` needs for its HTTPS ports, telnet over TLS and
//! STREAM_TLS sockets (`todo.md` HavokOS P1 #8, OpenSSL through
//! `extern "C"` since P2 #1 lets Star call its uppercase names). It is also
//! the general answer to `projects/havokos/NOTES.md` constraint #9 (Star's
//! FFI can't read a C struct): a struct's bytes come out with
//! `ptr_to_bytes(p, size)` and its fields decode from the `Bytes`.
//!
//! The alternative was a set of TLS builtins wrapping each OpenSSL buffer
//! call (the shape `crate::codegen::sqlite` took for SQLite's two
//! out-parameter calls); two generic copies cover every such call in every
//! library, with the C side's own buffer -- allocated by the C library, e.g.
//! OpenSSL's `CRYPTO_malloc` -- between them.
//!
//! - `ptr_to_bytes(p, n)`: a fresh `Bytes` holding a copy of the `n` bytes
//!   at `p`. `n <= 0` gives an empty `Bytes` without touching `p`; a null
//!   `p` with `n > 0` aborts with a message, as `ptr_to_str` does.
//! - `ptr_write_bytes(dst, b, off, n)`: copies `b[off..off + n]` to `dst`
//!   and returns how many bytes it copied: the range is clamped to `b` (a
//!   negative `off` reads from 0; a negative `n` means "to the end"), so it
//!   never reads past the `Bytes`. Writing past `dst`'s own allocation is
//!   the caller's responsibility, exactly as with the C buffer it came
//!   from. A null `dst` with something to copy aborts.
//!
//! Neither hands out a pointer into a `Bytes`' own storage: `Bytes` is
//! copy-on-write and refcounted, so a C function writing through such a
//! pointer could change a copy that shares it, or outlive it.
//!
//! ## No `Target` seam
//! Both are a `malloc` and a `memcpy`, the same on every target.

use crate::diagnostics::Span;
use crate::types::*;

use super::Codegen;

impl Codegen {
    /// `ptr_to_bytes(p: ptr, n: int) -> Bytes`; see the module doc comment.
    pub(super) fn emit_ptr_to_bytes(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("ptr_to_bytes(..) expects 2 arguments (pointer, length)", Span::dummy());
            return "i8* null".into();
        }
        let pv = self.emit_expr(&args[0]);
        let p = self.untag(&pv, &Ty::Ptr);
        let nv = self.emit_expr(&args[1]);
        let n = self.untag(&nv, &Ty::Int);
        let empty = self.block_label("ptr_to_bytes_empty");
        let check = self.block_label("ptr_to_bytes_check");
        let null_l = self.block_label("ptr_to_bytes_null");
        let copy = self.block_label("ptr_to_bytes_copy");
        let end = self.block_label("ptr_to_bytes_end");
        let none = self.tmp_name();
        self.line(&format!("  {} = icmp sle i32 {}, 0", none, n));
        self.line(&format!("  br i1 {}, label %{}, label %{}", none, empty, check));
        self.open_block(&empty);
        self.line(&format!("  br label %{}", end));

        self.open_block(&check);
        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, p));
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, null_l, copy));
        self.open_block(&null_l);
        self.emit_abort_with_message("star runtime error: ptr_to_bytes(..) called with a null ptr\n");

        self.open_block(&copy);
        let n64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", n64, n));
        let buf = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", buf, n64));
        self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", buf, p, n64));
        let wrapped = self.emit_bytes_wrap_raw_buf(&buf, &n64);
        let wreg = self.reg_of(&wrapped);
        let copy_pred = self.current_label.clone();
        self.line(&format!("  br label %{}", end));

        self.open_block(&end);
        let r = self.tmp_name();
        self.line(&format!("  {} = phi i8* [ null, %{} ], [ {}, %{} ]", r, empty, wreg, copy_pred));
        format!("i8* {}", r)
    }

    /// `ptr_write_bytes(dst: ptr, b: Bytes, off: int, n: int) -> int`; see
    /// the module doc comment.
    pub(super) fn emit_ptr_write_bytes(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 4 {
            self.err("ptr_write_bytes(..) expects 4 arguments (destination, data, start, length)", Span::dummy());
            return "i32 0".into();
        }
        let dv = self.emit_expr(&args[0]);
        let dst = self.untag(&dv, &Ty::Ptr);
        let ov = self.emit_expr(&args[2]);
        let off = self.untag(&ov, &Ty::Int);
        let nv = self.emit_expr(&args[3]);
        let n = self.untag(&nv, &Ty::Int);
        let (data, len) = self.list_fields(&args[1], &Ty::U8);
        // start = max(off, 0); avail = max(len - start, 0)
        let o64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", o64, off));
        let oneg = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, 0", oneg, o64));
        let start = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i64 0, i64 {}", start, oneg, o64));
        let rem = self.tmp_name();
        self.line(&format!("  {} = sub i64 {}, {}", rem, len, start));
        let rneg = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, 0", rneg, rem));
        let avail = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i64 0, i64 {}", avail, rneg, rem));
        // count = n < 0 ? avail : min(n, avail)
        let n64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", n64, n));
        let nneg = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, 0", nneg, n64));
        let nbig = self.tmp_name();
        self.line(&format!("  {} = icmp sgt i64 {}, {}", nbig, n64, avail));
        let take_avail = self.tmp_name();
        self.line(&format!("  {} = or i1 {}, {}", take_avail, nneg, nbig));
        let count = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i64 {}, i64 {}", count, take_avail, avail, n64));

        let nothing = self.block_label("ptr_write_bytes_nothing");
        let check = self.block_label("ptr_write_bytes_check");
        let null_l = self.block_label("ptr_write_bytes_null");
        let copy = self.block_label("ptr_write_bytes_copy");
        let end = self.block_label("ptr_write_bytes_end");
        let zero = self.tmp_name();
        self.line(&format!("  {} = icmp sle i64 {}, 0", zero, count));
        self.line(&format!("  br i1 {}, label %{}, label %{}", zero, nothing, check));
        self.open_block(&nothing);
        self.line(&format!("  br label %{}", end));

        self.open_block(&check);
        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, dst));
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, null_l, copy));
        self.open_block(&null_l);
        self.emit_abort_with_message("star runtime error: ptr_write_bytes(..) called with a null ptr\n");

        self.open_block(&copy);
        let src = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", src, data, start));
        self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", dst, src, count));
        let c32 = self.tmp_name();
        self.line(&format!("  {} = trunc i64 {} to i32", c32, count));
        self.line(&format!("  br label %{}", end));

        self.open_block(&end);
        let r = self.tmp_name();
        self.line(&format!("  {} = phi i32 [ 0, %{} ], [ {}, %{} ]", r, nothing, c32, copy));
        format!("i32 {}", r)
    }
}

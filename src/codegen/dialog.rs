//! `open_file_dialog(filter_pattern: str) -> str`: a native Windows "Open
//! File" common dialog (`GetOpenFileNameA`, `comdlg32.dll`) -- the builtin
//! `projects/nova/main.star`'s new `Load` toolbar button needs to pick a
//! `.bin` off disk without shelling out to a second process or hand-rolling
//! a `draw_rect`/`draw_text`-based file browser. `projects/nova/NOTES.md`'s
//! "GUI+controls parity" section previously scoped this out as "no
//! file-dialog builtin anywhere in this language's surface" -- this module
//! is that builtin, added specifically because a user-visible `Load` button
//! (not just command-line-argument loading) was requested for real.
//!
//! ## Why `GetOpenFileNameA` over `IFileOpenDialog`
//! The modern replacement (`IFileOpenDialog`, Vista+) is a COM interface --
//! `CoInitialize`, a class-factory `CoCreateInstance` against a GUID vtable,
//! manual `AddRef`/`Release` reference counting, and a vtable-index call
//! convention this codegen has no existing machinery for at all.
//! `GetOpenFileNameA` is a single flat C ABI call taking one struct pointer,
//! the exact "hand-emit a call to an existing C API" shape every other
//! OS-facing builtin here already uses (`net.rs`'s `connect`, `file_io.rs`'s
//! `fopen`, `system_font.rs`'s `CreateFontA`) -- no COM plumbing needed to
//! add, and it's still the officially supported (if legacy-styled) API for
//! exactly this use case.
//!
//! ## The `OPENFILENAMEA` struct (x64 layout, 152 bytes)
//! This codegen has no struct-type declarations for external C structs --
//! every field is written by hand via `getelementptr`/`bitcast`/`store` at
//! its known byte offset into a flat `alloca [152 x i8]`, the same technique
//! `net.rs::emit_tcp_connect` already uses for `sockaddr_in`. Offsets below
//! (verified against the real `commdlg.h` field order and x64's natural
//! pointer/`DWORD` alignment -- every 8-byte pointer field lands on an
//! 8-byte boundary, forcing 4 bytes of padding after each lone trailing
//! `DWORD`):
//!
//! ```text
//! offset  size  field
//!      0     4  lStructSize        (DWORD)
//!      4     4  (padding)
//!      8     8  hwndOwner          (HWND)
//!     16     8  hInstance          (HINSTANCE)
//!     24     8  lpstrFilter        (LPCSTR)
//!     32     8  lpstrCustomFilter  (LPSTR)
//!     40     4  nMaxCustFilter     (DWORD)
//!     44     4  nFilterIndex       (DWORD)
//!     48     8  lpstrFile          (LPSTR)
//!     56     4  nMaxFile           (DWORD)
//!     60     4  (padding)
//!     64     8  lpstrFileTitle     (LPSTR)
//!     72     4  nMaxFileTitle      (DWORD)
//!     76     4  (padding)
//!     80     8  lpstrInitialDir    (LPCSTR)
//!     88     8  lpstrTitle         (LPCSTR)
//!     96     4  Flags              (DWORD)
//!    100     2  nFileOffset        (WORD)
//!    102     2  nFileExtension     (WORD)
//!    104     8  lpstrDefExt        (LPCSTR)
//!    112     8  lCustomData        (LPARAM)
//!    120     8  lpfnHook           (LPOFNHOOKPROC)
//!    128     8  lpTemplateName     (LPCSTR)
//!    136     8  pvReserved         (void*)
//!    144     4  dwReserved         (DWORD)
//!    148     4  FlagsEx            (DWORD)
//! ```
//!
//! This builtin only ever writes `lStructSize`/`lpstrFilter`/`lpstrFile`/
//! `nMaxFile`/`Flags` -- every other field is left at the zero/null the
//! struct's own `alloca` is filled with up front (`Codegen::emit_fill_i8`,
//! the same "hand-rolled store loop, no `@llvm.memset` declared" primitive
//! `hashtable.rs` already established), which is exactly what
//! `GetOpenFileNameA` expects for "not used".
//!
//! ## The filter string
//! `GetOpenFileNameA` wants a `"Display Text\0Pattern\0"` pair (or several,
//! back to back) followed by one extra terminating `\0`, all packed into one
//! buffer -- a shape an ordinary Star `str` (implicitly NUL-terminated at
//! its first `\0`, per this codegen's C-string representation) can't carry
//! as a single argument. Rather than expose that packed format to Star
//! callers directly, this builtin takes one plain `filter_pattern` `str`
//! (e.g. `"*.bin"`; `""` means "all files") and builds
//! `"Files (PATTERN)\0PATTERN\0\0"` itself by hand into a zeroed scratch
//! buffer: `emit_fill_i8` zeroes the whole thing first, so both the
//! mid-string separator and the final double-NUL terminator fall out for
//! free from bytes this code never has to touch, and only the two literal
//! runs (`"Files ("`/`")"`) and the two live copies of `PATTERN` need
//! writing.
//!
//! ## Return value and ownership
//! Returns the chosen absolute path as a fresh, `star_rc_alloc`'d, owned
//! `str` (same "fresh buffer, refcount 1, no release callback" shape
//! `emit_read_line` already uses) -- the buffer doubles as `lpstrFile`
//! itself, so the OS writes the answer directly into this builtin's own
//! return value with no extra copy. Returns `""` if the user canceled
//! (`GetOpenFileNameA` returning `FALSE`), the same "empty string means
//! nothing here" convention `file_read`/`read_line`/`tcp_recv` already use,
//! rather than a new `Option`-shaped sentinel this language doesn't have.
//!
//! ## No owner window, and why that's fine
//! `hwndOwner` is left null. `GetOpenFileNameA` blocks the calling thread
//! until the dialog closes either way, which is exactly the "pause here and
//! wait for a binary" behavior a `Load` button wants -- an unparented
//! dialog still works correctly, it's simply not centered over the caller's
//! own window. Parenting it for real would mean resolving a `window_create`
//! handle's actual Win32 `HWND` out of its `SDL_Window*`, which needs
//! `SDL_GetWindowWMInfo` (a whole new builtin, with its own versioned
//! `SDL_SysWMinfo` struct to lay out by hand the same way this module lays
//! out `OPENFILENAMEA`) wired up just to parent one dialog -- a real feature
//! addition, out of scope for this floor.
//!
//! ## Linking note
//! Needs `-l comdlg32` passed explicitly at build time -- like
//! `net.rs`'s `-l ws2_32` and `system_font.rs`'s `-l gdi32`, `comdlg32.dll`
//! isn't part of this target's implicitly-linked default libraries.
//!
//! ## Windows-only by construction
//! Same rationale as `system_font.rs`: there is no POSIX common-dialog
//! syscall for `open_file_dialog` to fall back to under a future
//! `Target::LinuxGnu` (GTK/Qt each have their own, mutually incompatible,
//! file-chooser APIs, and none of them are a thin C ABI call the way this
//! module's single `GetOpenFileNameA` call is) -- a real new backend, not a
//! retrofit, if a second target is ever shipped.

use crate::diagnostics::Span;
use crate::types::*;

use super::Codegen;

impl Codegen {
    /// See this module's own doc comment for the full field-offset
    /// derivation, the filter-string construction, and the ownership/
    /// cancellation conventions.
    pub(super) fn emit_open_file_dialog(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("open_file_dialog(..) expects 1 argument (filter_pattern)", Span::dummy());
            return "i8* null".into();
        };
        let pattern_raw = self.emit_raw_str_ptr(arg);

        // An empty `filter_pattern` falls back to `"*.*"` (all files) --
        // decided at runtime (`strlen`/`select`) since the argument is an
        // ordinary, possibly-empty `str`, not a compile-time constant.
        let raw_len = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", raw_len, pattern_raw));
        let is_empty = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 0", is_empty, raw_len));
        let all_g = self.global_name();
        self.global_defs.push(format!("{} = private unnamed_addr constant [4 x i8] c\"*.*\\00\"", all_g));
        let all_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [4 x i8], [4 x i8]* {}, i64 0, i64 0", all_ptr, all_g));
        let pattern = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i8* {}, i8* {}", pattern, is_empty, all_ptr, pattern_raw));
        let pat_len32 = self.tmp_name();
        self.line(&format!("  {} = call i32 @strlen(i8* {})", pat_len32, pattern));
        let pat_len = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", pat_len, pat_len32));

        // Build `"Files (PATTERN)\0PATTERN\0\0"` into a zeroed scratch
        // buffer -- see this module's own doc comment for why the
        // separator/terminating NULs never need an explicit write.
        const FILTER_CAP: u64 = 512;
        let filter_alloca = self.tmp_name();
        self.line(&format!("  {} = alloca [{} x i8]", filter_alloca, FILTER_CAP));
        let filter_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8], [{} x i8]* {}, i64 0, i64 0",
            filter_ptr, FILTER_CAP, FILTER_CAP, filter_alloca
        ));
        self.emit_fill_i8(&filter_ptr, &FILTER_CAP.to_string(), 0);

        let prefix_g = self.global_name();
        self.global_defs.push(format!("{} = private unnamed_addr constant [7 x i8] c\"Files (\"", prefix_g));
        let prefix_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [7 x i8], [7 x i8]* {}, i64 0, i64 0", prefix_ptr, prefix_g));
        self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 7)", filter_ptr, prefix_ptr));

        let after_prefix = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 7", after_prefix, filter_ptr));
        self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", after_prefix, pattern, pat_len));

        let close_paren_off = self.tmp_name();
        self.line(&format!("  {} = add i64 7, {}", close_paren_off, pat_len));
        let close_paren_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", close_paren_ptr, filter_ptr, close_paren_off));
        self.line(&format!("  store i8 41, i8* {}", close_paren_ptr)); // ')'

        // `+ 2` skips the ')' just written and the (already-zero) NUL that
        // terminates the display half of the pair.
        let second_off = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 2", second_off, close_paren_off));
        let second_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", second_ptr, filter_ptr, second_off));
        self.line(&format!("  call i8* @memcpy(i8* {}, i8* {}, i64 {})", second_ptr, pattern, pat_len));

        // `pattern_raw` is done being read -- release whatever
        // `emit_raw_str_ptr` left us owning (see its own doc comment). The
        // `"*.*"` fallback, if taken, is a `private unnamed_addr constant`,
        // never RC-owned, so this release is always correct regardless of
        // which branch `select` took.
        self.line(&format!("  call void @star_rc_release(i8* {})", pattern_raw));

        // The `OPENFILENAMEA` struct itself -- see this module's own doc
        // comment for the full offset table.
        const OFN_SIZE: u64 = 152;
        let ofn_alloca = self.tmp_name();
        self.line(&format!("  {} = alloca [{} x i8]", ofn_alloca, OFN_SIZE));
        let ofn_ptr = self.tmp_name();
        self.line(&format!(
            "  {} = getelementptr inbounds [{} x i8], [{} x i8]* {}, i64 0, i64 0",
            ofn_ptr, OFN_SIZE, OFN_SIZE, ofn_alloca
        ));
        self.emit_fill_i8(&ofn_ptr, &OFN_SIZE.to_string(), 0);

        // lStructSize (offset 0, DWORD).
        let size_field = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", size_field, ofn_ptr));
        self.line(&format!("  store i32 {}, i32* {}", OFN_SIZE, size_field));

        // lpstrFilter (offset 24, LPCSTR).
        let filter_field_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 24", filter_field_gep, ofn_ptr));
        let filter_field = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i8**", filter_field, filter_field_gep));
        self.line(&format!("  store i8* {}, i8** {}", filter_ptr, filter_field));

        // lpstrFile (offset 48, LPSTR) -- the fresh, owned result buffer
        // (see this module's own doc comment on ownership).
        const PATH_CAP: u64 = 1024;
        let path_buf = self.tmp_name();
        self.line(&format!("  {} = call i8* @star_rc_alloc(i64 {}, i8* null)", path_buf, PATH_CAP));
        self.emit_fill_i8(&path_buf, &PATH_CAP.to_string(), 0);
        let file_field_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 48", file_field_gep, ofn_ptr));
        let file_field = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i8**", file_field, file_field_gep));
        self.line(&format!("  store i8* {}, i8** {}", path_buf, file_field));

        // nMaxFile (offset 56, DWORD) -- must match `path_buf`'s own
        // capacity exactly.
        let maxfile_field_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 56", maxfile_field_gep, ofn_ptr));
        let maxfile_field = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", maxfile_field, maxfile_field_gep));
        self.line(&format!("  store i32 {}, i32* {}", PATH_CAP, maxfile_field));

        // Flags (offset 96, DWORD): OFN_FILEMUSTEXIST (0x1000) |
        // OFN_PATHMUSTEXIST (0x800) | OFN_HIDEREADONLY (0x4) -- a real,
        // already-existing path, and no obsolete "read only" checkbox.
        let flags_field_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 96", flags_field_gep, ofn_ptr));
        let flags_field = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", flags_field, flags_field_gep));
        self.line(&format!("  store i32 6148, i32* {}", flags_field));

        let ok = self.tmp_name();
        self.line(&format!("  {} = call i32 @GetOpenFileNameA(i8* {})", ok, ofn_ptr));
        let canceled = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 0", canceled, ok));
        let cancel_label = self.block_label("open_file_dialog_cancel");
        let end_label = self.block_label("open_file_dialog_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", canceled, cancel_label, end_label));

        self.open_block(&cancel_label);
        // Canceled -- return `""` (see this module's own doc comment),
        // discarding whatever partial path `GetOpenFileNameA` may have
        // written into `path_buf` before the user backed out.
        self.line(&format!("  store i8 0, i8* {}", path_buf));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        path_buf
    }
}

//! Proportional, real-glyph-shaped text rendering via Windows GDI's own font
//! engine (`todo.md` P2 #9, "a proportional/lowercase-aware text renderer, or
//! a documented, supported path to bind `SDL_ttf`") -- the sibling, higher-
//! fidelity counterpart to `crate::codegen::font`'s hand-authored 5x7
//! uppercase-only bitmap font, which remains unchanged and still exists for
//! a zero-setup debug HUD.
//!
//! ## Why GDI instead of `SDL_ttf` or a hand-rolled TrueType rasterizer
//! gdi32.dll ships with every Windows install, so binding it needs no new
//! vendored DLL the way `SDL_ttf` (+ its own transitive `libfreetype`
//! dependency) would, the exact tradeoff `crate::codegen::font`'s own doc
//! comment already declined. It also sidesteps hand-rolling a TrueType
//! glyph-outline rasterizer (`glyf`/`loca` quadratic-bezier parsing,
//! scanline coverage antialiasing) entirely as hand-emitted LLVM IR text --
//! what `stb_truetype.h` needs ~5000 careful lines of C for. Windows' own
//! font engine already does that work (with real hinting, antialiasing, and
//! kerning) behind a flat, easy-to-`declare`-and-`call` C ABI; this module
//! only has to drive it and copy its output into an SDL texture.
//!
//! ## Windows-only by construction, not by omission
//! Unlike `par_pool.rs`'s thread/semaphore/core-count primitives (see
//! `crate::codegen::platform`), this module has no cross-platform seam and
//! isn't going to grow one cheaply: there's no POSIX syscall that
//! rasterizes a TrueType glyph, only a genuinely new rendering backend
//! (`SDL_ttf`+`libfreetype`, or a hand-rolled rasterizer) would make
//! `font_load_system`/`font_load_ttf`/`draw_text_ttf` work under
//! `Target::LinuxGnu` -- a real feature addition, not a retrofit, and out of
//! scope until (if) a second target is ever actually shipped. Every
//! `declare` this module needs (`CreateFontA`, `TextOutA`, ...) stays
//! unconditional regardless of `Target` -- an unreferenced `declare` costs
//! nothing at link time -- but calling any of these builtins under
//! `Target::LinuxGnu` will still fail to *link*, on purpose, since nothing
//! provides those symbols there. `crate::codegen::font`'s hand-rolled 5x7
//! bitmap font is the already-portable fallback for a program that needs
//! text under both targets.
//!
//! ## Loading
//! `font_load_system(window, family, size) -> ptr` loads an already-
//! installed system font by family name (e.g. `"Segoe UI"`, `"Consolas"`) --
//! the literal "loading system fonts" this feature exists for.
//! `font_load_ttf(window, path, size) -> ptr` loads a bundled `.ttf`/`.otf`
//! file instead, so a game can ship its own font and get a consistent look
//! regardless of what's installed on the player's machine: it privately
//! registers the file (`AddFontResourceExA`, `FR_PRIVATE` -- invisible
//! system-wide, undone by a matching `RemoveFontResourceExA` once loading
//! finishes), then hand-parses just enough of the file's own `sfnt` table
//! directory and `name` table (a small, bounded, fixed-format binary parse,
//! no different in kind from `crate::codegen::font::emit_font_load`'s or
//! `crate::codegen::audio`'s own hand-rolled header parsing) to recover the
//! font's family name -- GDI has no "open by file path" entry point, only
//! "select an installed face by name". Both loaders share one rasterization
//! core (`emit_rasterize_font`) once they have a real `HFONT`.
//!
//! `size` is a pixel height, clamped to `>= 1`; both loaders take a
//! `window` up front because the rasterized glyph atlas becomes a real
//! `SDL_Texture`, and an SDL texture is inherently owned by one
//! `SDL_Renderer` (re-derived from `window` exactly like every other
//! drawing builtin in `crate::codegen::sdl` -- see that module's own doc
//! comment) -- unlike the old bitmap `ptr` font handle, a font loaded here
//! can only ever be drawn against the window it was loaded for.
//!
//! ## Rasterization (`emit_rasterize_font`)
//! Renders the fixed printable-ASCII range `' '..='~'` (32..=126, 95
//! glyphs -- real distinct upper *and* lowercase shapes, unlike
//! `crate::codegen::font`'s fold-to-uppercase bitmap font) once, up front,
//! into one horizontal atlas: `GetTextExtentPoint32A` measures each glyph's
//! own advance width (proportional, not a fixed cell), `TextOutA` draws it
//! at the running cursor with `SetBkMode(TRANSPARENT)`/white
//! `SetTextColor`/`ANTIALIASED_QUALITY` (grayscale AA, deliberately *not*
//! `CLEARTYPE_QUALITY` -- ClearType's per-subpixel RGB fringing would break
//! the "R, G, and B channels are always equal" assumption the next step
//! relies on) into a top-down 32bpp `CreateDIBSection` bitmap zeroed to
//! black first. White-glyph-on-black-background is a coverage trick: the
//! resulting pixel's equal R=G=B value *is* that pixel's antialiased glyph
//! coverage (0 = background, 255 = fully inside a stroke). A follow-up pass
//! (`emit_convert_coverage_to_alpha`) rewrites each pixel from `(cov, cov,
//! cov, 0)` to `(255, 255, 255, cov)` -- opaque white with the coverage
//! moved into the alpha channel -- which is then the raw byte layout
//! `SDL_PIXELFORMAT_ARGB8888` expects on this little-endian target (bytes
//! `B, G, R, A`, matching a 32bpp `BI_RGB` DIB's own `B, G, R, unused`
//! layout exactly, so only the 4th byte of each pixel ever needs to
//! change). The atlas becomes a real `SDL_Texture`
//! (`SDL_TEXTUREACCESS_STATIC`, blend mode `SDL_BLENDMODE_BLEND`) via one
//! `SDL_UpdateTexture` call; every GDI object (`HFONT`/`HBITMAP`/memory
//! `HDC`) is deleted immediately afterward -- once the pixels are copied
//! into the texture, none of them are needed again.
//!
//! `Ty::Ptr` is reused as the opaque font handle (a `malloc`'d, RC-header-
//! free buffer -- see `crate::codegen::font`'s own doc comment for why:
//! `[i8* sdl_texture][i32 line_height][i32 x 95 glyph_x][i32 x 95
//! glyph_w]`, `HANDLE_SIZE` bytes total, freed with plain `free()` by
//! `font_ttf_free`, never `star_rc_release`). `glyph_x`/`glyph_w` are
//! indexed by `codepoint - FIRST_CHAR`; a codepoint outside
//! `FIRST_CHAR..=LAST_CHAR` (including `\n`, handled separately as a line
//! break) draws as nothing and advances by glyph 0's own width (the space
//! character's real advance, not an arbitrary guess), matching
//! `crate::codegen::font`'s own "stays aligned, doesn't drift" convention
//! for an unsupported character.
//!
//! ## Linking note
//! Needs `-l gdi32` passed explicitly at build time, mirroring
//! `crate::codegen::net`'s own `-l ws2_32` note -- gdi32 isn't part of this
//! target's implicitly-linked default libraries. Also needs
//! `-L sdl/lib/x64 -l SDL2` (see `crate::codegen::sdl`'s doc comment) since
//! the rasterized atlas is drawn through an ordinary SDL texture/renderer.

use crate::diagnostics::Span;
use crate::types::*;

use super::Codegen;

/// First/last codepoint the atlas covers -- the full printable-ASCII range,
/// deliberately wider than `crate::codegen::font`'s uppercase-only default
/// font since GDI rasterizes real lowercase glyph shapes for free.
const FIRST_CHAR: u32 = 32;
const LAST_CHAR: u32 = 126;
/// `LAST_CHAR - FIRST_CHAR + 1`.
const NUM_GLYPHS: u32 = LAST_CHAR - FIRST_CHAR + 1;

/// Font handle byte layout -- see this module's own doc comment.
const TEX_OFF: i64 = 0;
const LINEH_OFF: i64 = 8;
const GLYPH_X_OFF: i64 = 12;
const GLYPH_W_OFF: i64 = GLYPH_X_OFF + (NUM_GLYPHS as i64) * 4;
const HANDLE_SIZE: i64 = GLYPH_W_OFF + (NUM_GLYPHS as i64) * 4;

/// `FR_PRIVATE` (`wingdi.h`): the font is only visible to this process, and
/// only for as long as it stays registered -- never system-wide, never
/// persisted.
const FR_PRIVATE: u32 = 0x10;
/// `SDL_PIXELFORMAT_ARGB8888` (`SDL_pixels.h`) -- see this module's own doc
/// comment for the exact byte layout this depends on.
const SDL_PIXELFORMAT_ARGB8888: u32 = 372_645_892;
/// `SDL_BLENDMODE_BLEND`.
const SDL_BLENDMODE_BLEND: u32 = 1;

/// Dead-space padding (pixels) left between adjacent glyph cells in the
/// atlas. GDI positions/advances glyphs by their *advance width*, but a
/// glyph's actual antialiased ink can extend past that box (ordinary,
/// non-italic overhang -- e.g. the curved right edge of `n`/`g`, or the
/// AA fringe on a serif/round stroke), even at `ANTIALIASED_QUALITY`. With
/// zero gap, packing every glyph edge-to-edge at its cursor position lets
/// one glyph's overhang bleed into the *next* glyph's own atlas column
/// (`TextOutA` never clears what's already there in `TRANSPARENT` mode) --
/// invisible until that next glyph's own `src_rect` samples it back out as
/// a stray pixel glued to the wrong character. Padding leaves overhang
/// room to bleed into empty atlas space instead, without changing any
/// glyph's own recorded advance width (`glyph_w`, used for text layout/
/// draw-cursor advance) -- only where each glyph's *storage* starts in the
/// atlas moves. Confirmed as the real cause (not a measurement /
/// coverage-conversion bug) by reproducing it live: `"Engine"` at 32px
/// visibly glued a stray fragment near `n`/`g`/`i` before this padding was
/// added, gone after.
const GLYPH_PAD: i32 = 3;

impl Codegen {

    /// Abort (mirrors `crate::codegen::font::abort_if_null_font`'s shape
    /// exactly, with wording distinguishing this handle kind) if `handle`
    /// is a null `ptr`.
    fn abort_if_null_system_font(&mut self, handle: &str, builtin_name: &str) {
        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, handle));
        let fail_label = self.block_label("sysfont_null_handle");
        let ok_label = self.block_label("sysfont_handle_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, fail_label, ok_label));

        self.open_block(&fail_label);
        let msg = format!("star runtime error: {}(..) called with a null/freed system-font handle\n", builtin_name);
        let g = self.global_name();
        let escaped = msg.replace("\\", "\\\\").replace("\"", "\\22").replace("\n", "\\0A");
        self.global_defs.push(format!("{} = private unnamed_addr constant [{} x i8] c\"{}\\00\"", g, msg.len() + 1, escaped));
        let msg_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [{} x i8], [{} x i8]* {}, i64 0, i64 0", msg_ptr, msg.len() + 1, msg.len() + 1, g));
        self.line(&format!("  call i32 @puts(i8* {})", msg_ptr));
        self.line("  call void @exit(i32 1)");
        self.line("  unreachable");

        self.open_block(&ok_label);
    }

    /// `getelementptr inbounds i8, i8* base, i64 off` into a fresh register
    /// -- the single-instruction byte-offset helper almost every step below
    /// needs (this module reads a lot of small, fixed-offset struct/table
    /// fields).
    fn gep8(&mut self, base: &str, off: i64) -> String {
        let p = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", p, base, off));
        p
    }

    /// Same as `gep8`, but `off` is itself a runtime `i32` register
    /// (sign-extended to `i64` first) rather than a compile-time literal.
    fn gep8_dyn(&mut self, base: &str, off32: &str) -> String {
        let off64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", off64, off32));
        let p = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", p, base, off64));
        p
    }

    /// Read a big-endian `u16` at byte pointer `ptr` into an `i32` register
    /// -- every multi-byte field in an `sfnt` (TrueType/OpenType) file is
    /// big-endian, the opposite of this target's native little-endian byte
    /// order, so (unlike `crate::codegen::audio`'s WAV-tag reads, which are
    /// little-endian and so can just `load i32` directly) each field here
    /// needs an explicit byte-by-byte shift-and-combine.
    fn emit_read_u16be(&mut self, ptr: &str) -> String {
        let b0 = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", b0, ptr));
        let p1 = self.gep8(ptr, 1);
        let b1 = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", b1, p1));
        let b0_32 = self.tmp_name();
        self.line(&format!("  {} = zext i8 {} to i32", b0_32, b0));
        let b1_32 = self.tmp_name();
        self.line(&format!("  {} = zext i8 {} to i32", b1_32, b1));
        let shifted = self.tmp_name();
        self.line(&format!("  {} = shl i32 {}, 8", shifted, b0_32));
        let combined = self.tmp_name();
        self.line(&format!("  {} = or i32 {}, {}", combined, shifted, b1_32));
        combined
    }

    /// `emit_read_u16be`'s 4-byte counterpart, used for `sfnt` table-tag/
    /// offset/length fields.
    fn emit_read_u32be(&mut self, ptr: &str) -> String {
        let mut bytes = Vec::with_capacity(4);
        for i in 0..4i64 {
            let bp = self.gep8(ptr, i);
            let b = self.tmp_name();
            self.line(&format!("  {} = load i8, i8* {}", b, bp));
            let b32 = self.tmp_name();
            self.line(&format!("  {} = zext i8 {} to i32", b32, b));
            bytes.push(b32);
        }
        let acc0 = self.tmp_name();
        self.line(&format!("  {} = shl i32 {}, 24", acc0, bytes[0]));
        let mut acc = acc0;
        for (i, b) in bytes.iter().enumerate().skip(1) {
            let shifted = self.tmp_name();
            self.line(&format!("  {} = shl i32 {}, {}", shifted, b, (3 - i) * 8));
            let combined = self.tmp_name();
            self.line(&format!("  {} = or i32 {}, {}", combined, acc, shifted));
            acc = combined;
        }
        acc
    }

    /// Build a stack `SDL_Rect` (see `crate::codegen::sdl::emit_fill_rect`'s
    /// own doc comment for the identical 16-byte layout) and return its
    /// pointer, without drawing anything -- `SDL_RenderCopy` (unlike
    /// `SDL_RenderFillRect`) needs *two* such rects (source and
    /// destination) per call.
    fn emit_build_rect(&mut self, x: &str, y: &str, w: &str, h: &str) -> String {
        let rect_buf = self.tmp_name();
        self.line(&format!("  {} = alloca [16 x i8]", rect_buf));
        let rect_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [16 x i8], [16 x i8]* {}, i64 0, i64 0", rect_ptr, rect_buf));
        let x_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", x_ptr, rect_ptr));
        self.line(&format!("  store i32 {}, i32* {}", x, x_ptr));
        let y_gep = self.gep8(&rect_ptr, 4);
        let y_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", y_ptr, y_gep));
        self.line(&format!("  store i32 {}, i32* {}", y, y_ptr));
        let w_gep = self.gep8(&rect_ptr, 8);
        let w_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", w_ptr, w_gep));
        self.line(&format!("  store i32 {}, i32* {}", w, w_ptr));
        let h_gep = self.gep8(&rect_ptr, 12);
        let h_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", h_ptr, h_gep));
        self.line(&format!("  store i32 {}, i32* {}", h, h_ptr));
        rect_ptr
    }

    /// Clamp a caller-supplied point-size argument to `>= 1` -- mirrors
    /// `crate::codegen::font::emit_clamp_scale`'s exact rationale (a `0` or
    /// negative size would otherwise reach `CreateFontA` as a meaningless
    /// or degenerate request instead of failing safely).
    fn emit_clamp_size(&mut self, size: &str) -> String {
        let is_pos = self.tmp_name();
        self.line(&format!("  {} = icmp sgt i32 {}, 0", is_pos, size));
        let clamped = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i32 {}, i32 1", clamped, is_pos, size));
        clamped
    }

    /// Rewrite a `w * h * 4`-byte, white-on-black-rasterized 32bpp buffer
    /// (`(cov, cov, cov, 0)` per pixel) in place into
    /// `SDL_PIXELFORMAT_ARGB8888`'s own expected layout (`(255, 255, 255,
    /// cov)`) -- see this module's own doc comment for why this is the
    /// *only* per-pixel transformation needed. `pixel_count64` is an `i64`
    /// register or literal.
    fn emit_convert_coverage_to_alpha(&mut self, buf: &str, pixel_count64: &str) {
        let i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", i_ptr));
        self.line(&format!("  store i64 0, i64* {}", i_ptr));
        let cond = self.block_label("cov2a_cond");
        let body = self.block_label("cov2a_body");
        let end = self.block_label("cov2a_end");
        self.line(&format!("  br label %{}", cond));

        self.open_block(&cond);
        let i = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", i, i_ptr));
        let more = self.tmp_name();
        self.line(&format!("  {} = icmp slt i64 {}, {}", more, i, pixel_count64));
        self.line(&format!("  br i1 {}, label %{}, label %{}", more, body, end));

        self.open_block(&body);
        let byte_off = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, 4", byte_off, i));
        let px = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", px, buf, byte_off));
        let blue = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", blue, px));
        let g_ptr = self.gep8(&px, 1);
        let r_ptr = self.gep8(&px, 2);
        let a_ptr = self.gep8(&px, 3);
        self.line(&format!("  store i8 {}, i8* {}", blue, a_ptr));
        self.line(&format!("  store i8 255, i8* {}", px));
        self.line(&format!("  store i8 255, i8* {}", g_ptr));
        self.line(&format!("  store i8 255, i8* {}", r_ptr));
        let i_next = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", i_next, i));
        self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
        self.line(&format!("  br label %{}", cond));

        self.open_block(&end);
    }

    /// The shared rasterization core both `font_load_system`/`font_load_ttf`
    /// call once they have a real, already-`CreateFontA`'d `hfont` -- see
    /// this module's own doc comment for the full algorithm. Always
    /// consumes (deletes) `hfont`, on every path including failure, so
    /// neither caller needs its own cleanup for it. Returns a null `ptr` if
    /// any GDI/SDL resource acquisition here fails (`CreateCompatibleDC`,
    /// `CreateDIBSection`, `SDL_CreateTexture`) -- `hfont` itself creating
    /// successfully is checked by the caller before this is ever called.
    fn emit_rasterize_font(&mut self, window: &str, hfont: &str) -> String {
        let result_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i8*", result_ptr));
        self.line(&format!("  store i8* null, i8** {}", result_ptr));
        let end_label = self.block_label("rasterize_end");

        let renderer = self.emit_sdl_get_renderer(window);

        let memdc = self.tmp_name();
        self.line(&format!("  {} = call i8* @CreateCompatibleDC(i8* null)", memdc));
        let memdc_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", memdc_null, memdc));
        let memdc_fail = self.block_label("rasterize_memdc_fail");
        let memdc_ok = self.block_label("rasterize_memdc_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", memdc_null, memdc_fail, memdc_ok));

        self.open_block(&memdc_fail);
        self.line(&format!("  call i32 @DeleteObject(i8* {})", hfont));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&memdc_ok);
        let old_font = self.tmp_name();
        self.line(&format!("  {} = call i8* @SelectObject(i8* {}, i8* {})", old_font, memdc, hfont));
        self.line(&format!("  call i32 @SetBkMode(i8* {}, i32 1)", memdc)); // TRANSPARENT
        self.line(&format!("  call i32 @SetTextColor(i8* {}, i32 16777215)", memdc)); // 0x00FFFFFF, white

        // `TEXTMETRICA`: only `tmHeight` (the struct's leading `LONG`) is
        // read. Buffer sized generously past the struct's real ~53 bytes.
        let tm_buf = self.tmp_name();
        self.line(&format!("  {} = alloca [64 x i8]", tm_buf));
        let tm_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [64 x i8], [64 x i8]* {}, i64 0, i64 0", tm_ptr, tm_buf));
        self.line(&format!("  call i32 @GetTextMetricsA(i8* {}, i8* {})", memdc, tm_ptr));
        let tmheight_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", tmheight_ptr, tm_ptr));
        let tmheight_raw = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", tmheight_raw, tmheight_ptr));
        let tmheight_ok = self.tmp_name();
        self.line(&format!("  {} = icmp sgt i32 {}, 0", tmheight_ok, tmheight_raw));
        let line_height = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i32 {}, i32 1", line_height, tmheight_ok, tmheight_raw));

        // The font handle buffer -- allocated now so the glyph-measuring
        // pass below can store `glyph_x`/`glyph_w` directly into their
        // final home as it goes.
        let handle = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", handle, HANDLE_SIZE));

        let char_buf = self.tmp_name();
        self.line(&format!("  {} = alloca i8", char_buf));
        let size_buf = self.tmp_name();
        self.line(&format!("  {} = alloca [8 x i8]", size_buf)); // SIZE { LONG cx; LONG cy; }
        let size_cx_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast [8 x i8]* {} to i32*", size_cx_ptr, size_buf));

        // Pass 1: measure every glyph's own advance width and lay the atlas
        // out left-to-right, storing each glyph's `(x_offset, width)`
        // straight into the handle buffer at its fixed (compile-time-known)
        // index -- `idx` is a Rust-level loop counter here, not a Star
        // runtime value, so every offset below is a plain integer literal,
        // not a computed GEP.
        let mut cursor = "0".to_string();
        let mut glyph_x_regs: Vec<String> = Vec::with_capacity(NUM_GLYPHS as usize);
        for (idx, ch) in (FIRST_CHAR..=LAST_CHAR).enumerate() {
            self.line(&format!("  store i8 {}, i8* {}", ch, char_buf));
            self.line(&format!(
                "  call i32 @GetTextExtentPoint32A(i8* {}, i8* {}, i32 1, i8* {})",
                memdc, char_buf, size_buf
            ));
            let w_raw = self.tmp_name();
            self.line(&format!("  {} = load i32, i32* {}", w_raw, size_cx_ptr));
            let w_ok = self.tmp_name();
            self.line(&format!("  {} = icmp sgt i32 {}, 0", w_ok, w_raw));
            let w = self.tmp_name();
            self.line(&format!("  {} = select i1 {}, i32 {}, i32 1", w, w_ok, w_raw));

            let gx_off = GLYPH_X_OFF + (idx as i64) * 4;
            let gx_field = self.gep8(&handle, gx_off);
            let gx_field_i32 = self.tmp_name();
            self.line(&format!("  {} = bitcast i8* {} to i32*", gx_field_i32, gx_field));
            self.line(&format!("  store i32 {}, i32* {}", cursor, gx_field_i32));
            let gw_off = GLYPH_W_OFF + (idx as i64) * 4;
            let gw_field = self.gep8(&handle, gw_off);
            let gw_field_i32 = self.tmp_name();
            self.line(&format!("  {} = bitcast i8* {} to i32*", gw_field_i32, gw_field));
            self.line(&format!("  store i32 {}, i32* {}", w, gw_field_i32));

            glyph_x_regs.push(cursor.clone());
            let next_cursor = self.tmp_name();
            self.line(&format!("  {} = add i32 {}, {}", next_cursor, cursor, w));
            let next_cursor_padded = self.tmp_name();
            self.line(&format!("  {} = add i32 {}, {}", next_cursor_padded, next_cursor, GLYPH_PAD));
            cursor = next_cursor_padded;
        }
        let atlas_width = cursor;

        // `BITMAPINFOHEADER`, 40 bytes, `BI_RGB`/32bpp, top-down (negative
        // height).
        let bmi_buf = self.tmp_name();
        self.line(&format!("  {} = alloca [40 x i8]", bmi_buf));
        let bmi_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [40 x i8], [40 x i8]* {}, i64 0, i64 0", bmi_ptr, bmi_buf));
        self.emit_fill_i8(&bmi_ptr, "40", 0);
        let bmi_size_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", bmi_size_ptr, bmi_ptr));
        self.line(&format!("  store i32 40, i32* {}", bmi_size_ptr));
        let bmi_w_gep = self.gep8(&bmi_ptr, 4);
        let bmi_w_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", bmi_w_ptr, bmi_w_gep));
        self.line(&format!("  store i32 {}, i32* {}", atlas_width, bmi_w_ptr));
        let neg_line_height = self.tmp_name();
        self.line(&format!("  {} = sub i32 0, {}", neg_line_height, line_height));
        let bmi_h_gep = self.gep8(&bmi_ptr, 8);
        let bmi_h_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", bmi_h_ptr, bmi_h_gep));
        self.line(&format!("  store i32 {}, i32* {}", neg_line_height, bmi_h_ptr));
        let bmi_planes_gep = self.gep8(&bmi_ptr, 12);
        let bmi_planes_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i16*", bmi_planes_ptr, bmi_planes_gep));
        self.line(&format!("  store i16 1, i16* {}", bmi_planes_ptr));
        let bmi_bits_gep = self.gep8(&bmi_ptr, 14);
        let bmi_bits_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i16*", bmi_bits_ptr, bmi_bits_gep));
        self.line(&format!("  store i16 32, i16* {}", bmi_bits_ptr));

        let dibbits_slot = self.tmp_name();
        self.line(&format!("  {} = alloca i8*", dibbits_slot));
        let hbitmap = self.tmp_name();
        self.line(&format!(
            "  {} = call i8* @CreateDIBSection(i8* {}, i8* {}, i32 0, i8** {}, i8* null, i32 0)",
            hbitmap, memdc, bmi_ptr, dibbits_slot
        ));
        let hbitmap_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", hbitmap_null, hbitmap));
        let dib_fail = self.block_label("rasterize_dib_fail");
        let dib_ok = self.block_label("rasterize_dib_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", hbitmap_null, dib_fail, dib_ok));

        self.open_block(&dib_fail);
        self.line(&format!("  call i8* @SelectObject(i8* {}, i8* {})", memdc, old_font));
        self.line(&format!("  call i32 @DeleteObject(i8* {})", hfont));
        self.line(&format!("  call i32 @DeleteDC(i8* {})", memdc));
        self.line(&format!("  call void @free(i8* {})", handle));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&dib_ok);
        let dib_bits = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", dib_bits, dibbits_slot));
        let old_bmp = self.tmp_name();
        self.line(&format!("  {} = call i8* @SelectObject(i8* {}, i8* {})", old_bmp, memdc, hbitmap));

        let pixel_count = self.tmp_name();
        self.line(&format!("  {} = mul i32 {}, {}", pixel_count, atlas_width, line_height));
        let pixel_count64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", pixel_count64, pixel_count));
        let byte_count64 = self.tmp_name();
        self.line(&format!("  {} = mul i64 {}, 4", byte_count64, pixel_count64));
        self.emit_fill_i8(&dib_bits, &byte_count64, 0);

        // Pass 2: draw every glyph at its already-computed `x_offset`
        // (`glyph_x_regs`, from pass 1 -- no need to reload it from the
        // handle buffer).
        for (idx, ch) in (FIRST_CHAR..=LAST_CHAR).enumerate() {
            self.line(&format!("  store i8 {}, i8* {}", ch, char_buf));
            self.line(&format!(
                "  call i32 @TextOutA(i8* {}, i32 {}, i32 0, i8* {}, i32 1)",
                memdc, glyph_x_regs[idx], char_buf
            ));
        }

        self.line(&format!("  call i8* @SelectObject(i8* {}, i8* {})", memdc, old_font));
        self.line(&format!("  call i8* @SelectObject(i8* {}, i8* {})", memdc, old_bmp));

        self.emit_convert_coverage_to_alpha(&dib_bits, &pixel_count64);

        let tex = self.tmp_name();
        self.line(&format!(
            "  {} = call i8* @SDL_CreateTexture(i8* {}, i32 {}, i32 0, i32 {}, i32 {})",
            tex, renderer, SDL_PIXELFORMAT_ARGB8888, atlas_width, line_height
        ));
        let tex_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", tex_null, tex));
        let tex_fail = self.block_label("rasterize_tex_fail");
        let tex_ok = self.block_label("rasterize_tex_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", tex_null, tex_fail, tex_ok));

        self.open_block(&tex_fail);
        self.line(&format!("  call i32 @DeleteObject(i8* {})", hbitmap));
        self.line(&format!("  call i32 @DeleteObject(i8* {})", hfont));
        self.line(&format!("  call i32 @DeleteDC(i8* {})", memdc));
        self.line(&format!("  call void @free(i8* {})", handle));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&tex_ok);
        self.line(&format!("  call i32 @SDL_SetTextureBlendMode(i8* {}, i32 {})", tex, SDL_BLENDMODE_BLEND));
        let pitch = self.tmp_name();
        self.line(&format!("  {} = mul i32 {}, 4", pitch, atlas_width));
        self.line(&format!(
            "  call i32 @SDL_UpdateTexture(i8* {}, i8* null, i8* {}, i32 {})",
            tex, dib_bits, pitch
        ));
        self.line(&format!("  call i32 @DeleteObject(i8* {})", hbitmap));
        self.line(&format!("  call i32 @DeleteObject(i8* {})", hfont));
        self.line(&format!("  call i32 @DeleteDC(i8* {})", memdc));

        let handle_tex_ptr = self.gep8(&handle, TEX_OFF);
        let handle_tex_slot = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i8**", handle_tex_slot, handle_tex_ptr));
        self.line(&format!("  store i8* {}, i8** {}", tex, handle_tex_slot));
        let handle_lineh_ptr = self.gep8(&handle, LINEH_OFF);
        let handle_lineh_slot = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", handle_lineh_slot, handle_lineh_ptr));
        self.line(&format!("  store i32 {}, i32* {}", line_height, handle_lineh_slot));
        self.line(&format!("  store i8* {}, i8** {}", handle, result_ptr));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let result = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", result, result_ptr));
        result
    }

    /// `font_load_system(window: ptr, family: str, size: int) -> ptr`: loads
    /// an already-installed system font by family name. `null` on failure
    /// (an unknown/unmatched family is unusual -- GDI's font mapper
    /// substitutes a close match rather than failing outright -- but a
    /// downstream `CreateCompatibleDC`/`CreateDIBSection`/
    /// `SDL_CreateTexture` failure still surfaces as `null` here, checked
    /// with `is_null` exactly like `font_load`/`window_create`).
    pub(super) fn emit_font_load_system(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 3 {
            self.err("font_load_system(..) expects 3 arguments (window, family, size)", Span::dummy());
            return "i8* null".into();
        }
        let wv = self.emit_expr(&args[0]);
        let window = self.untag(&wv, &Ty::Ptr);
        self.abort_if_null_window(&window, "font_load_system");
        let family_ptr = self.emit_raw_str_ptr(&args[1]);
        let sv = self.emit_expr(&args[2]);
        let size_raw = self.untag(&sv, &Ty::Int);
        let size = self.emit_clamp_size(&size_raw);
        let neg_size = self.tmp_name();
        self.line(&format!("  {} = sub i32 0, {}", neg_size, size));

        let hfont = self.tmp_name();
        self.line(&format!(
            "  {} = call i8* @CreateFontA(i32 {}, i32 0, i32 0, i32 0, i32 400, i32 0, i32 0, i32 0, i32 1, i32 4, i32 0, i32 4, i32 0, i8* {})",
            hfont, neg_size, family_ptr
        ));
        self.line(&format!("  call void @star_rc_release(i8* {})", family_ptr));

        let hfont_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", hfont_null, hfont));
        let fail_label = self.block_label("font_load_system_fail");
        let ok_label = self.block_label("font_load_system_ok");
        let end_label = self.block_label("font_load_system_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", hfont_null, fail_label, ok_label));

        self.open_block(&fail_label);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&ok_label);
        let handle = self.emit_rasterize_font(&window, &hfont);
        // `emit_rasterize_font` opens several basic blocks of its own, so
        // the block actually falling through to `end_label` below is
        // whichever one it last opened (`self.current_label`), not
        // `ok_label` itself -- see `Codegen::current_label`'s own doc
        // comment for why every value-producing `phi` here must ask rather
        // than assume.
        let handle_from = self.current_label.clone();
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let result = self.tmp_name();
        self.line(&format!("  {} = phi i8* [ null, %{} ], [ {}, %{} ]", result, fail_label, handle, handle_from));
        format!("i8* {}", result)
    }

    /// Shared cleanup for `font_load_ttf`'s several post-`AddFontResourceExA`
    /// failure paths: undo the private font-resource registration and free
    /// the loaded file buffer, since both are only ever live between a
    /// successful `AddFontResourceExA` and this being called.
    fn emit_ttf_load_fail_cleanup(&mut self, path_ptr: &str, buf: &str) {
        self.line(&format!("  call i32 @RemoveFontResourceExA(i8* {}, i32 {}, i8* null)", path_ptr, FR_PRIVATE));
        self.line(&format!("  call void @free(i8* {})", buf));
    }

    /// `font_load_ttf(window: ptr, path: str, size: int) -> ptr`: loads a
    /// bundled `.ttf`/`.otf` file -- see this module's own doc comment for
    /// the private-registration-plus-`name`-table-parse approach. `null` on
    /// any failure (missing/unreadable file, not a recognizable `sfnt`
    /// file, no usable family name found, or a downstream rasterization
    /// failure), checked with `is_null`.
    pub(super) fn emit_font_load_ttf(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 3 {
            self.err("font_load_ttf(..) expects 3 arguments (window, path, size)", Span::dummy());
            return "i8* null".into();
        }
        let wv = self.emit_expr(&args[0]);
        let window = self.untag(&wv, &Ty::Ptr);
        self.abort_if_null_window(&window, "font_load_ttf");
        let path_ptr = self.emit_raw_str_ptr(&args[1]);
        let sv = self.emit_expr(&args[2]);
        let size_raw = self.untag(&sv, &Ty::Int);
        let size = self.emit_clamp_size(&size_raw);
        let neg_size = self.tmp_name();
        self.line(&format!("  {} = sub i32 0, {}", neg_size, size));

        let result_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i8*", result_ptr));
        self.line(&format!("  store i8* null, i8** {}", result_ptr));
        let end_label = self.block_label("ttf_load_end");

        // Read the whole file into a fresh `malloc`'d buffer -- same
        // `fopen`/`fseek`/`ftell`/`malloc`+`fread` shape as
        // `crate::codegen::font::emit_font_load`/
        // `crate::codegen::audio::emit_sound_load`.
        let mode_g = self.global_name();
        self.global_defs.push(format!("{} = private unnamed_addr constant [3 x i8] c\"rb\\00\"", mode_g));
        let mode_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [3 x i8], [3 x i8]* {}, i64 0, i64 0", mode_ptr, mode_g));
        let fhandle = self.tmp_name();
        self.line(&format!("  {} = call i8* @fopen(i8* {}, i8* {})", fhandle, path_ptr, mode_ptr));

        let open_failed = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", open_failed, fhandle));
        let open_fail_label = self.block_label("ttf_load_open_fail");
        let open_ok_label = self.block_label("ttf_load_open_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", open_failed, open_fail_label, open_ok_label));

        self.open_block(&open_fail_label);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&open_ok_label);
        self.line(&format!("  call i32 @fseek(i8* {}, i32 0, i32 2)", fhandle));
        let size0 = self.tmp_name();
        self.line(&format!("  {} = call i32 @ftell(i8* {})", size0, fhandle));
        self.line(&format!("  call i32 @fseek(i8* {}, i32 0, i32 0)", fhandle));

        let size_ok = self.tmp_name();
        self.line(&format!("  {} = icmp sge i32 {}, 12", size_ok, size0)); // sfnt header minimum
        let too_small_label = self.block_label("ttf_load_too_small");
        let read_label = self.block_label("ttf_load_read");
        self.line(&format!("  br i1 {}, label %{}, label %{}", size_ok, read_label, too_small_label));

        self.open_block(&too_small_label);
        self.line(&format!("  call i32 @fclose(i8* {})", fhandle));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&read_label);
        let size64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", size64, size0));
        let buf = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", buf, size64));
        self.line(&format!("  call i64 @fread(i8* {}, i64 1, i64 {}, i8* {})", buf, size64, fhandle));
        self.line(&format!("  call i32 @fclose(i8* {})", fhandle));

        // Privately register the file so `CreateFontA` (below) can find it
        // by name -- GDI has no "open by path" entry point.
        let added = self.tmp_name();
        self.line(&format!("  {} = call i32 @AddFontResourceExA(i8* {}, i32 {}, i8* null)", added, path_ptr, FR_PRIVATE));
        let add_failed = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 0", add_failed, added));
        let add_fail_label = self.block_label("ttf_load_add_fail");
        let add_ok_label = self.block_label("ttf_load_add_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", add_failed, add_fail_label, add_ok_label));

        self.open_block(&add_fail_label);
        self.line(&format!("  call void @free(i8* {})", buf));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&add_ok_label);

        // Scan the `sfnt` table directory for the `name` table.
        let numtables_ptr0 = self.gep8(&buf, 4);
        let numtables = self.emit_read_u16be(&numtables_ptr0);
        let tdir_found_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i1", tdir_found_ptr));
        self.line(&format!("  store i1 false, i1* {}", tdir_found_ptr));
        let tdir_off_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", tdir_off_ptr));
        self.line(&format!("  store i32 0, i32* {}", tdir_off_ptr));
        let tdir_i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", tdir_i_ptr));
        self.line(&format!("  store i32 0, i32* {}", tdir_i_ptr));

        let tdir_cond = self.block_label("ttf_tdir_cond");
        let tdir_body = self.block_label("ttf_tdir_body");
        let tdir_match = self.block_label("ttf_tdir_match");
        let tdir_next = self.block_label("ttf_tdir_next");
        let tdir_end = self.block_label("ttf_tdir_end");
        self.line(&format!("  br label %{}", tdir_cond));

        self.open_block(&tdir_cond);
        let ti = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", ti, tdir_i_ptr));
        let ti_lt_n = self.tmp_name();
        self.line(&format!("  {} = icmp slt i32 {}, {}", ti_lt_n, ti, numtables));
        let entry_base = self.tmp_name();
        self.line(&format!("  {} = mul i32 {}, 16", entry_base, ti));
        let entry_base2 = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 12", entry_base2, entry_base));
        let entry_end = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 16", entry_end, entry_base2));
        let entry_fits = self.tmp_name();
        self.line(&format!("  {} = icmp sle i32 {}, {}", entry_fits, entry_end, size0));
        let tdir_go = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", tdir_go, ti_lt_n, entry_fits));
        self.line(&format!("  br i1 {}, label %{}, label %{}", tdir_go, tdir_body, tdir_end));

        self.open_block(&tdir_body);
        let entry_ptr = self.gep8_dyn(&buf, &entry_base2);
        let tag = self.emit_read_u32be(&entry_ptr);
        let is_name = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, {}", is_name, tag, u32::from_be_bytes(*b"name")));
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_name, tdir_match, tdir_next));

        self.open_block(&tdir_match);
        let off_ptr = self.gep8(&entry_ptr, 8);
        let off_val = self.emit_read_u32be(&off_ptr);
        self.line(&format!("  store i1 true, i1* {}", tdir_found_ptr));
        self.line(&format!("  store i32 {}, i32* {}", off_val, tdir_off_ptr));
        self.line(&format!("  br label %{}", tdir_next));

        self.open_block(&tdir_next);
        let ti_next = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", ti_next, ti));
        self.line(&format!("  store i32 {}, i32* {}", ti_next, tdir_i_ptr));
        self.line(&format!("  br label %{}", tdir_cond));

        self.open_block(&tdir_end);
        let tdir_found = self.tmp_name();
        self.line(&format!("  {} = load i1, i1* {}", tdir_found, tdir_found_ptr));
        let name_hdr_fail_label = self.block_label("ttf_name_hdr_fail");
        let name_hdr_ok_label = self.block_label("ttf_name_hdr_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", tdir_found, name_hdr_ok_label, name_hdr_fail_label));

        self.open_block(&name_hdr_fail_label);
        self.emit_ttf_load_fail_cleanup(&path_ptr, &buf);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&name_hdr_ok_label);
        let tdir_off = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", tdir_off, tdir_off_ptr));
        let hdr_end = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 6", hdr_end, tdir_off));
        let hdr_ok = self.tmp_name();
        self.line(&format!("  {} = icmp sle i32 {}, {}", hdr_ok, hdr_end, size0));
        let hdr_fail_label = self.block_label("ttf_hdr_fail");
        let hdr_ok_label = self.block_label("ttf_hdr_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", hdr_ok, hdr_ok_label, hdr_fail_label));

        self.open_block(&hdr_fail_label);
        self.emit_ttf_load_fail_cleanup(&path_ptr, &buf);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&hdr_ok_label);
        let name_table_start = self.gep8_dyn(&buf, &tdir_off);
        let count_ptr = self.gep8(&name_table_start, 2);
        let count = self.emit_read_u16be(&count_ptr);
        let stroff_ptr = self.gep8(&name_table_start, 4);
        let string_offset = self.emit_read_u16be(&stroff_ptr);

        let exact_found_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i1", exact_found_ptr));
        self.line(&format!("  store i1 false, i1* {}", exact_found_ptr));
        let exact_off_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", exact_off_ptr));
        self.line(&format!("  store i32 0, i32* {}", exact_off_ptr));
        let exact_len_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", exact_len_ptr));
        self.line(&format!("  store i32 0, i32* {}", exact_len_ptr));
        let fb_found_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i1", fb_found_ptr));
        self.line(&format!("  store i1 false, i1* {}", fb_found_ptr));
        let fb_off_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", fb_off_ptr));
        self.line(&format!("  store i32 0, i32* {}", fb_off_ptr));
        let fb_len_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", fb_len_ptr));
        self.line(&format!("  store i32 0, i32* {}", fb_len_ptr));
        let rec_i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", rec_i_ptr));
        self.line(&format!("  store i32 0, i32* {}", rec_i_ptr));

        let rec_cond = self.block_label("ttf_rec_cond");
        let rec_body = self.block_label("ttf_rec_body");
        let rec_exact = self.block_label("ttf_rec_exact");
        let rec_check_fb = self.block_label("ttf_rec_check_fb");
        let rec_fb = self.block_label("ttf_rec_fb");
        let rec_next = self.block_label("ttf_rec_next");
        let rec_end = self.block_label("ttf_rec_end");
        self.line(&format!("  br label %{}", rec_cond));

        self.open_block(&rec_cond);
        let ri = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", ri, rec_i_ptr));
        let ri_lt_n = self.tmp_name();
        self.line(&format!("  {} = icmp slt i32 {}, {}", ri_lt_n, ri, count));
        let rec_base_a = self.tmp_name();
        self.line(&format!("  {} = mul i32 {}, 12", rec_base_a, ri));
        let rec_base = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 6", rec_base, rec_base_a));
        let rec_end_off = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 12", rec_end_off, rec_base));
        let rec_abs_end = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, {}", rec_abs_end, tdir_off, rec_end_off));
        let rec_fits = self.tmp_name();
        self.line(&format!("  {} = icmp sle i32 {}, {}", rec_fits, rec_abs_end, size0));
        let rec_go = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", rec_go, ri_lt_n, rec_fits));
        self.line(&format!("  br i1 {}, label %{}, label %{}", rec_go, rec_body, rec_end));

        self.open_block(&rec_body);
        let rec_abs_off = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, {}", rec_abs_off, tdir_off, rec_base));
        let rec_ptr = self.gep8_dyn(&buf, &rec_abs_off);
        let platform = self.emit_read_u16be(&rec_ptr);
        let enc_ptr = self.gep8(&rec_ptr, 2);
        let encoding = self.emit_read_u16be(&enc_ptr);
        let lang_ptr = self.gep8(&rec_ptr, 4);
        let language = self.emit_read_u16be(&lang_ptr);
        let nameid_ptr = self.gep8(&rec_ptr, 6);
        let nameid = self.emit_read_u16be(&nameid_ptr);
        let reclen_ptr = self.gep8(&rec_ptr, 8);
        let reclen = self.emit_read_u16be(&reclen_ptr);
        let recoff_ptr = self.gep8(&rec_ptr, 10);
        let recoff = self.emit_read_u16be(&recoff_ptr);

        let p_eq3 = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 3", p_eq3, platform));
        let e_eq1 = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 1", e_eq1, encoding));
        let l_eq = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 1033", l_eq, language)); // 0x0409, en-US
        let n_eq1 = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 1", n_eq1, nameid));
        let a1 = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", a1, p_eq3, e_eq1));
        let a2 = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", a2, a1, l_eq));
        let is_exact = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", is_exact, a2, n_eq1));
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_exact, rec_exact, rec_check_fb));

        self.open_block(&rec_exact);
        self.line(&format!("  store i1 true, i1* {}", exact_found_ptr));
        self.line(&format!("  store i32 {}, i32* {}", recoff, exact_off_ptr));
        self.line(&format!("  store i32 {}, i32* {}", reclen, exact_len_ptr));
        self.line(&format!("  br label %{}", rec_next));

        self.open_block(&rec_check_fb);
        self.line(&format!("  br i1 {}, label %{}, label %{}", n_eq1, rec_fb, rec_next));

        self.open_block(&rec_fb);
        self.line(&format!("  store i1 true, i1* {}", fb_found_ptr));
        self.line(&format!("  store i32 {}, i32* {}", recoff, fb_off_ptr));
        self.line(&format!("  store i32 {}, i32* {}", reclen, fb_len_ptr));
        self.line(&format!("  br label %{}", rec_next));

        self.open_block(&rec_next);
        let ri_next = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", ri_next, ri));
        self.line(&format!("  store i32 {}, i32* {}", ri_next, rec_i_ptr));
        self.line(&format!("  br label %{}", rec_cond));

        self.open_block(&rec_end);
        let ef = self.tmp_name();
        self.line(&format!("  {} = load i1, i1* {}", ef, exact_found_ptr));
        let ff = self.tmp_name();
        self.line(&format!("  {} = load i1, i1* {}", ff, fb_found_ptr));
        let best_found = self.tmp_name();
        self.line(&format!("  {} = or i1 {}, {}", best_found, ef, ff));
        let eoff = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", eoff, exact_off_ptr));
        let elen = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", elen, exact_len_ptr));
        let foff = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", foff, fb_off_ptr));
        let flen = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", flen, fb_len_ptr));
        let chosen_off = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i32 {}, i32 {}", chosen_off, ef, eoff, foff));
        let chosen_len = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i32 {}, i32 {}", chosen_len, ef, elen, flen));

        let name_found_fail_label = self.block_label("ttf_name_found_fail");
        let name_found_ok_label = self.block_label("ttf_name_found_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", best_found, name_found_ok_label, name_found_fail_label));

        self.open_block(&name_found_fail_label);
        self.emit_ttf_load_fail_cleanup(&path_ptr, &buf);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&name_found_ok_label);
        let abs_off_a = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, {}", abs_off_a, tdir_off, string_offset));
        let abs_off = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, {}", abs_off, abs_off_a, chosen_off));
        let abs_end = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, {}", abs_end, abs_off, chosen_len));
        let off_ge0 = self.tmp_name();
        self.line(&format!("  {} = icmp sge i32 {}, 0", off_ge0, abs_off));
        let len_ge0 = self.tmp_name();
        self.line(&format!("  {} = icmp sge i32 {}, 0", len_ge0, chosen_len));
        let end_le_size = self.tmp_name();
        self.line(&format!("  {} = icmp sle i32 {}, {}", end_le_size, abs_end, size0));
        let b1 = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", b1, off_ge0, len_ge0));
        let str_ok = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", str_ok, b1, end_le_size));

        let str_fail_label = self.block_label("ttf_str_fail");
        let str_ok_label = self.block_label("ttf_str_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", str_ok, str_ok_label, str_fail_label));

        self.open_block(&str_fail_label);
        self.emit_ttf_load_fail_cleanup(&path_ptr, &buf);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&str_ok_label);
        let n_chars = self.tmp_name();
        self.line(&format!("  {} = sdiv i32 {}, 2", n_chars, chosen_len));
        let n_chars_plus1 = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", n_chars_plus1, n_chars));
        let face_len64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", face_len64, n_chars_plus1));
        let face_buf = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", face_buf, face_len64));

        let k_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", k_ptr));
        self.line(&format!("  store i32 0, i32* {}", k_ptr));
        let k_cond = self.block_label("ttf_copy_cond");
        let k_body = self.block_label("ttf_copy_body");
        let k_end = self.block_label("ttf_copy_end");
        self.line(&format!("  br label %{}", k_cond));

        self.open_block(&k_cond);
        let k = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", k, k_ptr));
        let k_more = self.tmp_name();
        self.line(&format!("  {} = icmp slt i32 {}, {}", k_more, k, n_chars));
        self.line(&format!("  br i1 {}, label %{}, label %{}", k_more, k_body, k_end));

        self.open_block(&k_body);
        let k2 = self.tmp_name();
        self.line(&format!("  {} = mul i32 {}, 2", k2, k));
        let src_off = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", src_off, k2));
        let src_off_abs = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, {}", src_off_abs, abs_off, src_off));
        let src_ptr = self.gep8_dyn(&buf, &src_off_abs);
        let b = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", b, src_ptr));
        let dst_ptr = self.gep8_dyn(&face_buf, &k);
        self.line(&format!("  store i8 {}, i8* {}", b, dst_ptr));
        let k_next = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", k_next, k));
        self.line(&format!("  store i32 {}, i32* {}", k_next, k_ptr));
        self.line(&format!("  br label %{}", k_cond));

        self.open_block(&k_end);
        let nul_ptr = self.gep8_dyn(&face_buf, &n_chars);
        self.line(&format!("  store i8 0, i8* {}", nul_ptr));

        self.line(&format!("  call void @free(i8* {})", buf));

        let hfont = self.tmp_name();
        self.line(&format!(
            "  {} = call i8* @CreateFontA(i32 {}, i32 0, i32 0, i32 0, i32 400, i32 0, i32 0, i32 0, i32 1, i32 4, i32 0, i32 4, i32 0, i8* {})",
            hfont, neg_size, face_buf
        ));
        self.line(&format!("  call void @free(i8* {})", face_buf));

        let hfont_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", hfont_null, hfont));
        let hfont_fail_label = self.block_label("ttf_hfont_fail");
        let hfont_ok_label = self.block_label("ttf_hfont_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", hfont_null, hfont_fail_label, hfont_ok_label));

        self.open_block(&hfont_fail_label);
        self.line(&format!("  call i32 @RemoveFontResourceExA(i8* {}, i32 {}, i8* null)", path_ptr, FR_PRIVATE));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&hfont_ok_label);
        let handle = self.emit_rasterize_font(&window, &hfont);
        self.line(&format!("  call i32 @RemoveFontResourceExA(i8* {}, i32 {}, i8* null)", path_ptr, FR_PRIVATE));
        self.line(&format!("  store i8* {}, i8** {}", handle, result_ptr));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        self.line(&format!("  call void @star_rc_release(i8* {})", path_ptr));
        let result = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", result, result_ptr));
        format!("i8* {}", result)
    }

    /// `font_ttf_free(font: ptr)`: destroys the atlas texture and frees the
    /// handle buffer. Nulls out the caller's own variable, if `arg` is a
    /// bare one -- same rationale as `crate::codegen::font::emit_font_free`.
    pub(super) fn emit_font_ttf_free(&mut self, args: &[TypedExpr]) {
        let Some(arg) = args.first() else {
            self.err("font_ttf_free(..) expects 1 argument", Span::dummy());
            return;
        };
        let val = self.emit_expr(arg);
        let font = self.untag(&val, &Ty::Ptr);
        self.abort_if_null_system_font(&font, "font_ttf_free");

        let tex_slot = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i8**", tex_slot, font));
        let tex = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", tex, tex_slot));
        self.line(&format!("  call void @SDL_DestroyTexture(i8* {})", tex));
        self.line(&format!("  call void @free(i8* {})", font));

        if let TypedExpr::Ident { .. } = arg {
            let place = self.emit_place(arg);
            self.line(&format!("  store i8* null, i8** {}", place));
        }
    }

    /// Load `(sdl_texture, line_height)` back out of a font handle.
    fn emit_read_system_font_header(&mut self, font: &str) -> (String, String) {
        let tex_slot = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i8**", tex_slot, font));
        let tex = self.tmp_name();
        self.line(&format!("  {} = load i8*, i8** {}", tex, tex_slot));
        let lineh_gep = self.gep8(font, LINEH_OFF);
        let lineh_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", lineh_ptr, lineh_gep));
        let line_height = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", line_height, lineh_ptr));
        (tex, line_height)
    }

    /// Look up glyph `codepoint`'s own `(x_offset, width)` in the atlas,
    /// falling back to glyph 0's (the space character's) width -- and an
    /// undrawn `x_offset` -- for any codepoint outside `FIRST_CHAR..=
    /// LAST_CHAR`, so an unsupported character still advances the cursor by
    /// a sensible amount instead of drifting. Returns `(in_range: i1,
    /// x_offset, width)`.
    fn emit_lookup_glyph(&mut self, font: &str, codepoint: &str) -> (String, String, String) {
        let idx = self.tmp_name();
        self.line(&format!("  {} = sub i32 {}, {}", idx, codepoint, FIRST_CHAR));
        let idx_ge0 = self.tmp_name();
        self.line(&format!("  {} = icmp sge i32 {}, 0", idx_ge0, idx));
        let idx_lt_n = self.tmp_name();
        self.line(&format!("  {} = icmp slt i32 {}, {}", idx_lt_n, idx, NUM_GLYPHS));
        let in_range = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", in_range, idx_ge0, idx_lt_n));

        let gx_arr = self.gep8(font, GLYPH_X_OFF);
        let gx_arr_i32 = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", gx_arr_i32, gx_arr));
        let gw_arr = self.gep8(font, GLYPH_W_OFF);
        let gw_arr_i32 = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", gw_arr_i32, gw_arr));

        let idx_safe = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i32 {}, i32 0", idx_safe, in_range, idx));
        let idx_safe64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", idx_safe64, idx_safe));
        let gx_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i32, i32* {}, i64 {}", gx_ptr, gx_arr_i32, idx_safe64));
        let gx_raw = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", gx_raw, gx_ptr));
        let gw_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i32, i32* {}, i64 {}", gw_ptr, gw_arr_i32, idx_safe64));
        let gw_raw = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", gw_raw, gw_ptr));

        (in_range, gx_raw, gw_raw)
    }

    /// `draw_text_ttf(window: ptr, font: ptr, text: str, x: int, y: int,
    /// color: Color32)`: blits `text` glyph-by-glyph via `SDL_RenderCopy`
    /// out of the font's own atlas texture, tinted with `color`
    /// (`SDL_SetTextureColorMod`/`SDL_SetTextureAlphaMod`, applied once up
    /// front -- every glyph this call draws shares one color). `\n` is a
    /// line break (reset `x`, advance `y` by the font's own line height --
    /// see this module's doc comment for why no extra gap is added, unlike
    /// `crate::codegen::font::emit_draw_text`). No lowercase folding: the
    /// atlas already has real, distinct lowercase glyph shapes.
    pub(super) fn emit_draw_text_ttf(&mut self, args: &[TypedExpr]) {
        if args.len() < 6 {
            self.err("draw_text_ttf(..) expects 6 arguments (window, font, text, x, y, color)", Span::dummy());
            return;
        }
        let wv = self.emit_expr(&args[0]);
        let window = self.untag(&wv, &Ty::Ptr);
        self.abort_if_null_window(&window, "draw_text_ttf");
        let fv = self.emit_expr(&args[1]);
        let font = self.untag(&fv, &Ty::Ptr);
        self.abort_if_null_system_font(&font, "draw_text_ttf");
        let renderer = self.emit_sdl_get_renderer(&window);
        let (tex, line_height) = self.emit_read_system_font_header(&font);
        let (r, g, b, a) = self.emit_color32_rgba8(&args[5]);
        self.line(&format!("  call i32 @SDL_SetTextureColorMod(i8* {}, i8 {}, i8 {}, i8 {})", tex, r, g, b));
        self.line(&format!("  call i32 @SDL_SetTextureAlphaMod(i8* {}, i8 {})", tex, a));

        let text_ptr = self.emit_raw_str_ptr(&args[2]);
        let x0v = self.emit_expr(&args[3]);
        let x0 = self.untag(&x0v, &Ty::Int);
        let y0v = self.emit_expr(&args[4]);
        let y0 = self.untag(&y0v, &Ty::Int);

        let cx_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", cx_ptr));
        self.line(&format!("  store i32 {}, i32* {}", x0, cx_ptr));
        let cy_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", cy_ptr));
        self.line(&format!("  store i32 {}, i32* {}", y0, cy_ptr));
        let i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", i_ptr));
        self.line(&format!("  store i64 0, i64* {}", i_ptr));

        let cond_label = self.block_label("draw_ttf_cond");
        let body_label = self.block_label("draw_ttf_body");
        let newline_label = self.block_label("draw_ttf_newline");
        let glyph_label = self.block_label("draw_ttf_glyph");
        let draw_label = self.block_label("draw_ttf_draw");
        let after_label = self.block_label("draw_ttf_after");
        let end_label = self.block_label("draw_ttf_end");

        self.line(&format!("  br label %{}", cond_label));
        self.open_block(&cond_label);
        let i_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
        let c_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", c_ptr, text_ptr, i_reg));
        let c8 = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", c8, c_ptr));
        let is_end = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8 {}, 0", is_end, c8));
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_end, end_label, body_label));

        self.open_block(&body_label);
        let c32 = self.tmp_name();
        self.line(&format!("  {} = zext i8 {} to i32", c32, c8));
        let is_nl = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 10", is_nl, c32));
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_nl, newline_label, glyph_label));

        self.open_block(&newline_label);
        self.line(&format!("  store i32 {}, i32* {}", x0, cx_ptr));
        let cy_cur = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", cy_cur, cy_ptr));
        let cy_next = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, {}", cy_next, cy_cur, line_height));
        self.line(&format!("  store i32 {}, i32* {}", cy_next, cy_ptr));
        let i_next_nl = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", i_next_nl, i_reg));
        self.line(&format!("  store i64 {}, i64* {}", i_next_nl, i_ptr));
        self.line(&format!("  br label %{}", cond_label));

        self.open_block(&glyph_label);
        let (in_range, gx, gw) = self.emit_lookup_glyph(&font, &c32);
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_range, draw_label, after_label));

        self.open_block(&draw_label);
        let cx0 = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", cx0, cx_ptr));
        let cy0 = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", cy0, cy_ptr));
        let src_rect = self.emit_build_rect(&gx, "0", &gw, &line_height);
        let dst_rect = self.emit_build_rect(&cx0, &cy0, &gw, &line_height);
        self.line(&format!("  call i32 @SDL_RenderCopy(i8* {}, i8* {}, i8* {}, i8* {})", renderer, tex, src_rect, dst_rect));
        self.line(&format!("  br label %{}", after_label));

        self.open_block(&after_label);
        let advance = self.tmp_name();
        self.line(&format!("  {} = phi i32 [ {}, %{} ], [ {}, %{} ]", advance, gw, draw_label, gw, glyph_label));
        let cx_cur = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", cx_cur, cx_ptr));
        let cx_next = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, {}", cx_next, cx_cur, advance));
        self.line(&format!("  store i32 {}, i32* {}", cx_next, cx_ptr));
        let i_next = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
        self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
        self.line(&format!("  br label %{}", cond_label));

        self.open_block(&end_label);
        self.line(&format!("  call void @star_rc_release(i8* {})", text_ptr));
    }

    /// `measure_text_ttf(font: ptr, text: str) -> (int, int)`: the `(width,
    /// height)` in pixels `draw_text_ttf` would occupy drawing `text` with
    /// `font`, without drawing anything -- shares its character-walking/
    /// glyph-lookup/`\n`-handling logic with `emit_draw_text_ttf` via
    /// `emit_read_system_font_header`/`emit_lookup_glyph` so the two can
    /// never silently disagree about where a character lands.
    pub(super) fn emit_measure_text_ttf(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("measure_text_ttf(..) expects 2 arguments (font, text)", Span::dummy());
            return "{ i32, i32 } zeroinitializer".into();
        }
        let fv = self.emit_expr(&args[0]);
        let font = self.untag(&fv, &Ty::Ptr);
        self.abort_if_null_system_font(&font, "measure_text_ttf");
        let (_tex, line_height) = self.emit_read_system_font_header(&font);
        let text_ptr = self.emit_raw_str_ptr(&args[1]);

        let cur_w_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", cur_w_ptr));
        self.line(&format!("  store i32 0, i32* {}", cur_w_ptr));
        let max_w_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", max_w_ptr));
        self.line(&format!("  store i32 0, i32* {}", max_w_ptr));
        let line_count_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", line_count_ptr));
        self.line(&format!("  store i32 1, i32* {}", line_count_ptr));
        let i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", i_ptr));
        self.line(&format!("  store i64 0, i64* {}", i_ptr));

        let cond_label = self.block_label("measure_ttf_cond");
        let body_label = self.block_label("measure_ttf_body");
        let newline_label = self.block_label("measure_ttf_newline");
        let advance_label = self.block_label("measure_ttf_advance");
        let end_label = self.block_label("measure_ttf_end");

        self.line(&format!("  br label %{}", cond_label));
        self.open_block(&cond_label);
        let i_reg = self.tmp_name();
        self.line(&format!("  {} = load i64, i64* {}", i_reg, i_ptr));
        let c_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", c_ptr, text_ptr, i_reg));
        let c8 = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", c8, c_ptr));
        let is_end = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8 {}, 0", is_end, c8));
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_end, end_label, body_label));

        self.open_block(&body_label);
        let c32 = self.tmp_name();
        self.line(&format!("  {} = zext i8 {} to i32", c32, c8));
        let is_nl = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 10", is_nl, c32));
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_nl, newline_label, advance_label));

        self.open_block(&newline_label);
        let cw1 = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", cw1, cur_w_ptr));
        let mw1 = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", mw1, max_w_ptr));
        let gt1 = self.tmp_name();
        self.line(&format!("  {} = icmp sgt i32 {}, {}", gt1, cw1, mw1));
        let newmax1 = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i32 {}, i32 {}", newmax1, gt1, cw1, mw1));
        self.line(&format!("  store i32 {}, i32* {}", newmax1, max_w_ptr));
        self.line(&format!("  store i32 0, i32* {}", cur_w_ptr));
        let lc1 = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", lc1, line_count_ptr));
        let lc2 = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", lc2, lc1));
        self.line(&format!("  store i32 {}, i32* {}", lc2, line_count_ptr));
        let i_next_nl = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", i_next_nl, i_reg));
        self.line(&format!("  store i64 {}, i64* {}", i_next_nl, i_ptr));
        self.line(&format!("  br label %{}", cond_label));

        self.open_block(&advance_label);
        let (_in_range, _gx, gw) = self.emit_lookup_glyph(&font, &c32);
        let cw2 = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", cw2, cur_w_ptr));
        let cw3 = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, {}", cw3, cw2, gw));
        self.line(&format!("  store i32 {}, i32* {}", cw3, cur_w_ptr));
        let i_next = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", i_next, i_reg));
        self.line(&format!("  store i64 {}, i64* {}", i_next, i_ptr));
        self.line(&format!("  br label %{}", cond_label));

        self.open_block(&end_label);
        self.line(&format!("  call void @star_rc_release(i8* {})", text_ptr));
        let cw_final = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", cw_final, cur_w_ptr));
        let mw_final = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", mw_final, max_w_ptr));
        let gt_final = self.tmp_name();
        self.line(&format!("  {} = icmp sgt i32 {}, {}", gt_final, cw_final, mw_final));
        let final_w = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i32 {}, i32 {}", final_w, gt_final, cw_final, mw_final));
        let lc_final = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", lc_final, line_count_ptr));
        let total_h = self.tmp_name();
        self.line(&format!("  {} = mul i32 {}, {}", total_h, lc_final, line_height));

        let tuple_ty = "{ i32, i32 }";
        let tuple_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca {}", tuple_ptr, tuple_ty));
        let w_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 0", w_gep, tuple_ty, tuple_ty, tuple_ptr));
        self.line(&format!("  store i32 {}, i32* {}", final_w, w_gep));
        let h_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds {}, {}* {}, i32 0, i32 1", h_gep, tuple_ty, tuple_ty, tuple_ptr));
        self.line(&format!("  store i32 {}, i32* {}", total_h, h_gep));
        let loaded = self.tmp_name();
        self.line(&format!("  {} = load {}, {}* {}", loaded, tuple_ty, tuple_ty, tuple_ptr));
        format!("{} {}", tuple_ty, loaded)
    }
}

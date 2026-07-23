//! Text rendering and font-loading builtins (`draw_text`/`measure_text`/
//! `font_load`/`font_free`/`default_font`, plus `get_pixel` for reading a
//! framebuffer pixel back) -- closes the gap `projects/snake/NOTES.md`
//! section 4 flagged: SDL2 itself (vendored under `sdl/`) has no bundled
//! text renderer (that's `SDL_ttf`, a separate library this repo doesn't
//! vendor), so `window_create`/`draw_pixel`/`draw_rect`/`draw_line`/
//! `present` (`crate::codegen::sdl`) was the *entire* drawing surface --
//! no way to put a score/HUD/message in the game window itself, only the
//! console. Rather than vendor `SDL_ttf` (a second binary DLL dependency,
//! plus its own transitive `libfreetype` dependency), this is a small,
//! from-scratch bitmap-font renderer built directly on the existing
//! `draw_rect`-style `SDL_RenderFillRect` primitive (`sdl.rs`'s
//! `emit_fill_rect`, extracted from `emit_draw_rect` specifically so this
//! module could reuse it).
//!
//! ## Font data format
//! A "font" is a flat byte buffer laid out as `[width: u8][height: u8]
//! [first_char: u8][num_chars: u8]` followed by `num_chars * height` bytes,
//! one byte per glyph row (bit `width-1-col` is set for a lit pixel at
//! column `col`, so a row byte's bit pattern reads the same left-to-right
//! as the glyph itself; `width` must be `1..=8` so one row always fits in
//! one byte). Glyph `i` (`i` in `0..num_chars`) occupies bytes
//! `[4 + i*height .. 4 + (i+1)*height)` and represents character
//! `first_char + i`. `Ty::Ptr` is reused as the font handle -- the same
//! "opaque foreign pointer, no RC header" shape `crate::codegen::sdl`
//! already established for `SDL_Window*` (see that module's own doc
//! comment).
//!
//! `default_font()` returns a pointer into a compiled-in constant (a fixed
//! 5x7 monospace font covering space, common punctuation, digits, and
//! uppercase letters -- `default_font_bytes`/`GLYPHS` below; any other
//! character in the font's own declared range renders as a blank,
//! same-width glyph). It is **never** valid to pass a `default_font()`
//! handle to `font_free` -- there is nothing to free, and doing so hands
//! `free()` a pointer it never allocated. `font_load(path)` reads a file in
//! exactly the format above into a fresh `malloc`'d buffer, validating the
//! header against the file's actual size before handing back a handle
//! (`null` on any failure: missing file, truncated/corrupt header, or a
//! `width` outside `1..=8`); free it with `font_free`, which is plain
//! `free()` under the hood -- **not** `star_rc_release`, since this handle
//! carries no RC header.
//!
//! `draw_text`/`measure_text` fold lowercase `a`-`z` to their uppercase
//! codepoint before glyph lookup (so a custom font only needs to define the
//! uppercase range to support both cases -- the built-in default font relies
//! on exactly this), and treat `\n` as a line break (reset the cursor's `x`
//! back to its starting column, advance `y` by one line height). Any
//! character outside `[first_char, first_char+num_chars)` after folding --
//! including one from a custom font loaded with a narrower range -- draws
//! as blank space, still advancing the cursor by one glyph cell exactly
//! like a defined-but-blank glyph, so text after an unsupported character
//! stays aligned instead of drifting.
//!
//! `get_pixel(window, x, y) -> Color32` reads a single pixel back from the
//! window's current (already-drawn, not-yet-presented) framebuffer via
//! `SDL_RenderReadPixels`, requesting `SDL_PIXELFORMAT_RGBA32` (numeric
//! value `376840196` -- `SDL_PIXELFORMAT_ABGR8888` on this little-endian
//! target, which is exactly what `SDL_PIXELFORMAT_RGBA32` aliases to; its
//! defining property is memory byte order R,G,B,A regardless of the
//! renderer's own internal format) so the 4 bytes read back, loaded as one
//! little-endian `i32`, land in exactly `Color32`'s own packed
//! `r | g<<8 | b<<16 | a<<24` layout with no repacking needed. This is the
//! only way any test (or any Star program) can observe what a drawing
//! builtin actually drew -- every other SDL drawing builtin here is
//! write-only.

use crate::diagnostics::Span;
use crate::types::*;

use super::Codegen;

/// Cell width (pixels) of every glyph in the built-in default font. Must be
/// `1..=8` -- one glyph row is packed into a single byte.
const FONT_WIDTH: u8 = 5;
/// Cell height (pixels, i.e. rows) of every glyph in the built-in default
/// font.
const FONT_HEIGHT: u8 = 7;
/// First codepoint the built-in default font covers (`' '`, space).
const FONT_FIRST_CHAR: u8 = 32;
/// Last codepoint the built-in default font covers (`'Z'`) -- chosen so the
/// covered range is exactly `[' ', 'Z']`, a contiguous 59-codepoint span
/// that includes every ASCII digit, uppercase letter, and a useful subset
/// of punctuation. Not every codepoint in this range has a hand-authored
/// glyph in `GLYPHS` below -- one not listed there renders blank.
const FONT_LAST_CHAR: u8 = 90;
/// `FONT_LAST_CHAR - FONT_FIRST_CHAR + 1`.
const FONT_NUM_CHARS: u8 = FONT_LAST_CHAR - FONT_FIRST_CHAR + 1;

/// One entry per hand-authored glyph in the built-in default font: the
/// ASCII character, and its 7 rows (5 characters each, `#` = lit pixel,
/// `.` = blank, read left-to-right matching `FONT_WIDTH`'s column order).
/// Deliberately a small subset (space, a handful of punctuation marks,
/// digits, uppercase letters) rather than full ASCII -- sized for
/// HUD/score/message text, not general typesetting. Any character in
/// `FONT_FIRST_CHAR..=FONT_LAST_CHAR` not listed here (`"` `#` `$` `%` `&`
/// `*` `+` `<` `=` `>` `@`, among others) renders as an all-blank glyph:
/// same cell width, no visible pixels.
const GLYPHS: &[(char, [&str; 7])] = &[
    ('0', [".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###."]),
    ('1', ["..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###."]),
    ('2', [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"]),
    ('3', [".###.", "#...#", "....#", "..##.", "....#", "#...#", ".###."]),
    ('4', ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."]),
    ('5', ["#####", "#....", "####.", "....#", "....#", "#...#", ".###."]),
    ('6', ["..##.", ".#...", "#....", "####.", "#...#", "#...#", ".###."]),
    ('7', ["#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..."]),
    ('8', [".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###."]),
    ('9', [".###.", "#...#", "#...#", ".####", "....#", "...#.", ".##.."]),
    ('A', ["..#..", ".#.#.", "#...#", "#...#", "#####", "#...#", "#...#"]),
    ('B', ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."]),
    ('C', [".###.", "#...#", "#....", "#....", "#....", "#...#", ".###."]),
    ('D', ["###..", "#..#.", "#...#", "#...#", "#...#", "#..#.", "###.."]),
    ('E', ["#####", "#....", "#....", "####.", "#....", "#....", "#####"]),
    ('F', ["#####", "#....", "#....", "####.", "#....", "#....", "#...."]),
    ('G', [".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".###."]),
    ('H', ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"]),
    ('I', [".###.", "..#..", "..#..", "..#..", "..#..", "..#..", ".###."]),
    ('J', ["..###", "...#.", "...#.", "...#.", "...#.", "#..#.", ".##.."]),
    ('K', ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"]),
    ('L', ["#....", "#....", "#....", "#....", "#....", "#....", "#####"]),
    ('M', ["#...#", "##.##", "#.#.#", "#...#", "#...#", "#...#", "#...#"]),
    ('N', ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"]),
    ('O', [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."]),
    ('P', ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."]),
    ('Q', [".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#"]),
    ('R', ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"]),
    ('S', [".####", "#....", "#....", ".###.", "....#", "....#", "####."]),
    ('T', ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."]),
    ('U', ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."]),
    ('V', ["#...#", "#...#", "#...#", "#...#", "#...#", ".#.#.", "..#.."]),
    ('W', ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"]),
    ('X', ["#...#", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#...#"]),
    ('Y', ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."]),
    ('Z', ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"]),
    ('!', ["..#..", "..#..", "..#..", "..#..", "..#..", ".....", "..#.."]),
    ('\'', ["..#..", "..#..", ".....", ".....", ".....", ".....", "....."]),
    ('(', ["...#.", "..#..", ".#...", ".#...", ".#...", "..#..", "...#."]),
    (')', [".#...", "..#..", "...#.", "...#.", "...#.", "..#..", ".#..."]),
    (',', [".....", ".....", ".....", ".....", ".....", "..#..", ".#..."]),
    ('-', [".....", ".....", ".....", "#####", ".....", ".....", "....."]),
    ('.', [".....", ".....", ".....", ".....", ".....", "..#..", "..#.."]),
    ('/', ["....#", "...#.", "..#..", "..#..", ".#...", "#....", "#...."]),
    (':', [".....", "..#..", ".....", ".....", "..#..", ".....", "....."]),
    (';', [".....", "..#..", ".....", ".....", "..#..", ".#...", "....."]),
    ('?', [".###.", "#...#", "....#", "...#.", "..#..", ".....", "..#.."]),
];

/// Pack one glyph row's ASCII-art (`#`/`.`) into a byte -- bit
/// `FONT_WIDTH-1-col` set for a `#` at column `col`, so the byte's bit
/// pattern reads left-to-right the same way the ASCII art does.
fn glyph_row_bits(row: &str) -> u8 {
    let mut bits = 0u8;
    for (col, ch) in row.chars().enumerate() {
        if ch == '#' {
            bits |= 1 << (FONT_WIDTH as usize - 1 - col);
        }
    }
    bits
}

/// Build the built-in default font's byte table -- header
/// (`width`/`height`/`first_char`/`num_chars`) followed by every codepoint
/// in `FONT_FIRST_CHAR..=FONT_LAST_CHAR`'s glyph rows in order (a codepoint
/// missing from `GLYPHS` gets all-zero rows, i.e. a blank glyph).
fn default_font_bytes() -> Vec<u8> {
    let num_chars = FONT_NUM_CHARS as usize;
    let height = FONT_HEIGHT as usize;
    let mut rows = vec![vec![0u8; height]; num_chars];
    for (ch, glyph_rows) in GLYPHS {
        let idx = (*ch as u8 - FONT_FIRST_CHAR) as usize;
        for (r, row) in glyph_rows.iter().enumerate() {
            rows[idx][r] = glyph_row_bits(row);
        }
    }
    let mut out = Vec::with_capacity(4 + num_chars * height);
    out.push(FONT_WIDTH);
    out.push(FONT_HEIGHT);
    out.push(FONT_FIRST_CHAR);
    out.push(FONT_NUM_CHARS);
    for row_set in rows {
        out.extend_from_slice(&row_set);
    }
    out
}

/// Hex-escape every byte (`\XX`) for an LLVM `c"..."` string constant --
/// unlike the `msg.replace("\\", ...).replace("\"", ...).replace("\n", ...)`
/// convention every error-message global elsewhere in this codegen uses
/// (safe there because those are short, hand-written ASCII messages with no
/// other control bytes), this constant's payload is genuinely arbitrary
/// binary data, including embedded `NUL`s (a blank glyph row is `0x00`) --
/// escaping unconditionally is the only encoding that's correct for every
/// possible byte value rather than just the handful `.replace()` chains
/// happen to cover.
fn escape_llvm_bytes(bytes: &[u8]) -> String {
    let mut s = String::with_capacity(bytes.len() * 4);
    for &b in bytes {
        s.push_str(&format!("\\{:02X}", b));
    }
    s
}

impl Codegen {
    /// Abort (matches `crate::codegen::sdl`'s `abort_if_null_window`/
    /// `crate::codegen::file_io`'s `abort_if_null_handle` shape exactly,
    /// with font-specific wording) if `handle` is a null `ptr`. Used by
    /// every builtin here except `font_load`/`default_font`, which have no
    /// handle to misuse yet.
    fn abort_if_null_font(&mut self, handle: &str, builtin_name: &str) {
        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, handle));
        let fail_label = self.block_label("font_null_handle");
        let ok_label = self.block_label("font_handle_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, fail_label, ok_label));

        self.open_block(&fail_label);
        let msg = format!("star runtime error: {}(..) called with a null/closed font handle\n", builtin_name);
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

    /// `default_font() -> ptr`: a pointer to the compiled-in default font's
    /// constant byte table (`default_font_bytes`), emitted once per program
    /// and memoized in `self.default_font_global` -- a program calling
    /// `default_font()` more than once (typically every frame, to pass into
    /// `draw_text`) gets a pointer to the same global each call, not a fresh
    /// duplicate constant per call site.
    pub(super) fn emit_default_font(&mut self) -> String {
        let (g, n) = if let Some((g, n)) = self.default_font_global.clone() {
            (g, n)
        } else {
            let bytes = default_font_bytes();
            let n = bytes.len() as u64;
            let g = self.global_name();
            let escaped = escape_llvm_bytes(&bytes);
            self.global_defs.push(format!("{} = private unnamed_addr constant [{} x i8] c\"{}\"", g, n, escaped));
            self.default_font_global = Some((g.clone(), n));
            (g, n)
        };
        let ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [{} x i8], [{} x i8]* {}, i64 0, i64 0", ptr, n, n, g));
        format!("i8* {}", ptr)
    }

    /// `font_load(path: str) -> ptr`: reads a file in this module's own
    /// doc-commented font format into a fresh `malloc`'d buffer -- `fopen`
    /// in binary mode, `fseek`/`ftell` to size the file (mirroring
    /// `crate::codegen::file_io::emit_file_read`'s own size-up-front
    /// approach), one `malloc`+`fread` of the whole file, then validates
    /// the header (`width` in `1..=8`, and the file's actual size matching
    /// `4 + num_chars*height` exactly) before handing back the buffer --
    /// `null` on any failure (missing file, truncated/corrupt header, or an
    /// out-of-range `width`), same convention as `file_open`/
    /// `window_create`, checked with `is_null`.
    pub(super) fn emit_font_load(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("font_load(..) expects 1 argument (path)", Span::dummy());
            return "i8* null".into();
        };
        let path = self.emit_raw_str_ptr(arg);
        let mode_g = self.global_name();
        self.global_defs.push(format!("{} = private unnamed_addr constant [3 x i8] c\"rb\\00\"", mode_g));
        let mode_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [3 x i8], [3 x i8]* {}, i64 0, i64 0", mode_ptr, mode_g));
        let handle = self.tmp_name();
        self.line(&format!("  {} = call i8* @fopen(i8* {}, i8* {})", handle, path, mode_ptr));
        self.line(&format!("  call void @star_rc_release(i8* {})", path));

        let open_failed = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", open_failed, handle));
        let open_fail_label = self.block_label("font_load_open_fail");
        let open_ok_label = self.block_label("font_load_open_ok");
        let end_label = self.block_label("font_load_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", open_failed, open_fail_label, open_ok_label));

        self.open_block(&open_fail_label);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&open_ok_label);
        self.line(&format!("  call i32 @fseek(i8* {}, i32 0, i32 2)", handle));
        let size = self.tmp_name();
        self.line(&format!("  {} = call i32 @ftell(i8* {})", size, handle));
        self.line(&format!("  call i32 @fseek(i8* {}, i32 0, i32 0)", handle));

        let size_ok = self.tmp_name();
        self.line(&format!("  {} = icmp sge i32 {}, 4", size_ok, size));
        let too_small_label = self.block_label("font_load_too_small");
        let read_label = self.block_label("font_load_read");
        self.line(&format!("  br i1 {}, label %{}, label %{}", size_ok, read_label, too_small_label));

        self.open_block(&too_small_label);
        self.line(&format!("  call i32 @fclose(i8* {})", handle));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&read_label);
        let size64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", size64, size));
        let buf = self.tmp_name();
        self.line(&format!("  {} = call i8* @malloc(i64 {})", buf, size64));
        self.line(&format!("  call i64 @fread(i8* {}, i64 1, i64 {}, i8* {})", buf, size64, handle));
        self.line(&format!("  call i32 @fclose(i8* {})", handle));

        let w_byte = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", w_byte, buf));
        let width = self.tmp_name();
        self.line(&format!("  {} = zext i8 {} to i32", width, w_byte));
        let h_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 1", h_gep, buf));
        let h_byte = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", h_byte, h_gep));
        let height = self.tmp_name();
        self.line(&format!("  {} = zext i8 {} to i32", height, h_byte));
        let nc_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 3", nc_gep, buf));
        let nc_byte = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", nc_byte, nc_gep));
        let num_chars = self.tmp_name();
        self.line(&format!("  {} = zext i8 {} to i32", num_chars, nc_byte));

        let glyph_bytes = self.tmp_name();
        self.line(&format!("  {} = mul i32 {}, {}", glyph_bytes, num_chars, height));
        let expected = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 4", expected, glyph_bytes));
        let size_matches = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, {}", size_matches, expected, size));
        let width_ge1 = self.tmp_name();
        self.line(&format!("  {} = icmp sge i32 {}, 1", width_ge1, width));
        let width_le8 = self.tmp_name();
        self.line(&format!("  {} = icmp sle i32 {}, 8", width_le8, width));
        let width_ok = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", width_ok, width_ge1, width_le8));
        let header_ok = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", header_ok, size_matches, width_ok));

        let bad_header_label = self.block_label("font_load_bad_header");
        let good_label = self.block_label("font_load_good");
        self.line(&format!("  br i1 {}, label %{}, label %{}", header_ok, good_label, bad_header_label));

        self.open_block(&bad_header_label);
        self.line(&format!("  call void @free(i8* {})", buf));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&good_label);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let result = self.tmp_name();
        self.line(&format!(
            "  {} = phi i8* [ null, %{} ], [ null, %{} ], [ null, %{} ], [ {}, %{} ]",
            result, open_fail_label, too_small_label, bad_header_label, buf, good_label
        ));
        format!("i8* {}", result)
    }

    /// `font_free(font: ptr)`: `free()` -- **not** `star_rc_release`, since
    /// a font handle carries no RC header (see this module's own doc
    /// comment). Must never be called on a `default_font()` handle (a
    /// pointer into a compiled-in constant, never `malloc`'d).
    pub(super) fn emit_font_free(&mut self, args: &[TypedExpr]) {
        let Some(arg) = args.first() else {
            self.err("font_free(..) expects 1 argument", Span::dummy());
            return;
        };
        let val = self.emit_expr(arg);
        let font = self.untag(&val, &Ty::Ptr);
        self.abort_if_null_font(&font, "font_free");
        self.line(&format!("  call void @free(i8* {})", font));
        // Null out the caller's own variable, if `arg` is a bare one --
        // same fix, same rationale, as `file_io.rs`'s `emit_file_close`/
        // `sdl.rs`'s `emit_window_destroy` (see either's doc comment).
        if let TypedExpr::Ident { .. } = arg {
            let place = self.emit_place(arg);
            self.line(&format!("  store i8* null, i8** {}", place));
        }
    }

    /// Read a font handle's 4-byte header into `(width, height, first_char,
    /// num_chars)`, each already `zext`ed to `i32`. Shared by
    /// `emit_draw_text`/`emit_measure_text` so the two can never disagree
    /// about how to interpret the same handle.
    fn emit_read_font_header(&mut self, font: &str) -> (String, String, String, String) {
        let w_byte = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", w_byte, font));
        let width = self.tmp_name();
        self.line(&format!("  {} = zext i8 {} to i32", width, w_byte));

        let h_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 1", h_gep, font));
        let h_byte = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", h_byte, h_gep));
        let height = self.tmp_name();
        self.line(&format!("  {} = zext i8 {} to i32", height, h_byte));

        let fc_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 2", fc_gep, font));
        let fc_byte = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", fc_byte, fc_gep));
        let first_char = self.tmp_name();
        self.line(&format!("  {} = zext i8 {} to i32", first_char, fc_byte));

        let nc_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 3", nc_gep, font));
        let nc_byte = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", nc_byte, nc_gep));
        let num_chars = self.tmp_name();
        self.line(&format!("  {} = zext i8 {} to i32", num_chars, nc_byte));

        (width, height, first_char, num_chars)
    }

    /// Clamp a caller-supplied `scale` argument to `>= 1` -- a `0` or
    /// negative scale would otherwise produce a zero/negative-size fill
    /// rect (harmless, SDL treats it as empty) but also a zero cursor
    /// advance per character, which would draw every glyph stacked directly
    /// on top of the last instead of failing loudly or safely; clamping to
    /// `1` matches this codegen's "safe, not undefined" convention
    /// `crate::codegen::sdl::emit_delay` already uses for a negative `ms`.
    fn emit_clamp_scale(&mut self, scale: &str) -> String {
        let is_pos = self.tmp_name();
        self.line(&format!("  {} = icmp sgt i32 {}, 0", is_pos, scale));
        let clamped = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i32 {}, i32 1", clamped, is_pos, scale));
        clamped
    }

    /// Fold lowercase `a`-`z` (97-122) to its uppercase codepoint (97-122
    /// minus 32 == 65-90) -- see this module's own doc comment for why.
    /// Every other codepoint passes through unchanged.
    fn emit_fold_lowercase(&mut self, c: &str) -> String {
        let ge_a = self.tmp_name();
        self.line(&format!("  {} = icmp sge i32 {}, 97", ge_a, c));
        let le_z = self.tmp_name();
        self.line(&format!("  {} = icmp sle i32 {}, 122", le_z, c));
        let is_lower = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", is_lower, ge_a, le_z));
        let folded = self.tmp_name();
        self.line(&format!("  {} = sub i32 {}, 32", folded, c));
        let result = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i32 {}, i32 {}", result, is_lower, folded, c));
        result
    }

    /// `draw_text(window: ptr, font: ptr, text: str, x: int, y: int, scale:
    /// int, color: Color32)`: blits `text` glyph-by-glyph (a filled
    /// `scale`x`scale` rect -- `sdl.rs`'s `emit_fill_rect` -- per lit font
    /// pixel) starting at `(x, y)`, in `color`. See this module's own doc
    /// comment for the lowercase-folding/`\n`-line-break/unsupported-
    /// character behavior, shared byte-for-byte with `measure_text` via
    /// `emit_read_font_header`/`emit_clamp_scale`/`emit_fold_lowercase`.
    pub(super) fn emit_draw_text(&mut self, args: &[TypedExpr]) {
        if args.len() < 7 {
            self.err("draw_text(..) expects 7 arguments (window, font, text, x, y, scale, color)", Span::dummy());
            return;
        }
        let wv = self.emit_expr(&args[0]);
        let window = self.untag(&wv, &Ty::Ptr);
        self.abort_if_null_window(&window, "draw_text");
        let fv = self.emit_expr(&args[1]);
        let font = self.untag(&fv, &Ty::Ptr);
        self.abort_if_null_font(&font, "draw_text");
        let renderer = self.emit_sdl_get_renderer(&window);
        self.emit_set_render_draw_color(&renderer, &args[6]);

        let text_ptr = self.emit_raw_str_ptr(&args[2]);
        let x0v = self.emit_expr(&args[3]);
        let x0 = self.untag(&x0v, &Ty::Int);
        let y0v = self.emit_expr(&args[4]);
        let y0 = self.untag(&y0v, &Ty::Int);
        let scalev = self.emit_expr(&args[5]);
        let scale_raw = self.untag(&scalev, &Ty::Int);
        let scale = self.emit_clamp_scale(&scale_raw);

        let (width, height, first_char, num_chars) = self.emit_read_font_header(&font);

        let advance_w = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", advance_w, width));
        let advance = self.tmp_name();
        self.line(&format!("  {} = mul i32 {}, {}", advance, advance_w, scale));
        let line_h_raw = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", line_h_raw, height));
        let line_h = self.tmp_name();
        self.line(&format!("  {} = mul i32 {}, {}", line_h, line_h_raw, scale));

        let cx_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", cx_ptr));
        self.line(&format!("  store i32 {}, i32* {}", x0, cx_ptr));
        let cy_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", cy_ptr));
        self.line(&format!("  store i32 {}, i32* {}", y0, cy_ptr));
        let i_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i64", i_ptr));
        self.line(&format!("  store i64 0, i64* {}", i_ptr));

        let cond_label = self.block_label("draw_text_cond");
        let body_label = self.block_label("draw_text_body");
        let newline_label = self.block_label("draw_text_newline");
        let glyph_label = self.block_label("draw_text_glyph");
        let draw_glyph_label = self.block_label("draw_text_draw_glyph");
        let advance_label = self.block_label("draw_text_advance");
        let end_label = self.block_label("draw_text_end");

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
        self.line(&format!("  {} = add i32 {}, {}", cy_next, cy_cur, line_h));
        self.line(&format!("  store i32 {}, i32* {}", cy_next, cy_ptr));
        let i_next_nl = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, 1", i_next_nl, i_reg));
        self.line(&format!("  store i64 {}, i64* {}", i_next_nl, i_ptr));
        self.line(&format!("  br label %{}", cond_label));

        self.open_block(&glyph_label);
        let folded = self.emit_fold_lowercase(&c32);
        let glyph_idx = self.tmp_name();
        self.line(&format!("  {} = sub i32 {}, {}", glyph_idx, folded, first_char));
        let idx_ge0 = self.tmp_name();
        self.line(&format!("  {} = icmp sge i32 {}, 0", idx_ge0, glyph_idx));
        let idx_lt_n = self.tmp_name();
        self.line(&format!("  {} = icmp slt i32 {}, {}", idx_lt_n, glyph_idx, num_chars));
        let in_range = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", in_range, idx_ge0, idx_lt_n));
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_range, draw_glyph_label, advance_label));

        self.open_block(&draw_glyph_label);
        let goff_cells = self.tmp_name();
        self.line(&format!("  {} = mul i32 {}, {}", goff_cells, glyph_idx, height));
        let goff = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 4", goff, goff_cells));
        let goff64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", goff64, goff));
        let cx0 = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", cx0, cx_ptr));
        let cy0 = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", cy0, cy_ptr));

        let row_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", row_ptr));
        self.line(&format!("  store i32 0, i32* {}", row_ptr));
        let row_cond = self.block_label("draw_text_row_cond");
        let row_body = self.block_label("draw_text_row_body");
        let row_end = self.block_label("draw_text_row_end");
        self.line(&format!("  br label %{}", row_cond));

        self.open_block(&row_cond);
        let row = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", row, row_ptr));
        let row_more = self.tmp_name();
        self.line(&format!("  {} = icmp slt i32 {}, {}", row_more, row, height));
        self.line(&format!("  br i1 {}, label %{}, label %{}", row_more, row_body, row_end));

        self.open_block(&row_body);
        let row64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", row64, row));
        let row_off = self.tmp_name();
        self.line(&format!("  {} = add i64 {}, {}", row_off, goff64, row64));
        let row_byte_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", row_byte_ptr, font, row_off));
        let row_byte8 = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", row_byte8, row_byte_ptr));
        let row_byte = self.tmp_name();
        self.line(&format!("  {} = zext i8 {} to i32", row_byte, row_byte8));

        let col_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", col_ptr));
        self.line(&format!("  store i32 0, i32* {}", col_ptr));
        let col_cond = self.block_label("draw_text_col_cond");
        let col_body = self.block_label("draw_text_col_body");
        let col_end = self.block_label("draw_text_col_end");
        self.line(&format!("  br label %{}", col_cond));

        self.open_block(&col_cond);
        let col = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", col, col_ptr));
        let col_more = self.tmp_name();
        self.line(&format!("  {} = icmp slt i32 {}, {}", col_more, col, width));
        self.line(&format!("  br i1 {}, label %{}, label %{}", col_more, col_body, col_end));

        self.open_block(&col_body);
        let shift_raw1 = self.tmp_name();
        self.line(&format!("  {} = sub i32 {}, 1", shift_raw1, width));
        let shift_raw2 = self.tmp_name();
        self.line(&format!("  {} = sub i32 {}, {}", shift_raw2, shift_raw1, col));
        // `width` is a runtime value read from the font handle (0..255 for
        // a hand-crafted-malicious font file, though `font_load` already
        // rejects anything outside `1..=8`) -- mask the shift amount to
        // 0..31 so a corrupt/bogus font can never trigger a poison shift
        // under LLVM's semantics, the same bug class
        // `crate::codegen::sdl::emit_mouse_button_down` already guards
        // against (see its own doc comment).
        let shift = self.tmp_name();
        self.line(&format!("  {} = and i32 {}, 31", shift, shift_raw2));
        let bit = self.tmp_name();
        self.line(&format!("  {} = lshr i32 {}, {}", bit, row_byte, shift));
        let bit_set = self.tmp_name();
        self.line(&format!("  {} = and i32 {}, 1", bit_set, bit));
        let pixel_on = self.tmp_name();
        self.line(&format!("  {} = icmp ne i32 {}, 0", pixel_on, bit_set));

        let pixel_label = self.block_label("draw_text_pixel");
        let after_pixel_label = self.block_label("draw_text_after_pixel");
        self.line(&format!("  br i1 {}, label %{}, label %{}", pixel_on, pixel_label, after_pixel_label));

        self.open_block(&pixel_label);
        let col_off = self.tmp_name();
        self.line(&format!("  {} = mul i32 {}, {}", col_off, col, scale));
        let px = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, {}", px, cx0, col_off));
        let row_off_px = self.tmp_name();
        self.line(&format!("  {} = mul i32 {}, {}", row_off_px, row, scale));
        let py = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, {}", py, cy0, row_off_px));
        self.emit_fill_rect(&renderer, &px, &py, &scale, &scale);
        self.line(&format!("  br label %{}", after_pixel_label));

        self.open_block(&after_pixel_label);
        let col_next = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", col_next, col));
        self.line(&format!("  store i32 {}, i32* {}", col_next, col_ptr));
        self.line(&format!("  br label %{}", col_cond));

        self.open_block(&col_end);
        let row_next = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", row_next, row));
        self.line(&format!("  store i32 {}, i32* {}", row_next, row_ptr));
        self.line(&format!("  br label %{}", row_cond));

        self.open_block(&row_end);
        self.line(&format!("  br label %{}", advance_label));

        self.open_block(&advance_label);
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

    /// `measure_text(font: ptr, text: str, scale: int) -> (int, int)`: the
    /// `(width, height)` in pixels `draw_text` would occupy drawing `text`
    /// with `font` at `scale`, without drawing anything -- shares its
    /// character-walking/lowercase-folding/`\n`-handling logic with
    /// `emit_draw_text` via `emit_read_font_header`/`emit_clamp_scale`/
    /// `emit_fold_lowercase` so the two can never silently disagree about
    /// where a character lands. Every character (defined or blank glyph
    /// alike) occupies exactly one glyph cell, so unlike `draw_text` this
    /// never needs to test whether a codepoint is actually in the font's
    /// range.
    pub(super) fn emit_measure_text(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 3 {
            self.err("measure_text(..) expects 3 arguments (font, text, scale)", Span::dummy());
            return "{ i32, i32 } zeroinitializer".into();
        }
        let fv = self.emit_expr(&args[0]);
        let font = self.untag(&fv, &Ty::Ptr);
        self.abort_if_null_font(&font, "measure_text");
        let text_ptr = self.emit_raw_str_ptr(&args[1]);
        let scalev = self.emit_expr(&args[2]);
        let scale_raw = self.untag(&scalev, &Ty::Int);
        let scale = self.emit_clamp_scale(&scale_raw);

        let (width, height, _first_char, _num_chars) = self.emit_read_font_header(&font);

        let advance_w = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", advance_w, width));
        let advance = self.tmp_name();
        self.line(&format!("  {} = mul i32 {}, {}", advance, advance_w, scale));
        let line_h_raw = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, 1", line_h_raw, height));
        let line_h = self.tmp_name();
        self.line(&format!("  {} = mul i32 {}, {}", line_h, line_h_raw, scale));

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

        let cond_label = self.block_label("measure_text_cond");
        let body_label = self.block_label("measure_text_body");
        let newline_label = self.block_label("measure_text_newline");
        let advance_label = self.block_label("measure_text_advance");
        let end_label = self.block_label("measure_text_end");

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
        let cw2 = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", cw2, cur_w_ptr));
        let cw3 = self.tmp_name();
        self.line(&format!("  {} = add i32 {}, {}", cw3, cw2, advance));
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
        // `lc_final` whole lines of height `line_h` each, minus one trailing
        // inter-line gap (`line_h` == `(height+1)*scale`, i.e. glyph height
        // plus a 1-row gap -- multiplying straight through would count a
        // gap *after* the last line too).
        let total_h_raw = self.tmp_name();
        self.line(&format!("  {} = mul i32 {}, {}", total_h_raw, lc_final, line_h));
        let total_h = self.tmp_name();
        self.line(&format!("  {} = sub i32 {}, {}", total_h, total_h_raw, scale));

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

    /// `get_pixel(window: ptr, x: int, y: int) -> Color32`: reads a single
    /// pixel back from `window`'s current framebuffer via
    /// `SDL_RenderReadPixels` against a 1x1 `SDL_Rect` at `(x, y)` -- see
    /// this module's own doc comment for the pixel-format/byte-order
    /// reasoning.
    pub(super) fn emit_get_pixel(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 3 {
            self.err("get_pixel(..) expects 3 arguments (window, x, y)", Span::dummy());
            return "i32 0".into();
        }
        let wv = self.emit_expr(&args[0]);
        let window = self.untag(&wv, &Ty::Ptr);
        self.abort_if_null_window(&window, "get_pixel");
        let renderer = self.emit_sdl_get_renderer(&window);
        let xv = self.emit_expr(&args[1]);
        let x = self.untag(&xv, &Ty::Int);
        let yv = self.emit_expr(&args[2]);
        let y = self.untag(&yv, &Ty::Int);

        let rect_buf = self.tmp_name();
        self.line(&format!("  {} = alloca [16 x i8]", rect_buf));
        let rect_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [16 x i8], [16 x i8]* {}, i64 0, i64 0", rect_ptr, rect_buf));
        let x_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", x_ptr, rect_ptr));
        self.line(&format!("  store i32 {}, i32* {}", x, x_ptr));
        let y_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 4", y_gep, rect_ptr));
        let y_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", y_ptr, y_gep));
        self.line(&format!("  store i32 {}, i32* {}", y, y_ptr));
        let w_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 8", w_gep, rect_ptr));
        let w_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", w_ptr, w_gep));
        self.line(&format!("  store i32 1, i32* {}", w_ptr));
        let h_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 12", h_gep, rect_ptr));
        let h_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", h_ptr, h_gep));
        self.line(&format!("  store i32 1, i32* {}", h_ptr));

        let pixel_buf = self.tmp_name();
        self.line(&format!("  {} = alloca [4 x i8]", pixel_buf));
        let pixel_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [4 x i8], [4 x i8]* {}, i64 0, i64 0", pixel_ptr, pixel_buf));
        // `376840196` == `SDL_PIXELFORMAT_RGBA32` (`SDL_PIXELFORMAT_ABGR8888`
        // on this little-endian target) -- see this module's own doc
        // comment.
        self.line(&format!(
            "  call i32 @SDL_RenderReadPixels(i8* {}, i8* {}, i32 376840196, i8* {}, i32 4)",
            renderer, rect_ptr, pixel_ptr
        ));
        let pixel_i32_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", pixel_i32_ptr, pixel_ptr));
        let packed = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", packed, pixel_i32_ptr));
        format!("i32 {}", packed)
    }
}

//! SDL2-backed graphics/input builtins (`todo.md` #4 "Graphics / audio /
//! input bindings" -- the "window creation + framebuffer/pixel-blit... input
//! polling" minimal viable slice that item's own note says to sequence after
//! FFI, so it's a binding to SDL rather than a from-scratch renderer). Thin
//! wrappers over a handful of SDL2 C functions, the same "hand-emit calls to
//! an existing C API" shape `file_io.rs`/`net.rs` already established. SDL2's
//! headers/import lib/runtime DLL are vendored under `sdl/` at the repo root
//! (`sdl/include`, `sdl/lib/x64`) rather than assumed to be installed
//! system-wide.
//!
//! `Ty::Ptr` is reused as the opaque window handle (an `SDL_Window*`) --
//! exactly the "opaque foreign pointer, no RC header" shape `file_io.rs`/
//! `net.rs` already established for a `FILE*`/`SOCKET`. There is
//! deliberately no separate renderer handle: every drawing builtin re-derives
//! the `SDL_Renderer*` from the window via `SDL_GetRenderer` (a real, cheap
//! SDL2 API for exactly this "one renderer per window" case) rather than
//! having the caller juggle two handles for what this floor always treats as
//! a single unit.
//!
//! Linking note: like `tcp_*`'s `ws2_32` (see `net.rs`'s own doc comment), a
//! Star program calling any of these needs `-L sdl/lib/x64 -l SDL2` passed
//! explicitly at build time (`star build foo.star -L sdl/lib/x64 -l SDL2`),
//! and `sdl/lib/x64/SDL2.dll` must be discoverable at run time (next to the
//! built `.exe`, or on `PATH`) -- SDL2 isn't part of this target's
//! implicitly-linked default libraries.
//!
//! Error model: `window_create` returns a null `ptr` if `SDL_Init`/
//! `SDL_CreateWindow`/`SDL_CreateRenderer` fails, checked with the existing
//! `is_null` builtin -- same convention as `file_open`/`tcp_connect`. Every
//! other builtin here aborts loudly on a null/closed window handle
//! (`abort_if_null_window`), mirroring `file_io.rs`'s `abort_if_null_handle`.
//! `window_should_close` drains the *entire* pending event queue every call
//! (not just peeks one event) -- an unpumped SDL event queue makes the OS
//! mark the window "Not Responding" within a couple of seconds, so this
//! doubles as the per-frame pump `key_down`/`mouse_x`/`mouse_y`/
//! `mouse_button_down` all depend on to see current input state. Only a
//! global `SDL_QUIT` event is recognized (not a per-window close button via
//! `SDL_WINDOWEVENT_CLOSE`) -- a deliberate floor cut for the common
//! single-window case, the same kind of scope cut `net.rs`'s "no hostname
//! resolution" already documents for `tcp_connect`.

use crate::diagnostics::Span;
use crate::types::*;

use super::Codegen;

impl Codegen {
    /// Abort (matches `file_io.rs`'s `abort_if_null_handle` shape exactly,
    /// with window-specific wording) if `handle` is a null `ptr`. Used by
    /// every builtin here except `window_create`, which has no handle to
    /// misuse yet.
    fn abort_if_null_window(&mut self, handle: &str, builtin_name: &str) {
        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, handle));
        let fail_label = self.block_label("sdl_null_window");
        let ok_label = self.block_label("sdl_window_handle_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, fail_label, ok_label));

        self.open_block(&fail_label);
        let msg = format!("star runtime error: {}(..) called with a null/closed window handle\n", builtin_name);
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

    /// `SDL_GetRenderer(window) -> SDL_Renderer*` -- see this module's own
    /// doc comment for why no builtin here ever holds a renderer handle of
    /// its own.
    fn emit_sdl_get_renderer(&mut self, window: &str) -> String {
        let renderer = self.tmp_name();
        self.line(&format!("  {} = call i8* @SDL_GetRenderer(i8* {})", renderer, window));
        renderer
    }

    /// Evaluate a `Color32` argument once and unpack its four 0-255 channels
    /// as `i8`s, in `SDL_SetRenderDrawColor`'s `(r, g, b, a)` order -- the
    /// exact `r | g<<8 | b<<16 | a<<24` layout `emit_color32_channel`
    /// (`crate::codegen::geometry`) already established, just truncated to
    /// `i8` (SDL's `Uint8`) instead of widened back to `i32`.
    fn emit_color32_rgba8(&mut self, arg: &TypedExpr) -> (String, String, String, String) {
        let val = self.emit_expr(arg);
        let packed = self.untag(&val, &Ty::Color32);
        let mut channels = Vec::with_capacity(4);
        for i in 0u32..4 {
            let shifted = if i == 0 {
                packed.clone()
            } else {
                let reg = self.tmp_name();
                self.line(&format!("  {} = lshr i32 {}, {}", reg, packed, i * 8));
                reg
            };
            let masked = self.tmp_name();
            self.line(&format!("  {} = and i32 {}, 255", masked, shifted));
            let byte = self.tmp_name();
            self.line(&format!("  {} = trunc i32 {} to i8", byte, masked));
            channels.push(byte);
        }
        (channels[0].clone(), channels[1].clone(), channels[2].clone(), channels[3].clone())
    }

    fn emit_set_render_draw_color(&mut self, renderer: &str, color: &TypedExpr) {
        let (r, g, b, a) = self.emit_color32_rgba8(color);
        self.line(&format!("  call i32 @SDL_SetRenderDrawColor(i8* {}, i8 {}, i8 {}, i8 {}, i8 {})", renderer, r, g, b, a));
    }

    /// `window_create(title: str, width: int, height: int) -> ptr`:
    /// `SDL_Init(SDL_INIT_VIDEO)` (called every time, ref-counted internally
    /// by SDL exactly like Winsock -- see `net.rs`'s `emit_tcp_connect`'s own
    /// "called on every connect" note), then `SDL_CreateWindow` at an
    /// unspecified (`SDL_WINDOWPOS_UNDEFINED`, `0x1FFF0000`) position with no
    /// flags, then `SDL_CreateRenderer` with no required flags (`-1`/`0`
    /// picks the first suitable driver -- hardware-accelerated where
    /// available, falling back to software, e.g. under a headless
    /// `SDL_VIDEODRIVER=dummy` test run). Null `ptr` if any of the three
    /// fails, same convention as `file_open`/`tcp_connect`, checked with
    /// `is_null`.
    pub(super) fn emit_window_create(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 3 {
            self.err("window_create(..) expects 3 arguments (title, width, height)", Span::dummy());
            return "i8* null".into();
        }
        let title = self.emit_raw_str_ptr(&args[0]);
        let wv = self.emit_expr(&args[1]);
        let w = self.untag(&wv, &Ty::Int);
        let hv = self.emit_expr(&args[2]);
        let h = self.untag(&hv, &Ty::Int);

        let init = self.tmp_name();
        self.line(&format!("  {} = call i32 @SDL_Init(i32 32)", init)); // SDL_INIT_VIDEO
        let init_failed = self.tmp_name();
        self.line(&format!("  {} = icmp ne i32 {}, 0", init_failed, init));
        let init_fail_label = self.block_label("sdl_init_fail");
        let init_ok_label = self.block_label("sdl_init_ok");
        let end_label = self.block_label("window_create_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", init_failed, init_fail_label, init_ok_label));

        self.open_block(&init_fail_label);
        self.line(&format!("  call void @star_rc_release(i8* {})", title));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&init_ok_label);
        let window = self.tmp_name();
        // `SDL_WINDOWPOS_UNDEFINED` == `SDL_WINDOWPOS_UNDEFINED_MASK | 0` ==
        // `0x1FFF0000` == 536870912 - 65536 == 536805376.
        self.line(&format!(
            "  {} = call i8* @SDL_CreateWindow(i8* {}, i32 536805376, i32 536805376, i32 {}, i32 {}, i32 0)",
            window, title, w, h
        ));
        self.line(&format!("  call void @star_rc_release(i8* {})", title));
        let win_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", win_null, window));
        let win_fail_label = self.block_label("sdl_window_fail");
        let win_ok_label = self.block_label("sdl_window_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", win_null, win_fail_label, win_ok_label));

        self.open_block(&win_fail_label);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&win_ok_label);
        let renderer = self.tmp_name();
        self.line(&format!("  {} = call i8* @SDL_CreateRenderer(i8* {}, i32 -1, i32 0)", renderer, window));
        let ren_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", ren_null, renderer));
        let ren_fail_label = self.block_label("sdl_renderer_fail");
        let ren_ok_label = self.block_label("sdl_renderer_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", ren_null, ren_fail_label, ren_ok_label));

        self.open_block(&ren_fail_label);
        self.line(&format!("  call void @SDL_DestroyWindow(i8* {})", window));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&ren_ok_label);
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let result = self.tmp_name();
        self.line(&format!(
            "  {} = phi i8* [ null, %{} ], [ null, %{} ], [ null, %{} ], [ {}, %{} ]",
            result, init_fail_label, win_fail_label, ren_fail_label, window, ren_ok_label
        ));
        format!("i8* {}", result)
    }

    /// `window_destroy(handle: ptr)`: destroys the window's renderer (found
    /// via `SDL_GetRenderer`, see this module's doc comment) and the window
    /// itself. No `SDL_Quit` call -- like `net.rs`'s `tcp_close` skipping
    /// `WSACleanup`, the OS tears the whole process's SDL state down at exit
    /// anyway, and `SDL_Init`/`SDL_Quit` calls must otherwise stay balanced
    /// (SDL ref-counts subsystem init), which this floor doesn't track.
    ///
    /// A repeated `window_create`/`window_destroy` cycle grows process memory
    /// under `SDL_VIDEODRIVER=dummy` (SDL2's headless video driver, used only
    /// for this project's own headless test runs) -- confirmed (see
    /// `todo.md`'s bug-hunting-round-5 writeup) via both a pure C program
    /// linked against the identical vendored `SDL2.dll` and this codegen's
    /// own compiled output. A follow-up investigation isolated this further:
    /// sampling process working-set across 400 cycles under the *real*
    /// `windows` video driver (what an actual built/shipped Star program
    /// uses -- nothing sets `SDL_VIDEODRIVER` in normal operation) plateaus
    /// and fluctuates in a ~20-36MB steady-state band with no sustained
    /// growth, while the identical 400 cycles under `dummy` climbs
    /// monotonically past 200MB. The growth is real but confined to the
    /// `dummy` driver's own window-recreation path -- it does not reproduce
    /// with a real window, so no shipped Star program is affected, and there
    /// is no codegen change that would fix a driver-internal accounting bug
    /// this floor has no access to anyway. Left unfixed for that reason; not
    /// a live risk unless a *test* cycles windows hundreds of times in one
    /// process under `dummy` (nothing in this project's own test suite does).
    pub(super) fn emit_window_destroy(&mut self, args: &[TypedExpr]) {
        let Some(arg) = args.first() else {
            self.err("window_destroy(..) expects 1 argument", Span::dummy());
            return;
        };
        let val = self.emit_expr(arg);
        let window = self.untag(&val, &Ty::Ptr);
        self.abort_if_null_window(&window, "window_destroy");
        let renderer = self.emit_sdl_get_renderer(&window);
        self.line(&format!("  call void @SDL_DestroyRenderer(i8* {})", renderer));
        self.line(&format!("  call void @SDL_DestroyWindow(i8* {})", window));
        // Null out the caller's own variable, if `arg` is a bare one --
        // same fix, same rationale, as `file_io.rs`'s `emit_file_close`/
        // `net.rs`'s `emit_tcp_close` (see either's doc comment): destroying
        // a window doesn't invalidate the handle *value* itself, which a
        // later, unrelated `window_create` may reuse for a different window.
        if let TypedExpr::Ident { .. } = arg {
            let place = self.emit_place(arg);
            self.line(&format!("  store i8* null, i8** {}", place));
        }
    }

    /// `window_should_close(handle: ptr) -> bool`: drains every pending SDL
    /// event (see this module's doc comment for why draining, not peeking,
    /// matters), returning whether an `SDL_QUIT` event (`0x100` == 256) was
    /// seen anywhere in the batch.
    pub(super) fn emit_window_should_close(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("window_should_close(..) expects 1 argument", Span::dummy());
            return "i1 false".into();
        };
        let val = self.emit_expr(arg);
        let window = self.untag(&val, &Ty::Ptr);
        self.abort_if_null_window(&window, "window_should_close");

        let quit_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i1", quit_ptr));
        self.line(&format!("  store i1 false, i1* {}", quit_ptr));

        // `SDL_Event` is a 56-byte union on a 64-bit target (`sizeof(void*)
        // <= 8 ? 56 : ...` in `SDL_events.h`) -- only the leading `Uint32
        // type` field is ever read here.
        let event_buf = self.tmp_name();
        self.line(&format!("  {} = alloca [56 x i8]", event_buf));
        let event_ptr = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds [56 x i8], [56 x i8]* {}, i64 0, i64 0", event_ptr, event_buf));

        let cond_label = self.block_label("sdl_poll_cond");
        let body_label = self.block_label("sdl_poll_body");
        let set_quit_label = self.block_label("sdl_poll_set_quit");
        let end_label = self.block_label("sdl_poll_end");
        self.line(&format!("  br label %{}", cond_label));

        self.open_block(&cond_label);
        let has_event = self.tmp_name();
        self.line(&format!("  {} = call i32 @SDL_PollEvent(i8* {})", has_event, event_ptr));
        let more = self.tmp_name();
        self.line(&format!("  {} = icmp ne i32 {}, 0", more, has_event));
        self.line(&format!("  br i1 {}, label %{}, label %{}", more, body_label, end_label));

        self.open_block(&body_label);
        let type_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", type_ptr, event_ptr));
        let ev_type = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", ev_type, type_ptr));
        let is_quit = self.tmp_name();
        self.line(&format!("  {} = icmp eq i32 {}, 256", is_quit, ev_type)); // SDL_QUIT
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_quit, set_quit_label, cond_label));

        self.open_block(&set_quit_label);
        self.line(&format!("  store i1 true, i1* {}", quit_ptr));
        self.line(&format!("  br label %{}", cond_label));

        self.open_block(&end_label);
        let result = self.tmp_name();
        self.line(&format!("  {} = load i1, i1* {}", result, quit_ptr));
        format!("i1 {}", result)
    }

    /// `clear_screen(handle: ptr, color: Color32)`: `SDL_RenderClear` after
    /// setting the draw color to `color`.
    pub(super) fn emit_clear_screen(&mut self, args: &[TypedExpr]) {
        if args.len() < 2 {
            self.err("clear_screen(..) expects 2 arguments (window, color)", Span::dummy());
            return;
        }
        let val = self.emit_expr(&args[0]);
        let window = self.untag(&val, &Ty::Ptr);
        self.abort_if_null_window(&window, "clear_screen");
        let renderer = self.emit_sdl_get_renderer(&window);
        self.emit_set_render_draw_color(&renderer, &args[1]);
        self.line(&format!("  call i32 @SDL_RenderClear(i8* {})", renderer));
    }

    /// `draw_pixel(handle: ptr, x: int, y: int, color: Color32)`:
    /// `SDL_RenderDrawPoint` after setting the draw color.
    pub(super) fn emit_draw_pixel(&mut self, args: &[TypedExpr]) {
        if args.len() < 4 {
            self.err("draw_pixel(..) expects 4 arguments (window, x, y, color)", Span::dummy());
            return;
        }
        let val = self.emit_expr(&args[0]);
        let window = self.untag(&val, &Ty::Ptr);
        self.abort_if_null_window(&window, "draw_pixel");
        let renderer = self.emit_sdl_get_renderer(&window);
        let xv = self.emit_expr(&args[1]);
        let x = self.untag(&xv, &Ty::Int);
        let yv = self.emit_expr(&args[2]);
        let y = self.untag(&yv, &Ty::Int);
        self.emit_set_render_draw_color(&renderer, &args[3]);
        self.line(&format!("  call i32 @SDL_RenderDrawPoint(i8* {}, i32 {}, i32 {})", renderer, x, y));
    }

    /// `draw_rect(handle: ptr, x: int, y: int, w: int, h: int, color:
    /// Color32)`: a filled rectangle -- `SDL_RenderFillRect` against a
    /// stack-built `SDL_Rect` (`{ i32 x, i32 y, i32 w, i32 h }`, 16 bytes, no
    /// padding -- the same hand-laid-out-struct move `net.rs`'s
    /// `emit_tcp_connect` already uses for `sockaddr_in`).
    pub(super) fn emit_draw_rect(&mut self, args: &[TypedExpr]) {
        if args.len() < 6 {
            self.err("draw_rect(..) expects 6 arguments (window, x, y, w, h, color)", Span::dummy());
            return;
        }
        let val = self.emit_expr(&args[0]);
        let window = self.untag(&val, &Ty::Ptr);
        self.abort_if_null_window(&window, "draw_rect");
        let renderer = self.emit_sdl_get_renderer(&window);
        let xv = self.emit_expr(&args[1]);
        let x = self.untag(&xv, &Ty::Int);
        let yv = self.emit_expr(&args[2]);
        let y = self.untag(&yv, &Ty::Int);
        let wv = self.emit_expr(&args[3]);
        let w = self.untag(&wv, &Ty::Int);
        let hv = self.emit_expr(&args[4]);
        let h = self.untag(&hv, &Ty::Int);
        self.emit_set_render_draw_color(&renderer, &args[5]);

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
        self.line(&format!("  store i32 {}, i32* {}", w, w_ptr));

        let h_gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 12", h_gep, rect_ptr));
        let h_ptr = self.tmp_name();
        self.line(&format!("  {} = bitcast i8* {} to i32*", h_ptr, h_gep));
        self.line(&format!("  store i32 {}, i32* {}", h, h_ptr));

        self.line(&format!("  call i32 @SDL_RenderFillRect(i8* {}, i8* {})", renderer, rect_ptr));
    }

    /// `draw_line(handle: ptr, x1: int, y1: int, x2: int, y2: int, color:
    /// Color32)`: `SDL_RenderDrawLine` after setting the draw color.
    pub(super) fn emit_draw_line(&mut self, args: &[TypedExpr]) {
        if args.len() < 6 {
            self.err("draw_line(..) expects 6 arguments (window, x1, y1, x2, y2, color)", Span::dummy());
            return;
        }
        let val = self.emit_expr(&args[0]);
        let window = self.untag(&val, &Ty::Ptr);
        self.abort_if_null_window(&window, "draw_line");
        let renderer = self.emit_sdl_get_renderer(&window);
        let x1v = self.emit_expr(&args[1]);
        let x1 = self.untag(&x1v, &Ty::Int);
        let y1v = self.emit_expr(&args[2]);
        let y1 = self.untag(&y1v, &Ty::Int);
        let x2v = self.emit_expr(&args[3]);
        let x2 = self.untag(&x2v, &Ty::Int);
        let y2v = self.emit_expr(&args[4]);
        let y2 = self.untag(&y2v, &Ty::Int);
        self.emit_set_render_draw_color(&renderer, &args[5]);
        self.line(&format!("  call i32 @SDL_RenderDrawLine(i8* {}, i32 {}, i32 {}, i32 {}, i32 {})", renderer, x1, y1, x2, y2));
    }

    /// `present(handle: ptr)`: `SDL_RenderPresent` -- flips the backbuffer
    /// built up by `clear_screen`/`draw_pixel`/`draw_rect`/`draw_line` to the
    /// screen. Nothing drawn this frame is visible until this is called.
    pub(super) fn emit_present(&mut self, args: &[TypedExpr]) {
        let Some(arg) = args.first() else {
            self.err("present(..) expects 1 argument", Span::dummy());
            return;
        };
        let val = self.emit_expr(arg);
        let window = self.untag(&val, &Ty::Ptr);
        self.abort_if_null_window(&window, "present");
        let renderer = self.emit_sdl_get_renderer(&window);
        self.line(&format!("  call void @SDL_RenderPresent(i8* {})", renderer));
    }

    /// `key_down(scancode: int) -> bool`: reads `SDL_GetKeyboardState`'s
    /// per-key snapshot array (kept current by `window_should_close`'s event
    /// pump -- see this module's doc comment) at `scancode`'s index.
    /// `SDL_NUM_SCANCODES` is 512; an out-of-range index (a bogus caller-
    /// supplied constant) is clamped to a safe `false` rather than indexing
    /// past the array the way an unchecked `List<T>[idx]` never would.
    pub(super) fn emit_key_down(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("key_down(..) expects 1 argument", Span::dummy());
            return "i1 false".into();
        };
        let val = self.emit_expr(arg);
        let scancode = self.untag(&val, &Ty::Int);

        let lo_ok = self.tmp_name();
        self.line(&format!("  {} = icmp sge i32 {}, 0", lo_ok, scancode));
        let hi_ok = self.tmp_name();
        self.line(&format!("  {} = icmp slt i32 {}, 512", hi_ok, scancode));
        let in_range = self.tmp_name();
        self.line(&format!("  {} = and i1 {}, {}", in_range, lo_ok, hi_ok));
        let pre_label = self.current_label.clone();
        let read_label = self.block_label("key_down_read");
        let end_label = self.block_label("key_down_end");
        self.line(&format!("  br i1 {}, label %{}, label %{}", in_range, read_label, end_label));

        self.open_block(&read_label);
        let state = self.tmp_name();
        self.line(&format!("  {} = call i8* @SDL_GetKeyboardState(i32* null)", state));
        let idx64 = self.tmp_name();
        self.line(&format!("  {} = sext i32 {} to i64", idx64, scancode));
        let gep = self.tmp_name();
        self.line(&format!("  {} = getelementptr inbounds i8, i8* {}, i64 {}", gep, state, idx64));
        let byte = self.tmp_name();
        self.line(&format!("  {} = load i8, i8* {}", byte, gep));
        let pressed = self.tmp_name();
        self.line(&format!("  {} = icmp ne i8 {}, 0", pressed, byte));
        self.line(&format!("  br label %{}", end_label));

        self.open_block(&end_label);
        let result = self.tmp_name();
        self.line(&format!("  {} = phi i1 [ false, %{} ], [ {}, %{} ]", result, pre_label, pressed, read_label));
        format!("i1 {}", result)
    }

    /// `SDL_GetMouseState(&x, &y) -> Uint32` into two stack `i32`s, returning
    /// `(buttons_mask, x, y)`. Shared by `mouse_x`/`mouse_y`/
    /// `mouse_button_down` -- each calls it fresh rather than caching, the
    /// same "no cross-builtin state" simplicity every other builtin here
    /// keeps.
    fn emit_sdl_get_mouse_state(&mut self) -> (String, String, String) {
        let x_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", x_ptr));
        let y_ptr = self.tmp_name();
        self.line(&format!("  {} = alloca i32", y_ptr));
        let buttons = self.tmp_name();
        self.line(&format!("  {} = call i32 @SDL_GetMouseState(i32* {}, i32* {})", buttons, x_ptr, y_ptr));
        let x = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", x, x_ptr));
        let y = self.tmp_name();
        self.line(&format!("  {} = load i32, i32* {}", y, y_ptr));
        (buttons, x, y)
    }

    /// `mouse_x() -> int`: the mouse cursor's current X position, relative
    /// to the focused window.
    pub(super) fn emit_mouse_x(&mut self) -> String {
        let (_, x, _) = self.emit_sdl_get_mouse_state();
        format!("i32 {}", x)
    }

    /// `mouse_y() -> int`: the mouse cursor's current Y position, relative
    /// to the focused window.
    pub(super) fn emit_mouse_y(&mut self) -> String {
        let (_, _, y) = self.emit_sdl_get_mouse_state();
        format!("i32 {}", y)
    }

    /// `mouse_button_down(button: int) -> bool`: `button` matches SDL's own
    /// 1-based `SDL_BUTTON_LEFT`/`MIDDLE`/`RIGHT` (1/2/3) numbering, tested
    /// against `SDL_GetMouseState`'s returned bitmask via
    /// `SDL_BUTTON(button)`'s own `1 << (button - 1)` definition. The shift
    /// amount is masked mod 32 before the `shl` -- an out-of-range `button`
    /// (e.g. 0 or a huge caller-supplied value) would otherwise be a poison
    /// shift under LLVM's semantics, the exact bug class
    /// `bit_get`/`bit_set`/... were fixed for (`crate::codegen::bitfield`'s
    /// module doc comment) -- rather than real undefined behavior, a bogus
    /// `button` now just yields some deterministic-but-meaningless mask,
    /// matching this codegen's "safe, not panicking" convention.
    pub(super) fn emit_mouse_button_down(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("mouse_button_down(..) expects 1 argument", Span::dummy());
            return "i1 false".into();
        };
        let val = self.emit_expr(arg);
        let button = self.untag(&val, &Ty::Int);
        let (buttons, _, _) = self.emit_sdl_get_mouse_state();
        let shift_raw = self.tmp_name();
        self.line(&format!("  {} = sub i32 {}, 1", shift_raw, button));
        let shift = self.tmp_name();
        self.line(&format!("  {} = and i32 {}, 31", shift, shift_raw));
        let mask = self.tmp_name();
        self.line(&format!("  {} = shl i32 1, {}", mask, shift));
        let anded = self.tmp_name();
        self.line(&format!("  {} = and i32 {}, {}", anded, buttons, mask));
        let reg = self.tmp_name();
        self.line(&format!("  {} = icmp ne i32 {}, 0", reg, anded));
        format!("i1 {}", reg)
    }

    /// `delay(ms: int)`: `SDL_Delay`, a blocking sleep. `ms` is clamped to 0
    /// if negative -- `SDL_Delay` takes an unsigned `Uint32`, and a negative
    /// `i32` bit-reinterpreted as unsigned would otherwise sleep for
    /// somewhere up to ~49 days instead of failing cleanly.
    pub(super) fn emit_delay(&mut self, args: &[TypedExpr]) {
        let Some(arg) = args.first() else {
            self.err("delay(..) expects 1 argument", Span::dummy());
            return;
        };
        let val = self.emit_expr(arg);
        let ms = self.untag(&val, &Ty::Int);
        let is_neg = self.tmp_name();
        self.line(&format!("  {} = icmp slt i32 {}, 0", is_neg, ms));
        let clamped = self.tmp_name();
        self.line(&format!("  {} = select i1 {}, i32 0, i32 {}", clamped, is_neg, ms));
        self.line(&format!("  call void @SDL_Delay(i32 {})", clamped));
    }

    /// `ticks() -> int`: milliseconds since `SDL_Init` was first called, per
    /// `SDL_GetTicks`'s own `Uint32` return (wraps after ~49 days -- a real,
    /// documented SDL2 limitation this floor inherits rather than works
    /// around, since `SDL_GetTicks64` would need its own separate `i64`
    /// return-type plumbing for a gap that never matters within one running
    /// game process).
    pub(super) fn emit_ticks(&mut self) -> String {
        let reg = self.tmp_name();
        self.line(&format!("  {} = call i32 @SDL_GetTicks()", reg));
        format!("i32 {}", reg)
    }
}

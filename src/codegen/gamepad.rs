//! SDL2-backed gamepad/joystick input builtins (`todo.md` #8 "Audio playback
//! and gamepad input" -- the gamepad half; see `crate::codegen::audio` for
//! the other half).
//!
//! Bound to SDL2's lower-level `SDL_Joystick` API (raw, numbered buttons/
//! axes) rather than the higher-level `SDL_GameController` API (a fixed
//! Xbox-style `A`/`B`/`LEFTX`/... layout). `SDL_GameController` only
//! recognizes a device as a "game controller" at all if its exact USB
//! vendor/product ID is present in SDL's mapping database (normally loaded
//! from a `gamecontrollerdb.txt` this floor doesn't bundle or fetch) --
//! without it, a real, physically-connected pad is invisible to that API
//! even though `SDL_Joystick` sees it fine. Raw numbered buttons/axes is
//! also directly testable end-to-end with no physical hardware at all via
//! SDL2's own virtual-joystick API (`SDL_JoystickAttachVirtual`/
//! `SDL_JoystickSetVirtualButton`/`SDL_JoystickSetVirtualAxis`, all called
//! straight from a test `.star` program through an `extern "C" fn`
//! declaration -- see `tests/frontend_audio_gamepad.rs`), which made it the clearly
//! better fit for this floor over pulling in a mapping database.
//!
//! `Ty::Ptr` is reused as the opaque `SDL_Joystick*` handle, exactly the
//! same "opaque foreign pointer, no RC header" shape `crate::codegen::sdl`/
//! `crate::codegen::font` already established for a window/font handle.
//!
//! Every read (`gamepad_button_down`/`gamepad_axis`/`gamepad_attached`)
//! calls `SDL_JoystickUpdate` first -- unlike `key_down`/`mouse_x`/`mouse_y`,
//! which piggyback on `window_should_close`'s own event-queue drain, a
//! gamepad-only program (no window at all) would otherwise never see fresh
//! input state, so this floor pumps joystick state itself rather than
//! depending on some other builtin having been called first.
//!
//! Linking note: same as `crate::codegen::sdl`'s own note -- needs
//! `-L sdl/lib/x64 -l SDL2` at build time and `SDL2.dll` discoverable at run
//! time.

use crate::diagnostics::Span;
use crate::types::*;

use super::Codegen;

/// `SDL_INIT_JOYSTICK` (`0x00000200` in `SDL.h`).
const SDL_INIT_JOYSTICK: u32 = 0x200;

impl Codegen {
    /// Abort (matches `crate::codegen::sdl`'s `abort_if_null_window` shape
    /// exactly, with gamepad-specific wording) if `handle` is a null `ptr`.
    /// Used by every builtin here except `gamepad_open`, which has no
    /// handle to misuse yet.
    fn abort_if_null_gamepad(&mut self, handle: &str, builtin_name: &str) {
        let is_null = self.tmp_name();
        self.line(&format!("  {} = icmp eq i8* {}, null", is_null, handle));
        let fail_label = self.block_label("gamepad_null_handle");
        let ok_label = self.block_label("gamepad_handle_ok");
        self.line(&format!("  br i1 {}, label %{}, label %{}", is_null, fail_label, ok_label));

        self.open_block(&fail_label);
        let msg = format!("star runtime error: {}(..) called with a null/closed gamepad handle\n", builtin_name);
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

    /// `gamepad_count() -> int`: `SDL_Init(SDL_INIT_JOYSTICK)` (called every
    /// time, ref-counted internally by SDL exactly like `window_create`'s
    /// own `SDL_INIT_VIDEO` call -- see that function's doc comment) then
    /// `SDL_NumJoysticks`. Counts every joystick device SDL sees, whether or
    /// not it's actually a recognized gamepad shape -- this floor has no
    /// mapping database to filter by (see this module's own doc comment).
    pub(super) fn emit_gamepad_count(&mut self) -> String {
        let init = self.tmp_name();
        self.line(&format!("  {} = call i32 @SDL_Init(i32 {})", init, SDL_INIT_JOYSTICK));
        let n = self.tmp_name();
        self.line(&format!("  {} = call i32 @SDL_NumJoysticks()", n));
        format!("i32 {}", n)
    }

    /// `gamepad_open(index: int) -> ptr`: `SDL_Init(SDL_INIT_JOYSTICK)` then
    /// `SDL_JoystickOpen(index)`. Null `ptr` if `index` is out of range or
    /// the device has since been unplugged, same convention as
    /// `window_create`/`file_open`, checked with `is_null`.
    pub(super) fn emit_gamepad_open(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("gamepad_open(..) expects 1 argument (index)", Span::dummy());
            return "i8* null".into();
        };
        let val = self.emit_expr(arg);
        let index = self.untag(&val, &Ty::Int);
        let init = self.tmp_name();
        self.line(&format!("  {} = call i32 @SDL_Init(i32 {})", init, SDL_INIT_JOYSTICK));
        let handle = self.tmp_name();
        self.line(&format!("  {} = call i8* @SDL_JoystickOpen(i32 {})", handle, index));
        format!("i8* {}", handle)
    }

    /// `gamepad_close(handle: ptr)`: `SDL_JoystickClose`. Nulls out the
    /// caller's own variable, if `arg` is a bare one -- same fix, same
    /// rationale, as `crate::codegen::sdl`'s `emit_window_destroy` (see its
    /// own doc comment): closing a joystick doesn't invalidate the handle
    /// *value* itself, which a later, unrelated `gamepad_open` may reuse.
    pub(super) fn emit_gamepad_close(&mut self, args: &[TypedExpr]) {
        let Some(arg) = args.first() else {
            self.err("gamepad_close(..) expects 1 argument", Span::dummy());
            return;
        };
        let val = self.emit_expr(arg);
        let handle = self.untag(&val, &Ty::Ptr);
        self.abort_if_null_gamepad(&handle, "gamepad_close");
        self.line(&format!("  call void @SDL_JoystickClose(i8* {})", handle));
        if let TypedExpr::Ident { .. } = arg {
            let place = self.emit_place(arg);
            self.line(&format!("  store i8* null, i8** {}", place));
        }
    }

    /// `gamepad_button_down(handle: ptr, button: int) -> bool`:
    /// `SDL_JoystickUpdate` (see this module's doc comment for why every
    /// read here pumps state itself) then `SDL_JoystickGetButton`. `button`
    /// is a raw, device-specific button index (`0..SDL_JoystickNumButtons`)
    /// -- this floor has no named/standardized button layout to offer (see
    /// this module's doc comment on why `SDL_GameController` was skipped).
    pub(super) fn emit_gamepad_button_down(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("gamepad_button_down(..) expects 2 arguments (handle, button)", Span::dummy());
            return "i1 false".into();
        }
        let val = self.emit_expr(&args[0]);
        let handle = self.untag(&val, &Ty::Ptr);
        self.abort_if_null_gamepad(&handle, "gamepad_button_down");
        let bv = self.emit_expr(&args[1]);
        let button = self.untag(&bv, &Ty::Int);
        self.line("  call void @SDL_JoystickUpdate()");
        let b = self.tmp_name();
        self.line(&format!("  {} = call i8 @SDL_JoystickGetButton(i8* {}, i32 {})", b, handle, button));
        let reg = self.tmp_name();
        self.line(&format!("  {} = icmp ne i8 {}, 0", reg, b));
        format!("i1 {}", reg)
    }

    /// `gamepad_axis(handle: ptr, axis: int) -> int`: `SDL_JoystickUpdate`
    /// then `SDL_JoystickGetAxis`, sign-extended from SDL's own `Sint16` to
    /// this compiler's default `i32` width. Returns SDL's raw, unnormalized
    /// `-32768..32767` range -- matching `mouse_x`/`mouse_y`'s own "raw
    /// pixel coordinates, no unit conversion" convention rather than
    /// inventing a `-1.0..1.0` float range this floor doesn't otherwise
    /// need. `axis` is a raw, device-specific axis index
    /// (`0..SDL_JoystickNumAxes`).
    pub(super) fn emit_gamepad_axis(&mut self, args: &[TypedExpr]) -> String {
        if args.len() < 2 {
            self.err("gamepad_axis(..) expects 2 arguments (handle, axis)", Span::dummy());
            return "i32 0".into();
        }
        let val = self.emit_expr(&args[0]);
        let handle = self.untag(&val, &Ty::Ptr);
        self.abort_if_null_gamepad(&handle, "gamepad_axis");
        let av = self.emit_expr(&args[1]);
        let axis = self.untag(&av, &Ty::Int);
        self.line("  call void @SDL_JoystickUpdate()");
        let a = self.tmp_name();
        self.line(&format!("  {} = call i16 @SDL_JoystickGetAxis(i8* {}, i32 {})", a, handle, axis));
        let a32 = self.tmp_name();
        self.line(&format!("  {} = sext i16 {} to i32", a32, a));
        format!("i32 {}", a32)
    }

    /// `gamepad_attached(handle: ptr) -> bool`: `SDL_JoystickGetAttached`
    /// (an `SDL_bool`, a plain `int`-shaped 0/1 typedef in `SDL_stdinc.h`),
    /// letting a game detect a mid-session unplug explicitly rather than
    /// only observing every button/axis silently reading back as "not
    /// pressed"/`0` forever after (SDL's own documented behavior for a
    /// stale handle, which never crashes but also never signals the
    /// disconnect).
    pub(super) fn emit_gamepad_attached(&mut self, args: &[TypedExpr]) -> String {
        let Some(arg) = args.first() else {
            self.err("gamepad_attached(..) expects 1 argument", Span::dummy());
            return "i1 false".into();
        };
        let val = self.emit_expr(arg);
        let handle = self.untag(&val, &Ty::Ptr);
        self.abort_if_null_gamepad(&handle, "gamepad_attached");
        let a = self.tmp_name();
        self.line(&format!("  {} = call i32 @SDL_JoystickGetAttached(i8* {})", a, handle));
        let reg = self.tmp_name();
        self.line(&format!("  {} = icmp ne i32 {}, 0", reg, a));
        format!("i1 {}", reg)
    }
}

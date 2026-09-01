# Headless regression test for the Keyboard's held-key repeat state machine
# (`keyboard.star::key_hold_begin`/`key_hold_tick`/`key_hold_end`/
# `key_holds_clear`) -- see NOTES.md "Held-key repeat: the reference's
# held_nova_keys synthesizer". Mirrors `nova_gui.py:482-490`'s contract,
# which `main.star`'s guest loop drives per frame: arm on the press edge
# with the press-time code, tick-gate each held frame (280ms initial delay,
# 50ms interval), raw-`push_key` on fire, end on release, clear on
# Reset/Load. The *caller-side* wiring (press-time code capture in
# main.star's `held_code`, the shift-state-at-press mapping) is GUI-loop
# state with no headless driver and is verified by reading + build, like
# the rest of main.star's loop logic; everything in Keyboard itself is
# covered here. SDL2 required same as every harness (ticks/delay/cpulink).
#
# Build: star build projects/nova/tests/key_repeat_test.star
#   -L sdl/lib/x64 -l SDL2 -o projects/nova/tests/key_repeat_test.exe
# Usage: key_repeat_test.exe -- prints PASS/FAIL lines, no arguments.

import "../keyboard.star" as keyboard

fn new_kbd() -> keyboard::Keyboard:
    keyboard::Keyboard(
        buffer = [0 as u8; 64],
        head = 0,
        tail = 0,
        count = 0,
        status = 0 as u8,
        control = 0 as u8,
        debounce_ms = keyboard::DEFAULT_DEBOUNCE_MS,
        last_press = [-1; 256],
        repeat_armed = [false; 256],
        repeat_down_time = [0; 256],
        repeat_last = [0; 256],
    )

# NOTE: the tick-then-raw-push contract is inlined at every fire site
# rather than wrapped in a helper: free functions take struct params by
# VALUE in Star (only `mut self` methods mutate through), so a helper's
# push/timestamp-refresh would silently land in a copy. The inlined shape
# below IS the caller contract main.star's loop implements.

fn check(name: str, got: bool, expected: bool):
    if got == expected:
        println(f"PASS {name}")
    else:
        println(f"FAIL {name}: got {got}, expected {expected}")

fn main():
    # Let the ticks() clock get comfortably positive before any synthetic
    # timestamp poking (same reason as keyboard_debounce_test.star).
    delay(100)

    let mut k = new_kbd()

    # Ticking a never-armed code never fires, and pushes nothing.
    let mut fired = k.key_hold_tick(65 as u8)
    check("never-armed code never fires", fired, false)
    check("never-armed tick left buffer empty", k.count == 0, true)

    # Arm via key_hold_begin (the press-edge call): an immediate tick must
    # NOT fire -- the initial delay hasn't elapsed.
    k.key_hold_begin(65 as u8)
    fired = k.key_hold_tick(65 as u8)
    check("just-armed hold does not fire yet", fired, false)
    check("initial press itself is not the repeater's job", k.count == 0, true)

    # Expire BOTH gates by poking down_time AND last back 300ms (> 280 and
    # > 50): the next tick fires, and the caller's raw push lands in the
    # buffer. (Poking only down_time correctly stays blocked -- the fresh
    # last fails the interval gate.)
    k.repeat_down_time[65] = ticks() - 300
    k.repeat_last[65] = ticks() - 300
    fired = k.key_hold_tick(65 as u8)
    if fired:
        k.push_key(65 as u8)
    check("fires after initial delay", fired, true)
    check("fired repeat landed in buffer", k.count == 1, true)

    # The fire refreshed repeat_last: an immediate second tick must NOT
    # fire -- the 50ms repeat interval hasn't passed.
    fired = k.key_hold_tick(65 as u8)
    check("immediate second tick held off by interval", fired, false)

    # Expire just the interval (poke repeat_last back 60ms > 50): fires
    # again. Two repeats now sit in the buffer effectively 0ms apart --
    # well inside the 35ms debounce window -- and BOTH landed: repeats go
    # through the raw push path, never debounce-dropped (the reference's
    # apply_debounce=False).
    k.repeat_last[65] = ticks() - 60
    fired = k.key_hold_tick(65 as u8)
    if fired:
        k.push_key(65 as u8)
    check("fires again after interval expires", fired, true)
    check("repeat bypasses debounce", k.count == 2, true)

    # key_hold_end (the KEYUP call): disarms even with both timestamps
    # still expired -- no more fires until a fresh begin.
    k.key_hold_end(65 as u8)
    fired = k.key_hold_tick(65 as u8)
    check("ended hold never fires", fired, false)
    check("ended hold pushed nothing", k.count == 2, true)

    # Re-arm after end (fresh press edge): gates apply from scratch --
    # an immediate tick does not fire just because old timestamps expired.
    k.key_hold_begin(65 as u8)
    fired = k.key_hold_tick(65 as u8)
    check("re-armed hold starts a fresh initial delay", fired, false)

    # key_holds_clear (Reset/Load): kills an armed hold regardless of
    # timestamps; a still-held key stays silent until a fresh press edge.
    k.repeat_down_time[65] = ticks() - 400
    k.repeat_last[65] = ticks() - 400
    k.key_holds_clear()
    fired = k.key_hold_tick(65 as u8)
    check("cleared hold does not fire", fired, false)

    # The clear is wholesale: a second keyboard's independently armed and
    # expired hold is equally dead afterwards.
    let mut k2 = new_kbd()
    k2.key_hold_begin(66 as u8)
    k2.repeat_down_time[66] = ticks() - 400
    k2.repeat_last[66] = ticks() - 400
    k2.key_holds_clear()
    fired = k2.key_hold_tick(66 as u8)
    check("clear covers all codes", fired, false)

    # Per-code independence: one code's hold expiring and firing leaves
    # another code's fresh hold untouched (still inside its initial delay).
    let mut k3 = new_kbd()
    k3.key_hold_begin(65 as u8)
    delay(30)
    k3.key_hold_begin(66 as u8)
    k3.repeat_down_time[66] = ticks() - 300
    k3.repeat_last[66] = ticks() - 300
    fired = k3.key_hold_tick(66 as u8)
    if fired:
        k3.push_key(66 as u8)
    check("independent code fires on its own schedule", fired, true)
    fired = k3.key_hold_tick(65 as u8)
    check("other code's hold unaffected", fired, false)

    # Real-clock confirmation of the actual constants (no pokes): 300ms
    # real delay > the 280ms initial delay fires; an immediate re-tick is
    # held off by the interval; 60ms real delay > the 50ms interval fires
    # again. All three raw pushes land.
    let mut k4 = new_kbd()
    k4.key_hold_begin(65 as u8)
    delay(300)
    fired = k4.key_hold_tick(65 as u8)
    if fired:
        k4.push_key(65 as u8)
    check("real 300ms hold fires (initial delay 280ms)", fired, true)
    fired = k4.key_hold_tick(65 as u8)
    check("real-clock immediate re-tick held off", fired, false)
    delay(60)
    fired = k4.key_hold_tick(65 as u8)
    if fired:
        k4.push_key(65 as u8)
    check("real 60ms later fires again (interval 50ms)", fired, true)
    check("real-clock pushes all landed", k4.count == 2, true)
# Headless regression test for the Keyboard's time-window debounce
# (`keyboard.star::should_debounce_key`/`press_key`) -- see NOTES.md
# "Keyboard debounce: the reference's 35ms time window". Mirrors
# `nova_keyboard.py::should_debounce_key`'s contract, which `main.star`'s
# host poll loop now goes through (its `press_key` path) but injected keys
# deliberately do not (raw `push_key`). Like `mouse_interrupt_test.star`,
# this is a direct-field-poke harness: the debounce window can't be driven
# from a `.bin` (nothing a running Nova-16 program can execute reaches the
# host physical-press path), and the per-key timestamps are poked directly
# for the window-expiry case instead of sleeping out the full 35ms (one
# real `delay()` case is included anyway, as a smoke check that the real
# clock path -- `ticks()`/SDL_GetTicks -- moves the way the poke test
# assumes). SDL2 is transitively required by `cpu_sound.star` same as
# every other harness here, and `ticks()`/`delay()` are SDL builtins.
#
# Build: star build projects/nova/tests/keyboard_debounce_test.star
#   -L sdl/lib/x64 -l SDL2 -o projects/nova/tests/keyboard_debounce_test.exe
# Usage: keyboard_debounce_test.exe -- prints PASS/FAIL lines, no arguments.

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
    )

fn check(name: str, got: bool, expected: bool):
    if got == expected:
        println(f"PASS {name}")
    else:
        println(f"FAIL {name}: got {got}, expected {expected}")

fn main():
    # Let the ticks() clock get comfortably positive before any synthetic
    # timestamp poking: near process start ticks() is single-digit, so a poke
    # like `ticks() - 30` would go negative and collide with the -1 "never
    # pressed" sentinel (accepted unconditionally) instead of exercising the
    # window comparison. 100ms in, `ticks() - 36` is safely positive.
    delay(100)

    let mut k = new_kbd()

    # First press of a code is always accepted, and lands in the buffer
    # (35ms default window, like the reference's constructor default).
    k.press_key(65 as u8) # 'A'
    check("first press accepted into buffer", k.count == 1, true)

    # Immediate repeat of the same code inside the window: dropped as
    # bounce -- this is the whole point of the feature.
    k.press_key(65 as u8)
    check("same code inside window dropped", k.count == 1, true)

    # The window is per key: a different code inside the first key's window
    # is still accepted (the reference keys its dict by key name; this port
    # by Nova-16 key code -- 'A'=65 vs 'B'=66 are distinct keys either way).
    k.press_key(66 as u8) # 'B'
    check("different code inside window accepted", k.count == 2, true)

    # Window expiry, poked directly: rewinding 'A's timestamp past the
    # window makes the next 'A' press accepted again (deterministic -- the
    # elapsed time is measured from the poked value, not from wall time).
    let mut poked = ticks() - (keyboard::DEFAULT_DEBOUNCE_MS + 1)
    k.last_press[65] = poked
    k.press_key(65 as u8)
    check("same code after window expiry accepted", k.count == 3, true)

    # Press just inside the window: dropped, and -- the reference's key
    # no-refresh semantic -- the dropped press must NOT refresh the
    # timestamp, verified by reading the field straight back.
    poked = ticks() - (keyboard::DEFAULT_DEBOUNCE_MS - 5)
    k.last_press[65] = poked
    k.press_key(65 as u8)
    check("press just inside window dropped", k.count == 3, true)
    check("dropped press did not refresh timestamp", k.last_press[65] == poked, true)

    # Real-clock path (no pokes): after the window has genuinely elapsed,
    # the same key is accepted again -- 40ms delay against the 35ms window.
    delay(40)
    k.press_key(65 as u8)
    check("same code after real 40ms accepted", k.count == 4, true)

    # Fresh keyboard, real clock only: press, immediate repeat dropped,
    # wait out the window, accepted.
    let mut k2 = new_kbd()
    k2.press_key(65 as u8)
    k2.press_key(65 as u8)
    check("fresh kbd immediate repeat dropped", k2.count == 1, true)
    delay(40)
    k2.press_key(65 as u8)
    check("fresh kbd press after real 40ms accepted", k2.count == 2, true)

    # set_debounce_ms(0) disables debouncing entirely (reference's
    # `debounce_window_seconds <= 0 -> False` branch): rapid repeats all
    # land.
    let mut k3 = new_kbd()
    k3.set_debounce_ms(0)
    k3.press_key(65 as u8)
    k3.press_key(65 as u8)
    k3.press_key(65 as u8)
    check("debounce disabled accepts rapid repeats", k3.count == 3, true)

    # Negative windows clamp to 0 (reference's `max(0, debounce_ms)`), not
    # to some negative window whose `<= 0` check then silently behaves as 0
    # anyway -- clamping keeps the stored state itself sane.
    let mut k4 = new_kbd()
    k4.set_debounce_ms(-5)
    check("negative window clamps to 0", k4.debounce_ms == 0, true)

    # The raw injection path (`push_key`, the reference's `add_key`)
    # deliberately bypasses debounce: injected keys -- uart_bridge tooling,
    # headless tests -- must never be dropped for timing reasons, exactly
    # like the reference's own `type_string`/`KeyboardSimulator` paths.
    let mut k5 = new_kbd()
    k5.push_key(65 as u8)
    k5.push_key(65 as u8)
    k5.push_key(65 as u8)
    check("raw push_key bypasses debounce", k5.count == 3, true)

    # Clearing the buffer (`keyclear`) does not disarm debounce -- matching
    # the reference's `clear_buffer`, which leaves `_last_key_press_time`
    # alone (a cleared buffer is not a fresh keyboard; bounce protection
    # survives it). Arm via a real accepted press, clear, then an immediate
    # repeat must still be dropped, leaving the buffer empty.
    let mut k6 = new_kbd()
    k6.press_key(65 as u8)
    check("keyclear setup: armed press accepted", k6.count == 1, true)
    k6.keyclear()
    check("keyclear empties buffer", k6.count == 0, true)
    k6.press_key(65 as u8)
    check("keyclear leaves debounce state armed", k6.count == 0, true)
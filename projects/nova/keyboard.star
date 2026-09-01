# Nova-16 keyboard subsystem (docs/Keyboard Implementation.md, cross-checked
# against the upstream reference's current behavior -- the doc's own opcode
# numbers and buffer size are stale, see NOTES.md "Doc-vs-code discrepancies").
# Not memory-mapped: the 4 internal registers (Data/Status/Control/Count) are
# reachable only through 5 dedicated opcodes (KEYIN/KEYSTAT/KEYCOUNT/
# KEYCLEAR/KEYCTRL). A 64-slot FIFO ring buffer, matching the live
# implementation (not the doc's stated 16).
#
# Status bits: 0 = key available, 1 = buffer full, 7 = interrupt pending
# (mirrors control bit 0's IRQ-enable, and only ever gets set alongside it).
# Control bits: 0 = IRQ enable.
#
# Physical keys also carry the reference's time-window debounce
# (`nova_keyboard.py`'s 35ms `should_debounce_key`, applied on the host
# physical-press path only -- injected keys bypass it, same as the
# reference's own type_string/simulator paths). See `press_key` below.

const BUFFER_SIZE: i32 = 64

# Physical-key debounce window, matching `nova_keyboard.py`'s
# `debounce_ms: int = 35` constructor default exactly (see
# `should_debounce_key` below for the semantics this buys).
const DEFAULT_DEBOUNCE_MS: i32 = 35

struct Keyboard:
    mut buffer: [u8; 64]
    mut head: i32
    mut tail: i32
    mut count: i32
    mut status: u8
    mut control: u8
    mut debounce_ms: i32
    # Last-accepted-press timestamp (ticks() ms) per Nova-16 key code; -1 =
    # never pressed. The reference keys its dict by key name; key code is
    # this port's equivalent per-key identity.
    mut last_press: [i32; 256]

impl Keyboard:
    fn irq_enabled(self) -> bool:
        bit_get(self.control, 0)

    fn refresh_status(mut self):
        if self.count > 0:
            self.status = bit_set(self.status, 0)
        else:
            self.status = bit_clear(self.status, 0)
        if self.count >= BUFFER_SIZE:
            self.status = bit_set(self.status, 1)
        else:
            self.status = bit_clear(self.status, 1)
        if self.count > 0 and self.irq_enabled():
            self.status = bit_set(self.status, 7)
        else:
            self.status = bit_clear(self.status, 7)

    # Called by the host (key press event) -- silently drops the key if the
    # buffer is already full, matching the upstream reference.
    fn push_key(mut self, code: u8):
        if self.count < BUFFER_SIZE:
            self.buffer[self.tail] = code
            self.tail = (self.tail + 1) % BUFFER_SIZE
            self.count += 1
        self.refresh_status()

    # KEYIN: pop the oldest key. Returns (value, had_key) -- the caller (Cpu)
    # sets the Zero flag from `had_key` per the CPU spec ("Z=1 if no key").
    fn pop_key(mut self) -> (u8, bool):
        if self.count <= 0:
            (0 as u8, false)
        else:
            let v = self.buffer[self.head]
            self.head = (self.head + 1) % BUFFER_SIZE
            self.count -= 1
            self.refresh_status()
            (v, true)

    fn keystat(self) -> u8:
        self.status

    fn keycount(self) -> u8:
        self.count as u8

    fn keyclear(mut self):
        self.head = 0
        self.tail = 0
        self.count = 0
        self.status = 0 as u8

    fn keyctrl(mut self, val: u8):
        self.control = val
        self.refresh_status()

    # Time-window debounce, mirroring `nova_keyboard.py::should_debounce_key`
    # (the reference's GUI passes every physical KEYDOWN through
    # `press_key(..., apply_debounce=True)` with a 35ms window): a press of a
    # key whose previous *accepted* press is still inside the window is
    # dropped as contact bounce. Exactly like the reference, a *dropped*
    # press does not refresh its timestamp -- the window always measures from
    # the last accepted press, so sustained bounce can't pin a key shut. The
    # plain `now - last` subtraction is wrap-safe for any real gap under
    # 2^31 ms (ticks() is SDL_GetTicks milliseconds on an i32). The `last >= 0`
    # guard is the -1 "never pressed" sentinel; stored timestamps only ever
    # come from real accepted presses, which are non-negative until ticks()'s
    # i32 view of SDL_GetTicks goes negative at ~24.8 days of uptime -- the
    # same regime where ticks() is already broken for any i32 consumer (see
    # `crate::codegen::sdl`'s wrap note), so the guard simply reads as
    # "debounce off" there rather than misbehaving.
    fn should_debounce_key(mut self, code: u8) -> bool:
        if self.debounce_ms <= 0:
            return false
        let now = ticks()
        let last = self.last_press[code as i32]
        let elapsed = now - last
        if last >= 0 and elapsed >= 0 and elapsed < self.debounce_ms:
            return true
        self.last_press[code as i32] = now
        return false

    # The host's physical-key entry point (main.star's per-frame poll loop),
    # standing in for the reference's `press_key(..., apply_debounce=True)`
    # path. Deliberately a separate method from `push_key` (the reference's
    # `add_key`): injected keys -- headless test harnesses, any future host
    # tooling that must not lose bytes to timing -- keep calling `push_key`
    # directly and bypass debounce exactly like the reference's own
    # `type_string`/`KeyboardSimulator` paths.
    fn press_key(mut self, code: u8):
        if self.should_debounce_key(code):
            return
        self.push_key(code)

    # `set_debounce_window_ms` counterpart; negatives clamp to 0 (debounce
    # fully off) the way the reference's own `max(0, debounce_ms)` does.
    fn set_debounce_ms(mut self, ms: i32):
        if ms < 0:
            self.debounce_ms = 0
        else:
            self.debounce_ms = ms

    fn irq_pending(self) -> bool:
        bit_get(self.status, 7)

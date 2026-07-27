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

const BUFFER_SIZE: i32 = 64

struct Keyboard:
    mut buffer: [u8; 64]
    mut head: i32
    mut tail: i32
    mut count: i32
    mut status: u8
    mut control: u8

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

    fn irq_pending(self) -> bool:
        bit_get(self.status, 7)

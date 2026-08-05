# Bit-level shift/rotate helpers for the Nova-16 CPU's dynamic-shift-amount
# instructions (SHL/SHR/SAR/SAL/ROL/ROR/RCL/RCR, where the amount is a
# runtime operand that can be any 0-255 value, not a fixed constant). Star
# gained real `<<`/`>>`/`&`/`|`/`^`/`~` operators after this file was written
# (see NOTES.md "Language gotchas" / todo.md P0 #3), and every *fixed*-amount
# shift/combine elsewhere in this project (byte-half register packing,
# `SWAP`'s nibble swap, `read_word`/`write_word`) was switched over to them
# directly -- safe there because the amount is always a compile-time literal
# already in range. This file's functions stay hand-rolled because their
# amount-clamping semantics are Nova-specific and deliberately differ from
# the new operators' behavior: `<<`/`>>` mask the shift count mod the
# operand's width (so shifting a `u8` by 8 is a no-op, matching x86 hardware
# masking), while Nova-16's ISA -- ported from `core/exec.py` -- clamps
# instead: a shift amount >= the operand's width zeroes the result entirely
# (or fills with the sign bit for `SAR`/`SAL`), not "shift by amount mod
# width". Replacing these with the native operators would silently change
# behavior for any program that shifts by >= 8 (or >= 16), so the bit-by-bit
# construction from `bit_get`/`bit_set` stays.
#
# Multiply/divide-by-power-of-two was considered and rejected for the
# arithmetic-shift-right case: dividing a negative `Wrapping<iN>` truncates
# toward zero, not toward -infinity, so `-1 >> 1` (expected: -1, sign bit
# copies down) would wrongly come out as 0. Building every shift from
# `bit_get`/`bit_set` sidesteps that and stays correct regardless of
# signedness, at the cost of being O(width) instead of O(1) -- fine for an
# 8/16-bit machine.
#
# Every hand-rolled `while i = <n>; while i </>= <bound>: ...; i +/-= 1` bit
# index loop in this file was later switched to a real `for` loop -- the
# descending ones (`shl8`/`shl16`/`clz8`/`clz16`, walking MSB-to-LSB) use the
# inclusive/stepped range form (`for i in 7..=0 step -1:`) Star gained after
# this file was written, since a plain `for i in 0..8:` can't count downward
# on its own. Purely a loop-header rewrite -- no bit-index math changed.

fn shl8(x: u8, n: i32) -> u8:
    let mut amt = n
    if amt < 0:
        amt = 0
    if amt >= 8:
        0 as u8
    else:
        let mut result: u8 = 0 as u8
        for i in 7..=0 step -1:
            let src = i - amt
            if src >= 0:
                if bit_get(x, src):
                    result = bit_set(result, i)
        result

fn shr8(x: u8, n: i32) -> u8:
    let mut amt = n
    if amt < 0:
        amt = 0
    if amt >= 8:
        0 as u8
    else:
        let mut result: u8 = 0 as u8
        for i in 0..8:
            let src = i + amt
            if src < 8:
                if bit_get(x, src):
                    result = bit_set(result, i)
        result

# Arithmetic shift right: vacated high bits copy the sign bit (bit 7)
# instead of filling with zero.
fn sar8(x: u8, n: i32) -> u8:
    let mut amt = n
    if amt < 0:
        amt = 0
    let sign = bit_get(x, 7)
    if amt >= 8:
        if sign:
            255 as u8
        else:
            0 as u8
    else:
        let mut result: u8 = 0 as u8
        for i in 0..8:
            let src = i + amt
            if src < 8:
                if bit_get(x, src):
                    result = bit_set(result, i)
            else:
                if sign:
                    result = bit_set(result, i)
        result

fn rol8(x: u8, n: i32) -> u8:
    let mut amt = n % 8
    if amt < 0:
        amt += 8
    let mut result: u8 = 0 as u8
    for i in 0..8:
        let src = (i - amt + 8) % 8
        if bit_get(x, src):
            result = bit_set(result, i)
    result

fn ror8(x: u8, n: i32) -> u8:
    let mut amt = n % 8
    if amt < 0:
        amt += 8
    rol8(x, 8 - amt)

fn shl16(x: u16, n: i32) -> u16:
    let mut amt = n
    if amt < 0:
        amt = 0
    if amt >= 16:
        0 as u16
    else:
        let mut result: u16 = 0 as u16
        for i in 15..=0 step -1:
            let src = i - amt
            if src >= 0:
                if bit_get(x, src):
                    result = bit_set(result, i)
        result

fn shr16(x: u16, n: i32) -> u16:
    let mut amt = n
    if amt < 0:
        amt = 0
    if amt >= 16:
        0 as u16
    else:
        let mut result: u16 = 0 as u16
        for i in 0..16:
            let src = i + amt
            if src < 16:
                if bit_get(x, src):
                    result = bit_set(result, i)
        result

fn sar16(x: u16, n: i32) -> u16:
    let mut amt = n
    if amt < 0:
        amt = 0
    let sign = bit_get(x, 15)
    if amt >= 16:
        if sign:
            65_535 as u16
        else:
            0 as u16
    else:
        let mut result: u16 = 0 as u16
        for i in 0..16:
            let src = i + amt
            if src < 16:
                if bit_get(x, src):
                    result = bit_set(result, i)
            else:
                if sign:
                    result = bit_set(result, i)
        result

fn rol16(x: u16, n: i32) -> u16:
    let mut amt = n % 16
    if amt < 0:
        amt += 16
    let mut result: u16 = 0 as u16
    for i in 0..16:
        let src = (i - amt + 16) % 16
        if bit_get(x, src):
            result = bit_set(result, i)
    result

fn ror16(x: u16, n: i32) -> u16:
    let mut amt = n % 16
    if amt < 0:
        amt += 16
    rol16(x, 16 - amt)

# Rotate-through-carry: the carry flag participates as one extra bit in the
# rotation, and comes back out as the new carry (returned as `.1`).
fn rcl8(x: u8, carry_in: bool, n: i32) -> (u8, bool):
    let mut val = x
    let mut carry = carry_in
    let mut amt = n % 9
    if amt < 0:
        amt += 9
    for i in 0..amt:
        let msb = bit_get(val, 7)
        val = shl8(val, 1)
        if carry:
            val = bit_set(val, 0)
        carry = msb
    (val, carry)

fn rcr8(x: u8, carry_in: bool, n: i32) -> (u8, bool):
    let mut val = x
    let mut carry = carry_in
    let mut amt = n % 9
    if amt < 0:
        amt += 9
    for i in 0..amt:
        let lsb = bit_get(val, 0)
        val = shr8(val, 1)
        if carry:
            val = bit_set(val, 7)
        carry = lsb
    (val, carry)

fn rcl16(x: u16, carry_in: bool, n: i32) -> (u16, bool):
    let mut val = x
    let mut carry = carry_in
    let mut amt = n % 17
    if amt < 0:
        amt += 17
    for i in 0..amt:
        let msb = bit_get(val, 15)
        val = shl16(val, 1)
        if carry:
            val = bit_set(val, 0)
        carry = msb
    (val, carry)

fn rcr16(x: u16, carry_in: bool, n: i32) -> (u16, bool):
    let mut val = x
    let mut carry = carry_in
    let mut amt = n % 17
    if amt < 0:
        amt += 17
    for i in 0..amt:
        let lsb = bit_get(val, 0)
        val = shr16(val, 1)
        if carry:
            val = bit_set(val, 15)
        carry = lsb
    (val, carry)

fn popcount8(x: u8) -> i32:
    let mut count = 0
    for i in 0..8:
        if bit_get(x, i):
            count += 1
    count

fn popcount16(x: u16) -> i32:
    let mut count = 0
    for i in 0..16:
        if bit_get(x, i):
            count += 1
    count

# Even parity of the low byte of a result, per the CPU spec's P flag.
fn parity8(x: u8) -> bool:
    popcount8(x) % 2 == 0

fn clz8(x: u8) -> i32:
    let mut count = 0
    let mut done = false
    for i in 7..=0 step -1:
        if !done:
            if bit_get(x, i):
                done = true
            else:
                count += 1
    count

fn clz16(x: u16) -> i32:
    let mut count = 0
    let mut done = false
    for i in 15..=0 step -1:
        if !done:
            if bit_get(x, i):
                done = true
            else:
                count += 1
    count

fn ctz8(x: u8) -> i32:
    let mut count = 0
    let mut done = false
    for i in 0..8:
        if !done:
            if bit_get(x, i):
                done = true
            else:
                count += 1
    count

fn ctz16(x: u16) -> i32:
    let mut count = 0
    let mut done = false
    for i in 0..16:
        if !done:
            if bit_get(x, i):
                done = true
            else:
                count += 1
    count

# Sign-extend an 8-bit two's-complement offset byte (used by register- and
# direct-indexed addressing) to a plain i32 for address arithmetic.
fn sign_extend8(x: u8) -> i32:
    let v = x as i32
    if v >= 128:
        v - 256
    else:
        v

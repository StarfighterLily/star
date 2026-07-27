# Bit-level helpers the Nova-16 CPU needs that the language doesn't provide
# as operators: there is no `<<`/`>>`/`&`/`|`/`^`/`~` in Star at all (see
# NOTES.md "No bitwise shift operators") -- only the free-function surface
# `bit_get`/`bit_set`/`bit_clear`/`bit_toggle`/`bit_and`/`bit_or`/`bit_xor`/
# `bit_not`, which read/flip *one* bit or combine two whole registers, with
# no general "shift a value left/right by N" primitive. Every shift/rotate
# instruction (SHL/SHR/SAR/SAL/ROL/ROR/RCL/RCR) is therefore built here,
# bit-by-bit, once per width, rather than assumed available.
#
# Multiply/divide-by-power-of-two was considered and rejected for the
# arithmetic-shift-right case: dividing a negative `Wrapping<iN>` truncates
# toward zero, not toward -infinity, so `-1 >> 1` (expected: -1, sign bit
# copies down) would wrongly come out as 0. Building every shift from
# `bit_get`/`bit_set` sidesteps that and stays correct regardless of
# signedness, at the cost of being O(width) instead of O(1) -- fine for an
# 8/16-bit machine.

fn shl8(x: u8, n: i32) -> u8:
    let mut amt = n
    if amt < 0:
        amt = 0
    if amt >= 8:
        0 as u8
    else:
        let mut result: u8 = 0 as u8
        let mut i = 7
        while i >= 0:
            let src = i - amt
            if src >= 0:
                if bit_get(x, src):
                    result = bit_set(result, i)
            i -= 1
        result

fn shr8(x: u8, n: i32) -> u8:
    let mut amt = n
    if amt < 0:
        amt = 0
    if amt >= 8:
        0 as u8
    else:
        let mut result: u8 = 0 as u8
        let mut i = 0
        while i < 8:
            let src = i + amt
            if src < 8:
                if bit_get(x, src):
                    result = bit_set(result, i)
            i += 1
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
        let mut i = 0
        while i < 8:
            let src = i + amt
            if src < 8:
                if bit_get(x, src):
                    result = bit_set(result, i)
            else:
                if sign:
                    result = bit_set(result, i)
            i += 1
        result

fn rol8(x: u8, n: i32) -> u8:
    let mut amt = n % 8
    if amt < 0:
        amt += 8
    let mut result: u8 = 0 as u8
    let mut i = 0
    while i < 8:
        let src = (i - amt + 8) % 8
        if bit_get(x, src):
            result = bit_set(result, i)
        i += 1
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
        let mut i = 15
        while i >= 0:
            let src = i - amt
            if src >= 0:
                if bit_get(x, src):
                    result = bit_set(result, i)
            i -= 1
        result

fn shr16(x: u16, n: i32) -> u16:
    let mut amt = n
    if amt < 0:
        amt = 0
    if amt >= 16:
        0 as u16
    else:
        let mut result: u16 = 0 as u16
        let mut i = 0
        while i < 16:
            let src = i + amt
            if src < 16:
                if bit_get(x, src):
                    result = bit_set(result, i)
            i += 1
        result

fn sar16(x: u16, n: i32) -> u16:
    let mut amt = n
    if amt < 0:
        amt = 0
    let sign = bit_get(x, 15)
    if amt >= 16:
        if sign:
            65535 as u16
        else:
            0 as u16
    else:
        let mut result: u16 = 0 as u16
        let mut i = 0
        while i < 16:
            let src = i + amt
            if src < 16:
                if bit_get(x, src):
                    result = bit_set(result, i)
            else:
                if sign:
                    result = bit_set(result, i)
            i += 1
        result

fn rol16(x: u16, n: i32) -> u16:
    let mut amt = n % 16
    if amt < 0:
        amt += 16
    let mut result: u16 = 0 as u16
    let mut i = 0
    while i < 16:
        let src = (i - amt + 16) % 16
        if bit_get(x, src):
            result = bit_set(result, i)
        i += 1
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
    let mut i = 0
    while i < amt:
        let msb = bit_get(val, 7)
        val = shl8(val, 1)
        if carry:
            val = bit_set(val, 0)
        carry = msb
        i += 1
    (val, carry)

fn rcr8(x: u8, carry_in: bool, n: i32) -> (u8, bool):
    let mut val = x
    let mut carry = carry_in
    let mut amt = n % 9
    if amt < 0:
        amt += 9
    let mut i = 0
    while i < amt:
        let lsb = bit_get(val, 0)
        val = shr8(val, 1)
        if carry:
            val = bit_set(val, 7)
        carry = lsb
        i += 1
    (val, carry)

fn rcl16(x: u16, carry_in: bool, n: i32) -> (u16, bool):
    let mut val = x
    let mut carry = carry_in
    let mut amt = n % 17
    if amt < 0:
        amt += 17
    let mut i = 0
    while i < amt:
        let msb = bit_get(val, 15)
        val = shl16(val, 1)
        if carry:
            val = bit_set(val, 0)
        carry = msb
        i += 1
    (val, carry)

fn rcr16(x: u16, carry_in: bool, n: i32) -> (u16, bool):
    let mut val = x
    let mut carry = carry_in
    let mut amt = n % 17
    if amt < 0:
        amt += 17
    let mut i = 0
    while i < amt:
        let lsb = bit_get(val, 0)
        val = shr16(val, 1)
        if carry:
            val = bit_set(val, 15)
        carry = lsb
        i += 1
    (val, carry)

fn popcount8(x: u8) -> i32:
    let mut count = 0
    let mut i = 0
    while i < 8:
        if bit_get(x, i):
            count += 1
        i += 1
    count

fn popcount16(x: u16) -> i32:
    let mut count = 0
    let mut i = 0
    while i < 16:
        if bit_get(x, i):
            count += 1
        i += 1
    count

# Even parity of the low byte of a result, per the CPU spec's P flag.
fn parity8(x: u8) -> bool:
    popcount8(x) % 2 == 0

fn clz8(x: u8) -> i32:
    let mut i = 7
    let mut count = 0
    let mut done = false
    while i >= 0:
        if !done:
            if bit_get(x, i):
                done = true
            else:
                count += 1
        i -= 1
    count

fn clz16(x: u16) -> i32:
    let mut i = 15
    let mut count = 0
    let mut done = false
    while i >= 0:
        if !done:
            if bit_get(x, i):
                done = true
            else:
                count += 1
        i -= 1
    count

fn ctz8(x: u8) -> i32:
    let mut i = 0
    let mut count = 0
    let mut done = false
    while i < 8:
        if !done:
            if bit_get(x, i):
                done = true
            else:
                count += 1
        i += 1
    count

fn ctz16(x: u16) -> i32:
    let mut i = 0
    let mut count = 0
    let mut done = false
    while i < 16:
        if !done:
            if bit_get(x, i):
                done = true
            else:
                count += 1
        i += 1
    count

# Sign-extend an 8-bit two's-complement offset byte (used by register- and
# direct-indexed addressing) to a plain i32 for address arithmetic.
fn sign_extend8(x: u8) -> i32:
    let v = x as i32
    if v >= 128:
        v - 256
    else:
        v

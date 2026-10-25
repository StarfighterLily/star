# The `~xx` printable form telnet bytes cross LPC strings and test
# transcripts in -- todo.md HavokOS M6: printable ASCII as itself, any other
# byte (and `~`) as `~xx`, two lower-case hex digits. Used by the case
# runner's test_tel_* hooks (efuns_net.star) and the scripted client
# (tools/telnet_script.star); tools/ref_cases.pike has the same two
# functions for the reference.

fn hexd(c: i32) -> i32:
    if c >= 48 and c <= 57:
        return c - 48
    if c >= 97 and c <= 102:
        return c - 87
    if c >= 65 and c <= 70:
        return c - 55
    -1

# The hooks' printable form, both ways.
fn tel_decode(s: str) -> Bytes:
    let b = bytes_from_str(s)
    let mut o: Bytes = Bytes()
    let mut i = 0
    while i < b.len():
        let c = b[i] as i32
        if c == 126 and i + 2 < b.len() and hexd(b[i + 1] as i32) >= 0 and hexd(b[i + 2] as i32) >= 0:
            o.push((hexd(b[i + 1] as i32) * 16 + hexd(b[i + 2] as i32)) as u8)
            i += 3
        else:
            o.push(b[i])
            i += 1
    o

fn tel_encode(b: Bytes) -> str:
    let digits = bytes_from_str("0123456789abcdef")
    let mut o: Bytes = Bytes()
    for i in 0..b.len():
        let c = b[i] as i32
        if c >= 32 and c < 127 and c != 126:
            o.push(b[i])
        else:
            o.push(126 as u8)
            o.push(digits[c / 16])
            o.push(digits[c % 16])
    str_from_bytes(o)

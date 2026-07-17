# Demonstrates `Bytes` (docs/design.md's "Text and bytes" section): an
# owned, growable byte buffer distinct from `str` -- for asset formats,
# binary save data, and network payloads that aren't text. Reuses `List<u8>`'s
# exact layout/method surface under the hood (`push`/`pop`/`len`/`[i]`), but
# is a nominally distinct type constructed as a plain `Bytes()` literal.

fn main():
    let mut buf = Bytes()
    print(f"empty buf.len() = {buf.len()}")

    buf.push(72 as u8)
    buf.push(73 as u8)
    buf.push(33 as u8)
    print(f"after 3 pushes, len = {buf.len()}")
    print(f"buf[0] = {buf[0]}, buf[1] = {buf[1]}, buf[2] = {buf[2]}")

    buf[0] = 104 as u8
    print(f"after buf[0] = 104, buf[0] = {buf[0]}")

    let popped = buf.pop()
    print(f"popped = {popped}, len now = {buf.len()}")

    # Out-of-bounds reads/pushes-past-cap are safe (zero-value/no-op),
    # mirroring `List<T>`'s own convention.
    let mut empty = Bytes()
    print(f"empty.pop() = {empty.pop()}")
    print(f"empty[0] = {empty[0]}")

    # `bytes_from_str`/`str_from_bytes`: round-trip through `str`.
    let from_str = bytes_from_str("Hello")
    print(f"bytes_from_str(\"Hello\").len() = {from_str.len()}")
    print(f"bytes_from_str(\"Hello\")[0] = {from_str[0]}")
    let back = str_from_bytes(from_str)
    print(f"round-trip: {back}")

    # Mutating one binding never affects another (copy-on-write, matching
    # `List<T>`).
    let mut a = bytes_from_str("ab")
    let b = a
    a.push(99 as u8)
    print(f"a.len() = {a.len()}, b.len() = {b.len()}")

    # An empty `str` round-trips to an empty `Bytes`.
    let empty_bytes = bytes_from_str("")
    print(f"bytes_from_str(\"\").len() = {empty_bytes.len()}")
    print(f"str_from_bytes(empty) = \"{str_from_bytes(empty_bytes)}\"")

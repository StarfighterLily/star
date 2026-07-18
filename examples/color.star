# Demonstrates docs/design.md's "Math and geometry" section's `Color`/
# `Color32`: `f32`-per-channel linear HDR color for AAA lighting pipelines,
# and packed 8-bit-per-channel color for indie/retro-scale rendering.

fn main():
    # `Color` reuses `Vec4`'s exact layout: field access accepts both
    # `.r/.g/.b/.a` and `.x/.y/.z/.w`, and `+`/`-`/scalar `*`/`/` (additive/
    # multiplicative blending) work for free.
    let orange = Color(1.0, 0.5, 0.0, 1.0)
    println(f"orange channels: {orange.r}, {orange.g}, {orange.b}, {orange.a}")

    let dimmed = orange * 0.5
    println(f"dimmed red channel: {dimmed.r}")

    let blended = orange + Color(0.0, 0.0, 1.0, 0.0)
    println(f"blended blue channel: {blended.b}")

    # Packing down to 8-bit-per-channel for indie/retro storage.
    let packed = color_to_color32(orange)
    println(f"packed r: {color32_r(packed)}")
    println(f"packed g: {color32_g(packed)}")
    println(f"packed b: {color32_b(packed)}")
    println(f"packed a: {color32_a(packed)}")

    # Constructing a `Color32` directly from raw 0-255 channel values.
    let raw = Color32(255, 128, 64, 255)
    println(f"raw g: {color32_g(raw)}")

    # Round-tripping back to `Color`.
    let restored = color32_to_color(raw)
    println(f"restored r: {restored.r}")

    println(f"packed == packed is {packed == Color32(255, 127, 0, 255)}")

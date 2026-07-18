# Demonstrates docs/design.md's "Math and geometry" section's
# `PaletteIndex`/`Palette`: indexed color, for faithful retro console
# emulation (e.g. an NES/Game Boy-style hardware palette), complementing
# `Color32`'s packed direct-color format.

fn main():
    let mut pal: Palette = Palette()
    pal.push(Color32(255, 0, 0, 255))
    pal.push(Color32(0, 255, 0, 255))
    pal.push(Color32(0, 0, 255, 255))
    println(f"palette len: {pal.len()}")

    let idx: PaletteIndex = PaletteIndex(1)
    # `pal[i]` -- like `List<T>`, requires a plain `i32` index; a
    # `PaletteIndex` only casts directly to/from `u8` (see `Ty::PaletteIndex`'s
    # doc comment), so bridging into an index needs one more ordinary
    # numeric `as` on top of that.
    let entry = pal[(idx as u8) as i32]
    println(f"palette[1] g channel: {color32_g(entry)}")

    # `PaletteIndex <-> u8` is a free bit-preserving relabel via `as`.
    let raw: u8 = idx as u8
    println(f"index as u8: {raw}")
    let back: PaletteIndex = raw as PaletteIndex
    println(f"index round-trip == original: {back == idx}")

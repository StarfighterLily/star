# Nova-16's fixed 256-color indexed palette: sixteen 16-shade ramps
# (grayscale, then fourteen named hues, docs/VRAM Specification.md "Color
# Palette Organization"). Ported directly from the upstream reference's
# `nova/graphics/gfx.py::set_color_palette` -- same float formula per ramp,
# not an approximation -- since the exact RGB values are part of what a
# program running on this machine can observe (SREAD/VREAD hand back
# palette indices, but anything drawn to the host window necessarily goes
# through this table).

fn ramp_val(i: u8, base: i32) -> f32:
    let offset = (i as i32) - base
    ((offset as f32) * 255.0) / 15.0

fn palette_color(index: u8) -> (u8, u8, u8):
    let i = index as i32
    match i:
        <= 15 ->
            let v = ramp_val(index, 0)
            let c = v as u8
            (c, c, c)
        <= 31 ->
            let v = ramp_val(index, 16)
            (v as u8, 0 as u8, 0 as u8)
        <= 47 ->
            let v = ramp_val(index, 32)
            (0 as u8, v as u8, 0 as u8)
        <= 63 ->
            let v = ramp_val(index, 48)
            (0 as u8, 0 as u8, v as u8)
        <= 79 ->
            let v = ramp_val(index, 64)
            let c = v as u8
            (c, c, 0 as u8)
        <= 95 ->
            let v = ramp_val(index, 80)
            let c = v as u8
            (c, 0 as u8, c)
        <= 111 ->
            let v = ramp_val(index, 96)
            let c = v as u8
            (0 as u8, c, c)
        <= 127 ->
            let v = ramp_val(index, 112)
            (v as u8, (v * 0.5) as u8, 0 as u8)
        <= 143 ->
            let v = ramp_val(index, 128)
            ((v * 0.5) as u8, 0 as u8, v as u8)
        <= 159 ->
            let v = ramp_val(index, 144)
            ((v * 0.5) as u8, v as u8, 0 as u8)
        <= 175 ->
            let v = ramp_val(index, 160)
            (v as u8, (v * 0.5) as u8, (v * 0.5) as u8)
        <= 191 ->
            let v = ramp_val(index, 176)
            (0 as u8, (v * 0.5) as u8, (v * 0.5) as u8)
        <= 207 ->
            let v = ramp_val(index, 192)
            ((v * 0.6) as u8, (v * 0.3) as u8, 0 as u8)
        <= 223 ->
            let v = ramp_val(index, 208)
            ((v * 0.5) as u8, (v * 0.5) as u8, v as u8)
        <= 239 ->
            let v = ramp_val(index, 224)
            ((v * 0.5) as u8, v as u8, (v * 0.5) as u8)
        _ ->
            let v = ramp_val(index, 240)
            (v as u8, (v * 0.5) as u8, (v * 0.5) as u8)

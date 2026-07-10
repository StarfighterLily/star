# Regression check for the frame bump-allocator capacity bounds check
# (LANGUAGE_ANALYSIS.md §3.1): `@frame.buf` is a fixed 4096-byte global, and
# a `frame:` block that allocates more than that must abort loudly with a
# diagnostic message instead of segfaulting or silently corrupting whatever
# global data happens to sit right after the buffer. 70 `Mat4` fields (64
# bytes each) is 4480 bytes -- comfortably past the 4096-byte capacity in a
# single allocation.
struct Big:
    m0: Mat4
    m1: Mat4
    m2: Mat4
    m3: Mat4
    m4: Mat4
    m5: Mat4
    m6: Mat4
    m7: Mat4
    m8: Mat4
    m9: Mat4
    m10: Mat4
    m11: Mat4
    m12: Mat4
    m13: Mat4
    m14: Mat4
    m15: Mat4
    m16: Mat4
    m17: Mat4
    m18: Mat4
    m19: Mat4
    m20: Mat4
    m21: Mat4
    m22: Mat4
    m23: Mat4
    m24: Mat4
    m25: Mat4
    m26: Mat4
    m27: Mat4
    m28: Mat4
    m29: Mat4
    m30: Mat4
    m31: Mat4
    m32: Mat4
    m33: Mat4
    m34: Mat4
    m35: Mat4
    m36: Mat4
    m37: Mat4
    m38: Mat4
    m39: Mat4
    m40: Mat4
    m41: Mat4
    m42: Mat4
    m43: Mat4
    m44: Mat4
    m45: Mat4
    m46: Mat4
    m47: Mat4
    m48: Mat4
    m49: Mat4
    m50: Mat4
    m51: Mat4
    m52: Mat4
    m53: Mat4
    m54: Mat4
    m55: Mat4
    m56: Mat4
    m57: Mat4
    m58: Mat4
    m59: Mat4
    m60: Mat4
    m61: Mat4
    m62: Mat4
    m63: Mat4
    m64: Mat4
    m65: Mat4
    m66: Mat4
    m67: Mat4
    m68: Mat4
    m69: Mat4

fn identity() -> Mat4:
    Mat4(Vec4(1, 0, 0, 0), Vec4(0, 1, 0, 0), Vec4(0, 0, 1, 0), Vec4(0, 0, 0, 1))

fn main():
    frame:
        let m = Big(identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity(), identity())
        print("should not reach here: frame allocator did not abort on overflow")

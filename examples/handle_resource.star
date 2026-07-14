# Demonstrates `Handle<T>` (design.md's "Resource handles" section): the
# exact same generation-checked slot-map safety `GenRef<T>` gives arena
# entities, reused for engine resources instead. A `Handle<Texture>`
# dereferenced after its texture is unloaded falls back to the element
# type's zero value instead of returning stale data or segfaulting the
# renderer, just like `GenRef` does for despawned entities.

struct Texture:
    width: i32
    height: i32

arena Textures: Texture

fn main():
    spawn Textures(256, 256)
    let tex = Handle<Texture>(0)
    let before = tex[0]
    print(f"before unload: {before.width}x{before.height}")
    despawn Textures[0]
    let after = tex[0]
    print(f"after unload: {after.width}x{after.height}")

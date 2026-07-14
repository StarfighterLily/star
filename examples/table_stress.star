# Stress test for `Table<T>`'s growth/copy-on-write column-realloc path (see
# `crate::codegen::table`'s module doc comment): several thousand pushes of a
# struct with a `str` field, forcing many capacity doublings -- each one
# exercises `TableMethod::Push`'s "grow" branch (`malloc` a bigger column,
# `memcpy` the live prefix in, `free` the old buffer) for every column,
# including the `str` one. A leaked or double-freed column buffer, or a
# corrupted `str` pointer surviving a `memcpy`-based grow, would either leak
# unboundedly, crash, or read back garbled text; see
# `runtime_table_stress_end_to_end` in tests/frontend.rs.
#
# Iteration counts here are deliberately modest (thousands, not tens of
# thousands): constructing a struct literal (`Item(...)`) directly inside a
# `while` loop repeats an unhoisted `alloca` every iteration, and this
# compiler's LLVM emission relies entirely on `clang -O2`'s `mem2reg` to
# clean that up after the fact (see `examples/rc_stress.star`'s doc comment
# for the same characteristic with a `let`) -- past roughly 40-50k
# iterations of a struct literal built this way, that stops happening in
# practice and the native stack overflows. That threshold reproduces
# identically with a plain `List<Item>`, so it's a pre-existing, general
# codegen gap, not anything specific to `Table<T>`; this test stays well
# under it so it actually exercises the column-realloc/CoW logic it's meant
# to, instead of flaking on an unrelated stack limit.
struct Item:
    mut hp: i32
    tag: str

fn main():
    let mut t: Table<Item> = Table<Item>()
    let mut i = 0
    while i < 5000:
        t.push(Item(hp = i, tag = f"tag-{i}"))
        i += 1
    println(f"len = {t.len()}")
    println(f"t[0] = {t[0].tag} hp={t[0].hp}")
    println(f"t[4999] = {t[4999].tag} hp={t[4999].hp}")

    # Copy-on-write under the same growth pressure: clone late (after
    # several doublings), keep pushing into both -- the two must diverge in
    # length but never in shared content, and the clone's later pushes must
    # never observably mutate the original's already-CoW'd columns.
    let mut clone = t
    let mut k = 0
    while k < 5000:
        clone.push(Item(hp = k, tag = f"clone-{k}"))
        k += 1
    println(f"original len = {t.len()} clone len = {clone.len()}")
    println(f"original[0] = {t[0].tag} clone[0] = {clone[0].tag}")
    println(f"original[4999] = {t[4999].tag} clone[4999] = {clone[4999].tag}")

    # A separate pop-heavy pass -- `let`-bound, mirroring
    # `examples/table.star`'s existing pop usage (see `ring_stress.star`'s
    # matching doc comment for why a bare discarded `.pop()` isn't used here).
    let mut cycler: Table<Item> = Table<Item>()
    let mut j = 0
    while j < 3000:
        cycler.push(Item(hp = j, tag = f"cyc-{j}"))
        if j % 3 == 0:
            let popped = cycler.pop()
            if len(popped.tag) == 0:
                println("unexpected empty pop")
        j += 1
    println(f"cycler len = {cycler.len()}")

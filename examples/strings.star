# Demonstrates `todo.md` #6 "String ops": `str_contains`/`str_starts_with`/
# `str_ends_with`/`str_index_of`/`str_trim`/`str_replace`/`str_split`/
# `str_join` -- the split/join/trim/replace/contains surface beyond what
# `len`/`concat` already covered.

fn main():
    # `str_contains`/`str_starts_with`/`str_ends_with`/`str_index_of`: the
    # substring-search family, all backed by `strstr`/`strncmp`/`strcmp`.
    let msg = "the quick brown fox"
    let has_quick = str_contains(msg, "quick")
    let has_slow = str_contains(msg, "slow")
    println(f"contains 'quick'? {has_quick}, contains 'slow'? {has_slow}")

    let starts_the = str_starts_with(msg, "the")
    let ends_fox = str_ends_with(msg, "fox")
    println(f"starts with 'the'? {starts_the}, ends with 'fox'? {ends_fox}")

    let idx_brown = str_index_of(msg, "brown")
    let idx_nope = str_index_of(msg, "nope")
    println(f"index of 'brown' = {idx_brown}, index of 'nope' = {idx_nope}")

    # `str_trim`: strips leading/trailing whitespace (space/tab/newline/CR).
    let padded = "   surrounded by spaces   "
    let trimmed = str_trim(padded)
    println(f"trimmed = '{trimmed}'")

    # `str_replace`: every non-overlapping occurrence, left to right.
    println(str_replace("2024-01-15", "-", "/"))
    println(str_replace("aaaa", "aa", "b")) # non-overlapping: "aa"+"aa" -> "b"+"b"

    # `str_split`/`str_join`: cut on a separator, then reassemble -- `str_join`
    # is `str_split`'s inverse for a non-empty separator.
    let csv = "apple,banana,,cherry"
    let fruits = str_split(csv, ",")
    let count = fruits.len()
    println(f"{count} fields (the empty one between banana/cherry is kept)")
    let mut i: i32 = 0
    while i < fruits.len():
        let field = fruits[i]
        println(f"  [{i}] = '{field}'")
        i += 1
    println(str_join(fruits, " | "))

    # Splitting on a multi-character separator advances by the separator's
    # own length, not one byte at a time.
    let path_like = "a::b::c"
    let segments = str_split(path_like, "::")
    println(str_join(segments, "/"))

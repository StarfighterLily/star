# High-score persistence: a one-line save file "score,difficulty", read back
# with str_split, and a `difficulty` tag whose case is normalized through a
# real `extern "C"` libc call rather than a hand-rolled loop -- a small,
# self-contained exercise of the FFI surface `docs/language_reference.md`
# documents (todo.md gap #2 notes `extern "C" fn` only accepts scalar/`str`
# ABI shapes, which is exactly this: one `int` in, one `int` out).

extern "C" fn toupper(c: int) -> int
extern "C" fn atoi(s: str) -> int

fn normalize_difficulty(raw: str) -> str:
    let bytes = bytes_from_str(str_trim(raw))
    let mut out = Bytes()
    let mut i = 0
    while i < bytes.len():
        let upper = toupper(bytes[i] as i32)
        out.push(upper as u8)
        i += 1
    str_from_bytes(out)

fn save_high_score(path: str, score: i32, difficulty: str) -> bool:
    let f = file_open(path, "w")
    if is_null(f):
        return false
    file_write(f, f"{score},{difficulty}\n")
    file_close(f)
    true

# Returns (high_score, difficulty). Missing/corrupt saves fail safe: a fresh
# 0-score "normal" run rather than an error the caller has to thread through
# -- this is a toy game's save slot, not a format worth a `Result<T,E>` over.
fn load_high_score(path: str) -> (i32, str):
    if !file_exists(path):
        return (0, "normal")
    let f = file_open(path, "r")
    if is_null(f):
        return (0, "normal")
    let line = file_read_line(f)
    file_close(f)
    let parts = str_split(str_trim(line), ",")
    if parts.len() != 2:
        return (0, "normal")
    let score = atoi(parts[0])
    let difficulty = normalize_difficulty(parts[1])
    (score, difficulty)

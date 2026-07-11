# Regression check for the File I/O builtins (todo.md "Next Steps" #2):
# file_open/file_read/file_read_line/file_write/file_close/file_exists,
# reusing the `ptr`/`null_ptr`/`is_null` FFI machinery as the file handle
# type. See tests/frontend.rs's file_*/runtime_file_*_end_to_end tests for
# the full behavioral coverage -- this file is just an end-to-end smoke test
# of the same builtins composed in one real program.
fn main():
    let path = "star_file_io_example_scratch.txt"
    let missing_path = "star_file_io_example_missing.txt"

    let w = file_open(path, "w")
    if is_null(w):
        print("failed to open for writing")
        return
    file_write(w, "hello from star\n")
    file_write(w, "second line\n")
    file_close(w)

    let exists = file_exists(path)
    let missing = file_exists(missing_path)
    print(f"file_exists(written file): {exists}")
    print(f"file_exists(missing file): {missing}")

    let r = file_open(path, "r")
    if is_null(r):
        print("failed to open for reading")
        return
    let line1 = file_read_line(r)
    print(f"line1: {line1}")
    let rest = file_read(r)
    print(f"rest: {rest}")
    file_close(r)

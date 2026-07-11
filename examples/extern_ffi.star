# Regression check for extern "C" fn FFI (todo.md "Next Steps" #1): binding
# real C runtime symbols instead of requiring every capability to be
# hand-implemented inside the compiler. See tests/frontend.rs's
# extern_fn_*/runtime_extern_*/ptr_* tests for the full behavioral coverage
# (arity/type checking, ABI/type-signature restrictions, codegen shape, and
# RC-safety of str arguments) -- this file is just an end-to-end smoke test
# of the same symbols in one real program.
extern "C" fn toupper(c: int) -> int
extern "C" fn atoi(s: str) -> int
extern "C" fn getenv(name: str) -> ptr

fn main():
    print(f"toupper(97): {toupper(97)}")

    let s = "42"
    print(f"atoi(s): {atoi(s)}")

    let missing = getenv("STAR_EXAMPLE_DEFINITELY_UNSET_VAR_XYZ")
    print(f"is_null(missing env var): {is_null(missing)}")

    let path = getenv("PATH")
    print(f"is_null(PATH): {is_null(path)}")
    if !is_null(path):
        let path_str = ptr_to_str(path)
        print(f"PATH length > 0: {len(path_str) > 0}")

    print(f"null_ptr() == null_ptr(): {null_ptr() == null_ptr()}")

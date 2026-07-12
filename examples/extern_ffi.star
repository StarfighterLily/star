# Regression check for extern "C" fn FFI (todo.md "Next Steps" #1): binding
# real C runtime symbols instead of requiring every capability to be
# hand-implemented inside the compiler. See tests/frontend.rs's
# extern_fn_*/runtime_extern_*/ptr_* tests for the full behavioral coverage
# (arity/type checking, ABI/type-signature restrictions, codegen shape, and
# RC-safety of str arguments) -- this file is just an end-to-end smoke test
# of the same symbols in one real program.
#
# `getenv` used to be demonstrated here, but it's now a reserved runtime
# symbol declared internally by the `env_get`/`env_set` builtins (see
# todo.md #2, examples/os_surface.star) -- `strstr` fills the same
# "str argument, ptr return" FFI-shape demo slot instead.
extern "C" fn toupper(c: int) -> int
extern "C" fn atoi(s: str) -> int
extern "C" fn strstr(haystack: str, needle: str) -> ptr

fn main():
    print(f"toupper(97): {toupper(97)}")

    let s = "42"
    print(f"atoi(s): {atoi(s)}")

    let missing = strstr("hello world", "xyz")
    print(f"is_null(missing substring): {is_null(missing)}")

    let found = strstr("hello world", "world")
    print(f"is_null(found substring): {is_null(found)}")
    if !is_null(found):
        let found_str = ptr_to_str(found)
        print(f"found substring: {found_str}")

    print(f"null_ptr() == null_ptr(): {null_ptr() == null_ptr()}")

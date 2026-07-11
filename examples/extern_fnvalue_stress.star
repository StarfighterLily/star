# Stress test for the extern-fn-as-first-class-value `str`-argument release
# fix in `Codegen::emit_fn_value` (see the fix's own doc comment in
# `src/codegen/closure.rs`): calling an `extern "C" fn` indirectly through a
# variable (`let g = some_extern_fn; g(s)`) must release `s`'s reference the
# same way a direct call (`emit_extern_call`) already does, or every call
# through the thunk leaks one refcount. Routed through its own function
# (`call_it`), not inlined in the loop body, to sidestep the unrelated
# alloca-in-a-loop native-stack growth `rc_stress.star` already documents.
extern "C" fn atoi(s: str) -> i32

fn call_it(g: Fn(str) -> i32) -> i32:
    let s = concat("4", "2")
    g(s)

fn main():
    let g = atoi
    let mut i = 0
    let mut total: i32 = 0
    while i < 5000000:
        total = total + call_it(g)
        i = i + 1
    println(f"done, total = {total}")

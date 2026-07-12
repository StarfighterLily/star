# Regression check for the minimal OS surface (todo.md "Next Steps" #2):
# args()/env_get/env_set. See tests/frontend.rs's runtime_args_*/
# runtime_env_*_end_to_end tests for the full behavioral coverage -- this
# file is just an end-to-end smoke test of the same builtins composed in one
# real program.
fn main():
    let argv: List<str> = args()
    println(f"arg count: {argv.len()}")
    for i in 0..argv.len():
        println(f"argv[{i}] = {argv[i]}")

    let missing = env_get("STAR_OS_SURFACE_DEFINITELY_UNSET_VAR_XYZ")
    println(f"missing var is empty: {len(missing) == 0}")

    let set_ok = env_set("STAR_OS_SURFACE_EXAMPLE_VAR", "hello from star")
    println(f"env_set succeeded: {set_ok}")

    let round_trip = env_get("STAR_OS_SURFACE_EXAMPLE_VAR")
    println(f"round trip: {round_trip}")

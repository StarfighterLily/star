//! SDL builtins as shared-state hazards inside par/swarm; f-string interpolation of aggregate vector/matrix types
//!
//! Split out of the former monolithic `tests/frontend.rs` (see `todo.md`
//! P2 #6); shared helpers live in `tests/frontend/common.rs`.

#[path = "frontend/common.rs"]
#[allow(dead_code, unused_imports)]
mod common;
use common::*;

// ===== Bug-fix round: SDL builtins are shared-state hazards inside par/swarm

/// `Checker::unsafe_par_fns`'s ban-list mechanism only ever covers
/// user-defined `fn`/`impl` bodies that (transitively) `spawn`/`despawn`/
/// open a `frame:` block (`compute_unsafe_par_fns` walks the raw AST
/// looking for exactly those three statement kinds) -- a builtin free
/// function is never added to `bodies`/the call graph at all, so nothing
/// stopped `crate::codegen::sdl`'s window/render/input builtins from being
/// called with a captured window handle from inside a `par`/`swarm` body,
/// the same blind spot `Symbol(..)`/`rand(..)` had before `@sym.lock`/
/// `@rng.lock` (see their write-ups in `todo.md`). Unlike those two, a lock
/// isn't the fix here (see `is_banned_sdl_builtin_in_par`'s doc comment for
/// why) -- confirmed via a real crash before this test's fix: `window_create`
/// once outside the loop, then a `par` body over 64 spawned entities calling
/// `clear_screen`/`draw_pixel`/`present` on the same window handle for 500
/// ticks hit SDL's own internal assertion failure ("SetDrawState",
/// `viewport != ((void *)0)`, `SDL_render_sw.c:644`) from concurrent
/// renderer-state corruption in 5 of 6 runs. This is a compile-time
/// rejection test (mirroring `rejects_closure_invocation_inside_par_body`'s
/// own shape) rather than a runtime one, since the fix makes the hazardous
/// program simply fail to type-check.
#[test]
fn rejects_sdl_render_calls_inside_par_body() {
    let src = concat!(
        "struct Entity:\n    mut idx: i32\n\n",
        "arena Entities: Entity\n\n",
        "fn main():\n",
        "    let w = window_create(\"race\", 64, 48)\n",
        "    par e in Entities:\n",
        "        clear_screen(w, Color32(1, 2, 3, 255))\n",
        "        draw_pixel(w, e.idx, e.idx, Color32(4, 5, 6, 255))\n",
        "        present(w)\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else {
        panic!("clear_screen/draw_pixel/present on a captured window handle inside a par/swarm body should be rejected")
    };
    for name in ["clear_screen", "draw_pixel", "present"] {
        assert!(
            diags.iter().any(|d| d.message.contains(&format!("cannot call `{}`", name)) && d.message.contains("shared window/renderer")),
            "expected a rejection for `{}`, got: {:?}",
            name,
            diags
        );
    }
}

/// Sibling of `rejects_sdl_render_calls_inside_par_body` covering the rest
/// of the banned set: `window_create`/`window_destroy` (SDL subsystem
/// init/teardown is itself process-global state) and `window_should_close`/
/// `key_down`/`mouse_x`/`mouse_y`/`mouse_button_down` (the shared,
/// `window_should_close`-drained global input-event queue).
#[test]
fn rejects_sdl_window_and_input_calls_inside_par_body() {
    let src = concat!(
        "struct Entity:\n    mut idx: i32\n\n",
        "arena Entities: Entity\n\n",
        "fn main():\n",
        "    let w = window_create(\"race\", 64, 48)\n",
        "    par e in Entities:\n",
        "        window_should_close(w)\n",
        "        key_down(e.idx)\n",
        "        mouse_x()\n",
        "        mouse_y()\n",
        "        mouse_button_down(1)\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let Err(diags) = Driver::check(&module) else {
        panic!("window_should_close/key_down/mouse_x/mouse_y/mouse_button_down inside a par/swarm body should be rejected")
    };
    for name in ["window_should_close", "key_down", "mouse_x", "mouse_y", "mouse_button_down"] {
        assert!(
            diags.iter().any(|d| d.message.contains(&format!("cannot call `{}`", name))),
            "expected a rejection for `{}`, got: {:?}",
            name,
            diags
        );
    }
}

/// `delay`/`ticks` touch no window/renderer/event-queue state
/// (`SDL_Delay`/`SDL_GetTicks` are plain, stateless-to-this-analysis calls)
/// -- a regression guard so the ban doesn't overcorrect into rejecting every
/// `crate::codegen::sdl` builtin indiscriminately, the same "positive sibling
/// test" shape as `accepts_plain_method_call_on_loop_variable_inside_par_body`.
#[test]
fn accepts_sdl_delay_and_ticks_inside_par_body() {
    let src = concat!(
        "struct Entity:\n    mut idx: i32\n\n",
        "arena Entities: Entity\n\n",
        "fn main():\n",
        "    par e in Entities:\n",
        "        delay(0)\n",
        "        let t = ticks()\n",
    );
    let module = Driver::parse(src).expect("should parse");
    let result = Driver::check(&module);
    assert!(result.is_ok(), "delay/ticks inside a par/swarm body should still be allowed: {:?}", result.err());
}

// ===== Bug-fix: f-string interpolation of aggregate vector/matrix types
// (Vec2/Vec3/Vec4/Mat4/Quat/Color/Mat2/Mat3), noted in round 5's `todo.md`
// writeup as a real, reproduced, but explicitly out-of-scope-for-that-round
// finding: both f-string codegen paths (`emit_print_like` in `builtins.rs`,
// and the general `TypedExpr::FStr`-as-value path in `expr.rs`) only ever
// special-cased bare scalar types, so every builtin aggregate fell through
// the `%p` catch-all and tagged a `<N x float>`/`[N x <N x float>]` register
// as a pointer vararg -- an invalid-IR `clang` compile failure identical in
// kind to round 5's `Color32`/`PaletteIndex` fix, just for the much larger
// remaining set of bare-scalar-shaped-but-not-scalar types. Fixed by
// `Codegen::emit_agg_fstring_lanes` (`src/codegen/vector_math.rs`), shared by
// both paths, which formats each aggregate as its own constructor call
// syntax (`Vec2(1.000000, 2.000000)`, `Mat2(Vec2(...), Vec2(...))`).

/// IR-shape assertion: an f-string value interpolating a `Vec2` and a `Mat2`
/// must expand into the `Vec2(%f, %f)`/`Mat2(Vec2(%f, %f), Vec2(%f, %f))`
/// literal-plus-hole format fragments, with every vararg widened to `double`
/// (C's variadic promotion rule for `float`) -- never left as a bare
/// `<2 x float>`/`[2 x <2 x float>]` aggregate tagged for the `%p`/`i8*` hole
/// the pre-fix catch-all produced (an invalid-IR vararg type mismatch
/// `clang` rejects outright, confirmed via a real pre-fix `star build`
/// failure).
#[test]
fn codegen_fstring_value_interpolates_vec_and_mat_aggregates_with_correct_format() {
    let src = "fn t(v: Vec2, m: Mat2) -> str:\n    f\"v={v} m={m}\"\n";
    let module = Driver::parse(src).expect("should parse");
    let typed = Driver::check(&module).expect("should type-check");
    let ir = Driver::codegen(&typed).expect("should codegen");
    assert!(
        ir.contains("v=Vec2(%f, %f) m=Mat2(Vec2(%f, %f), Vec2(%f, %f))"),
        "Vec2/Mat2 should format as constructor-syntax %f holes, not fall through to %p: {}",
        ir
    );
    let fn_ir = extract_fn_body(&ir, "define i8* @t(");
    assert!(fn_ir.contains("extractelement"), "Vec2/Mat2 lanes must be read via extractelement: {}", fn_ir);
    assert!(fn_ir.contains("extractvalue"), "Mat2's rows must be read via extractvalue: {}", fn_ir);
    // 2 (Vec2) + 4 (Mat2, 2x2) = 6 total lanes, each fpext'd to double and
    // passed as a `double` vararg -- never `i8*`/`ptr` (the pre-fix bug).
    assert!(fn_ir.matches("fpext float").count() >= 6, "every lane must be fpext'd to double: {}", fn_ir);
    assert!(
        fn_ir.contains("@snprintf(i8* null, i64 0, i8* ") && fn_ir.matches(", double ").count() >= 6,
        "both snprintf calls' Vec2/Mat2 lane varargs must be tagged double, not i8*: {}",
        fn_ir
    );
}

/// Runtime companion: actually compiling (via `clang`) and running an
/// f-string value that interpolates every builtin vector/matrix aggregate
/// (`Vec2`/`Vec3`/`Vec4`/`Quat`/`Color`/`Mat2`/`Mat3`/`Mat4`) must produce
/// its constructor-syntax textual form, not fail to compile.
#[test]
fn runtime_fstring_value_interpolates_vec_and_mat_aggregates_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let v2 = Vec2(1.0, 2.0)\n",
        "    let v3 = Vec3(1.0, 2.0, 3.0)\n",
        "    let v4 = Vec4(1.0, 2.0, 3.0, 4.0)\n",
        "    let q = Quat(0.0, 0.0, 0.0, 1.0)\n",
        "    let c = Color(1.0, 0.5, 0.25, 1.0)\n",
        "    let m2 = Mat2(Vec2(1.0, 0.0), Vec2(0.0, 1.0))\n",
        "    let m3 = Mat3(Vec3(1.0, 0.0, 0.0), Vec3(0.0, 1.0, 0.0), Vec3(0.0, 0.0, 1.0))\n",
        "    let m4 = Mat4(Vec4(1.0, 0.0, 0.0, 0.0), Vec4(0.0, 1.0, 0.0, 0.0), \
                          Vec4(0.0, 0.0, 1.0, 0.0), Vec4(0.0, 0.0, 0.0, 1.0))\n",
        "    println(f\"{v2}\")\n",
        "    println(f\"{v3}\")\n",
        "    println(f\"{v4}\")\n",
        "    println(f\"{q}\")\n",
        "    println(f\"{c}\")\n",
        "    println(f\"{m2}\")\n",
        "    println(f\"{m3}\")\n",
        "    println(f\"{m4}\")\n",
    );
    let output = compile_and_run("fstring_value_vec_mat_aggregates", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(
        lines,
        vec![
            "Vec2(1.000000, 2.000000)",
            "Vec3(1.000000, 2.000000, 3.000000)",
            "Vec4(1.000000, 2.000000, 3.000000, 4.000000)",
            "Quat(0.000000, 0.000000, 0.000000, 1.000000)",
            "Color(1.000000, 0.500000, 0.250000, 1.000000)",
            "Mat2(Vec2(1.000000, 0.000000), Vec2(0.000000, 1.000000))",
            "Mat3(Vec3(1.000000, 0.000000, 0.000000), Vec3(0.000000, 1.000000, 0.000000), Vec3(0.000000, 0.000000, 1.000000))",
            "Mat4(Vec4(1.000000, 0.000000, 0.000000, 0.000000), Vec4(0.000000, 1.000000, 0.000000, 0.000000), \
             Vec4(0.000000, 0.000000, 1.000000, 0.000000), Vec4(0.000000, 0.000000, 0.000000, 1.000000))",
        ],
        "{}",
        stdout
    );
}

/// Same bug, reached through `println(f"...")`'s direct sole-argument path
/// (`emit_print_like` in `builtins.rs`) rather than the general f-string
/// value path -- a separate format-specifier table with the identical gap,
/// mirroring round 5's `Color32`/`PaletteIndex` print-direct-path companion
/// test. Also covers interpolating an aggregate alongside an ordinary scalar
/// in the same f-string, and a nested (non-identity) `Mat3`.
#[test]
fn runtime_print_fstring_interpolates_vec_and_mat_aggregates_end_to_end() {
    let src = concat!(
        "fn main():\n",
        "    let v3 = Vec3(1.0, 2.0, 3.0)\n",
        "    let tag = \"pos\"\n",
        "    println(f\"{tag}: {v3}\")\n",
        "    let m3 = Mat3(Vec3(0.0, 1.0, 0.0), Vec3(1.0, 0.0, 0.0), Vec3(0.0, 0.0, 1.0))\n",
        "    println(f\"{m3}\")\n",
    );
    let output = compile_and_run("print_fstring_vec_mat_aggregates", src);
    assert!(output.status.success(), "{:?}", output.status);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let lines: Vec<&str> = stdout.lines().collect();
    assert_eq!(
        lines,
        vec![
            "pos: Vec3(1.000000, 2.000000, 3.000000)",
            "Mat3(Vec3(0.000000, 1.000000, 0.000000), Vec3(1.000000, 0.000000, 0.000000), Vec3(0.000000, 0.000000, 1.000000))",
        ],
        "{}",
        stdout
    );
}

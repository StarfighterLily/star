# A Brainfuck interpreter (todo.md #8: "one real, non-toy program"). Exercises
# List<i32> as the 30000-cell tape end to end: growth-by-push, indexed
# read/write, and sustained mutation in tight loops -- good stress material
# for verifying List<T>'s RC/realloc codegen actually behaves under a real
# workload instead of just the handful of ops the existing List<T> examples
# touch. The source program is read directly out of a string literal via
# `s[i]` (byte indexing) and `len` instead of being hand-encoded as a
# `List<i32>` of opcodes. Output goes through `extern "C" fn putchar` rather
# than building up an output `str` with `chr`/`concat`, so it still streams
# character-by-character as the program runs (matters for a `.`-heavy or
# non-halting Brainfuck program) instead of only appearing once the whole
# interpreter loop finishes. `getchar` isn't available as an `extern "C" fn`
# -- it's one of the CRT symbols the compiler already declares internally to
# implement `read_line` (see `Checker::check_extern_fn`'s reserved-name
# check), so redeclaring it here fails to compile. `,` is implemented as
# "always EOF" (sets the cell to 0) since this particular program never
# executes one.
extern "C" fn putchar(c: int) -> int

fn main():
    # The canonical Brainfuck "Hello World!" program (esolangs.org).
    let prog = "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++."
    let prog_len = len(prog)

    let mut tape: List<i32> = List<i32>()
    let mut i: i32 = 0
    while i < 30000:
        tape.push(0)
        i += 1

    # Precompute `[`/`]` jump targets (each op's matching bracket's index) by
    # walking `prog` once with an explicit stack of open-bracket positions --
    # avoids re-scanning for the match on every loop iteration at run time.
    let mut jump: List<i32> = List<i32>()
    i = 0
    while i < prog_len:
        jump.push(0)
        i += 1

    let mut stack: List<i32> = List<i32>()
    i = 0
    while i < prog_len:
        let op = prog[i]
        if op == 91:
            stack.push(i)
        if op == 93:
            let open = stack.pop()
            jump[open] = i
            jump[i] = open
        i += 1

    let mut ptr: i32 = 0
    let mut pc: i32 = 0
    while pc < prog_len:
        let op = prog[pc]
        match op:
            43 ->
                let mut v = tape[ptr] + 1
                if v > 255:
                    v = 0
                tape[ptr] = v
            45 ->
                let mut v = tape[ptr] - 1
                if v < 0:
                    v = 255
                tape[ptr] = v
            62 ->
                ptr += 1
            60 ->
                ptr -= 1
            46 -> putchar(tape[ptr])
            44 ->
                tape[ptr] = 0
            91 ->
                if tape[ptr] == 0:
                    pc = jump[pc]
            93 ->
                if tape[ptr] != 0:
                    pc = jump[pc]
            _ -> 0
        pc += 1

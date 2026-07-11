# Standard input: `read_line()` reads one line from stdin (trailing
# newline stripped) as a fresh `str`, exercised end to end via a real
# compiled binary fed piped input in the runtime test.

fn main():
    let name = read_line()
    println(f"hello, {name}")
    let again = read_line()
    println(f"again: {again}")
    let last = read_line()
    println(f"last: {last}")

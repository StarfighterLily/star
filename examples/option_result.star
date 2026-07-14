enum Shape:
    Circle(radius: i32)
    Rect(width: i32, height: i32)

fn safe_div(a: i32, b: i32) -> Result<i32, i32>:
    if b == 0:
        return Result<i32, i32>::Err(1)
    Result<i32, i32>::Ok(a / b)

fn first_even(a: i32, b: i32, c: i32) -> Option<i32>:
    if a % 2 == 0:
        return Option::Some(a)
    if b % 2 == 0:
        return Option::Some(b)
    if c % 2 == 0:
        return Option::Some(c)
    Option<i32>::None

# `?`-propagation: `safe_div(a, b)?` unwraps a `Result::Ok(v)` to `v`, or
# immediately `return`s the `Result::Err(code)` unchanged out of this
# function -- no explicit `match` needed at the call site.
fn checked_double(a: i32, b: i32) -> Result<i32, i32>:
    let h = safe_div(a, b)?
    Result<i32, i32>::Ok(h * 2)

# Same sugar over `Option<T>`: `?` on a `None` propagates `Option::None`
# instead of a `Result::Err`.
fn first_even_doubled(a: i32, b: i32, c: i32) -> Option<i32>:
    let v = first_even(a, b, c)?
    Option::Some(v * 2)

fn describe_option(o: Option<i32>) -> i32:
    match o:
        Option::Some(v) ->
            return v
        Option::None ->
            return -1

# `match` used as a value-producing expression: each arm's trailing
# expression (rather than an explicit `return`) flows out through the
# codegen `phi` merge at the match's join point.
fn unwrap_or(o: Option<i32>, default: i32) -> i32:
    match o:
        Option::Some(v) -> v
        Option::None -> default

# `match` used as a bare statement that is *not* the last statement of its
# enclosing block -- `println("done describing")` immediately follows it at
# the same indentation.
fn describe_sign(x: i32):
    match x:
        <= 0 -> println("non-positive")
        _ -> println("positive")
    println("done describing")

fn print_div(r: Result<i32, i32>):
    match r:
        Result::Ok(v) -> println(f"ok: {v}")
        Result::Err(code) -> println(f"err: {code}")

fn print_doubled(r: Result<i32, i32>):
    match r:
        Result::Ok(v) -> println(f"checked_double ok: {v}")
        Result::Err(code) -> println(f"checked_double err: {code}")

fn print_option(o: Option<i32>):
    match o:
        Option::Some(v) -> println(f"first_even_doubled: {v}")
        Option::None -> println("first_even_doubled: none")

fn area(s: Shape) -> i32:
    match s:
        Shape::Circle(r) ->
            return 3 * r * r
        Shape::Rect(w, h) ->
            return w * h

fn main():
    print_div(safe_div(10, 2))
    print_div(safe_div(10, 0))
    println(f"found: {describe_option(first_even(1, 3, 4))}")
    println(f"found: {describe_option(first_even(1, 3, 5))}")
    println(f"circle area: {area(Shape::Circle(2))}")
    println(f"rect area: {area(Shape::Rect(3, 4))}")
    println(f"unwrap_or(Some(7), -1) = {unwrap_or(Option::Some(7), -1)}")
    println(f"unwrap_or(None, -1) = {unwrap_or(Option<i32>::None, -1)}")
    describe_sign(-3)
    describe_sign(4)
    print_doubled(checked_double(10, 2))
    print_doubled(checked_double(10, 0))
    print_option(first_even_doubled(1, 3, 4))
    print_option(first_even_doubled(1, 3, 5))

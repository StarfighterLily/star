enum IntOption:
    None
    Some(value: i32)

enum DivResult:
    Ok(value: i32)
    Err(code: i32)

enum Shape:
    Circle(radius: i32)
    Rect(width: i32, height: i32)

fn safe_div(a: i32, b: i32) -> DivResult:
    if b == 0:
        return DivResult::Err(1)
    DivResult::Ok(a / b)

fn first_even(a: i32, b: i32, c: i32) -> IntOption:
    if a % 2 == 0:
        return IntOption::Some(a)
    if b % 2 == 0:
        return IntOption::Some(b)
    if c % 2 == 0:
        return IntOption::Some(c)
    IntOption::None

fn describe_option(o: IntOption) -> i32:
    match o:
        IntOption::Some(v) ->
            return v
        IntOption::None ->
            return -1

# `match` used as a value-producing expression: each arm's trailing
# expression (rather than an explicit `return`) flows out through the
# codegen `phi` merge at the match's join point.
fn unwrap_or(o: IntOption, default: i32) -> i32:
    match o:
        IntOption::Some(v) -> v
        IntOption::None -> default

# `match` used as a bare statement that is *not* the last statement of its
# enclosing block -- `println("done describing")` immediately follows it at
# the same indentation.
fn describe_sign(x: i32):
    match x:
        <= 0 -> println("non-positive")
        _ -> println("positive")
    println("done describing")

fn print_div(r: DivResult):
    match r:
        DivResult::Ok(v) -> println(f"ok: {v}")
        DivResult::Err(code) -> println(f"err: {code}")

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
    println(f"unwrap_or(Some(7), -1) = {unwrap_or(IntOption::Some(7), -1)}")
    println(f"unwrap_or(None, -1) = {unwrap_or(IntOption::None, -1)}")
    describe_sign(-3)
    describe_sign(4)

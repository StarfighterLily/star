struct Box<T>:
    value: T

enum Option<T>:
    None
    Some(value: T)

enum Result<T, E>:
    Ok(value: T)
    Err(error: E)

fn identity<T>(x: T) -> T:
    return x

fn unwrap_or<T>(o: Option<T>, default: T) -> T:
    match o:
        Option::Some(v) ->
            return v
        Option::None ->
            return default

fn print_result(r: Result<i32, str>):
    match r:
        Result::Ok(v) -> println(f"ok: {v}")
        Result::Err(e) -> println(f"err: {e}")

fn main():
    let b = Box(value = 42)
    println(f"box: {b.value}")

    let boxed_box = Box(value = Box(value = 99))
    println(f"nested box: {boxed_box.value.value}")

    let some_int = Option::Some(5)
    let none_int = Option<i32>::None
    println(f"unwrap some: {unwrap_or(some_int, 0)}")
    println(f"unwrap none: {unwrap_or(none_int, -1)}")

    let ok = Result<i32, str>::Ok(10)
    let err = Result<i32, str>::Err("bad")
    print_result(ok)
    print_result(err)

    println(f"identity int: {identity(7)}")
    println(f"identity float: {identity(3.5)}")

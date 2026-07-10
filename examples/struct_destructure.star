# Exercises struct destructuring in match patterns: `StructName(a, b, ...)`
# binds each of the struct's fields into a fresh local in declaration order.

struct Point:
    x: i32
    y: i32

struct Line:
    start: Point
    end: Point

fn manhattan(p: Point) -> i32:
    match p:
        Point(x, y) ->
            return x + y

fn length_sq(l: Line) -> i32:
    match l:
        Line(start, end) ->
            let dx = end.x - start.x
            let dy = end.y - start.y
            return dx * dx + dy * dy

fn main():
    println(f"sum: {manhattan(Point(3, 4))}")
    println(f"length_sq: {length_sq(Line(Point(0, 0), Point(3, 4)))}")

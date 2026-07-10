# A small library file with no `main` of its own, meant to be pulled in via
# `import "geometry_lib.star" as geo` (see modules_main.star) -- exercises a
# struct with a method, a free function, and a payload-carrying enum with a
# match, all reachable through a module alias.

struct Point:
    x: i32
    y: i32

impl Point:
    fn length_sq(self) -> i32:
        return self.x * self.x + self.y * self.y

fn dot(a: Point, b: Point) -> i32:
    return a.x * b.x + a.y * b.y

enum Shape:
    Circle(radius: i32)
    Rect(width: i32, height: i32)

fn area(s: Shape) -> i32:
    match s:
        Shape::Circle(r) ->
            return 3 * r * r
        Shape::Rect(w, h) ->
            return w * h

# Transitive re-export: `main` imports `reexport_lib.star` as `shapes`, which
# itself imports `geometry_lib.star` as `geo` -- `main` never imports
# geometry_lib.star directly, but can still reach its items through the full
# two-hop qualified path `shapes::geo::...` (a struct literal, a free
# function, and a payload enum variant + match, mirroring modules_main.star's
# single-hop coverage of the same shapes). `shapes::unit_circle()` shows the
# alternative: a helper declared in the middle file that itself reaches
# through to the innermost one.

import "reexport_lib.star" as shapes

fn main():
    let p = shapes::geo::Point(3, 4)
    println(f"dot: {shapes::geo::dot(p, shapes::geo::Point(1, 2))}")
    println(f"circle area: {shapes::geo::area(shapes::geo::Shape::Circle(2))}")
    println(f"unit circle area: {shapes::geo::area(shapes::unit_circle())}")

# Exercises `import "path.star" as alias`: a qualified struct literal, a
# qualified free-function call, and a qualified payload enum variant
# construction (`geo::Shape::Circle(...)`, a 3-segment path), all reaching
# into geometry_lib.star's namespace through the `geo` alias.

import "geometry_lib.star" as geo

fn main():
    let p = geo::Point(3, 4)
    println(f"dot: {geo::dot(p, geo::Point(1, 2))}")
    println(f"circle area: {geo::area(geo::Shape::Circle(2))}")
    println(f"rect area: {geo::area(geo::Shape::Rect(3, 4))}")

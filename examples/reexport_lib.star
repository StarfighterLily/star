# A middle-tier "facade" file, meant to be pulled in via
# `import "reexport_lib.star" as shapes` (see reexport_main.star) -- itself
# imports geometry_lib.star, exercising transitive re-export: a file that
# imports `geo` can reach `geo`'s own items through `shapes::geo::...` from
# whichever file imports *it*, with no explicit re-export syntax needed.
# Also adds one function of its own (`unit_circle`) that constructs and
# returns a type declared in the innermost file, showing the two styles
# (reach straight through vs. wrap in a local helper) compose freely.

import "geometry_lib.star" as geo

fn unit_circle() -> geo::Shape:
    geo::Shape::Circle(1)

# Regression check for `&&`/`||`/`and`/`or`/`not` (LANGUAGE_ANALYSIS.md
# §2.1): both spellings of each operator, and short-circuit evaluation (the
# right-hand side must not be evaluated when the left-hand side already
# determines the result).
fn side_effect(tag: str) -> bool:
    print(f"called: {tag}")
    true

fn main():
    let a: i32 = 5
    let b: i32 = -3

    if a > 0 and b > 0:
        print("both positive (unexpected)")
    else:
        print("not both positive")

    if a > 0 or b > 0:
        print("at least one positive")

    if not (a > 0 and b > 0):
        print("negated and works")

    if a > 0 && b < 0:
        print("symbolic && works")

    if a < 0 || b < 0:
        print("symbolic || works")

    # Short-circuit: `side_effect` must never run in either case below.
    if false and side_effect("and-rhs"):
        print("unreachable")
    print("false-and short-circuited")

    if true or side_effect("or-rhs"):
        print("true-or short-circuited")

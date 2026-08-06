# NoBASIC AST -- ported from the reference Python `compiler/parser/ast.py`
# (`c:\Code\projects\Nova\NoBASIC\compiler\parser\ast.py`), todo.md P0 #2.
# `parser.star` (this port's `Parser`) builds these nodes; a later phase
# (`semantic.star`, todo.md P0 #3) will walk them.
#
# Deliberate deviation -- index-based arena, not an object tree:
# the reference represents the AST as ordinary Python objects holding direct
# references to their children (`BinaryExpr.left: Expression`, an actual
# nested `Expression` instance). Star has no heap object references for a
# `struct`/`enum` -- a `struct`/`enum` field naming another `struct`/`enum`
# by value nests it inline, and the compiler's own recursive-struct-layout
# check (`src/types/mod.rs`'s `check_no_recursive_structs`) rejects exactly
# this shape at compile time with "has infinite size -- use `GenRef<T>`
# instead of nesting by value" the moment a type would contain itself
# (confirmed empirically before writing this file -- see this project's own
# session notes; `GenRef<T>` itself was ruled out too, since it's an
# arena-`spawn`/generational-handle mechanism built for runtime ECS entities
# with despawn/reuse semantics, not a fixed, append-only compile-time tree).
# Instead, `Expr`/`Stmt` are flat structs (`kind` + `line`/`column`) whose
# `ExprKind`/`StmtKind` payloads reference child nodes by `i32` index into a
# flat `Ast.exprs`/`Ast.stmts` list rather than embedding a child node by
# value -- confirmed empirically to compile and run correctly (a `List<T>`
# field is a fixed-size handle regardless of what `T` is, so it never trips
# the recursive-layout check; see `check_no_recursive_structs`'s own
# "`List<T>`/`GenRef<T>`/closures/primitives are all fixed-size handles"
# comment). This is the standard "arena-of-nodes, children by index" shape
# real-world arena-based ASTs (e.g. `rustc`'s own arenas) already use for
# exactly this reason, not a workaround invented just for this port.
#
# Deliberate deviation -- one shared `i32` index type for both expressions
# and statements, not separate `ExprId`/`StmtId` newtypes: `parser.star`
# threads a single `Result<i32, ParseError>` through essentially every
# parsing method (see that file's own header comment for why), and a
# postfix `?` requires the *enclosing function's* declared return type to be
# the exact same `Result<T, E>` instantiation as what it propagates (per
# `docs/language_reference.md`'s "`?`-propagation" section) -- not merely a
# compatible `T`. Expression-parsing and statement-parsing genuinely call
# into each other in both directions (`if_statement` parses an expression
# condition *and* a list of statement children; `expression`'s `primary`
# never calls into statement parsing, but plenty of statement parsers call
# `self.expression()`), so splitting `i32` into two distinct wrapper structs
# would force many call sites to fall back to manual `match`-based
# propagation instead of `?`, working against the exact readability `?` is
# for. The type-safety cost (an `ExprKind` field could theoretically be
# fed a `Stmt` index by a typo) is accepted the same way this project
# already accepts `Token`'s dual num/str fields in `tokens.star` -- a
# pragmatic representation choice, not an oversight.
#
# `StructType` is ported even though nothing in this phase (`parser.star`)
# constructs one -- the reference's own `Parser` doesn't either; it exists
# for the semantic analyzer (`todo.md` P0 #3) to build. Kept here now for
# 1:1 parity with `ast.py`, the same "kept for a later phase" calibration
# `tokens.star` already uses for the built-in-function `TokenType` variants.

# Variable scope, mirroring the reference `VarScope` enum exactly.
enum VarScope:
    Global
    Local
    Implicit

# Expression data type, mirroring the reference `DataType` enum exactly.
# (`DataType::List` does not collide with the builtin generic `List<T>`
# type -- confirmed empirically; enum variants live in their own
# `EnumName::Variant`-qualified namespace.)
enum DataType:
    Number
    String
    List
    Matrix
    Struct

# User-defined struct type -- see this file's header comment on why this is
# ported now but not yet built by anything in this phase.
struct StructType:
    name: str
    fields: List<str>

# A function-definition parameter: a name plus an optional default-value
# expression (an `Ast.exprs` index), mirroring the reference
# `FunctionDefStmt.params: List[Tuple[str, Optional[Expression]]]`. Star has
# no tuple type usable as a struct field, so this is a small named struct
# instead.
struct Param:
    name: str
    default: Option<i32> = Option<i32>::None

# ---------------------------------------------------------------------------
# Expressions -- one `ExprKind` variant per reference `Expression` subclass.
# A field typed `i32` is an index into the owning `Ast.exprs`; a field typed
# `List<i32>` is a list of such indices (reference call/index-list fields).
# ---------------------------------------------------------------------------

enum ExprKind:
    # Literal value. The reference's `LiteralExpr.value: Any` holds either a
    # number or a string; split into side-by-side fields the same way
    # `tokens.star`'s `Token` already splits `Token.literal: Optional[Any]`
    # (only the field matching `data_type` is ever populated).
    Literal(data_type: DataType, num_value: f64, is_float: bool, str_value: str)
    # Variable reference.
    Variable(name: str)
    # List access: `L1(index)`.
    ListAccess(list_name: str, index: i32)
    # Matrix access: `MatA(row, col)`.
    MatrixAccess(matrix_name: str, row: i32, col: i32)
    # Member access: `struct.field`.
    MemberAccess(object: i32, member: str)
    # Binary operation: `left op right`.
    Binary(left: i32, operator: str, right: i32)
    # Unary operation: `op expr` (supports pre/post `++`/`--`).
    Unary(operator: str, expr: i32, is_post: bool)
    # Function call: `func(arg1, arg2, ...)`.
    Call(name: str, arguments: List<i32>)
    # Grouped expression: `(expr)`.
    Grouping(expr: i32)

struct Expr:
    kind: ExprKind
    line: i32 = 0
    column: i32 = 0

# ---------------------------------------------------------------------------
# Statements -- one `StmtKind` variant per reference `Statement` subclass,
# grouped/ordered the same way as `ast.py` to stay easy to eyeball-compare.
# ---------------------------------------------------------------------------

enum StmtKind:
    ClrDraw
    PxlOn(x: i32, y: i32, color: i32)
    PxlOff(x: i32, y: i32)
    Line(x1: i32, y1: i32, x2: i32, y2: i32, color: i32)
    # `filled`: `None` means "filled" (default true), matching the
    # reference's own `Optional[Expression] = None` default/meaning.
    Circle(x: i32, y: i32, radius: i32, color: i32, filled: Option<i32>)
    Text(x: i32, y: i32, text: i32, color: i32)
    SetLayer(layer: i32)
    SRol(axis: i32, amount: i32)
    SRot(direction: i32, amount: i32)
    SShft(axis: i32, amount: i32)
    SFlip(axis: i32)
    SpriteOn(sprite_id: i32, x: i32, y: i32)
    SpriteOff(sprite_id: i32)
    PlayTone(frequency: i32, duration: i32, volume: i32)
    PlayWave(waveform: i32, frequency: i32, volume: i32)
    StopSound
    SetChannel(channel: i32)
    GetKey
    SerOut(value: i32)
    SerIn(variable: str)
    SerStat(variable: str)
    SerCtrl(value: i32)
    Input(prompt: Option<i32>, variable: str)
    Disp(text: i32)
    Pause
    # Function-call statement. `call` indexes an `Expr` whose `kind` is
    # `ExprKind::Call` (matches the reference `FunctionCallStmt.function_call`
    # comment: "This should be a FunctionCallExpr").
    FunctionCall(call: i32)
    # Expression statement -- side-effect expressions like `++`/`--`.
    ExpressionStmt(expr: i32)
    Assignment(variable: i32, expr: i32)
    If(condition: i32, then_branch: List<i32>, else_branch: Option<List<i32>>)
    For(variable: str, start: i32, end: i32, step: Option<i32>, body: List<i32>)
    While(condition: i32, body: List<i32>)
    Repeat(body: List<i32>, condition: i32)
    Goto(label: str)
    Label(label: str)
    StructDecl(name: str, fields: List<str>)
    VarDecl(scope: VarScope, variables: List<str>)
    AsmBlock(assembly_code: str)
    FunctionDef(name: str, params: List<Param>, body: List<i32>)
    Return(value: Option<i32>)

struct Stmt:
    kind: StmtKind
    line: i32 = 0
    column: i32 = 0

# The whole parsed program: `exprs`/`stmts` are the flat node arenas every
# `i32` index above refers into; `program` is the reference `Program.
# statements` list -- top-level statement indices in source order.
struct Ast:
    exprs: List<Expr>
    stmts: List<Stmt>
    program: List<i32>

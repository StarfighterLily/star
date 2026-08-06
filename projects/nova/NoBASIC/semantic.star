# NoBASIC semantic analyzer -- ported from the reference Python
# `compiler/semantic/analyzer.py` (`c:\Code\projects\Nova\NoBASIC\compiler\
# semantic\analyzer.py`, 779 lines), todo.md P0 #3. Walks the `ast::Ast`
# `parser.star` builds (see that file's own header comment for why it's an
# index-based arena, not an object tree) and reports the first semantic
# error found, or `Ok` if the program checks out. `codegen.star` (todo.md
# P1 #1) is the next phase to read this file.
#
# Same `had_error`-flag propagation as `lexer.star`/`parser.star`, for the
# same reason documented at length in `parser.star`'s header comment: no
# single `Result<T, E>` instantiation fits every method here either
# (`analyze_expression` hands back a `ast::DataType`; every statement
# analyzer is a plain procedure; `SymbolTable`'s own lookups hand back
# `Option<...>`/`bool`/`ast::DataType`), and these methods call into each
# other in every direction. `Analyzer` carries `had_error` plus the
# failure's message/line/column exactly like `Lexer`/`Parser` do; every
# call site that might have set it checks `self.had_error` immediately
# afterward and returns before doing anything else with the result --
# same discipline as `parser.star`'s `-1` sentinel, just returning
# `ast::DataType::Number` (a harmless, ignored-on-error placeholder,
# exactly what the reference's own exception-driven code never even
# constructs on the error path) as `analyze_expression`'s sentinel instead.
#
# Deliberate deviation -- `SymbolTable.structs` is a `List<ast::StructType>`
# with linear-scan lookup, not a `Map<str, StructType>` matching the
# reference's `Dict[str, StructType]`: Star's `Map<K, V>` supports only
# `insert`/`get`/`remove`/`contains`/`len` (confirmed against
# `src/types/expr.rs`'s `infer_map_method` before committing to this) --
# no key/value iteration at all. `get_structs_with_field` (used by
# `infer_struct_instance_type` to find which struct a bare member-access
# name like `player.hp` refers to) and the "exactly one struct total"
# fallback both need to enumerate *every* struct definition, not look one
# up by a known key, so a `Map` alone can't implement them. A flat list
# with `find_struct_index`'s linear scan is the direct substitute -- struct
# *counts* in any real NoBASIC program are small (this is a TI-83/84-style
# scripting language, not a whole-program C++ project), so the O(n) lookup
# this trades away is not a real performance concern here.
#
# Deliberate simplification -- one `Map<str, BuiltinFn>` table, not four:
# the reference spreads a built-in function's four properties (is it one at
# all; its expected argument count, possibly one of two values for
# `CIRCLE`/`RECT`/`SEQ`; its per-argument expected types, `None` meaning
# "any"; its return type, defaulting to `NUMBER`) across four separately
# hand-maintained structures: `is_builtin_function`'s membership list,
# `get_function_arg_count`'s dict, `get_function_arg_types`'s dict, and
# `get_function_return_type`'s dict -- kept in sync only by the author's own
# care, not the language. Porting that shape verbatim would repeat every one
# of the ~107 function-name string literals up to four times each across
# four separate tables, the exact kind of copy-paste hazard a from-scratch
# port has no reason to reproduce. `register_builtins` instead builds one
# `Map<str, BuiltinFn>` with one `reg(...)` call per function, each row
# holding all four properties together -- verified against the reference's
# four tables function-by-function while writing it (see the "genuine
# reference quirks" list below for the two real asymmetries found doing
# that cross-check). `BuiltinFn.count_a`/`count_b` hold the same value for
# a fixed arg count (`SIN` -> `1, 1`) or the two allowed values for
# `CIRCLE`/`RECT`/`SEQ` (`CIRCLE` -> `4, 5`) -- one field pair instead of
# the reference's "sometimes an `int`, sometimes a `(min, max)` tuple"
# dynamic typing, which Star's static structs can't express directly anyway.
#
# Genuine reference quirks, confirmed by direct inspection of
# `analyzer.py` while building the table above (not assumed, and not
# "fixed" -- reproduced exactly):
#
# - `LN` and `POW` are listed in `is_builtin_function`'s membership check
#   but have **no entry at all** in `get_function_arg_count`/
#   `get_function_arg_types` -- so the reference silently skips *both*
#   argument-count and argument-type validation for exactly these two
#   functions (`expected_args is not None` is false; `expected_types` is
#   `[]`, so `i < len(expected_types)` is false for every argument). Every
#   other same-shape math function (`LOG`, `EXP`, ...) *does* get `expected
#   1 arg, NUMBER` checking. Looks like an oversight in the reference, but
#   it's the actual live behavior -- reproduced here via `reg_uncounted`,
#   which `analyze_call` recognizes through `has_count = false` to skip
#   both checks, matching the reference precisely rather than "fixing" it
#   to check like its neighbors.
# - There is no `_is_matrix_name`-equivalent to `_is_list_name`: a bare
#   `L1` reference auto-vivifies as a list purely from its *name* shape
#   (`is_list_name`, checked in both `analyze_expression`'s `Variable` case
#   and `analyze_assignable_expression`'s `ListAccess` case), but a matrix
#   is only ever auto-vivified through the "this name isn't defined as
#   anything yet" fallback inside `MatrixAccess` assignment -- there's no
#   equivalent `MatA`-shaped name-pattern recognition anywhere for plain
#   `Variable` references. This asymmetry is already true of the reference
#   itself (confirmed: no `_is_matrix_name` function exists in
#   `analyzer.py` at all), not a gap introduced by this port -- flagged here
#   so a future reader of `codegen.star` doesn't assume symmetry that was
#   never there.
#
# Deliberate fix, documented per todo.md's "any such gap ... should be
# documented ... not silently reconciled" guidance (this one is a bug in
# the reference *implementation* itself, not a design-doc/implementation
# drift, but the same "don't silently paper over it" spirit applies): the
# reference's pending-GOTO undefined-label check
# (`analyze`'s final loop) constructs
# `SemanticError(f"Undefined label '{label_name}'", line, column)` --
# only 3 positional arguments against `CompilerError.__init__(self,
# message, filename="<stdin>", line=0, column=0)`. That silently passes
# the goto's own `line` as `filename` and `column` as `line`, leaving the
# real `column` at its default `0` -- Python's duck typing never raises for
# this (an `int` is a perfectly legal value to store in `self.filename`
# and later f-string-interpolate), it just produces a nonsensical message
# ("Error in 7 at line 3, column 0: Undefined label 'x'" instead of "Error
# in prog.nobasic at line 7, column 3: ..."). Star's `SemanticError` is a
# typed struct (`filename: str`), so the same mistake would be a compile
# error here, not a silent runtime mix-up -- `analyze`'s equivalent check
# constructs it with the correct field order instead.
#
# `Analyzer.exprs`/`Analyzer.stmts` are the same `ast::Ast` arena
# `parser.star` built (copied in at construction -- `List<T>` is a
# fixed-size handle per that file's own header comment, so this is a cheap
# reference copy, not a deep clone). `analyze` returns `Result<ast::Ast,
# SemanticError>` rather than the reference's bare `None`-on-success: this
# port's pipeline has no separate place to hold "the program, now
# confirmed semantically valid" otherwise, and threading it back out lets
# `codegen.star` (todo.md P1 #1) take a `Result<ast::Ast, SemanticError>`
# straight from this function without the caller needing to have kept its
# own copy around.

import "ast.star" as ast

struct SemanticError:
    message: str
    filename: str = "<stdin>"
    line: i32 = 0
    column: i32 = 0

fn format_semantic_error(e: SemanticError) -> str:
    if e.filename == "<stdin>":
        concat("Error: ", e.message)
    else:
        f"Error in {e.filename} at line {e.line}, column {e.column}: {e.message}"

# ---------------------------------------------------------------------------
# Byte/string helpers -- duplicated locally rather than imported from
# `lexer.star`/`parser.star`, matching those files' own "self-contained
# tool" rationale (see `lexer.star`'s header comment).
# ---------------------------------------------------------------------------

fn is_digit_byte(c: i32) -> bool:
    c >= 48 and c <= 57

fn to_lower_byte(c: i32) -> i32:
    if c >= 65 and c <= 90:
        c + 32
    else:
        c

fn to_upper_byte(c: i32) -> i32:
    if c >= 97 and c <= 122:
        c - 32
    else:
        c

fn str_lower(s: str) -> str:
    let mut parts: List<str> = List<str>()
    let mut i = 0
    while i < len(s):
        parts.push(chr(to_lower_byte(s[i])))
        i += 1
    str_join(parts, "")

fn str_upper(s: str) -> str:
    let mut parts: List<str> = List<str>()
    let mut i = 0
    while i < len(s):
        parts.push(chr(to_upper_byte(s[i])))
        i += 1
    str_join(parts, "")

# TI-83/84 style list name: 'L' followed by one or more digits (`L1`, `L23`,
# ...). Matches `parser.star`'s own `is_list_name` (and, transitively, the
# reference `_is_list_name`) exactly.
fn is_list_name(name: str) -> bool:
    if len(name) < 2:
        return false
    if name[0] != 76:
        return false
    let mut i = 1
    while i < len(name):
        if !is_digit_byte(name[i]):
            return false
        i += 1
    true

fn list_contains_str(items: List<str>, target: str) -> bool:
    let mut i = 0
    while i < items.len():
        if items[i] == target:
            return true
        i += 1
    false

# Matches the reference `DataType.value` strings exactly (`ast.py`'s
# `DataType(Enum)` -- `NUMBER = "number"`, etc.) -- used only to build the
# same wording the reference's f-strings produce for type-mismatch errors.
fn data_type_name(d: ast::DataType) -> str:
    match d:
        ast::DataType::Number -> "number"
        ast::DataType::String -> "string"
        ast::DataType::List -> "list"
        ast::DataType::Matrix -> "matrix"
        ast::DataType::Struct -> "struct"

# Tiny builders so `register_builtins`'s ~107 rows can write `[num(), strt()]`
# instead of fully qualifying `Option<ast::DataType>::Some(ast::DataType::
# Number)` at every one of the several hundred call sites that would
# otherwise need it.
fn num() -> Option<ast::DataType>:
    Option<ast::DataType>::Some(ast::DataType::Number)

fn strt() -> Option<ast::DataType>:
    Option<ast::DataType>::Some(ast::DataType::String)

fn listt() -> Option<ast::DataType>:
    Option<ast::DataType>::Some(ast::DataType::List)

fn any_t() -> Option<ast::DataType>:
    Option<ast::DataType>::None

# ---------------------------------------------------------------------------
# Scope / SymbolTable -- see this file's header comment for why `structs`
# is a `List<ast::StructType>` rather than a `Map`.
# ---------------------------------------------------------------------------

struct Scope:
    is_global: bool = false
    mut variables: Map<str, ast::DataType> = Map<str, ast::DataType>()
    mut explicit_declarations: Set<str> = Set<str>()

impl Scope:
    fn define_variable(mut self, name: str, data_type: ast::DataType, explicit: bool):
        self.variables.insert(name, data_type)
        if explicit:
            self.explicit_declarations.insert(name)

    fn has_variable(self, name: str) -> bool:
        self.variables.contains(name)

    fn get_variable_type(self, name: str) -> Option<ast::DataType>:
        self.variables.get(name)

struct SymbolTable:
    mut scopes: List<Scope> = List<Scope>()
    mut lists: Set<str> = Set<str>()
    mut matrices: Set<str> = Set<str>()
    mut labels: Set<str> = Set<str>()
    mut structs: List<ast::StructType> = List<ast::StructType>()
    mut struct_instances: Map<str, str> = Map<str, str>()

fn new_symbol_table() -> SymbolTable:
    let mut st = SymbolTable()
    st.scopes.push(Scope(is_global = true))
    st

impl SymbolTable:
    fn push_scope(mut self):
        self.scopes.push(Scope(is_global = false))

    fn pop_scope(mut self):
        if self.scopes.len() > 1:
            self.scopes.pop()

    fn is_in_global_scope(self) -> bool:
        self.scopes.len() == 1

    # `scope` controls where `name` is (re)defined -- see `ast::VarScope`'s
    # own doc comment. The reference's own internal "can't declare LOCAL in
    # global scope" guard is not reproduced here: every caller that can
    # legally pass `VarScope::Local` (only `analyze_var_declaration`)
    # already checked `is_in_global_scope()` itself first and reports its
    # own error before ever reaching this method -- see that method below.
    fn define_variable(mut self, name: str, data_type: ast::DataType, scope: ast::VarScope):
        match scope:
            ast::VarScope::Global ->
                self.scopes[0].define_variable(name, data_type, true)
            ast::VarScope::Local ->
                let last = self.scopes.len() - 1
                self.scopes[last].define_variable(name, data_type, true)
            ast::VarScope::Implicit ->
                let mut i = self.scopes.len() - 1
                let mut found = false
                while i >= 0 and !found:
                    if self.scopes[i].has_variable(name):
                        self.scopes[i].define_variable(name, data_type, false)
                        found = true
                    i -= 1
                if !found:
                    self.scopes[0].define_variable(name, data_type, false)

    fn get_variable_type(self, name: str) -> ast::DataType:
        let mut i = self.scopes.len() - 1
        while i >= 0:
            match self.scopes[i].get_variable_type(name):
                Option::Some(t) ->
                    return t
                Option::None -> 0
            i -= 1
        ast::DataType::Number

    fn is_variable_defined(self, name: str) -> bool:
        let mut i = self.scopes.len() - 1
        while i >= 0:
            if self.scopes[i].has_variable(name):
                return true
            i -= 1
        false

    fn find_struct_index(self, name: str) -> i32:
        let target = str_lower(name)
        let mut i = 0
        while i < self.structs.len():
            if str_lower(self.structs[i].name) == target:
                return i
            i += 1
        -1

    fn define_struct(mut self, name: str, fields: List<str>):
        let mut lowered: List<str> = List<str>()
        let mut i = 0
        while i < fields.len():
            lowered.push(str_lower(fields[i]))
            i += 1
        self.structs.push(ast::StructType(name = name, fields = lowered))

    fn get_struct(self, name: str) -> Option<ast::StructType>:
        let idx = self.find_struct_index(name)
        if idx < 0:
            Option<ast::StructType>::None
        else:
            Option<ast::StructType>::Some(self.structs[idx])

    fn is_struct(self, name: str) -> bool:
        self.find_struct_index(name) >= 0

    fn define_struct_instance(mut self, var_name: str, struct_name: str):
        self.struct_instances.insert(str_lower(var_name), struct_name)

    fn get_struct_instance_type(self, var_name: str) -> Option<str>:
        self.struct_instances.get(str_lower(var_name))

    fn get_structs_with_field(self, field_name: str) -> List<ast::StructType>:
        let field_key = str_lower(field_name)
        let mut result: List<ast::StructType> = List<ast::StructType>()
        let mut i = 0
        while i < self.structs.len():
            if list_contains_str(self.structs[i].fields, field_key):
                result.push(self.structs[i])
            i += 1
        result

    fn infer_struct_instance_type(mut self, var_name: str, member: str) -> Option<str>:
        match self.get_struct_instance_type(var_name):
            Option::Some(existing) ->
                return Option<str>::Some(existing)
            Option::None -> 0
        let matching = self.get_structs_with_field(member)
        if matching.len() == 1:
            let struct_name = matching[0].name
            self.define_struct_instance(var_name, struct_name)
            return Option<str>::Some(struct_name)
        if matching.len() == 0 and self.structs.len() == 1:
            let struct_name = self.structs[0].name
            self.define_struct_instance(var_name, struct_name)
            return Option<str>::Some(struct_name)
        Option<str>::None

    fn is_list(self, name: str) -> bool:
        self.lists.contains(name)

    fn is_matrix(self, name: str) -> bool:
        self.matrices.contains(name)

    fn is_defined(self, name: str) -> bool:
        self.is_variable_defined(name) or self.lists.contains(name) or self.matrices.contains(name)

    fn get_type(self, name: str) -> ast::DataType:
        if self.is_variable_defined(name):
            self.get_variable_type(name)
        elif self.is_list(name):
            ast::DataType::List
        elif self.is_matrix(name):
            ast::DataType::Matrix
        else:
            ast::DataType::Number

    fn define_label(mut self, name: str):
        self.labels.insert(name)

    fn is_label_defined(self, name: str) -> bool:
        self.labels.contains(name)

# ---------------------------------------------------------------------------
# Built-in function table -- see this file's header comment for why this is
# one `Map<str, BuiltinFn>`, not four parallel reference tables.
# ---------------------------------------------------------------------------

struct BuiltinFn:
    name: str
    has_count: bool = true
    count_a: i32 = 0
    count_b: i32 = 0
    arg_types: List<Option<ast::DataType>> = List<Option<ast::DataType>>()
    return_type: ast::DataType = ast::DataType::Number

# A `(label_name, line, column)` pending `GOTO` target, checked once every
# label in the program has been collected -- matches the reference's own
# `self.pending_gotos: List[Tuple[str, int, int]]`, a small named struct
# instead of a tuple for the same reason `ast::Param` is (Star has no tuple
# field type).
struct PendingGoto:
    label: str
    line: i32 = 0
    column: i32 = 0

# ---------------------------------------------------------------------------
# Analyzer
# ---------------------------------------------------------------------------

struct Analyzer:
    exprs: List<ast::Expr> = List<ast::Expr>()
    stmts: List<ast::Stmt> = List<ast::Stmt>()
    filename: str = "<stdin>"
    mut symbol_table: SymbolTable = SymbolTable()
    mut pending_gotos: List<PendingGoto> = List<PendingGoto>()
    mut functions: Map<str, i32> = Map<str, i32>()
    mut current_function: Option<str> = Option<str>::None
    mut builtins: Map<str, BuiltinFn> = Map<str, BuiltinFn>()
    mut had_error: bool = false
    mut error_message: str = ""
    mut error_line: i32 = 0
    mut error_column: i32 = 0

fn new_analyzer(exprs: List<ast::Expr>, stmts: List<ast::Stmt>, filename: str) -> Analyzer:
    let mut a = Analyzer(exprs = exprs, stmts = stmts, filename = filename, symbol_table = new_symbol_table())
    let mut i = 1
    while i <= 6:
        a.symbol_table.lists.insert(f"L{i}")
        i += 1
    a.symbol_table.matrices.insert("MatA")
    a.symbol_table.matrices.insert("MatB")
    a.symbol_table.matrices.insert("MatC")
    a.register_builtins()
    a

impl Analyzer:
    fn fail(mut self, message: str, line: i32, column: i32):
        if !self.had_error:
            self.had_error = true
            self.error_message = message
            self.error_line = line
            self.error_column = column

    fn reg(mut self, name: str, count_a: i32, count_b: i32, arg_types: List<Option<ast::DataType>>, return_type: ast::DataType):
        self.builtins.insert(name, BuiltinFn(name = name, has_count = true, count_a = count_a, count_b = count_b, arg_types = arg_types, return_type = return_type))

    # `LN`/`POW` -- see this file's header comment's "genuine reference
    # quirks" section.
    fn reg_uncounted(mut self, name: str):
        self.builtins.insert(name, BuiltinFn(name = name, has_count = false, return_type = ast::DataType::Number))

    fn register_builtins(mut self):
        # Original math functions.
        self.reg("SIN", 1, 1, [num()], ast::DataType::Number)
        self.reg("COS", 1, 1, [num()], ast::DataType::Number)
        self.reg("TAN", 1, 1, [num()], ast::DataType::Number)
        self.reg("SQRT", 1, 1, [num()], ast::DataType::Number)
        self.reg("ABS", 1, 1, [num()], ast::DataType::Number)
        self.reg("RAND", 0, 0, List<Option<ast::DataType>>(), ast::DataType::Number)
        self.reg("RND", 0, 0, List<Option<ast::DataType>>(), ast::DataType::Number)
        self.reg("RNDR", 2, 2, [num(), num()], ast::DataType::Number)
        self.reg("RANDOMIZE", 1, 1, [num()], ast::DataType::Number)
        self.reg("LEN", 1, 1, [strt()], ast::DataType::Number)
        self.reg("LENGTH", 1, 1, [strt()], ast::DataType::Number)
        self.reg("MIN", 2, 2, [num(), num()], ast::DataType::Number)
        self.reg("MAX", 2, 2, [num(), num()], ast::DataType::Number)
        self.reg("LOG", 1, 1, [num()], ast::DataType::Number)
        self.reg_uncounted("LN")
        self.reg("EXP", 1, 1, [num()], ast::DataType::Number)
        self.reg_uncounted("POW")
        self.reg("INT", 1, 1, [num()], ast::DataType::Number)
        self.reg("ROUND", 1, 1, [num()], ast::DataType::Number)
        # Extended math functions.
        self.reg("ATAN", 1, 1, [num()], ast::DataType::Number)
        self.reg("ASIN", 1, 1, [num()], ast::DataType::Number)
        self.reg("ACOS", 1, 1, [num()], ast::DataType::Number)
        self.reg("DEG", 1, 1, [num()], ast::DataType::Number)
        self.reg("RAD", 1, 1, [num()], ast::DataType::Number)
        self.reg("FLOOR", 1, 1, [num()], ast::DataType::Number)
        self.reg("CEIL", 1, 1, [num()], ast::DataType::Number)
        self.reg("TRUNC", 1, 1, [num()], ast::DataType::Number)
        self.reg("FRAC", 1, 1, [num()], ast::DataType::Number)
        self.reg("INTGR", 1, 1, [num()], ast::DataType::Number)
        self.reg("POWR", 2, 2, [num(), num()], ast::DataType::Number)
        # String functions.
        self.reg("STRLEN", 1, 1, [strt()], ast::DataType::Number)
        self.reg("STRCPY", 2, 2, [strt(), strt()], ast::DataType::String)
        self.reg("STRCAT", 2, 2, [strt(), strt()], ast::DataType::String)
        self.reg("STRCMP", 3, 3, [strt(), strt(), num()], ast::DataType::Number)
        self.reg("STRUPR", 1, 1, [strt()], ast::DataType::String)
        self.reg("STRLWR", 1, 1, [strt()], ast::DataType::String)
        self.reg("STRREV", 1, 1, [strt()], ast::DataType::String)
        self.reg("STRFIND", 2, 2, [strt(), strt()], ast::DataType::Number)
        self.reg("STRFINDI", 2, 2, [strt(), strt()], ast::DataType::Number)
        self.reg("STREXT", 4, 4, [strt(), num(), num(), strt()], ast::DataType::String)
        self.reg("STREXTI", 4, 4, [strt(), num(), num(), strt()], ast::DataType::String)
        self.reg("SUB", 3, 3, [strt(), num(), num()], ast::DataType::String)
        # Additional string functions.
        self.reg("INSTRING", 2, 2, [strt(), strt()], ast::DataType::Number)
        self.reg("UPSTRING", 1, 1, [strt()], ast::DataType::String)
        self.reg("LOWSTRING", 1, 1, [strt()], ast::DataType::String)
        self.reg("LENSTRING", 1, 1, [strt()], ast::DataType::Number)
        # Bit manipulation functions.
        self.reg("BTST", 2, 2, [any_t(), any_t()], ast::DataType::Number)
        self.reg("BSET", 2, 2, [any_t(), any_t()], ast::DataType::Number)
        self.reg("BCLR", 2, 2, [any_t(), any_t()], ast::DataType::Number)
        self.reg("BFLIP", 2, 2, [any_t(), any_t()], ast::DataType::Number)
        self.reg("CLZ", 1, 1, [any_t()], ast::DataType::Number)
        self.reg("CTZ", 1, 1, [any_t()], ast::DataType::Number)
        self.reg("POPCNT", 1, 1, [any_t()], ast::DataType::Number)
        # Shift and rotate functions.
        self.reg("SHL", 2, 2, [any_t(), any_t()], ast::DataType::Number)
        self.reg("SHR", 2, 2, [any_t(), any_t()], ast::DataType::Number)
        self.reg("SAL", 2, 2, [any_t(), any_t()], ast::DataType::Number)
        self.reg("SAR", 2, 2, [any_t(), any_t()], ast::DataType::Number)
        self.reg("ROL", 2, 2, [any_t(), any_t()], ast::DataType::Number)
        self.reg("ROR", 2, 2, [any_t(), any_t()], ast::DataType::Number)
        self.reg("RCL", 2, 2, [any_t(), any_t()], ast::DataType::Number)
        self.reg("RCR", 2, 2, [any_t(), any_t()], ast::DataType::Number)
        # Bitwise logical functions.
        self.reg("BAND", 2, 2, [any_t(), any_t()], ast::DataType::Number)
        self.reg("BOR", 2, 2, [any_t(), any_t()], ast::DataType::Number)
        self.reg("BXOR", 2, 2, [any_t(), any_t()], ast::DataType::Number)
        self.reg("BNOT", 1, 1, [any_t()], ast::DataType::Number)
        # Memory functions.
        self.reg("MEMREAD", 1, 1, [any_t()], ast::DataType::Number)
        self.reg("MEMWRITE", 2, 2, [any_t(), any_t()], ast::DataType::Number)
        self.reg("MEMCPY", 3, 3, [any_t(), any_t(), any_t()], ast::DataType::Number)
        self.reg("MEMSET", 3, 3, [any_t(), any_t(), any_t()], ast::DataType::Number)
        self.reg("MEMTEST", 3, 3, [any_t(), any_t(), any_t()], ast::DataType::Number)
        self.reg("MEMMOVE", 3, 3, [any_t(), any_t(), any_t()], ast::DataType::Number)
        self.reg("MEMCMP", 4, 4, [any_t(), any_t(), any_t(), any_t()], ast::DataType::Number)
        self.reg("MEMSWAP", 3, 3, [any_t(), any_t(), any_t()], ast::DataType::Number)
        # Enhanced arithmetic.
        self.reg("ADC", 3, 3, [any_t(), any_t(), any_t()], ast::DataType::Number)
        self.reg("SBC", 3, 3, [any_t(), any_t(), any_t()], ast::DataType::Number)
        self.reg("MULH", 3, 3, [any_t(), any_t(), any_t()], ast::DataType::Number)
        self.reg("DIVH", 3, 3, [any_t(), any_t(), any_t()], ast::DataType::Number)
        self.reg("SWAP", 1, 1, [any_t()], ast::DataType::Number)
        self.reg("XCHNG", 2, 2, [any_t(), any_t()], ast::DataType::Number)
        self.reg("MOVZ", 2, 2, [any_t(), any_t()], ast::DataType::Number)
        self.reg("MOVNZ", 2, 2, [any_t(), any_t()], ast::DataType::Number)
        self.reg("LEA", 2, 2, [any_t(), any_t()], ast::DataType::Number)
        # Type conversion.
        self.reg("ITOB", 2, 2, [any_t(), any_t()], ast::DataType::Number)
        self.reg("BTOI", 2, 2, [any_t(), any_t()], ast::DataType::Number)
        self.reg("ITOS", 2, 2, [any_t(), any_t()], ast::DataType::Number)
        self.reg("STOI", 2, 2, [any_t(), any_t()], ast::DataType::Number)
        self.reg("STR", 1, 1, [num()], ast::DataType::String)
        # Graphics functions.
        self.reg("CLRDRAW", 0, 0, List<Option<ast::DataType>>(), ast::DataType::Number)
        self.reg("SETLAYER", 1, 1, [num()], ast::DataType::Number)
        self.reg("PXLON", 3, 3, [num(), num(), num()], ast::DataType::Number)
        self.reg("PXLOFF", 2, 2, [num(), num()], ast::DataType::Number)
        self.reg("LINE", 5, 5, [num(), num(), num(), num(), num()], ast::DataType::Number)
        # `filled` (a 5th, optional arg) has no listed type -- see the
        # reference's own `expected_types` list, only 4 entries long
        # despite `count_b = 5`; matches its "no check past the last
        # listed type" behavior automatically (see `analyze_call`).
        self.reg("CIRCLE", 4, 5, [num(), num(), num(), num()], ast::DataType::Number)
        self.reg("TEXT", 4, 4, [num(), num(), strt(), num()], ast::DataType::Number)
        self.reg("RECT", 5, 6, [num(), num(), num(), num(), num(), num()], ast::DataType::Number)
        # List/Array functions.
        self.reg("SUM", 1, 1, [listt()], ast::DataType::Number)
        self.reg("MEAN", 1, 1, [listt()], ast::DataType::Number)
        self.reg("DIM", 1, 1, [listt()], ast::DataType::Number)
        self.reg("SORTA", 1, 1, [listt()], ast::DataType::Number)
        self.reg("SORTD", 1, 1, [listt()], ast::DataType::Number)
        self.reg("FILL", 2, 2, [listt(), num()], ast::DataType::Number)
        # `SEQ`: expression, iterator, start, end, [step] -- expression/
        # iterator are loosely typed, matching the reference's own `None`
        # entries there.
        self.reg("SEQ", 4, 5, [any_t(), any_t(), num(), num(), num()], ast::DataType::Number)
        self.reg("REVERSE", 1, 1, [listt()], ast::DataType::Number)
        # I/O functions.
        self.reg("GETKEY", 0, 0, List<Option<ast::DataType>>(), ast::DataType::Number)
        self.reg("PAUSE", 0, 0, List<Option<ast::DataType>>(), ast::DataType::Number)
        # Serial I/O functions.
        self.reg("SERIN", 0, 0, List<Option<ast::DataType>>(), ast::DataType::Number)
        self.reg("SERSTAT", 0, 0, List<Option<ast::DataType>>(), ast::DataType::Number)

    # ------------------------------------------------------------------
    # Top-level dispatch
    # ------------------------------------------------------------------

    fn analyze_statement(mut self, stmt_id: i32):
        let stmt = self.stmts[stmt_id]
        match stmt.kind:
            ast::StmtKind::VarDecl(scope, variables) ->
                self.analyze_var_declaration(scope, variables, stmt.line, stmt.column)
            ast::StmtKind::FunctionDef(name, params, body) ->
                self.analyze_function_def(name, params, body)
            ast::StmtKind::Return(value) ->
                self.analyze_return(value, stmt.line, stmt.column)
            ast::StmtKind::Assignment(variable, expr) ->
                self.analyze_assignment(variable, expr)
            ast::StmtKind::If(condition, then_branch, else_branch) ->
                self.analyze_if(condition, then_branch, else_branch)
            ast::StmtKind::For(variable, start, end, step, body) ->
                self.analyze_for(variable, start, end, step, body)
            ast::StmtKind::While(condition, body) ->
                self.analyze_while(condition, body)
            ast::StmtKind::Repeat(body, condition) ->
                self.analyze_repeat(body, condition)
            ast::StmtKind::Goto(label) ->
                self.analyze_goto(label, stmt.line, stmt.column)
            ast::StmtKind::Label(label) ->
                self.analyze_label(label, stmt.line, stmt.column)
            ast::StmtKind::StructDecl(name, fields) ->
                self.analyze_struct_declaration(name, fields, stmt.line, stmt.column)
            ast::StmtKind::FunctionCall(call) ->
                self.analyze_expression(call)
            ast::StmtKind::ExpressionStmt(expr) ->
                self.analyze_expression(expr)
            ast::StmtKind::SerIn(variable) ->
                self.symbol_table.define_variable(variable, ast::DataType::Number, ast::VarScope::Implicit)
            ast::StmtKind::SerStat(variable) ->
                self.symbol_table.define_variable(variable, ast::DataType::Number, ast::VarScope::Implicit)
            # Graphics/sound statements -- just analyze every embedded
            # expression, matching the reference's `dir(stmt)`-based
            # reflection (which Star has no equivalent of, so each shape is
            # spelled out explicitly instead).
            ast::StmtKind::PxlOn(x, y, color) ->
                self.analyze_all([x, y, color])
            ast::StmtKind::PxlOff(x, y) ->
                self.analyze_all([x, y])
            ast::StmtKind::Line(x1, y1, x2, y2, color) ->
                self.analyze_all([x1, y1, x2, y2, color])
            ast::StmtKind::Circle(x, y, radius, color, filled) ->
                self.analyze_all([x, y, radius, color])
                if self.had_error:
                    return
                match filled:
                    Option::Some(f) -> self.analyze_expression(f)
                    Option::None -> ast::DataType::Number
            ast::StmtKind::Text(x, y, text, color) ->
                self.analyze_all([x, y, text, color])
            ast::StmtKind::SetLayer(layer) ->
                self.analyze_all([layer])
            ast::StmtKind::SRol(axis, amount) ->
                self.analyze_all([axis, amount])
            ast::StmtKind::SRot(direction, amount) ->
                self.analyze_all([direction, amount])
            ast::StmtKind::SShft(axis, amount) ->
                self.analyze_all([axis, amount])
            ast::StmtKind::SFlip(axis) ->
                self.analyze_all([axis])
            ast::StmtKind::SpriteOn(sprite_id, x, y) ->
                self.analyze_all([sprite_id, x, y])
            ast::StmtKind::SpriteOff(sprite_id) ->
                self.analyze_all([sprite_id])
            ast::StmtKind::PlayTone(frequency, duration, volume) ->
                self.analyze_all([frequency, duration, volume])
            ast::StmtKind::PlayWave(waveform, frequency, volume) ->
                self.analyze_all([waveform, frequency, volume])
            ast::StmtKind::SetChannel(channel) ->
                self.analyze_all([channel])
            ast::StmtKind::SerOut(value) ->
                self.analyze_all([value])
            ast::StmtKind::SerCtrl(value) ->
                self.analyze_all([value])
            ast::StmtKind::Input(prompt, variable) ->
                match prompt:
                    Option::Some(p) -> self.analyze_expression(p)
                    Option::None -> ast::DataType::Number
            ast::StmtKind::Disp(text) ->
                self.analyze_all([text])
            # `ClrDraw`/`StopSound`/`GetKey`/`Pause`/`AsmBlock` carry no
            # expression operands to check -- matches the reference falling
            # through its `isinstance` chain to "Other statements don't
            # need special analysis".
            _ -> 0

    # Analyze a list of expression-id operands in order, stopping at the
    # first error -- shared by every graphics/sound statement arm above.
    fn analyze_all(mut self, ids: List<i32>):
        let mut i = 0
        while i < ids.len() and !self.had_error:
            self.analyze_expression(ids[i])
            i += 1

    # ------------------------------------------------------------------
    # Statement analyzers
    # ------------------------------------------------------------------

    fn analyze_function_def(mut self, name: str, params: List<ast::Param>, body: List<i32>):
        let prev_function = self.current_function
        self.current_function = Option<str>::Some(str_lower(name))
        self.symbol_table.push_scope()
        let mut i = 0
        while i < params.len() and !self.had_error:
            self.symbol_table.define_variable(params[i].name, ast::DataType::Number, ast::VarScope::Implicit)
            match params[i].default:
                Option::Some(d) -> self.analyze_expression(d)
                Option::None -> ast::DataType::Number
            i += 1
        if !self.had_error:
            let mut bi = 0
            while bi < body.len() and !self.had_error:
                self.analyze_statement(body[bi])
                bi += 1
        self.symbol_table.pop_scope()
        self.current_function = prev_function

    fn analyze_return(mut self, value: Option<i32>, line: i32, column: i32):
        match self.current_function:
            Option::None ->
                self.fail("Return outside of function", line, column)
            Option::Some(fname) ->
                match value:
                    Option::Some(v) -> self.analyze_expression(v)
                    Option::None -> ast::DataType::Number

    fn analyze_assignment(mut self, variable: i32, expr: i32):
        let expr_type = self.analyze_expression(expr)
        if self.had_error:
            return
        self.analyze_assignable_expression(variable, expr_type)

    fn analyze_if(mut self, condition: i32, then_branch: List<i32>, else_branch: Option<List<i32>>):
        self.analyze_expression(condition)
        if self.had_error:
            return
        let mut i = 0
        while i < then_branch.len() and !self.had_error:
            self.analyze_statement(then_branch[i])
            i += 1
        if self.had_error:
            return
        match else_branch:
            Option::Some(eb) ->
                let mut j = 0
                while j < eb.len() and !self.had_error:
                    self.analyze_statement(eb[j])
                    j += 1
            Option::None -> 0

    fn analyze_for(mut self, variable: str, start: i32, end: i32, step: Option<i32>, body: List<i32>):
        self.symbol_table.define_variable(variable, ast::DataType::Number, ast::VarScope::Implicit)
        self.analyze_expression(start)
        if self.had_error:
            return
        self.analyze_expression(end)
        if self.had_error:
            return
        match step:
            Option::Some(s) -> self.analyze_expression(s)
            Option::None -> ast::DataType::Number
        if self.had_error:
            return
        let mut i = 0
        while i < body.len() and !self.had_error:
            self.analyze_statement(body[i])
            i += 1

    fn analyze_while(mut self, condition: i32, body: List<i32>):
        self.analyze_expression(condition)
        if self.had_error:
            return
        let mut i = 0
        while i < body.len() and !self.had_error:
            self.analyze_statement(body[i])
            i += 1

    fn analyze_repeat(mut self, body: List<i32>, condition: i32):
        let mut i = 0
        while i < body.len() and !self.had_error:
            self.analyze_statement(body[i])
            i += 1
        if self.had_error:
            return
        self.analyze_expression(condition)

    # Deferred: not checked until every label in the program has been
    # collected -- see `analyze` below, matching the reference's own
    # two-pass shape (`self.pending_gotos.append(...)` here, resolved at
    # the very end of `analyze`).
    fn analyze_goto(mut self, label: str, line: i32, column: i32):
        self.pending_gotos.push(PendingGoto(label = label, line = line, column = column))

    fn analyze_label(mut self, label: str, line: i32, column: i32):
        if self.symbol_table.is_label_defined(label):
            self.fail("Label already defined", line, column)
            return
        self.symbol_table.define_label(label)

    fn analyze_struct_declaration(mut self, name: str, fields: List<str>, line: i32, column: i32):
        if self.symbol_table.is_struct(name):
            self.fail(f"Struct '{name}' is already defined", line, column)
            return
        let mut seen: Set<str> = Set<str>()
        let mut i = 0
        while i < fields.len():
            let field_key = str_lower(fields[i])
            if seen.contains(field_key):
                self.fail(f"Duplicate field '{fields[i]}' in struct '{name}'", line, column)
                return
            seen.insert(field_key)
            i += 1
        self.symbol_table.define_struct(name, fields)

    fn analyze_var_declaration(mut self, scope: ast::VarScope, variables: List<str>, line: i32, column: i32):
        match scope:
            ast::VarScope::Local ->
                if self.symbol_table.is_in_global_scope():
                    let first = variables[0]
                    self.fail(f"Cannot declare LOCAL variable '{first}' in global scope", line, column)
                    return
            _ -> 0
        let mut i = 0
        while i < variables.len() and !self.had_error:
            let var_name = variables[i]
            match scope:
                ast::VarScope::Local ->
                    if !self.symbol_table.is_in_global_scope():
                        let last = self.symbol_table.scopes.len() - 1
                        if self.symbol_table.scopes[last].explicit_declarations.contains(var_name):
                            self.fail(f"Variable '{var_name}' already declared in this scope", line, column)
                ast::VarScope::Global ->
                    if self.symbol_table.scopes[0].explicit_declarations.contains(var_name):
                        self.fail(f"Variable '{var_name}' already declared as global", line, column)
                ast::VarScope::Implicit -> 0
            if self.had_error:
                return
            self.symbol_table.define_variable(var_name, ast::DataType::Number, scope)
            i += 1

    # ------------------------------------------------------------------
    # Expressions
    # ------------------------------------------------------------------

    fn analyze_expression(mut self, expr_id: i32) -> ast::DataType:
        let expr = self.exprs[expr_id]
        match expr.kind:
            ast::ExprKind::Literal(data_type, num_value, is_float, str_value) ->
                data_type
            ast::ExprKind::Variable(name) ->
                if is_list_name(name):
                    self.symbol_table.lists.insert(name)
                    return ast::DataType::List
                if self.symbol_table.is_list(name):
                    ast::DataType::List
                elif self.symbol_table.is_matrix(name):
                    ast::DataType::Matrix
                elif self.symbol_table.is_defined(name):
                    self.symbol_table.get_variable_type(name)
                else:
                    # Undefined variables can be any type in BASIC --
                    # default to NUMBER, matching the reference.
                    ast::DataType::Number
            ast::ExprKind::ListAccess(list_name, index) ->
                if !self.symbol_table.is_list(list_name):
                    if is_list_name(list_name):
                        self.symbol_table.lists.insert(list_name)
                    else:
                        self.fail(f"Undefined list: {list_name}", expr.line, expr.column)
                        return ast::DataType::Number
                let index_type = self.analyze_expression(index)
                if self.had_error:
                    return index_type
                if index_type != ast::DataType::Number:
                    self.fail("List index must be numeric", expr.line, expr.column)
                    return ast::DataType::Number
                ast::DataType::Number
            ast::ExprKind::MatrixAccess(matrix_name, row, col) ->
                if !self.symbol_table.is_matrix(matrix_name):
                    self.fail(f"Undefined matrix: {matrix_name}", expr.line, expr.column)
                    return ast::DataType::Number
                let row_type = self.analyze_expression(row)
                if self.had_error:
                    return row_type
                let col_type = self.analyze_expression(col)
                if self.had_error:
                    return col_type
                if row_type != ast::DataType::Number or col_type != ast::DataType::Number:
                    self.fail("Matrix indices must be numeric", expr.line, expr.column)
                    return ast::DataType::Number
                ast::DataType::Number
            ast::ExprKind::MemberAccess(object, member) ->
                self.analyze_member_access(object, member, expr.line, expr.column)
            ast::ExprKind::Binary(left, operator, right) ->
                self.analyze_binary(left, operator, right, expr.line, expr.column)
            ast::ExprKind::Unary(operator, inner, is_post) ->
                self.analyze_unary(operator, inner, expr.line, expr.column)
            ast::ExprKind::Call(name, arguments) ->
                self.analyze_call(name, arguments, expr.line, expr.column)
            ast::ExprKind::Grouping(inner) ->
                self.analyze_expression(inner)

    fn analyze_member_access(mut self, object: i32, member: str, line: i32, column: i32) -> ast::DataType:
        self.analyze_expression(object)
        if self.had_error:
            return ast::DataType::Number
        match self.exprs[object].kind:
            ast::ExprKind::Variable(var_name) ->
                match self.symbol_table.infer_struct_instance_type(var_name, member):
                    Option::Some(struct_name) ->
                        match self.symbol_table.get_struct(struct_name):
                            Option::Some(struct_def) ->
                                if list_contains_str(struct_def.fields, str_lower(member)):
                                    ast::DataType::Number
                                else:
                                    self.fail(f"Struct '{struct_name}' has no field '{member}'", line, column)
                                    ast::DataType::Number
                            Option::None ->
                                self.fail(f"Variable '{var_name}' is not a struct instance", line, column)
                                ast::DataType::Number
                    Option::None ->
                        self.fail(f"Variable '{var_name}' is not a struct instance", line, column)
                        ast::DataType::Number
            _ ->
                self.fail("Cannot access member of non-struct expression", line, column)
                ast::DataType::Number

    fn analyze_binary(mut self, left: i32, operator: str, right: i32, line: i32, column: i32) -> ast::DataType:
        let left_type = self.analyze_expression(left)
        if self.had_error:
            return left_type
        let right_type = self.analyze_expression(right)
        if self.had_error:
            return right_type
        if operator == "+" or operator == "-" or operator == "*" or operator == "/" or operator == "^":
            if operator == "+" and (left_type == ast::DataType::String or right_type == ast::DataType::String):
                # Allow string concatenation with `+` (TI-BASIC style).
                return ast::DataType::String
            elif left_type == ast::DataType::String or right_type == ast::DataType::String:
                self.fail("Cannot perform arithmetic on strings", line, column)
                return ast::DataType::Number
            return ast::DataType::Number
        # Comparison (`=`, `<>`, `<`, `>`, `<=`, `>=`) and logical (`and`,
        # `or`) operators all fall through to this same result, matching
        # the reference's own final `return DataType.NUMBER`.
        ast::DataType::Number

    fn analyze_unary(mut self, operator: str, inner: i32, line: i32, column: i32) -> ast::DataType:
        if operator == "++" or operator == "--":
            match self.exprs[inner].kind:
                ast::ExprKind::Variable(name) ->
                    if !self.symbol_table.is_variable_defined(name):
                        self.symbol_table.define_variable(name, ast::DataType::Number, ast::VarScope::Implicit)
                    self.analyze_expression(inner)
                    if self.had_error:
                        return ast::DataType::Number
                    ast::DataType::Number
                ast::ExprKind::ListAccess(list_name, index) ->
                    self.analyze_expression(inner)
                    if self.had_error:
                        return ast::DataType::Number
                    ast::DataType::Number
                ast::ExprKind::MatrixAccess(matrix_name, row, col) ->
                    self.analyze_expression(inner)
                    if self.had_error:
                        return ast::DataType::Number
                    ast::DataType::Number
                ast::ExprKind::MemberAccess(object, member) ->
                    self.analyze_expression(inner)
                    if self.had_error:
                        return ast::DataType::Number
                    ast::DataType::Number
                _ ->
                    self.fail("Increment/decrement requires an assignable target", line, column)
                    ast::DataType::Number
        else:
            self.analyze_expression(inner)

    fn analyze_call(mut self, name: str, arguments: List<i32>, line: i32, column: i32) -> ast::DataType:
        let func_name_lower = str_lower(name)
        match self.functions.get(func_name_lower):
            Option::Some(stmt_id) ->
                self.analyze_user_function_call(name, stmt_id, arguments, line, column)
            Option::None ->
                self.analyze_builtin_call(name, arguments, line, column)

    fn analyze_user_function_call(mut self, name: str, stmt_id: i32, arguments: List<i32>, line: i32, column: i32) -> ast::DataType:
        let func_stmt = self.stmts[stmt_id]
        match func_stmt.kind:
            ast::StmtKind::FunctionDef(fname, params, body) ->
                let mut min_args = 0
                let mut pi = 0
                while pi < params.len():
                    match params[pi].default:
                        Option::None ->
                            min_args += 1
                        Option::Some(d) -> 0
                    pi += 1
                let max_args = params.len()
                let n = arguments.len()
                if !(n >= min_args and n <= max_args):
                    self.fail(f"Wrong number of arguments for function '{name}': expected {min_args}-{max_args}, got {n}", line, column)
                    return ast::DataType::Number
                # Analyze provided argument expressions. Default values are
                # analyzed once, in `analyze_function_def`, not here.
                let mut ai = 0
                while ai < arguments.len() and !self.had_error:
                    self.analyze_expression(arguments[ai])
                    ai += 1
                ast::DataType::Number
            # Unreachable: `self.functions` only ever maps a name to a
            # `FunctionDef` statement id (see `analyze`'s first pass).
            _ -> ast::DataType::Number

    fn analyze_builtin_call(mut self, name: str, arguments: List<i32>, line: i32, column: i32) -> ast::DataType:
        let func_name_upper = str_upper(name)
        match self.builtins.get(func_name_upper):
            Option::None ->
                self.fail(f"Undefined function '{name}'", line, column)
                ast::DataType::Number
            Option::Some(b) ->
                let n = arguments.len()
                if b.has_count and !(n == b.count_a or n == b.count_b):
                    if b.count_a == b.count_b:
                        self.fail(f"Wrong number of arguments for function '{name}': expected {b.count_a}, got {n}", line, column)
                    else:
                        self.fail(f"Wrong number of arguments for function '{name}': expected [{b.count_a}, {b.count_b}], got {n}", line, column)
                    return ast::DataType::Number
                let mut i = 0
                while i < arguments.len() and !self.had_error:
                    let arg_type = self.analyze_expression(arguments[i])
                    if self.had_error:
                        return arg_type
                    if i < b.arg_types.len():
                        match b.arg_types[i]:
                            Option::Some(expected_type) ->
                                # Allow type coercion in BASIC: NUMBER can be
                                # used where STRING is expected.
                                if arg_type != expected_type and !(arg_type == ast::DataType::Number and expected_type == ast::DataType::String):
                                    self.fail(f"Invalid argument type for function '{name}': argument {i + 1} expected {data_type_name(expected_type)}, got {data_type_name(arg_type)}", line, column)
                                    return ast::DataType::Number
                            Option::None -> 0
                    i += 1
                if self.had_error:
                    return ast::DataType::Number
                b.return_type

    # ------------------------------------------------------------------
    # Assignable (left-hand-side) expressions
    # ------------------------------------------------------------------

    fn analyze_assignable_expression(mut self, expr_id: i32, value_type: ast::DataType):
        let expr = self.exprs[expr_id]
        match expr.kind:
            ast::ExprKind::Variable(name) ->
                # Variables are dynamically typed and implicitly global by
                # default, unless an existing local/parameter binding
                # already exists.
                self.symbol_table.define_variable(name, value_type, ast::VarScope::Implicit)
            ast::ExprKind::MemberAccess(object, member) ->
                self.analyze_assignable_member_access(object, member, value_type, expr.line, expr.column)
            ast::ExprKind::ListAccess(list_name, index) ->
                if is_list_name(list_name):
                    self.symbol_table.lists.insert(list_name)
                elif !self.symbol_table.is_defined(list_name):
                    self.symbol_table.lists.insert(list_name)
                elif self.symbol_table.get_type(list_name) != ast::DataType::List:
                    self.fail(f"'{list_name}' is not a list", expr.line, expr.column)
                    return
                let index_type = self.analyze_expression(index)
                if self.had_error:
                    return
                if index_type != ast::DataType::Number:
                    self.fail("List index must be a number", expr.line, expr.column)
            ast::ExprKind::MatrixAccess(matrix_name, row, col) ->
                if !self.symbol_table.is_defined(matrix_name):
                    self.symbol_table.matrices.insert(matrix_name)
                elif self.symbol_table.get_type(matrix_name) != ast::DataType::Matrix:
                    self.fail(f"'{matrix_name}' is not a matrix", expr.line, expr.column)
                    return
                let row_type = self.analyze_expression(row)
                if self.had_error:
                    return
                let col_type = self.analyze_expression(col)
                if self.had_error:
                    return
                if row_type != ast::DataType::Number or col_type != ast::DataType::Number:
                    self.fail("Matrix indices must be numbers", expr.line, expr.column)
            _ ->
                self.fail("Invalid assignment target", expr.line, expr.column)

    fn analyze_assignable_member_access(mut self, object: i32, member: str, value_type: ast::DataType, line: i32, column: i32):
        match self.exprs[object].kind:
            ast::ExprKind::Variable(var_name) ->
                match self.symbol_table.infer_struct_instance_type(var_name, member):
                    Option::Some(struct_name) ->
                        match self.symbol_table.get_struct(struct_name):
                            Option::Some(struct_def) ->
                                if !list_contains_str(struct_def.fields, str_lower(member)):
                                    self.fail(f"Struct '{struct_name}' has no field '{member}'", line, column)
                                elif value_type != ast::DataType::Number:
                                    self.fail("Struct fields can only hold numeric values", line, column)
                            Option::None ->
                                self.fail(f"Variable '{var_name}' is not a struct instance", line, column)
                    Option::None ->
                        self.fail(f"Variable '{var_name}' is not a struct instance", line, column)
            _ ->
                self.fail("Cannot assign to member of non-struct expression", line, column)

# Analyze `program` semantically, reporting the first error found (matching
# the reference's own "raise on first `SemanticError`" behavior -- no
# partial-analysis recovery is attempted either there or here). See this
# file's header comment for why the success case hands `program` itself
# back rather than the reference's bare `None`.
fn analyze(program: ast::Ast, filename: str) -> Result<ast::Ast, SemanticError>:
    let mut a = new_analyzer(program.exprs, program.stmts, filename)

    # First pass: collect all function definitions.
    let mut pi = 0
    while pi < program.program.len() and !a.had_error:
        let stmt_id = program.program[pi]
        match a.stmts[stmt_id].kind:
            ast::StmtKind::FunctionDef(name, params, body) ->
                let key = str_lower(name)
                if a.functions.contains(key):
                    a.fail(f"Function '{name}' already defined", a.stmts[stmt_id].line, a.stmts[stmt_id].column)
                else:
                    a.functions.insert(key, stmt_id)
            _ -> 0
        pi += 1

    # Second pass: analyze all statements.
    let mut si = 0
    while si < program.program.len() and !a.had_error:
        a.analyze_statement(program.program[si])
        si += 1

    # Check every deferred GOTO now that every label has been collected.
    let mut gi = 0
    while gi < a.pending_gotos.len() and !a.had_error:
        let pg = a.pending_gotos[gi]
        if !a.symbol_table.is_label_defined(pg.label):
            a.fail(f"Undefined label '{pg.label}'", pg.line, pg.column)
        gi += 1

    if a.had_error:
        return Result<ast::Ast, SemanticError>::Err(SemanticError(message = a.error_message, filename = filename, line = a.error_line, column = a.error_column))
    Result<ast::Ast, SemanticError>::Ok(program)

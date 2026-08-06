# Star-side half of the parser's Python-cross-checked regression test
# (todo.md P0 #2) -- reads a `.nobasic` source file named on the command
# line, lexes then parses it with `../lexer.star`/`../parser.star`, and
# prints one deterministic, indented line per AST node so a shell script
# can diff it against a fixture generated from the live Python reference
# (`run_parser_test.ps1` in this directory) -- the same "no in-language
# assertion facility, so dump and diff instead" shape `lexer_dump.star`
# already established for the lexer (see `NOTES.md`'s "Testing" section).
#
# Dump format (one node per line, `field=value` pairs, two-space indent per
# nesting level, a child node introduced by its own `.field_name:` header
# line immediately above it): designed alongside, and generated
# byte-for-byte identically by, a throwaway Python reference dumper over
# the live `compiler.parser.ast` node classes (not checked in anywhere --
# see `NOTES.md`'s own "Parser + AST" section for where it lived and the
# regeneration procedure). Reuses `lexer_dump.star`'s own
# `dump_escape`/`format_amount` numeric-literal formatting verbatim so a
# `Literal`'s `num_value` renders identically to how that file already
# renders a `Token`'s `num_value`.
#
# Usage: parser_dump.exe path/to/source.nobasic
# (built via:
#   star build projects/nova/NoBASIC/tests/parser_dump.star -o projects/nova/NoBASIC/tests/parser_dump.exe
# -- a plain text-in/text-out tool, no SDL2 link needed.)

import "../lexer.star" as lex
import "../parser.star" as psr
import "../ast.star" as ast

fn dump_escape(s: str) -> str:
    let s1 = str_replace(s, "\\", "\\\\")
    let s2 = str_replace(s1, "\n", "\\n")
    let s3 = str_replace(s2, "\r", "\\r")
    str_replace(s3, "\t", "\\t")

# Same fixed 2-decimal-place formatter as `lexer_dump.star`'s own
# `format_amount` -- see that file's header comment for why.
fn format_amount(v: f64) -> str:
    let sign = if v < 0 as f64: "-" else: ""
    let av = if v < 0 as f64: -v else: v
    let scaled = (av * (100.0 as f64) + (0.5 as f64)) as i64
    let whole = scaled / (100 as i64)
    let frac = scaled % (100 as i64)
    let frac_str = if frac < (10 as i64): concat("0", f"{frac}") else: f"{frac}"
    concat(sign, concat(f"{whole}", concat(".", frac_str)))

fn pad(indent: i32) -> str:
    let mut parts: List<str> = List<str>()
    let mut i = 0
    while i < indent:
        parts.push("  ")
        i += 1
    str_join(parts, "")

fn scope_name(s: ast::VarScope) -> str:
    match s:
        ast::VarScope::Global -> "GLOBAL"
        ast::VarScope::Local -> "LOCAL"
        ast::VarScope::Implicit -> "IMPLICIT"

fn dump_expr(a: ast::Ast, id: i32, indent: i32):
    let e = a.exprs[id]
    let p = pad(indent)
    match e.kind:
        ast::ExprKind::Literal(data_type, num_value, is_float, str_value) ->
            match data_type:
                ast::DataType::Number ->
                    println(f"{p}{e.line}:{e.column} Literal number={format_amount(num_value)}")
                _ ->
                    println(f"{p}{e.line}:{e.column} Literal string=\"{dump_escape(str_value)}\"")
        ast::ExprKind::Variable(name) ->
            println(f"{p}{e.line}:{e.column} Variable name={name}")
        ast::ExprKind::ListAccess(list_name, index) ->
            println(f"{p}{e.line}:{e.column} ListAccess list_name={list_name}")
            println(f"{p}  .index:")
            dump_expr(a, index, indent + 2)
        ast::ExprKind::MatrixAccess(matrix_name, row, col) ->
            println(f"{p}{e.line}:{e.column} MatrixAccess matrix_name={matrix_name}")
            println(f"{p}  .row:")
            dump_expr(a, row, indent + 2)
            println(f"{p}  .col:")
            dump_expr(a, col, indent + 2)
        ast::ExprKind::MemberAccess(object, member) ->
            println(f"{p}{e.line}:{e.column} MemberAccess member={member}")
            println(f"{p}  .object:")
            dump_expr(a, object, indent + 2)
        ast::ExprKind::Binary(left, operator, right) ->
            println(f"{p}{e.line}:{e.column} Binary operator={operator}")
            println(f"{p}  .left:")
            dump_expr(a, left, indent + 2)
            println(f"{p}  .right:")
            dump_expr(a, right, indent + 2)
        ast::ExprKind::Unary(operator, expr, is_post) ->
            let ip = if is_post: 1 else: 0
            println(f"{p}{e.line}:{e.column} Unary operator={operator} is_post={ip}")
            println(f"{p}  .expr:")
            dump_expr(a, expr, indent + 2)
        ast::ExprKind::Call(name, arguments) ->
            println(f"{p}{e.line}:{e.column} Call name={name} argc={arguments.len()}")
            let mut i = 0
            while i < arguments.len():
                println(f"{p}  .arg[{i}]:")
                dump_expr(a, arguments[i], indent + 2)
                i += 1
        ast::ExprKind::Grouping(expr) ->
            println(f"{p}{e.line}:{e.column} Grouping")
            println(f"{p}  .expr:")
            dump_expr(a, expr, indent + 2)

fn dump_opt_expr(label: str, a: ast::Ast, opt: Option<i32>, indent: i32):
    let p = pad(indent)
    println(f"{p}.{label}:")
    match opt:
        Option::Some(id) -> dump_expr(a, id, indent + 1)
        Option::None -> println(f"{p}  <none>")

fn dump_stmt_list(label: str, a: ast::Ast, stmts: List<i32>, indent: i32):
    let p = pad(indent)
    println(f"{p}.{label}[{stmts.len()}]:")
    let mut i = 0
    while i < stmts.len():
        dump_stmt(a, stmts[i], indent + 1)
        i += 1

fn dump_stmt(a: ast::Ast, id: i32, indent: i32):
    let s = a.stmts[id]
    let p = pad(indent)
    match s.kind:
        ast::StmtKind::ClrDraw ->
            println(f"{p}{s.line}:{s.column} ClrDraw")
        ast::StmtKind::PxlOn(x, y, color) ->
            println(f"{p}{s.line}:{s.column} PxlOn")
            println(f"{p}  .x:")
            dump_expr(a, x, indent + 2)
            println(f"{p}  .y:")
            dump_expr(a, y, indent + 2)
            println(f"{p}  .color:")
            dump_expr(a, color, indent + 2)
        ast::StmtKind::PxlOff(x, y) ->
            println(f"{p}{s.line}:{s.column} PxlOff")
            println(f"{p}  .x:")
            dump_expr(a, x, indent + 2)
            println(f"{p}  .y:")
            dump_expr(a, y, indent + 2)
        ast::StmtKind::Line(x1, y1, x2, y2, color) ->
            println(f"{p}{s.line}:{s.column} Line")
            println(f"{p}  .x1:")
            dump_expr(a, x1, indent + 2)
            println(f"{p}  .y1:")
            dump_expr(a, y1, indent + 2)
            println(f"{p}  .x2:")
            dump_expr(a, x2, indent + 2)
            println(f"{p}  .y2:")
            dump_expr(a, y2, indent + 2)
            println(f"{p}  .color:")
            dump_expr(a, color, indent + 2)
        ast::StmtKind::Circle(x, y, radius, color, filled) ->
            println(f"{p}{s.line}:{s.column} Circle")
            println(f"{p}  .x:")
            dump_expr(a, x, indent + 2)
            println(f"{p}  .y:")
            dump_expr(a, y, indent + 2)
            println(f"{p}  .radius:")
            dump_expr(a, radius, indent + 2)
            println(f"{p}  .color:")
            dump_expr(a, color, indent + 2)
            dump_opt_expr("filled", a, filled, indent + 1)
        ast::StmtKind::Text(x, y, text, color) ->
            println(f"{p}{s.line}:{s.column} Text")
            println(f"{p}  .x:")
            dump_expr(a, x, indent + 2)
            println(f"{p}  .y:")
            dump_expr(a, y, indent + 2)
            println(f"{p}  .text:")
            dump_expr(a, text, indent + 2)
            println(f"{p}  .color:")
            dump_expr(a, color, indent + 2)
        ast::StmtKind::SetLayer(layer) ->
            println(f"{p}{s.line}:{s.column} SetLayer")
            println(f"{p}  .layer:")
            dump_expr(a, layer, indent + 2)
        ast::StmtKind::SRol(axis, amount) ->
            println(f"{p}{s.line}:{s.column} SRol")
            println(f"{p}  .axis:")
            dump_expr(a, axis, indent + 2)
            println(f"{p}  .amount:")
            dump_expr(a, amount, indent + 2)
        ast::StmtKind::SRot(direction, amount) ->
            println(f"{p}{s.line}:{s.column} SRot")
            println(f"{p}  .direction:")
            dump_expr(a, direction, indent + 2)
            println(f"{p}  .amount:")
            dump_expr(a, amount, indent + 2)
        ast::StmtKind::SShft(axis, amount) ->
            println(f"{p}{s.line}:{s.column} SShft")
            println(f"{p}  .axis:")
            dump_expr(a, axis, indent + 2)
            println(f"{p}  .amount:")
            dump_expr(a, amount, indent + 2)
        ast::StmtKind::SFlip(axis) ->
            println(f"{p}{s.line}:{s.column} SFlip")
            println(f"{p}  .axis:")
            dump_expr(a, axis, indent + 2)
        ast::StmtKind::SpriteOn(sprite_id, x, y) ->
            println(f"{p}{s.line}:{s.column} SpriteOn")
            println(f"{p}  .sprite_id:")
            dump_expr(a, sprite_id, indent + 2)
            println(f"{p}  .x:")
            dump_expr(a, x, indent + 2)
            println(f"{p}  .y:")
            dump_expr(a, y, indent + 2)
        ast::StmtKind::SpriteOff(sprite_id) ->
            println(f"{p}{s.line}:{s.column} SpriteOff")
            println(f"{p}  .sprite_id:")
            dump_expr(a, sprite_id, indent + 2)
        ast::StmtKind::PlayTone(frequency, duration, volume) ->
            println(f"{p}{s.line}:{s.column} PlayTone")
            println(f"{p}  .frequency:")
            dump_expr(a, frequency, indent + 2)
            println(f"{p}  .duration:")
            dump_expr(a, duration, indent + 2)
            println(f"{p}  .volume:")
            dump_expr(a, volume, indent + 2)
        ast::StmtKind::PlayWave(waveform, frequency, volume) ->
            println(f"{p}{s.line}:{s.column} PlayWave")
            println(f"{p}  .waveform:")
            dump_expr(a, waveform, indent + 2)
            println(f"{p}  .frequency:")
            dump_expr(a, frequency, indent + 2)
            println(f"{p}  .volume:")
            dump_expr(a, volume, indent + 2)
        ast::StmtKind::StopSound ->
            println(f"{p}{s.line}:{s.column} StopSound")
        ast::StmtKind::SetChannel(channel) ->
            println(f"{p}{s.line}:{s.column} SetChannel")
            println(f"{p}  .channel:")
            dump_expr(a, channel, indent + 2)
        ast::StmtKind::GetKey ->
            println(f"{p}{s.line}:{s.column} GetKey")
        ast::StmtKind::SerOut(value) ->
            println(f"{p}{s.line}:{s.column} SerOut")
            println(f"{p}  .value:")
            dump_expr(a, value, indent + 2)
        ast::StmtKind::SerIn(variable) ->
            println(f"{p}{s.line}:{s.column} SerIn variable={variable}")
        ast::StmtKind::SerStat(variable) ->
            println(f"{p}{s.line}:{s.column} SerStat variable={variable}")
        ast::StmtKind::SerCtrl(value) ->
            println(f"{p}{s.line}:{s.column} SerCtrl")
            println(f"{p}  .value:")
            dump_expr(a, value, indent + 2)
        ast::StmtKind::Input(prompt, variable) ->
            println(f"{p}{s.line}:{s.column} Input variable={variable}")
            dump_opt_expr("prompt", a, prompt, indent + 1)
        ast::StmtKind::Disp(text) ->
            println(f"{p}{s.line}:{s.column} Disp")
            println(f"{p}  .text:")
            dump_expr(a, text, indent + 2)
        ast::StmtKind::Pause ->
            println(f"{p}{s.line}:{s.column} Pause")
        ast::StmtKind::FunctionCall(call) ->
            println(f"{p}{s.line}:{s.column} FunctionCall")
            println(f"{p}  .call:")
            dump_expr(a, call, indent + 2)
        ast::StmtKind::ExpressionStmt(expr) ->
            println(f"{p}{s.line}:{s.column} ExpressionStmt")
            println(f"{p}  .expr:")
            dump_expr(a, expr, indent + 2)
        ast::StmtKind::Assignment(variable, expr) ->
            println(f"{p}{s.line}:{s.column} Assignment")
            println(f"{p}  .variable:")
            dump_expr(a, variable, indent + 2)
            println(f"{p}  .expr:")
            dump_expr(a, expr, indent + 2)
        ast::StmtKind::If(condition, then_branch, else_branch) ->
            println(f"{p}{s.line}:{s.column} If")
            println(f"{p}  .condition:")
            dump_expr(a, condition, indent + 2)
            dump_stmt_list("then", a, then_branch, indent + 1)
            match else_branch:
                Option::Some(eb) -> dump_stmt_list("else", a, eb, indent + 1)
                Option::None -> println(f"{p}  .else: <none>")
        ast::StmtKind::For(variable, start, end, step, body) ->
            println(f"{p}{s.line}:{s.column} For variable={variable}")
            println(f"{p}  .start:")
            dump_expr(a, start, indent + 2)
            println(f"{p}  .end:")
            dump_expr(a, end, indent + 2)
            dump_opt_expr("step", a, step, indent + 1)
            dump_stmt_list("body", a, body, indent + 1)
        ast::StmtKind::While(condition, body) ->
            println(f"{p}{s.line}:{s.column} While")
            println(f"{p}  .condition:")
            dump_expr(a, condition, indent + 2)
            dump_stmt_list("body", a, body, indent + 1)
        ast::StmtKind::Repeat(body, condition) ->
            println(f"{p}{s.line}:{s.column} Repeat")
            dump_stmt_list("body", a, body, indent + 1)
            println(f"{p}  .condition:")
            dump_expr(a, condition, indent + 2)
        ast::StmtKind::Goto(label) ->
            println(f"{p}{s.line}:{s.column} Goto label={label}")
        ast::StmtKind::Label(label) ->
            println(f"{p}{s.line}:{s.column} Label label={label}")
        ast::StmtKind::StructDecl(name, fields) ->
            let fields_joined = str_join(fields, ",")
            println(f"{p}{s.line}:{s.column} StructDecl name={name} fields={fields_joined}")
        ast::StmtKind::VarDecl(scope, variables) ->
            let vars_joined = str_join(variables, ",")
            println(f"{p}{s.line}:{s.column} VarDecl scope={scope_name(scope)} variables={vars_joined}")
        ast::StmtKind::AsmBlock(assembly_code) ->
            println(f"{p}{s.line}:{s.column} AsmBlock code=\"{dump_escape(assembly_code)}\"")
        ast::StmtKind::FunctionDef(name, params, body) ->
            println(f"{p}{s.line}:{s.column} FunctionDef name={name} paramc={params.len()}")
            let mut i = 0
            while i < params.len():
                let prm = params[i]
                match prm.default:
                    Option::Some(d) ->
                        println(f"{p}  .param[{i}] name={prm.name} has_default=1")
                        println(f"{p}    .default:")
                        dump_expr(a, d, indent + 3)
                    Option::None ->
                        println(f"{p}  .param[{i}] name={prm.name} has_default=0")
                i += 1
            dump_stmt_list("body", a, body, indent + 1)
        ast::StmtKind::Return(value) ->
            println(f"{p}{s.line}:{s.column} Return")
            dump_opt_expr("value", a, value, indent + 1)

fn main() -> i32:
    let cli = args()
    if cli.len() < 2:
        println("usage: parser_dump <path.nobasic>")
        return 1
    let path = cli[1]
    let h = file_open(path, "r")
    if is_null(h):
        println(concat("could not open '", concat(path, "'")))
        return 1
    let source = file_read(h)
    file_close(h)

    let tokens = match lex::lex(source, path):
        Result::Ok(toks) -> toks
        Result::Err(e) ->
            println(concat("LEX ERROR: ", lex::format_lex_error(e)))
            return 1

    match psr::parse(tokens, path):
        Result::Ok(a) ->
            println(f"program[{a.program.len()}]:")
            let mut i = 0
            while i < a.program.len():
                dump_stmt(a, a.program[i], 1)
                i += 1
            return 0
        Result::Err(e) ->
            println(concat("PARSE ERROR: ", psr::format_parse_error(e)))
            return 1
    0

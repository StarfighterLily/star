# NoBASIC expression codegen -- part of `codegen.star`'s `Codegen` (see that
# file's header comment for the overall file split and this round's scope).
# Ports `generator.py`'s `generate_expression`/`generate_binary_expression`/
# `generate_unary_expression`/`generate_function_call` and their small
# helpers (`fold_constants` callers, strength reduction, signed div/mod).
#
# `generate_expression`'s reference `try/except Exception ... finally:
# deallocate; raise` (register cleanup on internal-invariant failure) is not
# reproduced -- this port's `had_error`-flag convention has no exception
# unwind to hook a `finally` onto (same as every earlier phase's own header
# comment explains). A `fail()`'d expression leaves whatever partial
# register state existed at the failure point; callers are expected to stop
# generating further code once `had_error` is set (exactly like
# `semantic.star`'s analyzer), not to keep compiling around a leaked
# register.

import "ast.star" as ast
import "codegen.star" as codegen

fn normalize_numeric_literal(num_value: f64) -> i32:
    num_value as i32

fn list_contains_i32(items: List<i32>, target: i32) -> bool:
    let mut i = 0
    while i < items.len():
        if items[i] == target:
            return true
        i += 1
    false

# Number of bits needed to represent `v` (`v.bit_length()` in Python) --
# `v` is always a positive power of two at both of this file's call sites
# (a literal known to be in `[2,4,...,1024]`, or a strength-reduction
# `factor` already confirmed a power of two via `factor & (factor - 1) ==
# 0`), so this only needs to handle that case correctly, not `v <= 0`.
fn bit_length(v: i32) -> i32:
    let mut n = v
    let mut bits = 0
    while n > 0:
        n = n >> 1
        bits += 1
    bits

# Numeric literal value of `expr_id` if it is a plain `NUMBER` literal, else
# `None` -- mirrors `_extract_numeric_literal_value`.
fn literal_numeric_value(cg: codegen::Codegen, expr_id: i32) -> Option<i32>:
    let e = cg.exprs[expr_id]
    match e.kind:
        ast::ExprKind::Literal(data_type, num_value, is_float, str_value) ->
            if data_type == ast::DataType::Number:
                Option<i32>::Some(normalize_numeric_literal(num_value))
            else:
                Option<i32>::None
        _ -> Option<i32>::None

impl codegen::Codegen:
    fn function_params(self, stmt_id: i32) -> List<ast::Param>:
        match self.stmts[stmt_id].kind:
            ast::StmtKind::FunctionDef(fname, params, body) -> params
            _ -> List<ast::Param>()

    fn function_body(self, stmt_id: i32) -> List<i32>:
        match self.stmts[stmt_id].kind:
            ast::StmtKind::FunctionDef(fname, params, body) -> body
            _ -> List<i32>()

    fn widen_to_p_register_if_needed(mut self, target_reg: str, value: i32) -> str:
        if !((value > 255 or value < 0) and codegen::str_starts_with(target_reg, "R")):
            return target_reg
        self.deallocate_register(target_reg)
        let p_regs = ["P0", "P1", "P2", "P3", "P4", "P5", "P6", "P7"]
        let mut i = 0
        while i < p_regs.len():
            if !codegen::opt_bool_or(self.register_usage.get(p_regs[i]), false):
                return self.allocate_register(Option<str>::Some(p_regs[i]))
            i += 1
        self.fail(f"No available P registers for 16-bit value {value}", 0, 0)
        target_reg

    # Generate an expression directly into a target (hardware or general)
    # register, avoiding an intermediate `MOV`. Only the plain-value paths
    # this round's builtin set actually needs (`STREXT`/`STREXTI`) are
    # ported; the reference's own hardware-register (`VX`/`VY`/`VC`/...)
    # fast paths aren't exercised by anything in scope yet and fall through
    # to the generic "evaluate then MOV" branch, which is still correct,
    # just not maximally tight.
    fn generate_expression_into(mut self, expr_id: i32, target_reg: str):
        let temp_reg = self.generate_expression(expr_id, Option<str>::None)
        if temp_reg != target_reg:
            self.current_output.push(f"MOV {target_reg}, {temp_reg}")
        self.deallocate_register(temp_reg)

    fn generate_expression(mut self, expr_id: i32, preferred_reg: Option<str>) -> str:
        let mut needs_p_register = self.is_string_expression(expr_id)
        let expr = self.exprs[expr_id]
        match expr.kind:
            ast::ExprKind::Call(name, arguments) ->
                if codegen::list_contains_str(codegen::wide_result_math_builtins(), codegen::str_upper(name)):
                    needs_p_register = true
            _ -> 0

        let mut pref = preferred_reg
        match pref:
            Option::Some(p) ->
                if needs_p_register and codegen::str_starts_with(p, "R"):
                    pref = Option<str>::None
            Option::None -> 0

        let mut pref_is_none = true
        match pref:
            Option::Some(pv) ->
                pref_is_none = false
            Option::None -> 0

        if needs_p_register and pref_is_none:
            let p_regs = ["P0", "P1", "P2", "P3", "P4", "P5", "P6", "P7"]
            let mut i = 0
            while i < p_regs.len():
                if !codegen::opt_bool_or(self.register_usage.get(p_regs[i]), false):
                    pref = Option<str>::Some(p_regs[i])
                    break
                i += 1

        let mut target_reg = ""
        let mut pref_free = false
        match pref:
            Option::Some(p) ->
                if !codegen::opt_bool_or(self.register_usage.get(p), true):
                    pref_free = true
            Option::None -> 0

        if pref_free:
            match pref:
                Option::Some(p) ->
                    target_reg = self.allocate_register(Option<str>::Some(p))
                Option::None -> 0
        elif needs_p_register:
            let p_regs = ["P0", "P1", "P2", "P3", "P4", "P5", "P6", "P7"]
            let mut i = 0
            let mut found = false
            while i < p_regs.len():
                if !codegen::opt_bool_or(self.register_usage.get(p_regs[i]), false):
                    target_reg = self.allocate_register(Option<str>::Some(p_regs[i]))
                    found = true
                    break
                i += 1
            if !found:
                self.fail("No available P registers for string expression", expr.line, expr.column)
                target_reg = "P1"
        else:
            target_reg = self.allocate_register(Option<str>::None)

        let mut result_reg = target_reg
        match expr.kind:
            ast::ExprKind::Literal(data_type, num_value, is_float, str_value) ->
                if data_type == ast::DataType::Number:
                    let literal_value = normalize_numeric_literal(num_value)
                    target_reg = self.widen_to_p_register_if_needed(target_reg, literal_value)
                    if literal_value == 0:
                        self.current_output.push(f"XOR {target_reg}, {target_reg}")
                    elif literal_value == 1:
                        self.current_output.push(f"MOV {target_reg}, 1")
                    elif list_contains_i32([2, 4, 8, 16, 32, 64, 128, 256, 512, 1024], literal_value):
                        self.current_output.push(f"MOV {target_reg}, 1")
                        self.current_output.push(f"SHL {target_reg}, {bit_length(literal_value) - 1}")
                    else:
                        self.current_output.push(f"MOV {target_reg}, {literal_value}")
                    result_reg = target_reg
                elif data_type == ast::DataType::String:
                    if codegen::str_starts_with(target_reg, "R"):
                        self.deallocate_register(target_reg)
                        target_reg = self.allocate_p_register(["P1", "P2", "P3"])
                    let label = self.add_string_literal(str_value)
                    self.current_output.push(f"MOV {target_reg}, {label}")
                    result_reg = target_reg
                else:
                    self.current_output.push(f"MOV {target_reg}, 0")
                    result_reg = target_reg
            ast::ExprKind::Variable(name) ->
                result_reg = self.load_variable(name, target_reg)
            ast::ExprKind::Binary(left, operator, right) ->
                result_reg = self.generate_binary_expression(expr_id, target_reg)
            ast::ExprKind::Unary(operator, inner, is_post) ->
                result_reg = self.generate_unary_expression(expr_id, target_reg)
            ast::ExprKind::Call(name, arguments) ->
                result_reg = self.generate_function_call(expr_id, target_reg)
            ast::ExprKind::Grouping(inner) ->
                self.deallocate_register(target_reg)
                result_reg = self.generate_expression(inner, Option<str>::Some(target_reg))
            _ ->
                self.fail(f"Codegen core: this expression kind is not yet ported (todo.md P1 #1 remaining work)", expr.line, expr.column)
                self.current_output.push(f"MOV {target_reg}, 0")
                result_reg = target_reg
        result_reg

    fn emit_signed_div(mut self, target_reg: str, right_result: str):
        let left_pos = self.new_label()
        let neg_neg = self.new_label()
        let pos_pos = self.new_label()
        let done = self.new_label()

        self.current_output.push(f"CMP {target_reg}, 0")
        self.current_output.push(f"JGE {left_pos}")
        self.current_output.push(f"NEG {target_reg}")
        self.current_output.push(f"CMP {right_result}, 0")
        self.current_output.push(f"JGE {neg_neg}")
        self.current_output.push(f"NEG {right_result}")
        self.current_output.push(f"DIV {target_reg}, {right_result}")
        self.current_output.push(f"JMP {done}")
        self.current_output.push(f"{neg_neg}:")
        self.current_output.push(f"DIV {target_reg}, {right_result}")
        self.current_output.push(f"NEG {target_reg}")
        self.current_output.push(f"JMP {done}")
        self.current_output.push(f"{left_pos}:")
        self.current_output.push(f"CMP {right_result}, 0")
        self.current_output.push(f"JGE {pos_pos}")
        self.current_output.push(f"NEG {right_result}")
        self.current_output.push(f"DIV {target_reg}, {right_result}")
        self.current_output.push(f"NEG {target_reg}")
        self.current_output.push(f"JMP {done}")
        self.current_output.push(f"{pos_pos}:")
        self.current_output.push(f"DIV {target_reg}, {right_result}")
        self.current_output.push(f"{done}:")

    fn emit_signed_mod(mut self, target_reg: str, right_result: str):
        let right_ok = self.new_label()
        let left_ok = self.new_label()
        let done = self.new_label()

        self.current_output.push(f"CMP {right_result}, 0")
        self.current_output.push(f"JGE {right_ok}")
        self.current_output.push(f"NEG {right_result}")
        self.current_output.push(f"{right_ok}:")
        self.current_output.push(f"CMP {target_reg}, 0")
        self.current_output.push(f"JGE {left_ok}")
        self.current_output.push(f"NEG {target_reg}")
        self.current_output.push(f"MOD {target_reg}, {right_result}")
        self.current_output.push(f"NEG {target_reg}")
        self.current_output.push(f"JMP {done}")
        self.current_output.push(f"{left_ok}:")
        self.current_output.push(f"MOD {target_reg}, {right_result}")
        self.current_output.push(f"{done}:")

    # Lower `x * 2^n` (either operand order) to a shift when semantics-safe.
    # Mirrors `_try_generate_strength_reduced_multiply`.
    fn try_generate_strength_reduced_multiply(mut self, expr_id: i32, target_reg: str) -> Option<str>:
        let expr = self.exprs[expr_id]
        match expr.kind:
            ast::ExprKind::Binary(left, operator, right) ->
                if operator != "*":
                    return Option<str>::None

                let left_literal = literal_numeric_value(self, left)
                let right_literal = literal_numeric_value(self, right)

                let mut factor = 0
                let mut value_expr = -1
                let mut have_factor = false
                match right_literal:
                    Option::Some(f) ->
                        factor = f
                        value_expr = left
                        have_factor = true
                    Option::None ->
                        match left_literal:
                            Option::Some(f) ->
                                factor = f
                                value_expr = right
                                have_factor = true
                            Option::None -> 0

                if !have_factor:
                    return Option<str>::None
                if factor <= 1 or (factor & (factor - 1)) != 0:
                    return Option<str>::None

                let value_reg = self.generate_expression(value_expr, Option<str>::None)
                if value_reg != target_reg:
                    self.current_output.push(f"MOV {target_reg}, {value_reg}")
                self.current_output.push(f"SHL {target_reg}, {bit_length(factor) - 1}")
                if value_reg != target_reg:
                    self.smart_deallocate(value_reg, true)
                return Option<str>::Some(target_reg)
            _ -> Option<str>::None

    fn generate_binary_expression(mut self, expr_id: i32, target_reg: str) -> str:
        let expr = self.exprs[expr_id]
        match expr.kind:
            ast::ExprKind::Binary(left, operator, right) ->
                self.generate_binary_expression_impl(expr_id, left, operator, right, target_reg, expr.line, expr.column)
            _ ->
                self.fail("generate_binary_expression called on non-Binary expression", expr.line, expr.column)
                target_reg

    fn generate_binary_expression_impl(mut self, expr_id: i32, left: i32, operator: str, right: i32, target_reg: str, line: i32, column: i32) -> str:
        # Constant folding.
        let left_lit = literal_numeric_value(self, left)
        let right_lit = literal_numeric_value(self, right)
        match left_lit:
            Option::Some(lv) ->
                match right_lit:
                    Option::Some(rv) ->
                        match self.fold_constants(operator, lv, rv):
                            Option::Some(folded) ->
                                self.current_output.push(f"; Constant folded: {lv} {operator} {rv} = {folded}")
                                self.current_output.push(f"MOV {target_reg}, {folded}")
                                return target_reg
                            Option::None -> 0
                    Option::None -> 0
            Option::None -> 0

        match self.try_generate_strength_reduced_multiply(expr_id, target_reg):
            Option::Some(r) ->
                return r
            Option::None -> 0

        let mut is_string_concat = false
        if operator == "+":
            is_string_concat = self.is_string_expression(left) or self.is_string_expression(right)

        if is_string_concat:
            let mut t = target_reg
            if codegen::str_starts_with(t, "R"):
                self.deallocate_register(t)
                t = self.allocate_p_register(["P1", "P2", "P3"])

            let mut left_result = self.generate_expression(left, Option<str>::None)
            if left_result != "P2":
                self.current_output.push(f"MOV P2, {left_result}")
                self.smart_deallocate(left_result, true)
                left_result = "P2"
                self.register_usage.insert("P2", true)

            let mut right_result = self.generate_expression(right, Option<str>::None)
            if right_result != "P3":
                self.current_output.push(f"MOV P3, {right_result}")
                self.smart_deallocate(right_result, true)
                right_result = "P3"
                self.register_usage.insert("P3", true)

            let buffer_addr = self.reserve_data_memory(256, "string concatenation buffer")
            self.current_output.push(f"MOV P0, {buffer_addr}")
            self.current_output.push(f"STRCPY P0, {left_result}")
            self.current_output.push(f"STRCAT P0, {right_result}")
            self.current_output.push(f"MOV {t}, {buffer_addr}")
            self.deallocate_register("P2")
            self.deallocate_register("P3")
            return t

        let is_comparison = operator == "<" or operator == ">" or operator == "=" or operator == "<>" or operator == "<=" or operator == ">="

        let mut available_regs: List<str> = List<str>()
        if is_comparison:
            available_regs = ["P1", "P2", "P3", "P4", "P5", "P6", "P7"]
        else:
            let mut i = 0
            while i < self.allocation_order.len():
                if self.allocation_order[i] != target_reg:
                    available_regs.push(self.allocation_order[i])
                i += 1

        let mut left_pref: Option<str> = Option<str>::None
        let mut right_pref: Option<str> = Option<str>::None
        if available_regs.len() > 0:
            left_pref = Option<str>::Some(available_regs[0])
        if available_regs.len() > 1:
            right_pref = Option<str>::Some(available_regs[1])

        let mut left_result = self.generate_expression(left, left_pref)

        let mut left_preserved_reg: Option<str> = Option<str>::None

        if is_comparison:
            self.register_usage.insert(left_result, true)

        if !is_comparison:
            self.current_output.push("; Preserve left operand in register across right-side evaluation")
            let mut i = 0
            while i < self.allocation_order.len():
                let reg = self.allocation_order[i]
                if !codegen::opt_bool_or(self.register_usage.get(reg), false) and reg != target_reg:
                    left_preserved_reg = Option<str>::Some(reg)
                    self.current_output.push(f"MOV {reg}, {left_result}")
                    self.register_usage.insert(reg, true)
                    break
                i += 1

            match left_preserved_reg:
                Option::None ->
                    if codegen::str_starts_with(left_result, "R"):
                        let p_temp = if !codegen::opt_bool_or(self.register_usage.get("P1"), false): "P1" else: "P2"
                        self.current_output.push(f"MOV {p_temp}, {left_result}")
                        self.current_output.push(f"PUSH {p_temp}")
                    else:
                        self.current_output.push(f"PUSH {left_result}")
                Option::Some(pv) -> 0

        let mut right_result = self.generate_expression(right, right_pref)

        if is_comparison and right_result == left_result:
            let candidates = ["P2", "P3", "P4", "P5", "P6", "P7", "P1"]
            let mut i = 0
            while i < candidates.len():
                let reg = candidates[i]
                if reg != left_result and !codegen::opt_bool_or(self.register_usage.get(reg), false):
                    self.current_output.push(f"MOV {reg}, {right_result}")
                    right_result = reg
                    self.register_usage.insert(reg, true)
                    break
                i += 1

        if !is_comparison:
            match left_preserved_reg:
                Option::Some(reg) ->
                    left_result = reg
                Option::None ->
                    self.current_output.push("POP P1")
                    if left_result != "P1":
                        self.current_output.push(f"MOV {left_result}, P1")

        if operator == "+":
            if left_result == target_reg:
                self.current_output.push(f"ADD {target_reg}, {right_result}")
            else:
                self.current_output.push(f"MOV {target_reg}, {left_result}")
                self.current_output.push(f"ADD {target_reg}, {right_result}")
        elif operator == "-":
            if left_result == target_reg:
                self.current_output.push(f"SUB {target_reg}, {right_result}")
            else:
                self.current_output.push(f"MOV {target_reg}, {left_result}")
                self.current_output.push(f"SUB {target_reg}, {right_result}")
        elif operator == "*":
            if left_result == target_reg:
                self.current_output.push(f"MUL {target_reg}, {right_result}")
            else:
                self.current_output.push(f"MOV {target_reg}, {left_result}")
                self.current_output.push(f"MUL {target_reg}, {right_result}")
        elif operator == "/":
            if left_result != target_reg:
                self.current_output.push(f"MOV {target_reg}, {left_result}")
            self.emit_signed_div(target_reg, right_result)
        elif operator == "%" or operator == "MOD":
            if left_result != target_reg:
                self.current_output.push(f"MOV {target_reg}, {left_result}")
            self.emit_signed_mod(target_reg, right_result)
        elif operator == "&" or operator == "AND":
            if left_result == target_reg:
                self.current_output.push(f"AND {target_reg}, {right_result}")
            else:
                self.current_output.push(f"MOV {target_reg}, {left_result}")
                self.current_output.push(f"AND {target_reg}, {right_result}")
        elif operator == "|" or operator == "OR":
            if left_result == target_reg:
                self.current_output.push(f"OR {target_reg}, {right_result}")
            else:
                self.current_output.push(f"MOV {target_reg}, {left_result}")
                self.current_output.push(f"OR {target_reg}, {right_result}")
        elif operator == "^" or operator == "XOR":
            if left_result == target_reg:
                self.current_output.push(f"XOR {target_reg}, {right_result}")
            else:
                self.current_output.push(f"MOV {target_reg}, {left_result}")
                self.current_output.push(f"XOR {target_reg}, {right_result}")
        elif operator == "<<" or operator == "SHL":
            if left_result == target_reg:
                self.current_output.push(f"SHL {target_reg}, {right_result}")
            else:
                self.current_output.push(f"MOV {target_reg}, {left_result}")
                self.current_output.push(f"SHL {target_reg}, {right_result}")
        elif operator == ">>" or operator == "SHR":
            if left_result == target_reg:
                self.current_output.push(f"SHR {target_reg}, {right_result}")
            else:
                self.current_output.push(f"MOV {target_reg}, {left_result}")
                self.current_output.push(f"SHR {target_reg}, {right_result}")
        elif operator == "<<<" or operator == "SAL":
            if left_result != target_reg:
                self.current_output.push(f"MOV {target_reg}, {left_result}")
            self.current_output.push(f"SAL {target_reg}, {right_result}")
        elif operator == ">>>" or operator == "SAR":
            if left_result != target_reg:
                self.current_output.push(f"MOV {target_reg}, {left_result}")
            self.current_output.push(f"SAR {target_reg}, {right_result}")
        elif operator == "<@>" or operator == "ROL":
            if left_result != target_reg:
                self.current_output.push(f"MOV {target_reg}, {left_result}")
            self.current_output.push(f"ROL {target_reg}, {right_result}")
        elif operator == "@>" or operator == "ROR":
            if left_result != target_reg:
                self.current_output.push(f"MOV {target_reg}, {left_result}")
            self.current_output.push(f"ROR {target_reg}, {right_result}")
        elif operator == "<@@" or operator == "RCL":
            if left_result != target_reg:
                self.current_output.push(f"MOV {target_reg}, {left_result}")
            self.current_output.push(f"RCL {target_reg}, {right_result}")
        elif operator == "@@>" or operator == "RCR":
            if left_result != target_reg:
                self.current_output.push(f"MOV {target_reg}, {left_result}")
            self.current_output.push(f"RCR {target_reg}, {right_result}")
        elif is_comparison:
            if operator == "=" or operator == "<>":
                self.current_output.push(f"XOR {target_reg}, {target_reg}")
                self.current_output.push(f"CMP {left_result}, {right_result}")
                let predicated_move = if operator == "=": "MOVZ" else: "MOVNZ"
                self.current_output.push(f"{predicated_move} {target_reg}, 1")
                self.smart_deallocate(left_result, true)
                self.smart_deallocate(right_result, true)
                match left_preserved_reg:
                    Option::Some(r) -> self.deallocate_register(r)
                    Option::None -> 0
                return target_reg

            self.current_output.push(f"CMP {left_result}, {right_result}")
            self.smart_deallocate(left_result, true)
            self.smart_deallocate(right_result, true)

            let true_label = self.new_label()
            let end_label = self.new_label()
            self.current_output.push(f"MOV {target_reg}, 0")
            if operator == "<":
                self.current_output.push(f"JLT {true_label}")
            elif operator == ">":
                self.current_output.push(f"JGT {true_label}")
            elif operator == "<=":
                self.current_output.push(f"JLE {true_label}")
            elif operator == ">=":
                self.current_output.push(f"JGE {true_label}")
            self.current_output.push(f"JMP {end_label}")
            self.current_output.push(f"{true_label}:")
            self.current_output.push(f"MOV {target_reg}, 1")
            self.current_output.push(f"{end_label}:")
            match left_preserved_reg:
                Option::Some(r) -> self.deallocate_register(r)
                Option::None -> 0
            return target_reg
        else:
            self.current_output.push(f"MOV {target_reg}, 0")

        if left_result != target_reg:
            self.smart_deallocate(left_result, true)
        if right_result != target_reg:
            self.smart_deallocate(right_result, true)
        match left_preserved_reg:
            Option::Some(r) -> self.deallocate_register(r)
            Option::None -> 0
        target_reg

    fn generate_unary_expression(mut self, expr_id: i32, target_reg: str) -> str:
        let expr = self.exprs[expr_id]
        match expr.kind:
            ast::ExprKind::Unary(operator, inner, is_post) ->
                self.generate_unary_expression_impl(operator, inner, is_post, target_reg, expr.line, expr.column)
            _ ->
                self.fail("generate_unary_expression called on non-Unary expression", expr.line, expr.column)
                target_reg

    fn generate_unary_expression_impl(mut self, operator: str, inner: i32, is_post: bool, target_reg: str, line: i32, column: i32) -> str:
        if operator == "++" or operator == "--":
            let inner_expr = self.exprs[inner]
            let mut value_reg: Option<str> = Option<str>::None
            let mut var_name = ""

            match inner_expr.kind:
                ast::ExprKind::Variable(name) ->
                    var_name = name
                    let dest = if codegen::str_starts_with(target_reg, "P"): target_reg else: "P1"
                    value_reg = Option<str>::Some(self.load_variable(name, dest))
                _ -> 0

            match value_reg:
                Option::Some(vreg) ->
                    if is_post and target_reg != vreg:
                        self.current_output.push(f"MOV {target_reg}, {vreg}")
                    if operator == "++":
                        self.current_output.push(f"ADD {vreg}, 1")
                    else:
                        self.current_output.push(f"SUB {vreg}, 1")
                    self.store_variable(var_name, vreg)
                    if !is_post and target_reg != vreg:
                        self.current_output.push(f"MOV {target_reg}, {vreg}")
                    return target_reg
                Option::None -> 0

            let operand_reg = self.generate_expression(inner, Option<str>::Some(target_reg))
            if operand_reg != target_reg:
                self.current_output.push(f"MOV {target_reg}, {operand_reg}")
                self.smart_deallocate(operand_reg, true)
            return target_reg

        match self.exprs[inner].kind:
            ast::ExprKind::Literal(data_type, num_value, is_float, str_value) ->
                if data_type == ast::DataType::Number:
                    let orig_value = normalize_numeric_literal(num_value)
                    match self.fold_unary_constant(operator, orig_value):
                        Option::Some(folded) ->
                            let widened = self.widen_to_p_register_if_needed(target_reg, folded)
                            self.current_output.push(f"; Constant folded: {operator}({orig_value}) = {folded}")
                            self.current_output.push(f"MOV {widened}, {folded}")
                            return widened
                        Option::None -> 0
            _ -> 0

        let operand_reg = self.generate_expression(inner, Option<str>::Some(target_reg))

        if operator == "-":
            if operand_reg != target_reg:
                self.current_output.push(f"MOV {target_reg}, {operand_reg}")
                self.smart_deallocate(operand_reg, true)
            self.current_output.push(f"NEG {target_reg}")
        elif operator == "NOT":
            if operand_reg != target_reg:
                self.current_output.push(f"MOV {target_reg}, {operand_reg}")
                self.smart_deallocate(operand_reg, true)
            self.current_output.push(f"NOT {target_reg}")
        elif operator == "ABS":
            if operand_reg != target_reg:
                self.current_output.push(f"MOV {target_reg}, {operand_reg}")
                self.smart_deallocate(operand_reg, true)
            self.current_output.push(f"ABS {target_reg}")
        else:
            if operand_reg != target_reg:
                self.current_output.push(f"MOV {target_reg}, {operand_reg}")
                self.smart_deallocate(operand_reg, true)
        target_reg

    # ------------------------------------------------------------------
    # Function calls -- user-defined functions in full, plus the builtin
    # subset this round covers. See `codegen.star`'s header comment for the
    # exact list of builtins not yet ported (and the `LN`/`POW` reference
    # bug deliberately left unfixed).
    # ------------------------------------------------------------------

    fn generate_function_call(mut self, expr_id: i32, target_reg: str) -> str:
        let expr = self.exprs[expr_id]
        match expr.kind:
            ast::ExprKind::Call(name, arguments) ->
                let func_name_lower = codegen::str_lower(name)
                let func_name = codegen::str_upper(name)

                match self.functions.get(func_name_lower):
                    Option::Some(stmt_id) ->
                        return self.generate_user_function_call(stmt_id, func_name_lower, arguments, target_reg)
                    Option::None -> 0

                self.generate_builtin_call(func_name, arguments, target_reg, expr.line, expr.column)
            _ ->
                self.fail("generate_function_call called on non-Call expression", expr.line, expr.column)
                target_reg

    fn generate_user_function_call(mut self, stmt_id: i32, func_key: str, arguments: List<i32>, target_reg: str) -> str:
        let label = match self.function_labels.get(func_key):
            Option::Some(l) -> l
            Option::None -> ""
        if label == "":
            self.fail(f"Internal error: no label registered for function '{func_key}'", 0, 0)
            return target_reg

        let saved_var_regs = self.var_reg_distinct_regs()
        let mut i = 0
        while i < saved_var_regs.len():
            let reg = saved_var_regs[i]
            if reg != "SP" and reg != "FP" and codegen::str_starts_with(reg, "P"):
                self.current_output.push(f"PUSH {reg}")
            i += 1

        let params = self.function_params(stmt_id)

        # Provided arguments first, then defaults for any missing trailing
        # parameters -- mirrors the reference's `all_args` construction.
        let mut arg_exprs: List<i32> = List<i32>()
        i = 0
        while i < arguments.len():
            arg_exprs.push(arguments[i])
            i += 1
        i = arguments.len()
        while i < params.len():
            match params[i].default:
                Option::Some(d) -> arg_exprs.push(d)
                Option::None ->
                    self.fail(f"Missing required argument for parameter '{params[i].name}'", 0, 0)
                    return target_reg
            i += 1

        i = 0
        while i < arg_exprs.len():
            let arg_reg = self.generate_expression(arg_exprs[i], Option<str>::None)
            if codegen::str_starts_with(arg_reg, "R"):
                let p_temp = self.allocate_p_register(["P1", "P2", "P3"])
                self.current_output.push(f"MOV {p_temp}, {arg_reg}")
                self.current_output.push(f"PUSH {p_temp}")
                self.deallocate_register(p_temp)
            else:
                self.current_output.push(f"PUSH {arg_reg}")
            self.smart_deallocate(arg_reg, true)
            i += 1

        self.current_output.push(f"CALL {label}")

        let total_args = arg_exprs.len()
        if total_args > 0:
            self.current_output.push(f"ADD SP, {total_args * 2}")

        # Restore in reverse push order.
        i = saved_var_regs.len()
        while i > 0:
            i -= 1
            let reg = saved_var_regs[i]
            if reg != "SP" and reg != "FP" and codegen::str_starts_with(reg, "P"):
                self.current_output.push(f"POP {reg}")

        if target_reg != "R0":
            self.current_output.push(f"MOV {target_reg}, R0")
        target_reg

    fn generate_builtin_call(mut self, func_name: str, arguments: List<i32>, target_reg: str, line: i32, column: i32) -> str:
        let unary_math_ops = ["SIN", "COS", "TAN", "SQRT", "ABS", "ATAN", "ASIN", "ACOS", "DEG", "RAD", "FLOOR", "CEIL", "ROUND", "TRUNC", "FRAC", "INTGR", "INT", "LOG", "EXP"]
        if codegen::list_contains_str(unary_math_ops, func_name):
            let mnemonic = if func_name == "INT": "INTGR" else: func_name
            let arg_reg = self.generate_expression(arguments[0], Option<str>::Some(target_reg))
            if arg_reg != target_reg:
                self.current_output.push(f"MOV {target_reg}, {arg_reg}")
                self.smart_deallocate(arg_reg, true)
            self.current_output.push(f"{mnemonic} {target_reg}")
            return target_reg

        if func_name == "RND":
            self.current_output.push(f"RND {target_reg}")
        elif func_name == "RNDR":
            let min_reg = self.generate_expression(arguments[0], Option<str>::Some("R1"))
            let max_reg = self.generate_expression(arguments[1], Option<str>::Some("R2"))
            self.current_output.push(f"RNDR {target_reg}, {min_reg}, {max_reg}")
            self.smart_deallocate(min_reg, true)
            self.smart_deallocate(max_reg, true)
        elif func_name == "RANDOMIZE":
            let seed_reg = self.generate_expression(arguments[0], Option<str>::Some("R1"))
            self.current_output.push(f"MOV R0, {seed_reg}")
            self.current_output.push(f"RND {target_reg}")
            self.smart_deallocate(seed_reg, true)
        elif func_name == "LEN" or func_name == "LENGTH" or func_name == "STRLEN":
            let arg_reg = self.generate_expression(arguments[0], Option<str>::Some("R1"))
            self.current_output.push(f"STRLEN {arg_reg}")
            if target_reg != "R0":
                self.current_output.push(f"MOV {target_reg}, R0")
            self.smart_deallocate(arg_reg, true)
        elif func_name == "STRCPY":
            let dest_reg = self.generate_expression(arguments[0], Option<str>::Some("R1"))
            let src_reg = self.generate_expression(arguments[1], Option<str>::Some("R2"))
            self.current_output.push(f"STRCPY {dest_reg}, {src_reg}")
            self.current_output.push(f"MOV {target_reg}, {dest_reg}")
            self.smart_deallocate(dest_reg, true)
            self.smart_deallocate(src_reg, true)
        elif func_name == "STRCAT":
            let dest_reg = self.generate_expression(arguments[0], Option<str>::Some("R1"))
            let src_reg = self.generate_expression(arguments[1], Option<str>::Some("R2"))
            self.current_output.push(f"STRCAT {dest_reg}, {src_reg}")
            self.current_output.push(f"MOV {target_reg}, {dest_reg}")
            self.smart_deallocate(dest_reg, true)
            self.smart_deallocate(src_reg, true)
        elif func_name == "STRCMP":
            let str1_reg = self.generate_expression(arguments[0], Option<str>::Some("R1"))
            let str2_reg = self.generate_expression(arguments[1], Option<str>::Some("R2"))
            let len_reg = self.generate_expression(arguments[2], Option<str>::Some("R3"))
            self.current_output.push(f"STRCMP {str1_reg}, {str2_reg}, {len_reg}")
            let less_label = self.new_label()
            let equal_label = self.new_label()
            let end_label = self.new_label()
            self.current_output.push(f"MOV {target_reg}, 1")
            self.current_output.push(f"JZ {equal_label}")
            self.current_output.push(f"JS {less_label}")
            self.current_output.push(f"JMP {end_label}")
            self.current_output.push(f"{less_label}:")
            self.current_output.push(f"MOV {target_reg}, 0xFFFF")
            self.current_output.push(f"JMP {end_label}")
            self.current_output.push(f"{equal_label}:")
            self.current_output.push(f"MOV {target_reg}, 0")
            self.current_output.push(f"{end_label}:")
            if str1_reg != target_reg:
                self.smart_deallocate(str1_reg, true)
            if str2_reg != target_reg:
                self.smart_deallocate(str2_reg, true)
            if len_reg != target_reg:
                self.smart_deallocate(len_reg, true)
        elif func_name == "STRUPR" or func_name == "UPSTRING":
            let arg_reg = self.generate_expression(arguments[0], Option<str>::Some("R1"))
            self.current_output.push(f"STRUPR {arg_reg}")
            if target_reg != arg_reg:
                self.current_output.push(f"MOV {target_reg}, {arg_reg}")
                self.smart_deallocate(arg_reg, true)
        elif func_name == "STRLWR" or func_name == "LOWSTRING":
            let arg_reg = self.generate_expression(arguments[0], Option<str>::Some("R1"))
            self.current_output.push(f"STRLWR {arg_reg}")
            if target_reg != arg_reg:
                self.current_output.push(f"MOV {target_reg}, {arg_reg}")
                self.smart_deallocate(arg_reg, true)
        elif func_name == "LENSTRING":
            let arg_reg = self.generate_expression(arguments[0], Option<str>::Some("R1"))
            self.current_output.push(f"STRLEN {arg_reg}")
            if target_reg != "R0":
                self.current_output.push(f"MOV {target_reg}, R0")
            self.smart_deallocate(arg_reg, true)
        elif func_name == "INSTRING" or func_name == "STRFIND":
            let haystack_reg = self.generate_expression(arguments[0], Option<str>::Some("R1"))
            let needle_reg = self.generate_expression(arguments[1], Option<str>::Some("R2"))
            self.current_output.push(f"STRFIND {haystack_reg}, {needle_reg}")
            if target_reg != "R0":
                self.current_output.push(f"MOV {target_reg}, R0")
            self.smart_deallocate(haystack_reg, true)
            self.smart_deallocate(needle_reg, true)
        elif func_name == "STRFINDI":
            let haystack_reg = self.generate_expression(arguments[0], Option<str>::Some("R1"))
            let needle_reg = self.generate_expression(arguments[1], Option<str>::Some("R2"))
            self.current_output.push(f"STRFINDI {haystack_reg}, {needle_reg}")
            if target_reg != "R0":
                self.current_output.push(f"MOV {target_reg}, R0")
            self.smart_deallocate(haystack_reg, true)
            self.smart_deallocate(needle_reg, true)
        elif func_name == "STRREV":
            let arg_reg = self.generate_expression(arguments[0], Option<str>::Some("R1"))
            self.current_output.push(f"STRREV {arg_reg}")
            if target_reg != arg_reg:
                self.current_output.push(f"MOV {target_reg}, {arg_reg}")
                self.smart_deallocate(arg_reg, true)
        elif func_name == "STREXT" or func_name == "STREXTI":
            self.generate_expression_into(arguments[0], "R1")
            self.generate_expression_into(arguments[1], "R2")
            self.generate_expression_into(arguments[2], "R3")
            self.generate_expression_into(arguments[3], "R4")
            self.current_output.push(f"{func_name} R1, R2, R3, R4")
            self.current_output.push(f"MOV {target_reg}, R1")
            if target_reg != "R2":
                self.smart_deallocate("R2", true)
            if target_reg != "R3":
                self.smart_deallocate("R3", true)
            if target_reg != "R4":
                self.smart_deallocate("R4", true)
        elif func_name == "MIN":
            let left_reg = self.generate_expression(arguments[0], Option<str>::Some("R1"))
            let right_reg = self.generate_expression(arguments[1], Option<str>::Some("R2"))
            self.current_output.push(f"MIN {target_reg}, {left_reg}, {right_reg}")
            if left_reg != target_reg:
                self.smart_deallocate(left_reg, true)
            if right_reg != target_reg:
                self.smart_deallocate(right_reg, true)
        elif func_name == "MAX":
            let left_reg = self.generate_expression(arguments[0], Option<str>::Some("R1"))
            let right_reg = self.generate_expression(arguments[1], Option<str>::Some("R2"))
            self.current_output.push(f"MAX {target_reg}, {left_reg}, {right_reg}")
            if left_reg != target_reg:
                self.smart_deallocate(left_reg, true)
            if right_reg != target_reg:
                self.smart_deallocate(right_reg, true)
        elif func_name == "POWR":
            let left_reg = self.generate_expression(arguments[0], Option<str>::Some("R1"))
            let right_reg = self.generate_expression(arguments[1], Option<str>::Some("R2"))
            self.current_output.push(f"POWR {target_reg}, {left_reg}, {right_reg}")
            self.smart_deallocate(left_reg, true)
            self.smart_deallocate(right_reg, true)
        elif func_name == "GETKEY":
            self.current_output.push("KEYIN R0")
            self.current_output.push(f"MOV {target_reg}, R0")
        elif func_name == "SERIN":
            self.current_output.push("SERIN R0")
            self.current_output.push(f"MOV {target_reg}, R0")
        elif func_name == "SERSTAT":
            self.current_output.push("SERSTAT R0")
            self.current_output.push(f"MOV {target_reg}, R0")
        elif func_name == "PAUSE":
            let label = self.new_label()
            self.current_output.push(f"{label}:")
            self.current_output.push("KEYSTAT R0")
            self.current_output.push("CMP R0, 0")
            self.current_output.push(f"JZ {label}")
            self.current_output.push("KEYIN R0")
        else:
            self.fail(f"Codegen core: builtin function '{func_name}' is not yet ported (todo.md P1 #1 remaining work; see codegen.star's header comment)", line, column)
        target_reg

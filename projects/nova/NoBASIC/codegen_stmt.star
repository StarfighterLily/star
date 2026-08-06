# NoBASIC statement codegen + top-level driver -- part of `codegen.star`'s
# `Codegen` (see that file's header comment for the overall file split and
# this round's scope). Ports `generator.py`'s `generate_statement` dispatch,
# the statement generators this round covers, and `generate` itself (the
# reference's `apply_pre_allocation_optimizations`/`apply_post_allocation_
# optimizations`/live-range-scheduler/peephole calls are all omitted --
# every one is a no-op with `enable_optimizations`/`enable_peephole`/
# `enable_live_range_scheduling` at their reference defaults disabled,
# which is how this port's own verification invokes the live reference for
# comparison; see `codegen.star`'s header comment).
#
# Every `StmtKind` variant not yet ported (graphics statements, `Input`,
# nested `FunctionDef`) reaches an explicit `self.fail(...)` in `generate_
# statement`'s dispatch `match` -- a loud compile-time error, never a
# silent no-op or wrong-code emission. See `codegen.star`'s header comment
# for the exact remaining-work list.

import "ast.star" as ast
import "codegen.star" as codegen
import "codegen_expr.star" as codegen_expr

impl codegen::Codegen:
    # ------------------------------------------------------------------
    # Local-variable collection for a function body -- mirrors
    # `_collect_function_local_variables`, recursing into `If`/`For`/
    # `While`/`Repeat` bodies the same way the reference does (a `LOCAL`
    # declaration nested inside a conditional/loop still reserves a
    # function-wide stack slot; NoBASIC has no block scoping).
    # ------------------------------------------------------------------

    fn collect_function_local_variables(self, body: List<i32>) -> List<str>:
        let mut out: List<str> = List<str>()
        let mut i = 0
        while i < body.len():
            let stmt = self.stmts[body[i]]
            match stmt.kind:
                ast::StmtKind::VarDecl(scope, variables) ->
                    if scope == ast::VarScope::Local:
                        let mut v = 0
                        while v < variables.len():
                            out.push(variables[v])
                            v += 1
                ast::StmtKind::If(condition, then_branch, else_branch) ->
                    let then_locals = self.collect_function_local_variables(then_branch)
                    let mut t = 0
                    while t < then_locals.len():
                        out.push(then_locals[t])
                        t += 1
                    match else_branch:
                        Option::Some(eb) ->
                            let else_locals = self.collect_function_local_variables(eb)
                            let mut e = 0
                            while e < else_locals.len():
                                out.push(else_locals[e])
                                e += 1
                        Option::None -> 0
                ast::StmtKind::For(variable, start, end, step, fbody) ->
                    let inner = self.collect_function_local_variables(fbody)
                    let mut f = 0
                    while f < inner.len():
                        out.push(inner[f])
                        f += 1
                ast::StmtKind::While(condition, wbody) ->
                    let inner = self.collect_function_local_variables(wbody)
                    let mut w = 0
                    while w < inner.len():
                        out.push(inner[w])
                        w += 1
                ast::StmtKind::Repeat(rbody, condition) ->
                    let inner = self.collect_function_local_variables(rbody)
                    let mut r = 0
                    while r < inner.len():
                        out.push(inner[r])
                        r += 1
                _ -> 0
            i += 1
        out

    # ------------------------------------------------------------------
    # Top-level dispatch.
    # ------------------------------------------------------------------

    fn generate_statement(mut self, stmt_id: i32):
        self.program_counter += 1
        self.clear_temp_registers()
        let stmt = self.stmts[stmt_id]

        match stmt.kind:
            ast::StmtKind::Return(value) ->
                self.generate_return(value)
            ast::StmtKind::VarDecl(scope, variables) ->
                self.generate_var_declaration(scope, variables)
            ast::StmtKind::PlayTone(frequency, duration, volume) ->
                self.generate_play_tone(frequency, duration, volume)
            ast::StmtKind::PlayWave(waveform, frequency, volume) ->
                self.generate_play_wave(waveform, frequency, volume)
            ast::StmtKind::StopSound ->
                self.current_output.push("MOV SV, 0")
            ast::StmtKind::SetChannel(channel) ->
                self.current_output.push("; Set channel - simplified")
            ast::StmtKind::GetKey ->
                self.current_output.push("KEYIN R0")
            ast::StmtKind::SerOut(value) ->
                self.generate_ser_out(value)
            ast::StmtKind::SerIn(variable) ->
                self.current_output.push("SERIN R0")
                self.store_variable(variable, "R0")
            ast::StmtKind::SerStat(variable) ->
                self.current_output.push("SERSTAT R0")
                self.store_variable(variable, "R0")
            ast::StmtKind::SerCtrl(value) ->
                self.generate_ser_ctrl(value)
            ast::StmtKind::Disp(text) ->
                self.generate_disp(text)
            ast::StmtKind::Pause ->
                self.generate_pause()
            ast::StmtKind::FunctionCall(call) ->
                self.generate_expression(call, Option<str>::Some("R0"))
            ast::StmtKind::ExpressionStmt(expr) ->
                self.generate_expression(expr, Option<str>::Some("R0"))
            ast::StmtKind::Assignment(variable, expr) ->
                self.generate_assignment(variable, expr)
            ast::StmtKind::If(condition, then_branch, else_branch) ->
                self.generate_if(condition, then_branch, else_branch)
            ast::StmtKind::For(variable, start, end, step, body) ->
                self.generate_for(variable, start, end, step, body)
            ast::StmtKind::While(condition, body) ->
                self.generate_while(condition, body)
            ast::StmtKind::Repeat(body, condition) ->
                self.generate_repeat(body, condition)
            ast::StmtKind::Goto(label) ->
                self.current_output.push(f"JMP {label}")
            ast::StmtKind::Label(label) ->
                self.current_output.push(f"{label}:")
            ast::StmtKind::StructDecl(name, fields) ->
                self.current_output.push(f"; Struct {name} declared")
            ast::StmtKind::AsmBlock(assembly_code) ->
                self.generate_asm_block(assembly_code)
            _ ->
                self.fail("Codegen core: this statement kind is not yet ported (todo.md P1 #1 remaining work; see codegen.star's header comment)", stmt.line, stmt.column)

    # ------------------------------------------------------------------
    # Functions.
    # ------------------------------------------------------------------

    fn generate_function_def(mut self, stmt_id: i32, func_key: str):
        let label = match self.function_labels.get(func_key):
            Option::Some(l) -> l
            Option::None -> ""
        let fname = match self.stmts[stmt_id].kind:
            ast::StmtKind::FunctionDef(n, p, b) -> n
            _ -> ""
        let params = self.function_params(stmt_id)
        let body = self.function_body(stmt_id)

        let local_vars = self.collect_function_local_variables(body)
        let locals_size = local_vars.len() * 2

        let mut i = 0
        while i < local_vars.len():
            let offset = -((i + 1) * 2)
            self.function_locals.insert(self.function_local_key(func_key, local_vars[i]), offset)
            i += 1

        let mut param_names: List<str> = List<str>()
        i = 0
        while i < params.len():
            param_names.push(params[i].name)
            i += 1

        let comma_sep = ", "
        let param_names_str = str_join(param_names, comma_sep)
        let local_vars_str = str_join(local_vars, comma_sep)

        let mut func_lines: List<str> = List<str>()
        func_lines.push("")
        func_lines.push(f"{label}:")
        func_lines.push(f"; Function: {fname}")
        func_lines.push(f"; Parameters: {param_names_str}")
        func_lines.push(f"; Locals: {local_vars_str} ({locals_size} bytes)")
        func_lines.push(f"ENTER {locals_size}")

        let prev_function = self.current_function
        self.current_function = Option<str>::Some(func_key)
        let saved_output = self.current_output
        self.current_output = func_lines

        i = 0
        while i < body.len() and !self.had_error:
            self.generate_statement(body[i])
            i += 1

        let mut last_is_return = false
        if body.len() > 0:
            match self.stmts[body[body.len() - 1]].kind:
                ast::StmtKind::Return(v) ->
                    last_is_return = true
                _ -> 0
        if !last_is_return:
            self.current_output.push("MOV SP, FP")
            self.current_output.push("POP FP")
            self.current_output.push("RETN 0")

        let generated_lines = self.current_output
        self.current_output = saved_output
        self.current_function = prev_function

        self.function_outputs.push(generated_lines)

    fn generate_return(mut self, value: Option<i32>):
        let mut return_value = "0"
        match value:
            Option::Some(v) ->
                return_value = self.generate_expression(v, Option<str>::Some("R0"))
            Option::None -> 0

        match self.current_function:
            Option::Some(f) ->
                self.current_output.push("MOV SP, FP")
                self.current_output.push("POP FP")
            Option::None -> 0

        self.current_output.push(f"RETN {return_value}")

    # ------------------------------------------------------------------
    # Simple statements.
    # ------------------------------------------------------------------

    fn generate_asm_block(mut self, assembly_code: str):
        self.current_output.push("; --- Inline Assembly Block ---")
        let mut lines: List<str> = List<str>()
        let mut current = ""
        let mut i = 0
        while i < len(assembly_code):
            let c = assembly_code[i]
            if c == 10:
                lines.push(current)
                current = ""
            else:
                current = concat(current, chr(c))
            i += 1
        lines.push(current)
        i = 0
        while i < lines.len():
            let stripped = str_trim(lines[i])
            if len(stripped) > 0:
                self.current_output.push(stripped)
            i += 1
        self.current_output.push("; --- End Inline Assembly ---")

    fn generate_var_declaration(mut self, scope: ast::VarScope, variables: List<str>):
        let scope_str = if scope == ast::VarScope::Local: "LOCAL" else: "GLOBAL"
        let mut i = 0
        while i < variables.len():
            let var_name = variables[i]
            let mut is_local_in_function = false
            match self.current_function:
                Option::Some(func_key) ->
                    if scope == ast::VarScope::Local:
                        is_local_in_function = true
                        let offset = codegen::opt_i32_or(self.function_local_offset(func_key, var_name), 0)
                        self.current_output.push(f"; {scope_str} variable: {var_name} @ FP{codegen::signed_str(offset)}")
                Option::None -> 0
            if !is_local_in_function:
                let addr = self.get_variable_address(var_name)
                self.current_output.push(f"; {scope_str} variable: {var_name} @ 0x{codegen::hex4(addr)}")
            i += 1

    fn generate_play_tone(mut self, frequency: i32, duration: i32, volume: i32):
        let freq_reg = self.generate_expression(frequency, Option<str>::None)
        let dur_reg = self.generate_expression(duration, Option<str>::None)
        let vol_reg = self.generate_expression(volume, Option<str>::None)
        self.current_output.push(f"MOV SF, {freq_reg}")
        self.current_output.push(f"MOV SV, {vol_reg}")
        self.current_output.push("MOV SW, 0")
        self.current_output.push("SPLAY")
        self.current_output.push("; Duration handling - simplified")

    fn generate_play_wave(mut self, waveform: i32, frequency: i32, volume: i32):
        let wave_reg = self.generate_expression(waveform, Option<str>::None)
        let freq_reg = self.generate_expression(frequency, Option<str>::None)
        let vol_reg = self.generate_expression(volume, Option<str>::None)
        self.current_output.push(f"MOV SW, {wave_reg}")
        self.current_output.push(f"MOV SF, {freq_reg}")
        self.current_output.push(f"MOV SV, {vol_reg}")
        self.current_output.push("SPLAY")

    fn generate_ser_out(mut self, value: i32):
        let val_reg = self.generate_expression(value, Option<str>::Some("R1"))
        self.current_output.push(f"SEROUT {val_reg}")
        self.smart_deallocate(val_reg, true)

    fn generate_ser_ctrl(mut self, value: i32):
        let val_reg = self.generate_expression(value, Option<str>::Some("R1"))
        self.current_output.push(f"SERCTRL {val_reg}")
        self.smart_deallocate(val_reg, true)

    fn generate_pause(mut self):
        let pause_label = self.new_label()
        self.current_output.push(f"{pause_label}:")
        self.current_output.push("KEYSTAT R0")
        self.current_output.push("CMP R0, 0")
        self.current_output.push(f"JZ {pause_label}")

    # `Disp` -- string literal / string variable / (string or numeric)
    # `+` / plain numeric, each converted to text and drawn via `TEXT`.
    # Mirrors `generate_disp`'s own four-way dispatch.
    fn generate_disp(mut self, text: i32):
        let expr = self.exprs[text]
        let mut is_string_literal = false
        let mut is_string_variable = false
        match expr.kind:
            ast::ExprKind::Literal(data_type, num_value, is_float, str_value) ->
                is_string_literal = data_type == ast::DataType::String
            ast::ExprKind::Variable(name) ->
                is_string_variable = codegen::str_starts_with(codegen::str_upper(name), "STR")
            _ -> 0

        if is_string_literal:
            match expr.kind:
                ast::ExprKind::Literal(data_type, num_value, is_float, str_value) ->
                    let label = self.add_string_literal(str_value)
                    self.current_output.push("MOV VX, 0")
                    self.current_output.push("MOV VC, 15")
                    self.current_output.push(f"TEXT {label}")
                    self.current_output.push("ADD VY, 8")
                _ -> 0
            return

        if is_string_variable:
            let text_addr_reg = self.generate_expression(text, Option<str>::Some("P1"))
            self.current_output.push("MOV VX, 0")
            self.current_output.push("MOV VC, 15")
            self.current_output.push(f"TEXT {text_addr_reg}")
            self.current_output.push("ADD VY, 8")
            self.smart_deallocate(text_addr_reg, true)
            return

        let mut is_string_concat = false
        match expr.kind:
            ast::ExprKind::Binary(left, operator, right) ->
                if operator == "+":
                    is_string_concat = self.is_string_expression(left) or self.is_string_expression(right)
            _ -> 0

        if is_string_concat:
            let text_addr_reg = self.generate_expression(text, Option<str>::Some("P1"))
            self.current_output.push("MOV VX, 0")
            self.current_output.push("MOV VC, 15")
            self.current_output.push(f"TEXT {text_addr_reg}")
            self.current_output.push("ADD VY, 8")
            self.smart_deallocate(text_addr_reg, true)
            return

        # Numeric expression (default case): evaluate, convert to text.
        let mut value_reg = self.generate_expression(text, Option<str>::Some("R1"))
        if codegen::str_starts_with(value_reg, "P"):
            let temp_r_reg = self.allocate_register(Option<str>::Some("R1"))
            self.current_output.push(f"MOV {temp_r_reg}, {value_reg}")
            self.smart_deallocate(value_reg, true)
            value_reg = temp_r_reg

        let string_reg = self.allocate_p_register(["P1", "P2", "P3"])
        self.current_output.push(f"ITOS {string_reg}, {value_reg}")
        self.current_output.push("MOV VX, 0")
        self.current_output.push("MOV VC, 15")
        self.current_output.push(f"TEXT {string_reg}")
        self.current_output.push("ADD VY, 8")
        self.deallocate_register(string_reg)
        self.smart_deallocate(value_reg, true)

    # ------------------------------------------------------------------
    # Assignment.
    # ------------------------------------------------------------------

    fn generate_assignment(mut self, variable: i32, expr: i32):
        let value_reg = self.generate_expression(expr, Option<str>::Some("P1"))
        let target = self.exprs[variable]
        match target.kind:
            ast::ExprKind::Variable(name) ->
                match self.var_reg_get(name):
                    Option::Some(reg) ->
                        if reg != value_reg:
                            self.current_output.push(f"MOV {reg}, {value_reg}")
                    Option::None ->
                        self.store_variable(name, value_reg)
            _ ->
                self.fail("Codegen core: assignment to list/matrix/struct-member targets is not yet ported (todo.md P1 #1 remaining work)", target.line, target.column)

    # ------------------------------------------------------------------
    # Control flow.
    # ------------------------------------------------------------------

    fn generate_if(mut self, condition: i32, then_branch: List<i32>, else_branch: Option<List<i32>>):
        let else_label = self.new_label()
        let end_label = self.new_label()

        self.emit_condition_false_jump(condition, else_label)

        let mut i = 0
        while i < then_branch.len() and !self.had_error:
            self.generate_statement(then_branch[i])
            i += 1

        match else_branch:
            Option::Some(eb) ->
                self.current_output.push(f"JMP {end_label}")
                self.current_output.push(f"{else_label}:")
                i = 0
                while i < eb.len() and !self.had_error:
                    self.generate_statement(eb[i])
                    i += 1
                self.current_output.push(f"{end_label}:")
            Option::None ->
                self.current_output.push(f"{else_label}:")

    fn generate_while(mut self, condition: i32, body: List<i32>):
        let loop_label = self.new_label()
        let end_label = self.new_label()

        self.current_output.push(f"{loop_label}:")
        self.emit_condition_false_jump(condition, end_label)

        let mut i = 0
        while i < body.len() and !self.had_error:
            self.generate_statement(body[i])
            i += 1

        self.current_output.push(f"JMP {loop_label}")
        self.current_output.push(f"{end_label}:")

    fn generate_repeat(mut self, body: List<i32>, condition: i32):
        let loop_label = self.new_label()
        self.current_output.push(f"{loop_label}:")

        let mut i = 0
        while i < body.len() and !self.had_error:
            self.generate_statement(body[i])
            i += 1

        self.emit_condition_false_jump(condition, loop_label)

    # Emit a jump to `false_label` when `condition` is false, with
    # short-circuit `and`/`or` handling -- mirrors `emit_condition_false_
    # jump` exactly.
    fn emit_condition_false_jump(mut self, condition: i32, false_label: str):
        let expr = self.exprs[condition]
        match expr.kind:
            ast::ExprKind::Binary(left, operator, right) ->
                if operator == "and":
                    self.emit_condition_false_jump(left, false_label)
                    self.emit_condition_false_jump(right, false_label)
                    return
                if operator == "or":
                    let right_check_label = self.new_label()
                    let pass_label = self.new_label()
                    self.emit_condition_false_jump(left, right_check_label)
                    self.current_output.push(f"JMP {pass_label}")
                    self.current_output.push(f"{right_check_label}:")
                    self.emit_condition_false_jump(right, false_label)
                    self.current_output.push(f"{pass_label}:")
                    return

                let mut jump_opcode = ""
                if operator == "<":
                    jump_opcode = "JGE"
                elif operator == ">":
                    jump_opcode = "JLE"
                elif operator == "=":
                    jump_opcode = "JNZ"
                elif operator == "<>":
                    jump_opcode = "JZ"
                elif operator == "<=":
                    jump_opcode = "JGT"
                elif operator == ">=":
                    jump_opcode = "JLT"

                if jump_opcode != "":
                    let left_result = self.generate_expression(left, Option<str>::Some("P1"))
                    let right_result = self.generate_expression(right, Option<str>::Some("P2"))
                    self.current_output.push(f"CMP {left_result}, {right_result}")
                    self.smart_deallocate(left_result, true)
                    self.smart_deallocate(right_result, true)
                    self.current_output.push(f"{jump_opcode} {false_label}")
                    return
            _ -> 0

        let temp_reg = self.allocate_register(Option<str>::None)
        let condition_reg = self.generate_expression(condition, Option<str>::Some(temp_reg))
        self.current_output.push(f"WHILE {condition_reg}")
        self.current_output.push(f"JZ {false_label}")
        self.deallocate_register(temp_reg)

    # ------------------------------------------------------------------
    # `For` -- the largest single statement generator; ported in full
    # (address hoisting included) since it's exercised by nearly every
    # real NoBASIC program. See `generator.py`'s own `generate_for` doc
    # comment for the register-selection rationale.
    # ------------------------------------------------------------------

    fn generate_for(mut self, variable: str, start: i32, end: i32, step: Option<i32>, body: List<i32>):
        let loop_label = self.new_label()
        let end_label = self.new_label()

        let loop_regs = self.get_loop_registers()
        let mut current_reg = loop_regs[0]
        let mut end_reg = loop_regs[1]
        let mut step_reg = loop_regs[2]

        self.loop_nesting_level += 1

        let mut is_local_var = false
        match self.current_function:
            Option::Some(func_key) ->
                match self.function_local_offset(func_key, variable):
                    Option::Some(off) ->
                        is_local_var = true
                    Option::None -> 0
            Option::None -> 0

        let mut is_none_function = false
        match self.current_function:
            Option::None ->
                is_none_function = true
            Option::Some(_f) -> 0

        let is_register_allocated = self.var_reg_contains(variable) and is_none_function

        let mut loop_reg = current_reg
        if is_register_allocated:
            loop_reg = match self.var_reg_get(variable):
                Option::Some(r) -> r
                Option::None -> current_reg
            self.register_usage.insert(loop_reg, true)
        else:
            let preferred = [current_reg, "P1", "P2", "P3", "P4", "P5", "P6", "P7"]
            let mut found = false
            let mut i = 0
            while i < preferred.len():
                if !codegen::opt_bool_or(self.register_usage.get(preferred[i]), false):
                    loop_reg = preferred[i]
                    found = true
                    break
                i += 1
            if !found:
                loop_reg = self.allocate_register(Option<str>::None)
            self.register_usage.insert(loop_reg, true)
            self.var_reg_set(variable, loop_reg)

        if end_reg == loop_reg or codegen::opt_bool_or(self.register_usage.get(end_reg), false):
            end_reg = self.allocate_register(Option<str>::None)
        self.register_usage.insert(end_reg, true)
        self.auto_free_registers.remove(end_reg)

        let mut have_step = false
        match step:
            Option::Some(_s) ->
                have_step = true
            Option::None -> 0

        if have_step:
            if step_reg == loop_reg or step_reg == end_reg or codegen::opt_bool_or(self.register_usage.get(step_reg), false):
                step_reg = self.allocate_register(Option<str>::None)
            self.register_usage.insert(step_reg, true)
            self.auto_free_registers.remove(step_reg)

        let start_reg = self.generate_expression(start, Option<str>::None)
        if start_reg != loop_reg:
            self.current_output.push(f"MOV {loop_reg}, {start_reg}")
            self.deallocate_register(start_reg)

        let mut loop_var_addr_reg = ""
        let mut have_addr_reg = false
        let mut loop_var_addr = 0
        if !is_local_var and !is_register_allocated and is_none_function:
            loop_var_addr = self.get_variable_address(variable)
            if self.loop_body_allows_address_hoist(body):
                let candidates = ["P6", "P5", "P4"]
                let mut ci = 0
                while ci < candidates.len() and !have_addr_reg:
                    let cand = candidates[ci]
                    let taken = cand == loop_reg or cand == end_reg or (have_step and cand == step_reg)
                    if !taken and !codegen::opt_bool_or(self.register_usage.get(cand), false):
                        loop_var_addr_reg = cand
                        have_addr_reg = true
                        self.register_usage.insert(cand, true)
                        self.current_output.push(f"MOV {cand}, {loop_var_addr}")
                    ci += 1

        if is_local_var:
            let off = codegen::opt_i32_or(self.function_local_offset(codegen::opt_str_or(self.current_function, ""), variable), 0)
            self.current_output.push("MOV P0, FP")
            self.current_output.push(f"ADD P0, {off}")
            self.current_output.push(f"MOV [P0], {loop_reg}")
        elif !is_register_allocated and is_none_function:
            if have_addr_reg:
                self.current_output.push(f"MOV [{loop_var_addr_reg}], {loop_reg}")
            else:
                self.current_output.push(f"MOV P0, {loop_var_addr}")
                self.current_output.push(f"MOV [P0], {loop_reg}")

        let mut end_value_reg = self.generate_expression(end, Option<str>::Some(end_reg))
        if end_value_reg != end_reg:
            self.current_output.push(f"MOV {end_reg}, {end_value_reg}")
            self.deallocate_register(end_value_reg)
            end_value_reg = end_reg

        let mut step_value_reg = step_reg
        if have_step:
            match step:
                Option::Some(s) ->
                    step_value_reg = self.generate_expression(s, Option<str>::Some(step_reg))
                    if step_value_reg != step_reg:
                        self.current_output.push(f"MOV {step_reg}, {step_value_reg}")
                        self.deallocate_register(step_value_reg)
                        step_value_reg = step_reg
                Option::None -> 0

        self.current_output.push(f"{loop_label}:")

        if is_local_var:
            let off = codegen::opt_i32_or(self.function_local_offset(codegen::opt_str_or(self.current_function, ""), variable), 0)
            self.current_output.push("MOV P0, FP")
            self.current_output.push(f"ADD P0, {off}")
            self.current_output.push(f"MOV [P0], {loop_reg}")
        elif !is_register_allocated and is_none_function:
            if have_addr_reg:
                self.current_output.push(f"MOV [{loop_var_addr_reg}], {loop_reg}")
            else:
                self.current_output.push(f"MOV P0, {loop_var_addr}")
                self.current_output.push(f"MOV [P0], {loop_reg}")

        self.current_output.push(f"CMP {loop_reg}, {end_value_reg}")
        self.current_output.push(f"JGT {end_label}")

        let mut i = 0
        while i < body.len() and !self.had_error:
            self.generate_statement(body[i])
            i += 1

        if have_step:
            self.current_output.push(f"ADD {loop_reg}, {step_value_reg}")
        else:
            self.current_output.push(f"INC {loop_reg}")

        self.current_output.push(f"JMP {loop_label}")
        self.current_output.push(f"{end_label}:")

        if is_local_var:
            let off = codegen::opt_i32_or(self.function_local_offset(codegen::opt_str_or(self.current_function, ""), variable), 0)
            self.current_output.push("MOV P0, FP")
            self.current_output.push(f"ADD P0, {off}")
            self.current_output.push(f"MOV [P0], {loop_reg}")

        if !is_register_allocated:
            self.var_reg_remove(variable)
            self.deallocate_register(loop_reg)
        self.deallocate_register(end_reg)
        if have_step:
            self.deallocate_register(step_reg)
        if have_addr_reg:
            self.deallocate_register(loop_var_addr_reg)

        self.loop_nesting_level -= 1

    # ------------------------------------------------------------------
    # Loop-invariant address-hoist safety checks for `For` -- mirrors
    # `_expr_has_unsafe_loop_addr_hoist_nodes`/`_stmt_allows_loop_addr_
    # hoist`/`_loop_body_allows_address_hoist`. Conservative: any
    # statement kind this round hasn't ported into the "known safe" list
    # returns `false` (never hoists), matching the reference's own
    # catch-all `return False` for unrecognized statement shapes.
    # ------------------------------------------------------------------

    fn expr_has_unsafe_loop_addr_hoist_nodes(self, expr_id: i32) -> bool:
        let expr = self.exprs[expr_id]
        match expr.kind:
            ast::ExprKind::Call(name, arguments) -> true
            ast::ExprKind::ListAccess(list_name, index) -> true
            ast::ExprKind::MatrixAccess(matrix_name, row, col) -> true
            ast::ExprKind::MemberAccess(object, member) -> true
            ast::ExprKind::Binary(left, operator, right) ->
                self.expr_has_unsafe_loop_addr_hoist_nodes(left) or self.expr_has_unsafe_loop_addr_hoist_nodes(right)
            ast::ExprKind::Unary(operator, inner, is_post) ->
                self.expr_has_unsafe_loop_addr_hoist_nodes(inner)
            ast::ExprKind::Grouping(inner) ->
                self.expr_has_unsafe_loop_addr_hoist_nodes(inner)
            _ -> false

    fn stmt_allows_loop_addr_hoist(self, stmt_id: i32) -> bool:
        let stmt = self.stmts[stmt_id]
        match stmt.kind:
            ast::StmtKind::Assignment(variable, expr) ->
                let mut target_unsafe = false
                match self.exprs[variable].kind:
                    ast::ExprKind::ListAccess(ln, idx) ->
                        target_unsafe = true
                    ast::ExprKind::MatrixAccess(mn, r, c) ->
                        target_unsafe = true
                    ast::ExprKind::MemberAccess(o, m) ->
                        target_unsafe = true
                    _ ->
                        target_unsafe = self.expr_has_unsafe_loop_addr_hoist_nodes(variable)
                !target_unsafe and !self.expr_has_unsafe_loop_addr_hoist_nodes(expr)
            ast::StmtKind::ExpressionStmt(expr) ->
                !self.expr_has_unsafe_loop_addr_hoist_nodes(expr)
            ast::StmtKind::If(condition, then_branch, else_branch) ->
                if self.expr_has_unsafe_loop_addr_hoist_nodes(condition):
                    false
                else:
                    let mut ok = true
                    let mut i = 0
                    while i < then_branch.len() and ok:
                        if !self.stmt_allows_loop_addr_hoist(then_branch[i]):
                            ok = false
                        i += 1
                    match else_branch:
                        Option::Some(eb) ->
                            i = 0
                            while i < eb.len() and ok:
                                if !self.stmt_allows_loop_addr_hoist(eb[i]):
                                    ok = false
                                i += 1
                        Option::None -> 0
                    ok
            ast::StmtKind::SetLayer(layer) ->
                !self.expr_has_unsafe_loop_addr_hoist_nodes(layer)
            _ -> false

    fn loop_body_allows_address_hoist(self, body: List<i32>) -> bool:
        let mut i = 0
        while i < body.len():
            if !self.stmt_allows_loop_addr_hoist(body[i]):
                return false
            i += 1
        true

    # ------------------------------------------------------------------
    # Top-level driver.
    # ------------------------------------------------------------------

    # `program`: the top-level statement-id list (`ast::Ast.program`).
    # `self.exprs`/`self.stmts` are set by `new_codegen` at construction,
    # matching `semantic.star`'s `new_analyzer` -- the caller builds a
    # `Codegen` from a whole `ast::Ast` once, then calls `generate` with
    # just the top-level statement order.
    fn generate(mut self, program: List<i32>) -> str:
        # First pass: collect function definitions and generate their code.
        let mut pi = 0
        while pi < program.len() and !self.had_error:
            let stmt_id = program[pi]
            match self.stmts[stmt_id].kind:
                ast::StmtKind::FunctionDef(name, params, body) ->
                    let func_key = codegen::str_lower(name)
                    let label = f"_func_{name}_{self.function_counter}"
                    self.function_counter += 1
                    self.function_labels.insert(func_key, label)
                    self.functions.insert(func_key, stmt_id)
                    self.generate_function_def(stmt_id, func_key)
                _ -> 0
            pi += 1

        if self.had_error:
            return ""

        # Second pass: collect lifetimes, then assign registers.
        self.collect_lifetimes(program)
        self.assign_registers()

        self.current_output.push("; NoBASIC compiler output")
        self.current_output.push("; Generated for Nova-16")
        self.current_output.push("ORG 0x0200")
        self.current_output.push("MOV P7:, 0xFF")
        self.current_output.push("MOV :P7, 0xFF")
        self.current_output.push("MOV SP, P7")
        self.current_output.push("MOV FP, SP")

        let mut si = 0
        while si < program.len() and !self.had_error:
            let stmt_id = program[si]
            match self.stmts[stmt_id].kind:
                ast::StmtKind::FunctionDef(name, params, body) -> 0
                _ -> self.generate_statement(stmt_id)
            si += 1

        if self.had_error:
            return ""

        self.current_output.push("HLT")

        let mut fi = 0
        while fi < self.function_outputs.len():
            let flines = self.function_outputs[fi]
            let mut li = 0
            while li < flines.len():
                self.current_output.push(flines[li])
                li += 1
            fi += 1

        let mut sli = 0
        while sli < self.strings.len():
            let s = self.strings[sli]
            let escaped = self.escape_assembly_string(s.value)
            self.current_output.push(f"{s.label}: DEFSTR \"{escaped}\"")
            sli += 1

        str_join(self.current_output, "\n")

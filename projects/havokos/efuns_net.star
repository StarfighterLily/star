# Efuns of connections -- todo.md HavokOS M6, the "users", line editor-free
# network part of `havok/efuns.pike` (efun_table.star codes 300-349): exec,
# input_to/get_char, the query_ip_* family, snoop, charmode, the telnet
# protocols' has_*/send_* efuns, client_info() and network_stats(). The
# mechanisms are `net.star`'s; this file is argument handling and result
# shapes, as `efuns_obj.star` is for the object model.
#
# As there, an *omitted* optional object argument means this_object(),
# while a passed 0 is no object. query_idle(), query_snoop() and the
# charmode efuns have no default, as in the reference.
#
# The line editor's two query efuns, in_edit() and query_ed_mode(), answered
# "no session" here until M7 brought the editor; they are `ed.star`'s now.
#
# Also here: the case runner's telnet hooks (codes 911-917), which
# `tools/ref_cases.pike` gives the reference too, so the M6 cases drive
# both drivers' telnet layers byte for byte:
#   test_tel_open(ob)      a connection with no socket attached to ob, as
#                          run_tests.pike's fake_user() (no master connect(),
#                          no logon()); returns its id
#   test_tel_connect()     a new connection through the master's connect()
#                          and logon(), as for a real client; returns its id
#   test_tel_user(id)      the object a connection drives (0 if none)
#   test_tel_say(id, s)    the client sends s; returns what came back
#   test_tel_drain(id)     what the driver has sent and the test hasn't read
#   test_tel_hangup(id)    the client closes the connection
#   test_tel_tp(ob)        set this_player() (run_tests.pike sets
#                          drv->cur_player around its input_to() calls)
# Bytes cross the hooks in a printable form: printable ASCII as itself, any
# other byte (and `~`) as `~xx` (two lower-case hex digits), so telnet
# commands and the NULs of subnegotiations survive LPC strings (NOTES.md
# deviation #7).

import "value.star" as val
import "vm.star" as vm
import "efun_table.star" as et
import "net.star" as net
import "telcodec.star" as tc

impl vm::Vm:
    # args[i] as an object, with the efun's argument-count rule: an omitted
    # argument is `self_ob`
    fn net_ob_arg(self, args: List<val::Value>, i: i32, self_ob: i32) -> i32:
        if args.len() <= i:
            return self_ob
        self.obj_of(args[i])

    # The connection out-of-band senders write to: this object's, or
    # this_player()'s when it has none.
    fn oob_conn(self, self_ob: i32) -> i32:
        let ci = self.user_conn(self_ob)
        if ci >= 0:
            return ci
        if self.alive(self.cur_player):
            return self.user_conn(self.cur_player)
        -1

    # input_to(fun, [flag], args...) / get_char(...): to this_player()'s
    # connection; 0 when it has none or something is already waiting.
    fn efun_input_to(mut self, args: List<val::Value>, self_ob: i32, is_char: bool) -> val::Value:
        let zero = val::Value::Int(0 as i64)
        let fun = self.arg(args, 0)
        let mut flag = 0
        let mut start = 1
        if args.len() > 1:
            match args[1]:
                val::Value::Int(x) ->
                    flag = x as i32
                    start = 2
                val::Value::Undef ->
                    start = 2
                _ -> 0
        let mut rest: List<val::Value> = List<val::Value>()
        for i in start..args.len():
            rest.push(args[i])
        let ci = self.user_conn(self.cur_player)
        if ci < 0:
            return zero
        let mut f = fun
        match fun:
            val::Value::Str(name) ->
                let e = self.any_fn(self_ob, name)
                if e.prog < 0:
                    if !is_char:
                        self.fail(f"input_to(): function {name} not found\n")
                        return val::Value::Undef
                    f = zero
                else:
                    f = self.new_fn(val::FnSlot(kind = val::FK_DIRECT, owner = self_ob, owner_gen = self.objs[self_ob].gen, name = name, prog = e.prog, fnidx = e.fnidx, var_base = e.var_off))
            _ -> 0
        self.bool_v(self.set_input_to(ci, f, self_ob, flag, rest, is_char))

    fn efun_snoop(mut self, args: List<val::Value>) -> val::Value:
        let zero = val::Value::Int(0 as i64)
        let by = if args.len() > 0: self.obj_of(args[0]) else: -1
        if by < 0:
            self.fail("Bad argument 1 to snoop()\n")
            return val::Value::Undef
        let victim = self.arg(args, 1)
        if !self.truthy(victim):
            self.stop_snoop(by)
            return self.obj_value(by)
        let v = self.obj_of(victim)
        if v < 0:
            return zero
        let ci = self.user_conn(v)
        if ci < 0:
            self.fail("Second argument of snoop() is not interactive!\n")
            return val::Value::Undef
        # refuse snoop loops: walk the chain of whoever is snooping `by`
        let mut t = by
        while t >= 0:
            if t == v:
                return zero
            let tc = self.user_conn(t)
            t = if tc >= 0: self.obj_of(self.conns[tc].snooped_by) else: -1
        self.stop_snoop(by)
        self.conns[ci].snooped_by = self.obj_value(by)
        self.obj_value(v)

    fn efun_network_stats(mut self) -> val::Value:
        let m = self.new_map()
        let mut total: List<i64> = [0 as i64, 0 as i64, 0 as i64, 0 as i64]
        for i in 0..self.traffic_ports.len():
            let p = vm::int_str(self.traffic_ports[i] as i64)
            let names = ["incoming packets port ", "incoming volume port ", "outgoing packets port ", "outgoing volume port "]
            for j in 0..4:
                let v = self.traffic[i * 4 + j]
                self.map_set(m, val::Value::Str(concat(names[j], p)), val::Value::Int(v))
                total[j] = total[j] + v
        let tnames = ["incoming packets total", "incoming volume total", "outgoing packets total", "outgoing volume total"]
        for j in 0..4:
            self.map_set(m, val::Value::Str(tnames[j]), val::Value::Int(total[j]))
        val::Value::Map(m)

    fn efun_net(mut self, code: i32, name: str, args: List<val::Value>, self_ob: i32) -> val::Value:
        let zero = val::Value::Int(0 as i64)
        if code == et::E_EXEC:
            let to = self.obj_of(self.arg(args, 0))
            let from = self.obj_of(self.arg(args, 1))
            if to < 0 or from < 0:
                return zero
            if self.alive(self.master_ob):
                let ok = self.master_apply("valid_exec", [val::Value::Str(self.obj_name(self_ob)), self.obj_value(to), self.obj_value(from)], self_ob)
                if self.err:
                    return val::Value::Undef
                match ok:
                    val::Value::Undef -> 0
                    _ ->
                        if !self.truthy(ok):
                            return zero
            if !self.alive(to) or !self.alive(from):
                return zero
            # the reference returns the object exec() moved to (truthy)
            return if self.net_exec(to, from): self.obj_value(to) else: zero
        if code == et::E_QUERY_IP_NUMBER or code == et::E_QUERY_IP_NAME:
            let ci = self.user_conn(self.net_ob_arg(args, 0, self_ob))
            return if ci >= 0: val::Value::Str(self.conns[ci].ip) else: zero
        if code == et::E_QUERY_IP_PORT:
            let ci = self.user_conn(self.net_ob_arg(args, 0, self_ob))
            return if ci >= 0: val::Value::Int(self.conns[ci].local_port as i64) else: zero
        if code == et::E_QUERY_HOST_NAME:
            return val::Value::Str(host_name())
        if code == et::E_QUERY_IDLE:
            let ci = self.user_conn(self.obj_of(self.arg(args, 0)))
            if ci < 0:
                self.fail("query_idle() of non-interactive object.\n")
                return val::Value::Undef
            return val::Value::Int(vm::epoch_now() - self.conns[ci].last_input)
        if code == et::E_IN_INPUT:
            let ci = self.user_conn(self.net_ob_arg(args, 0, self_ob))
            return self.bool_v(ci >= 0 and !val::is_zero(self.conns[ci].input_fn))
        if code == et::E_REMOVE_INTERACTIVE:
            let ci = self.user_conn(self.obj_of(self.arg(args, 0)))
            if ci >= 0:
                self.conn_close(ci, "remove_interactive")
            return zero
        if code == et::E_SNOOP:
            return self.efun_snoop(args)
        if code == et::E_QUERY_SNOOP:
            let ci = self.user_conn(self.obj_of(self.arg(args, 0)))
            if ci >= 0 and self.obj_of(self.conns[ci].snooped_by) >= 0:
                return self.conns[ci].snooped_by
            return zero
        if code == et::E_QUERY_SNOOPING:
            let o = self.obj_of(self.arg(args, 0))
            return if o >= 0: self.obj_value(self.snoop_target(o)) else: zero
        if code == et::E_QUERY_CHARMODE:
            let ci = self.user_conn(self.obj_of(self.arg(args, 0)))
            return val::Value::Int(if ci < 0: (0 - 1) as i64 elif self.conns[ci].charmode: 1 as i64 else: 0 as i64)
        if code == et::E_REMOVE_CHARMODE:
            let ci = self.user_conn(self.obj_of(self.arg(args, 0)))
            if ci >= 0:
                self.conns[ci].charmode = false
            return zero
        if code == et::E_REMOVE_GET_CHAR:
            let ci = self.user_conn(self.obj_of(self.arg(args, 0)))
            if ci >= 0:
                self.clear_input_to(ci)
            return zero
        if code >= et::E_HAS_MXP and code <= et::E_HAS_MSP:
            let ci = self.user_conn(self.net_ob_arg(args, 0, self_ob))
            if ci < 0:
                return zero
            let c = self.conns[ci]
            let f = if code == et::E_HAS_MXP: c.mxp elif code == et::E_HAS_ZMP: c.zmp elif code == et::E_HAS_GMCP: c.gmcp elif code == et::E_HAS_MSDP: c.msdp else: c.msp
            return self.bool_v(f)
        if code == et::E_SEND_ZMP:
            if !self.is_str(self.arg(args, 0)):
                self.fail("Bad argument 1 to send_zmp()\n")
                return val::Value::Undef
            let mut items: List<val::Value> = List<val::Value>()
            match self.arg(args, 1):
                val::Value::Arr(h) ->
                    items = self.arrs[h].items
                _ ->
                    self.fail("Bad argument 2 to send_zmp()\n")
                    return val::Value::Undef
            let ci = self.oob_conn(self_ob)
            if ci >= 0:
                let mut strs: List<str> = List<str>()
                for i in 0..items.len():
                    strs.push(self.to_text(items[i]))
                self.send_zmp(ci, self.str_arg(args, 0), strs)
            return zero
        if code == et::E_SEND_GMCP or code == et::E_SEND_MSP:
            if !self.is_str(self.arg(args, 0)):
                self.fail(f"Bad argument 1 to {name}()\n")
                return val::Value::Undef
            let ci = self.oob_conn(self_ob)
            if ci >= 0:
                if code == et::E_SEND_GMCP:
                    self.send_gmcp(ci, self.str_arg(args, 0))
                else:
                    self.send_msp(ci, self.str_arg(args, 0))
            return zero
        if code == et::E_ACT_MXP:
            let ci = self.oob_conn(self_ob)
            if ci >= 0:
                self.act_mxp(ci)
            return zero
        if code == et::E_SEND_MSDP:
            match self.arg(args, 0):
                val::Value::Map(h) ->
                    let ci = self.oob_conn(self_ob)
                    if ci >= 0:
                        self.send_msdp(ci, h)
                    return zero
                _ ->
                    self.fail("Bad argument 1 to send_msdp()\n")
                    return val::Value::Undef
        if code == et::E_CLIENT_INFO:
            let ci = self.user_conn(self.net_ob_arg(args, 0, self_ob))
            return if ci >= 0: self.client_info(ci) else: zero
        if code >= et::E_REQUEST_TERM_TYPE and code <= et::E_SEND_NULLBYTE:
            return zero
        if code == et::E_NETWORK_STATS:
            return self.efun_network_stats()
        if code == et::E_INPUT_TO or code == et::E_GET_CHAR:
            return self.efun_input_to(args, self_ob, code == et::E_GET_CHAR)
        self.fail(f"Efun {name}() is not implemented by this driver.\n")
        val::Value::Undef

    # The case runner's telnet hooks (see the header).
    fn efun_tel_test(mut self, code: i32, args: List<val::Value>, self_ob: i32) -> val::Value:
        let zero = val::Value::Int(0 as i64)
        if code == et::E_TEST_TEL_OPEN:
            let u = self.obj_of(self.arg(args, 0))
            if u < 0:
                return zero
            let ci = self.conn_new(null_ptr(), 0)
            self.conn_offer(ci)
            self.conns[ci].user = u
            self.objs[u].conn = ci
            return val::Value::Int(ci as i64)
        if code == et::E_TEST_TEL_CONNECT:
            let ci = self.conn_new(null_ptr(), 0)
            self.conns[ci].ip = "127.0.0.1"
            self.conn_offer(ci)
            self.start_session(ci)
            return val::Value::Int(ci as i64)
        let ci = val::int_of(self.arg(args, 0)) as i32
        if code == et::E_TEST_TEL_TP:
            self.cur_player = self.obj_of(self.arg(args, 0))
            return zero
        if ci < 0 or ci >= self.conns.len():
            return zero
        if code == et::E_TEST_TEL_USER:
            let u = self.conns[ci].user
            return if self.conn_ok(ci) and self.alive(u): self.obj_value(u) else: zero
        if code == et::E_TEST_TEL_SAY:
            self.conn_input(ci, tc::tel_decode(self.str_arg(args, 1)))
            return val::Value::Str(tc::tel_encode(self.conn_take_output(ci)))
        if code == et::E_TEST_TEL_DRAIN:
            return val::Value::Str(tc::tel_encode(self.conn_take_output(ci)))
        if code == et::E_TEST_TEL_HANGUP:
            self.conn_close(ci, "connection closed by peer")
            return zero
        self.fail("unknown test hook\n")
        val::Value::Undef

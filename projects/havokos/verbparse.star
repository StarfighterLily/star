# The verb parser's registry -- todo.md HavokOS M6: `havok/parser.pike`'s
# registry efuns (parse_init, parse_refresh, parse_add_rule,
# parse_add_synonym, parse_remove, parse_dump), written like the reference
# from HavokOS's docs/verb-parser-spec.md.
#
# Why the parser is in M6 at all: logging in needs it. Every Dead Souls object
# calls parse_init() from create() (lib/comp/object.c), verbs register their
# rules with parse_add_rule() as /daemon/verbs loads them, and the player
# body calls parse_init()/parse_refresh() as it is set up, so with these
# efuns still "not implemented" the player object fails to load and nobody
# gets past character creation. What the registry does is small and fully
# specified (spec sections 3.1-3.6). The matching engine behind
# parse_sentence()/parse_my_rules() -- candidate discovery, noun phrases,
# the can_/direct_/indirect_ validation protocol and error ranking, most of
# parser.pike -- is `verbmatch.star`.
#
# Rules are compiled and checked exactly as the reference does, with its
# error messages: literals must be in the master's
# parse_command_prepos_list() (fetched once, again after the master calls
# parse_refresh()), no modifiers on STR/WRD, at most two object tokens, one
# plural, ten tokens.

import "value.star" as val
import "vm.star" as vm
import "vpdata.star" as vpd
import "efun_table.star" as et

const MAX_TOKENS: i32 = 10

# A literal in lower case, ASCII letters only (bytes above 127 may be UTF-8).
fn ascii_lower(s: str) -> str:
    let b = bytes_from_str(s)
    let mut o: Bytes = Bytes()
    for i in 0..b.len():
        let c = b[i] as i32
        if c >= 65 and c <= 90:
            o.push((c + 32) as u8)
        else:
            o.push(b[i])
    str_from_bytes(o)

impl vm::Vm:
    # An apply on a parser-information function; an error is reported, not
    # raised, and reads as 0.
    fn vp_ask_info(mut self, ob: i32, fname: str) -> val::Value:
        let ol = self.ostack.len()
        let sl = self.stack.len()
        let r = self.apply_value(ob, fname, List<val::Value>())
        if self.err:
            self.report_error(f"parser: {fname}() in {self.obj_name(ob)}")
            self.truncate_ostack(ol)
            self.truncate_stack(sl)
            return val::Value::Int(0 as i64)
        r

    fn vp_ask_remote(mut self, h: i32):
        let r = self.vp_ask_info(h, "livings_are_remote")
        if self.alive(h):
            self.objs[h].vp_remote = self.truthy(r)

    fn vp_is_known(self, ob: i32) -> bool:
        self.alive(ob) and (self.objs[ob].vp_known or ob == self.master_ob)

    # The master's parse_command_prepos_list(), cached until it calls
    # parse_refresh().
    fn vp_is_literal(mut self, w: str) -> bool:
        if !self.vp_literals_ok:
            let l = self.master_apply("parse_command_prepos_list", List<val::Value>(), -1)
            if self.err:
                return false
            let mut m: Set<str> = Set<str>()
            match l:
                val::Value::Arr(h) ->
                    let items = self.arrs[h].items
                    for i in 0..items.len():
                        match items[i]:
                            val::Value::Str(s) ->
                                m.insert(s)
                            _ -> 0
                _ -> 0
            if self.alive(self.master_ob):
                self.vp_literals = m
                self.vp_literals_ok = true
            else:
                return m.contains(w)
        self.vp_literals.contains(w)

    # Tokenize and check a rule (parser.pike compile_rule()); verb, handler
    # and seq are filled in by the caller. On an error `err` is set.
    fn vp_compile_rule(mut self, rule: str) -> vpd::VpRule:
        let raw = str_split(rule, " ")
        let mut parts: List<str> = List<str>()
        for i in 0..raw.len():
            if raw[i] != "":
                parts.push(raw[i])
        let mut toks: List<vpd::VpTok> = List<vpd::VpTok>()
        let mut objpos: List<i32> = List<i32>()
        let mut score = 1
        let mut nlits = 0
        let mut variable = false
        let mut text: List<str> = List<str>()
        let mut sig: List<str> = List<str>()
        let mut plurals = 0
        let bad = vpd::VpRule(toks = toks, text = "", sig = "", score = 0, nlits = 0, objpos = objpos, variable = false)
        if parts.len() > MAX_TOKENS:
            self.fail(f"Too many tokens in rule \"{rule}\".\n")
            return bad
        for ti in 0..parts.len():
            let p = parts[ti]
            # sscanf(p, "%s:%s", base, mods)
            let c = str_index_of(p, ":")
            let base = if c >= 0: vm::substr(p, 0, c) else: p
            let has_mods = c >= 0
            let mods = if c >= 0: vm::substr(p, c + 1, len(p)) else: ""
            if base == "OBJ" or base == "OBS" or base == "LIV" or base == "LVS":
                let mut living = base == "LIV" or base == "LVS"
                let mut plural = base == "OBS" or base == "LVS"
                let mut visible = false
                let mb = bytes_from_str(mods)
                for k in 0..mb.len():
                    let m = mb[k] as i32
                    if m == 108:
                        living = true
                    elif m == 118:
                        visible = true
                    elif m == 112:
                        plural = true
                    elif m == 99:
                        0
                    else:
                        self.fail(f"Unknown modifier '{vm::substr(mods, k, k + 1)}' in rule \"{rule}\".\n")
                        return bad
                objpos.push(ti)
                variable = true
                if plural:
                    plurals += 1
                score += 2 + (if living: 1 else: 0) + (if visible: 0 else: 1) - (if plural: 1 else: 0)
                let t = if living: (if plural: "LVS" else: "LIV") else: (if plural: "OBS" else: "OBJ")
                text.push(t)
                sig.push(if visible: concat(t, ":v") else: t)
                toks.push(vpd::VpTok(kind = vpd::T_OBJ, living = living, plural = plural, visible = visible))
            elif base == "STR" or base == "WRD":
                if has_mods:
                    self.fail(f"No modifiers allowed on {base} in rule \"{rule}\".\n")
                    return bad
                let kind = if base == "STR": vpd::T_STR else: vpd::T_WRD
                if kind == vpd::T_STR:
                    variable = true
                score += 1
                text.push(base)
                sig.push(base)
                toks.push(vpd::VpTok(kind = kind))
            else:
                let lit = self.vp_is_literal(p)
                if self.err:
                    return bad
                if !lit:
                    self.fail(f"Unknown literal \"{p}\" in rule \"{rule}\" (not in the master's parse_command_prepos_list()).\n")
                    return bad
                nlits += 1
                score += 1
                text.push(p)
                sig.push(concat("'", p))
                toks.push(vpd::VpTok(kind = vpd::T_LIT, word = p, lword = ascii_lower(p)))
        if objpos.len() > 2:
            self.fail(f"More than two object tokens in rule \"{rule}\".\n")
            return bad
        if plurals > 1:
            self.fail(f"More than one plural object token in rule \"{rule}\".\n")
            return bad
        vpd::VpRule(toks = toks, text = str_join(text, " "), sig = str_join(sig, " "), score = score, nlits = nlits, objpos = objpos, variable = variable)

    fn vp_verb_entry(mut self, verb: str) -> i32:
        if let Option::Some(i) = self.vp_verb_idx.get(verb):
            return i
        self.vp_verbs.push(vpd::VpVerb(name = verb))
        let i = self.vp_verbs.len() - 1
        self.vp_verb_idx.insert(verb, i)
        self.vp_vidx_ok = false
        i

    fn vp_add_rule_to(mut self, verb: str, r_in: vpd::VpRule):
        let mut r = r_in
        let vi = self.vp_verb_entry(verb)
        # the same rule again from the same handler moves to "newest"
        let old = self.vp_verbs[vi].rules
        let mut keep: List<vpd::VpRule> = List<vpd::VpRule>()
        for i in 0..old.len():
            let x = old[i]
            if !(self.lpc_eq(x.handler, r.handler) and x.sig == r.sig and x.verb == r.verb):
                keep.push(x)
        self.vp_next_seq += 1
        r.seq = self.vp_next_seq
        keep.push(r)
        self.vp_verbs[vi].rules = keep
        let h = self.obj_of(r.handler)
        if h >= 0 and !self.objs[h].vp_handler:
            self.objs[h].vp_handler = true
            self.vp_ask_remote(h)

    # Rules of a verb, following plain synonyms.
    fn vp_rules_of(self, verb: str, depth: i32) -> List<vpd::VpRule>:
        let mut out: List<vpd::VpRule> = List<vpd::VpRule>()
        if let Option::Some(vi) = self.vp_verb_idx.get(verb):
            let rs = self.vp_verbs[vi].rules
            for i in 0..rs.len():
                out.push(rs[i])
            let syn = self.vp_verbs[vi].synonym_for
            if syn != "" and depth < 8:
                let more = self.vp_rules_of(syn, depth + 1)
                for i in 0..more.len():
                    out.push(more[i])
        out

    # Everything the parser knows about a destructed object goes
    # (parser.pike forget_object()); a handler's rules go with it.
    fn vp_forget(mut self, ob: i32):
        self.objs[ob].vp_known = false
        self.objs[ob].vp_remote = false
        if self.objs[ob].vp_info >= 0:
            self.vp_info_free.push(self.objs[ob].vp_info)
            self.objs[ob].vp_info = -1
        if !self.objs[ob].vp_handler:
            return
        self.objs[ob].vp_handler = false
        for vi in 0..self.vp_verbs.len():
            let rs = self.vp_verbs[vi].rules
            let mut keep: List<vpd::VpRule> = List<vpd::VpRule>()
            for i in 0..rs.len():
                let h = self.obj_of(rs[i].handler)
                if h >= 0 and h != ob:
                    keep.push(rs[i])
            if keep.len() != rs.len():
                self.vp_verbs[vi].rules = keep

    fn vp_dump(self) -> str:
        let mut names: List<str> = List<str>()
        for i in 0..self.vp_verbs.len():
            names.push(self.vp_verbs[i].name)
        let mut a = 1
        while a < names.len():
            let x = names[a]
            let mut b = a - 1
            while b >= 0 and vm::str_cmp(x, names[b]) < 0:
                names[b + 1] = names[b]
                b -= 1
            names[b + 1] = x
            a += 1
        let mut out: List<str> = List<str>()
        for i in 0..names.len():
            if let Option::Some(vi) = self.vp_verb_idx.get(names[i]):
                let v = self.vp_verbs[vi]
                if v.synonym_for != "":
                    out.push(f"Verb {v.name} (synonym for {v.synonym_for})\n")
                if v.rules.len() == 0:
                    continue
                out.push(f"Verb {v.name}:\n")
                for k in 0..v.rules.len():
                    let h = self.obj_of(v.rules[k].handler)
                    let hn = if h >= 0: self.objs[h].name else: "?"
                    out.push(f"  ({hn}) {v.rules[k].text}\n")
        str_join(out, "")

    fn efun_parse(mut self, code: i32, name: str, args: List<val::Value>, self_ob: i32) -> val::Value:
        let zero = val::Value::Int(0 as i64)
        if code == et::E_PARSE_INIT:
            if self.alive(self_ob):
                self.objs[self_ob].vp_known = true
            return zero
        if code == et::E_PARSE_REFRESH:
            if self_ob == self.master_ob:
                self.vp_literals_ok = false
            if self.alive(self_ob):
                # known, or (the master) holding cached information
                if self.objs[self_ob].vp_known or self.objs[self_ob].vp_info >= 0:
                    self.objs[self_ob].vp_stale = true
                if self.objs[self_ob].vp_handler:
                    self.vp_ask_remote(self_ob)
            return zero
        if code == et::E_PARSE_ADD_RULE:
            if !self.vp_is_known(self_ob):
                let n = if self.alive(self_ob): self.objs[self_ob].name else: "object"
                self.fail(f"{n} is not known by the parser.  Call parse_init() first.\n")
                return val::Value::Undef
            if !self.is_str(self.arg(args, 0)):
                self.fail("Bad verb for parse_add_rule().\n")
                return val::Value::Undef
            let mut r = self.vp_compile_rule(self.str_arg(args, 1))
            if self.err:
                return val::Value::Undef
            r.verb = self.str_arg(args, 0)
            r.handler = self.obj_value(self_ob)
            self.vp_add_rule_to(r.verb, r)
            return zero
        if code == et::E_PARSE_ADD_SYNONYM:
            if !self.is_str(self.arg(args, 0)) or !self.is_str(self.arg(args, 1)):
                self.fail("Bad verb for parse_add_synonym().\n")
                return val::Value::Undef
            let nv = self.str_arg(args, 0)
            let ov = self.str_arg(args, 1)
            if nv == ov:
                self.fail("A verb cannot be a synonym for itself.\n")
                return val::Value::Undef
            if !self.vp_verb_idx.contains(ov):
                self.fail(f"parse_add_synonym(): no such verb \"{ov}\".\n")
                return val::Value::Undef
            if !self.is_str(self.arg(args, 2)):
                let vi = self.vp_verb_entry(nv)
                self.vp_verbs[vi].synonym_for = ov
                return zero
            let rule = self.str_arg(args, 2)
            let want = self.vp_compile_rule(rule)
            if self.err:
                return val::Value::Undef
            let me = self.obj_value(self_ob)
            let rs = self.vp_rules_of(ov, 0)
            for i in 0..rs.len():
                if rs[i].sig != want.sig or !self.lpc_eq(rs[i].handler, me) or self.dead_obj(rs[i].handler):
                    continue
                let mut c = self.vp_compile_rule(rule)
                if self.err:
                    return val::Value::Undef
                c.verb = rs[i].verb
                c.handler = me
                self.vp_add_rule_to(nv, c)
                return zero
            let who = if self.alive(self_ob): self.objs[self_ob].name else: "this object"
            self.fail(f"parse_add_synonym(): verb \"{ov}\" has no rule \"{rule}\" belonging to {who}.\n")
            return val::Value::Undef
        if code == et::E_PARSE_REMOVE:
            if let Option::Some(vi) = self.vp_verb_idx.get(self.str_arg(args, 0)):
                let me = self.obj_value(self_ob)
                let rs = self.vp_verbs[vi].rules
                let mut keep: List<vpd::VpRule> = List<vpd::VpRule>()
                for i in 0..rs.len():
                    if !(self.lpc_eq(rs[i].handler, me) and !self.dead_obj(rs[i].handler)):
                        keep.push(rs[i])
                self.vp_verbs[vi].rules = keep
            return zero
        if code == et::E_PARSE_DUMP:
            return val::Value::Str(self.vp_dump())
        if code == et::E_PARSE_SENTENCE:
            let s = if self.is_str(self.arg(args, 0)): self.str_arg(args, 0) else: ""
            return self.vp_parse(self_ob, s, self.arg(args, 2), self.arg(args, 3), -1, true)
        if code == et::E_PARSE_MY_RULES:
            let s = if self.is_str(self.arg(args, 1)): self.str_arg(args, 1) else: ""
            return self.vp_parse(self.obj_of(self.arg(args, 0)), s, val::Value::Int(0 as i64), val::Value::Int(0 as i64), self_ob, self.truthy(self.arg(args, 2)))
        self.fail(f"Efun {name}() is not implemented by this driver.\n")
        val::Value::Undef

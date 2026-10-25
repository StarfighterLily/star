# The verb parser's matching engine -- todo.md HavokOS M6: parse_sentence()
# and parse_my_rules(), `havok/parser.pike` from its "Small helpers" on
# (the registry it reads is `verbparse.star`), written like the reference
# from HavokOS's docs/verb-parser-spec.md.
#
# Why it is in M6: logging into Dead Souls ends with commands (the login
# runs `look` for the new player, the player's setup runs others), and every
# command that isn't a command file is a verb, parsed here. Without it a
# player gets as far as choosing a race and then sees nothing.
#
# A parse, as in the reference:
#   1. split the input into words, find every verb that is a prefix
#   2. enumerate every way each rule of those verbs can cover the remaining
#      words (an interpretation per split), without calling any LPC code
#   3. sort the interpretations best-first (specificity, literals, recency,
#      order) and evaluate them in that order: resolve the noun phrases
#      against the candidates, then the can_ / direct_ / indirect_ / pair
#      checks. The first acceptable one gets its do_ call.
#   4. if none is acceptable, the best failed one names the error, which the
#      master turns into a message (parser_error_message()).
#
# Followed function for function. Differences in mechanism only:
# - The reference's Parse and Interp objects are on the VM's vp_ps/vp_its
#   stacks and addressed by index (`pi`, `k`): an apply made while checking
#   can call parse_sentence() again, and nothing here may hold a copy of
#   either across an LPC call. vp_parse() pops both back however the parse
#   ends, since an error in an apply unwinds through it.
# - The closures inside resolve_pair() (pair(), partnered(), no_pair()) are
#   methods; pair()'s memo, refusal and cap live on the interpretation.
# - Its apply-name cache and function-lookup cache are not kept; they only
#   saved repeated lookups.
# - An object's information cache remembers the strings an id list was
#   built from rather than a copy of the LPC array, which is the same test:
#   the lists are built from those strings alone.

import "value.star" as val
import "vm.star" as vm
import "vpdata.star" as vpd
import "program.star" as pg
import "verbparse.star" as vp

const ERR_IS_NOT: i32 = 1
const ERR_NOT_LIVING: i32 = 2
const ERR_NOT_ACCESSIBLE: i32 = 3
const ERR_AMBIG: i32 = 4
const ERR_ORDINAL: i32 = 5
const ERR_ALLOCATED: i32 = 6
const ERR_THERE_IS_NO: i32 = 7
const ERR_BAD_MULTIPLE: i32 = 8
const ERR_TOO_MANY_PAIRS: i32 = 9

# answer kinds of a check: NO, YES, and MSG ("this one, but it fails")
const NO: i32 = 0
const YES: i32 = 1
const MSG: i32 = 2

const PAIR_CAP: i32 = 100
const SPLIT_CAP: i32 = 256

# Characters that make up words; apostrophes and control characters are
# dropped without splitting; everything else separates words.
fn word_char(c: i32) -> bool:
    (c >= 97 and c <= 122) or (c >= 65 and c <= 90) or (c >= 48 and c <= 57) or c == 42 or c == 63 or c == 33 or c == 46 or c == 58 or c > 127

fn dropped_char(c: i32) -> bool:
    c == 39 or c < 32 or c == 127

struct SplitText:
    words: List<str>
    starts: List<i32>
    ends: List<i32>

# Split text into lower-case words, with the offsets of the first and last
# kept character of each.
fn split_text(s: str) -> SplitText:
    let b = bytes_from_str(s)
    let n = b.len()
    let mut words: List<str> = List<str>()
    let mut starts: List<i32> = List<i32>()
    let mut ends: List<i32> = List<i32>()
    let mut i = 0
    while i < n:
        let c0 = b[i] as i32
        if !word_char(c0) and !dropped_char(c0):
            i += 1
            continue
        let mut buf: Bytes = Bytes()
        let mut first = -1
        let mut last = -1
        while i < n:
            let c = b[i] as i32
            if word_char(c):
                buf.push((if c >= 65 and c <= 90: c + 32 else: c) as u8)
                if first < 0:
                    first = i
                last = i
            elif !dropped_char(c):
                break
            i += 1
        if buf.len() > 0:
            words.push(str_from_bytes(buf))
            starts.push(first)
            ends.push(last)
    SplitText(words = words, starts = starts, ends = ends)

# A name from an id list as words ("long sword" -> ["long", "sword"]).
fn name_words(id: str) -> List<str>:
    let l = vp::ascii_lower(id)
    let b = bytes_from_str(l)
    let mut plain = true
    for i in 0..b.len():
        let c = b[i] as i32
        if !((c >= 97 and c <= 122) or (c >= 48 and c <= 57) or c == 32):
            plain = false
            break
    if plain:
        let parts = str_split(l, " ")
        let mut out: List<str> = List<str>()
        for i in 0..parts.len():
            if parts[i] != "":
                out.push(parts[i])
        return out
    split_text(id).words

# "1st", "2nd", "third", "a" ...; 0 if not an ordinal.
fn ordinal(w: str) -> i32:
    if w == "first" or w == "a" or w == "an" or w == "any":
        return 1
    if w == "second" or w == "other":
        return 2
    if w == "third":
        return 3
    if w == "fourth":
        return 4
    if w == "fifth":
        return 5
    if w == "sixth":
        return 6
    if w == "seventh":
        return 7
    if w == "eighth":
        return 8
    if w == "ninth":
        return 9
    let b = bytes_from_str(w)
    if b.len() < 3:
        return 0
    # sscanf("%d%s"), and the number written plainly ((string)n + suf == w)
    let mut k = 0
    while k < b.len() and (b[k] as i32) >= 48 and (b[k] as i32) <= 57:
        k += 1
    if k == 0 or k >= b.len() or (b[0] as i32) == 48 or k > 9:
        return 0
    let n = vm::parse_int_prefix(vm::substr(w, 0, k)) as i32
    let suf = vm::substr(w, k, b.len())
    let mut want = "th"
    if n % 100 < 11 or n % 100 > 13:
        if n % 10 == 1:
            want = "st"
        elif n % 10 == 2:
            want = "nd"
        elif n % 10 == 3:
            want = "rd"
    if suf == want:
        return n
    0

fn words_eq(w: List<str>, from: i32, name: List<str>) -> bool:
    if from < 0 or from + name.len() > w.len():
        return false
    for i in 0..name.len():
        if w[from + i] != name[i]:
            return false
    true

# Can words[i..to] be read as adjectives of one object ("the" is skipped)?
fn adj_ok(adjs: List<List<str>>, w: List<str>, i: i32, to: i32) -> bool:
    if i > to:
        return true
    if w[i] == "the":
        return adj_ok(adjs, w, i + 1, to)
    for k in 0..adjs.len():
        let a = adjs[k]
        if i + a.len() - 1 > to:
            continue
        if !words_eq(w, i, a):
            continue
        if adj_ok(adjs, w, i + a.len(), to):
            return true
    false

# Names grouped by their last word (indices into the name list).
fn by_last(names: List<List<str>>) -> Map<str, List<i32>>:
    let mut m: Map<str, List<i32>> = Map<str, List<i32>>()
    for i in 0..names.len():
        let w = names[i]
        let last = w[w.len() - 1]
        let mut l: List<i32> = List<i32>()
        if let Option::Some(x) = m.get(last):
            l = x
        l.push(i)
        m.insert(last, l)
    m

# Every way rule r can cover words[wi..], as flat span lists. STR takes as
# few words as possible first, object phrases as many (the same preference
# seen from the other side).
fn splits(words: List<str>, r: vpd::VpRule, ti: i32, wi: i32, spans: List<i32>, budget: i32) -> List<List<i32>>:
    let n = words.len()
    let mut out: List<List<i32>> = List<List<i32>>()
    if ti == r.toks.len():
        if wi == n:
            out.push(spans)
        return out
    let t = r.toks[ti]
    let maxlen = n - wi - (r.toks.len() - ti - 1)
    if maxlen < 1:
        return out
    if t.kind == vpd::T_LIT or t.kind == vpd::T_WRD:
        if t.kind == vpd::T_LIT and words[wi] != t.lword:
            return out
        let mut s = spans
        s[ti * 2] = wi
        s[ti * 2 + 1] = wi
        return splits(words, r, ti + 1, wi + 1, s, budget)
    if t.kind == vpd::T_STR:
        let mut l = 1
        while l <= maxlen and out.len() < budget:
            let mut s = spans
            s[ti * 2] = wi
            s[ti * 2 + 1] = wi + l - 1
            let sub = splits(words, r, ti + 1, wi + l, s, budget - out.len())
            for k in 0..sub.len():
                out.push(sub[k])
            l += 1
        return out
    let mut l = maxlen
    while l >= 1 and out.len() < budget:
        let mut s = spans
        s[ti * 2] = wi
        s[ti * 2 + 1] = wi + l - 1
        let sub = splits(words, r, ti + 1, wi + l, s, budget - out.len())
        for k in 0..sub.len():
            out.push(sub[k])
        l -= 1
    out

# Can rule r possibly match words[from..]? (no LPC calls)
fn may_match(words: List<str>, r: vpd::VpRule, from: i32) -> bool:
    let rest = words.len() - from
    let ntok = r.toks.len()
    if rest < ntok or (!r.variable and rest != ntok):
        return false
    if r.nlits > 0:
        for i in 0..ntok:
            let t = r.toks[i]
            if t.kind == vpd::T_LIT:
                let mut found = false
                for k in from..words.len():
                    if words[k] == t.lword:
                        found = true
                        break
                if !found:
                    return false
    true

# Better interpretations first: specificity, literals, newest rule, order found.
fn worse(x: vpd::VpInterp, y: vpd::VpInterp) -> bool:
    if x.rule.score != y.rule.score:
        return x.rule.score < y.rule.score
    if x.rule.nlits != y.rule.nlits:
        return x.rule.nlits < y.rule.nlits
    if x.rule.seq != y.rule.seq:
        return x.rule.seq < y.rule.seq
    x.order > y.order

fn worse_failure(x: vpd::VpInterp, y: vpd::VpInterp) -> bool:
    if x.fails != y.fails:
        return x.fails > y.fails
    if x.tin_only != y.tin_only:
        return x.tin_only
    worse(x, y)

fn falses(n: i32) -> List<bool>:
    let mut out: List<bool> = List<bool>()
    for i in 0..n:
        out.push(false)
    out

# One error (an entry of failed()'s errs): its type, argument and flag, and
# how many failures it stands for (both() makes it 2); `has` false is the
# reference's "no error" (0).
struct VpErr:
    has: bool
    et: i32 = 0
    earg: val::Value = val::Value::Int(0 as i64)
    eflag: i32 = 0
    count: i32 = 1

fn no_err() -> VpErr:
    VpErr(has = false)

fn mk_err(t: i32, arg: val::Value, flag: i32) -> VpErr:
    VpErr(has = true, et = t, earg = arg, eflag = flag)

fn both(e: VpErr) -> VpErr:
    VpErr(has = e.has, et = e.et, earg = e.earg, eflag = e.eflag, count = 2)

# A check's answer (ask()): NO/YES/MSG and the message.
struct VpAns:
    kind: i32
    msg: val::Value

# token_cands(): an error, or the candidates and whether the phrase is plural.
struct VpTC:
    err: VpErr
    list: List<i32>
    many: bool

# Where an apply name resolved: the object (shadows honoured) and function.
struct VpFn:
    target: i32
    e: pg::DispEntry

struct VpCall:
    found: bool
    r: val::Value

# names_ending()'s ({ cand, words, plural }).
struct VpEnt:
    c: i32
    words: List<str>
    plural: bool

impl vm::Vm:
    # --- object information ---------------------------------------------------

    # The strings of an id-list answer as a comparable key ("-" when it isn't
    # an array): the names are built from those alone.
    fn vp_strings_key(self, v: val::Value) -> str:
        match v:
            val::Value::Arr(h) ->
                let items = self.arrs[h].items
                let mut parts: List<str> = List<str>()
                for i in 0..items.len():
                    match items[i]:
                        val::Value::Str(s) ->
                            parts.push(f"{len(s)}:{s}")
                        _ ->
                            parts.push("x")
                return concat("A", str_join(parts, ","))
            _ ->
                return "-"

    # An id-list apply result as a list of names (each a word list).
    fn vp_name_list(self, v: val::Value) -> List<List<str>>:
        let mut out: List<List<str>> = List<List<str>>()
        match v:
            val::Value::Arr(h) ->
                let items = self.arrs[h].items
                let mut seen: Set<str> = Set<str>()
                for i in 0..items.len():
                    match items[i]:
                        val::Value::Str(x) ->
                            if seen.contains(x):
                                continue
                            seen.insert(x)
                            let w = name_words(x)
                            let key = str_join(w, " ")
                            if w.len() == 0 or (key != x and seen.contains(key)):
                                continue
                            seen.insert(key)
                            out.push(w)
                        _ -> 0
            _ -> 0
        out

    fn vp_info_slot(mut self, ob: i32) -> i32:
        let cur = self.objs[ob].vp_info
        if cur >= 0:
            return cur
        let mut ii = -1
        if self.vp_info_free.len() > 0:
            ii = self.vp_info_free[self.vp_info_free.len() - 1]
            self.vp_info_free.pop()
            self.vp_infos[ii] = vpd::VpInfo()
        else:
            self.vp_infos.push(vpd::VpInfo())
            ii = self.vp_infos.len() - 1
        self.objs[ob].vp_info = ii
        ii

    # Cached object information, fetched again after parse_refresh(); -1
    # when the object is not known or was destructed while being asked.
    fn vp_info_of(mut self, ob: i32) -> i32:
        if !self.alive(ob):
            return -1
        if !self.objs[ob].vp_known and self.objs[ob].vp_info < 0 and ob != self.master_ob:
            return -1
        let ii = self.vp_info_slot(ob)
        if self.objs[ob].vp_stale:
            # first, so a parse_refresh() from inside an apply sticks
            self.objs[ob].vp_stale = false
            let raw = self.vp_ask_info(ob, "parse_command_id_list")
            let k1 = self.vp_strings_key(raw)
            if k1 != self.vp_infos[ii].raw_nouns:
                let names = self.vp_name_list(raw)
                self.vp_infos[ii].raw_nouns = k1
                self.vp_infos[ii].nouns = names
                self.vp_infos[ii].noun_last = by_last(names)
            let raw2 = self.vp_ask_info(ob, "parse_command_plural_id_list")
            let k2 = self.vp_strings_key(raw2)
            if k2 != self.vp_infos[ii].raw_plurals:
                let names = self.vp_name_list(raw2)
                self.vp_infos[ii].raw_plurals = k2
                self.vp_infos[ii].plurals = names
                self.vp_infos[ii].plural_last = by_last(names)
            let raw3 = self.vp_ask_info(ob, "parse_command_adjectiv_id_list")
            let k3 = self.vp_strings_key(raw3)
            if k3 != self.vp_infos[ii].raw_adjs:
                let names = self.vp_name_list(raw3)
                let mut words: Set<str> = Set<str>()
                for i in 0..names.len():
                    for j in 0..names[i].len():
                        words.insert(names[i][j])
                self.vp_infos[ii].raw_adjs = k3
                self.vp_infos[ii].adjs = names
                self.vp_infos[ii].adj_words = words
            let lv = self.vp_ask_info(ob, "is_living")
            self.vp_infos[ii].living = self.truthy(lv)
            let ac = self.vp_ask_info(ob, "inventory_accessible")
            self.vp_infos[ii].access = self.truthy(ac)
            let vi = self.vp_ask_info(ob, "inventory_visible")
            self.vp_infos[ii].visible = self.truthy(vi)
            if !self.alive(ob):
                return -1
        ii

    # --- candidates -------------------------------------------------------------

    fn vp_add_cand(mut self, pi: i32, ob: i32, info: i32, reach: bool, carried: bool):
        let idx = self.vp_ps[pi].cands.len()
        self.vp_ps[pi].seen.insert(ob)
        self.vp_ps[pi].cands.push(vpd::VpCand(ob = self.obj_value(ob), oh = ob, info = info, idx = idx, reach = reach, carried = carried))

    fn vp_visit(mut self, pi: i32, ob: i32, reach: bool, carried: bool):
        if self.vp_ps[pi].seen.contains(ob) or !self.alive(ob):
            return
        let inside = carried or ob == self.vp_ps[pi].subject
        if self.vp_is_known(ob):
            let ii = self.vp_info_of(ob)
            if ii < 0:
                return
            self.vp_add_cand(pi, ob, ii, reach, carried)
            if self.vp_infos[ii].visible:
                let inv = self.live_inventory(ob)
                let acc = self.vp_infos[ii].access
                for k in 0..inv.len():
                    self.vp_visit(pi, inv[k], reach and acc, inside)
        else:
            self.vp_ps[pi].seen.insert(ob)
            let inv = self.live_inventory(ob)
            for k in 0..inv.len():
                self.vp_visit(pi, inv[k], reach, inside)

    # env array: ({ table, ({ cup, plate }), chair })
    fn vp_visit_array(mut self, pi: i32, a: List<val::Value>, reach: bool, carried: bool):
        let mut k = 0
        while k < a.len():
            let x = a[k]
            let mut sub = false
            match x:
                val::Value::Arr(h) ->
                    self.vp_visit_array(pi, self.arrs[h].items, reach, carried)
                    sub = true
                _ -> 0
            if sub:
                k += 1
                continue
            let is_ob = match x:
                val::Value::Obj(h, g) -> true
                _ -> false
            if !is_ob:
                k += 1
                continue
            let mut inner: List<val::Value> = List<val::Value>()
            let mut has_inner = false
            if k + 1 < a.len():
                match a[k + 1]:
                    val::Value::Arr(h) ->
                        inner = self.arrs[h].items
                        has_inner = true
                    _ -> 0
            if has_inner:
                k += 1
            k += 1
            let o = self.obj_of(x)
            if o < 0 or self.vp_ps[pi].seen.contains(o):
                continue
            let inside = carried or o == self.vp_ps[pi].subject
            if self.vp_is_known(o):
                let ii = self.vp_info_of(o)
                if ii < 0:
                    continue
                self.vp_add_cand(pi, o, ii, reach, carried)
                if has_inner and self.vp_infos[ii].visible:
                    self.vp_visit_array(pi, inner, reach and self.vp_infos[ii].access, inside)
            elif has_inner:
                self.vp_visit_array(pi, inner, reach, inside)

    fn vp_discover(mut self, pi: i32):
        self.vp_ps[pi].have_cands = true
        self.vp_ps[pi].cands = List<vpd::VpCand>()
        self.vp_ps[pi].seen = Set<i32>()
        let mut array_env = false
        match self.vp_ps[pi].env:
            val::Value::Arr(h) ->
                array_env = true
                self.vp_visit_array(pi, self.arrs[h].items, true, false)
            _ -> 0
        if !array_env:
            let subj = self.vp_ps[pi].subject
            let e = if self.alive(subj): self.objs[subj].env else: -1
            if self.alive(e):
                if self.vp_is_known(e):
                    let ii = self.vp_info_of(e)
                    if ii >= 0:
                        self.vp_add_cand(pi, e, ii, true, false)
                self.vp_ps[pi].seen.insert(e)
                let inv = self.live_inventory(e)
                for k in 0..inv.len():
                    self.vp_visit(pi, inv[k], true, false)
        # remote users, asked again on every parse
        let ol = self.ostack.len()
        let sl = self.stack.len()
        let users = self.master_apply("parse_command_users", List<val::Value>(), -1)
        if self.err:
            self.report_error("parser: parse_command_users()")
            self.truncate_ostack(ol)
            self.truncate_stack(sl)
        else:
            match users:
                val::Value::Arr(h) ->
                    let us = self.arrs[h].items
                    for i in 0..us.len():
                        let u = self.obj_of(us[i])
                        if u < 0 or self.vp_ps[pi].seen.contains(u) or !self.objs[u].vp_known:
                            continue
                        let ii = self.vp_info_of(u)
                        if ii < 0:
                            continue
                        self.vp_add_cand(pi, u, ii, true, false)
                        let last = self.vp_ps[pi].cands.len() - 1
                        self.vp_ps[pi].cands[last].remote = true
                _ -> 0
        # nicknames: extra nouns for candidates
        match self.vp_ps[pi].nicks:
            val::Value::Map(h) ->
                let mut ks: List<str> = List<str>()
                let mk = self.maps[h].keys
                for i in 0..mk.len():
                    match mk[i]:
                        val::Value::Str(s) ->
                            ks.push(s)
                        _ -> 0
                let mut a = 1
                while a < ks.len():
                    let x = ks[a]
                    let mut b = a - 1
                    while b >= 0 and vm::str_cmp(x, ks[b]) < 0:
                        ks[b + 1] = ks[b]
                        b -= 1
                    ks[b + 1] = x
                    a += 1
                for i in 0..ks.len():
                    let target = self.obj_of(self.map_get(h, val::Value::Str(ks[i])))
                    if target < 0:
                        continue
                    let mut c = -1
                    for j in 0..self.vp_ps[pi].cands.len():
                        if self.vp_ps[pi].cands[j].oh == target:
                            c = j
                            break
                    let w = name_words(ks[i])
                    if c < 0 or w.len() == 0:
                        continue
                    let ni = self.vp_ps[pi].nick_cand.len()
                    self.vp_ps[pi].nick_cand.push(c)
                    self.vp_ps[pi].nick_words.push(w)
                    let last = w[w.len() - 1]
                    let mut l: List<i32> = List<i32>()
                    if let Option::Some(x) = self.vp_ps[pi].nick_last.get(last):
                        l = x
                    l.push(ni)
                    self.vp_ps[pi].nick_last.insert(last, l)
            _ -> 0

    # Every candidate name ending in `last`, in discovery order (nicknames
    # last).
    fn vp_names_ending(self, pi: i32, last: str) -> List<VpEnt>:
        let mut out: List<VpEnt> = List<VpEnt>()
        let cands = self.vp_ps[pi].cands
        for k in 0..cands.len():
            let inf = self.vp_infos[cands[k].info]
            if let Option::Some(l) = inf.noun_last.get(last):
                for j in 0..l.len():
                    out.push(VpEnt(c = k, words = inf.nouns[l[j]], plural = false))
            if let Option::Some(l) = inf.plural_last.get(last):
                for j in 0..l.len():
                    out.push(VpEnt(c = k, words = inf.plurals[l[j]], plural = true))
        if let Option::Some(l) = self.vp_ps[pi].nick_last.get(last):
            for j in 0..l.len():
                out.push(VpEnt(c = self.vp_ps[pi].nick_cand[l[j]], words = self.vp_ps[pi].nick_words[l[j]], plural = false))
        out

    fn vp_is_adjective(self, pi: i32, word: str) -> bool:
        let cands = self.vp_ps[pi].cands
        for k in 0..cands.len():
            if self.vp_infos[cands[k].info].adj_words.contains(word):
                return true
        false

    # The words a..b as typed: spacing collapsed, case kept.
    fn vp_typed(self, pi: i32, a: i32, b: i32) -> str:
        let s = vm::substr(self.vp_ps[pi].input, self.vp_ps[pi].starts[a], self.vp_ps[pi].ends[b] + 1)
        let parts = str_split(str_replace(str_replace(str_replace(s, "\t", " "), "\n", " "), "\r", " "), " ")
        let mut out: List<str> = List<str>()
        for i in 0..parts.len():
            if parts[i] != "":
                out.push(parts[i])
        str_join(out, " ")

    # --- noun phrases -------------------------------------------------------------

    fn vp_phrase_err(self, t: i32, arg: val::Value, flag: i32) -> vpd::VpPhrase:
        vpd::VpPhrase(kind = vpd::PH_ERR, et = t, earg = arg, eflag = flag)

    # [the] [ordinal|my]... adjectives noun, over words s0..e. many: the
    # phrase follows "all" and is read as plural whatever its noun.
    fn vp_noun_phrase(mut self, pi: i32, s0: i32, e: i32, many: bool) -> vpd::VpPhrase:
        let w = self.vp_ps[pi].words
        let mut s = s0
        let mut ord = 0
        let mut ordat = 0
        let mut my = false
        while s < e:
            if w[s] == "the":
                s += 1
                continue
            let o = if ord == 0 and !many: ordinal(w[s]) else: 0
            if o != 0:
                ord = o
                s += 1
                ordat = s
            elif !my and w[s] == "my":
                my = true
                s += 1
            else:
                break
        let nc = self.vp_ps[pi].cands.len()
        let mut one = falses(nc)
        let mut more = falses(nc)
        let mut noun = ""
        let mut has_noun = false
        let mut noun_pl = false
        let mut noun_at = 0
        let ents = self.vp_names_ending(pi, w[e])
        for k in 0..ents.len():
            let ent = ents[k]
            let nw = ent.words
            let st = e - nw.len() + 1
            if st < s or (nw.len() > 1 and !words_eq(w, st, nw)):
                continue
            if !has_noun or (noun_pl and !ent.plural):
                noun = str_join(nw, " ")
                has_noun = true
                noun_pl = ent.plural
                noun_at = st
            let c = self.vp_ps[pi].cands[ent.c]
            if my and !c.carried:
                continue
            if !adj_ok(self.vp_infos[c.info].adjs, w, s, st - 1):
                continue
            if ent.plural:
                more[c.idx] = true
            else:
                one[c.idx] = true
        let mut n_one = 0
        let mut n_more = 0
        let mut n_any = 0
        for k in 0..nc:
            if one[k]:
                n_one += 1
            if more[k]:
                n_more += 1
            if one[k] or more[k]:
                n_any += 1
        let mut ph = vpd::VpPhrase(kind = vpd::PH_ONE)
        if many and n_any > 0:
            ph = vpd::VpPhrase(kind = vpd::PH_MANY, has_idx = true)
            for k in 0..nc:
                if one[k] or more[k]:
                    ph.idx.push(k)
        elif n_one > 0:
            ph = vpd::VpPhrase(kind = vpd::PH_ONE, has_idx = true, ord = ord, ordat = ordat)
            for k in 0..nc:
                if one[k]:
                    ph.idx.push(k)
        elif n_more > 0:
            ph = vpd::VpPhrase(kind = vpd::PH_MANY, has_idx = true)
            for k in 0..nc:
                if more[k]:
                    ph.idx.push(k)
        else:
            # an unknown noun, or a word before the noun that is nobody's
            # adjective, means the phrase names nothing ("big xyzzy", "10
            # gold", "of the daggers"); known words that do not fit together
            # are ERR_IS_NOT ("red sword")
            let mut unknown = !has_noun
            let mut k = s
            while k < noun_at and !unknown:
                unknown = w[k] != "the" and !self.vp_is_adjective(pi, w[k])
                k += 1
            if unknown:
                return self.vp_phrase_err(ERR_THERE_IS_NO, val::Value::Str(vp::ascii_lower(self.vp_typed(pi, s, e))), 0)
        # how many candidates the noun alone names (error flags)
        if has_noun:
            let mut named = falses(nc)
            for k in 0..ents.len():
                if ents[k].plural == noun_pl and str_join(ents[k].words, " ") == noun:
                    named[self.vp_ps[pi].cands[ents[k].c].idx] = true
            let mut cnt = 0
            for k in 0..nc:
                if named[k]:
                    cnt += 1
            ph.noun = noun
            ph.has_noun = true
            ph.ncount = cnt
        if !ph.has_idx:
            let arg = if has_noun: val::Value::Str(noun) else: val::Value::Int(0 as i64)
            return self.vp_phrase_err(ERR_IS_NOT, arg, if ph.ncount > 1: 1 else: 0)
        ph

    fn vp_phrase(mut self, pi: i32, a: i32, b: i32) -> vpd::VpPhrase:
        let key = a * 1024 + b
        if let Option::Some(k) = self.vp_ps[pi].ph_index.get(key):
            return self.vp_ps[pi].phrases[k]
        if !self.vp_ps[pi].have_cands:
            self.vp_discover(pi)
            if self.err:
                return self.vp_phrase_err(0, val::Value::Int(0 as i64), 0)
        let w = self.vp_ps[pi].words
        let mut ph = vpd::VpPhrase(kind = vpd::PH_ERR)
        if a == b and (w[a] == "me" or w[a] == "myself"):
            let mut k = -1
            let subj = self.vp_ps[pi].subject
            for j in 0..self.vp_ps[pi].cands.len():
                if self.vp_ps[pi].cands[j].oh == subj:
                    k = j
                    break
            if k < 0:
                ph = self.vp_phrase_err(ERR_THERE_IS_NO, val::Value::Str(w[a]), 0)
            else:
                ph = vpd::VpPhrase(kind = vpd::PH_ONE, has_idx = true, noun = w[a], has_noun = true, ncount = 1)
                ph.idx.push(k)
        elif w[a] == "all":
            if a == b:
                let nc = self.vp_ps[pi].cands.len()
                ph = vpd::VpPhrase(kind = vpd::PH_MANY, has_idx = true, noun = "all", has_noun = true, ncount = nc)
                for j in 0..nc:
                    ph.idx.push(j)
                if nc == 0:
                    ph = self.vp_phrase_err(ERR_THERE_IS_NO, val::Value::Str("all"), 0)
            else:
                let mut s = a + 1
                if w[s] == "of":
                    s += 1
                if s > b:
                    ph = self.vp_phrase_err(ERR_THERE_IS_NO, val::Value::Str(vp::ascii_lower(self.vp_typed(pi, a, b))), 0)
                else:
                    ph = self.vp_noun_phrase(pi, s, b, true)
        else:
            ph = self.vp_noun_phrase(pi, a, b, false)
        if self.err:
            return ph
        let k = self.vp_ps[pi].phrases.len()
        self.vp_ps[pi].phrases.push(ph)
        self.vp_ps[pi].ph_index.insert(key, k)
        ph

    # The candidates a phrase offers an object token.
    fn vp_token_cands(self, pi: i32, ph: vpd::VpPhrase, t: vpd::VpTok, remote: bool) -> VpTC:
        let empty: List<i32> = List<i32>()
        if ph.kind == vpd::PH_ERR:
            return VpTC(err = mk_err(ph.et, ph.earg, ph.eflag), list = empty, many = false)
        if ph.kind == vpd::PH_MANY and !t.plural:
            return VpTC(err = mk_err(ERR_BAD_MULTIPLE, val::Value::Int(0 as i64), 0), list = empty, many = false)
        let flag = if ph.ncount > 1: 1 else: 0
        let noun = if ph.has_noun: val::Value::Str(ph.noun) else: val::Value::Int(0 as i64)
        let mut list = ph.idx
        if !remote:
            let mut keep: List<i32> = List<i32>()
            for k in 0..list.len():
                if !self.vp_ps[pi].cands[list[k]].remote:
                    keep.push(list[k])
            list = keep
            if list.len() == 0:
                return VpTC(err = mk_err(ERR_IS_NOT, noun, flag), list = empty, many = false)
        if t.living:
            let mut keep: List<i32> = List<i32>()
            for k in 0..list.len():
                if self.vp_infos[self.vp_ps[pi].cands[list[k]].info].living:
                    keep.push(list[k])
            list = keep
            if list.len() == 0:
                return VpTC(err = mk_err(ERR_NOT_LIVING, noun, flag), list = empty, many = false)
        if !t.visible:
            let mut keep: List<i32> = List<i32>()
            for k in 0..list.len():
                if self.vp_ps[pi].cands[list[k]].reach:
                    keep.push(list[k])
            list = keep
            if list.len() == 0:
                return VpTC(err = mk_err(ERR_NOT_ACCESSIBLE, noun, flag), list = empty, many = false)
        VpTC(err = no_err(), list = list, many = ph.kind == vpd::PH_MANY)

    # --- applies ------------------------------------------------------------------

    # Apply names for a rule and prefix, in lookup order ('A'..'D' forms
    # alongside in vp_apply_forms()); `pl` marks object tokens to be named
    # obs/lvs.
    fn vp_apply_names(self, r: vpd::VpRule, pfx: str, pl: List<bool>) -> List<str>:
        let mut a: List<str> = List<str>()
        let mut b: List<str> = List<str>()
        for ti in 0..r.toks.len():
            let t = r.toks[ti]
            if t.kind == vpd::T_LIT:
                a.push(t.word)
                b.push("word")
                continue
            let n = if t.kind == vpd::T_STR: "str" elif t.kind == vpd::T_WRD: "wrd" elif t.living: (if pl[ti]: "lvs" else: "liv") else: (if pl[ti]: "obs" else: "obj")
            a.push(n)
            b.push(n)
        let v = str_replace(r.verb, " ", "_")
        let mut names: List<str> = List<str>()
        names.push(concat(concat(pfx, v), if a.len() > 0: concat("_", str_join(a, "_")) else: ""))
        if r.nlits > 0:
            names.push(concat(concat(concat(pfx, v), "_"), str_join(b, "_")))
        names.push(concat(concat(pfx, "verb"), if b.len() > 0: concat("_", str_join(b, "_")) else: ""))
        names.push(concat(pfx, "verb_rule"))
        names

    fn vp_apply_forms(self, r: vpd::VpRule) -> List<i32>:
        if r.nlits > 0:
            return [65, 66, 67, 68]
        [65, 67, 68]

    fn vp_build_args(self, k: i32, form: i32, vals: List<val::Value>) -> List<val::Value>:
        let r = self.vp_its[k].rule
        let mut plain: List<val::Value> = List<val::Value>()
        let mut with_lits: List<val::Value> = List<val::Value>()
        let mut texts: List<val::Value> = List<val::Value>()
        for ti in 0..r.toks.len():
            if r.toks[ti].kind == vpd::T_LIT:
                with_lits.push(val::Value::Str(r.toks[ti].word))
                continue
            plain.push(vals[ti])
            with_lits.push(vals[ti])
            texts.push(val::Value::Str(self.vp_its[k].text[ti]))
        let mut out: List<val::Value> = List<val::Value>()
        if form == 65:
            for i in 0..plain.len():
                out.push(plain[i])
        elif form == 66:
            for i in 0..with_lits.len():
                out.push(with_lits[i])
        elif form == 67:
            out.push(val::Value::Str(r.verb))
            for i in 0..with_lits.len():
                out.push(with_lits[i])
            out.push(val::Value::Str(self.vp_its[k].typed_verb))
        else:
            out.push(val::Value::Str(r.verb))
            out.push(val::Value::Str(r.text))
            for i in 0..plain.len():
                out.push(plain[i])
            out.push(val::Value::Str(self.vp_its[k].typed_verb))
        for i in 0..texts.len():
            out.push(texts[i])
        out

    # Shadow-aware lookup, as apply_value() does it.
    fn vp_find_fn(self, ob: i32, name: str) -> VpFn:
        let mut target = ob
        let sb = self.objs[ob].shadowed_by
        if sb >= 0:
            let mut s = sb
            while s >= 0 and s != ob:
                if self.public_fn(s, name).prog >= 0:
                    target = s
                    break
                s = self.objs[s].shadowing
        VpFn(target = target, e = self.any_fn(target, name))

    # Call the first existing name form on the first object that has one.
    fn vp_call_forms(mut self, k: i32, obs: List<val::Value>, pfx: str, vals: List<val::Value>, pl: List<bool>) -> VpCall:
        let r = self.vp_its[k].rule
        let forms = self.vp_apply_forms(r)
        let names = self.vp_apply_names(r, pfx, pl)
        # a verb named "verb" would repeat a name; keep the first
        let mut seen: Set<str> = Set<str>()
        let mut un: List<str> = List<str>()
        let mut uf: List<i32> = List<i32>()
        for i in 0..names.len():
            if !seen.contains(names[i]):
                seen.insert(names[i])
                un.push(names[i])
                uf.push(forms[i])
        for oi in 0..obs.len():
            let ob = self.obj_of(obs[oi])
            if ob < 0:
                continue
            for ni in 0..un.len():
                let f = self.vp_find_fn(ob, un[ni])
                if f.e.prog < 0:
                    continue
                let args = self.vp_build_args(k, uf[ni], vals)
                let res = self.run_entry(f.target, f.e, un[ni], args)
                if self.err:
                    return VpCall(found = true, r = val::Value::Undef)
                return VpCall(found = true, r = res)
        VpCall(found = false, r = val::Value::Int(0 as i64))

    # A check: NO / YES / MSG with its message.
    fn vp_ask(mut self, k: i32, obs: List<val::Value>, pfx: str, vals: List<val::Value>, pl: List<bool>) -> VpAns:
        let fr = self.vp_call_forms(k, obs, pfx, vals, pl)
        if self.err:
            return VpAns(kind = NO, msg = val::Value::Int(0 as i64))
        match fr.r:
            val::Value::Str(s) ->
                if str_starts_with(s, "#"):
                    return VpAns(kind = NO, msg = val::Value::Str(vm::substr(s, 1, len(s))))
                return VpAns(kind = MSG, msg = fr.r)
            val::Value::Undef ->
                return VpAns(kind = NO, msg = val::Value::Int(0 as i64))
            _ -> 0
        if !fr.found or !self.truthy(fr.r):
            return VpAns(kind = NO, msg = val::Value::Int(0 as i64))
        VpAns(kind = YES, msg = val::Value::Int(0 as i64))

    fn vp_ask_obj(mut self, k: i32, pi: i32, pfx: str, c: i32, vals: List<val::Value>, pl: List<bool>) -> VpAns:
        let ob = self.vp_ps[pi].cands[c].ob
        if self.obj_of(ob) < 0:
            return VpAns(kind = NO, msg = val::Value::Int(0 as i64))
        self.vp_ask(k, [ob, self.vp_its[k].rule.handler], pfx, vals, pl)

    fn vp_the_short(mut self, ob: i32) -> str:
        let ol = self.ostack.len()
        let sl = self.stack.len()
        let r = self.apply_value(ob, "the_short", List<val::Value>())
        if self.err:
            self.report_error("parser: the_short()")
            self.truncate_ostack(ol)
            self.truncate_stack(sl)
            return "the thing"
        match r:
            val::Value::Str(s) -> s
            _ -> "the thing"

    # "You can't put the sword in that." for a check of token `checked` (-1:
    # can_) that said no without a message.
    fn vp_default_msg(mut self, k: i32, checked: i32, vals: List<val::Value>) -> str:
        let r = self.vp_its[k].rule
        let mut parts: List<str> = List<str>()
        for ti in 0..r.toks.len():
            let t = r.toks[ti]
            if t.kind == vpd::T_LIT:
                parts.push(t.word)
            elif t.kind == vpd::T_OBJ:
                let o = self.obj_of(vals[ti])
                if ti < checked and o >= 0:
                    let sh = self.vp_the_short(o)
                    parts.push(sh)
                else:
                    parts.push("that")
            else:
                parts.push(self.vp_its[k].text[ti])
        let tail = if parts.len() > 0: concat(" ", str_join(parts, " ")) else: ""
        concat(concat(concat("You can't ", vp::ascii_lower(self.vp_its[k].typed_verb)), tail), ".")

    # --- resolving tokens -----------------------------------------------------------

    fn vp_prefix_of(self, k: i32, ti: i32) -> str:
        if ti == self.vp_its[k].rule.objpos[0]:
            return "direct_"
        "indirect_"

    # The failure of a token none of whose candidates said yes.
    fn vp_refusal(mut self, k: i32, ti: i32, checked: List<vpd::VpStat>, vals: List<val::Value>) -> VpErr:
        let mut first = val::Value::Int(0 as i64)
        let mut last = val::Value::Int(0 as i64)
        let mut any = false
        for i in 0..checked.len():
            if checked[i].kind == NO and self.is_str(checked[i].msg):
                if !any:
                    first = checked[i].msg
                last = checked[i].msg
                any = true
        if any:
            # a plural token: the last in result order
            return mk_err(ERR_ALLOCATED, if self.vp_its[k].many[ti]: last else: first, 0)
        let m = self.vp_default_msg(k, ti, vals)
        mk_err(ERR_ALLOCATED, val::Value::Str(m), 0)

    # Step 2 for one token, in discovery order; stop_at > 0 stops after that
    # many yes / plain-string answers.
    fn vp_check_token(mut self, k: i32, pi: i32, ti: i32, vals: List<val::Value>, pl: List<bool>, stop_at: i32) -> List<vpd::VpStat>:
        let mut out: List<vpd::VpStat> = List<vpd::VpStat>()
        let mut got = 0
        let list = self.vp_its[k].lists[ti]
        let pfx = self.vp_prefix_of(k, ti)
        for i in 0..list.len():
            let c = list[i]
            let mut v = vals
            v[ti] = self.vp_ps[pi].cands[c].ob
            let a = self.vp_ask_obj(k, pi, pfx, c, v, pl)
            if self.err:
                return out
            out.push(vpd::VpStat(c = c, kind = a.kind, msg = a.msg))
            if a.kind != NO:
                got += 1
                if got == stop_at:
                    break
        out

    fn vp_set_plural(mut self, k: i32, pi: i32, ti: i32, stats: List<vpd::VpStat>):
        let mut obs: List<val::Value> = List<val::Value>()
        let mut sob: List<val::Value> = List<val::Value>()
        let mut smsg: List<val::Value> = List<val::Value>()
        for i in 0..stats.len():
            let ob = self.vp_ps[pi].cands[stats[i].c].ob
            if stats[i].kind == YES:
                obs.push(ob)
            elif stats[i].kind == MSG:
                sob.push(ob)
                smsg.push(stats[i].msg)
        self.vp_its[k].pobjs[ti] = obs
        self.vp_its[k].pstr_obs[ti] = sob
        self.vp_its[k].pstr_msgs[ti] = smsg

    fn vp_nonno(self, stats: List<vpd::VpStat>) -> List<vpd::VpStat>:
        let mut out: List<vpd::VpStat> = List<vpd::VpStat>()
        for i in 0..stats.len():
            if stats[i].kind != NO:
                out.push(stats[i])
        out

    fn vp_want(self, k: i32, ti: i32) -> i32:
        let o = self.vp_its[k].ord[ti]
        if o > 1:
            return o
        1

    # Rule with one object token.
    fn vp_resolve_single(mut self, k: i32, pi: i32, vals: List<val::Value>) -> VpErr:
        let ti = self.vp_its[k].rule.objpos[0]
        let pl = falses(vals.len())
        if self.vp_its[k].many[ti]:
            let stats = self.vp_check_token(k, pi, ti, vals, pl, 0)
            if self.err:
                return no_err()
            self.vp_set_plural(k, pi, ti, stats)
            if self.vp_its[k].pobjs[ti].len() == 0 and self.vp_its[k].pstr_obs[ti].len() == 0:
                return self.vp_refusal(k, ti, stats, vals)
            return no_err()
        let want = self.vp_want(k, ti)
        let stats = self.vp_check_token(k, pi, ti, vals, pl, want)
        if self.err:
            return no_err()
        let yes = self.vp_nonno(stats)
        if yes.len() >= want:
            let st = yes[want - 1]
            if st.kind == MSG:
                return mk_err(ERR_ALLOCATED, st.msg, 0)
            self.vp_its[k].val[ti] = self.vp_ps[pi].cands[st.c].ob
            return no_err()
        if yes.len() > 0:
            return mk_err(ERR_ORDINAL, val::Value::Int(yes.len() as i64), 0)
        self.vp_refusal(k, ti, stats, vals)

    # The direct token failed: the interpretation is lost, but it is ranked
    # by its indirect-object problems too, so the indirect checks are still
    # made (with the direct object 0). The direct failure is reported.
    fn vp_direct_failed(mut self, k: i32, pi: i32, e: VpErr, vals: List<val::Value>) -> VpErr:
        let d = self.vp_its[k].rule.objpos[0]
        let i = self.vp_its[k].rule.objpos[1]
        let mut pl = falses(vals.len())
        pl[d] = self.vp_its[k].many[d]
        let mut v = vals
        v[d] = val::Value::Int(0 as i64)
        let istats = self.vp_check_token(k, pi, i, v, pl, 1)
        if self.err:
            return no_err()
        if self.vp_nonno(istats).len() > 0:
            return e
        both(e)

    # resolve_pair()'s pair(D, I): a pair is valid unless a side says no; a
    # plain string from either side (or from its step 2) makes it a valid
    # pair that fails with that message. Memoized; at most PAIR_CAP checks.
    fn vp_pair(mut self, k: i32, pi: i32, dd: vpd::VpStat, ii: vpd::VpStat, vals: List<val::Value>) -> VpAns:
        let key = f"{dd.c}:{ii.c}"
        if let Option::Some(m) = self.vp_its[k].memo.get(key):
            return VpAns(kind = self.vp_its[k].memo_kind[m], msg = self.vp_its[k].memo_msg[m])
        self.vp_its[k].pairs = self.vp_its[k].pairs + 1
        if self.vp_its[k].pairs > PAIR_CAP:
            self.vp_its[k].capped = true
            return VpAns(kind = NO, msg = val::Value::Int(0 as i64))
        let d = self.vp_its[k].rule.objpos[0]
        let i = self.vp_its[k].rule.objpos[1]
        let zero = falses(vals.len())
        let mut v = vals
        v[d] = self.vp_ps[pi].cands[dd.c].ob
        v[i] = self.vp_ps[pi].cands[ii.c].ob
        let a = self.vp_ask_obj(k, pi, "direct_", dd.c, v, zero)
        if self.err:
            return a
        let mut b = a
        if a.kind != NO:
            b = self.vp_ask_obj(k, pi, "indirect_", ii.c, v, zero)
            if self.err:
                return b
        let mut res = VpAns(kind = YES, msg = val::Value::Int(0 as i64))
        if b.kind == NO:
            res = b
        elif a.kind == MSG:
            res = a
        elif b.kind == MSG:
            res = b
        elif dd.kind == MSG:
            res = VpAns(kind = MSG, msg = dd.msg)
        elif ii.kind == MSG:
            res = VpAns(kind = MSG, msg = ii.msg)
        if res.kind == NO and self.is_str(res.msg) and !self.is_str(self.vp_its[k].pair_refusal):
            self.vp_its[k].pair_refusal = res.msg
        let m = self.vp_its[k].memo_kind.len()
        self.vp_its[k].memo_kind.push(res.kind)
        self.vp_its[k].memo_msg.push(res.msg)
        self.vp_its[k].memo.insert(key, m)
        res

    # Has `x` a valid partner among `others`? (x is direct when x_is_d)
    fn vp_partnered(mut self, k: i32, pi: i32, x: vpd::VpStat, others: List<vpd::VpStat>, x_is_d: bool, vals: List<val::Value>) -> bool:
        for j in 0..others.len():
            let r = if x_is_d: self.vp_pair(k, pi, x, others[j], vals) else: self.vp_pair(k, pi, others[j], x, vals)
            if self.err:
                return false
            if r.kind != NO:
                return true
        false

    fn vp_no_pair(mut self, k: i32, vals: List<val::Value>, v2: List<val::Value>) -> VpErr:
        if self.vp_its[k].capped:
            return both(mk_err(ERR_TOO_MANY_PAIRS, val::Value::Int(0 as i64), 0))
        let d = self.vp_its[k].rule.objpos[0]
        let i = self.vp_its[k].rule.objpos[1]
        let mut v = vals
        if !self.vp_its[k].many[d]:
            v[d] = v2[d]
        if self.is_str(self.vp_its[k].pair_refusal):
            return both(mk_err(ERR_ALLOCATED, self.vp_its[k].pair_refusal, 0))
        let m = self.vp_default_msg(k, i, v)
        both(mk_err(ERR_ALLOCATED, val::Value::Str(m), 0))

    # Rule with two object tokens: step 2 for each, then pair checks.
    fn vp_resolve_pair(mut self, k: i32, pi: i32, vals: List<val::Value>) -> VpErr:
        let d = self.vp_its[k].rule.objpos[0]
        let i = self.vp_its[k].rule.objpos[1]
        let zero = falses(vals.len())
        let dstats = self.vp_check_token(k, pi, d, vals, zero, 0)
        if self.err:
            return no_err()
        let dyes = self.vp_nonno(dstats)
        if dyes.len() == 0:
            let e = self.vp_refusal(k, d, dstats, vals)
            return self.vp_direct_failed(k, pi, e, vals)
        if !self.vp_its[k].many[d] and dyes.len() < self.vp_want(k, d):
            return self.vp_direct_failed(k, pi, mk_err(ERR_ORDINAL, val::Value::Int(dyes.len() as i64), 0), vals)
        # the direct object's current value, for the indirect checks
        let mut v2 = vals
        let mut pl2 = zero
        if self.vp_its[k].many[d]:
            let mut obs: List<val::Value> = List<val::Value>()
            let mut q = dyes.len() - 1
            while q >= 0:
                if dyes[q].kind == YES:
                    obs.push(self.vp_ps[pi].cands[dyes[q].c].ob)
                q -= 1
            v2[d] = self.new_arr(obs)
            pl2[d] = true
        else:
            let mut pick = dyes[0]
            for q in 0..dyes.len():
                if dyes[q].kind == YES:
                    pick = dyes[q]
                    break
            v2[d] = self.vp_ps[pi].cands[pick.c].ob
        let istats = self.vp_check_token(k, pi, i, v2, pl2, 0)
        if self.err:
            return no_err()
        let iyes = self.vp_nonno(istats)
        if iyes.len() == 0:
            return self.vp_refusal(k, i, istats, if self.vp_its[k].many[d]: vals else: v2)
        if !self.vp_its[k].many[i] and iyes.len() < self.vp_want(k, i):
            return mk_err(ERR_ORDINAL, val::Value::Int(iyes.len() as i64), 0)
        # pick the singular token first (the direct one when both are
        # singular), then the other token among its valid partners
        let first_d = !self.vp_its[k].many[d]
        let f = if first_d: d else: i
        let o = if first_d: i else: d
        let fyes = if first_d: dyes else: iyes
        let oyes = if first_d: iyes else: dyes
        let want = self.vp_want(k, f)
        let mut got = 0
        for fi in 0..fyes.len():
            let ff = fyes[fi]
            let ok_p = self.vp_partnered(k, pi, ff, oyes, first_d, vals)
            if self.err:
                return no_err()
            if !ok_p:
                if self.vp_its[k].capped:
                    return self.vp_no_pair(k, vals, v2)
                continue
            got += 1
            if got < want:
                continue
            let mut partners: List<vpd::VpStat> = List<vpd::VpStat>()
            for oi in 0..oyes.len():
                let oo = oyes[oi]
                let pr = if first_d: self.vp_pair(k, pi, ff, oo, vals) else: self.vp_pair(k, pi, oo, ff, vals)
                if self.err:
                    return no_err()
                if self.vp_its[k].capped:
                    return self.vp_no_pair(k, vals, v2)
                partners.push(vpd::VpStat(c = oo.c, kind = pr.kind, msg = pr.msg))
            let okp = self.vp_nonno(partners)
            if !self.vp_its[k].many[o]:
                let owant = self.vp_want(k, o)
                if okp.len() < owant:
                    return mk_err(ERR_ORDINAL, val::Value::Int(okp.len() as i64), 0)
                let oo = okp[owant - 1]
                if oo.kind == MSG:
                    return mk_err(ERR_ALLOCATED, oo.msg, 0)
                self.vp_its[k].val[o] = self.vp_ps[pi].cands[oo.c].ob
            else:
                # a plain string on the singular side fails the whole
                # pairing; on the plural side it is just that entry's message
                if ff.kind == MSG:
                    return both(mk_err(ERR_ALLOCATED, ff.msg, 0))
                self.vp_set_plural(k, pi, o, partners)
            self.vp_its[k].val[f] = self.vp_ps[pi].cands[ff.c].ob
            return no_err()
        if got > 0:
            return both(mk_err(ERR_ORDINAL, val::Value::Int(got as i64), 0))
        self.vp_no_pair(k, vals, v2)

    # errs: one entry per failure (both() entries count twice).
    fn vp_failed(mut self, k: i32, errs: List<VpErr>):
        self.vp_its[k].ok = false
        let mut fails = 0
        let mut tin = true
        for i in 0..errs.len():
            fails += errs[i].count
            if errs[i].et != ERR_THERE_IS_NO:
                tin = false
        self.vp_its[k].fails = fails
        self.vp_its[k].tin_only = tin
        self.vp_its[k].has_err = true
        self.vp_its[k].et = errs[0].et
        self.vp_its[k].earg = errs[0].earg
        self.vp_its[k].eflag = errs[0].eflag

    fn vp_evaluate(mut self, pi: i32, k: i32):
        let r = self.vp_its[k].rule
        let n = r.toks.len()
        for ti in 0..n:
            self.vp_its[k].lists.push(List<i32>())
            self.vp_its[k].many.push(false)
            self.vp_its[k].ord.push(0)
            self.vp_its[k].val.push(val::Value::Int(0 as i64))
            self.vp_its[k].pobjs.push(List<val::Value>())
            self.vp_its[k].pstr_obs.push(List<val::Value>())
            self.vp_its[k].pstr_msgs.push(List<val::Value>())
        let mut vals: List<val::Value> = List<val::Value>()
        for ti in 0..n:
            let t = r.toks[ti]
            if t.kind == vpd::T_STR or t.kind == vpd::T_WRD:
                let tv = val::Value::Str(self.vp_its[k].text[ti])
                vals.push(tv)
                self.vp_its[k].val[ti] = tv
            else:
                vals.push(val::Value::Int(0 as i64))
        # noun phrases; any error ends the interpretation before any check
        let mut errs: List<VpErr> = List<VpErr>()
        let h = self.obj_of(r.handler)
        let remote = h >= 0 and self.objs[h].vp_remote
        for q in 0..r.objpos.len():
            let ti = r.objpos[q]
            let sa = self.vp_its[k].spans[ti * 2]
            let sb = self.vp_its[k].spans[ti * 2 + 1]
            let ph = self.vp_phrase(pi, sa, sb)
            if self.err:
                return
            let tc = self.vp_token_cands(pi, ph, r.toks[ti], remote)
            if tc.err.has:
                errs.push(tc.err)
                continue
            self.vp_its[k].lists[ti] = tc.list
            self.vp_its[k].many[ti] = tc.many
            self.vp_its[k].ord[ti] = ph.ord
            if ph.ordat != 0:
                # the ordinal is not part of the typed text ("get 2nd rose" -> "rose")
                let kk = ph.ordat - 1
                let mut parts: List<str> = List<str>()
                if kk > sa:
                    parts.push(self.vp_typed(pi, sa, kk - 1))
                if kk < sb:
                    parts.push(self.vp_typed(pi, kk + 1, sb))
                self.vp_its[k].text[ti] = str_join(parts, " ")
        if errs.len() > 0:
            self.vp_failed(k, errs)
            return
        let can = self.vp_ask(k, [r.handler], "can_", vals, falses(n))
        if self.err:
            return
        let mut e = no_err()
        if can.kind != YES:
            if self.is_str(can.msg):
                e = mk_err(ERR_ALLOCATED, can.msg, 0)
            else:
                let m = self.vp_default_msg(k, -1, vals)
                e = mk_err(ERR_ALLOCATED, val::Value::Str(m), 0)
        elif r.objpos.len() == 1:
            e = self.vp_resolve_single(k, pi, vals)
        elif r.objpos.len() == 2:
            e = self.vp_resolve_pair(k, pi, vals)
        if self.err:
            return
        if e.has:
            self.vp_failed(k, [e])
        else:
            self.vp_its[k].ok = true

    # --- the whole parse -----------------------------------------------------------

    # first word -> verbs starting with it, sorted by name (determinism)
    fn vp_build_index(mut self):
        if self.vp_vidx_ok:
            return
        let mut order: List<i32> = List<i32>()
        for i in 0..self.vp_verbs.len():
            order.push(i)
        let mut a = 1
        while a < order.len():
            let x = order[a]
            let mut b = a - 1
            while b >= 0 and vm::str_cmp(self.vp_verbs[x].name, self.vp_verbs[order[b]].name) < 0:
                order[b + 1] = order[b]
                b -= 1
            order[b + 1] = x
            a += 1
        let mut idx: Map<str, List<i32>> = Map<str, List<i32>>()
        for i in 0..order.len():
            let w = split_text(self.vp_verbs[order[i]].name).words
            if w.len() == 0:
                continue
            let mut l: List<i32> = List<i32>()
            if let Option::Some(x) = idx.get(w[0]):
                l = x
            l.push(order[i])
            idx.insert(w[0], l)
        self.vp_vidx = idx
        self.vp_vidx_ok = true

    # The whole parse (parser.pike run()). only >= 0: consider only that
    # handler's rules. call_do: call do_ (else return the form D arguments).
    fn vp_run(mut self, subject: i32, s: str, env: val::Value, nicks: val::Value, only: i32, call_do: bool) -> val::Value:
        let st = split_text(s)
        if st.words.len() == 0:
            return val::Value::Int(0 as i64)
        self.vp_ps.push(vpd::VpParse(subject = subject, input = s, words = st.words, starts = st.starts, ends = st.ends, env = env, nicks = nicks))
        let pi = self.vp_ps.len() - 1
        let words = st.words
        self.vp_build_index()
        # verbs that are a prefix of the input, and their interpretations
        let mut interps: List<vpd::VpInterp> = List<vpd::VpInterp>()
        let mut verb_found = false
        let mut cand_verbs: List<i32> = List<i32>()
        if let Option::Some(x) = self.vp_vidx.get(words[0]):
            cand_verbs = x
        for cv in 0..cand_verbs.len():
            let vname = self.vp_verbs[cand_verbs[cv]].name
            let vw = split_text(vname).words
            let vlen = vw.len()
            if vlen > words.len() or !words_eq(words, 0, vw):
                continue
            let all = self.vp_rules_of(vname, 0)
            let mut rules: List<vpd::VpRule> = List<vpd::VpRule>()
            for i in 0..all.len():
                let h = self.obj_of(all[i].handler)
                if h < 0 or (only >= 0 and h != only):
                    continue
                rules.push(all[i])
            if rules.len() == 0:
                continue
            verb_found = true
            let tv = self.vp_typed(pi, 0, vlen - 1)
            for ri in 0..rules.len():
                let r = rules[ri]
                if !may_match(words, r, vlen):
                    continue
                let mut spans: List<i32> = List<i32>()
                for q in 0..r.toks.len():
                    spans.push(0)
                    spans.push(0)
                let sp = splits(words, r, 0, vlen, spans, SPLIT_CAP)
                for q in 0..sp.len():
                    let mut text: List<str> = List<str>()
                    for t in 0..r.toks.len():
                        text.push(self.vp_typed(pi, sp[q][t * 2], sp[q][t * 2 + 1]))
                    interps.push(vpd::VpInterp(rule = r, vlen = vlen, spans = sp[q], text = text, typed_verb = tv, order = interps.len()))
        if !verb_found:
            return val::Value::Int(0 as i64)
        if interps.len() == 0:
            return val::Value::Int((0 - 1) as i64)
        # best first
        let mut a = 1
        while a < interps.len():
            let x = interps[a]
            let mut b = a - 1
            while b >= 0 and worse(interps[b], x):
                interps[b + 1] = interps[b]
                b -= 1
            interps[b + 1] = x
            a += 1
        for q in 0..interps.len():
            self.vp_its.push(interps[q])
            let k = self.vp_its.len() - 1
            self.vp_evaluate(pi, k)
            interps[q] = self.vp_its[k]
            if self.err:
                return val::Value::Undef
            if interps[q].ok:
                return self.vp_finish(pi, k, call_do)
            self.vp_its.pop()
        let mut best = interps[0]
        for q in 1..interps.len():
            if worse_failure(best, interps[q]):
                best = interps[q]
        if !best.has_err:
            return val::Value::Int((0 - 2) as i64)
        let msg = self.master_apply("parser_error_message", [val::Value::Int(best.et as i64), val::Value::Int(0 as i64), best.earg, val::Value::Int(best.eflag as i64)], -1)
        if self.err:
            return val::Value::Undef
        match msg:
            val::Value::Str(m) -> msg
            _ -> val::Value::Int((0 - 2) as i64)

    # Success: final values, then do_ (or the argument array).
    fn vp_finish(mut self, pi: i32, k: i32, call_do: bool) -> val::Value:
        let r = self.vp_its[k].rule
        let n = r.toks.len()
        let mut vals = self.vp_its[k].val
        let mut pl = falses(n)
        for q in 0..r.objpos.len():
            let ti = r.objpos[q]
            if self.vp_its[k].many[ti]:
                pl[ti] = true
                let mut items: List<val::Value> = List<val::Value>()
                let sob = self.vp_its[k].pstr_obs[ti]
                let smsg = self.vp_its[k].pstr_msgs[ti]
                let mut j = sob.len() - 1
                while j >= 0:
                    let o = if self.obj_of(sob[j]) >= 0: sob[j] else: val::Value::Int(0 as i64)
                    let m = self.master_apply("parser_error_message", [val::Value::Int(ERR_ALLOCATED as i64), o, smsg[j], val::Value::Int(0 as i64)], -1)
                    if self.err:
                        return val::Value::Undef
                    items.push(m)
                    j -= 1
                let pobs = self.vp_its[k].pobjs[ti]
                let mut q2 = pobs.len() - 1
                while q2 >= 0:
                    items.push(if self.obj_of(pobs[q2]) >= 0: pobs[q2] else: val::Value::Int(0 as i64))
                    q2 -= 1
                vals[ti] = self.new_arr(items)
            elif self.obj_of(vals[ti]) < 0:
                vals[ti] = val::Value::Int(0 as i64)
        if !call_do:
            let args = self.vp_build_args(k, 68, vals)
            return self.new_arr(args)
        let fr = self.vp_call_forms(k, [r.handler], "do_", vals, pl)
        if self.err:
            return val::Value::Undef
        if !fr.found:
            let h = self.obj_of(r.handler)
            let hn = if h >= 0: self.objs[h].name else: "?"
            self.fail(f"Parse accepted, but no do_* function found in object {hn}!\n")
            return val::Value::Undef
        val::Value::Int(1 as i64)

    # parse_sentence()/parse_my_rules(): the subject must be known; the
    # stacks are back where they were however the parse ends.
    fn vp_parse(mut self, subject: i32, s: str, env: val::Value, nicks: val::Value, only: i32, call_do: bool) -> val::Value:
        if !self.vp_is_known(subject):
            let n = if self.alive(subject): self.objs[subject].name else: "object"
            self.fail(f"{n} is not known by the parser.  Call parse_init() first.\n")
            return val::Value::Undef
        let np = self.vp_ps.len()
        let ni = self.vp_its.len()
        let r = self.vp_run(subject, s, env, nicks, only, call_do)
        while self.vp_ps.len() > np:
            self.vp_ps.pop()
        while self.vp_its.len() > ni:
            self.vp_its.pop()
        r

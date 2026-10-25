# The verb parser's registry data -- todo.md HavokOS M6, `havok/parser.pike`'s
# Tok/Rule/Verb classes. In a file of its own so `vm.star` can hold the
# registry without importing the parser (`verbparse.star`).
#
# The reference's per-object tables (`known`, `remote_ok`, `handlers`) are
# flags on each object's `vm.star` ObjSlot here instead, so a destruct
# (forget_object()) or a reused slot can't leave stale entries behind.

import "value.star" as val

# token kinds
const T_LIT: i32 = 0
const T_OBJ: i32 = 1
const T_STR: i32 = 2
const T_WRD: i32 = 3

struct VpTok:
    kind: i32
    # a literal as written in the rule, and in lower case (matched against
    # the input)
    word: str = ""
    lword: str = ""
    living: bool = false
    plural: bool = false
    visible: bool = false

struct VpRule:
    # the verb used in apply names (the original verb for a synonym)
    mut verb: str = ""
    # the object that registered it (generation-checked)
    mut handler: val::Value = val::Value::Int(0 as i64)
    toks: List<VpTok>
    # canonical rule text, and the tokens with every flag (for comparing)
    text: str
    sig: str
    # registration order (larger = newer)
    mut seq: i32 = 0
    # specificity, literal count, the token indices of the object tokens,
    # and whether it has a STR or object token
    score: i32
    nlits: i32
    objpos: List<i32>
    variable: bool

struct VpVerb:
    name: str
    mut rules: List<VpRule> = List<VpRule>()
    # a plain synonym: that verb's rules count too ("" for none)
    mut synonym_for: str = ""

# --- the matching engine (parse_sentence()) ---

# Cached information about one object (parser.pike Info): its id lists as
# word lists, grouped by last word for matching a phrase from its end, and
# the flags. `raw_*` remember the strings the lists were built from, so an
# unchanged answer after parse_refresh() isn't processed again.
struct VpInfo:
    mut adjs: List<List<str>> = List<List<str>>()
    mut adj_words: Set<str> = Set<str>()
    mut nouns: List<List<str>> = List<List<str>>()
    mut noun_last: Map<str, List<i32>> = Map<str, List<i32>>()
    mut plurals: List<List<str>> = List<List<str>>()
    mut plural_last: Map<str, List<i32>> = Map<str, List<i32>>()
    mut raw_nouns: str = "-"
    mut raw_plurals: str = "-"
    mut raw_adjs: str = "-"
    mut living: bool = false
    mut access: bool = false
    mut visible: bool = false

# A candidate object of one parse (Cand): its info, discovery order, and
# whether it can be reached, is carried by the subject, or is a remote user.
struct VpCand:
    ob: val::Value
    oh: i32
    info: i32
    idx: i32
    reach: bool
    carried: bool
    mut remote: bool = false

# phrase kinds
const PH_ERR: i32 = 0
const PH_ONE: i32 = 1
const PH_MANY: i32 = 2

# A noun phrase read over some words (Phrase): the candidates it names, or
# an error.
struct VpPhrase:
    kind: i32
    mut ord: i32 = 0
    mut ordat: i32 = 0
    mut idx: List<i32> = List<i32>()
    mut has_idx: bool = false
    mut noun: str = ""
    mut has_noun: bool = false
    mut ncount: i32 = 0
    mut et: i32 = 0
    mut earg: val::Value = val::Value::Int(0 as i64)
    mut eflag: i32 = 0

# One parse (Parse); kept on Vm.vp_ps, since applies it makes can parse
# again.
struct VpParse:
    subject: i32
    input: str
    words: List<str>
    starts: List<i32>
    ends: List<i32>
    env: val::Value
    nicks: val::Value
    mut have_cands: bool = false
    mut cands: List<VpCand> = List<VpCand>()
    mut seen: Set<i32> = Set<i32>()
    mut nick_cand: List<i32> = List<i32>()
    mut nick_words: List<List<str>> = List<List<str>>()
    mut nick_last: Map<str, List<i32>> = Map<str, List<i32>>()
    mut ph_index: Map<i32, i32> = Map<i32, i32>()
    mut phrases: List<VpPhrase> = List<VpPhrase>()

# One way a rule can cover the input (Interp), and what evaluating it
# found. Evaluated on Vm.vp_its for the same reason as VpParse.
struct VpInterp:
    rule: VpRule
    vlen: i32
    # per token, the first and last word it covers: [a0, b0, a1, b1, ...]
    spans: List<i32>
    mut text: List<str>
    typed_verb: str
    order: i32
    mut ok: bool = false
    mut fails: i32 = 0
    mut tin_only: bool = false
    mut has_err: bool = false
    mut et: i32 = 0
    mut earg: val::Value = val::Value::Int(0 as i64)
    mut eflag: i32 = 0
    # per token: candidate indices, plural, ordinal, resolved value, and for
    # a plural token the objects that said yes and the (object, message)
    # pairs that answered a plain string, in discovery order
    mut lists: List<List<i32>> = List<List<i32>>()
    mut many: List<bool> = List<bool>()
    mut ord: List<i32> = List<i32>()
    mut val: List<val::Value> = List<val::Value>()
    mut pobjs: List<List<val::Value>> = List<List<val::Value>>()
    mut pstr_obs: List<List<val::Value>> = List<List<val::Value>>()
    mut pstr_msgs: List<List<val::Value>> = List<List<val::Value>>()
    # pair checks made, their memo ("d:i" -> kind, message), the first
    # refusal message, and whether PAIR_CAP was hit
    mut pairs: i32 = 0
    mut memo: Map<str, i32> = Map<str, i32>()
    mut memo_kind: List<i32> = List<i32>()
    mut memo_msg: List<val::Value> = List<val::Value>()
    mut pair_refusal: val::Value = val::Value::Int(0 as i64)
    mut capped: bool = false

# One candidate's answer in a check (check_token()'s ({ cand, kind, msg })).
struct VpStat:
    c: i32
    kind: i32
    msg: val::Value

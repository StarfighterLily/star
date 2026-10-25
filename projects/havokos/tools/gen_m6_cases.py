"""Generates tests/fixtures/cases/m6_cases.txt (todo.md HavokOS M6).

The M6 cases drive the telnet layer, connections and the verb parser's
registry through the test_tel_* hooks both case runners provide
(efuns_net.star's header; tools/ref_cases.pike). They are written here as
readable LPC and flattened to the case file's one-line, escaped form; the
expected results (m6_extra.expected.txt) are whatever the live reference
returns for them (tools/ref_cases.pike -extra), never hand-predicted.

Bytes cross the hooks as `~xx`: e.g. IAC WILL TTYPE is "~ff~fb~18".

Usage: python tools/gen_m6_cases.py > tests/fixtures/cases/m6_cases.txt
"""

def lpc_str(src):
    """An LPC string literal holding src."""
    return '"' + src.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n') + '"'

HELPERS = {
    # a session object, as the master's connect() hands out: logon(),
    # input_to (one noecho, with an extra argument), net_dead()
    "/test/tmp_m6_sess.c": """
string *log = ({});
void L(string s) { log += ({ s }); }
string *take() { string *l = log; log = ({}); return l; }
void logon() {
    L("logon tp=" + (this_player() == this_object()) + " ti=" + (this_interactive() == this_object()));
    write("Welcome!\\nName: ");
    input_to("got_name");
}
void got_name(string s) {
    L("name:" + s + " tp=" + (this_player() == this_object()));
    write("Hi " + s + "\\n");
    input_to("got_pass", 1, "extra");
}
void got_pass(string s, string x) { L("pass:" + s + ":" + x); }
void net_dead() { L("net_dead ip=" + query_ip_number(this_object()) + " int=" + interactive()); }
mixed process_input(string s) { L("input:" + s); return 0; }
void receive_message(string c, string m) { L("msg:" + c + ":" + m); }
void move_to(mixed d) { move_object(d); }
""",
    # a living with commands, a write_prompt(), and the snoop/message applies
    "/test/tmp_m6_cmd.c": """
string *log = ({});
string prompt_text;
void L(string s) { log += ({ s }); }
string *take() { string *l = log; log = ({}); return l; }
void create() {
    enable_commands();
    add_action("do_x", "x");
    add_action("do_nf", "nf");
    add_action("do_fnf", "fnf");
}
int do_x(string a) {
    L("x:" + (a ? a : "-") + ":tp=" + (this_player() == this_object()) + ":ti=" + (this_interactive() == this_object()));
    write("did x\\n");
    return 1;
}
int do_nf(string a) { notify_fail("no nf\\n"); return 0; }
int do_fnf(string a) { notify_fail((: "fn fail\\n" :)); return 0; }
mixed process_input(string s) {
    if (s == "alias") return "x aliased";
    if (s == "eat") { L("ate"); return 1; }
    return 0;
}
mixed write_prompt() { if (prompt_text) write(prompt_text); return 0; }
void set_prompt(string s) { prompt_text = s; }
void receive_message(string c, string m) { L("msg:" + c + ":" + m); }
void receive_snoop(string s) { L("snoop:" + s); }
void net_dead() { L("net_dead"); }
int got_char(string s) { L("char:" + s); return 1; }
void move_to(mixed d) { move_object(d); }
""",
    # verb handlers for the parser registry
    "/test/tmp_m6_verb.c": """
void create() { parse_init(); }
mixed add(mixed v, mixed r) { return catch(parse_add_rule(v, r)); }
mixed syn2(mixed a, mixed b) { return catch(parse_add_synonym(a, b)); }
mixed syn3(mixed a, mixed b, mixed r) { return catch(parse_add_synonym(a, b, r)); }
void rm(string v) { parse_remove(v); }
string dump() { return parse_dump(); }
int remote_asks;
int livings_are_remote() { remote_asks++; return 1; }
int asks() { return remote_asks; }
void refresh() { parse_refresh(); }
""",
    "/test/tmp_m6_verb2.c": """
void create() { parse_init(); }
mixed add(mixed v, mixed r) { return catch(parse_add_rule(v, r)); }
mixed syn3(mixed a, mixed b, mixed r) { return catch(parse_add_synonym(a, b, r)); }
""",
    "/test/tmp_m6_noinit.c": """
mixed add(mixed v, mixed r) { return catch(parse_add_rule(v, r)); }
void refresh() { parse_refresh(); }
""",
}

CASES = []

def case(name, body, globals_=""):
    CASES.append((name, (globals_ + " @@ " if globals_ else "") + body))

case("m6 setup helpers",
     " ".join("write_file(%s, %s, 1);" % (lpc_str(p), lpc_str(src.strip() + "\n")) for p, src in HELPERS.items())
     + " return 1;")

# --- ports of run_tests.pike telnet_tests(), split so each is one case
OPEN = 'object u = clone_object("/test/tel_user"); int c = test_tel_open(u); string offers = test_tel_drain(c);'
CLOSE = 'test_tel_hangup(c); destruct(u);'

case("telnet offers on connect", OPEN + " " + CLOSE + " return offers;")

case("telnet TTYPE, MTTS cycle, NAWS", OPEN + """
mixed r = ({ test_tel_say(c, "~ff~fb~18") });
r += ({ test_tel_say(c, "~ff~fa~18~00MUDLET~ff~f0"), test_tel_say(c, "~ff~fa~18~00ANSI-TRUECOLOR~ff~f0"),
        test_tel_say(c, "~ff~fa~18~00MTTS 2349~ff~f0"), test_tel_say(c, "~ff~fa~18~00MTTS 2349~ff~f0") });
test_tel_say(c, "~ff~fa~1f~00d~00(~ff~f0~ff~fa~1f~00~ff~ff~01,~ff~f0");
r += ({ u->query_log() });
mapping ci = client_info(u);
r += ({ ci["terminal"], ci["terminals"], ci["mtts"], ci["window"] });
""" + CLOSE + " return r;")

# UPTIME is each driver's own boot time: checked against time() - uptime()
case("telnet MSSP from get_mud_stats", OPEN + """
string s = test_tel_say(c, "~ff~fd~46");
string a, b; int n;
int ok = sscanf(s, "%sUPTIME~02%d%s", a, n, b) == 3;
""" + CLOSE + " return ({ ok ? a + \"UPTIME~02N\" + b : s, ok && abs(n - (time() - uptime())) <= 2 });")

case("telnet GA after each line, EOR, refused options, other suboptions", OPEN + """
mixed r = ({ test_tel_say(c, "hello~0d~0a") });
r += ({ test_tel_say(c, "~ff~fd~19"), test_tel_say(c, "x~0d~0a") });
r += ({ test_tel_say(c, "~ff~fd~03~ff~fb~63~ff~fd~63") });
u->query_log();
test_tel_say(c, "~ff~fa~63xy~ff~f0");
r += ({ u->query_log() });
""" + CLOSE + " return r;")

case("telnet GMCP, ZMP, MXP", OPEN + """
test_tel_say(c, "~ff~fd~c9~ff~fa~c9Core.Hello {\\"client\\":\\"t\\"}~ff~f0");
mixed r = ({ u->query_log(), has_gmcp(u) });
test_tel_tp(u); send_gmcp("Char.Vitals {\\"hp\\":1}"); test_tel_tp(0);
r += ({ test_tel_drain(c) });
test_tel_say(c, "~ff~fe~c9");
r += ({ has_gmcp(u) });
test_tel_say(c, "~ff~fd~5d~ff~fa~5dzmp.ident~00probe~00v1~00~ff~f0");
r += ({ u->query_log(), has_zmp(u) });
test_tel_tp(u); send_zmp("zmp.ping", ({ "a", "b" })); test_tel_tp(0);
r += ({ test_tel_drain(c) });
r += ({ test_tel_say(c, "~ff~fb~5b"), u->query_log(), has_mxp(u) });
test_tel_tp(u); act_mxp(); test_tel_tp(0);
r += ({ test_tel_drain(c) });
""" + CLOSE + " return r;")

case("telnet NEW-ENVIRON", OPEN + """
mixed r = ({ test_tel_say(c, "~ff~fb~27"), test_tel_say(c, "~ff~fa~27~00~00USER~01bob~ff~f0"), u->query_log() });
test_tel_say(c, "~ff~fa~27~02~03CLIENT_NAME~01MUDLET~03OSC_HYPERLINKS_SEND~011~03A~02~01B~01v~00USER~ff~f0");
r += ({ client_info(u)["environ"] });
""" + CLOSE + " return r;")

case("telnet MSDP", OPEN + """
mixed r = ({ test_tel_say(c, "~ff~fd~45"), u->query_log(), has_msdp(u) });
test_tel_say(c, "~ff~fa~45~01REPORT~02HEALTH~02MANA~01LIST~02COMMANDS~01SEND~02~05~02A~02B~06~01T~02~03~01k~02v~01n~02~05~02x~06~04~ff~f0");
r += ({ u->query_log() });
test_tel_tp(u); send_msdp(([ "HEALTH": 10, "ROOM": ([ "VNUM": 5, "EXITS": ([ "n": 6 ]) ]), "L": ({ 1, "a\\x01b" }) ])); test_tel_tp(0);
r += ({ test_tel_drain(c) });
""" + CLOSE + " return r;")

case("telnet MSP and client_info flags", OPEN + """
test_tel_say(c, "~ff~fd~5a");
test_tel_tp(u); send_msp("!!SOUND(rain.wav L=-1)"); test_tel_tp(0);
mixed r = ({ has_msp(u), test_tel_drain(c) });
test_tel_say(c, "~ff~fd~19~ff~fd~5d~ff~fb~5b~ff~fd~45");
mapping ci = client_info(u);
r += ({ ci["gmcp"], ci["msdp"], ci["msp"], ci["mxp"], ci["zmp"], ci["utf8"], ci["tls"], ci["websocket"], ci["eor"], ci["mccp"] });
object other = clone_object("/test/tel_user");
r += ({ client_info(other), has_gmcp(other), has_msp() });
destruct(other);
""" + CLOSE + " return r;")

case("telnet line endings, IAC IAC, NUL dropped, CR at a packet end", OPEN + """
test_tel_say(c, "a~ff~ffb~0d~0alf only~0acr only~0d");
test_tel_say(c, "crnul~0d~00next~0d~0a");
test_tel_say(c, "one~0d");
test_tel_say(c, "~0atwo~0d~0athr~00ee~0d~0a");
mixed r = map(u->query_log(), (: $1[1] :));
""" + CLOSE + " return r;")

case("telnet output: 0xff doubled, newlines", OPEN + """
tell_object(u, sprintf("%c\\n", 255));
string a = test_tel_drain(c);
tell_object(u, "a\\r\\nb\\nc\\rd");
string b = test_tel_drain(c);
""" + CLOSE + " return ({ a, b });")

case("telnet split commands and subnegotiations across reads, ignored commands", OPEN + """
mixed r = ({ test_tel_say(c, "~ff"), test_tel_say(c, "~fb"), test_tel_say(c, "~18") });
test_tel_say(c, "~ff~fa~18~00XY");
test_tel_say(c, "Z~ff");
r += ({ test_tel_say(c, "~f0"), u->query_log() });
r += ({ test_tel_say(c, "~ff~f1~ff~f9~ff~f6ab~0d~0a"), u->query_log() });
""" + CLOSE + " return r;")

case("telnet noecho input_to", OPEN + """
test_tel_tp(u);
int ok = input_to((: 0 :), 1);
int again = input_to((: 0 :));
test_tel_tp(0);
string on = test_tel_drain(c);
mixed r = ({ ok, again, on, in_input(u), test_tel_say(c, "pw~0d~0a"), in_input(u) });
""" + CLOSE + " return r;")

case("telnet CHARSET", OPEN + """
mixed r = ({ test_tel_say(c, "~ff~fd~2a") });
test_tel_say(c, "~ff~fa~2a~02UTF-8~ff~f0");
r += ({ client_info(u)["utf8"] });
r += ({ test_tel_say(c, "~ff~fa~2a~01;ISO-8859-1;utf8~ff~f0"), test_tel_say(c, "~ff~fa~2a~01 latin1 ascii~ff~f0") });
r += ({ test_tel_say(c, "~ff~fa~2a~01[TTABLE]~01;UTF-8~ff~f0") });
""" + CLOSE + " return r;")

case("telnet TTYPE cycle ends on a repeat, COMPRESS2 refused", OPEN + """
test_tel_say(c, "~ff~fb~18");
string again = test_tel_say(c, "~ff~fa~18~00XTERM~ff~f0");
mixed r = ({ again, test_tel_say(c, "~ff~fa~18~00XTERM~ff~f0"), client_info(u)["terminals"], undefinedp(client_info(u)["mtts"]) });
r += ({ test_tel_say(c, "~ff~fd~56"), client_info(u)["mccp"] });
r += ({ test_tel_say(c, "~ff~fd~01"), test_tel_say(c, "~ff~fe~01"), test_tel_say(c, "~ff~fb~01") });
""" + CLOSE + " return r;")

# --- sessions, input_to, commands, exec, snoop
case("session: connect, logon, input_to chain, commands, net_dead", """
master()->set_connect("/test/tmp_m6_sess");
int c = test_tel_connect();
string first = test_tel_drain(c);
object u = test_tel_user(c);
mixed r = ({ first, interactive(u), userp(u), query_ip_number(u), query_ip_name(u), member_array(u, users()) >= 0, in_input(u) });
r += ({ test_tel_say(c, "bob~0d~0a"), in_input(u) });
r += ({ test_tel_say(c, "secret~0d~0a"), in_input(u) });
r += ({ test_tel_say(c, "look~0d~0a") });
r += ({ query_idle(u) <= 1, query_charmode(u) });
r += ({ u->take() });
test_tel_hangup(c);
r += ({ u->take(), interactive(u), userp(u), member_array(u, users()), test_tel_user(c), query_ip_number(u) });
r += ({ catch(query_idle(u)) });
master()->set_connect(0);
destruct(u);
return r;""")

case("session: connect refused", """
master()->set_connect(0);
int c = test_tel_connect();
return ({ test_tel_drain(c), test_tel_user(c) });""")

case("commands: process_input, notify_fail, write_prompt, blank lines", """
object a = clone_object("/test/tmp_m6_cmd");
int c = test_tel_open(a);
test_tel_drain(c);
mixed r = ({ test_tel_say(c, "x foo~0d~0a"), test_tel_say(c, "alias~0d~0a"), test_tel_say(c, "eat~0d~0a") });
r += ({ test_tel_say(c, "nf~0d~0a"), test_tel_say(c, "fnf~0d~0a"), test_tel_say(c, "zzz~0d~0a"), test_tel_say(c, "   ~0d~0a") });
a->set_prompt("PROMPT> ");
r += ({ test_tel_say(c, "x~0d~0a"), a->take() });
test_tel_hangup(c);
r += ({ a->take() });
destruct(a);
return r;""")

case("exec: moves the connection, refuses one already interactive", """
object a = clone_object("/test/tmp_m6_cmd"), b = clone_object("/test/tmp_m6_cmd");
int c = test_tel_open(a);
test_tel_drain(c);
mixed r = ({ interactive(a), interactive(b), userp(a), userp(b) });
r += ({ exec(b, a) == b, interactive(a), interactive(b), test_tel_user(c) == b, userp(a), userp(b) });
r += ({ test_tel_say(c, "x moved~0d~0a"), b->take(), a->take() });
int c2 = test_tel_open(a);
test_tel_drain(c2);
r += ({ exec(a, b), exec(b, b) == b, exec(b, 0), exec(0, b) });
object d = clone_object("/test/tmp_m6_cmd");
r += ({ exec(d, b) == d, interactive(b), interactive(d), sizeof(users() & ({ a, b, d })) });
test_tel_hangup(c); test_tel_hangup(c2);
destruct(a); destruct(b); destruct(d);
return r;""")

case("snoop: output and typed input to receive_snoop, loops, stopping", """
object a = clone_object("/test/tmp_m6_cmd"), b = clone_object("/test/tmp_m6_cmd"), n = clone_object("/test/tmp_m6_cmd");
int ca = test_tel_open(a), cb = test_tel_open(b);
test_tel_drain(ca); test_tel_drain(cb);
mixed r = ({ snoop(a, b) == b, query_snoop(b) == a, query_snooping(a) == b, query_snoop(a), query_snooping(b) });
tell_object(b, "hello\\n");
r += ({ test_tel_drain(cb), a->take() });
r += ({ test_tel_say(cb, "x hi~0d~0a"), a->take() });
r += ({ snoop(b, a), catch(snoop(a, n)), catch(snoop(0, b)) });
r += ({ snoop(a) == a, query_snoop(b) });
tell_object(b, "quiet\\n");
r += ({ a->take() });
test_tel_hangup(ca); test_tel_hangup(cb);
destruct(a); destruct(b); destruct(n);
return r;""")

case("get_char, charmode, remove_get_char, remove_charmode", """
object a = clone_object("/test/tmp_m6_cmd");
int c = test_tel_open(a);
test_tel_drain(c);
test_tel_tp(a);
mixed r = ({ get_char("nonexistent_fn"), query_charmode(a), in_input(a) });
remove_get_char(a);
r += ({ in_input(a), query_charmode(a) });
remove_charmode(a);
r += ({ query_charmode(a) });
test_tel_tp(a);
a->set_prompt("");
r += ({ catch(input_to("nonexistent_fn")), in_input(a) });
test_tel_tp(0);
r += ({ input_to((: 0 :)), query_charmode(0) });
test_tel_hangup(c);
destruct(a);
return r;""")

case("get_char delivers one character, then lines again", """
object a = clone_object("/test/tmp_m6_cmd");
int c = test_tel_open(a);
test_tel_drain(c);
test_tel_tp(a);
int ok = get_char((: $(a)->got_char($1) :));
test_tel_tp(0);
mixed r = ({ ok, query_charmode(a), test_tel_say(c, "qx"), query_charmode(a), a->take() });
r += ({ test_tel_say(c, " later~0d~0a"), a->take() });
test_tel_hangup(c);
destruct(a);
return r;""")

case("remove_interactive, destruct of an interactive object", """
object a = clone_object("/test/tmp_m6_cmd"), b = clone_object("/test/tmp_m6_cmd");
int ca = test_tel_open(a), cb = test_tel_open(b);
test_tel_drain(ca); test_tel_drain(cb);
remove_interactive(a);
mixed r = ({ interactive(a), a->take(), test_tel_user(ca) });
destruct(b);
r += ({ test_tel_user(cb), sizeof(users() & ({ a, b })) });
destruct(a);
return r;""")

case("messages: say, shout, message to an interactive non-living", """
object s = clone_object("/test/tmp_m6_sess"), a = clone_object("/test/tmp_m6_cmd");
int cs = test_tel_open(s), ca = test_tel_open(a);
test_tel_drain(cs); test_tel_drain(ca);
object room = clone_object("/test/gthing");
s->move_to(room); a->move_to(room);
s->take(); a->take();
shout("hey all\\n");
mixed r = ({ test_tel_drain(cs), test_tel_drain(ca) });
message("info", "msg!", ({ s, a }));
r += ({ s->take(), a->take() });
tell_room(room, "in room\\n");
r += ({ test_tel_drain(cs), test_tel_drain(ca) });
test_tel_hangup(cs); test_tel_hangup(ca);
s->take(); a->take();
destruct(s); destruct(a); destruct(room);
return r;""")

case("query_host_name, network_stats shape", """
mapping m = network_stats();
return ({ query_host_name(), mapp(m), intp(m["incoming packets total"]), intp(m["outgoing volume total"]) });""")

# --- the verb parser's registry
case("parse registry: rules and dump", """
object v = load_object("/test/tmp_m6_verb");
mixed r = ({ v->add("get", "OBJ"), v->add("get", "OBJ from OBJ"), v->add("put", "OBS in OBJ"), v->add("look", "") });
r += ({ v->add("look", "at OBJ:v"), v->add("get up", ""), v->add("say", "STR"), v->add("tell", "LIV WRD") });
r += ({ v->add("show", "OBJ:l to LIV:p"), v->add("hit", "OBJ:c with  OBJ:lv"), v->add("throw", "LVS at OBJ") });
r += ({ v->dump(), v->asks() });
v->rm("get"); v->rm("look"); v->rm("get up"); v->rm("say"); v->rm("tell"); v->rm("put"); v->rm("show"); v->rm("hit"); v->rm("throw");
r += ({ v->dump() });
return r;""")

case("parse registry: rule errors", """
object v = load_object("/test/tmp_m6_verb"), n = load_object("/test/tmp_m6_noinit");
mixed r = ({ v->add("x", "OBJ into OBJ"), v->add("x", "STR:v"), v->add("x", "WRD:"), v->add("x", "OBJ:q") });
r += ({ v->add("x", "OBJ OBJ OBJ"), v->add("x", "OBS in LVS"), v->add("x", "in in in in in in in in in in in") });
r += ({ v->add(5, "OBJ"), v->add("x", "OBJ:l:v"), n->add("x", "OBJ"), v->add("x", ":v") });
r += ({ v->dump() });
n->refresh();
return r;""")

case("parse registry: synonyms, re-adding, forgetting a destructed handler", """
object v = load_object("/test/tmp_m6_verb"), w = load_object("/test/tmp_m6_verb2");
v->add("get", "OBJ"); v->add("get", "OBJ from OBJ"); w->add("get", "OBS");
mixed r = ({ v->syn2("take", "get"), v->syn3("grab", "get", "OBJ   from OBJ"), v->syn3("grab", "get", "OBS") });
r += ({ w->syn3("snatch", "get", "OBS"), v->syn2("get", "get"), v->syn2("x", "nope"), v->syn3("y", "nope", "OBJ") });
r += ({ v->syn2(0, "get") });
v->add("get", "OBJ");
r += ({ v->dump() });
destruct(w);
r += ({ v->dump() });
v->rm("get"); v->rm("grab");
r += ({ v->dump() });
destruct(v);
return r;""")

# the clones are made in mk() so that no local holds them
case("parse registry: refresh asks livings_are_remote again, parse_init clones and get_garbage", """
object v = load_object("/test/tmp_m6_verb");
v->add("poke", "OBJ");
int a0 = v->asks();
v->refresh();
int a1 = v->asks();
int v0 = count("/test/tmp_m6_verb"), g0 = count("/test/gthing");
mk();
mixed r = ({ a0, a1, count("/test/tmp_m6_verb") - v0, count("/test/gthing") - g0 });
foreach (object o in get_garbage()) if (base_name(o) == "/test/tmp_m6_verb" || base_name(o) == "/test/gthing") destruct(o);
v->rm("poke");
destruct(v);
return r;""", """void mk() { clone_object("/test/tmp_m6_verb"); clone_object("/test/gthing"); }
int count(string p) { return sizeof(filter(get_garbage(), (: base_name($1) == $(p) :))); }""")

case("m6 remove helpers",
     " ".join("rm(%s);" % lpc_str(p) for p in HELPERS) + " return 1;")

def esc(s):
    return s.replace("\\", "\\\\").replace("\n", "\\n").replace("\t", "\\t")

print("# HavokOS M6 cases (todo.md HavokOS M6): connections, telnet and the verb")
print("# parser's registry, through the test_tel_* hooks both case runners provide.")
print("# GENERATED by tools/gen_m6_cases.py -- edit that, not this file. One case per")
print("# line, <name><TAB><body>; expected results in m6_extra.expected.txt are the")
print("# live Pike driver's own (tools/ref_cases.pike -extra).")
for name, body in CASES:
    print(name + "\t" + esc(body.strip()))

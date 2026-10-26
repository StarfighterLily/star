// Reference side of the P1 #8 network hooks (todo.md HavokOS P1 #8): what
// tools/ref_cases.pike's test_cli_* / test_srv_* / test_*_listen efuns do,
// kept in their own file so their strings needn't be escaped inside
// ref_cases.pike's compile_string() block. The Star side is efuns_net.star
// efun_net_test(); the two must agree on every hook's meaning:
//
//   test_cli_open(port, secure)    connect to 127.0.0.1:port, over TLS
//                                  (no certificate check, SNI "localhost",
//                                  as run_tests.pike's tls_client()) when
//                                  secure; returns a client id, 0 if refused
//   test_cli_send(id, s)           send s (`~xx` form)
//   test_cli_recv(id, until)       what arrived since the last call (`~xx`
//                                  form), after pumping the driver: until 0,
//                                  ten 20 ms rounds; until 1, until the peer
//                                  closes; a string, until it has arrived
//                                  (both at most about two seconds)
//   test_cli_closed(id)            1 once the peer has closed
//   test_cli_close(id)             close this end, then pump ten rounds
//   test_srv_listen(secure)        a listening socket on 127.0.0.1 (TLS with
//                                  the driver's default server certificate
//                                  when secure); its port
//   test_srv_take(port)            pump until that listener accepted a
//                                  connection; its client id (0: none)
//   test_tel_listen(secure)        the driver's own telnet listener on a free
//                                  port, over TLS when secure; the port
//   test_http_listen(secure)       the driver's HTTP port (HTTPS when secure)
//                                  on a free port; the port
//   test_free_port()               a port nothing listens on (bound on
//                                  127.0.0.1 and released), for an LPC socket
//                                  to bind
//   test_ports_close()             close every listener these hooks opened
//                                  (the driver's telnet and HTTP ports, and
//                                  test_srv_listen's), and every client

object drv;
protected void create(object d) { drv = d; }

string dec(string s) {
    String.Buffer b = String.Buffer();
    string hex = "0123456789abcdef";
    for (int i = 0; i < sizeof(s); i++) {
        int hi = i + 2 < sizeof(s) ? search(hex, s[i + 1..i + 1]) : -1;
        int lo = i + 2 < sizeof(s) ? search(hex, s[i + 2..i + 2]) : -1;
        if (s[i] == '~' && hi >= 0 && lo >= 0) {
            b->putchar(hi * 16 + lo);
            i += 2;
        } else b->putchar(s[i]);
    }
    return b->get();
}

string enc(string s) {
    String.Buffer b = String.Buffer();
    foreach (s; ; int c) {
        if (c >= 32 && c < 127 && c != '~') b->putchar(c);
        else b->add(sprintf("~%02x", c & 255));
    }
    return b->get();
}

protected class Cli {
    object s;            // Stdio.File or SSL.File
    string got = "";
    string out = "";
    int closed;

    // SSL.File may call the write callback from inside write(): take the
    // buffer before writing so nothing goes out twice (run_tests.pike)
    void flush() {
        string data = out;
        out = "";
        if (!sizeof(data) || closed) return;
        int n = s->write(data);
        if (n < sizeof(data)) out = data[max(n, 0)..] + out;
    }
}

protected mapping(int:Cli) clis = ([]);
protected int seq;
protected array(object) srv_ports = ({});
protected mapping(int:array(object)) srv_accepted = ([]);
protected array(int) tel_ports = ({});

protected void pump(int rounds, float t) { for (int i = 0; i < rounds; i++) Pike.DefaultBackend(t); }

protected int add(object s) {
    Cli c = Cli();
    c->s = s;
    s->set_nonblocking(lambda(mixed id, string d) { c->got += d; }, lambda(mixed id) { c->flush(); },
                       lambda(mixed id) { c->closed = 1; });
    clis[++seq] = c;
    return seq;
}

int cli_open(int port, int secure) {
    Stdio.File f = Stdio.File();
    if (!f->connect("127.0.0.1", port)) return 0;
    object s = f;
    if (secure) {
        s = SSL.File(f, SSL.Context());
        s->connect("localhost");
    }
    return add(s);
}

int cli_send(int id, string data) {
    Cli c = clis[id];
    if (!c) return 0;
    c->out += dec(data);
    c->flush();
    return 1;
}

string cli_recv(int id, mixed until) {
    Cli c = clis[id];
    if (!c) return 0;
    if (intp(until) && !until) pump(10, 0.02);
    else {
        string want = stringp(until) ? dec(until) : 0;
        for (int i = 0; i < 200; i++) {
            if (c->closed || (want && has_value(c->got, want))) break;
            Pike.DefaultBackend(0.01);
        }
    }
    string g = c->got;
    c->got = "";
    return enc(g);
}

int cli_closed(int id) { return clis[id] ? clis[id]->closed : 1; }

int cli_close(int id) {
    Cli c = clis[id];
    if (!c) return 0;
    catch { c->s->close(); };
    m_delete(clis, id);
    pump(10, 0.02);
    return 0;
}

int srv_listen(int secure) {
    object p = secure ? SSL.Port(drv->tls()->server_context()) : Stdio.Port();
    int portno;
    if (!p->bind(0, lambda() {
            object a;
            while (a = p->accept()) srv_accepted[portno] = (srv_accepted[portno] || ({})) + ({ a });
        }, "127.0.0.1")) return 0;
    portno = (int)((p->query_address() / " ")[1]);
    srv_ports += ({ p });
    return portno;
}

int srv_take(int port) {
    for (int i = 0; i < 200 && !sizeof(srv_accepted[port] || ({})); i++) Pike.DefaultBackend(0.01);
    array(object) q = srv_accepted[port] || ({});
    if (!sizeof(q)) return 0;
    srv_accepted[port] = q[1..];
    return add(q[0]);
}

int tel_listen(int secure) {
    int n = drv->net->listen(0, secure ? drv->tls()->server_context() : 0);
    if (n) tel_ports += ({ sizeof(drv->net->ports) - 1 });
    return n;
}

int http_listen(int secure) {
    return drv->http()->listen(0, secure ? drv->tls()->server_context() : 0);
}

int free_port() {
    Stdio.Port p = Stdio.Port(0, 0, "127.0.0.1");
    int n = (int)((p->query_address() / " ")[1]);
    destruct(p);
    return n;
}

int ports_close() {
    foreach (clis; int id; Cli c) catch { c->s->close(); };
    clis = ([]);
    foreach (reverse(tel_ports), int i) {
        catch { destruct(drv->net->ports[i]); };
        drv->net->ports = drv->net->ports[..i - 1] + drv->net->ports[i + 1..];
    }
    tel_ports = ({});
    foreach (srv_ports, object p) catch { destruct(p); };
    srv_ports = ({});
    srv_accepted = ([]);
    drv->http()->close_ports();
    pump(10, 0.02);
    return 0;
}

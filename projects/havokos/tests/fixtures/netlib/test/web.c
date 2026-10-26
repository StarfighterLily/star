// http_request() fixture for the P1 #8 HTTP cases (todo.md HavokOS P1 #8):
// a superset of the reference's own pike/tests/minilib/test/web.c, which
// the case runners' network fixture overlays on a scratch copy of the
// minilib (tests/run_cases_test.ps1). The first six answers are the
// original's, verbatim, so run_tests.pike's own HTTP checks port as they
// are; the rest let a case see everything the driver parsed (/req) and
// choose the answer itself (/answer: the request body is the answer, as
// JSON -- a mapping, a string or a status code).
int later_id;

mixed http(mapping req) {
    switch (req["path"]) {
    case "/hello": return "<b>hi</b>";
    case "/echo":
        return ([ "status": 201, "type": "application/json", "headers": ([ "X-Test": "yes" ]),
                  "body": json_encode(([ "method": req["method"], "query": req["query"],
                                         "variables": req["variables"], "body": req["body"],
                                         "secure": req["secure"], "cookie": req["cookies"]["c"],
                                         "agent": req["headers"]["user-agent"] ]), 2) ]);
    case "/file": return ([ "file": "/test/web.txt" ]);
    case "/teapot": return 418;
    case "/later": later_id = req["id"]; return -1;
    case "/boom": error("boom\n");
    case "/answer": return json_decode(req["body"]);
    }
    if (req["path"][0..3] == "/req")
        return ([ "type": "application/json",
                  "body": json_encode(req + ([ "id": req["id"] > 0, "port": req["port"] > 0 ])) ]);
    return 0;
}

int query_later() { return later_id; }

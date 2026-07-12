# Regression check for the raw TCP socket builtins (todo.md #3 "Networking
# basics"): tcp_connect/tcp_send/tcp_recv/tcp_close, reusing the `ptr`/
# `null_ptr`/`is_null` FFI machinery as the socket handle type, the same way
# file_io.star's builtins reuse it for file handles. See
# tests/frontend.rs's tcp_*/runtime_tcp_*_end_to_end tests for the full
# behavioral coverage (including a real round trip against a listener) --
# this file is just an end-to-end smoke test of the same builtins composed
# in one real program.
#
# Build with `-l ws2_32` (Winsock2 isn't linked by default on this target):
#   star build examples/tcp_socket.star -l ws2_32
#
# No server is required to run this: connecting to a closed port on
# localhost demonstrates the null-handle failure path. To see a real
# round trip, start a listener on the port below first (e.g.
# `python -m http.server 8080` for a plain-text HTTP reply).
fn main():
    let host = "127.0.0.1"
    let port = 8080

    let h = tcp_connect(host, port)
    if is_null(h):
        print(f"tcp_connect({host}, {port}) failed -- no listener there")
        return

    let request = "GET / HTTP/1.0\r\nHost: 127.0.0.1\r\n\r\n"
    let sent = tcp_send(h, request)
    print(f"tcp_send ok: {sent}")

    let reply = tcp_recv(h)
    print(f"tcp_recv: {reply}")

    tcp_close(h)

# TLS -- todo.md HavokOS P1 #8: `havok/tls.pike` (which certificate a
# server presents, what a client trusts) and the part of Pike's SSL.File /
# SSL.Port the reference relies on for telnet over TLS, HTTPS and the
# STREAM_TLS socket modes.
#
# Over OpenSSL 3 (the DLLs in `openssl/lib/x64`, see `openssl/README.md`;
# the user chose OpenSSL over a hand-written TLS stack or SChannel when
# this round began). Every OpenSSL call is `extern "C"` -- possible since
# the Star compiler reads an uppercase extern's `SSL_new(ctx)` as a call
# (HavokOS P2 #1, fixed this round) -- and the only binary data crossing
# the FFI goes through the compiler's `ptr_to_bytes`/`ptr_write_bytes`
# (`src/codegen/ffi_bytes.rs`, also new) and one scratch buffer from
# OpenSSL's own allocator.
#
# Shape. A session is a TlsLink (netdata.star) over two memory BIOs rather
# than an SSL bound to the socket: the driver's one poll (net.star
# net_poll()) keeps doing every socket read and write, handing what
# arrives to tls_feed() (which runs the handshake and returns plaintext)
# and sending what tls_take() returns. So a TLS connection waits in the
# same tcp_wait_io() as everything else, and nothing here blocks.
#
# Contexts, as tls.pike:
# - Server: `external_port_N_tls : cert=<file> key=<file>` for one port, or
#   `havok tls certificate`/`havok tls key` for all; the key may be in the
#   certificate file; relative names are taken from the config file's
#   directory (`havok config dir`). With none, a self-signed certificate is
#   made once (RSA 2048, ten years, the mud's name as its common name) and
#   kept in runtime/tls/selfsigned.pem beside the tools directory, where
#   the reference keeps its own beside its source. Contexts are cached per
#   certificate and key file.
# - Client: certificates are only verified when `havok tls ca file` names a
#   PEM bundle of trusted roots; without one the link is encrypted but the
#   server unchecked.
# The error texts are tls.pike's ("TLS: cannot read certificate %s", ...).
#
# OpenSSL's `long` parameters are declared i64: on Windows x64 a long is 32
# bits but every argument travels in a 64-bit register or stack slot, so
# the callee reads the low half; on Linux a long is the full 64 bits. No
# `long` result is used where its upper half would matter.

import "value.star" as val
import "vm.star" as vm
import "netdata.star" as nd
import "paths.star" as paths

extern "C" fn TLS_server_method() -> ptr
extern "C" fn TLS_client_method() -> ptr
extern "C" fn SSL_CTX_new(m: ptr) -> ptr
extern "C" fn SSL_CTX_use_certificate_chain_file(ctx: ptr, f: str) -> i32
extern "C" fn SSL_CTX_use_PrivateKey_file(ctx: ptr, f: str, t: i32) -> i32
extern "C" fn SSL_CTX_check_private_key(ctx: ptr) -> i32
extern "C" fn SSL_CTX_load_verify_locations(ctx: ptr, ca: str, dir: ptr) -> i32
extern "C" fn SSL_CTX_set_verify(ctx: ptr, mode: i32, cb: ptr)
extern "C" fn SSL_CTX_free(ctx: ptr)
extern "C" fn SSL_new(ctx: ptr) -> ptr
extern "C" fn SSL_free(s: ptr)
extern "C" fn SSL_set_bio(s: ptr, r: ptr, w: ptr)
extern "C" fn SSL_set_accept_state(s: ptr)
extern "C" fn SSL_set_connect_state(s: ptr)
extern "C" fn SSL_ctrl(s: ptr, cmd: i32, larg: i64, parg: str) -> i32
extern "C" fn SSL_do_handshake(s: ptr) -> i32
extern "C" fn SSL_get_error(s: ptr, r: i32) -> i32
extern "C" fn SSL_read(s: ptr, buf: ptr, n: i32) -> i32
extern "C" fn SSL_write(s: ptr, buf: ptr, n: i32) -> i32
extern "C" fn SSL_shutdown(s: ptr) -> i32
extern "C" fn BIO_s_mem() -> ptr
extern "C" fn BIO_new(m: ptr) -> ptr
extern "C" fn BIO_read(b: ptr, buf: ptr, n: i32) -> i32
extern "C" fn BIO_write(b: ptr, buf: ptr, n: i32) -> i32
extern "C" fn BIO_new_file(path: str, mode: str) -> ptr
extern "C" fn BIO_free(b: ptr) -> i32
extern "C" fn ERR_clear_error()
extern "C" fn CRYPTO_malloc(n: i64, file: str, line: i32) -> ptr
extern "C" fn BN_new() -> ptr
extern "C" fn BN_set_word(bn: ptr, w: i64) -> i32
extern "C" fn BN_free(bn: ptr)
extern "C" fn RSA_new() -> ptr
extern "C" fn RSA_generate_key_ex(rsa: ptr, bits: i32, e: ptr, cb: ptr) -> i32
extern "C" fn EVP_PKEY_new() -> ptr
extern "C" fn EVP_PKEY_assign(pkey: ptr, kind: i32, key: ptr) -> i32
extern "C" fn EVP_PKEY_free(pkey: ptr)
extern "C" fn EVP_sha256() -> ptr
extern "C" fn X509_new() -> ptr
extern "C" fn X509_free(x: ptr)
extern "C" fn X509_set_version(x: ptr, v: i64) -> i32
extern "C" fn X509_get_serialNumber(x: ptr) -> ptr
extern "C" fn ASN1_INTEGER_set(a: ptr, v: i64) -> i32
extern "C" fn X509_getm_notBefore(x: ptr) -> ptr
extern "C" fn X509_getm_notAfter(x: ptr) -> ptr
extern "C" fn X509_gmtime_adj(t: ptr, adj: i64) -> ptr
extern "C" fn X509_set_pubkey(x: ptr, pkey: ptr) -> i32
extern "C" fn X509_get_subject_name(x: ptr) -> ptr
extern "C" fn X509_NAME_add_entry_by_txt(name: ptr, field: str, kind: i32, bytes: str, len: i32, loc: i32, set: i32) -> i32
extern "C" fn X509_set_issuer_name(x: ptr, name: ptr) -> i32
extern "C" fn X509_sign(x: ptr, pkey: ptr, md: ptr) -> i32
extern "C" fn PEM_write_bio_X509(b: ptr, x: ptr) -> i32
extern "C" fn PEM_write_bio_RSAPrivateKey(b: ptr, rsa: ptr, enc: ptr, kstr: ptr, klen: i32, cb: ptr, u: ptr) -> i32

const SSL_FILETYPE_PEM: i32 = 1
const SSL_ERROR_WANT_READ: i32 = 2
const SSL_ERROR_WANT_WRITE: i32 = 3
const SSL_ERROR_ZERO_RETURN: i32 = 6
const SSL_VERIFY_PEER: i32 = 1
const SSL_CTRL_SET_TLSEXT_HOSTNAME: i32 = 55
const MBSTRING_ASC: i32 = 4097
const EVP_PKEY_RSA: i32 = 6
# the scratch buffer every BIO/SSL read and write goes through
const SCRATCH: i32 = 65536

fn read_text(path: str) -> str:
    let f = file_open(path, "rb")
    if is_null(f):
        return ""
    let b = file_read_bytes(f)
    file_close(f)
    str_from_bytes(b)

# the index of the last `/` in s, or -1
fn last_slash(s: str) -> i32:
    let b = bytes_from_str(s)
    let mut i = b.len() - 1
    while i >= 0:
        if (b[i] as i32) == 47:
            return i
        i -= 1
    -1

fn readable(path: str) -> bool:
    let f = file_open(path, "rb")
    if is_null(f):
        return false
    file_close(f)
    true

impl vm::Vm:
    fn tls_scratch(mut self) -> ptr:
        if is_null(self.tls_buf):
            self.tls_buf = CRYPTO_malloc(SCRATCH as i64, "havokos", 0)
        self.tls_buf

    # tls.pike config_path(): a config file name as an OS path ("" for none)
    fn tls_config_path(self, f: str) -> str:
        if f == "":
            return ""
        let b = bytes_from_str(f)
        if str_starts_with(f, "/") or (b.len() > 1 and (b[1] as i32) == 58):
            return f
        let mut base = "."
        if let Option::Some(d) = self.config.get("havok config dir"):
            if d != "":
                base = d
        concat(concat(base, "/"), f)

    # runtime/tls/selfsigned.pem beside the tools directory the running
    # program lives in (tools/havokos.exe, tools/run_cases.exe, ...)
    fn tls_self_signed_file(self) -> str:
        let exe = str_replace(args()[0], "\\", "/")
        let cut = last_slash(exe)
        let dir = if cut < 0: "." else: vm::substr(exe, 0, cut)
        concat(dir, "/../runtime/tls/selfsigned.pem")

    # tls.pike self_signed(): the certificate and key file, made once.
    fn tls_self_signed(mut self) -> str:
        let file = self.tls_self_signed_file()
        if readable(file):
            return file
        self.log_msg(f"[tls] no certificate configured; making a self-signed one in {file}")
        let cut = last_slash(file)
        let tdir = vm::substr(file, 0, cut)
        dir_create(vm::substr(tdir, 0, last_slash(tdir)))
        dir_create(tdir)
        let mut name = "HavokOS"
        if let Option::Some(n) = self.config.get("name"):
            if n != "":
                name = n
        let e = BN_new()
        BN_set_word(e, 65537 as i64)
        let rsa = RSA_new()
        let ok = RSA_generate_key_ex(rsa, 2048, e, null_ptr())
        BN_free(e)
        if ok != 1:
            return ""
        let pkey = EVP_PKEY_new()
        EVP_PKEY_assign(pkey, EVP_PKEY_RSA, rsa)
        let x = X509_new()
        X509_set_version(x, 2 as i64)
        ASN1_INTEGER_set(X509_get_serialNumber(x), 1 as i64)
        X509_gmtime_adj(X509_getm_notBefore(x), 0 as i64)
        X509_gmtime_adj(X509_getm_notAfter(x), (3650 as i64) * (86400 as i64))
        X509_set_pubkey(x, pkey)
        let subject = X509_get_subject_name(x)
        X509_NAME_add_entry_by_txt(subject, "CN", MBSTRING_ASC, name, -1, -1, 0)
        X509_set_issuer_name(x, subject)
        X509_sign(x, pkey, EVP_sha256())
        let out = BIO_new_file(file, "w")
        let mut written = false
        if !is_null(out):
            written = PEM_write_bio_X509(out, x) == 1 and PEM_write_bio_RSAPrivateKey(out, rsa, null_ptr(), null_ptr(), 0, null_ptr(), null_ptr()) == 1
            BIO_free(out)
        X509_free(x)
        EVP_PKEY_free(pkey)
        if !written:
            return ""
        file

    # tls.pike server_context(): the server context for a certificate and
    # key file ("": the configured default, else the self-signed one); null,
    # with the reason in `tls_err`, if they can't be loaded.
    fn tls_server_context(mut self, cert_in: str, key_in: str) -> ptr:
        let mut cert = cert_in
        let mut key = key_in
        if cert == "":
            cert = self.tls_config_path(self.tls_cfg("havok tls certificate"))
            key = self.tls_config_path(self.tls_cfg("havok tls key"))
        if cert == "":
            cert = self.tls_self_signed()
            if cert == "":
                self.tls_err = "TLS: cannot make a self-signed certificate\n"
                return null_ptr()
        if key == "":
            key = cert
        let id = concat(concat(cert, "|"), key)
        if let Option::Some(c) = self.tls_ctxs.get(id):
            return c
        if !readable(cert):
            self.tls_err = f"TLS: cannot read certificate {cert}\n"
            return null_ptr()
        if !readable(key):
            self.tls_err = f"TLS: cannot read key {key}\n"
            return null_ptr()
        if !str_contains(read_text(cert), "-----BEGIN CERTIFICATE-----"):
            self.tls_err = f"TLS: no CERTIFICATE in {cert}\n"
            return null_ptr()
        let ctx = SSL_CTX_new(TLS_server_method())
        ERR_clear_error()
        if SSL_CTX_use_certificate_chain_file(ctx, cert) != 1:
            SSL_CTX_free(ctx)
            self.tls_err = f"TLS: no CERTIFICATE in {cert}\n"
            return null_ptr()
        if SSL_CTX_use_PrivateKey_file(ctx, key, SSL_FILETYPE_PEM) != 1 or SSL_CTX_check_private_key(ctx) != 1:
            ERR_clear_error()
            SSL_CTX_free(ctx)
            self.tls_err = f"TLS: no usable private key in {key}\n"
            return null_ptr()
        self.tls_ctxs.insert(id, ctx)
        ctx

    # tls.pike client_context()
    fn tls_client_context(mut self) -> ptr:
        if !is_null(self.tls_client):
            return self.tls_client
        let ctx = SSL_CTX_new(TLS_client_method())
        let ca = self.tls_config_path(self.tls_cfg("havok tls ca file"))
        if ca != "":
            ERR_clear_error()
            if SSL_CTX_load_verify_locations(ctx, ca, null_ptr()) != 1:
                ERR_clear_error()
                SSL_CTX_free(ctx)
                self.tls_err = f"TLS: cannot read CA file {ca}\n"
                return null_ptr()
            SSL_CTX_set_verify(ctx, SSL_VERIFY_PEER, null_ptr())
        self.tls_client = ctx
        ctx

    # A client context that checks nothing, for the case runner's clients
    # (run_tests.pike's tls_client() uses a bare SSL.Context()).
    fn tls_test_context(mut self) -> ptr:
        if is_null(self.tls_test):
            self.tls_test = SSL_CTX_new(TLS_client_method())
        self.tls_test

    # tls.pike port_files(): `external_port_N_tls : cert=<file> key=<file>`
    # -> [cert, key] as OS paths ("" for the defaults).
    fn tls_port_files(self, spec: str) -> List<str>:
        let mut cert = ""
        let mut key = ""
        let words = str_split(str_replace(str_replace(spec, "\t", " "), "\r", " "), " ")
        for i in 0..words.len():
            let w = words[i]
            if str_starts_with(w, "cert="):
                cert = self.tls_config_path(vm::substr(w, 5, len(w)))
            elif str_starts_with(w, "key="):
                key = self.tls_config_path(vm::substr(w, 4, len(w)))
        if cert != "" and key == "":
            key = cert
        [cert, key]

    fn tls_cfg(self, k: str) -> str:
        if let Option::Some(v) = self.config.get(k):
            return v
        ""

    # --- sessions ---------------------------------------------------------------

    # A new session on `ctx`: the server side of an accepted connection, or a
    # client naming `host` (SNI). Its row in `tlss`.
    fn tls_open(mut self, ctx: ptr, server: bool, host: str) -> i32:
        let s = SSL_new(ctx)
        let r = BIO_new(BIO_s_mem())
        let w = BIO_new(BIO_s_mem())
        SSL_set_bio(s, r, w)
        if server:
            SSL_set_accept_state(s)
        else:
            SSL_set_connect_state(s)
            if host != "":
                SSL_ctrl(s, SSL_CTRL_SET_TLSEXT_HOSTNAME, 0 as i64, host)
        let link = nd::TlsLink(ssl = s, rbio = r, wbio = w, server = server)
        for i in 0..self.tlss.len():
            if !self.tlss[i].used:
                self.tlss[i] = link
                return i
        self.tlss.push(link)
        self.tlss.len() - 1

    # Bytes from the socket: on with the handshake (a client sends its hello
    # on the first, empty, feed), then the plaintext that came through.
    fn tls_feed(mut self, li: i32, cipher: Bytes) -> Bytes:
        let buf = self.tls_scratch()
        let mut off = 0
        while off < cipher.len():
            let k = ptr_write_bytes(buf, cipher, off, SCRATCH)
            BIO_write(self.tlss[li].rbio, buf, k)
            off += k
        let ssl = self.tlss[li].ssl
        let mut out: Bytes = Bytes()
        if self.tlss[li].failed:
            return out
        if !self.tlss[li].up:
            ERR_clear_error()
            let r = SSL_do_handshake(ssl)
            if r == 1:
                self.tlss[li].up = true
                let p = self.tlss[li].pend
                self.tlss[li].pend = Bytes()
                if p.len() > 0:
                    self.tls_send(li, p)
            else:
                let e = SSL_get_error(ssl, r)
                if e != SSL_ERROR_WANT_READ and e != SSL_ERROR_WANT_WRITE:
                    self.tlss[li].failed = true
                ERR_clear_error()
                return out
        while true:
            ERR_clear_error()
            let n = SSL_read(ssl, buf, SCRATCH)
            if n > 0:
                let c = ptr_to_bytes(buf, n)
                for i in 0..c.len():
                    out.push(c[i])
                continue
            let e = SSL_get_error(ssl, n)
            if e == SSL_ERROR_ZERO_RETURN:
                self.tlss[li].peer_closed = true
            elif e != SSL_ERROR_WANT_READ and e != SSL_ERROR_WANT_WRITE:
                self.tlss[li].failed = true
            ERR_clear_error()
            break
        out

    # Plaintext to send: encrypted now, or held until the handshake is done.
    fn tls_send(mut self, li: i32, plain: Bytes):
        if plain.len() == 0 or self.tlss[li].failed:
            return
        if !self.tlss[li].up:
            for i in 0..plain.len():
                self.tlss[li].pend.push(plain[i])
            return
        let buf = self.tls_scratch()
        let mut off = 0
        while off < plain.len():
            let k = ptr_write_bytes(buf, plain, off, SCRATCH)
            ERR_clear_error()
            let n = SSL_write(self.tlss[li].ssl, buf, k)
            if n <= 0:
                self.tlss[li].failed = true
                ERR_clear_error()
                return
            off += n

    # What OpenSSL has for the socket (handshake records, encrypted data,
    # alerts).
    fn tls_take(mut self, li: i32) -> Bytes:
        let buf = self.tls_scratch()
        let mut out: Bytes = Bytes()
        let mut n = BIO_read(self.tlss[li].wbio, buf, SCRATCH)
        while n > 0:
            let c = ptr_to_bytes(buf, n)
            for i in 0..c.len():
                out.push(c[i])
            n = BIO_read(self.tlss[li].wbio, buf, SCRATCH)
        out

    # The close_notify alert, for tls_take() to send before the socket closes.
    fn tls_close(mut self, li: i32):
        if li < 0 or li >= self.tlss.len() or !self.tlss[li].used:
            return
        if self.tlss[li].up and !self.tlss[li].failed:
            ERR_clear_error()
            SSL_shutdown(self.tlss[li].ssl)
            ERR_clear_error()

    fn tls_free(mut self, li: i32):
        if li < 0 or li >= self.tlss.len() or !self.tlss[li].used:
            return
        SSL_free(self.tlss[li].ssl)
        self.tlss[li] = nd::TlsLink(used = false)

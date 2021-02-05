# Node.js

```{contents}
:depth: 2
:local:
```

## Development Certificates

In {doc}`appendix/index`, we lay out the process for generating a chain that is
valid for `localhost` that can be used for testing. Since it costs money to get
a real CA to create a certificate **and** since a real CA would never sign a
certificate for `localhost`, we also use a custom self-signed root CA. Since
this is custom, we must add it to our root trust store when making requests
(some may recommend installing this onto the system root store permanently,
this should be avoided **at all costs**).

## Server

We'll use this to run a TLS server ({doc}`appendix/server-js`) and connect to
it via `curl`. In particular, we are going to specify the private key and
public certificate pair for the server's leaf certificate:

```{literalinclude} nodejs/server.js
---
language: javascript
lines: 32-35,43
dedent: 4
---
```

(server-misconfiguration)=

### Misconfiguration

We'll first run the server with an invalid configuration:

```text
cd docs/nodejs/
node server.js \
  --cert ../tls-certs/localhost-server-cert.pem \
  --key ../tls-certs/localhost-server-key.pem
# Example TLS app listening at https://localhost:8443
```

The certificate file for this server **does not** contain the intermediate.
Using `curl` to hit this server will **fail** in most typical ways we may
invoke it.

#### No Extra CA Provided

Using a vanilla `curl` request fails, as expected:

```text
$ curl https://localhost:8443
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

As mentioned above, we are using a custom CA so we need to add this to
`curl`.

#### Only Root CA Provided

We "expect" it to work if we can trust the local root that we created

```text
$ curl --cacert ../tls-certs/root-ca-cert.pem https://localhost:8443
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

In particular note that the `unable to get local issuer certificate`
resembles a similar error we saw in {doc}`openssl` when using
`openssl verify`. The issue here is that when validating the server, `curl`
has no way to follow the leaf certificate to the root because it doesn't
know anything about our (private) intermediate certificate.

#### Only Intermediate CA Provided

Since we've concluded that the missing intermediate certificate is the
problem, a common next step may be to specify (only) the intermediate as
an extra CA:

```text
$ curl --cacert ../tls-certs/intermediate-ca-cert.pem https://localhost:8443
curl: (60) SSL certificate problem: unable to get issuer certificate
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

The error message here `unable to get issuer certificate` is slightly
different. It indicates that we **are** able to find the issuer of our
leaf certificate, but **are not** able to follow the chain one more step
to find the issuer of the intermediate.

#### Both Root and Intermediate CA Provided

Since it's clear now that **both** the intermediate and root CA are needed,
we use the `intermediate-ca-chain.pem` file, which bundles both certificates
together.

```text
$ curl --cacert ../tls-certs/intermediate-ca-chain.pem https://localhost:8443
{"success": true}
```

### Valid Configuration

In {ref}`server-misconfiguration` above, we intentionally ran the server
with an "invalid" certificate. Instead, we should've used a file that
contained enough of our chain for clients to do all validation they'd need
to. The `localhost-server-chain.pem` file contains both the leaf and the
intermediate certificates.

```text
cd docs/nodejs/
node server.js \
  --cert ../tls-certs/localhost-server-chain.pem \
  --key ../tls-certs/localhost-server-key.pem
# Example TLS app listening at https://localhost:8443
```

#### Only Root CA Provided

Now, we can successfully make a request when only adding the root CA as an
extra CA:

```
$ curl --cacert ../tls-certs/root-ca-cert.pem https://localhost:8443
{"success": true}
```

#### No Extra CA Provided

Using a vanilla `curl` request still fails:

```
$ curl https://localhost:8443
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

### Presenting the Root with the Server Chain

If it was good to present the intermediate, is it good to present the root too?
The `localhost-server-full.pem` file contains bundles the leaf, intermediate
and root certificates together.

```text
cd docs/nodejs/
node server.js \
  --cert ../tls-certs/localhost-server-full.pem \
  --key ../tls-certs/localhost-server-key.pem
# Example TLS app listening at https://localhost:8443
```

However, a vanilla `curl` **still** fails (but now for a different reason)

```
$ curl https://localhost:8443
curl: (60) SSL certificate problem: self signed certificate in certificate chain
More details here: https://curl.haxx.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

The `self signed certificate in certificate chain` error makes sense here
because we have a custom self-signed root CA.

Tacking on the root CA will continue to work though:

```
$ curl --cacert ../tls-certs/root-ca-cert.pem https://localhost:8443
{"success": true}
```

Being familiar with this `self signed certificate` error in other situations
may be very useful. As we'll see later in {ref}`nodejs-client`, it's possible
to &mdash; either intentionally or by mistake &mdash; to **replace** the root
bundle in Node.js client code. For example, if a client needed to connect
to `github.com`, overriding the root bundle with just the
`DigiCert High Assurance EV Root CA` certificate would still continue to work.
But, when GitHub rotates their certificate, the code / configuration that used
to work may stop working with this exact error if GitHub rotated to a
certificate signed by a different CA.

(nodejs-client)=

## Client

As we saw above, there is an apparent disagreement between the `--cert` flag
(and the Node.js `cert` TLS option) and the `*-chain.pem` suffix. This is not
an accident. There is a significant amount of confusion using the
[TLS options][1] for the typical application developer that doesn't think
about TLS very often (or ever).

The `cert` option is typically interpreted as "just the leaf certificate" but
the documentation makes it clear that `chain` or `certChain` would be a better
option name:

```{admonition} cert
:class: note

Cert chains in PEM format ... Each cert chain should consist of the PEM
formatted certificate for a provided private key, followed by the PEM
formatted intermediate certificates (if any) ... If the intermediate
certificates are not provided, the peer will not be able to validate the
certificate, and the handshake will fail.
```

Similarly, the `ca` option is typically interpreted as "just the CA for
the leaf certificate", which is ambiguous as-is. However, the interpretation
of this field is **made worse** by its behavior. The default behavior
of `curl --cacert` is to **append** to the system trust store, e.g. specifying
our custom root CA doesn't stop us from trusting `google.com`

```text
$ curl --cacert ../tls-certs/root-ca-cert.pem https://google.com
<HTML><HEAD><meta http-equiv="content-type" content="text/html;charset=utf-8">
<TITLE>301 Moved</TITLE></HEAD><BODY>
...
```

However, that is **not** the behavior of the `ca` TLS option in Node.js:

```{admonition} ca
:class: note

Optionally override the trusted CA certificates. Default is to trust the
well-known CAs curated by Mozilla. Mozilla's CAs are completely replaced when
CAs are explicitly specified using this option.
```

[1]: https://nodejs.org/docs/latest-v14.x/api/tls.html#tls_tls_createsecurecontext_options

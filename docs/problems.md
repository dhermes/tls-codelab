# Common Reasons to Debug TLS

There are at least two unique reasons to care about this as it pertains to
integrating with partners and external APIs.

(misconfiguration)=

## Misconfiguration

The first is in cases where a partner has made a mistake in configuring
their certificates in a server. For example, consider a fictional API
server `initech.dev.invalid` that does not present an intermediate
certificate:

```text
$ openssl s_client -connect initech.dev.invalid:443 -servername initech.dev.invalid
CONNECTED(00000005)
depth=0 C = US, ST = California, O = Initech, OU = Initech Certificate Authority, CN = Initech Dev Server
verify error:num=20:unable to get local issuer certificate
verify return:1
depth=0 C = US, ST = California, O = Initech, OU = Initech Certificate Authority, CN = Initech Dev Server
verify error:num=21:unable to verify the first certificate
verify return:1
---
Certificate chain
 0 s:/C=US/ST=California/O=Initech/OU=Initech Certificate Authority/CN=Initech Dev Server
   i:/C=US/ST=California/O=Initech/OU=Initech Certificate Authority/CN=Initech Intermediate CA
---
Server certificate
-----BEGIN CERTIFICATE-----
MIIFAzCCAuugAwIBAgICEAAwDQYJKoZIhvcNAQELBQAwfjELMAkGA1UEBhMCVVMx
...
```

Since intermediate certificates will not be stored in our system root store,
in these situations we need to modify the root bundle (e.g. via the `cert`
TLS option in Node.js) to also contain the relevant intermediate certificate.

Addressing this problem by modifying a root bundle is **incredibly** brittle.
When the server leaf certificate inevitably expires, our outbound connections
to the misconfigured partner will likely fail unless the newly rotated leaf
certificate is also signed by the exact same intermediate. For this reason,
it's critical to rely on technical support, business development and other
channels to try to help partners "do the right thing"&#x2122; and fix their
server TLS configuration.

## Mutual TLS

Mutual TLS (mTLS[^massl]) is a form of TLS where **both** the server and the
client present certificates and prove they own the corresponding private key.
Usage of mTLS is somewhat uncommon in the "general" web and API landscape,
though it is fairly common both in banking and in infrastructure projects
(e.g. Kubernetes).

When using mTLS, it's not uncommon for a partner to use a private or internal
CA to sign client certificates. In typical cases, this can be addressed (as a
client) by just presenting the entire chain with a private root CA; i.e.
we can handle this in our code with just our certificate and without the need
to modify the root bundle used by our TLS / HTTPS client. In rare cases,
partners may require **only** a leaf be presented for validation. In these
rare cases, most programming language runtimes will require adding these
internal CA certificates to the root bundle.

As with the {ref}`misconfiguration` section above, having to modify the
root bundle should be a last resort both for security reasons and for potential
for application / configuration brittleness. Rather than doing this,
coordination with partners should be attempted to allow for more flexibility
in validation. I.e. for a partner, a client certificate presented as the
full chain should be considered just as a valid as presenting the leaf only
if the handshake is valid.

[^massl]: mTLS is sometimes referred to as MASSL. This is an "outdated"
  reference to now defunct protocols SSL 1.0, 2.0 and 3.0. Unfortunately there
  will probably always be some confusion in terminology between SSL and TLS,
  e.g. the very useful `openssl` project likely will never rename to `opentls`.

# Generating Leaf Certificate for TLS Client (in mTLS)

To create a "local" client certificate for testing purposes

## Prerequisites

To make sure we are in the right directory for generating certificates:

```{literalinclude} ../scripts/make-client-leaf.sh
---
language: shell
lines: 5-14
---
```

This is actually critical because some paths in the `openssl` configuration
files (`.cnf`) are relative paths starting with `./`.

## Generate a Private Key

```{literalinclude} ../scripts/make-client-leaf.sh
---
language: shell
lines: 17-22
---
```

Notice we make sure to remove any lingering private key (if a previously
generated one exists) and we make sure the generated file is readonly and
only for the current user (permissions `0400`).

## Generate a CSR for the Intermediate CA

A Certificate Signing Request (CSR) is typically used with public certificate
authorities (e.g. think DigiCert) so that a customer can request a **signed**
public certificate without having to share their private key with the CA.

```{literalinclude} ../scripts/make-client-leaf.sh
---
language: shell
lines: 25-33
---
```

## Create "Temporary" Files Used by the Intermediate CA for Tracking

```{literalinclude} ../scripts/make-client-leaf.sh
---
language: shell
lines: 36-40
---
```

## Submit the CSR to the Intermediate CA

```{literalinclude} ../scripts/make-client-leaf.sh
---
language: shell
lines: 43-55
---
```

## Create Full Chain with Leaf Certificate, Intermediate CA and Root CA

```{literalinclude} ../scripts/make-client-leaf.sh
---
language: shell
lines: 64-69
---
```

## Example

After generating, the private key will resemble

```{literalinclude} ../tls-certs/localhost-client-key.pem
---
language: text
---
```

and the public certificate will resemble

```{literalinclude} ../tls-certs/localhost-client-cert.pem
---
language: text
---
```

Running `openssl x509 -noout -text -in .../localhost-client-cert.pem` on the
public CA certificate should produce attributes of the form

```{literalinclude} ../tls-certs/localhost-client-cert.txt
---
language: text
---
```

## References

-   [Sign server and client certificates][1] tutorial from Jamie Nguyen

[1]: https://jamielinux.com/docs/openssl-certificate-authority/sign-client-and-client-certificates.html

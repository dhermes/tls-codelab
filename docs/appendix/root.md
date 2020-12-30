# Generating Root CA Certificate

To create a "local" root certificate authority for testing purposes

## Prerequisites

To make sure we are in the right directory for generating certificates:

```{literalinclude} ../scripts/make-root-ca.sh
---
language: shell
lines: 5-14
---
```

This is actually critical because some paths in the `openssl` configuration
files (`.cnf`) are relative paths starting with `./`.

## Generate a Private Key

```{literalinclude} ../scripts/make-root-ca.sh
---
language: shell
lines: 17-22
---
```

Notice we make sure to remove any lingering private key (if a previously
generated one exists) and we make sure the generated file is readonly and
only for the current user (permissions `0400`).

## Self-sign a Public Certificate

Using an `openssl` configuration file (`.cnf`) that

```{literalinclude} ../scripts/make-root-ca.sh
---
language: shell
lines: 25-37
---
```

Here we make the root CA certificate readonly to **all** users on the machine,
e.g. so other users could add this CA to a trust store.

## Example

After generating, the private key will resemble

```{literalinclude} ../tls-certs/root-ca-key.pem
---
language: text
---
```

and the public certificate will resemble

```{literalinclude} ../tls-certs/root-ca-cert.pem
---
language: text
---
```

Running `openssl x509 -noout -text -in .../root-ca-cert.pem` on the public CA
certificate should produce attributes of the form

```{literalinclude} ../tls-certs/root-ca-cert.txt
---
language: text
---
```

## References

-   [Create the root pair][1] tutorial from Jamie Nguyen

[1]: https://jamielinux.com/docs/openssl-certificate-authority/create-the-root-pair.html

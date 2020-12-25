# Generating Root CA Certificate

To create a "local" root certificate authority for testing purposes

## Generate a Private Key

```
TLS_CERTS=".../path/to/tls-certs"
rm -f "${TLS_CERTS}/root-ca-key.pem"  # In cases where we are regenerating
openssl genrsa \
  -out "${TLS_CERTS}/root-ca-key.pem" \
  4096
chmod 400 "${TLS_CERTS}/root-ca-key.pem"
```

Notice we make sure to remove any lingering private key (if a previously
generated one exists) and we make sure the generated file is readonly and
only for the current user (permissions `0400`).

## Self-sign a Public Certificate

Using an `openssl` configuration file (`.cnf`) that

```
rm -f "${TLS_CERTS}/root-ca-cert.pem"  # In cases where we are regenerating
openssl req \
  -config "${TLS_CERTS}/root-ca.cnf" \
  -key "${TLS_CERTS}/root-ca-key.pem" \
  -new \
  -x509 \
  -days 7300 \
  -sha256 \
  -extensions v3_ca \
  -out "${TLS_CERTS}/root-ca-cert.pem"
chmod 444 "${TLS_CERTS}/root-ca-cert.pem"
```

Here we make the root CA certificate read-only to **all** users on the machine,
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

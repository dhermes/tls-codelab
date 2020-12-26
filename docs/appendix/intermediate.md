# Generating Intermediate CA Certificate

To create a "local" intermediate certificate authority for testing purposes

## Prerequisites

To make sure we are in the right directory for generating certificates:

```shell
TLS_CERTS=".../path/to/tls-certs"
cd "${TLS_CERTS}"
```

This is actually critical because some paths in the `openssl` configuration
files (`.cnf`) are relative paths starting with `./`.

## Generate a Private Key

```shell
PRIVATE_KEY="./intermediate-ca-key.pem"
rm -f "${PRIVATE_KEY}"  # In cases where we are regenerating
openssl genrsa \
  -out "${PRIVATE_KEY}" \
  4096
chmod 400 "${PRIVATE_KEY}"
```

Notice we make sure to remove any lingering private key (if a previously
generated one exists) and we make sure the generated file is readonly and
only for the current user (permissions `0400`).

## Generate a CSR for the Root CA

A Certificate Signing Request (CSR) is typically used with public certificate
authorities (e.g. think DigiCert) so that a customer can request a **signed**
public certificate without having to share their private key with the CA.

```shell
CSR="./intermediate-ca-csr.pem"
CONFIG_FILE="./intermediate-ca.cnf"
rm -f "${CSR}"  # Clean up from previous runs
openssl req \
  -config "${CONFIG_FILE}" \
  -key "${PRIVATE_KEY}" \
  -new \
  -sha256 \
  -out "${CSR}"
```

## Create "Temporary" Files Used by the Root CA for Tracking

```shell
ROOT_CA_SERIAL_ID=1000
ROOT_CA_DATABASE="./root-ca-database.txt"
ROOT_CA_SERIAL_TXT="./root-ca-serial.txt"
touch "${ROOT_CA_DATABASE}"
echo "${ROOT_CA_SERIAL_ID}" > "${ROOT_CA_SERIAL_TXT}"
```

## Submit the CSR to the Root CA

```shell
PUBLIC_CERTIFICATE="./intermediate-ca-cert.pem"
ROOT_CA_CONFIG_FILE="./root-ca.cnf"
rm -f "${PUBLIC_CERTIFICATE}"  # In cases where we are regenerating
openssl ca \
  -batch \
  -config "${ROOT_CA_CONFIG_FILE}" \
  -extensions v3_intermediate_ca \
  -days 3650 \
  -notext \
  -md sha256 \
  -in "${CSR}" \
  -out "${PUBLIC_CERTIFICATE}"
chmod 444 "${PUBLIC_CERTIFICATE}"
```

## Create Full Chain with Root CA and Intermediate CA

```shell
CERTIFICATE_CHAIN="./intermediate-ca-chain.pem"
ROOT_CA_PUBLIC_CERTIFICATE="./root-ca-cert.pem"
rm -f "${CERTIFICATE_CHAIN}"  # In cases where we are regenerating
cat "${PUBLIC_CERTIFICATE}" >> "${CERTIFICATE_CHAIN}"
cat "${ROOT_CA_PUBLIC_CERTIFICATE}" >> "${CERTIFICATE_CHAIN}"
chmod 444 "${CERTIFICATE_CHAIN}"
```

## Example

After generating, the private key will resemble

```{literalinclude} ../tls-certs/intermediate-ca-key.pem
---
language: text
---
```

and the public certificate will resemble

```{literalinclude} ../tls-certs/intermediate-ca-cert.pem
---
language: text
---
```

Running `openssl x509 -noout -text -in .../intermediate-ca-cert.pem` on the
public CA certificate should produce attributes of the form

```{literalinclude} ../tls-certs/intermediate-ca-cert.txt
---
language: text
---
```

## References

-   [Create the intermediate pair][1] tutorial from Jamie Nguyen

[1]: https://jamielinux.com/docs/openssl-certificate-authority/create-the-intermediate-pair.html

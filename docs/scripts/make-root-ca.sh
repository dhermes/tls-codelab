#!/bin/bash

set -e -x

if [ -z "${TLS_CERTS_PATH}" ]; then
  echo "TLS_CERTS_PATH environment variable should be set by the caller."
  exit 1
fi

# Just change directories into the `tls-certs` path; this is because the
# paths (e.g. for the `private_key`) in the `.cnf` files are relative to `./`
# and making them absolute is not worth the trouble of worrying about a
# specific absolute path always being available.
cd "${TLS_CERTS_PATH}"

# 1. Make the key
PRIVATE_KEY="./root-ca-key.pem"
rm -f "${PRIVATE_KEY}"  # In cases where we are regenerating
openssl genrsa \
  -out "${PRIVATE_KEY}" \
  4096
chmod 400 "${PRIVATE_KEY}"

# 2. Make the CA cert (self-signed)
PUBLIC_CERTIFICATE="./root-ca-cert.pem"
CONFIG_FILE="./root-ca.cnf"
rm -f "${PUBLIC_CERTIFICATE}"  # In cases where we are regenerating
openssl req \
  -config "${CONFIG_FILE}" \
  -key "${PRIVATE_KEY}" \
  -new \
  -x509 \
  -days 7300 \
  -sha256 \
  -extensions v3_ca \
  -out "${PUBLIC_CERTIFICATE}"
chmod 444 "${PUBLIC_CERTIFICATE}"

# 3. Generate the x509 text description
OPENSSL_X509_TXT="./root-ca-cert.txt"
openssl x509 -noout -text -in "${PUBLIC_CERTIFICATE}" > "${OPENSSL_X509_TXT}"

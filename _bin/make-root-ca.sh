#!/bin/bash

set -e -x

if [ -z "${TLS_CERTS_PATH}" ]; then
  echo "TLS_CERTS_PATH environment variable should be set by the caller."
  exit 1
fi

PRIVATE_KEY="${TLS_CERTS_PATH}/root-ca-key.pem"
PUBLIC_CERTIFICATE="${TLS_CERTS_PATH}/root-ca-cert.pem"
CONFIG_FILE="${TLS_CERTS_PATH}/root-ca.cnf"
OPENSSL_X509_TXT="${TLS_CERTS_PATH}/root-ca-cert.txt"

# 1. Make the key
rm -f "${PRIVATE_KEY}"
openssl genrsa \
  -out "${PRIVATE_KEY}" \
  4096
chmod 400 "${PRIVATE_KEY}"

# 2. Make the CA cert (self-signed)
rm -f "${PUBLIC_CERTIFICATE}"
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
openssl x509 -noout -text -in "${PUBLIC_CERTIFICATE}" > "${OPENSSL_X509_TXT}"

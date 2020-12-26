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

PRIVATE_KEY="./intermediate-ca-key.pem"
CSR="./intermediate-ca-csr.pem"
CONFIG_FILE="./intermediate-ca.cnf"
PUBLIC_CERTIFICATE="./intermediate-ca-cert.pem"
CERTIFICATE_CHAIN="./intermediate-ca-chain.pem"
OPENSSL_X509_TXT="./intermediate-ca-cert.txt"
# Root CA paths (this assumes the root CA also uses `TLS_CERTS_PATH`)
ROOT_CA_SERIAL_ID=1000
ROOT_CA_DATABASE="./root-ca-database.txt"
ROOT_CA_SERIAL_TXT="./root-ca-serial.txt"
ROOT_CA_CONFIG_FILE="./root-ca.cnf"
ROOT_CA_PUBLIC_CERTIFICATE="./root-ca-cert.pem"

# 1. Make the key
rm -f "${PRIVATE_KEY}"  # In cases where we are regenerating
openssl genrsa \
  -out "${PRIVATE_KEY}" \
  4096
chmod 400 "${PRIVATE_KEY}"

# 2. Make the CSR
rm -f "${CSR}"  # Clean up from previous runs
openssl req \
  -config "${CONFIG_FILE}" \
  -key "${PRIVATE_KEY}" \
  -new \
  -sha256 \
  -out "${CSR}"

# 3. Create "temporary" files used by the CA for tracking certs
touch "${ROOT_CA_DATABASE}"
echo "${ROOT_CA_SERIAL_ID}" > "${ROOT_CA_SERIAL_TXT}"

# 4. "Submit" the CSR to the CA
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

# 5. Clean up files we won't keep
rm -f "./${ROOT_CA_SERIAL_ID}.pem"
rm -f "${CSR}"
rm -f "${ROOT_CA_DATABASE}"*
rm -f "${ROOT_CA_SERIAL_TXT}"*

# 6. Create auxiliary "chain" file to be used in CA bundles.
rm -f "${CERTIFICATE_CHAIN}"  # In cases where we are regenerating
cat "${PUBLIC_CERTIFICATE}" >> "${CERTIFICATE_CHAIN}"
cat "${ROOT_CA_PUBLIC_CERTIFICATE}" >> "${CERTIFICATE_CHAIN}"
chmod 444 "${CERTIFICATE_CHAIN}"

# 7. Generate the x509 text description
openssl x509 -noout -text -in "${PUBLIC_CERTIFICATE}" > "${OPENSSL_X509_TXT}"

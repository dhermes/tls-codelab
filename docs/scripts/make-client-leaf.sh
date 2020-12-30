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
PRIVATE_KEY="./localhost-client-key.pem"
rm -f "${PRIVATE_KEY}"  # In cases where we are regenerating
openssl genrsa \
  -out "${PRIVATE_KEY}" \
  2048
chmod 400 "${PRIVATE_KEY}"

# 2. Make the CSR
CSR="./localhost-client-csr.pem"
CONFIG_FILE="./localhost-client.cnf"
rm -f "${CSR}"  # Clean up from previous runs
openssl req \
  -config "${CONFIG_FILE}" \
  -key "${PRIVATE_KEY}" \
  -new \
  -sha256 \
  -out "${CSR}"

# 3. Create "temporary" files used by the intermediate CA for tracking certs
INTERMEDIATE_CA_SERIAL_ID=1000
INTERMEDIATE_CA_DATABASE="./intermediate-ca-database.txt"
INTERMEDIATE_CA_SERIAL_TXT="./intermediate-ca-serial.txt"
touch "${INTERMEDIATE_CA_DATABASE}"
echo "${INTERMEDIATE_CA_SERIAL_ID}" > "${INTERMEDIATE_CA_SERIAL_TXT}"

# 4. "Submit" the CSR to the CA
PUBLIC_CERTIFICATE="./localhost-client-cert.pem"
INTERMEDIATE_CA_CONFIG_FILE="./intermediate-ca.cnf"
rm -f "${PUBLIC_CERTIFICATE}"  # In cases where we are regenerating
openssl ca \
  -batch \
  -config "${INTERMEDIATE_CA_CONFIG_FILE}" \
  -extensions client_cert \
  -days 375 \
  -notext \
  -md sha256 \
  -in "${CSR}" \
  -out "${PUBLIC_CERTIFICATE}"
chmod 444 "${PUBLIC_CERTIFICATE}"

# 5. Clean up files we won't keep
rm -f "./${INTERMEDIATE_CA_SERIAL_ID}.pem"
rm -f "${CSR}"
rm -f "${INTERMEDIATE_CA_DATABASE}"*
rm -f "${INTERMEDIATE_CA_SERIAL_TXT}"*

# 6. Create auxiliary "chain" file to be used with client mTLS requests.
CERTIFICATE_CHAIN="./localhost-client-chain.pem"
INTERMEDIATE_CA_PUBLIC_CERTIFICATE="./intermediate-ca-cert.pem"
rm -f "${CERTIFICATE_CHAIN}"  # In cases where we are regenerating
cat "${PUBLIC_CERTIFICATE}" >> "${CERTIFICATE_CHAIN}"
cat "${INTERMEDIATE_CA_PUBLIC_CERTIFICATE}" >> "${CERTIFICATE_CHAIN}"
chmod 444 "${CERTIFICATE_CHAIN}"

# 7. Generate the x509 text description
OPENSSL_X509_TXT="./localhost-client-cert.txt"
openssl x509 -noout -text -in "${PUBLIC_CERTIFICATE}" > "${OPENSSL_X509_TXT}"

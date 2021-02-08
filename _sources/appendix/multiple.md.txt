# Keeping Around Two (or More) Root CAs

Luckily all of the scripts for generating private keys and certificates take
a generic `TLS_CERTS_PATH` argument. Unfortunately, these **assume** the
presence of `.cnf` configuration files for `openssl`. To address this,
we have created symlinks to those files in an alternate directory
and then pointed the scripts at that directory:

```
export TLS_CERTS_PATH=./docs/alternate-tls-certs

./docs/scripts/make-root-ca.sh
./docs/scripts/make-intermediate-ca.sh
./docs/scripts/make-server-leaf.sh
./docs/scripts/make-client-leaf.sh

unset TLS_CERTS_PATH
```

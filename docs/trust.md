# Trust

Backing up a bit, let's briefly discuss how trust and validation works. The
primary components critical to the TLS protocol are cryptographic proof
of private key ownership and CA signature as well as checking certificate
attributes like DNS SANs and Key Usages.

The whole goal of PKI (public key infrastructure) is for "everyone" to agree
on a small set of public CAs that "we" (i.e. the internet) all can trust.
For example, that small set is 164 system roots in Keychain Access for macOS
Big Sur and 138 `tls.rootCertificates` in the Mozilla bundle that ships with
Node.js 14.15.4.

## Why Intermediates?

Due to the **extreme** sensitivity of a trusted root and the long lifetimes,
it's standard practice for root CAs to be completely offline in a hardware
security module (HSM) and used in **very rare** occasions only to sign
intermediates. The intermediate CAs are the real workhorses that actually do
the signing of new leaf certificates (e.g. if as a customer you go on DigiCert
and request a certificate).

I like to joke that the CA private keys are buried somewhere under a pyramid
in Egypt.

## Revocation

As we go down a chain, each certificate can be trusted slightly less than the
one above it. To deal with potential leaks and key cracking, most CAs
provide revocation lists (CRL) and other more modern methods (OCSP) of checking
if a certificate remains valid.

```
            X509v3 CRL Distribution Points:

                Full Name:
                  URI:http://crl3.digicert.com/sha2-ha-server-g6.crl

                Full Name:
                  URI:http://crl4.digicert.com/sha2-ha-server-g6.crl

            X509v3 Certificate Policies:
                Policy: 2.16.840.1.114412.1.1
                  CPS: https://www.digicert.com/CPS
                Policy: 2.23.140.1.2.2

            Authority Information Access:
                OCSP - URI:http://ocsp.digicert.com
                CA Issuers - URI:http://cacerts.digicert.com/DigiCertSHA2HighAssuranceServerCA.crt
```

However, these recovation mechanisms **necessarily** (i.e. by design)
centralize an inherently decentralized infrastructue (PKI) and can cause
severe issues if not done well. For example, during an early release of
Big Sur on November 12, 2020, the `ocsp.apple.com` server collapsed under load
and the centralized revocation checks caused loading of **all** applications
to slow to a crawl on every macOS machine in the world.

## Accidental Vulnerabilities from PC Vendors

Sometimes PC vendors or antivirus software will install extra roots into the
system trust store. The **goal** of such an extra root is to allow tooling
(from the PC vendor or for the antivirus software) to intercept encrypted
TLS traffic and then proxy it back to the computer. This way, from the
perspective of applications on the computer, the traffic is still encrypted,
but the tools are able to decrypt it.

However, this is problematic when private keys leak or are exposed for these
system roots. Once an attacker has a private key for one of the trusted system
roots, the attacker can impersonate **any** website and the system will trust
any TLS connection as valid and encrypted.

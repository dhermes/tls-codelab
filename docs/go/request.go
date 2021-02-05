package main

import (
	"crypto/tls"
	"crypto/x509"
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
)

const (
	envVarRootCA        = "ROOT_CA"
	envVarMutualTLSCert = "MTLS_CERT"
	envVarMutualTLSKey  = "MTLS_KEY"
)

func getCertPool() (*x509.CertPool, error) {
	pool, err := x509.SystemCertPool()
	if err != nil {
		return nil, err
	}

	rootCA, ok := os.LookupEnv(envVarRootCA)
	if !ok {
		return pool, nil
	}

	pemBytes, err := ioutil.ReadFile(rootCA)
	if err != nil {
		return nil, err
	}

	ok = pool.AppendCertsFromPEM(pemBytes)
	if !ok {
		return nil, errors.New("Failed to append PEM bytes to cert pool")
	}

	return pool, nil
}

func getMutualTLSCertificates() ([]tls.Certificate, error) {
	certFile, okCert := os.LookupEnv(envVarMutualTLSCert)
	keyFile, okKey := os.LookupEnv(envVarMutualTLSKey)

	if okCert != okKey {
		err := fmt.Errorf(
			"The %q and %q environment variables must be specified together",
			envVarMutualTLSKey, envVarMutualTLSCert,
		)
		return nil, err
	}

	if !okCert {
		return nil, nil
	}

	cert, err := tls.LoadX509KeyPair(certFile, keyFile)
	if err != nil {
		return nil, err
	}

	return []tls.Certificate{cert}, nil
}

func run() error {
	pool, err := getCertPool()
	if err != nil {
		return err
	}

	certificates, err := getMutualTLSCertificates()
	if err != nil {
		return err
	}

	client := &http.Client{
		Transport: &http.Transport{
			TLSClientConfig: &tls.Config{
				RootCAs:      pool,
				Certificates: certificates,
			},
		},
	}
	resp, err := client.Get("https://localhost:8443")
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return err
	}

	fmt.Printf("Status Code: %d, Response: %q\n", resp.StatusCode, string(body))
	return nil
}

func main() {
	err := run()
	if err != nil {
		fmt.Fprintf(os.Stderr, "FAILURE: %v\n", err)
		os.Exit(1)
	}
}

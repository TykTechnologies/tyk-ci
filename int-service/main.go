package main

import (
	"crypto/tls"
	"crypto/x509"
	"flag"
	"io"
	"io/ioutil"
	"net/http"
	"path/filepath"

	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

func helloHandler(w http.ResponseWriter, r *http.Request) {
	io.WriteString(w, "Hello, world!")
	log.Info().Msg("Responded to /hello")
}

func main() {
	zerolog.TimeFieldFormat = zerolog.TimeFormatUnix

	certpath := flag.String("certpath", "certs", "Path to root, server certificate and key")
	flag.Parse()

	rootca := filepath.Join(*certpath, "rootca.pem")
	s_cert := filepath.Join(*certpath, "server.pem")
	s_key := filepath.Join(*certpath, "server-key.pem")

	caCert, err := ioutil.ReadFile(rootca)
	if err != nil {
		log.Fatal().Err(err).Msg("Could not find root CA certificate!")
	}
	caCertPool := x509.NewCertPool()
	caCertPool.AppendCertsFromPEM(caCert)
	tlsConfig := &tls.Config{
		ClientCAs:  caCertPool,
		ClientAuth: tls.RequireAndVerifyClientCert,
	}
	tlsConfig.BuildNameToCertificate()

	http.HandleFunc("/hello", helloHandler)

	server := &http.Server{
		Addr:      ":8443",
		TLSConfig: tlsConfig,
	}
	server.ListenAndServeTLS(s_cert, s_key)

	log.Fatal().Msg("Exiting")
}

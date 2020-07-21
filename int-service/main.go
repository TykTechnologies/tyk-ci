package main

import (
	"crypto/tls"
	"crypto/x509"
	"flag"
	"io"
	"io/ioutil"
	"net/http"

	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

func helloHandler(w http.ResponseWriter, r *http.Request) {
	io.WriteString(w, "Hello, world!")
	log.Info().Msg("Responded to /hello")
}

func main() {
	zerolog.TimeFieldFormat = zerolog.TimeFormatUnix

	rootca := flag.String("ca", "ca.pem", "Path to CA certificate")
	s_cert := flag.String("cert", "server.pem", "Path to server certificate")
	s_key := flag.String("key", "server-key.pem", "Path to server key")
	flag.Parse()

	caCert, err := ioutil.ReadFile(*rootca)
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
	server.ListenAndServeTLS(*s_cert, *s_key)

	log.Fatal().Msg("Exiting")
}

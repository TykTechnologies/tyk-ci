package main

import (
	"crypto/tls"
	"crypto/x509"
	"encoding/json"
	"flag"
	"io"
	"io/ioutil"
	"net/http"
	"strings"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/aws/external"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/ecr"
	"github.com/kelseyhightower/envconfig"
	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
)

// EnvConfig holds global environment variables
type EnvConfig struct {
	Repos      []string
	TableName  string
	RegistryID string
}

var e EnvConfig

func startHTTPSServer(ca *string, cert *string, key *string) {
	caCert, err := ioutil.ReadFile(*ca)
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

	server := &http.Server{
		Addr:      ":443",
		TLSConfig: tlsConfig,
	}
	log.Info().Msg("starting server")
	if err := server.ListenAndServeTLS(*cert, *key); err != nil && err != http.ErrServerClosed {
		log.Fatal().Err(err).Msg("Server startup failed")
	}
}

func healthCheckHandler(w http.ResponseWriter, r *http.Request) {
	io.WriteString(w, "200 OK")
	log.Debug().Msg("Healthcheck")
}

func loglevelHandler(w http.ResponseWriter, r *http.Request) {
	zerolog.SetGlobalLevel(zerolog.TraceLevel)
}

type newBuild struct {
	Repo string
	Ref  string
	Sha  string
}

// unexported globals
var cfg aws.Config

func newBuildHandler(w http.ResponseWriter, r *http.Request) {
	var req newBuild
	err := json.NewDecoder(r.Body).Decode(&req)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	log.Debug().Interface("Raw request", req)

	// Github sends a path like refs/.../integration/<ref that we want>
	ss := strings.Split(req.Ref, "/")
	req.Ref = ss[len(ss)-1]

	log.Debug().Interface("Parsed request", req)

	state, err := getEnvState(ecr.New(cfg), req.Ref, e.Repos)
	log.Debug().Interface("initial state", state)
	state[req.Repo] = req.Sha
	log.Debug().Interface("updated state", state)

	err = UpsertNewBuild(dynamodb.New(cfg), req.Ref, state)
	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	io.WriteString(w, "200 OK New build "+req.Ref)
}

func main() {
	err := envconfig.Process("gromit", &e)
	if err != nil {
		log.Fatal().Err(err)
	}
	log.Info().Interface("env", e).Msg("loaded env")

	rootca := flag.String("ca", "ca.pem", "Path to CA certificate")
	sCert := flag.String("cert", "server.pem", "Path to server certificate")
	sKey := flag.String("key", "server-key.pem", "Path to server key")
	flag.Parse()

	// Set global cfg
	cfg, err = external.LoadDefaultAWSConfig()
	if err != nil {
		log.Fatal().Err(err).Msg("unable to load SDK config")
	}

	http.HandleFunc("/healthcheck", healthCheckHandler)
	http.HandleFunc("/loglevel", loglevelHandler)
	http.HandleFunc("/newbuild", newBuildHandler)

	startHTTPSServer(rootca, sCert, sKey)
}

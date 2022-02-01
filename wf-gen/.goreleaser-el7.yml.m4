include(header.m4)
dnl xPKG_NAME is the package in which version.go lives
define(<<xPKG_NAME>>, <<ifelse(xREPO, <<tyk>>, <<github.com/TykTechnologies/tyk/gateway>>, xREPO, <<tyk-analytics>>, <<github.com/TykTechnologies/tyk-analytics/dashboard>>, xREPO, <<tyk-pump>>, <<github.com/TykTechnologies/tyk-pump/pumps>>, <<github.com/TykTechnologies/xREPO/main>>)>>)dnl
define(<<xPKG_DESC>>, <<ifelse(xREPO, <<tyk>>, <<Tyk API Gateway>>, xREPO, <<tyk-analytics>>, <<Dashboard for the Tyk API gateway>>, xREPO, <<tyk-pump>>, <<Archive analytics for the Tyk API gateway>>)>>)dnl
define(<<xPORTS>>, <<ifelse(xREPO, <<tyk>>, <<8080>>, xREPO, <<tyk-analytics>>, <<3000 5000>>, <<80>>)>>)dnl

# Check the documentation at http://goreleaser.com
# This project needs CGO_ENABLED=1 and the cross-compiler toolchains for
# - arm64
# - amd64

ifelse(xCGO, <<1>>, include(goreleaser/cgo-builds.m4), include(goreleaser/builds.m4))

include(goreleaser/nfpm.m4)
include(goreleaser/publishers.m4)

# This disables archives
archives:
  - format: binary
    allow_different_binary_count: true

include(goreleaser/docker.tyk-el7.m4)

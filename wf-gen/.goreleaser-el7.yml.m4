include(header.m4)

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

ifelse(xREPO, <<tyk>>,
dockers:
include(goreleaser/plugin-compiler.m4))

checksum:
  disable: true

release:
  disable: true
  github:
    owner: TykTechnologies
    name: xREPO
  prerelease: auto
  draft: true
  name_template: "{{.ProjectName}}-v{{.Version}}"

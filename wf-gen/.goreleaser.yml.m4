include(header.m4)
dnl xPKG_NAME is the package in which version.go lives
define(<<xPKG_NAME>>, <<ifelse(xREPO, <<tyk>>, <<gateway>>, xREPO, <<tyk-analytics>>, <<dashboard>>, xREPO, <<tyk-pump>>, <<main>>)>>)dnl
define(<<xPKG_DESC>>, <<ifelse(xREPO, <<tyk>>, <<Tyk API Gateway>>, xREPO, <<tyk-analytics>>, <<Dashboard for the Tyk API gateway>>, xREPO, <<tyk-pump>>, <<Archive analytics for the Tyk API gateway>>)>>)dnl
define(<<xPORTS>>, <<ifelse(xREPO, <<tyk>>, <<8080>>, xREPO, <<tyk-analytics>>, <<3000 5000>>, <<80>>)>>)dnl

# Check the documentation at http://goreleaser.com
# This project needs CGO_ENABLED=1 and the cross-compiler toolchains for
# - arm64
# - macOS (only 10.15 is supported)
# - amd64

include(goreleaser/builds.m4)


snapshot:
  name_template: 0.0.0-SNAPSHOT-{{ .ShortCommit }}

dockers:
include(goreleaser/docker.std.m4)
include(goreleaser/docker.slim.m4)
ifelse(xREPO, <<tyk>>, include(goreleaser/docker.tyk.m4))

include(goreleaser/nfpm.m4)

include(goreleaser/archives.m4)

checksum:
  disable: false

signs:
  - id: std
    artifacts: checksum

changelog:
  sort: asc
  filters:
    exclude:
    - '^utils:'
    - (?i)typo
    - 'Merge (pull request|branch)'
    - '\[CI\]'
    - '(?i)\[Buddy\]'
    - 'cherry picked'
    - '^rel-eng:'
    - '^minor:'

release:
  github:
    owner: TykTechnologies
    name: xREPO
  prerelease: auto
  draft: true
  name_template: "{{.ProjectName}}-v{{.Version}}"

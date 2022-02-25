include(header.m4)

# Check the documentation at http://goreleaser.com
# This project needs CGO_ENABLED=1 and the cross-compiler toolchains for
# - arm64
# - amd64

ifelse(xCGO, <<1>>, include(goreleaser/cgo-builds.m4), include(goreleaser/builds.m4))

dockers:
include(goreleaser/docker.std.m4)
include(goreleaser/docker.slim.m4)
ifelse(xREPO, <<tyk>>, include(goreleaser/docker.tyk.m4))
docker_manifests:
  - name_template: tykio/xDH_REPO:{{ .Tag }}
    image_templates:
    - tykio/xDH_REPO:{{ .Tag }}-amd64
    - tykio/xDH_REPO:{{ .Tag }}-arm64
  - name_template: tykio/xDH_REPO:v{{ .Major }}.{{ .Minor }}{{.Prerelease}}
    image_templates:
    - tykio/xDH_REPO:{{ .Tag }}-amd64
    - tykio/xDH_REPO:{{ .Tag }}-arm64
ifelse(xREPO, <<tyk>>, <<
  - name_template: tykio/tyk-hybrid-docker:{{ .Tag }}
    image_templates:
    - tykio/tyk-hybrid-docker:{{ .Tag }}-amd64
    - tykio/tyk-hybrid-docker:{{ .Tag }}-arm64
>>)

include(goreleaser/nfpm.m4)
include(goreleaser/publishers.m4)
include(goreleaser/archives.m4)

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

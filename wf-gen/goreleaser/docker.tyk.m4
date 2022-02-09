# Build gateway hybrid container amd64
- ids:
    - std
  image_templates:
    - "tykio/tyk-hybrid-docker:{{ .Tag }}-amd64"
  build_flag_templates:
    - "--platform=linux/amd64"
    - "--label=org.opencontainers.image.created={{.Date}}"
    - "--label=org.opencontainers.image.title={{.ProjectName}}-hybrid"
    - "--label=org.opencontainers.image.revision={{.FullCommit}}"
    - "--label=org.opencontainers.image.version={{.Version}}"
  use: buildx
  goarch: amd64
  goos: linux
  dockerfile: images/hybrid/Dockerfile
  extra_files:
    - "images/hybrid/"

# Build gateway hybrid container arm64
- ids:
    - std
  image_templates:
    - "tykio/tyk-hybrid-docker:{{ .Tag }}-arm64"
  build_flag_templates:
    - "--platform=linux/arm64"
    - "--label=org.opencontainers.image.created={{.Date}}"
    - "--label=org.opencontainers.image.title={{.ProjectName}}-hybrid"
    - "--label=org.opencontainers.image.revision={{.FullCommit}}"
    - "--label=org.opencontainers.image.version={{.Version}}"
  use: buildx
  goarch: arm64
  goos: linux
  dockerfile: images/hybrid/Dockerfile
  extra_files:
    - "images/hybrid/"

include(goreleaser/plugin-compiler.m4)

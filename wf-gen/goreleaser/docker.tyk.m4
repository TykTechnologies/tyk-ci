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
  use_buildx: true
  goarch: amd64
  goos: linux
  dockerfile: images/hybrid/Dockerfile
  skip_push: auto
  extra_files:
    - "images/hybrid/"
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
  use_buildx: true
  goarch: arm64
  goos: linux
  dockerfile: images/hybrid/Dockerfile
  skip_push: auto
  extra_files:
    - "images/hybrid/"
- ids:
    - std
  image_templates:
    - "tykio/tyk-plugin-compiler:{{ .Tag }}"
    - "tykio/tyk-plugin-compiler:v{{ .Major }}.{{ .Minor }}{{.Prerelease}}"
  build_flag_templates:
    - "--build-arg=TYK_GW_TAG={{ .Commit }}"
    - "--label=org.opencontainers.image.created={{.Date}}"
    - "--label=org.opencontainers.image.title=tyk-plugin-compiler"
    - "--label=org.opencontainers.image.revision={{.FullCommit}}"
    - "--label=org.opencontainers.image.version={{.Version}}"
  goarch: amd64
  goos: linux
  dockerfile: images/plugin-compiler/Dockerfile
  skip_push: auto
  extra_files:
    - "images/plugin-compiler/"

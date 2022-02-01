dnl The default EL7 suffix is nil, it is set on the command line when needed
define(xEL7_SUFFIX)dnl

# Build plugin-compiler
- ids:
    - std
  image_templates:
    - tykio/tyk-plugin-compiler:{{ .Tag }}xEL7_SUFFIX
    - "tykio/tyk-plugin-compiler:v{{ .Major }}.{{ .Minor }}{{.Prerelease}}xEL7_SUFFIX"
  build_flag_templates:
    - "--label=org.opencontainers.image.created={{.Date}}"
    - "--label=org.opencontainers.image.title=tyk-plugin-compiler"
    - "--label=org.opencontainers.image.revision={{.FullCommit}}"
    - "--label=org.opencontainers.image.version={{.Version}}"
    - "--build-arg=TYK_GW_TAG={{ .Tag }}"
    - "--build-arg=GOLANG_CROSS={{ .Env.GOLANG_CROSS }}"
  goarch: amd64
  goos: linux
  dockerfile: images/plugin-compiler/Dockerfile
  extra_files:
    - "images/plugin-compiler/"
    - "go.mod"

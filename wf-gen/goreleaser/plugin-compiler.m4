dnl The default EL7 suffix is nil, it is set on the command line when needed
define(xEL7_SUFFIX)dnl

# Build plugin-compiler amd64
- ids:
    - std
  image_templates:
    - tykio/tyk-plugin-compiler:{{ .Tag }}xEL7_SUFFIX-amd64
  build_flag_templates:
    - "--platform=linux/amd64"
    - "--label=org.opencontainers.image.created={{.Date}}"
    - "--label=org.opencontainers.image.title=tyk-plugin-compiler-amd64"
    - "--label=org.opencontainers.image.revision={{.FullCommit}}"
    - "--label=org.opencontainers.image.version={{.Version}}"
    - "--build-arg=TYK_GW_TAG={{ .Tag }}"
    - "--build-arg=GOLANG_CROSS={{ .Env.GOLANG_CROSS }}"
  goarch: amd64
  goos: linux
  dockerfile: ci/images/plugin-compiler/Dockerfile
  extra_files:
    - ci/images/plugin-compiler
    - go.mod
    - apidef
    - certs
    - checkup
    - cli
    - config
    - coprocess
    - ctx
    - dlpython
    - dnscache
    - gateway
    - goplugin
    - headers
    - log
    - regexp
    - request
    - rpc
    - signature_validator
    - storage
    - tcp
    - templates
    - test
    - testdata
    - trace
    - user

# Build plugin-compiler arm64
- ids:
    - std
  image_templates:
    - tykio/tyk-plugin-compiler:{{ .Tag }}xEL7_SUFFIX-arm64
  build_flag_templates:
    - "--platform=linux/arm64"
    - "--label=org.opencontainers.image.created={{.Date}}"
    - "--label=org.opencontainers.image.title=tyk-plugin-compiler-arm64"
    - "--label=org.opencontainers.image.revision={{.FullCommit}}"
    - "--label=org.opencontainers.image.version={{.Version}}"
    - "--build-arg=TYK_GW_TAG={{ .Tag }}"
    - "--build-arg=GOLANG_CROSS={{ .Env.GOLANG_CROSS }}"
  goarch: arm64
  goos: linux
  dockerfile: ci/images/plugin-compiler/Dockerfile
  extra_files:
    - ci/images/plugin-compiler
    - go.mod
    - apidef
    - certs
    - checkup
    - cli
    - config
    - coprocess
    - ctx
    - dlpython
    - dnscache
    - gateway
    - goplugin
    - headers
    - log
    - regexp
    - request
    - rpc
    - signature_validator
    - storage
    - tcp
    - templates
    - test
    - testdata
    - trace
    - user

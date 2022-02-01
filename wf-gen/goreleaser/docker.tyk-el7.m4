dockers:
# Build plugin-compiler
- ids:
    - std
  image_templates:
    - tykio/tyk-plugin-compiler:{{ .Tag }}-el7
    - "tykio/tyk-plugin-compiler:v{{ .Major }}.{{ .Minor }}{{.Prerelease}}"
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
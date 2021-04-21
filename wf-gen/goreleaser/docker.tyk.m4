- ids:
    - std
  image_templates:
    - "tykio/tyk-hybrid-docker:{{ .Tag }}"
    - "tykio/tyk-hybrid-docker:v{{ .Major }}.{{ .Minor }}"
  build_flag_templates:
    - "--label=org.opencontainers.image.created={{.Date}}"
    - "--label=org.opencontainers.image.title={{.ProjectName}}-hybrid"
    - "--label=org.opencontainers.image.revision={{.FullCommit}}"
    - "--label=org.opencontainers.image.version={{.Version}}"
  goarch: amd64
  goos: linux
  dockerfile: images/hybrid/Dockerfile
  skip_push: auto
  extra_files:
    - "images/hybrid/"
- ids:
    - std
  image_templates:
    - "{{ .Env.CI_REGISTRY }}/tyk-plugin-compiler:{{ .Env.CI_TAG }}"
    - "tykio/tyk-plugin-compiler:{{ .Tag }}"
    - "tykio/tyk-plugin-compiler:v{{ .Major }}.{{ .Minor }}"
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

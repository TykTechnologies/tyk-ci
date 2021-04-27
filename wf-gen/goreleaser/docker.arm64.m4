- ids:
    - std
  image_templates:
    - "tykio/xDH_REPO:{{ .Tag }}"
    - "tykio/xDH_REPO:v{{ .Major }}.{{ .Minor }}"
    - "docker.tyk.io/xCOMPATIBILITY_NAME/xCOMPATIBILITY_NAME:v{{ .Major }}.{{ .Minor }}"
    - "docker.tyk.io/xCOMPATIBILITY_NAME/xCOMPATIBILITY_NAME:{{ .Tag }}"
  build_flag_templates:
    - "--build-arg=PORTS=xPORTS"
    - "--platform=linux/arm64"
    - "--label=org.opencontainers.image.created={{.Date}}"
    - "--label=org.opencontainers.image.title={{.ProjectName}}-arm64"
    - "--label=org.opencontainers.image.revision={{.FullCommit}}"
    - "--label=org.opencontainers.image.version={{.Version}}"
  use_buildx: true
  goarch: arm64
  goos: linux
  dockerfile: Dockerfile.std
  skip_push: auto
  extra_files:
    - "install/"
    - "README.md"
ifelse(xREPO, <<tyk-analytics>>,<<
    - "EULA.md"
    - "portal"
    - "schemas"
    - "webclient/lang"
    - "tyk_config_sample.config"
>>, xREPO, <<tyk>>,<<
    - "LICENSE.md"
    - "apps/app_sample.json"
    - "templates"
    - "middleware"
    - "event_handlers/sample"
    - "policies"
    - "coprocess"
    - "tyk.conf.example"
>>, xREPO, <<tyk-pump>>,<<
    - "LICENSE.md"
    - "pump.example.conf"
>>)dnl

- ids:
    - std
  image_templates:
    - "tykio/xDH_REPO:{{ .Tag }}-amd64"
    - "docker.tyk.io/xCOMPATIBILITY_NAME/xCOMPATIBILITY_NAME:{{ .Tag }}-amd64"
  build_flag_templates:
    - "--build-arg=PORTS=xPORTS"
    - "--platform=linux/amd64"
    - "--label=org.opencontainers.image.created={{.Date}}"
    - "--label=org.opencontainers.image.title={{.ProjectName}}"
    - "--label=org.opencontainers.image.revision={{.FullCommit}}"
    - "--label=org.opencontainers.image.version={{.Version}}"
  use_buildx: true
  goarch: amd64
  goos: linux
  dockerfile: Dockerfile.std
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

- ids:
    - std
  image_templates:
    - "tykio/xDH_REPO:{{ .Tag }}-arm64"
    - "docker.tyk.io/xCOMPATIBILITY_NAME/xCOMPATIBILITY_NAME:{{ .Tag }}-arm64"
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

# Build tykio/xDH_REPO, cloudsmith/xCOMPATIBILITY_NAME (amd64)
- ids:
    - std
  image_templates:
    - "tykio/xDH_REPO:{{ .Tag }}-amd64"
ifelse(xREPO,<<portal>>,<<>>,<<dnl
    - "docker.tyk.io/xCOMPATIBILITY_NAME/xCOMPATIBILITY_NAME:{{ .Tag }}"
>>)dnl
  build_flag_templates:
    - "--build-arg=PORTS=xPORTS"
    - "--platform=linux/amd64"
    - "--label=org.opencontainers.image.created={{.Date}}"
    - "--label=org.opencontainers.image.title={{.ProjectName}}"
    - "--label=org.opencontainers.image.revision={{.FullCommit}}"
    - "--label=org.opencontainers.image.version={{.Version}}"
  use: buildx
  goarch: amd64
  goos: linux
  dockerfile: ci/Dockerfile.std
  extra_files:
    - "ci/install/"
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

# Build tykio/xDH_REPO, cloudsmith/xCOMPATIBILITY_NAME (arm64)
- ids:
    - std
  image_templates:
    - "tykio/xDH_REPO:{{ .Tag }}-arm64"
ifelse(xREPO,<<portal>>,<<>>,<<dnl
    - "docker.tyk.io/xCOMPATIBILITY_NAME/xCOMPATIBILITY_NAME:{{ .Tag }}-arm64"
>>)dnl
  build_flag_templates:
    - "--build-arg=PORTS=xPORTS"
    - "--platform=linux/arm64"
    - "--label=org.opencontainers.image.created={{.Date}}"
    - "--label=org.opencontainers.image.title={{.ProjectName}}-arm64"
    - "--label=org.opencontainers.image.revision={{.FullCommit}}"
    - "--label=org.opencontainers.image.version={{.Version}}"
  use: buildx
  goarch: arm64
  goos: linux
  dockerfile: ci/Dockerfile.std
  extra_files:
    - "ci/install/"
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

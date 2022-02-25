- ids:
    - static-amd64
  image_templates:
    - "tykio/xDH_REPO:s{{ .Version }}"
    - "tykio/xDH_REPO:s{{ .Major }}.{{ .Minor }}"
    - "docker.tyk.io/xCOMPATIBILITY_NAME/xCOMPATIBILITY_NAME:s{{ .Version }}"
    - "docker.tyk.io/xCOMPATIBILITY_NAME/xCOMPATIBILITY_NAME:s{{ .Major }}.{{ .Minor }}"
  build_flag_templates:
    - "--build-arg=PORTS=xPORTS"
    - "--label=org.opencontainers.image.created={{.Date}}"
    - "--label=org.opencontainers.image.title={{.ProjectName}}-slim"
    - "--label=org.opencontainers.image.revision={{.FullCommit}}"
    - "--label=org.opencontainers.image.version={{.Version}}"
  goarch: amd64
  goos: linux
  dockerfile: ci/Dockerfile.slim
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

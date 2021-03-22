- ids:
    - std
  image_templates:
    - "tykio/xDH_REPO:{{ .Tag }}"
    - "tykio/xDH_REPO:v{{ .Major }}.{{ .Minor }}"
    - "docker.cloudsmith.io/tyk/xCOMPATIBILITY_NAME/xCOMPATIBILITY_NAME:{{ .Tag }}"
    - "docker.cloudsmith.io/tyk/xCOMPATIBILITY_NAME/xCOMPATIBILITY_NAME:v{{ .Major }}.{{ .Minor }}"
  build_flag_templates:
    - "--build-arg=PORTS=xPORTS"
    - "--label=org.opencontainers.image.created={{.Date}}"
    - "--label=org.opencontainers.image.title={{.ProjectName}}"
    - "--label=org.opencontainers.image.revision={{.FullCommit}}"
    - "--label=org.opencontainers.image.version={{.Version}}"
  goarch: amd64
  goos: linux
  dockerfile: Dockerfile.std
  skip_push: auto
  extra_files:
    - "install/data"
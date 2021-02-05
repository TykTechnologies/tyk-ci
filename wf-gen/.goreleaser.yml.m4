include(header.m4)
dnl xPKG_NAME is the package in which version.go lives
define(<<xPKG_NAME>>, <<ifelse(xREPO, <<tyk>>, <<gateway>>, xREPO, <<tyk-analytics>>, <<dashboard>>, xREPO, <<tyk-pump>>, <<main>>)>>)dnl
define(<<xPKG_DESC>>, <<ifelse(xREPO, <<tyk>>, <<Tyk API Gateway>>, xREPO, <<tyk-analytics>>, <<Dashboard for the Tyk API gateway>>, xREPO, <<tyk-pump>>, <<Archive analytics for the Tyk API gateway>>)>>)dnl
define(<<xPORTS>>, <<ifelse(xREPO, <<tyk>>, <<8080>>, xREPO, <<tyk-analytics>>, <<3000 5000>>, xREPO)>>)dnl

# Check the documentation at http://goreleaser.com
# This project needs CGO_ENABLED=1 and the cross-compiler toolchains for
# - arm64
# - macOS (only 10.15 is supported)
# - amd64

builds:
  - id: std-linux
    ldflags:
      - -X xPKG_NAME.VERSION={{.Version}} -X xPKG_NAME.commit={{.Commit}} -X xPKG_NAME.buildDate={{.Date}} -X xPKG_NAME.builtBy=goreleaser
    goos:
      - linux
    goarch:
      - amd64
  - id: std-darwin
    ldflags:
      - -X xPKG_NAME.VERSION={{.Version}} -X xPKG_NAME.commit={{.Commit}} -X xPKG_NAME.buildDate={{.Date}} -X xPKG_NAME.builtBy=goreleaser
    env:
      - CC=o64-clang
    goos:
      - darwin
    goarch:
      - amd64
  - id: std-arm64
    ldflags:
      - -X xPKG_NAME.VERSION={{.Version}} -X xPKG_NAME.commit={{.Commit}} -X xPKG_NAME.buildDate={{.Date}} -X xPKG_NAME.builtBy=goreleaser
    env:
      - CC=aarch64-linux-gnu-gcc
    goos:
      - linux
    goarch:
      - arm64
  # static builds strip symbols and do not allow plugins
  - id: static-amd64
    ldflags:
      - -s -w -X xPKG_NAME.VERSION={{.Version}} -X xPKG_NAME.commit={{.Commit}} -X xPKG_NAME.buildDate={{.Date}} -X xPKG_NAME.builtBy=goreleaser
      - -linkmode external -extldflags -static
    goos:
      - linux
    goarch:
      - amd64
ifelse(xREPO, <<tyk-analytics>>, <<
  # With special license pubkey
  - id: payg
    flags:
      - -v
      - -x
    ldflags:
      - -s -w -X xPKG_NAME.VERSION={{.Version}} -X xPKG_NAME.commit={{.Commit}} -X xPKG_NAME.buildDate={{.Date}} -X xPKG_NAME.builtBy=goreleaser
      - "-X 'main.pk=-----BEGIN PUBLIC KEY-----MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAtbfq5KSbK2+fvcZ36RxuWI2uRpG+nfoOs6WlhBkkzYQ6MNVijrr08yjjZutaScK1svc2gr+Atu3P+c92ov0hr1AUBg7vXIp96E+8wX58rWzrsKkBI+0nO0UlKjyAXzQiNpBvHDdJem5jltRxrCa0wy18rPnJNuLtXmyN9FHBWCZ8bvK8RshaBIbuqIm+QeOY9FVhKs+ZAAy0f2jI5DMh1CaGAHi7TjGcm5JIO1NeK3AaMMHn+cKUQ8pnY9/vGhO86BCgsW8cyvuwbsOzB3R7Dbjx1mqCUKlS9vc9vttq7DmUejiewkH6fVaP6bSp1pRE2AQ8yFSKhsUZqOJ/HxUaIeyx3hFj0qhwf0vvmWxswdN/ugtUdRdTGvWrGIY9diGDyOw7NHARvD7a9NMPOR+McIrBvCTOebZp/58zNZ9MBYPPPcNI75+fY9LA1BNXwA+ffGhik22gUH6v7lszUAe+pVHbYUMf/kuv2f45QXwKG2qJqmgsqvL9xwy8BkY74t9mDGSLHmWoX59Tb9sCvj6bwxg5OwGDWI2O68cNEmaZOwd2Hj1gJU8MsnHbPqvJXJ65Cc4GLpLHIPhlkwHdBUtxg+Wjnz2TGOOl2ihT1eA3jPQArz98TU028XlMqXH34Na7z0oM7vAtUzTnl+9cQI/9n9aIjARXrSl5gtk4UfACIDUCAwEAAQ==-----END PUBLIC KEY-----'"
    goos:
      - linux
    goarch:
      - amd64
>>)

dockers:
  - ids:
      - std-linux
    image_templates:
      - "tykio/xCOMPATIBILITY_NAME:{{ .Tag }}"
      - "tykio/xCOMPATIBILITY_NAME:v{{ .Major }}.{{ .Minor }}"
      - {{ .Env.ECR_REGISTRY }}:xREPO:{{ .Branch }}
      - {{ .Env.ECR_REGISTRY }}:xREPO:{{ .Commit }}
      - {{ .Env.ECR_REGISTRY }}:xREPO:latest
    build_flag_templates:
      - "--build-arg BASE_IMAGE=debian:buster-slim TARBALL={{.ArtifactPath}} PORTS=xPORTS"
      - "--label=org.opencontainers.image.created={{.Date}}"
      - "--label=org.opencontainers.image.title={{.ProjectName}}"
      - "--label=org.opencontainers.image.revision={{.FullCommit}}"
      - "--label=org.opencontainers.image.version={{.Version}}"
    goarch: amd64
    goos: linux
    dockerfile: Dockerfile
    extra_files:
      - "tyk_config_sample.config"
      - "portal"
      - "schemas"
      - "webclient/lang"
  - ids:
      - static-amd64
    image_templates:
      - "tykio/xCOMPATIBILITY_NAME:slim"
      - "tykio/xCOMPATIBILITY_NAME:s{{ .Major }}.{{ .Minor }}"
    build_flag_templates:
      - "--build-arg BASE_IMAGE=gcr.io/distroless/static-debian10 TARBALL={{.ArtifactPath}} PORTS=xPORTS"
      - "--label=org.opencontainers.image.created={{.Date}}"
      - "--label=org.opencontainers.image.title={{.ProjectName}}-slim"
      - "--label=org.opencontainers.image.revision={{.FullCommit}}"
      - "--label=org.opencontainers.image.version={{.Version}}"
    goarch: amd64
    goos: linux
    dockerfile: Dockerfile
    extra_files:
      - "tyk_config_sample.config"
      - "portal"
      - "schemas"
      - "webclient/lang"

nfpms:
  - id: std
    vendor: "Tyk Technologies Ltd"
    homepage: "https://tyk.io"
    maintainer: "Tyk <info@tyk.io>"
    description: xPKG_DESC
    builds:
      - std-linux
      - std-arm64
    formats:
      - deb
      - rpm
    contents:
      - src: "README*"
        dst: "/opt/xREPO/"
ifelse(xREPO, <<tyk-analytics>>,
<<      - src: "EULA.md"
        dst: "/opt/xREPO"
      - src: "portal/*"
        dst: "/opt/xREPO/portal"
      - src: "schemas/*"
        dst: "/opt/xREPO/schemas"
      - src: "webclient/lang/*"
        dst: "/opt/xREPO/lang"
      - src: "install/inits/*"
        dst: "/opt/xREPO/install/inits"
      - src: tyk_config_sample.config
        dst: /opt/xREPO/tyk_analytics.conf
        type: "config|noreplace"
>>, xREPO, <<tyk>>,
<<      - src: "LICENSE.md"
        dst: "/opt/xREPO"
      - src: "apps/app_sample.json"
        dst: "/opt/xREPO/apps"
      - src: "templates/*.json"
        dst: "/opt/xREPO/templates"
      - src: "install/*"
        dst: "/opt/xREPO/install"
      - src: "middleware/*.js"
        dst: "/opt/xREPO/middleware"
      - src: "event_handlers/sample/*.js"
        dst: "/opt/xREPO/event_handlers/sample"
      - src: "policies/*.json"
        dst: "/opt/xREPO/policies"
      - src: "coprocess/*"
        dst: "/opt/xREPO/coprocess"
      - src: tyk.conf.example
        dst: /opt/xREPO/tyk.conf
        type: "config|noreplace"
>>, xREPO, <<tyk-pump>>,
<<      - src: "EULA.md"
        dst: "/opt/xREPO"
      - src: "install/*"
        dst: "/opt/xREPO/install"
      - src: pump.example.conf
        dst: /opt/xREPO/pump.conf
        type: "config|noreplace"
>>)dnl
    scripts:
      preinstall: "install/before_install.sh"
      postinstall: "install/post_install.sh"
      postremove: "install/post_remove.sh"
    bindir: "/opt/xCOMPATIBILITY_NAME"
    overrides:
      rpm:
        replacements:
          amd64: x86_64
          arm: aarch64
      deb:
        replacements:
          arm: arm64
    rpm:
      signature:
        key_file: tyk.io.signing.key
    deb:
      signature:
        key_file: tyk.io.signing.key
        type: origin
ifelse(xREPO, <<tyk-analytics>>, <<
  - id: payg
    vendor: "Tyk Technologies Ltd"
    homepage: "https://tyk.io"
    maintainer: "Tyk <info@tyk.io>"
    description: "PAYG Dashboard for the Tyk API Gateway"
    file_name_template: "{{ .ProjectName }}_PAYG_{{ .Version }}_{{ .Os }}_{{ .Arch }}"
    builds:
      - payg
    formats:
      - rpm
    contents:
      - src: "README*"
        dst: "/opt/xREPO/"
      - src: "EULA.md"
        dst: "/opt/xREPO"
      - src: "portal/*"
        dst: "/opt/xREPO/portal"
      - src: "schemas/*"
        dst: "/opt/xREPO/schemas"
      - src: "webclient/lang/*"
        dst: "/opt/xREPO/lang"
      - src: "install/inits/*"
        dst: "/opt/xREPO/install/inits"
      - src: tyk_config_sample.config
        dst: /opt/xREPO/tyk_analytics.conf
        type: "config|noreplace"
    scripts:
      preinstall: "install/before_install.sh"
      postinstall: "install/post_install.sh"
      postremove: "install/post_remove.sh"
    bindir: "/opt/xCOMPATIBILITY_NAME"
    rpm:
      signature:
        key_file: tyk.io.signing.key
>>)

archives:
- id: std-linux
  builds:
    - std-linux
  files:
    - README.md
    - CHANGELOG.md
ifelse(xREPO, <<tyk-analytics>>,
<<    - EULA.md
    - portal/*
    - schemas/*
    - lang/*
    - tyk_config_sample.config
>>, xREPO, <<tyk>>,
<<    - "LICENSE.md"
    - "apps/app_sample.json"
    - "templates/*.json"
    - "install/*"
    - "middleware/*.js"
    - "event_handlers/sample/*.js"
    - "policies/*.json"
    - "coprocess/*"
    - tyk.conf.example
>>, xREPO, <<tyk-pump>>,
<<    - "EULA.md"
    - "install/*"
    - pump.example.conf
>>)
- id: std-arm64
  builds:
    - std-arm64
  files:
    - README.md
    - CHANGELOG.md
ifelse(xREPO, <<tyk-analytics>>,
<<    - EULA.md
    - portal/*
    - schemas/*
    - lang/*
    - tyk_config_sample.config
>>, xREPO, <<tyk>>,
<<    - "LICENSE.md"
    - "apps/app_sample.json"
    - "templates/*.json"
    - "install/*"
    - "middleware/*.js"
    - "event_handlers/sample/*.js"
    - "policies/*.json"
    - "coprocess/*"
    - tyk.conf.example
>>, xREPO, <<tyk-pump>>,
<<    - "EULA.md"
    - "install/*"
    - pump.example.conf
>>)dnl

- id: static-amd64
  name_template: "{{ .ProjectName }}_{{ .Version }}_static_{{ .Os }}_{{ .Arch }}"
  builds:
    - static-amd64
  files:
    - README.md
    - CHANGELOG.md
ifelse(xREPO, <<tyk-analytics>>,
<<    - EULA.md
    - portal/*
    - schemas/*
    - lang/*
>>, xREPO, <<tyk>>,
<<    - "LICENSE.md"
    - "apps/app_sample.json"
    - "templates/*.json"
    - "install/*"
    - "middleware/*.js"
    - "event_handlers/sample/*.js"
    - "policies/*.json"
    - "coprocess/*"
    - tyk.conf.example
>>, xREPO, <<tyk-pump>>,
<<    - "EULA.md"
    - "install/*"
    - pump.example.conf
>>)

checksum:
  disable: false

signs:
  - id: std
    artifacts: checksum

changelog:
  sort: asc
  filters:
    exclude:
    - '^utils:'
    - (?i)typo
    - 'Merge (pull request|branch)'

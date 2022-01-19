env:
  - MAIN_PKG_GOPATH=github.com/TykTechnologies/xREPO/xPKG_NAME

builds:
  - id: std
    ldflags:
      - -X {{ .Env.MAIN_PKG_GOPATH }}.VERSION={{.Version}} -X {{ .Env.MAIN_PKG_GOPATH }}.commit={{.FullCommit}} -X {{ .Env.MAIN_PKG_GOPATH }}.buildDate={{.Date}} -X {{ .Env.MAIN_PKG_GOPATH }}.builtBy=goreleaser
    goos:
      - linux
      - darwin
    goarch:
      - amd64
      - arm64
  # static builds strip symbols and do not allow plugins
  - id: static-amd64
    ldflags:
      - -s -w -X {{ .Env.MAIN_PKG_GOPATH }}.VERSION={{.Version}} -X {{ .Env.MAIN_PKG_GOPATH }}.commit={{.FullCommit}} -X {{ .Env.MAIN_PKG_GOPATH }}.buildDate={{.Date}} -X {{ .Env.MAIN_PKG_GOPATH }}.builtBy=goreleaser
    goos:
      - linux
    goarch:
      - amd64

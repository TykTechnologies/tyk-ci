
builds:
  - id: std
    ldflags:
      - -X xPKG_NAME.VERSION={{.Version}} -X xPKG_NAME.commit={{.FullCommit}} -X xPKG_NAME.buildDate={{.Date}} -X xPKG_NAME.builtBy=goreleaser
    goos:
      - linux
      - darwin
    goarch:
      - amd64
      - arm64
  # static builds strip symbols and do not allow plugins
  - id: static-amd64
    ldflags:
      - -s -w -X xPKG_NAME.VERSION={{.Version}} -X xPKG_NAME.commit={{.FullCommit}} -X xPKG_NAME.buildDate={{.Date}} -X xPKG_NAME.builtBy=goreleaser
    goos:
      - linux
    goarch:
      - amd64

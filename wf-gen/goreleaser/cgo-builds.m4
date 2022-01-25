
builds:
  - id: std-linux
ifelse(xREPO, <<tyk>>, <<
    flags:
      - -tags=goplugin
>>)dnl
    ldflags:
      - -X xPKG_NAME.VERSION={{.Version}} -X xPKG_NAME.commit={{.FullCommit}} -X xPKG_NAME.buildDate={{.Date}} -X xPKG_NAME.builtBy=goreleaser
    goos:
      - linux
    goarch:
      - amd64
    binary: xBINARY
  - id: std-darwin
    ldflags:
      - -X xPKG_NAME.VERSION={{.Version}} -X xPKG_NAME.commit={{.FullCommit}} -X xPKG_NAME.buildDate={{.Date}} -X xPKG_NAME.builtBy=goreleaser
    env:
      - CC=o64-clang
    goos:
      - darwin
    goarch:
      - amd64
    binary: xBINARY
  - id: std-arm64
ifelse(xREPO, <<tyk>>, <<
    flags:
      - -tags=goplugin
>>)dnl
    ldflags:
      - -X xPKG_NAME.VERSION={{.Version}} -X xPKG_NAME.commit={{.FullCommit}} -X xPKG_NAME.buildDate={{.Date}} -X xPKG_NAME.builtBy=goreleaser
    env:
      - CC=aarch64-linux-gnu-gcc
    goos:
      - linux
    goarch:
      - arm64
    binary: xBINARY
  # static builds strip symbols and do not allow plugins
  - id: static-amd64
    ldflags:
      - -s -w -X xPKG_NAME.VERSION={{.Version}} -X xPKG_NAME.commit={{.FullCommit}} -X xPKG_NAME.buildDate={{.Date}} -X xPKG_NAME.builtBy=goreleaser
      - -linkmode external -extldflags -static
    goos:
      - linux
    goarch:
      - amd64
    binary: xBINARY
ifelse(xREPO, <<tyk-analytics>>, <<
  # With special license pubkey
  - id: payg
    flags:
      - -v
      - -x
    ldflags:
      - -s -w -X xPKG_NAME.VERSION={{.Version}} -X xPKG_NAME.commit={{.FullCommit}} -X xPKG_NAME.buildDate={{.Date}} -X xPKG_NAME.builtBy=goreleaser
      - "-X 'main.pk=-----BEGIN PUBLIC KEY-----MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAtbfq5KSbK2+fvcZ36RxuWI2uRpG+nfoOs6WlhBkkzYQ6MNVijrr08yjjZutaScK1svc2gr+Atu3P+c92ov0hr1AUBg7vXIp96E+8wX58rWzrsKkBI+0nO0UlKjyAXzQiNpBvHDdJem5jltRxrCa0wy18rPnJNuLtXmyN9FHBWCZ8bvK8RshaBIbuqIm+QeOY9FVhKs+ZAAy0f2jI5DMh1CaGAHi7TjGcm5JIO1NeK3AaMMHn+cKUQ8pnY9/vGhO86BCgsW8cyvuwbsOzB3R7Dbjx1mqCUKlS9vc9vttq7DmUejiewkH6fVaP6bSp1pRE2AQ8yFSKhsUZqOJ/HxUaIeyx3hFj0qhwf0vvmWxswdN/ugtUdRdTGvWrGIY9diGDyOw7NHARvD7a9NMPOR+McIrBvCTOebZp/58zNZ9MBYPPPcNI75+fY9LA1BNXwA+ffGhik22gUH6v7lszUAe+pVHbYUMf/kuv2f45QXwKG2qJqmgsqvL9xwy8BkY74t9mDGSLHmWoX59Tb9sCvj6bwxg5OwGDWI2O68cNEmaZOwd2Hj1gJU8MsnHbPqvJXJ65Cc4GLpLHIPhlkwHdBUtxg+Wjnz2TGOOl2ihT1eA3jPQArz98TU028XlMqXH34Na7z0oM7vAtUzTnl+9cQI/9n9aIjARXrSl5gtk4UfACIDUCAwEAAQ==-----END PUBLIC KEY-----'"
    goos:
      - linux
    goarch:
      - amd64
>>)

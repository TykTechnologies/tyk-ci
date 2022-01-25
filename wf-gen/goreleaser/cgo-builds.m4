builds:
  - id: std-linux
ifelse(xREPO, <<tyk>>, <<
    flags:
      - -tags=goplugin
>>)dnl
    ldflags:
      - -X xPKG_NAME.VERSION={{.Version}} -X xPKG_NAME.Commit={{.FullCommit}} -X xPKG_NAME.buildDate={{.Date}} -X xPKG_NAME.builtBy=goreleaser
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
      - -X xPKG_NAME.VERSION={{.Version}} -X xPKG_NAME.Commit={{.FullCommit}} -X xPKG_NAME.buildDate={{.Date}} -X xPKG_NAME.builtBy=goreleaser
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
      - -s -w -X xPKG_NAME.VERSION={{.Version}} -X xPKG_NAME.Commit={{.FullCommit}} -X xPKG_NAME.buildDate={{.Date}} -X xPKG_NAME.builtBy=goreleaser
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
      - -s -w -X xPKG_NAME.VERSION={{.Version}} -X xPKG_NAME.Commit={{.FullCommit}} -X xPKG_NAME.buildDate={{.Date}} -X xPKG_NAME.builtBy=goreleaser
      - "-X 'xPKG_NAME.pk=LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUlJQ0lqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FnOEFNSUlDQ2dLQ0FnRUF0YmZxNUtTYksyK2Z2Y1ozNlJ4dQpXSTJ1UnBHK25mb09zNldsaEJra3pZUTZNTlZpanJyMDh5ampadXRhU2NLMXN2YzJncitBdHUzUCtjOTJvdjBoCnIxQVVCZzd2WElwOTZFKzh3WDU4cld6cnNLa0JJKzBuTzBVbEtqeUFYelFpTnBCdkhEZEplbTVqbHRSeHJDYTAKd3kxOHJQbkpOdUx0WG15TjlGSEJXQ1o4YnZLOFJzaGFCSWJ1cUltK1FlT1k5RlZoS3MrWkFBeTBmMmpJNURNaAoxQ2FHQUhpN1RqR2NtNUpJTzFOZUszQWFNTUhuK2NLVVE4cG5ZOS92R2hPODZCQ2dzVzhjeXZ1d2JzT3pCM1I3CkRiangxbXFDVUtsUzl2Yzl2dHRxN0RtVWVqaWV3a0g2ZlZhUDZiU3AxcFJFMkFROHlGU0toc1VacU9KL0h4VWEKSWV5eDNoRmowcWh3ZjB2dm1XeHN3ZE4vdWd0VWRSZFRHdldyR0lZOWRpR0R5T3c3TkhBUnZEN2E5Tk1QT1IrTQpjSXJCdkNUT2ViWnAvNTh6Tlo5TUJZUFBQY05JNzUrZlk5TEExQk5Yd0ErZmZHaGlrMjJnVUg2djdsc3pVQWUrCnBWSGJZVU1mL2t1djJmNDVRWHdLRzJxSnFtZ3Nxdkw5eHd5OEJrWTc0dDltREdTTEhtV29YNTlUYjlzQ3ZqNmIKd3hnNU93R0RXSTJPNjhjTkVtYVpPd2QySGoxZ0pVOE1zbkhiUHF2SlhKNjVDYzRHTHBMSElQaGxrd0hkQlV0eApnK1dqbnoyVEdPT2wyaWhUMWVBM2pQUUFyejk4VFUwMjhYbE1xWEgzNE5hN3owb003dkF0VXpUbmwrOWNRSS85Cm45YUlqQVJYclNsNWd0azRVZkFDSURVQ0F3RUFBUT09Ci0tLS0tRU5EIFBVQkxJQyBLRVktLS0tLQo='"
    goos:
      - linux
    goarch:
      - amd64
>>)

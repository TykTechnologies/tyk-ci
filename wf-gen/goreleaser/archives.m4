archives:
- id: std-linux
  builds:
ifelse(xCGO, <<1>>,<<
    - std-linux
    - std-darwin
    - std-arm64
>>, <<
    - std
>>)dnl
  files:
    - README.md
    - "install/*"
ifelse(xREPO, <<tyk-analytics>>,
<<    - EULA.md
    - CHANGELOG.md
    - portal/*
    - schemas/*
    - lang/*
    - tyk_config_sample.config
>>, xREPO, <<tyk>>,
<<    - "LICENSE.md"
    - "apps/app_sample.json"
    - "templates/*.json"
    - "templates/playground/index.html"
    - "templates/playground/playground.js"
    - "middleware/*.js"
    - "event_handlers/sample/*.js"
    - "policies/*.json"
    - "coprocess/*"
    - tyk.conf.example
>>, xREPO, <<tyk-pump>>,
<<    - "LICENSE.md"
    - CHANGELOG.md
    - pump.example.conf
>>)
- id: static-amd64
  name_template: "{{ .ProjectName }}_{{ .Version }}_static_{{ .Os }}_{{ .Arch }}"
  builds:
    - static-amd64
  files:
    - README.md
ifelse(xREPO, <<tyk-analytics>>,
<<    - EULA.md
    - CHANGELOG.md
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
<<    - "LICENSE.md"
    - CHANGELOG.md
    - "install/*"
    - pump.example.conf
>>)

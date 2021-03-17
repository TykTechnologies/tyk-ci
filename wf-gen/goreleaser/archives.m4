archives:
- id: std-linux
  builds:
    - std-linux
  files:
    - README.md
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
- id: std-darwin
  builds:
    - std-darwin
  files:
    - README.md
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
- id: std-arm64
  builds:
    - std-arm64
  files:
    - README.md
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
>>)dnl
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

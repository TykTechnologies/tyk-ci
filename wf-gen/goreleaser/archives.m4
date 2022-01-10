archives:
- id: std-linux
  builds:
ifelse(xCGO, <<1>>,<<
    - std-linux
    - std-arm64
>>, <<
    - std
>>)dnl
  files:
    - README.md
    - "ci/install/*"
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
>>, xREPO, <<portal>>,
<<    - "app/*"
    - "themes/*"
    - "public/system/*"  
>>)
nfpms:
  - id: std
    vendor: "Tyk Technologies Ltd"
    homepage: "https://tyk.io"
    maintainer: "Tyk <info@tyk.io>"
    description: xPKG_DESC
    package_name: xCOMPATIBILITY_NAME
    builds:
ifelse(xCGO, <<1>>,<<
      - std-linux
      - std-arm64
>>, <<
      - std
>>)dnl
    formats:
      - deb
      - rpm
    contents:
      - src: "README.md"
        dst: "/opt/share/docs/xCOMPATIBILITY_NAME/README.md"
      - src: "ci/install/*"
        dst: "/opt/xCOMPATIBILITY_NAME/install"
      - src: ci/install/inits/systemd/system/xCOMPATIBILITY_NAME.service
        dst: /lib/systemd/system/xCOMPATIBILITY_NAME.service
      - src: ci/install/inits/sysv/init.d/xCOMPATIBILITY_NAME
        dst: /etc/init.d/xCOMPATIBILITY_NAME
ifelse(xREPO, <<tyk-analytics>>,<<
      - src: /opt/xCOMPATIBILITY_NAME
        dst: /opt/xREPO
        type: "symlink"
      - src: "EULA.md"
        dst: "/opt/share/docs/xCOMPATIBILITY_NAME/EULA.md"
      - src: "portal/*"
        dst: "/opt/xCOMPATIBILITY_NAME/portal"
      - src: "utils/scripts/*"
        dst: "/opt/xCOMPATIBILITY_NAME/utils/scripts"
      - src: "schemas/*"
        dst: "/opt/xCOMPATIBILITY_NAME/schemas"
      - src: "webclient/lang/*"
        dst: "/opt/xCOMPATIBILITY_NAME/lang"
      - src: tyk_config_sample.config
        dst: /opt/xCOMPATIBILITY_NAME/xCONFIG_FILE
        type: "config|noreplace"
>>, xREPO, <<tyk>>,<<
      - src: /opt/xCOMPATIBILITY_NAME
        dst: /opt/xREPO
        type: "symlink"
      - src: "LICENSE.md"
        dst: "/opt/share/docs/xCOMPATIBILITY_NAME/LICENSE.md"
      - src: "apps/app_sample.*"
        dst: "/opt/xCOMPATIBILITY_NAME/apps"
      - src: "templates/*.json"
        dst: "/opt/xCOMPATIBILITY_NAME/templates"
      - src: "templates/playground/*"
        dst: "/opt/xCOMPATIBILITY_NAME/templates/playground"
      - src: "middleware/*.js"
        dst: "/opt/xCOMPATIBILITY_NAME/middleware"
      - src: "event_handlers/sample/*.js"
        dst: "/opt/xCOMPATIBILITY_NAME/event_handlers/sample"
      - src: "policies/*.json"
        dst: "/opt/xCOMPATIBILITY_NAME/policies"
      - src: "coprocess/*"
        dst: "/opt/xCOMPATIBILITY_NAME/coprocess"
      - src: tyk.conf.example
        dst: /opt/xCOMPATIBILITY_NAME/xCONFIG_FILE
        type: "config|noreplace"
>>, xREPO, <<tyk-identity-broker>>, <<
      - src: "LICENSE.md"
        dst: "/opt/share/docs/xCOMPATIBILITY_NAME/LICENSE.md"
      - src: tib_sample.conf
        dst: /opt/xCOMPATIBILITY_NAME/xCONFIG_FILE
        type: "config|noreplace"
>>, xREPO, <<tyk-pump>>,<<
      - src: "LICENSE.md"
        dst: "/opt/share/docs/xCOMPATIBILITY_NAME/LICENSE.md"
      - src: pump.example.conf
        dst: /opt/xCOMPATIBILITY_NAME/xCONFIG_FILE
        type: "config|noreplace"
>>, xREPO, <<tyk-sink>>, <<
      - src: tyk_sink_sample.conf
        dst: /opt/xCOMPATIBILITY_NAME/xCONFIG_FILE
        type: "config|noreplace"
>>, xREPO, <<raava>>, <<
      - src: raava.conf
        dst: /opt/xCOMPATIBILITY_NAME/xCONFIG_FILE
        type: "config|noreplace"
      - src: app/*
        dst: /opt/xCOMPATIBILITY_NAME/app/
      - src: themes/*
        dst: /opt/xCOMPATIBILITY_NAME/themes/
      - src: public/system/*
        dst: /opt/xCOMPATIBILITY_NAME/public/system/
>>)dnl
include(goreleaser/nfpm-common.m4)
ifelse(xREPO, <<tyk-analytics>>, <<
  - id: payg
    vendor: "Tyk Technologies Ltd"
    homepage: "https://tyk.io"
    maintainer: "Tyk <info@tyk.io>"
    description: "PAYG Dashboard for the Tyk API Gateway"
    package_name: xCOMPATIBILITY_NAME-PAYG
    file_name_template: "{{ .ProjectName }}_PAYG_{{ .Version }}_{{ .Os }}_{{ .Arch }}"
    builds:
      - payg
    formats:
      - deb
      - rpm
    contents:
      - src: "README.md"
        dst: "/opt/share/docs/xCOMPATIBILITY_NAME/README.md"
      - src: "ci/install/*"
        dst: "/opt/xCOMPATIBILITY_NAME/install"
      - src: ci/install/inits/systemd/system/xCOMPATIBILITY_NAME.service
        dst: /lib/systemd/system/xCOMPATIBILITY_NAME.service
      - src: ci/install/inits/sysv/init.d/xCOMPATIBILITY_NAME
        dst: /etc/init.d/xCOMPATIBILITY_NAME
      - src: /opt/xCOMPATIBILITY_NAME
        dst: /opt/xREPO
        type: "symlink"
      - src: "EULA.md"
        dst: "/opt/share/docs/xCOMPATIBILITY_NAME/EULA.md"
      - src: "portal/*"
        dst: "/opt/xCOMPATIBILITY_NAME/portal"
      - src: "utils/scripts/*"
        dst: "/opt/xCOMPATIBILITY_NAME/utils/scripts"
      - src: "schemas/*"
        dst: "/opt/xCOMPATIBILITY_NAME/schemas"
      - src: "webclient/lang/*"
        dst: "/opt/xCOMPATIBILITY_NAME/lang"
      - src: tyk_config_sample.config
        dst: /opt/xCOMPATIBILITY_NAME/xCONFIG_FILE
        type: "config|noreplace"
include(goreleaser/nfpm-common.m4)
>>)

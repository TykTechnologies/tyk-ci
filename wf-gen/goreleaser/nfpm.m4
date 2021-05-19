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
      - src: "install/*"
        dst: "/opt/xCOMPATIBILITY_NAME/install"
ifelse(xREPO, <<tyk-analytics>>,<<
      - src: /opt/xCOMPATIBILITY_NAME
        dst: /opt/xREPO
        type: "symlink"
      - src: "EULA.md"
        dst: "/opt/share/docs/xCOMPATIBILITY_NAME/EULA.md"
      - src: "portal/*"
        dst: "/opt/xCOMPATIBILITY_NAME/portal"
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
      # in the repo coprocess/python/proto is a symlink, so copy the files explicitly
      - src: "coprocess/bindings/python/*"
        dst: "/opt/xCOMPATIBILITY_NAME/coprocess/python/proto"
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
      - deb
      - rpm
    contents:
      - src: "README*"
        dst: "/opt/xCOMPATIBILITY_NAME/"
      - src: "EULA.md"
        dst: "/opt/xCOMPATIBILITY_NAME"
      - src: "portal/*"
        dst: "/opt/xCOMPATIBILITY_NAME/portal"
      - src: "schemas/*"
        dst: "/opt/xCOMPATIBILITY_NAME/schemas"
      - src: "webclient/lang/*"
        dst: "/opt/xCOMPATIBILITY_NAME/lang"
      - src: "install/inits/*"
        dst: "/opt/xCOMPATIBILITY_NAME/install/inits"
      - src: tyk_config_sample.config
        dst: /opt/xCOMPATIBILITY_NAME/xCONFIG_FILE
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

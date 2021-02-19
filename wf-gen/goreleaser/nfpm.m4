nfpms:
  - id: std
    vendor: "Tyk Technologies Ltd"
    homepage: "https://tyk.io"
    maintainer: "Tyk <info@tyk.io>"
    description: xPKG_DESC
    package_name: xCOMPATIBILITY_NAME
    builds:
      - std-linux
      - std-arm64
    formats:
      - deb
      - rpm
    contents:
      - src: "README.md"
        dst: "/opt/share/docs/xREPO/README.md"
ifelse(xREPO, <<tyk-analytics>>,<<
      - src: /opt/xREPO
        dst: /opt/xCOMPATIBILITY_NAME
        type: "symlink"
      - src: "EULA.md"
        dst: "/opt/share/docs/xREPO/EULA.md"
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
>>, xREPO, <<tyk>>,<<
      - src: /opt/xREPO
        dst: /opt/xCOMPATIBILITY_NAME
        type: "symlink"
      - src: "LICENSE.md"
        dst: "/opt/share/docs/xREPO/LICENSE.md"
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
>>, xREPO, <<tyk-pump>>,<<
      - src: "LICENSE.md"
        dst: "/opt/share/docs/xREPO/LICENSE.md"
      - src: "install/*"
        dst: "/opt/xREPO/install"
      - src: pump.example.conf
        dst: /opt/xREPO/pump.conf
        type: "config|noreplace"
>>, xREPO, <<tyk-sink>>, <<
      - src: /opt/xREPO
        dst: /opt/xCOMPATIBILITY_NAME
        type: "symlink"
      - src: "install/inits/*"
        dst: "/opt/xREPO/install/inits"
      - src: tyk_sink_sample.conf
        dst: /opt/xREPO/xREPO.conf
        type: "config|noreplace"
>>)dnl
    scripts:
      preinstall: "install/before_install.sh"
      postinstall: "install/post_install.sh"
      postremove: "install/post_remove.sh"
    bindir: "/opt/xREPO"
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

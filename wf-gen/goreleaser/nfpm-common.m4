    scripts:
      preinstall: "ci/install/before_install.sh"
      postinstall: "ci/install/post_install.sh"
      postremove: "ci/install/post_remove.sh"
    bindir: "/opt/xCOMPATIBILITY_NAME"
    overrides:
      rpm:
        file_name_template: '{{ .PackageName }}-{{ replace .Version "-" "~" }}-1.{{ .Arch }}{{ if .Arm }}v{{ .Arm }}{{ end }}{{ if .Mips }}_{{ .Mips }}{{ end }}'
        replacements:
          amd64: x86_64
          arm: aarch64
          arm64: aarch64
      deb:
        file_name_template: '{{ .PackageName }}_{{ replace .Version "-" "~" }}_{{ .Arch }}{{ if .Arm }}v{{ .Arm }}{{ end }}{{ if .Mips }}_{{ .Mips }}{{ end }}'
        replacements:
          arm: arm64
    rpm:
      scripts:
        posttrans: ci/install/post_trans.sh
      signature:
        key_file: tyk.io.signing.key
    deb:
      signature:
        key_file: tyk.io.signing.key
        type: origin

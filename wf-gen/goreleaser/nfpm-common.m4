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
      scripts:
        posttrans: install/post_trans.sh
      signature:
        key_file: tyk.io.signing.key
    deb:
      signature:
        key_file: tyk.io.signing.key
        type: origin
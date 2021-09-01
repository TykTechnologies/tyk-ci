  goreleaser:
    runs-on: ubuntu-latest
ifelse(xCGO, <<1>>, <<
    container: tykio/golang-cross:1.15.15
>>)
    outputs:
      tag: ${{ steps.targets.outputs.tag }}
      upload: ${{ steps.targets.outputs.upload }}
      pc: ${{ steps.targets.outputs.pc }}

    steps:
      - name: Checkout of xREPO
        uses: actions/checkout@v2
        with:
          fetch-depth: ${{ ! startsWith(github.ref, 'refs/tags') }}
ifelse(xREPO, <<tyk-analytics>>,
<<          token: ${{ secrets.REPO_TOKEN }}
          submodules: true
>>)
      - uses: docker/setup-qemu-action@v1

      - uses: docker/setup-buildx-action@v1

      - name: Login to DockerHub
        if: startsWith(github.ref, 'refs/tags')
        uses: docker/login-action@v1
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Login to Cloudsmith
        if: startsWith(github.ref, 'refs/tags')
        uses: docker/login-action@v1
        with:
          registry: docker.tyk.io
          username: ${{ secrets.CLOUDSMITH_USERNAME }}
          password: ${{ secrets.CLOUDSMITH_API_KEY }}

      - name: Unlock agent and set targets
        id: targets
        shell: bash
        env:
          NFPM_STD_PASSPHRASE: ${{ secrets.SIGNING_KEY_PASSPHRASE }}
          GPG_FINGERPRINT: 12B5D62C28F57592D1575BD51ED14C59E37DAC20
          PKG_SIGNING_KEY: ${{ secrets.SIGNING_KEY }}
        run: |
          bin/unlock-agent.sh
          DOCKER_CFG_PATH="${DOCKER_CONFIG:-$HOME/.docker}/config.json"
          jq '. + {"experimental": "enabled"}' "$DOCKER_CFG_PATH" > c.json && mv c.json "$DOCKER_CFG_PATH" || rm c.json
          current_tag=${GITHUB_REF##*/}
          echo "::set-output name=tag::${current_tag}"
          if [[ $current_tag =~ .+-(qa|rc).* ]]; then
                  echo "::set-output name=upload::true"
                  echo "::set-output name=pc::xPC_REPO-unstable"
                  echo "::debug file=.goreleaser.yml::Pushing to unstable repos"
          # From https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
          # If this is a public release, the tag is of the form vX.Y.Z where X, Y, Z ∈ ℤ
          elif [[ $current_tag =~ v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*) ]]; then
                  echo "::set-output name=upload::true"
                  echo "::set-output name=pc::xPC_REPO"
                  echo "::debug file=.goreleaser.yml::Pushing to stable repos"
          else
                  echo "::set-output name=upload::false"
                  echo "::debug file=.goreleaser.yml::No uploads"
          fi

      - name: Delete old release assets
        if: startsWith(github.ref, 'refs/tags')
        uses: mknejp/delete-release-assets@v1
        with:
          token: ${{ github.token }}
          tag: ${{ github.ref }}
          fail-if-no-assets: false
          fail-if-no-release: false
          assets: |
            *.deb
            *.rpm
            *.tar.gz
            *.txt.sig
            *.txt

      - uses: goreleaser/goreleaser-action@v2
        with:
          version: latest
          args: release --rm-dist
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          CGO_ENABLED: xCGO
          NFPM_STD_PASSPHRASE: ${{ secrets.SIGNING_KEY_PASSPHRASE }}
          NFPM_PAYG_PASSPHRASE: ${{ secrets.SIGNING_KEY_PASSPHRASE }}
          GPG_FINGERPRINT: 12B5D62C28F57592D1575BD51ED14C59E37DAC20
          PKG_SIGNING_KEY: ${{ secrets.SIGNING_KEY }}

      - uses: actions/upload-artifact@v2
        with:
          name: deb
          retention-days: 1
          path: |
            dist/*.deb
            !dist/*PAYG*.deb

      - uses: actions/upload-artifact@v2
        with:
          name: rpm
          retention-days: 1
          path: |
            dist/*.rpm
            !dist/*PAYG*.rpm

      - uses: actions/upload-artifact@v2
        with:
          name: payg
          retention-days: 1
          path: dist/*PAYG*

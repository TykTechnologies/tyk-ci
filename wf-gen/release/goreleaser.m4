  goreleaser:
    name: '${{ matrix.golang_cross }}'
    runs-on: ubuntu-latest
    container: 'tykio/golang-cross:${{ matrix.golang_cross }}'
    strategy:
      fail-fast: false
      matrix:
        golang_cross: [ 1.15 ifelse(xCGO, <<1>>, <<, 1.15-el7>>) ]
        include:ifelse(xCGO, <<1>>,<<
          - golang_cross: 1.15-el7
            goreleaser: 'ci/goreleaser/goreleaser-el7.yml'
            rpmvers: 'el/7'
            debvers: 'ubuntu/xenial ubuntu/bionic debian/jessie'>>)
          - golang_cross: 1.15
            goreleaser: 'ci/goreleaser/goreleaser.yml'ifelse(xCGO, <<1>>, <<
            rpmvers: 'el/8'
            debvers: 'ubuntu/focal debian/buster debian/bullseye'
>>)ifelse(xCGO, <<0>>, <<
            rpmvers: 'el/7 el/8'
            debvers: 'ubuntu/xenial ubuntu/bionic debian/jessie ubuntu/focal debian/buster debian/bullseye'
>>)
    outputs:
      tag: ${{ steps.targets.outputs.tag }}

    steps:
      - name: Fix private module deps
        env:
          TOKEN: '${{ secrets.ORG_GH_TOKEN }}'
        run: >
          git config --global url."https://${TOKEN}@github.com".insteadOf "https://github.com"

      - name: Checkout of xREPO
        uses: actions/checkout@v2
        with:
          fetch-depth: 1
ifelse(xREPO, <<tyk-analytics>>,
<<          token: ${{ secrets.ORG_GH_TOKEN }}
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

      - name: Unlock agent and set tag
        id: targets
        shell: bash
        env:
          NFPM_STD_PASSPHRASE: ${{ secrets.SIGNING_KEY_PASSPHRASE }}
          GPG_FINGERPRINT: 12B5D62C28F57592D1575BD51ED14C59E37DAC20
          PKG_SIGNING_KEY: ${{ secrets.SIGNING_KEY }}
        run: |
          ci/bin/unlock-agent.sh
          current_tag=${GITHUB_REF##*/}
          echo "::set-output name=tag::${current_tag}"

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

ifelse(xREPO, <<tyk>>,
<<
      - name: Fix vendor
        run: |
          export GOPATH=/go
          mkdir -p /go/src || true
          whereis go
          go mod tidy
          go mod vendor
          echo "Moving vendor"
          cp -r -f vendor/* $GOPATH/src
          rm -rf vendor
          mkdir -p /go/src/github.com/TykTechnologies/tyk
          cp -r ./* /go/src/github.com/TykTechnologies/tyk
>>)

      - uses: goreleaser/goreleaser-action@v2
        with:
          version: latest
          args: release --rm-dist -f ${{ matrix.goreleaser }}
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          CGO_ENABLED: xCGO
ifelse(xREPO, <<tyk>>,
<<          GO111MODULE: off>>)
          NFPM_STD_PASSPHRASE: ${{ secrets.SIGNING_KEY_PASSPHRASE }}
          NFPM_PAYG_PASSPHRASE: ${{ secrets.SIGNING_KEY_PASSPHRASE }}
          GPG_FINGERPRINT: 12B5D62C28F57592D1575BD51ED14C59E37DAC20
          PKG_SIGNING_KEY: ${{ secrets.SIGNING_KEY }}
          GOLANG_CROSS: ${{ matrix.golang_cross }}
          DEBVERS: ${{ matrix.debvers }}
          RPMVERS: ${{ matrix.rpmvers }}
          REPO: tyk/tyk-gateway-unstable
          PACKAGECLOUD_TOKEN: ${{ secrets.PACKAGECLOUD_TOKEN }}

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
ifelse(xREPO, <<tyk-analytics>>,
<<
      - uses: actions/upload-artifact@v2
        with:
          name: payg
          retention-days: 1
          path: dist/*PAYG*
>>)            

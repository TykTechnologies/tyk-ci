  upgrade-deb:
    runs-on: ubuntu-latest
    needs: goreleaser
    strategy:
      fail-fast: false
      matrix:
        arch:
          - amd64
          - arm64
        distro:
          - ubuntu:xenial
          - ubuntu:bionic
          - ubuntu:focal
          - debian:jessie

    steps:
      - uses: actions/checkout@v2
        with:
          fetch-depth: 1

      - uses: actions/download-artifact@v2
        with:
          name: deb

      - uses: docker/setup-qemu-action@v1

      - uses: docker/setup-buildx-action@v1

      - name: generate dockerfile
        run: |
          echo 'FROM ${{ matrix.distro }}
          ARG TARGETARCH
          COPY xCOMPATIBILITY_NAME*_${TARGETARCH}.deb /xCOMPATIBILITY_NAME.deb
          RUN apt-get update && apt-get install -y curl
ifelse(xPC_PRIVATE, <<0>>, <<
          RUN curl -fsSL https://packagecloud.io/install/repositories/tyk/xPC_REPO-unstable/script.deb.sh | bash && apt-get install -y xCOMPATIBILITY_NAME=xUPGRADE_FROM>>, <<
          RUN curl -u ${{ secrets.PACKAGECLOUD_MASTER_TOKEN }}: -fsSL https://packagecloud.io/install/repositories/tyk/xPC_REPO/script.deb.sh | bash && apt-get install -y xCOMPATIBILITY_NAME=xUPGRADE_FROM>>)
          RUN dpkg -i xCOMPATIBILITY_NAME.deb' > Dockerfile

      - name: install on ${{ matrix.distro }}
        uses: docker/build-push-action@v2
        with:
          context: "."
          platforms: linux/${{ matrix.arch }}
          file: Dockerfile
          push: false

  upgrade-rpm:
    needs: goreleaser
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        distro:
          - ubi7/ubi
          - ubi8/ubi

    steps:
      - uses: actions/checkout@v2
        with:
          fetch-depth: 1

      - uses: actions/download-artifact@v2
        with:
          name: rpm

      - uses: docker/setup-buildx-action@v1

      - name: generate dockerfile
        run: |
          echo 'FROM registry.access.redhat.com/${{ matrix.distro }}
          COPY xCOMPATIBILITY_NAME*_x86_64.rpm /xCOMPATIBILITY_NAME.rpm
          RUN yum install -y curl
ifelse(xPC_PRIVATE, <<0>>, <<
          RUN curl -s https://packagecloud.io/install/repositories/tyk/xPC_REPO-unstable/script.rpm.sh | bash && yum install -y xCOMPATIBILITY_NAME-xUPGRADE_FROM-1>>, <<
          RUN curl -u ${{ secrets.PACKAGECLOUD_MASTER_TOKEN }}: -s https://packagecloud.io/install/repositories/tyk/xPC_REPO/script.rpm.sh | bash && yum install -y xCOMPATIBILITY_NAME-xUPGRADE_FROM-1>>)
          RUN rpm -Uvh xCOMPATIBILITY_NAME.rpm' > Dockerfile

      - name: install on ${{ matrix.distro }}
        uses: docker/build-push-action@v2
        with:
          context: "."
          file: Dockerfile
          push: false

  smoke-tests:
    needs:
      - goreleaser
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v2
        with:
          fetch-depth: 1

      - name: Run tests
        shell: bash
        run: |
          set -eaxo pipefail
          if [ ! -d integration/smoke-tests ]; then
             echo "::warning No smoke tests defined"
             exit 0
          fi
          for d in integration/smoke-tests/*/
          do
              echo Attempting to test $d
              if [ -d $d ]; then
                  cd $d
                  ./test.sh ${{ needs.goreleaser.outputs.tag }}
                  cd -
              fi
          done


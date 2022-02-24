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
          - debian:bullseye

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
          RUN curl -fsSL https://packagecloud.io/install/repositories/tyk/xPC_REPO/script.deb.sh | bash && apt-get install -y xCOMPATIBILITY_NAME=xUPGRADE_FROM>>, <<
          RUN curl -u ${{ secrets.PACKAGECLOUD_MASTER_TOKEN }}: -fsSL https://packagecloud.io/install/repositories/tyk/xPC_REPO/script.deb.sh | bash && apt-get install -y xCOMPATIBILITY_NAME=xUPGRADE_FROM>>)
          RUN dpkg -i xCOMPATIBILITY_NAME.deb dnl
ifelse(xREPO, <<tyk>>, <<
          RUN apt-get install -y jq
          RUN /opt/tyk-gateway/install/setup.sh --listenport=8080 --redishost=localhost --redisport=6379 --domain=""
          COPY ci/tests/api-functionality/api_test.sh /
          COPY ci/tests/api-functionality/pkg_test.sh /
          COPY ci/tests/api-functionality/data/api.json /opt/tyk-gateway/apps/
          CMD [ "/pkg_test.sh" ]
          >>)' > Dockerfile

      - name: install on ${{ matrix.distro }}
        uses: docker/build-push-action@v2
        with:
          context: "."
          platforms: linux/${{ matrix.arch }}
          file: Dockerfile
          push: false
ifelse(xREPO, <<tyk>>, <<format(%10s)tags: test-${{ matrix.distro }}-${{ matrix.arch }}
          load: true

      - name: Test the built container image with api functionality test.
        run: |
          docker run --rm test-${{ matrix.distro }}-${{ matrix.arch }}>>)

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
          COPY xCOMPATIBILITY_NAME*.x86_64.rpm /xCOMPATIBILITY_NAME.rpm
          RUN yum install -y curl
ifelse(xPC_PRIVATE, <<0>>, <<
          RUN curl -fsSL https://packagecloud.io/install/repositories/tyk/xPC_REPO/script.rpm.sh | bash && yum install -y xCOMPATIBILITY_NAME-xUPGRADE_FROM-1>>, <<
          RUN curl -u ${{ secrets.PACKAGECLOUD_MASTER_TOKEN }}: -s https://packagecloud.io/install/repositories/tyk/xPC_REPO/script.rpm.sh | bash && yum install -y xCOMPATIBILITY_NAME-xUPGRADE_FROM-1>>)
          RUN curl https://keyserver.tyk.io/tyk.io.rpm.signing.key.2020 -o xPC_REPO.key && rpm --import xPC_REPO.key
          RUN rpm --checksig xCOMPATIBILITY_NAME.rpm
          RUN rpm -Uvh --force xCOMPATIBILITY_NAME.rpm dnl
ifelse(xREPO, <<tyk>>, <<
          RUN curl -fSL https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 --output /usr/local/bin/jq && chmod a+x /usr/local/bin/jq
          RUN /opt/tyk-gateway/install/setup.sh --listenport=8080 --redishost=localhost --redisport=6379 --domain=""
          COPY ci/tests/api-functionality/data/api.json /opt/tyk-gateway/apps/
          COPY ci/tests/api-functionality/api_test.sh /
          COPY ci/tests/api-functionality/pkg_test.sh /
          CMD [ "/pkg_test.sh" ]
          >>)' > Dockerfile

      - name: install on ${{ matrix.distro }}
        uses: docker/build-push-action@v2
        with:
          context: "."
          file: Dockerfile
          push: false
ifelse(xREPO, <<tyk>>, <<format(%10s)tags: test-${{ matrix.distro }}
          load: true

      - name: Test the built container image with api functionality test.
        run: |
          docker run --rm test-${{ matrix.distro }}>>)

  smoke-tests:
    if: startsWith(github.ref, 'refs/tags')
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
          if [ ! -d smoke-tests ]; then
             echo "::warning No repo specific smoke tests defined"
          fi
          if [ ! -d ci/tests ]; then
             echo "::warning No ci tests defined"
             exit 0
          fi
          for d in ci/tests/*/
          do
              echo Attempting to test $d
              if [ -d $d ] && [ -e $d/test.sh ]; then
                  cd $d
                  ./test.sh ${{ needs.goreleaser.outputs.tag }}
                  cd -
              fi
          done
          for d in smoke-tests/*/
          do
              echo Attempting to test $d
              if [ -d $d ] && [ -e $d/test.sh ]; then
                  cd $d
                  ./test.sh ${{ needs.goreleaser.outputs.tag }}
                  cd -
              fi
          done


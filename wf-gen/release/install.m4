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
          - debian:stretch
          - debian:buster

    steps:
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
          RUN curl -u ${{ secrets.PACKAGECLOUD_TOKEN }}: -fsSL https://packagecloud.io/install/repositories/tyk/xPC_REPO/script.deb.sh | bash && apt-get install -y xCOMPATIBILITY_NAME=xUPGRADE_FROM>>)
          RUN dpkg -i /xCOMPATIBILITY_NAME.deb && /opt/xCOMPATIBILITY_NAME/xREPO --conf=/opt/xCOMPATIBILITY_NAME/xREPO.conf &' > Dockerfile

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
          - ubi7/ubi:7.9
          - ubi8/ubi:8.3

    steps:
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
          RUN curl -s https://packagecloud.io/install/repositories/tyk/xPC_REPO/script.rpm.sh | bash && yum install -y xCOMPATIBILITY_NAME-xUPGRADE_FROM-1>>, <<
          RUN curl -u ${{ secrets.PACKAGECLOUD_TOKEN }}: -s https://packagecloud.io/install/repositories/tyk/xPC_REPO/script.rpm.sh | bash && yum install -y xCOMPATIBILITY_NAME-xUPGRADE_FROM-1>>)
          RUN rpm -ih /xCOMPATIBILITY_NAME.rpm && /opt/xCOMPATIBILITY_NAME/xREPO --conf=/opt/xCOMPATIBILITY_NAME/xREPO.conf &' > Dockerfile

      - name: install on ${{ matrix.distro }}
        uses: docker/build-push-action@v2
        with:
          context: "."
          file: Dockerfile
          push: false

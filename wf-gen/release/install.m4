  install-deb:
    runs-on: ubuntu-latest
    needs: goreleaser
    strategy:
      matrix:
        distro:
          - ubuntu:xenial
          - ubuntu:bionic
          - ubuntu:focal
          - debian:jessie
          - debian:stretch
          - debian:buster

    steps:
      - uses: actions/download-artifact@v2
        with:
          name: deb

      - uses: docker/setup-buildx-action@v1

      - name: generate dockerfile
        run: |
          echo 'FROM ${{ matrix.distro }}
          COPY xCOMPATIBILITY_NAME*_amd64.deb /xCOMPATIBILITY_NAME.deb
          RUN dpkg -i /xCOMPATIBILITY_NAME.deb && /opt/xCOMPATIBILITY_NAME/xREPO --conf=/opt/xCOMPATIBILITY_NAME/xREPO.conf &' > Dockerfile

      - name: install on ${{ matrix.distro }}
        uses: docker/build-push-action@v2
        with:
          context: "."
          file: Dockerfile
          push: false

  install-rpm:
    needs: goreleaser
    runs-on: ubuntu-latest
    strategy:
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
          RUN rpm -ih /xCOMPATIBILITY_NAME.rpm && /opt/xCOMPATIBILITY_NAME/xREPO --conf=/opt/xCOMPATIBILITY_NAME/xREPO.conf &' > Dockerfile

      - name: install on ${{ matrix.distro }}
        uses: docker/build-push-action@v2
        with:
          context: "."
          file: Dockerfile
          push: false

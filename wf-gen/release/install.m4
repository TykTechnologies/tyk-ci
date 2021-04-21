  install-deb:
    if: startsWith(github.ref, 'refs/tags/')
    needs:
      - goreleaser
    runs-on: ubuntu-latest
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
      - uses: TykTechnologies/gh-asset-action@main
        with:
          tag: ${{ needs.goreleaser.outputs.tag }}
          kind: "_linux_amd64.deb"
          dest: "xCOMPATIBILITY_NAME.deb"
          token: ${{ secrets.GITHUB_TOKEN }}

      - uses: docker/setup-buildx-action@v1

      - name: generate dockerfile
        run: |
          echo 'FROM ${{ matrix.distro }}
          COPY xCOMPATIBILITY_NAME.deb /
          RUN dpkg -i /xCOMPATIBILITY_NAME.deb && /opt/xCOMPATIBILITY_NAME/xREPO --conf=/opt/xCOMPATIBILITY_NAME/xREPO.conf &' > Dockerfile

      - name: install on ${{ matrix.distro }}
        uses: docker/build-push-action@v2
        with:
          context: "."
          file: Dockerfile
          push: false

  install-rpm:
    if: startsWith(github.ref, 'refs/tags/')
    needs:
      - goreleaser
    runs-on: ubuntu-latest
    strategy:
      matrix:
        distro:
          - registry.access.redhat.com/ubi7/ubi:7.9
          - registry.access.redhat.com/ubi8/ubi:8.3

    steps:
      - uses: TykTechnologies/gh-asset-action@main
        with:
          tag: ${{ needs.goreleaser.outputs.tag }}
          kind: "_linux_x86_64.rpm"
          dest: "xCOMPATIBILITY_NAME.rpm"
          token: ${{ secrets.GITHUB_TOKEN }}

      - uses: docker/setup-buildx-action@v1

      - name: generate dockerfile
        run: |
          echo 'FROM ${{ matrix.distro }}
          COPY tyk-pump.rpm /
          RUN rpm -ih /tyk-pump.rpm && /opt/xCOMPATIBILITY_NAME/xREPO --conf=/opt/xCOMPATIBILITY_NAME/xREPO.conf &' > Dockerfile

      - name: install on ${{ matrix.distro }}
        uses: docker/build-push-action@v2
        with:
          context: "."
          file: Dockerfile
          push: false


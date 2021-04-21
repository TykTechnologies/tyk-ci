# AWS updates only for stable releases

  aws-mktplace-byol:
    if: startsWith(github.ref, 'refs/tags/v3.0')
    runs-on: ubuntu-latest
    strategy:
      matrix:
        flavour:
          - al2
          - rhel

    steps:
      - name: Checkout xREPO
        uses: actions/checkout@v2
        with:
          fetch-depth: 1

      - uses: TykTechnologies/gh-asset-action@main
        with:
          tag: ${{ needs.goreleaser.outputs.tag }}
          kind: "_linux_amd64.deb"
          dest: "aws/xCOMPATIBILITY_NAME.deb"
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Packer build
        working-directory: ./aws
        run: |
          export VERSION=${{ needs.goreleaser.outputs.tag }}
          packer validate -var-file=${{ matrix.flavour }}.vars.json byol.pkr.hcl
          packer build -var-file=${{ matrix.flavour }}.vars.json byol.pkr.hcl

ifelse(xREPO, <<tyk-analytics>>, <<
  aws-mktplace-payg:
    if: startsWith(github.ref, 'refs/tags/v3.0')
    runs-on: ubuntu-latest
    strategy:
      matrix:
        flavour:
          - al2
          - rhel
        gws:
          - ONE_GW
          - TWO_GW
          - UNLIMITED_GW

    steps:
      - name: Checkout xREPO
        uses: actions/checkout@v2
        with:
          fetch-depth: 1

      - uses: TykTechnologies/gh-asset-action@main
        with:
          tag: ${{ needs.goreleaser.outputs.tag }}
          kind: "_linux_amd64.deb"
          dest: "aws/xCOMPATIBILITY_NAME.deb"
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Packer build
        working-directory: ./aws
        env:
          ONE_GW: ${{ secrets.PAYG_ONE_GW }}
          TWO_GW: ${{ secrets.PAYG_TWO_GW }}
          UNLIMITED_GW: ${{ secrets.PAYG_UNLIMITED_GW }}
        run: |
          export TYK_DB_VERSION=${{ needs.goreleaser.outputs.tag }}
          export LICENSE_STRING=$${{ matrix.gws }}
          packer validate -var-file=${{ matrix.flavour }}.vars.json payg.pkr.hcl
          packer build -var-file=${{ matrix.flavour }}.vars.json payg.pkr.hcl
>>)

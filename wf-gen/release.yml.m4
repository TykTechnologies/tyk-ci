include(header.m4)
# Distribution channels covered by this workflow
# - Ubuntu and Debian
# - RHEL/OL
# - tarballs
# - docker hub
# - devenv ECR
# - AWS mktplace

name: Release

on:
  pull_request:
  push:
    branches:
      - master
      - release-**
    tags:
      - 'v*'

jobs:
  goreleaser:
    runs-on: ubuntu-latest
    container: tykio/golang-cross:1.15

    steps:
      - name: Checkout xREPO
        uses: actions/checkout@v2
        with:
          fetch-depth: 0
          token: ${{ secrets.repo_token }}
ifelse(xREPO, <<tyk-analytics>>,
<<          submodules: true
>>)
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v1
        with:
          cli_config_credentials_token: ${{ secrets.TF_API_TOKEN }}
          terraform_wrapper: false

      - name: Get AWS creds from Terraform remote state
        id: aws-creds
        run: |
            cd integration/terraform
            terraform init -input=false -lock=false
            terraform refresh
            eval $(terraform output -json xREPO | jq -r 'to_entries[] | [.key,.value] | join("=")')
            region=$(terraform output region | xargs)
            [ -z "$key" -o -z "$secret" -o -z "$region" -o -z "$ecr" ] && exit 1
            echo "::set-output name=secret::$secret"
            echo "::add-mask::$secret"
            echo "::set-output name=key::$key"
            echo "::set-output name=ecr::$ecr"
            echo "::set-output name=region::$region"

      - name: Configure AWS credentials for use
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ steps.aws-creds.outputs.key }}
          aws-secret-access-key: ${{ steps.aws-creds.outputs.secret }}
          aws-region: ${{ steps.aws-creds.outputs.region }}

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1

      - name: Login to DockerHub
        if: startsWith(github.ref, 'refs/tags')
        uses: docker/login-action@v1
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Unlock agent
        env:
          NFPM_STD_PASSPHRASE: ${{ secrets.SIGNING_KEY_PASSPHRASE }}
          GPG_FINGERPRINT: 12B5D62C28F57592D1575BD51ED14C59E37DAC20
          PKG_SIGNING_KEY: ${{ secrets.SIGNING_KEY }}
        run: |
          /unlock-agent.sh

      - uses: goreleaser/goreleaser-action@v2
        with:
          version: latest
          args: release --rm-dist
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          CGO_ENABLED: 1
          NFPM_STD_PASSPHRASE: ${{ secrets.SIGNING_KEY_PASSPHRASE }}
          NFPM_PAYG_PASSPHRASE: ${{ secrets.SIGNING_KEY_PASSPHRASE }}
          GPG_FINGERPRINT: 12B5D62C28F57592D1575BD51ED14C59E37DAC20
          PKG_SIGNING_KEY: ${{ secrets.SIGNING_KEY }}
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}

      - name: Push to xCOMPATIBILITY_NAME-unstable
        if: startsWith(github.ref, 'refs/heads')
        uses: TykTechnologies/packagecloud-action@main
        env:
          PACKAGECLOUD_TOKEN: ${{ secrets.PACKAGECLOUD_TOKEN }}
        with:
          repo: 'tyk/xCOMPATIBILITY_NAME-unstable'
          dir: 'dist'

      - name: Push to xCOMPATIBILITY_NAME
        if: startsWith(github.ref, 'refs/tags')
        uses: TykTechnologies/packagecloud-action@v1
        env:
          PACKAGECLOUD_TOKEN: ${{ secrets.PACKAGECLOUD_TOKEN }}
        with:
          repo: 'tyk/xCOMPATIBILITY_NAME'
          dir: 'dist'

      - name: Logout of Amazon ECR
        if: always()
        run: docker logout ${{ steps.login-ecr.outputs.registry }}

# AWS mktplace update only for LTS releases
  aws-mktplace-byol:
    if: startsWith(github.ref, 'refs/tags/v3.0')
    needs: [ goreleaser ]
    runs-on: ubuntu-latest
    strategy:
      matrix:
        flavour:
          - al2
          - rhel

    steps:
      - name: Packer build
        working-directory: ./aws
        run: |
          export VERSION=${GITHUB_REF##*/}
          packer validate -var-file=${{ matrix.flavour }}.vars.json byol.pkr.hcl
          packer build -var-file=${{ matrix.flavour }}.vars.json byol.pkr.hcl

ifelse(xREPO, <<tyk-analytics>>, <<
  aws-mktplace-payg:
    if: startsWith(github.ref, 'refs/tags/v3.0')
    needs: [ goreleaser ]
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
      - name: Packer build
        working-directory: ./aws
        env:
          ONE_GW: ${{ secrets.PAYG_ONE_GW }}
          TWO_GW: ${{ secrets.PAYG_TWO_GW }}
          UNLIMITED_GW: ${{ secrets.PAYG_UNLIMITED_GW }}
        run: |
          export TYK_DB_VERSION=${GITHUB_REF##*/}
          export LICENSE_STRING=$${{ matrix.gws }}
          packer validate -var-file=${{ matrix.flavour }}.vars.json payg.pkr.hcl
          packer build -var-file=${{ matrix.flavour }}.vars.json payg.pkr.hcl
>>)

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
  int-image:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout xREPO
        uses: actions/checkout@v2
        with:
          fetch-depth: 1
ifelse(xREPO, <<tyk-analytics>>,
<<          token: ${{ secrets.repo_token }}
          submodules: true
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

      - name: Build integration tarball
        run: |
            if [ -x bin/integration_build.sh ]; then
               SIGNPKGS=0 BUILDPKGS=0 BUILDWEB=0 ARCH=amd64 bin/integration_build.sh
               cp xREPO-amd64-*.tar.gz integration/image/xREPO.tar.gz
            fi

      - name: Build, tag, and push image to Amazon ECR
        env:
          ECR_REGISTRY: ${{ steps.aws-creds.outputs.ecr }}
        run: |
            docker build -t ${ECR_REGISTRY}:${GITHUB_REF##*/} \
                         -t ${ECR_REGISTRY}:latest \
                         -t ${ECR_REGISTRY}:${GITHUB_SHA} \
                         integration/image
            docker push --all-tags $ECR_REGISTRY

      - name: Tell gromit about new build
        run: |
            curl -fsSL -H "Authorization: ${{secrets.GROMIT_TOKEN}}" 'https://domu-kun.cloud.tyk.io/gromit/newbuild' \
                 -X POST -d '{ "repo": "${{ github.repository}}", "ref": "${{ github.ref }}", "sha": "${{ github.sha }}" }'

      - name: Logout of Amazon ECR
        if: always()
        run: docker logout ${{ steps.login-ecr.outputs.registry }}

  goreleaser:
    runs-on: ubuntu-latest
    container: tykio/golang-cross:1.15.8

    steps:
      - name: Checkout xREPO
        uses: actions/checkout@v2
        with:
          fetch-depth: 0
ifelse(xREPO, <<tyk-analytics>>,
<<          token: ${{ secrets.repo_token }}
          submodules: true
>>)
      - name: Login to DockerHub
        if: startsWith(github.ref, 'refs/tags')
        uses: docker/login-action@v1
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Unlock agent and set targets
        env:
          NFPM_STD_PASSPHRASE: ${{ secrets.SIGNING_KEY_PASSPHRASE }}
          GPG_FINGERPRINT: 12B5D62C28F57592D1575BD51ED14C59E37DAC20
          PKG_SIGNING_KEY: ${{ secrets.SIGNING_KEY }}
        run: |
          /unlock-agent.sh
          current_tag=$(git describe --tags)
          if [[ $current_tag =~ ".+-(qa|rc).*" ]]; then
                  echo "::set-output name=upload::true"
                  echo "::set-output name=pc::xPC_REPO-unstable"
                  echo "::set-output name=hub::unstable"
          # From https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string
          elif [[ $current_tag =~ "v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?" ]]; then
                  echo "::set-output name=upload::true"
                  echo "::set-output name=pc::xPC_REPO"
                  echo "::set-output name=hub::stable"
          else
                  echo "::set-output name=upload::false"
                  echo "::set-output name=hub::unstable"
          fi

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
          HUB_TAG: ${{ steps.targets.outputs.hub }}

      - name: Push to packagecloud
        if: steps.targets.outputs.upload == true
        uses: TykTechnologies/packagecloud-action@main
        env:
          PACKAGECLOUD_TOKEN: ${{ secrets.PACKAGECLOUD_TOKEN }}
        with:
          repo: tyk/${{ steps.targets.outputs.pc }}
          dir: 'dist'

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

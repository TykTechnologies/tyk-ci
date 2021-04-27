  ci:
    needs:
      - goreleaser
    runs-on: ubuntu-latest

    steps:
      - name: Shallow checkout of xREPO
        uses: actions/checkout@v2
        with:
          fetch-depth: 1
ifelse(xREPO, <<tyk-analytics>>,
<<          token: ${{ secrets.REPO_TOKEN }}
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
          terraform init -input=false
          terraform refresh 2>&1 >/dev/null
          eval $(terraform output -json xREPO | jq -r 'to_entries[] | [.key,.value] | join("=")')
          region=$(terraform output region | xargs)
          [ -z "$key" -o -z "$secret" -o -z "$region" ] && exit 1
          echo "::set-output name=secret::$secret"
          echo "::set-output name=key::$key"
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

      - uses: actions/download-artifact@v2
        with:
          name: deb

      - uses: docker/setup-qemu-action@v1

      - uses: docker/setup-buildx-action@v1

      - name: CI build
        uses: docker/build-push-action@v2
        with:
          push: true
          context: "."
          file: Dockerfile.std
          platforms: linux/amd64,linux/arm64
          tags: |
            ${{ steps.login-ecr.outputs.registry }}/xREPO:${{ needs.goreleaser.outputs.tag }}
            ${{ steps.login-ecr.outputs.registry }}/xREPO:${{ github.sha }}

      - name: Tell gromit about new build
        id: gromit
        run: |
          curl -fsSL -H "Authorization: ${{secrets.GROMIT_TOKEN}}" 'https://domu-kun.cloud.tyk.io/gromit/newbuild' \
                 -X POST -d '{ "repo": "${{ github.repository}}", "ref": "${{ github.ref }}", "sha": "${{ github.sha }}" }'

      - name: Tell integration channel
        if: ${{ failure() }}
        run: |
          colour=bad
          pretext=":boom: Could not add new build $${{ github.ref }} from ${{ github.repository }} to CD. Please review this run and correct it if needed. See https://github.com/TykTechnologies/tyk-ci/wiki/IntegrationEnvironment for what this is about."
          curl https://raw.githubusercontent.com/rockymadden/slack-cli/master/src/slack -o /tmp/slack && chmod +x /tmp/slack
          /tmp/slack chat send \
          --actions '{"type": "button", "style": "primary", "text": "See log", "url": "https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }}"}' \
          --author 'Bender' \
          --author-icon 'https://hcoop.net/~alephnull/bender/bender-arms.jpg' \
          --author-link 'https://github.com/TykTechnologies/tyk-ci' \
          --channel '#integration' \
          --color $colour \
          --fields '{"title": "Repo", "value": "${{ github.repository }}", "short": false}' \
          --footer 'github-actions' \
          --footer-icon 'https://assets-cdn.github.com/images/modules/logos_page/Octocat.png' \
          --image 'https://assets-cdn.github.com/images/modules/logos_page/Octocat.png' \
          --pretext "$pretext" \
          --text 'Commit message: ${{ github.event.head_commit.message }}' \
          --title 'Failed to add new build for CD' \
          --title-link 'https://github.com/${{ github.repository }}/actions/runs/${{ github.run_id }}'

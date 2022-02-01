# Repos under management
REPOS='tyk,tyk-analytics,tyk-pump,tyk-sink,tyk-identity-broker,raava'
# Files to update for each repo, changes here need to be in meta.zsh
TARGETS=(.goreleaser.yml .goreleaser-el7.yml Dockerfile.std Dockerfile.slim aws/byol.pkr.hcl .github/workflows/release.yml .github/workflows/del-env.yml integration/terraform/outputs.tf .github/dependabot.yml install/before_install.sh install/post_install.sh install/post_remove.sh install/post_trans.sh)
# For each TARGETS, add SOURCE_SUFFIX to the basename to obtain the source file for that target
SOURCE_SUFFIX=m4

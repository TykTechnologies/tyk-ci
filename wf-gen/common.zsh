# Repos under management
REPOS='tyk,tyk-analytics,tyk-pump,tyk-sink,tyk-identity-broker,raava'
# Files to update for each repo, changes here need to be in meta.zsh
TARGETS=(ci/goreleaser/goreleaser.yml ci/goreleaser/goreleaser-el7.yml ci/Dockerfile.std ci/Dockerfile.slim ci/aws/byol.pkr.hcl .github/workflows/release.yml .github/workflows/del-env.yml ci/terraform/outputs.tf .github/dependabot.yml ci/install/before_install.sh ci/install/post_install.sh ci/install/post_remove.sh ci/install/post_trans.sh)
SYNC_AUTO_TARGETS=(ci .github/workflows/release.yml .github/dependabot.ym )
# For each TARGETS, add SOURCE_SUFFIX to the basename to obtain the source file for that target
SOURCE_SUFFIX=m4

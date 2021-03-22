# Repos under management
REPOS='tyk,tyk-analytics,tyk-pump,tyk-sink'
# Files to update for each repo, changes here need to be in meta.zsh
TARGETS=(.goreleaser.yml Dockerfile.std Dockerfile.slim aws/byol.pkr.hcl .github/workflows/release.yml .github/workflows/del-env.yml integration/terraform/outputs.tf)
# For each TARGETS, add SOURCE_SUFFIX to the basename to obtain the source file for that target
SOURCE_SUFFIX=m4

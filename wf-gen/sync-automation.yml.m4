include(header.m4)
# This workflow will silently ignore FILES that are missing in master
# Most of the time this is what we want, older repos may not have some files

name: Sync automation

on:
  push:
    branches:
      - xSRC_BRANCH
    paths:
      - .github/workflows/*
      - integration/*
      - .goreleaser.yml

env:
  FILES: xAUTO_FILES
  
jobs:
  sync:
    runs-on: ubuntu-latest

    strategy:
      fail-fast: false
      matrix:
        branch: [ xRELEASE_BRANCHES ]
          
    steps:
      - uses: actions/checkout@v2
        with:
          ref: ${{matrix.branch}}

      - name: sync ${{matrix.branch}} from xSRC_BRANCH
        run: |
          git fetch origin xSRC_BRANCH
          git config --local user.email "wf-gen@tyk-ci"
          git config --local user.name "Bender"
          for f in $FILES; do 
            git checkout --theirs origin/xSRC_BRANCH -- $f || true
          done
          git commit -a -m "[CI] Syncing release automation from xSRC_BRANCH"
          git push origin
          echo "::warning::${FILES} syncd for ${{matrix.branch}}"

include(header.m4)
# This workflow will silently ignore FILES that are missing in master
# Most of the time this is what we want, older repos may not have some files

name: Sync automation

on:
  push:
    branches:
      - master
    paths:
      - .github/workflows/*
      - integration/*

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

      - name: sync ${{matrix.branch}} from master
        run: |
          git fetch origin master
          git config --local user.email "wf-gen@tyk-ci"
          git config --local user.name "Bender"
          for f in $FILES; do 
            git checkout --theirs origin/master -- $f || true
          done
          git commit -a -m "[CI] Syncing automation from master"
          git push origin
          echo "::warning::${FILES} syncd for ${{matrix.branch}}"

include(header.m4)
name: Retiring dev env

on:
  delete:
    branches:
      - feature/*
      - integration/*

jobs:
  retire:
    runs-on: ubuntu-latest

    steps:
      - name: Tell gromit about deleted branch
        run: |
            curl -fsSL -H "Authorization: ${{secrets.GROMIT_TOKEN}}" "https://domu-kun.cloud.tyk.io/gromit/env/${GITHUB_REF##*/}" \
                 -X DELETE

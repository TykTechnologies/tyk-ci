include(header.m4)
# Distribution channels covered by this workflow
# - Ubuntu and Debian
# - RHEL/OL
# - tarballs
# - docker hub
# - devenv ECR
# - AWS mktplace
# - Cloudsmith

name: Release

on:
  pull_request:
  push:
    branches:
      - master
      - release-**
      - integration/**
      - feature/**
      - perf/**
    tags:
      - 'v*'

env:
  SLACK_CLI_TOKEN: ${{ secrets.BENDER_TOKEN }}
  
jobs:
include(release/goreleaser.m4)
include(release/ci.m4)
include(release/tests.m4)
include(release/packagecloud.m4)
include(release/aws.m4)

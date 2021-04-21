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
    tags:
      - 'v*'

jobs:
include(release/goreleaser.m4)
include(release/install.m4)
include(release/aws.m4)

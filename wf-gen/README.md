# CI
Orchestrated by github-actions. This repo contains m4 templates for all repos under management, and is responsible for,

- building artefacts
  - amd64
  - arm64
  - slim
  - osx (SDK 10.15)
  - deb
  - rpm
  - std docker image
  - slim docker image
  - AWS PAYG version with special pubkey
  - aws mktplace AMIs
- the artefacts above are pushed to,
  - packagecloud (el, ol, debian and ubuntu)
  - cloudsmith
  - Docker Hub
  - CI ECR
  
# Implementation
[prs.zsh](prs.zsh) renders the m4 templates and creates PRs in the respective repositories. Most of the workflows are triggered by PRs but if they are not, most actions that are public facing are not triggered. Public actions are triggered by pushing tags. cf. [confluence](https://tyktech.atlassian.net/wiki/spaces/EN/pages/449708061/Release+Engineering).

There are three levels of abstraction,

## m4 templates
These template vars are level at which [prs.zsh](prs.zsh) operates. They are defined in [header.m4](header.m4) and are set on the command line when prs.zsh operates. They are defined in header.m4 and are set on the command line in prs.zsh. These are compile time variables for prs.zsh. 

## github variables
These are variables defined like `${{ ... }}` in the code. These are compile time variables for the github actions. An error here will result in the workflow not running due to an syntax error.

## dynamic variables
These are runtime variables which are defined at runtime. These are usually shell variables, with YAML block scope. If they are required between blocks, they have to be defined using [github action output parameters](https://docs.github.com/en/actions/reference/workflow-commands-for-github-actions#setting-an-output-parameter).

## goreleaser
All binary artefacts are _created_ by goreleaser, controlled by a `.goreleaser.yml` file in the root of each repo. These files are generated from [.goreleaser.yml.m4](.goreleaser.yml.m4).

Since goreleaser does not support `CGO_ENABLED=1`, goreleaser runs inside [a specially crafted docker image](https://github.com/TykTechnologies/golang-cross) that contains cross compiler toolchains for arm64 and darwin-amd64. amd64 is the host architecture.

Multi-platform docker images are built by buildx.

deb and rpm files are built by nfpm.

A draft github release with all the assets attached and a changelog is created.

## releaser.yml
This is triggered on pull requests and pushes to release branches. It lives in `.github/workflows/release.yml` in each repo. It is generated from [release.yml.m4](release.yml.m4). It,

- builds artefacts using goreleaser
- tests artefacts for installability on ubuntu, rhel, and debian
- pushes artefacts to cloudsmith, Docker Hub, packagecloud, CI ECR, AWS, and github releases
- notifies Slack

## Dockerfile.std
This is the file used by goreleaser to build the standard image. Based on `debian:buster-slim`.

## Dockerfile.slim
This is the file used by goreleaser to build the slim image. Based on `gcr.io/distroless/static-debian10`. It is populated by the static tarball.

## byol.pkr.hcl
This is the packer manifest for the AWS mktplace AMIs. They live in `aws/` in each repo. The PAYG version with the special PAYG build from goreleaser is also defined here.

## del-env.yml
This is triggered when a branch is deleted and will retire the CD environment if needed. It lives in `.github/workflows/del-env.yml` in each repo.

# Meta-Automation
The github actions based automation lives in git. Thus, the automation triggered will be the version in that branch. How then do we ensure that bugfixes that apply to all versions of the automation will propagate to all needed branches? Enter [meta.zsh](meta.zsh).

[meta.zsh](meta.zsh) controls [sync-automation.yml.m4](sync-automation.yml.m4) the template that is rendered to `.github/workflows/sync-automation.yml` in each repo. This action will sync commits that land on `master` to active release branches. It also knows about old release branches going back to `release-3-lts` and knows where to sync commits that land on branches like `release-3.1` for instance.

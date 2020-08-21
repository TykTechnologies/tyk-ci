terraform {
  required_version = ">= 0.12.16"
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "Tyk"
    workspaces {
      prefix = "base-"
    }
  }
}

provider "aws" {
  version = "= 2.70"
  region = "eu-central-1"
}

# Internal variables
locals {
  # name should match the tf workspace name
  name = "base-prod"
  # Repositories to create
  tyk_repos = ["tyk", "tyk-analytics", "tyk-pump" ]
  # Somehow this works, even on 0.12.0
  common_tags = "${map(
    "managed", "byhand",
    "ou", "devops",
    "purpose", "ci",
    "env", local.name,
  )}"
}

# This is exported in outputs.tf
data "aws_region" "current" {}

# EFS filesystems

resource "aws_efs_file_system" "cfssl" {
  creation_token = "cfssl-keys"

  tags = local.common_tags
}

resource "aws_efs_file_system" "config" {
  creation_token = "dev-env-config"

  tags = local.common_tags
}

# TODO: Lifecycle management for ECR images

resource "aws_ecr_repository" "integration" {
  for_each = toset(local.tyk_repos)
  
  name                 = each.key
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = local.common_tags
}

# Per repo access keys

resource "aws_iam_access_key" "integration" {
  for_each = toset(local.tyk_repos)

  user = aws_iam_user.integration[each.key].name
}

resource "aws_iam_user" "integration" {
  for_each = toset(local.tyk_repos)

  name = "ecr-push_${each.value}"

  tags = local.common_tags
}

resource "aws_iam_user_policy" "integration" {
  for_each = toset(local.tyk_repos)

  name   = "ECRpush-${each.value}"
  user   = "ecr-push_${each.value}"
  policy = data.template_file.per_repo_access[each.value].rendered
}

data "template_file" "per_repo_access" {
  for_each = toset(local.tyk_repos)
  
  template = templatefile("templates/ecr-push-pull.tpl",
                          {resources = [ aws_ecr_repository.integration[each.value].arn ]})
}

# shared dev access key

resource "aws_iam_user" "devshared" {
  name = "ecr-devshared"

  tags = local.common_tags
}

resource "aws_iam_access_key" "devshared" {
  user = aws_iam_user.devshared.name
}

resource "aws_iam_user_policy" "devshared" {
  name   = "ECRpush-devshared"
  user   = "ecr-devshared"
  policy = data.template_file.devshared_access.rendered
}

data "template_file" "devshared_access" {
  template = templatefile("templates/devshared.tpl",
                          {resources = [ for repo in local.tyk_repos: aws_ecr_repository.integration[repo].arn ]})
}

# terraform apply -target=null_resource.debug will show the rendered template
# resource "null_resource" "debug" {
#   triggers = {
#     json = "${data.template_file.tyk_repo_access.rendered}"
#   }
# }


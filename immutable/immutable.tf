terraform {
  required_version = ">= 0.12"
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "Tyk"

    workspaces {
      name = "immutable"
    }
  }
}

provider "aws" {
  version = ">= 2.17"
  region = var.region
}

# Internal variables
locals {
  common_tags = "${map(
    "managed", "byhand",
    "ou", "devops",
    "purpose", "ci",
    "env", var.name,
  )}"
}

resource "aws_efs_file_system" "cfssl" {
  creation_token = "cfssl-keys"

  tags = local.common_tags
}

resource "aws_efs_file_system" "config" {
  creation_token = "dev-env-config"

  tags = local.common_tags
}


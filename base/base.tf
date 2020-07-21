terraform {
  required_version = ">= 0.12.16"
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "Tyk"
    workspaces {
      name = "base-euc1"
    }
  }
}

provider "aws" {
  version = ">= 2.17"
  region = "eu-central-1"
}

# Internal variables
locals {
  # name should match the tf workspace name
  name = "base-euc1"
  # Repositories to create
  repositories = ["tyk", "tyk-analytics", "tyk-pump", "int-service", "cfssl"]
  # Somehow this works, even on 0.12.0
  common_tags = "${map(
    "managed", "byhand",
    "ou", "devops",
    "purpose", "ci",
    "env", local.name,
  )}"
}

data "aws_region" "current" {}

resource "aws_efs_file_system" "cfssl" {
  creation_token = "cfssl-keys"

  tags = local.common_tags
}

resource "aws_efs_file_system" "config" {
  creation_token = "dev-env-config"

  tags = local.common_tags
}

resource "aws_ecr_repository" "integration" {
  for_each = toset(local.repositories)
  
  name                 = each.key
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = local.common_tags
}

resource "null_resource" "int_service" {
  provisioner "local-exec" {
    command = "cd ../int-service; make int-service"
  }
  triggers = {
    ecr_repo = aws_ecr_repository.integration["int-service"].repository_url
  }
}

resource "null_resource" "cfssl" {
  provisioner "local-exec" {
    command = "cd ../cfssl; make cfssl"
  }
  triggers = {
    ecr_repo = aws_ecr_repository.integration["cfssl"].repository_url
  }
}

resource "aws_iam_access_key" "integration" {
  for_each = toset(local.repositories)

  user = aws_iam_user.integration[each.key].name
}

resource "aws_iam_user" "integration" {
  for_each = toset(local.repositories)

  name = "ecr-push_${each.value}"

  tags = local.common_tags
}

resource "aws_iam_user_policy" "integration" {
  for_each = toset(local.repositories)

  name   = "ECRpush"
  user   = "ecr-push_${each.value}"
  policy = <<EOF
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Sid":"GetAuthorizationToken",
         "Effect":"Allow",
         "Action":[
            "ecr:GetAuthorizationToken"
         ],
         "Resource":"*"
      },
       {
         "Sid":"AllowPull",
         "Effect":"Allow",
         "Action":[
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability"
         ],
         "Resource": "${aws_ecr_repository.integration[each.key].arn}"
       },
       {
         "Sid":"AllowPush",
         "Effect":"Allow",
         "Action":[
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability",
            "ecr:PutImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload"
         ],
         "Resource": "${aws_ecr_repository.integration[each.key].arn}"
      }
   ]
}
EOF
}

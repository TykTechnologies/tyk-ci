terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "Tyk"
    workspaces {
      prefix = "base-"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

# Internal variables
locals {
  # name should match the tf workspace name
  name = "base-prod"
  # Repositories to create with per-repo access keys
  repos = ["tyk", "tyk-analytics", "tyk-pump", "tyk-sink", "tyk-identity-broker", "raava"]
  # An additional repo that will be linked to the tyk user from repos above
  tyk_repos = ["tyk-plugin-compiler"]
  common_tags = {
    "managed" = "automation",
    "ou"      = "devops",
    "purpose" = "ci",
    "env"     = local.name
  }
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

resource "aws_ecr_repository" "integration" {
  for_each = toset(concat(local.repos, local.tyk_repos))

  name                 = each.key
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = local.common_tags
}

resource "aws_ecr_lifecycle_policy" "retain_2w" {
  for_each = toset(concat(local.repos, local.tyk_repos))

  repository = each.key

  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Expire untagged images older than 1 week",
            "selection": {
                "tagStatus": "untagged",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 7
            },
            "action": {
                "type": "expire"
            }
        },
        {
            "rulePriority": 2,
            "description": "Expire all images older than 2 weeks",
            "selection": {
                "tagStatus": "any",
                "countType": "sinceImagePushed",
                "countUnit": "days",
                "countNumber": 14
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}

# Per repo access keys

resource "aws_iam_access_key" "integration" {
  for_each = toset(local.repos)

  user = aws_iam_user.integration[each.key].name
}

resource "aws_iam_user" "integration" {
  for_each = toset(local.repos)

  name = "ecr-push_${each.value}"

  tags = local.common_tags
}

resource "aws_iam_user_policy" "integration" {
  for_each = toset(local.repos)

  name   = "ECRpush-${each.value}"
  user   = "ecr-push_${each.value}"
  policy = data.template_file.per_repo_access[each.value].rendered
}

data "template_file" "per_repo_access" {
  for_each = toset(local.repos)

  template = templatefile("templates/deployment.tpl",
    {
      ecrs = [aws_ecr_repository.integration[each.value].arn],
  })
}

# Give the tyk user access to plugin-compiler repo

resource "aws_iam_policy" "plugin-compiler" {
  name        = "plugin-compiler"
  path        = "/"
  description = "ecr-push_tyk user can push to plugin-compiler ECR"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Effect   = "Allow"
        Resource = aws_ecr_repository.integration["tyk-plugin-compiler"].arn
      },
    ]
  })
}

resource "aws_iam_user_policy_attachment" "plugin-compiler" {
  for_each = toset(local.tyk_repos)

  user       = aws_iam_user.integration["tyk"].name
  policy_arn = aws_iam_policy.plugin-compiler.arn
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
  { resources = [for repo in local.repos : aws_ecr_repository.integration[repo].arn] })
}

# terraform apply -target=null_resource.debug will show the rendered template
# resource "null_resource" "debug" {
#   triggers = {
#     json = "${data.template_file.tyk_repo_access.rendered}"
#   }
# }


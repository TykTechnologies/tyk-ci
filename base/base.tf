provider "aws" {
  region = "eu-central-1"
}

# Internal variables
locals {
  # name should match the tf workspace name
  name = "base-prod"
  # Repositories to create with per-repo access keys
  repos = ["tyk", "tyk-analytics", "tyk-pump", "tyk-sink", "tyk-identity-broker", "portal", "tyk-sync"]
  # An additional repo that will be linked to the tyk user from repos above
  tyk_repos = ["tyk-plugin-compiler"]
  # repo list based on release cadence
  low_cadence_repos = ["tyk-pump", "tyk-sink", "tyk-identity-broker", "portal", "tyk-sync", "tyk-plugin-compiler","tyk-automated-tests"]
  high_cadence_repos = ["tyk", "tyk-analytics"]

  pr_policy1 = jsondecode(file("files/pr_policy.json"))
  pr_policy2 = jsondecode(file("files/retain_all.json"))

  combined_policy = jsonencode({
    "rules": concat(local.pr_policy1.rules, local.pr_policy2.rules)
  })

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

resource "aws_efs_file_system" "ca" {
  creation_token = "ca-keys"

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

resource "aws_ecr_lifecycle_policy" "low_cadence" {
  
  for_each = toset(local.low_cadence_repos)

  depends_on = [aws_ecr_repository.integration]
  repository = each.key

  policy = file("files/pr_policy.json")

}

resource "aws_ecr_lifecycle_policy" "high_cadence" {
  for_each = toset(local.high_cadence_repos)

  depends_on = [aws_ecr_repository.integration]
  repository = each.key

  policy = local.combined_policy

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

# AWS - Github OIDC
# https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html
resource "aws_iam_openid_connect_provider" "github" {
      url             = "https://token.actions.githubusercontent.com"
      client_id_list  = ["sts.amazonaws.com"]
      thumbprint_list = data.tls_certificate.github.certificates[*].sha1_fingerprint
      tags            = local.common_tags
}

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

# terraform apply -target=null_resource.debug will show the rendered template
# resource "null_resource" "debug" {
#   triggers = {
#     json = "${data.template_file.tyk_repo_access.rendered}"
#   }
# }


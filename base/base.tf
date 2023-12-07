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

# Allow assume role from Github Actions
data "aws_iam_policy_document" "github_actions" {
  statement {
    sid     = "gha"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "repo:TykTechnologies/*",
        "repo:tyklabs/*",
      ]
    }

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::754489498669:oidc-provider/token.actions.githubusercontent.com"]
    }
  }
}

resource "aws_iam_role" "ecr_rw_tyk" {
  name               = "ecr_rw_tyk"
  assume_role_policy = data.aws_iam_policy_document.github_actions.json
}

resource "aws_iam_role_policy_attachment" "cipush" {
  role       = aws_iam_role.ecr_rw_tyk.name
  policy_arn = aws_iam_policy.cipush.arn
}

resource "aws_iam_policy" "cipush" {
  name        = "cipush"
  path        = "/"
  description = "allow push to ECR from release.yml"

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
        Resource = "*"
      },
    ]
  })
}

# terraform apply -target=null_resource.debug will show the rendered template
# resource "null_resource" "debug" {
#   triggers = {
#     json = "${data.template_file.tyk_repo_access.rendered}"
#   }
# }


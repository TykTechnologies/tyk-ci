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

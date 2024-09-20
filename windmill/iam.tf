data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# to decrypt secrets in SSM
data "aws_iam_policy_document" "ssm_decrypt" {
  statement {
    sid = "kms"
    actions = [
      "kms:Decrypt"
    ]

    resources = [data.terraform_remote_state.base.outputs.kms]
  }

  statement {
    sid = "ssm"
    actions = [
      "ssm:GetParameters"
    ]

    resources = [data.aws_ssm_parameter.windmill_db_url.arn]
  }

  statement {
    sid = "logs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role" "windmill" {
  name = "windmill"
  path = "/infra/windmill/"

  inline_policy {
    name   = "ssm-decrypt"
    policy = data.aws_iam_policy_document.ssm_decrypt.json
  }
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
}


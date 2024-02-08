data "aws_iam_policy_document" "ecs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# extra stuff beyond the AWS managed AmazonECSServiceRolePolicy that tasks need
data "aws_iam_policy_document" "extra" {
  statement {
    sid = "ecr"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }

  statement {
    sid = "efs"
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:DescribeMountTargets",
      "elasticfilesystem:DescribeFileSystems"
    ]

    resources = [aws_efs_file_system.shared.arn]
  }
}

# ter is required for the task to start. We create it in one shot
# instead of using role_policy_attachment resources as this role is
# managed exclusively by terraform
resource "aws_iam_role" "ter" {
  name = "ter"
  path = "/cd/"

  inline_policy {
    name   = "extra-ter"
    policy = data.aws_iam_policy_document.extra.json
  }
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy.json
  #managed_policy_arns = ["arn:aws:iam::aws:policy/aws-service-role/AmazonECSServiceRolePolicy"]
}

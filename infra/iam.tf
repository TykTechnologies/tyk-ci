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

    resources = [data.aws_efs_file_system.shared.arn]
  }
}

data "aws_efs_file_system" "shared" {
  file_system_id = data.terraform_remote_state.base.outputs.shared_efs
}


# ter is required for the CD task to start. We create it in one shot
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

resource "aws_s3_bucket_policy" "deptrack_lb_logs" {
  bucket = data.terraform_remote_state.base.outputs.assets
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::054676820928:root"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${data.terraform_remote_state.base.outputs.assets}/deptrack-lb/AWSLogs/754489498669/*"
    }
  ]
}
EOF
}

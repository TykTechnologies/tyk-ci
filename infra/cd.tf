# Common resources used by all CD tasks

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

  statement {
    sid = "envfiles"
    actions = [
      "s3:GetObject"
    ]

    resources = ["arn:aws:s3:::${data.terraform_remote_state.base.outputs.assets}/envfiles/*"]
  }

  statement {
    sid = "secrets"
    actions = [
      "ssm:GetParameters",
      "kms:Decrypt"
    ]

    resources = [
      data.terraform_remote_state.base.outputs.kms,
      "arn:aws:ssm:eu-central-1:754489498669:parameter/cd/*"
    ]
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

# ecr_rw_tyk is created in base but ter is created here. We need to
# know ter so that we can give ecr_rw_tyk the minimum permission
# boundary
data "aws_iam_role" "ecr_rw_tyk" {
  name = "ecr_rw_tyk"
}

resource "aws_iam_policy" "ecs_deploy" {
  name        = "ecs_deploy"
  path        = "/cd/deploy/"
  description = "Allows ECS tasks to be updated"

  policy = <<-EOF
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Sid":"RegisterTaskDefinition",
         "Effect":"Allow",
         "Action":[
            "ecs:RegisterTaskDefinition"
         ],
         "Resource":"*"
      },
      {
         "Sid":"PassRolesInTaskDefinition",
         "Effect":"Allow",
         "Action":[
            "iam:PassRole"
         ],
         "Resource":[
            "${data.aws_iam_role.ecr_rw_tyk.arn}"
         ]
      },
      {
         "Sid":"DeployService",
         "Effect":"Allow",
         "Action":[
            "ecs:UpdateService",
            "ecs:DescribeServices"
         ],
         "Resource":[
            "arn:aws:ecs:eu-central-1:754489498669:service/*"
         ]
      }
   ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_deploy" {
  role       = data.aws_iam_role.ecr_rw_tyk.name
  policy_arn = aws_iam_policy.ecs_deploy.arn
}

resource "aws_ssm_parameter" "ter" {
  name        = "/cd/ter"
  type        = "String"
  description = "Task execution role ARN for CD tasks"
  value       = aws_iam_role.ter.arn
}

resource "aws_s3_bucket_policy" "deptrack_lb_logs" {
  bucket = data.terraform_remote_state.base.outputs.assets
  policy = <<-EOF
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

resource "aws_security_group" "cd_tasks" {
  name        = "cd-tasks"
  description = "EFS, gw, dash"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ssm_parameter" "cd_sg" {
  name        = "/cd/sg"
  type        = "String"
  description = "Security group ID for CD tasks"
  value       = aws_security_group.cd_tasks.id
}

resource "aws_vpc_security_group_ingress_rule" "gw" {
  security_group_id = aws_security_group.cd_tasks.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "dash" {
  security_group_id = aws_security_group.cd_tasks.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 3000
  to_port           = 3000
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "efs" {
  security_group_id = aws_security_group.cd_tasks.id
  cidr_ipv4         = data.terraform_remote_state.base.outputs.vpc.cidr
  from_port         = 2049
  to_port           = 2049
  ip_protocol       = "tcp"
}

# Runtime permissions

data "aws_iam_policy" "gromit_tr" {
  for_each = toset(local.policies)
  arn      = "arn:aws:iam::aws:policy/${each.value}"
}

data "aws_iam_policy_document" "gromit_tr" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "logs" {
  statement {
    actions = [
      "logs:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "logs" {
  name = "cw-logs"
  role = aws_iam_role.gromit_tr.id

  policy = data.aws_iam_policy_document.logs.json
}

resource "aws_iam_role" "gromit_tr" {
  name = "gromit"
  assume_role_policy = data.aws_iam_policy_document.gromit_tr.json
  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "gromit_tr" {
  for_each = toset(local.policies)

  role       = aws_iam_role.gromit_tr.id
  policy_arn = data.aws_iam_policy.gromit_tr[each.value].arn
}

# Init time permissions

# Extra stuff
# ecs:RunTask and iam:PassRole req'd for scheduled tasks
# logs:* added due to errors seen on the console
data "aws_iam_policy_document" "gromit_ter" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "kms:Decrypt"
    ]
    resources = [
      "arn:aws:secretsmanager:eu-central-1:754489498669:secret:TFCloudAPI-1UnG8y",
      "arn:aws:kms:eu-central-1:754489498669:key/17432de6-5a75-4a4a-b32e-ff8d8efd277f"
    ]
  }

  statement {
    actions = [
      "iam:PassRole",
      "ecs:RunTask",
      "logs:DescribeLogStreams"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "gromit_ter" {
  name   = "gromit-init"
  policy = data.aws_iam_policy_document.gromit_ter.json
}

# Permissions needed to start a gromit task via schedule or by service
resource "aws_iam_role" "gromit_ter" {
  name        = "gromit-ecs-init"
  description = "Permissions required at task init"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   },
   {
     "Sid": "",
     "Effect": "Allow",
     "Principal": {
       "Service": "events.amazonaws.com"
     },
     "Action": "sts:AssumeRole"
   }
 ]
}
EOF
  
  tags               = local.common_tags
}

# To be able to pull from ECR
resource "aws_iam_role_policy_attachment" "ecs_init" {
  role       = aws_iam_role.gromit_ter.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "gromit_ter" {
  role   = aws_iam_role.gromit_ter.id
  policy_arn = aws_iam_policy.gromit_ter.arn
}


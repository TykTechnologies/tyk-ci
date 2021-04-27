# Runtime permissions

data "aws_iam_policy_document" "gromit_tr" {
  statement {
    actions = [
      "secretsmanager:*",
      "kms:Decrypt"
    ]
    resources = [
      "arn:aws:secretsmanager:eu-central-1:754489498669:secret:TFCloudAPI-1UnG8y",
      "arn:aws:kms:eu-central-1:754489498669:key/17432de6-5a75-4a4a-b32e-ff8d8efd277f",
      "arn:aws:secretsmanager:eu-central-1:754489498669:secret:DashTrialLicense-7EzdZh",
      "arn:aws:secretsmanager:eu-central-1:754489498669:secret:MDCBTrialLicense-9BIRjv"
    ]
  }

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com", "chatbot.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "chatops" {
  statement {
    actions = [
      "logs:*",
      "chatbot:DescribeSlackChannelConfigurations"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "chatops" {
  name = "chatops"
  role = aws_iam_role.gromit_tr.id

  policy = data.aws_iam_policy_document.chatops.json
}

resource "aws_iam_role" "gromit_tr" {
  name               = "gromit"
  assume_role_policy = data.aws_iam_policy_document.gromit_tr.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "gromit_tr" {
  for_each = toset(local.policies)

  role       = aws_iam_role.gromit_tr.id
  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
}

# Deployment automation user

resource "aws_iam_access_key" "deployment" {
  user = aws_iam_user.deployment.name
}

resource "aws_iam_user" "deployment" {
  name = "github-actions"

  tags = local.common_tags
}

resource "aws_iam_user_policy_attachment" "deployment1" {
  for_each = toset(local.policies)

  user       = aws_iam_user.deployment.id
  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
}

resource "aws_iam_user_policy" "deployment" {
  name = "deployment"
  user = aws_iam_user.deployment.id

  policy = data.aws_iam_policy_document.gromit_ter.json
}

# Extra permissions required for deployment via CD
resource "aws_iam_user_policy_attachment" "deployment2" {
  for_each = toset(local.deployment_policies)

  user       = aws_iam_user.deployment.id
  policy_arn = "arn:aws:iam::aws:policy/${each.value}"
}

# Init time permissions

# Extra stuff
# ecs:RunTask and iam:PassRole req'd for scheduled tasks
# logs:* added due to errors seen on the console
data "aws_iam_policy_document" "gromit_ter" {
  statement {
    actions = [
      "secretsmanager:*",
      "kms:Decrypt"
    ]
    resources = [
      "arn:aws:secretsmanager:eu-central-1:754489498669:secret:TFCloudAPI-1UnG8y",
      "arn:aws:kms:eu-central-1:754489498669:key/17432de6-5a75-4a4a-b32e-ff8d8efd277f",
      "arn:aws:secretsmanager:eu-central-1:754489498669:secret:DashTrialToken-BfNk9B",
      "arn:aws:secretsmanager:eu-central-1:754489498669:secret:MDCBTrialToken-5zTlhf",
      "arn:aws:secretsmanager:eu-central-1:754489498669:secret:GromitServeKey-pkgkwi"
    ]
  }

  statement {
    actions = [
      "logs:*",
      "events:*",
      "ecs:RunTask",
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::ara-bundles-live"
    ]
  }

  statement {
    actions = [
      "iam:PassRole",
      "iam:PutUserPolicy",
      "iam:PassRole",
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

  tags = local.common_tags
}

# To be able to pull from ECR
resource "aws_iam_role_policy_attachment" "ecs_init" {
  role       = aws_iam_role.gromit_ter.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "gromit_ter" {
  role       = aws_iam_role.gromit_ter.id
  policy_arn = aws_iam_policy.gromit_ter.arn
}

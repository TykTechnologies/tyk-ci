# Gromit ECS task execution role

data "aws_iam_policy" "gromit" {
  for_each = toset(local.policies)
  arn      = "arn:aws:iam::aws:policy/${each.value}"
}

resource "aws_iam_role" "gromit" {
  name = "gromit"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "gromit" {
  for_each = toset(local.policies)

  role       = aws_iam_role.gromit.id
  policy_arn = data.aws_iam_policy.gromit[each.value].arn
}

# To be able to pull from ECR
resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.ecs_role.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "gromit_ecs" {
  name        = "gromit-ecs"
  description = "Start tasks via schedule"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "kms:Decrypt"
      ],
      "Resource": [
        "arn:aws:secretsmanager:eu-central-1:754489498669:secret:TFCloudAPI-1UnG8y",
        "arn:aws:kms:eu-central-1:754489498669:key/17432de6-5a75-4a4a-b32e-ff8d8efd277f"
      ]
    },
    {
        "Effect": "Allow",
        "Action": [
           "iam:PassRole",
           "logs:CreateLogStream",
           "logs:PutLogEvents"
        ],
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": "ecs:RunTask",
        "Resource": "*"
    }

  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "gromit_ecs" {
  role       = aws_iam_role.ecs_role.name
  policy_arn = aws_iam_policy.gromit_ecs.arn
}

resource "aws_iam_role" "ecs_role" {
  name = "ecsExecutionRole"

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
}

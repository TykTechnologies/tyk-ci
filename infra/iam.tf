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

resource "aws_iam_policy" "gromit_terraform" {
  name        = "gromit-terraform"
  description = "Access to remote state in TFCloud"
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
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "gromit_terraform" {
  role       = aws_iam_role.ecs_role.name
  policy_arn = aws_iam_policy.gromit_terraform.arn
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
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_role" {
  role       = aws_iam_role.ecs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_events" {
  name = "ecs_events"

  assume_role_policy = <<DOC
{
  "Version": "2012-10-17",
  "Statement": [
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
DOC
}

resource "aws_iam_role_policy" "ecs_events_run_task" {
  name = "ecs_events_run_task"
  role = aws_iam_role.ecs_events.id

  policy = <<DOC
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "iam:PassRole",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "ecs:RunTask",
            "Resource": "${replace(aws_ecs_task_definition.gromit_run.arn, "/:\\d+$/", ":*")}"
        }
    ]
}
DOC
}

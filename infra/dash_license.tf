data "template_file" "licenser" {
  template = templatefile("templates/cd-awsvpc.tpl",
    { port      = 443,
      name      = "licenser",
      log_group = "internal",
      image     = "debian:buster",
      command   = ["curl", "https://bots.cluster.internal.tyk.technology/license-bot/dashboard-trial", "-o /config/dash.license"],
      mounts = [
        { src = "config", dest = "/config", readonly = false }
      ],
      env = [],
      secrets = [],
  region = var.region })
}

resource "aws_ecs_task_definition" "licenser" {
  family                   = "licenser"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_role.arn
  task_role_arn            = aws_iam_role.gromit.arn
  cpu                      = 256
  memory                   = 512

  container_definitions = data.template_file.licenser.rendered

  volume {
    name = "config"

    efs_volume_configuration {
      file_system_id = var.config_efs
      root_directory = "/"
    }
  }

  depends_on = [aws_cloudwatch_log_group.internal]

  tags = local.common_tags
}

resource "aws_security_group" "licenser" {
  name        = "licenser"
  description = "Allow only outbound traffic"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_event_rule" "licenser" {
  name                = "licenser-rule"
  schedule_expression = "rate(29 days)"
}

resource "aws_cloudwatch_event_target" "licenser" {
  target_id = "licenser"
  rule      = aws_cloudwatch_event_rule.licenser.name
  arn       = aws_ecs_cluster.internal.arn
  role_arn  = aws_iam_role.ecs_role.arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.licenser.arn
    launch_type         = "FARGATE"
    platform_version    = "1.4.0"

    network_configuration {
      subnets         = module.vpc.private_subnets
      security_groups = [aws_security_group.licenser.id]
    }
  }
}

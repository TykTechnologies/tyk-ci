data "template_file" "gromit_run" {
  template = templatefile("templates/cd-awsvpc.tpl",
    { port      = 443,
      name      = "grun",
      log_group = "internal",
      image     = var.gromit_image,
      command   = ["run"],
      mounts = [
        { src = "config", dest = "/config", readonly = false }
      ],
      env = [
        { name = "GROMIT_TABLENAME", value = local.gromit.table },
        { name = "GROMIT_REPOS", value = local.gromit.repos },
        { name = "GROMIT_DOMAIN", value = local.gromit.domain },
        { name = "GROMIT_ZONEID", value = aws_route53_zone.dev_tyk_tech.zone_id }
      ],
      secrets = [
        { name = "TF_API_TOKEN", from = "arn:aws:secretsmanager:eu-central-1:754489498669:secret:TFCloudAPI-1UnG8y" }
      ],
  region = var.region })
}

resource "aws_ecs_task_definition" "gromit_run" {
  family                   = "gromit_run"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_role.arn
  task_role_arn            = aws_iam_role.gromit.arn
  cpu                      = 256
  memory                   = 512

  container_definitions = data.template_file.gromit_run.rendered

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

resource "aws_security_group" "gromit_run" {
  name        = "gromit_run"
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

resource "aws_cloudwatch_event_rule" "gromit_run" {
  name                = "gromit-run-rule"
  schedule_expression = "rate(37 minutes)"
}

resource "aws_cloudwatch_event_target" "gromit_run" {
  target_id = "gromit-run"
  rule      = aws_cloudwatch_event_rule.gromit_run.name
  arn       = aws_ecs_cluster.internal.arn
  role_arn  = aws_iam_role.ecs_role.arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.gromit_run.arn
    launch_type         = "FARGATE"
    platform_version    = "1.4.0"

    network_configuration {
      subnets         = module.vpc.private_subnets
      security_groups = [aws_security_group.gromit_run.id]
    }
  }
}

data "template_file" "cd" {
  template = templatefile(var.cdt, merge(var.cd, { port = null }))
}

resource "aws_ecs_task_definition" "td" {
  family                   = var.cd.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = var.tearn
  task_role_arn            = var.trarn
  cpu                      = 256
  memory                   = 512

  container_definitions = data.template_file.cd.rendered

  dynamic "volume" {
    for_each = var.cd.mounts[*].src
    content {
      name = volume.value

      efs_volume_configuration {
        file_system_id = var.volume_map[volume.value]
        root_directory = "/"
      }
    }
  }
}

resource "aws_security_group" "sg" {
  name        = var.cd.name
  description = "Allow only outbound traffic"
  vpc_id      = var.vpc

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_event_rule" "cw_erule" {
  name                = var.cd.name
  schedule_expression = var.schedule
}

resource "aws_cloudwatch_event_target" "cw_etarget" {
  target_id = var.cd.name
  rule      = aws_cloudwatch_event_rule.cw_erule.name
  arn       = var.cluster
  role_arn  = var.tearn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.td.arn
    launch_type         = "FARGATE"
    platform_version    = "1.4.0"

    network_configuration {
      subnets         = var.subnets
      security_groups = [aws_security_group.sg.id]
    }
  }
}

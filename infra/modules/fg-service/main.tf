data "template_file" "cd" {
  template = templatefile(var.cdt, var.cd)
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
    for_each = toset(var.cd.mounts[*].src)
    content {
      name = volume.value

      efs_volume_configuration {
        file_system_id = var.volume_map[volume.value].fs_id
        root_directory = var.volume_map[volume.value].root
      }
    }
  }
}

resource "aws_security_group" "sg" {
  name        = var.cd.name
  description = format("For service %s", var.cd.name)
  vpc_id      = var.vpc

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_security_group_ingress_rule" "ing_port" {
  security_group_id = aws_security_group.sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = var.cd.port
  to_port           = var.cd.port
  ip_protocol       = "tcp"
}

data "aws_vpc" "vpc" {
  id = var.vpc
}

resource "aws_vpc_security_group_ingress_rule" "efs" {
  security_group_id = aws_security_group.sg.id
  cidr_ipv4         = data.aws_vpc.vpc.cidr_block
  from_port         = 2049
  to_port           = 2049
  ip_protocol       = "tcp"
}

resource "aws_ecs_service" "service" {
  name            = var.cd.name
  cluster         = var.cluster
  task_definition = aws_ecs_task_definition.td.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnets
    security_groups  = [aws_security_group.sg.id]
    assign_public_ip = var.public_ip
  }
}

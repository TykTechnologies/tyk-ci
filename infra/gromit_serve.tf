data "template_file" "gromit_serve" {
  template = templatefile("templates/cd-awsvpc.tpl",
    { port      = 443,
      name      = "gserve",
      log_group = "internal",
      image     = var.gromit_image,
      command   = [ "serve", "--certpath=/cfssl" ],
      mounts = [
        { src = "cfssl", dest = "/cfssl" },
        { src = "config", dest = "/config" }
      ],
      env = [
        { name = "GROMIT_TABLENAME", value = local.gromit.table },
        { name = "GROMIT_REGISTRYID", value = data.aws_caller_identity.current.account_id },
        { name = "GROMIT_REPOS", value = local.gromit.repos }
      ],
      secrets = [],
  region = var.region })
}

data "aws_caller_identity" "current" {}

resource "aws_ecs_task_definition" "gromit_serve" {
  family                   = "gromit_serve"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_role.arn
  task_role_arn            = var.gromit_role_arn
  cpu                      = 256
  memory                   = 512

  container_definitions = data.template_file.gromit_serve.rendered

  volume {
    name = "config"

    efs_volume_configuration {
      file_system_id = var.config_efs
      root_directory = "/"
    }
  }

  volume {
    name = "cfssl"

    efs_volume_configuration {
      file_system_id = var.cfssl_efs
      root_directory = "/gromit/server"
    }
  }

  depends_on = [aws_cloudwatch_log_group.internal]

  tags = local.common_tags
}

resource "aws_security_group" "gromit_serve" {
  name        = "gromit_serve"
  description = "Allow traffic from anywhere"
  vpc_id      = module.vpc.vpc_id


  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_ecs_service" "gromit_serve" {
  name            = "gromit_serve"
  cluster         = aws_ecs_cluster.internal.id
  task_definition = aws_ecs_task_definition.gromit_serve.id
  desired_count   = 1
  launch_type     = "FARGATE"
  # Needed for EFS
  platform_version = "1.4.0"

  network_configuration {
    subnets          = module.vpc.public_subnets
    security_groups  = [aws_security_group.gromit_serve.id]
    assign_public_ip = true
  }

  tags = local.common_tags
}

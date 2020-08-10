data "template_file" "cfssl" {
  template = templatefile("templates/cd-awsvpc.tpl",
    { port      = 8888,
      name      = "cfssl",
      log_group = "internal",
      image     = var.cfssl_image,
      command   = ["-port=8888", "-ca=rootca/rootca.pem", "-ca-key=rootca/rootca-key.pem", "-config=rootca/config.json", "-loglevel", "1"],
      mounts = [
        { src = "cfssl", dest = "/cfssl" }
      ],
      region = var.region,
      env = [
        { name = "CFSSL_API_KEY", value = var.cfssl_apikey }
      ],
      secrets = [] })
}

resource "aws_ecs_task_definition" "cfssl" {
  family                   = "cfssl"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_role.arn
  cpu                      = 256
  memory                   = 512

  container_definitions = data.template_file.cfssl.rendered

  volume {
    name = "cfssl"

    efs_volume_configuration {
      file_system_id = var.cfssl_efs
      root_directory = "/"
    }
  }

  depends_on = [aws_cloudwatch_log_group.internal]

  tags = local.common_tags
}

resource "aws_security_group" "cfssl" {
  name        = "cfssl"
  description = "Allow traffic from anywhere"
  vpc_id      = module.vpc.vpc_id


  ingress {
    from_port   = 8888
    to_port     = 8888
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

resource "aws_ecs_service" "cfssl" {
  name            = "cfssl"
  cluster         = aws_ecs_cluster.internal.id
  task_definition = aws_ecs_task_definition.cfssl.id
  desired_count   = 1
  launch_type     = "FARGATE"
  # Needed for EFS
  platform_version = "1.4.0"

  network_configuration {
    subnets          = module.vpc.public_subnets
    security_groups  = [aws_security_group.cfssl.id]
    assign_public_ip = true
  }

  tags = local.common_tags
}


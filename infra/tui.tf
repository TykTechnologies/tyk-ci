# tui.dev

module "tui" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name             = "tui"
  cluster_arn      = aws_ecs_cluster.internal.arn
  assign_public_ip = false
  launch_type      = "FARGATE"

  volume = {
    tui_shared = {
      efs_volume_configuration = {
        file_system_id = data.terraform_remote_state.base.outputs.shared_efs
        root_directory = "/tui"
      }

    }
  }

  cpu           = 256 # 0.25 vCPU
  memory        = 512
  desired_count = 1
  container_definitions = {
    tui = {
      cpu     = 256
      memory  = 512
      image   = var.gromit_image
      command = ["--textlogs=false", "policy", "serve", "--save=/shared", "--port=:80"]

      environment = []
      secrets = [
        { name = "CREDENTIALS", valueFrom = aws_ssm_parameter.tui_credentials.arn }
      ]
      port_mappings = [
        {
          name          = "tui"
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
      mount_points = [
        {
          sourceVolume  = "tui_shared"
          containerPath = "/shared"
        }
      ]
      health_check = {
        command     = ["CMD-SHELL", "curl -f http://localhost/ping || exit 1"]
        interval    = 300
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }
      log_configuration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "internal"
          awslogs-region        = "eu-central-1"
          awslogs-stream-prefix = "tui"
        }
      }
    }
  }
  subnet_ids = data.terraform_remote_state.base.outputs.vpc.public_subnets
  load_balancer = {
    service = {
      target_group_arn = aws_lb_target_group.tui.arn
      container_name   = "tui"
      container_port   = 80
    }
  }

  create_task_exec_iam_role = false
  create_task_exec_policy   = false
  task_exec_iam_role_arn    = aws_iam_role.ter.arn
  create_security_group     = false
  security_group_ids        = [aws_security_group.tui.id]
}

resource "aws_security_group" "tui" {
  name        = "tui"
  description = "EFS, http"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.tui.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "efs_tui" {
  security_group_id = aws_security_group.tui.id
  cidr_ipv4         = data.terraform_remote_state.base.outputs.vpc.cidr
  from_port         = 2049
  to_port           = 2049
  ip_protocol       = "tcp"
}

resource "aws_lb_target_group" "tui" {
  name        = "tui"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc.id
}

resource "aws_lb" "tui" {
  name               = "tui"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tui.id]
  subnets            = data.terraform_remote_state.base.outputs.vpc.public_subnets

  # FIXME: enable before making public
  enable_deletion_protection = false

  access_logs {
    bucket  = data.terraform_remote_state.base.outputs.assets
    prefix  = "tui-lb"
    enabled = true
  }

  connection_logs {
    bucket  = data.terraform_remote_state.base.outputs.assets
    prefix  = "tui-lb"
    enabled = true
  }
}

resource "aws_lb_listener" "tui" {
  load_balancer_arn = aws_lb.tui.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tui.arn
  }
}

resource "aws_route53_record" "tui" {
  zone_id = data.terraform_remote_state.base.outputs.dns.zone_id

  name = "tui.internal"
  type = "CNAME"
  ttl  = "300"

  records = [aws_lb.tui.dns_name]
}

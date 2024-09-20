# windmill.dev

module "server" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name                     = "server"
  cluster_arn              = aws_ecs_cluster.windmill.arn
  assign_public_ip         = false
  requires_compatibilities = ["EC2"]
  launch_type              = "EC2"

  #depends_on = [aws_lb_listener.windmill]

  cpu           = 1024
  memory        = 1536
  desired_count = 1
  container_definitions = {
    windmill-server = {
      cpu    = 1024
      memory = 1536
      image  = "${local.wmill_image}"

      readonly_root_filesystem = false
      environment = [
        { name = "MODE", value = "server" },
        { name = "JSON_FMT", value = "true" }
      ]
      secrets = [
        { name = "DATABASE_URL", valueFrom = data.aws_ssm_parameter.windmill_db_url.arn }
      ]
      port_mappings = [
        {
          name          = "windmill-server"
          containerPort = local.wmill_port
          hostPort      = local.wmill_port
          protocol      = "tcp"
        }
      ]
      health_check = {
        command     = ["CMD-SHELL", "curl -f http://localhost:${local.wmill_port}/api/version || exit 1"]
        interval    = 300
        timeout     = 5
        retries     = 3
        startPeriod = 30
      }
      log_configuration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "windmill"
          awslogs-region        = "eu-central-1"
          awslogs-stream-prefix = "server"
        }
      }
    }
  }
  subnet_ids = data.terraform_remote_state.base.outputs.vpc.public_subnets
  load_balancer = {
    service = {
      target_group_arn = aws_lb_target_group.server.arn
      container_name   = "windmill-server"
      container_port   = local.wmill_port
    }
  }

  create_task_exec_iam_role = false
  create_task_exec_policy   = false
  task_exec_iam_role_arn    = aws_iam_role.windmill.arn
  create_security_group     = false
  security_group_ids        = [aws_security_group.windmill.id]
}

resource "aws_lb_target_group" "server" {
  name        = "windmill-server"
  port        = local.wmill_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc.id
}

data "aws_security_group" "http_s" {
  name = "http_s"
}

resource "aws_lb" "windmill" {
  name               = "windmill"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.windmill.id]
  subnets            = data.terraform_remote_state.base.outputs.vpc.public_subnets

  # FIXME: enable before making public
  enable_deletion_protection = false

  access_logs {
    bucket  = data.terraform_remote_state.base.outputs.assets
    prefix  = "windmill-lb"
    enabled = true
  }

  connection_logs {
    bucket  = data.terraform_remote_state.base.outputs.assets
    prefix  = "windmill-lb"
    enabled = true
  }
}

resource "aws_lb_listener" "windmill" {
  load_balancer_arn = aws_lb.windmill.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.terraform_remote_state.base.outputs.dns.cert

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.server.arn
  }
}

resource "aws_route53_record" "windmill" {
  zone_id = data.terraform_remote_state.base.outputs.dns.zone_id

  name = "windmill"
  type = "CNAME"
  ttl  = "300"

  records = [aws_lb.windmill.dns_name]
}

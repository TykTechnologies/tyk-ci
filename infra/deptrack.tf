# Dependency Track

locals {
  # ports
  dtrack_port    = 8080
  dtrack_version = "4.10.0"
  dtrack_tags = {
    purpose = "security"
  }
}

resource "aws_ecs_cluster" "deptrack" {
  name = "deptrack"
  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.deptrack.name
      }
    }
  }
  tags = local.dtrack_tags
}

resource "aws_cloudwatch_log_group" "deptrack" {
  name = "deptrack"

  retention_in_days = 7
  tags              = local.dtrack_tags
}

resource "aws_security_group" "deptrack" {
  name        = "deptrack"
  description = "For DependencyTrack on Fargate"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = local.dtrack_tags
}

resource "aws_vpc_security_group_ingress_rule" "deptrack" {
  for_each = toset([for p in [2049, local.dtrack_port] : tostring(p)])

  security_group_id = aws_security_group.deptrack.id
  cidr_ipv4         = module.vpc.vpc_cidr_block
  from_port         = each.key
  to_port           = each.key
  ip_protocol       = "tcp"
  tags              = local.dtrack_tags
}

module "deptrack_api" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name             = "deptrack-api"
  cluster_arn      = aws_ecs_cluster.deptrack.arn
  assign_public_ip = true

  cpu           = 4096
  memory        = 16384
  desired_count = 1
  container_definitions = {
    deptrack-api = {
      cpu                      = 4096
      memory                   = 16384
      image                    = "dependencytrack/apiserver:${local.dtrack_version}"
      readonly_root_filesystem = false
      memory_reservation       = 8192
      mount_points = [
        { sourceVolume = "dtrack-data", containerPath = "/root" }
      ]
      environment = [
        { name = "ALPINE_CORS_ENABLED", value = "true" },
        { name = "ALPINE_CORS_ALLOW_ORIGIN", value = "*" },
        { name = "ALPINE_CORS_ALLOW_METHODS", value = "GET,POST,PUT,DELETE,OPTIONS" },
        { name = "ALPINE_CORS_ALLOW_HEADERS", value = "Origin, Content-Type, Authorization, X-Requested-With, Content-Length, Accept, Origin, X-Api-Key, X-Total-Count, *" },
        { name = "ALPINE_CORS_EXPOSE_HEADERS", value = "Origin, Content-Type, Authorization, X-Requested-With, Content-Length, Accept, Origin, X-Api-Key, X-Total-Count" },
        { name = "ALPINE_CORS_ALLOW_CREDENTIALS", value = "true" },
        { name = "ALPINE_OIDC_ENABLED", value = "true" },
        { name = "ALPINE_OIDC_ISSUER", value = "https://tyk.onelogin.com/oidc/2" },
        { name = "ALPINE_OIDC_CLIENT_ID", value = "511adce0-c1b0-013b-ebc1-06a565e566d1150043" },
        { name = "ALPINE_OIDC_USERNAME_CLAIM", value = "preferred_username" },
        { name = "ALPINE_OIDC_TEAMS_CLAIM", value = "groups" },
        { name = "ALPINE_OIDC_USER_PROVISIONING", value = "true" },
        { name = "ALPINE_OIDC_TEAM_SYNCHRONIZATION", value = "false" },
        { name = "LOGGING_LEVEL", value = "INFO" }
      ]
      port_mappings = [
        {
          name          = "deptrack-api"
          containerPort = local.dtrack_port
          hostPort      = local.dtrack_port
          protocol      = "tcp"
        }
      ]
      log_configuration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "deptrack"
          awslogs-region        = "eu-central-1"
          awslogs-stream-prefix = "api"
        }
      }
    }
  }
  volume = {
    dtrack-data = {
      efs_volume_configuration = {
        file_system_id = data.terraform_remote_state.base.outputs.deptrack_efs
      }
    }
  }
  depends_on = [aws_lb_listener.deptrack]

  subnet_ids = module.vpc.public_subnets
  load_balancer = {
    service = {
      target_group_arn = aws_lb_target_group.deptrack_api.arn
      container_name   = "deptrack-api"
      container_port   = local.dtrack_port
    }
  }

  create_security_group = false
  security_group_ids    = [aws_security_group.deptrack.id]

  tags = local.dtrack_tags
}

module "deptrack_fe" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name             = "deptrack-fe"
  cluster_arn      = aws_ecs_cluster.deptrack.arn
  assign_public_ip = true

  cpu    = 1024
  memory = 2048
  container_definitions = {
    deptrack-fe = {
      cpu                      = 512
      memory                   = 1024
      essential                = true
      readonly_root_filesystem = false
      image                    = "dependencytrack/frontend:${local.dtrack_version}"
      port_mappings = [
        {
          name          = "deptrack-fe"
          containerPort = local.dtrack_port
          hostPort      = local.dtrack_port
          protocol      = "tcp"
        }
      ]
      log_configuration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "deptrack"
          awslogs-region        = "eu-central-1"
          awslogs-stream-prefix = "fe"
        }
      }
      environment = [
        { name = "API_BASE_URL", value = "https://deptrack-api.dev.tyk.technology" },
        { name = "OIDC_ISSUER", value = "https://tyk.onelogin.com/oidc/2" },
        { name = "OIDC_CLIENT_ID", value = "511adce0-c1b0-013b-ebc1-06a565e566d1150043" },
        { name = "OIDC_LOGIN_BUTTON_TEXT", value = "OneLogin" }
      ]
    }
  }
  desired_count = 2
  depends_on    = [module.deptrack_api, aws_lb_listener.deptrack]

  subnet_ids = module.vpc.public_subnets
  load_balancer = {
    service = {
      target_group_arn = aws_lb_target_group.deptrack_fe.arn
      container_name   = "deptrack-fe"
      container_port   = local.dtrack_port
    }
  }

  create_security_group = false
  security_group_ids    = [aws_security_group.deptrack.id]

  tags = local.dtrack_tags
}

resource "aws_lb" "deptrack" {
  name               = "deptrack"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.http_s.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = true

  access_logs {
    bucket  = data.terraform_remote_state.base.outputs.assets
    prefix  = "deptrack-lb"
    enabled = true
  }

  connection_logs {
    bucket  = data.terraform_remote_state.base.outputs.assets
    prefix  = "deptrack-lb"
    enabled = true
  }
  tags = local.dtrack_tags
}

resource "aws_lb_listener" "deptrack" {
  load_balancer_arn = aws_lb.deptrack.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.dev_tyk_technology.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: Not Found"
      status_code  = "404"
    }
  }
  tags = local.dtrack_tags
}

resource "aws_lb_listener_rule" "deptrack" {
  listener_arn = aws_lb_listener.deptrack.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.deptrack_fe.arn
  }
  condition {
    host_header {
      values = ["deptrack.dev.tyk.technology"]
    }
  }
  tags = local.dtrack_tags
}

resource "aws_lb_listener_rule" "deptrack_api" {
  listener_arn = aws_lb_listener.deptrack.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.deptrack_api.arn
  }
  condition {
    host_header {
      values = ["deptrack-api.dev.tyk.technology"]
    }
  }
  tags = local.dtrack_tags
}

resource "aws_lb_target_group" "deptrack_fe" {
  name        = "deptrack-fe"
  port        = local.dtrack_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id

  tags = local.dtrack_tags
}

resource "aws_lb_target_group" "deptrack_api" {
  name        = "deptrack-api"
  port        = local.dtrack_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id

  health_check {
    enabled = true
    path    = "/api/version"
  }

  tags = local.dtrack_tags
}

resource "aws_route53_record" "deptrack" {
  for_each = toset(["deptrack", "deptrack-api"])

  zone_id = aws_route53_zone.dev_tyk_tech.zone_id

  name = each.key
  type = "CNAME"
  ttl  = "300"

  records = [aws_lb.deptrack.dns_name]
}


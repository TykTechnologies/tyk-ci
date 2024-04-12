# Dependency Track

locals {
  # ports
  dtrack_fe      = 8080
  dtrack_api     = 8081
  dtrack_version = "4.10.0"
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
}

resource "aws_cloudwatch_log_group" "deptrack" {
  name = "deptrack"

  retention_in_days = 7
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
      cpu                = 4096
      memory             = 16384
      image              = "dependencytrack/apiserver:${local.dtrack_version}"
      memory_reservation = 8192
      mount_points = [
        { sourceVolume = "dtrack-data", containerPath = "/data" }
      ]
      environment = [
        { name = "ALPINE_CORS_ENABLED", value = "true" },
        { name = "ALPINE_CORS_ALLOW_ORIGIN=", value = "*" },
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
        { name = "ALPINE_OIDC_TEAM_SYNCHRONIZATION", value = "false" }
      ]
      port_mappings = [
        {
          name          = "deptrack-api"
          containerPort = local.dtrack_api
          hostPort      = local.dtrack_api
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

  subnet_ids = module.vpc.private_subnets

  security_group_rules = {
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  volume = {
    dtrack-data = {
      efs_volume_configuration = {
        file_system_id = data.terraform_remote_state.base.outputs.deptrack_efs
      }
    }
  }
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
          containerPort = local.dtrack_fe
          hostPort      = local.dtrack_fe
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
        { name = "API_BASE_URL", value = "deptrack-api." },
        { name = "OIDC_ISSUER", value = "https://tyk.onelogin.com/oidc/2" },
        { name = "OIDC_CLIENT_ID", value = "511adce0-c1b0-013b-ebc1-06a565e566d1150043" },
        { name = "OIDC_LOGIN_BUTTON_TEXT", value = "OneLogin" }
      ]
    }
  }
  desired_count = 2
  depends_on    = [module.deptrack_api, aws_lb_listener.deptrack_fe]

  load_balancer = {
    service = {
      target_group_arn = aws_lb_target_group.deptrack-fe.arn
      container_name   = "deptrack-fe"
      container_port   = local.dtrack_fe
    }
  }

  subnet_ids = module.vpc.public_subnets
  security_group_rules = {
    lb_ingress = {
      type        = "ingress"
      from_port   = local.dtrack_fe
      to_port     = local.dtrack_fe
      protocol    = "tcp"
      description = "deptrack api"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
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
}

resource "aws_acm_certificate" "dev_tyk_technology" {
  domain_name       = "*.dev.tyk.technology"
  validation_method = "DNS"
}

resource "aws_route53_record" "dev_tyk_technology" {
  for_each = {
    for dvo in aws_acm_certificate.dev_tyk_technology.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.dev_tyk_tech.zone_id
}

resource "aws_acm_certificate_validation" "dev_tyk_technology" {
  certificate_arn         = aws_acm_certificate.dev_tyk_technology.arn
  validation_record_fqdns = [for record in aws_route53_record.dev_tyk_technology : record.fqdn]
}

resource "aws_lb_listener" "deptrack_fe" {
  load_balancer_arn = aws_lb.deptrack.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.dev_tyk_technology.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.deptrack-fe.arn
  }
}

resource "aws_lb_target_group" "deptrack-fe" {
  name        = "deptrack-fe"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_route53_record" "deptrack" {
  zone_id = aws_route53_zone.dev_tyk_tech.zone_id

  name = "deptrack"
  type = "CNAME"
  ttl  = "300"

  records = [aws_lb.deptrack.dns_name]
}


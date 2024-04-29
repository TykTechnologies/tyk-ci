# Dependency Track

provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = {
      "managed" = "terraform",
      "ou"      = "devops",
      "purpose" = "security",
    }
  }
}

# Persistence layer
data "terraform_remote_state" "base" {
  backend = "remote"

  config = {
    organization = "Tyk"
    workspaces = {
      name = var.base
    }
  }
}

locals {
  # ports
  dtrack_port    = 8080
  dtrack_version = "4.10.0"
  # See README for how DB objects are created
  dtrack_db_name = "deptrack"
  dtrack_db_role = "deptrack"
}
# See README for how this parameter is created
data "aws_ssm_parameter" "deptrack_db_pass" {
  name            = "/deptrack/db_pass"
  with_decryption = false
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

resource "aws_security_group" "deptrack" {
  name        = "deptrack"
  description = "For DependencyTrack on Fargate"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_security_group_ingress_rule" "deptrack" {
  for_each = toset([for p in [2049, local.dtrack_port] : tostring(p)])

  security_group_id = aws_security_group.deptrack.id
  cidr_ipv4         = data.terraform_remote_state.base.outputs.vpc.cidr
  from_port         = each.key
  to_port           = each.key
  ip_protocol       = "tcp"
}

resource "aws_security_group" "http_s" {
  name        = "http_s"
  description = "Allow http(s) inbound traffic from anywhere"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.http_s.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.http_s.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

module "deptrack_api" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name             = "deptrack-api"
  cluster_arn      = aws_ecs_cluster.deptrack.arn
  assign_public_ip = true

  depends_on = [aws_lb_listener.deptrack]

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
        { name = "ALPINE_DATABASE_MODE", value = "external" },
        { name = "ALPINE_DATABASE_URL", value = "jdbc:postgresql://${data.terraform_remote_state.base.outputs.rds.address}:${data.terraform_remote_state.base.outputs.rds.port}/${local.dtrack_db_name}?sslmode=require&sslfactory=org.postgresql.ssl.NonValidatingFactory" },
        { name = "ALPINE_DATABASE_DRIVER", value = "org.postgresql.Driver" },
        { name = "ALPINE_DATABASE_USERNAME", value = local.dtrack_db_role },
        { name = "ALPINE_DATABASE_POOL_ENABLED", value = "true" },
        { name = "ALPINE_DATABASE_POOL_MAX_SIZE", value = "20" },
        { name = "ALPINE_DATABASE_POOL_MIN_IDLE", value = "10" },
        { name = "ALPINE_DATABASE_POOL_IDLE_TIMEOUT", value = "300000" },
        { name = "ALPINE_DATABASE_POOL_MAX_LIFETIME", value = "600000" },
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
      secrets = [
        { name = "ALPINE_DATABASE_PASSWORD", valueFrom = data.aws_ssm_parameter.deptrack_db_pass.arn }
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
  subnet_ids = data.terraform_remote_state.base.outputs.vpc.public_subnets
  load_balancer = {
    service = {
      target_group_arn = aws_lb_target_group.deptrack_api.arn
      container_name   = "deptrack-api"
      container_port   = local.dtrack_port
    }
  }

  create_task_exec_iam_role = false
  create_task_exec_policy   = false
  task_exec_iam_role_arn    = aws_iam_role.deptrack.arn
  create_security_group     = false
  security_group_ids        = [aws_security_group.deptrack.id]
}

module "deptrack_fe" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name             = "deptrack-fe"
  cluster_arn      = aws_ecs_cluster.deptrack.arn
  assign_public_ip = true
  desired_count    = 2

  create_security_group = false

  depends_on = [module.deptrack_api, aws_lb_listener.deptrack]

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
  subnet_ids = data.terraform_remote_state.base.outputs.vpc.public_subnets
  load_balancer = {
    service = {
      target_group_arn = aws_lb_target_group.deptrack_fe.arn
      container_name   = "deptrack-fe"
      container_port   = local.dtrack_port
    }
  }
  security_group_ids = [aws_security_group.deptrack.id]
}

resource "aws_lb" "deptrack" {
  name               = "deptrack"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.http_s.id]
  subnets            = data.terraform_remote_state.base.outputs.vpc.public_subnets

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

resource "aws_lb_listener" "deptrack" {
  load_balancer_arn = aws_lb.deptrack.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = data.terraform_remote_state.base.outputs.dns.cert

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: Not Found"
      status_code  = "404"
    }
  }
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
}

resource "aws_lb_target_group" "deptrack_fe" {
  name        = "deptrack-fe"
  port        = local.dtrack_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc.id
}

resource "aws_lb_target_group" "deptrack_api" {
  name        = "deptrack-api"
  port        = local.dtrack_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc.id

  health_check {
    enabled = true
    path    = "/api/version"
  }
}

resource "aws_route53_record" "deptrack" {
  for_each = toset(["deptrack", "deptrack-api"])

  zone_id = data.terraform_remote_state.base.outputs.dns.zone_id

  name = each.key
  type = "CNAME"
  ttl  = "300"

  records = [aws_lb.deptrack.dns_name]
}

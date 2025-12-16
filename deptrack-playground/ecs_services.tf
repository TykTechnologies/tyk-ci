# ECS Task Definitions and Services

# Placeholder for deptrack database password in SSM
# This will be created manually after RDS is provisioned
# IMPORTANT: Uncomment this after creating the SSM parameter
# data "aws_ssm_parameter" "deptrack_db_pass" {
#   name            = "/${local.name_prefix}/db_pass"
#   with_decryption = false
# }

# Temporary placeholder - replace with actual SSM parameter ARN after creation
locals {
  deptrack_db_pass_arn = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${local.name_prefix}/db_pass"
}

# API Server Task Definition
resource "aws_ecs_task_definition" "api" {
  family                   = "${local.name_prefix}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 4096
  memory                   = 16384
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  volume {
    name = "deptrack-data"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.deptrack.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.deptrack.id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([
    {
      name      = "api"
      image     = "dependencytrack/apiserver:${local.dtrack_version}"
      essential = true
      cpu       = 4096
      memory    = 16384
      memoryReservation = 8192

      mountPoints = [
        {
          sourceVolume  = "deptrack-data"
          containerPath = "/data"
          readOnly      = false
        }
      ]

      portMappings = [
        {
          containerPort = local.dtrack_port
          protocol      = "tcp"
          name          = "api"
        }
      ]

      environment = [
        { name = "ALPINE_DATABASE_MODE", value = "external" },
        { name = "ALPINE_DATABASE_URL", value = "jdbc:postgresql://${aws_db_instance.deptrack.address}:${aws_db_instance.deptrack.port}/${local.dtrack_db_name}?sslmode=require&sslfactory=org.postgresql.ssl.NonValidatingFactory" },
        { name = "ALPINE_DATABASE_DRIVER", value = "org.postgresql.Driver" },
        { name = "ALPINE_DATABASE_USERNAME", value = local.dtrack_db_user },
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
        # OIDC Configuration - Commented out to enable local admin login
        # Uncomment these lines and redeploy to enable OneLogin SSO
        # { name = "ALPINE_OIDC_ENABLED", value = "true" },
        # { name = "ALPINE_OIDC_ISSUER", value = "https://tyk.onelogin.com/oidc/2" },
        # { name = "ALPINE_OIDC_CLIENT_ID", value = "511adce0-c1b0-013b-ebc1-06a565e566d1150043" },
        # { name = "ALPINE_OIDC_USERNAME_CLAIM", value = "preferred_username" },
        # { name = "ALPINE_OIDC_TEAMS_CLAIM", value = "groups" },
        # { name = "ALPINE_OIDC_USER_PROVISIONING", value = "true" },
        # { name = "ALPINE_OIDC_TEAM_SYNCHRONIZATION", value = "false" },
        { name = "LOGGING_LEVEL", value = "INFO" }
      ]

      secrets = [
        {
          name      = "ALPINE_DATABASE_PASSWORD"
          valueFrom = local.deptrack_db_pass_arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.deptrack.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "api"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:${local.dtrack_port}/api/version || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 120
      }
    }
  ])

  tags = {
    Name = "${local.name_prefix}-api"
  }
}

# API Server Service
resource "aws_ecs_service" "api" {
  name            = "${local.name_prefix}-api"
  cluster         = aws_ecs_cluster.deptrack.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = var.api_task_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "api"
    container_port   = local.dtrack_port
  }

  enable_execute_command = true

  depends_on = [
    aws_lb_listener.http,
    aws_efs_mount_target.deptrack
  ]

  tags = {
    Name = "${local.name_prefix}-api"
  }
}

# Frontend Task Definition
resource "aws_ecs_task_definition" "frontend" {
  family                   = "${local.name_prefix}-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "frontend"
      image     = "dependencytrack/frontend:${local.dtrack_version}"
      essential = true
      cpu       = 512
      memory    = 1024

      portMappings = [
        {
          containerPort = local.dtrack_port
          protocol      = "tcp"
          name          = "frontend"
        }
      ]

      environment = [
        { name = "API_BASE_URL", value = "http://api.deptrack.tyk.io" }
        # OIDC Configuration - Commented out to enable local admin login
        # Uncomment these lines and redeploy to enable OneLogin SSO button
        # { name = "OIDC_ISSUER", value = "https://tyk.onelogin.com/oidc/2" },
        # { name = "OIDC_CLIENT_ID", value = "511adce0-c1b0-013b-ebc1-06a565e566d1150043" },
        # { name = "OIDC_LOGIN_BUTTON_TEXT", value = "OneLogin" }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.deptrack.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "frontend"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "wget --no-verbose --tries=1 --spider http://localhost:${local.dtrack_port}/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name = "${local.name_prefix}-frontend"
  }
}

# Frontend Service
resource "aws_ecs_service" "frontend" {
  name            = "${local.name_prefix}-frontend"
  cluster         = aws_ecs_cluster.deptrack.id
  task_definition = aws_ecs_task_definition.frontend.arn
  desired_count   = var.frontend_task_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = local.dtrack_port
  }

  enable_execute_command = true

  depends_on = [
    aws_lb_listener.http,
    aws_ecs_service.api
  ]

  tags = {
    Name = "${local.name_prefix}-frontend"
  }
}

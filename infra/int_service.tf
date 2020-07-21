resource "aws_ecs_cluster" "int_service" {
  name = "int-service"

  tags = local.common_tags
}

resource "aws_ecs_task_definition" "int_service" {
  family                   = "int_service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  cpu                      = 256
  memory                   = 512

  container_definitions = <<EOF
    [
        {
            "portMappings": [
                {
                    "hostPost": 8443,
                    "containerPort": 8443
                }
            ],
            "mountPoints": [
                {
                    "sourceVolume": "cfssl",
                    "containerPath": "/cfssl",
                    "readOnly": true
                },
                {
                    "sourceVolume": "config",
                    "containerPath": "/conf",
                    "readOnly": true
                }
            ],
            "environment": [
                {
                    "name": "SECRET",
                    "value": "KEY"
                }
            ],
            "image": "${var.int_service_ecr}:latest",
            "name": "int_service",
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "int_service",
                    "awslogs-stream-prefix": "int",
                    "awslogs-region": "${var.region}"
                }
            }
        }
    ]
EOF

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
      root_directory = "/"
    }
  }

  depends_on = [aws_cloudwatch_log_group.int_service]

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "int_service" {
  name = "int_service"

  tags = local.common_tags
}

resource "aws_service_discovery_service" "int_service" {
  name = "int-service"

  dns_config {
    namespace_id = aws_service_discovery_public_dns_namespace.dev.id

    dns_records {
      ttl  = 60
      type = "SRV"
    }
  }
}

resource "aws_ecs_service" "int_service" {
  name            = "int_service"
  cluster         = aws_ecs_cluster.int_service.id
  task_definition = aws_ecs_task_definition.int_service.id
  desired_count   = 1
  launch_type     = "FARGATE"
  # Needed for EFS
  platform_version = "1.4.0"

  network_configuration {
    subnets          = module.vpc.public_subnets
    assign_public_ip = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.int_service.arn
    port         = 8080
  }

  tags = local.common_tags
}

resource "aws_dynamodb_table" "devenv" {
  name         = "DeveloperEnvironments"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "env"
  range_key    = "last_updated"

  attribute {
    name = "env"
    type = "S"
  }

  attribute {
    name = "last_updated"
    type = "S"
  }

  # Not supported in eu-central-1
  # dynamic "replica" {
  #   for_each = data.aws_availability_zones.available.names
  #   content {
  #     region_name = replica.value
  #   }
  # }

  tags = local.common_tags
}

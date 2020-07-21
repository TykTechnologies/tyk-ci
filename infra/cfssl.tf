# This needs to be separate from int_service as a bug[1]
# prevents multiple service_registries in an aws_ecs_service block
# [1] https://github.com/terraform-providers/terraform-provider-aws/issues/9573

resource "aws_ecs_task_definition" "cfssl" {
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
                    "hostPost": 8888,
                    "containerPort": 8888
                }
            ],
            "mountPoints": [
                {
                    "sourceVolume": "cfssl",
                    "containerPath": "/cfssl",
                    "readOnly": true
                }
            ],
            "environment": [
                {
                    "name": "CFSSL_API_KEY",
                    "value": "${var.cfssl_apikey}"
                }
            ],
            "image": "${var.cfssl_ecr}:latest",
            "name": "cfssl",
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "int_service",
                    "awslogs-stream-prefix": "cfssl",
                    "awslogs-region": "${var.region}"
                }
            }
        }
    ]
EOF

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

resource "aws_service_discovery_service" "cfssl" {
  name = "cfssl"

  dns_config {
    namespace_id = aws_service_discovery_public_dns_namespace.dev.id

    dns_records {
      ttl  = 60
      type = "SRV"
    }
  }
}

resource "aws_ecs_service" "cfssl" {
  name            = "cfssl"
  cluster         = aws_ecs_cluster.int_service.id
  task_definition = aws_ecs_task_definition.cfssl.id
  desired_count   = 1
  launch_type     = "FARGATE"
  # Needed for EFS
  platform_version = "1.4.0"

  network_configuration {
    subnets          = module.vpc.public_subnets
    assign_public_ip = true

  } 

  service_registries {
    registry_arn = aws_service_discovery_service.cfssl.arn
    port = 8888
  }

  tags = local.common_tags
}


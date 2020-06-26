resource "aws_ecs_cluster" "cfssl" {
  name = "integration_service"

  tags = local.common_tags
}

resource "aws_ecs_task_definition" "cfssl" {
  family = "cfssl"
  requires_compatibilities = [ "FARGATE" ]
  network_mode = "awsvpc"
  execution_role_arn = data.aws_iam_role.ecs_task_execution_role.arn
  cpu = 256
  memory = 512

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
                    "containerPath": "/cfssl/certs",
                    "readOnly": true
                }
            ],
            "environment": [
                {
                    "name": "SECRET",
                    "value": "KEY"
                }
            ],
            "image": "046805072452.dkr.ecr.eu-central-1.amazonaws.com/cfssl:latest",
            "name": "cfssl",
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "cfssl",
                    "awslogs-stream-prefix": "ecs",
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
      root_directory = "/integration"
    }
  }

  depends_on = [ aws_cloudwatch_log_group.cfssl ]
  
  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "cfssl" {
  name = "cfssl"

  tags = local.common_tags
}

resource "aws_ecs_service" "cfssl" {
  name = "cfssl"
  cluster = aws_ecs_cluster.cfssl.id
  task_definition = aws_ecs_task_definition.cfssl.id
  desired_count = 1
  launch_type = "FARGATE"
  # Needed for EFS
  platform_version = "1.4.0"

  network_configuration {
    subnets =  module.vpc.private_subnets
  }

  tags = local.common_tags
}

resource "aws_lb_target_group" "cfssl" {
  name        = "int-service"
  port        = 8443
  protocol    = "TCP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  tags = local.common_tags

  depends_on = [ aws_lb.integration ]
}

# Redirect all traffic from the ALB to the target group
resource "aws_lb_listener" "cfssl" {
  load_balancer_arn = aws_lb.integration.id
  port              = "443"
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.cfssl.id
    type             = "forward"
  }
}

resource "aws_route53_record" "cfssl" {
  zone_id = data.aws_route53_zone.integration.zone_id
  name = "cfssl.${data.aws_route53_zone.integration.name}"
  type = "CNAME"
  ttl = 300
  records = [ aws_lb.integration.dns_name ]
}


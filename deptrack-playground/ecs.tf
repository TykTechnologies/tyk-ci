# ECS Cluster and CloudWatch Logs

resource "aws_ecs_cluster" "deptrack" {
  name = local.name_prefix

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.deptrack.name
      }
    }
  }

  tags = {
    Name = local.name_prefix
  }
}

resource "aws_ecs_cluster_capacity_providers" "deptrack" {
  cluster_name = aws_ecs_cluster.deptrack.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
    base              = 1
  }
}

resource "aws_cloudwatch_log_group" "deptrack" {
  name              = "/ecs/${local.name_prefix}"
  retention_in_days = 7

  tags = {
    Name = "${local.name_prefix}-logs"
  }
}

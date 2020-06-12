resource "aws_ecs_cluster" "config-mgmt" {
  name = "git-cfssl"
  capacity_providers = [ "FARGATE" ]

  tags = var.common_tags
}

resource "aws_ecs_task_definition" "git" {
  family = "service"
  container_definitions = "${file("git.json")}"

  volume {
    name = "git-storage"
    host_path = "/srv"
  }
  tags = var.common_tags
}

resource "aws_ecs_task_definition" "cfssl" {
  family = "service"
  container_definitions = "${file("cfssl.json")}"

  volume {
    name = "git-storage"
    host_path = "/srv"
  }
  tags = var.common_tags
}

resource "aws_volume" "git" {
  availability_zone = "data.aws_availability_zones.available.names[0]"
  size = var.git_cache_size

  tags = var.common_tags
}

# This is used to ensure that all the ELB subnets are in different AZs
data "aws_availability_zones" "available" {
  state = available
}


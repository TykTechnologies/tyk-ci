provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = {
      "managed" = "terraform",
      "ou"      = "devops",
      "purpose" = "automation",
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
  wmill_port  = 8000
  wmill_image = "ghcr.io/windmill-labs/windmill:main"
}

# See README for how this parameter is created
data "aws_ssm_parameter" "windmill_db_url" {
  name            = "/windmill/db_url"
  with_decryption = false
}

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/retrieve-ecs-optimized_AMI.html
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended"
}

resource "aws_security_group" "windmill" {
  name        = "windmill"
  description = "For Windmill ECS cluster"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc.id

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ecs_cluster resources are boilerplate to allow the EC2 instances to
# join the ECS cluster. AmazonEC2ContainerServiceforEC2Role is the AWS
# managed policy that needs to be attached to each instance via the
# launch template.

data "aws_iam_policy" "ecs_cluster" {
  name = "AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role" "ecs_cluster" {
  name = "ecs-cluster"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_cluster" {
  role       = aws_iam_role.ecs_cluster.name
  policy_arn = data.aws_iam_policy.ecs_cluster.arn
}

resource "aws_iam_instance_profile" "ecs_cluster" {
  name = "ecs-cluster"
  role = aws_iam_role.ecs_cluster.name
}

resource "aws_launch_template" "windmill" {
  name          = "windmill-cluster"
  image_id      = jsondecode(data.aws_ssm_parameter.ecs_ami.value)["image_id"]
  instance_type = "t3.medium"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 100
    }
  }

  key_name = data.terraform_remote_state.base.outputs.key_name

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_cluster.name
  }

  instance_initiated_shutdown_behavior = "terminate"

  # instance_market_options {
  #   market_type = "spot"
  #   spot_options {
  #     max_price = 0.03
  #   }
  # }

  network_interfaces {
    device_index                = 0
    delete_on_termination       = true
    associate_public_ip_address = false
    security_groups = [
      aws_security_group.windmill.id,
      data.aws_security_group.http_s.id
    ]
  }

  user_data = data.cloudinit_config.ecs_cluster.rendered

  tag_specifications {
    resource_type = "instance"
    tags = {
      managed = "terraform",
      ou      = "devops",
      purpose = "automation"
    }
  }
}

data "cloudinit_config" "ecs_cluster" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/ecs-boot.tftpl", { name = aws_ecs_cluster.windmill.name })
  }
}

# For debugging cloud-init
# output "cloudinit" {
#   value = data.cloudinit_config.ecs_cluster.rendered
# }

resource "aws_autoscaling_group" "windmill" {
  name = "windmill-cluster"

  max_size         = 3
  min_size         = 2
  desired_capacity = 2

  vpc_zone_identifier = data.terraform_remote_state.base.outputs.vpc.private_subnets

  launch_template {
    id      = aws_launch_template.windmill.id
    version = "$Latest"
  }

  health_check_type = "EC2"

  metrics_granularity = "1Minute"
  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
    "GroupInServiceCapacity",
    "GroupPendingCapacity",
    "GroupStandbyCapacity",
    "GroupTerminatingCapacity",
    "GroupTotalCapacity"
  ]

  # AmazonECSManaged tag is used by terraform
  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}

resource "aws_ecs_cluster" "windmill" {
  name = "windmill"
  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.windmill.name
      }
    }
  }
}

resource "aws_cloudwatch_log_group" "windmill" {
  name = "windmill"

  retention_in_days = 7
}

resource "aws_ecs_capacity_provider" "windmill" {
  name = "windmill-cluster"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.windmill.arn

    managed_scaling {
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      target_capacity           = 50 # avg cpu utilisation %
      status                    = "ENABLED"
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "windmill" {
  cluster_name = aws_ecs_cluster.windmill.name

  capacity_providers = [
    aws_ecs_capacity_provider.windmill.name
  ]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = aws_ecs_capacity_provider.windmill.name
  }
}

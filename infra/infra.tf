provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = {
      "managed" = "terraform",
      "ou"      = "devops",
      "purpose" = "ci",
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

resource "aws_security_group" "instances" {
  name        = "instances"
  description = "EFS, ssh and egress"
  vpc_id      = data.terraform_remote_state.base.outputs.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.instances.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "efs_tasks" {
  security_group_id = aws_security_group.instances.id
  cidr_ipv4         = data.terraform_remote_state.base.outputs.vpc.cidr
  from_port         = 2049
  to_port           = 2049
  ip_protocol       = "tcp"
}

# CD tasks will run in the public subnet
resource "aws_efs_mount_target" "shared" {
  for_each = toset(data.terraform_remote_state.base.outputs.vpc.public_subnets)

  file_system_id  = data.terraform_remote_state.base.outputs.shared_efs
  subnet_id       = each.value
  security_groups = [aws_security_group.instances.id]
}

# TODO: remove deptrack when done
resource "aws_efs_mount_target" "deptrack" {
  for_each = toset(data.terraform_remote_state.base.outputs.vpc.public_subnets)

  file_system_id  = data.terraform_remote_state.base.outputs.deptrack_efs
  subnet_id       = each.value
  security_groups = [aws_security_group.instances.id]
}

data "cloudinit_config" "bastion" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content = templatefile("bastion-cloudinit.yaml.tftpl", {
      efs_mounts = [
        # TODO: remove deptrack
        { dev = data.terraform_remote_state.base.outputs.deptrack_efs, mp = "/deptrack" },
        { dev = data.terraform_remote_state.base.outputs.shared_efs, mp = "/shared" },
      ]
    })
  }
}

# For debugging cloud-init
# output "cloudinit" {
#   value = data.cloudinit_config.bastion.rendered
# }

# Bastion

module "bastion" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "bastion"

  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.nano"
  key_name                    = data.terraform_remote_state.base.outputs.key_name
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.instances.id]
  subnet_id                   = element(data.terraform_remote_state.base.outputs.vpc.public_subnets, 0)
  associate_public_ip_address = true
  user_data_base64            = data.cloudinit_config.bastion.rendered
  user_data_replace_on_change = true
  # Allow access via SessionManager
  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 instance"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    CloudWatchAgentServerPolicy  = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  }
  # Spot request specific attributes
  spot_price                          = "0.1"
  spot_wait_for_fulfillment           = true
  spot_type                           = "persistent"
  spot_instance_interruption_behavior = "terminate"

  metadata_options = {
    http_tokens = "required" # IMDSv2
  }
}

data "aws_ami" "al2023" {

  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Log group for CD tasks
# Everything logs to cloudwatch with prefixes
resource "aws_cloudwatch_log_group" "cd" {
  name = "cd"

  retention_in_days = 3
}


# Log group for internal tasks
resource "aws_cloudwatch_log_group" "internal" {
  name = "internal"

  retention_in_days = 7
}

resource "aws_ecs_cluster" "internal" {
  name = "internal"
  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.cd.name
      }
    }
  }
}

# DNS

resource "aws_route53_record" "bastion" {
  zone_id = data.terraform_remote_state.base.outputs.dns.zone_id

  name = "bastion"
  type = "A"
  ttl  = "300"

  records = [module.bastion.public_ip]
}

# For CD tasks
resource "aws_service_discovery_private_dns_namespace" "dev_internal" {
  name        = "dev.internal"
  description = "For CD ECS tasks"
  vpc         = data.terraform_remote_state.base.outputs.vpc.id
}

resource "aws_service_discovery_service" "dev_internal" {
  name = "dev-internal"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.dev_internal.id

    dns_records {
      ttl  = 10
      type = "A"
    }
    dns_records {
      ttl  = 10
      type = "SRV"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_ssm_parameter" "cd_sd" {
  name        = "/cd/sd"
  type        = "String"
  description = "Service discovery registry arn for CD tasks"
  value       = aws_service_discovery_service.dev_internal.arn
}

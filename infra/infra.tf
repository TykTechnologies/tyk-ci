provider "aws" {
  region = var.region
  default_tags {
    tags = {
      "managed" = "terraform",
      "ou"      = "devops",
      "purpose" = "ci",
      "env"     = var.name_prefix
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

data "aws_availability_zones" "available" {
  state = "available"
}

module "private_subnets" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = cidrsubnet(var.cidr, 4, 1)
  networks = [
    { name = "privaz1", new_bits = 4 },
    { name = "privaz2", new_bits = 4 },
    { name = "privaz3", new_bits = 4 },
  ]
}

module "public_subnets" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = cidrsubnet(var.cidr, 4, 15)
  networks = [
    { name = "pubaz1", new_bits = 4 },
    { name = "pubaz2", new_bits = 4 },
    { name = "pubaz3", new_bits = 4 },
  ]
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.name_prefix
  cidr = var.cidr

  azs                 = data.aws_availability_zones.available.names
  private_subnets     = module.private_subnets.networks[*].cidr_block
  private_subnet_tags = { Type = "private" }
  public_subnets      = module.public_subnets.networks[*].cidr_block
  public_subnet_tags  = { Type = "public" }

  enable_nat_gateway      = true
  single_nat_gateway      = true
  map_public_ip_on_launch = true

  # Need DNS to address EFS by name
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_security_group" "efs" {
  name        = "efs"
  description = "Allow efs inbound traffic from anywhere in the VPC"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
}

resource "aws_security_group" "ssh" {
  name        = "ssh"
  description = "Allow ssh inbound traffic from anywhere"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "egress-all" {
  name        = "egress-all"
  description = "Allow all outbound traffic"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# shared mount targets for all public subnets

data "template_file" "mount_shared" {
  template = file("scripts/setup-efs.sh")
  vars = {
    efs_id      = data.terraform_remote_state.base.outputs.shared_efs
    mount_point = "/shared"
  }
}

data "template_cloudinit_config" "bastion" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.mount_shared.rendered
  }

  part {
    content_type = "text/x-shellscript"
    content      = file("scripts/bastion-setup.sh")
  }
}

resource "aws_efs_mount_target" "shared" {
  for_each = toset(module.vpc.public_subnets)

  file_system_id  = data.terraform_remote_state.base.outputs.shared_efs
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}

# Bastion

module "bastion" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "bastion"

  ami                         = data.aws_ami.bastion.id
  instance_type               = "t2.micro"
  key_name                    = var.key_name
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.efs.id, aws_security_group.ssh.id, aws_security_group.egress-all.id]
  subnet_id                   = element(module.vpc.public_subnets, 0)
  associate_public_ip_address = true
  user_data_base64            = data.template_cloudinit_config.bastion.rendered

  # Spot request specific attributes
  spot_price                          = "0.1"
  spot_wait_for_fulfillment           = true
  spot_type                           = "persistent"
  spot_instance_interruption_behavior = "terminate"

  metadata_options = {
    http_tokens = "required" # IMDSv2
  }
}

data "aws_ami" "bastion" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-minimal-*"]
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

# Everything logs to cloudwatch with prefixes
resource "aws_cloudwatch_log_group" "logs" {
  name = "cd"

  retention_in_days = 7
}

resource "aws_ecs_cluster" "internal" {
  name = "internal"
  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.logs.name
      }
    }
  }
}


# DNS

# resource "aws_service_discovery_private_dns_namespace" "cd" {
#   name        = "dev.tyk.technology"
#   description = "CD ECS resources"
# }

resource "aws_route53_zone" "dev_tyk_tech" {
  name = "dev.tyk.technology"
}

resource "aws_route53_record" "bastion" {
  zone_id = aws_route53_zone.dev_tyk_tech.zone_id

  name = "bastion"
  type = "A"
  ttl  = "300"

  records = [module.bastion.public_ip]
}

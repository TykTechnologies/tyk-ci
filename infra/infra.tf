provider "aws" {
  region = var.region
}

# Internal variables

locals {
  gromit = {
    base  = "base-prod"
    infra = "infra-prod"
    repos = "tyk,tyk-analytics,tyk-pump,tyk-sink,tyk-identity-broker,portal,tyk-sync"
  }
  # R53 zone for all resources that need it
  domain = "dev.tyk.technology"
  # Managed policies for task role
  policies = [
    "AmazonRoute53FullAccess",
    "AmazonECS_FullAccess",
    "AmazonDynamoDBFullAccess",
    "AmazonEC2ContainerRegistryReadOnly",
    "AWSCloudMapFullAccess",
    "AmazonS3FullAccess",
    "AmazonEC2FullAccess"
  ]
  common_tags = {
    "managed" = "terraform",
    "ou"      = "devops",
    "purpose" = "ci",
    "env"     = var.name_prefix
  }
}

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

  enable_nat_gateway = true
  single_nat_gateway = true
  # Need DNS to address EFS by name
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = local.common_tags
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

# shared and ca mount targets for all public subnets

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

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.bastion.id
  instance_type               = "t2.micro"
  key_name                    = var.key_name
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.efs.id, aws_security_group.ssh.id, aws_security_group.egress-all.id]
  user_data_base64            = data.template_cloudinit_config.bastion.rendered
  metadata_options {
    http_tokens = "required"	# IMDSv2
  }
  tags = local.common_tags
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

# Internal cluster ancillaries

resource "aws_ecs_cluster" "internal" {
  name = "internal"

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "internal" {
  name              = "internal"
  retention_in_days = 5

  tags = local.common_tags
}

# DNS

resource "aws_route53_zone" "dev_tyk_tech" {
  name = local.domain

  tags = local.common_tags
}

resource "aws_route53_record" "bastion" {
  zone_id = aws_route53_zone.dev_tyk_tech.zone_id

  name = "bastion"
  type = "A"
  ttl  = "300"

  records = [aws_instance.bastion.public_ip]
}

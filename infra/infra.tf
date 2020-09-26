terraform {
  required_version = ">= 0.12"
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "Tyk"

    workspaces {
      prefix = "infra-"
    }
  }
}

provider "aws" {
  #version = "= 2.70"
  region = var.region
}

# Internal variables

locals {
  gromit = {
    table  = "DeveloperEnvironments"
    repos  = "tyk,tyk-analytics,tyk-pump"
    domain = "dev.tyk.technology"
  }
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
  common_tags = map(
    "managed", "automation",
    "ou", "devops",
    "purpose", "ci",
    "env", var.name_prefix,
  )
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.name_prefix
  cidr = "10.91.0.0/16"

  azs                 = data.aws_availability_zones.available.names
  private_subnets     = cidrsubnets(cidrsubnet(var.cidr, 8, 100), 4, 4, 4)
  private_subnet_tags = { Type = "private" }
  public_subnets      = cidrsubnets(cidrsubnet(var.cidr, 8, 1), 4, 4, 4)
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

resource "aws_security_group" "mongo" {
  name        = "mongo"
  description = "Allow mongo inbound traffic from anywhere in the VPC"
  vpc_id      = module.vpc.vpc_id


  ingress {
    from_port   = 27017
    to_port     = 27017
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

resource "aws_instance" "mongo" {
  ami                    = data.aws_ami.mongo.id
  instance_type          = "t3.micro"
  key_name               = var.key_name
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.mongo.id, aws_security_group.ssh.id, aws_security_group.egress-all.id]
  user_data_base64       = data.template_cloudinit_config.mongo_noauth.rendered

  tags = local.common_tags
}

data "aws_ami" "mongo" {
  most_recent = true
  # Bitnami
  owners = ["979382823631"]
  filter {
    name   = "name"
    values = ["bitnami-mongo*"]
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

data "template_cloudinit_config" "mongo_noauth" {
  gzip = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content = "sed -i.orig -e '/security:/,+3 s/^/#/' /opt/bitnami/mongodb/conf/mongodb.conf"
  }
}

# config and cfssl mount targets for all public subnets

data "template_file" "mount_config" {
  template = file("scripts/setup-efs.sh")
  vars = {
    efs_id      = var.config_efs
    mount_point = "/config"
  }
}

data "template_file" "mount_cfssl_keys" {
  template = file("scripts/setup-efs.sh")
  vars = {
    efs_id      = var.cfssl_efs
    mount_point = "/cfssl"
  }
}

data "template_cloudinit_config" "mounts" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.mount_config.rendered
  }

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.mount_cfssl_keys.rendered
  }
}

resource "aws_efs_mount_target" "cfssl" {
  for_each = toset(module.vpc.public_subnets)

  file_system_id  = var.cfssl_efs
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "config" {
  for_each = toset(module.vpc.public_subnets)

  file_system_id  = var.config_efs
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}

# Bastion

resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.bastion.id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.efs.id, aws_security_group.mongo.id, aws_security_group.ssh.id, aws_security_group.egress-all.id]
  user_data_base64       = data.template_cloudinit_config.mounts.rendered

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
  name = local.gromit.domain

  tags = local.common_tags
}

resource "aws_route53_record" "bastion" {
  zone_id = aws_route53_zone.dev_tyk_tech.zone_id
  name    = "bastion"
  type    = "A"
  ttl     = "300"

  records = [aws_instance.bastion.public_ip]
}

resource "aws_route53_record" "mongo" {
  zone_id = aws_route53_zone.dev_tyk_tech.zone_id
  name    = "mongo"
  type    = "A"
  ttl     = "300"

  records = [aws_instance.mongo.private_ip]
}

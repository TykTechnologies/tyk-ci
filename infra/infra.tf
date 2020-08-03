terraform {
  required_version = ">= 0.12"
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "Tyk"

    workspaces {
      prefix = "dev-"
    }
  }
}

provider "aws" {
  version = ">= 2.46"
  region  = var.region
}

# Internal variables

locals {
  gromit = {
    table = "DeveloperEnvironments"
    repos = "tyk,tyk-analytics,tyk-pump"
  }
  r53 = {
    domain = "dev.tyk.technology"
    zoneid = "Z07417902665IQVVMAJKJ"
  }
  common_tags = "${map(
    "managed", "automation",
    "ou", "devops",
    "purpose", "ci",
    "env", var.name_prefix,
  )}"
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

# Created by hand in the eu-central-1 region of the CE account on
# Fri, 19 Jun 2020 16:05:41 IST
data "aws_secretsmanager_secret" "mongo_password" {
  arn = "arn:aws:secretsmanager:eu-central-1:046805072452:secret:dev_shared_mongo_password-NtuHRv"
}

resource "aws_instance" "mongo" {
  ami                    = data.aws_ami.mongo.id
  instance_type          = "t3.micro"
  key_name               = var.key_name
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.mongo.id, aws_security_group.ssh.id, aws_security_group.egress-all.id]

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
  name = "internal"
  retention_in_days = 5

  tags = local.common_tags
}

# DNS

resource "aws_route53_zone" "dev_tyk_tech" {
  name = "dev.tyk.technology"

  tags = local.common_tags
}

resource "aws_route53_record" "bastion" {
  zone_id = aws_route53_zone.dev_tyk_tech.zone_id
  name    = "bastion"
  type    = "A"
  ttl     = "300"

  records = [aws_instance.bastion.public_ip]
}

# Access to Terraform cloud

resource "aws_iam_policy" "gromit_terraform" {
  name = "gromit-terraform"
  description = "Access to remote state in TFCloud"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "kms:Decrypt"
      ],
      "Resource": [
        "arn:aws:secretsmanager:eu-central-1:046805072452:secret:TFCloudAPI-VbBFQf",
        "arn:aws:kms:eu-central-1:046805072452:key/219ad562-d72b-4a40-bc2a-8e13af94b66f"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "gromit_terraform" {
  role      = data.aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.gromit_terraform.arn
}


# The default for ecs task definitions
data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

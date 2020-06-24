terraform {
  required_version = ">= 0.12"
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "Tyk"

    workspaces {
      prefix = "dev-"
    }
  }
}

provider "aws" {
  version = ">= 2.17"
  region = var.region
}

# Internal variables

locals {
  common_tags = "${map(
    "managed", "terraform",
    "ou", "devops",
    "purpose", "ci",
    "env", var.name_prefix,
  )}"
}

resource "aws_ecr_repository" "integration" {
  for_each = toset(var.repositories)
  
  name                 = each.key
  image_tag_mutability = "MUTABLE" 

  image_scanning_configuration {
    scan_on_push = false
  }

  tags = local.common_tags
}

resource "aws_iam_access_key" "integration" {
  for_each = toset(var.repositories)
  
  user    = aws_iam_user.integration[each.key].name
}

resource "aws_iam_user" "integration" {
  for_each = toset(var.repositories)

  name = "ecr-push_${each.key}"

  tags = local.common_tags
}

resource "aws_iam_user_policy" "integration" {
  for_each = toset(var.repositories)
  
  name = "ECRpush"
  user = "ecr-push_${each.key}"
  policy = <<EOF
{
   "Version":"2012-10-17",
   "Statement":[
      {
         "Sid":"GetAuthorizationToken",
         "Effect":"Allow",
         "Action":[
            "ecr:GetAuthorizationToken"
         ],
         "Resource":"*"
      },
       {
         "Sid":"AllowPull",
         "Effect":"Allow",
         "Action":[
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability"
         ],
         "Resource": "${aws_ecr_repository.integration[each.key].arn}"
       },
       {
         "Sid":"AllowPush",
         "Effect":"Allow",
         "Action":[
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "ecr:BatchCheckLayerAvailability",
            "ecr:PutImage",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload"
         ],
         "Resource": "${aws_ecr_repository.integration[each.key].arn}"
      }
   ]
}
EOF
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.name_prefix
  cidr = "10.91.0.0/16"

  azs             = [ data.aws_availability_zones.available.names[0] ]
  private_subnets = [ cidrsubnet(var.cidr, 8, 100) ]
  public_subnets  = [ cidrsubnet(var.cidr, 8, 1) ]

  enable_nat_gateway = true
  single_nat_gateway = true
  # Need DNS to address EFS by name
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = local.common_tags
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_security_group" "mongo" {
  name        = "mongo"
  description = "Allow mongo inbound traffic from private subnet"
  vpc_id      = module.vpc.vpc_id


  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = [ module.vpc.private_subnets_cidr_blocks[0] ]
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
    cidr_blocks = [ "0.0.0.0/0" ]
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
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

# Created by hand in the eu-central-1 region of the CE account on
# Fri, 19 Jun 2020 16:05:41 IST
data "aws_secretsmanager_secret" "mongo_password" {
  arn = "arn:aws:secretsmanager:eu-central-1:046805072452:secret:dev_shared_mongo_password-NtuHRv"
}

resource "aws_instance" "mongo" {
  ami = data.aws_ami.mongo.id
  instance_type = "t3.micro"
  key_name = var.key_name
  subnet_id = module.vpc.private_subnets[0]
  vpc_security_group_ids = [ aws_security_group.mongo.id, aws_security_group.ssh.id, aws_security_group.egress-all.id ]
  
  tags = local.common_tags
}

data "aws_ami" "mongo" {
  most_recent = true
  # Bitnami
  owners = [ "979382823631" ]
  filter {
    name = "name"
    values = [ "bitnami-mongo*"]
  }
  filter {
    name = "architecture"
    values = [ "x86_64" ]
  }
  filter {
    name = "root-device-type"
    values = [ "ebs" ]
  }
  filter {
    name = "virtualization-type"
    values = [ "hvm" ]
  }
}

resource "aws_security_group" "efs" {
  name        = "efs"
  description = "Allow efs inbound traffic from anywhere in the VPC"
  vpc_id      = module.vpc.vpc_id


  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [ module.vpc.vpc_cidr_block ]
  }
}

resource "aws_efs_file_system" "cfssl" {
  creation_token = "cfssl-keys"

  tags = local.common_tags
}

resource "aws_efs_mount_target" "cfssl" {
  file_system_id = aws_efs_file_system.cfssl.id
  subnet_id = module.vpc.private_subnets[0]
  security_groups = [ aws_security_group.efs.id ]
}

resource "aws_efs_file_system" "config" {
  creation_token = "dev-env-config"

  tags = local.common_tags
}

resource "aws_efs_mount_target" "config" {
  file_system_id = aws_efs_file_system.config.id
  subnet_id = module.vpc.public_subnets[0]
  security_groups = [ aws_security_group.efs.id ]
}

data "template_file" "mount_config" {
  template = file("scripts/setup-efs.sh")
  vars = {
    efs_id = aws_efs_file_system.config.id
    mount_point = "/config"
  }
}

data "template_file" "mount_cfssl_keys" {
  template = file("scripts/setup-efs.sh")
  vars = {
    efs_id = aws_efs_file_system.cfssl.id
    mount_point = "/cfssl"
  }
}

data "template_cloudinit_config" "mounts" {
  gzip = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content = data.template_file.mount_config.rendered
  }

  part {
    content_type = "text/x-shellscript"
    content = data.template_file.mount_cfssl_keys.rendered
  }
}

resource "aws_instance" "bastion" {
  ami = data.aws_ami.bastion.id
  instance_type = "t2.micro"
  key_name = var.key_name
  subnet_id = module.vpc.public_subnets[0]
  vpc_security_group_ids = [ aws_security_group.efs.id, aws_security_group.mongo.id, aws_security_group.ssh.id, aws_security_group.egress-all.id ]
  user_data_base64 = data.template_cloudinit_config.mounts.rendered

  depends_on = [
    aws_efs_mount_target.config,
    aws_efs_mount_target.cfssl,
  ]
  
  tags = local.common_tags
}

data "aws_ami" "bastion" {
  most_recent = true
  owners = [ "amazon" ]
  filter {
    name = "name"
    values = [ "amzn2-ami-minimal-*"]
  }
  filter {
    name = "architecture"
    values = [ "x86_64" ]
  }
  filter {
    name = "root-device-type"
    values = [ "ebs" ]
  }
  filter {
    name = "virtualization-type"
    values = [ "hvm" ]
  }
}

resource "aws_route53_record" "bastion" {
  zone_id = data.aws_route53_zone.integration.zone_id
  name = "bastion.${data.aws_route53_zone.integration.name}"
  type = "A"
  ttl = 300
  records = [ aws_instance.bastion.public_ip ]
}

data "aws_route53_zone" "integration" {
  name         = "dev.tyk.technology."
  private_zone = false
}

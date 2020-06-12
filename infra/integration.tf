terraform {
  required_version = ">= 0.12"
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
    "purpose", "ci"
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

resource "aws_efs_file_system" "config" {
  creation_token = "dev-env-config"

  tags = local.common_tags
}

resource "aws_efs_mount_target" "config" {
  file_system_id = aws_efs_file_system.config.id
  subnet_id = module.vpc.public_subnets[0]
  security_groups = [ aws_security_group.efs.id ]
}

resource "aws_instance" "bastion" {
  ami = data.aws_ami.bastion.id
  instance_type = "t2.micro"
  key_name = var.key_name
  subnet_id = module.vpc.public_subnets[0]
  vpc_security_group_ids = [ aws_security_group.efs.id, aws_security_group.mongo.id, aws_security_group.ssh.id, aws_security_group.egress-all.id ]
  user_data = data.template_file.efs.rendered
  
  tags = local.common_tags
}

data "template_file" "efs" {
  template = file("scripts/setup-efs.sh")
  vars = {
    efs_id = aws_efs_file_system.config.id
  }
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

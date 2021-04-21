provider "aws" {
  region = var.region
}

# Internal variables

locals {
  gromit = {
    table           = "DeveloperEnvironments"
    repos           = "tyk,tyk-analytics,tyk-pump,tyk-sink,tyk-identity-broker,raava"
    domain          = "${var.domain}.tyk.technology"
    ca = <<EOF
-----BEGIN CERTIFICATE-----
MIIEhjCCA26gAwIBAgIUPMTrJG/5xhETA8W7DVXJc/oL6kowDQYJKoZIhvcNAQEL
BQAwgYgxCzAJBgNVBAYTAlVLMRcwFQYDVQQIEw5HcmVhdGVyIExvbmRvbjEPMA0G
A1UEBxMGTG9uZG9uMRkwFwYDVQQKExBUeWsgVGVjaG5vbG9naWVzMQ8wDQYDVQQL
EwZEZXZvcHMxIzAhBgNVBAMTGlR5ayBEZXZlbG9wZXIgRW52aXJvbm1lbnRzMB4X
DTIwMTExODEwNDkwMFoXDTIxMTExODEwNDkwMFowgYIxCzAJBgNVBAYTAlVLMRcw
FQYDVQQIEw5HcmVhdGVyIExvbmRvbjEPMA0GA1UEBxMGTG9uZG9uMRkwFwYDVQQK
ExBUeWsgVGVjaG5vbG9naWVzMQ8wDQYDVQQLEwZEZXZvcHMxHTAbBgNVBAMTFElu
dGVnZXJhdGlvbiBzZXJ2aWNlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKC
AQEA0ajHXUFRo2fkpam3YW3ssjznu4aY0HwhrFw2zxuVYBt/R8Tsp4KJsBdKae4Z
lTKhlSO/0U3vIypuKDGCac2S3ldsCh/apYGxDaxEHY0FRbrLH8GD2kq1tizSWzwe
Zpq50jGDjXgvs0VhmF8ztpwn0/Hizy1hUWCR8WJLyomht6wlQ6rqgX+s5pB65i8K
1cTAw15buieHU8F+y5CgZI2tlRWB1BO6tcL65/4hGdMaIyET/X1rmi8nhV0oNlI5
fk05vvgTKgtFtCO4MOYs3SxtEq2j9XoOfDPmhY8LLcqB/91zAMLZDgXqsNjlwCfO
xneOHvxsn3VnbNHUYyLzqLYdMQIDAQABo4HrMIHoMA4GA1UdDwEB/wQEAwIFoDAT
BgNVHSUEDDAKBggrBgEFBQcDATAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBTNLqqS
8kioQGXnn9OLHYtGJzhW1zAfBgNVHSMEGDAWgBSdThDUT+03n5EjM7ZVHlsxQEWZ
1TA4BgNVHREEMTAvgglsb2NhbGhvc3SCImdzZXJ2ZS5pbnRlcm5hbC5kZXYudHlr
LnRlY2hub2xvZ3kwOQYDVR0fBDIwMDAuoCygKoYoaHR0cDovL2Nmc3NsLmRldi50
eWsudGVjaG5vbG9neTo4ODg4L2NybDANBgkqhkiG9w0BAQsFAAOCAQEARTiLUBfI
6QaABx0a5suyuImBEf1gHu23kXmDsL4rteYyPDdPqRUwsI2ygeduvSHfRWqv0oga
YXcM8vNbZKxdHg0sP7qTc6tZNqpMV6A2sHIciXqYJXm2ZpiHhGtRi0PlRp8e7VrY
D8FUzHrUBG2cVsKPAoZcvujlC75oEGOaFacgJWgHrR0yi4c9I6Bhudlhou8VDQns
KIQIUpvXe/I+MZARvyS9NTMo4H4bxTLKTQQU5aXUgpK32aBZCI7VLeLnC8Fy/NbL
iXoMBgkNh8lJPmG6cqyrF5LDdR4JgrHD4kSLjyBpe0C0XRKGnuCO2fxLI0iYKEFp
m+gZMbj+s40v4g==
-----END CERTIFICATE-----
EOF
    serve_cert = <<EOF
-----BEGIN CERTIFICATE-----
MIID4jCCAsqgAwIBAgIUZrB9yKVNOgt9g4MAj4Z8cjWVWNYwDQYJKoZIhvcNAQEL
BQAwgYgxCzAJBgNVBAYTAlVLMRcwFQYDVQQIEw5HcmVhdGVyIExvbmRvbjEPMA0G
A1UEBxMGTG9uZG9uMRkwFwYDVQQKExBUeWsgVGVjaG5vbG9naWVzMQ8wDQYDVQQL
EwZEZXZvcHMxIzAhBgNVBAMTGlR5ayBEZXZlbG9wZXIgRW52aXJvbm1lbnRzMB4X
DTIwMDYyNTE0NTIwMFoXDTI1MDYyNDE0NTIwMFowgYgxCzAJBgNVBAYTAlVLMRcw
FQYDVQQIEw5HcmVhdGVyIExvbmRvbjEPMA0GA1UEBxMGTG9uZG9uMRkwFwYDVQQK
ExBUeWsgVGVjaG5vbG9naWVzMQ8wDQYDVQQLEwZEZXZvcHMxIzAhBgNVBAMTGlR5
ayBEZXZlbG9wZXIgRW52aXJvbm1lbnRzMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
MIIBCgKCAQEArI0TEIeeO7WU/dEqOiSVmLYBBIrysxD4vhlvO8WUmnV6E778dVYk
7HTPY7pk4aEJnS9hiYJkS5YPIH5aa3wGEkGkpWMFYa+kgIfRF2LcGUL0pQwDCsCR
ev7N9KSUknlLOS6je6oWJKsCDLH9jwyFRvxDMuXf2nWQ0VIg30Txf+cqZhGDbvq+
zrlcdvn49rHvPl/92mIHF8hGNyoR5FwdU/VwnEsqic77KIeNpZUfjMcAFQ7ztAQ8
21+JVMqLXCbBqfm0INQhDfTKENjvxxC+mWaLETZdzlI1OSk9KuKbt0FsELPFJgt3
ciiwvqV4tEKqQrwOj/NigEorFHAG6XmxjQIDAQABo0IwQDAOBgNVHQ8BAf8EBAMC
AQYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUnU4Q1E/tN5+RIzO2VR5bMUBF
mdUwDQYJKoZIhvcNAQELBQADggEBACHrJPFpLw4l2lhHHcFs1+NfCKe5Ftqdrtk8
TmImWhu6AdAn7pQ2GG7qKktdUu6/aDO5NWd8B480YScfjq+lXSvotpJiGQYw0RQp
lgpYqX9kE+zEL2m5vl83ur8CrCh7pdGfb8iHuhCT04dmk32u6bB8m7RjndSrmFPT
4XsFeus88UsueLz9ZP0pPsR4LuMEq2PcCDj5G3ugZqKIaejr4VuTP7NDuAS4qRJJ
tHPeqYbwCxbSZumgbU9FygKjyh5zbsguOCYZOjoN11XhXazhIzoEzLjCczcpvO0X
s2XKc+hGMJXbo0+3CtjSYHZ87EJOfMolyjnz5H4P6+fIMheXtfA=
-----END CERTIFICATE-----
EOF
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
  # Deployment policies, max 10 policies can be attached to a user
  deployment_policies = [
    "AmazonElasticFileSystemFullAccess",
    "IAMReadOnlyAccess"
  ]
  common_tags = {
    "managed" = "automation",
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
  user_data              = file("scripts/mongo-setup.sh")

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
    efs_id      = data.terraform_remote_state.base.outputs.config_efs
    mount_point = "/config"
  }
}

data "template_file" "mount_cfssl_keys" {
  template = file("scripts/setup-efs.sh")
  vars = {
    efs_id      = data.terraform_remote_state.base.outputs.cfssl_efs
    mount_point = "/cfssl"
  }
}

data "template_cloudinit_config" "bastion" {
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

  part {
    content_type = "text/x-shellscript"
    content      = file("scripts/bastion-setup.sh")
  }
}

resource "aws_efs_mount_target" "cfssl" {
  for_each = toset(module.vpc.public_subnets)

  file_system_id  = data.terraform_remote_state.base.outputs.cfssl_efs
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_mount_target" "config" {
  for_each = toset(module.vpc.public_subnets)

  file_system_id  = data.terraform_remote_state.base.outputs.config_efs
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
  user_data_base64       = data.template_cloudinit_config.bastion.rendered

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

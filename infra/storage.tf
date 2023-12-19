locals {
  storage_components = {
    # dns name
    mongo44 = {
      # filter
      ami   = "TykCI Mongo 4.4"
      itype = "t2.micro"
    }
    redis60 = {
      ami   = "TykCI Redis 6.0"
      itype = "t2.micro"
    }
  }
}

data "aws_ami" "storage_components" {
  for_each = local.storage_components

  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = [each.value.ami]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

module "storage_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "storage"
  description = "Persistent storage EC2 instances"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = [module.vpc.vpc_cidr_block]
  ingress_rules       = [
    "postgresql-tcp",
    "mongodb-27017-tcp",
    "redis-tcp",
    "all-icmp"
  ]
}

module "storage_components" {
  source = "terraform-aws-modules/ec2-instance/aws"

  for_each = local.storage_components

  name = each.key

  ami           = data.aws_ami.storage_components[each.key].id
  instance_type = each.value.itype
  key_name      = var.key_name
  monitoring    = true
  vpc_security_group_ids = [
    module.storage_sg.security_group_id,
    aws_security_group.efs.id,
    aws_security_group.ssh.id,
    aws_security_group.egress-all.id
  ]
  subnet_id = element(module.vpc.private_subnets, 1)

  spot_price                          = "0.1"
  spot_wait_for_fulfillment           = true
  spot_type                           = "persistent"
  spot_instance_interruption_behavior = "terminate"

  metadata_options = {
    http_tokens = "required" # IMDSv2
  }
}

resource "aws_route53_zone" "storage_internal" {
  name = "storage.internal"
  vpc {
    vpc_id = module.vpc.vpc_id
  }
}

resource "aws_route53_record" "storage_components" {
  for_each = local.storage_components

  zone_id = aws_route53_zone.storage_internal.zone_id

  name = each.key
  type = "CNAME"
  ttl  = "300"

  records = [module.storage_components[each.key].private_dns]
}

locals {
  cidr = "10.91.0.0/16"
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "private_subnets" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = cidrsubnet(local.cidr, 4, 1)
  networks = [
    { name = "privaz1", new_bits = 4 },
    { name = "privaz2", new_bits = 4 },
    { name = "privaz3", new_bits = 4 },
  ]
}

module "db_subnets" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = cidrsubnet(local.cidr, 4, 8)
  networks = [
    { name = "pubaz1", new_bits = 4 },
    { name = "pubaz2", new_bits = 4 },
    { name = "pubaz3", new_bits = 4 },
  ]
}

module "public_subnets" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = cidrsubnet(local.cidr, 4, 15)
  networks = [
    { name = "pubaz1", new_bits = 4 },
    { name = "pubaz2", new_bits = 4 },
    { name = "pubaz3", new_bits = 4 },
  ]
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "infra"
  cidr = local.cidr

  azs                  = data.aws_availability_zones.available.names
  private_subnets      = module.private_subnets.networks[*].cidr_block
  private_subnet_tags  = { Type = "private" }
  database_subnets     = module.db_subnets.networks[*].cidr_block
  database_subnet_tags = { Type = "rds" }
  public_subnets       = module.public_subnets.networks[*].cidr_block
  public_subnet_tags   = { Type = "public" }

  create_database_subnet_group = true
  enable_nat_gateway           = true
  single_nat_gateway           = true
  map_public_ip_on_launch      = true

  # Need DNS to address EFS by name
  enable_dns_support   = true
  enable_dns_hostnames = true
}

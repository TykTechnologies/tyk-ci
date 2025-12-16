# DependencyTrack Standalone Deployment for Playground Account
# Account: 863518456494 (Tyk Playground: Persistent)
# Region: eu-central-1

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = {
      managed     = "terraform"
      environment = "playground"
      purpose     = "security"
      project     = "deptrack"
    }
  }
}

locals {
  name_prefix    = "deptrack-pg"
  dtrack_port    = 8080
  dtrack_version = "4.13.6"
  dtrack_db_name = "deptrack"
  dtrack_db_user = "deptrack"
  
  # Use existing default VPC
  vpc_id = var.vpc_id
  subnet_ids = var.subnet_ids
}

# Data source for existing VPC
data "aws_vpc" "selected" {
  id = local.vpc_id
}

data "aws_subnets" "selected" {
  filter {
    name   = "subnet-id"
    values = local.subnet_ids
  }
}

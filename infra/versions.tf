terraform {
  cloud {
    organization = "Tyk"

    workspaces {
      name = "infra-prod"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.31.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = ">= 1.0.0"
    }
  }
  required_version = ">= 1.7"
}

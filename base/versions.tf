terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "Tyk"

    workspaces {
      prefix = "base-"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.52.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 4.20.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = ">= 1.0.0"
    }
  }
  required_version = ">= 1.3"
}

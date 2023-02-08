terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "Tyk"

    workspaces {
      prefix = "infra-"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.52.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 3.33.1"
    }
    sops = {
      source  = "carlpett/sops"
      version = ">= 0.5.3"
    }
    template = {
      source = "hashicorp/template"
    }
  }
  required_version = ">= 1.3"
}

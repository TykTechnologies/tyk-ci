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
      source = "hashicorp/aws"
    }
    cloudflare = {
      source = "cloudflare/cloudflare"
    }
    template = {
      source = "hashicorp/template"
    }
    sops = {
      source  = "carlpett/sops"
      version = "0.5.3"
    }
  }
  required_version = ">= 1.3"
}

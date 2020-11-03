terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
    cloudflare = {
      version    = "~> 2.0"
      source     = "terraform-providers/cloudflare"
    }
    template = {
      source = "hashicorp/template"
    }
  }
  required_version = ">= 0.13"
}

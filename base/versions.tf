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
  }
  required_version = ">= 1.3"
}

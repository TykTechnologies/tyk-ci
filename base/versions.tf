terraform {
  required_providers {
    aws = {
      version = "> 2.70"
      source  = "hashicorp/aws"
    }
  }
  required_version = ">= 0.13"
}

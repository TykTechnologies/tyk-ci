terraform {
  required_providers {
    aws = {
      version = "> 3.0"
      source  = "hashicorp/aws"
    }
    mongodbatlas = {
      version = "> 1.3.0"
      source = "mongodb/mongodbatlas"
    }
  }
  required_version = ">= 0.14"
}

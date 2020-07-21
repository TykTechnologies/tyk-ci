variable "name_prefix" {
  description = "Prefixed to resource names where possible"
  type        = string
}

variable "cidr" {
  description = "CIDR for VPC"
  type = string
}

variable "region" {
  type = string
}

variable "key_name" {
  description = "ssh pubkey added to bastion"
  type        = string
}

variable "config_efs" {
  description = "EFS volume with tyk configurations"
  type        = string
}

variable "cfssl_efs" {
  description = "EFS volume with CFSSL keys and certs"
}

variable "efs_sg" {
  description = "SG for access on EFS port"
}

variable "cfssl_apikey" {
  description = "API key for cfssl requests"
}

variable "cfssl_ecr" {
  description = "Repo URL for CFSSL"
}

variable "int_service_ecr" {
  description = "Repo URL for int-service"
}


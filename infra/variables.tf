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

variable "registryid" {
  description = "Registry ID of the ECR repos"
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

variable "cfssl_apikey" {
  description = "API key for cfssl requests"
}

variable "cfssl_image" {
  description = "Full repo URL with tag of the cfssl image to use"
}

variable "gromit_image" {
  description = "Full repo URL with tag of the gromit image to use"
}

variable "gromit_role_arn" {
  description = "Full repo URL with tag of the gromit image to use"
}

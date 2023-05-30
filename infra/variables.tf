variable "base" {
  description = "Name of the terraform workspace which holds the base layer"
  type = string
}

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

variable "stepca_image" {
  description = "Full repo URL with tag of the step-ca image to use"
}

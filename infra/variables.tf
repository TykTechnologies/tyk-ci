variable "base" {
  description = "Name of the terraform workspace which holds the base layer"
  type = string
}

variable "name_prefix" {
  description = "Prefixed to resource names where possible"
  type        = string
}

variable "domain" {
  description = "Prefix added to .tyk.technology to construct the hosted zone"
  type = string
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

variable "cfssl_apikey" {
  description = "API key for cfssl requests"
}

variable "cfssl_image" {
  description = "Full repo URL with tag of the cfssl image to use"
}

variable "gromit_image" {
  description = "Full repo URL with tag of the gromit image to use"
}

variable "atlas_cidr" {
  description = "CIDR for ATLAS"
  type = string
  default = "10.92.0.0/21"
}
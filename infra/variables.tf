variable "name_prefix" {
  description = "Prefixed to resource names where possible"
  type    = string
}

variable "cidr" {
  description = "CIDR for VPC"
  type = string
}

variable "region" {
  type    = string
}

variable "key_name" {
  description = "ssh pubkey added to bastion"
  type    = string
}

variable "config_efs" {
  description = "EFS volume with tyk configurations"
  type = string
}

variable "cfssl_efs" {
  description = "EFS volume with CFSSL keys and certs"
}

variable "repositories" {
  type = list(string)
  default = [ "tyk", "tyk-analytics", "tyk-pump", "int-service", "cfssl" ]
}

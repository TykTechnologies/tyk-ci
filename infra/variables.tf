variable "name_prefix" {
  type    = string
}

variable "cidr" {
  type = string
}

variable "region" {
  type    = string
}

variable "key_name" {
  type    = string
}

variable "repositories" {
  type = list(string)
  default = [ "tyk", "tyk-analytics", "tyk-pump" ]
}

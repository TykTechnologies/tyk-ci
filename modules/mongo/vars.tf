// MongoDB Atlas

variable "atlas_org_id" {
  type        = string
  description = "MongoDB Atlas organisation ID"
}

variable "atlas_teams" {
  type        = list(object({ id = string, roles = list(string) }))
  description = "Assign teams to the MongoDB Atlas project"
  default     = []
}

variable "atlas_instance_size" {
  type        = string
  description = "MongoDB Atlas cluster instance size name"
  default     = "M10"
}

variable "atlas_region" {
  type        = string
  description = "Provider region where MongoDB Atlas cluster will be placed (should be compatible with `aws_region`)"
}

variable "atlas_disk_size_gb" {
  type        = number
  description = "MongoDB Atlas cluster storage size in GB"
  default     = 10
}

variable "atlas_cidr" {
  type        = string
  description = "MongoDB Atlas network container CIDR block (must not intersect with `vpc_cidr`)"
}

variable "atlas_allowed_cidrs" {
  type        = set(string)
  description = "A set of additional CIDRs allowed to access the MongoDB Atlas cluster"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "cluster_provider_name" {
  type        = string
  description = "Mongo Atlas cluster provider"
  default     = "AWS"
}

variable "backup_enabled" {
  type = bool
  description = "Mongo Atlas cluster backup flag"
  default = true
}

// Network peering
variable "peering_enabled" {
  type = bool
  description = "If true, enables VPC peering resources creation"
  default = false
}

variable "peering_aws_region" {
  type        = string
  description = "AWS region to use for cluster deployment"
  default = "eu-central-1"
}

variable "peering_aws_vpc_id" {
  type        = string
  description = "VPC id for cluster network peering"
}

variable "peering_cidr" {
  type        = string
  description = "VPC id for cluster network peering"
  default     = "10.91.0.0/16"
}

// Users
variable "admin_username" {
  type        = string
  description = "Mongo Atlas admin username"
  default     = "ara_admin"
}

variable "admin_password" {
  type        = string
  description = "Mongo Atlas admin password"
}

// General

variable "aws_region" {
  type        = string
  description = "AWS region to use for cluster deployment"
}

variable "default_labels" {
  type = map
  description = "AWS default tags for different resources"
}
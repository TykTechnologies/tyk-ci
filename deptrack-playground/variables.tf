variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "eu-central-1"
}

variable "aws_profile" {
  description = "AWS CLI profile to use"
  type        = string
  default     = "863518456494_AdministratorAccess"
}

variable "vpc_id" {
  description = "VPC ID to use for deployment"
  type        = string
  default     = "vpc-0cc4cd92338453905"
}

variable "subnet_ids" {
  description = "List of subnet IDs for deployment"
  type        = list(string)
  default = [
    "subnet-07e6cada0b69ec28a", # eu-central-1a
    "subnet-0aec1e4d3c9289d89", # eu-central-1c
    "subnet-0daed39c422ca8267"  # eu-central-1b
  ]
}

variable "db_master_password" {
  description = "Master password for RDS database (will be auto-generated if not provided)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "deptrack_db_password" {
  description = "Password for deptrack database user"
  type        = string
  default     = ""
  sensitive   = true
}

variable "create_s3_bucket" {
  description = "Whether to create a new S3 bucket for ALB logs or use existing"
  type        = bool
  default     = true
}

variable "existing_s3_bucket" {
  description = "Existing S3 bucket name for ALB logs (if create_s3_bucket is false)"
  type        = string
  default     = ""
}

variable "frontend_task_count" {
  description = "Number of frontend tasks to run"
  type        = number
  default     = 1
}

variable "api_task_count" {
  description = "Number of API server tasks to run"
  type        = number
  default     = 1
}

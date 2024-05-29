variable "cluster" {
  description = "ECS cluster arn"
  type        = string
}

variable "cdt" {
  description = "Container definition template file"
  type        = string
  default     = "templates/cd-awsvpc.tpl"
}

variable "cd" {
  description = "Container definition object to fill in the template"
  type = object({
    name      = string
    command   = list(string)
    port      = number
    log_group = string
    image     = string
    mounts    = list(object({ src = string, dest = string, readonly = bool }))
    env       = list(map(string))
    secrets   = list(map(string))
    region    = string
  })
}

variable "trarn" {
  description = "Task role ARN for the task"
  type        = string
  default     = ""
}

variable "tearn" {
  description = "Task execution role ARN for the task"
  type        = string
  default     = ""
}

variable "vpc" {
  description = "VPC to use, the task will be attached to networks below"
  type        = string
}

variable "subnets" {
  description = "Subnets that the task will access"
  type        = list(any)
}

variable "volume_map" {
  description = "map of volume name to EFS id"
  type        = map(object({ fs_id = string, root = string }))
}

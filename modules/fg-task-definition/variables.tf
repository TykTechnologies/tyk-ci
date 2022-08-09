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
    cpu       = number
    memory    = number
    log_group = string
    image     = string
    mounts    = list(object({src=string, dest=string, readonly=bool}))
    env       = list(map(string))
    secrets   = list(map(string))
    region    = string
  })
}

variable "tearn" {
  description = "Task execution role ARN"
  type        = string
}

variable "common_tags" {
  description = "Tags to apply to every resource that can be tagged"
  type        = map(string)
}

variable "volume_map" {
  description = "map of volume name to EFS id"
  type        = map(string)
}
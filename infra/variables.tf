variable "base" {
  description = "Name of the terraform workspace which holds the base layer"
  type        = string
}

variable "stepca_image" {
  description = "Full repo URL with tag of the step-ca image to use"
}

variable "gromit_image" {
  description = "Gromit image for TUI and licensers"
}

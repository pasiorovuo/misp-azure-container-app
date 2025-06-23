
variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
}

variable "resource_group" {
  type = object({
    name     = string
    location = string
  })
}

variable "retention_days" {
  type = number
}

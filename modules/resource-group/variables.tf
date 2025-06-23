
variable "location" {
  nullable    = false
  description = "Resource group location."
  type        = string
}

variable "name_prefix" {
  type = string
}

variable "resource_group_name" {
  default     = null
  description = "The name of the resource group to use. If not provided, a new resource group will be created."
  type        = string
}

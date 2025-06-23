variable "config" {
  type = object({
    database_name = string
    sku_name      = optional(string)
    size_gb       = number
    version       = string
  })
}

variable "environment" {
  type = string
}

variable "keyvault" {
  type = object({
    id = string
  })
}

variable "log_analytics_workspace" {
  type = object({
    id = string
  })
}

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

variable "subnet" {
  type = object({
    id = string
  })
}

variable "vnet" {
  type = object({
    id = string
  })
}

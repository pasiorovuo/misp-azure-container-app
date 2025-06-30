variable "config" {
  type = object({
    database_name = string
    sku_name      = optional(string)
    size_gb       = number
    version       = string
  })
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

variable "naming" {
  type = object({
    clean_input   = bool
    name          = string
    prefixes      = list(string)
    random_length = number
    suffixes      = list(string)
    use_slug      = bool
  })
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

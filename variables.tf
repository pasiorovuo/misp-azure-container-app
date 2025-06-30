
variable "cache" {
  default = {
    cpu    = 0.5
    memory = 1
  }
  type = object({
    cpu    = number
    memory = number
  })
}

variable "fqdn" {
  type = string
  validation {
    condition     = length(split(".", var.fqdn)) >= 3 && !endswith(var.fqdn, ".")
    error_message = "FQDN must contain at least three parts i.e. misp.example.com."
  }
}

variable "location" {
  default  = "swedencentral"
  nullable = false
  type     = string
}

variable "log_renention_days" {
  description = "Number of days to store the logs in the log analytics workspace"
  default     = 30
  type        = number
}

variable "database" {
  default = {
    database_name = "misp"
    sku_name      = "B_Standard_B1ms"
    size_gb       = 20
    version       = "8.0"
  }
  type = object({
    database_name = string
    sku_name      = string
    size_gb       = number
    version       = string
  })
}

variable "misp" {
  default = {
    core = {
      cpu    = 1
      memory = 2
      environment = {
        CORE_RUNNING_TAG = "latest"
      }
    }
    modules = {
      cpu    = 0.5
      memory = 1
      environment = {
        MODULES_FLAVOR = "full",
        MODULES_TAG    = "latest"
      }
    }
  }
  type = object({
    core = optional(object({
      cpu         = number
      memory      = number
      environment = map(string)
    }))
    modules = optional(object({
      cpu         = number
      memory      = number
      environment = map(string)
    }))
  })
}

variable "naming" {
  default = {
    name = "misp"
  }
  type = object({
    prefix = optional(string)
    name   = string
    suffix = optional(string)
  })
}

variable "resource_group_name" {
  default  = null
  nullable = true
  type     = string
}

variable "subscription_id" {
  nullable = false
  type     = string
}

variable "vnet_cidr" {
  default = "10.20.0.0/16"
  type    = string
  validation {
    condition     = can(regex("/16$", var.vnet_cidr))
    error_message = "CIDR must end with a /16."
  }
}


variable "environment" {
  default = "dev"
  type    = string

  validation {
    condition     = contains(["dev", "tst", "stg", "prd"], var.environment)
    error_message = "Must be one of dev, tst, stg, prd."
  }
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

variable "misp_env" {
  description = "Environment variables passed to MISP"
  type        = map(string)
}

variable "misp_modules_env" {
  default = {
    MODULES_FLAVOR = "full",
    MODULES_TAG    = "latest"
  }
  description = "Environment variables passed to MISP modules. Defaults to `full` modules with `latest` tag."
  type        = map(string)
}

variable "mysql_config" {
  default = {
    database_name = "misp"
    # Default SKU is selected based on environment according to the map in modules/database/main.tf
    size_gb = 20
    version = "8.0"
  }
  type = object({
    database_name = optional(string)
    sku_name      = optional(string)
    size_gb       = number
    version       = string
  })
}

variable "name_prefix" {
  default = "misp"
  type    = string
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

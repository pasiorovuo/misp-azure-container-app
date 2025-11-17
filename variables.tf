
variable "cache" {
  description = "Configuration for the Redis cache used by MISP."
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
  description = "Fully qualified domain name for the MISP instance."
  type = string
  validation {
    condition     = length(split(".", var.fqdn)) >= 3 && !endswith(var.fqdn, ".")
    error_message = "FQDN must contain at least three parts i.e. misp.example.com."
  }
}

variable "location" {
  description = "Azure region where the resources will be deployed."
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
  description = "Configuration for the MySQL database used by MISP."
  default = {
    database_name = "misp"
    sku_name      = "B_Standard_B1ms"
    size_gb       = 20
    version       = "8.0.21"
  }
  type = object({
    database_name = string
    sku_name      = string
    size_gb       = number
    version       = string
  })
}

variable "ip_allowlist" {
  description = "IP restrictions for restricting access to the MISP instance. `access` permits access to the load balancer used by MISP and consequently to the user interface of MISP. `management` permits access to the user interface as well as different Azure services' (Key Vault, Storage Account etc.) dataplane, enabling management of the resources. Management IP address must include the IP address deploying the infrastructure."
  default = {
    access     = [] # No access
    management = [] # No access
  }
  type = object({
    access     = set(string)
    management = set(string)
  })
}

variable "misp" {
  description = "Configuration for the MISP application components. `core` defines the resources for the core MISP application while `modules` defines the resources for MISP modules. See `terraform.tfvars.example` for example environment variables."
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
  description = "Naming conventions for the resources."
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
  description = "Name of the resource group where the resources will be deployed. If not provided, a new resource group will be created."
  default  = null
  nullable = true
  type     = string
}

variable "storage" {
  description = "Configuration for the storage used by MISP."
  default = {
    quota = 10
  }
  type = object({
    quota = number # Size of file storage
  })
}

variable "subscription_id" {
  description = "Azure subscription ID where the resources will be deployed."
  nullable = false
  type     = string
}

variable "vnet_cidr" {
  description = "CIDR block for the virtual network."
  default = "10.20.0.0/16"
  type    = string
  validation {
    condition     = can(regex("/16$", var.vnet_cidr))
    error_message = "CIDR must end with a /16."
  }
}

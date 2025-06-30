variable "cache" {
  default = {
    cpu    = 0.5
    memory = 1
  }
  type = object({
    cpu    = number
    memory = number
    # REDIS_HOST = string
    # REDIS_PORT = string
  })
}

variable "database" {
  type = object({
    MYSQL_HOST     = string
    MYSQL_PORT     = string
    MYSQL_USER     = string
    MYSQL_DATABASE = string
  })
}

variable "fqdn" {
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

variable "misp" {
  type = object({
    core = object({
      cpu         = number
      memory      = number
      environment = map(string)
    })
    modules = object({
      cpu         = number
      memory      = number
      environment = map(string)
    })
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

variable "secret_ids" {
  type = object({
    # cache_password = string
    db_password = string
  })
}

variable "storage_account" {
  type = object({
    id         = string
    name       = string
    access_key = string
    share = object({
      id   = string
      name = string
    })
  })
}

variable "subnet" {
  type = object({
    id = string
  })
}

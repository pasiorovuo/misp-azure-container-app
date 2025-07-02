
variable "config" {
  type = object({
    quota = number
  })
}

variable "ip_allowlist" {
  type = set(string)
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

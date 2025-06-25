
variable "cidr" {
  type = string
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

variable "network_contributor_identities" {
  default     = []
  description = "List of identities that will be granted the Network Contributor role on the vnet"
  type        = list(string)
}

variable "resource_group" {
  type = object({
    name     = string
    location = string
  })
}

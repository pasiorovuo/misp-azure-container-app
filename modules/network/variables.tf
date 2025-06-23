
variable "cidr" {
  type = string
}

variable "name_prefix" {
  description = "Name prefix for resources"
  type        = string
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

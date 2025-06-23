
variable "keyvault_secrets_officer_identities" {
  default     = []
  description = "List of identities that will be granted the Key Vault Secrets Officer role on the key vault"
  type        = list(string)
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

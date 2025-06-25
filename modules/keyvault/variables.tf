
variable "keyvault_secrets_officer_identities" {
  default     = []
  description = "List of identities that will be granted the Key Vault Secrets Officer role on the key vault"
  type        = list(string)
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

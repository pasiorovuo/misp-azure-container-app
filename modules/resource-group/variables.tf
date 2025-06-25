
variable "location" {
  nullable    = false
  description = "Resource group location."
  type        = string
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

variable "resource_group_name" {
  default     = null
  description = "The name of the resource group to use. If not provided, a new resource group will be created."
  type        = string
}

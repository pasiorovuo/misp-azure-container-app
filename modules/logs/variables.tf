
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

variable "retention_days" {
  type = number
}

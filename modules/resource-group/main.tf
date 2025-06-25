
locals {
  location            = var.location
  resource_group_name = var.resource_group_name
  naming              = var.naming
}

data "azurerm_resource_group" "resource_group" {
  count = local.resource_group_name != null ? 1 : 0

  name = local.resource_group_name
}

resource "azurecaf_name" "resource_group" {
  clean_input   = local.naming.clean_input
  name          = local.naming.name
  prefixes      = local.naming.prefixes
  random_length = local.naming.random_length
  resource_type = "azurerm_resource_group"
  suffixes      = local.naming.suffixes
  use_slug      = local.naming.use_slug
}

resource "azurerm_resource_group" "resource_group" {
  count = local.resource_group_name == null ? 1 : 0

  name     = azurecaf_name.resource_group.result
  location = local.location
}

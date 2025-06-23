
locals {
  location    = var.location
  name        = var.resource_group_name
  name_prefix = var.name_prefix
}

data "azurerm_resource_group" "resource_group" {
  count = local.name != null ? 1 : 0

  name = local.name
}

resource "azurerm_resource_group" "resource_group" {
  count = local.name == null ? 1 : 0

  name     = "${local.name_prefix}-rg"
  location = local.location
}

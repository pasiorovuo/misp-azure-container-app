
locals {
  naming         = var.naming
  resource_group = var.resource_group
  retention_days = var.retention_days
}

resource "azurecaf_name" "workspace" {
  clean_input   = local.naming.clean_input
  name          = local.naming.name
  prefixes      = local.naming.prefixes
  random_length = local.naming.random_length
  resource_type = "azurerm_log_analytics_workspace"
  suffixes      = local.naming.suffixes
  use_slug      = local.naming.use_slug
}

resource "azurerm_log_analytics_workspace" "workspace" {
  name                = azurecaf_name.workspace.result
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  sku                 = "PerGB2018"
  retention_in_days   = local.retention_days
}

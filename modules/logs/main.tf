
locals {
  name_prefix    = var.name_prefix
  resource_group = var.resource_group
  retention_days = var.retention_days
}

resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "${local.name_prefix}-log-analytics-ws"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  sku                 = "PerGB2018"
  retention_in_days   = local.retention_days
}

locals {
  keyvault                = var.keyvault
  log_analytics_workspace = var.log_analytics_workspace
  prefix                  = var.name_prefix
  private_dns_zone_name   = "privatelink.redis.cache.windows.net"
  resource_group          = var.resource_group
  subnet                  = var.subnet
  vnet                    = var.vnet
}

resource "random_string" "identifier" {
  length  = 8
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "azurerm_redis_cache" "cache" {
  capacity                      = 0
  family                        = "C"
  location                      = local.resource_group.location
  name                          = "${local.prefix}-redis-${random_string.identifier.result}"
  non_ssl_port_enabled          = true
  public_network_access_enabled = false
  resource_group_name           = local.resource_group.name
  sku_name                      = "Basic"
}

resource "azurerm_private_endpoint" "cache" {
  name                = "${local.prefix}-cache-private-endpoint"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
  subnet_id           = local.subnet.id

  private_service_connection {
    is_manual_connection           = false
    name                           = "cache-private-connection"
    private_connection_resource_id = azurerm_redis_cache.cache.id
    subresource_names              = ["redisCache"]
  }

  private_dns_zone_group {
    name                 = "dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.cache.id]
  }
}

resource "azurerm_private_dns_zone" "cache" {
  name                = local.private_dns_zone_name
  resource_group_name = local.resource_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "cache" {
  name                  = "${local.prefix}-cache-private-dns-zone-link"
  resource_group_name   = local.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.cache.name
  virtual_network_id    = local.vnet.id
}

resource "azurerm_key_vault_secret" "primary" {
  key_vault_id = local.keyvault.id
  name         = "${local.prefix}-cache-primary-access-key"
  value        = azurerm_redis_cache.cache.primary_access_key
}

resource "azurerm_key_vault_secret" "secondary" {
  key_vault_id = local.keyvault.id
  name         = "${local.prefix}-cache-secondary-access-key"
  value        = azurerm_redis_cache.cache.secondary_access_key
}

resource "azurerm_monitor_diagnostic_setting" "database" {
  log_analytics_workspace_id = local.log_analytics_workspace.id
  name                       = "${local.prefix}-cache-diagnostic-settings"
  target_resource_id         = azurerm_redis_cache.cache.id

  enabled_log {
    category = "ConnectedClientList"
  }
  enabled_metric {
    category = "AllMetrics"
  }
}

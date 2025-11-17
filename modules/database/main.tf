
locals {
  admin_username          = "mispadmin"
  config                  = var.config
  keyvault                = var.keyvault
  log_analytics_workspace = var.log_analytics_workspace
  # TODO: Make these configurable
  mysql_tweaks = {
    # innodb_buffer_pool_size = "1073741824" # Closest supported value 2147483648
    # innodb_change_buffering = "none"
    # innodb_io_capacity      = "1000"
    # innodb_io_capacity_max  = "2000"
    # innodb_log_file_size    = "536870912" # Closest supported value in Azure
    # innodb_read_io_threads  = "16"
    # innodb_stats_persistent = "ON"
    # innodb_write_io_threads = "4"
    long_query_time          = "10"
    require_secure_transport = "OFF"
    slow_query_log           = "ON"
  }
  naming         = var.naming
  resource_group = var.resource_group
  subnet         = var.subnet
  vnet           = var.vnet
}

data "azurerm_client_config" "current" {}

resource "random_password" "admin_password" {
  length      = 24
  lower       = true
  min_lower   = 1
  min_numeric = 1
  min_upper   = 1
  numeric     = true
  special     = false
  upper       = true
}

resource "azurecaf_name" "database" {
  clean_input   = local.naming.clean_input
  name          = local.naming.name
  prefixes      = local.naming.prefixes
  random_length = local.naming.random_length
  resource_type = "azurerm_mysql_server"
  suffixes      = local.naming.suffixes
  use_slug      = local.naming.use_slug
}

resource "azurecaf_name" "admin_password" {
  clean_input   = local.naming.clean_input
  name          = "${local.naming.name}-db-admin-pwd"
  prefixes      = local.naming.prefixes
  random_length = local.naming.random_length
  resource_type = "azurerm_key_vault_secret"
  suffixes      = local.naming.suffixes
  use_slug      = local.naming.use_slug
}

resource "azurerm_key_vault_secret" "password" {
  key_vault_id = local.keyvault.id
  name         = azurecaf_name.admin_password.result
  value        = random_password.admin_password.result
}

resource "time_sleep" "sleep_60_seconds" {
  create_duration = "60s"
  depends_on      = [azurerm_key_vault_secret.password]
}

resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = local.resource_group.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = replace(azurecaf_name.database.result, "mysql", "dnsvnetlnk")
  resource_group_name   = local.resource_group.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = local.vnet.id
}

resource "azurerm_mysql_flexible_server" "database" {
  administrator_login    = local.admin_username
  administrator_password = azurerm_key_vault_secret.password.value
  backup_retention_days  = 30
  delegated_subnet_id    = local.subnet.id
  depends_on             = [
    azurerm_key_vault_secret.password,
    azurerm_private_dns_zone_virtual_network_link.sql,
    time_sleep.sleep_60_seconds
  ]
  location               = local.resource_group.location
  name                   = azurecaf_name.database.result
  private_dns_zone_id    = azurerm_private_dns_zone.sql.id
  resource_group_name    = local.resource_group.name
  sku_name               = local.config.sku_name
  version                = local.config.version

  storage {
    auto_grow_enabled = true
    # Define IOPS?
    size_gb = local.config.size_gb
  }
}

resource "azurerm_mysql_flexible_server_configuration" "database" {
  for_each = local.mysql_tweaks

  name                = each.key
  resource_group_name = local.resource_group.name
  server_name         = azurerm_mysql_flexible_server.database.name
  value               = each.value
}

resource "azurerm_monitor_diagnostic_setting" "database" {
  log_analytics_workspace_id = local.log_analytics_workspace.id
  name                       = replace(azurecaf_name.database.result, "mysql", "diagsett")
  target_resource_id         = azurerm_mysql_flexible_server.database.id

  enabled_log {
    category = "MySqlAuditLogs"
  }
  enabled_log {
    category = "MySqlSlowLogs"
  }
  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azurerm_mysql_flexible_database" "misp" {
  name                = local.config.database_name
  resource_group_name = local.resource_group.name
  server_name         = azurerm_mysql_flexible_server.database.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

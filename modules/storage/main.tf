
locals {
  naming         = var.naming
  resource_group = var.resource_group
  subnet         = var.subnet
  vnet           = var.vnet
}

resource "azurecaf_name" "storage_account" {
  clean_input   = local.naming.clean_input
  name          = local.naming.name
  prefixes      = local.naming.prefixes
  random_length = local.naming.random_length
  resource_type = "azurerm_storage_account"
  suffixes      = local.naming.suffixes
  use_slug      = local.naming.use_slug
}

resource "azurecaf_name" "storage_share" {
  clean_input   = var.naming.clean_input
  name          = var.naming.name
  prefixes      = var.naming.prefixes
  random_length = var.naming.random_length
  resource_type = "azurerm_storage_share"
  suffixes      = var.naming.suffixes
  use_slug      = var.naming.use_slug
}

# resource "azurecaf_name" "private_endpoint" {
#   clean_input   = var.naming.clean_input
#   name          = var.naming.name
#   prefixes      = var.naming.prefixes
#   random_length = var.naming.random_length
#   resource_type = "azurerm_private_endpoint"
#   suffixes      = var.naming.suffixes
#   use_slug      = var.naming.use_slug
# }

# data "http" "public_ip" {
#   url = "https://icanhazip.com"
# }

resource "azurerm_storage_account" "storage" {
  account_kind                      = "StorageV2"
  account_replication_type          = "LRS"
  account_tier                      = "Standard"
  https_traffic_only_enabled        = true
  infrastructure_encryption_enabled = true
  large_file_share_enabled          = true
  location                          = local.resource_group.location
  name                              = azurecaf_name.storage_account.result
  public_network_access_enabled     = true
  resource_group_name               = local.resource_group.name

  network_rules {
    bypass                     = ["Logging", "Metrics", "AzureServices"]
    default_action             = "Deny"
    ip_rules                   = [] # [trimspace(data.http.public_ip.response_body)]
    virtual_network_subnet_ids = [local.subnet.id]
  }
}

# resource "azurerm_private_endpoint" "private_endpoint" {
#   name                = azurecaf_name.private_endpoint.result
#   location            = local.resource_group.location
#   resource_group_name = local.resource_group.name
#   subnet_id           = local.subnet.id

#   private_service_connection {
#     name                           = "private-service-connection"
#     private_connection_resource_id = azurerm_storage_account.storage.id
#     subresource_names              = ["file"]
#     is_manual_connection           = false
#   }

#   private_dns_zone_group {
#     name                 = "dns-zone-group"
#     private_dns_zone_ids = [azurerm_private_dns_zone.dns_zone.id]
#   }
# }

# resource "azurerm_private_dns_zone" "dns_zone" {
#   name                = "privatelink.file.core.windows.net"
#   resource_group_name = local.resource_group.name
# }

# resource "azurerm_private_dns_zone_virtual_network_link" "virtual_network_link" {
#   name                  = "virtual-network-link"
#   private_dns_zone_name = azurerm_private_dns_zone.dns_zone.name
#   resource_group_name   = local.resource_group.name
#   virtual_network_id    = local.vnet.id
# }

resource "azurerm_storage_share" "share" {
  enabled_protocol   = "SMB"
  name               = azurecaf_name.storage_share.result
  quota              = 10
  storage_account_id = azurerm_storage_account.storage.id
}

# resource "azurerm_storage_share_directory" "configs" {
#   name             = "configs"
#   storage_share_id = azurerm_storage_share.share.url
# }

# resource "azurerm_storage_share_directory" "logs" {
#   name             = "logs"
#   storage_share_id = azurerm_storage_share.share.url
# }

# resource "azurerm_storage_share_directory" "files" {
#   name             = "files"
#   storage_share_id = azurerm_storage_share.share.url
# }

# resource "azurerm_storage_share_directory" "ssl" {
#   name             = "ssl"
#   storage_share_id = azurerm_storage_share.share.url
# }

# resource "azurerm_storage_share_directory" "gnupg" {
#   name             = "gnupg"
#   storage_share_id = azurerm_storage_share.share.url
# }


locals {
  cidr                           = var.cidr
  naming                         = var.naming
  network_contributor_identities = var.network_contributor_identities
  resource_group                 = var.resource_group
}

resource "azurecaf_name" "vnet" {
  clean_input   = local.naming.clean_input
  name          = local.naming.name
  prefixes      = local.naming.prefixes
  random_length = local.naming.random_length
  resource_type = "azurerm_virtual_network"
  suffixes      = local.naming.suffixes
  use_slug      = local.naming.use_slug
}

resource "azurecaf_name" "subnet_app" {
  clean_input   = local.naming.clean_input
  name          = "${local.naming.name}-app"
  prefixes      = local.naming.prefixes
  random_length = local.naming.random_length
  resource_type = "azurerm_subnet"
  resource_types = [
    "azurerm_network_security_group",
    "azurerm_network_security_group_rule",
    "azurerm_public_ip"
  ]
  suffixes = local.naming.suffixes
  use_slug = local.naming.use_slug
}

resource "azurecaf_name" "subnet_database" {
  clean_input    = local.naming.clean_input
  name           = "${local.naming.name}-database"
  prefixes       = local.naming.prefixes
  random_length  = local.naming.random_length
  resource_type  = "azurerm_subnet"
  resource_types = ["azurerm_network_security_group", "azurerm_network_security_group_rule"]
  suffixes       = local.naming.suffixes
  use_slug       = local.naming.use_slug
}

# resource "azurecaf_name" "subnet_cache" {
#   clean_input    = local.naming.clean_input
#   name           = "${local.naming.name}-cache"
#   prefixes       = local.naming.prefixes
#   random_length  = local.naming.random_length
#   resource_type  = "azurerm_subnet"
#   resource_types = ["azurerm_network_security_group", "azurerm_network_security_group_rule"]
#   suffixes       = local.naming.suffixes
#   use_slug       = local.naming.use_slug
# }

resource "azurecaf_name" "subnet_storage_account" {
  clean_input    = local.naming.clean_input
  name           = "${local.naming.name}-storage-account"
  prefixes       = local.naming.prefixes
  random_length  = local.naming.random_length
  resource_type  = "azurerm_subnet"
  resource_types = ["azurerm_network_security_group", "azurerm_network_security_group_rule"]
  suffixes       = local.naming.suffixes
  use_slug       = local.naming.use_slug
}

resource "azurerm_virtual_network" "vnet" {
  address_space       = [local.cidr]
  location            = local.resource_group.location
  name                = azurecaf_name.vnet.result
  resource_group_name = local.resource_group.name
}

resource "azurerm_subnet" "app" {
  address_prefixes     = [cidrsubnet(local.cidr, 7, 0)]
  name                 = azurecaf_name.subnet_app.result
  resource_group_name  = local.resource_group.name
  service_endpoints    = ["Microsoft.KeyVault", "Microsoft.Storage"]
  virtual_network_name = azurerm_virtual_network.vnet.name

  delegation {
    name = "app-delegation"
    service_delegation {
      name = "Microsoft.App/environments"
      # actions = [
      #   "Microsoft.Network/virtualNetworks/subnets/action",
      # ]
    }
  }
  lifecycle {
    ignore_changes = [delegation]
  }
}

resource "azurerm_subnet" "database" {
  address_prefixes                = [cidrsubnet(local.cidr, 8, 50)]
  default_outbound_access_enabled = false
  name                            = azurecaf_name.subnet_database.result
  resource_group_name             = local.resource_group.name
  service_endpoints               = ["Microsoft.KeyVault"]
  virtual_network_name            = azurerm_virtual_network.vnet.name

  delegation {
    name = "database-delegation"
    service_delegation {
      name = "Microsoft.DBforMySQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action",
      ]
    }
  }
  lifecycle {
    ignore_changes = [delegation]
  }
}

# resource "azurerm_subnet" "cache" {
#   address_prefixes                = [cidrsubnet(local.cidr, 8, 60)]
#   default_outbound_access_enabled = false
#   name                            = azurecaf_name.subnet_cache.result
#   resource_group_name             = local.resource_group.name
#   service_endpoints               = ["Microsoft.KeyVault"]
#   virtual_network_name            = azurerm_virtual_network.vnet.name
# }

resource "azurerm_subnet" "storage_account" {
  address_prefixes                = [cidrsubnet(local.cidr, 8, 70)]
  default_outbound_access_enabled = false
  name                            = azurecaf_name.subnet_storage_account.result
  resource_group_name             = local.resource_group.name
  service_endpoints               = ["Microsoft.KeyVault", "Microsoft.Storage"]
  virtual_network_name            = azurerm_virtual_network.vnet.name
}

resource "azurerm_network_security_group" "app" {
  name                = azurecaf_name.subnet_app.results["azurerm_network_security_group"]
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
}

resource "azurerm_subnet_network_security_group_association" "app" {
  network_security_group_id = azurerm_network_security_group.app.id
  subnet_id                 = azurerm_subnet.app.id
}

resource "azurerm_network_security_group" "database" {
  name                = azurecaf_name.subnet_database.results["azurerm_network_security_group"]
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
}

resource "azurerm_subnet_network_security_group_association" "database" {
  network_security_group_id = azurerm_network_security_group.database.id
  subnet_id                 = azurerm_subnet.database.id
}

# resource "azurerm_network_security_group" "cache" {
#   name                = azurecaf_name.subnet_cache.results["azurerm_network_security_group"]
#   location            = local.resource_group.location
#   resource_group_name = local.resource_group.name
# }

# resource "azurerm_subnet_network_security_group_association" "cache" {
#   network_security_group_id = azurerm_network_security_group.cache.id
#   subnet_id                 = azurerm_subnet.cache.id
# }

resource "azurerm_network_security_group" "storage_account" {
  name                = azurecaf_name.subnet_storage_account.results["azurerm_network_security_group"]
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name
}

resource "azurerm_subnet_network_security_group_association" "storage_account" {
  network_security_group_id = azurerm_network_security_group.storage_account.id
  subnet_id                 = azurerm_subnet.storage_account.id
}

resource "azurerm_public_ip" "natgw_ip" {
  allocation_method   = "Static"
  location            = local.resource_group.location
  name                = azurecaf_name.subnet_app.results["azurerm_public_ip"]
  resource_group_name = local.resource_group.name
}

resource "azurerm_nat_gateway" "natgw" {
  location            = local.resource_group.location
  name                = replace(azurecaf_name.subnet_app.result, "snet", "natgw")
  resource_group_name = local.resource_group.name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "natgw_ip_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.natgw.id
  public_ip_address_id = azurerm_public_ip.natgw_ip.id
}

resource "azurerm_subnet_nat_gateway_association" "app" {
  nat_gateway_id = azurerm_nat_gateway.natgw.id
  subnet_id      = azurerm_subnet.app.id
}

resource "azurerm_role_assignment" "network_contributor" {
  for_each             = toset(local.network_contributor_identities)
  scope                = azurerm_virtual_network.vnet.id
  role_definition_name = "Network Contributor"
  principal_id         = each.key
}

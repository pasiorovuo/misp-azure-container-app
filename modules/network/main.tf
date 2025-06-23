
locals {
  cidr                           = var.cidr
  network_contributor_identities = var.network_contributor_identities
  prefix                         = var.name_prefix
  resource_group                 = var.resource_group
}

resource "azurerm_virtual_network" "vnet" {
  address_space       = [local.cidr]
  location            = local.resource_group.location
  name                = "${local.prefix}-vnet"
  resource_group_name = local.resource_group.name
}

resource "azurerm_subnet" "public" {
  address_prefixes     = [cidrsubnet(local.cidr, 8, 10)]
  name                 = "${local.prefix}-public-subnet"
  resource_group_name  = local.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
}

resource "azurerm_subnet" "app" {
  address_prefixes     = [cidrsubnet(local.cidr, 7, 50)]
  name                 = "${local.prefix}-app-subnet"
  resource_group_name  = local.resource_group.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  delegation {
    name = "${local.prefix}-app-delegation"
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
  address_prefixes                = [cidrsubnet(local.cidr, 8, 30)]
  default_outbound_access_enabled = false
  name                            = "${local.prefix}-database-subnet"
  resource_group_name             = local.resource_group.name
  virtual_network_name            = azurerm_virtual_network.vnet.name

  delegation {
    name = "${local.prefix}-mysql-delegation"
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

resource "azurerm_subnet" "cache" {
  address_prefixes                = [cidrsubnet(local.cidr, 8, 40)]
  default_outbound_access_enabled = false
  name                            = "${local.prefix}-cache-subnet"
  resource_group_name             = local.resource_group.name
  virtual_network_name            = azurerm_virtual_network.vnet.name
}

# resource "azurerm_network_security_group" "public" {
#   name                = "${local.prefix}-public-nsg"
#   location            = local.resource_group.location
#   resource_group_name = local.resource_group.name

#   security_rule {
#     name                       = "Allow-HTTPS"
#     priority                   = 100
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "443"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
# }

resource "azurerm_network_security_group" "app" {
  name                = "${local.prefix}-app-nsg"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name

  # security_rule {
  #   name                       = "Allow-HTTPS"
  #   priority                   = 100
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   destination_port_range     = "*"
  #   source_address_prefix      = azurerm_subnet.subnet_public.address_prefixes[0]
  #   destination_address_prefix = "*"
  # }
}

resource "azurerm_subnet_network_security_group_association" "app" {
  network_security_group_id = azurerm_network_security_group.app.id
  subnet_id                 = azurerm_subnet.app.id
}

resource "azurerm_network_security_group" "database" {
  name                = "${local.prefix}-database-nsg"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name


  # security_rule {
  #   name                       = "Allow-Vnet-Inbound"
  #   priority                   = 100
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   destination_port_range     = "*"
  #   source_address_prefix      = azurerm_subnet.app.address_prefixes[0]
  #   destination_address_prefix = "*"
  # }

  # security_rule {
  #   name                       = "Deny-Outbound"
  #   priority                   = 100
  #   direction                  = "Outbound"
  #   access                     = "Deny"
  #   protocol                   = "*"
  #   source_port_range          = "*"
  #   destination_port_range     = "*"
  #   source_address_prefix      = "*"
  #   destination_address_prefix = "*"
  # }
}

resource "azurerm_subnet_network_security_group_association" "database" {
  network_security_group_id = azurerm_network_security_group.database.id
  subnet_id                 = azurerm_subnet.database.id
}

resource "azurerm_network_security_group" "cache" {
  name                = "${local.prefix}-cache-nsg"
  location            = local.resource_group.location
  resource_group_name = local.resource_group.name

  # security_rule {
  #   name                       = "Allow-Vnet-Inbound"
  #   priority                   = 100
  #   direction                  = "Inbound"
  #   access                     = "Allow"
  #   protocol                   = "Tcp"
  #   source_port_range          = "*"
  #   destination_port_range     = "*"
  #   source_address_prefix      = azurerm_subnet.app.address_prefixes[0]
  #   destination_address_prefix = "*"
  # }

  # security_rule {
  #   name                       = "Deny-Outbound"
  #   priority                   = 100
  #   direction                  = "Outbound"
  #   access                     = "Deny"
  #   protocol                   = "*"
  #   source_port_range          = "*"
  #   destination_port_range     = "*"
  #   source_address_prefix      = "*"
  #   destination_address_prefix = "*"
  # }
}

resource "azurerm_subnet_network_security_group_association" "cache" {
  network_security_group_id = azurerm_network_security_group.cache.id
  subnet_id                 = azurerm_subnet.cache.id
}

resource "azurerm_public_ip" "natgw_ip" {
  allocation_method   = "Static"
  location            = local.resource_group.location
  name                = "${local.prefix}-natgw-ip"
  resource_group_name = local.resource_group.name
}

resource "azurerm_nat_gateway" "natgw" {
  location            = local.resource_group.location
  name                = "${local.prefix}-natgw"
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

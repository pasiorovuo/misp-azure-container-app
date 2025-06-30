output "vnet" {
  value = azurerm_virtual_network.vnet
}

output "subnets" {
  value = {
    app = azurerm_subnet.app
    # cache           = azurerm_subnet.cache
    database        = azurerm_subnet.database
    storage_account = azurerm_subnet.storage_account
  }
}

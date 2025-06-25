
output "storage_account" {
  value = {
    id         = azurerm_storage_account.storage.id
    name       = azurerm_storage_account.storage.name
    access_key = azurerm_storage_account.storage.primary_access_key
  }
}

output "share" {
  value = {
    id   = azurerm_storage_share.share.id
    name = azurerm_storage_share.share.name
    # directories = {
    #   # configs = azurerm_storage_share_directory.configs.name
    #   # files   = azurerm_storage_share_directory.files.name
    #   # gnupg   = azurerm_storage_share_directory.gnupg.name
    #   # logs    = azurerm_storage_share_directory.logs.name
    #   # ssl     = azurerm_storage_share_directory.ssl.name
    # }
  }
}

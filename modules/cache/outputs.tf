
output "access_keys" {
  value = {
    primary   = azurerm_key_vault_secret.primary.id
    secondary = azurerm_key_vault_secret.secondary.id
  }
}

output "host" {
  value = {
    name = azurerm_redis_cache.cache.hostname
    port = azurerm_redis_cache.cache.port
  }
}

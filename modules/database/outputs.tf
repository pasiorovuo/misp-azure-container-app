
output "hostname" {
  value = azurerm_mysql_flexible_server.database.fqdn
}

output "port" {
  value = 3306
}

output "credentials" {
  value = {
    username = local.admin_username
    password = azurerm_key_vault_secret.password.id
  }
}

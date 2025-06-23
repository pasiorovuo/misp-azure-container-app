
output "output" {
  depends_on = [azurerm_key_vault_secret.null_secret]
  value      = azurerm_key_vault.keyvault
}

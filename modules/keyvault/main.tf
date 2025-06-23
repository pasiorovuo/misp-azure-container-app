
locals {
  keyvault_secrets_officer_identities = var.keyvault_secrets_officer_identities
  prefix                              = var.name_prefix
  resource_group                      = var.resource_group
}

data "azurerm_client_config" "current" {}

resource "random_string" "identifier" {
  length  = 8
  lower   = true
  numeric = true
  special = false
  upper   = false
}

resource "azurerm_key_vault" "keyvault" {
  enable_rbac_authorization     = true
  location                      = local.resource_group.location
  name                          = "${local.prefix}-keyvault-${random_string.identifier.result}"
  public_network_access_enabled = true
  purge_protection_enabled      = true
  resource_group_name           = local.resource_group.name
  sku_name                      = "standard"
  soft_delete_retention_days    = 7
  tenant_id                     = data.azurerm_client_config.current.tenant_id
}

resource "time_sleep" "sleep_60_seconds" {
  create_duration = "60s"
  depends_on      = [azurerm_key_vault.keyvault]
}

resource "azurerm_role_assignment" "keyvault_secrets_officer" {
  for_each             = toset(local.keyvault_secrets_officer_identities)
  principal_id         = each.key
  role_definition_name = "Key Vault Secrets Officer"
  scope                = azurerm_key_vault.keyvault.id
}

resource "azurerm_role_assignment" "administrator" {
  principal_id         = data.azurerm_client_config.current.object_id
  role_definition_name = "Key Vault Administrator"
  scope                = azurerm_key_vault.keyvault.id
}

resource "azurerm_key_vault_secret" "null_secret" {
  depends_on   = [time_sleep.sleep_60_seconds]
  key_vault_id = azurerm_key_vault.keyvault.id
  name         = "${local.prefix}-null-secret"
  value        = "Purpose of this secret is to introduce a delay after creating the key vault, so the permissions would have time to be propagated, and creation of secrets would succeed without errors."
}

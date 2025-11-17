
locals {
  ip_allowlist                        = var.ip_allowlist
  keyvault_secrets_officer_identities = var.keyvault_secrets_officer_identities
  naming                              = var.naming
  resource_group                      = var.resource_group
  subnet_ids                          = var.subnet_ids
}

data "azurerm_client_config" "current" {}

resource "azurecaf_name" "key_vault" {
  clean_input    = local.naming.clean_input
  name           = local.naming.name
  prefixes       = local.naming.prefixes
  random_length  = local.naming.random_length
  resource_type  = "azurerm_key_vault"
  resource_types = ["azurerm_key_vault_secret"]
  suffixes       = local.naming.suffixes
  use_slug       = local.naming.use_slug
}

resource "azurerm_key_vault" "keyvault" {
  location                      = local.resource_group.location
  name                          = azurecaf_name.key_vault.result
  public_network_access_enabled = true
  purge_protection_enabled      = true
  rbac_authorization_enabled    = true
  resource_group_name           = local.resource_group.name
  sku_name                      = "standard"
  soft_delete_retention_days    = 7
  tenant_id                     = data.azurerm_client_config.current.tenant_id

  network_acls {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    ip_rules                   = local.ip_allowlist
    virtual_network_subnet_ids = local.subnet_ids
  }
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
  name         = azurecaf_name.key_vault.results["azurerm_key_vault_secret"]
  value        = "Purpose of this secret is to introduce a delay after creating the key vault, so the permissions would have time to be propagated, and creation of secrets would succeed without errors."
}

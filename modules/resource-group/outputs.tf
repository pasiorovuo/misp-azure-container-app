
output "output" {
  value = local.name != null ? data.azurerm_resource_group.resource_group[0] : azurerm_resource_group.resource_group[0]
}

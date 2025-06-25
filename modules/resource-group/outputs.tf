
output "result" {
  value = local.resource_group_name != null ? data.azurerm_resource_group.resource_group[0] : azurerm_resource_group.resource_group[0]
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}
output "function_app_name" {
  value = azurerm_function_app.func.name
}
output "cosmos_account_name" {
  value = azurerm_cosmosdb_account.cosmos.name
}

output "cosmos_db_name" {
  value = azurerm_cosmosdb_sql_database.db.name
}

output "cosmos_container_name" {
  value = azurerm_cosmosdb_sql_container.container.name
}
provider "azurerm" {
  features {}
  subscription_id = "77a5c8b6-a16a-4269-98ee-1dd34a3266fd"
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}
resource "azurerm_storage_account" "sa" {
  name                     = "serverlessapisa${random_id.suffix.hex}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "random_id" "suffix" {
  byte_length = 4
}

resource "azurerm_app_service_plan" "plan" {
  name                = "serverless-api-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "FunctionApp"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "func" {
  name                       = "serverless-api-func"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_app_service_plan.plan.id
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  version                    = "~4"

  app_settings = {
    COSMOS_DB_CONNECTION_STRING = azurerm_cosmosdb_account.cosmos.primary_sql_connection_string
    COSMOS_DB_DATABASE_NAME     = azurerm_cosmosdb_sql_database.db.name
    COSMOS_DB_CONTAINER_NAME    = azurerm_cosmosdb_sql_container.container.name
  }

  site_config {
    linux_fx_version = "python|3.9"
  }

  identity {
    type = "SystemAssigned"
  }
}
resource "azurerm_cosmosdb_account" "cosmos" {
  name                = "serverless-api-cosmos"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }
}

resource "azurerm_cosmosdb_sql_database" "db" {
  name                = "tasks-db"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
}

resource "azurerm_cosmosdb_sql_container" "container" {
  name                = "tasks"
  resource_group_name = azurerm_resource_group.rg.name
  account_name        = azurerm_cosmosdb_account.cosmos.name
  database_name       = azurerm_cosmosdb_sql_database.db.name
  partition_key_paths = ["/id"]
}
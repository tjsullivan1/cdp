terraform {
  backend "remote" {
    organization = "tjssullivanent"

    workspaces {
      name = "cdp"
    }
  }
}

# Configure the Azure provider
provider "azurerm" {
  version = "= 2.13.0"
  features {}
}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azurerm_key_vault" "kv" {
  name                = "kv-tjs-01"
  resource_group_name = "rg-development-resources-01"
}

resource "azurerm_storage_account" "funcstore" {
  name                     = "stor${var.name}${var.env}"
  resource_group_name      = data.azurerm_resource_group.rg.name
  location                 = data.azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "asp" {
  name                = "azapp-${var.name}-${var.env}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  kind                = "FunctionApp"
  reserved = (var.os == "linux"
    ? true
  : false)

  sku {
    tier = var.function_tier
    size = var.function_size
  }
}

resource "azurerm_application_insights" "appin" {
  name                = "appin-${var.name}-${var.env}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  application_type    = "web"
}

resource "azurerm_function_app" "function_lin" {
  count = (var.os == "linux"
    ? 1
  : 0)

  name                       = "azfun-${var.name}-${var.env}"
  location                   = data.azurerm_resource_group.rg.location
  resource_group_name        = data.azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_app_service_plan.asp.id
  storage_account_access_key = azurerm_storage_account.funcstore.primary_access_key
  storage_account_name       = azurerm_storage_account.funcstore.name
  os_type                    = var.os
  version                    = var.function_runtime_version

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.appin.instrumentation_key,
    SCM_DO_BUILD_DURING_DEPLOYMENT = "true",
    ENABLE_ORYX_BUILD              = "true"
    COSMOS_CXN_STRING              = "@Microsoft.KeyVault(VaultName=${data.azurerm_key_vault.kv.name};SecretName=cosmos-connection-string;SecretVersion=${azurerm_key_vault_secret.cosmos.version})"
  }
}

resource "azurerm_cosmosdb_account" "db" {
  name                = "cosmos-db-${var.name}-${var.env}"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  enable_automatic_failover = true

  capabilities {
    name = "EnableTable"
  }

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 10
    max_staleness_prefix    = 200
  }

  geo_location {
    location          = data.azurerm_resource_group.rg.location
    failover_priority = 0
  }
}

resource "azurerm_key_vault_secret" "cosmos" {
  name         = "cosmos-connection-string"
  value        = "DefaultEndpointsProtocol=https;${azurerm_cosmosdb_account.db.connection_strings[0]}TableEndpoint=https://${azurerm_cosmosdb_account.db.name}.table.cosmos.azure.com:443/;"
  key_vault_id = data.azurerm_key_vault.kv.id
}
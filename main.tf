# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }

  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.resource_group_location
  tags = {
     Environment = var.resource_group_environment,
     Owner = "Lee"
  }
}

resource "azurerm_app_service_plan" "sp" {
  name                = "${azurerm_resource_group.rg.name}-service-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  kind                = "FunctionApp"
  reserved = true
  sku {
    tier              = var.app_service_plan_tier
    size              = var.app_service_plan_size
  }
}

resource "azurerm_storage_account" "sa" {
  name                     = "${lower(azurerm_resource_group.rg.name)}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_storage_container" "sc" {
  name                  = "func-deployments"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"

  depends_on = [azurerm_resource_group.rg]
}

data "archive_file" "ffa" {
  type        = "zip"
  source_dir  = "../slackbotazfunction/"
  output_path = "src.zip"
}

resource "azurerm_storage_blob" "storage_blob" {
  name = "${filesha256(data.archive_file.ffa.output_path)}.zip"
  storage_account_name = azurerm_storage_account.sa.name
  storage_container_name = azurerm_storage_container.sc.name
  type = "Block"
  source = data.archive_file.ffa.output_path
}

data "azurerm_storage_account_blob_container_sas" "sabcs" {
  connection_string = azurerm_storage_account.sa.primary_connection_string
  container_name    = azurerm_storage_container.sc.name

  start = "2022-01-01T00:00:00Z"
  expiry = "2023-01-01T00:00:00Z"

  permissions {
    read   = true
    add    = false
    create = false
    write  = false
    delete = false
    list   = false
  }
}

resource "azurerm_application_insights" "ai" {
  name                = "${azurerm_resource_group.rg.name}-application-insights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

resource "azurerm_function_app" "app" {
  name                = "${azurerm_resource_group.rg.name}-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.sp.id
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "dotnet",
    WEBSITE_RUN_FROM_PACKAGE = "https://${azurerm_storage_account.sa.name}.blob.core.windows.net/${azurerm_storage_container.sc.name}/${azurerm_storage_blob.storage_blob.name}${data.azurerm_storage_account_blob_container_sas.sabcs.sas}",
    AzureWebJobsStorage = azurerm_storage_account.sa.primary_connection_string,
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.ai.instrumentation_key,
  }
  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key
  version                    = "~3"
  https_only                 = true

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"]
    ]
  }

  site_config {
    cors {
      allowed_origins = ["*"]
    }
  }
}

output "api_url"{
  value = azurerm_function_app.app.default_hostname
}
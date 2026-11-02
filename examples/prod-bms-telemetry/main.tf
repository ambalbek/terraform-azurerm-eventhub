# Deployment: Event Hub Namespace (namespace-only)

terraform {
  required_version = ">= 1.9"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = var.log_analytics_workspace_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_analytics_retention_days
}

module "eventhub" {
  source  = "Azure/avm-res-eventhub-namespace/azurerm"
  version = "~> 0.1"

  name                = var.namespace_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = var.namespace_sku
  capacity            = var.capacity

  diagnostic_settings = {
    to_law = {
      name                  = "${var.namespace_name}-diag"
      workspace_resource_id = azurerm_log_analytics_workspace.this.id
    }
  }

  tags = var.tags
}

output "namespace_id" {
  value = module.eventhub.resource_id
}

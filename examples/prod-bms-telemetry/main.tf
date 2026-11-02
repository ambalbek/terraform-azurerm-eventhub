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

locals {
  resource_group_name = "rg-${var.location}-${var.environment}-bms-telemetry"
  namespace_name      = "evhnsp-vdc-${var.location}-${var.environment}-microsoft-telemetry"
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
}

module "eventhub" {
  source  = "Azure/avm-res-eventhub-namespace/azurerm"
  version = "0.1.1"

  name                          = local.namespace_name
  resource_group_name           = azurerm_resource_group.this.name
  location                      = azurerm_resource_group.this.location
  sku                           = var.namespace_sku
  capacity                      = var.capacity
  public_network_access_enabled = true
  tags                          = var.tags
}

output "namespace_id" {
  value = module.eventhub.resource_id
}

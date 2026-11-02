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

module "eventhub" {
  source  = "Azure/avm-res-eventhub-namespace/azurerm"
  version = "~> 0.1"

  name                = var.namespace_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = var.namespace_sku
  capacity            = var.capacity
  tags                = var.tags
}

output "namespace_id" {
  value = module.eventhub.resource_id
}

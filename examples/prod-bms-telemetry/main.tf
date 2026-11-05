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

  hubs = {
    for site in var.sites : "evh-microsoft-telemetry-${site}" => {
      partition_count   = 5
      message_retention = 7
      consumer_groups = {
        "cg-microsoft-telemetry-${site}-01"      = { user_metadata = "" }
        "cg-capture-microsoft-telemetry-${site}"  = { user_metadata = "" }
      }
    }
  }
}

resource "azurerm_resource_group" "this" {
  name     = local.resource_group_name
  location = var.location
}

module "eventhub" {
  source = "../../"

  namespace_name      = local.namespace_name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  namespace_sku       = var.namespace_sku
  capacity            = var.capacity
  hubs                = local.hubs
  tags                = var.tags
}

output "namespace_id" {
  value = module.eventhub.namespace_id
}

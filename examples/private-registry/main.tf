# Example: Using the custom module from TFC private registry
# Source: app.terraform.io/vantagedc/eventhub/azurerm

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

resource "azurerm_resource_group" "example" {
  name     = "rg-eventhub-private-example"
  location = "eastus2"
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = "law-eventhub-example"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

module "eventhub" {
  source  = "app.terraform.io/vantagedc/eventhub/azurerm"
  version = "~> 1.0"

  namespace_name      = "evhns-private-example"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  namespace_sku       = "Standard"
  capacity            = 1

  hubs = {
    telemetry = {
      partition_count   = 4
      message_retention = 7
      consumer_groups = {
        processor = { user_metadata = "Telemetry processor" }
      }
      authorization_rules = {
        sender   = { send = true }
        listener = { listen = true }
      }
    }
  }

  namespace_authorization_rules = {
    root-manage = { listen = true, send = true, manage = true }
  }

  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  tags = {
    environment = "dev"
    source      = "private-registry"
  }
}

output "namespace_id" {
  value = module.eventhub.namespace_id
}

output "hub_ids" {
  value = module.eventhub.hub_ids
}

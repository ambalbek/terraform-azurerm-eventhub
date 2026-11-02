# Example: Using the public Azure Verified Module (AVM) for Event Hub
# Source: Azure/avm-res-eventhub-namespace/azurerm (Terraform public registry)

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
  name     = "rg-eventhub-avm-example"
  location = "eastus2"
}

resource "azurerm_log_analytics_workspace" "example" {
  name                = "law-eventhub-avm-example"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# --------------------------------------------------------------------------
# Public AVM Module — Event Hub Namespace
# Registry: https://registry.terraform.io/modules/Azure/avm-res-eventhub-namespace/azurerm
# --------------------------------------------------------------------------
module "eventhub_namespace" {
  source  = "Azure/avm-res-eventhub-namespace/azurerm"
  version = "~> 0.5"

  name                = "evhns-avm-example"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  sku                 = "Standard"
  capacity            = 1

  # Event Hubs
  eventhubs = {
    telemetry = {
      partition_count   = 4
      message_retention = 7

      consumer_groups = {
        processor = {
          name          = "processor"
          user_metadata = "Telemetry processor"
        }
      }

      authorization_rules = {
        sender = {
          name   = "sender"
          send   = true
          listen = false
          manage = false
        }
        listener = {
          name   = "listener"
          send   = false
          listen = true
          manage = false
        }
      }
    }
  }

  # Namespace authorization rules
  namespace_authorization_rules = {
    root-manage = {
      name   = "root-manage"
      listen = true
      send   = true
      manage = true
    }
  }

  # Diagnostic settings
  diagnostic_settings = {
    to_law = {
      name                  = "evhns-avm-diag"
      workspace_resource_id = azurerm_log_analytics_workspace.example.id
    }
  }

  tags = {
    environment = "dev"
    source      = "public-avm"
  }
}

output "namespace_id" {
  value = module.eventhub_namespace.resource_id
}

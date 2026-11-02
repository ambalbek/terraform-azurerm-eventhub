# terraform-azurerm-eventhub

Creates an Azure Event Hub namespace with configurable hubs, consumer groups, authorization rules, network rule sets, private endpoint, and diagnostic settings.

## Usage

```hcl
module "eventhub" {
  source  = "app.terraform.io/vantagedc/eventhub/azurerm"
  version = "~> 1.0"

  namespace_name      = "myapp-dev-evhns"
  resource_group_name = module.rg.name
  location            = module.rg.location
  namespace_sku       = "Standard"
  capacity            = 2

  hubs = {
    events = {
      partition_count   = 4
      message_retention = 7
      consumer_groups = {
        processor = { user_metadata = "Event processor" }
      }
      authorization_rules = {
        sender = { send = true }
      }
    }
  }

  namespace_authorization_rules = {
    root-manage = { listen = true, send = true, manage = true }
  }

  log_analytics_workspace_id = module.law.id
  tags                       = local.common_tags
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| namespace_name | string | — | Namespace name |
| resource_group_name | string | — | Resource group |
| location | string | — | Azure region |
| namespace_sku | string | Standard | Standard or Premium |
| capacity | number | 1 | Throughput/processing units |
| auto_inflate_enabled | bool | false | Enable auto-inflate |
| maximum_throughput_units | number | 0 | Max TUs for auto-inflate |
| public_network_access_enabled | bool | false | Public network access |
| network_rulesets | object | Deny | Network rule set config |
| hubs | map(object) | {} | Event Hubs with CGs and auth rules |
| namespace_authorization_rules | map(object) | {} | Namespace auth rules |
| private_endpoint_subnet_id | string | null | Subnet for PE |
| log_analytics_workspace_id | string | — | LA workspace ID |
| tags | map(string) | {} | Tags |

## Outputs

| Name | Description |
|------|-------------|
| namespace_id | Namespace ID |
| namespace_name | Namespace name |
| hub_ids | Map of hub name to ID |
| primary_connection_strings | Namespace auth rule connection strings (sensitive) |
| hub_authorization_rule_ids | Map of hub auth rule key to ID |

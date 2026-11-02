output "namespace_id" {
  description = "Event Hub namespace ID."
  value       = azurerm_eventhub_namespace.this.id
}

output "namespace_name" {
  description = "Event Hub namespace name."
  value       = azurerm_eventhub_namespace.this.name
}

output "hub_ids" {
  description = "Map of Event Hub name to ID."
  value       = { for k, v in azurerm_eventhub.this : k => v.id }
}

output "primary_connection_strings" {
  description = "Map of namespace authorization rule name to primary connection string."
  value = {
    for k, v in azurerm_eventhub_namespace_authorization_rule.this :
    k => v.primary_connection_string
  }
  sensitive = true
}

output "hub_authorization_rule_ids" {
  description = "Map of hub auth rule key to rule ID."
  value       = { for k, v in azurerm_eventhub_authorization_rule.this : k => v.id }
}

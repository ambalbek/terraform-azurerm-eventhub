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

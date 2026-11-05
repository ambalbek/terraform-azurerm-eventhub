locals {
  consumer_groups = merge([
    for hub_name, hub in var.hubs : {
      for cg_name, cg in hub.consumer_groups :
      "${hub_name}/${cg_name}" => {
        hub_name      = hub_name
        cg_name       = cg_name
        user_metadata = cg.user_metadata
      }
    }
  ]...)
}

resource "azurerm_eventhub_namespace" "this" {
  name                          = var.namespace_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.namespace_sku
  capacity                      = var.capacity
  auto_inflate_enabled          = var.namespace_sku == "Standard" ? var.auto_inflate_enabled : false
  maximum_throughput_units      = var.namespace_sku == "Standard" && var.auto_inflate_enabled ? var.maximum_throughput_units : 0
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags
}

resource "azurerm_eventhub" "this" {
  for_each = var.hubs

  name              = each.key
  namespace_id      = azurerm_eventhub_namespace.this.id
  partition_count   = each.value.partition_count
  message_retention = each.value.message_retention
}

resource "azurerm_eventhub_consumer_group" "this" {
  for_each = local.consumer_groups

  name                = each.value.cg_name
  namespace_name      = azurerm_eventhub_namespace.this.name
  eventhub_name       = azurerm_eventhub.this[each.value.hub_name].name
  resource_group_name = var.resource_group_name
  user_metadata       = each.value.user_metadata != "" ? each.value.user_metadata : null
}

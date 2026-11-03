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

# --------------------------------------------------------------------------
# Flatten maps for for_each on nested resources
# --------------------------------------------------------------------------
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

  hub_auth_rules = merge([
    for hub_name, hub in var.hubs : {
      for rule_name, rule in hub.authorization_rules :
      "${hub_name}/${rule_name}" => {
        hub_name  = hub_name
        rule_name = rule_name
        listen    = rule.listen
        send      = rule.send
        manage    = rule.manage
      }
    }
  ]...)
}

# --------------------------------------------------------------------------
# Namespace
# --------------------------------------------------------------------------
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

  network_rulesets = [{
    default_action                 = var.network_rulesets.default_action
    trusted_service_access_enabled = var.network_rulesets.trusted_service_access_enabled
    public_network_access_enabled  = var.public_network_access_enabled

    ip_rule = [
      for rule in var.network_rulesets.ip_rules : {
        ip_mask = rule.ip_mask
        action  = rule.action
      }
    ]

    virtual_network_rule = [
      for rule in var.network_rulesets.virtual_network_rules : {
        subnet_id                                       = rule.subnet_id
        ignore_missing_virtual_network_service_endpoint = false
      }
    ]
  }]
}

# --------------------------------------------------------------------------
# Event Hubs
# --------------------------------------------------------------------------
resource "azurerm_eventhub" "this" {
  for_each = var.hubs

  name              = each.key
  namespace_id      = azurerm_eventhub_namespace.this.id
  partition_count   = each.value.partition_count
  message_retention = each.value.message_retention
}

# --------------------------------------------------------------------------
# Consumer Groups
# --------------------------------------------------------------------------
resource "azurerm_eventhub_consumer_group" "this" {
  for_each = local.consumer_groups

  name                = each.value.cg_name
  namespace_name      = azurerm_eventhub_namespace.this.name
  eventhub_name       = azurerm_eventhub.this[each.value.hub_name].name
  resource_group_name = var.resource_group_name
  user_metadata       = each.value.user_metadata
}

# --------------------------------------------------------------------------
# Namespace Authorization Rules
# --------------------------------------------------------------------------
resource "azurerm_eventhub_namespace_authorization_rule" "this" {
  for_each = var.namespace_authorization_rules

  name                = each.key
  namespace_name      = azurerm_eventhub_namespace.this.name
  resource_group_name = var.resource_group_name
  listen              = each.value.listen
  send                = each.value.send
  manage              = each.value.manage
}

# --------------------------------------------------------------------------
# Hub-level Authorization Rules
# --------------------------------------------------------------------------
resource "azurerm_eventhub_authorization_rule" "this" {
  for_each = local.hub_auth_rules

  name                = each.value.rule_name
  namespace_name      = azurerm_eventhub_namespace.this.name
  eventhub_name       = azurerm_eventhub.this[each.value.hub_name].name
  resource_group_name = var.resource_group_name
  listen              = each.value.listen
  send                = each.value.send
  manage              = each.value.manage
}

# --------------------------------------------------------------------------
# Private Endpoint (optional)
# --------------------------------------------------------------------------
resource "azurerm_private_endpoint" "this" {
  count = var.private_endpoint_subnet_id != null ? 1 : 0

  name                = "${var.namespace_name}-pe"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "${var.namespace_name}-psc"
    private_connection_resource_id = azurerm_eventhub_namespace.this.id
    is_manual_connection           = false
    subresource_names              = ["namespace"]
  }
}

# --------------------------------------------------------------------------
# Diagnostic Settings
# --------------------------------------------------------------------------
resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "${var.namespace_name}-diag"
  target_resource_id         = azurerm_eventhub_namespace.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category_group = "allLogs"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

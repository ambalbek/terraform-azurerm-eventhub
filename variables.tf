variable "namespace_name" {
  description = "Name of the Event Hub namespace."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "namespace_sku" {
  description = "SKU for the Event Hub namespace (Standard or Premium)."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Standard", "Premium"], var.namespace_sku)
    error_message = "namespace_sku must be 'Standard' or 'Premium'."
  }
}

variable "capacity" {
  description = "Throughput units (Standard) or processing units (Premium)."
  type        = number
  default     = 1

  validation {
    condition     = var.capacity >= 1 && var.capacity <= 40
    error_message = "capacity must be between 1 and 40."
  }
}

variable "auto_inflate_enabled" {
  description = "Enable auto-inflate for Standard SKU."
  type        = bool
  default     = false
}

variable "maximum_throughput_units" {
  description = "Maximum throughput units when auto-inflate is enabled."
  type        = number
  default     = 0

  validation {
    condition     = var.maximum_throughput_units >= 0 && var.maximum_throughput_units <= 40
    error_message = "maximum_throughput_units must be between 0 and 40."
  }
}

variable "public_network_access_enabled" {
  description = "Allow public network access to the namespace."
  type        = bool
  default     = false
}

variable "hubs" {
  description = "Map of Event Hubs to create within the namespace."
  type = map(object({
    partition_count   = number
    message_retention = number
    consumer_groups = optional(map(object({
      user_metadata = optional(string, "")
    })), {})
  }))
  default = {}
}

variable "tags" {
  description = "Tags to apply."
  type        = map(string)
  default     = {}
}

variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "namespace_name" {
  description = "Name of the Event Hub namespace."
  type        = string
}

variable "namespace_sku" {
  description = "SKU for the Event Hub namespace."
  type        = string
  default     = "Premium"
}

variable "capacity" {
  description = "Throughput units (Standard) or processing units (Premium)."
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

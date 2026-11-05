variable "environment" {
  description = "Environment name (e.g. dev, prod)."
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region."
  type        = string
  default     = "canadacentral"
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

variable "sites" {
  description = "List of site codes for event hub creation."
  type        = list(string)
  default = [
    "az11", "az12", "az13", "az14",
    "ber11", "ber12",
    "ca11", "ca14", "ca21", "ca22", "ca23", "ca31",
    "cwl11", "cwl13",
    "fra21",
    "inb11", "inb12",
    "mxp11",
    "qc21", "qc22", "qc23",
    "va31",
    "wa12", "wa13",
    "zrh21"
  ]
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

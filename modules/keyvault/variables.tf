variable "name" {
  type        = string
  description = "Name of the Key Vault (must be globally unique, 3-24 alphanumeric and hyphens)"

  validation {
    condition     = length(var.name) >= 3 && length(var.name) <= 24 && can(regex("^[a-zA-Z0-9-]+$", var.name))
    error_message = "Key Vault name must be 3-24 characters, alphanumeric and hyphens only."
  }
}

variable "rg_name" {
  type        = string
  description = "Name of the resource group"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, prod, staging)"

  validation {
    condition     = contains(["dev", "prod", "staging"], var.environment)
    error_message = "Environment must be dev, prod, or staging."
  }
}

variable "tenant_id" {
  type        = string
  description = "Azure Tenant ID"
  sensitive   = true
}

variable "object_id" {
  type        = string
  description = "Object ID of the principal (user or service principal)"
  sensitive   = true
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to Key Vault"
  default     = {}
}
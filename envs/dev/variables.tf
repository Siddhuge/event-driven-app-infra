variable "location" {
  type        = string
  description = "Azure region for resource deployment"
  default     = "Central India"

  validation {
    condition     = can(regex("^[a-zA-Z\\s]+$", var.location))
    error_message = "Location must be a valid Azure region name."
  }
}

variable "environment" {
  type        = string
  description = "Environment name (dev, prod, staging)"
  default     = "dev"

  validation {
    condition     = contains(["dev", "prod", "staging"], var.environment)
    error_message = "Environment must be dev, prod, or staging."
  }
}

variable "project_name" {
  type        = string
  description = "Project name for resource naming and tagging"
  default     = "event-driven"

  validation {
    condition     = length(var.project_name) <= 20 && can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must be lowercase alphanumeric with hyphens, max 20 chars."
  }
}

variable "created_date" {
  type        = string
  description = "Stable creation date tag value applied to Terraform-managed resources"
  default     = "2026-04-29"

  validation {
    condition     = can(regex("^\\d{4}-\\d{2}-\\d{2}$", var.created_date))
    error_message = "Created date must use YYYY-MM-DD format."
  }
}

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
  default = {
    "Managed-By"  = "Terraform",
    "Cost-Center" = "Engineering",
    "Compliance"  = "SOC2"
  }
}

variable "aks_authorized_ips" {
  type        = list(string)
  description = "IP ranges authorized to access AKS API server"
  default     = ["106.213.87.181"]

  validation {
    condition     = alltrue([for ip in var.aks_authorized_ips : can(cidrhost(ip, 0))])
    error_message = "All entries must be valid CIDR blocks."
  }
}

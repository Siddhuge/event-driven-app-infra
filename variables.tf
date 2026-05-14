variable "resource_group_name" {
  default = "rg-bluegreen-prod"
}

variable "location" {
  default = "Central India"
}

variable "vnet_name" {
  default = "bluegreen-vnet"
}

variable "vnet_address_space" {
  default = ["10.0.0.0/16"]
}

variable "app_subnet" {
  default = "10.0.1.0/24"
}

variable "appgw_subnet" {
  default = "10.0.2.0/24"
}

variable "admin_username" {
  default = "azureuser"
}

variable "vm_size" {
  default = "Standard_B2s"
}

variable "environment" {
  default = "prod"
}
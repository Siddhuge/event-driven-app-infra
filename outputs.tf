output "application_gateway_public_ip" {
  value = azurerm_public_ip.appgw_pip.ip_address
}

output "blue_vm_public_ip" {
  value = azurerm_public_ip.blue_pip.ip_address
}

output "green_vm_public_ip" {
  value = azurerm_public_ip.green_pip.ip_address
}

output "blue_vm_private_ip" {
  value = azurerm_network_interface.blue_nic.private_ip_address
}

output "green_vm_private_ip" {
  value = azurerm_network_interface.green_nic.private_ip_address
}
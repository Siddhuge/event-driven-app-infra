output "id" {
  value       = azurerm_key_vault.kv.id
  description = "Key Vault resource ID"
}

output "vault_uri" {
  value       = azurerm_key_vault.kv.vault_uri
  description = "Key Vault URI for accessing secrets and keys"
  sensitive   = false
}

output "name" {
  value       = azurerm_key_vault.kv.name
  description = "Name of the Key Vault"
}

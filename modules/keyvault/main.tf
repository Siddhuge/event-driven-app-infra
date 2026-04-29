data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  name                = var.name
  location            = var.location
  resource_group_name = var.rg_name
  tenant_id           = var.tenant_id
  sku_name            = var.environment == "prod" ? "premium" : "standard"

  # Security and compliance
  enabled_for_deployment          = true
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true

  purge_protection_enabled   = var.environment == "prod" ? true : false
  soft_delete_retention_days = 90

  # Network security
  public_network_access_enabled = false
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  # Logging and audit
  access_policy {
    tenant_id = var.tenant_id
    object_id = var.object_id

    key_permissions = [
      "Create", "Delete", "Get", "List", "Restore", "Recover",
      "Update", "WrapKey", "UnwrapKey", "Sign", "Verify"
    ]

    secret_permissions = [
      "Set", "Get", "Delete", "List", "Recover", "Restore"
    ]

    certificate_permissions = [
      "Create", "Delete", "Get", "List", "Recover", "Restore",
      "Update", "Import"
    ]
  }

  tags = var.tags
}

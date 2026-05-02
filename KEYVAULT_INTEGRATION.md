# Azure Key Vault Integration with Azure Pipelines

This guide explains how to set up Azure Key Vault to securely manage sensitive variables for the Terraform infrastructure pipeline.

## Overview

The updated Azure Pipeline integrates with Azure Key Vault to securely store and retrieve sensitive data like SSH keys and CIDR ranges. This eliminates the need to hardcode secrets in pipeline variables or terraform.tfvars files.

## Prerequisites

- Azure subscription with appropriate permissions
- Azure DevOps project with the pipeline configured
- An existing Azure Key Vault or create one using Terraform

## Setup Instructions

### 1. Create Azure Key Vault (if not already created)

The Key Vault is created as part of the Terraform deployment:

```bash
# Check if Key Vault was created
az keyvault list --query "[?contains(name, 'event-driven')].{name: name, id: id}"
```

Expected output (from terraform outputs):
```
key_vault_uri = "https://event-driven-dev-kv.vault.azure.net/"
```

### 2. Add Secrets to Key Vault

Add the required secrets to your Key Vault:

```bash
# Set your SSH public key
SSH_PUBLIC_KEY="ssh-rsa AAAA... your-key-here"
ALLOWED_CIDR="YOUR_IP/32"

# Add secrets to Key Vault
az keyvault secret set \
  --vault-name event-driven-dev-kv \
  --name jumpbox-ssh-public-key \
  --value "$SSH_PUBLIC_KEY"

az keyvault secret set \
  --vault-name event-driven-dev-kv \
  --name jumpbox-allowed-ssh-cidr \
  --value "$ALLOWED_CIDR"
```

### 3. Configure Azure DevOps Service Connection Permissions

The Azure DevOps service connection needs permissions to read from Key Vault.

**Via Azure Portal:**

1. Navigate to your Key Vault
2. Go to **Access control (IAM)**
3. Click **Add role assignment**
4. Select role: **Key Vault Secrets User**
5. Assign to: Your service principal (used by Azure DevOps pipeline)
6. Click **Review + assign**

**Via Azure CLI:**

```bash
# Get your service principal ID (replace with actual value)
SERVICE_PRINCIPAL_ID="00000000-0000-0000-0000-000000000000"

# Grant Key Vault Secrets User role
az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee-object-id "$SERVICE_PRINCIPAL_ID" \
  --scope "/subscriptions/{subscriptionId}/resourceGroups/{rgName}/providers/Microsoft.KeyVault/vaults/event-driven-dev-kv"
```

### 4. Pipeline Variables Configuration

Update the following variables in your Azure Pipeline:

**Pipeline Library Variables** (set in Azure DevOps):
```
azureServiceConnection: IAC-Conn          # Your service connection name
terraformVersion: 1.5.7                   # Terraform version to use
keyVaultName: event-driven-dev-kv         # Your Key Vault name
jumpboxEnabledDev: 'true'                 # Enable/disable jumpbox in DEV
jumpboxEnabledProd: 'false'               # Enable/disable jumpbox in PROD
```

**Key Vault Secrets** (stored securely):
```
jumpbox-ssh-public-key    → SSH public key for jumpbox access
jumpbox-allowed-ssh-cidr  → CIDR range allowed to SSH (e.g., "203.0.113.45/32")
```

### 5. Update Pipeline YAML (Already Done)

The `azure-pipelines.yml` has been updated with:

```yaml
- task: AzureKeyVault@2
  displayName: 🔐 Fetch Secrets from Key Vault
  inputs:
    azureSubscription: $(azureServiceConnection)
    KeyVaultName: $(keyVaultName)
    SecretsFilter: |
      jumpbox-ssh-public-key
      jumpbox-allowed-ssh-cidr
    RunAsPreJob: true
```

The secrets are retrieved and converted to pipeline variables automatically:
- `jumpbox-ssh-public-key` → `$(jumpbox-ssh-public-key)`
- `jumpbox-allowed-ssh-cidr` → `$(jumpbox-allowed-ssh-cidr)`

## How It Works

### Pipeline Execution Flow

1. **Security Scan Stage**: Runs Checkov to scan Terraform code
2. **DEV Plan Stage**: 
   - Authenticates to Key Vault
   - Retrieves secrets
   - Creates `pipeline.auto.tfvars` with Key Vault values
   - Runs terraform plan with drift detection
3. **DEV Apply Stage**: Applies the plan if approved
4. **PROD Plan Stage**: Same as DEV but for production
5. **PROD Apply Stage**: Applies prod plan if approved

### Environment-Specific Configuration

```yaml
# In pipeline.auto.tfvars (automatically generated):
jumpbox_enabled              = true/false                    # From pipeline variable
jumpbox_admin_username       = "azureuser"                  # Hardcoded
jumpbox_admin_ssh_public_key = "$(jumpbox-ssh-public-key)"  # From Key Vault
jumpbox_allowed_ssh_cidrs    = ["$(jumpbox-allowed-ssh-cidr)"] # From Key Vault
```

## Security Best Practices

✅ **Implemented:**
- SSH keys stored in Key Vault (not in code)
- CIDR ranges managed securely
- RBAC-based access control
- Secrets never logged in pipeline output
- Service principal used for authentication
- Drift detection in both DEV and PROD

✅ **Additional Recommendations:**
1. **Rotate SSH Keys**: Update Key Vault secrets regularly
2. **Audit Logs**: Check Key Vault audit logs for access
3. **Network Access**: Restrict Key Vault access via firewall rules
4. **RBAC**: Limit service principal permissions to minimum required
5. **Secrets Expiration**: Set expiration policies on sensitive secrets

## Troubleshooting

### Pipeline fails with "Access denied to Key Vault"

**Solution**: Ensure the service principal has **Key Vault Secrets User** role:

```bash
az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee-object-id "<SERVICE_PRINCIPAL_ID>" \
  --scope "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/<RG_NAME>/providers/Microsoft.KeyVault/vaults/<KV_NAME>"
```

### Secrets not appearing in Terraform variables

**Solution**: Verify the secret names match exactly:
```bash
az keyvault secret list --vault-name event-driven-dev-kv --query "[].name"
```

Must match:
- `jumpbox-ssh-public-key`
- `jumpbox-allowed-ssh-cidr`

### Terraform fails with "resource still exists" during destroy

**Solution**: The Azure Resource Group deletion protection has been disabled in providers.tf:

```hcl
features {
  resource_group {
    prevent_deletion_if_contains_resources = false
  }
}
```

This allows the resource group and all nested resources to be deleted.

## Adding New Secrets

To add more secrets to the pipeline:

1. **Add secret to Key Vault**:
```bash
az keyvault secret set --vault-name event-driven-dev-kv \
  --name <secret-name> \
  --value <secret-value>
```

2. **Update pipeline YAML** - Add to `SecretsFilter`:
```yaml
SecretsFilter: |
  jumpbox-ssh-public-key
  jumpbox-allowed-ssh-cidr
  new-secret-name
```

3. **Use in inline script**:
```bash
echo "$(new-secret-name)"
```

## Example: Storing Database Passwords

```bash
# Store database password
az keyvault secret set --vault-name event-driven-dev-kv \
  --name db-admin-password \
  --value "SecurePassword123!"

# Use in pipeline
cat >> "$TF_DIR/pipeline.auto.tfvars" <<EOF
db_admin_password = "$(db-admin-password)"
EOF
```

## References

- [Azure Key Vault Documentation](https://learn.microsoft.com/en-us/azure/key-vault/)
- [Azure Pipelines Key Vault Task](https://learn.microsoft.com/en-us/azure/devops/pipelines/tasks/deploy/azure-key-vault)
- [GitHub - Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review pipeline execution logs in Azure DevOps
3. Verify Key Vault secret names and permissions
4. Consult Azure documentation links above

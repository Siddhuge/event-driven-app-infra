resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.name
  location            = var.location
  resource_group_name = var.rg_name
  dns_prefix          = replace(var.name, "-", "")
  kubernetes_version  = "1.27"

  # Security: Private cluster with API server restricted
  private_cluster_enabled             = true
  api_server_authorized_ip_ranges     = length(var.authorized_ip_ranges) > 0 ? var.authorized_ip_ranges : null
  private_cluster_public_fqdn_enabled = false

  default_node_pool {
    name                = "system"
    node_count          = var.environment == "prod" ? 3 : 1
    vm_size             = var.environment == "prod" ? "Standard_D4s_v3" : "Standard_DS2_v2"
    vnet_subnet_id      = var.subnet_id
    max_pods            = 110
    enable_auto_scaling = true
    min_count           = var.environment == "prod" ? 3 : 1
    max_count           = var.environment == "prod" ? 10 : 3

    # Security settings
    os_disk_size_gb             = 50
    os_disk_type                = "Managed"
    temporary_name_for_rotation = "system-tmp"
  }

  # Identity and Access
  identity {
    type = "SystemAssigned"
  }

  # Network security
  network_profile {
    network_plugin    = "azure" # CNI for Azure native networking
    network_policy    = "azure" # Enforces NSG-based policies
    service_cidr      = "10.0.0.0/16"
    dns_service_ip    = "10.0.0.10"
    load_balancer_sku = "standard"
    outbound_type     = "userDefinedRouting"
  }

  # RBAC and Azure AD integration
  role_based_access_control_enabled = true

  # Azure Policy for compliance
  azure_policy_enabled = true

  # OMS agent for monitoring (optional, configure as needed)
  dynamic "oms_agent" {
    for_each = var.key_vault_id != "" ? [1] : []
    content {
      log_analytics_workspace_id = "" # Configure workspace ID as needed
    }
  }

  # Cluster tagging
  tags = var.tags

  depends_on = []
}
provider "azurerm" {
  features {}
}

# --- Financial Foundation (Institutional Hub) ---

resource "azurerm_resource_group" "fslz" {
  name     = "rg-${var.project_name}-foundation-${var.environment}"
  location = var.location
}

# --- Shared Services Hub Network ---

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-${var.project_name}-hub-${var.environment}"
  location            = azurerm_resource_group.fslz.location
  resource_group_name = azurerm_resource_group.fslz.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    Environment = var.environment
    CostCenter  = "Core-IT"
  }
}

# --- Regulated Workload Plane (AKS) ---

resource "azurerm_kubernetes_cluster" "fslz_k8s" {
  name                = "aks-${var.project_name}-payments-${var.environment}"
  location            = azurerm_resource_group.fslz.location
  resource_group_name = azurerm_resource_group.fslz.name
  dns_prefix          = "fslz-payments"

  default_node_pool {
    name       = "fslzpool"
    node_count = 3
    vm_size    = "Standard_D4s_v3"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }
}

# --- Institutional Design Store (Postgres) ---

resource "azurerm_postgresql_flexible_server" "fslz" {
  name                   = "psql-${var.project_name}-governance-${var.environment}"
  resource_group_name    = azurerm_resource_group.fslz.name
  location               = azurerm_resource_group.fslz.location
  version                = "13"
  administrator_login    = "fslzadmin"
  administrator_password = var.db_password
  storage_mb             = 32768
  sku_name               = "GP_Standard_D2ds_v4"
}

# --- Compliance Secrets & Identity (Key Vault) ---

resource "azurerm_key_vault" "fslz" {
  name                        = "kv-fslz-maestro-${var.environment}"
  location                    = azurerm_resource_group.fslz.location
  resource_group_name         = azurerm_resource_group.fslz.name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true # Critical for financial records

  sku_name = "standard"
}

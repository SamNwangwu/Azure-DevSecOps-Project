output "aks_id" {
  value = azurerm_kubernetes_cluster.aks.id
  description = "The ID of the AKS cluster"
}

output "aks_fqdn" {
  value = azurerm_kubernetes_cluster.aks.fqdn
  description = "The FQDN of the AKS cluster"
}

output "aks_node_rg" {
  value = azurerm_kubernetes_cluster.aks.node_resource_group
  description = "The auto-generated resource group for AKS nodes"
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
  description = "The login server URL for the Azure Container Registry"
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
  description = "The Kubernetes configuration for connecting to the cluster"
}

output "resource_group_name" {
  value = azurerm_resource_group.rg.name
  description = "The name of the resource group"
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
  description = "The name of the Azure Container Registry"
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
  description = "The name of the AKS cluster"
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.aks_logs.id
  description = "The ID of the Log Analytics workspace"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "azure-devsecops-rg"
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "West Europe"
}

variable "cluster_name" {
  description = "Name of AKS cluster"
  type        = string
  default     = "devsecops-aks"
}

variable "acr_name" {
  description = "Name of Azure Container Registry"
  type        = string
  default     = "devsecopssam123456"
}

variable "dns_prefix" {
  description = "DNS prefix for AKS cluster"
  type        = string
  default     = "devsecops"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 1
}

variable "vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_B2s"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.30.4"
}

# Azure DevSecOps CI/CD Project
A comprehensive end-to-end DevSecOps project implementing a secure three-tier web application on Azure Kubernetes Service using industry best practices for security, CI/CD, GitOps, and monitoring.

<div align="center">
  <img src="./Three-Tier-App-AzureDevSecOps.png" alt="Azure Architecture Diagram" width="800">
</div>

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Tools & Technologies](#tools--technologies)
- [Project Implementation](#project-implementation)
- [Infrastructure Provisioning](#infrastructure-provisioning)
- [CI/CD Pipeline](#cicd-pipeline)
- [GitOps Configuration](#gitops-configuration)
- [Monitoring Setup](#monitoring-setup)
- [Security Features](#security-features)
- [Monitoring Dashboards](#monitoring-dashboards)
- [Results & Benefits](#results--benefits)
- [Next Steps](#next-steps)
- [About](#about)

## 🏗️ Architecture Overview

This project demonstrates a complete DevSecOps pipeline for deploying and managing a containerised three-tier web application on Azure Kubernetes Service. The architecture leverages Infrastructure as Code, CI/CD automation, security scanning, and comprehensive monitoring to deliver a secure and reliable application platform.

## 🛠️ Tools & Technologies

**Cloud Infrastructure**

* Azure (Entra, AKS, Application Gateway, Azure DNS, Azure CLI)
* Terraform (Infrastructure as Code)

**CI/CD Pipeline**

* GitHub Actions (CI/CD workflow automation)
* ArgoCD (GitOps continuous delivery)

**Security Scanning**

* SonarQube (SAST code quality analysis)
* Snyk (Dependency vulnerability scanning)
* Trivy (Container image vulnerability scanning)
* Microsoft Defender for Containers (Runtime security)

**Containerization & Orchestration**

* Docker (Application containerization)
* Azure Container Registry (Container image repository)
* Azure Kubernetes Service (Container orchestration)
* Helm (Kubernetes package management)

**Monitoring & Observability**

* Azure Monitor (Platform monitoring)
* Prometheus (Metrics collection)
* Grafana (Dashboards and visualization)
* Azure Application Insights (Application performance monitoring)

## 💻 Project Implementation

### Infrastructure Provisioning with Terraform

The project uses Terraform to provision all required Azure infrastructure:

```hcl
# main.tf excerpt

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name    = var.resource_group_name
  location = var.location
}

# Create Azure Kubernetes Service
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }
}

# Create Container Registry
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  admin_enabled       = false
}
```

### CI/CD Pipeline with GitHub Actions

The project implements a comprehensive CI/CD pipeline using GitHub Actions:

```yaml
# .github/workflows/ci-cd.yml excerpt

name: CI/CD Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
      with:
        fetch-depth: 0

    - name: Set up Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '16'

    - name: Install dependencies
      run: npm ci

    - name: Run SonarQube Scan
      uses: SonarSource/sonarcloud-github-action@master
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}

    - name: Run Snyk Security Scan
      uses: snyk/actions/node@master
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}

  build-and-push:
    needs: build-and-test
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3

    - name: Login to ACR
      uses: azure/docker-login@v1
      with:
        login-server: ${{ secrets.ACR_LOGIN_SERVER }}
        username: ${{ secrets.AZURE_CLIENT_ID }}
        password: ${{ secrets.AZURE_CLIENT_SECRET }}

    - name: Build and push Docker image
      uses: docker/build-push-action@v4
      with:
        context: .
        push: true
        tags: ${{ secrets.ACR_LOGIN_SERVER }}/myapp:${{ github.sha }}

    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: ${{ secrets.ACR_LOGIN_SERVER }}/myapp:${{ github.sha }}
        format: 'table'
        exit-code: '1'
        severity: 'CRITICAL,HIGH'

  deploy:
    needs: build-and-push
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3

    - name: Install ArgoCD CLI
      run: |
        curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
        chmod +x argocd
        sudo mv argocd /usr/local/bin/argocd

    - name: Update Kubernetes manifests
      run: |
        sed -i "s|image:.*|image: ${{ secrets.ACR_LOGIN_SERVER }}/myapp:${{ github.sha }}|" kubernetes/deployment.yaml

    - name: Commit and push updated manifests
      run: |
        git config --global user.name 'GitHub Actions'
        git config --global user.email 'actions@github.com'
        git add kubernetes/deployment.yaml
        git commit -m "Update image to ${{ github.sha }}" || echo "No changes to commit"
        git push
```

### ArgoCD Configuration for GitOps

ArgoCD is used to implement GitOps principles for continuous delivery:

```yaml
# argocd/application.yaml excerpt

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: myapp
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/yourusername/azure-devops-project.git
    targetRevision: HEAD
    path: kubernetes
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Monitoring Setup

The project includes comprehensive monitoring with Prometheus and Grafana:

```yaml
# prometheus/prometheus.yaml excerpt

apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
          - role: pod
        relabel_configs:
          - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
            action: keep
            regex: true
```

## 🔒 Security Features

* Static Application Security Testing (SAST) with SonarQube
* Software Composition Analysis (SCA) with Snyk
* Container Vulnerability Scanning with Trivy
* Runtime Protection with Microsoft Defender for Containers
* Network Security with Azure Network Security Groups
* Secret Management using Azure Key Vault
* RBAC implementation for AKS and Azure resources

## 📊 Monitoring Dashboards

The project includes comprehensive monitoring dashboards:

<div align="center">
<table>
  <tr>
    <td width="50%">
      <strong>Kubernetes Cluster Health</strong><br/>
      <img src="./Grafana-Dashboard.png" alt="K8s Dashboard" width="100%">
    </td>
    <td width="50%">
      <strong>Application Performance</strong><br/>
      <img src="[placeholder-image]" alt="App Dashboard" width="100%">
    </td>
  </tr>
  <tr>
    <td width="50%">
      <strong>Security Posture</strong><br/>
      <img src="[placeholder-image]" alt="Security Dashboard" width="100%">
    </td>
    <td width="50%">
      <strong>Cost Optimization</strong><br/>
      <img src="[placeholder-image]" alt="Cost Dashboard" width="100%">
    </td>
  </tr>
</table>
</div>

## 🚀 Results & Benefits

This CI/CD implementation delivers:

* ✅ Enhanced Security: Comprehensive security scanning and monitoring
* ✅ Deployment Automation: Consistent, repeatable deployments using GitOps
* ✅ Infrastructure as Code: Reproducible infrastructure with Terraform
* ✅ Observability: Complete monitoring of infrastructure and applications
* ✅ Scalability: Leveraging Azure's managed Kubernetes service for growth

## 🔮 Next Steps

* Implement blue-green deployment strategy
* Add chaos engineering tests
* Integrate cost optimization tools
* Implement policy as code with Open Policy Agent

## 📝 About

This project demonstrates the implementation of DevSecOps best practices for deploying secure, containerized applications on Azure Kubernetes Service. It integrates CI/CD automation, security scanning, GitOps principles, and comprehensive monitoring to deliver a robust and reliable application platform.

<div align="center">
  <img src="https://img.shields.io/badge/Made_with_❤️_by-Samuel_Nwangwu-blue?style=for-the-badge" alt="Made with love">
</div>
